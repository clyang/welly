//
//  WLExitAreaHotspotHandler.m
//  Welly
//
//  Created by K.O.ed on 09-1-26.
//  Copyright 2009 Welly Group. All rights reserved.
//

#import "WLMovingAreaHotspotHandler.h"
#import "WLMouseBehaviorManager.h"
#import "WLTerminalView.h"
#import "WLTerminal.h"
#import "WLConnection.h"

NSString *const WLCommandSequencePageUp = termKeyPageUp;
NSString *const WLCommandSequencePageDown = termKeyPageDown;
NSString *const WLCommandSequenceLeftArrow = termKeyLeft;
NSString *const WLCommandSequenceHome = termKeyHome;
NSString *const WLCommandSequenceEnd = termKeyEnd;
NSString *const WLCommandSequencePressQ = @"q";

NSString *const WLMenuTitlePressHome = @"Press Home";
NSString *const WLMenuTitlePressEnd = @"Press End";
NSString *const WLMenuTitleQuitMode = @"Quit Mode";

@implementation WLMovingAreaHotspotHandler
- (id)init {
	self = [super init];
	_leftArrowCursor = [NSCursor resizeLeftCursor];
	_pageUpCursor = [NSCursor resizeUpCursor];
	_pageDownCursor = [NSCursor resizeDownCursor];
	return self;
}

- (BOOL)shouldEnablePageUpDownForState:(BBSState)bbsState {
	return (bbsState.state == BBSBoardList 
			|| bbsState.state == BBSBrowseBoard
			|| bbsState.state == BBSFriendList
			|| bbsState.state == BBSMailList
			|| bbsState.state == BBSViewPost);
}

- (BOOL)shouldEnablePageUpDown {
	return [self shouldEnablePageUpDownForState:[[_view frontMostTerminal] bbsState]];
}

- (BOOL)shouldEnableExitAreaForState:(BBSState)bbsState {
	if (bbsState.state == BBSComposePost || bbsState.state == BBSWaitingEnter)
		return NO;
	return YES;
}

- (BOOL)shouldEnableExitArea {
	return [self shouldEnableExitAreaForState:[[_view frontMostTerminal] bbsState]];
}

#pragma mark -
#pragma mark Mouse Event Handler
- (void)mouseUp:(NSEvent *)theEvent {
	NSString *commandSequence = [_manager.backgroundTrackingAreaUserInfo objectForKey:WLMouseCommandSequenceUserInfoName];
	[_view sendText:commandSequence];
}

- (void)mouseEntered:(NSEvent *)theEvent {
	if([[_view frontMostConnection] isConnected]) {
		_manager.backgroundTrackingAreaUserInfo = [[theEvent trackingArea] userInfo];
	}
}

- (void)mouseExited:(NSEvent *)theEvent {
	if ([NSCursor currentCursor] == [_manager.backgroundTrackingAreaUserInfo objectForKey:WLMouseCursorUserInfoName])
		[_manager restoreNormalCursor];
	_manager.backgroundTrackingAreaUserInfo = nil;
}

- (void)mouseMoved:(NSEvent *)theEvent {
	if ([NSCursor currentCursor] == _manager.normalCursor)
		[(NSCursor *)[_manager.backgroundTrackingAreaUserInfo objectForKey:WLMouseCursorUserInfoName] set];
}

#pragma mark -
#pragma mark Contextual Menu
- (IBAction)pressHome:(id)sender {
	[_view sendText:WLCommandSequenceHome];
}

- (IBAction)pressEnd:(id)sender {
	[_view sendText:WLCommandSequenceEnd];
}

- (IBAction)pressQ:(id)sender {
	[_view sendText:WLCommandSequencePressQ];
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
	NSMenu *menu = [[[NSMenu alloc] init] autorelease];
	if ([self shouldEnablePageUpDown]) {
		[menu addItemWithTitle:NSLocalizedString(WLMenuTitlePressHome, @"Contextual Menu")
						action:@selector(pressHome:)
				 keyEquivalent:@""];
		[menu addItemWithTitle:NSLocalizedString(WLMenuTitlePressEnd, @"Contextual Menu") 
						action:@selector(pressEnd:) 
				 keyEquivalent:@""];
	}
	
	if ([[_view frontMostTerminal] bbsState].state == BBSBrowseBoard) {
		[menu addItemWithTitle:NSLocalizedString(WLMenuTitleQuitMode, @"Contextual Menu") 
						action:@selector(pressQ:) 
				 keyEquivalent:@""];
	}

	for (NSMenuItem *item in [menu itemArray]) {
		if ([item isSeparatorItem])
			continue;
		[item setTarget:self];
		[item setRepresentedObject:_manager.backgroundTrackingAreaUserInfo];
	}
	return menu;
}

