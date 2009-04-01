//
//  WLMouseHotspotHandler.m
//  Welly
//
//  Created by K.O.ed on 09-1-27.
//  Copyright 2009 Welly Group. All rights reserved.
//
#import "WLMouseHotspotHandler.h"
#import "YLView.h"
#import "WLEffectView.h"
#import "YLLGlobalConfig.h"
#import "WLMouseBehaviorManager.h"

@implementation WLMouseHotspotHandler
@synthesize manager = _manager;
- (id)initWithView:(YLView *)view {
	[self init];
	_view = view;
	_maxRow = [[YLLGlobalConfig sharedInstance] row];
	_maxColumn = [[YLLGlobalConfig sharedInstance] column];
	return self;
}

- (id)initWithManager:(WLMouseBehaviorManager *)manager {
	_manager = manager;
	return [self initWithView:[_manager view]];
}

- (void)mouseEntered:(NSEvent *)theEvent {
	// Do nothing, just a virtual function
}

@end
