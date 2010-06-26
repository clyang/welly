//
//  WLAsciiArtRender.m
//  Welly
//
//  Created by K.O.ed on 10-6-25.
//  Copyright 2010 Welly Group. All rights reserved.
//

#import "WLAsciiArtRender.h"
#import "WLGlobalConfig.h"

@interface NSBezierPath (LineSegmentAppendable)

- (void)addLineSegmentFrom:(NSPoint)pt1 
						to:(NSPoint)pt2;

@end

@implementation NSBezierPath (LineSegmentAppendable)

- (void)addLineSegmentFrom:(NSPoint)pt1 
						to:(NSPoint)pt2 {
	BOOL shouldRestoreOldPoint = ![self isEmpty];
	NSPoint oldPt;
	if (shouldRestoreOldPoint)
		oldPt = [self currentPoint];
	[self moveToPoint:pt1];
	[self lineToPoint:pt2];
	if (shouldRestoreOldPoint)
		[self moveToPoint:oldPt];
}

@end



static WLGlobalConfig *gConfig;
static NSImage *gLeftImage;

static NSRect gSymbolBlackSquareRectL;
static NSRect gSymbolBlackSquareRectR;
static NSRect gSymbolLowerBlockRectL[8];
static NSRect gSymbolLowerBlockRectR[8];
static NSRect gSymbolLeftBlockRectL[7];
static NSRect gSymbolLeftBlockRectR[7];
static NSBezierPath *gSymbolTrianglePathL[4];
static NSBezierPath *gSymbolTrianglePathR[4];

// Extended Ascii Art support
static NSBezierPath *gSymbolDiagonalPathL[3];
static NSBezierPath *gSymbolDiagonalPathR[3];

static NSBezierPath *gSymbolDualLinePath[29];

static NSBezierPath *gSymbolArcPath[4];

@implementation WLAsciiArtRender

