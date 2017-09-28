//
//  WLFullScreenProcessor.h
//  Welly
//
//  Created by gtCarrera @ 9# on 08-8-11.
//  Copyright 2008. All rights reserved.
//
#import <Cocoa/Cocoa.h>

// The protocol for the full screen processors
@protocol WLFullScreenProcessor

// A full screen processor shoule have the following methods
- (void)processBeforeEnter;
- (void)processBeforeExit;

@end
