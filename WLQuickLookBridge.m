//
//  XIQuickLookBridge.m
//  Preview via Quick Look
//
//  Created by boost @ 9# on 7/11/08.
//  Copyright 2008 Xi Wang. All rights reserved.
//

#import "WLQuickLookBridge.h"

@interface WLQuickLookBridge (WLQuickLookBridgeSingleton)
+ (WLQuickLookBridge *)sharedInstance;
@end

@interface QLPreviewPanel : NSPanel
+ (id)sharedPreviewPanel;
- (void)close;
- (void)makeKeyAndOrderFrontWithEffect:(int)flag canClose:(BOOL)canClose;
// 10.5 only
- (void)setURLs:(NSArray *)URLs currentIndex:(unsigned)index preservingDisplayState:(BOOL)flag;
- (void)setEnableDragNDrop:(BOOL)flag;
// 10.6 and above
- (id)sharedPreviewView;
- (void)reloadDataPreservingDisplayState:(BOOL)flag;
@end

@implementation WLQuickLookBridge

static BOOL isLeopard;

+ (WLQuickLookBridge *)sharedInstance {
    static WLQuickLookBridge *instance = nil;
    if (instance == nil) {
        instance = [WLQuickLookBridge new];
    }
    return instance;
}

+ (void)initialize {
    SInt32 ver;
    isLeopard = Gestalt(gestaltSystemVersion, &ver) == noErr && ver < 0x1060;
}

- (id)init {
    if (self != [super init]) 
        return nil;
    _URLs = [[NSMutableArray alloc] init];
    // 10.5: /System/Library/PrivateFrameworks/QuickLookUI.framework
    // 10.6: /System/Library/Frameworks/Quartz.framework/Versions/A/Frameworks/QuickLookUI.framework
    [[NSBundle bundleWithPath:@"/System/Library/…/QuickLookUI.framework"] load];
    _panel = [NSClassFromString(@"QLPreviewPanel") sharedPreviewPanel];
    // To deal with full screen window level
    // Modified by gtCarrera
    //[_panel setLevel:kCGStatusWindowLevel+1];
    // End
    [[_panel windowController] setDelegate:self];
    if (isLeopard) {
        [_panel setEnableDragNDrop:YES];
    } else {
        [[_panel sharedPreviewView] setEnableDragNDrop:YES];
        [_panel setDataSource:self];
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
    return [self sharedInstance]->_URLs;
}

+ (id)Panel {
    return [self sharedInstance]->_panel;
}

+ (void)orderFront {
    // 1 = fade in, 2 = zoom in
    [[self Panel] makeKeyAndOrderFrontWithEffect:2 canClose:YES];
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
    if (isLeopard)
        [[self Panel] setURLs:URLs currentIndex:index preservingDisplayState:YES];
    else
        [[self Panel] reloadDataPreservingDisplayState:YES];
    [self orderFront];
}
/*
+ (void)removeAll {
    [[self URLs] removeAllObjects];
    [[self sharedPanel] close];
    // we don't call setURLs here
}*/

#pragma mark -
#pragma mark QLPreviewPanelDataSource protocol

- (NSInteger)numberOfPreviewItemsInPreviewPanel:(id)panel {
    return [_URLs count];
}

- (id)previewPanel:(id)panel previewItemAtIndex:(NSInteger)index {
    return [_URLs objectAtIndex:index];
}

@end
