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

typedef struct {
	enum {
		BBSUnknown, 
		BBSMainMenu, 
		BBSBoardList, 
		BBSFriendList, 
		BBSBrowseBoard, 
		BBSViewPost, 
		BBSComposePost
	} state;
	NSString *boardName;
	int cursorRow;
} BBSState;

@interface YLTerminal : NSObject {	
	TYBBSType _bbsType;
@public
    unsigned int _row;
    unsigned int _column;
    unsigned int _cursorX;
    unsigned int _cursorY;
    unsigned int _offset;
	
    cell **_grid;
    char *_dirty;

    YLView *_view;

    YLConnection *_connection;
	
	BBSState _bbsState;
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
- (void)updateURLStateForRow:(int)r;
- (void)updateDoubleByteStateForRow:(int)r;
- (NSString *)urlStringAtRow:(int)r column:(int)c;
- (void)updateBBSState;

/* Accessor */
- (int)cursorRow;
- (int)cursorColumn;
- (YLEncoding)encoding;
- (void)setEncoding:(YLEncoding) encoding;
- (YLConnection *)connection;
- (void)setConnection:(YLConnection *)value;
- (BBSState)bbsState;
- (TYBBSType)bbsType;
- (void)setBbsType:(TYBBSType)bbsType;

/* Input Interface */
- (void)feedGrid: (cell **)grid;
- (void)setCursorX: (int) cursorX
				 Y: (int) cursorY;
@end
