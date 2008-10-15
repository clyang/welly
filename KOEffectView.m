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
#import <CoreText/CTFont.h>


@implementation KOEffectView
- (id)initWithView:(YLView *)view {
	self = [self initWithFrame:[view frame]];
	if (self) {
		mainView = [view retain];
		[self setWantsLayer:YES];
		[self setupLayer];
	}
	return self;
}

- (id)initWithFrame:(NSRect)frame {
	// NSLog(@"Init");
    self = [super initWithFrame:frame];
    if (self) {
		//NSLog(@"%d", frame.size.width);
        // Initialization code here.
		[self setFrame:frame];
		[self setWantsLayer: YES];
    }
    return self;
}

- (void)dealloc {
	[mainLayer release];
	[boxLayer release];
	[popUpLayer release];
	[super dealloc];
}

- (void)setupLayer
{
	NSRect contentFrame = [mainView frame];
	[self setFrame: contentFrame];
	// NSLog(@"current effectView layer = %x", [self layer]);
	
    /*CALayer *root = [CALayer layer];
	// NSLog(@"root's superLayer = %x", [root superlayer]);
	[root removeFromSuperlayer];
	[self setLayer:root];*/
	
	// NSLog(@"root's superLayer = %x", [root superlayer]);
	// NSLog(@"current effectView layer = %x", [self layer]);
    // mainLayer is the layer that gets scaled. All of its sublayers
    // are automatically scaled with it.
    mainLayer = [CALayer layer];
    mainLayer.frame = NSRectToCGRect(contentFrame);
    [self setLayer:mainLayer];
    // Make the background color to be a dark gray with a 50% alpha similar to
    // the real Dashbaord.
    mainLayer.backgroundColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 0.0);
    //[root insertSublayer:[mainLayer retain] above:[mainView layer]];
	
	// NSLog(@"root = %x", root);
}

- (void)drawRect:(NSRect)rect {
	// Drawing code here.
}

- (void)awakeFromNib {
	// NSLog(@"awake");
	[self setupLayer];
}

- (void) setBox {
	// NSLog(@"setBox");
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

#pragma mark Pop-Up Message

// Just similiar to the code of "addNewLayer"...
// by gtCarrera @ 9#
- (void)drawPopUpMessage:(NSString*) message {
	//Initiallize a new CALayer
	if(!popUpLayer){
		popUpLayer = [CALayer layer];

		// Set the colors of the pop-up layer
		popUpLayer.backgroundColor = CGColorCreateGenericRGB(0.1, 0.1, 0.1, 0.5f);
		popUpLayer.borderColor = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 0.75f);
		popUpLayer.borderWidth = 2.0;
    }	
    // Create a text layer to add so we can see the message.
    CATextLayer *textLayer = [CATextLayer layer];
	// Set its foreground color
    textLayer.foregroundColor = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1.0f);
	
	// Set the message to the text layer
	textLayer.string = message;
	// Modify its styles
	textLayer.truncationMode = kCATruncationEnd;
    CGFontRef font = CGFontCreateWithFontName((CFStringRef)DEFAULT_POPUP_BOX_FONT);
    textLayer.font = font;
	// Here, calculate the size of the text layer
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
								[NSFont fontWithName:DEFAULT_POPUP_BOX_FONT 
												size:textLayer.fontSize], 
								NSFontAttributeName, 
								nil];
	NSSize messageSize = [message sizeWithAttributes:attributes];
	
	// Change the size of text layer automatically
	NSRect textRect = NSZeroRect;
	textRect.size.width = messageSize.width;
	textRect.size.height = messageSize.height;
    CGFontRelease(font);
	
    // Create a new rectangle with a suitable size for the inner texts.
	// Set it to an appropriate position of the whole view
    NSRect rect = textRect;
	NSRect screenRect = [self frame];
	rect.origin.x = screenRect.size.width / 2 - textRect.size.width / 2;
	rect.origin.y = screenRect.size.height / 5;
	rect.size.height += 10;
	rect.size.width += 50;
	
	// Move the origin point of the message layer, so the message can be 
	// displayed in the center of the background layer
	textRect.origin.x += (rect.size.width - textRect.size.width) / 2.0;
	textLayer.frame = NSRectToCGRect(textRect);
	
    // Set the layer frame to our rectangle.
    popUpLayer.frame = NSRectToCGRect(rect);
	popUpLayer.cornerRadius = rect.size.height/5;
	[popUpLayer addSublayer:[textLayer retain]];
    
    // Insert the layer into the root layer
	[mainLayer addSublayer:[popUpLayer retain]];
	// NSLog(@"Pop message @ (%f, %f)", rect.origin.x, rect.origin.y);
}

- (void)removePopUpMessage {
	if(popUpLayer) {
		[popUpLayer removeFromSuperlayer];
		[popUpLayer autorelease];
		popUpLayer = nil;
	}
}

-(void) resize {
	[self setFrameSize:[mainView frame].size];
	[self setFrameOrigin: NSMakePoint(0, 0)];
}
@end
