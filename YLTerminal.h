//
//  YLTerminal.h
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/9/10.
//  Copyright 2006 yllan.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CommonType.h"

@class YLView, YLConnection, WLMessageDelegate, WLIntegerArray;

@interface YLTerminal : NSObject {	
	WLBBSType _bbsType;
	
    unsigned int _maxRow;
    unsigned int _maxColumn;
    unsigned int _cursorColumn;
    unsigned int _cursorRow;
    unsigned int _offset;
	
    cell **_grid;
    char *_dirty;

    YLView *_view;

    YLConnection *_connection;
	
	BBSState _bbsState;
	
	unichar *_textBuf;
}
@property unsigned int maxRow;
@property unsigned int maxColumn;
@property unsigned int cursorColumn;
@property unsigned int cursorRow;
@property cell **grid;
@property (assign, setter=setConnection:) YLConnection *connection;
@property (assign, readwrite) WLBBSType bbsType;
@property (readonly) BBSState bbsState;

+ (YLTerminal *)terminalWithView:(YLView *)view;

/* Start / Stop */
- (void)startConnection;
- (void)closeConnection;

/* Clear */
- (void)clearAll;

/* Dirty */
- (BOOL)isDirtyAtRow:(int)r 
			  column:(int)c;
- (void)setAllDirty;
- (void)setDirty:(BOOL)d 
		   atRow:(int)r 
		  column:(int)c;
- (void)setDirtyForRow:(int)r;

/* Access Data */
- (attribute)attrAtRow:(int)r 
				column:(int)c ;
- (NSString *)stringFromIndex:(int)begin 
					   length:(int)length;
- (cell *)cellsOfRow:(int)r;
- (cell)cellAtIndex:(int)index;

/* Update State */
- (void)updateDoubleByteStateForRow:(int)r;
- (void)updateBBSState;

/* Accessor */
- (YLEncoding)encoding;
- (void)setEncoding:(YLEncoding)encoding;

/* Input Interface */
- (void)feedGrid:(cell **)grid;
- (void)setCursorX:(int)cursorX
				 Y:(int)cursorY;
@end
