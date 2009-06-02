//
//  WLTerminalFeeder.h
//  Welly
//
//  Created by K.O.ed on 08-8-11.
//  Copyright 2008 Welly Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CommonType.h"

@class YLConnection, WLIntegerArray, YLTerminal;

@interface WLTerminalFeeder : NSObject {
    unsigned int _row;
    unsigned int _column;
    int _cursorX;
    int _cursorY;
    unsigned int _offset;
	
    int _savedCursorX;
    int _savedCursorY;
	
    int _fgColor;
    int _bgColor;
    BOOL _bold;
    BOOL _underline;
    BOOL _blink;
    BOOL _reverse;
	
    cell **_grid;
	
    enum { TP_NORMAL, TP_ESCAPE, TP_CONTROL, TP_SCS } _state;
	
    WLIntegerArray *_csBuf;
    WLIntegerArray *_csArg;
    unsigned int _csTemp;
	
    int _scrollBeginRow;
    int _scrollEndRow;
	
	YLTerminal *_terminal;
	YLConnection *_connection;
	
	BOOL _hasNewMessage;	// to determine if a growl notification is needed
	
    enum { VT100, VT102 } _emustd;
	
    BOOL _modeScreenReverse;  // reverse (true), not reverse (false, default)
	BOOL _modeOriginRelative; // relative origin (true), absolute origin (false, default)
    BOOL _modeWraptext;       // autowrap (true, default), wrap disabled (false)
    BOOL _modeLNM;            // line feed (true, default), new line (false)
    BOOL _modeIRM;            // insert (true), replace (false, default)
}
@property int cursorX;
@property int cursorY;
@property cell **grid;

- (id)init;
- (id)initWithConnection:(YLConnection *)connection;
- (void)dealloc;

/* Input Interface */
- (void)feedData:(NSData *)data connection:(id)connection;
- (void)feedBytes:(const unsigned char*)bytes 
		   length:(NSUInteger)len 
	   connection:(id)connection;

- (void)setTerminal:(YLTerminal *)terminal;

/* Clear */
- (void)clearAll;

- (cell *)cellsOfRow:(int)r;
@end
