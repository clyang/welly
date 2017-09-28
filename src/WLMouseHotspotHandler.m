//
//  WLMouseHotspotHandler.m
//  Welly
//
//  Created by K.O.ed on 09-1-27.
//  Copyright 2009 Welly Group. All rights reserved.
//
#import "WLMouseHotspotHandler.h"
#import "WLTerminalView.h"
#import "WLEffectView.h"
#import "WLGlobalConfig.h"
#import "WLMouseBehaviorManager.h"

@implementation WLMouseHotspotHandler
@synthesize manager = _manager;
- (id)init {
	self = [super init];
	if (self)
		_trackingAreas = [[NSMutableArray alloc] initWithCapacity:10];
	return self;
}

- (id)initWithView:(WLTerminalView *)view {
	self = [self init];
	if (self) {
		_view = view;
		_maxRow = [[WLGlobalConfig sharedInstance] row];
		_maxColumn = [[WLGlobalConfig sharedInstance] column];
	}
	return self;
}

- (id)initWithManager:(WLMouseBehaviorManager *)manager {
	_manager = manager;
	return [self initWithView:[_manager view]];
}

- (void)dealloc {
	[_trackingAreas release];
	[super dealloc];
}

- (void)mouseEntered:(NSEvent *)theEvent {
	// Do nothing, just a virtual function
}

- (void)removeAllTrackingAreas {
	for (NSTrackingArea *trackingArea in _trackingAreas) {
		[_manager removeTrackingArea:trackingArea];
	}
	[_trackingAreas removeAllObjects];
}

- (void)clear {
	[self removeAllTrackingAreas];
}
@end
