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
#import "KOEffectView.h"

@interface LLTelnetProcessor : LLFullScreenProcessor {
	CGFloat _screenRatio;
	NSRect _viewRect;
	NSView * _myView;
	NSView * _tabView;
	KOEffectView * _effectView;
}

// Constructor
- (id) initByView:(NSView*) view myTabView:(NSView*) tView effectView:(KOEffectView*) eView;
// Private functions to access font sizes
- (void) setFont:(bool)isSet;

// Overrided functions
- (void) processBeforeEnter;
- (void) processBeforeExit;

@end
