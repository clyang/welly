//
//  WLTermView.m
//  Welly
//
//  Created by K.O.ed on 09-11-2.
//  Copyright 2009 Welly Group. All rights reserved.
//

#import "WLTermView.h"
#import "CommonType.h"
#import "WLGlobalConfig.h"
#import "WLTerminal.h"
#import "WLConnection.h"

static WLGlobalConfig *gConfig;

static NSImage *gLeftImage;
static CGSize *gSingleAdvance;
static CGSize *gDoubleAdvance;

static NSRect gSymbolBlackSquareRect;
static NSRect gSymbolBlackSquareRect1;
static NSRect gSymbolBlackSquareRect2;
static NSRect gSymbolLowerBlockRect[8];
static NSRect gSymbolLowerBlockRect1[8];
static NSRect gSymbolLowerBlockRect2[8];
static NSRect gSymbolLeftBlockRect[7];
static NSRect gSymbolLeftBlockRect1[7];
static NSRect gSymbolLeftBlockRect2[7];
static NSBezierPath *gSymbolTrianglePath[4];
static NSBezierPath *gSymbolTrianglePath1[4];
static NSBezierPath *gSymbolTrianglePath2[4];

@interface WLTermView ()
- (void)drawSpecialSymbol:(unichar)ch 
				   forRow:(int)r 
				   column:(int)c 
			leftAttribute:(attribute)attr1 
		   rightAttribute:(attribute)attr2;
- (void)updateBackgroundForRow:(int)r 
						  from:(int)start 
							to:(int)end;
- (void)drawBlink;
- (void)drawStringForRow:(int)r
				 context:(CGContextRef)myCGContext;
- (void)tick;
@end


@implementation WLTermView

@synthesize fontWidth = _fontWidth;
@synthesize fontHeight = _fontHeight;

#pragma mark -
#pragma mark Initialization & Destruction

- (void)createSymbolPath {
	int i = 0;
	gSymbolBlackSquareRect = NSMakeRect(1.0, 1.0, _fontWidth * 2 - 2, _fontHeight - 2);
	gSymbolBlackSquareRect1 = NSMakeRect(1.0, 1.0, _fontWidth - 1, _fontHeight - 2); 
	gSymbolBlackSquareRect2 = NSMakeRect(_fontWidth, 1.0, _fontWidth - 1, _fontHeight - 2);
	
	for (i = 0; i < 8; i++) {
		gSymbolLowerBlockRect[i] = NSMakeRect(0.0, 0.0, _fontWidth * 2, _fontHeight * (i + 1) / 8);
        gSymbolLowerBlockRect1[i] = NSMakeRect(0.0, 0.0, _fontWidth, _fontHeight * (i + 1) / 8);
        gSymbolLowerBlockRect2[i] = NSMakeRect(_fontWidth, 0.0, _fontWidth, _fontHeight * (i + 1) / 8);
	}
    
    for (i = 0; i < 7; i++) {
        gSymbolLeftBlockRect[i] = NSMakeRect(0.0, 0.0, _fontWidth * (7 - i) / 4, _fontHeight);
        gSymbolLeftBlockRect1[i] = NSMakeRect(0.0, 0.0, (7 - i >= 4) ? _fontWidth : (_fontWidth * (7 - i) / 4), _fontHeight);
        gSymbolLeftBlockRect2[i] = NSMakeRect(_fontWidth, 0.0, (7 - i <= 4) ? 0.0 : (_fontWidth * (3 - i) / 4), _fontHeight);
    }
    
    NSPoint pts[6] = {
        NSMakePoint(_fontWidth, 0.0),
        NSMakePoint(0.0, 0.0),
        NSMakePoint(0.0, _fontHeight),
        NSMakePoint(_fontWidth, _fontHeight),
        NSMakePoint(_fontWidth * 2, _fontHeight),
        NSMakePoint(_fontWidth * 2, 0.0),
    };
    int triangleIndex[4][3] = { {1, 4, 5}, {1, 2, 5}, {1, 2, 4}, {2, 4, 5} };
	
    int triangleIndex1[4][3] = { {0, 1, -1}, {0, 1, 2}, {1, 2, 3}, {2, 3, -1} };
    int triangleIndex2[4][3] = { {4, 5, 0}, {5, 0, -1}, {3, 4, -1}, {3, 4, 5} };
    
    int base = 0;
    for (base = 0; base < 4; base++) {
        if (gSymbolTrianglePath[base]) 
            [gSymbolTrianglePath[base] release];
        gSymbolTrianglePath[base] = [[NSBezierPath alloc] init];
        [gSymbolTrianglePath[base] moveToPoint: pts[triangleIndex[base][0]]];
        for (i = 1; i < 3; i ++)
            [gSymbolTrianglePath[base] lineToPoint: pts[triangleIndex[base][i]]];
        [gSymbolTrianglePath[base] closePath];
        
        if (gSymbolTrianglePath1[base])
            [gSymbolTrianglePath1[base] release];
        gSymbolTrianglePath1[base] = [[NSBezierPath alloc] init];
        [gSymbolTrianglePath1[base] moveToPoint: NSMakePoint(_fontWidth, _fontHeight / 2)];
        for (i = 0; i < 3 && triangleIndex1[base][i] >= 0; i++)
            [gSymbolTrianglePath1[base] lineToPoint: pts[triangleIndex1[base][i]]];
        [gSymbolTrianglePath1[base] closePath];
        
        if (gSymbolTrianglePath2[base])
            [gSymbolTrianglePath2[base] release];
        gSymbolTrianglePath2[base] = [[NSBezierPath alloc] init];
        [gSymbolTrianglePath2[base] moveToPoint: NSMakePoint(_fontWidth, _fontHeight / 2)];
        for (i = 0; i < 3 && triangleIndex2[base][i] >= 0; i++)
            [gSymbolTrianglePath2[base] lineToPoint: pts[triangleIndex2[base][i]]];
        [gSymbolTrianglePath2[base] closePath];
    }
}

