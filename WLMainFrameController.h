//
//  YLController.h
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 9/11/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WLSitesPanelController.h"

#define scrollTimerInterval 0.12

@class WLTabView;
@class WLFeedGenerator;
@class WLTabBarControl;
@class WLPresentationController;

@class RemoteControl;
@class MultiClickRemoteBehavior;

#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_5
@protocol NSTabViewDelegate
@end
#endif

@interface WLMainFrameController : NSObject <NSTabViewDelegate, WLSitesObserver> {
    /* composeWindow */
    IBOutlet NSTextView *_composeText;
    IBOutlet NSPanel *_composeWindow;
	
    IBOutlet NSWindow *_mainWindow;
    IBOutlet NSPanel *_messageWindow;
    IBOutlet id _addressBar;
    IBOutlet id _detectDoubleByteButton;
    IBOutlet id _autoReplyButton;
    IBOutlet id _mouseButton;

    IBOutlet WLTabView *_tabView;
    IBOutlet WLTabBarControl *_tabBarControl;
	
	/* Menus */
    IBOutlet NSMenuItem *_detectDoubleByteMenuItem;
    IBOutlet NSMenuItem *_closeWindowMenuItem;
    IBOutlet NSMenuItem *_closeTabMenuItem;
	IBOutlet NSMenuItem *_autoReplyMenuItem;
	
    IBOutlet NSMenuItem *_showHiddenTextMenuItem;
    IBOutlet NSMenuItem *_encodingMenuItem;
	IBOutlet NSMenuItem *_presentationModeMenuItem;
	
	IBOutlet NSMenuItem *_sitesMenu;
	
	/* Message */
	IBOutlet NSTextView *_unreadMessageTextView;
	
	// Remote Control
	RemoteControl *_remoteControl;
	MultiClickRemoteBehavior *_remoteControlBehavior;
	NSTimer* _scrollTimer;
	
	// Full Screen
	WLPresentationController *_presentationModeController;
    
    // RSS feed
    NSThread *_rssThread;
	
	// 10.7 Full Screen
	@private
	NSRect _originalFrame;
	CGFloat _screenRatio;
	NSColor *_originalWindowBackgroundColor;
	NSDictionary *_originalSizeParameters;
}
@property (readonly) WLTabView *tabView;

+ (WLMainFrameController *)sharedInstance;

- (IBAction)toggleAutoReply:(id)sender;
- (IBAction)toggleMouseAction:(id)sender;

- (IBAction)connectLocation:(id)sender;
- (IBAction)openLocation:(id)sender;
- (IBAction)reconnect:(id)sender;
- (IBAction)openPreferencesWindow:(id)sender;
- (void)newConnectionWithSite:(WLSite *)site;

- (IBAction)openSitePanel:(id)sender;
- (IBAction)addCurrentSite:(id)sender;
- (IBAction)openEmoticonsPanel:(id)sender;
- (IBAction)openComposePanel:(id)sender;
- (IBAction)downloadPost:(id)sender;

// Message
- (IBAction)closeMessageWindow:(id)sender;

#pragma mark -
#pragma mark Menu:View
- (IBAction)toggleShowsHiddenText:(id)sender;
- (IBAction)toggleDetectDoubleByte:(id)sender;

- (IBAction)increaseFontSize:(id)sender;
- (IBAction)decreaseFontSize:(id)sender;
- (IBAction)togglePresentationMode:(id)sender;

- (IBAction)setEncoding:(id)sender;


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
