//
//  WLAuthorAreaHotspotHandler.m
//  Welly
//
//  Created by K.O.ed on 09-2-16.
//  Copyright 2009 Welly Group. All rights reserved.
//

#import "WLAuthorAreaHotspotHandler.h"
#import "WLMouseBehaviorManager.h"
#import "YLView.h"
#import "YLTerminal.h"
#import "WLEffectView.h"

NSString *const WLButtonNameAuthorMode = @"Author: %@";

NSString *const FBCommandSequenceAuthorMode = @"\07""5\n""%@\n";
NSString *const FBCommandSequenceAuthorInfo = @"u%@\n";
NSString *const FBCommandSequenceAddAuthorAsFriend = @"u%@\noY\n\n";

NSString *const WLMenuTitleAuthorInfo = @"Info for %@";
NSString *const WLMenuTitleAddAsFriend = @"Add %@ as friend";

@implementation WLAuthorAreaHotspotHandler

#pragma mark -
#pragma mark Event Handle
- (void)mouseUp:(NSEvent *)theEvent {
	NSString *author = [_manager.activeTrackingAreaUserInfo objectForKey:WLMouseAuthorUserInfoName];
	if (author == nil) {
		return;
	}
	NSString *commandSequence = [NSString stringWithFormat:FBCommandSequenceAuthorMode, author];
	[_view sendText:commandSequence];
}

- (void)mouseEntered:(NSEvent *)theEvent {
	NSDictionary *userInfo = [[theEvent trackingArea] userInfo];
	if ([_view isMouseActive]) {
		NSString *buttonTitle = [NSString stringWithFormat:NSLocalizedString(WLButtonNameAuthorMode, @"Mouse Button"), [userInfo objectForKey:WLMouseAuthorUserInfoName]];
		[[_view effectView] drawButton:[[theEvent trackingArea] rect] withMessage:buttonTitle];
	}
	_manager.activeTrackingAreaUserInfo = userInfo;
	[[NSCursor pointingHandCursor] set];
}

- (void)mouseExited:(NSEvent *)theEvent {
	[[_view effectView] clearButton];
	_manager.activeTrackingAreaUserInfo = nil;
	// FIXME: Temporally solve the problem in full screen mode.
	if ([NSCursor currentCursor] == [NSCursor pointingHandCursor])
		[_manager restoreNormalCursor];
}

- (void)mouseMoved:(NSEvent *)theEvent {
	if ([NSCursor currentCursor] != [NSCursor pointingHandCursor])
		[[NSCursor pointingHandCursor] set];
}

#pragma mark -
#pragma mark Contextual Menu
- (IBAction)authorInfo:(id)sender {
	NSDictionary *userInfo = [sender representedObject];
	NSString *author = [userInfo objectForKey:WLMouseAuthorUserInfoName];
	NSString *commandSequence = [NSString stringWithFormat:FBCommandSequenceAuthorInfo, author];
	[_view sendText:commandSequence];
}

- (IBAction)addAsFriend:(id)sender {
	NSDictionary *userInfo = [sender representedObject];
	NSString *author = [userInfo objectForKey:WLMouseAuthorUserInfoName];
	NSString *commandSequence = [NSString stringWithFormat:FBCommandSequenceAddAuthorAsFriend, author];
	[_view sendText:commandSequence];
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
	NSMenu *menu = [[[NSMenu alloc] init] autorelease];
	NSString *author = [_manager.activeTrackingAreaUserInfo objectForKey:WLMouseAuthorUserInfoName];
	if (author == nil)
		return nil;
	
	[menu addItemWithTitle:[NSString stringWithFormat:NSLocalizedString(WLMenuTitleAuthorInfo, @"Contextual Menu"), author]
					action:@selector(authorInfo:)
			 keyEquivalent:@""];
	
	[menu addItemWithTitle:[NSString stringWithFormat:NSLocalizedString(WLMenuTitleAddAsFriend, @"Contextual Menu"), author]
					action:@selector(addAsFriend:)
			 keyEquivalent:@""];
	
	for (NSMenuItem *item in [menu itemArray]) {
		if ([item isSeparatorItem])
			continue;
		[item setTarget:self];
		[item setRepresentedObject:_manager.activeTrackingAreaUserInfo];
	}
	return menu;
}

#pragma mark -
#pragma mark Update State
- (void)addAuthorArea:(NSString *)author 
				  row:(int)row 
			   column:(int)column 
			   length:(int)length {
	NSRect rect = [_view rectAtRow:row column:column height:1 width:length];
	// Generate User Info
	NSArray *keys = [NSArray arrayWithObjects: WLMouseHandlerUserInfoName, WLMouseAuthorUserInfoName, nil];
	NSArray *objects = [NSArray arrayWithObjects: self, author, nil];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	// Add into manager
	[_trackingAreas addObject:[_manager addTrackingAreaWithRect:rect userInfo:userInfo]];
}

- (void)updateAuthorAreaForRow:(int)r {
	// TODO: enable this for Maple BBS
	if ([[_view frontMostTerminal] bbsType] == WLMaple)
		return;
	
	YLTerminal *ds = [_view frontMostTerminal];
    cell *currRow = [ds cellsOfRow:r];
	
	if ([ds bbsState].state == BBSBrowseBoard || [ds bbsState].state == BBSMailList) {
        // browsing a board
		// header/footer
		if (r < 3 || r == _maxRow - 1)
			return;
		
		int start = -1, end = -1;
		unichar textBuf[_maxColumn + 1];
		int bufLength = 0;
		
        // don't check the first two columns ("●" may be used as cursor)
        for (int i = 2; i < _maxColumn - 1; ++i) {
			int db = currRow[i].attr.f.doubleByte;
			if (db == 0) {
                if (start == -1) {	// User ID should start with a letter
                    if (isLetter(currRow[i].byte))
                        start = i;
                }
				if (isLetter(currRow[i].byte) || isNumber(currRow[i].byte))
					end = i;
				else if (start != -1) {
					if (end > start)
						break;
					else {	// User ID should have at least 2 bytes
						start = end = -1;
						textBuf[0] = textBuf[1] = 0;
						bufLength = 0;
					}
				}
                if (start != -1)
                    textBuf[bufLength++] = 0x0000 + (currRow[i].byte ?: ' ');
            } else if (db == 2) {
				if (start != -1) {
					if (end > start)
						break;
					else {	// User ID should have at least 2 bytes
						start = end = -1;
						textBuf[0] = textBuf[1] = 0;
						bufLength = 0;
					}
				}
			}
		}
		
		if (start == -1)
			return;
		
		[self addAuthorArea:[NSString stringWithCharacters:textBuf length:bufLength]
						row:r
					 column:start
					 length:end - start + 1];
	}
}

- (BOOL)shouldUpdate {
	if (![_view shouldEnableMouse] || ![_view isConnected]) {
		return YES;	
	}
	
	// In the same page, do NOT update
	YLTerminal *ds = [_view frontMostTerminal];
	BBSState bbsState = [ds bbsState];
	if (bbsState.state == [_manager lastBBSState].state && abs([_manager lastCursorRow] - [ds cursorRow]) == 1) {
		return NO;
	}
	return YES;
}

- (void)update {
	[self clear];
	if (![_view shouldEnableMouse] || ![_view isConnected]) {
		return;	
	}
	
	BBSState bbsState = [[_view frontMostTerminal] bbsState];
	if (bbsState.state != BBSBrowseBoard && bbsState.state != BBSMailList)
		return;
	for (int r = 0; r < _maxRow; ++r) {
		[self updateAuthorAreaForRow:r];
	}
}
@end