- (void)configure {
    if (!gConfig) 
		gConfig = [WLGlobalConfig sharedInstance];
	_maxColumn = [gConfig column];
	_maxRow = [gConfig row];
    _fontWidth = [gConfig cellWidth];
    _fontHeight = [gConfig cellHeight];
	
    NSRect frame = [self frame];
	frame.size = [gConfig contentSize];
    frame.origin = NSZeroPoint;
    [self setFrame:frame];
	
    [self createSymbolPath];
	
    [_backedImage release];
    _backedImage = [[NSImage alloc] initWithSize:frame.size];
    [_backedImage setFlipped:NO];
	
    [gLeftImage release]; 
    gLeftImage = [[NSImage alloc] initWithSize:NSMakeSize(_fontWidth, _fontHeight)];			
	
    if (!gSingleAdvance) gSingleAdvance = (CGSize *) malloc(sizeof(CGSize) * _maxColumn);
    if (!gDoubleAdvance) gDoubleAdvance = (CGSize *) malloc(sizeof(CGSize) * _maxColumn);
	
    for (int i = 0; i < _maxColumn; i++) {
        gSingleAdvance[i] = CGSizeMake(_fontWidth * 1.0, 0.0);
        gDoubleAdvance[i] = CGSizeMake(_fontWidth * 2.0, 0.0);
    }
}

- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self configure];
		
		// Register KVO
		NSArray *observeKeys = [NSArray arrayWithObjects:@"shouldSmoothFonts", @"showsHiddenText", @"cellWidth", @"cellHeight", 
								@"chineseFontName", @"chineseFontSize", @"chineseFontPaddingLeft", @"chineseFontPaddingBottom",
								@"englishFontName", @"englishFontSize", @"englishFontPaddingLeft", @"englishFontPaddingBottom", 
								@"colorBlack", @"colorBlackHilite", @"colorRed", @"colorRedHilite", @"colorGreen", @"colorGreenHilite",
								@"colorYellow", @"colorYellowHilite", @"colorBlue", @"colorBlueHilite", @"colorMagenta", @"colorMagentaHilite", 
								@"colorCyan", @"colorCyanHilite", @"colorWhite", @"colorWhiteHilite", @"colorBG", @"colorBGHilite", nil];
		for (NSString *key in observeKeys)
			[[WLGlobalConfig sharedInstance] addObserver:self
											  forKeyPath:key
												 options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) 
												 context:nil];
		
		// For blink cells
		[NSTimer scheduledTimerWithTimeInterval:1 
										 target:self 
									   selector:@selector(updateBlinkTicker:) 
									   userInfo:nil 
										repeats:YES];
    }
    return self;
}

- (void)dealloc {
    [_backedImage release];
    [super dealloc];
}

#pragma mark -
#pragma mark Accessor
- (WLConnection *)frontMostConnection {
	return _connection;
}

- (WLTerminal *)frontMostTerminal {
	if (!_connection)
		return nil;
    return (WLTerminal *)[[self frontMostConnection] terminal];
}

- (BOOL)isConnected {
	if (!_connection)
		return NO;
	return [[self frontMostConnection] isConnected];
}

- (BOOL)hasBlinkCell {
    int c, r;
    id ds = [self frontMostTerminal];
    if (!ds) return NO;
    for (r = 0; r < _maxRow; r++) {
        [ds updateDoubleByteStateForRow: r];
        cell *currRow = [ds cellsOfRow: r];
        for (c = 0; c < _maxColumn; c++) 
            if (isBlinkCell(currRow[c]))
                return YES;
    }
    return NO;
}

- (void)setFrame:(NSRect)frameRect {
	[super setFrame:frameRect];
	[self refreshDisplay];
}

