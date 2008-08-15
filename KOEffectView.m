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
		[self setWantsLayer: YES];
    }
    return self;
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
	
    // Add a new layer to the mainlayer.
    //[self addNewLayer:nil];
}

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
	//[[NSColor redColor] set];
	//NSRectFill([self bounds]);
}

- (void)awakeFromNib;
{
    //[self setWantsLayer:YES];
    //[window setFrame:[[NSScreen mainScreen] frame] display:NO animate:NO];
    /*
	NSRect contentFrame = [mainView frame];
    CALayer *root = [mainView layer];
    
    // mainLayer is the layer that gets scaled. All of its sublayers
    // are automatically scaled with it.
    mainLayer = [CALayer layer];
    mainLayer.frame = NSRectToCGRect(contentFrame);
    
    // Make the background color to be a dark gray with a 50% alpha similar to
    // the real Dashbaord.
    mainLayer.backgroundColor = CGColorCreateGenericRGB(0.10, 0.10, 0.10, 0.50);
    [root insertSublayer:mainLayer above:0];
	
    // Add a new layer to the mainlayer.
    [self addNewLayer:nil];
    */
	[self setupLayer];
}

- (IBAction)addNewLayer:(id)sender;
{
	NSLog(@"addNewLayer:");
	CALayer *layer = [CALayer layer];
    
	layer.backgroundColor = CGColorCreateGenericRGB(0.1, 0.1, 0.1, 1.0f);
	layer.borderColor = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1.0f);
	layer.borderWidth = 1.0;
	
    // Create a random rectangle with a size between 300 and 200 pixels.
    NSRect rect = NSZeroRect;
	rect.size = NSMakeSize(200.0, 50.0);
	
	// Calculate random origin point
	rect.origin = SSRandomPointForSizeWithinRect( rect.size, [mainView frame] );
    
    // Set the layer frame to our random rectangle.
    layer.frame = NSRectToCGRect(rect);
	layer.cornerRadius = rect.size.height/5;
    
    // Create a text layer to add so we can see text scale too.
    CATextLayer *textLayer = [CATextLayer layer];
    textLayer.string = @"Hello World!";
    CGFontRef font = CGFontCreateWithFontName((CFStringRef)@"Helvetica");
    textLayer.font = font;
    textLayer.frame = CGRectMake(10.0, 100.0, 195.0, 35.0);
    CGFontRelease(font);
    
    // Use the same color for the text that we used for the border.
    textLayer.foregroundColor = layer.borderColor;
    // Add the text layer
    [layer addSublayer:textLayer];
    
    // Insert the layer into the root layer
	[mainLayer addSublayer:layer];
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
