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
	[data autorelease];
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

@end
