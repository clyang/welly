//
//  YLView.h
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/6/9.
//  Copyright 2006 yllan.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CommonType.h"

@class YLTerminal;
@class YLConnection;
@class YLMarkedTextView;
@class WLEffectView;
@class WLPortal;
@class WLMouseBehaviorManager;
@class WLURLManager;

#define disableMouseByKeyingTimerInterval 0.3

@interface YLView : NSTabView <NSTextInput> {	
	CGFloat _fontWidth;
	CGFloat _fontHeight;
	
	NSImage *_backedImage;
	
	NSTimer *_timer;
	int _x;
	int _y;
	
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
@property CGFloat fontWidth;
@property CGFloat fontHeight;
@property (readonly) WLEffectView *effectView;

- (void)configure;

- (void)copy:(id)sender;
- (void)pasteWrap:(id)sender;
- (void)paste:(id)sender;
- (void)pasteColor:(id)sender;

- (void)displayCellAtRow:(int)r column:(int)c;
- (void)updateBackedImage;
- (void)drawSelection;
- (void)drawBlink;
- (void)refreshHiddenRegion;
- (void)refreshMouseHotspot;

- (void)clearSelection;

- (YLTerminal *)frontMostTerminal;
- (YLConnection *)frontMostConnection;
- (BOOL)isConnected;

- (void)extendBottomFrom:(int)start 
					  to:(int)end;
- (void)extendTopFrom:(int)start 
				   to:(int)end ;

- (void)drawStringForRow:(int)r 
				 context:(CGContextRef)myCGContext;
- (void)drawURLUnderlineAtRow:(int)r 
				   fromColumn:(int)start 
					 toColumn:(int)end;
- (void)updateBackgroundForRow:(int)r 
						  from:(int)start 
							to:(int)end;

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
- (void)updatePortal;
- (void)removePortal;
- (void)checkPortal;
- (void)resetPortal;
- (void)addPortalPicture:(NSString *)source
				 forSite:(NSString *)siteName;

// Mouse operation
- (void)deactivateMouseForKeying;
- (void)activateMouseForKeying:(NSTimer*)timer;

- (int)convertIndexFromPoint:(NSPoint)aPoint;
- (NSPoint)mouseLocationInView;
@end
