//
//  YLController.m
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 9/11/07.
//  Copyright 2007 yllan.org. All rights reserved.

#import "WLMainFrameController.h"
#import "WLMainFrameController+RemoteControl.h"
#import "WLMainFrameController+TabControl.h"
#import "WLMainFrameController+FullScreen.h"

// Models
#import "WLConnection.h"
#import "WLSite.h"

// Views
#import "WLTabView.h"

// Panel Controllers
#import "WLSitesPanelController.h"
#import "WLEmoticonsPanelController.h"
#import "WLComposePanelController.h"
#import "WLPostDownloadDelegate.h"
#import "DBPrefsWindowController.h"

// Full Screen
#import "WLPresentationController.h"
#import "WLTelnetProcessor.h"

// Others
#import "WLGlobalConfig.h"
#import "WLAnsiColorOperationManager.h"
#import "WLMessageDelegate.h"

#import "WLNotifications.h"

// for RSS
#import "WLFeedGenerator.h"

// End
#import "SynthesizeSingleton.h"

@interface WLMainFrameController ()
- (void)loadLastConnections;
- (void)updateSitesMenuWithSites:(NSArray *)sites;
- (void)exitPresentationMode;
@end

@implementation WLMainFrameController
@synthesize tabView = _tabView;

SYNTHESIZE_SINGLETON_FOR_CLASS(WLMainFrameController);

- (void)awakeFromNib {
    // Register URL
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(getUrl:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
    
    NSArray *observeKeys = [NSArray arrayWithObjects:@"shouldSmoothFonts", @"showHiddenText", @"messageCount", @"cellWidth", @"cellHeight", @"cellSize",
                            @"chineseFontName", @"chineseFontSize", @"chineseFontPaddingLeft", @"chineseFontPaddingBottom",
                            @"englishFontName", @"englishFontSize", @"englishFontPaddingLeft", @"englishFontPaddingBottom", 
                            @"colorBlack", @"colorBlackHilite", @"colorRed", @"colorRedHilite", @"colorGreen", @"colorGreenHilite",
                            @"colorYellow", @"colorYellowHilite", @"colorBlue", @"colorBlueHilite", @"colorMagenta", @"colorMagentaHilite", 
                            @"colorCyan", @"colorCyanHilite", @"colorWhite", @"colorWhiteHilite", @"colorBG", @"colorBGHilite", nil];
    for (NSString *key in observeKeys)
        [[WLGlobalConfig sharedInstance] addObserver:self
                                           forKeyPath:key
                                              options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) 
                                              context:nil];

	[self initializeTabControl];
    // Trigger the KVO to update the information properly.
    [[WLGlobalConfig sharedInstance] setShowsHiddenText:[[WLGlobalConfig sharedInstance] showsHiddenText]];
    [[WLGlobalConfig sharedInstance] setCellWidth:[[WLGlobalConfig sharedInstance] cellWidth]];

    //[_mainWindow setHasShadow:YES];
    [_mainWindow setOpaque:NO];

    [_mainWindow setFrameAutosaveName:@"wellyMainWindowFrame"];
        
    [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(antiIdle:) userInfo:nil repeats:YES];
    
	[self initializeRemoteControl];
	// FIXME: Remove this controller
	// For full screen, initiallize the full screen controller
	_presentationModeController = [[WLPresentationController alloc] initWithTargetView:_tabView
																	 superView:[_tabView superview] 
																originalWindow:_mainWindow];
	
	// Set up color panel
	[[NSUserDefaults standardUserDefaults] setObject:@"1Welly" forKey:@"NSColorPickerPageableNameListDefaults"];
    WLGlobalConfig *config = [WLGlobalConfig sharedInstance];
	NSColorPanel *colorPanel = [NSColorPanel sharedColorPanel];
    [colorPanel setMode:NSColorListModeColorPanel];
    NSColorList *colorList = [[NSColorList alloc] initWithName:@"Welly"];
    [colorList insertColor:[config colorBlack] key:NSLocalizedString(@"Black", @"Color") atIndex:0];
    [colorList insertColor:[config colorRed] key:NSLocalizedString(@"Red", @"Color") atIndex:1];
    [colorList insertColor:[config colorGreen] key:NSLocalizedString(@"Green", @"Color") atIndex:2];
    [colorList insertColor:[config colorYellow] key:NSLocalizedString(@"Yellow", @"Color") atIndex:3];
    [colorList insertColor:[config colorBlue] key:NSLocalizedString(@"Blue", @"Color") atIndex:4];
    [colorList insertColor:[config colorMagenta] key:NSLocalizedString(@"Magenta", @"Color") atIndex:5];
    [colorList insertColor:[config colorCyan] key:NSLocalizedString(@"Cyan", @"Color") atIndex:6];
    [colorList insertColor:[config colorWhite] key:NSLocalizedString(@"White", @"Color") atIndex:7];
    [colorList insertColor:[config colorBlackHilite] key:NSLocalizedString(@"BlackHilite", @"Color") atIndex:8];
    [colorList insertColor:[config colorRedHilite] key:NSLocalizedString(@"RedHilite", @"Color") atIndex:9];
    [colorList insertColor:[config colorGreenHilite] key:NSLocalizedString(@"GreenHilite", @"Color") atIndex:10];
    [colorList insertColor:[config colorYellowHilite] key:NSLocalizedString(@"YellowHilite", @"Color") atIndex:11];
    [colorList insertColor:[config colorBlueHilite] key:NSLocalizedString(@"BlueHilite", @"Color") atIndex:12];
    [colorList insertColor:[config colorMagentaHilite] key:NSLocalizedString(@"MagentaHilite", @"Color") atIndex:13];
    [colorList insertColor:[config colorCyanHilite] key:NSLocalizedString(@"CyanHilite", @"Color") atIndex:14];
    [colorList insertColor:[config colorWhiteHilite] key:NSLocalizedString(@"WhiteHilite", @"Color") atIndex:15];
    [colorPanel attachColorList:colorList];
	[colorPanel setShowsAlpha:YES];
    [colorList release];
	
    // restore connections
    if ([[NSUserDefaults standardUserDefaults] boolForKey:WLRestoreConnectionKeyName]) 
        [self loadLastConnections];
	
	// Ask window to receive mouseMoved
	[_mainWindow setAcceptsMouseMovedEvents:YES];
	
	// Register as sites observer
	[WLSitesPanelController addSitesObserver:self];
}

