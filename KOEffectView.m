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
	[self removePopUpMessage];
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
    
	// Set up the box
	ipAddrLayer.backgroundColor = CGColorCreateGenericRGB(0.0, 0.95, 0.95, 0.1f);
	ipAddrLayer.borderColor = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1.0f);
	ipAddrLayer.borderWidth = 1.4;
	ipAddrLayer.cornerRadius = 6.0;
	
    // Insert the layer into the root layer
	[mainLayer addSublayer: [ipAddrLayer retain]];
}

- (void) drawIPAddrBox: (NSRect) rect {
	if (!ipAddrLayer)
		[self setIPAddrBox];
	
	rect.origin.x -= 1.0;
	rect.origin.y -= 0.0;
	rect.size.width += 2.0;
	rect.size.height += 0.0;
	
    // Set the layer frame to the rect
    ipAddrLayer.frame = NSRectToCGRect(rect);
    
    // Set the opacity to make the layer appear
	ipAddrLayer.opacity = 1.0f;
}

- (void) clearIPAddrBox {
	ipAddrLayer.opacity = 0.0f;
}

#pragma mark Click Entry
- (void) setClickEntry {
	clickEntryLayer = [CALayer layer];
    
	clickEntryLayer.backgroundColor = CGColorCreateGenericRGB(0.0, 0.95, 0.95, 0.17f);
	clickEntryLayer.borderColor = CGColorCreateGenericRGB(0.8f, 0.8f, 0.8f, 0.8f);
	clickEntryLayer.borderWidth = 0;
	clickEntryLayer.cornerRadius = 6.0;
	
    // Insert the layer into the root layer
	[mainLayer addSublayer: [clickEntryLayer retain]];
}

- (void) drawClickEntry: (NSRect) rect {
	if (!clickEntryLayer)
		[self setClickEntry];
	
	rect.origin.x -= 1.0;
	rect.origin.y -= 0.0;
	rect.size.width += 2.0;
	rect.size.height += 0.0;
	
    // Set the layer frame to the rect
    clickEntryLayer.frame = NSRectToCGRect(rect);
    
    // Set the opacity to make the layer appear
	clickEntryLayer.opacity = 1.0f;
}

- (void)clearClickEntry {
	clickEntryLayer.opacity = 0.0f;
}

#pragma mark Welly Buttons

- (void)drawButton: (NSRect) rect withMessage: (NSString *) message {
	//Initiallize a new CALayer
	if(buttonLayer)
		[buttonLayer release];
	
	buttonLayer = [CALayer layer];
	// Set the colors of the pop-up layer
	CGColorRef myColor = CGColorCreateGenericRGB(1, 1, 0.0, 1.0f);
	buttonLayer.backgroundColor = myColor;
	CGColorRelease(myColor);
	myColor = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 0.75f);
	buttonLayer.borderColor = myColor;
	CGColorRelease(myColor);
	buttonLayer.borderWidth = 0.0;
	buttonLayer.cornerRadius = 10.0;
	
    // Create a text layer to add so we can see the message.
    CATextLayer *textLayer = [CATextLayer layer];
	[textLayer autorelease];
	// Set its foreground color
	myColor = CGColorCreateGenericRGB(0, 0, 0, 1.0f);
    textLayer.foregroundColor = myColor;
	CGColorRelease(myColor);
	
	// Set the message to the text layer
	textLayer.string = [message retain];
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
    [buttonTrans autorelease];
    // Insert the layer into the root layer
	[mainLayer addSublayer:[buttonLayer retain]];
}

- (void)clearButton {
	CATextLayer *textLayer = [[buttonLayer sublayers] lastObject];
	[textLayer.string release];
	[textLayer removeFromSuperlayer];
	[buttonLayer removeAllAnimations];
	[buttonLayer removeFromSuperlayer];
}

#pragma mark -
#pragma mark Menu

const CGFloat menuWidth = 300.0;
const CGFloat menuHeight = 50.0;
const CGFloat menuFontSize = 24.0;
const CGFloat menuItemPadding = 5.0;
const CGFloat menuMarginHeight = 5.0;
const CGFloat menuMarginWidth = 20.0;

-(void)setupMenuLayer;
{
    //[[self window] makeFirstResponder:self];
    
	// create menu layer
    menuLayer = [CALayer layer];
    menuLayer.frame = mainLayer.bounds;
    menuLayer.layoutManager =[CAConstraintLayoutManager layoutManager];
	
	// set border style
	menuLayer.borderWidth = 2.0;
    menuLayer.borderColor = CGColorCreateGenericRGB(1.0f, 1.0f, 1.0f, 1.0f);
	menuLayer.cornerRadius = 5.0;
	
    [mainLayer addSublayer: menuLayer];
    
	// set selection layer
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
	
    //[mainLayer addSublayer:selectionLayer];
    
    //[self changeSelectedIndex:0];
}

