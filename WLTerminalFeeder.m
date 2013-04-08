//
//  WLTerminalFeeder.m
//  Welly
//
//  Created by K.O.ed on 08-8-11.
//  Copyright 2008 Welly Group. All rights reserved.
//

#import "WLTerminalFeeder.h"
#import "WLIntegerArray.h"
#import "WLTerminal.h"
#import "WLGlobalConfig.h"
#import "WLConnection.h"

#pragma mark -
#pragma mark Constant Define
// single character control command
#define ASC_NUL     0x00 // NULL
#define ASC_SOH     0x01 // START OF HEADING
#define ASC_STX     0x02 // START OF TEXT
#define ASC_ETX     0x03 // END OF TEXT
#define ASC_EQT     0x04 // END OF TRANSMISSION
#define ASC_ENQ     0x05 // ^E, ENQUIRE
#define ASC_ACK     0x06 // ACKNOWLEDGE
#define ASC_BEL     0x07 // ^G, BELL (BEEP)
#define ASC_BS      0x08 // ^H, BACKSPACE
#define ASC_HT      0x09 // ^I, HORIZONTAL TABULATION
#define ASC_LF      0x0A // ^J, LINE FEED
#define ASC_VT      0x0B // ^K, Virtical Tabulation
#define ASC_FF      0x0C // ^L, Form Feed
#define ASC_CR      0x0D // ^M, Carriage Return
#define ASC_LS1     0x0E // Shift Out
#define ASC_LS0     0x0F // ^O, Shift In
#define ASC_DLE     0x10 // Data Link Escape, normally MODEM
#define ASC_DC1     0x11 // Device Control One, XON
#define ASC_DC2     0x12 // Device Control Two
#define ASC_DC3     0x13 // Device Control Three, XOFF
#define ASC_DC4     0x14 // Device Control Four
#define ASC_NAK     0x15 // Negative Acknowledge
#define ASC_SYN     0x16 // Synchronous Idle
#define ASC_ETB     0x17 // End of Transmission Block
#define ASC_CAN     0x18 // Cancel
#define ASC_EM      0x19 // End of Medium
#define ASC_SUB     0x1A // Substitute
#define ASC_ESC     0x1B // Escape
#define ASC_FS      0x1C // File Separator
#define ASC_GS      0x1D // Group Separator
#define ASC_RS      0x1E // Record Separator
#define ASC_US      0x1F // Unit Separator
#define ASC_DEL     0x7F // Delete, Ignored on input; not stored in buffer.

// Escape Sequence
#define ESC_HASH    0x23 // #, Several DEC modes..
#define ESC_sG0     0x28 // (, Font Set G0
#define ESC_sG1     0x29 // ), Font Set G1
#define ESC_APPK    0x3D // =, Appl. keypad
#define ESC_NUMK    0x3E // >, Numeric keypad
#define ESC_DECSC   0x37 // 7,
#define ESC_DECRC   0x38 // 8,
#define ESC_BPH     0x42 // B,
#define ESC_NBH     0x43 // C,
#define ESC_IND     0x44 // D, Index
#define ESC_NEL     0x45 // E, Next Line
#define ESC_SSA     0x46 // F,
#define ESC_ESA     0x47 // G,
#define ESC_HTS     0x48 // H, Tab Set
#define ESC_HTJ     0x49 // I,
#define ESC_VTS     0x4A // J,
#define ESC_PLD     0x4B // K,
#define ESC_PLU     0x4C // L,
#define ESC_RI      0x4D // M, Reverse Index
#define ESC_SS2     0x4E // N, Single Shift Select of G2 Character Set
#define ESC_SS3     0x4F // O, Single Shift Select of G3 Character Set
#define ESC_DCS     0x50 // P, Device Control String
#define ESC_PU1     0x51 // Q,
#define ESC_PU2     0x52 // R,
#define ESC_STS     0x53 // S,
#define ESC_CCH     0x54 // T,
#define ESC_MW      0x55 // U,
#define ESC_SPA     0x56 // V, Start of Guarded Area
#define ESC_EPA     0x57 // W, End of Guarded Area
#define ESC_SOS     0x58 // X, Start of String
//#define ESC_      0x59 // Y,
#define ESC_SCI     0x5A // Z, Return Terminal ID
#define ESC_CSI     0x5B // [, Control Sequence Introducer
#define ESC_ST      0x5C // \, String Terminator
#define ESC_OSC     0x5D // ], Operating System Command
#define ESC_PM      0x5E // ^, Privacy Message
#define ESC_APC     0x5F // _, Application Program Command
#define ESC_RIS     0x63 // c, RIS reset

