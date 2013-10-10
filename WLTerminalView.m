//
//  YLView.m
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/6/9.
//  Copyright 2006 yllan.org. All rights reserved.
//

#import "WLTerminalView.h"
#import "WLEffectView.h"
#import "YLMarkedTextView.h"

#import "WLTerminal.h"
#import "WLConnection.h"
#import "WLSite.h"
#import "WLGLobalConfig.h"
#import "WLContextualMenuManager.h"
#import "WLPreviewController.h"
#import "WLIntegerArray.h"
#import "IPSeeker.h"
#import "WLMouseBehaviorManager.h"
#import "WLURLManager.h"
#import "WLPopUpMessage.h"
#import "WLAnsiColorOperationManager.h"
#import "WLEncoder.h"

#import "WLNotifications.h"

#import <Carbon/Carbon.h>
#include <math.h>

const float WLActivityCheckingTimeInteval = 5.0;

NSString *const ANSIColorPBoardType = @"ANSIColorPBoardType";

BOOL isEnglishNumberAlphabet(unsigned char c) {
    return ('0' <= c && c <= '9') || ('A' <= c && c <= 'Z') || ('a' <= c && c <= 'z') || (c == '-') || (c == '_') || (c == '.');
}


@interface WLTerminalView ()
- (void)drawSelection;

// safe_paste
- (void)confirmPaste:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)confirmPasteWrap:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)confirmPasteColor:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)performPaste;
- (void)performPasteWrap;
- (void)performPasteColor;
@end

@implementation WLTerminalView
@synthesize isInUrlMode = _isInUrlMode;
@synthesize isMouseActive = _isMouseActive;
@synthesize effectView = _effectView;

- (id)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) {
        _selectionLength = 0;
        _selectionLocation = 0;
		_isInUrlMode = NO;
		_isKeying = NO;
		_isNotCancelingSelection = YES;
		_isMouseActive = YES;
		_mouseBehaviorDelegate = [[WLMouseBehaviorManager alloc] initWithView:self];
		_urlManager = [[WLURLManager alloc] initWithView:self];
		[_mouseBehaviorDelegate addHandler:_urlManager];
		_activityCheckingTimer = [NSTimer scheduledTimerWithTimeInterval:WLActivityCheckingTimeInteval
																  target:self 
																selector:@selector(checkActivity:)
																userInfo:nil
																 repeats:YES];
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(refreshMouseHotspot) 
													 name:WLNotificationSiteDidChangeShouldEnableMouse 
												   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(refreshDisplay) 
													 name:WLNotificationSiteDidChangeEncoding
												   object:nil];
    }
    return self;
}

- (void)dealloc {
	[_mouseBehaviorDelegate dealloc];
    [super dealloc];
}

#pragma mark -
#pragma mark Conversion

- (int)convertIndexFromPoint:(NSPoint)p {
	if (p.x >= _maxColumn * _fontWidth)
		p.x = _maxColumn * _fontWidth - 0.001;
    if (p.y >= _maxRow * _fontHeight)
		p.y = _maxRow * _fontHeight - 0.001;
    if (p.x < 0)
		p.x = 0;
    if (p.y < 0)
		p.y = 0;
    int cx, cy = 0;
    cx = (int) ((CGFloat) p.x / _fontWidth);
    cy = _maxRow - (int) ((CGFloat) p.y / _fontHeight) - 1;
    return cy * _maxColumn + cx;
}

- (NSRect)rectAtRow:(int)r 
			 column:(int)c 
			 height:(int)h 
			  width:(int)w {
	return NSMakeRect(c * _fontWidth, (_maxRow - h - r) * _fontHeight, _fontWidth * w, _fontHeight * h);
}

- (NSRect)selectedRect {
	if (_selectionLength == 0)
		return NSZeroRect;
	
	int startIndex = _selectionLocation;
	int endIndex = startIndex + _selectionLength;
	if (_selectionLength > 0)
		--endIndex;
	
	int row = startIndex / _maxColumn;
	int column = startIndex % _maxColumn;
	int endRow = endIndex / _maxColumn;
	int endColumn = endIndex % _maxColumn;
	
	if (endRow < row) {
		int temp = row;
		row = endRow;
		endRow = temp - 1;
	}
	if (endColumn < column) {
		int temp = column;
		column = endColumn;
		endColumn = temp - 1;
	}
	int height = (endRow - row) + 1;
	int width = (endColumn - column) + 1;
	
	return NSMakeRect(column, row, width, height);
}

- (NSPoint)mouseLocationInView {
	return [self convertPoint:[[self window] convertScreenToBase:[NSEvent mouseLocation]] fromView:nil];
}

