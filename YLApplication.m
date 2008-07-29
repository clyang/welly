//
//  YLApplication.m
//  MacBlueTelnet
//
//  Created by Lan Yung-Luen on 11/17/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import "YLApplication.h"
#import "YLController.h"

static NSString *gLeftString, *gRightString;

@implementation YLApplication

+ (void)initialize {
    unichar r = NSRightArrowFunctionKey;
    unichar l = NSLeftArrowFunctionKey;
    gLeftString = [[NSString stringWithCharacters:&l length:1] retain];
    gRightString = [[NSString stringWithCharacters:&r length:1] retain];

    [NSColor setIgnoresAlpha: NO];
}

- (void)sendEvent:(NSEvent *)event {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    if ([event type] == NSKeyDown) {
        if ((([event modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask) && 
            (([event modifierFlags] & NSShiftKeyMask) == NSShiftKeyMask) &&
            [[event charactersIgnoringModifiers] isEqualToString:gRightString] ) {

            event = [NSEvent keyEventWithType:[event type] 
                                     location:[event locationInWindow] 
                                modifierFlags:[event modifierFlags] ^ NSShiftKeyMask
                                    timestamp:[event timestamp] 
                                 windowNumber:[event windowNumber] 
                                      context:[event context] 
                                   characters:gRightString
                  charactersIgnoringModifiers:gRightString 
                                    isARepeat:[event isARepeat] 
                                      keyCode:[event keyCode]];
        } else if ((([event modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask) && 
                    (([event modifierFlags] & NSShiftKeyMask) == NSShiftKeyMask) &&
                    [[event charactersIgnoringModifiers] isEqualToString:gLeftString] ) {
            
            event = [NSEvent keyEventWithType:[event type] 
                                     location:[event locationInWindow] 
                                modifierFlags:[event modifierFlags] ^ NSShiftKeyMask
                                    timestamp:[event timestamp] 
                                 windowNumber:[event windowNumber] 
                                      context:[event context] 
                                   characters:gLeftString
                  charactersIgnoringModifiers:gLeftString 
                                    isARepeat:[event isARepeat] 
                                      keyCode:[event keyCode]];
        } else if (([event modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask && 
                   ([event modifierFlags] & NSAlternateKeyMask) == 0 && 
                   ([event modifierFlags] & NSControlKeyMask) == 0 && 
                   ([event modifierFlags] & NSShiftKeyMask) == 0 && 
                   [[event characters] intValue] > 0 && 
                   [[event characters] intValue] < 10) {
            [_controller selectTabNumber:[[event characters] intValue]];
            event = nil;
        } else if (([event modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask && 
                   ([event modifierFlags] & NSAlternateKeyMask) == 0 && 
                   ([event modifierFlags] & NSControlKeyMask) == 0 && 
                   ([event modifierFlags] & NSShiftKeyMask) == 0 && 
                   [[event characters] isEqualToString:@"r"] &&
                   [[NSUserDefaults standardUserDefaults] boolForKey:@"CommandRHotkey"]) {
            [_controller reconnect:self];
            event = nil;
        } else if (([event modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask && 
                   ([event modifierFlags] & NSAlternateKeyMask) == 0 && 
                   ([event modifierFlags] & NSControlKeyMask) == 0 && 
                   ([event modifierFlags] & NSShiftKeyMask) == 0 && 
                   [[event characters] isEqualToString:@"n"]) {
            [_controller editSites:self];
            event = nil;
        } else if (([event modifierFlags] & NSCommandKeyMask) == 0 && 
                   ([event modifierFlags] & NSAlternateKeyMask) == 0 && 
                   ([event modifierFlags] & NSControlKeyMask) == NSControlKeyMask && 
                   ([event modifierFlags] & NSShiftKeyMask) == 0 && 
                   [[event characters] characterAtIndex:0] == '\t') {
            [_controller selectNextTab:self];
            event = nil;
        }
    }

    if (event)
        [super sendEvent:event];

    [pool release];
}

- (YLController *)controller {
    return _controller;
}

@end
