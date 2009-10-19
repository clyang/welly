//
//  YLController.h
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 9/11/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WLTabBarControl.h"
#import "WLSite.h"
#import "WLMessageDelegate.h"
#import "WLFullScreenController.h"
#import "WLTelnetProcessor.h"
#import "WLSitesPanelController.h"

#define scrollTimerInterval 0.12

@class YLView, WLTerminal;
@class RemoteControl;
@class MultiClickRemoteBehavior;
@class WLFeedGenerator;

#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_5
@protocol NSTabViewDelegate
@end
#endif

@interface YLController : NSObject <NSTabViewDelegate, WLSitesObserver> {
    /* composeWindow */
    IBOutlet NSTextView *_composeText;
    IBOutlet NSPanel *_composeWindow;
	
    IBOutlet NSWindow *_mainWindow;
    IBOutlet NSPanel *_messageWindow;
    IBOutlet id _addressBar;
    IBOutlet id _detectDoubleByteButton;
    IBOutlet id _autoReplyButton;
    IBOutlet id _mouseButton;

    IBOutlet YLView *_telnetView;
    IBOutlet WLTabBarControl *_tab;
	
	/* Menus */
    IBOutlet NSMenuItem *_detectDoubleByteMenuItem;
    IBOutlet NSMenuItem *_closeWindowMenuItem;
    IBOutlet NSMenuItem *_closeTabMenuItem;
	IBOutlet NSMenuItem *_autoReplyMenuItem;
	
    IBOutlet NSMenuItem *_showHiddenTextMenuItem;
    IBOutlet NSMenuItem *_encodingMenuItem;
	IBOutlet NSMenuItem *_fullScreenMenuItem;
	
	IBOutlet NSMenuItem *_sitesMenu;
	
	/* Message */
	IBOutlet NSTextView *_unreadMessageTextView;

	// Remote Control
	RemoteControl *remoteControl;
	MultiClickRemoteBehavior *remoteControlBehavior;
	
	// Full Screen
	WLFullScreenController* _fullScreenController;
	
	// Timer test
	NSTimer* _scrollTimer;
    
    // RSS feed
    NSThread *_rssThread;
}
@property (readonly) YLView *telnetView;

+ (YLController *)sharedInstance;

- (IBAction)setEncoding:(id)sender;
- (IBAction)setDetectDoubleByteAction:(id)sender;
- (IBAction)setAutoReplyAction:(id)sender;
- (IBAction)setMouseAction:(id)sender;

- (IBAction)newTab:(id)sender;
- (IBAction)connectLocation:(id)sender;
- (IBAction)openLocation:(id)sender;
- (IBAction)selectNextTab:(id)sender;
- (IBAction)selectPrevTab:(id)sender;
- (void)selectTabNumber:(int)index;
- (IBAction)closeTab:(id)sender;
- (IBAction)reconnect:(id)sender;
- (IBAction)showHiddenText:(id)sender;
- (IBAction)openPreferencesWindow:(id)sender;
- (void)newConnectionWithSite:(WLSite *)site;

- (IBAction)openSitePanel:(id)sender;
- (IBAction)addCurrentSite:(id)sender;
- (IBAction)openEmoticonsPanel:(id)sender;
- (IBAction)openComposePanel:(id)sender;

// Message
- (IBAction)closeMessageWindow:(id)sender;


// for bindings access
- (RemoteControl*)remoteControl;
- (MultiClickRemoteBehavior*)remoteBehavior;

// for full screen
- (IBAction)fullScreenMode:(id)sender;

// for Font size
- (IBAction)increaseFontSize:(id)sender;
- (IBAction)decreaseFontSize:(id)sender;

// for timer
- (void)doScrollUp:(NSTimer*)timer;
- (void)doScrollDown:(NSTimer*)timer;
- (void)disableTimer;
/*
// for portal
- (IBAction)browseImage:(id)sender;
- (IBAction)removeSiteImage:(id)sender;
- (void)openPanelDidEnd:(NSOpenPanel *)sheet 
			 returnCode:(int)returnCode 
			contextInfo:(void *)contextInfo;
*/
// for resotre
- (IBAction)restoreSettings:(id)sender;

// for RSS feed
- (IBAction)openRSS:(id)sender;

@end