- (NSRange)rangeForWordAtPoint:(NSPoint)point {
	NSRange range;
	range.location = [self convertIndexFromPoint:point];
	range.length = 0;
	
	int r = range.location / _maxColumn;
	int c = range.location % _maxColumn;
	cell *currRow = [[self frontMostTerminal] cellsOfRow:r];
	[[self frontMostTerminal] updateDoubleByteStateForRow:r];
	if (currRow[c].attr.f.doubleByte == 1) { // Double Byte
		// Chinese word
		range.length = 2;
	} else if (currRow[c].attr.f.doubleByte == 2) {
		range.location--;
		// Chinese word
		range.length = 2;
	} else if (isEnglishNumberAlphabet(currRow[c].byte)) { // Not Double Byte
		for (; c >= 0; c--) {
			if (isEnglishNumberAlphabet(currRow[c].byte) && currRow[c].attr.f.doubleByte == 0) 
				range.location = r * _maxColumn + c;
			else 
				break;
		}
		for (c = c + 1; c < _maxColumn; c++) {
			if (isEnglishNumberAlphabet(currRow[c].byte) && currRow[c].attr.f.doubleByte == 0) 
				range.length++;
			else 
				break;
		}
	} else {
		range.length = 1;
	}
	return range;
}

#pragma mark -
#pragma mark safe_paste
- (void)confirmPaste:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertDefaultReturn) {
		[self performPaste];
    }
}

- (void)confirmPasteWrap:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertDefaultReturn) {
		[self performPasteWrap];
    }
}

- (void)confirmPasteColor:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertDefaultReturn) {
		[self performPasteColor];
    }
}

- (void)performPaste {
	NSPasteboard *pb = [NSPasteboard generalPasteboard];
	NSArray *types = [pb types];
	if ([types containsObject:NSStringPboardType]) {
		NSString *str = [pb stringForType:NSStringPboardType];
		//[self insertText:str withDelay:100];
		[self insertText:str withDelay:0];
	}
}

- (void)performPasteWrap {
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    NSArray *types = [pb types];
    if (![types containsObject:NSStringPboardType]) return;

    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    NSString *str = [pb stringForType:NSStringPboardType];
    const int LINE_WIDTH = 66, LPADDING = 4;
    WLIntegerArray *word = [WLIntegerArray integerArray];
    WLIntegerArray *text = [WLIntegerArray integerArray];
    int word_width = 0, line_width = 0;
    [text push_back:0x000d];
    for (int j = 0; j < LPADDING; j++)
        [text push_back:0x0020];
    line_width = LPADDING;
    for (int i = 0; i < [str length]; i++) {
        unichar c = [str characterAtIndex:i];
        if (c == 0x0020 || c == 0x0009) { // space
            for (int j = 0; j < [word size]; j++)
                [text push_back:[word at:j]];
            [word clear];
            line_width += word_width;
            word_width = 0;
            if (line_width >= LINE_WIDTH + LPADDING) {
                [text push_back:0x000d];
                for (int j = 0; j < LPADDING; j++)
                    [text push_back:0x0020];
                line_width = LPADDING;
            }
            int repeat = (c == 0x0020) ? 1 : 4;
            for (int j = 0; j < repeat ; j++)
                [text push_back:0x0020];
            line_width += repeat;
        } else if (c == 0x000a || c == 0x000d) {
            for (int j = 0; j < [word size]; j++)
                [text push_back:[word at:j]];
            [word clear];
            [text push_back:0x000d];
            for (int j = 0; j < LPADDING; j++)
                [text push_back:0x0020];
            line_width = LPADDING;
            word_width = 0;
        } else if (c > 0x0020 && c < 0x0100) {
            [word push_back:c];
            word_width++;
            if (c >= 0x0080) word_width++;
        } else if (c >= 0x1000){
            for (int j = 0; j < [word size]; j++)
                [text push_back:[word at:j]];
            [word clear];
            line_width += word_width;
            word_width = 0;
            if (line_width >= LINE_WIDTH + LPADDING) {
                [text push_back:0x000d];
                for (int j = 0; j < LPADDING; j++)
                    [text push_back:0x0020];
                line_width = LPADDING;
            }
            [text push_back:c];
            line_width += 2;
        } else {
            [word push_back:c];
        }

        // the word is too long
        if (word_width > LINE_WIDTH) {
            int acc_width = 0;
            while (![word empty]) {
                int w = ([word front] < 0x0080) ? 1 : 2;
                if (acc_width + w <= LINE_WIDTH) {
                    [text push_back:[word front]];
                    acc_width += w;
                    [word pop_front];
                } else {
                    [text push_back:0x000d];
                    for (int j = 0; j < LPADDING; j++)
                        [text push_back:0x0020];
                    line_width = LPADDING;
                    word_width -= acc_width;
                    break;
                }
            }
        }
        assert(word_width <= LINE_WIDTH);

        // the tailing word is too long
        if (line_width + word_width > LINE_WIDTH + LPADDING) {
            [text push_back:0x000d];
            for (int j = 0; j < LPADDING; j++)
                [text push_back:0x0020];
            line_width = LPADDING;
        }
    }

    while (![word empty]) {
        [text push_back:[word front]];
        [word pop_front];
    }

    unichar *carray = (unichar *)malloc(sizeof(unichar) * [text size]);
    for (int i = 0; i < [text size]; i++)
        carray[i] = [text at:i];
    NSString *mStr = [NSString stringWithCharacters:carray length:[text size]];
    free(carray);
    //[self insertText:mStr withDelay:100];		
    [self insertText:mStr withDelay:0];
    [pool release];
}

