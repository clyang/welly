//
//  WLTabView.m
//  Welly
//
//  Created by K.O.ed on 10-4-20.
//  Copyright 2010 Welly Group. All rights reserved.
//

#import "WLTabView.h"
#import "WLConnection.h"
#import "WLTerminal.h"
#import "WLTerminalView.h"
#import "WLMainFrameController.h"
#import "WLTabBarControl.h"

#import "WLTabViewItemController.h"

#import "WLGlobalConfig.h"

#import "WLBookmarkPortalItem.h"
#import "WLNewBookmarkPortalItem.h"
#import "WLCoverFlowPortal.h"

@interface WLTabView ()

- (void)updatePortal;
- (void)showPortal;

@end


@implementation WLTabView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    // Comments added by gtCarrera
    // I moved cover flow initialization to awakeFromNib. 
    // Because, here the fram size was wrong! It has not been really "initialized"!
    /*
     if (self) {
		// Initialize the portal
		_portal = [[WLCoverFlowPortal alloc] initWithFrame:[self frame]];
    }*/
    return self;
}

- (void)awakeFromNib {
	[self setTabViewType:NSNoTabsNoBorder];
	
	// Register as sites observer
	[WLSitesPanelController addSitesObserver:self];
	
	// Register KVO
	NSArray *observeKeys = [NSArray arrayWithObjects:@"cellWidth", @"cellHeight", @"cellSize", nil];
	for (NSString *key in observeKeys)
		[[WLGlobalConfig sharedInstance] addObserver:self
										  forKeyPath:key
											 options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) 
											 context:nil];
	
	// Set frame position and size
	[self setFrameOrigin:NSZeroPoint];
	[self setFrameSize:[[WLGlobalConfig sharedInstance] contentSize]];
    // Initialize the portal
    _portal = [[WLCoverFlowPortal alloc] initWithFrame:[self frame]];
	[self updatePortal];
	
	// If no active tabs, we should show the coverflow portal if necessary.
	if ([self numberOfTabViewItems] == 0) {
		[self showPortal];
	}
	[_portal awakeFromNib];
}

#pragma mark -
#pragma mark Drawing
- (void)drawRect:(NSRect)rect {
    // Drawing the background.
	[[[WLGlobalConfig sharedInstance] colorBG] set];
	NSRectFill(rect);
}

- (void)showPortal {
	// Show the coverflow portal if necessary.
	if ([WLGlobalConfig shouldEnableCoverFlow]) {
		[self addSubview:_portal];
		[[self window] makeFirstResponder:_portal];
	}	
}

#pragma mark -
#pragma mark Accessor
- (NSView *)frontMostView {
	return [[self selectedTabViewItem] view];
}

- (WLConnection *)frontMostConnection {
	if ([[[[self selectedTabViewItem] identifier] content] isKindOfClass:[WLConnection class]]) {
		return [[[self selectedTabViewItem] identifier] content];
	}
	
	return nil;
}

- (WLTerminal *)frontMostTerminal {
	return [[self frontMostConnection] terminal];
}

- (BOOL)isFrontMostTabPortal {
	return [[self frontMostView] isKindOfClass:[WLCoverFlowPortal class]];
}

- (BOOL)isSelectedTabEmpty {
	return [self isFrontMostTabPortal] || ([self frontMostConnection] && ([self frontMostTerminal] == nil));
}

#pragma mark -
#pragma mark Adding and removing a tab
- (NSTabViewItem *)emptyTab {
    NSTabViewItem *tabViewItem;
	if ([self isSelectedTabEmpty]) {
		// reuse the empty tab
        tabViewItem = [self selectedTabViewItem];
	} else {	
		// open a new tab
		tabViewItem = [[[NSTabViewItem alloc] initWithIdentifier:[WLTabViewItemController emptyTabViewItemController]] autorelease];
		// this will invoke tabView:didSelectTabViewItem for the first tab
        [self addTabViewItem:tabViewItem];
	}
	return tabViewItem;
}

