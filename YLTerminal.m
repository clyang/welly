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
#import "encoding.h"
#import "YLSite.h"

@implementation YLTerminal
@synthesize maxRow = _maxRow;
@synthesize maxColumn = _maxColumn;
@synthesize cursorColumn = _cursorColumn;
@synthesize cursorRow = _cursorRow;
@synthesize grid = _grid;
@synthesize bbsType = _bbsType;
@synthesize bbsState = _bbsState;
@synthesize connection = _connection;

+ (YLTerminal *)terminalWithView:(YLView *)view {
    YLTerminal *terminal = [[YLTerminal alloc] init];
    terminal->_view = view;
	return [terminal autorelease];
}

- (id)init {
	if (self = [super init]) {
        _maxRow = [[YLLGlobalConfig sharedInstance] row];
		_maxColumn = [[YLLGlobalConfig sharedInstance] column];
		_grid = (cell **)malloc(sizeof(cell *) * _maxRow);
        int i;
        for (i = 0; i < _maxRow; i++) {
			// NOTE: in case _cursorX will exceed _column size (at the border of the
			//		 screen), we allocate one more unit for this array
			_grid[i] = (cell *) malloc(sizeof(cell) * (_maxColumn + 1));
		}
		_dirty = (char *)malloc(sizeof(char) * (_maxRow * _maxColumn));
		_textBuf = (unichar *)malloc(sizeof(unichar) * (_maxRow * _maxColumn + 1));
		
        [self clearAll];
	}
	return self;
}

- (void)dealloc {
    for (int i = 0; i < _maxRow; i++)
        free(_grid[i]);
    free(_grid);
    [super dealloc];
}

#pragma mark -
#pragma mark input interface
- (void)feedGrid:(cell **)grid {
	// Clear the url list
	for (int i = 0; i < _maxRow; i++) {
		memcpy(_grid[i], grid[i], sizeof(cell) * (_maxColumn + 1));
	}
	
	for (int i = 0; i < _maxRow; i++) {
        [self updateDoubleByteStateForRow:i];
    }
	
	[self updateBBSState];
    [_view performSelector:@selector(tick:)
				withObject:nil
				afterDelay:0.01];
}

- (void)setCursorX:(int)cursorX
				 Y:(int)cursorY {
	_cursorColumn = cursorX;
	_cursorRow = cursorY;
}

# pragma mark -
# pragma mark Start / Stop

- (void)startConnection {
    [self clearAll];
    [_view updateBackedImage];
	[_view setNeedsDisplay:YES];
}

- (void)closeConnection {
	[_view setNeedsDisplay:YES];
}

# pragma mark -
# pragma mark Clear

- (void)clearAll {
    _cursorColumn = _cursorRow = 0;
	
    attribute t;
    t.f.fgColor = [YLLGlobalConfig sharedInstance]->_fgColorIndex;
    t.f.bgColor = [YLLGlobalConfig sharedInstance]->_bgColorIndex;
    t.f.bold = 0;
    t.f.underline = 0;
    t.f.blink = 0;
    t.f.reverse = 0;
    t.f.url = 0;
    t.f.nothing = 0;
    for (int i = 0; i < _maxRow; i++) {
		for (int j = 0; j < _maxColumn; j++) {
			_grid[i][j].byte = '\0';
			_grid[i][j].attr.v = t.v;
		}
	}
	
	[self setAllDirty];
}

# pragma mark -
# pragma mark Dirty

- (void)setAllDirty {
	int i, end = _maxColumn * _maxRow;
	for (i = 0; i < end; i++)
		_dirty[i] = YES;
}

- (void)setDirtyForRow:(int)r {
	int i, end = _maxColumn * _maxRow;
	for (i = r * _maxColumn; i < end; i++)
		_dirty[i] = YES;
}

- (BOOL)isDirtyAtRow:(int)r 
			  column:(int)c {
	return _dirty[(r) * _maxColumn + (c)];
}

- (void)setDirty:(BOOL)d
		   atRow:(int)r
		  column:(int)c {
	_dirty[(r) * _maxColumn + (c)] = d;
}

# pragma mark -
# pragma mark Access Data

- (attribute)attrAtRow:(int)r 
				column:(int)c {
	return _grid[r][c].attr;
}

