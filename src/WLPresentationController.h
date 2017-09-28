//
//  LLFullScreenController.h
//  Welly
//
//  Created by gtCarrera @ 9# on 08-8-11.
//  Copyright 2008. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@protocol WLPresentationModeProcessor;

@interface WLPresentationController : NSObject
@property (readonly) BOOL isInPresentationMode;

// Init functions
- (id)initWithProcessor:(NSObject <WLPresentationModeProcessor>*)pro 
			 targetView:(NSView*)tview 
			  superView:(NSView*)sview
		 originalWindow:(NSWindow*)owin;
- (id)initWithTargetView:(NSView*)tview 
				 superView:(NSView*)sview
			originalWindow:(NSWindow*)owin;
// Handle functions
- (void)togglePresentationMode;
- (void)exitPresentationMode;

@end