#pragma mark -
#pragma mark Update Menus
- (void)updateEncodingMenu {
    // update encoding menu status
    NSMenu *m = [_encodingMenuItem submenu];
    for (int i = 0; i < [m numberOfItems]; i++) {
        NSMenuItem *item = [m itemAtIndex:i];
        [item setState:NSOffState];
    }
    if (![_tabView frontMostTerminal])
        return;
    WLEncoding currentEncoding = [[_tabView frontMostTerminal] encoding];
    if (currentEncoding == WLBig5Encoding)
        [[m itemAtIndex:1] setState:NSOnState];
    if (currentEncoding == WLGBKEncoding)
        [[m itemAtIndex:0] setState:NSOnState];
}

- (void)updateSitesMenuWithSites:(NSArray *)sites {
	// Update Sites Menus
	int total = [[_sitesMenu submenu] numberOfItems];
    int i = total - 1;
    // search the last seperator from the bottom
    for (; i > 0; i--)
        if ([[[_sitesMenu submenu] itemAtIndex:i] isSeparatorItem])
            break;
	
    // then remove all menuitems below it, since we need to refresh the site menus
    ++i;
    for (int j = i; j < total; j++) {
        [[_sitesMenu submenu] removeItemAtIndex:i];
    }
    
    // Now add items of site one by one
    for (WLSite *s in sites) {
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[s name] ?: @"" action:@selector(openSiteMenu:) keyEquivalent:@""];
        [menuItem setRepresentedObject:s];
        [[_sitesMenu submenu] addItem:menuItem];
        [menuItem release];
    }	
}

- (void)sitesDidChanged:(NSArray *)sitesAfterChange {
	[self updateSitesMenuWithSites:sitesAfterChange];
}

- (void)antiIdle:(NSTimer *)timer {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"AntiIdle"]) 
		return;
    NSArray *a = [_tabView tabViewItems];
    for (NSTabViewItem *item in a) {
        WLConnection *connection = [[item identifier] content];
        if ([connection isKindOfClass:[WLConnection class]] &&
            [connection isConnected] &&
            [connection lastTouchDate] &&
            [[NSDate date] timeIntervalSinceDate:[connection lastTouchDate]] >= 119) {
//            unsigned char msg[] = {0x1B, 'O', 'A', 0x1B, 'O', 'B'};
            unsigned char msg[] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
            [connection sendBytes:msg length:6];
        }
    }
}

- (void)newConnectionWithSite:(WLSite *)site {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    WLConnection *connection = [[WLConnection alloc] initWithSite:site];
	
	[_tabView newTabWithConnection:connection label:[site name]];
	// We can release it since it is retained by the tab view item
	[connection release];
	// Set the view to be focused.
	[_mainWindow makeFirstResponder:[_tabView frontMostView]];
	
    [self updateEncodingMenu];
    [_detectDoubleByteButton setState:[site shouldDetectDoubleByte] ? NSOnState : NSOffState];
    [_detectDoubleByteMenuItem setState:[site shouldDetectDoubleByte] ? NSOnState : NSOffState];
    [_autoReplyButton setState:[site shouldAutoReply] ? NSOnState : NSOffState];
    [_autoReplyMenuItem setState:[site shouldAutoReply] ? NSOnState : NSOffState];
    [_mouseButton setState:[site shouldEnableMouse] ? NSOnState : NSOffState];

    [pool release];
}

