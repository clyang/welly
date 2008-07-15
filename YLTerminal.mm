//
//  YLTerminal.m
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/9/10.
//  Copyright 2006 yllan.org. All rights reserved.
//

#import "YLTerminal.h"
#import "YLLGlobalConfig.h"
#import "encoding.h"
#import "TYGrowlBridge.h"
#import "KOAutoReplyDelegate.h"

#define CURSOR_MOVETO(x, y)		do {\
									_cursorX = (x); _cursorY = (y); \
									if (_cursorX < 0) _cursorX = 0; if (_cursorX >= _column) _cursorX = _column - 1;\
									if (_cursorY < 0) _cursorY = 0; if (_cursorY >= _row) _cursorY = _row - 1;\
								} while(0);


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

@interface YLTerminal ()
- (void) setDelegate: (id) d;
- (id) delegate;
@end;

@implementation YLTerminal

+ (YLTerminal *)terminalWithView:(YLView *)view {
    YLTerminal *terminal = [[YLTerminal alloc] init];
    [terminal setDelegate:view];
    return [terminal autorelease];
}

- (id) init {
	if (self = [super init]) {
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
		_dirty = (char *) malloc(sizeof(char) * (_row * _column));
		
		_autoReplyDelegate = [[KOAutoReplyDelegate alloc] init];
		[_autoReplyDelegate setConnection: _connection];
        [self clearAll];
	}
	return self;
}

- (void) dealloc {
	delete _csBuf;
	delete _csArg;
    int i;
    for (i = 0; i < _row; i++)
        free(_grid[i]);
    free(_grid);
	[_autoReplyDelegate dealloc];
	[super dealloc];
}

# pragma mark -
# pragma mark Input Interface
- (void) feedData: (NSData *) data connection: (id) connection{
	[self feedBytes: (const unsigned char *)[data bytes] length: [data length] connection: connection];
}

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
    [self setDirty: YES atRow: _cursorY column: _cursorX]; \
    _cursorX++; \
}

