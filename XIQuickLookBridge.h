//
//  XIQuickLookBridge.h
//  Preview via Quick Look
//
//  Created by boost @ 9# on 7/11/08.
//  Copyright 2008 Xi Wang. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface XIQuickLookBridge : NSObject {
    NSMutableArray *_URLs; 
}

+ (id)sharedPanel;
+ (void)add:(NSURL *)URL;
+ (void)removeAll;

@end
