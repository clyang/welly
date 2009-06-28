//
//  YLLGlobalConfig.h
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/11/12.
//  Copyright 2006 yllan.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CommonType.h"
#import <ApplicationServices/ApplicationServices.h>
#define NUM_COLOR 10

NSString *const WLRestoreConnectionKeyName;
NSString *const WLCommandRHotkeyEnabledKeyName;
NSString *const WLConfirmOnCloseEnabledKeyName;
NSString *const WLSafePasteEnabledKeyName;
NSString *const WLCoverFlowModeEnabledKeyName;

@interface YLLGlobalConfig : NSObject {
    int _messageCount;
	int _row;
	int _column;
	CGFloat _cellWidth;
	CGFloat _cellHeight;
    
    BOOL _showsHiddenText;
	BOOL _blinkTicker;
    BOOL _shouldSmoothFonts;
    BOOL _shouldDetectDoubleByte;
	BOOL _shouldEnableMouse;
	BOOL _shouldAutoReply;
    BOOL _shouldRepeatBounce;
    YLEncoding _defaultEncoding;
    YLANSIColorKey _defaultANSIColorKey;
    
    CGFloat _chineseFontSize;
    CGFloat _englishFontSize;
    CGFloat _chineseFontPaddingLeft;
    CGFloat _englishFontPaddingLeft;
    CGFloat _chineseFontPaddingBottom;
    CGFloat _englishFontPaddingBottom;
    NSString *_chineseFontName;
    NSString *_englishFontName;
	
@public   
    int _bgColorIndex;
    int _fgColorIndex;
	
	CTFontRef _cCTFont;
	CTFontRef _eCTFont;
	CGFontRef _cCGFont;
	CGFontRef _eCGFont;

	NSColor *_colorTable[2][NUM_COLOR];

	CFDictionaryRef _cCTAttribute[2][NUM_COLOR];
	CFDictionaryRef _eCTAttribute[2][NUM_COLOR];
}
@property (readwrite, assign) int messageCount;
@property (readwrite, assign) int row;
@property (readwrite, assign) int column;
@property (readwrite, assign) CGFloat cellWidth;
@property (readwrite, assign) CGFloat cellHeight;
@property (readwrite, assign) BOOL showsHiddenText;
@property (readwrite, assign) BOOL shouldSmoothFonts;
@property (readwrite, assign) BOOL shouldDetectDoubleByte;
@property (readwrite, assign) BOOL shouldEnableMouse;
@property (readwrite, assign) BOOL shouldRepeatBounce;
@property (readwrite, assign) YLEncoding defaultEncoding;
@property (readwrite, assign) YLANSIColorKey defaultANSIColorKey;
@property (readwrite, assign) BOOL blinkTicker;
@property (readwrite, assign) CGFloat chineseFontSize;
@property (readwrite, assign) CGFloat englishFontSize;
@property (readwrite, assign) CGFloat chineseFontPaddingLeft;
@property (readwrite, assign) CGFloat englishFontPaddingLeft;
@property (readwrite, assign) CGFloat chineseFontPaddingBottom;
@property (readwrite, assign) CGFloat englishFontPaddingBottom;
@property (readwrite, copy) NSString *chineseFontName;
@property (readwrite, copy) NSString *englishFontName;

+ (YLLGlobalConfig *)sharedInstance;

- (void)refreshFont;

- (NSColor *)colorAtIndex:(int)i 
				   hilite:(BOOL)h;
- (void)setColor:(NSColor *)c 
		  hilite:(BOOL)h 
		 atIndex:(int)i;

- (void)updateBlinkTicker;

/* Set font size */
- (void)setFontSizeRatio:(CGFloat)ratio;

/* Color */
- (NSColor *)colorBlack;
- (void)setColorBlack:(NSColor *)c;
- (NSColor *)colorBlackHilite;
- (void)setColorBlackHilite:(NSColor *)c;

- (NSColor *)colorRed;
- (void)setColorRed:(NSColor *)c;
- (NSColor *)colorRedHilite;
- (void)setColorRedHilite:(NSColor *)c;

- (NSColor *)colorGreen;
- (void)setColorGreen:(NSColor *)c;
- (NSColor *)colorGreenHilite;
- (void)setColorGreenHilite:(NSColor *)c;

- (NSColor *)colorYellow;
- (void)setColorYellow:(NSColor *)c;
- (NSColor *)colorYellowHilite;
- (void)setColorYellowHilite:(NSColor *)c;

- (NSColor *)colorBlue;
- (void)setColorBlue:(NSColor *)c;
- (NSColor *)colorBlueHilite;
- (void)setColorBlueHilite:(NSColor *)c;

- (NSColor *)colorMagenta;
- (void)setColorMagenta:(NSColor *)c;
- (NSColor *)colorMagentaHilite;
- (void)setColorMagentaHilite:(NSColor *)c;

- (NSColor *)colorCyan;
- (void)setColorCyan:(NSColor *)c;
- (NSColor *)colorCyanHilite;
- (void)setColorCyanHilite:(NSColor *)c;

- (NSColor *)colorWhite;
- (void)setColorWhite:(NSColor *)c;
- (NSColor *)colorWhiteHilite;
- (void)setColorWhiteHilite:(NSColor *)c;

- (NSColor *)colorBG;
- (void)setColorBG:(NSColor *)c;
- (NSColor *)colorBGHilite;
- (void)setColorBGHilite:(NSColor *)c;

@end
