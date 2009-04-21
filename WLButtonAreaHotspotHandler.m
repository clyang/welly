//
//  WLButtonAreaHotspotHandler.m
//  Welly
//
//  Created by K.O.ed on 09-1-27.
//  Copyright 2009 Welly Group. All rights reserved.
//

#import "WLButtonAreaHotspotHandler.h"
#import "WLMouseBehaviorManager.h"

#import "YLView.h"
#import "YLConnection.h"
#import "YLTerminal.h"
#import "WLEffectView.h"

#define fbComposePost @"\020"
#define fbDeletePost @"dy\n"
#define fbShowNote @"\t"
#define fbShowHelp @"h"
#define fbNormalToDigest @"\07""1\n"
#define fbDigestToThread @"\07""2\n"
#define fbThreadToMark @"\07""3\n"
#define fbMarkToOrigin @"\07""4\n"
#define fbOriginToNormal @"e"
#define fbSwitchDisplayAllBoards @"y"
#define fbSwitchSortBoards @"S"
#define fbSwitchBoardsNumber @"c"

NSString *const WLButtonNameComposePost = @"Compose Post";
NSString *const WLButtonNameDeletePost = @"Delete Post";
NSString *const WLButtonNameShowNote = @"Show Note";
NSString *const WLButtonNameShowHelp = @"Show Help";
NSString *const WLButtonNameNormalToDigest = @"Normal To Digest";
NSString *const WLButtonNameDigestToThread = @"Digest To Thread";
NSString *const WLButtonNameThreadToMark = @"Thread To Mark";
NSString *const WLButtonNameMarkToOrigin = @"Mark To Origin";
NSString *const WLButtonNameOriginToNormal = @"Origin To Normal";
NSString *const WLButtonNameAuthorToNormal = @"Author To Normal";
NSString *const WLButtonNameJumpToMailList = @"Jump To Mail List";
NSString *const WLButtonNameEnterExcerption = @"Enter Excerption";

NSString *const WLButtonNameSwitchDisplayAllBoards = @"Display All Boards";
NSString *const WLButtonNameSwitchSortBoards = @"Sort Boards";
NSString *const WLButtonNameSwitchBoardsNumber = @"Switch Boards Number";
NSString *const WLButtonNameDeleteBoard = @"Delete Board";

NSString *const WLButtonNameChatWithUser = @"Chat";
NSString *const WLButtonNameMailToUser = @"Mail";
NSString *const WLButtonNameSendMessageToUser = @"Send Message";
NSString *const WLButtonNameAddUserToFriendList = @"Add To Friend List";
NSString *const WLButtonNameRemoveUserFromFriendList = @"Remove From Friend List";
NSString *const WLButtonNameSwitchUserListMode = @"Switch User List Mode";
NSString *const WLButtonNameShowUserDescription = @"Show User Description";
NSString *const WLButtonNamePreviousUser = @"Previous User";
NSString *const WLButtonNameNextUser = @"Next User";

NSString *const FBCommandSequenceAuthorToNormal = @"e";
NSString *const FBCommandSequenceChatWithUser = @"t";
NSString *const FBCommandSequenceMailToUser = @"m";
NSString *const FBCommandSequenceSendMessageToUser = @"s";
NSString *const FBCommandSequenceAddUserToFriendList = @"oY\n";
NSString *const FBCommandSequenceRemoveUserFromFriendList = @"dY\n";
NSString *const FBCommandSequenceSwitchUserListMode = @"f";
NSString *const FBCommandSequenceShowUserDescription = @"l";
NSString *const FBCommandSequencePreviousUser = termKeyUp;
NSString *const FBCommandSequenceNextUser = termKeyDown;
NSString *const FBCommandSequenceJumpToMailList = @"v";
NSString *const FBCommandSequenceEnterExcerption = @"x";

