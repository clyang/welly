//
//  XITabBarControl.m
//  Welly
//
//  Created by boost @ 9# on 7/14/08.
//  Copyright 2008 Xi Wang. All rights reserved.
//

#import "WLTabBarControl.h"
#import "WLMainFrameController.h"
#import "CommonType.h"

// suppress warnings
@interface PSMTabBarControl ()
- (NSArray *)cells;
- (id)cellForPoint:(NSPoint)mousePt 
		 cellFrame:(NSRect *)cellFrame;
- (void)closeTabClick:(id)sender;

@end

@implementation WLTabBarControl

- (void)closeTabClick:(id)sender
{
    NSTabViewItem *item = [sender representedObject];
    [sender retain];
    if(([_cells count] == 1) && (![self canCloseOnlyTab]))
        return;
    
    if ([[self delegate] respondsToSelector:@selector(tabView:shouldCloseTabViewItem:)]) {
        if (![[self delegate] tabView:tabView shouldCloseTabViewItem:item]) {
            // fix mouse downed close button
            [sender setCloseButtonPressed:NO];
            [sender release];
            return;
        }
    }
    
    [item retain];
    
    [tabView removeTabViewItem:item];
    [item release];
    [sender release];
}

- (void)mouseDown:(NSEvent *)theEvent {
    // double click
    if ([theEvent clickCount] > 1) {
        // PSMTabBarControl: detect if on cells
        NSPoint mousePt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        NSRect cellFrame;
        id cell = [self cellForPoint:mousePt cellFrame:&cellFrame];
        // not on any cell: new tab
        if (!cell) {
            NSButton *button = (NSButton *)[self addTabButton];
            [button performClick:button];
        }
    }
    [super mouseDown:theEvent];
}

- (void)selectTabViewItemAtIndex:(NSInteger)index {
    if ([[self cells] count] > 0 && [[self cells] count] < index) {
        NSTabViewItem *tabViewItem = [[[self cells] objectAtIndex:index] representedObject];
        [[self tabView] selectTabViewItem:tabViewItem];
    }
}

- (void)selectFirstTabViewItem:(id)sender {
    if ([[self cells] count] > 0)
        [self selectTabViewItemAtIndex:0];
}

- (void)selectLastTabViewItem:(id)sender {
    uint count = [[self cells] count];
    if (count > 0)
        [self selectTabViewItemAtIndex:count-1];
}

- (NSInteger)indexOfTabViewItem:(NSTabViewItem *)tabViewItem {
    size_t count = [[self cells] count];
    for (size_t i = 0; i < count; ++i) {
        if ([[[[self cells] objectAtIndex:i] representedObject] isEqualTo:tabViewItem])
            return i;
    }
    return -1;
}

- (void)selectNextTabViewItem:(id)sender {
    NSTabViewItem *sel = [[self tabView] selectedTabViewItem];
    if (sel == nil)
        return;
    int index = [self indexOfTabViewItem:sel] + 1;
    if (index == [[self cells] count])
        index = 0;
    [self selectTabViewItemAtIndex:index];
}

- (void)selectPreviousTabViewItem:(id)sender {
    NSTabViewItem *sel = [[self tabView] selectedTabViewItem];
    if (sel == nil)
        return;
    int index = [self indexOfTabViewItem:sel];
    if (index == 0)
        [self selectLastTabViewItem:sender];
    else
        [self selectTabViewItemAtIndex:index-1];
}

#pragma mark -
- (void)removeTabViewItem:(NSTabViewItem *)tabViewItem {
    int index = [self indexOfTabViewItem:tabViewItem];
    [self closeTabClick:[[self cells] objectAtIndex:index]];
}

#pragma mark - Set main controller
- (void)setMainController:(WLMainFrameController *)controller {
	_currMainController = controller;
}

- (void)tabViewDidChangeNumberOfTabViewItems:(NSTabView *)aTabView
{
    NSArray *tabItems = [tabView tabViewItems];
    // go through cells, remove any whose representedObjects are not in [tabView tabViewItems]
    NSEnumerator *e = [[[_cells copy] autorelease] objectEnumerator];
    PSMTabBarCell *cell;
    while ( (cell = [e nextObject]) ) {
        //remove the observer binding
        if ([cell representedObject] && ![tabItems containsObject:[cell representedObject]]) {
            // see issue #2609
            // -removeTabForCell: comes first to stop the observing that would be triggered in the delegate's call tree
            // below and finally caused a crash.
            [self removeTabForCell:cell];
            
            if ([[self delegate] respondsToSelector:@selector(tabView:didCloseTabViewItem:)]) {
                [[self delegate] tabView:aTabView didCloseTabViewItem:[cell representedObject]];
            }
        }
    }
    
    // go through tab view items, add cell for any not present
    NSMutableArray *cellItems = [self representedTabViewItems];
    NSEnumerator *ex = [tabItems objectEnumerator];
    NSTabViewItem *item;
    while ( (item = [ex nextObject]) ) {
        if (![cellItems containsObject:item]) {
            [self addTabViewItem:item];
        }
    }
    
    // pass along for other delegate responses
    if ([[self delegate] respondsToSelector:@selector(tabViewDidChangeNumberOfTabViewItems:)]) {
        [[self delegate] performSelector:@selector(tabViewDidChangeNumberOfTabViewItems:) withObject:aTabView];
    }
    
    // reset cursor tracking for the add tab button if one exists
    if ([self addTabButton]) [[self addTabButton] resetCursorRects];
}

@end
