//
//  KOTrackingRectData.m
//  Welly
//
//  Created by K.O.ed on 08-10-15.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "KOTrackingRectData.h"


@implementation KOTrackingRectData

+ (KOTrackingRectData *)ipRectData: (NSString *)ipAddr
						   toolTip: (NSString *)toolTip {
	KOTrackingRectData *data = [[self alloc] init];
	data->type = IPADDR;
	data->ipAddr = ipAddr;
	data->toolTip = toolTip;
	return data;
}

@end
