//
//  YLController.m
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 9/11/07.
//  Copyright 2007 yllan.org. All rights reserved.

//  Modified by boost @ 9# on 7/12/2008.
//  Add support for ordering sites via drag & drop.

#import "YLController.h"
#import "YLTerminal.h"
#import "XIPTY.h"
#import "YLLGlobalConfig.h"
#import "DBPrefsWindowController.h"
#import "YLEmoticon.h"
#import "YLImagePreviewer.h"

// for remote control
#import "AppleRemote.h"
#import "KeyspanFrontRowControl.h"
#import "RemoteControlContainer.h"
#import "MultiClickRemoteBehavior.h"

const NSTimeInterval DEFAULT_CLICK_TIME_DIFFERENCE = 0.25;	// for remote control
#define SiteTableViewDataType @"SiteTableViewDataType"

@interface YLController (Private)
- (BOOL)tabView:(NSTabView *)tabView shouldCloseTabViewItem:(NSTabViewItem *)tabViewItem ;
- (void)tabView:(NSTabView *)tabView willCloseTabViewItem:(NSTabViewItem *)tabViewItem ;
- (void)tabView:(NSTabView *)tabView didCloseTabViewItem:(NSTabViewItem *)tabViewItem ;
@end

@implementation YLController

- (id) init {
	self = [super init];
	// Init...
	isFullScreen = false;
	if (self != nil) {
	}
	return self;
}

- (void) awakeFromNib {
    // Register URL
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(getUrl:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
    
    NSArray *observeKeys = [NSArray arrayWithObjects: @"shouldSmoothFonts", @"showHiddenText", @"messageCount", @"cellWidth", @"cellHeight", 
                            @"chineseFontName", @"chineseFontSize", @"chineseFontPaddingLeft", @"chineseFontPaddingBottom",
                            @"englishFontName", @"englishFontSize", @"englishFontPaddingLeft", @"englishFontPaddingBottom", 
                            @"colorBlack", @"colorBlackHilite", @"colorRed", @"colorRedHilite", @"colorGreen", @"colorGreenHilite",
                            @"colorYellow", @"colorYellowHilite", @"colorBlue", @"colorBlueHilite", @"colorMagenta", @"colorMagentaHilite", 
                            @"colorCyan", @"colorCyanHilite", @"colorWhite", @"colorWhiteHilite", @"colorBG", @"colorBGHilite", nil];
    for (NSString *key in observeKeys)
        [[YLLGlobalConfig sharedInstance] addObserver: self
                                           forKeyPath: key
                                              options: (NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) 
                                              context: NULL];

    // tab control style
    [_tab setCanCloseOnlyTab:YES];
    [_tab setDelegate:self];
    /*// show a new-tab button
    [_tab setShowAddTabButton:YES];*/
    [[_tab addTabButton] setTarget:self];
    [[_tab addTabButton] setAction:@selector(newTab:)];

    /* Trigger the KVO to update the information properly. */
    [[YLLGlobalConfig sharedInstance] setShowHiddenText: [[YLLGlobalConfig sharedInstance] showHiddenText]];
    [[YLLGlobalConfig sharedInstance] setCellWidth: [[YLLGlobalConfig sharedInstance] cellWidth]];
    
    [self loadSites];
    [self updateSitesMenu];
    [self loadEmoticons];

    //[_mainWindow setHasShadow: YES];
    [_mainWindow setOpaque: NO];

    [_mainWindow setFrameAutosaveName: @"wellyMainWindowFrame"];

    if ([[NSUserDefaults standardUserDefaults] boolForKey: @"RestoreConnection"]) 
        [self loadLastConnections];
    
    [NSTimer scheduledTimerWithTimeInterval: 120 target: self selector: @selector(antiIdle:) userInfo: nil repeats: YES];
    [NSTimer scheduledTimerWithTimeInterval: 1 target: self selector: @selector(updateBlinkTicker:) userInfo: nil repeats: YES];

	// set remote control
	//remoteControl = [[AppleRemote alloc] initWithDelegate: self];
	//[remoteControl startListening: self];
	// 1. instantiate the desired behavior for the remote control device
	remoteControlBehavior = [[MultiClickRemoteBehavior alloc] init];	
	
	// 2. configure the behavior
	[remoteControlBehavior setDelegate: self];
	[remoteControlBehavior setClickCountingEnabled: YES];
	[remoteControlBehavior setSimulateHoldEvent: YES];
	[remoteControlBehavior setMaximumClickCountTimeDifference: DEFAULT_CLICK_TIME_DIFFERENCE];
		
	// 3. a Remote Control Container manages a number of devices and conforms to the RemoteControl interface
	//    Therefore you can enable or disable all the devices of the container with a single "startListening:" call.
	RemoteControlContainer* container = [[RemoteControlContainer alloc] initWithDelegate: remoteControlBehavior];
	[container instantiateAndAddRemoteControlDeviceWithClass: [AppleRemote class]];	
	[container instantiateAndAddRemoteControlDeviceWithClass: [KeyspanFrontRowControl class]];
	
	// to give the binding mechanism a chance to see the change of the attribute
	[self setValue: container forKey: @"remoteControl"];
	
	[container startListening: self];
	
	remoteControl = container;
    
    // drag & drop in site view
    [_tableView registerForDraggedTypes:[NSArray arrayWithObject:SiteTableViewDataType] ];
}

- (void) updateSitesMenu {
    int total = [[_sitesMenu submenu] numberOfItems] ;
    int i, j;
	// search the last seperator from the bottom
	for (i = total - 1; i > 0; i--)
		if ([[[_sitesMenu submenu] itemAtIndex: i] isSeparatorItem])
			break;
			
	// then remove all menuitems below it, since we need to refresh the site menus
    for (j = i + 1; j < total; j++) {
        [[_sitesMenu submenu] removeItemAtIndex: i + 1];
    }
    
	// Now add items of site one by one
    for (YLSite *s in _sites) {
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle: [s name] ?: @"" action: @selector(openSiteMenu:) keyEquivalent: @""];
        [menuItem setRepresentedObject: s];
        [[_sitesMenu submenu] addItem: menuItem];
        [menuItem release];
    }
}

- (void) updateEncodingMenu {
    // Update encoding menu status
    NSMenu *m = [_encodingMenuItem submenu];
    int i;
    for (i = 0; i < [m numberOfItems]; i++) {
        NSMenuItem *item = [m itemAtIndex: i];
        [item setState: NSOffState];
    }
	if (![_telnetView frontMostTerminal])
		return;
	YLEncoding currentEncoding = [[_telnetView frontMostTerminal] encoding];
	if (currentEncoding == YLBig5Encoding)
		[[m itemWithTitle: titleBig5] setState: NSOnState];
	if (currentEncoding == YLGBKEncoding)
		[[m itemWithTitle: titleGBK] setState: NSOnState];
}

