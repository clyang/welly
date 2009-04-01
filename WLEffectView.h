//
//  WLEffectView.h
//  Welly
//
//  Created by K.O.ed on 08-8-15.
//  Copyright 2008 Welly Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CoreAnimation.h>

#define DEFAULT_POPUP_BOX_FONT @"Helvetica"
#define DEFAULT_POPUP_MENU_FONT @"Lucida Grande"

@class YLView;

@interface WLEffectView : NSView {
    CALayer *_mainLayer;
	
	IBOutlet YLView *_mainView;
	
	CALayer *_ipAddrLayer;
	CALayer *_clickEntryLayer;
	CALayer *_popUpLayer;
	CALayer *_buttonLayer;
	
	CALayer *_menuLayer;
	CALayer *_selectionLayer;
	CALayer *_urlLineLayer;
	CGImageRef _urlIndicatorImage;
	CALayer *_urlIndicatorLayer;
	int selectedItemIndex;
}

// for ip seeker
- (void)drawIPAddrBox:(NSRect)rect;
- (void)clearIPAddrBox;

// for post view
- (void)drawClickEntry:(NSRect)rect;
- (void)clearClickEntry;

// for button
- (void)drawButton:(NSRect)rect 
	   withMessage:(NSString *)message;
- (void)clearButton;

// for menu
- (void)showMenuAtPoint:(NSPoint)pt 
			  withItems:(NSArray *)items;
- (void)hideMenu;
- (void)selectMenuItemAtIndex:(int)index;
- (void)selectPreviousMenuItem;
- (void)selectNextMenuItem;

// for URL
- (void)drawURLUnderlineAtRow:(int)r
				   fromColumn:(int)start 
					 toColumn:(int)end;
- (void)showIndicatorAtPoint:(NSPoint)point;
- (void)removeIndicator;

// To show pop up message by core animation
// This method might be changed in future
// by gtCarrera @ 9#
- (void)drawPopUpMessage:(NSString*)message;
- (void)removePopUpMessage;

- (void)resize;
- (void)clear;
- (void)setupLayer;
@end
