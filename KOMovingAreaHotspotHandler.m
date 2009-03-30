//
//  KOExitAreaHotspotHandler.m
//  Welly
//
//  Created by K.O.ed on 09-1-26.
//  Copyright 2009 Welly Group. All rights reserved.
//

#import "KOMovingAreaHotspotHandler.h"
#import "KOMouseBehaviorManager.h"
#import "YLView.h"
#import "YLTerminal.h"
#import "YLConnection.h"

NSString *const KOCommandSequencePageUp = termKeyPageUp;
NSString *const KOCommandSequencePageDown = termKeyPageDown;
NSString *const KOCommandSequenceLeftArrow = termKeyLeft;
NSString *const KOCommandSequenceHome = termKeyHome;
NSString *const KOCommandSequenceEnd = termKeyEnd;
NSString *const KOCommandSequencePressQ = @"q";

NSString *const KOMenuTitlePressHome = @"Press Home";
NSString *const KOMenuTitlePressEnd = @"Press End";
NSString *const KOMenuTitleQuitMode = @"Quit Mode";

@implementation KOMovingAreaHotspotHandler
- (id)init {
	[super init];
	_leftArrowCursor = [NSCursor resizeLeftCursor];
	_pageUpCursor = [NSCursor resizeUpCursor];
	_pageDownCursor = [NSCursor resizeDownCursor];
	return self;
}

- (BOOL)shouldEnablePageUpDown {
	YLTerminal *ds = [_view frontMostTerminal];
	return ([ds bbsState].state == BBSBoardList 
			|| [ds bbsState].state == BBSBrowseBoard
			|| [ds bbsState].state == BBSFriendList
			|| [ds bbsState].state == BBSMailList
			|| [ds bbsState].state == BBSViewPost);
}

#pragma mark -
#pragma mark Mouse Event Handler
- (void)mouseUp:(NSEvent *)theEvent {
	NSString *commandSequence = [_manager.backgroundTrackingAreaUserInfo objectForKey:KOMouseCommandSequenceUserInfoName];
	[_view sendText:commandSequence];
}

- (void)mouseEntered:(NSEvent *)theEvent {
	if([[_view frontMostConnection] isConnected]) {
		_manager.backgroundTrackingAreaUserInfo = [[theEvent trackingArea] userInfo];
	}
}

- (void)mouseExited:(NSEvent *)theEvent {
	if ([NSCursor currentCursor] == [_manager.backgroundTrackingAreaUserInfo objectForKey:KOMouseCursorUserInfoName])
		[_manager restoreNormalCursor];
	_manager.backgroundTrackingAreaUserInfo = nil;
}

- (void)mouseMoved:(NSEvent *)theEvent {
	if ([NSCursor currentCursor] == _manager.normalCursor)
		[[_manager.backgroundTrackingAreaUserInfo objectForKey:KOMouseCursorUserInfoName] set];
}

#pragma mark -
#pragma mark Contextual Menu
- (IBAction)pressHome:(id)sender {
	[_view sendText:KOCommandSequenceHome];
}

- (IBAction)pressEnd:(id)sender {
	[_view sendText:KOCommandSequenceEnd];
}

- (IBAction)pressQ:(id)sender {
	[_view sendText:KOCommandSequencePressQ];
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
	NSMenu *menu = [[[NSMenu alloc] init] autorelease];
	if ([self shouldEnablePageUpDown]) {
		[menu addItemWithTitle:NSLocalizedString(KOMenuTitlePressHome, @"Contextual Menu")
						action:@selector(pressHome:)
				 keyEquivalent:@""];
		[menu addItemWithTitle:NSLocalizedString(KOMenuTitlePressEnd, @"Contextual Menu") 
						action:@selector(pressEnd:) 
				 keyEquivalent:@""];
	}
	
	if ([[_view frontMostTerminal] bbsState].state == BBSBrowseBoard) {
		[menu addItemWithTitle:NSLocalizedString(KOMenuTitleQuitMode, @"Contextual Menu") 
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
	//NSLog(@"Exit Area added");	
	NSRect rect = [_view rectAtRow:r column:c height:h width:w];
	// Generate User Info
	NSArray *keys = [NSArray arrayWithObjects:KOMouseHandlerUserInfoName, KOMouseCommandSequenceUserInfoName, KOMouseCursorUserInfoName, nil];
	NSArray *objects = [NSArray arrayWithObjects:self, KOCommandSequenceLeftArrow, _leftArrowCursor, nil];
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
- (void)addPageUpAreaAtRow:(int)r 
					column:(int)c 
					height:(int)h 
					 width:(int)w {
	NSRect rect = [_view rectAtRow:r column:c height:h width:w];
	NSArray *keys = [NSArray arrayWithObjects:KOMouseHandlerUserInfoName, KOMouseCommandSequenceUserInfoName, KOMouseCursorUserInfoName, nil];
	NSArray *objects = [NSArray arrayWithObjects:self, KOCommandSequencePageUp, _pageUpCursor, nil];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	[_manager addTrackingAreaWithRect:rect userInfo:userInfo cursor:_pageUpCursor];
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
	NSArray *keys = [NSArray arrayWithObjects:KOMouseHandlerUserInfoName, KOMouseCommandSequenceUserInfoName, KOMouseCursorUserInfoName, nil];
	NSArray *objects = [NSArray arrayWithObjects:self, KOCommandSequencePageDown, _pageDownCursor, nil];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	[_manager addTrackingAreaWithRect:rect userInfo:userInfo cursor:_pageDownCursor];
}

- (void)updatePageDownArea {
	if ([self shouldEnablePageUpDown]) {
		[self addPageDownAreaAtRow:_maxRow / 2
							column:20
							height:_maxRow / 2
							 width:_maxColumn - 20];
	}
}

- (void)update {
	// For the mouse preference
	if (![_view mouseEnabled]) 
		return;
	[self updateExitArea];
	[self updatePageUpArea];
	[self updatePageDownArea];
}

@end