#pragma mark -
#pragma mark Drawing
- (void)refreshDisplay {
	[[self frontMostTerminal] setAllDirty];
	[self updateBackedImage];
	[self setNeedsDisplay:YES];
}

- (void)refreshHiddenRegion {
    if (![self isConnected]) 
		return;
    int i, j;
    for (i = 0; i < _maxRow; i++) {
        cell *currRow = [[self frontMostTerminal] cellsOfRow:i];
        for (j = 0; j < _maxColumn; j++)
            if (isHiddenAttribute(currRow[j].attr)) 
                [[self frontMostTerminal] setDirty:YES atRow:i column:j];
    }
	[self refreshDisplay];
}

- (void)displayCellAtRow:(int)r 
				  column:(int)c {
    [self setNeedsDisplayInRect:NSMakeRect(c * _fontWidth, (_maxRow - 1 - r) * _fontHeight, _fontWidth, _fontHeight)];
}

- (void)terminalDidUpdate:(WLTerminal *)terminal {
	if (terminal == [self frontMostTerminal]) {
		[self tick];
	}
}

- (void)tick {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
	[self updateBackedImage];
    WLTerminal *ds = [self frontMostTerminal];
	
	if (ds && (_x != [ds cursorColumn] || _y != [ds cursorRow])) {
		[self setNeedsDisplayInRect:NSMakeRect(_x * _fontWidth, (_maxRow - 1 - _y) * _fontHeight, _fontWidth, _fontHeight)];
		[self setNeedsDisplayInRect:NSMakeRect([ds cursorColumn] * _fontWidth, (_maxRow - 1 - [ds cursorRow]) * _fontHeight, _fontWidth, _fontHeight)];
		_x = [ds cursorColumn];
		_y = [ds cursorRow];
	}
    [pool release];
}

- (NSRect)cellRectForRect:(NSRect)r {
	int originx = r.origin.x / _fontWidth;
	int originy = r.origin.y / _fontHeight;
	int width = ((r.size.width + r.origin.x) / _fontWidth) - originx + 1;
	int height = ((r.size.height + r.origin.y) / _fontHeight) - originy + 1;
	return NSMakeRect(originx, originy, width, height);
}

- (void)drawRect:(NSRect)rect {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    WLTerminal *ds = [self frontMostTerminal];
	if ([self isConnected]) {
		// NSLog(@"connected");
		// Modified by gtCarrera
		// Draw the background color first!!!
		[[gConfig colorBG] set];
        NSRect retangle = [self bounds];
		NSRectFill(retangle);
        /* Draw the backed image */
		
		NSRect imgRect = rect;
		imgRect.origin.y = (_fontHeight * _maxRow) - rect.origin.y - rect.size.height;
		[_backedImage compositeToPoint:rect.origin
							  fromRect:rect
							 operation:NSCompositeCopy];
        [self drawBlink];
        
        /* Draw the url underline */
		int c, r;
		[[NSColor orangeColor] set];
		[NSBezierPath setDefaultLineWidth: 1.0];
		for (r = 0; r < _maxRow; r++) {
			cell *currRow = [ds cellsOfRow:r];
			for (c = 0; c < _maxColumn; c++) {
				int start;
				for (start = c; c < _maxColumn && currRow[c].attr.f.url; c++) ;
				if (c != start) {
					[NSBezierPath strokeLineFromPoint:NSMakePoint(start * _fontWidth, (_maxRow - r - 1) * _fontHeight + 0.5) 
											  toPoint:NSMakePoint(c * _fontWidth, (_maxRow - r - 1) * _fontHeight + 0.5)];
		//					//[self drawURLUnderlineAtRow:r fromColumn:start toColumn:c];
				}
			}
		}
        
		/* Draw the cursor */
		[[NSColor whiteColor] set];
		[NSBezierPath setDefaultLineWidth:2.0];
		[NSBezierPath strokeLineFromPoint:NSMakePoint([ds cursorColumn] * _fontWidth, (_maxRow - 1 - [ds cursorRow]) * _fontHeight + 1) 
								  toPoint:NSMakePoint(([ds cursorColumn] + 1) * _fontWidth, (_maxRow - 1 - [ds cursorRow]) * _fontHeight + 1) ];
        [NSBezierPath setDefaultLineWidth:1.0];
        _x = [ds cursorColumn], _y = [ds cursorRow];
		
        /* Draw the selection */
		//[self drawSelection];
	} else {
		// NSLog(@"Not connected!");
		[[gConfig colorBG] set];
        NSRect r = [self bounds];
        NSRectFill(r);
	}
	
    [pool release];
}

- (void)updateBlinkTicker:(NSTimer *)timer {
	// TODO: use local variable to do this.
    [[WLGlobalConfig sharedInstance] updateBlinkTicker];
	if ([self hasBlinkCell])
        [self setNeedsDisplay:YES];
}

