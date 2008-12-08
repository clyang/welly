//
//  KOEffectView.m
//  Welly
//
//  Created by K.O.ed on 08-8-15.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "KOEffectView.h"
#import "YLLGlobalConfig.h"
#import "KOMenuItem.h"

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
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		[self setFrame:frame];
		[self setWantsLayer: YES];
    }
    return self;
}

- (void)dealloc {
	[mainLayer release];
	[ipAddrLayer release];
	[popUpLayer release];
	[super dealloc];
}

- (void)setupLayer
{
	NSRect contentFrame = [mainView frame];
	[self setFrame: contentFrame];
	
    // mainLayer is the layer that gets scaled. All of its sublayers
    // are automatically scaled with it.
    mainLayer = [CALayer layer];
    mainLayer.frame = NSRectToCGRect(contentFrame);
    [self setLayer:mainLayer];
    // Make the background color to be a dark gray with a 50% alpha similar to
    // the real Dashbaord.
    mainLayer.backgroundColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 0.0);
}

- (void) clear {
	[self clearIPAddrBox];
	[self clearClickEntry];
	[self clearButton];
	[popUpLayer removeFromSuperlayer];
}

- (void)drawRect:(NSRect)rect {
	// Drawing code here.
}

-(void) resize {
	[self setFrameSize:[mainView frame].size];
	[self setFrameOrigin: NSMakePoint(0, 0)];
}

- (void)awakeFromNib {
	[self setupLayer];
}

- (void) setIPAddrBox {
	ipAddrLayer = [CALayer layer];
    
	ipAddrLayer.backgroundColor = CGColorCreateGenericRGB(0.0, 0.95, 0.95, 0.1f);
	ipAddrLayer.borderColor = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1.0f);
	ipAddrLayer.borderWidth = 1.4;
	ipAddrLayer.cornerRadius = 6.0;
}

- (void) drawIPAddrBox: (NSRect) rect {
	if (!ipAddrLayer)
		[self setIPAddrBox];
	
	[ipAddrLayer removeFromSuperlayer];
	
	rect.origin.x -= 1.0;
	rect.origin.y -= 0.0;
	rect.size.width += 2.0;
	rect.size.height += 0.0;
	
    // Set the layer frame to the rect
    ipAddrLayer.frame = NSRectToCGRect(rect);
    
    // Insert the layer into the root layer
	[mainLayer addSublayer: [ipAddrLayer retain]];
}

- (void) clearIPAddrBox {
	[ipAddrLayer removeFromSuperlayer];
}

#pragma mark Click Entry
- (void) setClickEntry {
	clickEntryLayer = [CALayer layer];
    
	clickEntryLayer.backgroundColor = CGColorCreateGenericRGB(0.0, 0.95, 0.95, 0.17f);
	clickEntryLayer.borderColor = CGColorCreateGenericRGB(0.8f, 0.8f, 0.8f, 0.8f);
	clickEntryLayer.borderWidth = 0;
	clickEntryLayer.cornerRadius = 6.0;
}

- (void) drawClickEntry: (NSRect) rect {
	if (!clickEntryLayer)
		[self setClickEntry];
	
	[clickEntryLayer removeFromSuperlayer];
	
	rect.origin.x -= 1.0;
	rect.origin.y -= 0.0;
	rect.size.width += 2.0;
	rect.size.height += 0.0;
	
    // Set the layer frame to the rect
    clickEntryLayer.frame = NSRectToCGRect(rect);
    
    // Insert the layer into the root layer
	[mainLayer addSublayer: [clickEntryLayer retain]];
}

- (void)clearClickEntry {
	[clickEntryLayer removeFromSuperlayer];
}

#pragma mark Welly Buttons

