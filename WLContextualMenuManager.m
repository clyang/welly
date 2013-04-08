//
//  YLContextualMenuManager.m
//  MacBlueTelnet
//
//  Created by Lan Yung-Luen on 11/28/07.
//  Copyright 2007 yllan.org. All rights reserved.
//
//  new interface, by boost @ 9#

#import "WLContextualMenuManager.h"
#import "WLEmoticonsPanelController.h"
#import "SynthesizeSingleton.h"
#import "Carbon/Carbon.h"
#ifdef _DEBUG
#import "WLEncoder.h"
#endif

NSString *const WLContextualMenuItemTitleFormatAttributeName = @"Title Format";
NSString *const WLContextualMenuItemURLFormatAttributeName = @"URL Format";
NSString *const WLOpenURLMenuItemFilename = @"contextualMenuItems";

@implementation WLContextualMenuManager
SYNTHESIZE_SINGLETON_FOR_CLASS(WLContextualMenuManager);

@synthesize openURLItemArray = _openURLItemArray;

- (id)init {
	if (self = [super init]) {
		@synchronized(self) {
			// init may be called multiple times, 
			// but there is only one shared instance.
			// So we need to make sure this array have been initialized only once
			if (!_openURLItemArray) {
				NSBundle *mainBundle = [NSBundle mainBundle];
				NSString *preferredLocalizationName = (NSString *)[[mainBundle preferredLocalizations] objectAtIndex:0];
				_openURLItemArray = [[NSArray arrayWithContentsOfFile:
									  [mainBundle pathForResource:WLOpenURLMenuItemFilename 
														   ofType:@"plist" 
													  inDirectory:nil 
												  forLocalization:preferredLocalizationName]] copy];
			}
		}
    }
    return self;
}

+ (NSMenuItem *)menuItemWithDictionary:(NSDictionary *)dictionary 
						selectedString:(NSString *)s {
	NSString *title = [NSString stringWithFormat:
					   [dictionary valueForKey:WLContextualMenuItemTitleFormatAttributeName],
					   s, nil];
	NSString *url = [NSString stringWithFormat:
					 [dictionary valueForKey:WLContextualMenuItemURLFormatAttributeName], 
					 [s stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], nil];
	NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title 
												  action:@selector(openURL:) 
										   keyEquivalent:@""];
	[item setToolTip:url];
	[item setRepresentedObject:url];
	return [item autorelease];
}

+ (NSMenu *)menuWithSelectedString:(NSString*)selectedString {
    NSMenu *menu = [[[NSMenu alloc] init] autorelease];

	// Remove all '\n' '\r' ' ' from the URL string
	NSString *longURL = [selectedString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	longURL = [longURL stringByReplacingOccurrencesOfString:@"　" withString:@""];
	longURL = [longURL stringByReplacingOccurrencesOfString:@"\r" withString:@""];
	
	if ([[longURL componentsSeparatedByString:@"."] count] > 1) {
		if (![longURL hasPrefix:@"http://"])
			longURL = [@"http://" stringByAppendingString:longURL];
		[menu addItemWithTitle:longURL
						action:@selector(openURL:)
				 keyEquivalent:@""];
	}

    if ([selectedString length] > 0) {
    
        [menu addItemWithTitle:NSLocalizedString(@"Search in Spotlight", @"Menu")
                        action:@selector(spotlight:)
                 keyEquivalent:@""];
        
        [menu addItemWithTitle:NSLocalizedString(@"Look Up in Dictionary", @"Menu")
                        action:@selector(lookupDictionary:)
                 keyEquivalent:@""];

        [menu addItem:[NSMenuItem separatorItem]];
#ifdef _DEBUG
		if ([selectedString length] >= 1) {
			unichar ch = [selectedString characterAtIndex:0];
			if (ch >= 0x007F) {
				unichar u2bCode = [WLEncoder fromUnicode:ch encoding:WLBig5Encoding];
				unichar u2gCode = [WLEncoder fromUnicode:ch encoding:WLGBKEncoding];
				NSString *str = [NSString stringWithFormat:@"%@ : ch = %04x, U2B[ch] = %04x, U2G[ch] = %04x", selectedString, ch, u2bCode, u2gCode];
				[menu addItemWithTitle:str action:@selector(copyCodeInfo:) keyEquivalent:@""];
			}
		}
#endif
		
		if ([[[NSApp keyWindow] firstResponder] respondsToSelector:@selector(copy:)]) {
			NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy", @"Menu") 
														  action:@selector(copy:) 
												   keyEquivalent:@""] autorelease];
			[item setTarget:[[NSApp keyWindow] firstResponder]];
			[menu addItem:item];
		}
				
		[menu addItemWithTitle:NSLocalizedString(@"Save as Emoticon", @"Menu") 
						action:@selector(saveAsEmoticon:) 
				 keyEquivalent:@""];
		
		if ([[[WLContextualMenuManager sharedInstance] openURLItemArray] count] > 0) {
			// User customized menu items
			[menu addItem:[NSMenuItem separatorItem]];
			
			for (NSObject *obj in [[WLContextualMenuManager sharedInstance] openURLItemArray]) {
				if ([obj isKindOfClass:[NSDictionary class]]) {
					NSMenuItem *item = [WLContextualMenuManager menuItemWithDictionary:(NSDictionary *)obj 
																		selectedString:selectedString];
					[menu addItem:item];
				}
			}
		}
    }

    for (int i = 0; i < [menu numberOfItems]; ++i) {
        NSMenuItem *item = [menu itemAtIndex:i];
        if ([item isSeparatorItem])
            continue;
        if ([item target] == nil)
			[item setTarget:self];
        if ([item representedObject] == nil)
			[item setRepresentedObject:selectedString];
    }

    return menu;
}

#ifdef _DEBUG
+ (void)copyCodeInfo:(id)sender {
	NSString *s = [sender title];
	NSPasteboard *pb = [NSPasteboard generalPasteboard];
    NSMutableArray *types = [NSMutableArray arrayWithObject:NSStringPboardType];
    if (!s) s = @"";
    [pb declareTypes:types owner:self];
    [pb setString:s forType:NSStringPboardType];
}
#endif

+ (void)openURL:(id)sender {
    NSString *u = [sender representedObject];
	if (!u) {
		u = [sender title];
	}
	if (![u hasPrefix:@"http://"]) {
		u = [@"http://" stringByAppendingString:[u stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	}
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:u]];
}

+ (void)spotlight:(id)sender {
    NSString *u = [sender representedObject];
    HISearchWindowShow((CFStringRef)u, kNilOptions);
}

+ (void)lookupDictionary:(id)sender {
    NSString *u = [sender representedObject];
    NSPasteboard *spb = [NSPasteboard pasteboardWithUniqueName];
    [spb declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
    [spb setString:u forType:NSStringPboardType];
    NSPerformService(@"Look Up in Dictionary", spb);
}

+ (void)saveAsEmoticon:(id)sender {
	NSString *s = [sender representedObject];
	[[WLEmoticonsPanelController sharedInstance] addEmoticonFromString:s];
}

@end
