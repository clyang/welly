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
- (id)cacheManager;
- (void)setSelectedIndex:(NSUInteger)index;
- (NSUInteger)selectedIndex;
- (NSUInteger)focusedIndex;
- (NSUInteger)cellIndexAtLocation:(NSPoint)point;
- (void)setBackgroundColor:(NSColor *)color;
- (NSColor *)backgroundColor;
- (void)setDraggingDestinationDelegate:(id)delegate;
@end

@interface IKCacheManager : NSObject
- (void)freeCache;
@end

// a container
@interface BackgroundColorView : NSView {
    NSColor *_color;
}
- (void)setBackgroundColor:(NSColor *)color;
@end

@implementation BackgroundColorView
- (void)dealloc {
    [_color release];
    [super dealloc];
}
- (void)drawRect:(NSRect)rect {
    [_color set];
    NSRectFill(rect);
}
- (void)setBackgroundColor:(NSColor *)color {
    _color = [color copy];
}
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
    _contentView = [[BackgroundColorView alloc] init];
    _view = [[NSClassFromString(@"IKImageFlowView") alloc] initWithFrame:NSZeroRect];
	[_view setDataSource:self];
    [_view setDelegate:self];
    [_view setDraggingDestinationDelegate:self];
    [_contentView addSubview:_view];
    [superview addSubview:_contentView];
    return self;
}

- (void)refresh {
    [[_view cacheManager] freeCache];
    [_view reloadData];
}

+ (NSString*)coverDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSAssert([paths count] > 0, @"~/Library/Application Support");
    NSString *dir = [[[paths objectAtIndex:0] stringByAppendingPathComponent:@"Welly"] stringByAppendingPathComponent:@"Covers"];
    return dir;
}

- (void)loadCovers {
    [_data removeAllObjects];
    NSString *dir = [[self class] coverDirectory];
    // load sites
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSArray *sites = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Sites"];
    for (NSDictionary *d in sites) {
        NSString *key = [d objectForKey:@"name"];
        if ([key length] == 0)
            continue;
        // guess the image file name
        NSArray *paths = nil;
        [[[dir stringByAppendingPathComponent:key] stringByAppendingString:@"."]
            completePathIntoString:nil caseSensitive:NO matchesIntoArray:&paths filterTypes:nil];
        NSString *path = nil;
        if ([paths count])
            path = [paths objectAtIndex:0];
        WLPortalImage *item = [[WLPortalImage alloc] initWithPath:path title:key];
        [_data addObject:item];
    }
    [pool release];
    [self refresh];
}

- (void)show {
    NSView *superview = [_contentView superview];
    NSRect frame = [superview frame];
    [_contentView setFrame:frame];
    frame.origin.x += frame.size.width * (1 - xscale) / 2;
    frame.origin.y += frame.size.height * (1 - yscale) / 2;
    frame.size.width *= xscale;
    frame.size.height *= yscale;
    [_view setFrame:frame];
    // background
    NSColor *color = [[YLLGlobalConfig sharedInstance] colorBG];
    // cover flow doesn't support alpha
    color = [color colorWithAlphaComponent:1.0];
    [_contentView setBackgroundColor:color];
    [_view setBackgroundColor:color];
    // event hanlding
    NSResponder *next = [superview nextResponder];
    if (_view != next) {
        [_view setNextResponder:next];
        [superview setNextResponder:_view];
    }
}

- (void)hide {
    [_contentView setFrame:NSZeroRect];
    NSView *superview = [_contentView superview];
    [superview setNextResponder:[_view nextResponder]];
    [_view setNextResponder:nil];
}

