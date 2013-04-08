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
@property (readwrite, copy, nonatomic) NSAttributedString *string;
@property (readwrite, assign, nonatomic) NSRange markedRange;
@property (readwrite, assign, nonatomic) NSRange selectedRange;
@property (readwrite, copy, nonatomic) NSFont *defaultFont;
@property (readwrite, assign, nonatomic) NSPoint destination;
@end
