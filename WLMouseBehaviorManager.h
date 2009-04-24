//
//  WLMouseBehaviorManager.h
//  Welly
//
//  Created by K.O.ed on 09-1-31.
//  Copyright 2009 Welly Group. All rights reserved.
//
/*!
    @header WLMouseBehaviorManager
    @abstract   A class deal with all mouse behavior within the YLView
    @discussion <#description#>
*/

#import <Cocoa/Cocoa.h>
#import "WLMouseHotspotHandler.h"
#import "CommonType.h"

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
	
	BBSState _lastBBSState;
	int _lastCursorRow;
}
@property (readwrite, assign) NSDictionary *activeTrackingAreaUserInfo;
@property (readwrite, assign) NSDictionary *backgroundTrackingAreaUserInfo;
@property (readwrite, assign) NSCursor *normalCursor;
@property (readonly) BBSState lastBBSState;
@property (readonly) int lastCursorRow;

- (id)initWithView:(YLView *)view;
- (YLView *)view;

// Add/Remove tracking areas
- (void)update;
- (void)forceUpdate;
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
