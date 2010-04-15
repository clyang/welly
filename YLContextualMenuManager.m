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
#import "WLTerminal.h"
#import "YLController.h"
#import "WLEmoticonsPanelController.h"
#import "SynthesizeSingleton.h"
#import "Carbon/Carbon.h"

NSString *const WLContextualMenuItemTitleFormatAttributeName = @"Title Format";
NSString *const WLContextualMenuItemURLFormatAttributeName = @"URL Format";
NSString *const WLOpenURLMenuItemFilename = @"OpenURLMenuItems";

@interface YLContextualMenuManager ()
+ (NSString *)extractShortURL:(NSString *)s;
@end

@implementation YLContextualMenuManager
SYNTHESIZE_SINGLETON_FOR_CLASS(YLContextualMenuManager);

@synthesize openURLItemArray = _openURLItemArray;

- (id)init {
	if (self = [super init]) {
		@synchronized(self) {
			// init may be called multiple times, 
			// but there is only one shared instance.
			// So we need to make sure this array have been initialized only once
			if (!_openURLItemArray) {
				_openURLItemArray = [[NSArray arrayWithContentsOfFile:
									  [[NSBundle mainBundle] pathForResource:WLOpenURLMenuItemFilename 
																	  ofType:@"plist"]] copy];
			}
		}
    }
    return self;
}

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

+ (NSMenuItem *)menuItemWithDictionary:(NSDictionary *)dictionary 
							   selectedString:(NSString *)s {
	NSString *title = [NSString stringWithFormat:[dictionary valueForKey:WLContextualMenuItemTitleFormatAttributeName], s, nil];
	NSString *url = [NSString stringWithFormat:[dictionary valueForKey:WLContextualMenuItemURLFormatAttributeName], s, nil];
	NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title 
												   action:@selector(openURL:) 
											keyEquivalent:@""];
	//[item autorelease];
	[item setRepresentedObject:url];
	return item;
}

+ (NSMenu *)menuWithSelectedString:(NSString*)selectedString {
    NSMenu *menu = [[[NSMenu alloc] init] autorelease];

	/* comment: why not just using the url recognition? */
    YLView *view = [[YLController sharedInstance] telnetView];
	
	NSString *shortURL = [self extractShortURL:selectedString];
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
    if ([selectedString length] > 0) {
    
        [menu addItemWithTitle:NSLocalizedString(@"Search in Spotlight", @"Menu")
                        action:@selector(spotlight:)
                 keyEquivalent:@""];

        [menu addItemWithTitle:NSLocalizedString(@"Search in Google", @"Menu")
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
		
		[menu addItemWithTitle:NSLocalizedString(@"Save as Emoticon", @"Menu") 
						action:@selector(saveAsEmoticon:) 
				 keyEquivalent:@""];
		
		if ([[[YLContextualMenuManager sharedInstance] openURLItemArray] count] > 0) {
			// User customized menu items
			[menu addItem:[NSMenuItem separatorItem]];
			
			for (NSObject *obj in [[YLContextualMenuManager sharedInstance] openURLItemArray]) {
				if ([obj isKindOfClass:[NSDictionary class]]) {
					NSMenuItem *item = [YLContextualMenuManager menuItemWithDictionary:(NSDictionary *)obj 
																		selectedString:selectedString];
					[menu addItem:item];
					[item release];
				}
			}
		} /* else {
			NSArray *defaultMenu = [NSArray arrayWithObject:
									[NSDictionary dictionaryWithObjectsAndKeys:
									 @"testEntry", WLContextualMenuItemTitleFormatAttributeName,
									 @"%@", WLContextualMenuItemURLFormatAttributeName, nil]];
			NSString *path = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:WLOpenURLMenuItemFilename] stringByAppendingPathExtension:@"plist"];
			[defaultMenu writeToFile:path atomically:YES];
		} */
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
    NSString *u = [sender representedObject];
	if (!u) {
		u = [sender title];
	}
	if (![u hasPrefix:@"http://"]) {
		u = [@"http://" stringByAppendingString:[u stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	}
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:u]];
	NSLog(@"opening url:%@", u);
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
    YLView *view = [[YLController sharedInstance] telnetView];
    [view copy:sender];
}

+ (IBAction)saveAsEmoticon:(id)sender {
	NSString *s = [sender representedObject];
	[[WLEmoticonsPanelController sharedInstance] addEmoticonFromString:s];
}

@end
