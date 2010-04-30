//
//  WLMainFrameController+TabControl.h
//  Welly
//
//  Created by K.O.ed on 10-4-30.
//  Copyright 2010 Welly Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WLMainFrameController.h"

@interface WLMainFrameController (TabControl)

- (void)initializeTabControl;

- (IBAction)newTab:(id)sender;
- (IBAction)selectNextTab:(id)sender;
- (IBAction)selectPrevTab:(id)sender;
- (IBAction)closeTab:(id)sender;
@end
