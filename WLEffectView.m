//
//  WLEffectView.m
//  Welly
//
//  Created by K.O.ed on 08-8-15.
//  Copyright 2008 Welly Group. All rights reserved.
//

#import "WLEffectView.h"
#import "YLLGlobalConfig.h"
#import "WLMenuItem.h"

#import <Quartz/Quartz.h>
#import <ScreenSaver/ScreenSaver.h>
#import <CoreText/CTFont.h>


@implementation WLEffectView
- (id)initWithView:(YLView *)view {
	self = [self initWithFrame:[view frame]];
	if (self) {
		_mainView = [view retain];
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
	[_mainLayer release];
	[_ipAddrLayer release];
	[_popUpLayer release];
	[super dealloc];
}

- (void)setupLayer
{
	NSRect contentFrame = [_mainView frame];
	[self setFrame: contentFrame];
	
    // mainLayer is the layer that gets scaled. All of its sublayers
    // are automatically scaled with it.
    _mainLayer = [CALayer layer];
    [_mainLayer setFrame:NSRectToCGRect(contentFrame)];
    [self setLayer:_mainLayer];
    // Make the background color to be a dark gray with a 50% alpha similar to
    // the real Dashbaord.
    [_mainLayer setBackgroundColor:CGColorCreateGenericRGB(0.0, 0.0, 0.0, 0.0)];
}

- (void)clear {
	[self clearIPAddrBox];
	[self clearClickEntry];
	[self clearButton];
}

- (void)drawRect:(NSRect)rect {
	// Drawing code here.
}

- (void)resize {
	[self setFrameSize:[_mainView frame].size];
	[self setFrameOrigin:NSMakePoint(0, 0)];
}

- (void)awakeFromNib {
	[self setupLayer];
}

- (void)setIPAddrBox {
	_ipAddrLayer = [CALayer layer];
    
	// Set up the box
	[_ipAddrLayer setBackgroundColor:CGColorCreateGenericRGB(0.0, 0.95, 0.95, 0.1f)];
	[_ipAddrLayer setBorderColor:CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1.0f)];
	[_ipAddrLayer setBorderWidth:1.4];
	[_ipAddrLayer setCornerRadius:6.0];
	
    // Insert the layer into the root layer
	[_mainLayer addSublayer:[_ipAddrLayer retain]];
}

- (void)drawIPAddrBox:(NSRect)rect {
	if (!_ipAddrLayer)
		[self setIPAddrBox];
	
	rect.origin.x -= 1.0;
	rect.origin.y -= 0.0;
	rect.size.width += 2.0;
	rect.size.height += 0.0;
	
    // Set the layer frame to the rect
    _ipAddrLayer.frame = NSRectToCGRect(rect);
    
    // Set the opacity to make the layer appear
	[_ipAddrLayer setOpacity:1.0f];
}

- (void)clearIPAddrBox {
	[_ipAddrLayer setOpacity:0.0f];
}

#pragma mark Click Entry
- (void)setClickEntry {
	_clickEntryLayer = [CALayer layer];
    
	[_clickEntryLayer setBackgroundColor:CGColorCreateGenericRGB(0.0, 0.95, 0.95, 0.17f)];
	[_clickEntryLayer setBorderWidth:0];
	[_clickEntryLayer setCornerRadius:6.0];
	
    // Insert the layer into the root layer
	[_mainLayer addSublayer:[_clickEntryLayer retain]];
}

- (void)drawClickEntry:(NSRect)rect {
	if (!_clickEntryLayer)
		[self setClickEntry];
	
	rect.origin.x -= 1.0;
	rect.origin.y -= 0.0;
	rect.size.width += 2.0;
	rect.size.height += 0.0;
	
    // Set the layer frame to the rect
    [_clickEntryLayer setFrame:NSRectToCGRect(rect)];
    
    // Set the opacity to make the layer appear
	[_clickEntryLayer setOpacity:1.0f];
}

- (void)clearClickEntry {
	[_clickEntryLayer setOpacity:0.0f];
}