- (void) updateBlinkTicker: (NSTimer *) t {
    [[YLLGlobalConfig sharedInstance] updateBlinkTicker];
    if ([_telnetView hasBlinkCell])
        [_telnetView setNeedsDisplay: YES];
}

- (void) antiIdle: (NSTimer *) t {
    if (![[NSUserDefaults standardUserDefaults] boolForKey: @"AntiIdle"]) return;
    NSArray *a = [_telnetView tabViewItems];
    for (NSTabViewItem *item in a) {
        id telnet = [item identifier];
        if ([telnet connected] && [telnet lastTouchDate] && [[NSDate date] timeIntervalSinceDate: [telnet lastTouchDate]] >= 119) {
//            unsigned char msg[] = {0x1B, 'O', 'A', 0x1B, 'O', 'B'};
            unsigned char msg[] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
            [telnet sendBytes:msg length:6];
        }
    }
}

- (void) newConnectionWithSite:(YLSite *)site {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

	// Set the view to be focused.
	[_mainWindow makeFirstResponder:_telnetView];

    YLConnection *connection;
    NSTabViewItem *tabViewItem;
    BOOL emptyTab = [_telnetView frontMostConnection] && ([_telnetView frontMostTerminal] == nil);
    if (emptyTab) {
		// reuse the empty tab
        tabViewItem = [_telnetView selectedTabViewItem];
        connection = [tabViewItem identifier];
        [connection setSite:site];
    } else {
        connection = [[[YLConnection alloc] initWithSite:site] autorelease];
        tabViewItem = [[[NSTabViewItem alloc] initWithIdentifier:connection] autorelease];
        // this will invoke tabView:didSelectTabViewItem
        [_telnetView addTabViewItem:tabViewItem];
    }

    // new terminal
    YLTerminal *terminal = [YLTerminal terminalWithView:_telnetView];
    [connection setTerminal:terminal];
	
	// Clear out the terminal
	[terminal clearAll];

    // XIPTY as the default protocol (a proxy)
    XIPTY *protocol = [[XIPTY new] autorelease];
    [connection setProtocol:protocol];
    [protocol setDelegate:connection];
    [protocol connect:[site address]];

    // set the tab label as the site name.
    [tabViewItem setLabel:[site name]];
    // select the item
    [_telnetView selectTabViewItem:tabViewItem];

    /* commented by boost @ 9#
    [self refreshTabLabelNumber: _telnetView];
    */
    [self updateEncodingMenu];
    [_detectDoubleByteButton setState: [[[_telnetView frontMostConnection] site] detectDoubleByte] ? NSOnState : NSOffState];
    [_detectDoubleByteMenuItem setState: [[[_telnetView frontMostConnection] site] detectDoubleByte] ? NSOnState : NSOffState];
	[_autoReplyButton setState: [[[_telnetView frontMostConnection] site] autoReply] ? NSOnState : NSOffState];
	[_autoReplyMenuItem setState: [[[_telnetView frontMostConnection] site] autoReply] ? NSOnState : NSOffState];
	
    [pool release];
}

#pragma mark -
#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqualToString: @"showHiddenText"]) {
        if ([[YLLGlobalConfig sharedInstance] showHiddenText]) 
            [_showHiddenTextMenuItem setState: NSOnState];
        else
            [_showHiddenTextMenuItem setState: NSOffState];        
    } else if ([keyPath isEqualToString: @"messageCount"]) {
        NSDockTile *dockTile = [NSApp dockTile];
        if ([[YLLGlobalConfig sharedInstance] messageCount] == 0) {
            [dockTile setBadgeLabel: nil];
        } else {
            [dockTile setBadgeLabel: [NSString stringWithFormat: @"%d", [[YLLGlobalConfig sharedInstance] messageCount]]];
        }
        [dockTile display];
    } else if ([keyPath isEqualToString: @"shouldSmoothFonts"]) {
        [[[[_telnetView selectedTabViewItem] identifier] terminal] setAllDirty];
        [_telnetView updateBackedImage];
        [_telnetView setNeedsDisplay: YES];
    } else if ([keyPath hasPrefix: @"cell"]) {
        YLLGlobalConfig *config = [YLLGlobalConfig sharedInstance];
        NSRect r = [_mainWindow frame];
        CGFloat topLeftCorner = r.origin.y + r.size.height;

        CGFloat shift = 0.0;

        /* Calculate the toolbar height */
        shift = NSHeight([_mainWindow frame]) - NSHeight([[_mainWindow contentView] frame]) + 22;

        r.size.width = [config cellWidth] * [config column];
        r.size.height = [config cellHeight] * [config row] + shift;
        r.origin.y = topLeftCorner - r.size.height;
        [_mainWindow setFrame: r display: YES animate: NO];
        [_telnetView configure];
        [[[[_telnetView selectedTabViewItem] identifier] terminal] setAllDirty];
        [_telnetView updateBackedImage];
        [_telnetView setNeedsDisplay: YES];
        NSRect tabRect = [_tab frame];
        tabRect.size.width = r.size.width;
        [_tab setFrame: tabRect];
    } else if ([keyPath hasPrefix: @"chineseFont"] || [keyPath hasPrefix: @"englishFont"] || [keyPath hasPrefix: @"color"]) {
        [[YLLGlobalConfig sharedInstance] refreshFont];
        [[[[_telnetView selectedTabViewItem] identifier] terminal] setAllDirty];
        [_telnetView updateBackedImage];
        [_telnetView setNeedsDisplay: YES];
    }
}

#pragma mark -
#pragma mark User Defaults

- (void) loadSites {
    NSArray *array = [[NSUserDefaults standardUserDefaults] arrayForKey: @"Sites"];
    for (NSDictionary *d in array) 
        [self insertObject: [YLSite siteWithDictionary: d] inSitesAtIndex: [self countOfSites]];    
}

- (void) saveSites {
    NSMutableArray *a = [NSMutableArray array];
    for (YLSite *s in _sites)
        [a addObject: [s dictionaryOfSite]];
    [[NSUserDefaults standardUserDefaults] setObject: a forKey: @"Sites"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self updateSitesMenu];
}

- (void) loadEmoticons {
    NSArray *a = [[NSUserDefaults standardUserDefaults] arrayForKey: @"Emoticons"];
    for (NSDictionary *d in a)
        [self insertObject: [YLEmoticon emoticonWithDictionary: d] inEmoticonsAtIndex: [self countOfEmoticons]];
}

- (void) saveEmoticons {
    NSMutableArray *a = [NSMutableArray array];
    for (YLEmoticon *e in _emoticons) 
        [a addObject: [e dictionaryOfEmoticon]];
    [[NSUserDefaults standardUserDefaults] setObject: a forKey: @"Emoticons"];    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) loadLastConnections {
    NSArray *a = [[NSUserDefaults standardUserDefaults] arrayForKey: @"LastConnections"];
    for (NSDictionary *d in a) {
        [self newConnectionWithSite: [YLSite siteWithDictionary: d]];
    }    
}

