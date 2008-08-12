//
//  LLFullScreenController.m
//  Welly
//
//  Created by gtCarrera @ 9# on 08-8-11.
//  Copyright 2008. All rights reserved.
//

#import "LLFullScreenController.h"


@implementation LLFullScreenController

#pragma mark -
#pragma mark Init
// Initiallize the controller with a given processor
- (id) initWithProcessor:(LLFullScreenProcessor*)pro 
			  targetView:(NSView*)tview 
			   superView:(NSView*)sview
		  originalWindow:(NSWindow*) owin {
	if(self = [super init]) {
		_myProcessor = [pro retain];
		_targetView = [tview retain];
		_superView = [sview retain];
		_originalWindow = [owin retain];
		_isFullScreen = false;
	}
	return self;
}

// Initiallize the controller with non-processor
// This way ONLY makes the target view showed in full
// screen but cannot resize it
- (id) initWithoutProcessor:(NSView*)tview 
				  superView:(NSView*)sview
			 originalWindow:(NSWindow*) owin {
	if(self = [super init]) {
		_myProcessor = nil;
		_targetView = [tview retain];
		_superView = [sview retain];
		_originalWindow = [owin retain];
		_isFullScreen = false;
	}
	return self;
}

#pragma mark -
#pragma mark Dealloc
- (void)dealloc {
	[_fullScreenWindow release];
    [super dealloc];
}

#pragma mark -
#pragma mark Handle functions
// The main control function of this object
- (void) handleFullScreen {
}

// Make the view out of the full screen state
- (void) releaseFullScreen {
}
@end
