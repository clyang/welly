//
//  TYComposeDelegate.m
//  Welly
//
//  Created by aqua9 on 17/1/2009.
//  Copyright 2009 TANG Yang. All rights reserved.
//

#import "TYComposeDelegate.h"
#import "YLLGlobalConfig.h"


@implementation TYComposeDelegate

- (void)textViewDidChangeSelection:(NSNotification *)aNotification
{
    NSTextView *textView = [aNotification object];
    NSTextStorage *storage = [textView textStorage];
    int location = [textView selectedRange].location;
    if (location > 0) --location;
    [_bgColorWell setColor:[[YLLGlobalConfig sharedInstance] colorBG]];
    if (location < [storage length]) {
        NSColor *bgColor = [storage attribute:NSBackgroundColorAttributeName
                                      atIndex:location
                               effectiveRange:nil];
        if (bgColor) {
            [_bgColorWell setColor:bgColor];
        }
    }
}

@end