- (void) saveLastConnections {
    int tabNumber = [_telnetView numberOfTabViewItems];
    int i;
    NSMutableArray *a = [NSMutableArray array];
    for (i = 0; i < tabNumber; i++) {
        id connection = [[_telnetView tabViewItemAtIndex: i] identifier];
        if ([connection terminal]) // not empty tab
            [a addObject: [[connection site] dictionaryOfSite]];
    }
    [[NSUserDefaults standardUserDefaults] setObject: a forKey: @"LastConnections"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark -
#pragma mark Actions
- (IBAction) setDetectDoubleByteAction: (id) sender {
    BOOL ddb = [sender state];
    if ([sender isKindOfClass: [NSMenuItem class]])
        ddb = !ddb;
    [[[_telnetView frontMostConnection] site] setDetectDoubleByte: ddb];
    [_detectDoubleByteButton setState: ddb ? NSOnState : NSOffState];
    [_detectDoubleByteMenuItem setState: ddb ? NSOnState : NSOffState];
}

- (IBAction) setAutoReplyAction: (id) sender {
	BOOL ar = [sender state];
	if ([sender isKindOfClass: [NSMenuItem class]])
		ar = !ar;
	// set the state of the button and menuitem
	[_autoReplyButton setState: ar ? NSOnState : NSOffState];
	[_autoReplyMenuItem setState: ar ? NSOnState : NSOffState];
	if (!ar && ar != [[[_telnetView frontMostConnection] site] autoReply]) {
		// when user is to close auto reply, 
		if ([[[_telnetView frontMostTerminal] autoReplyDelegate] unreadCount] > 0) {
			// we should inform him with the unread messages
			[[[_telnetView frontMostTerminal] autoReplyDelegate] showUnreadMessagesOnTextView: _unreadMessageTextView];
			[_messageWindow makeKeyAndOrderFront: self];
		}
	}
	
	[[[_telnetView frontMostConnection] site] setAutoReply: ar];
}

- (IBAction) closeMessageWindow: (id) sender {
	[_messageWindow orderOut: self];
}

- (IBAction) setEncoding: (id) sender {
    //int index = [[_encodingMenuItem submenu] indexOfItem: sender];
	YLEncoding encoding = YLGBKEncoding;
	if ([[sender title] isEqual: titleGBK])
		encoding = YLGBKEncoding;
	if ([[sender title] isEqual: titleBig5])
		encoding = YLBig5Encoding;
    if ([_telnetView frontMostTerminal]) {
        [[_telnetView frontMostTerminal] setEncoding: encoding];
        [[_telnetView frontMostTerminal] setAllDirty];
        [_telnetView updateBackedImage];
        [_telnetView setNeedsDisplay: YES];
        [self updateEncodingMenu];
    }
}

- (IBAction) newTab: (id) sender {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    YLSite *site = [YLSite site];
    [site setEncoding: [[YLLGlobalConfig sharedInstance] defaultEncoding]];
    [site setDetectDoubleByte:[[YLLGlobalConfig sharedInstance] detectDoubleByte]];
	[site setAutoReply:NO];
	[site setAutoReplyString:defaultAutoReplyString];

    YLConnection *connection = [[[YLConnection alloc] initWithSite:site] autorelease];

    NSTabViewItem *tabItem = [[[NSTabViewItem alloc] initWithIdentifier:connection] autorelease];
    [tabItem setLabel:@"Untitled"];
    [_telnetView addTabViewItem:tabItem];
    [_telnetView selectTabViewItem:tabItem];

    [_mainWindow makeKeyAndOrderFront:self];
    // let user input
	[_telnetView resignFirstResponder];
	[_addressBar becomeFirstResponder];
    
    [pool release];
}

- (IBAction) connect: (id) sender {
	[sender abortEditing];
	[[_telnetView window] makeFirstResponder: _telnetView];
    BOOL ssh = NO;
    
    NSString *name = [sender stringValue];
    if ([[name lowercaseString] hasPrefix: @"ssh://"]) 
        ssh = YES;
//        name = [name substringFromIndex: 6];
    if ([[name lowercaseString] hasPrefix: @"telnet://"])
        name = [name substringFromIndex: 9];
    if ([[name lowercaseString] hasPrefix: @"bbs://"])
        name = [name substringFromIndex: 6];
    
    NSMutableArray *matchedSites = [NSMutableArray array];
    YLSite *s = [YLSite site];
        
    if ([name rangeOfString: @"."].location != NSNotFound) { /* Normal address */        
        for (YLSite *site in _sites) 
            if ([[site address] rangeOfString: name].location != NSNotFound && !(ssh ^ [[site address] hasPrefix: @"ssh://"])) 
                [matchedSites addObject: site];
        if ([matchedSites count] > 0) {
            [matchedSites sortUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey:@"address.length" ascending:YES] autorelease]]];
            s = [[[matchedSites objectAtIndex: 0] copy] autorelease];
        } else {
            [s setAddress: name];
            [s setName: name];
            [s setEncoding: [[YLLGlobalConfig sharedInstance] defaultEncoding]];
            [s setAnsiColorKey: [[YLLGlobalConfig sharedInstance] defaultANSIColorKey]];
            [s setDetectDoubleByte: [[YLLGlobalConfig sharedInstance] detectDoubleByte]];
			[s setAutoReply: NO];
			[s setAutoReplyString: defaultAutoReplyString];
        }
    } else { /* Short Address? */
        for (YLSite *site in _sites) 
            if ([[site name] rangeOfString: name].location != NSNotFound) 
                [matchedSites addObject: site];
        [matchedSites sortUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey:@"name.length" ascending:YES] autorelease]]];
        if ([matchedSites count] == 0) {
            for (YLSite *site in _sites) 
                if ([[site address] rangeOfString: name].location != NSNotFound)
                    [matchedSites addObject: site];
            [matchedSites sortUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey:@"address.length" ascending:YES] autorelease]]];
        } 
        if ([matchedSites count] > 0) {
            s = [[[matchedSites objectAtIndex: 0] copy] autorelease];
        } else {
            [s setAddress: [sender stringValue]];
            [s setName: name];
            [s setEncoding: [[YLLGlobalConfig sharedInstance] defaultEncoding]];
            [s setAnsiColorKey: [[YLLGlobalConfig sharedInstance] defaultANSIColorKey]];
            [s setDetectDoubleByte: [[YLLGlobalConfig sharedInstance] detectDoubleByte]];
			[s setAutoReply: NO];
			[s setAutoReplyString: defaultAutoReplyString];
        }
    }
    [self newConnectionWithSite: s];
    [sender setStringValue: [s address]];
}

- (IBAction) openLocation: (id) sender {
    [_mainWindow makeKeyAndOrderFront: self];
	[_telnetView resignFirstResponder];
	[_addressBar becomeFirstResponder];
}