#pragma mark -
#pragma mark KVO
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"showHiddenText"]) {
        if ([[WLGlobalConfig sharedInstance] showsHiddenText]) 
            [_showHiddenTextMenuItem setState:NSOnState];
        else
            [_showHiddenTextMenuItem setState:NSOffState];        
    } else if ([keyPath isEqualToString:@"messageCount"]) {
        NSDockTile *dockTile = [NSApp dockTile];
        if ([[WLGlobalConfig sharedInstance] messageCount] == 0) {
            [dockTile setBadgeLabel:nil];
        } else {
            [dockTile setBadgeLabel:[NSString stringWithFormat:@"%d", [[WLGlobalConfig sharedInstance] messageCount]]];
        }
        [dockTile display];
    } else if ([keyPath isEqualToString:@"shouldSmoothFonts"]) {
    } else if ([keyPath hasPrefix:@"cell"]) {
        WLGlobalConfig *config = [WLGlobalConfig sharedInstance];
        NSRect r = [_mainWindow frame];
        CGFloat topLeftCorner = r.origin.y + r.size.height;

        CGFloat shift = 0.0;

        // Calculate the toolbar height
        shift = NSHeight([_mainWindow frame]) - NSHeight([[_mainWindow contentView] frame]) + 22;

        r.size.width = [config cellWidth] * [config column];
        r.size.height = [config cellHeight] * [config row] + shift;
        r.origin.y = topLeftCorner - r.size.height;
        [_mainWindow setFrame:r display:YES animate:NO];

		// Leave the task of resizing subviews to autoresizing
        //NSRect tabRect = [_tabBarControl frame];
        //tabRect.size.width = r.size.width;
        //[_tabBarControl setFrame:tabRect];
    } else if ([keyPath hasPrefix:@"chineseFont"] || [keyPath hasPrefix:@"englishFont"] || [keyPath hasPrefix:@"color"]) {
        [[WLGlobalConfig sharedInstance] refreshFont];
    }
}

#pragma mark -
#pragma mark User Defaults
- (void)loadLastConnections {
    NSArray *a = [[NSUserDefaults standardUserDefaults] arrayForKey:@"LastConnections"];
    for (NSDictionary *d in a) {
        [self newConnectionWithSite:[WLSite siteWithDictionary:d]];
    }    
}

- (void)saveLastConnections {
    int tabNumber = [_tabView numberOfTabViewItems];
    int i;
    NSMutableArray *a = [NSMutableArray array];
    for (i = 0; i < tabNumber; i++) {
        id connection = [[[_tabView tabViewItemAtIndex:i] identifier] content];
        if ([connection isKindOfClass:[WLConnection class]] && ![[connection site] isDummy]) // not empty tab
            [a addObject:[[connection site] dictionaryOfSite]];
    }
    [[NSUserDefaults standardUserDefaults] setObject:a forKey:@"LastConnections"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark -
#pragma mark Actions
- (IBAction)toggleDetectDoubleByte:(id)sender {
    BOOL ddb = [sender state];
    if ([sender isKindOfClass:[NSMenuItem class]])
        ddb = !ddb;
    [[[_tabView frontMostConnection] site] setShouldDetectDoubleByte:ddb];
    [_detectDoubleByteButton setState:(ddb ? NSOnState : NSOffState)];
    [_detectDoubleByteMenuItem setState:(ddb ? NSOnState : NSOffState)];
}

- (IBAction)toggleAutoReply:(id)sender {
	BOOL ar = [sender state];
	if ([sender isKindOfClass: [NSMenuItem class]])
		ar = !ar;
	// set the state of the button and menuitem
	[_autoReplyButton setState: ar ? NSOnState : NSOffState];
	[_autoReplyMenuItem setState: ar ? NSOnState : NSOffState];
	if (!ar && ar != [[[_tabView frontMostConnection] site] shouldAutoReply]) {
		// when user is to close auto reply, 
		if ([[[_tabView frontMostConnection] messageDelegate] unreadCount] > 0) {
			// we should inform him with the unread messages
			[[[_tabView frontMostConnection] messageDelegate] showUnreadMessagesOnTextView:_unreadMessageTextView];
			[_messageWindow makeKeyAndOrderFront:self];
		}
	}
	
	[[[_tabView frontMostConnection] site] setShouldAutoReply:ar];
}

- (IBAction)toggleMouseAction:(id)sender {
	if (![_tabView frontMostConnection])
		return;
	
    BOOL state = [sender state];
    if ([sender isKindOfClass:[NSMenuItem class]])
        state = !state;
    [_mouseButton setState:(state ? NSOnState : NSOffState)];
	
	[[[_tabView frontMostConnection] site] setShouldEnableMouse:state];

	// Post a notification to inform observers the site has changed the mouse enable preference
	[[NSNotificationCenter defaultCenter] postNotificationName:WLNotificationSiteDidChangeShouldEnableMouse
														object:self];
}

- (IBAction)toggleShowsHiddenText:(id)sender {
    BOOL show = ([sender state] == NSOnState);
    if ([sender isKindOfClass:[NSMenuItem class]]) {
        show = !show;
    }
	
	[_showHiddenTextMenuItem setState:show];
    [[WLGlobalConfig sharedInstance] setShowsHiddenText:show];
}

- (IBAction)closeMessageWindow:(id)sender {
	[_messageWindow orderOut: self];
}

- (IBAction)setEncoding:(id)sender {
    if ([_tabView frontMostConnection]) {
		WLEncoding encoding = WLGBKEncoding;
		if ([[sender title] rangeOfString:@"GBK"].location != NSNotFound)
			encoding = WLGBKEncoding;
		if ([[sender title] rangeOfString:@"Big5"].location != NSNotFound)
			encoding = WLBig5Encoding;
		
        [[[_tabView frontMostConnection] site] setEncoding:encoding];
		[[NSNotificationCenter defaultCenter] postNotificationName:WLNotificationSiteDidChangeEncoding 
															object:self];
        [self updateEncodingMenu];
    }
}

- (IBAction)connectLocation:(id)sender {
	[sender abortEditing];
	[[_tabView window] makeFirstResponder:_tabView];
    BOOL ssh = NO;
    
    NSString *name = [sender stringValue];
    if ([[name lowercaseString] hasPrefix:@"ssh://"]) 
        ssh = YES;
//        name = [name substringFromIndex: 6];
    if ([[name lowercaseString] hasPrefix:@"telnet://"])
        name = [name substringFromIndex: 9];
    if ([[name lowercaseString] hasPrefix:@"bbs://"])
        name = [name substringFromIndex: 6];
    
    NSMutableArray *matchedSites = [NSMutableArray array];
    WLSite *s;
	NSArray *sites = [WLSitesPanelController sites];
        
    if ([name rangeOfString:@"."].location != NSNotFound) { /* Normal address */        
        for (WLSite *site in sites) 
            if ([[site address] rangeOfString:name].location != NSNotFound && !(ssh ^ [[site address] hasPrefix:@"ssh://"])) 
                [matchedSites addObject:site];
        if ([matchedSites count] > 0) {
            [matchedSites sortUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"address.length" ascending:YES] autorelease]]];
            s = [[[matchedSites objectAtIndex:0] copy] autorelease];
        } else {
            s = [WLSite site];
            [s setAddress:name];
            [s setName:name];
        }
    } else { /* Short Address? */
        for (WLSite *site in sites) 
            if ([[site name] rangeOfString:name].location != NSNotFound) 
                [matchedSites addObject:site];
        [matchedSites sortUsingDescriptors: [NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"name.length" ascending:YES] autorelease]]];
        if ([matchedSites count] == 0) {
            for (WLSite *site in sites) 
                if ([[site address] rangeOfString:name].location != NSNotFound)
                    [matchedSites addObject:site];
            [matchedSites sortUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"address.length" ascending:YES] autorelease]]];
        } 
        if ([matchedSites count] > 0) {
            s = [[[matchedSites objectAtIndex:0] copy] autorelease];
        } else {
            s = [WLSite site];
            [s setAddress:[sender stringValue]];
            [s setName:name];
        }
    }
    [self newConnectionWithSite:s];
    [sender setStringValue:[s address]];
}