- (BOOL)updateCoverAtIndex:(NSUInteger)index withFile:(NSString*)src {
    if ([_data count] <= index)
        return NO;

    WLPortalImage *item = [_data objectAtIndex:index];
    if (item == nil)
        return NO;

    NSFileManager *fileMgr = [NSFileManager defaultManager];
    // remove the original one
    if ([item path])
        [fileMgr removeItemAtPath:[item path] error:nil];

    NSString *dst = nil;
    if (src) {
        NSString *dir = [[self class] coverDirectory];
        dst = [[dir stringByAppendingPathComponent:[item imageTitle]] stringByAppendingPathExtension:[src pathExtension]];
        // try to clean up dst first
        [fileMgr removeItemAtPath:dst error:nil];
        NSError *error = nil;
        // copy
        [fileMgr copyItemAtPath:src toPath:dst error:&error];
        if (error) {
            [NSApp presentError:error];
            return NO;
        }
    }

    // update
    [item setPath:dst];
    [self refresh];
    return YES;
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
#pragma mark Event handler

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

- (void)mouseDragged:(NSEvent *)theEvent {
	WLPortalImage *item = [_data objectAtIndex:[_view selectedIndex]];
	// Do not allow to drag & drop default image
	if ([item image] == nil)
		return;
    NSString *path = [item path];
    NSImage *image = [[NSWorkspace sharedWorkspace] iconForFile:path];
	NSPoint pt = [_view convertPoint:[theEvent locationInWindow] fromView:nil];
    NSSize size = [image size];
    pt.x -= size.width/2;
    pt.y -= size.height/2;
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
    [pboard declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType] owner:nil];
    [pboard setString:path forType:NSFilenamesPboardType];
    [_view dragImage:image at:pt offset:NSZeroSize 
        event:theEvent pasteboard:pboard source:self slideBack:NO];
	return;
}

#pragma mark -
#pragma mark NSDraggingSource protocol
// drag out images (remove covers)

// private
- (BOOL)draggedOut:(NSPoint)screenPoint {
	NSPoint pt = [[_view window] convertScreenToBase:screenPoint];
    return ![_view hitTest:pt];
}

- (void)draggedImage:(NSImage *)image movedTo:(NSPoint)screenPoint {
    if ([self draggedOut:screenPoint])
        [[NSCursor disappearingItemCursor] set];
    else
        [[NSCursor arrowCursor] set];
}

- (void)draggedImage:(NSImage *)image endedAt:(NSPoint)screenPoint operation:(NSDragOperation)operation {
    [[NSCursor arrowCursor] set];
    if (![self draggedOut:screenPoint])
        return;
    NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Are you sure you want to delete the cover?", @"Sheet Title")
                                     defaultButton:NSLocalizedString(@"Delete", @"Default Button")
                                   alternateButton:NSLocalizedString(@"Cancel", @"Cancel Button")
                                       otherButton:nil
                         informativeTextWithFormat:NSLocalizedString(@"Welly will delete this cover file, please confirm.", @"Sheet Message")];
    if ([alert runModal] == NSAlertDefaultReturn)
        [self updateCoverAtIndex:[_view selectedIndex] withFile:nil];
}

#pragma mark -
#pragma mark NSDraggingDestination protocol
// drop in images (add covers)

// private
- (NSUInteger)draggingIndex:(id <NSDraggingInfo>)sender {
    return [_view cellIndexAtLocation:[sender draggingLocation]];
}

// private
- (NSDragOperation)checkSource:(id <NSDraggingInfo>)sender {
    id files = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
    // only one file supported
    if ([files count] != 1)
        return NSDragOperationNone;
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSString *path = [files objectAtIndex:0];
    BOOL isDir;
    if (![fileMgr fileExistsAtPath:path isDirectory:&isDir] || isDir)
        return NSDragOperationNone;
    if (![fileMgr isReadableFileAtPath:path])
        return NSDragOperationNone;
    return NSDragOperationCopy;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    if ([sender draggingSource] == self)
        return NSDragOperationNone;
    NSPasteboard *pboard = [sender draggingPasteboard];
    if (![[pboard types] containsObject:NSFilenamesPboardType])
        return NSDragOperationNone;
    return [self draggingUpdated:sender];
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
    if ([self draggingIndex:sender] == NSNotFound)
        return NSDragOperationNone;
    return [self checkSource:sender];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
    return [self checkSource:sender];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    id files = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
    assert([files count] == 1);
    NSUInteger index = [self draggingIndex:sender];
    return [self updateCoverAtIndex:index withFile:[files objectAtIndex:0]];
}

- (void)concludeDragOperation:(id < NSDraggingInfo >)sender {
    [self refresh];
}

@end