- (void)newTabWithConnection:(WLConnection *)theConnection 
					   label:(NSString *)theLabel {	
	NSTabViewItem *tabViewItem = [self emptyTab];

	[[tabViewItem identifier] setContent:theConnection];
	
	// set appropriate label
	if (theLabel) {
		[tabViewItem setLabel:theLabel];
	}
	
	// set the view
	[tabViewItem setView:_terminalView];
	
	if (![[theConnection site] isDummy]) {
		// Create a new terminal for receiving connection's content, and forward to view
		WLTerminal *terminal = [[WLTerminal alloc] init];
		[terminal addObserver:_terminalView];
		[theConnection setTerminal:terminal];
		[terminal release];
	}
	
	// select the tab
	[self selectTabViewItem:nil];
	[self selectTabViewItem:tabViewItem];
}

- (void)newTabWithCoverFlowPortal {
	NSTabViewItem *tabViewItem = [self emptyTab];
	
	[tabViewItem setView:_portal];
	[tabViewItem setLabel:@"Cover Flow"];
	
	[self selectTabViewItem:tabViewItem];
}

#pragma mark -
#pragma mark Portal Control
// Show the portal, initiallize it if necessary
- (void)updatePortal {
	NSArray *sites = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Sites"];
	NSMutableArray *portalItems = [NSMutableArray arrayWithCapacity:[sites count]];
	for (NSDictionary *d in sites) {
		WLBookmarkPortalItem *item = [[WLBookmarkPortalItem alloc] initWithSite:[WLSite siteWithDictionary:d]];
		[portalItems addObject:item];
		[item release];
	}
	[portalItems addObject:[[WLNewBookmarkPortalItem new] autorelease]];
	
	[_portal setPortalItems:portalItems];
}

#pragma mark -
#pragma mark WLSitesObserver protocol
- (void)sitesDidChanged:(NSArray *)sitesAfterChange {
	if ([WLGlobalConfig shouldEnableCoverFlow]) {
		[self updatePortal];
	}
}

#pragma mark -
#pragma mark Override
- (void)addTabViewItem:(NSTabViewItem *)tabViewItem {
	// TODO: better solutions?
	if ([[self subviews] containsObject:_portal]) {
		[_portal removeFromSuperview];
	}
	[super addTabViewItem:tabViewItem];
}

- (void)selectTabViewItem:(NSTabViewItem *)tabViewItem {
	NSView *oldView = [[self selectedTabViewItem] view];
	[super selectTabViewItem:tabViewItem];
	
	NSView *currentView = [[self selectedTabViewItem] view];
	[[self window] makeFirstResponder:currentView];
	[[self window] makeKeyWindow];

	if ([currentView conformsToProtocol:@protocol(WLTabItemContentObserver)]) {
		[(id <WLTabItemContentObserver>)currentView didChangeContent:[[[self selectedTabViewItem] identifier] content]];
	}
	
	if ((oldView != currentView) && [oldView conformsToProtocol:@protocol(WLTabItemContentObserver)]) {
		[(id <WLTabItemContentObserver>)oldView didChangeContent:nil];
	}
}

- (void)removeTabViewItem:(NSTabViewItem *)tabViewItem {
	NSView *oldView = [tabViewItem view];
	[super removeTabViewItem:tabViewItem];
	
	if ([self numberOfTabViewItems] == 0) {
		if ([oldView conformsToProtocol:@protocol(WLTabItemContentObserver)]) {
			[(id <WLTabItemContentObserver>)oldView didChangeContent:nil];
		}
		// If no active tabs, we should show the coverflow portal if necessary.
		[self showPortal];
	}
}

- (void)selectNextTabViewItem:(NSTabViewItem *)tabViewItem {
	if([self indexOfTabViewItem:[self selectedTabViewItem]] == [self numberOfTabViewItems] - 1)
		[self selectFirstTabViewItem:self];
	else
		[super selectNextTabViewItem:self];
}

- (void)selectPreviousTabViewItem:(NSTabViewItem *)tabViewItem {
	if([self indexOfTabViewItem:[self selectedTabViewItem]] == 0)
		[self selectLastTabViewItem:self];
	else
		[super selectPreviousTabViewItem:self];
}

- (BOOL)acceptsFirstResponder {
	return NO;
}

- (BOOL)becomeFirstResponder {
	if ([self numberOfTabViewItems] == 0 && [[self subviews] containsObject:_portal]) {
		return [[self window] makeFirstResponder:_portal];
	} else {
		return [[self window] makeFirstResponder:[self frontMostView]];
	}
}

