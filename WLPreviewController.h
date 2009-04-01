//
//  XIPreviewController.h
//  Welly
//
//  Created by boost @ 9# on 7/15/08.
//  Copyright 2008 Xi Wang. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <HMBlkAppKit/HMBlkAppKit.h>

@interface WLPreviewController : NSObject {
}

- (IBAction)openPreview:(id)sender;
+ (NSURLDownload *)downloadWithURL:(NSURL *)URL;

@end
