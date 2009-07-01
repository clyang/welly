//
//  XIQuickLookBridge.m
//  Preview via Quick Look
//
//  Created by boost @ 9# on 7/11/08.
//  Copyright 2008 Xi Wang. All rights reserved.
//

#import "WLQuickLookBridge.h"

// suppress warnings
@interface QLPreviewPanel : NSPanel
+ (id)sharedPreviewPanel;
- (void)close;
- (void)makeKeyAndOrderFrontWithEffect:(int)flag;
- (void)setURLs:(NSArray *)URLs currentIndex:(unsigned)index preservingDisplayState:(BOOL)flag;
- (void)setEnableDragNDrop:(BOOL)flag;
@end


@implementation WLQuickLookBridge

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
        [[sSharedPanel windowController] setDelegate:[[WLQuickLookBridge alloc] init]];
        [sSharedPanel setEnableDragNDrop:YES];
    }
    return sSharedPanel;
}

+ (WLQuickLookBridge *)sharedInstance {
    return [[[self sharedPanel] windowController] delegate];
}

- (id)init {
    if (self == [super init]) {
        _URLs = [[NSMutableArray alloc] init];
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
    [[WLQuickLookBridge sharedPanel] makeKeyAndOrderFrontWithEffect:2]; 
	// 1 = fade in
	// 2 = zoom in
}

+ (NSMutableArray *)URLs {
    return [self sharedInstance]->_URLs;
}

+ (void)add:(NSURL *)URL {
    NSMutableArray *URLs = [self URLs];
    // check if the url is already under preview
    NSInteger index = [URLs indexOfObject:URL];
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
