//
//  WLMainFrameController+FullScreen.m
//  Welly
//
//  Created by KOed on 13-3-26.
//  Copyright (c) 2013年 Welly Group. All rights reserved.
//

#define NSLOG_Rect(rect) NSLog(@#rect ": (%f, %f) %f x %f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)
#define NSLOG_Size(size) NSLog(@#size ": %f x %f", size.width, size.height)
#define NSLog_Point(point) NSLog(@#point ": (%f, %f)", point.x, point.y)

#import "WLMainFrameController.h"
#import "WLTabBarControl.h"
#import "WLMainFrameController+FullScreen.h"
#import "WLGlobalConfig.h"

@implementation WLMainFrameController (FullScreen)

- (BOOL)isInFullScreenMode {
	return ([_mainWindow styleMask] & NSFullScreenWindowMask) ? YES : NO;
}

// Set and reset font size
- (void)setFont:(BOOL)isEnteringFullScreen {
	// In case of some stupid uses...
	if (_screenRatio == 0.0f)
		return;
	WLGlobalConfig *gConfig = [WLGlobalConfig sharedInstance];
	// Decide whether to set or to reset the font size
	if (isEnteringFullScreen) {
		// Store old parameters
		_originalSizeParameters = [@{@"englishFontSize":@([gConfig englishFontSize]), @"chineseFontSize":@([gConfig chineseFontSize]), @"cellWidth":@([gConfig cellWidth]), @"cellHeight":@([gConfig cellHeight])} copy];
		
		// And do it..
		[gConfig setEnglishFontSize:floor([gConfig englishFontSize] * _screenRatio)];
		[gConfig setChineseFontSize:floor([gConfig chineseFontSize] * _screenRatio)];
		[gConfig setCellWidth:floor([gConfig cellWidth] * _screenRatio)];
		[gConfig setCellHeight:floor([gConfig cellHeight] * _screenRatio)];
	} else {
		// Restore old parameters
		[gConfig setEnglishFontSize:[[_originalSizeParameters objectForKey:@"englishFontSize"] floatValue]];
		[gConfig setChineseFontSize:[[_originalSizeParameters objectForKey:@"chineseFontSize"] floatValue]];
		[gConfig setCellWidth:[[_originalSizeParameters objectForKey:@"cellWidth"] floatValue]];
		[gConfig setCellHeight:[[_originalSizeParameters objectForKey:@"cellHeight"] floatValue]];
		[_originalSizeParameters release];
		_originalSizeParameters = nil;
	}
}

- (NSApplicationPresentationOptions)window:(NSWindow *)window
	  willUseFullScreenPresentationOptions:(NSApplicationPresentationOptions)proposedOptions {
    // customize our appearance when entering full screen:
    // we don't want the dock to appear but we want the menubar to hide/show automatically
    // we also want the toolbar to hide/show automatically
    return (NSApplicationPresentationFullScreen |       // support full screen for this window (required)
            NSApplicationPresentationHideDock |         // completely hide the dock
            NSApplicationPresentationAutoHideMenuBar |  // yes we want the menu bar to show/hide
			NSApplicationPresentationAutoHideToolbar);	// we want the toolbar to show/hide
}

- (NSSize)window:(NSWindow *)window willUseFullScreenContentSize:(NSSize)proposedSize {
	return proposedSize;
}


- (void)windowWillEnterFullScreen:(NSNotification *)notification {
	[_tabBarControl setHidden:YES];
		
	// Back up the original frame of _targetView
	_originalFrame = [_tabView frame];
	
	// Get the fittest ratio for the expansion
	NSRect screenRect = [[NSScreen mainScreen] frame];
	
	CGFloat ratioH = screenRect.size.height / [_tabView frame].size.height;
	CGFloat ratioW = screenRect.size.width / [_tabView frame].size.width;
	_screenRatio = (ratioH > ratioW) ? ratioW : ratioH;
	
	// Then, do the expansion
	[self setFont:YES];
	
	// Record new origin
	
	NSPoint newOP = {(screenRect.size.width - [_tabView frame].size.width) / 2, (screenRect.size.height - [_tabView frame].size.height) / 2};
	
	// Set the window style
	[_mainWindow setOpaque:YES];
	// Back up original bg color
	_originalWindowBackgroundColor = [_mainWindow backgroundColor];
	// Now set to bg color of the tab view to ensure consistency
	[_mainWindow setBackgroundColor:[[WLGlobalConfig sharedInstance] colorBG]];
	
	// Move the origin point
	[_tabView setFrameOrigin:newOP];
}

- (void)windowDidEnterFullScreen:(NSNotification *)notification {

}

- (void)windowWillExitFullScreen:(NSNotification *)notification {
	[_tabBarControl setHidden:NO];
	
	// Set the size back
	[self setFont:NO];
	
	[_mainWindow setOpaque:NO];
	// Move view back
	[_tabView setFrame:_originalFrame];
	[_mainWindow setBackgroundColor:_originalWindowBackgroundColor];
}

- (void)windowDidExitFullScreen:(NSNotification *)notification {
	
}

@end