- (NSBezierPath *)dualLinePathWithIndex:(NSUInteger)index {
	if (gSymbolDualLinePath[index])
		return gSymbolDualLinePath[index];
	
	// Not existed, create it lively
	const static CGFloat gapRatio = 1 - 0.618;
	CGFloat xpts2[5] = {0, _fontWidth*(1-gapRatio/2), _fontWidth, _fontWidth*(1+gapRatio/2), 2*_fontWidth};
	CGFloat ypts2[5] = {0, _fontHeight/2*(1-gapRatio/2), _fontHeight/2, _fontHeight/2*(1+gapRatio/2), _fontHeight};
	
	gSymbolDualLinePath[index] = [[NSBezierPath alloc] init];
	[gSymbolDualLinePath[index] setLineWidth:2.0];
	
#define DLPoint(x, y) NSMakePoint(xpts2[(x)], ypts2[(y)])
	switch (index) {
		case 0: // ═
			[gSymbolDualLinePath[0] moveToPoint:DLPoint(0,1)];
			[gSymbolDualLinePath[0] lineToPoint:DLPoint(4,1)];
			[gSymbolDualLinePath[0] moveToPoint:DLPoint(0,3)];
			[gSymbolDualLinePath[0] lineToPoint:DLPoint(4,3)];
			break;
		case 1: // ║
			[gSymbolDualLinePath[1] moveToPoint:DLPoint(1,0)];
			[gSymbolDualLinePath[1] lineToPoint:DLPoint(1,4)];
			[gSymbolDualLinePath[1] moveToPoint:DLPoint(3,0)];
			[gSymbolDualLinePath[1] lineToPoint:DLPoint(3,4)];
			break;
		case 2: // ╒
			[gSymbolDualLinePath[2] moveToPoint:DLPoint(2,0)];
			[gSymbolDualLinePath[2] lineToPoint:DLPoint(2,3)];
			[gSymbolDualLinePath[2] lineToPoint:DLPoint(4,3)];
			[gSymbolDualLinePath[2] moveToPoint:DLPoint(2,1)]; 
			[gSymbolDualLinePath[2] lineToPoint:DLPoint(4,1)];
			break;
		case 3: // ╓
			[gSymbolDualLinePath[3] moveToPoint:DLPoint(4,2)];
			[gSymbolDualLinePath[3] lineToPoint:DLPoint(1,2)];
			[gSymbolDualLinePath[3] lineToPoint:DLPoint(1,0)];
			[gSymbolDualLinePath[3] moveToPoint:DLPoint(3,2)];
			[gSymbolDualLinePath[3] lineToPoint:DLPoint(3,0)];
			break;
		case 4: // ╔
			[gSymbolDualLinePath[4] moveToPoint:DLPoint(1,0)];
			[gSymbolDualLinePath[4] lineToPoint:DLPoint(1,3)];
			[gSymbolDualLinePath[4] lineToPoint:DLPoint(4,3)];
			[gSymbolDualLinePath[4] moveToPoint:DLPoint(3,0)];
			[gSymbolDualLinePath[4] lineToPoint:DLPoint(3,1)];
			[gSymbolDualLinePath[4] lineToPoint:DLPoint(4,1)];
			break;
		case 5:	// ╕
			[gSymbolDualLinePath[5] moveToPoint:DLPoint(2,0)];
			[gSymbolDualLinePath[5] lineToPoint:DLPoint(2,3)];
			[gSymbolDualLinePath[5] lineToPoint:DLPoint(0,3)];
			[gSymbolDualLinePath[5] moveToPoint:DLPoint(0,1)];
			[gSymbolDualLinePath[5] lineToPoint:DLPoint(2,1)];
			break;
		case 6: // ╖
			[gSymbolDualLinePath[6] moveToPoint:DLPoint(0,2)];
			[gSymbolDualLinePath[6] lineToPoint:DLPoint(3,2)];
			[gSymbolDualLinePath[6] lineToPoint:DLPoint(3,0)];
			[gSymbolDualLinePath[6] moveToPoint:DLPoint(1,2)];
			[gSymbolDualLinePath[6] lineToPoint:DLPoint(1,0)];
			break;
		case 7: // ╗
			[gSymbolDualLinePath[7] moveToPoint:DLPoint(0,1)];
			[gSymbolDualLinePath[7] lineToPoint:DLPoint(1,1)];
			[gSymbolDualLinePath[7] lineToPoint:DLPoint(1,0)];
			[gSymbolDualLinePath[7] moveToPoint:DLPoint(0,3)];
			[gSymbolDualLinePath[7] lineToPoint:DLPoint(3,3)];
			[gSymbolDualLinePath[7] lineToPoint:DLPoint(3,0)];
			break;
		case 8: // ╘
			[gSymbolDualLinePath[8] moveToPoint:DLPoint(2,4)];
			[gSymbolDualLinePath[8] lineToPoint:DLPoint(2,1)];
			[gSymbolDualLinePath[8] lineToPoint:DLPoint(4,1)];
			[gSymbolDualLinePath[8] moveToPoint:DLPoint(2,3)];
			[gSymbolDualLinePath[8] lineToPoint:DLPoint(4,3)];
			break;
		case 9: // ╙
			[gSymbolDualLinePath[9] moveToPoint:DLPoint(4,2)];
			[gSymbolDualLinePath[9] lineToPoint:DLPoint(1,2)];
			[gSymbolDualLinePath[9] lineToPoint:DLPoint(1,4)];
			[gSymbolDualLinePath[9] moveToPoint:DLPoint(3,2)];
			[gSymbolDualLinePath[9] lineToPoint:DLPoint(3,4)];
			break;
		case 10: // ╚
			[gSymbolDualLinePath[10] moveToPoint:DLPoint(1,4)];
			[gSymbolDualLinePath[10] lineToPoint:DLPoint(1,1)];
			[gSymbolDualLinePath[10] lineToPoint:DLPoint(4,1)];
			[gSymbolDualLinePath[10] moveToPoint:DLPoint(3,4)];
			[gSymbolDualLinePath[10] lineToPoint:DLPoint(3,3)];
			[gSymbolDualLinePath[10] lineToPoint:DLPoint(4,3)];
			break;
		case 11: // ╛
			[gSymbolDualLinePath[11] moveToPoint:DLPoint(2,4)];
			[gSymbolDualLinePath[11] lineToPoint:DLPoint(2,1)];
			[gSymbolDualLinePath[11] lineToPoint:DLPoint(0,1)];
			[gSymbolDualLinePath[11] moveToPoint:DLPoint(2,3)];
			[gSymbolDualLinePath[11] lineToPoint:DLPoint(0,3)];
			break;
		case 12: // ╜
			[gSymbolDualLinePath[12] moveToPoint:DLPoint(0,2)];
			[gSymbolDualLinePath[12] lineToPoint:DLPoint(3,2)];
			[gSymbolDualLinePath[12] lineToPoint:DLPoint(3,4)];
			[gSymbolDualLinePath[12] moveToPoint:DLPoint(1,2)];
			[gSymbolDualLinePath[12] lineToPoint:DLPoint(1,4)];
			break;
		case 13: // ╝
			[gSymbolDualLinePath[13] moveToPoint:DLPoint(0,1)];
			[gSymbolDualLinePath[13] lineToPoint:DLPoint(3,1)];
			[gSymbolDualLinePath[13] lineToPoint:DLPoint(3,4)];
			[gSymbolDualLinePath[13] moveToPoint:DLPoint(0,3)];
			[gSymbolDualLinePath[13] lineToPoint:DLPoint(1,3)];
			[gSymbolDualLinePath[13] lineToPoint:DLPoint(1,4)];
			break;
		case 14: // ╞
			[gSymbolDualLinePath[14] moveToPoint:DLPoint(2,0)];
			[gSymbolDualLinePath[14] lineToPoint:DLPoint(2,4)];
			[gSymbolDualLinePath[14] moveToPoint:DLPoint(2,1)];
			[gSymbolDualLinePath[14] lineToPoint:DLPoint(4,1)];
			[gSymbolDualLinePath[14] moveToPoint:DLPoint(2,3)];
			[gSymbolDualLinePath[14] lineToPoint:DLPoint(4,3)];
			break;
		case 15: // ╟
			[gSymbolDualLinePath[15] moveToPoint:DLPoint(1,0)];
			[gSymbolDualLinePath[15] lineToPoint:DLPoint(1,4)];
			[gSymbolDualLinePath[15] moveToPoint:DLPoint(3,0)];
			[gSymbolDualLinePath[15] lineToPoint:DLPoint(3,4)];
			[gSymbolDualLinePath[15] moveToPoint:DLPoint(3,2)];
			[gSymbolDualLinePath[15] lineToPoint:DLPoint(4,2)];
			break;
		case 16: // ╠
			[gSymbolDualLinePath[16] moveToPoint:DLPoint(1,0)];
			[gSymbolDualLinePath[16] lineToPoint:DLPoint(1,4)];
			[gSymbolDualLinePath[16] moveToPoint:DLPoint(3,0)];
			[gSymbolDualLinePath[16] lineToPoint:DLPoint(3,1)];
			[gSymbolDualLinePath[16] lineToPoint:DLPoint(4,1)];
			[gSymbolDualLinePath[16] moveToPoint:DLPoint(3,4)];
			[gSymbolDualLinePath[16] lineToPoint:DLPoint(3,3)];
			[gSymbolDualLinePath[16] lineToPoint:DLPoint(4,3)];
			break;
		case 17: // ╡
			[gSymbolDualLinePath[17] moveToPoint:DLPoint(2,0)];
			[gSymbolDualLinePath[17] lineToPoint:DLPoint(2,4)];
			[gSymbolDualLinePath[17] moveToPoint:DLPoint(0,1)];
			[gSymbolDualLinePath[17] lineToPoint:DLPoint(2,1)];
			[gSymbolDualLinePath[17] moveToPoint:DLPoint(0,3)];
			[gSymbolDualLinePath[17] lineToPoint:DLPoint(2,3)];
			break;
		case 18: // ╢
			[gSymbolDualLinePath[18] moveToPoint:DLPoint(1,0)];
			[gSymbolDualLinePath[18] lineToPoint:DLPoint(1,4)];
			[gSymbolDualLinePath[18] moveToPoint:DLPoint(3,0)];
			[gSymbolDualLinePath[18] lineToPoint:DLPoint(3,4)];
			[gSymbolDualLinePath[18] moveToPoint:DLPoint(0,2)];
			[gSymbolDualLinePath[18] lineToPoint:DLPoint(1,2)];
			break;
		case 19: // ╣
			[gSymbolDualLinePath[19] moveToPoint:DLPoint(3,0)];
			[gSymbolDualLinePath[19] lineToPoint:DLPoint(3,4)];
			[gSymbolDualLinePath[19] moveToPoint:DLPoint(1,0)];
			[gSymbolDualLinePath[19] lineToPoint:DLPoint(1,1)];
			[gSymbolDualLinePath[19] lineToPoint:DLPoint(0,1)];
			[gSymbolDualLinePath[19] moveToPoint:DLPoint(0,3)];
			[gSymbolDualLinePath[19] lineToPoint:DLPoint(1,3)];
			[gSymbolDualLinePath[19] lineToPoint:DLPoint(1,4)];
			break;
		case 20: // ╤
			[gSymbolDualLinePath[20] moveToPoint:DLPoint(0,3)];
			[gSymbolDualLinePath[20] lineToPoint:DLPoint(4,3)];
			[gSymbolDualLinePath[20] moveToPoint:DLPoint(0,1)];
			[gSymbolDualLinePath[20] lineToPoint:DLPoint(4,1)];
			[gSymbolDualLinePath[20] moveToPoint:DLPoint(2,1)];
			[gSymbolDualLinePath[20] lineToPoint:DLPoint(2,0)];
			break;
		case 21: // ╥
			[gSymbolDualLinePath[21] moveToPoint:DLPoint(0,2)];
			[gSymbolDualLinePath[21] lineToPoint:DLPoint(4,2)];
			[gSymbolDualLinePath[21] moveToPoint:DLPoint(1,2)];
			[gSymbolDualLinePath[21] lineToPoint:DLPoint(1,0)];
			[gSymbolDualLinePath[21] moveToPoint:DLPoint(3,2)];
			[gSymbolDualLinePath[21] lineToPoint:DLPoint(3,0)];
			break;
		case 22: // ╦
			[gSymbolDualLinePath[22] moveToPoint:DLPoint(0,3)];
			[gSymbolDualLinePath[22] lineToPoint:DLPoint(4,3)];
			[gSymbolDualLinePath[22] moveToPoint:DLPoint(0,1)];
			[gSymbolDualLinePath[22] lineToPoint:DLPoint(1,1)];
			[gSymbolDualLinePath[22] lineToPoint:DLPoint(1,0)];
			[gSymbolDualLinePath[22] moveToPoint:DLPoint(3,0)];
			[gSymbolDualLinePath[22] lineToPoint:DLPoint(3,1)];
			[gSymbolDualLinePath[22] lineToPoint:DLPoint(4,1)];
			break;
		case 23: // ╧
			[gSymbolDualLinePath[23] moveToPoint:DLPoint(0,1)];
			[gSymbolDualLinePath[23] lineToPoint:DLPoint(4,1)];
			[gSymbolDualLinePath[23] moveToPoint:DLPoint(0,3)];
			[gSymbolDualLinePath[23] lineToPoint:DLPoint(4,3)];
			[gSymbolDualLinePath[23] moveToPoint:DLPoint(2,3)];
			[gSymbolDualLinePath[23] lineToPoint:DLPoint(2,4)];
			break;
		case 24: // ╨
			[gSymbolDualLinePath[24] moveToPoint:DLPoint(0,2)];
			[gSymbolDualLinePath[24] lineToPoint:DLPoint(4,2)];
			[gSymbolDualLinePath[24] moveToPoint:DLPoint(1,2)];
			[gSymbolDualLinePath[24] lineToPoint:DLPoint(1,4)];
			[gSymbolDualLinePath[24] moveToPoint:DLPoint(3,2)];
			[gSymbolDualLinePath[24] lineToPoint:DLPoint(3,4)];
			break;
		case 25: // ╩
			[gSymbolDualLinePath[25] moveToPoint:DLPoint(0,1)];
			[gSymbolDualLinePath[25] lineToPoint:DLPoint(4,1)];
			[gSymbolDualLinePath[25] moveToPoint:DLPoint(0,3)];
			[gSymbolDualLinePath[25] lineToPoint:DLPoint(1,3)];
			[gSymbolDualLinePath[25] lineToPoint:DLPoint(1,4)];
			[gSymbolDualLinePath[25] moveToPoint:DLPoint(3,4)];
			[gSymbolDualLinePath[25] lineToPoint:DLPoint(3,3)];
			[gSymbolDualLinePath[25] lineToPoint:DLPoint(4,3)];
			break;
		case 26: // ╪
			[gSymbolDualLinePath[26] moveToPoint:DLPoint(0,1)];
			[gSymbolDualLinePath[26] lineToPoint:DLPoint(4,1)];
			[gSymbolDualLinePath[26] moveToPoint:DLPoint(0,3)];
			[gSymbolDualLinePath[26] lineToPoint:DLPoint(4,3)];
			[gSymbolDualLinePath[26] moveToPoint:DLPoint(2,0)];
			[gSymbolDualLinePath[26] lineToPoint:DLPoint(2,4)];
			break;
		case 27: // ╫
			[gSymbolDualLinePath[27] moveToPoint:DLPoint(0,2)];
			[gSymbolDualLinePath[27] lineToPoint:DLPoint(4,2)];
			[gSymbolDualLinePath[27] moveToPoint:DLPoint(1,0)];
			[gSymbolDualLinePath[27] lineToPoint:DLPoint(1,4)];
			[gSymbolDualLinePath[27] moveToPoint:DLPoint(3,0)];
			[gSymbolDualLinePath[27] lineToPoint:DLPoint(3,4)];
			break;
		case 28: // ╬
			[gSymbolDualLinePath[28] moveToPoint:DLPoint(0,1)];
			[gSymbolDualLinePath[28] lineToPoint:DLPoint(1,1)];
			[gSymbolDualLinePath[28] lineToPoint:DLPoint(1,0)];
			[gSymbolDualLinePath[28] moveToPoint:DLPoint(3,0)];
			[gSymbolDualLinePath[28] lineToPoint:DLPoint(3,1)];
			[gSymbolDualLinePath[28] lineToPoint:DLPoint(4,1)];
			[gSymbolDualLinePath[28] moveToPoint:DLPoint(4,3)];
			[gSymbolDualLinePath[28] lineToPoint:DLPoint(3,3)];
			[gSymbolDualLinePath[28] lineToPoint:DLPoint(3,4)];
			[gSymbolDualLinePath[28] moveToPoint:DLPoint(1,4)];
			[gSymbolDualLinePath[28] lineToPoint:DLPoint(1,3)];
			[gSymbolDualLinePath[28] lineToPoint:DLPoint(0,3)];
			break;
		default:
			break;
	}
#undef DLPoint
	
	return gSymbolDualLinePath[index];
}

