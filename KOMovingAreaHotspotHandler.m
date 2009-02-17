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
#import "YLTerminal.h"

NSString *const KOCommandSequencePageUp = termKeyPageUp;
NSString *const KOCommandSequencePageDown = termKeyPageDown;
NSString *const KOCommandSequenceLeftArrow = termKeyLeft;
NSString *const KOCommandSequenceHome = termKeyHome;
NSString *const KOCommandSequenceEnd = termKeyEnd;

NSString *const KOToolTipPageUp = @"Left click for PageUp, right click for Home";
NSString *const KOToolTipPageDown = @"Left click for PageDown, right click for End";

@implementation KOMovingAreaHotspotHandler
- (id) init {
	[super init];
	_leftArrowCursor = [NSCursor resizeLeftCursor];
	_pageUpCursor = [NSCursor resizeUpCursor];
	_pageDownCursor = [NSCursor resizeDownCursor];
	return self;
}

#pragma mark -
#pragma mark Mouse Event Handler
- (void) mouseUp: (NSEvent *)theEvent {
	NSString *commandSequence = [_manager.backgroundTrackingAreaUserInfo objectForKey:KOMouseCommandSequenceUserInfoName];
	[_view sendText: commandSequence];
}

- (void) mouseEntered: (NSEvent *)theEvent {
	if([[_view frontMostConnection] connected]) {
		_manager.backgroundTrackingAreaUserInfo = [[theEvent trackingArea] userInfo];
	}
}

- (void) mouseExited: (NSEvent *)theEvent {
	if ([NSCursor currentCursor] == [_manager.backgroundTrackingAreaUserInfo objectForKey:KOMouseCursorUserInfoName])
		[_manager restoreNormalCursor];
	_manager.backgroundTrackingAreaUserInfo = nil;
}

- (void) mouseMoved: (NSEvent *)theEvent {
	if ([NSCursor currentCursor] == _manager.normalCursor)
		[[_manager.backgroundTrackingAreaUserInfo objectForKey:KOMouseCursorUserInfoName] set];
}

#pragma mark -
#pragma mark Contextual Menu
- (NSMenu *) menuForEvent: (NSEvent *)theEvent {
	NSString *commandSequence = [_manager.backgroundTrackingAreaUserInfo objectForKey:KOMouseCommandSequenceUserInfoName];
	
	if ([commandSequence isEqualToString:KOCommandSequencePageUp]) {
		// Press HOME
		[_view sendText:KOCommandSequenceHome];
	} else if ([commandSequence isEqualToString:KOCommandSequencePageDown]) {
		// Press END
		[_view sendText:KOCommandSequenceEnd];
	}
	return nil;
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
	NSArray *objects = [NSArray arrayWithObjects: self, KOCommandSequenceLeftArrow, _leftArrowCursor, nil];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	[_manager addTrackingAreaWithRect:rect userInfo:userInfo cursor: _leftArrowCursor];
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
	NSArray *objects = [NSArray arrayWithObjects: self, KOCommandSequencePageUp, _pageUpCursor, nil];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	[_manager addTrackingAreaWithRect:rect userInfo:userInfo cursor: _pageUpCursor];
	// Add tool tip
	//[_view addToolTipRect:rect owner:self userData:KOToolTipPageUp];
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
	NSArray *objects = [NSArray arrayWithObjects: self, KOCommandSequencePageDown, _pageDownCursor, nil];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	[_manager addTrackingAreaWithRect:rect userInfo:userInfo cursor: _pageDownCursor];
	// Add tool tip
	//[_view addToolTipRect:rect owner:self userData:KOToolTipPageDown];
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

@implementation KOMovingAreaHotspotHandler(NSToolTipOwner)
- (NSString *) view: (NSView *)view 
   stringForToolTip: (NSToolTipTag)tag 
			  point: (NSPoint)point 
		   userData: (void *)userData {
	NSLog(@"tooltip:%@", userData);
	NSString *str = (NSString *)userData;
	if ([str isEqualToString:KOToolTipPageUp] && [NSCursor currentCursor] == _pageUpCursor) {
		return NSLocalizedString(KOToolTipPageUp, @"Tool Tip");
	} else if ([str isEqualToString:KOToolTipPageDown] && [NSCursor currentCursor] == _pageDownCursor) {
		return NSLocalizedString(KOToolTipPageDown, @"Tool Tip");
	}
	return nil;
}
@end