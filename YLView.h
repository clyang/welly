//
//  YLView.h
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/6/9.
//  Copyright 2006 yllan.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CommonType.h"

@class YLTerminal;
@class YLConnection;
@class YLMarkedTextView;
@class XIPortal;

@interface YLView : NSTabView <NSTextInput> {	
	CGFloat _fontWidth;
	CGFloat _fontHeight;
	
	NSImage *_backedImage;
	
	NSTimer *_timer;
	int _x;
	int _y;
	
	id _markedText;
	NSRange _selectedRange;
	NSRange _markedRange;
	
	IBOutlet YLMarkedTextView *_textField;
    
    int _selectionLocation;
    int _selectionLength;
    
    XIPortal *_portal;
}

- (void) configure ;

- (void) pasteWrap: (id) sender ;
- (void) paste: (id) sender ;
- (void) pasteColor: (id) sender ;

- (void) displayCellAtRow: (int) r column: (int) c;
- (void) updateBackedImage;
- (void) drawSelection ;
- (void) drawBlink ;
- (void) refreshHiddenRegion;

- (void) clearSelection;

- (YLTerminal *)frontMostTerminal;
- (YLConnection *)frontMostConnection;
- (BOOL)connected;

- (void) extendBottomFrom: (int) start to: (int) end;
- (void) extendTopFrom: (int) start to: (int) end ;

- (void) drawStringForRow: (int) r context: (CGContextRef) myCGContext ;
- (void) updateBackgroundForRow: (int) r from: (int) start to: (int) end ;

- (int)x;
- (void)setX:(int)value;

- (int)y;
- (void)setY:(int)value;

- (float) fontWidth;
- (void) setFontWidth:(float)value;

- (float) fontHeight;
- (void) setFontHeight:(float)value;

- (NSString *) selectedPlainString ;
- (BOOL) hasBlinkCell ;

- (void) insertText: (id) aString withDelay: (int) microsecond ;
@end