- (NSBezierPath *)arcPathWithIndex:(NSUInteger)index {
	if (gSymbolArcPath[index])
		return gSymbolArcPath[index];
	
	// Create Arc Path
	NSPoint pts[4] = {
		NSMakePoint(_fontWidth*2, _fontHeight/2),
		NSMakePoint(_fontWidth, 0),
		NSMakePoint(0, _fontHeight/2),
		NSMakePoint(_fontWidth, _fontHeight)
	};
	
	gSymbolArcPath[index] = [[NSBezierPath alloc] init];
	[gSymbolArcPath[index] setLineWidth:2.0];
	[gSymbolArcPath[index] moveToPoint:pts[index]];
	[gSymbolArcPath[index] appendBezierPathWithArcFromPoint:NSMakePoint(_fontWidth, _fontHeight/2) 
													toPoint:pts[(index+1)%4] 
													 radius:_fontWidth];
	return gSymbolArcPath[index];
}

- (void)resetDualLinePath {
	for (int i = 0; i < 29; ++i) {
		if (gSymbolDualLinePath[i])
			[gSymbolDualLinePath[i] release];
		gSymbolDualLinePath[i] = nil;
	}
}

- (void)resetArcPath {
	for (int i = 0; i < 4; ++i) {
		if (gSymbolArcPath[i])
			[gSymbolArcPath[i] release];
		gSymbolArcPath[i] = nil;
	}
}

