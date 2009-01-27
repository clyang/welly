//
//  KOIPAddrHotspotHandler.m
//  Welly
//
//  Created by K.O.ed on 09-1-27.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "KOIPAddrHotspotHandler.h"

#import "YLView.h"
#import "YLConnection.h"
#import "KOEffectView.h"

@implementation KOIPAddrHotspotHandler
- (void) mouseEntered: (NSEvent *)theEvent {
	//NSLog(@"mouseEntered: ");
	if([[_view frontMostConnection] connected]) {
		[_effectView drawIPAddrBox:_rect];
	}
}

- (void) mouseExited: (NSEvent *)theEvent {
	//NSLog(@"mouseExited: ");
	[_effectView clearIPAddrBox];
}
@end
