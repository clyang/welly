//
//  LLFullScreenController.m
//  Welly
//
//  Created by gtCarrera @ 9# on 08-8-11.
//  Copyright 2008. All rights reserved.
//

#import "WLMainFrameController+FullScreen.h"
#import "WLPresentationController.h"
#import "WLFullScreenProcessor.h"
#import "WLTerminalView.h"
#import "WLGlobalConfig.h"
#import <Carbon/Carbon.h>
#import <Quartz/Quartz.h>

#define NSLOG_Rect(rect) NSLog(@#rect ": (%f, %f) %f x %f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)
#define NSLOG_Size(size) NSLog(@#size ": %f x %f", size.width, size.height)
#define NSLog_Point(point) NSLog(@#point ": (%f, %f)", point.x, point.y)

@interface WLFullScreenWindow : NSWindow

@end


@implementation WLFullScreenWindow

- (BOOL)canBecomeKeyWindow {
	return YES;
}

@end

@interface WLPresentationController () {
	// The views necessary for full screen and reset
	NSView *_targetView;
	NSView *_superView;
	
	// NSWindows needed...
	NSWindow *_fullScreenWindow;
	NSWindow *_originalWindow;
	
	NSRect _originalFrame;
	
	// State variable
	BOOL _isInPresentationMode;
	CGFloat _screenRatio;
	
	// Store previous parameters
	NSDictionary *_originalSizeParameters;
}
// Preprocess functions for TerminalView
- (void)processBeforeEnter;
- (void)processBeforeExit;
@end

@implementation WLPresentationController
@synthesize isInPresentationMode = _isInPresentationMode;

WLGlobalConfig *gConfig;

#pragma mark -
#pragma mark Init
// Initiallize the controller with a given processor
- (id)initWithProcessor:(NSObject <WLPresentationModeProcessor>*)pro 
			 targetView:(NSView *)tview 
			  superView:(NSView *)sview
		 originalWindow:(NSWindow *)owin {
	if (self = [super init]) {
		_targetView = [tview retain];
		_superView = [sview retain];
		_originalWindow = [owin retain];
		_isInPresentationMode = NO;
		_screenRatio = 0.0f;
		if (!gConfig) {
			gConfig = [WLGlobalConfig sharedInstance];
		}
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
		_isInPresentationMode = NO;
		if (!gConfig) {
			gConfig = [WLGlobalConfig sharedInstance];
		}
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
- (void)togglePresentationMode {
	if (!_isInPresentationMode) {
		// Set current state
		_isInPresentationMode = YES;
		
		// Disable `Enter Full Screen' when we are in presentation mode
		_originalWindow.collectionBehavior ^= NSWindowCollectionBehaviorFullScreenPrimary;
		
		// Init the window and show
		NSRect screenRect = [[NSScreen mainScreen] frame];
		_fullScreenWindow = [[WLFullScreenWindow alloc] initWithContentRect:screenRect
														styleMask:NSBorderlessWindowMask
														  backing:NSBackingStoreBuffered
															defer:NO];
		[_fullScreenWindow setAlphaValue:0];
        if (floor(NSAppKitVersionNumber)>NSAppKitVersionNumber10_6) {
            [_fullScreenWindow setCollectionBehavior:NSWindowCollectionBehaviorFullScreenAuxiliary];
        }
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
		[self exitPresentationMode];
	}
}

// Make the view out of the full screen state
- (void)exitPresentationMode {
	if(_isInPresentationMode) {
		// Change the state
		_isInPresentationMode = NO;
		
		// Set the super view back
		[_superView addSubview:_targetView];
		[_targetView setFrame:_originalFrame];
		// Pre-process if necessary
		// Do not move it to else where!
		[self processBeforeExit];
		[_fullScreenWindow.animator setAlphaValue:0];
		// Change UI mode by carbon
		SetSystemUIMode(kUIModeNormal, 0);
		// Now, the delegate function will close the window
		// So simply do nothing here.
		
		// Enable `Enter Full Screen' from now on
		_originalWindow.collectionBehavior |= NSWindowCollectionBehaviorFullScreenPrimary;
	}
}

#pragma mark -
#pragma mark Delegate function
- (void)animationDidStop:(CAAnimation *)animation 
				finished:(BOOL)flag {
	if(!_isInPresentationMode) { 
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
		
        NSPoint newOP = {(screenRect.size.width - [_targetView frame].size.width) / 2, (screenRect.size.height - [_targetView frame].size.height) / 2};
		
		// Set the window style
        [_fullScreenWindow setBackgroundColor:[[WLGlobalConfig sharedInstance] colorBG]];
		
		[_fullScreenWindow setOpaque:NO];
		[_fullScreenWindow display];
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
	if (isEnteringFullScreen) {
		// Store old parameters
		_originalSizeParameters = [[gConfig sizeParameters] copy];
		
		// And do it..
		[gConfig setSizeParameters:[WLMainFrameController sizeParametersForZoomRatio:_screenRatio]];
		
	} else {
		// Restore old parameters
		[gConfig setSizeParameters:_originalSizeParameters];
		[_originalSizeParameters release];
		_originalSizeParameters = nil;
	}
}

// Overrided functions
- (void)processBeforeEnter {
	// Back up the original frame of _targetView
	_originalFrame = [_targetView frame];
	
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
