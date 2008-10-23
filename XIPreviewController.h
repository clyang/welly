//
//  XIPreviewController.h
//  Welly
//
//  Created by boost @ 9# on 7/15/08.
//  Copyright 2008 Xi Wang. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <HMBlkAppKit/HMBlkAppKit.h>

@interface XIPreviewController : NSObject {
}

// This progress bar is restored by gtCarrera
HMBlkProgressIndicator *_indicator;
NSPanel         *_window;

- (IBAction)openPreview:(id)sender;
+ (NSURLDownload *)dowloadWithURL:(NSURL *)URL;

@end