- (NSString *)stringFromIndex:(int)begin 
					   length:(int)length {
    int i, j;
    //unichar textBuf[length + 1];
    unichar firstByte = 0;
    int bufLength = 0;
    int spacebuf = 0;
    for (i = begin; i < begin + length; i++) {
        int x = i % _maxColumn;
        int y = i / _maxColumn;
        if (x == 0 && i != begin && i - 1 < begin + length) { // newline
			// REVIEW: why we need to update double byte state?????
            [self updateDoubleByteStateForRow:y];
            unichar cr = 0x000D;
            _textBuf[bufLength++] = cr;
            spacebuf = 0;
        }
        int db = _grid[y][x].attr.f.doubleByte;
        if (db == 0) {
            if (_grid[y][x].byte == '\0' || _grid[y][x].byte == ' ')
                spacebuf++;
            else {
                for (j = 0; j < spacebuf; j++)
                    _textBuf[bufLength++] = ' ';
                _textBuf[bufLength++] = _grid[y][x].byte;
                spacebuf = 0;
            }
        } else if (db == 1) {
            firstByte = _grid[y][x].byte;
        } else if (db == 2 && firstByte) {
            int index = (firstByte << 8) + _grid[y][x].byte - 0x8000;
            for (j = 0; j < spacebuf; j++)
                _textBuf[bufLength++] = ' ';
            _textBuf[bufLength++] = ([[[self connection] site] encoding] == YLBig5Encoding) ? B2U[index] : G2U[index];
			
            spacebuf = 0;
        }
    }
    if (bufLength == 0) return nil;
    return [NSString stringWithCharacters:_textBuf length:bufLength];
}

- (NSString *)stringAtRow:(int)row {
	return [self stringFromIndex:row * _maxColumn length:_maxColumn];
}

- (cell *)cellsOfRow:(int)r {
	return _grid[r];
}

- (cell)cellAtIndex:(int)index {
	return _grid[index / _maxColumn][index % _maxColumn];
}

# pragma mark -
# pragma mark Update State
- (void)updateDoubleByteStateForRow:(int)r {
	cell *currRow = _grid[r];
	int i, db = 0;
	for (i = 0; i < _maxColumn; i++) {
		if (db == 0 || db == 2) {
			if (currRow[i].byte > 0x7F) db = 1;
			else db = 0;
		} else { // db == 1
			db = 2;
		}
		currRow[i].attr.f.doubleByte = db;
	}
}

static NSString *extractString(NSString *row, NSString *start, NSString *end) {
    NSRange rs = [row rangeOfString:start], re = [row rangeOfString:end];
    if (rs.length == 0 || re.length == 0 || re.location <= rs.location)
        return nil;
    return [row substringWithRange:NSMakeRange(rs.location + 1, re.location - rs.location - 1)];    
}