- (void)drawBlink {
    if (![gConfig blinkTicker])
		return;
	
    int c, r;
    id ds = [self frontMostTerminal];
    if (!ds) 
		return;
	
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    for (r = 0; r < _maxRow; r++) {
        cell *currRow = [ds cellsOfRow: r];
        for (c = 0; c < _maxColumn; c++) {
            if (isBlinkCell(currRow[c])) {
                int bgColorIndex = currRow[c].attr.f.reverse ? currRow[c].attr.f.fgColor : currRow[c].attr.f.bgColor;
                BOOL bold = currRow[c].attr.f.reverse ? currRow[c].attr.f.bold : NO;
				
				// Modified by K.O.ed: All background color use same alpha setting.
				NSColor *bgColor = [gConfig colorAtIndex:bgColorIndex hilite:bold];
				bgColor = [bgColor colorWithAlphaComponent:[[gConfig colorBG] alphaComponent]];
				[bgColor set];
                //[[gConfig colorAtIndex: bgColorIndex hilite: bold] set];
                NSRectFill(NSMakeRect(c * _fontWidth, (_maxRow - r - 1) * _fontHeight, _fontWidth, _fontHeight));
            }
        }
    }
    
    [pool release];
}

/* 
 Extend Bottom:
 
 AAAAAAAAAAA			BBBBBBBBBBB
 BBBBBBBBBBB			CCCCCCCCCCC
 CCCCCCCCCCC   ->	DDDDDDDDDDD
 DDDDDDDDDDD			...........
 
 */
- (void)extendBottomFrom:(int)start
					  to:(int)end {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
	[_backedImage lockFocus];
	[_backedImage compositeToPoint:NSMakePoint(0, (_maxRow - end) * _fontHeight) 
						  fromRect:NSMakeRect(0, (_maxRow - end - 1) * _fontHeight, _maxColumn * _fontWidth, (end - start) * _fontHeight) 
						 operation:NSCompositeCopy];
	
	[gConfig->_colorTable[0][gConfig->_bgColorIndex] set];
	NSRectFill(NSMakeRect(0, (_maxRow - end - 1) * _fontHeight, _maxColumn * _fontWidth, _fontHeight));
	[_backedImage unlockFocus];
    [pool release];
}


/* 
 Extend Top:
 AAAAAAAAAAA			...........
 BBBBBBBBBBB			AAAAAAAAAAA
 CCCCCCCCCCC   ->	BBBBBBBBBBB
 DDDDDDDDDDD			CCCCCCCCCCC
 */
- (void)extendTopFrom:(int)start 
				   to:(int)end {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    [_backedImage lockFocus];
	[_backedImage compositeToPoint:NSMakePoint(0, (_maxRow - end - 1) * _fontHeight) 
						  fromRect:NSMakeRect(0, (_maxRow - end) * _fontHeight, _maxColumn * _fontWidth, (end - start) * _fontHeight) 
						 operation:NSCompositeCopy];
	
	[gConfig->_colorTable[0][gConfig->_bgColorIndex] set];
	NSRectFill(NSMakeRect(0, (_maxRow - start - 1) * _fontHeight, _maxColumn * _fontWidth, _fontHeight));
	[_backedImage unlockFocus];
    [pool release];
}

- (void)updateBackedImage {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
	int x, y;
    WLTerminal *ds = [self frontMostTerminal];
	[_backedImage lockFocus];
	CGContextRef myCGContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
	if (ds) {
        /* Draw Background */
        for (y = 0; y < _maxRow; y++) {
            for (x = 0; x < _maxColumn; x++) {
                if ([ds isDirtyAtRow:y column:x]) {
                    int startx = x;
                    for (; x < _maxColumn && [ds isDirtyAtRow:y column:x]; x++) ;
                    [self updateBackgroundForRow:y from:startx to:x];
                }
            }
        }
        CGContextSaveGState(myCGContext);
        CGContextSetShouldSmoothFonts(myCGContext, 
                                      [gConfig shouldSmoothFonts] ? true : false);
        
        /* Draw String row by row */
        for (y = 0; y < _maxRow; y++) {
            [self drawStringForRow:y context:myCGContext];
        }
        CGContextRestoreGState(myCGContext);
        /*
        for (y = 0; y < _maxRow; y++) {
            for (x = 0; x < _maxColumn; x++) {
                [ds setDirty:NO atRow:y column:x];
            }
        }*/
		[ds removeAllDirtyMarks];
    } else {
        [[NSColor clearColor] set];
        CGContextFillRect(myCGContext, CGRectMake(0, 0, _maxColumn * _fontWidth, _maxRow * _fontHeight));
    }
	
	[_backedImage unlockFocus];
    [pool release];
	return;
}