- (void)performPasteColor {
	NSPasteboard *pb = [NSPasteboard generalPasteboard];
	NSArray *types = [pb types];
	if ([types containsObject:ANSIColorPBoardType]) {
		NSData *ansiCode = [WLAnsiColorOperationManager ansiCodeFromANSIColorData:[pb dataForType:ANSIColorPBoardType] 
																  forANSIColorKey:[[[self frontMostConnection] site] ansiColorKey] 
																		 encoding:[[[self frontMostConnection] site] encoding]];
		[[self frontMostConnection] sendMessage:ansiCode];
		return;
	} else if ([types containsObject:NSRTFPboardType]) {
		NSAttributedString *rtfString = [[[NSAttributedString alloc]
										 initWithRTF:[pb dataForType:NSRTFPboardType] 
										 documentAttributes:nil] autorelease];
		NSString *ansiCode = [WLAnsiColorOperationManager ansiCodeStringFromAttributedString:rtfString 
																			 forANSIColorKey:[[[self frontMostConnection] site] ansiColorKey]];
		[[self frontMostConnection] sendText:ansiCode];
	} else {
		[self performPaste];
		return;
	}
}

#pragma mark -
#pragma mark Actions
- (void)copy:(id)sender {
    if (![self isConnected]) return;
    if (_selectionLength == 0) return;

    NSString *s = [self selectedPlainString];
    
    /* Color copy */
    int location, length;
    if (_selectionLength >= 0) {
        location = _selectionLocation;
        length = _selectionLength;
    } else {
        location = _selectionLocation + _selectionLength;
        length = 0 - (int)_selectionLength;
    }
    
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    NSMutableArray *types = [NSMutableArray arrayWithObjects:NSStringPboardType, ANSIColorPBoardType, nil];
    if (!s) s = @"";
    [pb declareTypes:types owner:self];
    [pb setString:s forType:NSStringPboardType];
	if (_hasRectangleSelected) {
		[pb setData:[WLAnsiColorOperationManager ansiColorDataFromTerminal:[self frontMostTerminal] 
																	inRect:[self selectedRect]] 
			forType:ANSIColorPBoardType];
	} else {
		[pb setData:[WLAnsiColorOperationManager ansiColorDataFromTerminal:[self frontMostTerminal] 
																atLocation:location 
																	length:length] 
			forType:ANSIColorPBoardType];
	}
}

- (void)copyImage:(id)sender {
    if (![self isConnected]) return;
	
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
	NSArray *typesArray = [NSArray arrayWithObject:NSPasteboardTypePDF];
	[pb declareTypes:typesArray owner:self];
	NSRect imageRect = [self frame];
	// If has selected a rectangle area, copy the image inside the rect
	if (_hasRectangleSelected) {
		NSRect selectedRect = [self selectedRect];
		imageRect = [self rectAtRow:selectedRect.origin.y 
							 column:selectedRect.origin.x 
							 height:selectedRect.size.height 
							  width:selectedRect.size.width];
		// Clear the selection, to avoid copying the selected mark
		[self clearSelection];
	}
	[self writePDFInsideRect:imageRect toPasteboard:pb];
}

- (void)warnPasteWithSelector:(SEL)didEndSelector {
	NSBeginAlertSheet(NSLocalizedString(@"Are you sure you want to paste?", @"Sheet Title"),
					  NSLocalizedString(@"Confirm", @"Default Button"),
					  NSLocalizedString(@"Cancel", @"Cancel Button"),
					  nil,
					  [self window],
					  self,
					  didEndSelector,
					  nil,
					  nil,
					  NSLocalizedString(@"It seems that you are not in edit mode. Pasting may cause unpredictable behaviors. Are you sure you want to paste?", @"Sheet Message"));
}

- (BOOL)shouldWarnPaste {
	return [[NSUserDefaults standardUserDefaults] boolForKey:WLSafePasteEnabledKeyName] && [[self frontMostTerminal] bbsState].state != BBSComposePost;
}

- (void)pasteColor:(id)sender {
    if (![self isConnected]) return;
	if ([self shouldWarnPaste]) {
		[self warnPasteWithSelector:@selector(confirmPasteColor:returnCode:contextInfo:)];
	} else {
		[self performPasteColor];
	}
}

- (void)paste:(id)sender {
    if (![self isConnected]) return;
	if ([self shouldWarnPaste]) {
		[self warnPasteWithSelector:@selector(confirmPaste:returnCode:contextInfo:)];
	} else {
		[self performPaste];
	}
}

- (void)pasteWrap:(id)sender {
    if (![self isConnected]) return;
	if ([self shouldWarnPaste]) {
		[self warnPasteWithSelector:@selector(confirmPasteWrap:returnCode:contextInfo:)];
	} else {
		[self performPasteWrap];
	}
}

- (void)selectAll:(id)sender {
    if (![self isConnected]) return;
    _selectionLocation = 0;
    _selectionLength = _maxRow * _maxColumn;
    [self setNeedsDisplay:YES];
}

- (BOOL)validateMenuItem:(NSMenuItem *)item {
    SEL action = [item action];
    if (action == @selector(copy:) && (![self isConnected] || _selectionLength == 0)) {
        return NO;
    } else if ((action == @selector(paste:) || 
                action == @selector(pasteWrap:) || 
                action == @selector(pasteColor:)) && ![self isConnected]) {
        return NO;
    } else if (action == @selector(selectAll:)  && ![self isConnected]) {
        return NO;
    }
    return YES;
}