- (BOOL) shouldReconnect {
	if (![[_telnetView frontMostConnection] connected]) return YES;
    if (![[NSUserDefaults standardUserDefaults] boolForKey: @"ConfirmOnClose"]) return YES;
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

- (void) confirmReconnect:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo {
    if (returnCode == NSAlertDefaultReturn) {
		[[_telnetView frontMostTerminal] resetMessageCount];
		[[_telnetView frontMostConnection] reconnect];
    }
}

- (IBAction) reconnect: (id) sender {
    if (![[_telnetView frontMostConnection] connected] || ![[NSUserDefaults standardUserDefaults] boolForKey: @"ConfirmOnClose"]) {
        [[_telnetView frontMostTerminal] resetMessageCount];
        [[_telnetView frontMostConnection] reconnect];
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

- (IBAction) selectNextTab: (id) sender {
    if ([_telnetView indexOfTabViewItem: [_telnetView selectedTabViewItem]] == [_telnetView numberOfTabViewItems] - 1)
        [_telnetView selectFirstTabViewItem: self];
    else
        [_telnetView selectNextTabViewItem: self];
}

- (IBAction) selectPrevTab: (id) sender {
    if ([_telnetView indexOfTabViewItem: [_telnetView selectedTabViewItem]] == 0)
        [_telnetView selectLastTabViewItem: self];
    else
        [_telnetView selectPreviousTabViewItem: self];
}

- (IBAction) selectTabNumber: (int) index {
    if (index <= [_telnetView numberOfTabViewItems]) {
        [_telnetView selectTabViewItemAtIndex: index - 1];
    }
}

- (IBAction) closeTab: (id) sender {
    if ([_telnetView numberOfTabViewItems] == 0) return;
    
    NSTabViewItem *sel = [_telnetView selectedTabViewItem];
    if ([self tabView:_telnetView shouldCloseTabViewItem:sel]) {
        [self tabView:_telnetView willCloseTabViewItem:sel];
        [_telnetView removeTabViewItem:sel];
    }
}

- (IBAction) editSites: (id) sender {
    [NSApp beginSheet: _sitesWindow
       modalForWindow: _mainWindow
        modalDelegate: nil
       didEndSelector: NULL
          contextInfo: nil];
	[_sitesWindow setLevel:	floatWindowLevel];
}

- (IBAction) openSites: (id) sender {
    NSArray *a = [_sitesController selectedObjects];
    [self closeSites: sender];
    
    if ([a count] == 1) {
        YLSite *s = [a objectAtIndex: 0];
        [self newConnectionWithSite: [[s copy] autorelease]];
    }
}

- (IBAction) openSiteMenu: (id) sender {
    YLSite *s = [sender representedObject];
    [self newConnectionWithSite: s];
}

- (IBAction) closeSites: (id) sender {
    [_sitesWindow endEditingFor: nil];
    [NSApp endSheet: _sitesWindow];
    [_sitesWindow orderOut: self];
    [self saveSites];
}

- (IBAction) addSites: (id) sender {
    if ([_telnetView numberOfTabViewItems] == 0) return;
    NSString *address = [[[_telnetView frontMostConnection] site] address];
    
    for (YLSite *s in _sites) 
        if ([[s address] isEqualToString: address]) 
            return;
    
    YLSite *s = [[[[_telnetView frontMostConnection] site] copy] autorelease];
    [_sitesController addObject: s];
    [_sitesController setSelectedObjects: [NSArray arrayWithObject: s]];
    [self performSelector: @selector(editSites:) withObject: sender afterDelay: 0.1];
    if ([_siteNameField acceptsFirstResponder])
        [_sitesWindow makeFirstResponder: _siteNameField];
}



- (IBAction) showHiddenText: (id) sender {
    BOOL show = ([sender state] == NSOnState);
    if ([sender isKindOfClass: [NSMenuItem class]]) {
        show = !show;
    }

    [[YLLGlobalConfig sharedInstance] setShowHiddenText: show];
    [_telnetView refreshHiddenRegion];
    [_telnetView updateBackedImage];
    [_telnetView setNeedsDisplay: YES];
}

- (IBAction) openPreferencesWindow: (id) sender {
    [[DBPrefsWindowController sharedPrefsWindowController] showWindow:nil];
}

- (IBAction) openEmoticonsWindow: (id) sender {
    [_emoticonsWindow makeKeyAndOrderFront: self];
}

- (IBAction) closeEmoticons: (id) sender {
    [_emoticonsWindow endEditingFor: nil];
    [_emoticonsWindow makeFirstResponder: _emoticonsWindow];
    [_emoticonsWindow orderOut: self];
    [self saveEmoticons];
}

- (IBAction) inputEmoticons: (id) sender {
    [self closeEmoticons: sender];
    
    if ([[_telnetView frontMostConnection] connected]) {
        NSArray *a = [_emoticonsController selectedObjects];
        
        if ([a count] == 1) {
            YLEmoticon *e = [a objectAtIndex: 0];
            [_telnetView insertText: [e content]];
        }
    }
}

#pragma mark -
#pragma mark Accessor
- (NSArray *)sites {
    if (!_sites) {
        _sites = [[NSMutableArray alloc] init];
    }
    return [[_sites retain] autorelease];
}

- (unsigned)countOfSites {
    if (!_sites) {
        _sites = [[NSMutableArray alloc] init];
    }
    return [_sites count];
}

- (id)objectInSitesAtIndex:(unsigned)theIndex {
    if (!_sites) {
        _sites = [[NSMutableArray alloc] init];
    }
    return [_sites objectAtIndex:theIndex];
}

- (void)getSites:(id *)objsPtr range:(NSRange)range {
    if (!_sites) {
        _sites = [[NSMutableArray alloc] init];
    }
    [_sites getObjects:objsPtr range:range];
}

- (void)insertObject:(id)obj inSitesAtIndex:(unsigned)theIndex {
    if (!_sites) {
        _sites = [[NSMutableArray alloc] init];
    }
    [_sites insertObject:obj atIndex:theIndex];
}

- (void)removeObjectFromSitesAtIndex:(unsigned)theIndex {
    if (!_sites) {
        _sites = [[NSMutableArray alloc] init];
    }
    [_sites removeObjectAtIndex:theIndex];
}

- (void)replaceObjectInSitesAtIndex:(unsigned)theIndex withObject:(id)obj {
    if (!_sites) {
        _sites = [[NSMutableArray alloc] init];
    }
}

- (NSArray *)emoticons {
    if (!_emoticons) {
        _emoticons = [[NSMutableArray alloc] init];
    }
    return [[_emoticons retain] autorelease];
}

- (unsigned)countOfEmoticons {
    if (!_emoticons) {
        _emoticons = [[NSMutableArray alloc] init];
    }
    return [_emoticons count];
}

- (id)objectInEmoticonsAtIndex:(unsigned)theIndex {
    if (!_emoticons) {
        _emoticons = [[NSMutableArray alloc] init];
    }
    return [_emoticons objectAtIndex:theIndex];
}

- (void)getEmoticons:(id *)objsPtr range:(NSRange)range {
    if (!_emoticons) {
        _emoticons = [[NSMutableArray alloc] init];
    }
    [_emoticons getObjects:objsPtr range:range];
}

- (void)insertObject:(id)obj inEmoticonsAtIndex:(unsigned)theIndex {
    if (!_emoticons) {
        _emoticons = [[NSMutableArray alloc] init];
    }
    [_emoticons insertObject:obj atIndex:theIndex];
}

- (void)removeObjectFromEmoticonsAtIndex:(unsigned)theIndex {
    if (!_emoticons) {
        _emoticons = [[NSMutableArray alloc] init];
    }
    [_emoticons removeObjectAtIndex:theIndex];
}

- (void)replaceObjectInEmoticonsAtIndex:(unsigned)theIndex withObject:(id)obj {
    if (!_emoticons) {
        _emoticons = [[NSMutableArray alloc] init];
    }
    [_emoticons replaceObjectAtIndex:theIndex withObject:obj];
}

- (IBOutlet) view { return _telnetView; }
- (void) setView: (IBOutlet) o {}

#pragma mark -
#pragma mark Application Delegation
- (BOOL) validateMenuItem: (NSMenuItem *) item {
    SEL action = [item action];
    if ((action == @selector(addSites:) ||
         action == @selector(reconnect:) ||
         action == @selector(selectNextTab:) ||
         action == @selector(selectPrevTab:) )
        && [_telnetView numberOfTabViewItems] == 0) {
        return NO;
    } else if (action == @selector(setEncoding:) && [_telnetView numberOfTabViewItems] == 0) {
        return NO;
    }
    return YES;
}

- (BOOL) applicationShouldHandleReopen: (id) s hasVisibleWindows: (BOOL) b {
    [_mainWindow makeKeyAndOrderFront: self];
    return NO;
} 

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	// Restore from full screen firstly
	if(isFullScreen) {
		isFullScreen = false;
		[self restoreFont:screenRatio];
		[testFSWindow close];
		[orinSuperView addSubview:_telnetView];
	}
    int tabNumber = [_telnetView numberOfTabViewItems];
    int i;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey: @"RestoreConnection"]) 
        [self saveLastConnections];
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey: @"ConfirmOnClose"]) 
        return YES;
    
    BOOL hasConnectedConnetion = NO;
    for (i = 0; i < tabNumber; i++) {
        id connection = [[_telnetView tabViewItemAtIndex: i] identifier];
        if ([connection connected]) 
            hasConnectedConnetion = YES;
    }
    if (!hasConnectedConnetion) return YES;
    NSBeginAlertSheet(NSLocalizedString(@"Are you sure you want to quit Welly?", @"Sheet Title"), 
                      NSLocalizedString(@"Quit", @"Default Button"), 
                      NSLocalizedString(@"Cancel", @"Cancel Button"), 
                      nil, 
                      _mainWindow, self, 
                      @selector(confirmSheetDidEnd:returnCode:contextInfo:), 
                      @selector(confirmSheetDidDismiss:returnCode:contextInfo:), nil, 
                      [NSString stringWithFormat: NSLocalizedString(@"There are %d tabs open in Welly. Do you want to quit anyway?", @"Sheet Message"),
                                tabNumber]);
    return NSTerminateLater;
}