#pragma mark Welly Buttons
- (void)drawButton:(NSRect)rect 
	   withMessage:(NSString *)message {
	//Initiallize a new CALayer
	[self clearButton];
	if (_buttonLayer)
		[_buttonLayer release];
	_buttonLayer = [CALayer layer];
	// Set the colors of the pop-up layer
	CGColorRef myColor = CGColorCreateGenericRGB(0.05, 0.05, 0.05, 0.9f);
	_buttonLayer.backgroundColor = myColor;
	CGColorRelease(myColor);
	myColor = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 0.9f);
	_buttonLayer.borderColor = myColor;
	CGColorRelease(myColor);
	_buttonLayer.borderWidth = 2.0;
	_buttonLayer.cornerRadius = 10.0;
	
    // Create a text layer to add so we can see the message.
    CATextLayer *textLayer = [CATextLayer layer];
	[textLayer autorelease];
	// Set its foreground color
	myColor = CGColorCreateGenericRGB(1, 1, 1, 1.0f);
    [textLayer setForegroundColor:myColor];
	CGColorRelease(myColor);
	
	// Set the message to the text layer
	[textLayer setString:[message retain]];
	// Modify its styles
	[textLayer setTruncationMode:kCATruncationEnd];
    CGFontRef font = CGFontCreateWithFontName((CFStringRef)[[YLLGlobalConfig sharedInstance] englishFontName]);
    [textLayer setFont:font];
	[textLayer setFontSize:[[YLLGlobalConfig sharedInstance] englishFontSize] - 2];
	// Here, calculate the size of the text layer
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
								[NSFont fontWithName:[[YLLGlobalConfig sharedInstance] englishFontName] 
												size:[textLayer fontSize]], 
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
	
	/* Comment out by K.O.ed: 2009.02.03
	NSRect finalRect = textRect;
	finalRect.origin.x = rect.origin.x;// - textRect.size.width / 2;
	finalRect.origin.y = rect.origin.y;// - textRect.size.height;
	finalRect.size.width += 8;
	finalRect.size.height += 4;
	*/
	NSRect finalRect = rect;
	if (finalRect.size.width < textRect.size.width + 8)
		finalRect.size.width = textRect.size.width + 8;
	finalRect.size.height = textRect.size.height + 4;
	
	// Move the origin point of the message layer, so the message can be 
	// displayed in the center of the background rect
	textRect.origin.x += (finalRect.size.width - textRect.size.width) / 2.0;
	textRect.origin.y += (finalRect.size.height - textRect.size.height) / 2.0;
	[textLayer setFrame:NSRectToCGRect(textRect)];
	
    // Set the layer frame to our rectangle.
    _buttonLayer.frame = NSRectToCGRect(finalRect);
	//buttonLayer.cornerRadius = finalRect.size.height/5;
	[_buttonLayer addSublayer:[textLayer retain]];

	[textLayer setFilters:[NSArray array]];
	
	CATransition * buttonTrans = [CATransition new];
	[buttonTrans setType:kCATransitionReveal];
	[_buttonLayer addAnimation:buttonTrans forKey:kCATransition];
    [buttonTrans autorelease];
    // Insert the layer into the root layer
	[_mainLayer addSublayer:[_buttonLayer retain]];
}

- (void)clearButton {
	if (_buttonLayer == nil)
		return;
	CATextLayer *textLayer = [[_buttonLayer sublayers] lastObject];
	[[textLayer string] release];
	[textLayer removeFromSuperlayer];
	[_buttonLayer removeAllAnimations];
	[_buttonLayer removeFromSuperlayer];
}

#pragma mark -
#pragma mark Menu

const CGFloat menuWidth = 300.0;
const CGFloat menuHeight = 50.0;
const CGFloat menuFontSize = 24.0;
const CGFloat menuItemPadding = 5.0;
const CGFloat menuMarginHeight = 5.0;
const CGFloat menuMarginWidth = 20.0;

-(void)setupMenuLayer {
    //[[self window] makeFirstResponder:self];
    
	// create menu layer
    _menuLayer = [CALayer layer];
    _menuLayer.frame = _mainLayer.bounds;
    _menuLayer.layoutManager =[CAConstraintLayoutManager layoutManager];
	
	// set border style
	_menuLayer.borderWidth = 2.0;
    _menuLayer.borderColor = CGColorCreateGenericRGB(1.0f, 1.0f, 1.0f, 1.0f);
	_menuLayer.cornerRadius = 5.0;
	
    [_mainLayer addSublayer: _menuLayer];
    
	// set selection layer
    _selectionLayer = [CALayer layer];
    [_selectionLayer setBounds:CGRectMake(0.0, 0.0, menuWidth, menuHeight)];
    [_selectionLayer setBorderWidth:2.0];
    [_selectionLayer setBorderColor:CGColorCreateGenericRGB(1.0f, 1.0f, 1.0f, 1.0f)];
    [_selectionLayer setCornerRadius:menuHeight / 2];
    
    CIFilter *filter = [CIFilter filterWithName:@"CIBloom"];
    [filter setDefaults];
    [filter setValue:[NSNumber numberWithFloat:5.0] forKey:@"inputRadius"];
    [filter setName:@"pulseFilter"];
    
    [_selectionLayer setFilters:[NSArray arrayWithObject:filter]];
    
    CABasicAnimation* pulseAnimation = [CABasicAnimation animation];
    pulseAnimation.keyPath = @"filters.pulseFilter.inputIntensity";
    pulseAnimation.fromValue = [NSNumber numberWithFloat: 0.0];
    pulseAnimation.toValue = [NSNumber numberWithFloat: 1.5];
    pulseAnimation.duration = 1.0;
    pulseAnimation.repeatCount = 1e100f;
    pulseAnimation.autoreverses = YES;
    pulseAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	
    [_selectionLayer addAnimation:pulseAnimation forKey:@"pulseAnimation"];
	
    //[mainLayer addSublayer:selectionLayer];
    
    //[self changeSelectedIndex:0];
}

