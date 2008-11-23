//
//  KOTrackingRectData.h
//  Welly
//
//  Created by K.O.ed on 08-10-15.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
typedef enum {
	COMPOSE_POST, DELETE_POST, SHOW_NOTE, SHOW_HELP, NORMAL_TO_DIGEST, DIGEST_TO_THREAD, THREAD_TO_MARK, MARK_TO_ORIGIN, ORIGIN_TO_NORMAL
} KOButtonType;

@interface KOTrackingRectData : NSData {
@public
	enum KOTrackingRectType {
		IP_ADDR, CLICK_ENTRY, MAIN_MENU_CLICK_ENTRY, EXIT_AREA, BUTTON
	} type;
	
	NSString *ipAddr;
	NSString *toolTip;
	NSString *postTitle;
	int row;
	int column;
	
	KOButtonType buttonType;
	
	NSString *commandSequence;
}

+ (KOTrackingRectData *)ipRectData: (NSString *)ipAddr
						   toolTip: (NSString *)toolTip;
+ (KOTrackingRectData *)clickEntryRectData: (NSString *)postTitle
									 atRow: (int)row;
+ (KOTrackingRectData *)mainMenuClickEntryRectData: (NSString *)cmd;
+ (KOTrackingRectData *)exitRectData;
+ (KOTrackingRectData *)buttonRectData: (KOButtonType)buttonType 
					   commandSequence: (NSString *)cmd;

- (NSString *)getButtonText;

#define fbComposePost @"\020"
#define fbDeletePost @"dy\n"
#define fbShowNote @"\t"
#define fbShowHelp @"h"
#define fbNormalToDigest @"\07""1\n"
#define fbDigestToThread @"\07""2\n"
#define fbThreadToMark @"\07""3\n"
#define fbMarkToOrigin @"\07""4\n"
#define fbOriginToNormal @"e"
@end
