//
//  KOButtonAreaHotspotHandler.m
//  Welly
//
//  Created by K.O.ed on 09-1-27.
//  Copyright 2009 Welly Group. All rights reserved.
//

#import "KOButtonAreaHotspotHandler.h"
#import "KOMouseBehaviorManager.h"

#import "YLView.h"
#import "YLConnection.h"
#import "YLTerminal.h"
#import "KOEffectView.h"

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

NSString *const KOButtonNameComposePost = @"Compose Post";
NSString *const KOButtonNameDeletePost = @"Delete Post";
NSString *const KOButtonNameShowNote = @"Show Note";
NSString *const KOButtonNameShowHelp = @"Show Help";
NSString *const KOButtonNameNormalToDigest = @"Normal To Digest";
NSString *const KOButtonNameDigestToThread = @"Digest To Thread";
NSString *const KOButtonNameThreadToMark = @"Thread To Mark";
NSString *const KOButtonNameMarkToOrigin = @"Mark To Origin";
NSString *const KOButtonNameOriginToNormal = @"Origin To Normal";
NSString *const KOButtonNameAuthorToNormal = @"Author To Normal";
NSString *const KOButtonNameJumpToMailList = @"Jump To Mail List";
NSString *const KOButtonNameEnterExcerption = @"Enter Excerption";

NSString *const KOButtonNameSwitchDisplayAllBoards = @"Display All Boards";
NSString *const KOButtonNameSwitchSortBoards = @"Sort Boards";
NSString *const KOButtonNameSwitchBoardsNumber = @"Switch Boards Number";
NSString *const KOButtonNameDeleteBoard = @"Delete Board";

NSString *const KOButtonNameChatWithUser = @"Chat";
NSString *const KOButtonNameMailToUser = @"Mail";
NSString *const KOButtonNameSendMessageToUser = @"Send Message";
NSString *const KOButtonNameAddUserToFriendList = @"Add To Friend List";
NSString *const KOButtonNameRemoveUserFromFriendList = @"Remove From Friend List";
NSString *const KOButtonNameSwitchUserListMode = @"Switch User List Mode";
NSString *const KOButtonNameShowUserDescription = @"Show User Description";
NSString *const KOButtonNamePreviousUser = @"Previous User";
NSString *const KOButtonNameNextUser = @"Next User";

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

@implementation KOButtonAreaHotspotHandler
#pragma mark -
#pragma mark Mouse Event Handler
- (void)mouseUp:(NSEvent *)theEvent {
	NSString *commandSequence = [[_manager activeTrackingAreaUserInfo] objectForKey:KOMouseCommandSequenceUserInfoName];
	if (commandSequence != nil) {
		[[_view frontMostConnection] sendText:commandSequence];
		return;
	}
}

- (void)mouseEntered:(NSEvent *)theEvent {
	//NSLog(@"mouseEntered: ");
	NSDictionary *userInfo = [[theEvent trackingArea] userInfo];
	NSString *buttonText = [userInfo objectForKey:KOMouseButtonTextUserInfoName];
	if([[_view frontMostConnection] isConnected]) {
		[[_view effectView] drawButton:[[theEvent trackingArea] rect] withMessage:buttonText];
		[_manager setActiveTrackingAreaUserInfo:userInfo];
	}
}

- (void)mouseExited:(NSEvent *)theEvent {
	//NSLog(@"mouseExited: ");
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
	NSArray *keys = [NSArray arrayWithObjects:KOMouseHandlerUserInfoName, KOMouseCommandSequenceUserInfoName, KOMouseButtonTextUserInfoName, nil];
	NSArray *objects = [NSArray arrayWithObjects:self, cmd, NSLocalizedString(buttonName, @"Mouse Button"), nil];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	[_manager addTrackingAreaWithRect:rect userInfo:userInfo cursor:[NSCursor pointingHandCursor]];
}