- (void)createSymbolPath {
	int i = 0;
	gSymbolBlackSquareRectL = NSMakeRect(1.0, 1.0, _fontWidth - 1, _fontHeight - 2); 
	gSymbolBlackSquareRectR = NSMakeRect(_fontWidth, 1.0, _fontWidth - 1, _fontHeight - 2);
	
	for (i = 0; i < 8; i++) {
        gSymbolLowerBlockRectL[i] = NSMakeRect(0.0, 0.0, _fontWidth, _fontHeight * (i + 1) / 8);
        gSymbolLowerBlockRectR[i] = NSMakeRect(_fontWidth, 0.0, _fontWidth, _fontHeight * (i + 1) / 8);
	}
    
    for (i = 0; i < 7; i++) {
        gSymbolLeftBlockRectL[i] = NSMakeRect(0.0, 0.0, (7 - i >= 4) ? _fontWidth : (_fontWidth * (7 - i) / 4), _fontHeight);
        gSymbolLeftBlockRectR[i] = NSMakeRect(_fontWidth, 0.0, (7 - i <= 4) ? 0.0 : (_fontWidth * (3 - i) / 4), _fontHeight);
    }
    
    NSPoint pts[6] = {
        NSMakePoint(_fontWidth, 0.0),
        NSMakePoint(0.0, 0.0),
        NSMakePoint(0.0, _fontHeight),
        NSMakePoint(_fontWidth, _fontHeight),
        NSMakePoint(_fontWidth * 2, _fontHeight),
        NSMakePoint(_fontWidth * 2, 0.0),
    };
    int triangleIndexL[4][3] = { {0, 1, -1}, {0, 1, 2}, {1, 2, 3}, {2, 3, -1} };
    int triangleIndexR[4][3] = { {4, 5, 0}, {5, 0, -1}, {3, 4, -1}, {3, 4, 5} };
    
    int base = 0;
    for (base = 0; base < 4; base++) {
        if (gSymbolTrianglePathL[base])
            [gSymbolTrianglePathL[base] release];
        gSymbolTrianglePathL[base] = [[NSBezierPath alloc] init];
        [gSymbolTrianglePathL[base] moveToPoint:NSMakePoint(_fontWidth, _fontHeight / 2)];
        for (i = 0; i < 3 && triangleIndexL[base][i] >= 0; i++)
            [gSymbolTrianglePathL[base] lineToPoint:pts[triangleIndexL[base][i]]];
        [gSymbolTrianglePathL[base] closePath];
        
        if (gSymbolTrianglePathR[base])
            [gSymbolTrianglePathR[base] release];
        gSymbolTrianglePathR[base] = [[NSBezierPath alloc] init];
        [gSymbolTrianglePathR[base] moveToPoint: NSMakePoint(_fontWidth, _fontHeight / 2)];
        for (i = 0; i < 3 && triangleIndexR[base][i] >= 0; i++)
            [gSymbolTrianglePathR[base] lineToPoint:pts[triangleIndexR[base][i]]];
        [gSymbolTrianglePathR[base] closePath];
    }
	
	// Extended
	int diagonalIndexL[2] = { 1, 2 };
	int diagonalIndexR[2] = { 4, 5 };
	for (base = 0; base < 2; base++) {
		if (gSymbolDiagonalPathL[base])
			[gSymbolDiagonalPathL[base] release];
		gSymbolDiagonalPathL[base] = [[NSBezierPath alloc] init];
		[gSymbolDiagonalPathL[base] moveToPoint:NSMakePoint(_fontWidth, _fontHeight / 2)];
		[gSymbolDiagonalPathL[base] setLineWidth:2.0];
		[gSymbolDiagonalPathL[base] lineToPoint:pts[diagonalIndexL[base]]];
		
		if (gSymbolDiagonalPathR[base])
			[gSymbolDiagonalPathR[base] release];
		gSymbolDiagonalPathR[base] = [[NSBezierPath alloc] init];
		[gSymbolDiagonalPathR[base] moveToPoint:NSMakePoint(_fontWidth, _fontHeight / 2)];
		[gSymbolDiagonalPathR[base] setLineWidth:2.0];
		[gSymbolDiagonalPathR[base] lineToPoint:pts[diagonalIndexR[base]]];
	}
	
	if (gSymbolDiagonalPathL[2])
		[gSymbolDiagonalPathL[2] release];
	gSymbolDiagonalPathL[2] = [[NSBezierPath alloc] init];
	[gSymbolDiagonalPathL[2] setLineWidth:2.0];
	[gSymbolDiagonalPathL[2] appendBezierPath:gSymbolDiagonalPathL[0]];
	[gSymbolDiagonalPathL[2] appendBezierPath:gSymbolDiagonalPathL[1]];
	
	if (gSymbolDiagonalPathR[2])
		[gSymbolDiagonalPathR[2] release];
	gSymbolDiagonalPathR[2] = [[NSBezierPath alloc] init];
	[gSymbolDiagonalPathR[2] setLineWidth:2.0];
	[gSymbolDiagonalPathR[2] appendBezierPath:gSymbolDiagonalPathR[0]];
	[gSymbolDiagonalPathR[2] appendBezierPath:gSymbolDiagonalPathR[1]];
	
	[self resetDualLinePath];
	[self resetArcPath];
}