- (void) confirmSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo {
    [[NSUserDefaults standardUserDefaults] synchronize];
    [NSApp replyToApplicationShouldTerminate: (returnCode == NSAlertDefaultReturn)];
}

- (void) confirmSheetDidDismiss:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo {
    [[NSUserDefaults standardUserDefaults] synchronize];
    [NSApp replyToApplicationShouldTerminate: (returnCode == NSAlertDefaultReturn)];
}

#pragma mark -
#pragma mark Window Delegation

- (BOOL) windowShouldClose: (id) window {
    [_mainWindow orderOut: self];
    return NO;
}

- (BOOL) windowWillClose: (id) window {
//    [NSApp terminate: self];
    return NO;
}

- (void) windowDidBecomeKey: (NSNotification *) notification {
    [_closeWindowMenuItem setKeyEquivalentModifierMask: NSCommandKeyMask | NSShiftKeyMask];
    [_closeTabMenuItem setKeyEquivalent: @"w"];
}

- (void) windowDidResignKey: (NSNotification *) notification {
    [_closeWindowMenuItem setKeyEquivalentModifierMask: NSCommandKeyMask];
    [_closeTabMenuItem setKeyEquivalent: @""];
}

- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
	NSString *url = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
	// now you can create an NSURL and grab the necessary parts
    if ([[url lowercaseString] hasPrefix: @"bbs://"])
        url = [url substringFromIndex: 6];
    [_addressBar setStringValue: url];
    [self connect: _addressBar];
}

#pragma mark -
#pragma mark TabView delegation

- (BOOL)tabView:(NSTabView *)tabView shouldCloseTabViewItem:(NSTabViewItem *)tabViewItem {
	// Restore from full screen firstly
	if(isFullScreen) {
		isFullScreen = false;
		[self restoreFont:screenRatio];
		[testFSWindow close];
		[orinSuperView addSubview:tabView];
	}
    if (![[tabViewItem identifier] connected]) return YES;
    if (![[NSUserDefaults standardUserDefaults] boolForKey: @"ConfirmOnClose"]) return YES;
    /* commented out by boost @ 9#: modal makes more sense
    NSBeginAlertSheet(NSLocalizedString(@"Are you sure you want to close this tab?", @"Sheet Title"), 
                      NSLocalizedString(@"Close", @"Default Button"), 
                      NSLocalizedString(@"Cancel", @"Cancel Button"), 
                      nil, 
                      _mainWindow, self, 
                      @selector(didShouldCloseTabViewItem:returnCode:contextInfo:), 
                      NULL, 
                      tabViewItem, 
                      NSLocalizedString(@"The connection is still alive. If you close this tab, the connection will be lost. Do you want to close this tab anyway?", @"Sheet Message"));
    */
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
    [[tabViewItem identifier] close];
}

- (void)tabView:(NSTabView *)tabView didCloseTabViewItem:(NSTabViewItem *)tabViewItem {
    // pass
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
    YLConnection *connection = [tabViewItem identifier];
    [_telnetView updateBackedImage];
    [_addressBar setStringValue: [[connection site] address]];
    [_telnetView setNeedsDisplay: YES];
    [_mainWindow makeFirstResponder: tabView];
	[[connection terminal] resetMessageCount];
    // empty tab
    if (![[[connection site] address] length]) {
        [_telnetView resignFirstResponder];
        [_addressBar becomeFirstResponder];
    }

    [self updateEncodingMenu];
    YLSite *site = [connection site];
    [_detectDoubleByteButton setState: [site detectDoubleByte] ? NSOnState : NSOffState];
    [_detectDoubleByteMenuItem setState: [site detectDoubleByte] ? NSOnState : NSOffState];
    [_autoReplyButton setState: [site autoReply] ? NSOnState : NSOffState];
}

