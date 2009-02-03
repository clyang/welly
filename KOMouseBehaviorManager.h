//
//  KOMouseBehaviorManager.h
//  Welly
//
//  Created by K.O.ed on 09-1-31.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KOMouseHotspotHandler.h"
#import "KOIPAddrHotspotHandler.h"
#import "KOClickEntryHotspotHandler.h"
#import "KOButtonAreaHotspotHandler.h"
#import "KOMovingAreaHotspotHandler.h"

NSString * const KOMouseHandlerUserInfoName;
NSString * const KOMouseRowUserInfoName;
NSString * const KOMouseCommandSequenceUserInfoName;
NSString * const KOMouseButtonTypeUserInfoName;
NSString * const KOMouseButtonTextUserInfoName;
NSString * const KOMouseCursorUserInfoName;

@class YLView, KOEffectView;
@interface KOMouseBehaviorManager : NSResponder {
	YLView *_view;
	
	NSDictionary *activeTrackingAreaUserInfo;
	NSDictionary *backgroundTrackingAreaUserInfo;
	
	KOMouseHotspotHandler <KOMouseHotspotDelegate> *_activeMouseHandler;
	
	KOIPAddrHotspotHandler *_ipAddrHandler;
	KOClickEntryHotspotHandler *_clickEntryHandler;
	KOButtonAreaHotspotHandler *_buttonAreaHandler;
	KOMovingAreaHotspotHandler *_movingAreaHandler;
}
@property (readwrite, assign) NSDictionary *activeTrackingAreaUserInfo;
@property (readwrite, assign) NSDictionary *backgroundTrackingAreaUserInfo;

- (id) initWithView: (YLView *)view;
- (YLView *) view;

- (void) refreshAllHotSpots;
- (void) addTrackingAreaWithRect: (NSRect) rect 
						userInfo: (NSDictionary *)userInfo;
- (void) addTrackingAreaWithRect: (NSRect) rect 
						userInfo: (NSDictionary *)userInfo 
						  cursor: (NSCursor *)cursor;
- (void) clearAllTrackingArea;
@end
