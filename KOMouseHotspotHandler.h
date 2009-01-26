//
//  KOMouseHotspotHandler.h
//  Welly
//
//  Created by K.O.ed on 09-1-12.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol KOMouseHotspotHandler
- (void) mouseUp: (NSEvent *)theEvent;
@end

@interface NSResponder (KOMouseHotspotHandler)
- (void) mouseEntered: (NSEvent *)theEvent;
- (void) mouseExited: (NSEvent *)theEvent;
- (void) mouseMoved: (NSEvent *)theEvent;
- (void) cursorUpdate: (NSEvent *)theEvent;
@end