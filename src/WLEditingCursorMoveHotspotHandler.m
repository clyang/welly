//
//  WLEditingCursorMoveHotspotHandler.m
//  Welly
//
//  Created by K.O.ed on 09-2-13.
//  Copyright 2009 Welly Group. All rights reserved.
//

#import "WLEditingCursorMoveHotspotHandler.h"
#import "WLMouseBehaviorManager.h"
#import "WLTerminalView.h"
#import "WLTerminal.h"
#import "WLConnection.h"
#import "WLSite.h"

static NSCursor *gMoveCursor = nil;

@implementation WLEditingCursorMoveHotspotHandler

+ (void)initialize {
    NSImage *cursorImage = [[NSImage alloc] initWithSize: NSMakeSize(11.0, 20.0)];
    [cursorImage lockFocus];
    [[NSColor clearColor] set];
    NSRectFill(NSMakeRect(0, 0, 11, 20));
    [[NSColor whiteColor] set];
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path setLineCapStyle: NSRoundLineCapStyle];
    [path moveToPoint: NSMakePoint(1.5, 1.5)];
    [path lineToPoint: NSMakePoint(2.5, 1.5)];
    [path lineToPoint: NSMakePoint(5.5, 4.5)];
    [path lineToPoint: NSMakePoint(8.5, 1.5)];
    [path lineToPoint: NSMakePoint(9.5, 1.5)];
    [path moveToPoint: NSMakePoint(5.5, 4.5)];
    [path lineToPoint: NSMakePoint(5.5, 15.5)];
    [path lineToPoint: NSMakePoint(2.5, 18.5)];
    [path lineToPoint: NSMakePoint(1.5, 18.5)];
    [path moveToPoint: NSMakePoint(5.5, 15.5)];
    [path lineToPoint: NSMakePoint(8.5, 18.5)];
    [path lineToPoint: NSMakePoint(9.5, 18.5)];
    [path moveToPoint: NSMakePoint(3.5, 9.5)];
    [path lineToPoint: NSMakePoint(7.5, 9.5)];
    [path setLineWidth: 3];
    [path stroke];
    [path setLineWidth: 1];
    [[NSColor blackColor] set];
    [path stroke];
    [cursorImage unlockFocus];
    gMoveCursor = [[NSCursor alloc] initWithImage: cursorImage hotSpot: NSMakePoint(5.5, 9.5)];
    [cursorImage release];
}

- (id)init {
	self = [super init];
	if (self) {
		if (!gMoveCursor)
			[WLEditingCursorMoveHotspotHandler initialize];
	}
	return self;
}

