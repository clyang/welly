//
//  KOMouseBehaviorManager.m
//  Welly
//
//  Created by K.O.ed on 09-1-31.
//  Copyright 2009 Welly Group. All rights reserved.
//

#import "KOMouseBehaviorManager.h"
#import "KOIPAddrHotspotHandler.h"
#import "KOMovingAreaHotspotHandler.h"
#import "KOClickEntryHotspotHandler.h"
#import "KOButtonAreaHotspotHandler.h"
#import "KOEditingCursorMoveHotspotHandler.h"
#import "KOAuthorAreaHotspotHandler.h"

#import "YLView.h"
#import "YLTerminal.h"
#import "YLSite.h"
#import "KOEffectView.h"

NSString * const KOMouseHandlerUserInfoName = @"Handler";
NSString * const KOMouseRowUserInfoName = @"Row";
NSString * const KOMouseCommandSequenceUserInfoName = @"Command Sequence";
NSString * const KOMouseButtonTypeUserInfoName = @"Button Type";
NSString * const KOMouseButtonTextUserInfoName = @"Button Text";
NSString * const KOMouseCursorUserInfoName = @"Cursor";
NSString * const KOMouseAuthorUserInfoName = @"Author";

@implementation KOMouseBehaviorManager
@synthesize activeTrackingAreaUserInfo = _activeTrackingAreaUserInfo;
@synthesize backgroundTrackingAreaUserInfo = _backgroundTrackingAreaUserInfo;
@synthesize normalCursor = _normalCursor;
#pragma mark -
#pragma mark Initialization
- (id)initWithView: (YLView *)view {
	[self init];
	_view = view;
	
	_handlers = [[NSArray alloc] initWithObjects:
				 [[KOIPAddrHotspotHandler alloc] initWithManager:self],
				 [[KOClickEntryHotspotHandler alloc] initWithManager:self],
				 [[KOButtonAreaHotspotHandler alloc] initWithManager:self],
				 [[KOMovingAreaHotspotHandler alloc] initWithManager:self],
				 [[KOEditingCursorMoveHotspotHandler alloc] initWithManager:self],
				 [[KOAuthorAreaHotspotHandler alloc] initWithManager:self],
				 nil];
	return self;
}

- (id)init {
	[super init];
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
	if ([theEvent trackingArea])
	{
		NSDictionary *userInfo = [[theEvent trackingArea] userInfo];
		if (!userInfo)
			return;
		KOMouseHotspotHandler *handler = [userInfo valueForKey:KOMouseHandlerUserInfoName];
		[handler mouseEntered:theEvent];		
	}
}

- (void)mouseExited:(NSEvent *)theEvent {
	if ([theEvent trackingArea])
	{
		NSDictionary *userInfo = [[theEvent trackingArea] userInfo];
		if (!userInfo)
			return;
		KOMouseHotspotHandler *handler = [userInfo valueForKey:KOMouseHandlerUserInfoName];
		[handler mouseExited:theEvent];	
	}
}

- (void)mouseMoved:(NSEvent *)theEvent {
	if (_activeTrackingAreaUserInfo)
	{
		KOMouseHotspotHandler *handler = [_activeTrackingAreaUserInfo valueForKey:KOMouseHandlerUserInfoName];
		[handler mouseMoved:theEvent];
	} else if (_backgroundTrackingAreaUserInfo) {
		KOMouseHotspotHandler *handler = [_backgroundTrackingAreaUserInfo valueForKey:KOMouseHandlerUserInfoName];
		[handler mouseMoved:theEvent];
	}
}

- (void)mouseUp:(NSEvent *)theEvent {
	if (_activeTrackingAreaUserInfo) {
		KOMouseHotspotHandler *handler = [_activeTrackingAreaUserInfo valueForKey:KOMouseHandlerUserInfoName];
		if ([handler conformsToProtocol:@protocol(KOMouseUpHandler)])
			[handler mouseUp:theEvent];
		return;
	}
	if (_backgroundTrackingAreaUserInfo) {
		KOMouseHotspotHandler *handler = [_backgroundTrackingAreaUserInfo valueForKey:KOMouseHandlerUserInfoName];
		if ([handler conformsToProtocol:@protocol(KOMouseUpHandler)])
			[handler mouseUp:theEvent];
		return;
	}
	
	if ([[_view frontMostTerminal] bbsState].state == BBSWaitingEnter) {
		[_view sendText:termKeyEnter];
	}
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
	if (_activeTrackingAreaUserInfo) {
		KOMouseHotspotHandler *handler = [_activeTrackingAreaUserInfo valueForKey:KOMouseHandlerUserInfoName];
		if ([handler conformsToProtocol:@protocol(KOContextualMenuHandler)])
			return [(NSObject <KOContextualMenuHandler> *)handler menuForEvent:theEvent];
	} 
	if (_backgroundTrackingAreaUserInfo) {
		KOMouseHotspotHandler *handler = [_backgroundTrackingAreaUserInfo valueForKey:KOMouseHandlerUserInfoName];
		if ([handler conformsToProtocol:@protocol(KOContextualMenuHandler)])
			return [(NSObject <KOContextualMenuHandler> *)handler menuForEvent:theEvent];
	}
	
	return nil;
}

#pragma mark -
#pragma mark Add Tracking Area
- (BOOL)isMouseInsideRect:(NSRect)rect {
	NSPoint mousePos = [_view convertPoint:[[_view window] convertScreenToBase:[NSEvent mouseLocation]] fromView:nil];
	return [_view mouse:mousePos inRect:rect];
}

- (void)addTrackingAreaWithRect:(NSRect)rect 
					   userInfo:(NSDictionary *)userInfo {
	NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:rect 
														options:(  NSTrackingMouseEnteredAndExited
																 | NSTrackingMouseMoved
																 | NSTrackingActiveInActiveApp) 
														  owner:self
													   userInfo:userInfo];
	[_view addTrackingArea:area];
	if ([_view isMouseActive] && [self isMouseInsideRect:rect]) {
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
}

- (void)addTrackingAreaWithRect:(NSRect)rect 
					   userInfo:(NSDictionary *)userInfo 
						 cursor:(NSCursor *)cursor {
	[_view addCursorRect:rect cursor:cursor];
	[self addTrackingAreaWithRect:rect userInfo:userInfo];
}

#pragma mark -
#pragma mark Update State
/*
 * clear all tracking rects
 */
- (void)clearAllTrackingArea {
	// Clear effect
	[[_view effectView] clear];
	// Restore cursor
	[[NSCursor arrowCursor] set];
	
	// remove all tool tips, cursor rects, and tracking areas
	[_view removeAllToolTips];
	[_view discardCursorRects];
	
	_activeTrackingAreaUserInfo = nil;
	_backgroundTrackingAreaUserInfo = nil;
	for (NSTrackingArea *area in [_view trackingAreas]) {
		[_view removeTrackingArea:area];
		if ([area owner] != self)
			[[area owner] release];
	}
}

- (void)update {
	// Clear it...
	[self clearAllTrackingArea];
	
	if(![[_view frontMostConnection] connected])
		return;
	
	for (NSObject *obj in _handlers) {
		if ([obj conformsToProtocol:@protocol(KOUpdatable)])
			[(NSObject <KOUpdatable> *)obj update];
	}
}

- (YLView *)view {
	return _view;
}

- (void)restoreNormalCursor {
	[_normalCursor set];
}

- (void)enable {
	_enabled = YES;
	[self update];
}

- (void)disable {
	_enabled = NO;
}
@end