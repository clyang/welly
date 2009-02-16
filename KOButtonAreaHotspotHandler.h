//
//  KOButtonAreaHotspotHandler.h
//  Welly
//
//  Created by K.O.ed on 09-1-27.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KOMouseHotspotHandler.h"
#import "YLTerminal.h"

NSString * const KOButtonNameComposePost;
NSString * const KOButtonNameDeletePost;
NSString * const KOButtonNameShowNote;
NSString * const KOButtonNameShowHelp;
NSString * const KOButtonNameNormalToDigest;
NSString * const KOButtonNameDigestToThread;
NSString * const KOButtonNameThreadToMark;
NSString * const KOButtonNameMarkToOrigin;
NSString * const KOButtonNameOriginToNormal;
NSString * const KOButtonNameSwitchDisplayAllBoards;
NSString * const KOButtonNameSwitchSortBoards;
NSString * const KOButtonNameSwitchBoardsNumber;
NSString * const KOButtonNameDeleteBoard;

typedef struct {
	int state;
	NSString *signature;
	int signatureLengthOfBytes;
	NSString *buttonName;
	NSString *commandSequence;
} KOButtonDescription;

@class YLView;
@interface KOButtonAreaHotspotHandler : KOMouseHotspotHandler <KOMouseUpHandler, KOUpdatable> {
	NSString *_commandSequence;
}
@end
