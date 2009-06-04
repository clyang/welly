//
//  YLView.m
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/6/9.
//  Copyright 2006 yllan.org. All rights reserved.
//

#import "YLView.h"
#import "YLTerminal.h"
#import "YLConnection.h"
#import "YLSite.h"
#import "YLLGLobalConfig.h"
#import "YLMarkedTextView.h"
#import "YLContextualMenuManager.h"
#import "WLPreviewController.h"
#import "WLPortal.h"
#import "WLIntegerArray.h"
#import "IPSeeker.h"
#import "WLMouseBehaviorManager.h"
#import "WLURLManager.h"
#import "WLPopUpMessage.h"
#import "WLAnsiColorOperationManager.h"

#include "encoding.h"
#include <math.h>

const float WLActivityCheckingTimeInteval = 5.0;


static YLLGlobalConfig *gConfig;
static int gRow;
static int gColumn;
static NSImage *gLeftImage;
static CGSize *gSingleAdvance;
static CGSize *gDoubleAdvance;

NSString *const ANSIColorPBoardType = @"ANSIColorPBoardType";

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

BOOL isEnglishNumberAlphabet(unsigned char c) {
    return ('0' <= c && c <= '9') || ('A' <= c && c <= 'Z') || ('a' <= c && c <= 'z') || (c == '-') || (c == '_') || (c == '.');
}

BOOL isSpecialSymbol(unichar ch) {
	if (ch == 0x25FC)  // ◼ BLACK SQUARE
		return YES;
	if (ch >= 0x2581 && ch <= 0x2588) // BLOCK ▁▂▃▄▅▆▇█
		return YES;
	if (ch >= 0x2589 && ch <= 0x258F) // BLOCK ▉▊▋▌▍▎▏
		return YES;
	if (ch >= 0x25E2 && ch <= 0x25E5) // TRIANGLE ◢◣◤◥
		return YES;
	return NO;
}

@interface YLView ()
- (void)drawSpecialSymbol:(unichar)ch 
				   forRow:(int)r 
				   column:(int)c 
			leftAttribute:(attribute)attr1 
		   rightAttribute:(attribute)attr2;

// safe_paste
- (void)confirmPaste:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)confirmPasteWrap:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)confirmPasteColor:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)performPaste;
- (void)performPasteWrap;
- (void)performPasteColor;
@end

@implementation YLView
@synthesize isInPortalMode = _isInPortalMode;
@synthesize isInUrlMode = _isInUrlMode;
@synthesize isMouseActive = _isMouseActive;
@synthesize fontWidth = _fontWidth;
@synthesize fontHeight = _fontHeight;
@synthesize effectView = _effectView;

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
    if (!gConfig) gConfig = [YLLGlobalConfig sharedInstance];
	gColumn = [gConfig column];
	gRow = [gConfig row];
    _fontWidth = [gConfig cellWidth];
    _fontHeight = [gConfig cellHeight];
	
    NSRect frame = [self frame];
	frame.size = NSMakeSize(gColumn * [gConfig cellWidth], gRow * [gConfig cellHeight]);
    frame.origin = NSZeroPoint;
    [self setFrame:frame];

    [self createSymbolPath];

    [_backedImage release];
    _backedImage = [[NSImage alloc] initWithSize:frame.size];
    [_backedImage setFlipped:NO];

    [gLeftImage release]; 
    gLeftImage = [[NSImage alloc] initWithSize:NSMakeSize(_fontWidth, _fontHeight)];			

    if (!gSingleAdvance) gSingleAdvance = (CGSize *) malloc(sizeof(CGSize) * gColumn);
    if (!gDoubleAdvance) gDoubleAdvance = (CGSize *) malloc(sizeof(CGSize) * gColumn);

    for (int i = 0; i < gColumn; i++) {
        gSingleAdvance[i] = CGSizeMake(_fontWidth * 1.0, 0.0);
        gDoubleAdvance[i] = CGSizeMake(_fontWidth * 2.0, 0.0);
    }
    [_markedText release];
    _markedText = nil;

    _selectedRange = NSMakeRange(NSNotFound, 0);
    _markedRange = NSMakeRange(NSNotFound, 0);
    
    [_textField setHidden: YES];
}

- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self configure];
        _selectionLength = 0;
        _selectionLocation = 0;
		_isInPortalMode = NO;
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
    }
    return self;
}

- (void)dealloc {
    [_backedImage release];
    [_portal release];
	[_mouseBehaviorDelegate dealloc];
    [super dealloc];
}

#pragma mark -
#pragma mark Conversion