- (IBAction)openLocation:(id)sender {
    [_mainWindow makeFirstResponder:_addressBar];
}

- (IBAction)openSitePanel:(id)sender {
	[[WLSitesPanelController sharedInstance] openSitesPanelInWindow:_mainWindow];
}

- (IBAction)addCurrentSite:(id)sender {
    if ([_tabView numberOfTabViewItems] == 0) return;
    NSString *address = [[[_tabView frontMostConnection] site] address];
    
    for (WLSite *s in [WLSitesPanelController sites])
        if ([[s address] isEqualToString:address]) 
            return;
    
    WLSite *site = [[_tabView frontMostConnection] site];
    [[WLSitesPanelController sharedInstance] openSitesPanelInWindow:_mainWindow 
														 andAddSite:site];
}

- (IBAction)openEmoticonsPanel:(id)sender {
    [[WLEmoticonsPanelController sharedInstance] openEmoticonsPanel];
}

// Open compose panel
- (IBAction)openComposePanel:(id)sender {
	if ([[_tabView frontMostView] conformsToProtocol:@protocol(NSTextInput)])
		[[WLComposePanelController sharedInstance] openComposePanelInWindow:_mainWindow 
																	forView:(NSView <NSTextInput>*)[_tabView frontMostView]];
}

// Download Post
- (IBAction)downloadPost:(id)sender {
	[[WLPostDownloadDelegate sharedInstance] beginPostDownloadInWindow:_mainWindow 
														   forTerminal:[_tabView frontMostTerminal]];
}

- (BOOL)shouldReconnect {
	if (![[_tabView frontMostConnection] isConnected]) return YES;
    if (![[NSUserDefaults standardUserDefaults] boolForKey:WLConfirmOnCloseEnabledKeyName]) return YES;
    NSBeginAlertSheet(NSLocalizedString(@"Are you sure you want to reconnect?", @"Sheet Title"), 
                      NSLocalizedString(@"Confirm", @"Default Button"), 
                      NSLocalizedString(@"Cancel", @"Cancel Button"), 
                      nil, 
                      _mainWindow, self, 
                      @selector(confirmSheetDidEnd:returnCode:contextInfo:), 
                      @selector(confirmSheetDidDismiss:returnCode:contextInfo:), 
                      nil, 
                      NSLocalizedString(@"The connection is still alive. If you reconnect, the current connection will be lost. Do you want to reconnect anyway?", @"Sheet Message"));
    return NO;
}

- (void)confirmReconnect:(NSWindow *)sheet 
			  returnCode:(int)returnCode 
			 contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertDefaultReturn) {
		[[_tabView frontMostConnection] reconnect];
    }
}

