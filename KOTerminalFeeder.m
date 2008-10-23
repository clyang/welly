//
//  KOTerminalFeeder.m
//  Welly
//
//  Created by K.O.ed on 08-8-11.
//  Copyright 2008 Welly Group. All rights reserved.
//

#import "KOTerminalFeeder.h"
#import "XIIntegerArray.h"
#import "YLTerminal.h"
#import "YLLGlobalConfig.h"
#import "YLConnection.h"

@implementation KOTerminalFeeder

#define CURSOR_MOVETO(x, y)		do {\
_cursorX = (x); _cursorY = (y); \
	if (_cursorX < 0) _cursorX = 0; if (_cursorX >= _column) _cursorX = _column - 1;\
	if (_cursorY < 0) _cursorY = 0; if (_cursorY >= _row) _cursorY = _row - 1;\
} while(0);

#define SET_GRID_BYTE(c) \
if (_cursorX <= _column - 1) { \
	_grid[_cursorY][_cursorX].byte = c; \
	_grid[_cursorY][_cursorX].attr.f.fgColor = _fgColor; \
	_grid[_cursorY][_cursorX].attr.f.bgColor = _bgColor; \
	_grid[_cursorY][_cursorX].attr.f.bold = _bold; \
	_grid[_cursorY][_cursorX].attr.f.underline = _underline; \
	_grid[_cursorY][_cursorX].attr.f.blink = _blink; \
	_grid[_cursorY][_cursorX].attr.f.reverse = _reverse; \
	_grid[_cursorY][_cursorX].attr.f.url = NO; \
	[_terminal setDirty:YES atRow:_cursorY column:_cursorX]; \
	_cursorX++; \
}

BOOL isC0Control(unsigned char c) { return (c <= 0x1F); }
BOOL isSPACE(unsigned char c) { return (c == 0x20 || c == 0xA0); }
BOOL isIntermediate(unsigned char c) { return (c >= 0x20 && c <= 0x2F); }
BOOL isParameter(unsigned char c) { return (c >= 0x30 && c <= 0x3F); }
BOOL isUppercase(unsigned char c) { return (c >= 0x40 && c <= 0x5F); }
BOOL isLowercase(unsigned char c) { return (c >= 0x60 && c <= 0x7E); }
BOOL isDelete(unsigned char c) { return (c == 0x7F); }
BOOL isC1Control(unsigned char c) { return(c >= 0x80 && c <= 0x9F); }
BOOL isG1Displayable(unsigned char c) { return(c >= 0xA1 && c <= 0xFE); }
BOOL isSpecial(unsigned char c) { return(c == 0xA0 || c == 0xFF); }
BOOL isAlphabetic(unsigned char c) { return(c >= 0x40 && c <= 0x7E); }

ASCII_CODE asciiCodeFamily(unsigned char c) {
	if (isC0Control(c)) return C0;
	if (isIntermediate(c)) return INTERMEDIATE;
	if (isAlphabetic(c)) return ALPHABETIC;
	if (isDelete(c)) return DELETE;
	if (isC1Control(c)) return C1;
	if (isG1Displayable(c)) return G1;
	if (isSpecial(c)) return SPECIAL;
	return ERROR;
}

static unsigned short gEmptyAttr;

- (id) init {
	if (self = [super init]) {
		_hasNewMessage = NO;
        _savedCursorX = _savedCursorY = -1;
        _row = [[YLLGlobalConfig sharedInstance] row];
		_column = [[YLLGlobalConfig sharedInstance] column];
        _scrollBeginRow = 0; _scrollEndRow = _row - 1;
		_grid = (cell **) malloc(sizeof(cell *) * _row);
        int i;
        for (i = 0; i < _row; i++) {
			// NOTE: in case _cursorX will exceed _column size (at the border of the
			//		 screen), we allocate one more unit for this array
			_grid[i] = (cell *) malloc(sizeof(cell) * (_column + 1));
		}
		
        [self clearAll];
	}
	return self;
}

- (id) initWithConnection: (YLConnection *) connection {
	if (self == [self init]) {
		_connection = connection;
	}
	return self;
}

