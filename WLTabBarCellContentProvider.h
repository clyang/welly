//
//  WLTabBarContentProvider.h
//  Welly
//
//  Created by K.O.ed on 10-4-30.
//  Copyright 2010 Welly Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@protocol WLTabBarCellContentProvider

// PSMTabBarControl needs these methods being implemented to provider indicator/icon/count feature
- (BOOL)isProcessing;
- (NSImage *)icon;
- (NSInteger)objectCount;

@end
