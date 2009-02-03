//
//  KOMouseBehaviorManager.m
//  Welly
//
//  Created by K.O.ed on 09-1-31.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "KOMouseBehaviorManager.h"
#import "KOIPAddrHotspotHandler.h"
#import "KOMovingAreaHotspotHandler.h"
#import "KOClickEntryHotspotHandler.h"
#import "KOButtonAreaHotspotHandler.h"

#import "YLLGlobalConfig.h"
#import "encoding.h"
#import "YLView.h"
#import "YLTerminal.h"
#import "YLSite.h"
#import "IPSeeker.h"
#import "KOEffectView.h"

static YLLGlobalConfig *gConfig;
static int gRow;
static int gColumn;
static NSCursor *gMoveCursor;

NSString * const KOMouseHandlerUserInfoName = @"Handler";
NSString * const KOMouseRowUserInfoName = @"Row";
NSString * const KOMouseCommandSequenceUserInfoName = @"Command Sequence";
NSString * const KOMouseButtonTypeUserInfoName = @"Button Type";
NSString * const KOMouseButtonTextUserInfoName = @"Button Text";
NSString * const KOMouseCursorUserInfoName = @"Cursor";

@implementation KOMouseBehaviorManager
#pragma mark -
#pragma mark Initialization
- (id) initWithView: (YLView *)view {
	[self init];
	_view = view;
	_ipAddrHandler = [[KOIPAddrHotspotHandler alloc] initWithManager:self];
	_clickEntryHandler = [[KOClickEntryHotspotHandler alloc] initWithManager:self];
	_buttonAreaHandler = [[KOButtonAreaHotspotHandler alloc] initWithManager:self];
	_movingAreaHandler = [[KOMovingAreaHotspotHandler alloc] initWithManager:self];
	return self;
}

- (id) init {
	[super init];
	if (!gConfig)
		[KOMouseBehaviorManager initialize];
	return self;
}

- (void) dealloc {
	[_ipAddrHandler dealloc];
	[_clickEntryHandler dealloc];
	[_buttonAreaHandler dealloc];
	[_movingAreaHandler dealloc];
	[super dealloc];
}

+ (void) initialize {
    NSImage *cursorImage = [[NSImage alloc] initWithSize: NSMakeSize(11.0, 20.0)];
    [cursorImage lockFocus];
    [[NSColor clearColor] set];
    NSRectFill(NSMakeRect(0, 0, 11, 20));
    [[NSColor whiteColor] set];
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path setLineCapStyle: NSRoundLineCapStyle];
    [path moveToPoint: NSMakePoint(1.5, 1.5)];
    [path lineToPoint: NSMakePoint(2.5, 1.5)];
    [path lineToPoint: NSMakePoint(5.5, 4.5)];
    [path lineToPoint: NSMakePoint(8.5, 1.5)];
    [path lineToPoint: NSMakePoint(9.5, 1.5)];
    [path moveToPoint: NSMakePoint(5.5, 4.5)];
    [path lineToPoint: NSMakePoint(5.5, 15.5)];
    [path lineToPoint: NSMakePoint(2.5, 18.5)];
    [path lineToPoint: NSMakePoint(1.5, 18.5)];
    [path moveToPoint: NSMakePoint(5.5, 15.5)];
    [path lineToPoint: NSMakePoint(8.5, 18.5)];
    [path lineToPoint: NSMakePoint(9.5, 18.5)];
    [path moveToPoint: NSMakePoint(3.5, 9.5)];
    [path lineToPoint: NSMakePoint(7.5, 9.5)];
    [path setLineWidth: 3];
    [path stroke];
    [path setLineWidth: 1];
    [[NSColor blackColor] set];
    [path stroke];
    [cursorImage unlockFocus];
    gMoveCursor = [[NSCursor alloc] initWithImage: cursorImage hotSpot: NSMakePoint(5.5, 9.5)];
    [cursorImage release];
    if (!gConfig) gConfig = [YLLGlobalConfig sharedInstance];
	gColumn = [gConfig column];
	gRow = [gConfig row];
}

#pragma mark -
#pragma mark Event Handle
- (void) mouseEntered: (NSEvent *)theEvent {
	if ([theEvent trackingArea])
	{
		NSDictionary *userInfo = [[theEvent trackingArea] userInfo];
		if (!userInfo)
			return;
		KOMouseHotspotHandler *handler = [userInfo valueForKey: KOMouseHandlerUserInfoName];
		[handler mouseEntered: theEvent];		
	}
}

- (void) mouseExited: (NSEvent *)theEvent {
	if ([theEvent trackingArea])
	{
		NSDictionary *userInfo = [[theEvent trackingArea] userInfo];
		if (!userInfo)
			return;
		KOMouseHotspotHandler *handler = [userInfo valueForKey: KOMouseHandlerUserInfoName];
		[handler mouseExited: theEvent];	
	}
}

