//
//  WLMainFrameController+TabControl.m
//  Welly
//
//  Created by K.O.ed on 10-4-30.
//  Copyright 2010 Welly Group. All rights reserved.
//

#import "WLMainFrameController+TabControl.h"

#import "WLTabBarControl.h"
#import "WLTabView.h"
#import "WLConnection.h"
#import "WLSite.h"
#import "WLGlobalConfig.h"

@interface WLMainFrameController ()

- (void)updateEncodingMenu;
- (void)exitPresentationMode;

@end

@implementation WLMainFrameController (TabControl)

- (void)initializeTabControl {
	// tab control style
    [_tabBarControl setCanCloseOnlyTab:YES];
    NSAssert([_tabBarControl delegate] == self, @"set in .nib");
    //show a new-tab button
    [_tabBarControl setShowAddTabButton:YES];
    [[_tabBarControl addTabButton] setTarget:self];
    [[_tabBarControl addTabButton] setAction:@selector(newTab:)];
    //_tabView = (WLTabView *)[_tabBarControl tabView];
	
    // open the portal
    // the switch
    [self tabViewDidChangeNumberOfTabViewItems:_tabView];
	[_tabBarControl setMainController:[self retain]];
}

#pragma mark -
#pragma mark Actions
- (IBAction)newTab:(id)sender {
	// Draw the portal and entering the portal control mode if needed...
	if ([WLGlobalConfig shouldEnableCoverFlow]) {
		[_tabView newTabWithCoverFlowPortal];
	} else {
		[self newConnectionWithSite:[WLSite site]];
		// let user input
		[_mainWindow makeFirstResponder:_addressBar];
	}
}

- (IBAction)selectNextTab:(id)sender {
    [_tabBarControl selectNextTabViewItem:sender];
}

- (IBAction)selectPrevTab:(id)sender {
    [_tabBarControl selectPreviousTabViewItem:sender];
}

- (IBAction)closeTab:(id)sender {
    if ([_tabView numberOfTabViewItems] == 0) return;
	// Here, sometimes it may throw a exception...
	@try {
		[_tabBarControl removeTabViewItem:[_tabView selectedTabViewItem]];
	}
	@catch (NSException * e) {
	}
}

#pragma mark -
#pragma mark TabView delegation
- (BOOL)tabView:(NSTabView *)tabView shouldCloseTabViewItem:(NSTabViewItem *)tabViewItem {
	// Restore from full screen firstly
	[self exitPresentationMode];
	
	// TODO: why not put these in WLTabView?
    if (![[[tabViewItem identifier] content] isKindOfClass:[WLConnection class]] ||
		![[[tabViewItem identifier] content] isConnected]) 
		return YES;
    if (![[NSUserDefaults standardUserDefaults] boolForKey:WLConfirmOnCloseEnabledKeyName]) 
		return YES;
	
    NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Are you sure you want to close this tab?", @"Sheet Title")
									 defaultButton:NSLocalizedString(@"Close", @"Default Button")
								   alternateButton:NSLocalizedString(@"Cancel", @"Cancel Button")
									   otherButton:nil
						 informativeTextWithFormat:NSLocalizedString(@"The connection is still alive. If you close this tab, the connection will be lost. Do you want to close this tab anyway?", @"Sheet Message")];
    if ([alert runModal] == NSAlertDefaultReturn)
        return YES;
    return NO;
}

- (void)tabView:(NSTabView *)tabView willCloseTabViewItem:(NSTabViewItem *)tabViewItem {
    // close the connection
	if ([[[tabViewItem identifier] content] isKindOfClass:[WLConnection class]])
		[[[tabViewItem identifier] content] close];
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
    NSAssert(tabView == _tabView, @"tabView");
	[_addressBar setStringValue:@""];
	if ([[[tabViewItem identifier] content] isKindOfClass:[WLConnection class]]) {
		WLConnection *connection = [[tabViewItem identifier] content];
		WLSite *site = [connection site];
		if (connection && [site address]) {
			[_addressBar setStringValue:[site address]];
			[connection resetMessageCount];
		}
		
		[_mainWindow makeFirstResponder:tabView];
		
		[self updateEncodingMenu];
#define CELLSTATE(x) ((x) ? NSOnState : NSOffState)
		[_detectDoubleByteButton setState:CELLSTATE([site shouldDetectDoubleByte])];
		[_detectDoubleByteMenuItem setState:CELLSTATE([site shouldDetectDoubleByte])];
		[_autoReplyButton setState:CELLSTATE([site shouldAutoReply])];
		[_autoReplyMenuItem setState:CELLSTATE([site shouldAutoReply])];
		[_mouseButton setState:CELLSTATE([site shouldEnableMouse])];
#undef CELLSTATE
	}
}

- (void)tabViewDidChangeNumberOfTabViewItems:(NSTabView *)tabView {
    // all tab closed, no didSelectTabViewItem will happen
    if ([tabView numberOfTabViewItems] == 0) {
        if ([WLGlobalConfig shouldEnableCoverFlow]) {
            [_mainWindow makeFirstResponder:tabView];
        } else {
            [_mainWindow makeFirstResponder:_addressBar];
        }
    }
}

@end