- (void)updateButtonAreaForRow:(int)r {
	const KOButtonDescription buttonsDefinition[] = {
		/* BBSBrowseBoard */
		{BBSBrowseBoard, @"发表文章[Ctrl-P]", 16, KOButtonNameComposePost, fbComposePost},
		{BBSBrowseBoard, @"砍信[d]", 7, KOButtonNameDeletePost, fbDeletePost},
		{BBSBrowseBoard, @"备忘录[TAB]", 11, KOButtonNameShowNote, fbShowNote},
		{BBSBrowseBoard, @"求助[h]", 7, KOButtonNameShowHelp, fbShowHelp},
		{BBSBrowseBoard, @"[一般模式]", 10, KOButtonNameNormalToDigest, fbNormalToDigest},
		{BBSBrowseBoard, @"[文摘模式]", 10, KOButtonNameDigestToThread, fbDigestToThread},
		{BBSBrowseBoard, @"[主题模式]", 10, KOButtonNameThreadToMark, fbThreadToMark},
		{BBSBrowseBoard, @"[精华模式]", 10, KOButtonNameMarkToOrigin, fbMarkToOrigin},
		{BBSBrowseBoard, @"[原作模式]", 10, KOButtonNameOriginToNormal, fbOriginToNormal},
		{BBSBrowseBoard, @"[作者模式]", 10, KOButtonNameAuthorToNormal, FBCommandSequenceAuthorToNormal},
		{BBSBrowseBoard, @"[您有信件]", 10, KOButtonNameJumpToMailList, FBCommandSequenceJumpToMailList},
		{BBSBrowseBoard, @"阅读[→,r]", 10, KOButtonNameEnterExcerption, FBCommandSequenceEnterExcerption},
		/* BBSBoardList */
		{BBSBoardList, @"列出[y]", 7, KOButtonNameSwitchDisplayAllBoards, fbSwitchDisplayAllBoards},
		{BBSBoardList, @"排序[S]", 7, KOButtonNameSwitchSortBoards, fbSwitchSortBoards},
		{BBSBoardList, @"切换[c]", 7, KOButtonNameSwitchBoardsNumber, fbSwitchBoardsNumber},
		{BBSBoardList, @"删除[d]", 7, KOButtonNameDeleteBoard, fbDeletePost},
		{BBSBoardList, @"求助[h]", 7, KOButtonNameShowHelp, fbShowHelp},
		{BBSBoardList, @"[您有信件]", 10, KOButtonNameJumpToMailList, FBCommandSequenceJumpToMailList},
		/* BBSUserInfo */
		{BBSUserInfo, @"寄信[m]", 7, KOButtonNameMailToUser, FBCommandSequenceMailToUser},
		{BBSUserInfo, @"聊天[t]", 7, KOButtonNameChatWithUser, FBCommandSequenceChatWithUser},
		{BBSUserInfo, @"送讯息[s]", 9, KOButtonNameSendMessageToUser, FBCommandSequenceSendMessageToUser},
		{BBSUserInfo, @"加,减朋", 7, KOButtonNameAddUserToFriendList, FBCommandSequenceAddUserToFriendList},
		{BBSUserInfo, @"友[o,d]", 7, KOButtonNameRemoveUserFromFriendList, FBCommandSequenceRemoveUserFromFriendList},
		{BBSUserInfo, @"切换模式 [f]", 12, KOButtonNameSwitchUserListMode, FBCommandSequenceSwitchUserListMode},
		{BBSUserInfo, @"求救[h]", 7, KOButtonNameShowHelp, fbShowHelp},
		{BBSUserInfo, @"查看说明档[l]", 13, KOButtonNameShowUserDescription, FBCommandSequenceShowUserDescription},
		{BBSUserInfo, @"选择使用", 8, KOButtonNamePreviousUser, FBCommandSequencePreviousUser},
		{BBSUserInfo, @"者[↑,↓]", 9, KOButtonNameNextUser, FBCommandSequenceNextUser},
	};
	YLTerminal *ds = [_view frontMostTerminal];
	
	for (int x = 0; x < _maxColumn; ++x) {
		for (int i = 0; i < sizeof(buttonsDefinition) / sizeof(KOButtonDescription); ++i) {
			KOButtonDescription buttonDescription  = buttonsDefinition[i];
			if ([ds bbsState].state != buttonDescription.state)
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

- (void)update {
	// For the mouse preference
	if (![_view mouseEnabled]) 
		return;
	for (int r = 0; r < _maxRow; ++r) {
		[self updateButtonAreaForRow:r];
	}
}
@end