- (void) mouseMoved: (NSEvent *)theEvent {
	if (activeTrackingAreaUserInfo)
	{
		//NSLog(@"mouseMoved: ");
		KOMouseHotspotHandler *handler = [activeTrackingAreaUserInfo valueForKey: KOMouseHandlerUserInfoName];
		[handler mouseMoved: theEvent];
	} else if (backgroundTrackingAreaUserInfo) {
		KOMouseHotspotHandler *handler = [backgroundTrackingAreaUserInfo valueForKey: KOMouseHandlerUserInfoName];
		[handler mouseMoved: theEvent];
	}
}

- (void) mouseUp: (NSEvent *)theEvent {
	/*if (_activeMouseHandler) {
		[_activeMouseHandler mouseUp:theEvent];
	}*/
	if (activeTrackingAreaUserInfo) {
		KOMouseHotspotHandler *handler = [activeTrackingAreaUserInfo valueForKey: KOMouseHandlerUserInfoName];
		[handler mouseUp: theEvent];
	} else if (backgroundTrackingAreaUserInfo) {
		KOMouseHotspotHandler *handler = [backgroundTrackingAreaUserInfo valueForKey: KOMouseHandlerUserInfoName];
		[handler mouseUp: theEvent];		
	}
}

- (void) cursorUpdate: (NSEvent *)theEvent {
	NSLog(@"KOMouseBehaviorManager cursorUpdate:");
}

#pragma mark -
#pragma mark Add Tracking Area
- (BOOL) isMouseInsideRect: (NSRect)rect {
	NSPoint mousePos = [_view convertPoint: [[_view window] convertScreenToBase:[NSEvent mouseLocation]] fromView:nil];
	return [_view mouse:mousePos inRect:rect];
}

- (void) addTrackingAreaWithRect: (NSRect)rect 
						userInfo: (NSDictionary *)userInfo {
	//NSLog(@"KOMouseBehaviorManager addTrackingAreaWithRect(No Cursor):");
	NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect: rect 
														options: (  NSTrackingMouseEnteredAndExited
																  | NSTrackingMouseMoved
																  | NSTrackingActiveWhenFirstResponder) 
														  owner: self
													   userInfo: userInfo];
	[_view addTrackingArea:area];
	if ([self isMouseInsideRect: rect]) {
		NSEvent *event = [NSEvent enterExitEventWithType:NSMouseEntered 
												location:[NSEvent mouseLocation] 
										   modifierFlags:NSMouseEnteredMask 
											   timestamp:0
											windowNumber:[[_view window] windowNumber] 
												 context:nil
											 eventNumber:0
										  trackingNumber:(NSInteger)area
												userData:nil];
		[self mouseEntered: event];
	}
}

- (void) addTrackingAreaWithRect: (NSRect)rect 
						userInfo: (NSDictionary *)userInfo 
						  cursor: (NSCursor *)cursor {
	NSLog(@"KOMouseBehaviorManager addTrackingAreaWithRect(Cursor):");
	[_view addCursorRect:rect cursor:cursor];
	[self addTrackingAreaWithRect:rect userInfo:userInfo];
}

#pragma mark -
#pragma mark Update State
/*
 * clear all tracking rects
 */
- (void)clearAllTrackingArea {
	[[_view getEffectView] clear];
	// remove all tool tips, cursor rects, and tracking areas
	[_view removeAllToolTips];
	[_view discardCursorRects];
	
	_activeMouseHandler = nil;
	activeTrackingAreaUserInfo = nil;
	for (NSTrackingArea *area in [_view trackingAreas]) {
		[_view removeTrackingArea: area];
		if ([area owner] != self)
			[[area owner] release];
	}
}

- (void)refreshAllHotSpots {
	// Clear it...
	[self clearAllTrackingArea];
	// For default hot spots
	if(![[_view frontMostConnection] connected])
		return;
	
	// Update IP address, this should be carried out always.
	[_ipAddrHandler update];
	// Set the cursor for writting texts
	// I don't know why the cursor cannot change the first time
	
	if ([[_view frontMostTerminal] bbsState].state == BBSComposePost) 
		[_view addCursorRect:[_view frame] cursor:gMoveCursor];
	
	// For the mouse preference
	if (![[[_view frontMostConnection] site] enableMouse]) 
		return;
	[_clickEntryHandler update];
	[_buttonAreaHandler update];
	[_movingAreaHandler update];
}

- (void)setActiveHandler: (KOMouseHotspotHandler <KOMouseHotspotDelegate> *)handler {
	_activeMouseHandler = handler;
}

- (KOMouseHotspotHandler <KOMouseHotspotDelegate> *)activeHandler {
	return _activeMouseHandler;
}

- (void)removeActiveHandler {
	_activeMouseHandler = nil;
}

#pragma mark button Area

- (YLView *)view {
	return _view;
}

@synthesize activeTrackingAreaUserInfo;
@synthesize backgroundTrackingAreaUserInfo;
@end