- (void)drawButton: (NSRect) rect withMessage: (NSString *) message {
	//Initiallize a new CALayer
	if(buttonLayer)
		[buttonLayer release];
	
	buttonLayer = [CALayer layer];
	// Set the colors of the pop-up layer
	buttonLayer.backgroundColor = CGColorCreateGenericRGB(1, 1, 0.0, 1.0f);
	buttonLayer.borderColor = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 0.75f);
	buttonLayer.borderWidth = 0.0;
	buttonLayer.cornerRadius = 10.0;

	
    // Create a text layer to add so we can see the message.
    CATextLayer *textLayer = [CATextLayer layer];
	// Set its foreground color
    textLayer.foregroundColor = CGColorCreateGenericRGB(0, 0, 0, 1.0f);
	
	// Set the message to the text layer
	textLayer.string = message;
	// Modify its styles
	textLayer.truncationMode = kCATruncationEnd;
    CGFontRef font = CGFontCreateWithFontName((CFStringRef)[[YLLGlobalConfig sharedInstance] englishFontName]);
    textLayer.font = font;
	textLayer.fontSize = [[YLLGlobalConfig sharedInstance] englishFontSize] - 2;
	// Here, calculate the size of the text layer
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
								[NSFont fontWithName:[[YLLGlobalConfig sharedInstance] englishFontName] 
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
    NSRect finalRect = textRect;
	finalRect.origin.x = rect.origin.x;// - textRect.size.width / 2;
	finalRect.origin.y = rect.origin.y;// - textRect.size.height;
	finalRect.size.width += 8;
	finalRect.size.height += 4;
	
	// Move the origin point of the message layer, so the message can be 
	// displayed in the center of the background rect
	textRect.origin.x += (finalRect.size.width - textRect.size.width) / 2.0;
	textRect.origin.y += (finalRect.size.height - textRect.size.height) / 2.0;
	textLayer.frame = NSRectToCGRect(textRect);
	
    // Set the layer frame to our rectangle.
    buttonLayer.frame = NSRectToCGRect(finalRect);
	//buttonLayer.cornerRadius = finalRect.size.height/5;
	[buttonLayer addSublayer:[textLayer retain]];
	
	CATransition * buttonTrans = [CATransition new];
	buttonTrans.type = kCATransitionReveal;
	[buttonLayer addAnimation: buttonTrans forKey: kCATransition];
    
    // Insert the layer into the root layer
	[mainLayer addSublayer:[buttonLayer retain]];
}

- (void)clearButton {
	CALayer *textLayer = [[buttonLayer sublayers] lastObject];
	[textLayer removeFromSuperlayer];
	[buttonLayer removeAllAnimations];
	[buttonLayer removeFromSuperlayer];
}

#pragma mark -
#pragma mark Menu

const CGFloat menuWidth = 300.0;
const CGFloat menuHeight = 50.0;
const CGFloat menuFontSize = 30.0;
const CGFloat menuSpacing = 20.0;
const CGFloat menuInitialOffset = 10.0;
const CGFloat menuItemPadding = 2.0;
const CGFloat menuMarginOffset = 10.0;

-(void)setupMenuLayer;
{
    [[self window] makeFirstResponder:self];
    
    menuLayer = [CALayer layer];
    menuLayer.frame = mainLayer.bounds;
    menuLayer.layoutManager =[CAConstraintLayoutManager layoutManager];
	
	menuLayer.borderWidth = 2.0;
    menuLayer.borderColor = CGColorCreateGenericRGB(1.0f, 1.0f, 1.0f, 1.0f);
	menuLayer.cornerRadius = 2.0;
	
    [mainLayer addSublayer: menuLayer];
    
    selectionLayer = [CALayer layer];
    selectionLayer.bounds = CGRectMake(0.0, 0.0, menuWidth, menuHeight);
    selectionLayer.borderWidth = 2.0;
    selectionLayer.borderColor = CGColorCreateGenericRGB(1.0f, 1.0f, 1.0f, 1.0f);
    selectionLayer.cornerRadius = menuHeight / 2;
    
    CIFilter *filter = [CIFilter filterWithName:@"CIBloom"];
    [filter setDefaults];
    [filter setValue:[NSNumber numberWithFloat:5.0] forKey:@"inputRadius"];
    [filter setName:@"pulseFilter"];
    
    [selectionLayer setFilters:[NSArray arrayWithObject:filter]];
    
    CABasicAnimation* pulseAnimation = [CABasicAnimation animation];
    pulseAnimation.keyPath = @"filters.pulseFilter.inputIntensity";
    pulseAnimation.fromValue = [NSNumber numberWithFloat: 0.0];
    pulseAnimation.toValue = [NSNumber numberWithFloat: 1.5];
    pulseAnimation.duration = 1.0;
    pulseAnimation.repeatCount = 1e100f;
    pulseAnimation.autoreverses = YES;
    pulseAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	
    [selectionLayer addAnimation:pulseAnimation forKey:@"pulseAnimation"];
	
    [mainLayer addSublayer:selectionLayer];
    
    //[self changeSelectedIndex:0];
}

