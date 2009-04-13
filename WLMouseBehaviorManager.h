//
//  WLMouseBehaviorManager.h
//  Welly
//
//  Created by K.O.ed on 09-1-31.
//  Copyright 2009 Welly Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WLMouseHotspotHandler.h"

NSString * const WLMouseHandlerUserInfoName;
NSString * const WLMouseRowUserInfoName;
NSString * const WLMouseCommandSequenceUserInfoName;
NSString * const WLMouseButtonTypeUserInfoName;
NSString * const WLMouseButtonTextUserInfoName;
NSString * const WLMouseCursorUserInfoName;
NSString * const WLMouseAuthorUserInfoName;
NSString * const WLURLUserInfoName;
NSString * const WLRangeLocationUserInfoName;
NSString * const WLRangeLengthUserInfoName;


@class YLView, WLEffectView;
@interface WLMouseBehaviorManager : NSResponder <WLMouseUpHandler, WLUpdatable, WLContextualMenuHandler> {
	YLView *_view;
	
	NSDictionary *_activeTrackingAreaUserInfo;
	NSDictionary *_backgroundTrackingAreaUserInfo;
	
	NSMutableArray *_handlers;
	
	NSCursor *_normalCursor;
	
	BOOL _enabled;
	
	enum {
		WLHorizontalScrollLeft, WLHorizontalScrollRight, WLHorizontalScrollNone
	} _lastHorizontalScrollDirection;
	NSTimer *_horizontalScrollReactivateTimer;
}
@property (readwrite, assign) NSDictionary *activeTrackingAreaUserInfo;
@property (readwrite, assign) NSDictionary *backgroundTrackingAreaUserInfo;
@property (readwrite, assign) NSCursor *normalCursor;

- (id)initWithView:(YLView *)view;
- (YLView *)view;

// Add/Remove tracking areas
- (void)update;
- (NSTrackingArea *)addTrackingAreaWithRect:(NSRect) rect 
					   userInfo:(NSDictionary *)userInfo;
- (NSTrackingArea *)addTrackingAreaWithRect:(NSRect) rect 
					   userInfo:(NSDictionary *)userInfo 
						 cursor:(NSCursor *)cursor;
- (void)removeTrackingArea:(NSTrackingArea *)area;
- (void)removeAllTrackingAreas;

- (void)restoreNormalCursor;

- (void)enable;
- (void)disable;

- (void)addHandler:(WLMouseHotspotHandler *)handler;
@end
