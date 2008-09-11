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
- (id) initByView:(NSView*) view myTabView:(NSView*) tView  effectView:(KOEffectView*) eView {
	if (self = [super init]) {
        _screenRatio = 0.0f;
		_myView = [view retain];
		_tabView = [tView retain];
		_effectView = [eView retain];
    }
    return self;
}

// Set and reset font size
- (void) setFont:(bool)isSet {
	// In case of some stupid uses...
	if(_screenRatio == 0.0f)
		return;
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
	// Get the fittest ratio for the expansion
	NSRect screenRect = [[NSScreen mainScreen] frame];
	CGFloat ratioH = screenRect.size.height / [_myView frame].size.height;
	CGFloat ratioW = screenRect.size.width / [_myView frame].size.width;
	_screenRatio = (ratioH > ratioW) ? ratioW : ratioH;
	
	// Set the effect view to screen size
	//_viewRect = [_effectView frame];
	NSLog(@"effectView frame %f,%f", _viewRect.size.width, _viewRect.size.height);
	NSLog(@"effectView origin %f,%f", _viewRect.origin.x, _viewRect.origin.y);
	//[_effectView setFrame:screenRect];
	NSLog(@"screenRect frame %f,%f", [_effectView frame].size.width, [_effectView frame].size.height);
	NSLog(@"screenRect origin %f,%f", [_effectView frame].origin.x, [_effectView frame].origin.y);
	// Then, do the expansion
	[self setFont:YES];
}

- (void) processBeforeExit {
	// Set the tab view back...
	[[_myView superview] addSubview:_tabView];
	[[_myView superview] addSubview:_effectView];
	// And reset the effect view...
	//[_effectView setFrame:_viewRect];
	NSLog(@"!screenRect frame %f,%f", [_effectView frame].size.width, [_effectView frame].size.height);
	NSLog(@"!screenRect origin %f,%f", [_effectView frame].origin.x, [_effectView frame].origin.y);
	// And reset the font...
	[self setFont:NO];
}

@end
