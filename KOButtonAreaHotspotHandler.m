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

NSString * const KOButtonTypeComposePost = @"Compose Post";
NSString * const KOButtonTypeDeletePost = @"Delete Post";
NSString * const KOButtonTypeShowNote = @"Show Note";
NSString * const KOButtonTypeShowHelp = @"Show Help";
NSString * const KOButtonTypeNormalToDigest = @"Normal To Digest";
NSString * const KOButtonTypeDigestToThread = @"Digest To Thread";
NSString * const KOButtonTypeThreadToMark = @"Thread To Mark";
NSString * const KOButtonTypeMarkToOrigin = @"Mark To Origin";
NSString * const KOButtonTypeOriginToNormal = @"Origin To Normal";

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

- (NSString *)getButtonText: (KOButtonType)buttonType {
	switch (buttonType) {
		case COMPOSE_POST:
			return @"发表文章";
		case DELETE_POST:
			return @"自宫";
		case SHOW_NOTE:
			return @"备忘录";
		case SHOW_HELP:
			return @"求助";
		case NORMAL_TO_DIGEST:
			return @"切换到文摘模式";
		case DIGEST_TO_THREAD:
			return @"切换到主题模式";
		case THREAD_TO_MARK:
			return @"切换到精华模式";
		case MARK_TO_ORIGIN:
			return @"切换到原作模式";
		case ORIGIN_TO_NORMAL:
			return @"切换到一般模式";
		default:
			break;
	}
	return @"";
}

#pragma mark -
#pragma mark Update State
- (void) addButtonArea: (KOButtonType)buttonType 
	   commandSequence: (NSString *)cmd 
				 atRow: (int)r 
				column: (int)c 
				length: (int)len {
	NSRect rect = [_view rectAtRow:r column:c height:1 width:len];
	// Generate User Info
	NSArray *keys = [NSArray arrayWithObjects: KOMouseHandlerUserInfoName, KOMouseCommandSequenceUserInfoName, KOMouseButtonTextUserInfoName, nil];
	NSArray *objects = [NSArray arrayWithObjects: self, cmd, [self getButtonText: buttonType], nil];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	[_manager addTrackingAreaWithRect:rect userInfo:userInfo cursor:[NSCursor pointingHandCursor]];
}

- (void) updateButtonAreaForRow:(int)r {
	YLTerminal *ds = [_view frontMostTerminal];
	//cell *currRow = [ds cellsOfRow: r];
	if ([ds bbsState].state == BBSBrowseBoard) {
		for (int x = 0; x < _maxColumn; ++x) {
			if (x < _maxColumn - 16 && [[ds stringFromIndex:(x + r * _maxColumn) length:16] isEqualToString:@"发表文章[Ctrl-P]"]) {
				[self addButtonArea:COMPOSE_POST commandSequence:fbComposePost atRow:r column:x length:16];
				x += 15;
				continue;
			}
			if (x < _maxColumn - 7 && [[ds stringFromIndex:(x + r * _maxColumn) length:7] isEqualToString:@"砍信[d]"]) {
				[self addButtonArea:DELETE_POST commandSequence:fbDeletePost atRow:r column:x length:7];
				x += 6;
				continue;
			}
			if (x < _maxColumn - 11 && [[ds stringFromIndex:(x + r * _maxColumn) length:11] isEqualToString:@"备忘录[TAB]"]) {
				[self addButtonArea:SHOW_NOTE commandSequence:fbShowNote atRow:r column:x length:11];
				x += 10;
				continue;
			}
			if (x < _maxColumn - 7 && [[ds stringFromIndex:(x + r * _maxColumn) length:7] isEqualToString:@"求助[h]"]) {
				[self addButtonArea:SHOW_HELP commandSequence:fbShowHelp atRow:r column:x length:7];
				x += 6;
				continue;
			}
			if (x < _maxColumn - 10 && [[ds stringFromIndex:(x + r * _maxColumn) length:10] isEqualToString:@"[一般模式]"]) {
				[self addButtonArea:NORMAL_TO_DIGEST commandSequence:fbNormalToDigest atRow:r column:x length:10];
				x += 9;
				continue;
			}
			if (x < _maxColumn - 10 && [[ds stringFromIndex:(x + r * _maxColumn) length:10] isEqualToString:@"[文摘模式]"]) {
				[self addButtonArea:DIGEST_TO_THREAD commandSequence:fbDigestToThread atRow:r column:x length:10];
				x += 9;
				continue;
			}
			if (x < _maxColumn - 10 && [[ds stringFromIndex:(x + r * _maxColumn) length:10] isEqualToString:@"[主题模式]"]) {
				[self addButtonArea:THREAD_TO_MARK commandSequence:fbThreadToMark atRow:r column:x length:10];
				x += 9;
				continue;
			}
			if (x < _maxColumn - 10 && [[ds stringFromIndex:(x + r * _maxColumn) length:10] isEqualToString:@"[精华模式]"]) {
				[self addButtonArea:MARK_TO_ORIGIN commandSequence:fbMarkToOrigin atRow:r column:x length:10];
				x += 9;
				continue;
			}
			if (x < _maxColumn - 10 && [[ds stringFromIndex:(x + r * _maxColumn) length:10] isEqualToString:@"[原作模式]"]) {
				[self addButtonArea:ORIGIN_TO_NORMAL commandSequence:fbOriginToNormal atRow:r column:x length:10];
				x += 9;
				continue;
			}
		}
	}
}

- (void) update {
	for (int r = 0; r < _maxRow; ++r) {
		[self updateButtonAreaForRow: r];
	}
}
@end
