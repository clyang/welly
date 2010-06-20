//
//  LLFullScreenController.m
//  Welly
//
//  Created by gtCarrera @ 9# on 08-8-11.
//  Copyright 2008. All rights reserved.
//

#import "WLFullScreenController.h"
#import "WLFullScreenProcessor.h"
#import "WLTerminalView.h"
#import "WLGlobalConfig.h"
#import <Carbon/Carbon.h>
#import <Quartz/Quartz.h>

@interface WLFullScreenWindow : NSWindow

@end


@implementation WLFullScreenWindow

- (BOOL)canBecomeKeyWindow {
	return YES;
}

@end


@implementation WLFullScreenController
@synthesize isInFullScreen = _isInFullScreen;
#pragma mark -
#pragma mark Init
// Initiallize the controller with a given processor
- (id)initWithProcessor:(NSObject <WLFullScreenProcessor>*)pro 
			 targetView:(NSView *)tview 
			  superView:(NSView *)sview
		 originalWindow:(NSWindow *)owin {
	if (self = [super init]) {
		_targetView = [tview retain];
		_superView = [sview retain];
		_originalWindow = [owin retain];
		_isInFullScreen = NO;
		_screenRatio = 0.0f;
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
#pragma mark Handle functions - Control Logic
// The main control function of this object
- (void)handleFullScreen {
	if (!_isInFullScreen) {
		// Set current state
		_isInFullScreen = YES;
		
		// Init the window and show
		NSRect screenRect = [[NSScreen mainScreen] frame];
		_fullScreenWindow = [[WLFullScreenWindow alloc] initWithContentRect:screenRect
														styleMask:NSBorderlessWindowMask
														  backing:NSBackingStoreBuffered
															defer:NO];
		[_fullScreenWindow setAlphaValue:0];
		[_fullScreenWindow setBackgroundColor:[NSColor blackColor]];
		[_fullScreenWindow setAcceptsMouseMovedEvents:YES];
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
		_isInFullScreen = NO;
		
		// Set the super view back
		[_superView addSubview:_targetView];
		// Pre-process if necessary
		// Do not move it to else where!
		[self processBeforeExit];
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
		[self processBeforeEnter];
		// Record new origin
		NSRect screenRect = [[NSScreen mainScreen] frame];
        NSPoint newOP = {0, (screenRect.size.height - [_targetView frame].size.height) / 2};
		// Set the window style
		[_fullScreenWindow setOpaque:NO];
        [_fullScreenWindow setBackgroundColor:[[WLGlobalConfig sharedInstance] colorBG]];
        // Set the view to the full screen window
        [_fullScreenWindow setContentView:_targetView];
        // Move the origin point
        [[_fullScreenWindow contentView] setFrameOrigin:newOP];
		// Focus on the view
		[_fullScreenWindow makeFirstResponder:_targetView];
	}
}

#pragma mark -
#pragma mark For TerminalView
// Set and reset font size
- (void)setFont:(BOOL)isEnteringFullScreen {
	// In case of some stupid uses...
	if(_screenRatio == 0.0f)
		return;
	// Decide whether to set or to reset the font size
	CGFloat currRatio = (isEnteringFullScreen ? _screenRatio : (1.0f / _screenRatio));
	// And do it..
	[[WLGlobalConfig sharedInstance] setEnglishFontSize: 
	 [[WLGlobalConfig sharedInstance] englishFontSize] * currRatio];
	[[WLGlobalConfig sharedInstance] setChineseFontSize: 
	 [[WLGlobalConfig sharedInstance] chineseFontSize] * currRatio];
	[[WLGlobalConfig sharedInstance] setCellWidth: 
	 [[WLGlobalConfig sharedInstance] cellWidth] * currRatio];
	[[WLGlobalConfig sharedInstance] setCellHeight: 
	 [[WLGlobalConfig sharedInstance] cellHeight] * currRatio];
}

// Overrided functions
- (void)processBeforeEnter {
	// Get the fittest ratio for the expansion
	NSRect screenRect = [[NSScreen mainScreen] frame];
	CGFloat ratioH = screenRect.size.height / [_targetView frame].size.height;
	CGFloat ratioW = screenRect.size.width / [_targetView frame].size.width;
	_screenRatio = (ratioH > ratioW) ? ratioW : ratioH;
	
	// Then, do the expansion
	[self setFont:YES];
}

- (void)processBeforeExit {
	// And reset the font...
	[self setFont:NO];
}

@end
