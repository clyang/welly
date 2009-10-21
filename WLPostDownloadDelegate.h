//
//  WLPostDownloader.h
//  Welly
//
//  Created by K.O.ed on 08-7-21.
//  Copyright 2008 Welly Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class WLTerminal;

@interface WLPostDownloadDelegate : NSObject {
	IBOutlet NSPanel *_postWindow;
	IBOutlet NSTextView *_postText;
}

+ (WLPostDownloadDelegate *)sharedInstance;
+ (NSString *)downloadPostFromTerminal:(WLTerminal *)terminal;

/* post download actions */
- (void)beginPostDownloadInWindow:(NSWindow *)window 
					  forTerminal:(WLTerminal *)terminal;
- (IBAction)cancelPostDownload:(id)sender;

@end
