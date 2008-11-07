//
//  YLTerminal.m
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/9/10.
//  Copyright 2006 yllan.org. All rights reserved.
//

#import "YLTerminal.h"
#import "YLLGlobalConfig.h"
#import "YLView.h"
#import "YLConnection.h"
#import "XIIntegerArray.h"
#import "encoding.h"
#import "YLSite.h"

@implementation YLTerminal

+ (YLTerminal *)terminalWithView:(YLView *)view {
    YLTerminal *terminal = [[YLTerminal alloc] init];
    terminal->_view = view;
    return [terminal autorelease];
}

- (id) init {
	if (self = [super init]) {
        _row = [[YLLGlobalConfig sharedInstance] row];
		_column = [[YLLGlobalConfig sharedInstance] column];
		_grid = (cell **) malloc(sizeof(cell *) * _row);
        int i;
        for (i = 0; i < _row; i++) {
			// NOTE: in case _cursorX will exceed _column size (at the border of the
			//		 screen), we allocate one more unit for this array
			_grid[i] = (cell *) malloc(sizeof(cell) * (_column + 1));
		}
		_dirty = (char *) malloc(sizeof(char) * (_row * _column));
		
        [self clearAll];
	}
	return self;
}

- (void)dealloc {
    for (int i = 0; i < _row; i++)
        free(_grid[i]);
    free(_grid);
    [super dealloc];
}

#pragma mark -
#pragma mark input interface
- (void)feedGrid: (cell **)grid {
	for (int i = 0; i < _row; i++) {
		memcpy(_grid[i], grid[i], sizeof(cell) * (_column + 1));
	}
	for (int i = 0; i < _row; i++) {
        [self updateDoubleByteStateForRow: i];
        [self updateURLStateForRow: i];
    }
	[self updateBBSState];
    [_view performSelector: @selector(tick:)
				withObject: nil
				afterDelay: 0.07];
}

- (void)setCursorX: (int) cursorX
				 Y: (int) cursorY {
	_cursorX = cursorX;
	_cursorY = cursorY;
}

# pragma mark -
# pragma mark Start / Stop

- (void) startConnection {
    [self clearAll];
    [_view updateBackedImage];
	[_view setNeedsDisplay: YES];
}

- (void) closeConnection {
	[_view setNeedsDisplay: YES];
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
    for (int i = 0; i < _row; i++) {
		for (int j = 0; j < _column; j++) {
			_grid[i][j].byte = '\0';
			_grid[i][j].attr.v = t.v;
		}
	}
	
	[self setAllDirty];
}

# pragma mark -# pragma mark Dirty

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
    // for URL that contains "()", esp. M$ sites
    int par = 0;
    for (int i = 0; i < _column; i++) {
        if (urlState) {
            unsigned char c = currRow[i].byte;
            if (0x21 > c || c > 0x7E || c == '"' || c == '\'')
                urlState = NO;
            else if (c == '(')
                ++par;
            else if (c == ')') {
                if (--par < 0)
                    urlState = NO;
            }
        } else {
            for (int p = 0; p < protocolNum; p++) {
                int len = strlen(protocols[p]);
                BOOL match = YES;
                for (int s = 0; s < len; s++) 
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
            //            [_view displayCellAtRow: r column: i];
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

// boost: ad-hoc
- (void)updateBBSCursor {
    for (int i = 3; i < _row; ++i) {
        NSString *cursor = [self stringFromIndex:i*_column length:2];
        if (cursor == nil)
            continue;
        // smth: "> "
        // ptt: "●"
        if ([cursor compare:@">"] == 0 || [cursor compare:@"●"] == 0) {
            _bbsState.cursorRow = i;
            break;
        }
    }
    // FIXME: what if not found
}

static NSString *extractString(NSString *row, NSString *start, NSString *end) {
    NSRange rs = [row rangeOfString:start], re = [row rangeOfString:end];
    if (rs.length == 0 || re.length == 0 || re.location <= rs.location)
        return nil;
    return [row substringWithRange:NSMakeRange(rs.location + 1, re.location - rs.location - 1)];    
}

static BOOL hasAnyString(NSString *row, NSArray *array) {
    NSEnumerator *e = [array objectEnumerator];
    NSString *s;
    while (s = [e nextObject]) {
        if ([row rangeOfString:s].length > 0)
            return YES;
    }
    return NO;
}

//
// added by K.O.ed
// WARNING: bunch of hard code
// 
- (void)updateBBSState {
    NSString *topLine = [self stringFromIndex:0 length:_column];	// get the first line from the screen
    NSString *secondLine = [self stringFromIndex:_column length:_column];
    NSString *bottomLine = [self stringFromIndex:(_row-1) * _column length:_column];
    if (NO) {
        // just for align
    } else if ([secondLine rangeOfString:@"目前选择"].length > 0) {
        //NSLog(@"主选单");
        _bbsState.state = BBSMainMenu;
    } else if (hasAnyString(topLine, [NSArray arrayWithObjects:@"讨论区列表", @"个人定制区", @"看板列表", nil])) {
        //NSLog(@"讨论区列表");
        _bbsState.state = BBSBoardList;
        [self updateBBSCursor];
    } else if (hasAnyString(topLine, [NSArray arrayWithObjects:@"好朋友列表", @"使用者列表", @"休閒聊天"])) {
        //NSLog(@"好朋友列表");
        _bbsState.state = BBSFriendList;
        [self updateBBSCursor];
    } else if (hasAnyString(topLine, [NSArray arrayWithObjects:@"版主", @"板主", @"诚征版主中", @"徵求中", nil])) {
        //NSLog(@"版面");
        _bbsState.state = BBSBrowseBoard;
        _bbsState.boardName = extractString(topLine, @"[", @"]");      // smth
        if (_bbsState.boardName == nil)
            _bbsState.boardName = extractString(topLine, @"《", @"》"); // ptt
        [self updateBBSCursor];
        //NSLog(@"%@, cursor @ row %d", _bbsState.boardName, _bbsState.cursorRow);
    } else if (hasAnyString(bottomLine, [NSArray arrayWithObjects:@"阅读文章", @"下面还有喔", @"瀏覽", nil])) {
        //NSLog(@"阅读文章");
        _bbsState.state = BBSViewPost;
    } else if ([self cellsOfRow:(_row - 1)]->byte == 161) {
        //NSLog(@"发表文章");
        _bbsState.state = BBSComposePost;
    } else {
        _bbsState.state = BBSUnknown;
    }
}

# pragma mark -
# pragma mark Accessor

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

- (YLConnection *)connection {
    return _connection;
}

- (void)setConnection:(YLConnection *)value {
    _connection = value;
	// FIXME: BBS type is temoprarily determined by the ansi color key.
	// remove #import "YLSite.h" when fixed.
	[self setBbsType:[[_connection site] ansiColorKey] == YLCtrlUANSIColorKey ? TYMaple : TYFirebird];
}

- (BBSState)bbsState {
	return _bbsState;
}

- (TYBBSType)bbsType {
	return _bbsType;
}

- (void)setBbsType:(TYBBSType)bbsType {
	_bbsType = bbsType;
}

@end
