//
//  XITabBarControl.h
//  Welly
//
//  Created by boost @ 9# on 7/14/08.
//  Copyright 2008 Xi Wang. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <PSMTabBarControl/PSMTabBarControl.h>

@class YLController;
@interface WLTabBarControl : PSMTabBarControl {
	YLController *_currMainController;
}

// select
- (void)selectTabViewItemAtIndex:(NSInteger)index;
- (void)selectFirstTabViewItem:(id)sender;
- (void)selectLastTabViewItem:(id)sender;
- (void)selectNextTabViewItem:(id)sender;
- (void)selectPreviousTabViewItem:(id)sender;

// close
- (void)removeTabViewItem:(NSTabViewItem *)tabViewItem;	

// Set main controller
- (void)setMainController:(YLController *)controller;

@end
