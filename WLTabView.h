//
//  WLTabView.h
//  Welly
//
//  Created by K.O.ed on 10-4-20.
//  Copyright 2010 Welly Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WLSitesPanelController.h"

@class WLTerminalView;
@class WLCoverFlowPortal;
@class WLConnection;
@class WLTerminal;

@protocol WLTabItemIdentifierObserver

- (void)didChangeIdentifier:(id)theIdentifier;

@end


@interface WLTabView : NSTabView <WLSitesObserver> {
	NSView *_frontMostView;
	NSArray *_tabViews;
	
	IBOutlet WLTerminalView *_terminalView;
	
	WLCoverFlowPortal *_portal;
}

- (void)newTabWithConnection:(WLConnection *)theConnection 
					   label:(NSString *)theLabel;
- (void)newTabWithCoverFlowPortal;

- (NSView *)frontMostView;
- (WLConnection *)frontMostConnection;
- (WLTerminal *)frontMostTerminal;

@end
