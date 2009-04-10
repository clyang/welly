//
//  WLClickEntryHotspotHandler.h
//  Welly
//
//  Created by K.O.ed on 09-1-12.
//  Copyright 2009 Welly Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WLMouseHotspotHandler.h"

@class YLView;
@class WLEffectView;

@interface WLClickEntryHotspotHandler : WLMouseHotspotHandler <WLMouseUpHandler, WLUpdatable, WLContextualMenuHandler> {
	int _row;
}
@end
