//
//  KOEffectView.h
//  Welly
//
//  Created by K.O.ed on 08-8-15.
//  Copyright 2008 Welly Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CoreAnimation.h>

@class YLView;

@interface KOEffectView : NSView {
    CALayer *mainLayer;
	
	IBOutlet YLView *mainView;
	
	CALayer *boxLayer;
}

- (IBAction)addNewLayer:(id)sender;
- (void)drawBox: (NSRect) rect;
- (void)clear;
@end