- (BOOL)tabView:(NSTabView *)tabView shouldSelectTabViewItem:(NSTabViewItem *)tabViewItem {
    return YES;
}

- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem {
    id identifier = [tabViewItem identifier];
    [[identifier terminal] setAllDirty];
    [_telnetView clearSelection];
}

/* commented out by boost @ 9#: what the hell are these delegates...

- (BOOL)tabView:(NSTabView*)aTabView shouldDragTabViewItem:(NSTabViewItem *)tabViewItem fromTabBar:(PSMTabBarControl *)tabBarControl {
	return NO;
}

- (BOOL)tabView:(NSTabView*)aTabView shouldDropTabViewItem:(NSTabViewItem *)tabViewItem inTabBar:(PSMTabBarControl *)tabBarControl {
	return YES;
}

- (void)tabView:(NSTabView*)aTabView didDropTabViewItem:(NSTabViewItem *)tabViewItem inTabBar:(PSMTabBarControl *)tabBarControl {
//    [self refreshTabLabelNumber: _telnetView];
}

- (NSImage *)tabView:(NSTabView *)aTabView imageForTabViewItem:(NSTabViewItem *)tabViewItem offset:(NSSize *)offset styleMask:(unsigned int *)styleMask {
    return nil;
}

*/
/* commented out by boost @ 9#: well, not necessary to number sites (is safari doing that)? 

- (void)tabViewDidChangeNumberOfTabViewItems:(NSTabView *)tabView {
    [self refreshTabLabelNumber: tabView];
}

- (void) refreshTabLabelNumber: (NSTabView *) tabView {
    int i, tabNumber;
    tabNumber = [tabView numberOfTabViewItems];
    for (i = 0; i < tabNumber; i++) {
        NSTabViewItem *item = [tabView tabViewItemAtIndex: i];
        [item setLabel: [NSString stringWithFormat: @"%d. %@", i + 1, [[item identifier] connectionName]]];
    }
    
}
*/

#pragma mark -
#pragma mark Compose
/* compose actions */
- (void) prepareCompose: (id) param {
	const int sleepTime = 500000;
	const int maxRounds = 3;
	const int linesPerRound = [[YLLGlobalConfig sharedInstance] row] - 1;
	BOOL isFinished = NO;
	/*
	[[_telnetView frontMostConnection] sendText: @"\023"];
	usleep(sleepTime);
	*/
	[_composeText setString: @""];
	[_composeText setBackgroundColor: [NSColor blackColor]];
	[_composeText setTextColor: [NSColor lightGrayColor]];
	[_composeText setInsertionPointColor: [NSColor whiteColor]];
	for (int i = 0; i < maxRounds && !isFinished; ++i) {
		for (int j = 0; j < linesPerRound; ++j) {
			NSString *nextLine = [[_telnetView frontMostTerminal] stringFromIndex: j * [[YLLGlobalConfig sharedInstance] column] length: [[YLLGlobalConfig sharedInstance] column]] ?: @"";
			if ([nextLine isEqualToString: @"--"]) {
				isFinished = YES;
				break;
			}
			[_composeText setString: [[[_composeText string] stringByAppendingString: nextLine] stringByAppendingString: @"\r"]];
			/*
			[_composeText insertText: nextLine];
			[_composeText insertText: @"\r"];
			*/
		}
		for (int j = 0; j < linesPerRound; ++j)
			[[_telnetView frontMostConnection] sendText: @"\031"];
		usleep(sleepTime);
	}
	[_composeText setString: [[_composeText string] stringByAppendingString: @"--\rgenerated by Welly\r"]];//\030\012"]];
	[_composeText setSelectedRange: NSMakeRange(0, 0)];
	[NSThread exit];
}

- (IBAction) openCompose: (id) sender {
	[NSThread detachNewThreadSelector: @selector(prepareCompose:) toTarget: self withObject: self];
    [NSApp beginSheet: _composeWindow
       modalForWindow: _mainWindow
        modalDelegate: nil
       didEndSelector: NULL
          contextInfo: nil];
}

- (IBAction) commitCompose: (id) sender {
	//[[_telnetView frontMostConnection] sendText: [_composeText string]];
	NSString *escString;
    YLSite *s = [[_telnetView frontMostConnection] site];
    if ([s ansiColorKey] == YLCtrlUANSIColorKey) {
        escString = @"\x15";
    } else if ([s ansiColorKey] == YLEscEscEscANSIColorKey) {
        escString = @"\x1B\x1B";
    } else {
        escString = @"\x1B";
    }
	
	NSFontManager *fontManager = [NSFontManager sharedFontManager];
	NSMutableString *writeBuffer = [NSMutableString string];
	NSTextStorage *storage = [_composeText textStorage];
	NSString *rawString = [storage string];
	BOOL underline, preUnderline = NO;
	BOOL blink, preBlink = NO;
	
	for (int i = 0; i < [storage length]; ++i) {
		char tmp[100] = "";
		// get attributes of i-th character
		
		underline = ([[storage attribute: NSUnderlineStyleAttributeName atIndex: i effectiveRange: nil] intValue] != NSUnderlineStyleNone);
		blink = [fontManager traitsOfFont: [storage attribute: NSFontAttributeName atIndex: i effectiveRange: nil]] & NSBoldFontMask;
		
		/* Add attributes */
		if ((underline != preUnderline) || 
			(blink != preBlink)) {
			strcat(tmp, "[");
			if (underline && !preUnderline) {
				strcat(tmp, "4;");
			}
			if (blink && !preBlink)
				strcat(tmp, "5;");
			strcat(tmp, "m");
			[writeBuffer appendString: escString];
			[writeBuffer appendString: [NSString stringWithCString: tmp]];
			preUnderline = underline;
			preBlink = blink;
		}
		
		// get i-th character
		unichar ch = [rawString characterAtIndex: i];
		
		// write to the buffer
		[writeBuffer appendString: [NSString stringWithCharacters: &ch length: 1]];
	}
	
	[[_telnetView frontMostConnection] sendText: writeBuffer];
	
    [_composeWindow endEditingFor: nil];
	[NSApp endSheet: _composeWindow];
    [_composeWindow orderOut: self];
}

- (IBAction) cancelCompose: (id) sender {
    [_composeWindow endEditingFor: nil];
    [NSApp endSheet: _composeWindow];
    [_composeWindow orderOut: self];
}

