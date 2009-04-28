//
//  YLMarkedTextView.m
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 9/29/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import "YLMarkedTextView.h"


@implementation YLMarkedTextView
@synthesize string = _string;
@synthesize markedRange = _markedRange;
@synthesize selectedRange = _selectedRange;
@synthesize defaultFont = _defaultFont;
@synthesize destination = _destination;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[self setDefaultFont:[NSFont fontWithName:@"Lucida Grande" size:20]];
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
	CGContextRef context = (CGContextRef) [[NSGraphicsContext currentContext] graphicsPort];
	CGContextSaveGState(context);
	
	CGFloat half = ([self frame].size.height / 2.0);
	BOOL fromTop = _destination.y > half;
	
	CGContextTranslateCTM(context, 1.0,  1.0);
	if (!fromTop) 
		CGContextTranslateCTM(context, 0.0,  5.0);

	CGPoint dest = NSPointToCGPoint(_destination);
	dest.x -= 1.0;
	dest.y -= 1.0;
	if (!fromTop)
		dest.y -= 5.0;
	
	CGContextSaveGState(context);
	CGFloat ovalSize = 6.0;
	CGContextTranslateCTM(context, 1.0,  1.0);

    CGFloat fw = ([self bounds].size.width - 3);
    CGFloat fh = ([self bounds].size.height - 3 - 5);

	CGContextBeginPath(context);
    CGContextMoveToPoint(context, 0, fh - ovalSize); 
    CGContextAddArcToPoint(context, 0, fh, ovalSize, fh, ovalSize);
	if (fromTop) {
		CGFloat left, right;
		left = dest.x - 2.5;
		right = left + 5.0;
		if (left < ovalSize) {
			left = ovalSize;
			right = left + 5.0;
		} else if (right > fw - ovalSize) {
			right = fw - ovalSize;
			left = right - 5.0;
		}
		CGContextAddLineToPoint(context, left, fh);
		CGContextAddLineToPoint(context, dest.x, dest.y);
		CGContextAddLineToPoint(context, right, fh);
	}
//    CGContextMoveToPoint(context, fw - ovalSize, fh); 
    CGContextAddArcToPoint(context, fw, fh, fw, fh - ovalSize, ovalSize);

//	CGContextMoveToPoint(context, fw, ovalSize); 
	CGContextAddArcToPoint(context, fw, 0, fw - ovalSize, 0, ovalSize);
	if (!fromTop) {
		CGFloat left, right;
		left = dest.x - 2.5;
		right = left + 5.0;
		if (left < ovalSize) {
			left = ovalSize;
			right = left + 5.0;
		} else if (right > fw - ovalSize) {
			right = fw - ovalSize;
			left = right - 5.0;
		}
		CGContextAddLineToPoint(context, right, 0);
		CGContextAddLineToPoint(context, dest.x, dest.y);
		CGContextAddLineToPoint(context, left, 0);		
	}
//	CGContextMoveToPoint(context, ovalSize, 0); 
    CGContextAddArcToPoint(context, 0, 0, 0, ovalSize, ovalSize); 
    CGContextClosePath(context);	

	CGContextSetRGBFillColor(context, 0.15, 0.15, 0.15, 1.0);
	CGContextSetLineWidth(context, 2.0);
	CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 1.0);

	CGContextDrawPath(context, kCGPathFillStroke);

	CGContextRestoreGState(context);

    // fixed by boost @ 9#
    // _string/line may be nil, and CFRelease(line) may crash 
    if (_string != nil) {
        CGContextTranslateCTM(context, 4.0, 3.0);
        [_string drawAtPoint:NSZeroPoint];
        CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)_string);
        CGFloat offset = CTLineGetOffsetForStringIndex(line, _selectedRange.location, NULL);
        [[NSColor whiteColor] set];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(offset, 0) toPoint:NSMakePoint(offset, _lineHeight)];
        CFRelease(line);
    }
    
	CGContextRestoreGState(context);
}

- (void)setString:(NSAttributedString *)value {
	NSMutableAttributedString *as = [[NSMutableAttributedString alloc] initWithAttributedString: value];
	[as addAttribute:NSFontAttributeName 
			   value:_defaultFont
			   range:NSMakeRange(0, [value length])];
	[as addAttribute:NSForegroundColorAttributeName 
			   value:[NSColor whiteColor]
			   range:NSMakeRange(0, [value length])];
	[_string release];
	_string = as;
	[self setNeedsDisplay:YES];

	CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)_string);
	double w = CTLineGetTypographicBounds(line, NULL, NULL, NULL) ;
	NSSize size = [self frame].size;
	size.width = w + 12;
	size.height = _lineHeight + 8 + 5;
	[self setFrameSize:size];
	CFRelease(line);
}

- (void)setMarkedRange:(NSRange)value {
	_markedRange = value;
	[self setNeedsDisplay:YES];
}

- (void)setSelectedRange:(NSRange)value {
	_selectedRange = value;
	[self setNeedsDisplay:YES];
}

- (void)setDefaultFont:(NSFont *)value {
    if (_defaultFont != value) {
        [_defaultFont release];
        _defaultFont = [value copy];
		_lineHeight = [[[NSLayoutManager new] autorelease] defaultLineHeightForFont:_defaultFont];
    }
	[self setNeedsDisplay:YES];
}

- (BOOL)isOpaque {
	return NO;
}

@end
