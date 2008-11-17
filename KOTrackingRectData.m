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
	data->type = IP_ADDR;
	data->ipAddr = [ipAddr retain];
	data->toolTip = [toolTip retain];
	return data;
}

+ (KOTrackingRectData *)clickEntryRectData: (NSString *)postTitle
									atRow: (int)row {
	KOTrackingRectData *data = [[self alloc] init];
	data->type = CLICK_ENTRY;
	data->postTitle = [postTitle retain];
	data->row = row;
	return data;
}

+ (KOTrackingRectData *)mainMenuClickEntryRectData: (NSString *)cmd {
	KOTrackingRectData *data = [[self alloc] init];
	data->type = MAIN_MENU_CLICK_ENTRY;
	data->commandSequence = [cmd retain];
	return data;
}

+ (KOTrackingRectData *)exitRectData {
	KOTrackingRectData *data = [[self alloc] init];
	data->type = EXIT_AREA;
	return data;
}

+ (KOTrackingRectData *)buttonRectData: (KOButtonType)buttonType 
					   commandSequence: (NSString *)cmd {
	KOTrackingRectData *data = [[self alloc] init];
	data->type = BUTTON;
	data->buttonType = buttonType;
	data->commandSequence = [cmd retain];
	return data;
}

- (NSString *)getButtonText {
	assert(type == BUTTON);
	switch (buttonType) {
		case COMPOSE_POST:
			return @"发表文章";
		case DELETE_POST:
			return @"自宫";
		default:
			break;
	}
	return @"";
}

@end
