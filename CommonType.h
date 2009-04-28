/*
 *  CommonType.h
 *  MacBlueTelnet
 *
 *  Created by Yung-Luen Lan on 9/11/07.
 *  Copyright 2007 yllan.org. All rights reserved.
 *
 */
#import <Cocoa/Cocoa.h>

typedef union {
	unsigned short v;
	struct {
		unsigned int fgColor	: 4;
		unsigned int bgColor	: 4;
		unsigned int bold		: 1;
		unsigned int underline	: 1;
		unsigned int blink		: 1;
		unsigned int reverse	: 1;
		unsigned int doubleByte	: 2;
        unsigned int url        : 1;
		unsigned int nothing	: 1;
	} f;
} attribute;

typedef struct {
	unsigned char byte;
	attribute attr;
} cell;

typedef enum {C0, INTERMEDIATE, ALPHABETIC, DELETE, C1, G1, SPECIAL, ERROR} ASCII_CODE;

typedef enum YLEncoding {
    YLBig5Encoding = 1, 
    YLGBKEncoding = 0
} YLEncoding;

typedef enum YLANSIColorKey {
    YLCtrlUANSIColorKey = 1, 
    YLEscEscANSIColorKey = 0
} YLANSIColorKey;

typedef enum {WLNoneProxy, WLAutoProxy, WLSocksProxy, WLHttpProxy, WLHttpsProxy} WLProxyType;

typedef enum {
	WLFirebird, WLMaple, WLUnix
} WLBBSType;

typedef struct {
	/*!
	 @enum 
	 @abstract   This enumeration describes main state of BBS.
	 @discussion States reconition is carried out in <code>[YLTerminal updateBBSState]</code>. Please refer to <code>YLTerminal.h</code> for detailed information about state recognition.
	 @constant   BBSUnknown			Unknown state that cannot be recognized by Welly.
	 @constant	 BBSMainMenu		The user is in the main menu of BBS.
	 @constant	 BBSMailMenu		The user is in the mail menu of BBS. Some special operation might be supported in this state.
	 @constant	 BBSMailList		The user is browsing his mail list. It is similar to the <code>BBSBrowseBoard</code> state, which lists out all mail entry for selection.
	 @constant   BBSFriendList		The user is browsing his friend list. Friends ids are listed.
	 @constant	 BBSBoardList		The user is browsing board list of BBS. Boards names are listed. There are some variants of this state, for example, the user might be browsing his FAVORITE board list. However these variants has similar behavior, so we merged them together.
	 @constant	 BBSBrowseBoard		The user is browsing a board's content. Posts are listed.
	 @constant	 BBSBrowseExcerption	The user is browsing excerption. Though its functionality is similar to the <code>BBSBrowseBoard</code> state, their behavior are different, so we treat them independently.
	 @constant	 BBSViewPost		The user is reading one post.
	 @constant	 BBSComposePost		The user is writing his post or editing existed post. These two states' supported operation is almost the same, so we merged them together.
	 @constant	 BBSWaitingEnter	The BBS is waiting for the user pressing enter key.
	 @constant	 BBSWaitingConfirm	The BBS is waiting for the user to confirm operation. (Y/N)
	 @constant	 BBSUserInfo		The user is querying some user's information.
	*/
	enum {
		BBSUnknown,
		BBSMainMenu, 
		BBSMailMenu, 
		BBSMailList, 
		BBSBoardList, 
		BBSFriendList, 
		BBSBrowseBoard,
		BBSViewPost, 
		BBSComposePost,
		BBSWaitingEnter,
		BBSUserInfo,
		BBSConfirmPost,
		BBSBrowseExcerption,
		BBSWaitingConfirm,
	} state;
	/*!
	 @enum 
	 @abstract   This enumeration is a supplement for the main state. Some main state have some variants which have common behaviors. Some variants have delicate differences, so we use substate to tell them apart for future implementation.
	 @discussion Currently, the <code>substate</code> is mainly used for <code>BBSBrowseBoard</code> main state.
	 @constant   BBSSubStateNone	The main state has no substate.
	 @constant	 BBSBrowseBoardNormalMode	In <code>BBSBrowseBoard</code> state, the user is in Normal mode, which provides most common operations of browsing a board.
	 @constant	 BBSBrowseBoardDigestMode	In <code>BBSBrowseBoard</code> state, the user is in Digest mode, which lists all posts marked as digest (for SMTH BBS, they are marked as 'g').
	 @constant	 BBSBrowseBoardThreadMode	In <code>BBSBrowseBoard</code> state, the user is in Thread mode, which clusters all posts according to the threads they belongs. i.e. posts belong to same thread would be listed together.
	 @constant	 BBSBrowseBoardMarkMode		In <code>BBSBrowseBoard</code> state, the user is in Mark mode, which lists all posts marked as memorable (for SMTH BBS, they are marked as 'm').
	 @constant	 BBSBrowseBoardDigestMode	In <code>BBSBrowseBoard</code> state, the user is in Origin mode, which lists all posts which are original rather than "Re: ...".
	 @constant	 BBSBrowseBoardAuthorMode	In <code>BBSBrowseBoard</code> state, the user is in Author mode, which lists all posts whose author are one certain user.
	*/
	enum {
		BBSSubStateNone,
		BBSBrowseBoardNormalMode,
		BBSBrowseBoardDigestMode,
		BBSBrowseBoardThreadMode,
		BBSBrowseBoardMarkMode,
		BBSBrowseBoardOriginMode,
		BBSBrowseBoardAuthorMode,
	} subState;
//	NSString *boardName;
} BBSState;

#ifdef __cplusplus
extern "C" {
#endif
	int isHiddenAttribute(attribute a) ;
	int isBlinkCell(cell c) ;
	int bgColorIndexOfAttribute(attribute a) ;
	int fgColorIndexOfAttribute(attribute a) ;
	int bgBoldOfAttribute(attribute a) ;
	int fgBoldOfAttribute(attribute a) ;
#ifdef __cplusplus
}
#endif
BOOL isEmptyCell(cell c);
BOOL isLetter(unsigned char c);
BOOL isNumber(unsigned char c);
BOOL shouldBeDirty(cell prevCell, cell newCell);

#define keyStringRight @"\uF703"
#define keyStringLeft @"\uF702"

#define termKeyUp @"\x1B[A"
#define termKeyDown @"\x1B[B"
#define termKeyRight @"\x1B[C"
#define termKeyLeft @"\x1B[D"
#define termKeyEnter @"\x0D"
#define termKeyHome @"\x1B[1~"
#define termKeyEnd @"\x1B[4~"
#define termKeyPageUp @"\x1B[5~"
#define termKeyPageDown @"\x1B[6~"

#define titleBig5 @"SetEncodingBig5"
#define titleGBK @"SetEncodingGBK"

#define supportedCoverExtensions ([NSArray arrayWithObjects:@"jpg", @"jpeg", @"bmp", @"png", @"gif", @"tiff", @"tif", nil])

enum {
	WLWhitespaceCharacter = ' ',
	WLTabCharacter = '\t',
	WLEscapeCharacter = 27,
	WLReturnCharacter = '\r',
	WLNewlineCharacter = '\n',
	WLNullTerminator = '\0',	
};