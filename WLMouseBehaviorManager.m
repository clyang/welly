//
//  WLMouseBehaviorManager.m
//  Welly
//
//  Created by K.O.ed on 09-1-31.
//  Copyright 2009 Welly Group. All rights reserved.
//

#import "WLMouseBehaviorManager.h"
#import "WLIPAddrHotspotHandler.h"
#import "WLMovingAreaHotspotHandler.h"
#import "WLClickEntryHotspotHandler.h"
#import "WLButtonAreaHotspotHandler.h"
#import "WLEditingCursorMoveHotspotHandler.h"
#import "WLAuthorAreaHotspotHandler.h"
#import "WLURLManager.h"

#import "WLTerminalView.h"
#import "WLTerminal.h"
#import "WLConnection.h"
#import "WLSite.h"
#import "WLEffectView.h"

NSString * const WLMouseHandlerUserInfoName = @"Handler";
NSString * const WLMouseRowUserInfoName = @"Row";
NSString * const WLMouseCommandSequenceUserInfoName = @"Command Sequence";
NSString * const WLMouseButtonTypeUserInfoName = @"Button Type";
NSString * const WLMouseButtonTextUserInfoName = @"Button Text";
NSString * const WLMouseCursorUserInfoName = @"Cursor";
NSString * const WLMouseAuthorUserInfoName = @"Author";
NSString * const WLURLUserInfoName = @"URL";
NSString * const WLRangeLocationUserInfoName = @"RangeLocation";
NSString * const WLRangeLengthUserInfoName = @"RangeLength";

const float WLHorizontalScrollReactivateTimeInteval = 1.0;

@implementation WLMouseBehaviorManager
@synthesize activeTrackingAreaUserInfo = _activeTrackingAreaUserInfo;
@synthesize backgroundTrackingAreaUserInfo = _backgroundTrackingAreaUserInfo;
@synthesize normalCursor = _normalCursor;
@synthesize lastBBSState = _lastBBSState;
@synthesize lastCursorRow = _lastCursorRow;
@synthesize view = _view;

#pragma mark -
#pragma mark Initialization
- (id)initWithView:(WLTerminalView *)view {
	self = [self init];
	if (self) {
		_view = view;
		
		_handlers = [[NSMutableArray alloc] initWithObjects:
					 [[[WLIPAddrHotspotHandler alloc] initWithManager:self] autorelease],
					 [[[WLClickEntryHotspotHandler alloc] initWithManager:self] autorelease],
					 [[[WLButtonAreaHotspotHandler alloc] initWithManager:self] autorelease],
					 [[[WLMovingAreaHotspotHandler alloc] initWithManager:self] autorelease],
					 [[[WLEditingCursorMoveHotspotHandler alloc] initWithManager:self] autorelease],
					 [[[WLAuthorAreaHotspotHandler alloc] initWithManager:self] autorelease],
					 nil];
		_horizontalScrollReactivateTimer = [NSTimer scheduledTimerWithTimeInterval:WLHorizontalScrollReactivateTimeInteval
																			target:self
																		  selector:@selector(reactiveHorizontalScroll:)
																		  userInfo:nil
																		   repeats:YES];
		_lastHorizontalScrollDirection = WLHorizontalScrollNone;
		
		_lastBBSState.state = BBSUnknown;
		_lastCursorRow = -1;
	}
	return self;
}

- (id)init {
	self = [super init];
	if (self)
		_normalCursor = [NSCursor arrowCursor];
	return self;
}

- (void)dealloc {
	for (NSObject *obj in _handlers)
		[obj dealloc];
	[_handlers dealloc];
	[super dealloc];
}

#pragma mark -
#pragma mark Event Handle
- (void)mouseEntered:(NSEvent *)theEvent {
	if (![_view isConnected])
		return;
	if ([theEvent trackingArea]) {
		NSDictionary *userInfo = [[theEvent trackingArea] userInfo];
		if (!userInfo)
			return;
		WLMouseHotspotHandler *handler = [userInfo valueForKey:WLMouseHandlerUserInfoName];
		[handler mouseEntered:theEvent];		
	}
}

- (void)mouseExited:(NSEvent *)theEvent {
	if (![_view isConnected])
		return;
	if ([theEvent trackingArea]) {
		NSDictionary *userInfo = [[theEvent trackingArea] userInfo];
		if (!userInfo)
			return;
		WLMouseHotspotHandler *handler = [userInfo valueForKey:WLMouseHandlerUserInfoName];
		[handler mouseExited:theEvent];	
	}
}

- (void)mouseMoved:(NSEvent *)theEvent {
	if (![_view isConnected])
		return;
	if (_activeTrackingAreaUserInfo) {
		WLMouseHotspotHandler *handler = [_activeTrackingAreaUserInfo valueForKey:WLMouseHandlerUserInfoName];
		[handler mouseMoved:theEvent];
	} else if (_backgroundTrackingAreaUserInfo) {
		WLMouseHotspotHandler *handler = [_backgroundTrackingAreaUserInfo valueForKey:WLMouseHandlerUserInfoName];
		[handler mouseMoved:theEvent];
	}
}

- (void)mouseUp:(NSEvent *)theEvent {
	if (![_view isConnected])
		return;
	if (_activeTrackingAreaUserInfo) {
		WLMouseHotspotHandler *handler = [_activeTrackingAreaUserInfo valueForKey:WLMouseHandlerUserInfoName];
		if ([handler conformsToProtocol:@protocol(WLMouseUpHandler)])
			[handler mouseUp:theEvent];
		return;
	}
	if (_backgroundTrackingAreaUserInfo) {
		WLMouseHotspotHandler *handler = [_backgroundTrackingAreaUserInfo valueForKey:WLMouseHandlerUserInfoName];
		if ([handler conformsToProtocol:@protocol(WLMouseUpHandler)])
			[handler mouseUp:theEvent];
		return;
	}
	
	if ([[_view frontMostTerminal] bbsState].state == BBSWaitingEnter) {
		[_view sendText:termKeyEnter];
	}
}

