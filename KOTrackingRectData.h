//
//  KOTrackingRectData.h
//  Welly
//
//  Created by K.O.ed on 08-10-15.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface KOTrackingRectData : NSData {
@public
	enum KOTrackingRectType {
		IPADDR, POSTENTRY
	} type;
	
	NSString *ipAddr;
	NSString *toolTip;
	NSString *postTitle;
	int row;
	int column;
}

+ (KOTrackingRectData *)ipRectData: (NSString *)ipAddr
						   toolTip: (NSString *)toolTip;
+ (KOTrackingRectData *)postEntryRectData: (NSString *)postTitle
									atRow: (int)row;
@end