- (IBAction)reconnect:(id)sender {
    if (![[_tabView frontMostConnection] isConnected] || ![[NSUserDefaults standardUserDefaults] boolForKey:WLConfirmOnCloseEnabledKeyName]) {
		[[_tabView frontMostConnection] reconnect];
        return;
    }
    NSBeginAlertSheet(NSLocalizedString(@"Are you sure you want to reconnect?", @"Sheet Title"), 
                      NSLocalizedString(@"Confirm", @"Default Button"), 
                      NSLocalizedString(@"Cancel", @"Cancel Button"), 
                      nil, 
                      _mainWindow, self, 
                      @selector(confirmReconnect:returnCode:contextInfo:), 
                      nil, 
                      nil, 
                      NSLocalizedString(@"The connection is still alive. If you reconnect, the current connection will be lost. Do you want to reconnect anyway?", @"Sheet Message"));
    return;	
}

- (IBAction)openSiteMenu:(id)sender {
    WLSite *s = [sender representedObject];
    [self newConnectionWithSite:s];
}

- (IBAction)openPreferencesWindow:(id)sender {
    [[DBPrefsWindowController sharedPrefsWindowController] showWindow:nil];
}

#pragma mark -
#pragma mark Application Delegation
- (BOOL)validateAction:(SEL)action {
	if (action == @selector(addCurrentSite:) ||
        action == @selector(reconnect:) ||
		action == @selector(setEncoding:)) {
		if (![_tabView frontMostConnection] ||
			[[[_tabView frontMostConnection] site] isDummy])
			return NO;
	} else if (action == @selector(selectNextTab:) ||
			   action == @selector(selectPrevTab:)) {
		if ([_tabView numberOfTabViewItems] == 0)
			return NO;
	} else if (action == @selector(toggleMouseAction:) ||
			   action == @selector(downloadPost:) ||
			   action == @selector(openComposePanel:)) {
		if (![_tabView frontMostConnection] ||
			![[_tabView frontMostConnection] isConnected]) {
			return NO;
		}
	} else if (action == @selector(togglePresentationMode:)) {
		if ([self isInFullScreenMode] && !_presentationModeController.isInPresentationMode) {
			return NO;
		} else
			return YES;
	} else if (action == @selector(increaseFontSize:) ||
			   action == @selector(decreaseFontSize:)) {
		if ([self isInFullScreenMode] || _presentationModeController.isInPresentationMode) {
			return NO;
		} else
			return YES;
	}
	
    return YES;
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem {
	// TODO: this is not working. We need to set the toolbar items' enable or not manually.
	return [self validateAction:[theItem action]];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	return [self validateAction:[menuItem action]];
}

- (BOOL)applicationShouldHandleReopen:(id)s 
					hasVisibleWindows:(BOOL)b {
    [_mainWindow makeKeyAndOrderFront:self];
    return NO;
} 

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	// Restore from presentation mode firstly
	[self exitPresentationMode];
	// Exit from full screen mode if necessary
	if ([self isInFullScreenMode]) {
		[_mainWindow toggleFullScreen:self];
	}
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:WLRestoreConnectionKeyName]) 
        [self saveLastConnections];
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:WLConfirmOnCloseEnabledKeyName]) 
        return YES;
    
    int tabNumber = [_tabView numberOfTabViewItems];
	int connectedConnection = 0;
    for (int i = 0; i < tabNumber; i++) {
        id connection = [[[_tabView tabViewItemAtIndex:i] identifier] content];
        if ([connection isKindOfClass:[WLConnection class]] && [connection isConnected])
            ++connectedConnection;
    }
    if (connectedConnection == 0) return YES;
    NSBeginAlertSheet(NSLocalizedString(@"Are you sure you want to quit Welly?", @"Sheet Title"), 
                      NSLocalizedString(@"Quit", @"Default Button"), 
                      NSLocalizedString(@"Cancel", @"Cancel Button"), 
                      nil, 
                      _mainWindow,
					  self, 
                      @selector(confirmSheetDidEnd:returnCode:contextInfo:), 
                      @selector(confirmSheetDidDismiss:returnCode:contextInfo:), nil, 
                      [NSString stringWithFormat:NSLocalizedString(@"There are %d tabs open in Welly. Do you want to quit anyway?", @"Sheet Message"),
                                connectedConnection]);
    return NSTerminateLater;
}

- (void)confirmSheetDidEnd:(NSWindow *)sheet 
				returnCode:(int)returnCode 
			   contextInfo:(void *)contextInfo {
    [[NSUserDefaults standardUserDefaults] synchronize];
    [NSApp replyToApplicationShouldTerminate:(returnCode == NSAlertDefaultReturn)];
}

- (void)confirmSheetDidDismiss:(NSWindow *)sheet
					returnCode:(int)returnCode 
				   contextInfo:(void *)contextInfo {
    [[NSUserDefaults standardUserDefaults] synchronize];
    [NSApp replyToApplicationShouldTerminate:(returnCode == NSAlertDefaultReturn)];
}

#pragma mark -
#pragma mark Window Delegation
- (BOOL)windowShouldClose:(id)window {
    [_mainWindow orderOut:self];
    return NO;
}

- (void)windowWillClose:(id)window {
//    [NSApp terminate: self];
    //return NO;
}

- (void)windowDidBecomeKey:(NSNotification *)notification {
	// TODO:[_telnetView deactivateMouseForKeying];
    [_closeWindowMenuItem setKeyEquivalentModifierMask:NSCommandKeyMask|NSShiftKeyMask];
    [_closeTabMenuItem setKeyEquivalent:@"w"];
}

