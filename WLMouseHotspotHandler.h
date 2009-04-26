//
//  WLMouseHotspotHandler.h
//  Welly
//
//  Created by K.O.ed on 09-1-12.
//  Copyright 2009 Welly Group. All rights reserved.
//
/*!
    @header WLMouseHotspotHandler
    @abstract   The base class for all mouse hotspot handlers and several relative protocols.
    @discussion This header defines the base class for all mouse hotspot, @link WLMouseHotspotHandler WLMouseHotspotHandler @/link, along with several relative protocols, including @link //apple_ref/occ/intf/WLMouseUpHandler <code>WLMouseUpHandler</code> @/link, <code>WLUpdatable</code>, and <code>WLContextualMenuHandler</code>.
	@seealso	WLMouseBehaviorManager	WLMouseBehaviorManager
*/

#import <Cocoa/Cocoa.h>
#import "CommonType.h"

/*!
    @protocol
    @abstract    Any objects that can handle a mouseUp: event should implement this protocol.
    @discussion  By implements this protocol, a class claims its capability of dealing with mouseUp: event, so the @link WLMouseBehaviorManager <code>WLMouseBehaviorManager</code>@/link would know this class can handle <code>mouseUp:</code> event and passes contextual message to it.
*/
@protocol WLMouseUpHandler
/*!
    @method     
    @abstract   This method would be called when manager received a <code>mouseUp:</code> message from view.
	@param		theEvent	Event context.
    @discussion When the YLView received a <code>mouseUp:</code> message, it would pass this message to its <code>WLMouseBehaviorManager</code>. The manager would then figure out proper <code>WLMouseUpHandler</code> to receive this message. To implement this protocol, just focus on "What should I do when <code>mouseUp:</code> on me".
*/
- (void)mouseUp:(NSEvent *)theEvent;
@end

/*!
    @protocol
    @abstract    Any objects that want to be updated by <code>WLMouseBehaviorManager</code> should implement this protocol
    @discussion  If any class implements this protocol, and add its instance into <code>WLMouseBehaviorManager</code>'s update list, then it would be updated by the manager.
*/
@protocol WLUpdatable
/*!
    @method     
    @abstract   Tells if the updatable object should be updated.
	@result		If the <code>update</code> should be called, return <code>YES</code>. Otherwise return <code>NO</code>.
    @discussion When the <code>YLView</code> refreshes, the WLMouseBehaviorManager should be informed. Then it would ask every updatable object in its list if it should be updated. It would then call every object which returns <code>YES</code> to <code>update</code>.
*/
- (BOOL)shouldUpdate;
/*!
    @method     
    @abstract   Update the object's state.
    @discussion This method would be called by <code>WLMouseBehaviorManager</code> when it thinks this object should be updated. 
 
 There is 2 cases. One is the daily update, the manager would query every updatable objects and ask if <code>shouldUpdate</code>, then call update method of those which return <code>YES</code>. 
 
 The other case is forced update. In this case, the manager would no ask if the object should be updated. Instead, it would call <code>update</code> directly.
 
 Note that, neither the manager nor the view would push its update information. The object who want to be updated need to fetch the update information from the view itself.
*/
- (void)update;
@end

/*!
    @protocol
    @abstract    Any objects that could provide a contextual menu should implement this protocol.
    @discussion  Contextual menu is supported since Welly 2.2. This protocol is optional for mouse hotspot handlers. However it is recommended to implement this if the handler want to provide variable operations.
*/
@protocol WLContextualMenuHandler
/*!
    @method     
    @abstract   Provide a contextual menu.
	@param		theEvent	The event context.
    @discussion When the <code>YLView</code> receives a right click (without any selection), it would inform <code>WLMouseBehaviourManager</code>. If the active handler implements this protocol, the manager would inform it to provide the contextual menu.
*/
- (NSMenu *)menuForEvent:(NSEvent *)theEvent;
@end

@class YLView, WLMouseBehaviorManager;
/*!
    @class
    @abstract    The base class for all mouse hotspot handlers.
	@property	 manager	Relative <code>WLMouseBehaviorManager</code>.
    @discussion  This base class defines several methods, which are shared by all hotspot handlers.
*/
@interface WLMouseHotspotHandler : NSResponder {
	YLView *_view;
	
	WLMouseBehaviorManager *_manager;
	int _maxRow, _maxColumn;
	
	NSMutableArray *_trackingAreas;
}
/*!
	@property
	@abstract    Relative <code>WLMouseBehaviorManager</code>.
 */
@property (readwrite, assign) WLMouseBehaviorManager *manager;

/*!
    @method     
    @abstract   Initialize the handler with a <code>YLView</code> object.
	@param		view	Relative <code>YLView</code> object.
	@discussion	This method should be rarely called. In most of time, developers should use @link initWithManager: <code>initWithManager:</code>@/link instead. Using this initializing method requires <code>setManager:</code> manually.
*/
- (id)initWithView:(YLView *)view;

/*!
    @method     
    @abstract   Initialize the handler with a <code>WLMouseBehaviorManager</code> object.
	@param		manager	relative <code>WLMouseBehaviorManager</code> object.
    @discussion This method would call <code>initWithView:</code> firstly.
*/
- (id)initWithManager:(WLMouseBehaviorManager *)manager;

/*!
    @method     
    @abstract   Just a virtual method for subclass to override.
    @discussion Subclass should override this method to customize its own behavior on <code>mouseEntered:</code> event.
 
 Note that tracking areas would not get in charge of mouse clicking event, such as <code>mouseUp:</code> and <code>menuForEvent:</code>. For these who want to get in charge of mouse clicking event, they should call <code>[_manager setActiveTrackingAreaInfo:]</code> in this method, providing relative information in order that the manager can find relevant handler to deal with mouse clicking events.
*/
- (void)mouseEntered:(NSEvent *)theEvent;

/*!
    @method     
    @abstract   Remove all recorded tracking areas.
    @discussion Tracking areas owned by the instance should be recorded in <code>_trackingAreas</code> array. Calling this method would remove all tracking areas in <code>_trackingAreas</code> and empty the <code>_trackingAreas</code>.
 
 When carrying out the task that removing all tracking areas, the instance would firstly fetch a <code>NSTrackingArea</code> object, say <code>area</code>, from the <code>_trackingArea</code> array, then call <code>[_manager removeTrackingArea:area]</code>. For detailed information, please refer to <code>WLMouseBehaviorManager</code> class reference.
*/

- (void)removeAllTrackingAreas;
/*!
    @method     
    @abstract   Do neccessary cleanning work when the handler need to be cleared.
    @discussion By default, this method would only call <code>removeAllTrackingAreas</code>. If the subclass need do additional cleanning work (For eg. clear visual effects), it should override this method. Rememeber to call <code>removeAllTrackingAreas</code>!
*/
- (void)clear;
@end