- (void)selectMenuItemAtIndex:(int)index {
	// TODO: add code for selecting menu item
	NSArray *layers = [_menuLayer sublayers];
	if (selectedItemIndex >= 0 && selectedItemIndex < [layers count]) {
		CALayer *menuItemLayer = [layers objectAtIndex:selectedItemIndex];
		[menuItemLayer setFilters: nil];
		[menuItemLayer removeAllAnimations];
	}
	
	selectedItemIndex = index;
	if (selectedItemIndex >= 0 && selectedItemIndex < [layers count]) {
		CALayer *menuItemLayer = [layers objectAtIndex:selectedItemIndex];
		
		// Add bloom
		CIFilter *filter = [CIFilter filterWithName:@"CIBloom"];
		[filter setDefaults];
		[filter setValue:[NSNumber numberWithFloat:5.0] forKey:@"inputRadius"];
		[filter setName:@"pulseFilter"];
		
		[menuItemLayer setFilters: [NSArray arrayWithObject:filter]];
		
		// Add pulse animation
		CABasicAnimation* pulseAnimation = [CABasicAnimation animation];
		pulseAnimation.keyPath = @"filters.pulseFilter.inputIntensity";
		pulseAnimation.fromValue = [NSNumber numberWithFloat:0.0];
		pulseAnimation.toValue = [NSNumber numberWithFloat:1.5];
		pulseAnimation.duration = 1.0;
		pulseAnimation.repeatCount = 1e100f;
		pulseAnimation.autoreverses = YES;
		pulseAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
		
		[menuItemLayer addAnimation:pulseAnimation forKey:@"pulseAnimation"];
	}
}

- (void)selectPreviousMenuItem {
	int previousItemIndex = selectedItemIndex - 1;
	if (previousItemIndex < 0)
		previousItemIndex += [[_menuLayer sublayers] count];
	[self selectMenuItemAtIndex:previousItemIndex];
}

- (void)selectNextMenuItem {
	int nextItemIndex = selectedItemIndex + 1;
	if (nextItemIndex >= [[_menuLayer sublayers] count])
		nextItemIndex -= [[_menuLayer sublayers] count];
	[self selectMenuItemAtIndex:nextItemIndex];
}

- (void)removeAllMenuItems {
	while ([[_menuLayer sublayers] count] > 0) {
		CATextLayer *menuItemLayer = [[_menuLayer sublayers] lastObject];
		[menuItemLayer.string release];
		[menuItemLayer removeFromSuperlayer];
	}
	
	selectedItemIndex = -1;
	[_menuLayer layoutIfNeeded];
}

- (void)showMenuAtPoint:(NSPoint)pt 
			  withItems:(NSArray *)items {
	if (!_menuLayer)
		[self setupMenuLayer];
	
	[self removeAllMenuItems];
	
	CGFloat width = 0.0;
	CGFloat height = menuMarginHeight;
	CGFloat itemHeight = 0.0;
	// Add menu items
    for (int i = 0; i < [items count]; i++) {
		WLMenuItem *item = (WLMenuItem *)[items objectAtIndex:i];
		NSString *name = [item name];
		
		CATextLayer *menuItemLayer = [CATextLayer layer];
		[menuItemLayer autorelease];
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
		[menuItemLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY
																relativeTo:@"superlayer"
																 attribute:kCAConstraintMaxY
																	offset:-height + itemHeight]];
		[menuItemLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX
																relativeTo:@"superlayer"
																 attribute:kCAConstraintMidX]];
		
		// insert this menu item
		[_menuLayer addSublayer: [menuItemLayer retain]];
    }
	CGFloat totalHeight = height + menuMarginHeight;
	CGFloat totalWidth = width + menuMarginWidth * 2;
	_menuLayer.cornerRadius = totalHeight / 5;
	
	CGRect rect = CGRectZero;
	rect.size.width = totalWidth;
	rect.size.height = totalHeight;
	rect.origin = NSPointToCGPoint(pt);
	rect.origin.y -= totalHeight;
	
	_menuLayer.frame = rect;
	_menuLayer.opacity = 1.0f;
	
    [_menuLayer layoutIfNeeded];

	[self selectMenuItemAtIndex:0];
}

