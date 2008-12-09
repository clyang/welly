//
//  KOEffectView.h
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

@interface KOEffectView : NSView {
    CALayer *mainLayer;
	
	IBOutlet YLView *mainView;
	
	CALayer *ipAddrLayer;
	CALayer *clickEntryLayer;
	CALayer *popUpLayer;
	CALayer *buttonLayer;
	
	CALayer *menuLayer;
	CALayer *selectionLayer;
}

// for ip seeker
- (void)drawIPAddrBox: (NSRect) rect;
- (void)clearIPAddrBox;

// for post view
- (void)drawClickEntry: (NSRect) rect;
- (void)clearClickEntry;

// for button
- (void)drawButton: (NSRect) rect withMessage: (NSString *) message;
- (void)clearButton;

// for menu
- (void)showMenuAtPoint: (NSPoint) pt 
			withItems: (NSArray *) items;
- (void)hideMenu;

// To show pop up message by core animation
// This method might be changed in future
// by gtCarrera @ 9#
- (void)drawPopUpMessage:(NSString*) message;
- (void)removePopUpMessage;

- (void)resize;
- (void)clear;
- (void)setupLayer;
@end
