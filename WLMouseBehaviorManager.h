//
//  WLMouseBehaviorManager.h
//  Welly
//
//  Created by K.O.ed on 09-1-31.
//  Copyright 2009 Welly Group. All rights reserved.
//
/*!
    @header WLMouseBehaviorManager
    @abstract   A class deal with all mouse behavior about mouse hotspot within the YLView.
    @discussion Welly uses <code>NSTrackingArea</code> to catch mouse movement inside the view. All tracking area for mouse hotspot should be created by the API provided in this file, so that they would have consistent behaviors. Currently welly's mouse hotspot only deal with <code>mouseUp:</code> and <code>menuForEvent:</code> (right click) clicking event. <code>mouseDown:</code> and <code>mouseDragged:</code> are implemented in <code>YLView</code> class, and they have no business with mouse hotspot.
*/

#import <Cocoa/Cocoa.h>
#import "WLMouseHotspotHandler.h"
#import "CommonType.h"

NSString *const WLMouseHandlerUserInfoName;
NSString *const WLMouseRowUserInfoName;
NSString *const WLMouseCommandSequenceUserInfoName;
NSString *const WLMouseButtonTypeUserInfoName;
NSString *const WLMouseButtonTextUserInfoName;
NSString *const WLMouseCursorUserInfoName;
NSString *const WLMouseAuthorUserInfoName;
NSString *const WLURLUserInfoName;
NSString *const WLRangeLocationUserInfoName;
NSString *const WLRangeLengthUserInfoName;


@class YLView, WLEffectView;
/*!
    @class
    @abstract    Manages mouse behavior for <code>YLView</code>, including <code>mouseUp:</code>, <code>mouseEntered:</code>, <code>mouseExited:</code>, <code>mouseMoved:</code>, and <code>menuForEvent:</code>.
    @discussion  When the <code>YLView</code> receives mouse event message, it would inform <code>WLMouseBehaviorManager</code> to deal the event for it. The manager would then dispatch the event to proper <code>WLMouseHotspotHandler</code> to handle.
 
 When the <code>YLView</code>'s content refreshes, it would inform manager about its change, and then the manager would inform all <code>WLUpdatable</code> handlers to update their state.
*/
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
@property (readonly) YLView *view;

- (id)initWithView:(YLView *)view;

// Add/Remove tracking areas
/*!
 @method     
 @abstract   Update all registered <code>WLUpdatable</code> objects
 @discussion This method would firstly ask every <code>WLUpdatable</code> if they <code>shouldUpdate</code>. For those return <code>YES</code>, their <code>update</code> method would then be called, informing them the view has changed so they can fetch the update info they need.
*/
- (void)update;
/*!
 @method     
 @abstract   Force all registered <code>WLUpdatable</code> objects to update themselves.
 @discussion Unlike the <code>update</code> method, this method would not ask the updatable objects if they <code>shouldUpdate</code>. Instead, their <code>update</code> method would be called immediately. In additional, calling this method would set the <code>activeTrackingAreaUserInfo</code> and <code>backgroundTrackingAreaUserInfo</code> to be <code>nil</code>.
*/
- (void)forceUpdate;
/*!
 @method     
 @abstract   Add a tracking area into the view.
 @param	rect		The rectangle area for the tracking area.
 @param	userInfo	The user info to set along with the tracking area.
 @discussion This method would create a tracking area with the given rectangle area and the user info. The tracking area's option would be set to <code>NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInActiveApp</code>. The owner for this area would be the manager itself. Then the area would be added into the view. 
 
 Finally, this method would check mouse's current position. If the mouse is inside the given <code>rect</code>, then a <code>mouseEntered:</code> message would be sent to the manager itself, so the event can be dispatch to the newly built area immediately.
 
 Notice that, the hot spot handlers should use this method to add tracking areas into the view. Otherwise they have to deal with the initial mouse enter event by themselves.
*/
- (NSTrackingArea *)addTrackingAreaWithRect:(NSRect)rect
								   userInfo:(NSDictionary *)userInfo;
/*!
 @method     
 @abstract   Add a tracking area into the view, along with a cursor rect.
 @param	rect		The rectangle area for the tracking area.
 @param	userInfo	The user info to set along with the tracking area.
 @param	cursor		The wanted cursor when mouse is moving above the tracking area.
 @discussion The method would firstly called <code>addTrackingAreaWithRect:userInfo:</code>, and then add a cursor rect with given <code>cursor</code>.
*/
- (NSTrackingArea *)addTrackingAreaWithRect:(NSRect)rect
								   userInfo:(NSDictionary *)userInfo
									 cursor:(NSCursor *)cursor;
/*!
 @method     
 @abstract   Remove a tracking area from the view.
 @discussion This method would firstly check the mouse's position. If the mouse currently lies inside the tracking area, a <code>mouseExited:</code> method would be firstly sent to the manager, and then dispatch to the area. And then the area would be removed from the view and get released.
*/
- (void)removeTrackingArea:(NSTrackingArea *)area;

- (void)restoreNormalCursor;

- (void)addHandler:(WLMouseHotspotHandler *)handler;
@end
