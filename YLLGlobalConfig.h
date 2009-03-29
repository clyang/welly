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

NSString *const WLCoverFlowModeEnabledKeyName;
NSString *const WLRestoreConnectionKeyName;

@interface YLLGlobalConfig : NSObject {
@public
    int _messageCount;
	int _row;
	int _column;
	CGFloat _cellWidth;
	CGFloat _cellHeight;
    
    int _bgColorIndex;
    int _fgColorIndex;
    
    BOOL _showHiddenText;
	BOOL _blinkTicker;
    BOOL _shouldSmoothFonts;
    BOOL _detectDoubleByte;
	BOOL _enableMouse;
	BOOL _autoReply;
    BOOL _repeatBounce;
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
    
	CTFontRef _cCTFont;
	CTFontRef _eCTFont;
	CGFontRef _cCGFont;
	CGFontRef _eCGFont;
    
	NSColor *_colorTable[2][NUM_COLOR];

	CFDictionaryRef _cCTAttribute[2][NUM_COLOR];
	CFDictionaryRef _eCTAttribute[2][NUM_COLOR];
}

+ (YLLGlobalConfig *)sharedInstance;

- (void)refreshFont;

- (int)messageCount;
- (void)setMessageCount:(int)value;

- (int)row;
- (void)setRow:(int)value;
- (int)column;
- (void)setColumn:(int)value;
- (CGFloat)cellWidth;
- (void)setCellWidth:(CGFloat)value;
- (CGFloat)cellHeight;
- (void)setCellHeight:(CGFloat)value;

- (BOOL)showHiddenText;
- (void)setShowHiddenText:(BOOL)value;
- (BOOL)shouldSmoothFonts;
- (void)setShouldSmoothFonts:(BOOL)value;
- (BOOL)detectDoubleByte;
- (void)setDetectDoubleByte:(BOOL)value;
- (BOOL)enableMouse;
- (void)setEnableMouse:(BOOL)value;
- (BOOL)repeatBounce;
- (void)setRepeatBounce:(BOOL)value;
- (YLEncoding)defaultEncoding;
- (void)setDefaultEncoding:(YLEncoding)value;
- (YLANSIColorKey)defaultANSIColorKey;
- (void)setDefaultANSIColorKey:(YLANSIColorKey)value;

- (NSColor *)colorAtIndex:(int)i 
				   hilite:(BOOL)h;
- (void)setColor:(NSColor *)c 
		  hilite:(BOOL)h 
		 atIndex:(int)i;

- (BOOL)blinkTicker;
- (void)setBlinkTicker:(BOOL)value;
- (void)updateBlinkTicker;

- (CGFloat)chineseFontSize;
- (void)setChineseFontSize:(CGFloat)value;

- (CGFloat)englishFontSize;
- (void)setEnglishFontSize:(CGFloat)value;

- (CGFloat)chineseFontPaddingLeft;
- (void)setChineseFontPaddingLeft:(CGFloat)value;

- (CGFloat)englishFontPaddingLeft;
- (void)setEnglishFontPaddingLeft:(CGFloat)value;

- (CGFloat)chineseFontPaddingBottom;
- (void)setChineseFontPaddingBottom:(CGFloat)value;

- (CGFloat)englishFontPaddingBottom;
- (void)setEnglishFontPaddingBottom:(CGFloat)value;

- (NSString *)chineseFontName;
- (void)setChineseFontName:(NSString *)value;

- (NSString *)englishFontName;
- (void)setEnglishFontName:(NSString *)value;

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
