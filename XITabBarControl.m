//
//  XITabBarControl.m
//  Welly
//
//  Created by boost @ 9# on 7/14/08.
//  Copyright 2008 Xi Wang. All rights reserved.
//

#import "XITabBarControl.h"

// double click for new tabs

// suppress warnings
@interface PSMTabBarControl ()
- (id)cellForPoint:(NSPoint)mousePt cellFrame:(NSRect *)cellFrame;
@end

@implementation XITabBarControl

- (void)mouseDown:(NSEvent *)theEvent {
    if ([theEvent clickCount] > 1) {
        NSPoint mousePt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        NSRect cellFrame;
        id cell = [self cellForPoint:mousePt cellFrame:&cellFrame];
        if (!cell) {
            NSLog(@"%@", theEvent);
            NSButton *button = (NSButton *)[self addTabButton];
            [button performClick:button];
        }
    }
    [super mouseDown:theEvent];
}

@end
