//
//  KOMouseHotspotHandler.m
//  Welly
//
//  Created by K.O.ed on 09-1-27.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//
#import "KOMouseHotspotHandler.h"
#import "YLView.h"
#import "KOEffectView.h"

@implementation KOMouseHotspotHandler
- (id) initWithView: (YLView *)view 
			   rect: (NSRect)rect {
	[self init];
	_view = view;
	_effectView = [view getEffectView];
	_rect = rect;
	// Check if mouse is already inside the area
	NSPoint mousePos = [_view convertPoint: [[_view window] convertScreenToBase:[NSEvent mouseLocation]] fromView:nil];
	if ([_view mouse:mousePos inRect:rect]) {
		[self mouseEntered:[[NSEvent alloc] init]];
	}
	return self;
}

- (void) mouseEntered: (NSEvent *)theEvent {
	// Do nothing, just a virtual function
}
@end
