//
//  KOClickEntryHotspotHandler.h
//  Welly
//
//  Created by K.O.ed on 09-1-12.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KOMouseHotspotHandler.h"

@class YLView;
@class KOEffectView;

@interface KOClickEntryHotspotHandler : KOMouseHotspotHandler <KOMouseHotspotDelegate> {
	int _row;
	NSString *_commandSequence;
}

- (id) initWithView: (YLView *)view 
			   rect: (NSRect)rect
				row: (int)row;
- (id) initWithView: (YLView *)view 
			   rect: (NSRect)rect 
	commandSequence: (NSString *)commandSequence;

@end
