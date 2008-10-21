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

@class YLView;

@interface KOEffectView : NSView {
    CALayer *mainLayer;
	
	IBOutlet YLView *mainView;
	
	CALayer *boxLayer;
	CALayer *postLayer;
	CALayer *popUpLayer;
}

// for ip seeker
- (void)drawBox: (NSRect) rect;
- (void)clearBox;

// for post view
- (void)drawPostEntry: (NSRect) rect;
- (void)clearPostEntry;

// To show pop up message by core animation
// This method might be changed in future
// by gtCarrera @ 9#
- (void)drawPopUpMessage:(NSString*) message;
- (void)removePopUpMessage;

- (void)resize;
- (void)clear;
- (void)setupLayer;
@end
