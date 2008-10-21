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
		IPADDR, CLICKENTRY
	} type;
	
	NSString *ipAddr;
	NSString *toolTip;
	NSString *postTitle;
	int row;
	int column;
}

+ (KOTrackingRectData *)ipRectData: (NSString *)ipAddr
						   toolTip: (NSString *)toolTip;
+ (KOTrackingRectData *)clickEntryRectData: (NSString *)postTitle
									atRow: (int)row;
@end
