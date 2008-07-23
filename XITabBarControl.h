//
//  XITabBarControl.h
//  Welly
//
//  Created by boost @ 9# on 7/14/08.
//  Copyright 2008 Xi Wang. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <PSMTabBarControl/PSMTabBarControl.h>

@interface XITabBarControl : PSMTabBarControl
- (void)selectTabViewItemAtIndex:(NSInteger)index;
- (void)selectFirstTabViewItem:(id)sender;
- (void)selectLastTabViewItem:(id)sender;
- (void)selectNextTabViewItem:(id)sender;
- (void)selectPreviousTabViewItem:(id)sender;
@end