- (void)configure {
    if (!gConfig) 
		gConfig = [WLGlobalConfig sharedInstance];
	_maxColumn = [gConfig column];
	_maxRow = [gConfig row];
    _fontWidth = [gConfig cellWidth];
    _fontHeight = [gConfig cellHeight];
	
	if (gLeftImage)
		[gLeftImage release];
    gLeftImage = [[NSImage alloc] initWithSize:NSMakeSize(_fontWidth, _fontHeight)];			
	
    [self createSymbolPath];
}

- (id)init {
	if (self = [super init]) {
		[self configure];
	}
	return self;
}

+ (BOOL)isAsciiArtSymbol:(unichar)ch {
	if (ch == 0x25FC)  // ◼ BLACK SQUARE
		return YES;
	if (ch >= 0x2581 && ch <= 0x2588) // BLOCK ▁▂▃▄▅▆▇█
		return YES;
	if (ch >= 0x2589 && ch <= 0x258F) // BLOCK ▉▊▋▌▍▎▏
		return YES;
	if (ch >= 0x25E2 && ch <= 0x25E5) // TRIANGLE ◢◣◤◥
		return YES;
	if (ch >= 0x2571 && ch <= 0x2573) // DIAGONAL ╱╲╳
		return YES;
	if (ch >= 0x2550 && ch <= 0x256C) // DUAL LINE
		return YES;
	if (ch >= 0x256D && ch <= 0x2570) // CIRCLE ╭╮╯╰
		return YES;
	return NO;
}

