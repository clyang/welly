//
//  YLMarkedTextView.h
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 9/29/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface YLMarkedTextView : NSView {
	NSAttributedString *_string;
	NSRange _markedRange;
	NSRange _selectedRange;
	NSFont *_defaultFont;
	CGFloat _lineHeight;
	NSPoint _destination;
}

- (NSAttributedString *)string;
- (void)setString:(NSAttributedString *)value;

- (NSRange)markedRange;
- (void)setMarkedRange:(NSRange)value;

- (NSRange)selectedRange;
- (void)setSelectedRange:(NSRange)value;

- (NSFont *)defaultFont;
- (void)setDefaultFont:(NSFont *)value;

- (NSPoint)destination;
- (void)setDestination:(NSPoint)value;

@end
