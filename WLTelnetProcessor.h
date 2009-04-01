//
//  LLTelnetProcessor.h
//  Welly
//
//  Created by gtCarrera @ 9# on 08-8-12.
//  Copyright 2008. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WLFullScreenProcessor.h"
#import "YLLGlobalConfig.h"
#import "WLEffectView.h"
#import "YLView.h"

@interface WLTelnetProcessor : WLFullScreenProcessor {
	BOOL needResetPortal;
	CGFloat _screenRatio;
	NSRect _viewRect;
	YLView *_myView;
	NSView *_tabView;
	WLEffectView *_effectView;
}

// Constructor
- (id)initWithView:(YLView*)view 
		 myTabView:(NSView*)tView 
		effectView:(WLEffectView*)eView;

// Overrided functions
- (void)processBeforeEnter;
- (void)processBeforeExit;
@end
