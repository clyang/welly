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
- (BOOL)isOpen;
- (void)makeKeyAndOrderFrontWithEffect:(int)flag;
- (void)setURLs:(NSArray *)URLs currentIndex:(unsigned)index preservingDisplayState:(BOOL)flag;
@end

@implementation XIQuickLookBridge

static XIQuickLookBridge *sSharedPanel = nil;
static QLPreviewPanel *sPreview;
// Quick Look
#define QLPreviewPanel NSClassFromString(@"QLPreviewPanel")

+ (id)sharedPanel {
    if (sSharedPanel == nil) {
        // Leopard: "/System/Library/PrivateFrameworks/QuickLookUI.framework"
        [[NSBundle bundleWithPath:@"/System/…/QuickLookUI.framework"] load];
        sPreview = [QLPreviewPanel sharedPreviewPanel];
        sSharedPanel = [[XIQuickLookBridge alloc] init];
    }
    return sSharedPanel;
}

- (id)init {
    self = [super init];
    if (self != nil) {
        [[sPreview windowController] setDelegate:self]; // for zoom effect
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

+ (NSMutableArray *)URLs {
    return ((XIQuickLookBridge *)[XIQuickLookBridge sharedPanel])->_URLs;
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
    [sPreview setURLs:URLs currentIndex:index preservingDisplayState:YES];
    if (![sPreview isOpen])
        [sPreview makeKeyAndOrderFrontWithEffect:2]; // 2 for zoom effect
}

+ (void)removeAll {
    [[self URLs] removeAllObjects];
    if ([sPreview isOpen])
        [sPreview close];
    // we don't call setURLs here
}

@end