- (void)dealloc {
    [_csBuf release];
    [_csArg release];
    for (int i = 0; i < _row; i++)
        free(_grid[i]);
    free(_grid);
    [super dealloc];
}

# pragma mark -
# pragma mark Input Interface
- (void) feedData:(NSData *)data connection:(id)connection {
	[self feedBytes:[data bytes] length:[data length] connection:connection];
}

- (void)feedBytes:(const void *)bytes length:(NSUInteger)len connection:(id)connection {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	int i, x;
	unsigned char c;
	
	if ([_terminal bbsType] == TYFirebird) {
		_hasNewMessage = NO;
	}
	
	//    NSLog(@"length: %d", len);
	for (i = 0; i < len; i++) {
		c = ((const char *)bytes)[i];
		//        if (c == 0x00) continue;
        
		switch (_state)
        {
			case TP_NORMAL:
				if (c == 0x00) {
					// do nothing
				} else if (c == 0x07) { // Beep
					[[NSSound soundNamed: @"Whit.aiff"] play];
					_hasNewMessage = YES;
				} else if (c == 0x08) { // Backspace (BS)
					if (_cursorX > 0)
						_cursorX--;
				} else if (c == 0x09) { // Tab (HT)
					_cursorX = (((int)(_cursorX / 8)) * 8);	// mjhsieh: this implement is not yet tested
				} else if (c == 0x0A || c == 0x0B || c == 0x0C) { // Linefeed (LF) / Vertical tab (VT) / Form feed (FF)
					if (_cursorY == _scrollEndRow) {
						//if ((i != len - 1 && bytes[i + 1] != 0x0A) || 
						//                        (i != 0 && bytes[i - 1] != 0x0A)) {
						//                        [_view updateBackedImage];
						//                        [_view extendBottomFrom: _scrollBeginRow to: _scrollEndRow];
						//                    }
						cell *emptyLine = _grid[_scrollBeginRow];
						[self clearRow: _scrollBeginRow];
						
						for (x = _scrollBeginRow; x < _scrollEndRow; x++) 
							_grid[x] = _grid[x + 1];
						_grid[_scrollEndRow] = emptyLine;
						[_terminal setAllDirty];
					} else {
						_cursorY++;
						if (_cursorY >= _row) _cursorY = _row - 1;
					}
				} else if (c == 0x0D) { // Carriage Return
					_cursorX = 0;
				} else if (c == 0x1B) { // ESC
					_state = TP_ESCAPE;
					//			} else if (c == 0x9B) { // Control Sequence Introducer
					//				[_csBuf clear];
					//				[_csArg->clear];
					//				_csTemp = 0;
					//				_state = TP_CONTROL;
				} else {
					SET_GRID_BYTE(c);
				}
				
				break;
				
			case TP_ESCAPE:
				if (c == 0x5B) { // 0x5B == '['
					[_csBuf clear];
					[_csArg clear];
					_csTemp = 0;
					_state = TP_CONTROL;
				} else if (c == 'M') { // scroll down (cursor up)
					if (_cursorY == _scrollBeginRow) {
						//[_view updateBackedImage];
						//[_view extendTopFrom: _scrollBeginRow to: _scrollEndRow];
						cell *emptyLine = _grid[_scrollEndRow];
						[self clearRow: _scrollEndRow];
						
						for (x = _scrollEndRow; x > _scrollBeginRow; x--) 
							_grid[x] = _grid[x - 1];
						_grid[_scrollBeginRow] = emptyLine;
						[_terminal setAllDirty];
					} else {
						_cursorY--;
						if (_cursorY < 0) _cursorY = 0;
					}
					_state = TP_NORMAL;
				} else if (c == 'D') { // scroll up (cursor down)
					if (_cursorY == _scrollEndRow) {
						//[_view updateBackedImage];
						//[_view extendBottomFrom: _scrollBeginRow to: _scrollEndRow];
						cell *emptyLine = _grid[_scrollBeginRow];
						[self clearRow: _scrollBeginRow];
						
						for (x = _scrollBeginRow; x < _scrollEndRow; x++) 
							_grid[x] = _grid[x + 1];
						_grid[_scrollEndRow] = emptyLine;
						[_terminal setAllDirty];
					} else {
						_cursorY++;
						if (_cursorY >= _row) _cursorY = _row - 1;
					}
					_state = TP_NORMAL;
				} else if (c == '7') { // Save cursor
					_savedCursorX = _cursorX;
					_savedCursorY = _cursorY;
					_state = TP_NORMAL;
				} else if (c == '8') { // Restore cursor
					_cursorX = _savedCursorX;
					_cursorY = _savedCursorY;
					_state = TP_NORMAL;
				} else if (c == 0x3D ) { // Application keypad mode (vt52)
					NSLog(@"Application keypad mode request ignored");
					_state = TP_NORMAL;
				} else if (c == 0x3E ) { // Numeric keypad mode (vt52)
					NSLog(@"Numeric keypad mode request ignored");
					_state = TP_NORMAL;
				} else {
					NSLog(@"unprocessed esc: %c(0x%X)", c, c);
					_state = TP_NORMAL;
				}
				
				break;
				
			case TP_CONTROL:
				if (isParameter(c)) {
					[_csBuf push_back:c];
					if (c >= '0' && c <= '9') {
						_csTemp = _csTemp * 10 + (c - '0');
					} else if (![_csBuf empty]) {
						[_csArg push_back:_csTemp];
						_csTemp = 0;
						[_csBuf clear];
					}
				} else {
					if (![_csBuf empty]) {
						[_csArg push_back:_csTemp];
						_csTemp = 0;
						[_csBuf clear];
					}
					
					if (NO) {
						// just for code alignment...
					} else if (c == 'A') {		// Cursor Up
						if ([_csArg size] > 0)
							_cursorY -= [_csArg front];
						else
							_cursorY--;
						
						if (_cursorY < 0) _cursorY = 0;
					} else if (c == 'B') {		// Cursor Down
						if ([_csArg size] > 0)
							_cursorY += [_csArg front];
						else
							_cursorY++;
						
						if (_cursorY >= _row) _cursorY = _row - 1;
					} else if (c == 'C') {		// Cursor Right
						if ([_csArg size] > 0)
							_cursorX += [_csArg front];
						else
							_cursorX++;
						
						if (_cursorX >= _column) _cursorX = _column - 1;					
					} else if (c == 'D') {		// Cursor Left
						if ([_csArg size] > 0)
							_cursorX -= [_csArg front];
						else
							_cursorX--;
						
						if (_cursorX < 0) _cursorX = 0;
					} else if (c == 'f' || c == 'H') {	// Cursor Position
						/* 
						 ^[H			: go to row 1, column 1
						 ^[3H		: go to row 3, column 1
						 ^[3;4H		: go to row 3, column 4
						 */
						if ([_csArg size] == 0) {
							_cursorX = 0, _cursorY = 0;
						} else if ([_csArg size] == 1) {
							if ([_csArg front] < 1) [_csArg set:1 at:0];
							CURSOR_MOVETO(0, [_csArg front] - 1);
						} else {
							if ([_csArg front] < 1) [_csArg set:1 at:0];
							if ([_csArg at:1] < 1) [_csArg set:1 at:1];
							//                        NSLog(@"jump %d %d", [_csArg front], [_csArg at:1]);
							CURSOR_MOVETO([_csArg at:1] - 1, [_csArg front] - 1);
							//                        [self setDirty: YES atRow: _cursorY column: _cursorX];
						}
					} else if (c == 'J') {		// Erase Region (cursor does not move)
						/* 
						 ^[J, ^[0J	: clear from cursor position to end
						 ^[1J		: clear from start to cursor position
						 ^[2J		: clear all
						 */
						int j;
						if ([_csArg size] == 0 || [_csArg front] == 0) {
							[self clearRow: _cursorY fromStart: _cursorX toEnd: _column - 1];
							for (j = _cursorY + 1; j < _row; j++)
								[self clearRow: j];
						} else if ([_csArg size] == 1 && [_csArg front] == 1) {
							[self clearRow: _cursorY fromStart: 0 toEnd: _cursorX];
							for (j = 0; j < _cursorY; j++)
								[self clearRow: j];
						} else if ([_csArg size] == 1 && [_csArg front] == 2) {
							[self clearAll];
						}
					} else if (c == 'K') {		// Erase Line (cursor does not move)
						/* 
						 ^[K, ^[0K	: clear from cursor position to end of line
						 ^[1K		: clear from start of line to cursor position
						 ^[2K		: clear whole line
						 */
						if ([_csArg size] == 0 || [_csArg front] == 0) {
							[self clearRow:_cursorY fromStart:_cursorX toEnd:(_column - 1)];
						} else if ([_csArg size] == 1 && [_csArg front] == 1) {
							[self clearRow: _cursorY fromStart:0 toEnd:_cursorX];
						} else if ([_csArg size] == 1 && [_csArg front] == 2) {
							[self clearRow:_cursorY];
						}
					} else if (c == 'L') {      // Insert Line
						int lineNumber = 0;
						if ([_csArg size] == 0) 
							lineNumber = 1;
						else if ([_csArg size] > 0)
							lineNumber = [_csArg front];
						
						int i;
						for (i = 0; i < lineNumber; i++) {
							[self clearRow: _row - 1];
							cell *emptyRow = [self cellsOfRow: _row - 1];
							int r;
							for (r = _row - 1; r > _cursorY; r--)
								_grid[r] = _grid[r - 1];
							_grid[_cursorY] = emptyRow;
						}
						for (i = _cursorY; i < _row; i++)
							[_terminal setDirtyForRow: i];
					} else if (c == 'M') {      // Delete Line
						int lineNumber = 0;
						if ([_csArg size] == 0) 
							lineNumber = 1;
						else if ([_csArg size] > 0)
							lineNumber = [_csArg front];
						
						int i;
						for (i = 0; i < lineNumber; i++) {
							[self clearRow: _cursorY];
							cell *emptyRow = [self cellsOfRow: _cursorY];
							int r;
							for (r = _cursorY; r < _row - 1; r++)
								_grid[r] = _grid[r + 1];
							_grid[_row - 1] = emptyRow;
						}
						for (i = _cursorY; i < _row; i++)
							[_terminal setDirtyForRow: i];
					} else if (c == 'h') {          // set mode
						NSLog(@"control sequence: set mode is not implemented yet.");
					} else if (c == 'l') {          // reset mode
						NSLog(@"control sequence: reset mode is not implemented yet.");
					} else if (c == 'm') { 
						if ([_csArg empty]) { // clear
							_fgColor = 7;
							_bgColor = 9;
							_bold = NO;
							_underline = NO;
							_blink = NO;
							_reverse = NO;
						} else {
							while (![_csArg empty]) {
								int p = [_csArg front];
								[_csArg pop_front];
								if (p == 0) {
									_fgColor = 7;
									_bgColor = 9;
									_bold = NO;
									_underline = NO;
									_blink = NO;
									_reverse = NO;
								} else if (30 <= p && p <= 39) {
									_fgColor = p - 30;
								} else if (40 <= p && p <= 49) {
									_bgColor = p - 40;
									// added by K.O.ed, *[40m should use background color but not black color
									if (p == 40)
										_bgColor = [YLLGlobalConfig sharedInstance]->_bgColorIndex;
								} else if (p == 1) {
									_bold = YES;
								} else if (p == 4) {
									_underline = YES;
								} else if (p == 5) {
									_blink = YES;
								} else if (p == 7) {
									_reverse = YES;
								}
							}
						}
					} else if (c == 'r') {
						if ([_csArg size] == 0) {
							_scrollBeginRow = 0;
							_scrollEndRow = _row - 1;
						} else if ([_csArg size] == 2) {
							int s = [_csArg front];
							int e = [_csArg at:1];
							if (s > e) s = [_csArg at:1], e = [_csArg front];
							_scrollBeginRow = s - 1;
							_scrollEndRow = e - 1;
						}
					} else if (c == 's') {
						_savedCursorX = _cursorX;
						_savedCursorY = _cursorY;
					} else if (c == 'u') {
						if (_savedCursorX >= 0 && _savedCursorY >= 0) {
							_cursorX = _savedCursorX;
							_cursorY = _savedCursorY;
						}
					} else {
						NSLog(@"unsupported control sequence: %c", c);
					}
					[_csArg clear];
					_state = TP_NORMAL;
				}
				
				break;
		}
	}
	[_terminal setCursorX: _cursorX Y: _cursorY];
	[_terminal feedGrid: _grid];
	
	if (_hasNewMessage) {
		// new incoming message
		if ([_terminal bbsType] == TYMaple && _grid[_row - 1][0].attr.f.bgColor != 9 && _grid[_row - 1][_column - 2].attr.f.bgColor == 9) {
			// for maple bbs (e.g. ptt)
			for (i = 2; i < _column && _grid[_row - 1][i].attr.f.bgColor == _grid[_row - 1][i - 1].attr.f.bgColor; ++i); // split callerName and messageString
			int splitPoint = i++;
			for (; i < _column && _grid[_row - 1][i].attr.f.bgColor == _grid[_row - 1][i - 1].attr.f.bgColor; ++i); // determine the end of the message
			NSString *callerName = [_terminal stringFromIndex: ((_row - 1) * _column + 2) length: (splitPoint - 2)];
			NSString *messageString = [_terminal stringFromIndex: ((_row - 1) * _column + splitPoint + 1) length: (i - splitPoint - 2)];
			
			[_connection newMessage: messageString fromCaller: callerName];
			_hasNewMessage = NO;
		} else if ([_terminal bbsType] == TYFirebird && _grid[0][0].attr.f.bgColor != 9) {
			// for firebird bbs (e.g. smth)
			for (i = 2; i < _row && _grid[i][0].attr.f.bgColor != 9; ++i);	// determine the end of the message
			NSString *callerName = [_terminal stringFromIndex: 0 length: _column];
			NSString *messageString = [_terminal stringFromIndex: _column length: (i - 1) * _column];
			
			[_connection newMessage: messageString fromCaller: callerName];
		}
    }
	
    [pool release];
}

