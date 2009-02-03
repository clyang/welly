//
//  KOButtonAreaHotspotHandler.h
//  Welly
//
//  Created by K.O.ed on 09-1-27.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KOMouseHotspotHandler.h"

#define fbComposePost @"\020"
#define fbDeletePost @"dy\n"
#define fbShowNote @"\t"
#define fbShowHelp @"h"
#define fbNormalToDigest @"\07""1\n"
#define fbDigestToThread @"\07""2\n"
#define fbThreadToMark @"\07""3\n"
#define fbMarkToOrigin @"\07""4\n"
#define fbOriginToNormal @"e"

NSString * const KOButtonTypeComposePost;
NSString * const KOButtonTypeDeletePost;
NSString * const KOButtonTypeShowNote;
NSString * const KOButtonTypeShowHelp;
NSString * const KOButtonTypeNormalToDigest;
NSString * const KOButtonTypeDigestToThread;
NSString * const KOButtonTypeThreadToMark;
NSString * const KOButtonTypeMarkToOrigin;
NSString * const KOButtonTypeOriginToNormal;

typedef enum {
	COMPOSE_POST, DELETE_POST, SHOW_NOTE, SHOW_HELP, NORMAL_TO_DIGEST, DIGEST_TO_THREAD, THREAD_TO_MARK, MARK_TO_ORIGIN, ORIGIN_TO_NORMAL
} KOButtonType;

@class YLView;
@interface KOButtonAreaHotspotHandler : KOMouseHotspotHandler <KOMouseHotspotDelegate> {
	NSString *_commandSequence;
}

- (void) update;
@end