- (IBAction) setUnderline: (id) sender {
	NSTextStorage *storage = [_composeText textStorage];
	NSRange selectedRange = [_composeText selectedRange];
	// get the underline style attribute of the first character in the text view
	id underlineStyle = [storage attribute: NSUnderlineStyleAttributeName atIndex: selectedRange.location effectiveRange: nil];
	// if already underlined, then the user is meant to remove the line.
	if ([underlineStyle intValue] == NSUnderlineStyleNone)
		[storage addAttribute: NSUnderlineStyleAttributeName value: [NSNumber numberWithInt: NSUnderlineStyleSingle] range: selectedRange];
	else
		[storage addAttribute: NSUnderlineStyleAttributeName value: [NSNumber numberWithInt: NSUnderlineStyleNone] range: selectedRange];
}

- (IBAction) setBlink: (id) sender {
	NSTextStorage *storage = [_composeText textStorage];
	NSRange selectedRange = [_composeText selectedRange];
	NSFontManager *fontManager = [NSFontManager sharedFontManager];
	// get the bold style attribute of the first character in the text view
	NSFont *font = [storage attribute: NSFontAttributeName atIndex: selectedRange.location effectiveRange: nil];
	NSFontTraitMask traits = [fontManager traitsOfFont: font];
	NSFont *newFont;
	if (traits & NSBoldFontMask)
		newFont = [fontManager convertFont: font toNotHaveTrait: NSBoldFontMask];
	else
		newFont = [fontManager convertFont: font toHaveTrait: NSBoldFontMask];
		
	[storage addAttribute: NSFontAttributeName value: newFont range: [_composeText selectedRange]];
}

#pragma mark -
#pragma mark Post Download
/* Post Download */
- (IBAction) openPostDownload: (id) sender {
	[NSThread detachNewThreadSelector: @selector(preparePostDownload:) toTarget: self withObject: self];
	[NSApp beginSheet: _postWindow
       modalForWindow: _mainWindow
        modalDelegate: nil
       didEndSelector: NULL
          contextInfo: nil];
}

- (IBAction) cancelPostDownload: (id) sender {
    [_postWindow endEditingFor: nil];
    [NSApp endSheet: _postWindow];
    [_postWindow orderOut: self];

}

- (void) preparePostDownload: (id) param {
	const int sleepTime = 10000;
	const int maxRounds = 3000;
	const int linesPerPage = [[YLLGlobalConfig sharedInstance] row] - 1;
	BOOL isFinished = NO;
	[_postText setString: @""];
	[_postText setFont: [NSFont fontWithName: @"Monaco" size: 12]];
	NSString *lastPage[linesPerPage];
	NSString *newPage[linesPerPage];
	
	NSString *bottomLine = [[_telnetView frontMostTerminal] stringFromIndex: linesPerPage * [[YLLGlobalConfig sharedInstance] column] length: [[YLLGlobalConfig sharedInstance] column]] ?: @"";
	NSString *newBottomLine = bottomLine;
	
	NSMutableString *buf = [[NSMutableString alloc] initWithCString: ""];
	
	for (int i = 0; i < maxRounds && !isFinished; ++i) {
		int j = 0, k = 0, lastline = linesPerPage;
		// read in the whole page, and store in 'newPage' array
		for (j = 0; j < linesPerPage; ++j) {
			// read one line
			newPage[j] = [[_telnetView frontMostTerminal] stringFromIndex: j * [[YLLGlobalConfig sharedInstance] column] length: [[YLLGlobalConfig sharedInstance] column]] ?: @"";
			if ([newPage[j] hasPrefix: @"※"]) {	// has post ending symbol
				isFinished = YES;
				lastline = j;
				break;
			}
		}
		if (![bottomLine hasPrefix: @"下面还有喔"]) {
			// bottom line should have this prefix if the post has not ended.
			isFinished = YES;
		}
		
		k = linesPerPage - 1;
		// if it is the last page, we should check if there are duplicated pages
		if (isFinished && i != 0) {
			int jj = j;
			//BOOL stopFlag = false;
			while (j > 0 && jj >= 0) {
				// first, we should locate the last line of last page in the new page.
				// i.e. find a newPage[j] that equals the last line of last page.
				while (j > 0) {
					--j;
					if ([newPage[j] isEqualToString: lastPage[k]])
						break;
				}
				assert(j == 0 || [newPage[j] isEqualToString: lastPage[k]]);
				
				// now check if it is really duplicated
				for (jj = j - 1; jj >= 0; --jj) {
					--k;
					if (![newPage[jj] isEqualToString: lastPage[k]]) {
						// it is not really duplicated by last page effect, but only duplicated by the author of the post
						j = jj;
						k = linesPerPage - 1;
						break;
					}
				}
			}
		} else {
			j = (i == 0) ? -1 : 0; // except the first page, every time page down would lead to the first line duplicated
		}
		
		// Now copy the content into the buffer
		//[buf setString: @""];	// clear out
		for (j = j + 1; j < lastline; ++j) {
			assert(newPage[j]);
			[buf appendFormat: @"%@\r", newPage[j]];
			lastPage[j] = newPage[j];
		}
		
		// copy the buf into the text view.
		[_postText setString: buf];
		if (isFinished)
			break;
		
		// invoke a "page down" command
		[[_telnetView frontMostConnection] sendText: @" "];
		while ([newBottomLine isEqualToString: bottomLine] && i < maxRounds) {
			// wait for the screen to refresh
			usleep(sleepTime);
			newBottomLine = [[_telnetView frontMostTerminal] stringFromIndex: linesPerPage * [[YLLGlobalConfig sharedInstance] column] length: [[YLLGlobalConfig sharedInstance] column]] ?: @"";
			++i;
		}
		bottomLine = newBottomLine;
	}
	//[_postText setString: buf];
	//}
	//[_postText setSelectedRange: NSMakeRange(0, 0)];
	[NSThread exit];
}

