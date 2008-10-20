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
}

+ (KOTrackingRectData *)ipRectData: (NSString *)ipAddr
						   toolTip: (NSString *)toolTip;
+ (KOTrackingRectData *)postEntryRectData;
@end
