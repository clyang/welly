//
//  LLFullScreenController.m
//  Welly
//
//  Created by gtCarrera @ 9# on 08-8-11.
//  Copyright 2008. All rights reserved.
//

#import "LLFullScreenController.h"
#import "YLView.h"
#import <Carbon/Carbon.h>

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
// This function ONLY makes the target view showed in full
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
	if (!_isFullScreen) {
		// Set current state
		_isFullScreen = true;
		// Pre-process if necessary
		if(_myProcessor != nil) {
			[_myProcessor processBeforeEnter];
		}
        // Record new origin
		NSRect screenRect = [[NSScreen mainScreen] frame];
        NSPoint newOP = {0, (screenRect.size.height - [_targetView frame].size.height) / 2};
		// Change UI mode by carbon
		SetSystemUIMode(kUIModeAllHidden, kUIOptionAutoShowMenuBar);
		// Init the window and show
        _fullScreenWindow = [[NSWindow alloc] initWithContentRect:screenRect
														styleMask:NSBorderlessWindowMask
														  backing:NSBackingStoreBuffered
															defer:NO];
        [_fullScreenWindow setOpaque:NO];
		// FIXME: A little bit hard-code here...
        [_fullScreenWindow setBackgroundColor:[[YLLGlobalConfig sharedInstance] colorBG]];
        [_fullScreenWindow makeKeyAndOrderFront:nil];
        // Set the view to the full screen window
        [_fullScreenWindow setContentView:_targetView];
        // Move the origin point
        [[_fullScreenWindow contentView] setFrameOrigin:newOP];
		
		// Hard code to fix the effect view problem
		NSPoint newOP2 = {0, 0};
		[[(YLView *)_targetView getEffectView] setFrameOrigin:newOP2];
        // Hide the main window
        [_originalWindow setAlphaValue:0.0f];
	} else {
		[self releaseFullScreen];
	}
}

// Make the view out of the full screen state
- (void) releaseFullScreen {
	if(_isFullScreen) {
		// Change the state
		_isFullScreen = false;
		// Set the super view back
		[_superView addSubview:_targetView];
		// Pre-process if necessary
		if(_myProcessor != nil) {
			[_myProcessor processBeforeExit];
		}
		// Close the window
		[_fullScreenWindow close];
		// Show the main window
		[_originalWindow setAlphaValue:100.0f];
		// Change UI mode by carbon
		SetSystemUIMode(kUIModeNormal, 0);
	}
}

// Accessor
- (void) setProcessor:(LLFullScreenProcessor*) myPro {
	_myProcessor = [myPro retain];
}

- (LLFullScreenProcessor*) getProcessor {
	return _myProcessor;
}

- (BOOL) isInFullScreen {
	return _isFullScreen;
}
@end
