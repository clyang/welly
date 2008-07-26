//
//  YLTerminal.h
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/9/10.
//  Copyright 2006 yllan.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CommonType.h"
#import "YLView.h"
#import "YLConnection.h"
#import "KOAutoReplyDelegate.h"
#ifdef __cplusplus
#import <deque>
typedef std::deque<unsigned char> uchar_queue;
typedef std::deque<int> int_queue;
#else
typedef void uchar_queue;
typedef void int_queue;
#endif


@interface YLTerminal : NSObject {	
@public
    unsigned int _row;
    unsigned int _column;
    unsigned int _cursorX;
    unsigned int _cursorY;
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
    char *_dirty;

    enum { TP_NORMAL, TP_ESCAPE, TP_CONTROL } _state;

    uchar_queue *_csBuf;
    int_queue *_csArg;
    unsigned int _csTemp;
    YLView *_view;
    
    int _scrollBeginRow;
    int _scrollEndRow;

    int _messageCount;
    YLConnection *_connection;

    KOAutoReplyDelegate *_autoReplyDelegate;
}

+ (YLTerminal *)terminalWithView:(YLView *)view;

/* Input Interface */
- (void)feedData:(NSData *)data connection:(id)connection;
- (void)feedBytes:(const void *)bytes length:(NSUInteger)len connection:(id)connection;

/* Start / Stop */
- (void)startConnection;
- (void)closeConnection;

/* Clear */
- (void)clearRow:(int)r;
- (void)clearRow:(int)r fromStart:(int)s toEnd:(int)e;
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

/* Accessor */
- (int)cursorRow;
- (int)cursorColumn;
- (YLEncoding)encoding;
- (void)setEncoding:(YLEncoding) encoding;
- (int)messageCount;
- (void)increaseMessageCount:(int)value;
- (void)resetMessageCount;
- (YLConnection *)connection;
- (void)setConnection:(YLConnection *)value;
- (KOAutoReplyDelegate *)autoReplyDelegate;
@end