#pragma mark -
#pragma mark Remote Control
/* Remote Control */
- (void) remoteButton: (RemoteControlEventIdentifier) buttonIdentifier 
		  pressedDown: (BOOL) pressedDown 
		   clickCount: (unsigned int) clickCount {
	NSString *cmd = nil;

	if (!pressedDown) {	// release
		switch(buttonIdentifier) {
			case kRemoteButtonPlus:		// up
				if (clickCount == 1)
					cmd = termKeyUp;
				else
					cmd = termKeyPageUp;
				break;
			case kRemoteButtonMinus:	// down
				if (clickCount == 1)
					cmd = termKeyDown;
				else
					cmd = termKeyPageDown;
				break;			
			case kRemoteButtonMenu:
				break;
			case kRemoteButtonPlay:
				cmd = termKeyEnter;
				break;			
			case kRemoteButtonRight:	// right
				if (clickCount == 1)
					cmd = termKeyRight;
				else
					cmd = termKeyEnd;
				break;			
			case kRemoteButtonLeft:		// left
				if (clickCount == 1)
					cmd = termKeyLeft;
				else
					cmd = termKeyHome;
				break;			
			case kRemoteButtonPlus_Hold:
				[self disableTimer];
				break;				
			case kRemoteButtonMinus_Hold:
				[self disableTimer];
				break;				
			case kRemoteButtonPlay_Hold:
				break;
		}
	}
	else { // Key Press
		switch(buttonIdentifier) {
			case kRemoteButtonRight_Hold:	// Right Tab
				[_telnetView selectNextTabViewItem: self];
				break;
			case kRemoteButtonLeft_Hold:	// Left Tab
				[_telnetView selectPreviousTabViewItem: self];
				break;
			case kRemoteButtonPlus_Hold:
				// Enable timer!
				[self disableTimer];
				scrollTimer = [[NSTimer scheduledTimerWithTimeInterval:scrollTimerInterval 
									  target:self 
									  selector:@selector(doScrollUp:)
									  userInfo:nil
									  repeats:YES] retain];
				break;
			case kRemoteButtonMinus_Hold:
				// Enable timer!
				[self disableTimer];
				scrollTimer = [[NSTimer scheduledTimerWithTimeInterval:scrollTimerInterval
									  target:self 
									  selector:@selector(doScrollDown:)
									  userInfo:nil
									  repeats:YES] retain];
				break;
			case kRemoteButtonMenu_Hold:
				[self fullScreenHandle];
				break;
		}
	}
	
	if (cmd != nil) {
		[[_telnetView frontMostConnection] sendText: cmd];
	}
}

// For timer
- (void) doScrollDown:(NSTimer*) timer {
	[[_telnetView frontMostConnection] sendText: termKeyDown];
}

- (void) doScrollUp:(NSTimer*) timer {
	[[_telnetView frontMostConnection] sendText: termKeyUp];
}

- (void) disableTimer {
	[scrollTimer invalidate];
	[scrollTimer release];
	scrollTimer = nil;
}

// for bindings access
- (RemoteControl*) remoteControl {
	return remoteControl;
}

- (MultiClickRemoteBehavior*) remoteBehavior {
	return remoteControlBehavior;
}

#pragma mark -
#pragma mark For full screen
- (IBAction) fullScreenMode: (id) sender {
	[self fullScreenHandle];
}

- (void) restoreFont:(CGFloat) ratio {
	if(ratio != 0.0f) {
		[[YLLGlobalConfig sharedInstance] setEnglishFontSize: 
			[[YLLGlobalConfig sharedInstance] englishFontSize] / ratio];
		[[YLLGlobalConfig sharedInstance] setChineseFontSize: 
			[[YLLGlobalConfig sharedInstance] chineseFontSize] / ratio];
		[[YLLGlobalConfig sharedInstance] setCellWidth: 
			[[YLLGlobalConfig sharedInstance] cellWidth] / ratio];
		[[YLLGlobalConfig sharedInstance] setCellHeight: 
			[[YLLGlobalConfig sharedInstance] cellHeight] / ratio];
	}
}

- (void) setFont:(CGFloat) ratio {
	[[YLLGlobalConfig sharedInstance] setEnglishFontSize: 
		[[YLLGlobalConfig sharedInstance] englishFontSize] * screenRatio];
	[[YLLGlobalConfig sharedInstance] setChineseFontSize: 
		[[YLLGlobalConfig sharedInstance] chineseFontSize] * screenRatio];
	[[YLLGlobalConfig sharedInstance] setCellWidth: 
		[[YLLGlobalConfig sharedInstance] cellWidth] * screenRatio];
	[[YLLGlobalConfig sharedInstance] setCellHeight: 
		[[YLLGlobalConfig sharedInstance] cellHeight] * screenRatio];
}

- (void) fullScreenHandle {
	// For full screen!
	if(!isFullScreen) {
		// Set current state
		isFullScreen = true;
		// Calculate the expand ratio
		NSRect screenRect = [[NSScreen mainScreen] frame];
		CGFloat ratioH = screenRect.size.height / [_telnetView frame].size.height;
		CGFloat ratioW = screenRect.size.width / [_telnetView frame].size.width;
		if(ratioH > ratioW && ratioH > screenRatio) {
			screenRatio = ratioW;
		}
		else if(ratioH > screenRatio) {
			screenRatio = ratioH;
		}
		// Do the expandsion
		[self setFont:screenRatio];
		
		// Move the origin point
		NSPoint newOP;
		if([_telnetView frame].size.height < screenRect.size.height) {
			newOP.y += (screenRect.size.height - [_telnetView frame].size.height) / 2;
		}
				
		// Init the window and show
		// int windowLevel = kCGMainMenuWindowLevel;
		// Change UI mode by carbon
		SetSystemUIMode(kUIModeAllHidden, kUIOptionAutoShowMenuBar 
						| kUIOptionDisableProcessSwitch);
		testFSWindow = [[NSWindow alloc] initWithContentRect:screenRect
											styleMask:NSBorderlessWindowMask
											backing:NSBackingStoreBuffered
											defer:NO
											screen:[NSScreen mainScreen]];
		[testFSWindow setOpaque: NO];
		[testFSWindow setBackgroundColor: [[YLLGlobalConfig sharedInstance] colorBG]];
		[testFSWindow makeKeyAndOrderFront:nil];
		//[testFSWindow setLevel:windowLevel];
		// Record superview
		orinSuperView = [_telnetView superview];
		[testFSWindow setContentView: [_telnetView retain]];
		[[testFSWindow contentView] setFrameOrigin:newOP];
		//NSLog(@"New OP x = %f, y = %f \n", newOP.x, newOP.y);
	}
	else {
		// Change the state
		isFullScreen = false;
		// Restore the font settings
		// REMEMBER: Also do it in terminating the app
		[self restoreFont:screenRatio];
		// Close
		[testFSWindow close];
		// Change UI mode by carbon
		SetSystemUIMode(kUIModeNormal, nil);
		// Set the super view back!!!
		// Important!
		[orinSuperView addSubview:_telnetView];
	}
}

#pragma mark -
#pragma mark Site View Drag & Drop
- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard {
    // copy to the pasteboard.
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard declareTypes:[NSArray arrayWithObject:SiteTableViewDataType] owner:self];
    [pboard setData:data forType:SiteTableViewDataType];
    return YES;
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info
                   proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op {
    // don't hover
    if (op == NSTableViewDropOn)
        return NSDragOperationNone;
    return NSDragOperationEvery;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info
        row:(int)row dropOperation:(NSTableViewDropOperation)op {
    NSPasteboard* pboard = [info draggingPasteboard];
    NSData* rowData = [pboard dataForType:SiteTableViewDataType];
    NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
    int dragRow = [rowIndexes firstIndex];
    // move
    NSObject *obj = [_sites objectAtIndex:dragRow];
    [_sitesController insertObject:obj atArrangedObjectIndex:row];
    if (row < dragRow)
        ++dragRow;
    [_sitesController removeObjectAtArrangedObjectIndex:dragRow];
    // done
    return YES;
}

@end
