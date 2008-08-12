//
//  LLTelnetProcessor.m
//  Welly
//
//  Created by gtCarrera @ 9# on 08-8-12.
//  Copyright 2008. All rights reserved.
//

#import "LLTelnetProcessor.h"


@implementation LLTelnetProcessor

// Constructor
- (id) initByView:(NSView*) view {
	if (self = [super init]) {
        _screenRatio = 0.0f;
		_myView = view;
		NSLog(@"init: [_myView frame].size.height = %f \n", [_myView frame].size.height);
    }
    return self;
}

// Set and reset font size
// The code is a little bit ugly...
- (void) setFont:(bool)isSet {
	// Decide whether to set or to reset the font size
	CGFloat currRatio = (isSet ? _screenRatio : (1.0f / _screenRatio));

	// And do it..
	[[YLLGlobalConfig sharedInstance] setEnglishFontSize: 
	 [[YLLGlobalConfig sharedInstance] englishFontSize] * currRatio];
	[[YLLGlobalConfig sharedInstance] setChineseFontSize: 
	 [[YLLGlobalConfig sharedInstance] chineseFontSize] * currRatio];
	[[YLLGlobalConfig sharedInstance] setCellWidth: 
	 [[YLLGlobalConfig sharedInstance] cellWidth] * currRatio];
	[[YLLGlobalConfig sharedInstance] setCellHeight: 
	 [[YLLGlobalConfig sharedInstance] cellHeight] * currRatio];
}

// Overrided functions
- (void) processBeforeEnter {
	NSRect screenRect = [[NSScreen mainScreen] frame];
	CGFloat ratioH = screenRect.size.height / [_myView frame].size.height;
	CGFloat ratioW = screenRect.size.width / [_myView frame].size.width;
	if (ratioH > ratioW) {
		_screenRatio = ratioW;
	} else {
		_screenRatio = ratioH;
	}
	NSLog(@"[_myView frame].size.height = %f \n", [_myView frame].size.height);
	// Do the expandsion
	[self setFont:YES];
}

- (void) processBeforeExit {
	[self setFont:NO];
}

@end
