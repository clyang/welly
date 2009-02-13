//
//  KOExitAreaHotspotHandler.m
//  Welly
//
//  Created by K.O.ed on 09-1-26.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "KOMovingAreaHotspotHandler.h"
#import "KOMouseBehaviorManager.h"
#import "YLView.h"
#import "YLConnection.h"
#import "YLTerminal.h"

@implementation KOMovingAreaHotspotHandler
#pragma mark -
#pragma mark Mouse Event Handler
- (void) mouseUp: (NSEvent *)theEvent {
	NSString *commandSequence = [_manager.backgroundTrackingAreaUserInfo objectForKey:KOMouseCommandSequenceUserInfoName];
	[[_view frontMostConnection] sendText: commandSequence];
}

- (void) mouseEntered: (NSEvent *)theEvent {
	if([[_view frontMostConnection] connected]) {
		_manager.backgroundTrackingAreaUserInfo = [[theEvent trackingArea] userInfo];
	}
}

- (void) mouseExited: (NSEvent *)theEvent {
	if ([NSCursor currentCursor] == [_manager.backgroundTrackingAreaUserInfo objectForKey:KOMouseCursorUserInfoName])
		[[NSCursor arrowCursor] set];
	_manager.backgroundTrackingAreaUserInfo = nil;
}

- (void) mouseMoved: (NSEvent *)theEvent {
	if ([NSCursor currentCursor] == [NSCursor arrowCursor])
		[[_manager.backgroundTrackingAreaUserInfo objectForKey:KOMouseCursorUserInfoName] set];
}

#pragma mark -
#pragma mark Update State

#pragma mark Exit Area

- (void)addExitAreaAtRow: (int)r 
				  column: (int)c 
				  height: (int)h 
				   width: (int)w {
	//NSLog(@"Exit Area added");	
	NSRect rect = [_view rectAtRow:r	column:c height:h width:w];
	// Generate User Info
	NSArray *keys = [NSArray arrayWithObjects: KOMouseHandlerUserInfoName, KOMouseCommandSequenceUserInfoName, KOMouseCursorUserInfoName, nil];
	NSArray *objects = [NSArray arrayWithObjects: self, termKeyLeft, [NSCursor resizeLeftCursor], nil];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	[_manager addTrackingAreaWithRect:rect userInfo:userInfo cursor: [NSCursor resizeLeftCursor]];
}

- (void)updateExitArea {
	YLTerminal *ds = [_view frontMostTerminal];
	if ([ds bbsState].state == BBSComposePost || [ds bbsState].state == BBSWaitingEnter) {
		return;
	} else {
		[self addExitAreaAtRow:3 
						column:0 
						height:20
						 width:20];
	}
}

#pragma mark pgUp/Down Area

- (void)addPageUpAreaAtRow: (int)r 
					column: (int)c 
					height: (int)h 
					 width: (int)w {
	NSRect rect = [_view rectAtRow:r	column:c height:h width:w];
	NSArray *keys = [NSArray arrayWithObjects: KOMouseHandlerUserInfoName, KOMouseCommandSequenceUserInfoName, KOMouseCursorUserInfoName, nil];
	NSArray *objects = [NSArray arrayWithObjects: self, termKeyPageUp, [NSCursor resizeUpCursor], nil];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	[_manager addTrackingAreaWithRect:rect userInfo:userInfo cursor: [NSCursor resizeUpCursor]];
}

- (void)updatePageUpArea {
	YLTerminal *ds = [_view frontMostTerminal];
	if ([ds bbsState].state == BBSBoardList 
		|| [ds bbsState].state == BBSBrowseBoard
		|| [ds bbsState].state == BBSFriendList
		|| [ds bbsState].state == BBSMailList
		|| [ds bbsState].state == BBSViewPost) {
		[self addPageUpAreaAtRow:0
						  column:20
						  height:_maxRow / 2
						   width:_maxColumn - 20];
	}
}

- (void)addPageDownAreaAtRow: (int)r 
					  column: (int)c 
					  height: (int)h 
					   width: (int)w {
	NSRect rect = [_view rectAtRow:r	column:c height:h width:w];
	// Generate User Info
	NSArray *keys = [NSArray arrayWithObjects: KOMouseHandlerUserInfoName, KOMouseCommandSequenceUserInfoName, KOMouseCursorUserInfoName, nil];
	NSArray *objects = [NSArray arrayWithObjects: self, termKeyPageDown, [NSCursor resizeDownCursor], nil];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	[_manager addTrackingAreaWithRect:rect userInfo:userInfo cursor: [NSCursor resizeDownCursor]];
}

- (void)updatePageDownArea {
	YLTerminal *ds = [_view frontMostTerminal];
	if ([ds bbsState].state == BBSBoardList 
		|| [ds bbsState].state == BBSBrowseBoard
		|| [ds bbsState].state == BBSFriendList
		|| [ds bbsState].state == BBSMailList
		|| [ds bbsState].state == BBSViewPost) {
		[self addPageDownAreaAtRow:_maxRow / 2
							column:20
							height:_maxRow / 2
							 width:_maxColumn - 20];
	}
}

- (void) update {
	// For the mouse preference
	if (![_view mouseEnabled]) 
		return;
	[self updateExitArea];
	[self updatePageUpArea];
	[self updatePageDownArea];
}

@end