@implementation WLButtonAreaHotspotHandler
#pragma mark -
#pragma mark Mouse Event Handler
- (void)mouseUp:(NSEvent *)theEvent {
	NSString *commandSequence = [[_manager activeTrackingAreaUserInfo] objectForKey:WLMouseCommandSequenceUserInfoName];
	if (commandSequence != nil) {
		[[_view frontMostConnection] sendText:commandSequence];
		return;
	}
}

- (void)mouseEntered:(NSEvent *)theEvent {
	NSDictionary *userInfo = [[theEvent trackingArea] userInfo];
	if ([_view isMouseActive]) {
		NSString *buttonText = [userInfo objectForKey:WLMouseButtonTextUserInfoName];
		[[_view effectView] drawButton:[[theEvent trackingArea] rect] withMessage:buttonText];
	}
	[_manager setActiveTrackingAreaUserInfo:userInfo];
	[[NSCursor pointingHandCursor] set];
}

- (void)mouseExited:(NSEvent *)theEvent {
	[[_view effectView] clearButton];
	[_manager setActiveTrackingAreaUserInfo:nil];
	// FIXME: Temporally solve the problem in full screen mode.
	if ([NSCursor currentCursor] == [NSCursor pointingHandCursor])
		[_manager restoreNormalCursor];
}

- (void)mouseMoved:(NSEvent *)theEvent {
	if ([NSCursor currentCursor] != [NSCursor pointingHandCursor])
		[[NSCursor pointingHandCursor] set];
}

#pragma mark -
#pragma mark Update State
- (void)addButtonArea:(NSString *)buttonName
	  commandSequence:(NSString *)cmd 
				atRow:(int)r 
			   column:(int)c 
			   length:(int)len {
	NSRect rect = [_view rectAtRow:r column:c height:1 width:len];
	// Generate User Info
	NSArray *keys = [NSArray arrayWithObjects:WLMouseHandlerUserInfoName, WLMouseCommandSequenceUserInfoName, WLMouseButtonTextUserInfoName, nil];
	NSArray *objects = [NSArray arrayWithObjects:self, cmd, NSLocalizedString(buttonName, @"Mouse Button"), nil];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	[_trackingAreas addObject:[_manager addTrackingAreaWithRect:rect userInfo:userInfo]];
}

