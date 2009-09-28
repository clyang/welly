//
//  WLPostDownloader.h
//  Welly
//
//  Created by K.O.ed on 08-7-21.
//  Copyright 2008 Welly Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class WLConnection;
@class YLView;

@interface WLPostDownloadDelegate : NSObject {
	/* post download window */
    IBOutlet NSWindow *_mainWindow;
	
	IBOutlet NSPanel *_postWindow;
	IBOutlet NSTextView *_postText;
	
	IBOutlet YLView *_telnetView;
}

+ (WLPostDownloadDelegate *)sharedInstance;
+ (NSString *)downloadPostFromConnection:(WLConnection *)connection;

/* post download actions */
- (IBAction)openPostDownload:(id)sender;
- (IBAction)cancelPostDownload:(id)sender;

@end
