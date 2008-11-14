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
#import "YLView.h"

@interface LLTelnetProcessor : LLFullScreenProcessor {
	BOOL needResetPortal;
	CGFloat _screenRatio;
	NSRect _viewRect;
	YLView * _myView;
	NSView * _tabView;
	KOEffectView * _effectView;
}

// Constructor
- (id) initByView:(YLView*) view myTabView:(NSView*) tView effectView:(KOEffectView*) eView;
// Private functions to access font sizes
- (void) setFont:(bool)isSet;

// Overrided functions
- (void) processBeforeEnter;
- (void) processBeforeExit;

@end