// Control sequences
#define CSI_ICH     0x40 // INSERT CHARACTER, requires DCSM implementation
#define CSI_CUU     0x41 // A, CURSOR UP
#define CSI_CUD     0x42 // B, CURSOR DOWN
#define CSI_CUF     0x43 // C, CURSOR FORWARD
#define CSI_CUB     0x44 // D, CURSOR BACKWARD
#define CSI_CNL     0x45 // E, CURSOR NEXT LINE
#define CSI_CPL     0x46 // F, CURSOR PRECEDING LINE
#define CSI_CHA     0x47 // G, CURSOR CHARACTER ABSOLUTE
#define CSI_CUP     0x48 // H, CURSOR POSITION
#define CSI_CHT     0x49 // I, CURSOR FORWARD TABULATION
#define CSI_ED      0x4A // J, ERASE IN PAGE
#define CSI_EL      0x4B // K, ERASE IN LINE
#define CSI_IL      0x4C // L, INSERT LINE
#define CSI_DL      0x4D // M, DELETE LINE
#define CSI_EF      0x4E // N, Erase in Field, not implemented
#define CSI_EA      0x4F // O, Erase in Area, not implemented
#define CSI_DCH     0x50 // P, DELETE CHARACTER 
#define CSI_SSE     0x51 // Q, ?
#define CSI_CPR     0x52 // R, ACTIVE POSITION REPORT, this is for responding
#define CSI_SU      0x53 // S, ?
#define CSI_SD      0x54 // T, ?
#define CSI_NP      0x55 // U, ?
#define CSI_PP      0x56 // V, ?
#define CSI_CTC     0x57 // W, CURSOR TABULATION CONTROL, not implemented
#define CSI_ECH     0x58 // X, ERASE CHARACTER
#define CSI_CVT     0x59 // Y, CURSOR LINE TABULATION, not implemented
#define CSI_CBT     0x5A // Z, CURSOR BACKWARD TABULATION, not implemented
#define CSI_SRS     0x5B // [, ?
#define CSI_PTX     0x5C // \, ?
#define CSI_SDS     0x5D // ], ?
#define CSISIMD     0x5E // ^, ?
#define CSI_HPA     0x60 // _, CHARACTER POSITION ABSOLUTE
#define CSI_HPR     0x61 // a, CHARACTER POSITION FORWARD
#define CSI_REP     0x62 // b, REPEAT, not implemented
#define CSI_DA      0x63 // c, DEVICE ATTRIBUTES
#define CSI_VPA     0x64 // d, LINE POSITION ABSOLUTE
#define CSI_VPR     0x65 // e, LINE POSITION FORWARD
#define CSI_HVP     0x66 // f, CHARACTER AND LINE POSITION
#define CSI_TBC     0x67 // g, TABULATION CLEAR, not implemented, ignored
#define CSI_SM      0x68 // h, Set Mode, not implemented, ignored
#define CSI_MC      0x69 // i, MEDIA COPY, not implemented, ignored
#define CSI_HPB     0x6A // j, CHARACTER POSITION BACKWARD
#define CSI_VPB     0x6B // k, LINE POSITION BACKWARD
#define CSI_RM      0x6C // l, Reset Mode. not implemented, ignored
#define CSI_SGR     0x6D // m, SELECT GRAPHIC RENDITION
#define CSI_DSR     0x6E // n, DEVICE STATUS REPORT
#define CSI_DAQ     0x6F // o, DEFINE AREA QUALIFICATION, not implemented
#define CSI_DFNKY   0x70 // p, shouldn't be implemented
//0x71 // q,
#define CSI_DECSTBM 0x72 // r, Set Top and Bottom Margins
#define CSI_SCP     0x73 // s, Saves the cursor position.
#define CSI_RCP     0x75 // u, Restores the cursor position.

@interface WLTerminalFeeder ()
/* Clear */
- (void)clearRow:(int)r;
- (void)clearRow:(int)r 
	   fromStart:(int)s 
		   toEnd:(int)e;
- (void)reverseAll;
@end

@implementation WLTerminalFeeder
@synthesize cursorX = _cursorX;
@synthesize cursorY = _cursorY;
@synthesize grid = _grid;

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

