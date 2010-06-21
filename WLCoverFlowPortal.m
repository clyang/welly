//
//  WLPortal.m
//  Welly
//
//  Created by boost on 9/6/09.
//  Copyright 2009 Xi Wang. All rights reserved.
//

#import "WLCoverFlowPortal.h"
#import "WLPortalItem.h"
#import "CommonType.h"
#import "WLGlobalConfig.h"

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

@implementation WLCoverFlowPortal

//@synthesize view = _imageFlowView;

- (void)dealloc {
	if (_portalItems)
		[_portalItems release];
    [super dealloc];
}

- (id)initWithFrame:(NSRect)frame {
	if (self = [super initWithFrame:frame]) {
		// Initialize the imageFlowView
		_imageFlowView = [[NSClassFromString(@"IKImageFlowView") alloc] initWithFrame:frame];
		[_imageFlowView setDataSource:self];
		[_imageFlowView setDelegate:self];
		[_imageFlowView setDraggingDestinationDelegate:self];
		[_imageFlowView setHidden:NO];

		// background
		NSColor *color = [[WLGlobalConfig sharedInstance] colorBG];
		// cover flow doesn't support alpha
		color = [color colorWithAlphaComponent:1.0];
		[_imageFlowView setBackgroundColor:color];
	}
	return self;
}

- (void)awakeFromNib {
	[self addSubview:_imageFlowView];
	[[self window] makeFirstResponder:self];
	// event hanlding
	/*NSResponder *next = [self nextResponder];
	if (_imageFlowView != next) {
		[_imageFlowView setNextResponder:next];
		[self setNextResponder:_imageFlowView];
	}*/	
}

- (void)setFrame:(NSRect)frame {
	[super setFrame:frame];
	frame.origin.x += frame.size.width * (1 - xscale) / 2;
	frame.origin.y += frame.size.height * (1 - yscale) / 2;
	frame.size.width *= xscale;
	frame.size.height *= yscale;
	[_imageFlowView setFrame:frame];
	//[_imageFlowView setNeedsDisplay:YES];
}

- (id)initWithPortalItems:(NSArray *)portalItems {
	if (self = [self init]) {
		[self setPortalItems:_portalItems];
	}
	return self;
}

#pragma mark -
#pragma mark Display
- (void)drawRect:(NSRect)rect {
	[[[WLGlobalConfig sharedInstance] colorBG] set];
    NSRectFill(rect);
}

- (void)refresh {
    [[_imageFlowView cacheManager] freeCache];
    [_imageFlowView reloadData];
}

- (void)setPortalItems:(NSArray *)portalItems {
	if (_portalItems)
		[_portalItems release];
	
	_portalItems = [portalItems copy];
	[self refresh];
}

- (void)select {
	WLPortalItem *item = [_portalItems objectAtIndex:[_imageFlowView selectedIndex]];
	[item didSelect:self];
}

#pragma mark -
#pragma mark Override
- (BOOL)acceptsFirstResponder {
	return YES;
}

- (BOOL)canBecomeKeyView {
    return YES;
}

/*- (NSView *)hitTest:(NSPoint)p {
    return self;
}*/

#pragma mark -
#pragma mark IKImageFlowDataSource protocol
- (NSUInteger)numberOfItemsInImageFlow:(id)aFlow {
	return [_portalItems count];
}

- (id)imageFlow:(id)aFlow itemAtIndex:(NSUInteger)index {
	return [_portalItems objectAtIndex:index];
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
    [_imageFlowView keyDown:theEvent];
}

// private
- (NSUInteger)cellIndexAtLocation:(NSPoint)p {
    NSPoint pt = [_imageFlowView convertPoint:p fromView:nil];
    return [_imageFlowView cellIndexAtLocation:pt];
}

- (id)itemAtLocation:(NSPoint)p {
	NSUInteger index = [self cellIndexAtLocation:p];
    if (index == NSNotFound || [_portalItems count] <= index)
        return nil;
	
    return [_portalItems objectAtIndex:index];
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
		NSPoint pt = [_imageFlowView convertPoint:[theEvent locationInWindow] fromView:nil];
		pt.x -= size.width/2;
		pt.y -= size.height/2;
		NSPasteboard *pboard = [draggingItem draggingPasteboard];
		[_imageFlowView dragImage:image at:pt offset:NSZeroSize 
				   event:theEvent pasteboard:pboard source:self slideBack:NO];
		return;
	} 
}

#pragma mark -
#pragma mark NSDraggingSource protocol
// drag out images (remove covers)

// private
- (BOOL)draggedOut:(NSPoint)screenPoint {
	NSPoint pt = [[_imageFlowView window] convertScreenToBase:screenPoint];
    return ![_imageFlowView hitTest:pt];
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
