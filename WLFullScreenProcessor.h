//
//  LLFullScreenProcessor.h
//  Welly
//
//  Created by gtCarrera @ 9# on 08-8-11.
//  Copyright 2008. All rights reserved.
//
#import <Cocoa/Cocoa.h>

// This class is the base class for the full screen processors
@interface WLFullScreenProcessor : NSObject {
}

// A full screen processor shoule have the following methods
// TODO: How can I define them in a C++ style like "pure virtual"?
- (void)processBeforeEnter;
- (void)processBeforeExit;

@end
