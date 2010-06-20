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

#import "WLTabViewItemController.h"

#import "WLGlobalConfig.h"

#import "WLBookmarkPortalItem.h"
#import "WLNewBookmarkPortalItem.h"
#import "WLCoverFlowPortal.h"

@interface WLTabView ()

- (void)updatePortal;
- (void)resetFrame;
- (void)showPortal;

@end


@implementation WLTabView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		// Initialize the portal
		_portal = [[WLCoverFlowPortal alloc] initWithFrame:[self frame]];
    }
    return self;
}

- (void)awakeFromNib {
	[self setTabViewType:NSNoTabsNoBorder];
	
	// Register as sites observer
	[WLSitesPanelController addSitesObserver:self];
	
	// Register KVO
	NSArray *observeKeys = [NSArray arrayWithObjects:@"cellWidth", @"cellHeight", nil];
	for (NSString *key in observeKeys)
		[[WLGlobalConfig sharedInstance] addObserver:self
										  forKeyPath:key
											 options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) 
											 context:nil];
	
	[self resetFrame];
	[self updatePortal];
	
	// If no active tabs, we should show the coverflow portal if necessary.
	if ([self numberOfTabViewItems] == 0) {
		[self showPortal];
	}
}

#pragma mark -
#pragma mark Drawing
- (void)drawRect:(NSRect)rect {
    // Drawing the background.
	[[[WLGlobalConfig sharedInstance] colorBG] set];
	NSRectFill(rect);
}

- (void)setFrame:(NSRect)frameRect {
	[super setFrame:frameRect];
	[self setNeedsDisplay:YES];
	[_terminalView setFrame:frameRect];
	[_portal setFrame:frameRect];
	[_terminalView setNeedsDisplay:YES];
	[_portal setNeedsDisplay:YES];
}

- (void)resetFrame {
	NSRect frame = [self frame];
	frame.origin = NSZeroPoint;
	frame.size = [[WLGlobalConfig sharedInstance] contentSize];
	
	[self setFrame:frame];
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

#pragma mark -
#pragma mark KVO
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath hasPrefix:@"cell"]) {
        [self resetFrame];
    }
}
@end
