//
//  KOMouseBehaviorManager.h
//  Welly
//
//  Created by K.O.ed on 09-1-31.
//  Copyright 2009 Welly Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KOMouseHotspotHandler.h"

NSString * const KOMouseHandlerUserInfoName;
NSString * const KOMouseRowUserInfoName;
NSString * const KOMouseCommandSequenceUserInfoName;
NSString * const KOMouseButtonTypeUserInfoName;
NSString * const KOMouseButtonTextUserInfoName;
NSString * const KOMouseCursorUserInfoName;
NSString * const KOMouseAuthorUserInfoName;
NSString * const KOURLUserInfoName;
NSString * const KORangeLocationUserInfoName;
NSString * const KORangeLengthUserInfoName;


@class YLView, KOEffectView;
@interface KOMouseBehaviorManager : NSResponder <KOMouseUpHandler, KOUpdatable, KOContextualMenuHandler> {
	YLView *_view;
	
	NSDictionary *_activeTrackingAreaUserInfo;
	NSDictionary *_backgroundTrackingAreaUserInfo;
	
	NSMutableArray *_handlers;
	
	NSCursor *_normalCursor;
	
	BOOL _enabled;
	
	BOOL _isHorizontalScrollEnabled;
	NSTimer *_horizontalScrollReactivateTimer;
}
@property (readwrite, assign) NSDictionary *activeTrackingAreaUserInfo;
@property (readwrite, assign) NSDictionary *backgroundTrackingAreaUserInfo;
@property (readwrite, assign) NSCursor *normalCursor;

- (id)initWithView:(YLView *)view;
- (YLView *)view;

- (void)update;
- (void)addTrackingAreaWithRect:(NSRect) rect 
					   userInfo:(NSDictionary *)userInfo;
- (void)addTrackingAreaWithRect:(NSRect) rect 
					   userInfo:(NSDictionary *)userInfo 
						 cursor:(NSCursor *)cursor;
- (void)clearAllTrackingArea;

- (void)restoreNormalCursor;

- (void)enable;
- (void)disable;

- (void)addHandler:(KOMouseHotspotHandler *)handler;
@end