- (void)windowDidResignKey:(NSNotification *)notification {
    [_closeWindowMenuItem setKeyEquivalentModifierMask:NSCommandKeyMask];
    [_closeTabMenuItem setKeyEquivalent:@""];
}

- (void)getUrl:(NSAppleEventDescriptor *)event 
withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
	NSString *url = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
	// now you can create an NSURL and grab the necessary parts
    if ([[url lowercaseString] hasPrefix:@"bbs://"])
        url = [url substringFromIndex:6];
    [_addressBar setStringValue:url];
    [self connectLocation:_addressBar];
}


#pragma mark -
#pragma mark For View Menu
// Here is an example to the newly designed full screen module with a customized processor
// A "processor" here will resize the NSViews and do some necessary work before full
// screen
- (IBAction)increaseFontSize:(id)sender {
	[_tabView increaseFontSize:sender];
}

- (IBAction)decreaseFontSize:(id)sender {
	[_tabView decreaseFontSize:sender];
}

- (IBAction)togglePresentationMode:(id)sender {
	[_presentationModeController togglePresentationMode];
	[_presentationModeMenuItem setTitle:
	 _presentationModeController.isInPresentationMode ? NSLocalizedString(@"Exit Presentation Mode", "Presentation Mode") : NSLocalizedString(@"Enter Presentation Mode", "Presentaion Mode")];
}

- (void)exitPresentationMode {
	[_presentationModeController exitPresentationMode];
}

#pragma mark -
#pragma mark For restore settings
- (IBAction)restoreSettings:(id)sender {
	NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Are you sure you want to restore all your font settings?", @"Sheet Title")
									 defaultButton:NSLocalizedString(@"Confirm", @"Default Button")
								   alternateButton:NSLocalizedString(@"Cancel", @"Cancel Button")
									   otherButton:nil
						 informativeTextWithFormat:NSLocalizedString(@"If you proceed, you will lost all your current font settings for Welly, and this operation is only encouraged when your font settings are missing. Are you sure you want to continue?", @"Sheet Message")];
	if ([alert runModal] != NSAlertDefaultReturn)
		return;
	
	// Set the font settings
	[[WLGlobalConfig sharedInstance] restoreSettings];
	[_mainWindow center];
}

#pragma mark -
#pragma mark For RSS feed
- (IBAction)openRSS:(id)sender {
    NSBeginAlertSheet(@"Sorry, RSS mode is not available yet.",
                      nil,
                      nil,
                      nil,
                      _mainWindow,
                      self,
                      nil,
                      nil,
                      nil,
                      @"Please pay attention to our future versions. Thanks for your cooperation.");
    return;
    // TODO: uncomment the following code to enable RSS mode.
    if (![_tabView frontMostConnection] || ![[_tabView frontMostConnection] isConnected]) return;
    if (!_rssThread) {
        [NSThread detachNewThreadSelector:@selector(fetchFeed) toTarget:self withObject:nil];
        NSBeginAlertSheet(@"Welly is now working in RSS mode. (Experimental)",
                          @"Leave RSS mode",
                          nil,
                          nil,
                          _mainWindow,
                          self,
                          @selector(rssSheetDidClose:returnCode:contextInfo:),
                          nil,
                          nil,
                          @"In this mode, Welly automatically fetches data and generates RSS feed. To leave, click the button below.\r\rCaution: This feature is very unstable, and works only with SMTH BBS. Try it at your own risk!");
    }
}

- (void)rssSheetDidClose:(NSWindow *)sheet
              returnCode:(int)returnCode
             contextInfo:(void *)contextInfo {
    if (_rssThread) {
        [[_rssThread threadDictionary] setValue:[NSNumber numberWithBool:YES] forKey:@"ThreadShouldExitNow"];
        _rssThread = nil;
    }
}

