//
//  WLButtonAreaHotspotHandler.h
//  Welly
//
//  Created by K.O.ed on 09-1-27.
//  Copyright 2009 Welly Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WLMouseHotspotHandler.h"
#import "YLTerminal.h"

NSString * const WLButtonNameComposePost;
NSString * const WLButtonNameDeletePost;
NSString * const WLButtonNameShowNote;
NSString * const WLButtonNameShowHelp;
NSString * const WLButtonNameNormalToDigest;
NSString * const WLButtonNameDigestToThread;
NSString * const WLButtonNameThreadToMark;
NSString * const WLButtonNameMarkToOrigin;
NSString * const WLButtonNameOriginToNormal;
NSString * const WLButtonNameSwitchDisplayAllBoards;
NSString * const WLButtonNameSwitchSortBoards;
NSString * const WLButtonNameSwitchBoardsNumber;
NSString * const WLButtonNameDeleteBoard;

typedef struct {
	int state;
	NSString *signature;
	int signatureLengthOfBytes;
	NSString *buttonName;
	NSString *commandSequence;
} WLButtonDescription;

@class YLView;
@interface WLButtonAreaHotspotHandler : WLMouseHotspotHandler <WLMouseUpHandler, WLUpdatable> {
	NSString *_commandSequence;
}
@end
