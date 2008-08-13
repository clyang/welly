//
//  LLFullScreenController.h
//  Welly
//
//  Created by gtCarrera @ 9# on 08-8-11.
//  Copyright 2008. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LLFullScreenProcessor.h"
#import "YLLGlobalConfig.h"

@interface LLFullScreenController : NSObject {
	// Object to resize the target view and its super view
	// This design follows the strategy pattern...
	LLFullScreenProcessor * _myProcessor;
	
	// The views necessary for full screen and reset
	NSView * _targetView;
	NSView * _superView;
	
	// NSWindows needed...
	NSWindow* _fullScreenWindow;
	NSWindow* _originalWindow;
	
	// State variable
	bool _isFullScreen;
}

// Init functions
- (id) initWithProcessor:(LLFullScreenProcessor*)pro targetView:(NSView*)tview superView:(NSView*)sview
		  originalWindow:(NSWindow*) owin;
- (id) initWithoutProcessor:(NSView*)tview superView:(NSView*)sview
			 originalWindow:(NSWindow*) owin;
// Handle functions
- (void) handleFullScreen;
- (void) releaseFullScreen;
// Accessor
- (void) setProcessor:(LLFullScreenProcessor*) myPro;
- (LLFullScreenProcessor*) getProcessor;
@end