- (void)drawStringForRow:(int)r
				 context:(CGContextRef)myCGContext {
	int i, c, x;
	int start, end;
	unichar textBuf[_maxColumn];
	BOOL isDoubleByte[_maxColumn];
	BOOL isDoubleColor[_maxColumn];
	int bufIndex[_maxColumn];
	int runLength[_maxColumn];
	CGPoint position[_maxColumn];
	int bufLength = 0;
    
    CGFloat ePaddingLeft = [gConfig englishFontPaddingLeft], ePaddingBottom = [gConfig englishFontPaddingBottom];
    CGFloat cPaddingLeft = [gConfig chineseFontPaddingLeft], cPaddingBottom = [gConfig chineseFontPaddingBottom];
    
    WLTerminal *ds = [self frontMostTerminal];
    [ds updateDoubleByteStateForRow:r];
	
    cell *currRow = [ds cellsOfRow:r];
	
	for (i = 0; i < _maxColumn; i++) 
		isDoubleColor[i] = isDoubleByte[i] = textBuf[i] = runLength[i] = 0;
	
    // find the first dirty position in this row
	for (x = 0; x < _maxColumn && ![ds isDirtyAtRow:r column:x]; x++) ;
	// all clean? great!
    if (x == _maxColumn) 
		return; 
    
	start = x;
	end = x;
	
    // update the information array
	for (x = start; x < _maxColumn; x++) {
		if (![ds isDirtyAtRow:r column:x]) 
			continue;
		end = x;
		int db = (currRow + x)->attr.f.doubleByte;
		
		if (db == 0) {
            isDoubleByte[bufLength] = NO;
            textBuf[bufLength] = 0x0000 + (currRow[x].byte ?: ' ');
            bufIndex[bufLength] = x;
            position[bufLength] = CGPointMake(x * _fontWidth + ePaddingLeft, (_maxRow - 1 - r) * _fontHeight + CTFontGetDescent(gConfig->_eCTFont) + ePaddingBottom);
            isDoubleColor[bufLength] = NO;
            bufLength++;
		} else if (db == 1) {
			continue;
		} else if (db == 2) {
			unsigned short code = (((currRow + x - 1)->byte) << 8) + ((currRow + x)->byte) - 0x8000;
			unichar ch = [WLEncoder toUnicode:code encoding:[[[self frontMostConnection] site] encoding]];
			//NSLog(@"r = %d, x = %d, ch = %d", r, x, ch);
			if (isSpecialSymbol(ch)) {
				[self drawSpecialSymbol:ch forRow:r column:(x - 1) leftAttribute:(currRow + x - 1)->attr rightAttribute:(currRow + x)->attr];
			} else {
                isDoubleColor[bufLength] = (fgColorIndexOfAttribute(currRow[x - 1].attr) != fgColorIndexOfAttribute(currRow[x].attr) || 
                                            fgBoldOfAttribute(currRow[x - 1].attr) != fgBoldOfAttribute(currRow[x].attr));
				isDoubleByte[bufLength] = YES;
				textBuf[bufLength] = ch;
				bufIndex[bufLength] = x;
				position[bufLength] = CGPointMake((x - 1) * _fontWidth + cPaddingLeft, (_maxRow - 1 - r) * _fontHeight + CTFontGetDescent(gConfig->_cCTFont) + cPaddingBottom);
				bufLength++;
			}
            // FIXME: why?
			if (x == start)
				[self setNeedsDisplayInRect:NSMakeRect((x - 1) * _fontWidth, (_maxRow - 1 - r) * _fontHeight, _fontWidth, _fontHeight)];
		}
	}
	
	CFStringRef str = CFStringCreateWithCharacters(kCFAllocatorDefault, textBuf, bufLength);
	CFAttributedStringRef attributedString = CFAttributedStringCreate(kCFAllocatorDefault, str, NULL);
	CFMutableAttributedStringRef mutableAttributedString = CFAttributedStringCreateMutableCopy(kCFAllocatorDefault, 0, attributedString);
	CFRelease(str);
	CFRelease(attributedString);
    
	/* Run-length of the style */
	c = 0;
	while (c < bufLength) {
		int location = c;
		int length = 0;
		BOOL db = isDoubleByte[c];
		
		attribute currAttr, lastAttr = (currRow + bufIndex[c])->attr;
		for (; c < bufLength; c++) {
			currAttr = (currRow + bufIndex[c])->attr;
			if (currAttr.v != lastAttr.v || isDoubleByte[c] != db) break;
		}
		length = c - location;
		
		CFDictionaryRef attr;
		if (db) 
			attr = gConfig->_cCTAttribute[fgBoldOfAttribute(lastAttr)][fgColorIndexOfAttribute(lastAttr)];
		else
			attr = gConfig->_eCTAttribute[fgBoldOfAttribute(lastAttr)][fgColorIndexOfAttribute(lastAttr)];
		CFAttributedStringSetAttributes(mutableAttributedString, CFRangeMake(location, length), attr, YES);
	}
    
	CTLineRef line = CTLineCreateWithAttributedString(mutableAttributedString);
	CFRelease(mutableAttributedString);
	
	CFIndex glyphCount = CTLineGetGlyphCount(line);
	if (glyphCount == 0) {
		CFRelease(line);
		return;
	}
	
	CFArrayRef runArray = CTLineGetGlyphRuns(line);
	CFIndex runCount = CFArrayGetCount(runArray);
	CFIndex glyphOffset = 0;
	
	CFIndex runIndex = 0;
	
	for (; runIndex < runCount; runIndex++) {
		CTRunRef run = (CTRunRef) CFArrayGetValueAtIndex(runArray,  runIndex);
		CFIndex runGlyphCount = CTRunGetGlyphCount(run);
		CFIndex runGlyphIndex = 0;
		
		CFDictionaryRef attrDict = CTRunGetAttributes(run);
		CTFontRef runFont = (CTFontRef)CFDictionaryGetValue(attrDict,  kCTFontAttributeName);
		CGFontRef cgFont = CTFontCopyGraphicsFont(runFont, NULL);
		NSColor *runColor = (NSColor *)CFDictionaryGetValue(attrDict, kCTForegroundColorAttributeName);
		
		CGContextSetFont(myCGContext, cgFont);
		CGContextSetFontSize(myCGContext, CTFontGetSize(runFont));
		CGContextSetRGBFillColor(myCGContext, 
								 [runColor redComponent], 
								 [runColor greenComponent], 
								 [runColor blueComponent], 
								 1.0);
        CGContextSetRGBStrokeColor(myCGContext, 1.0, 1.0, 1.0, 1.0);
        CGContextSetLineWidth(myCGContext, 1.0);
        
        int location = 0;
        int lastIndex = bufIndex[glyphOffset];
        BOOL hidden = isHiddenAttribute(currRow[lastIndex].attr);
        BOOL lastDoubleByte = isDoubleByte[glyphOffset];
        
        for (runGlyphIndex = 0; runGlyphIndex <= runGlyphCount; runGlyphIndex++) {
            int index = bufIndex[glyphOffset + runGlyphIndex];
            if (runGlyphIndex == runGlyphCount || 
                ([gConfig showsHiddenText] && isHiddenAttribute(currRow[index].attr) != hidden) ||
                (isDoubleByte[runGlyphIndex + glyphOffset] && index != lastIndex + 2) ||
                (!isDoubleByte[runGlyphIndex + glyphOffset] && index != lastIndex + 1) ||
                (isDoubleByte[runGlyphIndex + glyphOffset] != lastDoubleByte)) {
                lastDoubleByte = isDoubleByte[runGlyphIndex + glyphOffset];
                int len = runGlyphIndex - location;
                
                CGContextSetTextDrawingMode(myCGContext, ([gConfig showsHiddenText] && hidden) ? kCGTextStroke : kCGTextFill);
                CGGlyph glyph[_maxColumn];
                CFRange glyphRange = CFRangeMake(location, len);
                CTRunGetGlyphs(run, glyphRange, glyph);
                
                CGAffineTransform textMatrix = CTRunGetTextMatrix(run);
                textMatrix.tx = position[glyphOffset + location].x;
                textMatrix.ty = position[glyphOffset + location].y;
                CGContextSetTextMatrix(myCGContext, textMatrix);
                
                CGContextShowGlyphsWithAdvances(myCGContext, glyph, isDoubleByte[glyphOffset + location] ? gDoubleAdvance : gSingleAdvance, len);
                
                location = runGlyphIndex;
                if (runGlyphIndex != runGlyphCount)
                    hidden = isHiddenAttribute(currRow[index].attr);
            }
            lastIndex = index;
        }
        
        
		/* Double Color */
		for (runGlyphIndex = 0; runGlyphIndex < runGlyphCount; runGlyphIndex++) {
            if (isDoubleColor[glyphOffset + runGlyphIndex]) {
                CFRange glyphRange = CFRangeMake(runGlyphIndex, 1);
                CGGlyph glyph;
                CTRunGetGlyphs(run, glyphRange, &glyph);
                
                int index = bufIndex[glyphOffset + runGlyphIndex] - 1;
                unsigned int bgColor = bgColorIndexOfAttribute(currRow[index].attr);
                unsigned int fgColor = fgColorIndexOfAttribute(currRow[index].attr);
                
                [gLeftImage lockFocus];
                [[gConfig colorAtIndex:bgColor hilite:bgBoldOfAttribute(currRow[index].attr)] set];
                NSRect rect;
                rect.size = [gLeftImage size];
                rect.origin = NSZeroPoint;
                NSRectFill(rect);
                
                CGContextRef tempContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
                
                CGContextSetShouldSmoothFonts(tempContext, [gConfig shouldSmoothFonts] ? true : false);
                
                NSColor *tempColor = [gConfig colorAtIndex: fgColor hilite: fgBoldOfAttribute(currRow[index].attr)];
                CGContextSetFont(tempContext, cgFont);
                CGContextSetFontSize(tempContext, CTFontGetSize(runFont));
                CGContextSetRGBFillColor(tempContext, 
                                         [tempColor redComponent], 
                                         [tempColor greenComponent], 
                                         [tempColor blueComponent], 
                                         1.0);
                
                CGContextShowGlyphsAtPoint(tempContext, cPaddingLeft, CTFontGetDescent(gConfig->_cCTFont) + cPaddingBottom, &glyph, 1);
                [gLeftImage unlockFocus];
                [gLeftImage drawAtPoint:NSMakePoint(index * _fontWidth, (_maxRow - 1 - r) * _fontHeight)
							   fromRect:rect
							  operation:NSCompositeCopy
							   fraction:1.0];
            }
		}
		glyphOffset += runGlyphCount;
		CFRelease(cgFont);
	}
	
	CFRelease(line);
	
    /* underline */
    for (x = start; x <= end; x++) {
        if (currRow[x].attr.f.underline) {
            unsigned int beginColor = currRow[x].attr.f.reverse ? currRow[x].attr.f.bgColor : currRow[x].attr.f.fgColor;
            BOOL beginBold = !currRow[x].attr.f.reverse && currRow[x].attr.f.bold;
            int begin = x;
            for (; x <= end; x++) {
                unsigned int currentColor = currRow[x].attr.f.reverse ? currRow[x].attr.f.bgColor : currRow[x].attr.f.fgColor;
                BOOL currentBold = !currRow[x].attr.f.reverse && currRow[x].attr.f.bold;
                if (!currRow[x].attr.f.underline || currentColor != beginColor || currentBold != beginBold) 
                    break;
            }
            [[gConfig colorAtIndex:beginColor hilite:beginBold] set];
            [NSBezierPath strokeLineFromPoint:NSMakePoint(begin * _fontWidth, (_maxRow - 1 - r) * _fontHeight + 0.5) 
                                      toPoint:NSMakePoint(x * _fontWidth, (_maxRow - 1 - r) * _fontHeight + 0.5)];
            x--;
        }
    }
}

