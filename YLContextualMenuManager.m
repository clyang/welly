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
#import "YLTerminal.h"
#import "YLController.h"
#import "YLApplication.h"
#import "Carbon/Carbon.h"
#ifdef _DEBUG
#import "encoding.h"
#endif

@interface YLContextualMenuManager ()
+ (NSString *)extractShortURL:(NSString *)s;
@end

@implementation YLContextualMenuManager
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

+ (NSMenu *)menuWithSelectedString:(NSString*)s {
    NSMenu *menu = [[[NSMenu alloc] init] autorelease];

	/* comment: why not just using the url recognition? */
    YLView *view = [[((YLApplication *)NSApp) controller] telnetView];
	
	NSString *shortURL = [self extractShortURL:s];
	// Remove all '\n' '\r' ' ' from the URL string
	NSString *longURL = [s stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	longURL = [longURL stringByReplacingOccurrencesOfString:@"　" withString:@""];
	longURL = [longURL stringByReplacingOccurrencesOfString:@"\r" withString:@""];
	
	if ([[longURL componentsSeparatedByString:@"."] count] > 1) {
		if (![longURL hasPrefix:@"http://"])
			longURL = [@"http://" stringByAppendingString:longURL];
		[menu addItemWithTitle:longURL
						action:@selector(openURL:)
				 keyEquivalent:@""];
	}
#ifdef _DEBUG
	if ([s length] >= 1) {
		unichar ch = [s characterAtIndex:0];
		if (ch >= 0x007F) {
			unichar u2bCode = U2B[ch];
			unichar u2gCode = U2G[ch];
			NSString *str = [NSString stringWithFormat:@"%@ : ch = %04x, U2B[ch] = %04x, U2G[ch] = %04x", s, ch, u2bCode, u2gCode];
			[menu addItemWithTitle:str action:@selector(copyCodeInfo:) keyEquivalent:@""];
		}
	}
#endif
	
	if ([[view frontMostTerminal] bbsType] == WLMaple) {
		// Firebird BBS seldom use these	
		if ([shortURL length] > 0 && [shortURL length] < 8) {
			[menu addItemWithTitle:[@"0rz.tw/" stringByAppendingString:shortURL]
							action:@selector(openURL:)
					 keyEquivalent:@""];
			
			[menu addItemWithTitle:[@"tinyurl.com/" stringByAppendingString:shortURL]
							action:@selector(openURL:)
					 keyEquivalent:@""];
		}
	}
/* */
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
        //if ([item target] == nil)
        [item setTarget:self];
        //if ([item representedObject] == nil)
        [item setRepresentedObject:s];
    }

    return menu;
}

#ifdef _DEBUG
+ (IBAction)copyCodeInfo:(id)sender {
	NSString *s = [sender title];
	NSPasteboard *pb = [NSPasteboard generalPasteboard];
    NSMutableArray *types = [NSMutableArray arrayWithObject:NSStringPboardType];
    if (!s) s = @"";
    [pb declareTypes:types owner:self];
    [pb setString:s forType:NSStringPboardType];
}
#endif

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

+ (IBAction)copy:(id)sender {
    YLView *view = [[((YLApplication *)NSApp) controller] telnetView];
    [view copy:sender];
}

@end
