//
//  KOEffectView.m
//  Welly
//
//  Created by K.O.ed on 08-8-15.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "KOEffectView.h"

#import <Quartz/Quartz.h>
#import <ScreenSaver/ScreenSaver.h>


@implementation KOEffectView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)dealloc {
	[mainLayer release];
	[boxLayer release];
	
	[super dealloc];
}

- (void)setupLayer {
	NSRect contentFrame = [mainView frame];
	[self setFrame: contentFrame];
    CALayer *root = [self layer];
    
    // mainLayer is the layer that gets scaled. All of its sublayers
    // are automatically scaled with it.
    mainLayer = [CALayer layer];
    mainLayer.frame = NSRectToCGRect(contentFrame);
    
    // Make the background color to be a dark gray with a 50% alpha similar to
    // the real Dashbaord.
    mainLayer.backgroundColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 0.0);
    [root insertSublayer:mainLayer above:[mainView layer]];
}

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
	//[[NSColor redColor] set];
	//NSRectFill([self bounds]);
}

- (void)awakeFromNib;
{
	[self setupLayer];
}

- (void) setBox {
	boxLayer = [CALayer layer];
    
	boxLayer.backgroundColor = CGColorCreateGenericRGB(0.0, 0.95, 0.95, 0.1f);
	boxLayer.borderColor = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1.0f);
	boxLayer.borderWidth = 2.0;
	boxLayer.cornerRadius = 6.0;
}

- (void) drawBox: (NSRect) rect {
	if (!boxLayer)
		[self setBox];
	
	[boxLayer removeFromSuperlayer];
	
	rect.origin.x -= 1.0;
	rect.origin.y -= 0.0;
	rect.size.width += 2.0;
	rect.size.height += 0.0;
	
    // Set the layer frame to the rect
    boxLayer.frame = NSRectToCGRect(rect);
    
    // Insert the layer into the root layer
	[mainLayer addSublayer: [boxLayer retain]];
}

- (void) clear {
	[boxLayer removeFromSuperlayer];
}
@end
