//
//  KOClickEntryHotspotHandler.h
//  Welly
//
//  Created by K.O.ed on 09-1-12.
//  Copyright 2009 Welly Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KOMouseHotspotHandler.h"

@class YLView;
@class KOEffectView;

@interface KOClickEntryHotspotHandler : KOMouseHotspotHandler <KOMouseUpHandler, KOUpdatable, KOContextualMenuHandler> {
	int _row;
	NSString *_commandSequence;
}
@end
