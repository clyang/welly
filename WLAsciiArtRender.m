//
//  WLAsciiArtRender.m
//  Welly
//
//  Created by K.O.ed on 10-6-25.
//  Copyright 2010 Welly Group. All rights reserved.
//

#import "WLAsciiArtRender.h"
#import "WLGlobalConfig.h"

static WLGlobalConfig *gConfig;
static NSImage *gLeftImage;
static NSImage *gSymbolImage;

static NSRect gSymbolBlackSquareRectL;
static NSRect gSymbolBlackSquareRectR;
static NSRect gSymbolLowerBlockRectL[8];
static NSRect gSymbolLowerBlockRectR[8];
static NSRect gSymbolLeftBlockRectL[7];
static NSRect gSymbolLeftBlockRectR[7];
static NSBezierPath *gSymbolTrianglePathL[4];
static NSBezierPath *gSymbolTrianglePathR[4];

// Extended Ascii Art support
static NSBezierPath *gSymbolDiagonalPath[3];

static NSBezierPath *gSymbolDualLinePath[29];
static NSBezierPath *gSymbolArcPath[4];

static NSBezierPath *gSymbolSingleLinePathComponent[4][3];

static NSBezierPath *gSymbolStraightLinePath[4];

static NSRect gSymbolRightBlockRect;
static NSRect gSymbolUpperBlockRectL;
static NSRect gSymbolUpperBlockRectR;

static NSBezierPath *gSymbolUpperLinePath;
static NSBezierPath *gSymbolLeftLinePath;
static NSBezierPath *gSymbolLowerLinePath;

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

- (NSBezierPath *)straightLineWithIndex:(NSUInteger)index {
	return gSymbolStraightLinePath[index];
}

- (void)rebuildDualLinePath {
	for (int i = 0; i < 29; ++i) {
		if (gSymbolDualLinePath[i])
			[gSymbolDualLinePath[i] release];
		gSymbolDualLinePath[i] = nil;
	}
}

- (void)rebuildArcPath {
	for (int i = 0; i < 4; ++i) {
		if (gSymbolArcPath[i])
			[gSymbolArcPath[i] release];
		gSymbolArcPath[i] = nil;
	}
}

- (void)rebuildSingleLinePathComponent {
	NSPoint pts[4] = {
		NSMakePoint(_fontWidth*2, _fontHeight/2),
		NSMakePoint(_fontWidth, 0),
		NSMakePoint(0, _fontHeight/2),
		NSMakePoint(_fontWidth, _fontHeight)
	};
	
	NSPoint mid = NSMakePoint(_fontWidth, _fontHeight/2);
	
	for (int i = 0; i < 4; ++i) {
		if (!gSymbolSingleLinePathComponent[i][0])
			gSymbolSingleLinePathComponent[i][0] = [[NSBezierPath alloc] init];
		for (int j = 1; j < 3; ++j) {
			if (gSymbolSingleLinePathComponent[i][j])
				[gSymbolSingleLinePathComponent[i][j] release];
			gSymbolSingleLinePathComponent[i][j] = [[NSBezierPath alloc] init];
			[gSymbolSingleLinePathComponent[i][j] setLineWidth:(j-1)+2.0];
			[gSymbolSingleLinePathComponent[i][j] setLineCapStyle:NSSquareLineCapStyle];
			[gSymbolSingleLinePathComponent[i][j] moveToPoint:mid];
			[gSymbolSingleLinePathComponent[i][j] lineToPoint:pts[i]];
		}
	}
}

