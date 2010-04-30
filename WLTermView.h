//
//  WLTermView.h
//  Welly
//
//  Created by K.O.ed on 09-11-2.
//  Copyright 2009 Welly Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WLTabView.h"

@class WLTerminal, WLConnection;

@interface WLTermView : NSView <WLTabItemContentObserver> {
	CGFloat _fontWidth;
	CGFloat _fontHeight;
	
	NSImage *_backedImage;
	
	int _x;
	int _y;
	
	int _maxRow;
	int _maxColumn;
	
	WLConnection *_connection;
}
@property CGFloat fontWidth;
@property CGFloat fontHeight;

- (void)updateBackedImage;
- (void)configure;

- (WLTerminal *)frontMostTerminal;
- (WLConnection *)frontMostConnection;
- (BOOL)isConnected;

- (void)refreshDisplay;
- (void)terminalDidUpdate:(WLTerminal *)terminal;

// get current BBS image
- (NSImage *)image;
@end
