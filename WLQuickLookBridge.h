//
//  XIQuickLookBridge.h
//  Preview via Quick Look
//
//  Created by boost @ 9# on 7/11/08.
//  Copyright 2008 Xi Wang. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface WLQuickLookBridge : NSObject {
    pid_t _pid;
    NSMutableArray *_URLs;
    id _panel;
}

+ (void)orderFront;
+ (void)add:(NSURL *)URL;
//+ (void)removeAll;

@end
