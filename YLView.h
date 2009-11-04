//
//  YLView.h
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/6/9.
//  Copyright 2006 yllan.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CommonType.h"
#import "WLSitesPanelController.h"
#import "WLTermView.h"

@class WLTerminal;
@class WLConnection;
@class YLMarkedTextView;
@class WLEffectView;
@class WLPortal;
@class WLMouseBehaviorManager;
@class WLURLManager;

#define disableMouseByKeyingTimerInterval 0.3

@interface YLView : WLTermView <NSTextInput, WLSitesObserver> {	
	NSTimer *_timer;
	
	id _markedText;
	NSRange _selectedRange;
	NSRange _markedRange;
	
	IBOutlet YLMarkedTextView *_textField;
	IBOutlet WLEffectView *_effectView;
    
    int _selectionLocation;
    int _selectionLength;
	BOOL _wantsRectangleSelection;
	BOOL _hasRectangleSelected;
    
    WLPortal *_portal;
	
	BOOL _isInPortalMode;
	BOOL _isInUrlMode;
	BOOL _isNotCancelingSelection;
	BOOL _isKeying;
	BOOL _isMouseActive;
	
	NSTimer *_activityCheckingTimer;
	
	WLMouseBehaviorManager *_mouseBehaviorDelegate;
	WLURLManager *_urlManager;
}
@property BOOL isInPortalMode;
@property BOOL isInUrlMode;
@property BOOL isMouseActive;
@property (readonly) WLEffectView *effectView;

- (BOOL)shouldWarnCompose;

- (void)copy:(id)sender;
- (void)pasteWrap:(id)sender;
- (void)paste:(id)sender;
- (void)pasteColor:(id)sender;

- (void)refreshHiddenRegion;
- (void)refreshMouseHotspot;

- (void)clearSelection;


- (NSRect)rectAtRow:(int)r 
			 column:(int)c 
			 height:(int)h 
			  width:(int)w;

- (BOOL)shouldEnableMouse;

- (void)sendText:(NSString *)text;

- (NSString *)selectedPlainString ;
- (BOOL)hasBlinkCell ;

- (void)insertText:(id)aString withDelay:(int)microsecond;
/* Url Menu */
- (void)switchURL;
- (void)exitURL;
/* Portal */
- (NSView *)portalView;
- (void)updatePortal;
- (void)removePortal;
- (void)resetPortal;
- (void)checkPortal;
//- (void)addPortalImage:(NSString *)source forSite:(NSString *)siteName;

// Mouse operation
- (void)deactivateMouseForKeying;
- (void)activateMouseForKeying:(NSTimer*)timer;

- (int)convertIndexFromPoint:(NSPoint)aPoint;
- (NSPoint)mouseLocationInView;
@end
