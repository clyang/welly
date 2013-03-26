//
//  WLMainFrameController+FullScreen.m
//  Welly
//
//  Created by KOed on 13-3-26.
//  Copyright (c) 2013年 Welly Group. All rights reserved.
//

#import "WLMainFrameController.h"
#import "WLTabBarControl.h"
#import "WLMainFrameController+FullScreen.h"
#import "WLGlobalConfig.h"

@implementation WLMainFrameController (FullScreen)

// Set and reset font size
- (void)setFont:(BOOL)isEnteringFullScreen {
	// In case of some stupid uses...
	if (_screenRatio == 0.0f)
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

- (void)windowWillEnterFullScreen:(NSNotification *)notification {
//	[_tabBarControl hideTabBar:YES animate:NO];
	[_tabBarControl setHidden:YES];
	
	[_mainWindow setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
	
	// Back up the original frame of _targetView
	_originalFrame = [_tabView frame];
	
	// Get the fittest ratio for the expansion
	NSRect screenRect = [[[NSScreen screens] objectAtIndex:0] frame];
	CGFloat ratioH = screenRect.size.height / [_tabView frame].size.height;
	CGFloat ratioW = screenRect.size.width / [_tabView frame].size.width;
	_screenRatio = (ratioH > ratioW) ? ratioW : ratioH;
	
	// Then, do the expansion
	[self setFont:YES];
	
	// Record new origin
	NSPoint newOP = {0, (screenRect.size.height - [_tabView frame].size.height) / 2};
	
	// Set the window style
	[_mainWindow setOpaque:NO];
	_originalWindowBackgroundColor = [_mainWindow backgroundColor];
	[_mainWindow setBackgroundColor:[[WLGlobalConfig sharedInstance] colorBG]];
	
	// Move the origin point
//	[_mainWindow setFrame:screenRect display:YES];
//	[_mainWindow.contentView setFrame:screenRect];
	[_tabView setFrameOrigin:newOP];
}

- (void)windowDidEnterFullScreen:(NSNotification *)notification {
//	
//	// Get the fittest ratio for the expansion
//	NSRect screenRect = [[[NSScreen screens] objectAtIndex:0] frame];
//	NSLog(@"4. %f %f %f %f", screenRect.origin.x, screenRect.origin.y, screenRect.size.height, screenRect.size.width);
////	CGFloat ratioH = screenRect.size.height / [_tabView frame].size.height;
////	CGFloat ratioW = screenRect.size.width / [_tabView frame].size.width;
////	_screenRatio = (ratioH > ratioW) ? ratioW : ratioH;
//	
//	// Record new origin
//	NSPoint newOP = {0, (screenRect.size.height - [_tabView frame].size.height) / 2};
//	
//	// Set the window style
//	[_mainWindow setOpaque:NO];
//	//	[_mainWindow setBackgroundColor:[[WLGlobalConfig sharedInstance] colorBG]];
//	//	[_mainWindow setBackgroundColor:[NSColor redColor]];
//	
//	// Move the origin point
//	//	[_mainWindow setFrame:screenRect display:YES];
//	NSLog(@"5. %f %f %f %f", _mainWindow.frame.origin.x, _mainWindow.frame.origin.y, _mainWindow.frame.size.height, _mainWindow.frame.size.width);
////	[[_mainWindow animator] setFrame:screenRect display:NO];
//	[_mainWindow setFrame:screenRect display:NO];
//	NSLog(@"6. %f %f %f %f", _mainWindow.frame.origin.x, _mainWindow.frame.origin.y, _mainWindow.frame.size.height, _mainWindow.frame.size.width);
//	[_mainWindow.contentView setFrame:screenRect];
//	NSLog(@"7. %f %f %f %f", _mainWindow.frame.origin.x, _mainWindow.frame.origin.y, _mainWindow.frame.size.height, _mainWindow.frame.size.width);
//	[_tabView setFrameOrigin:newOP];
//	NSLog(@"8. %f %f %f %f", _mainWindow.frame.origin.x, _mainWindow.frame.origin.y, _mainWindow.frame.size.height, _mainWindow.frame.size.width);

}

- (void)windowWillExitFullScreen:(NSNotification *)notification {
	[_tabBarControl setHidden:NO];
	
	// Set the size back
	[self setFont:NO];
	
	[_mainWindow setOpaque:YES];
	// Move view back
	[_tabView setFrame:_originalFrame];
	[_mainWindow setBackgroundColor:_originalWindowBackgroundColor];
}

- (void)windowDidExitFullScreen:(NSNotification *)notification {
    [_mainWindow makeKeyAndOrderFront:nil];
}

@end