- (int)convertIndexFromPoint:(NSPoint)p {
	// The following 2 lines: for full screen mode
	NSRect frame = [self frame];
	p.y -= 2 * frame.origin.y;
	
    if (p.x >= gColumn * _fontWidth) p.x = gColumn * _fontWidth - 0.001;
    if (p.y >= gRow * _fontHeight) p.y = gRow * _fontHeight - 0.001;
    if (p.x < 0) p.x = 0;
    if (p.y < 0) p.y = 0;
    int cx, cy = 0;
    cx = (int) ((CGFloat) p.x / _fontWidth);
    cy = gRow - (int) ((CGFloat) p.y / _fontHeight) - 1;
    return cy * gColumn + cx;
}

- (NSRect)rectAtRow:(int)r 
			 column:(int)c 
			 height:(int)h 
			  width:(int)w {
	return NSMakeRect(c * _fontWidth, (gRow - h - r) * _fontHeight, _fontWidth * w, _fontHeight * h);
}

- (NSRect)selectedRect {
	if (_selectionLength == 0)
		return NSZeroRect;
	
	int startIndex = _selectionLocation;
	int endIndex = startIndex + _selectionLength;
	if (_selectionLength > 0)
		--endIndex;
	
	int row = startIndex / gColumn;
	int column = startIndex % gColumn;
	int endRow = endIndex / gColumn;
	int endColumn = endIndex % gColumn;
	
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
	if ([types containsObject: NSStringPboardType]) {
		NSString *str = [pb stringForType: NSStringPboardType];
		//[self insertText:str withDelay:100];
		[self insertText:str withDelay:0];
	}
}

- (void)performPasteWrap {
	NSPasteboard *pb = [NSPasteboard generalPasteboard];
	NSArray *types = [pb types];
	if (![types containsObject:NSStringPboardType]) return;
	
	NSString *str = [pb stringForType:NSStringPboardType];
	int i, j, LINE_WIDTH = 66, LPADDING = 4;
	WLIntegerArray *word = [WLIntegerArray integerArray];
	WLIntegerArray *text = [WLIntegerArray integerArray];
	int word_width = 0, line_width = 0;
	[text push_back:0x000d];
	for (i = 0; i < LPADDING; i++)
		[text push_back:0x0020];
	line_width = LPADDING;
	for (i = 0; i < [str length]; i++) {
		unichar c = [str characterAtIndex:i];
		if (c == 0x0020 || c == 0x0009) { // space
			for (j = 0; j < [word size]; j++)
				[text push_back:[word at:j]];
			[word clear];
			line_width += word_width;
			word_width = 0;
			if (line_width >= LINE_WIDTH + LPADDING) {
				[text push_back:0x000d];
				for (j = 0; j < LPADDING; j++)
					[text push_back:0x0020];
				line_width = LPADDING;
			}
			int repeat = (c == 0x0020) ? 1 : 4;
			for (j = 0; j < repeat ; j++)
				[text push_back:0x0020];
			line_width += repeat;
		} else if (c == 0x000a || c == 0x000d) {
			for (j = 0; j < [word size]; j++)
				[text push_back:[word at:j]];
			[word clear];
			[text push_back:0x000d];
			//            [text push_back:0x000d];
			for (j = 0; j < LPADDING; j++)
				[text push_back:0x0020];
			line_width = LPADDING;
			word_width = 0;
		} else if (c > 0x0020 && c < 0x0100) {
			[word push_back:c];
			word_width++;
			if (c >= 0x0080) word_width++;
		} else if (c >= 0x1000){
			for (j = 0; j < [word size]; j++)
				[text push_back:[word at:j]];
			[word clear];
			line_width += word_width;
			word_width = 0;
			if (line_width >= LINE_WIDTH + LPADDING) {
				[text push_back:0x000d];
				for (j = 0; j < LPADDING; j++)
					[text push_back:0x0020];
				line_width = LPADDING;
			}
			[text push_back:c];
			line_width += 2;
		} else {
			[word push_back:c];
		}
		if (line_width + word_width > LINE_WIDTH + LPADDING) {
			[text push_back:0x000d];
			for (j = 0; j < LPADDING; j++)
				[text push_back:0x0020];
			line_width = LPADDING;
		}
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
					for (j = 0; j < LPADDING; j++)
						[text push_back:0x0020];
					line_width = LPADDING;
					word_width -= acc_width;
				}
			}
		}
	}
	while (![word empty]) {
		[text push_back:[word front]];
		[word pop_front];
	}
	unichar *carray = (unichar *)malloc(sizeof(unichar) * [text size]);
	for (i = 0; i < [text size]; i++)
		carray[i] = [text at:i];
	NSString *mStr = [NSString stringWithCharacters:carray length:[text size]];
	free(carray);
	//[self insertText:mStr withDelay:100];		
	[self insertText:mStr withDelay:0];
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
		NSAttributedString *rtfString = [[NSAttributedString alloc]
										 initWithRTF:[pb dataForType:NSRTFPboardType] 
										 documentAttributes:nil];
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

