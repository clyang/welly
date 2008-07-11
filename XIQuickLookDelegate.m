//
//  QuickLookDelegate.m
//  Preview via Quick Look
//
//  Created by boost @ 9# on 7/11/08.
//  Copyright 2008 Xi Wang. All rights reserved.
//

#import "XIQuickLookDelegate.h"

// suppress warnings
@interface QLPreviewPanel: NSPanel
+ (id)sharedPreviewPanel;
- (void)close;
- (BOOL)isOpen;
- (void)makeKeyAndOrderFrontWithEffect:(int)flag;
- (void)setURLs:(NSArray *)URLs currentIndex:(unsigned)index preservingDisplayState:(BOOL)flag;
@end

@implementation XIQuickLookDelegate

static XIQuickLookDelegate *sSharedPanel = nil;
static QLPreviewPanel *sPreview;
// Quick Look
#define QLPreviewPanel NSClassFromString(@"QLPreviewPanel")

+ (id)sharedPanel {
    if (sSharedPanel == nil) {
        // Leopard: "/System/Library/PrivateFrameworks/QuickLookUI.framework"
        [[NSBundle bundleWithPath:@"/System/…/QuickLookUI.framework"] load];
        sPreview = [QLPreviewPanel sharedPreviewPanel];
        sSharedPanel = [[XIQuickLookDelegate alloc] init];
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

- (void)add:(NSURL *)URL {
    // check if the url is already under preview
    unsigned index = [_URLs indexOfObject:URL];
    if (index == NSNotFound) {
        [_URLs insertObject:URL atIndex:0];
        index = 0;
    }
    // update
    [sPreview setURLs:_URLs currentIndex:index preservingDisplayState:YES];
    if (![sPreview isOpen])
        [sPreview makeKeyAndOrderFrontWithEffect:2]; // 2 for zoom effect
}

- (void)removeAll {
    [_URLs removeAllObjects];
    if ([sPreview isOpen])
        [sPreview close];
    // we don't call setURLs here
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


@end
