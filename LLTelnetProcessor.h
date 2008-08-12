//
//  LLTelnetProcessor.h
//  Welly
//
//  Created by gtCarrera @ 9# on 08-8-12.
//  Copyright 2008. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LLFullScreenProcessor.h"
#import "YLLGlobalConfig.h"

@interface LLTelnetProcessor : LLFullScreenProcessor {
	CGFloat _screenRatio;
	NSView * _myView;
}

// Constructor
- (id) initByView:(NSView*) view;
// Private functions to access font sizes
- (void) setFont:(bool)isSet;

// Overrided functions
- (void) processBeforeEnter;
- (void) processBeforeExit;

@end