- (BOOL)needsWarnPaste {
	return [[NSUserDefaults standardUserDefaults] boolForKey:WLSafePasteEnabledKeyName] && [[self frontMostTerminal] bbsState].state != BBSComposePost;
}

- (void)pasteColor:(id)sender {
    if (![self isConnected]) return;
	if ([self needsWarnPaste]) {
		[self warnPasteWithSelector:@selector(confirmPasteColor:returnCode:contextInfo:)];
	} else {
		[self performPasteColor];
	}
}

- (void)paste:(id)sender {
    if (![self isConnected]) return;
	if ([self needsWarnPaste]) {
		[self warnPasteWithSelector:@selector(confirmPaste:returnCode:contextInfo:)];
	} else {
		[self performPaste];
	}
}

- (void)pasteWrap:(id)sender {
    if (![self isConnected]) return;
	if ([self needsWarnPaste]) {
		[self warnPasteWithSelector:@selector(confirmPasteWrap:returnCode:contextInfo:)];
	} else {
		[self performPasteWrap];
	}
}

- (void)selectAll:(id)sender {
    if (![self isConnected]) return;
    _selectionLocation = 0;
    _selectionLength = gRow * gColumn;
    [self setNeedsDisplay: YES];
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

- (void)refreshHiddenRegion {
    if (![self isConnected]) return;
    int i, j;
    for (i = 0; i < gRow; i++) {
        cell *currRow = [[self frontMostTerminal] cellsOfRow:i];
        for (j = 0; j < gColumn; j++)
            if (isHiddenAttribute(currRow[j].attr)) 
                [[self frontMostTerminal] setDirty:YES atRow:i column:j];
    }
}

- (void)sendText:(NSString *)text {
	[[self frontMostConnection] sendText:text];
}

- (void)refreshMouseHotspot {
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
- (void)selectChineseWord:(id)sender {
	_selectionLength = 2;
	// TODO(K.O.ed): select whole sentence instead
}

- (void)selectWord:(id)sender {
	int r = _selectionLocation / gColumn;
	int c = _selectionLocation % gColumn;
	cell *currRow = [[self frontMostTerminal] cellsOfRow:r];
	[[self frontMostTerminal] updateDoubleByteStateForRow:r];
	if (currRow[c].attr.f.doubleByte == 1) { // Double Byte
		[self selectChineseWord:self];
	} else if (currRow[c].attr.f.doubleByte == 2) {
		_selectionLocation--;
		[self selectChineseWord:self];
	} else if (isEnglishNumberAlphabet(currRow[c].byte)) { // Not Double Byte
		for (; c >= 0; c--) {
			if (isEnglishNumberAlphabet(currRow[c].byte) && currRow[c].attr.f.doubleByte == 0) 
				_selectionLocation = r * gColumn + c;
			else 
				break;
		}
		for (c = c + 1; c < gColumn; c++) {
			if (isEnglishNumberAlphabet(currRow[c].byte) && currRow[c].attr.f.doubleByte == 0) 
				_selectionLength++;
			else 
				break;
		}
	} else {
		_selectionLength = 1;
	}
}

- (void)mouseDown:(NSEvent *)theEvent {
	[self hasMouseActivity];
	[[self frontMostConnection] resetMessageCount];
    [[self window] makeFirstResponder:self];

    NSPoint p = [theEvent locationInWindow];
    p = [self convertPoint:p toView:nil];
    // portal
    if (_isInPortalMode) {
        //[_portal clickAtPoint:p count:[theEvent clickCount]];
		[_portal mouseDown:theEvent];
        return;
    }

    if (![self isConnected]) 
		return;
	// Disable the mouse if we cancelled any selection
	if(abs(_selectionLength) > 0) 
		_isNotCancelingSelection = NO;
    _selectionLocation = [self convertIndexFromPoint:p];
    _selectionLength = 0;
    
    if (([theEvent modifierFlags] & NSCommandKeyMask) == 0x00 &&
        [theEvent clickCount] == 3) {
        _selectionLocation = _selectionLocation - (_selectionLocation % gColumn);
        _selectionLength = gColumn;
    } else if (([theEvent modifierFlags] & NSCommandKeyMask) == 0x00 &&
               [theEvent clickCount] == 2) {
		[self selectWord:self];
    }
    
    [self setNeedsDisplay: YES];
	//    [super mouseDown: e];
}

- (void)mouseDragged:(NSEvent *)e {
	[self hasMouseActivity];
	// portal
    if (_isInPortalMode) {
		[_portal mouseDragged:e];
        return;
    }
    if (![self isConnected]) return;
    NSPoint p = [e locationInWindow];
    p = [self convertPoint:p toView:nil];
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
	// portal
    if (_isInPortalMode) {
		[_portal mouseUp:theEvent];
        return;
    }
	
    if (![self isConnected]) return;
    // open url
	NSPoint p = [theEvent locationInWindow];
    p = [self convertPoint:p toView:nil];

    if (abs(_selectionLength) <= 1 && _isNotCancelingSelection && !_isKeying && !_isInUrlMode) {
		[_mouseBehaviorDelegate mouseUp:theEvent];
    }
	_isNotCancelingSelection = YES;
}

- (void)mouseMoved:(NSEvent *)theEvent {
	//NSLog(@"mouseMoved:");
	[self hasMouseActivity];
}

- (void)scrollWheel:(NSEvent *)theEvent {
	[self hasMouseActivity];
    // portal
    if (_isInPortalMode) {
        if ([theEvent deltaX] > 0)
            [_portal moveSelection:-1];
        else if ([theEvent deltaX] < 0)
            [_portal moveSelection:+1];
		else if ([theEvent deltaY] > 0)
            [_portal moveSelection:-1];
        else if ([theEvent deltaY] < 0)
            [_portal moveSelection:+1];
    }
	[self clearSelection];
	[_mouseBehaviorDelegate scrollWheel:theEvent];
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
    if (![self isConnected])
        return nil;
    NSString *s = [self selectedPlainString];
	if (s != nil)
		return [YLContextualMenuManager menuWithSelectedString:s];
	else
		return [_mouseBehaviorDelegate menuForEvent:theEvent];
}

- (void)keyDown:(NSEvent *)theEvent {    
    [[self frontMostConnection] resetMessageCount];
	
    unichar c = [[theEvent characters] characterAtIndex:0];
    // portal
    if (_isInPortalMode) {
        switch (c) {
        case NSLeftArrowFunctionKey:
            [_portal moveSelection:-1];
            break;
        case NSRightArrowFunctionKey:
            [_portal moveSelection:+1];
            break;
        case WLWhitespaceCharacter:
        case WLReturnCharacter:
            [_portal select];
            break;
        }
        return;
    }
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

    YLTerminal *ds = [self frontMostTerminal];

    if (([theEvent modifierFlags] & NSControlKeyMask) &&
	   (([theEvent modifierFlags] & NSAlternateKeyMask) == 0 )) {
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
	
	[super flagsChanged: event];
}

- (void)clearSelection {
    if (_selectionLength != 0) {
        _selectionLength = 0;
		_isNotCancelingSelection = NO;
        [self setNeedsDisplay:YES];
    }
}

#pragma mark -
#pragma mark Drawing
- (void)displayCellAtRow:(int)r 
				  column:(int)c {
    [self setNeedsDisplayInRect:NSMakeRect(c * _fontWidth, (gRow - 1 - r) * _fontHeight, _fontWidth, _fontHeight)];
}

- (void)tick:(NSArray *)a {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
	[self updateBackedImage];
    YLTerminal *ds = [self frontMostTerminal];

	if (ds && (_x != [ds cursorColumn] || _y != [ds cursorRow])) {
		[self setNeedsDisplayInRect:NSMakeRect(_x * _fontWidth, (gRow - 1 - _y) * _fontHeight, _fontWidth, _fontHeight)];
		[self setNeedsDisplayInRect:NSMakeRect([ds cursorColumn] * _fontWidth, (gRow - 1 - [ds cursorRow]) * _fontHeight, _fontWidth, _fontHeight)];
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
    YLTerminal *ds = [self frontMostTerminal];
	if ([self isConnected]) {
		// NSLog(@"connected");
		// Modified by gtCarrera
		// Draw the background color first!!!
		[[gConfig colorBG] set];
        NSRect retangle = [self bounds];
		NSRectFill(retangle);
        /* Draw the backed image */
		
		NSRect imgRect = rect;
		imgRect.origin.y = (_fontHeight * gRow) - rect.origin.y - rect.size.height;
		[_backedImage compositeToPoint:rect.origin
							  fromRect:rect
							 operation:NSCompositeCopy];
        [self drawBlink];
        
        /* Draw the url underline */
//        int c, r;
//        [[NSColor orangeColor] set];
//        [NSBezierPath setDefaultLineWidth: 1.0];
//        for (r = 0; r < gRow; r++) {
//            cell *currRow = [ds cellsOfRow:r];
//            for (c = 0; c < gColumn; c++) {
//                int start;
//                for (start = c; c < gColumn && currRow[c].attr.f.url; c++) ;
//                if (c != start) {
////                    [NSBezierPath strokeLineFromPoint:NSMakePoint(start * _fontWidth, (gRow - r - 1) * _fontHeight + 0.5) 
////                                              toPoint:NSMakePoint(c * _fontWidth, (gRow - r - 1) * _fontHeight + 0.5)];
//					//[self drawURLUnderlineAtRow:r fromColumn:start toColumn:c];
//                }
//            }
//        }
        
		/* Draw the cursor */
		[[NSColor whiteColor] set];
		[NSBezierPath setDefaultLineWidth:2.0];
		[NSBezierPath strokeLineFromPoint:NSMakePoint([ds cursorColumn] * _fontWidth, (gRow - 1 - [ds cursorRow]) * _fontHeight + 1) 
								  toPoint:NSMakePoint(([ds cursorColumn] + 1) * _fontWidth, (gRow - 1 - [ds cursorRow]) * _fontHeight + 1) ];
        [NSBezierPath setDefaultLineWidth:1.0];
        _x = [ds cursorColumn], _y = [ds cursorRow];

        /* Draw the selection */
        if (_selectionLength != 0) 
            [self drawSelection];
	} else {
		// NSLog(@"Not connected!");
		[[gConfig colorBG] set];
        NSRect r = [self bounds];
        NSRectFill(r);
	}
	
	[_effectView resize];
    [pool release];
}

- (void)drawURLUnderlineAtRow:(int)r 
				   fromColumn:(int)start 
					 toColumn:(int)end {
	//NSLog(@"[drawURLUnderlineAtRow:%d fromColumn:%d toColumn:%d];", r, start, end);
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	[NSGraphicsContext saveGraphicsState];
	
	// ...Draw content using NS APIs...
	[[NSColor orangeColor] set];
	[NSBezierPath setDefaultLineWidth: 1.0];
	
	[NSBezierPath strokeLineFromPoint:NSMakePoint(start * _fontWidth, (gRow - r - 1) * _fontHeight + 0.5) 
							  toPoint:NSMakePoint(end * _fontWidth, (gRow - r - 1) * _fontHeight + 0.5)];
	
	[NSGraphicsContext restoreGraphicsState];

	[self setNeedsDisplay:YES];
	[pool release];
}

- (void)drawBlink {
    if (![gConfig blinkTicker]) return;

    NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
    int c, r;
    id ds = [self frontMostTerminal];
    if (!ds) return;
    for (r = 0; r < gRow; r++) {
        cell *currRow = [ds cellsOfRow: r];
        for (c = 0; c < gColumn; c++) {
            if (isBlinkCell(currRow[c])) {
                int bgColorIndex = currRow[c].attr.f.reverse ? currRow[c].attr.f.fgColor : currRow[c].attr.f.bgColor;
                BOOL bold = currRow[c].attr.f.reverse ? currRow[c].attr.f.bold : NO;
				
				// Modified by K.O.ed: All background color use same alpha setting.
				NSColor *bgColor = [gConfig colorAtIndex:bgColorIndex hilite:bold];
				bgColor = [bgColor colorWithAlphaComponent:[[gConfig colorBG] alphaComponent]];
				[bgColor set];
                //[[gConfig colorAtIndex: bgColorIndex hilite: bold] set];
                NSRectFill(NSMakeRect(c * _fontWidth, (gRow - r - 1) * _fontHeight, _fontWidth, _fontHeight));
            }
        }
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
    int x = location % gColumn;
    int y = location / gColumn;
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
			if (x + length <= gColumn) { // one-line
				[NSBezierPath fillRect:NSMakeRect(x * _fontWidth, (gRow - y - 1) * _fontHeight, _fontWidth * length, _fontHeight)];
				length = 0;
			} else {
				[NSBezierPath fillRect:NSMakeRect(x * _fontWidth, (gRow - y - 1) * _fontHeight, _fontWidth * (gColumn - x), _fontHeight)];
				length -= (gColumn - x);
			}
			x = 0;
			y++;
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
	[_backedImage compositeToPoint:NSMakePoint(0, (gRow - end) * _fontHeight) 
						  fromRect:NSMakeRect(0, (gRow - end - 1) * _fontHeight, gColumn * _fontWidth, (end - start) * _fontHeight) 
						 operation:NSCompositeCopy];

	[gConfig->_colorTable[0][gConfig->_bgColorIndex] set];
	NSRectFill(NSMakeRect(0, (gRow - end - 1) * _fontHeight, gColumn * _fontWidth, _fontHeight));
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
	[_backedImage compositeToPoint:NSMakePoint(0, (gRow - end - 1) * _fontHeight) 
						  fromRect:NSMakeRect(0, (gRow - end) * _fontHeight, gColumn * _fontWidth, (end - start) * _fontHeight) 
						 operation:NSCompositeCopy];
	
	[gConfig->_colorTable[0][gConfig->_bgColorIndex] set];
	NSRectFill(NSMakeRect(0, (gRow - start - 1) * _fontHeight, gColumn * _fontWidth, _fontHeight));
	[_backedImage unlockFocus];
    [pool release];
}

- (void)updateBackedImage {
	//NSLog(@"Image");
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
	int x, y;
    YLTerminal *ds = [self frontMostTerminal];
	[_backedImage lockFocus];
	CGContextRef myCGContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
	if (ds) {
        /* Draw Background */
        for (y = 0; y < gRow; y++) {
            for (x = 0; x < gColumn; x++) {
                if ([ds isDirtyAtRow: y column: x]) {
                    int startx = x;
                    for (; x < gColumn && [ds isDirtyAtRow:y column:x]; x++) ;
                    [self updateBackgroundForRow:y from:startx to:x];
                }
            }
        }
        CGContextSaveGState(myCGContext);
        CGContextSetShouldSmoothFonts(myCGContext, 
                                      [gConfig shouldSmoothFonts] ? true : false);
        
        /* Draw String row by row */
        for (y = 0; y < gRow; y++) {
            [self drawStringForRow:y context:myCGContext];
        }
        CGContextRestoreGState(myCGContext);
        
        for (y = 0; y < gRow; y++) {
            for (x = 0; x < gColumn; x++) {
                [ds setDirty:NO atRow:y column:x];
            }
        }
    } else {
        [[NSColor clearColor] set];
        CGContextFillRect(myCGContext, CGRectMake(0, 0, gColumn * _fontWidth, gRow * _fontHeight));
    }
	
	[self refreshMouseHotspot];
	[_backedImage unlockFocus];
    [pool release];
	return;
}

- (void)drawStringForRow:(int)r
				 context:(CGContextRef)myCGContext {
	int i, c, x;
	int start, end;
	unichar textBuf[gColumn];
	BOOL isDoubleByte[gColumn];
	BOOL isDoubleColor[gColumn];
	int bufIndex[gColumn];
	int runLength[gColumn];
	CGPoint position[gColumn];
	int bufLength = 0;
    
    CGFloat ePaddingLeft = [gConfig englishFontPaddingLeft], ePaddingBottom = [gConfig englishFontPaddingBottom];
    CGFloat cPaddingLeft = [gConfig chineseFontPaddingLeft], cPaddingBottom = [gConfig chineseFontPaddingBottom];
    
    YLTerminal *ds = [self frontMostTerminal];
    [ds updateDoubleByteStateForRow:r];
	
    cell *currRow = [ds cellsOfRow:r];

	for (i = 0; i < gColumn; i++) 
		isDoubleColor[i] = isDoubleByte[i] = textBuf[i] = runLength[i] = 0;

    // find the first dirty position in this row
	for (x = 0; x < gColumn && ![ds isDirtyAtRow:r column:x]; x++) ;
	// all clean? great!
    if (x == gColumn) 
		return; 
    
	start = x;

    // update the information array
	for (x = start; x < gColumn; x++) {
		if (![ds isDirtyAtRow:r column:x]) 
			continue;
		end = x;
		int db = (currRow + x)->attr.f.doubleByte;

		if (db == 0) {
            isDoubleByte[bufLength] = NO;
            textBuf[bufLength] = 0x0000 + (currRow[x].byte ?: ' ');
            bufIndex[bufLength] = x;
            position[bufLength] = CGPointMake(x * _fontWidth + ePaddingLeft, (gRow - 1 - r) * _fontHeight + CTFontGetDescent(gConfig->_eCTFont) + ePaddingBottom);
            isDoubleColor[bufLength] = NO;
            bufLength++;
		} else if (db == 1) {
			continue;
		} else if (db == 2) {
			unsigned short code = (((currRow + x - 1)->byte) << 8) + ((currRow + x)->byte) - 0x8000;
			unichar ch = [[[self frontMostConnection] site] encoding] == YLBig5Encoding ? B2U[code] : G2U[code];
			//NSLog(@"r = %d, x = %d, ch = %d", r, x, ch);
			if (isSpecialSymbol(ch)) {
				[self drawSpecialSymbol:ch forRow:r column:(x - 1) leftAttribute:(currRow + x - 1)->attr rightAttribute:(currRow + x)->attr];
			} else {
                isDoubleColor[bufLength] = (fgColorIndexOfAttribute(currRow[x - 1].attr) != fgColorIndexOfAttribute(currRow[x].attr) || 
                                            fgBoldOfAttribute(currRow[x - 1].attr) != fgBoldOfAttribute(currRow[x].attr));
				isDoubleByte[bufLength] = YES;
				textBuf[bufLength] = ch;
				bufIndex[bufLength] = x;
				position[bufLength] = CGPointMake((x - 1) * _fontWidth + cPaddingLeft, (gRow - 1 - r) * _fontHeight + CTFontGetDescent(gConfig->_cCTFont) + cPaddingBottom);
				bufLength++;
			}
            // FIXME: why?
			if (x == start)
				[self setNeedsDisplayInRect:NSMakeRect((x - 1) * _fontWidth, (gRow - 1 - r) * _fontHeight, _fontWidth, _fontHeight)];
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
        
        int location = runGlyphIndex = 0;
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
                CGGlyph glyph[gColumn];
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
                [gLeftImage drawAtPoint:NSMakePoint(index * _fontWidth, (gRow - 1 - r) * _fontHeight)
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
            [NSBezierPath strokeLineFromPoint:NSMakePoint(begin * _fontWidth, (gRow - 1 - r) * _fontHeight + 0.5) 
                                      toPoint:NSMakePoint(x * _fontWidth, (gRow - 1 - r) * _fontHeight + 0.5)];
            x--;
        }
    }
}

- (void)updateBackgroundForRow:(int)r 
						  from:(int)start 
							to:(int)end {
	int c;
	cell *currRow = [[self frontMostTerminal] cellsOfRow: r];
	NSRect rowRect = NSMakeRect(start * _fontWidth, (gRow - 1 - r) * _fontHeight, (end - start) * _fontWidth, _fontHeight);
	
	attribute currAttr, lastAttr = (currRow + start)->attr;
	int length = 0;
	unsigned int currentBackgroundColor;
    BOOL currentBold;
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
			NSRect rect = NSMakeRect((c - length) * _fontWidth, (gRow - 1 - r) * _fontHeight,
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
	NSPoint origin = NSMakePoint(c * _fontWidth, (gRow - 1 - r) * _fontHeight);

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

- (BOOL)becomeFirstResponder {
	//NSLog(@"becomeFirstResponder");
	return YES;
}
/* commented out by boost @ 9#: why not using the delegate...
- (void)removeTabViewItem:(NSTabViewItem *)tabViewItem {
    [[tabViewItem identifier] close];
    [super removeTabViewItem:tabViewItem];
}
*/
+ (NSMenu *)defaultMenu {
    return [[[NSMenu alloc] init] autorelease];
}

/* Otherwise, it will return the subview. */
- (NSView *)hitTest:(NSPoint)p {
    return self;
}

- (void)resetCursorRects {
	//NSLog(@"resetCursorRects!");
	[super resetCursorRects];
	[self refreshMouseHotspot];
	return;
}
#pragma mark -
#pragma mark Accessor
- (BOOL)isConnected {
	return [[self frontMostConnection] isConnected];
}

- (YLTerminal *)frontMostTerminal {
    return (YLTerminal *)[[self frontMostConnection] terminal];
}

- (YLConnection *)frontMostConnection {
    id identifier = [[self selectedTabViewItem] identifier];
    return (YLConnection *) identifier;
}

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
		return [[self frontMostTerminal] stringFromIndex:location length:length];
	} else {
		// Rectangle selection
		NSRect selectedRect = [self selectedRect];
		NSMutableString *string = [NSMutableString string];
		for (int r = selectedRect.origin.y; r < selectedRect.origin.y + selectedRect.size.height; ++r) {
			NSString *str = [[self frontMostTerminal] stringFromIndex:(r * gColumn + selectedRect.origin.x) 
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

- (BOOL)hasBlinkCell {
    int c, r;
    id ds = [self frontMostTerminal];
    if (!ds) return NO;
    for (r = 0; r < gRow; r++) {
        [ds updateDoubleByteStateForRow: r];
        cell *currRow = [ds cellsOfRow: r];
        for (c = 0; c < gColumn; c++) 
            if (isBlinkCell(currRow[c]))
                return YES;
    }
    return NO;
}

- (BOOL)shouldEnableMouse {
	return [[[self frontMostConnection] site] shouldEnableMouse];
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
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    [_textField setHidden:YES];
    [_markedText release];
    _markedText = nil;
	
    [[self frontMostConnection] sendText:aString withDelay:microsecond];

    [pool release];
}

- (void)doCommandBySelector:(SEL)aSelector {
	unsigned char ch[10];
    
//    NSLog(@"%s", aSelector);
    
	if (aSelector == @selector(insertNewline:)) {
		ch[0] = 0x0D;
		[[self frontMostConnection] sendBytes:ch length:1];
    } else if (aSelector == @selector(cancelOperation:)) {
        ch[0] = 0x1B;
		[[self frontMostConnection] sendBytes:ch length:1];
//	} else if (aSelector == @selector(cancel:)) {
	} else if (aSelector == @selector(scrollToBeginningOfDocument:)) {
        ch[0] = 0x1B; ch[1] = '['; ch[2] = '1'; ch[3] = '~';
		[[self frontMostConnection] sendBytes:ch length:4];		
	} else if (aSelector == @selector(scrollToEndOfDocument:)) {
        ch[0] = 0x1B; ch[1] = '['; ch[2] = '4'; ch[3] = '~';
		[[self frontMostConnection] sendBytes:ch length:4];		
	} else if (aSelector == @selector(scrollPageUp:)) {
		ch[0] = 0x1B; ch[1] = '['; ch[2] = '5'; ch[3] = '~';
		[[self frontMostConnection] sendBytes:ch length:4];
	} else if (aSelector == @selector(scrollPageDown:)) {
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
            [ds cursorColumn] < (gColumn - 1) && 
            [ds attrAtRow:[ds cursorRow] column:[ds cursorColumn] + 1].f.doubleByte == 2)
            len += 4;
        [[self frontMostConnection] sendBytes:ch length:len];
    } else if (aSelector == @selector(insertTabIgnoringFieldEditor:)) { // Now do URL mode switching
		[self switchURL];
	} else {
        NSLog(@"Unprocessed selector: %s", aSelector);
    }
}

// setMarkedText: cannot take a nil first argument. aString can be NSString or NSAttributedString
- (void)setMarkedText:(id)aString 
		selectedRange:(NSRange)selRange {
    YLTerminal *ds = [self frontMostTerminal];
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
	[_textField setSelectedRange: selRange];
	[_textField setMarkedRange:_markedRange];

	NSPoint o = NSMakePoint([ds cursorColumn] * _fontWidth, (gRow - 1 - [ds cursorRow]) * _fontHeight + 5.0);
	CGFloat dy;
	if (o.x + [_textField frame].size.width > gColumn * _fontWidth) 
		o.x = gColumn * _fontWidth - [_textField frame].size.width;
	if (o.y + [_textField frame].size.height > gRow * _fontHeight) {
		o.y = (gRow - [ds cursorRow]) * _fontHeight - 5.0 - [_textField frame].size.height;
		dy = o.y + [_textField frame].size.height;
	} else {
		dy = o.y;
	}
	[_textField setFrameOrigin:o];
	[_textField setDestination:[_textField convertPoint:NSMakePoint(([ds cursorColumn] + 0.5) * _fontWidth, dy)
											   fromView:self]];
	[_textField setHidden: NO];
}

- (void)unmarkText {
    [_markedText release];
    _markedText = nil;
    [_textField setHidden: YES];
}

- (BOOL)hasMarkedText {
    return (_markedText != nil);
}

- (NSInteger)conversationIdentifier {
    return (NSInteger)self;
}

// Returns attributed string at the range.  This allows input mangers to query any range in backing-store.  May return nil.
- (NSAttributedString *)attributedSubstringFromRange:(NSRange)theRange {
    if (theRange.location < 0 || theRange.location >= [_markedText length]) return nil;
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
#pragma mark Portal
// Show the portal, initiallize it if necessary
- (void)updatePortal {
	if(_portal) {
	} else {
		_portal = [[WLPortal alloc] initWithView:self];
		[_portal setFrame:[self frame]];
	}
	[_effectView clear];
	_isInPortalMode = YES;
	[_mouseBehaviorDelegate update];
	[self addSubview:_portal];
}
// Remove current portal
- (void)removePortal {
	if(_portal) {
		[_portal removeFromSuperview];
		[_portal release];
		_portal = nil;
	}
	_isInPortalMode = NO;
}

// Reset a new portal
- (void)resetPortal {
	// Remove it at first...
	if(_isInPortalMode)
		if(_portal)
			[_portal removeFromSuperview];
	[_portal release];
	_portal = nil;
	// Update the new portal if necessary...
	if(_isInPortalMode) {
		[self updatePortal];
	}
}

// Set the portal in right state...
- (void)checkPortal {
	if (_isInPortalMode && ![[[self frontMostConnection] site] empty]) {
		[self removePortal];
	} else if (([self numberOfTabViewItems] == 0 || [[[self frontMostConnection] site] empty]) && !_isInPortalMode && [[NSUserDefaults standardUserDefaults] boolForKey:WLCoverFlowModeEnabledKeyName]) {
		[self updatePortal];
	}
}

- (void)addPortalPicture:(NSString *)source 
				 forSite:(NSString *)siteName {
	[_portal addPortalPicture:source forSite:siteName];
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
@end