- (void)sendText:(NSString *)text {
	[self clearSelection];
	[[self frontMostConnection] sendText:text];
}

- (void)refreshMouseHotspot {
	[_effectView clear];
	[_mouseBehaviorDelegate forceUpdate];
}

#pragma mark -
#pragma mark Active Timer
- (void)hasMouseActivity {
	_isMouseActive = YES;
}

- (void)checkActivity:(NSTimer *)timer {
	if (_isMouseActive) {
		_isMouseActive = NO;
		return;
	} else {
		// Hide the cursor
		[NSCursor setHiddenUntilMouseMoves:YES];
		// Remove effects
		[_effectView clear];
	}
}

#pragma mark -
#pragma mark Event Handling
- (void)selectWordAtPoint:(NSPoint)point {
	NSRange range = [self rangeForWordAtPoint:point];
	_selectionLocation = range.location;
	_selectionLength = range.length;
}

- (void)mouseDown:(NSEvent *)theEvent {
    [self hasMouseActivity];
	
    [[self frontMostConnection] resetMessageCount];
    [[self window] makeFirstResponder:self];
    if (![self isConnected]) {
		return;
	}
	// Disable the mouse if we cancelled any selection
    if(abs(_selectionLength) > 0) 
        _isNotCancelingSelection = NO;
    NSPoint p = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    _selectionLocation = [self convertIndexFromPoint:p];
    _selectionLength = 0;
    
    if (([theEvent modifierFlags] & NSCommandKeyMask) == 0x00 &&
        [theEvent clickCount] == 3) {
        _selectionLocation = _selectionLocation - (_selectionLocation % _maxColumn);
        _selectionLength = _maxColumn;
    } else if (([theEvent modifierFlags] & NSCommandKeyMask) == 0x00 &&
               [theEvent clickCount] == 2) {
		[self selectWordAtPoint:p];
    }
    
    [self setNeedsDisplay:YES];
}

- (void)mouseDragged:(NSEvent *)theEvent {
    [self hasMouseActivity];
    if (![self isConnected]) {
		return;
	}

    NSPoint p = [theEvent locationInWindow];
    p = [self convertPoint:p fromView:nil];
    int index = [self convertIndexFromPoint:p];
    int oldValue = _selectionLength;
    _selectionLength = index - _selectionLocation + 1;
    if (_selectionLength <= 0) 
		_selectionLength--;
    if (oldValue != _selectionLength)
        [self setNeedsDisplay:YES];
	_hasRectangleSelected = _wantsRectangleSelection;
    // TODO: Calculate the precise region to redraw
}

- (void)mouseUp:(NSEvent *)theEvent {
    [self hasMouseActivity];
    if (![self isConnected]) return;
    // open url
    if (abs(_selectionLength) <= 1 && _isNotCancelingSelection && !_isKeying && !_isInUrlMode) {
		[_mouseBehaviorDelegate mouseUp:theEvent];
    }
	_isNotCancelingSelection = YES;
}

- (void)mouseMoved:(NSEvent *)theEvent {
	[self hasMouseActivity];
}

- (void)scrollWheel:(NSEvent *)theEvent {
    [super scrollWheel:theEvent];
    [self hasMouseActivity];
    [_mouseBehaviorDelegate scrollWheel:theEvent];
}

- (void)swipeWithEvent:(NSEvent *)event {
	if ([[[self frontMostTerminal] connection] isConnected]) {
		// For Y-Axis
		if ([event deltaY] > 0) {
			[self sendText:termKeyPageUp];
			return;
		} else if ([event deltaY] < 0) {
			[self sendText:termKeyPageDown];
			return;
		}
	}
	// We leave the X-Axis swiping for parent views to handle
	[super swipeWithEvent:event];
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
    if (![self isConnected])
        return nil;
    NSString *s = [self selectedPlainString];
	if (s != nil)
		return [WLContextualMenuManager menuWithSelectedString:s];
	else
		return [_mouseBehaviorDelegate menuForEvent:theEvent];
}