- (void)hideMenu {
	[_menuLayer setOpacity:0];
}

#pragma mark -
#pragma mark URL drawing
- (void)setURLLineLayer {
	
}

- (void)drawURLUnderlineAtRow:(int)r
				   fromColumn:(int)start 
					 toColumn:(int)end {
	
}

- (CGImageRef)indicatorImage { 
	if (_urlIndicatorImage == NULL) { 
		NSString *path = [[NSBundle mainBundle] pathForResource:@"indicator" 
														 ofType:@"png"]; 
		NSURL *imageURL = [NSURL fileURLWithPath:path]; 
		CGImageSourceRef src = CGImageSourceCreateWithURL((CFURLRef)imageURL, NULL); 
		if (NULL != src) { 
			_urlIndicatorImage = CGImageSourceCreateImageAtIndex(src, 0, NULL); 
			CFRelease(src);
		} 
	} 
	return _urlIndicatorImage; 
} 

- (void)setURLIndicatorLayer {
	_urlIndicatorLayer = [CALayer layer];
	[_urlIndicatorLayer setContents:(id)[self indicatorImage]];
	[_urlIndicatorLayer setFrame:CGRectMake(0, 0, 79, 90)];
	[_mainLayer addSublayer:_urlIndicatorLayer];
}

- (void)showIndicatorAtPoint:(NSPoint)point {
	if (!_urlIndicatorLayer)
		[self setURLIndicatorLayer];
	[_urlIndicatorLayer setOpacity:0.9];
	CGRect rect = [_urlIndicatorLayer frame];
	rect.origin = NSPointToCGPoint(point);
	[_urlIndicatorLayer setFrame:rect];
}

- (void)removeIndicator {
	if(_urlIndicatorLayer)
		[_urlIndicatorLayer setOpacity:0.0f];
}

#pragma mark Pop-Up Message

// Just similiar to the code of "addNewLayer"...
// by gtCarrera @ 9#
- (void)drawPopUpMessage:(NSString*)message {
	// Remove previous message
	[self removePopUpMessage];
	//Initiallize a new CALayer
	if(!_popUpLayer){
		_popUpLayer = [CALayer layer];

		// Set the colors of the pop-up layer
		[_popUpLayer setBackgroundColor:CGColorCreateGenericRGB(0.1, 0.1, 0.1, 0.5f)];
		[_popUpLayer setBorderColor:CGColorCreateGenericRGB(1.0, 1.0, 1.0, 0.75f)];
		[_popUpLayer setBorderWidth:2.0];
    }	
    // Create a text layer to add so we can see the message.
    CATextLayer *textLayer = [CATextLayer layer];
	[textLayer autorelease];
	// Set its foreground color
    [textLayer setForegroundColor:CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1.0f)];
	
	// Set the message to the text layer
	[textLayer setString:message];
	// Modify its styles
	[textLayer setTruncationMode:kCATruncationEnd];
    CGFontRef font = CGFontCreateWithFontName((CFStringRef)DEFAULT_POPUP_BOX_FONT);
    [textLayer setFont:font];
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
	rect.size.height += 10;
	rect.size.width += 50;
	rect.origin.x = screenRect.size.width / 2 - rect.size.width / 2;
	rect.origin.y = screenRect.size.height / 5;
	
	// Move the origin point of the message layer, so the message can be 
	// displayed in the center of the background layer
	textRect.origin.x += (rect.size.width - textRect.size.width) / 2.0;
	[textLayer setFrame:NSRectToCGRect(textRect)];
	
    // Set the layer frame to our rectangle.
    [_popUpLayer setFrame:NSRectToCGRect(rect)];
	[_popUpLayer setCornerRadius:rect.size.height/5];
	[_popUpLayer addSublayer:[textLayer retain]];
    
    // Insert the layer into the root layer
	[_mainLayer addSublayer:[_popUpLayer retain]];
	// NSLog(@"Pop message @ (%f, %f)", rect.origin.x, rect.origin.y);
}

- (void)removePopUpMessage {
	if(_popUpLayer) {
		[_popUpLayer removeFromSuperlayer];
		[_popUpLayer release];
		_popUpLayer = nil;
	}
}
@end
