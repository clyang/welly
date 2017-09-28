//
//  LLTelnetProcessor.m
//  Welly
//
//  Created by gtCarrera @ 9# on 08-8-12.
//  Copyright 2008. All rights reserved.
//

#import "WLTelnetProcessor.h"
#import "WLGlobalConfig.h"

@implementation WLTelnetProcessor
// Constructor
- (id)initWithView:(NSView *)view {
	if (self = [super init]) {
        _screenRatio = 0.0f;
		_targetView = [view retain];
    }
    return self;
}

@end