- (void)keyDown:(NSEvent *)theEvent {
    [[self frontMostConnection] resetMessageCount];
    
    if (theEvent.characters.length == 0) {
        // dead key pressed
        return;
    }
	
    unichar c = [theEvent.characters characterAtIndex:0];
	// URL
	if(_isInUrlMode) {
		BOOL shouldExit;
		switch(c) {
			// Add up and down arrows' event handling here.
			case NSLeftArrowFunctionKey:
			case NSUpArrowFunctionKey:
				[_effectView showIndicatorAtPoint:[_urlManager movePrev]];
				break;
			case WLTabCharacter:
			case NSRightArrowFunctionKey:
			case NSDownArrowFunctionKey:
				[_effectView showIndicatorAtPoint:[_urlManager moveNext]];
				break;
			case WLEscapeCharacter:	// esc
				[self exitURL];
				break;
			case WLWhitespaceCharacter:
			case WLReturnCharacter:
				shouldExit = [_urlManager openCurrentURL:theEvent];
				if(shouldExit)
					[self exitURL];
				else
					[_effectView showIndicatorAtPoint:[_urlManager moveNext]];
				break;
		}
		return;
	}
	
    [self clearSelection];
	unsigned char arrow[6] = {0x1B, 0x4F, 0x00, 0x1B, 0x4F, 0x00};
	unsigned char buf[10];

    WLTerminal *ds = [self frontMostTerminal];

    if ((theEvent.modifierFlags & NSControlKeyMask) &&
	   ((theEvent.modifierFlags & NSAlternateKeyMask) == 0 )) {
        buf[0] = c;
        [[self frontMostConnection] sendBytes:buf length:1];
        return;
    }
	
	if (c == NSUpArrowFunctionKey) arrow[2] = arrow[5] = 'A';
	if (c == NSDownArrowFunctionKey) arrow[2] = arrow[5] = 'B';
	if (c == NSRightArrowFunctionKey) arrow[2] = arrow[5] = 'C';
	if (c == NSLeftArrowFunctionKey) arrow[2] = arrow[5] = 'D';
	
	if (![self hasMarkedText] && 
		(c == NSUpArrowFunctionKey ||
		 c == NSDownArrowFunctionKey ||
		 c == NSRightArrowFunctionKey || 
		 c == NSLeftArrowFunctionKey)) {
        [ds updateDoubleByteStateForRow:[ds cursorRow]];
        if ((c == NSRightArrowFunctionKey && [ds attrAtRow:[ds cursorRow] column:[ds cursorColumn]].f.doubleByte == 1) || 
            (c == NSLeftArrowFunctionKey && [ds cursorColumn] > 0 && [ds attrAtRow:[ds cursorRow] column:[ds cursorColumn] - 1].f.doubleByte == 2))
            if ([[[self frontMostConnection] site] shouldDetectDoubleByte]) {
                [[self frontMostConnection] sendBytes:arrow length:6];
                return;
            }
        
		[[self frontMostConnection] sendBytes:arrow length:3];
		return;
	}
	
	if (![self hasMarkedText] && (c == NSDeleteCharacter)) {
		//buf[0] = buf[1] = NSBackspaceCharacter;
		// Modified by K.O.ed: using 0x7F instead of 0x08
		buf[0] = buf[1] = NSDeleteCharacter;
        if ([[[self frontMostConnection] site] shouldDetectDoubleByte] &&
            [ds cursorColumn] > 0 && [ds attrAtRow:[ds cursorRow] column:[ds cursorColumn] - 1].f.doubleByte == 2)
            [[self frontMostConnection] sendBytes:buf length:2];
        else
            [[self frontMostConnection] sendBytes:buf length:1];
        return;
	}

	[self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
}

- (void)flagsChanged:(NSEvent *)event {
	unsigned int currentFlags = [event modifierFlags];
	// For rectangle selection
	if ((currentFlags & NSAlternateKeyMask) == NSAlternateKeyMask) {
		_wantsRectangleSelection = YES;
		[[NSCursor crosshairCursor] push];
		_mouseBehaviorDelegate.normalCursor = [NSCursor crosshairCursor];
	} else {
		_wantsRectangleSelection = NO;
		[[NSCursor crosshairCursor] pop];
		_mouseBehaviorDelegate.normalCursor = [NSCursor arrowCursor];
	}
	return;
	
	[super flagsChanged:event];
}

- (void)clearSelection {
    if (_selectionLength != 0) {
        _selectionLength = 0;
		_isNotCancelingSelection = NO;
		_hasRectangleSelected = NO;
        [self setNeedsDisplay:YES];
    }
}

#pragma mark -
#pragma mark Drawing
- (void)drawRect:(NSRect)rect {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
	[super drawRect:rect];
	if ([self isConnected]) {
        /* Draw the selection */
        if (_selectionLength != 0) 
            [self drawSelection];
	}
	
    [pool release];
}

- (void)drawSelection {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    int location, length;
    if (_selectionLength >= 0) {
        location = _selectionLocation;
        length = _selectionLength;
    } else {
        location = _selectionLocation + _selectionLength;
        length = 0 - (int)_selectionLength;
    }
    int x = location % _maxColumn;
    int y = location / _maxColumn;
    [[NSColor colorWithCalibratedRed: 0.6 green: 0.9 blue: 0.6 alpha: 0.4] set];

	if (_hasRectangleSelected) {
		// Rectangle
		NSRect selectedRect = [self selectedRect];
		NSRect drawingRect = [self rectAtRow:selectedRect.origin.y
									  column:selectedRect.origin.x
									  height:selectedRect.size.height
									   width:selectedRect.size.width];
		[NSBezierPath fillRect:drawingRect];
	} else {
		while (length > 0) {
			if (x + length <= _maxColumn) { // one-line
				[NSBezierPath fillRect:NSMakeRect(x * _fontWidth, (_maxRow - y - 1) * _fontHeight, _fontWidth * length, _fontHeight)];
				length = 0;
			} else {
				[NSBezierPath fillRect:NSMakeRect(x * _fontWidth, (_maxRow - y - 1) * _fontHeight, _fontWidth * (_maxColumn - x), _fontHeight)];
				length -= (_maxColumn - x);
			}
			x = 0;
			y++;
		}
	}
    [pool release];
}

#pragma mark -
#pragma mark Override
- (BOOL)isFlipped {
	return NO;
}

- (BOOL)isOpaque {
	return YES;
}

- (BOOL)acceptsFirstResponder {
	return YES;
}

- (BOOL)canBecomeKeyView {
    return YES;
}

+ (NSMenu *)defaultMenu {
    return [[[NSMenu alloc] init] autorelease];
}

/* Otherwise, it will return the subview. */
- (NSView *)hitTest:(NSPoint)p {
    return self;
}

- (void)resetCursorRects {
	[super resetCursorRects];
	[self refreshMouseHotspot];
	return;
}

// For full screen
- (void)viewDidMoveToWindow {
	[self refreshDisplay];
	[self refreshMouseHotspot];
}

- (void)setFrame:(NSRect)frameRect {
	[super setFrame:frameRect];
	[_effectView resize];
}

#pragma mark -
#pragma mark Accessor
- (NSString *)selectedPlainString {
    if (_selectionLength == 0) return nil;
    
	if (!_hasRectangleSelected) {
		int location, length;
		if (_selectionLength >= 0) {
			location = _selectionLocation;
			length = _selectionLength;
		} else {
			location = _selectionLocation + _selectionLength;
			length = 0 - (int)_selectionLength;
		}
		return [[self frontMostTerminal] stringAtIndex:location length:length];
	} else {
		// Rectangle selection
		NSRect selectedRect = [self selectedRect];
		NSMutableString *string = [NSMutableString string];
		for (int r = selectedRect.origin.y; r < selectedRect.origin.y + selectedRect.size.height; ++r) {
			NSString *str = [[self frontMostTerminal] stringAtIndex:(r * _maxColumn + selectedRect.origin.x) 
															   length:selectedRect.size.width];
			if (str)
				[string appendString:str];
			if (r == selectedRect.origin.y + selectedRect.size.height - 1)
				break;
			[string appendString:@"\n"];
		}
		return string;
	}
}

- (BOOL)shouldEnableMouse {
	return [[[self frontMostConnection] site] shouldEnableMouse];
}

- (YLANSIColorKey)ansiColorKey {
	return [[[self frontMostConnection] site] ansiColorKey];
}

- (BOOL)shouldWarnCompose {
	return ([[self frontMostTerminal] bbsState].state != BBSComposePost);
}

- (void) showCustomizedPopUpMessage:(NSString *) message {
    [WLPopUpMessage showPopUpMessage:message 
                            duration:0.5
                          effectView:_effectView];
}

#pragma mark -
#pragma mark NSTextInput Protocol
/* NSTextInput protocol */
// instead of keyDown: aString can be NSString or NSAttributedString
- (void)insertText:(id)aString {
    [self insertText:aString withDelay:0];
}

- (void)insertText:(id)aString 
		 withDelay:(int)microsecond {
	if (![self frontMostConnection] || ![[self frontMostConnection] isConnected])
		return;
	
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    [_textField setHidden:YES];
    [_markedText release];
    _markedText = nil;
	
    [[self frontMostConnection] sendText:aString withDelay:microsecond];

    [pool release];
}

- (void)doCommandBySelector:(SEL)aSelector {
	unsigned char ch[10];
    
	if (aSelector == @selector(insertNewline:)) {
		ch[0] = 0x0D;
		[[self frontMostConnection] sendBytes:ch length:1];
    } else if (aSelector == @selector(cancelOperation:)) {
        ch[0] = 0x1B;
		[[self frontMostConnection] sendBytes:ch length:1];
	} else if (aSelector == @selector(scrollToBeginningOfDocument:) ||
			   aSelector == @selector(moveToBeginningOfLine:)) {
        ch[0] = 0x1B; ch[1] = '['; ch[2] = '1'; ch[3] = '~';
		[[self frontMostConnection] sendBytes:ch length:4];		
	} else if (aSelector == @selector(scrollToEndOfDocument:) ||
			   aSelector == @selector(moveToEndOfLine:)) {
        ch[0] = 0x1B; ch[1] = '['; ch[2] = '4'; ch[3] = '~';
		[[self frontMostConnection] sendBytes:ch length:4];		
	} else if (aSelector == @selector(scrollPageUp:) ||
			   aSelector == @selector(pageUp:)) {
		ch[0] = 0x1B; ch[1] = '['; ch[2] = '5'; ch[3] = '~';
		[[self frontMostConnection] sendBytes:ch length:4];
	} else if (aSelector == @selector(scrollPageDown:) ||
			   aSelector == @selector(pageDown:)) {
		ch[0] = 0x1B; ch[1] = '['; ch[2] = '6'; ch[3] = '~';
		[[self frontMostConnection] sendBytes:ch length:4];		
	} else if (aSelector == @selector(insertTab:)) {
        ch[0] = 0x09;
		[[self frontMostConnection] sendBytes:ch length:1];
    } else if (aSelector == @selector(deleteForward:)) {
		ch[0] = 0x1B; ch[1] = '['; ch[2] = '3'; ch[3] = '~';
		ch[4] = 0x1B; ch[5] = '['; ch[6] = '3'; ch[7] = '~';
        int len = 4;
        id ds = [self frontMostTerminal];
        if ([[[self frontMostConnection] site] shouldDetectDoubleByte] && 
            [ds cursorColumn] < (_maxColumn - 1) && 
            [ds attrAtRow:[ds cursorRow] column:[ds cursorColumn] + 1].f.doubleByte == 2)
            len += 4;
        [[self frontMostConnection] sendBytes:ch length:len];
    } else if (aSelector == @selector(insertTabIgnoringFieldEditor:)) { // Now do URL mode switching
		[self switchURL];
	} else {
        NSLog(@"Unprocessed selector: %@", NSStringFromSelector(aSelector));
    }
}

// setMarkedText: cannot take a nil first argument. aString can be NSString or NSAttributedString
- (void)setMarkedText:(id)aString 
		selectedRange:(NSRange)selRange {
    WLTerminal *ds = [self frontMostTerminal];
	if (![aString respondsToSelector:@selector(isEqualToAttributedString:)] && [aString isMemberOfClass:[NSString class]])
		aString = [[[NSAttributedString alloc] initWithString:aString] autorelease];

	if ([aString length] == 0) {
		[self unmarkText];
		return;
	}
	
	if (_markedText != aString) {
		[_markedText release];
		_markedText = [aString retain];
	}
	_selectedRange = selRange;
	_markedRange.location = 0;
	_markedRange.length = [aString length];
		
	[_textField setString:aString];
	[_textField setSelectedRange:selRange];
	[_textField setMarkedRange:_markedRange];

	NSPoint o = NSMakePoint([ds cursorColumn] * _fontWidth, (_maxRow - 1 - [ds cursorRow]) * _fontHeight + 5.0);
	CGFloat dy;
	if (o.x + [_textField frame].size.width > _maxColumn * _fontWidth) 
		o.x = _maxColumn * _fontWidth - [_textField frame].size.width;
	if (o.y + [_textField frame].size.height > _maxRow * _fontHeight) {
		o.y = (_maxRow - [ds cursorRow]) * _fontHeight - 5.0 - [_textField frame].size.height;
		dy = o.y + [_textField frame].size.height;
	} else {
		dy = o.y;
	}
	[_textField setFrameOrigin:o];
	[_textField setDestination:[_textField convertPoint:NSMakePoint(([ds cursorColumn] + 0.5) * _fontWidth, dy)
											   fromView:self]];
	[_textField setHidden:NO];
}

- (void)unmarkText {
    [_markedText release];
    _markedText = nil;
    [_textField setHidden:YES];
}

- (BOOL)hasMarkedText {
    return (_markedText != nil);
}

- (NSInteger)conversationIdentifier {
    return (NSInteger)self;
}

// Returns attributed string at the range.  This allows input mangers to query any range in backing-store.  May return nil.
- (NSAttributedString *)attributedSubstringFromRange:(NSRange)theRange {
    if (theRange.location >= [_markedText length]) return nil;
    if (theRange.location + theRange.length > [_markedText length]) 
        theRange.length = [_markedText length] - theRange.location;
    return [[[NSAttributedString alloc] initWithString:[[_markedText string] substringWithRange:theRange]] autorelease];
}

// This method returns the range for marked region.  If hasMarkedText == false, it'll return NSNotFound location & 0 length range.
- (NSRange)markedRange {
    return _markedRange;
}

// This method returns the range for selected region.  Just like markedRange method, its location field contains char index from the text beginning.
- (NSRange)selectedRange {
    return _selectedRange;
}

// This method returns the first frame of rects for theRange in screen coordindate system.
- (NSRect)firstRectForCharacterRange:(NSRange)theRange {
    NSPoint pointInWindowCoordinates;
    NSRect rectInScreenCoordinates;

    pointInWindowCoordinates = [_textField frame].origin;
    //[_textField convertPoint: [_textField frame].origin toView: nil];
    rectInScreenCoordinates.origin = [[_textField window] convertBaseToScreen:pointInWindowCoordinates];
    rectInScreenCoordinates.size = [_textField bounds].size;

    return rectInScreenCoordinates;
}

// This method returns the index for character that is nearest to thePoint.  thPoint is in screen coordinate system.
- (NSUInteger)characterIndexForPoint:(NSPoint)thePoint {
    return 0;
}

// This method is the key to attribute extension.  We could add new attributes through this method. NSInputServer examines the return value of this method & constructs appropriate attributed string.
- (NSArray*)validAttributesForMarkedText {
    return [NSArray array];
}

#pragma mark -
#pragma mark Url Menu
// Here I hijacked the option-tab key mapping...
// by gtCarrera, for URL menu
- (void)switchURL {
	// Now, just return...
	// return;
	// If not in URL mode, turn this mode on
	
	if(!_isInUrlMode) {
		_isInUrlMode = YES;
		[WLPopUpMessage showPopUpMessage:NSLocalizedString(@"URL Mode", @"URL Mode") 
								duration:0.5
							  effectView:_effectView];
		// For Test
		NSPoint p = [_urlManager currentSelectedURLPos];
		if(p.x < 0 || p.y < 0) { // No urls available
			[self exitURL];
			return;
		}
		[_effectView showIndicatorAtPoint:p];
	} else {
		// Move next
		[_effectView showIndicatorAtPoint:[_urlManager moveNext]];
	}
}

- (void)exitURL {
	if(!_isInUrlMode)
		return;
	[_effectView removeIndicator];
	[WLPopUpMessage showPopUpMessage:NSLocalizedString(@"Normal Mode", @"Normal Mode")
							duration:0.5
						  effectView:_effectView];
	_isInUrlMode = NO;
}

#pragma mark -
#pragma mark mouse operation
- (void)deactivateMouseForKeying {
	_isKeying = YES;
	[NSTimer scheduledTimerWithTimeInterval:disableMouseByKeyingTimerInterval
									 target:self 
								   selector:@selector(activateMouseForKeying:)
								   userInfo:nil
									repeats:NO];
}

- (void)activateMouseForKeying:(NSTimer*)timer {
	_isKeying = NO;
}

#pragma mark -
#pragma mark WLTabItemContentObserver protocol
- (void)didChangeContent:(id)content {
	// Clear
	[self clearSelection];
	[self exitURL];
	[_effectView clear];
	
	// Inform super class about the change
	[super didChangeContent:content];
	
	// Update contents
	if (content == nil) {
		[_effectView setHidden:YES];
	} else {
		[_effectView setHidden:NO];
		
		// Pop up a message indicating the selected site
		[WLPopUpMessage showPopUpMessage:[[(WLConnection *)content site] name]
								duration:1.2
							  effectView:_effectView];
	}
	[self refreshMouseHotspot];
}

#pragma mark -
#pragma mark WLTerminalObserver protocol
- (void)terminalDidUpdate:(WLTerminal *)terminal {
	if (terminal == [self frontMostTerminal]) {
		//[self updateBackedImage];
		//[self setNeedsDisplay:YES];
		[self refreshMouseHotspot];
	}
	[super terminalDidUpdate:terminal];
}

#pragma mark -
#pragma mark NSAccessibility protocol
- (BOOL)accessibilityIsIgnored {
	return NO;
}

- (id)accessibilityAttributeValue:(NSString *)attribute {
	if ([attribute isEqual:NSAccessibilityRoleAttribute]) {
		return NSAccessibilityTextAreaRole;
	} else if ([attribute isEqual:NSAccessibilitySelectedTextRangeAttribute]) {
		if (_selectionLength > 0) {
			return [NSValue valueWithRange:NSMakeRange(_selectionLocation, _selectionLength)];
		} else if (_selectionLength < 0) {
			return [NSValue valueWithRange:NSMakeRange(_selectionLocation + _selectionLength, abs(_selectionLength))];
		} else {
			// A weird workaround
			return [self accessibilityAttributeValue:NSAccessibilityRangeForPositionParameterizedAttribute 
										forParameter:[NSValue valueWithPoint:[NSEvent mouseLocation]]];
		}
	} else if ([attribute isEqual:NSAccessibilityNumberOfCharactersAttribute]) {
		if (_selectionLength != 0) {
			return [NSNumber numberWithUnsignedInteger:_selectionLength];
		} else {
			return [NSNumber numberWithUnsignedInteger:[self rangeForWordAtPoint:[self mouseLocationInView]].length];
		}
	}
	return nil;
}

- (id)accessibilityAttributeValue:(NSString *)attribute forParameter:(id)parameter {
	if ([attribute isEqual:NSAccessibilityRangeForPositionParameterizedAttribute]) {
		NSPoint point = [self convertPoint:[[self window] convertScreenToBase:[(NSValue *)parameter pointValue]] fromView:nil];
		return [NSValue valueWithRange:[self rangeForWordAtPoint:point]];
	} else if ([attribute isEqual:NSAccessibilityStringForRangeParameterizedAttribute]) {
		NSRange range = [(NSValue *)parameter rangeValue];
		return [[self frontMostTerminal] stringAtIndex:range.location length:range.length];
	} else if ([attribute isEqual:NSAccessibilityRTFForRangeParameterizedAttribute]) {
		NSRange range = [(NSValue *)parameter rangeValue];
		NSAttributedString *attrString = [[self frontMostTerminal] attributedStringAtIndex:range.location 
																					length:range.length];
		return [attrString RTFFromRange:NSMakeRange(0, [attrString length]) documentAttributes:nil];
	} else if ([attribute isEqual:NSAccessibilityLineForIndexParameterizedAttribute]) {
		NSUInteger index = [(NSNumber *)parameter unsignedIntegerValue];
		return [NSNumber numberWithUnsignedInteger:(index/_maxColumn)];
	} else if ([attribute isEqual:NSAccessibilityRangeForLineParameterizedAttribute]) {
		NSUInteger line = [(NSNumber *)parameter unsignedIntegerValue];
		return [NSValue valueWithRange:NSMakeRange(line * _maxColumn, _maxColumn)];
	} else if ([attribute isEqual:NSAccessibilityBoundsForRangeParameterizedAttribute]) {
		NSRange range = [(NSValue *)parameter rangeValue];
		NSRect rect = [self rectAtRow:range.location/_maxColumn 
							   column:range.location%_maxColumn
							   height:1 
								width:range.length];
		rect = [self convertRect:rect toView:nil];
		rect.origin = [[self window] convertBaseToScreen:rect.origin];
		return [NSValue valueWithRect:rect];
	}
	return nil;
}
@end