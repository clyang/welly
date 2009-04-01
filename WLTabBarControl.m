//
//  XITabBarControl.m
//  Welly
//
//  Created by boost @ 9# on 7/14/08.
//  Copyright 2008 Xi Wang. All rights reserved.
//

#import "WLTabBarControl.h"
#import "YLController.h"
#import "CommonType.h"

// suppress warnings
@interface PSMTabBarControl ()
- (NSArray *)cells;
- (id)cellForPoint:(NSPoint)mousePt 
		 cellFrame:(NSRect *)cellFrame;
- (void)closeTabClick:(id)sender;
@end

@implementation WLTabBarControl

- (void)mouseDown:(NSEvent *)theEvent {
    // double click
    if ([theEvent clickCount] > 1) {
        // PSMTabBarControl: detect if on cells
        NSPoint mousePt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        NSRect cellFrame;
        id cell = [self cellForPoint:mousePt cellFrame:&cellFrame];
        // not on any cell: new tab
        if (!cell) {
            //NSLog(@"%@", theEvent);
            NSButton *button = (NSButton *)[self addTabButton];
            [button performClick:button];
        }
    }
    [super mouseDown:theEvent];
}

// Respond to key equivalent: 
// Cmd+[0-9], Ctrl+Tab, Cmd+Shift+Left/Right (I don't know if we should keep this)
// Added by K.O.ed, 2009.02.02
- (BOOL)performKeyEquivalent:(NSEvent *)event {
	//NSLog(@"XITabBarControl performKeyEquivalent:");
	if ((([event modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask) && 
		(([event modifierFlags] & NSShiftKeyMask) == NSShiftKeyMask) &&
		[[event charactersIgnoringModifiers] isEqualToString:keyStringLeft] ) {
		[self selectPreviousTabViewItem:self];
		return YES;
	} else if ((([event modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask) && 
			   (([event modifierFlags] & NSShiftKeyMask) == NSShiftKeyMask) &&
			   [[event charactersIgnoringModifiers] isEqualToString:keyStringRight] ) {
		[self selectNextTabViewItem:self];
		return YES;
	} else if (([event modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask && 
			   ([event modifierFlags] & NSAlternateKeyMask) == 0 && 
			   ([event modifierFlags] & NSControlKeyMask) == 0 && 
			   ([event modifierFlags] & NSShiftKeyMask) == 0 && 
			   [[event characters] intValue] > 0 && 
			   [[event characters] intValue] < 10) {
		[self selectTabViewItemAtIndex:([[event characters] intValue]-1)];
		return YES;
	} else if (([event modifierFlags] & NSCommandKeyMask) == 0 && 
			   ([event modifierFlags] & NSAlternateKeyMask) == 0 && 
			   ([event modifierFlags] & NSControlKeyMask) == NSControlKeyMask && 
			   ([event modifierFlags] & NSShiftKeyMask) == 0 && 
			   [[event characters] characterAtIndex:0] == '\t') {
		[self selectNextTabViewItem:self];
		return YES;
	}
    
	return NO;
}

- (void)selectTabViewItemAtIndex:(NSInteger)index {
    NSTabViewItem *tabViewItem = [[[self cells] objectAtIndex:index] representedObject];
    [[self tabView] selectTabViewItem:tabViewItem];
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
- (void)setMainController:(YLController *)controller {
	_currMainController = controller;
}
@end