#pragma mark -
#pragma mark Update State

#pragma mark Exit Area
- (void)addExitAreaAtRow:(int)r 
				  column:(int)c 
				  height:(int)h 
				   width:(int)w {
	NSRect rect = [_view rectAtRow:r column:c height:h width:w];
	// Generate User Info
	NSArray *keys = [NSArray arrayWithObjects:WLMouseHandlerUserInfoName, WLMouseCommandSequenceUserInfoName, WLMouseCursorUserInfoName, nil];
	NSArray *objects = [NSArray arrayWithObjects:self, WLCommandSequenceLeftArrow, _leftArrowCursor, nil];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	[_trackingAreas addObject:[_manager addTrackingAreaWithRect:rect userInfo:userInfo cursor: _leftArrowCursor]];
}

- (void)updateExitArea {
	if (![self shouldEnableExitArea]) {
		return;
	} else {
		[self addExitAreaAtRow:3 
						column:0 
						height:20
						 width:20];
	}
}

#pragma mark pgUp/Down Area
- (void)addPageUpAreaAtRow:(int)r 
					column:(int)c 
					height:(int)h 
					 width:(int)w {
	NSRect rect = [_view rectAtRow:r column:c height:h width:w];
	NSArray *keys = [NSArray arrayWithObjects:WLMouseHandlerUserInfoName, WLMouseCommandSequenceUserInfoName, WLMouseCursorUserInfoName, nil];
	NSArray *objects = [NSArray arrayWithObjects:self, WLCommandSequencePageUp, _pageUpCursor, nil];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	[_trackingAreas addObject:[_manager addTrackingAreaWithRect:rect userInfo:userInfo cursor:_pageUpCursor]];
}

- (void)updatePageUpArea {
	if ([self shouldEnablePageUpDown]) {
		[self addPageUpAreaAtRow:0
						  column:20
						  height:_maxRow / 2
						   width:_maxColumn - 20];
	}
}

- (void)addPageDownAreaAtRow:(int)r 
					  column:(int)c 
					  height:(int)h 
					   width:(int)w {
	NSRect rect = [_view rectAtRow:r column:c height:h width:w];
	// Generate User Info
	NSArray *keys = [NSArray arrayWithObjects:WLMouseHandlerUserInfoName, WLMouseCommandSequenceUserInfoName, WLMouseCursorUserInfoName, nil];
	NSArray *objects = [NSArray arrayWithObjects:self, WLCommandSequencePageDown, _pageDownCursor, nil];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	[_trackingAreas addObject:[_manager addTrackingAreaWithRect:rect userInfo:userInfo cursor:_pageDownCursor]];
}

- (void)updatePageDownArea {
	if ([self shouldEnablePageUpDown]) {
		[self addPageDownAreaAtRow:_maxRow / 2
							column:20
							height:_maxRow / 2
							 width:_maxColumn - 20];
	}
}

- (void)clear {
	// Only Moving areas use cursor rects, so just discard them all.
	[_view discardCursorRects];
	[self removeAllTrackingAreas];
}

- (BOOL)shouldUpdate {
	if (![_view shouldEnableMouse] || ![_view isConnected]) {
		return YES;	
	}
	BBSState bbsState = [[_view frontMostTerminal] bbsState];
	BBSState lastBBSState = [_manager lastBBSState];
	if (bbsState.state == lastBBSState.state) {
		return NO;
	}
	
	if (([self shouldEnablePageUpDownForState:bbsState] == [self shouldEnablePageUpDownForState:lastBBSState]) &&
		([self shouldEnableExitAreaForState:bbsState] == [self shouldEnableExitAreaForState:lastBBSState])) {
		return NO;
	}
	
	return YES;
}

- (void)update {
	[self clear];
	if (![_view shouldEnableMouse] || ![_view isConnected]) {
		return;	
	}
	[self updateExitArea];
	[self updatePageUpArea];
	[self updatePageDownArea];
}
@end