- (void)fetchFeed {
	/*
    // FIXME: lots of HARDCODE here
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    BOOL exitNow = NO;
    _rssThread = [NSThread currentThread];
    NSMutableDictionary *threadDict = [_rssThread threadDictionary];
    [threadDict setValue:[NSNumber numberWithBool:exitNow] forKey:@"ThreadShouldExitNow"];
    WLConnection *connection = [_telnetView frontMostConnection];
    WLTerminal *terminal = [connection terminal];
    unsigned int column = [terminal maxColumn];
    unsigned int row = [terminal maxRow];
    NSString *siteName = [[connection site] name];
    // locate the cache directory
    NSString *cacheDir = [WLGlobalConfig cacheDirectory];
    NSString *fileName = [[cacheDir stringByAppendingPathComponent:@"rss"] stringByAppendingPathExtension:@"xml"];
    WLFeedGenerator *feedGenerator = [[WLFeedGenerator alloc] initWithSiteName:siteName];
    BOOL isFirstLoop = YES;
    const useconds_t rssInterval = 300000000;
    const useconds_t refreshInterval = 1000;
    while (!exitNow) {
        [connection sendText:termKeyLeft];
        [connection sendText:termKeyLeft];
        [connection sendText:termKeyLeft];
        [connection sendText:termKeyLeft];
        [connection sendText:termKeyLeft];
        [connection sendText:termKeyLeft];
        [connection sendText:termKeyLeft];
        [connection sendText:termKeyLeft];
        [connection sendText:termKeyLeft];
        [connection sendText:termKeyLeft];
        [connection sendText:@"f"];
        [connection sendText:termKeyRight];
        while (!exitNow) { // traverse every board
            NSString *unreadKeyword;
            while (![[terminal stringFromIndex:0 length:1] isEqualToString:@"["] || [terminal cursorColumn] != 1
                   || [terminal stringFromIndex:column * [terminal cursorRow] + 10 length:1]
                   || ![terminal stringFromIndex:column * [terminal cursorRow] length:column]
                   || !(unreadKeyword = [terminal stringFromIndex:column * [terminal cursorRow] + 8 length:2])
                   || !([unreadKeyword isEqualToString:@"◆"] || [unreadKeyword isEqualToString:@"◇"] || [unreadKeyword isEqualToString:@"＋"]))
                usleep(refreshInterval);
            while ([unreadKeyword isEqualToString:@"＋"]) {
                [connection sendText:termKeyDown];
                while (![terminal stringFromIndex:column * [terminal cursorRow] length:column]
                       || !(unreadKeyword = [terminal stringFromIndex:column * [terminal cursorRow] + 8 length:2]))
                    usleep(refreshInterval);
            }
            if (![unreadKeyword isEqualToString:@"◆"]) {
                // no more unread boards
                // NSLog(@"end because unreadKeyword is %@, cursorY is %u, cursorX is %u, whole line is {%@}", unreadKeyword, [terminal cursorY], [terminal cursorX], [terminal stringFromIndex:column * [terminal cursorY] length:column]);
                break;
            }
            [connection sendText:termKeyRight];
            [connection sendText:termKeyEnd];
            [connection sendText:termKeyEnd]; // in case of seeing board memo
            while ([[terminal stringFromIndex:column length:column] rangeOfString:@"发表"].location == NSNotFound || [terminal cursorColumn] != 1
                || ![terminal stringFromIndex:column * [terminal cursorRow] + 10 length:1])
                usleep(refreshInterval);
            BOOL isLastArticle = YES;
            for (;;) { // traverse every post
                exitNow = [[threadDict valueForKey:@"ThreadShouldExitNow"] boolValue];
                if (exitNow)
                    break;
                while (![terminal stringFromIndex:column * [terminal cursorRow] length:6])
                    usleep(refreshInterval);
                NSString *articleFlag = [terminal stringFromIndex:column * [terminal cursorRow] + 7 length:2];
                if (!articleFlag || [articleFlag rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"*MGBUO"]].location == NSNotFound) {
                    // no more unread articles
                    // NSLog(@"break because articleFlag is %@, cursorY is %u, cursorX is %u, +10 is %@, whole line is {%@}", articleFlag, [terminal cursorY], [terminal cursorX], [terminal stringFromIndex:column * [terminal cursorY] + 10 length:1], [terminal stringFromIndex:column * [terminal cursorY] length:column]);
                    break;
                }
                BOOL isOriginal = ([[terminal stringFromIndex:column * [terminal cursorRow] length:column] rangeOfString:@"●"].location != NSNotFound);
                if (isOriginal || isLastArticle) {
                    isLastArticle = NO;
                    [connection sendText:termKeyRight];
                    NSString *moreModeKeyword;
                    while ([terminal cursorRow] != row - 1 || !(moreModeKeyword = [terminal stringFromIndex:column * (row - 1) length:2])
                           || [moreModeKeyword isEqualToString:@"时"])
                        usleep(refreshInterval);
                    if (isOriginal) {
                        while (![[terminal stringFromIndex:6 length:2] isEqualToString:@":"]
                               || ![[terminal stringFromIndex:column * 2 + 6 length:2] isEqualToString:@":"])
                            usleep(refreshInterval);
                        int offset = ([[terminal stringFromIndex:column + 6 length:1] isEqualToString:@":"]) ? 0 : column; // in case of long nick + long board name
                        NSString *title = [terminal stringFromIndex:column + 8 + offset length:column - 8];
                        NSMutableString *description = [NSMutableString stringWithCapacity:column * (row - 4)];
                        for (int i = 4; i < row - 1; ++i) {
                            NSString *nextLine = [terminal stringFromIndex:column * i length:column];
                            if ([nextLine isEqualToString:@"--"] || [nextLine hasPrefix:@"【 "] || [nextLine hasPrefix:@"※ "]) {
                                break;
                            }
                            if (nextLine) {
                                [description appendString:nextLine];
                                [description appendString:@"<br />"];
                            }
                        }
                        [description replaceOccurrencesOfString:@"<br />" 
                                                     withString:@"" 
                                                        options:(NSBackwardsSearch | NSAnchoredSearch) 
                                                          range:NSMakeRange(0, [description length])];
                        if ([moreModeKeyword isEqualToString:@"下"])
                            [description appendFormat:@"<br />......"];
                        NSString *author = [terminal stringFromIndex:8 length:column - 8];
                        NSString *boardName = offset ? [terminal stringFromIndex:column length:column] 
                                                     : [author substringFromIndex:[author rangeOfString:@" " options:NSBackwardsSearch].location + 1];
                        author = [author substringToIndex:[author rangeOfString:@" "].location];
                        NSString *thirdLine;
                        while (!(thirdLine = [terminal stringFromIndex:column * 2 + 8 + offset length:column - 8]))
                            usleep(refreshInterval);
                        const NSUInteger openParenthesisLocation = [thirdLine rangeOfString:@"("].location;
                        NSString *dayOfWeek = [thirdLine substringWithRange:NSMakeRange(openParenthesisLocation + 1, 3)];
                        NSString *month = [thirdLine substringWithRange:NSMakeRange(openParenthesisLocation + 5, 3)];
                        NSString *day = [thirdLine substringWithRange:NSMakeRange(openParenthesisLocation + 9, 2)];
                        NSString *time = [thirdLine substringWithRange:NSMakeRange(openParenthesisLocation + 12, 8)];
                        NSString *year = [thirdLine substringWithRange:NSMakeRange(openParenthesisLocation + 21, 4)];
                        NSString *pubDate = [NSString stringWithFormat:@"%@, %@ %@ %@ %@ +0800", dayOfWeek, day, month, year, time];
                        if (!boardName || !title || !dayOfWeek || !day || !month || !year || !time) { // assert
                            // exception: assertion failed
                            NSLog(@"Exception in fetchFeed: not-nil assertion failed. %@#%@#%@#%@#%@#%@#%@#%u#%@\n%@\n%@\n%@\n%@", boardName, title, dayOfWeek, day, month, year, time, openParenthesisLocation, thirdLine,
                                  [terminal stringFromIndex:0 length:column], [terminal stringFromIndex:column length:column],
                                  [terminal stringFromIndex:column * 2 length:column], [terminal stringFromIndex:column * 4 length:column]);
                            [[_rssThread threadDictionary] setValue:[NSNumber numberWithBool:YES] forKey:@"ThreadShouldExitNow"];
                            break;
                        }
                        [feedGenerator addItemWithTitle:[[[@"[" stringByAppendingString:boardName] stringByAppendingString:@"] "] stringByAppendingString:title]
                                            description:description
                                                 author:author
                                                pubDate:pubDate];
                    }
                    if ([moreModeKeyword isEqualToString:@"下"]) {
                        [connection sendText:termKeyLeft];
                    }
                    [connection sendText:termKeyLeft];
                    while (![[terminal stringFromIndex:column * (row - 1) length:4] isEqualToString:@"时间"] || [terminal cursorColumn] != 1)
                        usleep(refreshInterval);
                }
                const unsigned int previousY = [terminal cursorRow];
                [connection sendText:termKeyUp];
                while ([terminal cursorRow] == previousY || [terminal cursorColumn] != 1 || ![terminal stringFromIndex:column * [terminal cursorRow] length:column])
                    usleep(refreshInterval);
            }
            [connection sendText:termKeyLeft];
        }
        [feedGenerator writeFeedToFile:fileName];
        if (isFirstLoop) {
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[@"feed:" stringByAppendingString:[[NSURL fileURLWithPath:fileName] absoluteString]]]];
            isFirstLoop = NO;
        }
        if (!exitNow)
            usleep(rssInterval);
        exitNow = [[threadDict valueForKey:@"ThreadShouldExitNow"] boolValue];
    }
    [feedGenerator release];
    [pool drain];
	 */
}

