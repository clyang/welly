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

// suppress warnings
@interface QLPreviewPanel : NSPanel
+ (id)sharedPreviewPanel;
- (void)close;
- (void)makeKeyAndOrderFrontWithEffect:(int)flag;
- (void)setURLs:(NSArray *)URLs currentIndex:(unsigned)index preservingDisplayState:(BOOL)flag;
- (void)setEnableDragNDrop:(BOOL)flag;
@end


@implementation WLQuickLookBridge

+ (WLQuickLookBridge *)sharedInstance {
    static WLQuickLookBridge *instance = nil;
    if (instance == nil) {
        instance = [WLQuickLookBridge new];
    }
    return instance;
}

- (id)init {
    if (self == [super init]) {
        _pid = -1;
        _URLs = [[NSMutableArray alloc] init];
        SInt32 ver;
        if (Gestalt(gestaltSystemVersion, &ver) == noErr && ver < 0x1060) {
            // Leopard: "/System/Library/PrivateFrameworks/QuickLookUI.framework"
            [[NSBundle bundleWithPath:@"/System/…/QuickLookUI.framework"] load];
            _panel = [NSClassFromString(@"QLPreviewPanel") sharedPreviewPanel];
        } else
            _panel = nil;
        // To deal with full screen window level
        // Modified by gtCarrera
        //[_panel setLevel:kCGStatusWindowLevel+1];
        // End
        [[_panel windowController] setDelegate:self];
        [_panel setEnableDragNDrop:YES];
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
    [[self Panel] makeKeyAndOrderFrontWithEffect:2];
    // 1 = fade in
    // 2 = zoom in
    if ([self Panel])
        return;

    NSUInteger count = [[self URLs] count];
//    if (count == 0)
//        return;
    WLQuickLookBridge *instance = [self sharedInstance];
    pid_t pid = instance->_pid;
    if (pid > 0)
        kill(pid, SIGQUIT);
    pid = fork();
    if (pid == 0) {
        char *argv[count+3];
        argv[0] = "/usr/bin/qlmanage";
        argv[1] = "-p";
        for (NSUInteger i = 0; i < count; ++i) {
            NSURL *URL = (NSURL *)[[self URLs] objectAtIndex:i];
            argv[i+2] = (char *)[[URL path] UTF8String];
        }
        argv[count+2] = 0;
        execv("/usr/bin/qlmanage", argv);
        exit(-1);
    }
    instance->_pid = pid;
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
    [[self Panel] setURLs:URLs currentIndex:index preservingDisplayState:YES];
    [self orderFront];
}
/*
+ (void)removeAll {
    [[self URLs] removeAllObjects];
    [[self sharedPanel] close];
    // we don't call setURLs here
}*/

@end