- (void)showMenuAtPoint: (NSPoint) pt 
			  withItems: (NSArray *)items {
	if (!menuLayer)
		[self setupMenuLayer];
	
	//[menuLayer setPosition: NSPointToCGPoint(pt)];
	CGFloat width = 0.0;
	CGFloat height = menuMarginOffset * 2;
	CGFloat itemHeight = 0.0;
	
    for (int i = 0; i < [items count]; i++) {
		KOMenuItem *item = (KOMenuItem *)[items objectAtIndex: i];
		NSString *name = [item name];
		name = @"fucking fucking";
		
		CATextLayer *menuItemLayer = [CATextLayer layer];
		
		CGFontRef font = CGFontCreateWithFontName((CFStringRef)DEFAULT_POPUP_MENU_FONT);
		menuItemLayer.font = font;
		menuItemLayer.fontSize = menuFontSize;
		NSLog(@"%f, %d", menuItemLayer.fontSize, menuFontSize);
		[menuItemLayer setForegroundColor:CGColorCreateGenericRGB(1.0f, 1.0f, 1.0f, 1.0f)];
		//menuItemLayer.foregroundColor = CGColorCreateGenericRGB(1.0f, 1.0f, 1.0f, 1.0f);
		
		// Modify its styles
		menuItemLayer.truncationMode = kCATruncationEnd;		// Here, calculate the size of the text layer
		NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSFont fontWithName:DEFAULT_POPUP_MENU_FONT 
													size:menuItemLayer.fontSize], 
									NSFontAttributeName,
									nil];
		menuItemLayer.string = name;
		NSSize messageSize = [name sizeWithAttributes:attributes];
		
		if (messageSize.width > width)
			width = messageSize.width;
		
		if (height > 0)
			height += messageSize.height + menuItemPadding;
		else
			height += messageSize.height;
		
		itemHeight = messageSize.height;
		/*
		[menuItemLayer addConstraint: [CAConstraint constraintWithAttribute: kCAConstraintMaxY
																 relativeTo: @"superlayer"
																  attribute: kCAConstraintMaxY
																	 offset: -(i * menuHeight + menuSpacing + menuInitialOffset)]];
		[menuItemLayer addConstraint: [CAConstraint constraintWithAttribute: kCAConstraintMidX
																 relativeTo: @"superlayer"
																  attribute: kCAConstraintMidX]];
		 */
		//menuItemLayer.foregroundColor = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 0.5f);
		[menuLayer addSublayer: menuItemLayer];
    }
	
	CGRect rect = CGRectZero;
	rect.size.width = width + menuMarginOffset * 2;
	rect.size.height = height;
	rect.origin = NSPointToCGPoint(pt);
	
	[menuLayer setFrame: rect];
	
	int i = 0;
	for (CALayer *menuItemLayer in [menuLayer sublayers]) {
		
		[menuItemLayer addConstraint: [CAConstraint constraintWithAttribute: kCAConstraintMaxY
																 relativeTo: @"superlayer"
																  attribute: kCAConstraintMaxY
																	 offset: -(i++ * itemHeight + menuItemPadding + menuMarginOffset)]];
		[menuItemLayer addConstraint: [CAConstraint constraintWithAttribute: kCAConstraintMidX
																 relativeTo: @"superlayer"
																  attribute: kCAConstraintMidX]];
	}
    
    //[menuLayer layoutIfNeeded];
}

- (void)hideMenu {
	
}

#pragma mark Pop-Up Message

// Just similiar to the code of "addNewLayer"...
// by gtCarrera @ 9#
- (void)drawPopUpMessage:(NSString*) message {
	// Remove previous message
	[self removePopUpMessage];
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
@end