// for portal
/*
- (IBAction)browseImage:(id)sender {
	[_sitesWindow setLevel:0];
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel beginSheetForDirectory:@"~"
								 file:nil
								types:[NSArray arrayWithObjects:@"jpg", @"jpeg", @"bmp", @"png", @"gif", @"tiff", @"tif", nil]
					   modalForWindow:_sitesWindow
						modalDelegate:self
					   didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
						  contextInfo:nil];
	//[openPanel setLevel:floatWindowLevel + 1];
}

- (void)removeImage {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	// Get the destination dir
	NSString *destination = [[[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"]
								stringByAppendingPathComponent:@"Application Support"]
							   stringByAppendingPathComponent:@"Welly"]
							  stringByAppendingPathComponent:@"Covers"]
							 stringByAppendingPathComponent:[_siteNameField stringValue]];
	
	// For all allowed types
	NSArray *allowedTypes = supportedCoverExtensions;
	for (NSString *ext in allowedTypes) {
		// Remove it!
		[fileManager removeItemAtPath:[destination stringByAppendingPathExtension:ext] error:NULL];
	}
}

- (IBAction)removeSiteImage:(id)sender {
	[_sitesWindow setAlphaValue:0];
	NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Are you sure you want to delete the cover?", @"Sheet Title")
									 defaultButton:NSLocalizedString(@"Delete", @"Default Button")
								   alternateButton:NSLocalizedString(@"Cancel", @"Cancel Button")
									   otherButton:nil
						 informativeTextWithFormat:NSLocalizedString(@"Welly will delete this cover file, please confirm.", @"Sheet Message")];
	if ([alert runModal] == NSAlertDefaultReturn)
		[self removeImage];
	[_sitesWindow setAlphaValue:100];
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet
			 returnCode:(int)returnCode
			contextInfo:(void *)contextInfo {
	if (returnCode == NSOKButton) {
		NSString *source = [sheet filename];
		NSString *siteName = [_siteNameField stringValue];
		[_telnetView addPortalImage:source forSite:siteName];
	}
}
*/

@end