- (void)drawSymbol:(NSObject *)symbol 
	  withSelector:(SEL)selector	   
	 leftAttribute:(attribute)attrL 
	rightAttribute:(attribute)attrR {
	int colorIndexL = fgColorIndexOfAttribute(attrL);
	int colorIndexR = fgColorIndexOfAttribute(attrR);
	NSColor *colorR = [gConfig colorAtIndex:colorIndexR hilite:fgBoldOfAttribute(attrR)];
	
	[colorR set];
	[symbol performSelector:selector];
	if (colorIndexL != colorIndexR || fgBoldOfAttribute(attrL) != fgBoldOfAttribute(attrR)) {
		NSColor *colorL = [gConfig colorAtIndex:fgColorIndexOfAttribute(attrL) hilite:fgBoldOfAttribute(attrL)];
		[gLeftImage lockFocus];
		[[gConfig colorAtIndex:bgColorIndexOfAttribute(attrL) hilite:bgBoldOfAttribute(attrL)] set];
		NSRect rect;
		rect.size = [gLeftImage size];
		rect.origin = NSZeroPoint;
		NSRectFill(rect);
		
		[colorL set];
		[symbol performSelector:selector];
		[gLeftImage unlockFocus];
		[gLeftImage drawAtPoint:NSZeroPoint
					   fromRect:rect
					  operation:NSCompositeCopy
					   fraction:1.0];		
	}
}

