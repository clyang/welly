//
//  YLTerminal.h
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/9/10.
//  Copyright 2006 yllan.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CommonType.h"

@class YLView, YLConnection, KOAutoReplyDelegate, XIIntegerArray;

@interface YLTerminal : NSObject {	
@public
    unsigned int _row;
    unsigned int _column;
    unsigned int _cursorX;
    unsigned int _cursorY;
    unsigned int _offset;
	
    cell **_grid;
    char *_dirty;

    //enum { TP_NORMAL, TP_ESCAPE, TP_CONTROL } _state;
    YLView *_view;

    YLConnection *_connection;
}

+ (YLTerminal *)terminalWithView:(YLView *)view;

/* Start / Stop */
- (void)startConnection;
- (void)closeConnection;

/* Clear */
- (void)clearAll;

/* Dirty */
- (BOOL)isDirtyAtRow:(int)r column:(int)c;
- (void)setAllDirty;
- (void)setDirty:(BOOL)d atRow:(int)r column:(int)c;
- (void)setDirtyForRow:(int)r;

/* Access Data */
- (attribute)attrAtRow:(int)r column:(int)c ;
- (NSString *)stringFromIndex:(int)begin length:(int)length;
- (cell *)cellsOfRow:(int)r;

/* Update State */
//- (void)updateIPStateForRow:(int)r;
- (void)updateURLStateForRow:(int)r;
- (void)updateDoubleByteStateForRow:(int)r;
- (NSString *)urlStringAtRow:(int)r column:(int)c;

/* Accessor */
- (int)cursorRow;
- (int)cursorColumn;
- (YLEncoding)encoding;
- (void)setEncoding:(YLEncoding) encoding;
- (YLConnection *)connection;
- (void)setConnection:(YLConnection *)value;

/* Input Interface */
- (void)feedGrid: (cell **)grid;
- (void)setCursorX: (int) cursorX
				 Y: (int) cursorY;
@end
