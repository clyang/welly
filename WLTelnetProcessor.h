//
//  LLTelnetProcessor.h
//  Welly
//
//  Created by gtCarrera @ 9# on 08-8-12.
//  Copyright 2008. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WLFullScreenProcessor.h"

@interface WLTelnetProcessor : NSObject <WLFullScreenProcessor> {
	CGFloat _screenRatio;
	NSRect _viewRect;
	NSView *_targetView;
}

// Constructor
- (id)initWithView:(NSView *)view;

@end
