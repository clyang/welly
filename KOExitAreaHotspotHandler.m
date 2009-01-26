//
//  KOExitAreaHotspotHandler.m
//  Welly
//
//  Created by K.O.ed on 09-1-26.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "KOExitAreaHotspotHandler.h"
#import "YLView.h"
#import "YLSite.h"
#import "YLConnection.h"
#import "YLTerminal.h"

@implementation KOExitAreaHotspotHandler

- (id) initWithView: (YLView *)view 
			   rect: (NSRect)rect {
	[self init];
	_view = view;
	_rect = rect;
	[_view addCursorRect:_rect cursor:[NSCursor resizeLeftCursor]];	
	// Check if mouse is already inside the area
	NSPoint mousePos = [_view convertPoint: [[_view window] convertScreenToBase:[NSEvent mouseLocation]] fromView:nil];
	if ([_view mouse:mousePos inRect:rect]) {
		[self mouseEntered:[[NSEvent alloc] init]];
	}
	return self;
}

- (void) dealloc {
	[_view removeCursorRect:_rect cursor:[NSCursor resizeLeftCursor]];
	[super dealloc];
}

#pragma mark -
#pragma mark Mouse Event Handler
- (void) mouseUp: (NSEvent *)theEvent {
	NSLog(@"ExitAreaHandler mouseUp:");
	if ([[_view frontMostTerminal] bbsState].state != BBSWaitingEnter
		&& [[_view frontMostTerminal] bbsState].state != BBSComposePost) {
		[[_view frontMostConnection] sendText: termKeyLeft];
		return;
	}
}

- (void) mouseEntered: (NSEvent *)theEvent {
	if([[[_view frontMostConnection] site] enableMouse]) {
		if ([_view activeHandler] == nil)
			[_view setActiveHandler: self];
	}
}

- (void) mouseExited: (NSEvent *)theEvent {
	if ([_view activeHandler] == self)
		[_view removeActiveHandler];
}

- (void) mouseMoved: (NSEvent *)theEvent {
	if ([NSCursor currentCursor] == [NSCursor arrowCursor])
		[[NSCursor resizeLeftCursor] set];
	if([[[_view frontMostConnection] site] enableMouse]) {
		if ([_view activeHandler] == nil)
			[_view setActiveHandler: self];
	}
}

@end
