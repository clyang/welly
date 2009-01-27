//
//  KOMouseHotspotHandler.h
//  Welly
//
//  Created by K.O.ed on 09-1-12.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol KOMouseHotspotDelegate
- (void) mouseUp: (NSEvent *)theEvent;
@end

@class YLView, KOEffectView;
@interface KOMouseHotspotHandler : NSObject {
	NSRect _rect;
	YLView *_view;
	KOEffectView *_effectView;
}

- (id) initWithView: (YLView *)view 
			   rect: (NSRect)rect;
- (void) checkMousePosition;
- (void) mouseEntered: (NSEvent *)theEvent;
@end