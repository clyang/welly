//
//  WLPortal.m
//  Welly
//
//  Created by boost on 9/6/09.
//  Copyright 2009 Xi Wang. All rights reserved.
//

#import "WLCoverFlowPortal.h"
#import "WLBookmarkPortalItem.h"
#import "CommonType.h"
#import "YLController.h"
#import "WLSitesPanelController.h"

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


@implementation WLCoverFlowPortal

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

- (void)loadCovers {
	// TODO(K.O.ed): Move this outta here! The data should be provided elsewhere
    [_data removeAllObjects];
    //NSString *dir = [[self class] coverDirectory];
    // load sites
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSArray *sites = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Sites"];
    for (NSDictionary *d in sites) {
		WLBookmarkPortalItem *item = [[WLBookmarkPortalItem alloc] initWithSite:[WLSite siteWithDictionary:d]];
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
    NSColor *color = [[WLGlobalConfig sharedInstance] colorBG];
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

- (void)select {
	WLPortalItem *item = [_data objectAtIndex:[_view selectedIndex]];
	[item didSelect:self];
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

// private
- (NSUInteger)cellIndexAtLocation:(NSPoint)p {
    NSPoint pt = [_view convertPoint:p fromView:nil];
    return [_view cellIndexAtLocation:pt];
}

- (id)itemAtLocation:(NSPoint)p {
	NSUInteger index = [self cellIndexAtLocation:p];
    if (index == NSNotFound || [_data count] <= index)
        return nil;
	
    return [_data objectAtIndex:index];
}

- (void)mouseDown:(NSEvent *)theEvent {
	_draggingItem = [self itemAtLocation:[theEvent locationInWindow]];
	if (_draggingItem) {
		if (![_draggingItem conformsToProtocol:@protocol(WLDraggingSource)] || 
			![(id <WLDraggingSource>)_draggingItem acceptsDragging]) {
			_draggingItem = nil;
			return;
		}
		
		WLPortalItem <WLDraggingSource> *draggingItem = (WLPortalItem <WLDraggingSource> *)_draggingItem;
		NSImage *image = [draggingItem draggingImage];
		NSSize size = [image size];
		NSPoint pt = [_view convertPoint:[theEvent locationInWindow] fromView:nil];
		pt.x -= size.width/2;
		pt.y -= size.height/2;
		NSPasteboard *pboard = [draggingItem draggingPasteboard];
		[_view dragImage:image at:pt offset:NSZeroSize 
				   event:theEvent pasteboard:pboard source:self slideBack:NO];
		return;
	} 
}

#pragma mark -
#pragma mark NSDraggingSource protocol
// drag out images (remove covers)

// private
- (BOOL)draggedOut:(NSPoint)screenPoint {
	NSPoint pt = [[_view window] convertScreenToBase:screenPoint];
    return ![_view hitTest:pt];
}

- (void)draggedImage:(NSImage *)image 
			 movedTo:(NSPoint)screenPoint {
    if ([self draggedOut:screenPoint])
        [[NSCursor disappearingItemCursor] set];
    else
        [[NSCursor arrowCursor] set];
}

- (void)draggedImage:(NSImage *)image 
			 endedAt:(NSPoint)screenPoint 
		   operation:(NSDragOperation)operation {
    [[NSCursor arrowCursor] set];
    if (![self draggedOut:screenPoint])
        return;
	
	if (_draggingItem) {
		assert([_draggingItem conformsToProtocol:@protocol(WLDraggingSource)]);
		id <WLDraggingSource> draggingItem = (id <WLDraggingSource>) _draggingItem;
		assert([draggingItem acceptsDragging]);
		[draggingItem draggedToRemove:self];
		[self refresh];
		_draggingItem = nil;
	}
}

#pragma mark -
#pragma mark NSDraggingDestination protocol
// drop in images (add covers)

// private
- (NSDragOperation)checkSource:(id <NSDraggingInfo>)sender {
	id item = [self itemAtLocation:[sender draggingLocation]];
    if (!item)
        return NSDragOperationNone;
	if ([item acceptsPBoard:[sender draggingPasteboard]])
		return NSDragOperationCopy;
	return NSDragOperationNone;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    if ([sender draggingSource] == self)
        return NSDragOperationNone;
    return [self draggingUpdated:sender];
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
    return [self checkSource:sender];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
    return [self checkSource:sender];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    id item = [self itemAtLocation:[sender draggingLocation]];
    if (item == nil || ![item conformsToProtocol:@protocol(WLPasteboardReceiver)])
        return NO;
	
	return [(id <WLPasteboardReceiver>)item didReceivePBoard:[sender draggingPasteboard]];
}

- (void)concludeDragOperation:(id < NSDraggingInfo >)sender {
    [self refresh];
}

@end
