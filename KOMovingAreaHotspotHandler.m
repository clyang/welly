//
//  KOExitAreaHotspotHandler.m
//  Welly
//
//  Created by K.O.ed on 09-1-26.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "KOMovingAreaHotspotHandler.h"
#import "YLView.h"
#import "YLSite.h"
#import "YLConnection.h"
#import "YLTerminal.h"

@implementation KOMovingAreaHotspotHandler

+ (KOMovingAreaHotspotHandler *) exitAreaHandlerForView: (YLView *)view 
												   rect: (NSRect)rect {
	KOMovingAreaHotspotHandler *handler = [[KOMovingAreaHotspotHandler alloc] initWithView:view rect:rect];
	[handler->_view addCursorRect:handler->_rect cursor:[NSCursor resizeLeftCursor]];
	handler->_type = AREA_EXIT;
	return handler;
}

+ (KOMovingAreaHotspotHandler *) pageUpAreaHandlerForView: (YLView *)view 
												     rect: (NSRect)rect {
	KOMovingAreaHotspotHandler *handler = [[KOMovingAreaHotspotHandler alloc] initWithView:view rect:rect];
	[handler->_view addCursorRect:handler->_rect cursor:[NSCursor resizeUpCursor]];
	handler->_type = AREA_PAGE_UP;
	return handler;	
}

+ (KOMovingAreaHotspotHandler *) pageDownAreaHandlerForView: (YLView *)view 
													   rect: (NSRect)rect {
	KOMovingAreaHotspotHandler *handler = [[KOMovingAreaHotspotHandler alloc] initWithView:view rect:rect];
	[handler->_view addCursorRect:handler->_rect cursor:[NSCursor resizeDownCursor]];
	handler->_type = AREA_PAGE_DOWN;
	return handler;	
}

- (id) initWithView: (YLView *)view 
			   rect: (NSRect)rect {
	[self init];
	_view = view;
	_rect = rect;
	// Check if mouse is already inside the area
	NSPoint mousePos = [_view convertPoint: [[_view window] convertScreenToBase:[NSEvent mouseLocation]] fromView:nil];
	if ([_view mouse:mousePos inRect:rect]) {
		[self mouseEntered:[[NSEvent alloc] init]];
	}
	return self;
}

- (void) dealloc {
	if (_type == AREA_EXIT)
		[_view removeCursorRect:_rect cursor:[NSCursor resizeLeftCursor]];
	if (_type == AREA_PAGE_UP)
		[_view removeCursorRect:_rect cursor:[NSCursor resizeUpCursor]];
	if (_type == AREA_PAGE_DOWN)
		[_view removeCursorRect:_rect cursor:[NSCursor resizeDownCursor]];
	[super dealloc];
}

#pragma mark -
#pragma mark Mouse Event Handler
- (void) mouseUp: (NSEvent *)theEvent {
	switch (_type) {
		case AREA_EXIT:
			[[_view frontMostConnection] sendText: termKeyLeft];
			break;
		case AREA_PAGE_UP:
			[[_view frontMostConnection] sendText: termKeyPageUp];
			break;
		case AREA_PAGE_DOWN:
			[[_view frontMostConnection] sendText: termKeyPageDown];
			break;
		default:
			break;
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
	if([[[_view frontMostConnection] site] enableMouse]) {
		if ([_view activeHandler] == nil) {
			[_view setActiveHandler: self];
			if ([NSCursor currentCursor] == [NSCursor arrowCursor]) {
				switch (_type) {
					case AREA_EXIT:
						[[NSCursor resizeLeftCursor] set];
						break;
					case AREA_PAGE_UP:
						[[NSCursor resizeUpCursor] set];
						break;
					case AREA_PAGE_DOWN:
						[[NSCursor resizeDownCursor] set];
						break;
					default:
						break;
				}
			}
		}
	}
}

@end
