//
//  XIQuickLookBridge.h
//  Preview via Quick Look
//
//  Created by boost @ 9# on 7/11/08.
//  Copyright 2008 Xi Wang. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
@interface WLQuickLookBridge : NSObject <NSComboBoxDataSource> {
#else
@interface WLQuickLookBridge : NSObject {
#endif
    NSMutableArray *_URLs;
    id _panel;
}

+ (void)orderFront;
+ (void)add:(NSURL *)URL;
//+ (void)removeAll;

@end