- (void)updateBackgroundForRow:(int)r 
						  from:(int)start 
							to:(int)end {
	int c;
	cell *currRow = [[self frontMostTerminal] cellsOfRow:r];
	NSRect rowRect = NSMakeRect(start * _fontWidth, (_maxRow - 1 - r) * _fontHeight, (end - start) * _fontWidth, _fontHeight);
	
	attribute currAttr, lastAttr = (currRow + start)->attr;
	int length = 0;
	unsigned int currentBackgroundColor = 0;
    BOOL currentBold = NO;
	unsigned int lastBackgroundColor = bgColorIndexOfAttribute(lastAttr);
	BOOL lastBold = bgBoldOfAttribute(lastAttr);
	/* 
	 Optimization Idea:
	 for example: 
	 
	 BBBBBBBBBBBWWWWWWWWWWBBBBBBBBBBB
	 
	 currently, we draw each color segment one by one, like this:
	 
	 1. BBBBBBBBBBB
	 2. BBBBBBBBBBBWWWWWWWWWW
	 3. BBBBBBBBBBBWWWWWWWWWWBBBBBBBBBBB
	 
	 but we can use only two fillRect: 
	 
	 1. BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
	 2. BBBBBBBBBBBWWWWWWWWWWBBBBBBBBBBB
	 
	 If further optimization of background drawing is needed, consider the 2D reduction.
     
	 NOTE: 2007/12/07
	 
	 We don't have to reduce the number of fillRect. We should reduce the number of pixels it draws.
	 Obviously, the current method draws less pixels than the second one. So it's optimized already!
	 */
	for (c = start; c <= end; c++) {
		if (c < end) {
			currAttr = (currRow + c)->attr;
			currentBackgroundColor = bgColorIndexOfAttribute(currAttr);
            currentBold = bgBoldOfAttribute(currAttr);
		}
		
		if (currentBackgroundColor != lastBackgroundColor || currentBold != lastBold || c == end) {
			/* Draw Background */
			NSRect rect = NSMakeRect((c - length) * _fontWidth, (_maxRow - 1 - r) * _fontHeight,
									 _fontWidth * length, _fontHeight);
			
			// Modified by K.O.ed: All background color use same alpha setting.
			NSColor *bgColor = [gConfig colorAtIndex:lastBackgroundColor hilite:lastBold];
			bgColor = [bgColor colorWithAlphaComponent:[[gConfig colorBG] alphaComponent]];
			[bgColor set];
			
			//[[gConfig colorAtIndex: lastBackgroundColor hilite: lastBold] set];
			// [NSBezierPath fillRect: rect];
            NSRectFill(rect);
			
			/* finish this segment */
			length = 1;
			lastAttr.v = currAttr.v;
			lastBackgroundColor = currentBackgroundColor;
            lastBold = currentBold;
		} else {
			length++;
		}
	}
	
	[self setNeedsDisplayInRect:rowRect];
}