- (void)drawSpecialSymbol:(unichar)ch 
				   forRow:(int)r 
				   column:(int)c 
			leftAttribute:(attribute)attrL 
		   rightAttribute:(attribute)attrR {
	int colorIndexL = fgColorIndexOfAttribute(attrL);
	int colorIndexR = fgColorIndexOfAttribute(attrR);
	NSPoint origin = NSMakePoint(c * _fontWidth, (_maxRow - 1 - r) * _fontHeight);
	
	NSAffineTransform *xform = [NSAffineTransform transform]; 
	[xform translateXBy:origin.x yBy:origin.y];
	[xform concat];
	
	NSColor *colorL = [gConfig colorAtIndex:colorIndexL hilite:fgBoldOfAttribute(attrL)];
	NSColor *colorR = [gConfig colorAtIndex:colorIndexR hilite:fgBoldOfAttribute(attrR)];
	if (ch == 0x25FC) { // ◼ BLACK SQUARE
		[colorL set];
		NSRectFill(gSymbolBlackSquareRectL);
		[colorR set];
		NSRectFill(gSymbolBlackSquareRectR);
	} else if (ch >= 0x2581 && ch <= 0x2588) { // BLOCK ▁▂▃▄▅▆▇█
		[colorL set];
		NSRectFill(gSymbolLowerBlockRectL[ch - 0x2581]);
		[colorR set];
		NSRectFill(gSymbolLowerBlockRectR[ch - 0x2581]);
	} else if (ch >= 0x2589 && ch <= 0x258F) { // BLOCK ▉▊▋▌▍▎▏
		[colorL set];
		NSRectFill(gSymbolLeftBlockRectL[ch - 0x2589]);
		if (ch <= 0x259B) {
			[colorR set];
			NSRectFill(gSymbolLeftBlockRectR[ch - 0x2589]);
		}
	} else if (ch >= 0x25E2 && ch <= 0x25E5) { // TRIANGLE ◢◣◤◥
		[colorL set];
		[gSymbolTrianglePathL[ch - 0x25E2] fill];
		[colorR set];
		[gSymbolTrianglePathR[ch - 0x25E2] fill];
	} else if (ch >= 0x2571 && ch <= 0x2573) { // DIAGONAL ╱╲╳
		[colorL set];
		[gSymbolDiagonalPathL[ch - 0x2571] stroke];
		[colorR set];
		[gSymbolDiagonalPathR[ch - 0x2571] stroke];
	} else if (ch >= 0x2550 && ch <= 0x256c) { // DUAL LINE
		[self drawSymbol:[self dualLinePathWithIndex:(ch-0x2550)]
			withSelector:@selector(stroke) 
		   leftAttribute:attrL 
		  rightAttribute:attrR];
	} else if (ch >= 0x256d && ch <= 0x2570) { // ARC
		[self drawSymbol:[self arcPathWithIndex:(ch-0x256d)]
			withSelector:@selector(stroke) 
		   leftAttribute:attrL 
		  rightAttribute:attrR];
	}
	
	[xform invert];
	[xform concat];
}

@end