- (void) setTerminal: (YLTerminal *) terminal {
	_terminal = terminal;
	[_terminal setConnection: _connection];
}


# pragma mark -
# pragma mark Clear

- (void)clearAll {
    _cursorX = _cursorY = 0;
	
    attribute t;
    t.f.fgColor = [YLLGlobalConfig sharedInstance]->_fgColorIndex;
    t.f.bgColor = [YLLGlobalConfig sharedInstance]->_bgColorIndex;
    t.f.bold = 0;
    t.f.underline = 0;
    t.f.blink = 0;
    t.f.reverse = 0;
    t.f.url = 0;
    t.f.nothing = 0;
    gEmptyAttr = t.v;
	
    _fgColor = [YLLGlobalConfig sharedInstance]->_fgColorIndex;
    _bgColor = [YLLGlobalConfig sharedInstance]->_bgColorIndex;
    _csTemp = 0;
    _state = TP_NORMAL;
    _bold = NO;
	_underline = NO;
	_blink = NO;
	_reverse = NO;
	
    int i;
    for (i = 0; i < _row; i++) 
        [self clearRow: i];
    
    if (_csBuf)
        [_csBuf clear];
    else
        _csBuf = [[XIIntegerArray integerArray] retain];
    if (_csArg)
        [_csArg clear];
    else
        _csArg = [[XIIntegerArray integerArray] retain];
}

- (void) clearRow: (int) r {
    [self clearRow: r fromStart: 0 toEnd: _column - 1];
}

- (void) clearRow: (int) r fromStart: (int) s toEnd: (int) e {
    int i;
    for (i = s; i <= e; i++) {
        _grid[r][i].byte = '\0';
        _grid[r][i].attr.v = gEmptyAttr;
        _grid[r][i].attr.f.bgColor = _bgColor;
		[_terminal setDirty:YES atRow:r column:i];
    }
}

- (cell *) cellsOfRow: (int) r {
	return _grid[r];
}

@end
