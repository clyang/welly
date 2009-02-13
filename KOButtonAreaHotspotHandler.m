//
//  KOButtonAreaHotspotHandler.m
//  Welly
//
//  Created by K.O.ed on 09-1-27.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
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

NSString * const KOButtonNameComposePost = @"Compose Post";
NSString * const KOButtonNameDeletePost = @"Delete Post";
NSString * const KOButtonNameShowNote = @"Show Note";
NSString * const KOButtonNameShowHelp = @"Show Help";
NSString * const KOButtonNameNormalToDigest = @"Normal To Digest";
NSString * const KOButtonNameDigestToThread = @"Digest To Thread";
NSString * const KOButtonNameThreadToMark = @"Thread To Mark";
NSString * const KOButtonNameMarkToOrigin = @"Mark To Origin";
NSString * const KOButtonNameOriginToNormal = @"Origin To Normal";
NSString * const KOButtonNameSwitchDisplayAllBoards = @"Display All Boards";
NSString * const KOButtonNameSwitchSortBoards = @"Sort Boards";
NSString * const KOButtonNameSwitchBoardsNumber = @"Switch Boards Number";

@implementation KOButtonAreaHotspotHandler
#pragma mark -
#pragma mark Mouse Event Handler
- (void) mouseUp: (NSEvent *)theEvent {
	NSString *commandSequence = [_manager.activeTrackingAreaUserInfo objectForKey:KOMouseCommandSequenceUserInfoName];
	if (commandSequence != nil) {
		[[_view frontMostConnection] sendText: commandSequence];
		return;
	}
}

- (void) mouseEntered: (NSEvent *)theEvent {
	//NSLog(@"mouseEntered: ");
	NSDictionary *userInfo = [[theEvent trackingArea] userInfo];
	NSString *buttonText = [userInfo objectForKey:KOMouseButtonTextUserInfoName];
	if([[_view frontMostConnection] connected]) {
		[[_view effectView] drawButton:[[theEvent trackingArea] rect] withMessage:buttonText];
		_manager.activeTrackingAreaUserInfo = userInfo;
	}
}

- (void) mouseExited: (NSEvent *)theEvent {
	//NSLog(@"mouseExited: ");
	[[_view effectView] clearButton];
	_manager.activeTrackingAreaUserInfo = nil;
	// FIXME: Temporally solve the problem in full screen mode.
	if ([NSCursor currentCursor] == [NSCursor pointingHandCursor])
		[[NSCursor arrowCursor] set];
}

- (void) mouseMoved: (NSEvent *)theEvent {
	if ([NSCursor currentCursor] != [NSCursor pointingHandCursor])
		[[NSCursor pointingHandCursor] set];
}

#pragma mark -
#pragma mark Update State
- (void) addButtonArea: (NSString *)buttonName
	   commandSequence: (NSString *)cmd 
				 atRow: (int)r 
				column: (int)c 
				length: (int)len {
	NSRect rect = [_view rectAtRow:r column:c height:1 width:len];
	// Generate User Info
	NSArray *keys = [NSArray arrayWithObjects: KOMouseHandlerUserInfoName, KOMouseCommandSequenceUserInfoName, KOMouseButtonTextUserInfoName, nil];
	NSArray *objects = [NSArray arrayWithObjects: self, cmd, NSLocalizedString(buttonName, @"Mouse Button"), nil];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	[_manager addTrackingAreaWithRect:rect userInfo:userInfo cursor:[NSCursor pointingHandCursor]];
}

- (void) updateButtonAreaForRow:(int)r {
	const KOButtonDescription ButtonsForBrowseBoard[] = {
		{@"发表文章[Ctrl-P]", 16, KOButtonNameComposePost, fbComposePost},
		{@"砍信[d]", 7, KOButtonNameDeletePost, fbDeletePost},
		{@"备忘录[TAB]", 11, KOButtonNameShowNote, fbShowNote},
		{@"求助[h]", 7, KOButtonNameShowHelp, fbShowHelp},
		{@"[一般模式]", 10, KOButtonNameNormalToDigest, fbNormalToDigest},
		{@"[文摘模式]", 10, KOButtonNameDigestToThread, fbDigestToThread},
		{@"[主题模式]", 10, KOButtonNameThreadToMark, fbThreadToMark},
		{@"[精华模式]", 10, KOButtonNameMarkToOrigin, fbMarkToOrigin},
		{@"[原作模式]", 10, KOButtonNameOriginToNormal, fbOriginToNormal},
	};
	const KOButtonDescription ButtonsForBoardList[] = {
		{@"列出[y]", 7, KOButtonNameSwitchDisplayAllBoards, fbSwitchDisplayAllBoards},
		{@"排序[S]", 7, KOButtonNameSwitchSortBoards, fbSwitchSortBoards},
		{@"切换[c]", 7, KOButtonNameSwitchBoardsNumber, fbSwitchBoardsNumber},
		{@"求助[h]", 7, KOButtonNameShowHelp, fbShowHelp},
	};
	YLTerminal *ds = [_view frontMostTerminal];
	
	if ([ds bbsState].state == BBSBrowseBoard) {
		for (int x = 0; x < _maxColumn; ++x) {
			for (int i = 0; i < sizeof(ButtonsForBrowseBoard) / sizeof(KOButtonDescription); ++i) {
				KOButtonDescription buttonDescription  = ButtonsForBrowseBoard[i];
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
	} else if ([ds bbsState].state == BBSBoardList) {
		for (int x = 0; x < _maxColumn; ++x) {
			for (int i = 0; i < sizeof(ButtonsForBoardList) / sizeof(KOButtonDescription); ++i) {
				KOButtonDescription buttonDescription  = ButtonsForBoardList[i];
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
}

- (void) update {
	// For the mouse preference
	if (![_view mouseEnabled]) 
		return;
	for (int r = 0; r < _maxRow; ++r) {
		[self updateButtonAreaForRow: r];
	}
}
@end
