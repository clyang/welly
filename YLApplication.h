//
//  YLApplication.h
//  MacBlueTelnet
//
//  Created by Lan Yung-Luen on 11/17/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class YLController;

@interface YLApplication : NSApplication {
    IBOutlet YLController *_controller;
}
@property (readonly) YLController *controller;
@end