- (void) feedBytes: (const unsigned char *) bytes length: (int) len connection: (id) connection {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

	int i, x;
	unsigned char c;
	BOOL hasNewMessage = NO;	// to determine if a growl notification is needed

//    NSLog(@"length: %d", len);
	for (i = 0; i < len; i++) {
		c = bytes[i];
//        if (c == 0x00) continue;
        
		switch (_state)
        {
        case TP_NORMAL:
            if (c == 0x00) {
                // do nothing
            } else if (c == 0x07) { // Beep
				[[NSSound soundNamed: @"Whit.aiff"] play];
				hasNewMessage = YES;
			} else if (c == 0x08) { // Backspace (BS)
				if (_cursorX > 0)
					_cursorX--;
			} else if (c == 0x09) { // Tab (HT)
				_cursorX = (int(_cursorX / 8) * 8);	// mjhsieh: this implement is not yet tested
			} else if (c == 0x0A || c == 0x0B || c == 0x0C) { // Linefeed (LF) / Vertical tab (VT) / Form feed (FF)
				if (_cursorY == _scrollEndRow) {
                    //if ((i != len - 1 && bytes[i + 1] != 0x0A) || 
//                        (i != 0 && bytes[i - 1] != 0x0A)) {
//                        [_delegate updateBackedImage];
//                        [_delegate extendBottomFrom: _scrollBeginRow to: _scrollEndRow];
//                    }
                    cell *emptyLine = _grid[_scrollBeginRow];
                    [self clearRow: _scrollBeginRow];
                    
                    for (x = _scrollBeginRow; x < _scrollEndRow; x++) 
                        _grid[x] = _grid[x + 1];
                    _grid[_scrollEndRow] = emptyLine;
					[self setAllDirty];
				} else {
					_cursorY++;
                    if (_cursorY >= _row) _cursorY = _row - 1;
				}
			} else if (c == 0x0D) { // Carriage Return
				_cursorX = 0;
			} else if (c == 0x1B) { // ESC
				_state = TP_ESCAPE;
//			} else if (c == 0x9B) { // Control Sequence Introducer
//				_csBuf->clear();
//				_csArg->clear();
//				_csTemp = 0;
//				_state = TP_CONTROL;
			} else {
                SET_GRID_BYTE(c);
			}

            break;

        case TP_ESCAPE:
			if (c == 0x5B) { // 0x5B == '['
				_csBuf->clear();
				_csArg->clear();
				_csTemp = 0;
				_state = TP_CONTROL;
			} else if (c == 'M') { // scroll down (cursor up)
				if (_cursorY == _scrollBeginRow) {
					[_delegate updateBackedImage];
					[_delegate extendTopFrom: _scrollBeginRow to: _scrollEndRow];
                    cell *emptyLine = _grid[_scrollEndRow];
                    [self clearRow: _scrollEndRow];
                    
                    for (x = _scrollEndRow; x > _scrollBeginRow; x--) 
                        _grid[x] = _grid[x - 1];
                    _grid[_scrollBeginRow] = emptyLine;
					[self setAllDirty];
				} else {
					_cursorY--;
                    if (_cursorY < 0) _cursorY = 0;
				}
				_state = TP_NORMAL;
            } else if (c == 'D') { // scroll up (cursor down)
                if (_cursorY == _scrollEndRow) {
					[_delegate updateBackedImage];
					[_delegate extendBottomFrom: _scrollBeginRow to: _scrollEndRow];
                    cell *emptyLine = _grid[_scrollBeginRow];
                    [self clearRow: _scrollBeginRow];
                    
                    for (x = _scrollBeginRow; x < _scrollEndRow; x++) 
                        _grid[x] = _grid[x + 1];
                    _grid[_scrollEndRow] = emptyLine;
					[self setAllDirty];
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
				_csBuf->push_back(c);
				if (c >= '0' && c <= '9') {
					_csTemp = _csTemp * 10 + (c - '0');
				} else if (!_csBuf->empty()) {
					_csArg->push_back(_csTemp);
					_csTemp = 0;
					_csBuf->clear();
				}
			} else {
				if (!_csBuf->empty()) {
					_csArg->push_back(_csTemp);
					_csTemp = 0;
					_csBuf->clear();
				}
				
				if (NO) {
					// just for code alignment...
				} else if (c == 'A') {		// Cursor Up
					if (_csArg->size() > 0)
						_cursorY -= _csArg->front();
					else
						_cursorY--;
					
					if (_cursorY < 0) _cursorY = 0;
				} else if (c == 'B') {		// Cursor Down
					if (_csArg->size() > 0)
						_cursorY += _csArg->front();
					else
						_cursorY++;
					
					if (_cursorY >= _row) _cursorY = _row - 1;
				} else if (c == 'C') {		// Cursor Right
					if (_csArg->size() > 0)
						_cursorX += _csArg->front();
					else
						_cursorX++;
					
					if (_cursorX >= _column) _cursorX = _column - 1;					
				} else if (c == 'D') {		// Cursor Left
					if (_csArg->size() > 0)
						_cursorX -= _csArg->front();
					else
						_cursorX--;
					
					if (_cursorX < 0) _cursorX = 0;
				} else if (c == 'f' || c == 'H') {	// Cursor Position
					/* 
						^[H			: go to row 1, column 1
						^[3H		: go to row 3, column 1
						^[3;4H		: go to row 3, column 4
					 */
					if (_csArg->size() == 0) {
						_cursorX = 0, _cursorY = 0;
					} else if (_csArg->size() == 1) {
                        if ((*_csArg)[0] < 1) (*_csArg)[0] = 1;
						CURSOR_MOVETO(0, _csArg->front() - 1);
					} else {
                        if ((*_csArg)[0] < 1) (*_csArg)[0] = 1;
                        if ((*_csArg)[1] < 1) (*_csArg)[1] = 1;
//                        NSLog(@"jump %d %d", (*_csArg)[0], (*_csArg)[1]);
						CURSOR_MOVETO((*_csArg)[1] - 1, (*_csArg)[0] - 1);
//                        [self setDirty: YES atRow: _cursorY column: _cursorX];
					}
				} else if (c == 'J') {		// Erase Region (cursor does not move)
					/* 
						^[J, ^[0J	: clear from cursor position to end
						^[1J		: clear from start to cursor position
						^[2J		: clear all
					 */
					int j;
					if (_csArg->size() == 0 || _csArg->front() == 0) {
                        [self clearRow: _cursorY fromStart: _cursorX toEnd: _column - 1];
                        for (j = _cursorY + 1; j < _row; j++)
                            [self clearRow: j];
                    } else if (_csArg->size() == 1 && _csArg->front() == 1) {
                        [self clearRow: _cursorY fromStart: 0 toEnd: _cursorX];
                        for (j = 0; j < _cursorY; j++)
                            [self clearRow: j];
                    } else if (_csArg->size() == 1 && _csArg->front() == 2) {
                        [self clearAll];
                    }
				} else if (c == 'K') {		// Erase Line (cursor does not move)
					/* 
						^[K, ^[0K	: clear from cursor position to end of line
						^[1K		: clear from start of line to cursor position
						^[2K		: clear whole line
					 */
					if (_csArg->size() == 0 || _csArg->front() == 0) {
                        [self clearRow: _cursorY fromStart: _cursorX toEnd: _column - 1];
                    } else if (_csArg->size() == 1 && _csArg->front() == 1) {
                        [self clearRow: _cursorY fromStart: 0 toEnd: _cursorX];
                    } else if (_csArg->size() == 1 && _csArg->front() == 2) {
                        [self clearRow: _cursorY];
                    }
				} else if (c == 'L') {      // Insert Line
                    int lineNumber = 0;
                    if (_csArg->size() == 0) 
                        lineNumber = 1;
                    else if (_csArg->size() > 0)
                        lineNumber = _csArg->front();

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
                        [self setDirtyForRow: i];
				} else if (c == 'M') {      // Delete Line
                    int lineNumber = 0;
                    if (_csArg->size() == 0) 
                        lineNumber = 1;
                    else if (_csArg->size() > 0)
                        lineNumber = _csArg->front();
                    
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
                        [self setDirtyForRow: i];
				} else if (c == 'h') {          // set mode
					NSLog(@"control sequence: set mode is not implemented yet.");
				} else if (c == 'l') {          // reset mode
					NSLog(@"control sequence: reset mode is not implemented yet.");
				} else if (c == 'm') { 
					if (_csArg->empty()) { // clear
						_fgColor = 7;
						_bgColor = 9;
						_bold = NO;
						_underline = NO;
						_blink = NO;
						_reverse = NO;
					} else {
						while (!_csArg->empty()) {
							int p = _csArg->front();
							_csArg->pop_front();
							if (p  == 0) {
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
									_bgColor = 9;
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
                    if (_csArg->size() == 0) {
                        _scrollBeginRow = 0;
                        _scrollEndRow = _row - 1;
                    } else if (_csArg->size() == 2) {
                        int s = (*_csArg)[0];
                        int e = (*_csArg)[1];
                        if (s > e) s = (*_csArg)[1], e = (*_csArg)[0];
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
				_csArg->clear();
				_state = TP_NORMAL;
			}

            break;
		}
	}

    for (i = 0; i < _row; i++) {
        [self updateDoubleByteStateForRow: i];
        [self updateURLStateForRow: i];
    }
    [_delegate performSelector: @selector(tick:)
					withObject: nil
					afterDelay: 0.07];
    
	if (hasNewMessage && _grid[0][0].attr.f.bgColor != 9) {
		for (i = 2; i < _row && _grid[i][0].attr.f.bgColor != 9; ++i);	// determine the end of the message
		NSString *callerName = [self stringFromIndex: 0 length: _column];
		NSString *messageString = [self stringFromIndex: _column length: (i - 1) * _column];
		
		// If there is a new message, we should notify the auto-reply delegate.	
		[_autoReplyDelegate setConnection: _connection];										
		[_autoReplyDelegate messageComes: callerName
						         message: messageString];
								  
		if (_connection != [[_delegate selectedTabViewItem] identifier] || ![NSApp isActive]) {
			// not in focus
            [self increaseMessageCount: 1];
            // should invoke growl notification
            // TODO: should bring the window to front or animate the icon?
			[TYGrowlBridge notifyWithTitle:callerName
                               description:messageString
                          notificationName:@"New Message Received"
                                  iconData:[NSData data]
                                  priority:0
                                  isSticky:NO
                              clickContext:_delegate
                             clickSelector:@selector(selectTabViewItemWithIdentifier:)
                                withObject:_connection];
		}
	}

    [pool release];
}

# pragma mark -
# pragma mark Start / Stop

- (void) startConnection {
    [self clearAll];
    [_delegate updateBackedImage];
	[_delegate setNeedsDisplay: YES];
}

- (void) closeConnection {
	[_delegate setNeedsDisplay: YES];
}

# pragma mark -
# pragma mark Clear

- (void) clearAll {
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
        _csBuf->clear();
    else
        _csBuf = new std::deque<unsigned char>();
    if (_csArg)
        _csArg->clear();
    else
        _csArg = new std::deque<int>();
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
        _dirty[r * _column + i] = YES;
    }
}

# pragma mark -
# pragma mark Dirty

- (void) setAllDirty {
	int i, end = _column * _row;
	for (i = 0; i < end; i++)
		_dirty[i] = YES;
}

- (void) setDirtyForRow: (int) r {
	int i, end = _column * _row;
	for (i = r * _column; i < end; i++)
		_dirty[i] = YES;
}

- (BOOL) isDirtyAtRow: (int) r column:(int) c {
	return _dirty[(r) * _column + (c)];
}

- (void) setDirty: (BOOL) d atRow: (int) r column: (int) c {
	_dirty[(r) * _column + (c)] = d;
}

# pragma mark -
# pragma mark Access Data

- (attribute) attrAtRow: (int) r column: (int) c {
	return _grid[r][c].attr;
}

- (NSString *) stringFromIndex: (int) begin length: (int) length {
    int i, j;
    unichar textBuf[_row * (_column + 1) + 1];
    unichar firstByte = 0;
    int bufLength = 0;
    int spacebuf = 0;
    for (i = begin; i < begin + length; i++) {
        int x = i % _column;
        int y = i / _column;
        if (x == 0 && i != begin && i - 1 < begin + length) { // newline
            [self updateDoubleByteStateForRow: y];
            unichar cr = 0x000D;
            textBuf[bufLength++] = cr;
            spacebuf = 0;
        }
        int db = _grid[y][x].attr.f.doubleByte;
        if (db == 0) {
            if (_grid[y][x].byte == '\0' || _grid[y][x].byte == ' ')
                spacebuf++;
            else {
                for (j = 0; j < spacebuf; j++)
                    textBuf[bufLength++] = ' ';
                textBuf[bufLength++] = _grid[y][x].byte;
                spacebuf = 0;
            }
        } else if (db == 1) {
            firstByte = _grid[y][x].byte;
        } else if (db == 2 && firstByte) {
            int index = (firstByte << 8) + _grid[y][x].byte - 0x8000;
            for (j = 0; j < spacebuf; j++)
                textBuf[bufLength++] = ' ';
            textBuf[bufLength++] = ([[[self connection] site] encoding] == YLBig5Encoding) ? B2U[index] : G2U[index];
			
            spacebuf = 0;
        }
    }
	NSLog(@"encoding %d, Big5 %d", [[[self connection] site] encoding], YLBig5Encoding);
    if (bufLength == 0) return nil;
    return [[[NSString alloc] initWithCharacters: textBuf length: bufLength] autorelease];
}

- (cell *) cellsOfRow: (int) r {
	return _grid[r];
}

# pragma mark -
# pragma mark Update State

- (void) updateDoubleByteStateForRow: (int) r {
	cell *currRow = _grid[r];
	int i, db = 0;
	for (i = 0; i < _column; i++) {
		if (db == 0 || db == 2) {
			if (currRow[i].byte > 0x7F) db = 1;
			else db = 0;
		} else { // db == 1
			db = 2;
		}
		currRow[i].attr.f.doubleByte = db;
	}
}

- (void) updateURLStateForRow: (int) r {
	cell *currRow = _grid[r];
    /* TODO: use DFA to reduce the computation  */
    char *protocols[] = {"http://", "https://", "ftp://", "telnet://", "bbs://", "ssh://", "mailto:"};
    int protocolNum = 7;
    
    BOOL urlState = NO;
    
    if (r > 0) 
        urlState = _grid[r - 1][_column - 1].attr.f.url;
    
	int i;
	for (i = 0; i < _column; i++) {
        if (urlState) {
            unsigned char c = currRow[i].byte;
            if (0x21 > c || c > 0x7E) 
                urlState = NO;
        } else {
            int p;
            for (p = 0; p < protocolNum; p++) {
                int s, len = strlen(protocols[p]);
                BOOL match = YES;
                for (s = 0; s < len; s++) 
                    if (currRow[i + s].byte != protocols[p][s] || currRow[i + s].attr.f.doubleByte) {
                        match = NO;
                        break;
                    }
                
                if (match) {
                    urlState = YES;
                    break;
                }
            }
        }            
        
        if (currRow[i].attr.f.url != urlState) {
            currRow[i].attr.f.url = urlState;
            [self setDirty: YES atRow: r column: i];
            //            [_delegate displayCellAtRow: r column: i];
            /* TODO: Do not regenerate the region. Draw the url line instead. */
        }
	}
}

- (NSString *) urlStringAtRow: (int) r column: (int) c {
    if (!_grid[r][c].attr.f.url) return nil;

    while (_grid[r][c].attr.f.url) {
        c--;
        if (c < 0) {
            c = _column - 1;
            r--;
        }
        if (r < 0) 
            break;
    }
    
    c++;
    if (c >= _column) {
        c = 0;
        r++;
    }
    
    NSMutableString *urlString = [NSMutableString string];
    while (_grid[r][c].attr.f.url) {
        [urlString appendFormat: @"%c", _grid[r][c].byte];
        c++;
        if (c >= _column) {
            c = 0;
            r++;
        }
        if (r >= _row) 
            break;
    }
    return urlString;
}

# pragma mark -
# pragma mark Accessor

- (void) setDelegate: (id) d {
	_delegate = d; // Yes, this is delegation. We shouldn't own the delegation object.
}

- (id) delegate {
	return _delegate;
}

- (int) cursorRow {
    return _cursorY;
}

- (int) cursorColumn {
    return _cursorX;
}

- (YLEncoding)encoding {
    return [[[self connection] site] encoding];
}

- (void)setEncoding:(YLEncoding)encoding {
    [[[self connection] site] setEncoding: encoding];
}

- (BOOL)hasMessage {
    return _hasMessage;
}
/* commented out by boost @ 9#: no one is using it.
- (void)setHasMessage:(BOOL)value {
    if (_hasMessage != value) {
        _hasMessage = value;
        YLLGlobalConfig *config = [YLLGlobalConfig sharedInstance];
        if (_hasMessage) {
            [NSApp requestUserAttention: ([config repeatBounce] ? NSCriticalRequest : NSInformationalRequest)];
            if (_connection != [[_delegate selectedTabViewItem] identifier] || ![NSApp isActive]) {
//                [_connection setIcon: [NSImage imageNamed: @"message.pdf"]];
                [config setMessageCount: [config messageCount] + 1];
            } else {
                _hasMessage = NO;
            }
        } else {
            [config setMessageCount: [config messageCount] - 1];
            if ([_connection connected])
                [_connection setIcon: [NSImage imageNamed: @"connect.pdf"]];
            else
                [_connection setIcon: [NSImage imageNamed: @"offline.pdf"]];

        }        
    }
}
*/
- (int)messageCount {
	return _messageCount;
}

- (void)increaseMessageCount : (int)value {
	// increase the '_messageCount' by 'value'
	if (value <= 0)
		return;
	
	YLLGlobalConfig *config = [YLLGlobalConfig sharedInstance];
	
	// we should let the icon on the deck bounce
	[NSApp requestUserAttention: ([config repeatBounce] ? NSCriticalRequest : NSInformationalRequest)];
	//if (_connection != [[_delegate selectedTabViewItem] identifier] || ![NSApp isActive]) { /* Not selected tab */
	//[_connection setIcon: [NSImage imageNamed: @"message.pdf"]];
	[config setMessageCount: [config messageCount] + value];
	_messageCount += value;
    [_connection setObjectCount:_messageCount];
	//} else {
	//	_hasMessage = NO;
	//}
}

- (void)resetMessageCount {
	// reset '_messageCount' to zero
	if (_messageCount <= 0)
		return;
	
	YLLGlobalConfig *config = [YLLGlobalConfig sharedInstance];
	[config setMessageCount: [config messageCount] - _messageCount];
/* commented out by boost @ 9#
	if ([_connection connected])
		[_connection setIcon: [NSImage imageNamed: @"connect.pdf"]];
	else
		[_connection setIcon: [NSImage imageNamed: @"offline.pdf"]];
*/
	_messageCount = 0;
    [_connection setObjectCount:_messageCount];
}

- (YLConnection *)connection {
    return _connection;
}

- (void)setConnection:(YLConnection *)value {
    _connection = value;
	[_autoReplyDelegate setConnection: value];
}

- (KOAutoReplyDelegate *)autoReplyDelegate {
	return _autoReplyDelegate;
}

@end
