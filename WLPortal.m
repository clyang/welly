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

- (id)initWithView:(NSView *)superview {
    if (self != [super init])
        return nil;
    _data = [[NSMutableArray alloc] init];
    _view = [[NSClassFromString(@"IKImageFlowView") alloc] initWithFrame:NSZeroRect];
	[_view setDataSource:self];
    [_view setDelegate:self];
	//[self setDraggingDestinationDelegate:self];
    [superview addSubview:_view];
    [self loadCovers];
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
        NSString *path = nil;
        [[[dir stringByAppendingPathComponent:key] stringByAppendingString:@"."]
            completePathIntoString:&path caseSensitive:NO matchesIntoArray:nil filterTypes:nil];
        WLPortalImage *item = [[WLPortalImage alloc] initWithPath:path title:key];
        [_data addObject:item];
    }
    [pool release];
}

- (void)show {
    NSView *superview = [_view superview];
    if (superview == nil)
        return;
    NSRect frame = [superview frame];
    frame.origin.x += frame.size.width * (1 - xscale) / 2;
    frame.origin.y += frame.size.height * (1 - yscale) / 2;
    frame.size.width *= xscale;
    frame.size.height *= yscale;
    [_view setFrame:frame];
    [_view setBackgroundColor:[[YLLGlobalConfig sharedInstance] colorBG]];
    [_view reloadData];
    // event hanlding
    NSResponder *next = [superview nextResponder];
    if (_view != next) {
        [_view setNextResponder:next];
        [superview setNextResponder:_view];
    }
}

- (void)hide {
    [_view setFrame:NSZeroRect];
    NSView *superview = [_view superview];
    [superview setNextResponder:[_view nextResponder]];
    [_view setNextResponder:nil];
}

- (void)select {
    [self hide];
    YLController *controller = [((YLApplication *)NSApp) controller];
    YLSite *site = [controller objectInSitesAtIndex:[_view selectedIndex]];
    [controller newConnectionWithSite:site];
}

#pragma mark - 
#pragma mark IKImageFlowDataSource protocol

- (NSUInteger)numberOfItemsInImageFlow:(id)aFlow {
	return [_data count];
}

- (id)imageFlow:(id)aFlow itemAtIndex:(NSUInteger)index {
	return [_data objectAtIndex:index];
}

#pragma mark -
#pragma mark IKImageFlowDelegate protocol

- (void)imageFlow:(id)aFlow cellWasDoubleClickedAtIndex:(NSInteger)index {
    [self select];
}

#pragma mark -
#pragma mark Event Handler

- (void)keyDown:(NSEvent *)theEvent {
	switch ([[theEvent charactersIgnoringModifiers] characterAtIndex:0]) {
        case WLWhitespaceCharacter:
        case WLReturnCharacter: {
            [self select];
            return;
        }
    }
    [_view keyDown:theEvent];
}

@end
