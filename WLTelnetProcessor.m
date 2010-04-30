//
//  LLTelnetProcessor.m
//  Welly
//
//  Created by gtCarrera @ 9# on 08-8-12.
//  Copyright 2008. All rights reserved.
//

#import "WLTelnetProcessor.h"
#import "WLGlobalConfig.h"

@implementation WLTelnetProcessor
// Constructor
- (id)initWithView:(NSView *)view {
	if (self = [super init]) {
        _screenRatio = 0.0f;
		_targetView = [view retain];
    }
    return self;
}

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