inline static BOOL hasAnyString(NSString *row, NSArray *array) {
	if (row == nil)
		return NO;
    NSString *s;
    for (s in array) {
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
    NSString *topLine = [self stringAtRow:0];	// get the first line from the screen
    NSString *secondLine = [self stringAtRow:1];
	NSString *thirdLine = [self stringAtRow:2];
    NSString *bottomLine = [self stringAtRow:_maxRow-1];
	NSString *wholePage = [self stringFromIndex:0 length:_maxRow * _maxColumn];
	_bbsState.subState = BBSSubStateNone;
    if (NO) {
        // just for align
    } else if (hasAnyString(bottomLine, [NSArray arrayWithObjects:@"【  】", @"【信】", @"編輯文章", nil])) {
        //NSLog(@"发表文章");
        _bbsState.state = BBSComposePost;
	} else if (hasAnyString(secondLine, [NSArray arrayWithObjects:@"目前", nil])
			   || hasAnyString(topLine, [NSArray arrayWithObjects:/*@"选单",*/ @"主功能表", @"聊天說話", @"個人設定", @"工具程式", @"網路遊樂場", @"白色恐怖", nil])) {
        //NSLog(@"主选单");
        _bbsState.state = BBSMainMenu;
    } else if (hasAnyString(topLine, [NSArray arrayWithObjects:@"讨论区列表", @"个人定制区", @"看板列表", @"板板列表", nil])) {
        //NSLog(@"讨论区列表");
        _bbsState.state = BBSBoardList;
    } else if (hasAnyString(topLine, [NSArray arrayWithObjects:@"好朋友列表", @"使用者列表", @"休閒聊天", nil])) {
        //NSLog(@"好朋友列表");
        _bbsState.state = BBSFriendList;
    } else if (hasAnyString(topLine, [NSArray arrayWithObjects:@"处理信笺选单", @"電子郵件", nil])) {
        //NSLog(@"处理信笺选单");
        _bbsState.state = BBSMailMenu;
    } else if (hasAnyString(topLine, [NSArray arrayWithObjects:@"邮件选单", nil])) {
        //NSLog(@"邮件选单");
        _bbsState.state = BBSMailList;
    } else if (hasAnyString(topLine, [NSArray arrayWithObjects:@"版主", @"板主", @"诚征版主中", @"徵求中", nil])) {
        //NSLog(@"版面");
        _bbsState.state = BBSBrowseBoard;
//        _bbsState.boardName = extractString(topLine, @"[", @"]");      // smth
//        if (_bbsState.boardName == nil)
//            _bbsState.boardName = extractString(topLine, @"《", @"》"); // ptt
		if (hasAnyString(thirdLine, [NSArray arrayWithObject:@"一般模式"]))
			_bbsState.subState = BBSBrowseBoardNormalMode;
		else if (hasAnyString(thirdLine, [NSArray arrayWithObject:@"文摘模式"]))
			_bbsState.subState = BBSBrowseBoardDigestMode;
		else if (hasAnyString(thirdLine, [NSArray arrayWithObject:@"主题模式"]))
			_bbsState.subState = BBSBrowseBoardThreadMode;
		else if (hasAnyString(thirdLine, [NSArray arrayWithObject:@"精华模式"]))
			_bbsState.subState = BBSBrowseBoardMarkMode;
		else if (hasAnyString(thirdLine, [NSArray arrayWithObject:@"原作模式"]))
			_bbsState.subState = BBSBrowseBoardOriginMode;
		else if (hasAnyString(thirdLine, [NSArray arrayWithObject:@"作者模式"]))
			_bbsState.subState = BBSBrowseBoardAuthorMode;
        //NSLog(@"%@, cursor @ row %d", _bbsState.boardName, _bbsState.cursorRow);
    } else if (hasAnyString(bottomLine, [NSArray arrayWithObjects:@"阅读文章", @"主题阅读", @"同作者阅读", @"下面还有喔", @"瀏覽", nil])) {
        //NSLog(@"阅读文章");
        _bbsState.state = BBSViewPost;
    } else if (hasAnyString([self stringAtRow:4], [NSArray arrayWithObjects:@"个人说明档如下", @"没有个人说明档", nil])
			   || hasAnyString([self stringAtRow:6], [NSArray arrayWithObjects:@"个人说明档如下", @"没有个人说明档", nil])) {
		//NSLog(@"用户信息");
		_bbsState.state = BBSUserInfo;
	} else if (hasAnyString(bottomLine, [NSArray arrayWithObjects:@"[功能键]", @"[版  主]", nil])) {
		//NSLog(@"浏览精华区");
		_bbsState.state = BBSBrowseExcerption;
    } else if (hasAnyString(wholePage, [NSArray arrayWithObjects:@"按任意键继续", @"按回车键", @"按 [RETURN] 继续", @"按 ◆Enter◆ 继续", @"按 <ENTER> 继续", @"按任何键继续", @"上次连线时间为", @"按任意鍵繼續", @"請按空白鍵或是Enter繼續", nil])) {
		//NSLog(@"按回车继续");
		_bbsState.state = BBSWaitingEnter;
	} else {
		//NSLog(@"未知状态");
        _bbsState.state = BBSUnknown;
    }
}

# pragma mark -
# pragma mark Accessor
- (YLEncoding)encoding {
    return [[[self connection] site] encoding];
}

- (void)setEncoding:(YLEncoding)encoding {
    [[[self connection] site] setEncoding:encoding];
}

- (void)setConnection:(YLConnection *)value {
    _connection = value;
	// FIXME: BBS type is temoprarily determined by the ansi color key.
	// remove #import "YLSite.h" when fixed.
	[self setBbsType:[[_connection site] ansiColorKey] == YLCtrlUANSIColorKey ? WLMaple : WLFirebird];
}
@end