#pragma mark -
#pragma mark Event Handling
// Respond to key equivalent: 
// Cmd+[0-9], Ctrl+Tab, Cmd+Shift+Left/Right (I don't know if we should keep this)
// Added by K.O.ed, 2009.02.02
- (BOOL)performKeyEquivalent:(NSEvent *)event {
	if ((([event modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask) && 
		(([event modifierFlags] & NSShiftKeyMask) == NSShiftKeyMask) &&
		([[event charactersIgnoringModifiers] isEqualToString:keyStringLeft] ||
		 [[event charactersIgnoringModifiers] isEqualToString:@"{"])) {
		[self selectPreviousTabViewItem:self];
		return YES;
	} else if ((([event modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask) && 
			   (([event modifierFlags] & NSShiftKeyMask) == NSShiftKeyMask) &&
			   ([[event charactersIgnoringModifiers] isEqualToString:keyStringRight] ||
				[[event charactersIgnoringModifiers] isEqualToString:@"}"])) {
		[self selectNextTabViewItem:self];
		return YES;
	} else if (([event modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask && 
			   ([event modifierFlags] & NSAlternateKeyMask) == 0 && 
			   ([event modifierFlags] & NSControlKeyMask) == 0 && 
			   ([event modifierFlags] & NSShiftKeyMask) == 0 && 
			   [[event characters] intValue] > 0 && 
			   [[event characters] intValue] < 10) {
		// User may drag and re-order tabs using tabBarControl
		// These re-ordering will not reflect when calling
		//  [self selectTabViewItemAtIndex:index];
		// We here call method from tabBarControl to choose correct tab
		[_tabBarControl selectTabViewItemAtIndex:([[event characters] intValue]-1)];
		return YES;
	} else if (([event modifierFlags] & NSCommandKeyMask) == 0 && 
			   ([event modifierFlags] & NSAlternateKeyMask) == 0 && 
			   ([event modifierFlags] & NSControlKeyMask) && 
			   ([event modifierFlags] & NSShiftKeyMask) == 0 && 
			   [[event characters] characterAtIndex:0] == '\t') {
		[self selectNextTabViewItem:self];
		return YES;
    } else if (([event modifierFlags] & NSCommandKeyMask) == 0 && 
        ([event modifierFlags] & NSAlternateKeyMask) == 0 && 
        ([event modifierFlags] & NSControlKeyMask)  && 
        ([event modifierFlags] & NSShiftKeyMask) && 
        ([event keyCode] == 48)) {
		//keyCode 48: back-tab
		[self selectPreviousTabViewItem:self];
		return YES;
	}
	return NO;
}

#pragma mark -
#pragma mark KVO
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath hasPrefix:@"cell"]) {
		[self setFrameSize:[[WLGlobalConfig sharedInstance] contentSize]];
		// Don't set frame origin here, leave for main controller
		if ([[self subviews] containsObject:_portal]) {
			[_portal setFrame:self.frame];
		}
    }
}

#pragma mark -
#pragma mark Trackpad Gesture Support
// Set and reset font size
- (void)setFontSizeRatio:(CGFloat)ratio {
    // Comments added by gtCarrera
    // If currently there's no tab, this means, there's only the cover flow! 
    // (because that's the only case allowed by our design)
    // If so, we don't change the size of the portal. 
//    if([self numberOfTabViewItems] == 0) {
//        // Shoot, doesn't work now!
//        // [_terminalView showCustomizedPopUpMessage:@"NO TAB"];
//        return;
//    }
	// Or else, just do it..
	[[WLGlobalConfig sharedInstance] setFontSizeRatio:ratio];
	[self setNeedsDisplay:YES];
}

// Increase global font size setting by 5%
- (void)increaseFontSize:(id)sender {
	// Here we use some small trick to provide better user experimence...
	[self setFontSizeRatio:1.05f];
}

// Decrease global font size setting by 5%
- (void)decreaseFontSize:(id)sender {
	[self setFontSizeRatio:1.0f/1.05f];
}

//- (void)magnifyWithEvent:(NSEvent *)event {
//	[self setFontSizeRatio:[event magnification]+1.0];
//}

- (void)swipeWithEvent:(NSEvent *)event {
	if ([event deltaX] < 0) {
		// Swiping to right
		[self selectNextTabViewItem:event];
		return;
	} else if ([event deltaX] > 0) {
		// Swiping to left
		[self selectPreviousTabViewItem:event];
		return;
	}
	[super swipeWithEvent:event];
}
@end