- (void)updateButtonAreaForRow:(int)r {
	const WLButtonDescription buttonsDefinition[] = {
		/* BBSBrowseBoard */
		{BBSBrowseBoard, @"发表文章[Ctrl-P]", 16, WLButtonNameComposePost, fbComposePost},
		{BBSBrowseBoard, @"砍信[d]", 7, WLButtonNameDeletePost, fbDeletePost},
		{BBSBrowseBoard, @"备忘录[TAB]", 11, WLButtonNameShowNote, fbShowNote},
		{BBSBrowseBoard, @"求助[h]", 7, WLButtonNameShowHelp, fbShowHelp},
		{BBSBrowseBoard, @"[一般模式]", 10, WLButtonNameNormalToDigest, fbNormalToDigest},
		{BBSBrowseBoard, @"[文摘模式]", 10, WLButtonNameDigestToThread, fbDigestToThread},
		{BBSBrowseBoard, @"[主题模式]", 10, WLButtonNameThreadToMark, fbThreadToMark},
		{BBSBrowseBoard, @"[精华模式]", 10, WLButtonNameMarkToOrigin, fbMarkToOrigin},
		{BBSBrowseBoard, @"[原作模式]", 10, WLButtonNameOriginToNormal, fbOriginToNormal},
		{BBSBrowseBoard, @"[作者模式]", 10, WLButtonNameAuthorToNormal, FBCommandSequenceAuthorToNormal},
		{BBSBrowseBoard, @"[您有信件]", 10, WLButtonNameJumpToMailList, FBCommandSequenceJumpToMailList},
		{BBSBrowseBoard, @"阅读[→,r]", 10, WLButtonNameEnterExcerption, FBCommandSequenceEnterExcerption},
		/* BBSBoardList */
		{BBSBoardList, @"列出[y]", 7, WLButtonNameSwitchDisplayAllBoards, fbSwitchDisplayAllBoards},
		{BBSBoardList, @"排序[S]", 7, WLButtonNameSwitchSortBoards, fbSwitchSortBoards},
		{BBSBoardList, @"切换[c]", 7, WLButtonNameSwitchBoardsNumber, fbSwitchBoardsNumber},
		{BBSBoardList, @"删除[d]", 7, WLButtonNameDeleteBoard, fbDeletePost},
		{BBSBoardList, @"求助[h]", 7, WLButtonNameShowHelp, fbShowHelp},
		{BBSBoardList, @"[您有信件]", 10, WLButtonNameJumpToMailList, FBCommandSequenceJumpToMailList},
		/* BBSUserInfo */
		{BBSUserInfo, @"寄信[m]", 7, WLButtonNameMailToUser, FBCommandSequenceMailToUser},
		{BBSUserInfo, @"聊天[t]", 7, WLButtonNameChatWithUser, FBCommandSequenceChatWithUser},
		{BBSUserInfo, @"送讯息[s]", 9, WLButtonNameSendMessageToUser, FBCommandSequenceSendMessageToUser},
		{BBSUserInfo, @"加,减朋", 7, WLButtonNameAddUserToFriendList, FBCommandSequenceAddUserToFriendList},
		{BBSUserInfo, @"友[o,d]", 7, WLButtonNameRemoveUserFromFriendList, FBCommandSequenceRemoveUserFromFriendList},
		{BBSUserInfo, @"切换模式 [f]", 12, WLButtonNameSwitchUserListMode, FBCommandSequenceSwitchUserListMode},
		{BBSUserInfo, @"求救[h]", 7, WLButtonNameShowHelp, fbShowHelp},
		{BBSUserInfo, @"查看说明档[l]", 13, WLButtonNameShowUserDescription, FBCommandSequenceShowUserDescription},
		{BBSUserInfo, @"选择使用", 8, WLButtonNamePreviousUser, FBCommandSequencePreviousUser},
		{BBSUserInfo, @"者[↑,↓]", 9, WLButtonNameNextUser, FBCommandSequenceNextUser},
	};
	
	if (r > 3 && r < _maxRow-1)
		return;
	
	YLTerminal *ds = [_view frontMostTerminal];
	BBSState bbsState = [ds bbsState];
	
	for (int x = 0; x < _maxColumn; ++x) {
		for (int i = 0; i < sizeof(buttonsDefinition) / sizeof(WLButtonDescription); ++i) {
			WLButtonDescription buttonDescription  = buttonsDefinition[i];
			if (bbsState.state != buttonDescription.state)
				continue;
			int length = buttonDescription.signatureLengthOfBytes;
			if (x < _maxColumn - length) {
				if ([[ds stringFromIndex:(x + r * _maxColumn) length:length] isEqualToString:buttonDescription.signature]) {
					[self addButtonArea:buttonDescription.buttonName 
						commandSequence:buttonDescription.commandSequence 
								  atRow:r 
								 column:x 
								 length:length];
					x += length - 1;
					break;
				}
			}
		}
	}
}

- (BOOL)shouldUpdate {
	if (![_view shouldEnableMouse] || ![_view isConnected]) {
		return YES;
	}
	
	// Only update when BBS state has been changed
	BBSState bbsState = [[_view frontMostTerminal] bbsState];
	BBSState lastBbsState = [_manager lastBBSState];
	if (bbsState.state == lastBbsState.state &&
		bbsState.subState == lastBbsState.subState)
		return NO;
	
	return YES;
}

- (void)update {
	// Clear & Update
	[self clear];
	if (![_view shouldEnableMouse] || ![_view isConnected]) {
		return;	
	}
	for (int r = 0; r < _maxRow; ++r) {
		[self updateButtonAreaForRow:r];
	}
}
@end