- (id)init {
	if (self = [super init]) {
		_hasNewMessage = NO;
        _savedCursorX = _savedCursorY = -1;
        _row = [[WLGlobalConfig sharedInstance] row];
		_column = [[WLGlobalConfig sharedInstance] column];
        _scrollBeginRow = 0; _scrollEndRow = _row - 1;
        _modeScreenReverse = NO;
		_modeOriginRelative = NO;
        _modeWraptext = YES;
		_modeLNM = YES;
        _modeIRM = NO;
        _emustd = VT102;
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

- (id)initWithConnection:(WLConnection *)connection {
	self = [self init];
	if (self) {
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
- (void)feedData:(NSData *)data 
	  connection:(id)connection {
	[self feedBytes:[data bytes] 
			 length:[data length] 
		 connection:connection];
}

- (void)feedBytes:(const unsigned char*)bytes 
		   length:(NSUInteger)len 
	   connection:(id)connection {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	int i, x;
	unsigned char c;
	
	if ([_terminal bbsType] == WLFirebird) {
		_hasNewMessage = NO;
	}
	
	for (i = 0; i < len; i++) {
		c = ((const char *)bytes)[i];
		//        if (c == 0x00) continue;
        
		switch (_state)
        {
			case TP_NORMAL:
				if (NO) {	// Code alignment
				} else if (c == ASC_NUL) {	// do nothing
				} else if (c == ASC_ETX) { // FLOW CONTROL? do nothing
				} else if (c == ASC_EQT) { // FLOW CONTROL? do nothing
				} else if (c == ASC_ENQ) { // FLOW CONTROL? do nothing
					unsigned char cmd[1];
					unsigned int cmdLength = 1;
					// Note: don't know what this is doing. But cmd[1]
					// is out of array index. So I change it to [0]
					// Original: cmd[1] = ASC_NUL;
					cmd[0] = ASC_NUL;
					[connection sendBytes:cmd length:cmdLength];
				} else if (c == ASC_ACK) { // FLOW CONTROL? do nothing					
				} else if (c == ASC_BEL) { // Beep
					[[NSSound soundNamed:@"Whit.aiff"] play];
					_hasNewMessage = YES;
				} else if (c == ASC_BS) { // ^H, Backspace (BS)
					if (_cursorX > 0) {
						// just walking back one char
						_cursorX--;
					}
					// reverse-wrap is not implemented yet
				} else if (c == ASC_HT) { // Horizontal TABulations
					// Normally the tabulation stops for every 8 chars
					_cursorX = ((int)(_cursorX / 8) + 1) * 8;
				} else if (c == ASC_LF || c == ASC_VT || c == ASC_FF) { // Linefeed (LF) / Vertical tab (VT) / Form feed (FF)
					if (_modeLNM == NO) _cursorX = 0;
					if (_cursorY == _scrollEndRow) {
						cell *emptyLine = _grid[_scrollBeginRow];
						[self clearRow:_scrollBeginRow];
						
						for (x = _scrollBeginRow; x < _scrollEndRow; x++) 
							_grid[x] = _grid[x + 1];
						_grid[_scrollEndRow] = emptyLine;
						[_terminal setAllDirty];
					} else {
						_cursorY++;
						if (_cursorY >= _row) _cursorY = _row - 1;
					}
				} else if (c == ASC_CR) { // Go to the begin of this line
					_cursorX = 0;
				} else if (c == ASC_LS1) { // do nothing for now
					//LS1 (Locked Shift-One in Unicode) Selects G1 characteri
					//set designated by a select character set sequence.
					//However we drop it for now
				} else if (c == ASC_LS0) { // (^O)
					//LS0 (Locked Shift-Zero in Unicode) Selects G0 character
					//set designated by a select character set sequence.
					//However we drop it for now
				} else if (c == ASC_DLE) { // Normally for MODEM
				} else if (c == ASC_DC1) { // XON
				} else if (c == ASC_DC2) { // 
				} else if (c == ASC_DC3) { // XOFF
				} else if (c == ASC_DC4) { 
				} else if (c == ASC_NAK) { 
				} else if (c == ASC_SYN) {
				} else if (c == ASC_ETB) {
				} else if (c == ASC_CAN || c == ASC_SUB) {
					//If received during an escape or control sequence, 
					//cancels the sequence and displays substitution character ().
					//SUB is processed as CAN
					//This is not implemented here
				} else if (c == ASC_EM ) { // ^Y
				} else if (c == ASC_ESC) { // ESC
					_state = TP_ESCAPE;
				} else if (c == ASC_FS ) { // ^\ 
				} else if (c == ASC_GS ) { // ^]
				} else if (c == ASC_RS ) { // ^^
				} else if (c == ASC_US ) { // ^_
					// 0x20 ~ 0x7E ascii readible bytes... (btw Big5 second byte 0x40 ~ 0x7E)
				} else if (c == ASC_DEL) { // Ignored on input; not stored
				} else {
					SET_GRID_BYTE(c);
				}
				
				break;
				
			case TP_ESCAPE:
				if (NO) {	// Code alignment
				} else if (c == ASC_ESC) { // ESCESC according to zterm this happens
					_state = TP_ESCAPE;
				} else if (c == ESC_CSI) { // 0x5B == '['
					[_csBuf clear];
					[_csArg clear];
					_csTemp = 0;
					_state = TP_CONTROL;
				} else if (c == ESC_RI) { // scroll down (cursor up)
					if (_cursorY == _scrollBeginRow) {
						//[_view updateBackedImage];
						//[_view extendTopFrom: _scrollBeginRow to: _scrollEndRow];
						cell *emptyLine = _grid[_scrollEndRow];
						[self clearRow:_scrollEndRow];
						
						for (x = _scrollEndRow; x > _scrollBeginRow; x--) 
							_grid[x] = _grid[x - 1];
						_grid[_scrollBeginRow] = emptyLine;
						[_terminal setAllDirty];
					} else {
						_cursorY--;
						if (_cursorY < 0) _cursorY = 0;
					}
					_state = TP_NORMAL;
				} else if (c == ESC_IND) { // scroll up (cursor down)
					if (_cursorY == _scrollEndRow) {
						//[_view updateBackedImage];
						//[_view extendBottomFrom: _scrollBeginRow to: _scrollEndRow];
						cell *emptyLine = _grid[_scrollBeginRow];
						[self clearRow:_scrollBeginRow];
						
						for (x = _scrollBeginRow; x < _scrollEndRow; x++) 
							_grid[x] = _grid[x + 1];
						_grid[_scrollEndRow] = emptyLine;
						[_terminal setAllDirty];
					} else {
						_cursorY++;
						if (_cursorY >= _row) _cursorY = _row - 1;
					}
					_state = TP_NORMAL;
				} else if (c == ESC_DECSC) { // Save cursor
					_savedCursorX = _cursorX;
					_savedCursorY = _cursorY;
					_state = TP_NORMAL;
				} else if (c == ESC_DECRC) { // Restore cursor
					_cursorX = _savedCursorX;
					_cursorY = _savedCursorY;
					_state = TP_NORMAL;
				} else if (c == ESC_HASH) { // 0x23
					if (i < len-1 && bytes[i+1] == '8'){ // DECALN (fill with E)
						i++;
						for (int y = 0; y <= _row-1; y++) {
							for (int x = 0; x <= _column-1; x++) {
								_grid[y][x].byte = 'E';
								_grid[y][x].attr.v = gEmptyAttr;
							}
							[_terminal setAllDirty];
						}
						//              } else if (i < len-1 && bytes[i+1] == '3'){ //DECDHL
						//              } else if (i < len-1 && bytes[i+1] == '4'){ //DECDHL
						//              } else if (i < len-1 && bytes[i+1] == '5'){ //DECSWL
						//              } else if (i < len-1 && bytes[i+1] == '6'){ //DECDWL
					} else
						NSLog(@"Unhandled <ESC># case");
					_state = TP_NORMAL;
				} else if (c == ESC_sG0) { // 0x28 Font Set G0
					_state = TP_SCS;
				} else if (c == ESC_sG1) { // 0x29 Font Set G1
					_state = TP_SCS;
				} else if (c == ESC_APPK) { // 0x3D Application keypad mode (vt52)
					//              NSLog(@"unprocessed request of application keypad mode");
					_state = TP_NORMAL;
				} else if (c == ESC_NUMK) { // 0x3E Numeric keypad mode (vt52)
					//              NSLog(@"unprocessed request of numeric keypad mode");
					_state = TP_NORMAL;
				} else if (c == ESC_NEL) { // 0x45 NEL Next Line (CR+Index)
					_cursorX = 0;
					if (_cursorY == _scrollEndRow) {
						//[_delegate updateBackedImage];
						//[_delegate extendBottomFrom: _scrollBeginRow to: _scrollEndRow];
						cell *emptyLine = _grid[_scrollBeginRow];
						[self clearRow:_scrollBeginRow];
						
						for (x = _scrollBeginRow; x < _scrollEndRow; x++) 
							_grid[x] = _grid[x + 1];
						_grid[_scrollEndRow] = emptyLine;
						[_terminal setAllDirty];
					} else {
						_cursorY++;
						if (_cursorY >= _row) _cursorY = _row - 1;
					}
					_state = TP_NORMAL;
					//          } else if (c == ESC_HTS) { // 0x48 Set a tab at the current column
					//              Please implement
					//              _state = TP_NORMAL;
				} else if (c == ESC_RIS) { // 0x63 RIS reset
					[self clearAll];
					_cursorX = 0, _cursorY = 0;
					_state = TP_NORMAL;
				} else {
					NSLog(@"unprocessed esc: %c(0x%X)", c, c);
					_state = TP_NORMAL;
				}
				break;
				
			case TP_SCS:
				/*
				 if (NO) {
				 } else if (c == '0') { //Special characters and line drawing set
				 _state = TP_NORMAL;
				 } else if (c == '1') { //Alternate character ROM
				 _state = TP_NORMAL;
				 } else if (c == '2') { //Alt character ROM - special characters
				 _state = TP_NORMAL;
				 } else if (c == 'A') { //United Kingdom (UK)
				 _state = TP_NORMAL;
				 } else if (c == 'B') { //United States (US)
				 _state = TP_NORMAL;
				 } else {
				 _state = TP_NORMAL;
				 }
				 */
				_state = TP_NORMAL;
				break;
				
			case TP_CONTROL:
				if (isParameter(c)) {
					[_csBuf push_back:c];
					if (c >= '0' && c <= '9') {
						_csTemp = _csTemp * 10 + (c - '0');
					} else if (c == '?') {
						[_csArg push_back:-1];
						_csTemp = 0;
						[_csBuf clear];
					}  else if (![_csBuf empty]) {
						[_csArg push_back:_csTemp];
						_csTemp = 0;
						[_csBuf clear];
					}
				} else if (c == ASC_BS) { // Backspace eats previous parameter.
					if (![_csBuf empty]) {
						[_csArg pop_front];
					}
				} else if (c == ASC_VT) { // Virtical Tabulation
					if (_modeLNM == NO) _cursorX = 0;
					if (_cursorY == _scrollEndRow) {
						cell *emptyLine = _grid[_scrollBeginRow];
						[self clearRow:_scrollBeginRow];
						
						for (x = _scrollBeginRow; x < _scrollEndRow; x++) 
							_grid[x] = _grid[x + 1];
						_grid[_scrollEndRow] = emptyLine;
						[_terminal setAllDirty]; // We might not need to set everything dirty.
					} else {
						_cursorY++;
						if (_cursorY >= _row) _cursorY = _row - 1;
					}
				} else if (c == ASC_CR) { // CR (Carriage Return)
					_cursorX = 0;
				} else {
					if (![_csBuf empty]) {
						[_csArg push_back:_csTemp];
						_csTemp = 0;
						[_csBuf clear];
					}
					
					if (NO) {
						// just for code alignment...
					} else if (c == CSI_ICH) {
						int p;
						if ([_csArg size] > 0) {
							p = [_csArg front];
							if (p < 1)
								p = 1;
						} else {
							p = 1;
						}
						for (x = _column - 1; x > _cursorX + p - 1; x--) {
							_grid[_cursorY][x] = _grid[_cursorY][x-p];
							[_terminal setDirty:YES atRow:_cursorY column:x];
						}
						[self clearRow:_cursorY fromStart:_cursorX toEnd:_cursorX+p-1];
					} else if (c == CSI_CUU) {		// Cursor Up
						if ([_csArg size] > 0){
							int p = [_csArg front];
							if (p < 1) p = 1;
								_cursorY -= p;
						} else
							_cursorY--;
						
						if (_modeOriginRelative && _cursorY < _scrollBeginRow) {
							_cursorY = _scrollBeginRow;
						} else if (_cursorY < 0) {
							_cursorY = 0;
						}
					} else if (c == CSI_CUD) {
						if ([_csArg size] > 0) {
							int p = [_csArg front];
							if (p < 1) p = 1;
							_cursorY += p;
						} else
							_cursorY++;
						if (_modeOriginRelative && _cursorY > _scrollEndRow) {
							_cursorY = _scrollEndRow;
						} else if (_cursorY >= _row) {
							_cursorY = _row - 1;
						}
					} else if (c == CSI_CUF) {
						if ([_csArg size] > 0) {
							int p = [_csArg front];
							if (p < 1) p = 1;
							_cursorX += p;
						} else
							_cursorX++;
						if (_cursorX >= _column) _cursorX = _column - 1;
					} else if (c == CSI_CUB) {
						if ([_csArg size] > 0) {
							int p = [_csArg front];
							if (p < 1) p = 1;
							_cursorX -= p;
						} else
							_cursorX--;
						if (_cursorX < 0) _cursorX = 0;
					} else if (c == CSI_CHA) { // move to Pn position of current line
						if ([_csArg size] > 0) {
							int p = [_csArg front];
							if (p < 1) p = 1;
							CURSOR_MOVETO(p - 1, _cursorY);
						} else {
							CURSOR_MOVETO(0, _cursorY);
						}
					} else if (c == CSI_HVP || c == CSI_CUP) { // Cursor Position
						/*  ^[H			: go to row 1, column 1
						 ^[3H		: go to row 3, column 1
						 ^[3;4H		: go to row 3, column 4 */
						if ([_csArg size] == 0) {
							_cursorX = 0, _cursorY = 0;
						} else if ([_csArg size] == 1) {
							int p = [_csArg front];
							if (p < 1) p = 1;
							if (_modeOriginRelative && _scrollBeginRow > 0) {
								p += _scrollBeginRow;
								if (p > _scrollEndRow) p = _scrollEndRow + 1;
							}
							CURSOR_MOVETO(0, p - 1);
						} else if ([_csArg size] > 1) {
							int p = [_csArg front]; [_csArg pop_front];
							int q = [_csArg front];
							if (p < 1) p = 1;
							if (q < 1) q = 1;
							if (_modeOriginRelative && _scrollBeginRow > 0) {
								p += _scrollBeginRow;
								if (p > _scrollEndRow) p = _scrollEndRow + 1;
							}
							CURSOR_MOVETO(q - 1, p - 1);
						}
					} else if (c == CSI_ED ) { // Erase Page (cursor does not move)
						/*  ^[J, ^[0J	: clear from cursor position to end
						 ^[1J		: clear from start to cursor position
						 ^[2J		: clear all */
						int j;
						if ([_csArg size] == 0 || [_csArg front] == 0) {
							// mjhsieh is not comfortable with putting _csArg lookup with
							// [_csArg size]==0
							[self clearRow:_cursorY 
								 fromStart:_cursorX 
									 toEnd:_column - 1];
							for (j = _cursorY + 1; j < _row; j++)
								[self clearRow:j];
						} else if ([_csArg size] > 0 && [_csArg front] == 1) {
							[self clearRow:_cursorY 
								 fromStart:0 
									 toEnd:_cursorX];
							for (j = 0; j < _cursorY; j++)
								[self clearRow:j];
						} else if ([_csArg size] > 0 && [_csArg front] == 2) {
							[self clearAll];
						}
					} else if (c == CSI_EL ) { // Erase Line (cursor does not move)
						/*  
						 ^[K, ^[0K	: clear from cursor position to end of line
						 ^[1K		: clear from start of line to cursor position
						 ^[2K		: clear whole line 
						 */
						if ([_csArg size] == 0 || [_csArg front] == 0) {
							[self clearRow:_cursorY 
								 fromStart:_cursorX 
									 toEnd:_column - 1];
						} else if ([_csArg size] > 0 && [_csArg front] == 1) {
							[self clearRow:_cursorY 
								 fromStart:0 
									 toEnd:_cursorX];
						} else if ([_csArg size] > 0 && [_csArg front] == 2) {
							[self clearRow:_cursorY];
						}
					}else if (c == CSI_IL ) { // Insert Line
						int lineNumber = 0;
						if ([_csArg size] == 0) 
							lineNumber = 1;
						else if ([_csArg size] > 0)
							lineNumber = [_csArg front];
						if (lineNumber < 1) lineNumber = 1; //mjhsieh is paranoid
						
						int j;
						for (j = 0; j < lineNumber; j++) {
							[self clearRow: _scrollEndRow];
							cell *emptyRow = [self cellsOfRow: _scrollEndRow];
							int r;
							for (r = _scrollEndRow; r > _cursorY; r--)
								_grid[r] = _grid[r - 1];
							_grid[_cursorY] = emptyRow;
						}
						for (j = _cursorY; j <= _scrollEndRow; j++)
							[_terminal setDirtyForRow:j];
					} else if (c == CSI_DL ) { // Delete Line
						int lineNumber = 0;
						if ([_csArg size] == 0) 
							lineNumber = 1;
						else if ([_csArg size] > 0)
							lineNumber = [_csArg front];
						if (lineNumber < 1) lineNumber = 1; //mjhsieh is paranoid
						
						int j;
						for (j = 0; j < lineNumber; j++) {
							[self clearRow:_cursorY];
							cell *emptyRow = _grid[_cursorY];
							int r;
							for (r = _cursorY; r < _scrollEndRow; r++)
								_grid[r] = _grid[r + 1];
							_grid[_scrollEndRow] = emptyRow;
						}
						for (j = _cursorY; j <= _scrollEndRow; j++)
							[_terminal setDirtyForRow:j];
					} else if (c == CSI_DCH) { // Delete characters at the current cursor position.
						int p = 1;
						if ([_csArg size] == 1) {
							p = [_csArg front];
						}
						if (p < 1) p = 1;
						int j;
						for (j = _cursorX; j <= _column - 1; j++){
							if ( j <= _column - 1 - p ) {
								_grid[_cursorY][j] = _grid[_cursorY][j+p];
							} else {
								_grid[_cursorY][j].byte = '\0';
								_grid[_cursorY][j].attr.v = gEmptyAttr;
								_grid[_cursorY][j].attr.f.bgColor = _bgColor;
							}
							[_terminal setDirty:YES atRow:_cursorY column:j];
						}
					} else if (c == CSI_HPA) { // goto to absolute character position
						int p = 0;
						if ([_csArg size] > 0) {
							p = [_csArg front]-1;
							if (p < 0) p = 0;
						}
						CURSOR_MOVETO(p,_cursorY);
					} else if (c == CSI_HPR) { // goto to the next position of the line
						int p = 1;
						if ([_csArg size] > 0) {
							p = [_csArg front];
							if (p < 1) p = 1;
						}
						CURSOR_MOVETO(_cursorX+p,_cursorY);					
						//				} else if (c == CSI_REP) { // REPEAT, not going to implement for now.
					} else if (c == CSI_DA ) { // Computer requests terminal identify itself.
						unsigned char cmd[10]; // 10 should be enough for now
						unsigned int cmdLength = 0;
						if (_emustd == VT100) { // VT100, respond ESC[?1;0c
							cmd[cmdLength++] = 0x1B; cmd[cmdLength++] = 0x5B;
							cmd[cmdLength++] = 0x3F; cmd[cmdLength++] = '1';
							cmd[cmdLength++] = 0x3B; cmd[cmdLength++] = '0';
							cmd[cmdLength++] = 'c';
						} else if (_emustd == VT102) { // VT102, respond ESC[?6c
							cmd[cmdLength++] = 0x1B; cmd[cmdLength++] = 0x5B;
							cmd[cmdLength++] = 0x3F; cmd[cmdLength++] = '6';
							cmd[cmdLength++] = 'c';
						}
						if ([_csArg empty]) {
							[connection sendBytes:cmd length:cmdLength];
						} else if ([_csArg size] == 1 && [_csArg front] == 0) {
							[connection sendBytes:cmd length:cmdLength];
						}
					} else if (c == CSI_VPA) { // move to Pn line, col remaind the same
						int p = 0;
						if ([_csArg size] > 0) {
							p = [_csArg front]-1;
							if (p < 0) p = 0;
						}
						CURSOR_MOVETO(_cursorX,p);
					} else if (c == CSI_VPR) { // move to Pn Line in forward direction
						int p = 1;
						if ([_csArg size] > 0) {
							p = [_csArg front];
							if (p < 1) p = 1;
						}
						CURSOR_MOVETO(_cursorX,_cursorY+p);
					} else if (c == CSI_TBC) { // Clear a tab at the current column
						int p = 1;
						if ([_csArg size] == 1){
							p = [_csArg front];
						}
						if (p == 3) {
							NSLog(@"Ignoring request to clear all horizontal tab stops.");
						} else
							NSLog(@"Ignoring request to clear one horizontal tab stop.");
					} else if (c == CSI_SM ) {  // set mode
						int doClear = 0;
						while (![_csArg empty]) {
							int p = [_csArg front];
							if (p == -1) {
								[_csArg pop_front];
								if ([_csArg size] == 1) {
									p = [_csArg front];
									if (p == 3) { // Set number of columns to 132
										NSLog(@"132-column mode is not supported.");
										doClear = 1;
										_modeOriginRelative = NO;
										_scrollBeginRow = 0;
										_scrollEndRow = _row - 1;
									} else if (p == 5 && _modeScreenReverse == NO) { //Set reverse video on screen
										_modeScreenReverse = YES;
										_reverse = !_reverse;
										[self reverseAll];
									} else if (p == 6) { // Set origin to relative
										_modeOriginRelative = YES;
									} else if (p == 7) { // Set auto-wrap mode
										_modeWraptext = YES;
										//								} else if (p == 1) { // Set cursor key to application
										//								} else if (p == 4) { // Set smooth scrolling
										//								} else if (p == 8) { // Set auto-repeat mode
										//								} else if (p == 9) { // Set interlacing mode
									}
								}
							} else if (p == 20) { // Set new line mode
								_modeLNM = NO;
							} else if (p == 4) {
								// selects insert mode and turns INSERT on. New
								// display characters move old display characters
								// to the right. Characters moved past the right
								// margin are lost.
								_modeIRM = YES;
								//                      } else if (p == 1) { //When set, the cursor keys send an ESC O prefix, rather than ESC [
								//                      } else if (p == 2) { //NSLog(@"ignore setting Keyboard Action Mode (AM)");
								//						} else if (p == 6) { //_modeErasure = YES;
								//                      } else if (p == 12) { //NSLog(@"ignore re/setting Send/receive (SRM)");
							}
							[_csArg pop_front];
						}
						if (doClear == 1) {
							if (_modeOriginRelative) {
								
							} else {
								[self clearAll];
								_cursorX = 0;
								_cursorY = 0;
							}
						}
					} else if (c == CSI_HPB) { // move to Pn Location in backward direction, same raw
						int p = 1;
						if ([_csArg size] > 0) {
							p = [_csArg front];
							if (p < 1) p = 1;
						}
						CURSOR_MOVETO(_cursorX-p,_cursorY);										
					} else if (c == CSI_VPB) { // move to Pn Line in backward direction
						int p = 1;
						if ([_csArg size] > 0) {
							p = [_csArg front];
							if (p < 1) p = 1;
						}
						CURSOR_MOVETO(_cursorX,_cursorY-p);
					} else if (c == CSI_RM ) { // reset mode
						int doClear = 0;
						while (![_csArg empty]) {
							int p = [_csArg front];
							if (p == -1) {
								[_csArg pop_front];
								if ([_csArg size] == 1) {
									p = [_csArg front];
									if (p == 3) { // Set number of columns to 80
										//NSLog(@"132-column mode (re)setting are not supported.");
										doClear = 1;
										_modeOriginRelative = NO;
										_scrollBeginRow = 0;
										_scrollEndRow = _row - 1;
									} else if (p == 5 && _modeScreenReverse) { // Set non-reverse video on screen
										_modeScreenReverse = NO;
										_reverse = !_reverse;
										[self reverseAll];
									} else if (p == 6) { // Set origin to absolute
										_modeOriginRelative = NO;
									} else if (p == 7) { // Reset auto-wrap mode (disable)
										_modeWraptext = NO;
										//							    } else if (p == 1) { // Set cursor key to cursor
										//								} else if (p == 4) { // Set jump scrolling
										//								} else if (p == 8) { // Reset auto-repeat mode
										//								} else if (p == 9) { // Reset interlacing mode
									}
								}
							} else if (p == 20) { // set line feed mode
								_modeLNM = YES;
							} else if (p == 4) {
								// selects replace mode and turns INSERT off. New
								// display characters replace old display characters
								// at cursor position. The old character is erased.
								_modeIRM = NO;
								//						} else if (p == 6) { //_modeErasure = NO;
							}
							[_csArg pop_front];
						}
						if (doClear == 1) {
							[self clearAll];
							_cursorX = 0, _cursorY = 0;
						}
					} else if (c == CSI_SGR) { // Character Attributes
						if ([_csArg empty]) { // clear
							_fgColor = 7;
							_bgColor = 9;
							_bold = NO;
							_underline = NO;
							_blink = NO;
							_reverse = NO ^ _modeScreenReverse;
						} else {
							while (![_csArg empty]) {
								int p = [_csArg front];
								[_csArg pop_front];
								if (p  == 0) {
									_fgColor = 7;
									_bgColor = 9;
									_bold = NO;
									_underline = NO;
									_blink = NO;
									_reverse = NO ^ _modeScreenReverse;
								} else if (30 <= p && p <= 39) {
									_fgColor = p - 30;
								} else if (40 <= p && p <= 49) {
									_bgColor = p - 40;
								} else if (p == 1) {
									_bold = YES;
								} else if (p == 4) {
									_underline = YES;
								} else if (p == 5) {
									_blink = YES;
								} else if (p == 7) {
									_reverse = YES ^ _modeScreenReverse;
								}
							}
						}
					} else if (c == CSI_DSR) {
						if ([_csArg size] != 1) {
							//do nothing
							//NSLog(@"%s %s",[_csArg front],(*_csArg)[1]);
						} else if ([_csArg front] == 5) {
							unsigned char cmd[4];
							unsigned int cmdLength = 0;
							// Report Device OK	<ESC>[0n
							cmd[cmdLength++] = 0x1B;
							cmd[cmdLength++] = 0x5B;
							cmd[cmdLength++] = 0x30;
							cmd[cmdLength++] = CSI_DSR;
							[connection sendBytes:cmd length:cmdLength];
						} else if ([_csArg front] == 6) {
							unsigned char cmd[8];
							unsigned int cmdLength = 0;
							unsigned int mynum;
							// Report Device OK	<ESC>[y;xR
							cmd[cmdLength++] = 0x1B;
							cmd[cmdLength++] = 0x5B;
							if ((_cursorY + 1)/10 >= 1) {
								mynum = (int)((_cursorY + 1)/10);
								cmd[cmdLength++] = 0x30+mynum;
							}
							mynum = (_cursorY + 1) % 10;
							cmd[cmdLength++] = 0x30+mynum;
							cmd[cmdLength++] = 0x3B;
							if ((_cursorX + 1)/10 >= 1) {
								mynum = (int)((_cursorX + 1)/10);
								cmd[cmdLength++] = 0x30+mynum;
							}
							mynum = (_cursorX + 1) % 10;
							cmd[cmdLength++] = 0x30+mynum;
							cmd[cmdLength++] = CSI_CPR;
							[connection sendBytes:cmd length:cmdLength];
						}
					} else if (c == CSI_DECSTBM) { // Assigning Scrolling Region
						if ([_csArg size] == 0) {
							_scrollBeginRow = 0;
							_scrollEndRow = _row - 1;
						} else if ([_csArg size] == 2) {
							int s = [_csArg front];
							int e = [_csArg at:1];
							if (s > e) s = [_csArg at:1], e = [_csArg front];
							_scrollBeginRow = s - 1;
							_scrollEndRow = e - 1;
							//NSLog(@"Assigning Scrolling Region between line %d and line %d",s,e);
						}
						_cursorX = 0;
						_cursorY = _scrollBeginRow;
					} else if (c == CSI_SCP) {
						_savedCursorX = _cursorX;
						_savedCursorY = _cursorY;
					} else if (c == CSI_RCP) {
						if (_savedCursorX >= 0 && _savedCursorY >= 0) {
							_cursorX = _savedCursorX;
							_cursorY = _savedCursorY;
						}
					} else {
						NSLog(@"unsupported control sequence: 0x%X", c);
					}
					
					[_csArg clear];
					_state = TP_NORMAL;
				}
				
				break;
		}
	}
	
	[_terminal setCursorX:_cursorX Y:_cursorY];
	[_terminal feedGrid:_grid];
	
	if (_hasNewMessage) {
		// new incoming message
		if ([_terminal bbsType] == WLMaple && _grid[_row - 1][0].attr.f.bgColor != 9 && _grid[_row - 1][_column - 2].attr.f.bgColor == 9) {
			// for maple bbs (e.g. ptt)
			for (i = 2; i < _column && _grid[_row - 1][i].attr.f.bgColor == _grid[_row - 1][i - 1].attr.f.bgColor; ++i); // split callerName and messageString
			int splitPoint = i++;
			for (; i < _column && _grid[_row - 1][i].attr.f.bgColor == _grid[_row - 1][i - 1].attr.f.bgColor; ++i); // determine the end of the message
			NSString *callerName = [_terminal stringAtIndex:((_row - 1) * _column + 2) length:(splitPoint - 2)];
			NSString *messageString = [_terminal stringAtIndex:((_row - 1) * _column + splitPoint + 1) length:(i - splitPoint - 2)];
			
			[connection didReceiveNewMessage:messageString fromCaller:callerName];
			_hasNewMessage = NO;
		} else if ([_terminal bbsType] == WLFirebird && _grid[0][0].attr.f.bgColor != 9) {
			// for firebird bbs (e.g. smth)
			for (i = 2; i < _row && _grid[i][0].attr.f.bgColor != 9; ++i);	// determine the end of the message
			NSString *callerName = [_terminal stringAtIndex:0 length:_column];
			NSString *messageString = [_terminal stringAtIndex:_column length:(i - 1) * _column];
			
			[connection didReceiveNewMessage:messageString fromCaller:callerName];
		}
    }
	
    [pool release];
}

- (void)setTerminal:(WLTerminal *)terminal {
    _terminal = terminal;
}


# pragma mark -
# pragma mark Clear

- (void)clearAll {
    _cursorX = _cursorY = 0;
	
    attribute t;
    t.f.fgColor = [WLGlobalConfig sharedInstance]->_fgColorIndex;
    t.f.bgColor = [WLGlobalConfig sharedInstance]->_bgColorIndex;
    t.f.bold = 0;
    t.f.underline = 0;
    t.f.blink = 0;
    t.f.reverse = 0;
    t.f.url = 0;
    t.f.nothing = 0;
    gEmptyAttr = t.v;
	
    _fgColor = [WLGlobalConfig sharedInstance]->_fgColorIndex;
    _bgColor = [WLGlobalConfig sharedInstance]->_bgColorIndex;
    _csTemp = 0;
    _state = TP_NORMAL;
    _bold = NO;
	_underline = NO;
	_blink = NO;
	_reverse = NO;
	
    int i;
    for (i = 0; i < _row; i++) 
        [self clearRow:i];
    
    if (_csBuf)
        [_csBuf clear];
    else
        _csBuf = [[WLIntegerArray integerArray] retain];
    if (_csArg)
        [_csArg clear];
    else
        _csArg = [[WLIntegerArray integerArray] retain];
}

- (void)clearRow:(int)r {
    [self clearRow:r fromStart:0 toEnd:_column - 1];
}

- (void)clearRow:(int)r 
	   fromStart:(int)s 
		   toEnd:(int)e {
    for (int i = s; i <= e; i++) {
        _grid[r][i].byte = '\0';
        _grid[r][i].attr.v = gEmptyAttr;
        _grid[r][i].attr.f.bgColor = _bgColor;
		[_terminal setDirty:YES atRow:r column:i];
    }
}

- (void)reverseAll {
    for (int j = 0; j < _row; j++) {
        for (int i = 0; i <= _column - 1; i++) {
            int tmpColorIndex = _grid[j][i].attr.f.bgColor;
            _grid[j][i].attr.f.bgColor = _grid[j][i].attr.f.fgColor;
            _grid[j][i].attr.f.fgColor = tmpColorIndex;
        }
    }
	[_terminal setAllDirty];
}

- (cell *)cellsOfRow:(int)r {
	return _grid[r];
}

@end
