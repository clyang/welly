//
//  YLContextualMenuManager.m
//  MacBlueTelnet
//
//  Created by Lan Yung-Luen on 11/28/07.
//  Copyright 2007 yllan.org. All rights reserved.
//
//  new interface, by boost @ 9#

#import "YLContextualMenuManager.h"
#import "YLView.h"
#import "Carbon/Carbon.h"

/*
@interface YLContextualMenuManager ()
+ (NSString *)extractShortURL:(NSString *)s;
@end

+ (NSString *)extractShortURL:(NSString *)s {
    NSMutableString *result = [NSMutableString string];
    for (int i = 0; i < [s length]; i++) {
        unichar c = [s characterAtIndex: i];
        if (('0' <= c && c <= '9') ||
            ('a' <= c && c <= 'z') ||
            ('A' <= c && c <= 'Z'))
            [result appendString:[NSString stringWithCharacters:&c length:1]];
    }
    return result;
}
*/

@implementation YLContextualMenuManager

+ (NSMenu *)menuWithSelectedString:(NSString*)s {
    NSMenu *menu = [[[NSMenu alloc] init] autorelease];

/* comment: why not just using the url recognition?

    NSString *shortURL = [self extractShortURL:s];
    NSString *longURL = [s stringByReplacingOccurrencesOfString:@"\n" withString:@""];

    if ([[longURL componentsSeparatedByString:@"."] count] > 1) {
        if (![longURL hasPrefix:@"http://"])
            longURL = [@"http://" stringByAppendingString:longURL];
        [menu addItemWithTitle:longURL
                        action:@selector(openURL:)
                 keyEquivalent:@""];
    }
    
    if ([shortURL length] > 0 && [shortURL length] < 8) {
        [menu addItemWithTitle:[@"0rz.tw/" stringByAppendingString: shortURL]
                        action:@selector(openURL:)
                 keyEquivalent:@""];
    
        [menu addItemWithTitle:[@"tinyurl.com/" stringByAppendingString:shortURL]
                        action:@selector(openURL:)
                 keyEquivalent:@""];
    }
*/
    if ([s length] > 0) {
    
        [menu addItemWithTitle:@"Search in Spotlight"
                        action:@selector(spotlight:)
                 keyEquivalent:@""];

        [menu addItemWithTitle:@"Search in Google"
                        action:@selector(google:)
                 keyEquivalent:@""];
        
        [menu addItem:[NSMenuItem separatorItem]];
        
        [menu addItemWithTitle:NSLocalizedString(@"Look Up in Dictionary", @"Menu")
                        action:@selector(lookupDictionary:)
                 keyEquivalent:@""];

        [menu addItem:[NSMenuItem separatorItem]];

        [menu addItemWithTitle:NSLocalizedString(@"Copy", @"Menu")
                        action:@selector(copy:) 
                 keyEquivalent:@""];
    }

    for (int i = 0; i < [menu numberOfItems]; ++i) {
        NSMenuItem *item = [menu itemAtIndex:i];
        if ([item isSeparatorItem])
            continue;
        [item setTarget:self];
        [item setRepresentedObject:s];
    }

    return menu;
}

+ (IBAction)openURL:(id)sender {
    NSString *u = [sender title];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:u]];
}

+ (IBAction)spotlight:(id)sender {
    NSString *u = [sender representedObject];
    HISearchWindowShow((CFStringRef)u, kNilOptions);
}

+ (IBAction)google:(id)sender {
    NSString *u = [sender representedObject];
    u = [@"http://www.google.com/search?q=" stringByAppendingString:[u stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:u]];
}

+ (IBAction)lookupDictionary:(id)sender {
    NSString *u = [sender representedObject];
    NSPasteboard *spb = [NSPasteboard pasteboardWithUniqueName];
    [spb declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
    [spb setString:u forType:NSStringPboardType];
    NSPerformService(@"Look Up in Dictionary", spb);
}

@end
