//
//  WLPortal.m
//  Welly
//
//  Created by boost on 9/6/09.
//  Copyright 2009 Xi Wang. All rights reserved.
//

#import "WLPortal.h"
#import "WLPortalImage.h"
#import "CommonType.h"
#import "YLApplication.h"
#import "YLController.h"

const float xscale = 1, yscale = 0.8;

// private methods
@interface WLPortal ()
- (void)loadCovers;
@end

// hack
@interface IKImageFlowView : NSOpenGLView
- (void)reloadData;
- (void)setSelectedIndex:(NSUInteger)index;
- (NSUInteger)selectedIndex;
- (NSUInteger)focusedIndex;
- (void)setBackgroundColor:(NSColor *)color;
- (NSColor *)backgroundColor;
@end

@implementation WLPortal

@synthesize view = _view;

- (void)dealloc {
    [_data release];
    [super dealloc];
}

- (id)init {
    if (self != [super init])
        return nil;
    _data = [[NSMutableArray alloc] init];
    _view = [[NSClassFromString(@"IKImageFlowView") alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)];
	//[_view setDelegate:self];
	[_view setDataSource:self];
	//[self setDraggingDestinationDelegate:self];
	[_view setBackgroundColor:[[YLLGlobalConfig sharedInstance] colorBG]];
    [self loadCovers];
    [_view reloadData];
    return self;
}

- (void)loadCovers {
    // cover directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSAssert([paths count] > 0, @"~/Library/Application Support");
    NSString *dir = [[[paths objectAtIndex:0] stringByAppendingPathComponent:@"Welly"] stringByAppendingPathComponent:@"Covers"];
    // load sites
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSArray *sites = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Sites"];
    for (NSDictionary *d in sites) {
        NSString *key = [d objectForKey:@"name"];
        if ([key length] == 0)
            continue;
        // guess the image file name
        NSString *file = nil;
        [[[dir stringByAppendingPathComponent:key] stringByAppendingString:@"."]
            completePathIntoString:&file caseSensitive:NO matchesIntoArray:nil filterTypes:nil];
        NSImage *image = nil;
        if (file)
            image = [[NSImage alloc] initByReferencingFile:file];
        // no image
        if (image == nil)
            image = [NSImage imageNamed:@"default_site.png"];
        WLPortalImage *item = [[WLPortalImage alloc] initWithImage:image title:key];
        [_data addObject:item];
    }
    [pool release];
}

- (void)show {
    NSView *view = [_view superview];
    if (view == nil)
        return;
    NSRect frame = [view frame];
    frame.origin.x += frame.size.width * (1 - xscale) / 2;
    frame.origin.y += frame.size.height * (1 - yscale) / 2;
    frame.size.width *= xscale;
    frame.size.height *= yscale;
    [_view setFrame:frame];
}

- (void)hide {
    [_view setFrame:NSMakeRect(0, 0, 0, 0)];
}

- (void)select {
    [self hide];
    YLController *controller = [((YLApplication *)NSApp) controller];
    YLSite *site = [controller objectInSitesAtIndex:[_view selectedIndex]];
    [controller newConnectionWithSite:site];
}

#pragma mark - 
#pragma mark IKImageFlowDataSource Protocol

- (NSUInteger)numberOfItemsInImageFlow:(id)aFlow {
	return [_data count];
}

- (id)imageFlow:(id)aFlow itemAtIndex:(NSUInteger)index {
	return [_data objectAtIndex:index];
}

#pragma mark -
#pragma mark Event Handler

- (void)keyDown:(NSEvent *)theEvent {
	switch ([[theEvent charactersIgnoringModifiers] characterAtIndex:0]) {
        case NSLeftArrowFunctionKey:
        case NSRightArrowFunctionKey:
        case NSUpArrowFunctionKey:
        case NSDownArrowFunctionKey:
            [_view keyDown:theEvent];
            break;
        case WLWhitespaceCharacter:
        case WLReturnCharacter: {
            [self select];
            break;
        }
    }
}

- (void)mouseUp:(NSEvent *)theEvent {
    [self select];
}

@end
