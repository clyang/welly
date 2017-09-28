//
//  WLTabViewItemObjectController.h
//  Welly
//
//  Created by K.O.ed on 10-4-30.
//  Copyright 2010 Welly Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@protocol WLTabBarCellContentProvider;

@interface WLTabViewItemController : NSObjectController {
}
// Get a controller with dummy content
+ (WLTabViewItemController *)emptyTabViewItemController;
- (id)initWithContent:(id)content;
@end
