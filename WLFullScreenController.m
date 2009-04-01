//
//  LLFullScreenController.m
//  Welly
//
//  Created by gtCarrera @ 9# on 08-8-11.
//  Copyright 2008. All rights reserved.
//

#import "WLFullScreenController.h"
#import "YLView.h"
#import <Carbon/Carbon.h>
#import <Quartz/Quartz.h>

@implementation WLFullScreenController
@synthesize isInFullScreen = _isInFullScreen;
@synthesize processor = _processor;
#pragma mark -
#pragma mark Init
// Initiallize the controller with a given processor
- (id)initWithProcessor:(WLFullScreenProcessor*)pro 
			 targetView:(NSView*)tview 
			  superView:(NSView*)sview
		 originalWindow:(NSWindow*)owin {
	if (self = [super init]) {
		_processor = [pro retain];
		_targetView = [tview retain];
		_superView = [sview retain];
		_originalWindow = [owin retain];
		_isInFullScreen = NO;
	}
	return self;
}

// Initiallize the controller with non-processor
// This function ONLY makes the target view showed in full
// screen but cannot resize it
- (id)initWithTargetView:(NSView*)tview 
			   superView:(NSView*)sview
		  originalWindow:(NSWindow*)owin {
	if (self = [super init]) {
		_processor = nil;
		_targetView = [tview retain];
		_superView = [sview retain];
		_originalWindow = [owin retain];
		_isInFullScreen = NO;
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
- (void)handleFullScreen {
	if (!_isInFullScreen) {
		// Set current state
		_isInFullScreen = YES;
		// Init the window and show
		NSRect screenRect = [[NSScreen mainScreen] frame];
		_fullScreenWindow = [[NSWindow alloc] initWithContentRect:screenRect
														styleMask:NSBorderlessWindowMask
														  backing:NSBackingStoreBuffered
															defer:NO];
		[_fullScreenWindow setAlphaValue:0];
		[_fullScreenWindow setBackgroundColor:[NSColor blackColor]];
		// Order front now
		[_fullScreenWindow makeKeyAndOrderFront:nil];
		// Initiallize the animation
		CAAnimation * anim = [CABasicAnimation animation];
		[anim setDelegate:self];
		[anim setDuration:0.8];
		// Set the animation to full screen window
		[_fullScreenWindow setAnimations:[NSDictionary dictionaryWithObject:anim forKey:@"alphaValue"]];
		[_fullScreenWindow.animator setAlphaValue:1.0];	
		// Change UI mode by carbon
		SetSystemUIMode(kUIModeAllHidden, kUIOptionAutoShowMenuBar);
		// Then, let the delegate function do it...
	} else {
		[self releaseFullScreen];
	}
}

// Make the view out of the full screen state
- (void)releaseFullScreen {
	if(_isInFullScreen) {
		// Change the state
		_isInFullScreen = false;
		// Set the super view back
		[_superView addSubview:_targetView];
		// Pre-process if necessary
		// Do not move it to else where!
		if(_processor != nil) {
			[_processor processBeforeExit];
		}
		[_fullScreenWindow.animator setAlphaValue:0];
		// Change UI mode by carbon
		SetSystemUIMode(kUIModeNormal, 0);
		// Now, the delegate function will close the window
		// So simply do nothing here.
	}
}

#pragma mark -
#pragma mark Delegate function
- (void)animationDidStop:(CAAnimation *)animation 
				finished:(BOOL)flag {
	if(!_isInFullScreen) { 
		// Close the window!
		[_fullScreenWindow close];
		// Show the main window
		[_originalWindow setAlphaValue:100.0f];
	} else { // Set the window when the animation is over
		// Hide the main window
        [_originalWindow setAlphaValue:0.0f];
		// Pre-process if necessary
		if(_processor != nil) {
			[_processor processBeforeEnter];
		}
		// Record new origin
		NSRect screenRect = [[NSScreen mainScreen] frame];
        NSPoint newOP = {0, (screenRect.size.height - [_targetView frame].size.height) / 2};
		// Set the window style
		[_fullScreenWindow setOpaque:NO];
        [_fullScreenWindow setBackgroundColor:[[YLLGlobalConfig sharedInstance] colorBG]];
        // Set the view to the full screen window
        [_fullScreenWindow setContentView:_targetView];
        // Move the origin point
        [[_fullScreenWindow contentView] setFrameOrigin:newOP];
	}
}
@end
