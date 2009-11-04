//
//  WLTermView.h
//  Welly
//
//  Created by K.O.ed on 09-11-2.
//  Copyright 2009 Welly Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class WLTerminal, WLConnection;
@interface WLTermView : NSTabView {
	CGFloat _fontWidth;
	CGFloat _fontHeight;
	
	NSImage *_backedImage;
	
	int _x;
	int _y;
	
	int _maxRow;
	int _maxColumn;
}
@property CGFloat fontWidth;
@property CGFloat fontHeight;

- (void)updateBackedImage;
- (void)configure;

- (WLTerminal *)frontMostTerminal;
- (WLConnection *)frontMostConnection;
- (BOOL)isConnected;

- (void)terminalDidUpdate:(WLTerminal *)terminal;
@end
