//
//  WLSiteDelegate.h
//  Welly
//
//  Created by K.O.ed on 09-9-29.
//  Copyright 2009 Welly Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define floatWindowLevel kCGStatusWindowLevel+1

@class YLView;
@class WLSite;

@interface WLSiteDelegate : NSObject {
	/* Sites Array */
    NSMutableArray *_sites;
    IBOutlet NSArrayController *_sitesController;
	
	/* Main Window Outlets */
    IBOutlet NSWindow *_mainWindow;
    IBOutlet YLView *_telnetView;
    IBOutlet NSMenuItem *_sitesMenu;
	
	/* Site Panel Outlets */
    IBOutlet NSPanel *_sitesWindow;
    IBOutlet NSTableView *_tableView;
    IBOutlet NSTextField *_siteNameField;
    IBOutlet NSTextField *_siteAddressField;

    IBOutlet NSPopUpButton *_proxyTypeButton;
    IBOutlet NSTextField *_proxyAddressField;
	
    /* Password Window Outlets */
    IBOutlet NSPanel *_passwordWindow;
    IBOutlet NSSecureTextField *_passwordField;
}
@property (readonly) NSArray *sites;

+ (WLSiteDelegate *)sharedInstance;

/* Accessors */
+ (NSArray *)sites;
+ (WLSite *)siteAtIndex:(NSUInteger)index;
- (unsigned)countOfSites;

/* Site Panel Actions */
- (IBAction)connectSite:(id)sender;
- (IBAction)openSitePanel:(id)sender;
- (IBAction)closeSitePanel:(id)sender;
- (IBAction)addCurrentSite:(id)sender;

- (IBAction)proxyTypeDidChange:(id)sender;

/* password window actions */
- (IBAction)openPasswordDialog:(id)sender;
- (IBAction)confirmPassword:(id)sender;
- (IBAction)cancelPassword:(id)sender;

@end