- (void)changeSelectedIndex: (int) index {
	// TODO: add code for selecting menu item
	NSArray *layers = [menuLayer sublayers];
	if (selectedItemIndex >= 0 && selectedItemIndex < [layers count]) {
		CALayer *menuItemLayer = [layers objectAtIndex: selectedItemIndex];
		[menuItemLayer setFilters: nil];
		[menuItemLayer removeAllAnimations];
	}
	
	selectedItemIndex = index;
	if (selectedItemIndex >= 0 && selectedItemIndex < [layers count]) {
		CALayer *menuItemLayer = [layers objectAtIndex: selectedItemIndex];
		
		// Add bloom
		CIFilter *filter = [CIFilter filterWithName:@"CIBloom"];
		[filter setDefaults];
		[filter setValue:[NSNumber numberWithFloat:5.0] forKey:@"inputRadius"];
		[filter setName:@"pulseFilter"];
		
		[menuItemLayer setFilters: [NSArray arrayWithObject:filter]];
		
		// Add pulse animation
		CABasicAnimation* pulseAnimation = [CABasicAnimation animation];
		pulseAnimation.keyPath = @"filters.pulseFilter.inputIntensity";
		pulseAnimation.fromValue = [NSNumber numberWithFloat: 0.0];
		pulseAnimation.toValue = [NSNumber numberWithFloat: 1.5];
		pulseAnimation.duration = 1.0;
		pulseAnimation.repeatCount = 1e100f;
		pulseAnimation.autoreverses = YES;
		pulseAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
		
		[menuItemLayer addAnimation:pulseAnimation forKey:@"pulseAnimation"];
	}
}

- (void)removeAllMenuItems {
	NSArray *layers = [menuLayer sublayers];
	for (int i = 0; i < [layers count]; ++i) {
		CALayer *menuItemLayer = [layers objectAtIndex: i];
		[menuItemLayer removeFromSuperlayer];
	}
	
	selectedItemIndex = -1;
	[menuLayer layoutIfNeeded];
}

- (void)showMenuAtPoint: (NSPoint) pt 
			  withItems: (NSArray *)items {
	if (!menuLayer)
		[self setupMenuLayer];
	
	[self removeAllMenuItems];
	
	CGFloat width = 0.0;
	CGFloat height = menuMarginHeight;
	CGFloat itemHeight = 0.0;
	// Add menu items
    for (int i = 0; i < [items count]; i++) {
		KOMenuItem *item = (KOMenuItem *)[items objectAtIndex: i];
		NSString *name = [item name];
		
		CATextLayer *menuItemLayer = [CATextLayer layer];
		menuItemLayer.string = name;
		
		// Modify its styles
		CGFontRef font = CGFontCreateWithFontName((CFStringRef)DEFAULT_POPUP_MENU_FONT);
		menuItemLayer.font = font;
		CGFontRelease(font);
		menuItemLayer.fontSize = menuFontSize;
		menuItemLayer.foregroundColor = CGColorCreateGenericRGB(1.0f, 1.0f, 1.0f, 1.0f);
		menuItemLayer.truncationMode = kCATruncationEnd;
		
		// Here, calculate the size of the text layer
		NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSFont fontWithName:DEFAULT_POPUP_MENU_FONT 
													size:menuItemLayer.fontSize], 
									NSFontAttributeName,
									nil];
		NSSize messageSize = [name sizeWithAttributes:attributes];
		
		// Modify the layer's size
		if (messageSize.width > width)
			width = messageSize.width;
		height += messageSize.height + ((i == 0) ? 0 : menuItemPadding);
		itemHeight = messageSize.height;
		
		// Set the layer's constraint
		[menuItemLayer addConstraint: [CAConstraint constraintWithAttribute: kCAConstraintMaxY
																 relativeTo: @"superlayer"
																  attribute: kCAConstraintMaxY
																	 offset: -height + itemHeight]];
		[menuItemLayer addConstraint: [CAConstraint constraintWithAttribute: kCAConstraintMidX
																 relativeTo: @"superlayer"
																  attribute: kCAConstraintMidX]];
		
		// insert this menu item
		[menuLayer addSublayer: menuItemLayer];
    }
	CGRect rect = CGRectZero;
	rect.size.width = width + menuMarginWidth * 2;
	rect.size.height = height + menuMarginHeight;
	rect.origin = NSPointToCGPoint(pt);
	rect.origin.y -= rect.size.height;
	
	[menuLayer setFrame: rect];
	menuLayer.cornerRadius = rect.size.height / 5;
	
    [menuLayer layoutIfNeeded];
	
	[self changeSelectedIndex: 0];
}

- (void)hideMenu {
	// TODO: add code to hide the menu
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
	[textLayer autorelease];
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
		[popUpLayer release];
		popUpLayer = nil;
	}
}
@end