- (void)rebuildStraightLinePath {
	for (int i = 0; i < 4; ++i) {
		if (gSymbolStraightLinePath[i]) {
			[gSymbolStraightLinePath[i] release];
		}
		gSymbolStraightLinePath[i] = [[NSBezierPath alloc] init];
	}
	
	NSPoint pts[4] = {
		NSMakePoint(_fontWidth*2, _fontHeight/2),
		NSMakePoint(_fontWidth, 0),
		NSMakePoint(0, _fontHeight/2),
		NSMakePoint(_fontWidth, _fontHeight)
	};
	[gSymbolStraightLinePath[0] moveToPoint:pts[0]];
	[gSymbolStraightLinePath[0] lineToPoint:pts[2]];
	[gSymbolStraightLinePath[0] setLineWidth:2.0];
	
	[gSymbolStraightLinePath[1] appendBezierPath:gSymbolStraightLinePath[0]];
	[gSymbolStraightLinePath[1] setLineWidth:3.0];
	
	[gSymbolStraightLinePath[2] moveToPoint:pts[1]];
	[gSymbolStraightLinePath[2] lineToPoint:pts[3]];
	[gSymbolStraightLinePath[2] setLineWidth:2.0];
	
	[gSymbolStraightLinePath[3] appendBezierPath:gSymbolStraightLinePath[2]];
	[gSymbolStraightLinePath[3] setLineWidth:3.0];
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
	
	gSymbolRightBlockRect = NSMakeRect(_fontWidth*7/4, 0, _fontWidth/4, _fontHeight);
	gSymbolUpperBlockRectL = NSMakeRect(0, _fontHeight*7/8, _fontWidth, _fontHeight/8);
	gSymbolUpperBlockRectR = NSMakeRect(_fontWidth, _fontHeight*7/8, _fontWidth, _fontHeight/8);
    
    NSPoint pts[6] = {
        NSMakePoint(_fontWidth, 0.0),
        NSMakePoint(0.0, 0.0),
        NSMakePoint(0.0, _fontHeight),
        NSMakePoint(_fontWidth, _fontHeight),
        NSMakePoint(_fontWidth*2, _fontHeight),
        NSMakePoint(_fontWidth*2, 0.0),
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
	for (int i = 0; i < 3; ++i) {
		if (gSymbolDiagonalPath[i])
			[gSymbolDiagonalPath[i] release];		
	}
	gSymbolDiagonalPath[0] = [[NSBezierPath alloc] init];
	[gSymbolDiagonalPath[0] setLineWidth:2.0];
	[gSymbolDiagonalPath[0] moveToPoint:NSMakePoint(0, 0)];
	[gSymbolDiagonalPath[0] lineToPoint:NSMakePoint(_fontWidth*2, _fontHeight)];
	
	gSymbolDiagonalPath[1] = [[NSBezierPath alloc] init];
	[gSymbolDiagonalPath[1] setLineWidth:2.0];
	[gSymbolDiagonalPath[1] moveToPoint:NSMakePoint(0, _fontHeight)];
	[gSymbolDiagonalPath[1] lineToPoint:NSMakePoint(_fontWidth*2, 0)];
	
	gSymbolDiagonalPath[2] = [[NSBezierPath alloc] init];
	[gSymbolDiagonalPath[2] setLineWidth:2.0];
	[gSymbolDiagonalPath[2] appendBezierPath:gSymbolDiagonalPath[0]];
	[gSymbolDiagonalPath[2] appendBezierPath:gSymbolDiagonalPath[1]];
	
	// Border Lines
	if (gSymbolUpperLinePath)
		[gSymbolUpperLinePath removeAllPoints];
	else {
		gSymbolUpperLinePath = [[NSBezierPath alloc] init];
		[gSymbolUpperLinePath setLineWidth:2.0];
	}
	[gSymbolUpperLinePath moveToPoint:NSMakePoint(0, _fontHeight-1)];
	[gSymbolUpperLinePath lineToPoint:NSMakePoint(_fontWidth*2, _fontHeight-1)];
	
	if (gSymbolLowerLinePath)
		[gSymbolLowerLinePath removeAllPoints];
	else {
		gSymbolLowerLinePath = [[NSBezierPath alloc] init];
		[gSymbolLowerLinePath setLineWidth:2.0];
	}
	[gSymbolLowerLinePath moveToPoint:NSMakePoint(0, 1)];
	[gSymbolLowerLinePath lineToPoint:NSMakePoint(_fontWidth*2, 1)];
	
	if (gSymbolLeftLinePath)
		[gSymbolLeftLinePath removeAllPoints];
	else {
		gSymbolLeftLinePath = [[NSBezierPath alloc] init];
		[gSymbolLeftLinePath setLineWidth:2.0];
	}
	[gSymbolLeftLinePath moveToPoint:NSMakePoint(1, 0)];
	[gSymbolLeftLinePath lineToPoint:NSMakePoint(1, _fontHeight)];
	
	[self rebuildDualLinePath];
	[self rebuildArcPath];
	[self rebuildSingleLinePathComponent];
	[self rebuildStraightLinePath];
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
	
	if (gSymbolImage)
		[gSymbolImage release];
	gSymbolImage = [[NSImage alloc] initWithSize:NSMakeSize(_fontWidth*2, _fontHeight)];
	
    [self createSymbolPath];
}

- (id)init {
	if ((self = [super init])) {
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
	if (ch == 0x2595 || ch == 0x2594) // ▔ ▕
		return YES;
	if (ch >= 0x25E2 && ch <= 0x25E5) // TRIANGLE ◢◣◤◥
		return YES;
	if (ch >= 0x2571 && ch <= 0x2573) // DIAGONAL ╱╲╳
		return YES;
	if (ch >= 0x2550 && ch <= 0x256C) // DUAL LINE
		return YES;
	if (ch >= 0x256D && ch <= 0x2570) // CIRCLE ╭╮╯╰
		return YES;
	if (ch >= 0x250C && ch <= 0x254B) // SINGLE LINE
		return YES;
	if (ch >= 0x2500 && ch <= 0x2503) // STRAIGHT LINE ─ ━ │ ┃
		return YES;
	if (ch == 0x2014) // —
		return YES;
	if (ch == 0xffe3 || ch == 0xfe33 || ch == 0xff3f ||
		ch == 0xff0f || ch == 0xfe68 || ch == 0xff3c)
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
		[[gConfig bgColorAtIndex:bgColorIndexOfAttribute(attrL) hilite:bgBoldOfAttribute(attrL)] set];
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

- (void)drawSingleLineSymbol:(unichar)ch 
			   leftAttribute:(attribute)attrL 
			  rightAttribute:(attribute)attrR {
	static const unsigned int singleLineWidth[64][4] = {
		{1,1,0,0},{2,1,0,0},{1,2,0,0},{2,2,0,0}, // ┌ ┍ ┎ ┏
		{0,1,1,0},{0,1,2,0},{0,2,1,0},{0,2,2,0}, // ┐ ┑ ┒ ┓
		{1,0,0,1},{2,0,0,1},{1,0,0,2},{2,0,0,2}, // └ ┕ ┖ ┗
		{0,0,1,1},{0,0,2,1},{0,0,1,2},{0,0,2,2}, // ┘ ┙ ┚ ┛
		// ├ ┝ ┞ ┟ ┠ ┡ ┢ ┣
		{1,1,0,1},{2,1,0,1},{1,1,0,2},{1,2,0,1},{1,2,0,2},{2,1,0,2},{2,2,0,1},{2,2,0,2},
		// ┤ ┥ ┦ ┧ ┨ ┩ ┪ ┫
		{0,1,1,1},{0,1,2,1},{0,1,1,2},{0,2,1,1},{0,2,1,2},{0,1,2,2},{0,2,2,1},{0,2,2,2},
		// ┬ ┭ ┮ ┯ ┰ ┱ ┲ ┳
		{1,1,1,0},{1,1,2,0},{2,1,1,0},{2,1,2,0},{1,2,1,0},{1,2,2,0},{2,2,1,0},{2,2,2,0},
		// ┴ ┵ ┶ ┷ ┸ ┹ ┺ ┻
		{1,0,1,1},{1,0,2,1},{2,0,1,1},{2,0,2,1},{1,0,1,2},{1,0,2,2},{2,0,1,2},{2,0,2,2},
		// ┼ ┽ ┾ ┿ ╀ ╁ ╂ ╃ ╄ ╅ ╆ ╇ ╈ ╉ ╊ ╋
		{1,1,1,1},{1,1,2,1},{2,1,1,1},{2,1,2,1},{1,1,1,2},{1,2,1,1},{1,2,1,2},{1,1,2,2},
		{2,1,1,2},{1,2,2,1},{2,2,1,1},{2,1,2,2},{2,2,2,1},{1,2,2,2},{2,2,1,2},{2,2,2,2}
	};
	NSUInteger index = ch - 0x250c;
	int colorIndexL = fgColorIndexOfAttribute(attrL);
	int colorIndexR = fgColorIndexOfAttribute(attrR);
	NSColor *colorR = [gConfig colorAtIndex:colorIndexR hilite:fgBoldOfAttribute(attrR)];
	
	[gSymbolImage lockFocus];
	[[gConfig bgColorAtIndex:bgColorIndexOfAttribute(attrR) hilite:bgBoldOfAttribute(attrR)] set];
	NSRect rect;
	rect.size = [gSymbolImage size];
	rect.origin = NSZeroPoint;
	NSRectFill(rect);
	[colorR set];
	for (int i = 0; i < 4; ++i) {
		[gSymbolSingleLinePathComponent[i][singleLineWidth[index][i]] stroke];
	}
	[gSymbolImage unlockFocus];
	[gSymbolImage drawAtPoint:NSZeroPoint
					 fromRect:rect
					operation:NSCompositeCopy
					 fraction:1.0];
	
	if (colorIndexL != colorIndexR || fgBoldOfAttribute(attrL) != fgBoldOfAttribute(attrR)) {
		NSColor *colorL = [gConfig colorAtIndex:fgColorIndexOfAttribute(attrL) hilite:fgBoldOfAttribute(attrL)];
		[gLeftImage lockFocus];
		[[gConfig bgColorAtIndex:bgColorIndexOfAttribute(attrL) hilite:bgBoldOfAttribute(attrL)] set];
		NSRect rect;
		rect.size = [gLeftImage size];
		rect.origin = NSZeroPoint;
		NSRectFill(rect);
		
		[colorL set];
		for (int i = 1; i < 4; ++i) { // No need to draw 0-th component since it is fully in right half
			[gSymbolSingleLinePathComponent[i][singleLineWidth[index][i]] stroke];
		}
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
	} else if (ch == 0x2594) {
		[colorL set];
		NSRectFill(gSymbolUpperBlockRectL);
		[colorR set];
		NSRectFill(gSymbolUpperBlockRectR);
	} else if (ch == 0x2595) {
		[colorR set];
		NSRectFill(gSymbolRightBlockRect);
	} else if (ch >= 0x25E2 && ch <= 0x25E5) { // TRIANGLE ◢◣◤◥
		[colorL set];
		[gSymbolTrianglePathL[ch - 0x25E2] fill];
		[colorR set];
		[gSymbolTrianglePathR[ch - 0x25E2] fill];
	} else if (ch >= 0x2571 && ch <= 0x2573) { // DIAGONAL ╱╲╳
		[self drawSymbol:gSymbolDiagonalPath[ch-0x2571] 
			withSelector:@selector(stroke)
		   leftAttribute:attrL 
		  rightAttribute:attrR];
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
	} else if (ch >= 0x250c && ch <= 0x254b) { // SINGLE LINE
		[self drawSingleLineSymbol:ch 
					 leftAttribute:attrL 
					rightAttribute:attrR];
	} else if (ch >= 0x2500 && ch <= 0x2503) { // STRAIGHT LINE ─ ━ │ ┃
		[self drawSymbol:[self straightLineWithIndex:ch-0x2500]
			withSelector:@selector(stroke) 
		   leftAttribute:attrL 
		  rightAttribute:attrR];
	} else if (ch == 0x2014) {
		[self drawSymbol:[self straightLineWithIndex:0]
			withSelector:@selector(stroke) 
		   leftAttribute:attrL 
		  rightAttribute:attrR];
	} else if (ch == 0xfe33) { // ︳
		[self drawSymbol:gSymbolLeftLinePath 
			withSelector:@selector(stroke) 
		   leftAttribute:attrL 
		  rightAttribute:attrR];
	} else if (ch == 0xffe3) { // ￣
		[self drawSymbol:gSymbolUpperLinePath 
			withSelector:@selector(stroke) 
		   leftAttribute:attrL 
		  rightAttribute:attrR];
	} else if (ch == 0xff3f) { // ＿
		[self drawSymbol:gSymbolLowerLinePath 
			withSelector:@selector(stroke) 
		   leftAttribute:attrL 
		  rightAttribute:attrR];
	} else if (ch == 0xff0f) { // ／
		[self drawSymbol:gSymbolDiagonalPath[0] 
			withSelector:@selector(stroke)
		   leftAttribute:attrL 
		  rightAttribute:attrR];
	} else if (ch == 0xfe68 || ch == 0xff3c) { // ﹨ ＼
		[self drawSymbol:gSymbolDiagonalPath[1] 
			withSelector:@selector(stroke)
		   leftAttribute:attrL 
		  rightAttribute:attrR];
	}
	
	[xform invert];
	[xform concat];
}

@end
