//
//  WLMouseHotspotHandler.h
//  Welly
//
//  Created by K.O.ed on 09-1-12.
//  Copyright 2009 Welly Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CommonType.h"

@protocol WLMouseUpHandler
- (void)mouseUp:(NSEvent *)theEvent;
@end

@protocol WLUpdatable
- (void)update;
@end

@protocol WLContextualMenuHandler
- (NSMenu *)menuForEvent:(NSEvent *)theEvent;
@end

@class YLView, WLMouseBehaviorManager;
@interface WLMouseHotspotHandler : NSResponder {
	YLView *_view;
	
	WLMouseBehaviorManager *_manager;
	int _maxRow, _maxColumn;
	
	NSMutableArray *_trackingAreas;
	
	BBSState _lastBbsState;
	int _lastCursorRow;
}
@property (readwrite, assign) WLMouseBehaviorManager *manager;

- (id)initWithView:(YLView *)view;
- (id)initWithManager:(WLMouseBehaviorManager *)manager;
- (void)mouseEntered:(NSEvent *)theEvent;
- (void)removeAllTrackingAreas;
@end