#pragma mark -
#pragma mark Event Handle
- (void)mouseUp:(NSEvent *)theEvent {
	// click to move cursor
	NSPoint p = [_view convertPoint:[theEvent locationInWindow] fromView:nil];
	int _selectionLocation = [_view convertIndexFromPoint: p];
	
	unsigned char cmd[_maxRow * _maxColumn * 3];
	unsigned int cmdLength = 0;
	id ds = [_view frontMostTerminal];
	// FIXME: what actually matters is whether the user enables auto-break-line
	// however, since it is enabled by default in smth (switchible by ctrl-p) and disabled in ptt,
	// we temporarily use bbsType here...
	if ([ds bbsType] == WLMaple) { // auto-break-line IS NOT enabled in bbs
		int moveToRow = _selectionLocation / _maxColumn;
		int moveToCol = _selectionLocation % _maxColumn;
		BOOL home = NO;
		if (moveToRow > [ds cursorRow]) {
			cmd[cmdLength++] = 0x01;
			home = YES;
			for (int i = [ds cursorRow]; i < moveToRow; i++) {
				cmd[cmdLength++] = 0x1B;
				cmd[cmdLength++] = 0x4F;
				cmd[cmdLength++] = 0x42;
			} 
		} else if (moveToRow < [ds cursorRow]) {
			cmd[cmdLength++] = 0x01;
			home = YES;
			for (int i = [ds cursorRow]; i > moveToRow; i--) {
				cmd[cmdLength++] = 0x1B;
				cmd[cmdLength++] = 0x4F;
				cmd[cmdLength++] = 0x41;
			} 			
		} 
		
		cell *currRow = [[_view frontMostTerminal] cellsOfRow:moveToRow];
		if (home) {
			for (int i = 0; i < moveToCol; i++) {
				if (currRow[i].attr.f.doubleByte != 2 || [[[_view frontMostConnection] site] shouldDetectDoubleByte]) {
					cmd[cmdLength++] = 0x1B;
					cmd[cmdLength++] = 0x4F;
					cmd[cmdLength++] = 0x43;                    
				}
			}
		} else if (moveToCol > [ds cursorColumn]) {
			for (int i = [ds cursorColumn]; i < moveToCol; i++) {
				if (currRow[i].attr.f.doubleByte != 2 || [[[_view frontMostConnection] site] shouldDetectDoubleByte]) {
					cmd[cmdLength++] = 0x1B;
					cmd[cmdLength++] = 0x4F;
					cmd[cmdLength++] = 0x43;
				}
			}
		} else if (moveToCol < [ds cursorColumn]) {
			for (int i = [ds cursorColumn]; i > moveToCol; i--) {
				if (currRow[i].attr.f.doubleByte != 2 || [[[_view frontMostConnection] site] shouldDetectDoubleByte]) {
					cmd[cmdLength++] = 0x1B;
					cmd[cmdLength++] = 0x4F;
					cmd[cmdLength++] = 0x44;
				}
			}
		}
	} else { // auto-break-line IS enabled in bbs
		int thisRow = [ds cursorRow];
		int cursorLocation = thisRow * _maxColumn + [ds cursorColumn];
		int prevRow = -1;
		int lastEffectiveChar = -1;
		if (cursorLocation < _selectionLocation) {
			for (int i = cursorLocation; i < _selectionLocation; ++i) {
				thisRow = i / _maxColumn;
				if (thisRow != prevRow) {
					cell *currRow = [ds cellsOfRow:thisRow];
					for (lastEffectiveChar = _maxColumn - 1;
						 lastEffectiveChar != 0
						 && (currRow[lastEffectiveChar - 1].byte == 0 || currRow[lastEffectiveChar - 1].byte == '~');
						 --lastEffectiveChar);
					prevRow = thisRow;
				}
				if (i % _maxColumn <= lastEffectiveChar
					&& ([ds attrAtRow:i / _maxColumn column:i % _maxColumn].f.doubleByte != 2
						|| [[[_view frontMostConnection] site] shouldDetectDoubleByte])) {
					cmd[cmdLength++] = 0x1B;
					cmd[cmdLength++] = 0x4F;
					cmd[cmdLength++] = 0x43;                    
				}
			}
		} else {
			for (int i = cursorLocation; i > _selectionLocation; --i) {
				thisRow = i / _maxColumn;
				if (thisRow != prevRow) {
					cell *currRow = [ds cellsOfRow:thisRow];
					for (lastEffectiveChar = _maxColumn - 1;
						 lastEffectiveChar != 0
						 && (currRow[lastEffectiveChar - 1].byte == 0 || currRow[lastEffectiveChar - 1].byte == '~');
						 --lastEffectiveChar);
					prevRow = thisRow;
				}
				if (i % _maxColumn <= lastEffectiveChar
					&& ([ds attrAtRow:i / _maxColumn column:i % _maxColumn].f.doubleByte != 2
						|| [[[_view frontMostConnection] site] shouldDetectDoubleByte])) {
					cmd[cmdLength++] = 0x1B;
					cmd[cmdLength++] = 0x4F;
					cmd[cmdLength++] = 0x44;                    
				}					
			}
		}				
	}
	if (cmdLength > 0)
		[[_view frontMostConnection] sendBytes:cmd length:cmdLength];
}

- (void)mouseEntered:(NSEvent *)theEvent {
	[[NSCursor IBeamCursor] set];
	_manager.activeTrackingAreaUserInfo = [[theEvent trackingArea] userInfo];
}

- (void)mouseExited:(NSEvent *)theEvent {
	_manager.activeTrackingAreaUserInfo = nil;
	// FIXME: Temporally solve the problem in full screen mode.
	if ([NSCursor currentCursor] == gMoveCursor)
		[[NSCursor arrowCursor] set];
}

- (void)mouseMoved:(NSEvent *)theEvent {
	if ([NSCursor currentCursor] != gMoveCursor)
		[[NSCursor IBeamCursor] set];
}

#pragma mark -
#pragma mark Update State
- (BOOL)shouldUpdate {
	if (![_view shouldEnableMouse] || ![_view isConnected]) {
		return YES;
	}
	BBSState bbsState = [[_view frontMostTerminal] bbsState];
	if ([_manager lastBBSState].state == bbsState.state)
		return NO;
	return YES;
}

- (void)update {
	[self clear];
	if (![_view shouldEnableMouse] || ![_view isConnected]) {
		return;
	}
	BBSState bbsState = [[_view frontMostTerminal] bbsState];
	if (bbsState.state == BBSComposePost) {
		[_trackingAreas addObject:[_manager addTrackingAreaWithRect:[_view frame]
														   userInfo:[NSDictionary dictionaryWithObject:self forKey:WLMouseHandlerUserInfoName] 
															 cursor:gMoveCursor]];
	}
}

#pragma mark -
#pragma mark Clear
- (void)clear {
	// Only Moving areas use cursor rects, so just discard them all.
	[_view discardCursorRects];
	[self removeAllTrackingAreas];
}

@end