- (void)scrollWheel:(NSEvent *)theEvent {
	const int WLScrollWheelHorizontalThreshold = 3;
	if ([[[_view frontMostTerminal] connection] isConnected]) {
		// For Y-Axis
		if ([theEvent deltaY] < 0)
			[_view sendText:termKeyDown];
		else if ([theEvent deltaY] > 0)
			[_view sendText:termKeyUp];
		else if (_lastHorizontalScrollDirection != WLHorizontalScrollLeft && [theEvent deltaX] > WLScrollWheelHorizontalThreshold) {
			// Disable horizontal scroll, in order to prevent multiple action
			_lastHorizontalScrollDirection = WLHorizontalScrollLeft;
			[_view sendText:termKeyLeft];
		}
		else if (_lastHorizontalScrollDirection != WLHorizontalScrollRight && [theEvent deltaX] < -WLScrollWheelHorizontalThreshold){
			// Disable horizontal scroll, in order to prevent multiple action
			_lastHorizontalScrollDirection = WLHorizontalScrollRight;
			[_view sendText:termKeyRight];
		}
	}
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
	if (_activeTrackingAreaUserInfo) {
		WLMouseHotspotHandler *handler = [_activeTrackingAreaUserInfo valueForKey:WLMouseHandlerUserInfoName];
		if ([handler conformsToProtocol:@protocol(WLContextualMenuHandler)])
			return [(NSObject <WLContextualMenuHandler> *)handler menuForEvent:theEvent];
	} 
	if (_backgroundTrackingAreaUserInfo) {
		WLMouseHotspotHandler *handler = [_backgroundTrackingAreaUserInfo valueForKey:WLMouseHandlerUserInfoName];
		if ([handler conformsToProtocol:@protocol(WLContextualMenuHandler)])
			return [(NSObject <WLContextualMenuHandler> *)handler menuForEvent:theEvent];
	}
	
	return nil;
}

#pragma mark -
#pragma mark Add/Remove Tracking Area
- (BOOL)isMouseInsideRect:(NSRect)rect {
	NSPoint mousePos = [_view mouseLocationInView];
	return [_view mouse:mousePos inRect:rect];
}

- (NSTrackingArea *)addTrackingAreaWithRect:(NSRect)rect 
								   userInfo:(NSDictionary *)userInfo {
	NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:rect 
														options:(  NSTrackingMouseEnteredAndExited
																 | NSTrackingMouseMoved
																 | NSTrackingActiveInActiveApp) 
														  owner:self
													   userInfo:userInfo];
	[_view addTrackingArea:area];
	if ([self isMouseInsideRect:rect]) {
		NSEvent *event = [NSEvent enterExitEventWithType:NSMouseEntered 
												location:[NSEvent mouseLocation] 
										   modifierFlags:NSMouseEnteredMask 
											   timestamp:0
											windowNumber:[[_view window] windowNumber] 
												 context:nil
											 eventNumber:0
										  trackingNumber:(NSInteger)area
												userData:nil];
		[self mouseEntered:event];
	}
	return area;
}

- (NSTrackingArea *)addTrackingAreaWithRect:(NSRect)rect 
								   userInfo:(NSDictionary *)userInfo 
									 cursor:(NSCursor *)cursor {
	[_view addCursorRect:rect cursor:cursor];
	return [self addTrackingAreaWithRect:rect userInfo:userInfo];
}

- (void)removeTrackingArea:(NSTrackingArea *)area {
	NSRect rect = [area rect];
	if ([self isMouseInsideRect:rect]) {
		NSEvent *event = [NSEvent enterExitEventWithType:NSMouseExited 
												location:[NSEvent mouseLocation] 
										   modifierFlags:NSMouseExitedMask 
											   timestamp:0
											windowNumber:[[_view window] windowNumber] 
												 context:nil
											 eventNumber:0
										  trackingNumber:(NSInteger)area
												userData:nil];
		[self mouseExited:event];
	}
	[_view removeTrackingArea:area];
	[area release];
}

#pragma mark -
#pragma mark Update State
- (BOOL)shouldUpdate {
	return YES;
}

- (void)update {
	for (NSObject *obj in _handlers) {
		if ([obj conformsToProtocol:@protocol(WLUpdatable)]) {
			NSObject <WLUpdatable> *updater = (NSObject <WLUpdatable> *)obj;
			// Ask if should update
			if ([updater shouldUpdate])
				[updater update];
		}
	}
	_lastBBSState = [[_view frontMostTerminal] bbsState];
	_lastCursorRow = [[_view frontMostTerminal] cursorRow];
}

- (void)forceUpdate {
	_activeTrackingAreaUserInfo = nil;
	_backgroundTrackingAreaUserInfo = nil;
	for (NSObject *obj in _handlers) {
		if ([obj conformsToProtocol:@protocol(WLUpdatable)])
			[(NSObject <WLUpdatable> *)obj update];
	}
	_lastBBSState = [[_view frontMostTerminal] bbsState];
	_lastCursorRow = [[_view frontMostTerminal] cursorRow];
}

#pragma mark -
#pragma mark Accessor
- (void)restoreNormalCursor {
	[_normalCursor set];
}

- (void)addHandler:(WLMouseHotspotHandler *)handler {
	[_handlers addObject:handler];
	[handler setManager:self];
}

- (void)reactiveHorizontalScroll:(id)sender {
	_lastHorizontalScrollDirection = WLHorizontalScrollNone;
}
@end