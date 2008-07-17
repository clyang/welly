//
//  XIQuickLookBridge.m
//  Preview via Quick Look
//
//  Created by boost @ 9# on 7/11/08.
//  Copyright 2008 Xi Wang. All rights reserved.
//

#import "XIQuickLookBridge.h"

// suppress warnings
@interface QLPreviewPanel : NSPanel
+ (id)sharedPreviewPanel;
- (void)close;
- (void)makeKeyAndOrderFrontWithEffect:(int)flag;
- (void)setURLs:(NSArray *)URLs currentIndex:(unsigned)index preservingDisplayState:(BOOL)flag;
@end

@implementation XIQuickLookBridge

+ (id)sharedPanel {
    static QLPreviewPanel *sSharedPanel = nil;
    if (sSharedPanel == nil) {
        // Leopard: "/System/Library/PrivateFrameworks/QuickLookUI.framework"
        [[NSBundle bundleWithPath:@"/System/…/QuickLookUI.framework"] load];
        sSharedPanel = [NSClassFromString(@"QLPreviewPanel") sharedPreviewPanel];
		// To deal with full screen window level
		// Modified by gtCarrera
		//[sSharedPanel setLevel:kCGStatusWindowLevel+1];
		// End
        // for zoom effect
        [[sSharedPanel windowController] setDelegate:[[XIQuickLookBridge alloc] init]];
    }
    return sSharedPanel;
}

+ (XIQuickLookBridge *)sharedInstance {
    return [[[self sharedPanel] windowController] delegate];
}

- (id)init {
    if (self == [super init]) {
        _URLs = [[NSMutableArray arrayWithCapacity: 1] retain];
    }
    return self;
}

- (void)dealloc {
    [_URLs release];
    [super dealloc];
}

// delegate for QLPreviewPanel
// zoom effect from the current mouse coordinates
- (NSRect)previewPanel:(NSPanel*)panel frameForURL:(NSURL*)URL {
	NSRect frame;
    frame.origin = [NSEvent mouseLocation];
    frame.size.width = 1;
    frame.size.height = 1;
    return frame;
}

+ (void)orderFront {
    [[XIQuickLookBridge sharedPanel] makeKeyAndOrderFrontWithEffect:2]; // 2 for zoom effect
}

+ (NSMutableArray *)URLs {
    return [self sharedInstance]->_URLs;
}

+ (void)add:(NSURL *)URL {
    NSMutableArray *URLs = [self URLs];
    // check if the url is already under preview
    unsigned index = [URLs indexOfObject:URL];
    if (index == NSNotFound) {
        [URLs insertObject:URL atIndex:0];
        index = 0;
    }
    // update
    [[self sharedPanel] setURLs:URLs currentIndex:index preservingDisplayState:YES];
    [self orderFront];
}

+ (void)removeAll {
    [[self URLs] removeAllObjects];
    [[self sharedPanel] close];
    // we don't call setURLs here
}

@end
