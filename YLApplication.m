//
//  YLApplication.m
//  MacBlueTelnet
//
//  Created by Lan Yung-Luen on 11/17/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import "YLApplication.h"
#import "YLController.h"

@implementation YLApplication
@synthesize controller = _controller;

+ (void)initialize {
    [NSColor setIgnoresAlpha:NO];
}

- (void)sendEvent:(NSEvent *)event {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
    if ([event type] == NSKeyDown) {
        if (NO) {
			// do nothing, just for alignment
		} else if (([event modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask && 
				   ([event modifierFlags] & NSAlternateKeyMask) == 0 && 
				   ([event modifierFlags] & NSControlKeyMask) == 0 && 
				   ([event modifierFlags] & NSShiftKeyMask) == 0 && 
				   [[event characters] isEqualToString:@"r"] &&
				   [[NSUserDefaults standardUserDefaults] boolForKey:WLCommandRHotkeyEnabledKeyName]) {
			[_controller reconnect:self];
			event = nil;
		} else if (([event modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask && 
				   ([event modifierFlags] & NSAlternateKeyMask) == 0 && 
				   ([event modifierFlags] & NSControlKeyMask) == 0 && 
				   ([event modifierFlags] & NSShiftKeyMask) == 0 && 
				   [[event characters] isEqualToString:@"n"]) {
			[_controller editSites:self];
			event = nil;
		}
    }

    if (event)
        [super sendEvent:event];

    [pool release];
}
@end