- (void)drawSpecialSymbol:(unichar)ch 
				   forRow:(int)r 
				   column:(int)c 
			leftAttribute:(attribute)attr1 
		   rightAttribute:(attribute)attr2 {
	int colorIndex1 = fgColorIndexOfAttribute(attr1);
	int colorIndex2 = fgColorIndexOfAttribute(attr2);
	NSPoint origin = NSMakePoint(c * _fontWidth, (_maxRow - 1 - r) * _fontHeight);
	
	NSAffineTransform *xform = [NSAffineTransform transform]; 
	[xform translateXBy: origin.x yBy: origin.y];
	[xform concat];
	
	if (colorIndex1 == colorIndex2 && fgBoldOfAttribute(attr1) == fgBoldOfAttribute(attr2)) {
		NSColor *color = [gConfig colorAtIndex:colorIndex1 hilite:fgBoldOfAttribute(attr1)];
		
		if (ch == 0x25FC) { // ◼ BLACK SQUARE
			[color set];
			NSRectFill(gSymbolBlackSquareRect);
		} else if (ch >= 0x2581 && ch <= 0x2588) { // BLOCK ▁▂▃▄▅▆▇█
			[color set];
			NSRectFill(gSymbolLowerBlockRect[ch - 0x2581]);
		} else if (ch >= 0x2589 && ch <= 0x258F) { // BLOCK ▉▊▋▌▍▎▏
			[color set];
			NSRectFill(gSymbolLeftBlockRect[ch - 0x2589]);
		} else if (ch >= 0x25E2 && ch <= 0x25E5) { // TRIANGLE ◢◣◤◥
            [color set];
            [gSymbolTrianglePath[ch - 0x25E2] fill];
		} else if (ch == 0x0) {
		}
	} else { // double color
		NSColor *color1 = [gConfig colorAtIndex:colorIndex1 hilite:fgBoldOfAttribute(attr1)];
		NSColor *color2 = [gConfig colorAtIndex:colorIndex2 hilite:fgBoldOfAttribute(attr2)];
		if (ch == 0x25FC) { // ◼ BLACK SQUARE
			[color1 set];
			NSRectFill(gSymbolBlackSquareRect1);
			[color2 set];
			NSRectFill(gSymbolBlackSquareRect2);
		} else if (ch >= 0x2581 && ch <= 0x2588) { // BLOCK ▁▂▃▄▅▆▇█
			[color1 set];
			NSRectFill(gSymbolLowerBlockRect1[ch - 0x2581]);
			[color2 set];
            NSRectFill(gSymbolLowerBlockRect2[ch - 0x2581]);
		} else if (ch >= 0x2589 && ch <= 0x258F) { // BLOCK ▉▊▋▌▍▎▏
			[color1 set];
			NSRectFill(gSymbolLeftBlockRect1[ch - 0x2589]);
            if (ch <= 0x259B) {
                [color2 set];
                NSRectFill(gSymbolLeftBlockRect2[ch - 0x2589]);
            }
		} else if (ch >= 0x25E2 && ch <= 0x25E5) { // TRIANGLE ◢◣◤◥
            [color1 set];
            [gSymbolTrianglePath1[ch - 0x25E2] fill];
            [color2 set];
            [gSymbolTrianglePath2[ch - 0x25E2] fill];
		}
	}
	[xform invert];
	[xform concat];
}

// Get current BBS image
- (NSImage *)image {
	// Leave for others to release it
	return [[[NSImage alloc] initWithData:[self dataWithPDFInsideRect:[self frame]]] autorelease];
}

#pragma mark -
#pragma mark WLTabItemContentObserver protocol
- (void)didChangeContent:(id)content {
	if ([content isKindOfClass:[WLConnection class]]) {
		_connection = content;
		[self refreshDisplay];
	}
}

#pragma mark -
#pragma mark KVO
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"shouldSmoothFonts"]) {
        [self refreshDisplay];
    } else if ([keyPath hasPrefix:@"cell"]) {
        [self configure];
        [self refreshDisplay];
    } else if ([keyPath hasPrefix:@"chineseFont"] || [keyPath hasPrefix:@"englishFont"] || [keyPath hasPrefix:@"color"]) {
        //[[WLGlobalConfig sharedInstance] refreshFont];
        [self refreshDisplay];
    } else if ([keyPath isEqualToString:@"showsHiddenText"]) {
		[self refreshHiddenRegion];
	}
}
@end
