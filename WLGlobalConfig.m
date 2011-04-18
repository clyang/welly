//
//  WLGlobalConfig.h
//  Welly
//
//  YLLGlobalConfig.m
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/11/12.
//  Copyright 2006 yllan.org. All rights reserved.
//

#import "WLGlobalConfig.h"
#import "SynthesizeSingleton.h"

#pragma mark -
#pragma mark Constants
NSString *const WLRestoreConnectionKeyName = @"RestoreConnection";
NSString *const WLCommandRHotkeyEnabledKeyName = @"CommandRHotkey";
NSString *const WLConfirmOnCloseEnabledKeyName = @"ConfirmOnClose";
NSString *const WLSafePasteEnabledKeyName = @"SafePaste";
NSString *const WLCoverFlowModeEnabledKeyName = @"Portal";

const CGFloat WLDefaultCellWidth = 12;
const CGFloat WLDefaultCellHeight = 24;
const CGFloat WLDefaultChineseFontSize = 22;
const CGFloat WLDefaultEnglishFontSize = 18;
NSString *const WLDefaultChineseFontName = @"STHeiti";
NSString *const WLDefaultEnglishFontName = @"Monaco";

#pragma mark -
#pragma mark Class Define

@interface NSUserDefaults(myColorSupport)
- (void)setMyColor:(NSColor *)aColor forKey:(NSString *)aKey;
- (NSColor *)myColorForKey:(NSString *)aKey;
@end

@implementation NSUserDefaults(myColorSupport)
- (void)setMyColor:(NSColor *)aColor 
			forKey:(NSString *)aKey {
    NSData *theData=[NSArchiver archivedDataWithRootObject:aColor];
    [self setObject:theData forKey:aKey];
}

- (NSColor *)myColorForKey:(NSString *)aKey {
    NSColor *theColor=nil;
    NSData *theData=[self dataForKey:aKey];
    if (theData != nil)
        theColor=(NSColor *)[NSUnarchiver unarchiveObjectWithData:theData];
    return theColor;
}
@end

@implementation WLGlobalConfig
@synthesize messageCount = _messageCount;
@synthesize row = _row;
@synthesize column = _column;
@synthesize cellWidth = _cellWidth;
@synthesize cellHeight = _cellHeight;
@synthesize showsHiddenText = _showsHiddenText;
@synthesize shouldSmoothFonts = _shouldSmoothFonts;
@synthesize shouldDetectDoubleByte = _shouldDetectDoubleByte;
@synthesize shouldEnableMouse = _shouldEnableMouse;
@synthesize shouldRepeatBounce = _shouldRepeatBounce;
@synthesize defaultEncoding = _defaultEncoding;
@synthesize defaultANSIColorKey = _defaultANSIColorKey;
@synthesize blinkTicker = _blinkTicker;
@synthesize chineseFontSize = _chineseFontSize;
@synthesize englishFontSize = _englishFontSize;
@synthesize chineseFontPaddingLeft = _chineseFontPaddingLeft;
@synthesize englishFontPaddingLeft = _englishFontPaddingLeft;
@synthesize chineseFontPaddingBottom = _chineseFontPaddingBottom;
@synthesize englishFontPaddingBottom = _englishFontPaddingBottom;
@synthesize chineseFontName = _chineseFontName;
@synthesize englishFontName = _englishFontName;

SYNTHESIZE_SINGLETON_FOR_CLASS(WLGlobalConfig);

- (id)init {
    if (self != [super init])
        return nil;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [self setShowsHiddenText:[defaults boolForKey:@"ShowHiddenText"]];
    [self setShouldSmoothFonts:[defaults boolForKey:@"ShouldSmoothFonts"]];
    [self setShouldDetectDoubleByte:[defaults boolForKey:@"DetectDoubleByte"]];
    [self setShouldEnableMouse:[defaults boolForKey:@"EnableMouse"]];
    [self setDefaultEncoding:(WLEncoding) [defaults integerForKey:@"DefaultEncoding"]];
    [self setDefaultANSIColorKey:(YLANSIColorKey) [defaults integerForKey:@"DefaultANSIColorKey"]];
    [self setShouldRepeatBounce:[defaults boolForKey:@"RepeatBounce"]];

    // init code
    _row = 24;
    _column = 80;
    [self setCellWidth:[defaults floatForKey:@"CellWidth"]];
    [self setCellHeight:[defaults floatForKey:@"CellHeight"]];

    [self setChineseFontName:[defaults stringForKey:@"ChineseFontName"]];
    [self setEnglishFontName:[defaults stringForKey:@"EnglishFontName"]];
    [self setChineseFontSize:[defaults floatForKey:@"ChineseFontSize"]];
    [self setEnglishFontSize:[defaults floatForKey:@"EnglishFontSize"]];
        
    if ([defaults objectForKey:@"ChinesePaddingLeft"])
        [self setChineseFontPaddingLeft:[defaults floatForKey:@"ChinesePaddingLeft"]];
    else
        [self setChineseFontPaddingLeft:1.0];

    if ([defaults objectForKey:@"EnglishPaddingLeft"])
        [self setEnglishFontPaddingLeft:[defaults floatForKey:@"EnglishPaddingLeft"]];
    else
        [self setEnglishFontPaddingLeft:1.0];
        
    if ([defaults objectForKey:@"ChinesePaddingBottom"])
        [self setChineseFontPaddingBottom:[defaults floatForKey:@"ChinesePaddingBottom"]];
    else
        [self setChineseFontPaddingBottom:1.0];
        
    if ([defaults objectForKey:@"EnglishPaddingBottom"])
        [self setEnglishFontPaddingBottom:[defaults floatForKey:@"EnglishPaddingBottom"]];
    else
        [self setEnglishFontPaddingBottom:2.0];        
        
    [self setColorBlack:[defaults myColorForKey:@"ColorBlack"]];
    [self setColorBlackHilite:[defaults myColorForKey:@"ColorBlackHilite"]]; 
    [self setColorRed:[defaults myColorForKey:@"ColorRed"]];
    [self setColorRedHilite:[defaults myColorForKey:@"ColorRedHilite"]]; 
    [self setColorBlack:[defaults myColorForKey:@"ColorBlack"]];
    [self setColorBlackHilite:[defaults myColorForKey:@"ColorBlackHilite"]]; 
    [self setColorGreen:[defaults myColorForKey:@"ColorGreen"]];
    [self setColorGreenHilite:[defaults myColorForKey:@"ColorGreenHilite"]]; 
    [self setColorYellow:[defaults myColorForKey:@"ColorYellow"]];
    [self setColorYellowHilite:[defaults myColorForKey:@"ColorYellowHilite"]]; 
    [self setColorBlue:[defaults myColorForKey:@"ColorBlue"]];
    [self setColorBlueHilite:[defaults myColorForKey:@"ColorBlueHilite"]]; 
    [self setColorMagenta:[defaults myColorForKey:@"ColorMagenta"]];
    [self setColorMagentaHilite:[defaults myColorForKey:@"ColorMagentaHilite"]]; 
    [self setColorCyan:[defaults myColorForKey:@"ColorCyan"]];
    [self setColorCyanHilite:[defaults myColorForKey:@"ColorCyanHilite"]]; 
    [self setColorWhite:[defaults myColorForKey:@"ColorWhite"]];
    [self setColorWhiteHilite:[defaults myColorForKey:@"ColorWhiteHilite"]]; // Foreground Color
    [self setColorBG:[defaults myColorForKey:@"ColorBG"]];
    [self setColorBGHilite:[defaults myColorForKey:@"ColorBGHilite"]]; 
    //_colorTable[0][8] = [[NSColor colorWithDeviceRed:0.75 green:0.75 blue:0.75 alpha:1.0] retain];
    //_colorTable[1][8] = [[NSColor colorWithDeviceRed:1.00 green:1.00 blue:1.00 alpha:1.0] retain];
	_colorTable[0][8] = [NSColor colorWithDeviceRed:0.75 green:0.75 blue:0.75 alpha:1.0];
    _colorTable[1][8] = [NSColor colorWithDeviceRed:1.00 green:1.00 blue:1.00 alpha:1.0];


    _bgColorIndex = 9;
    _fgColorIndex = 7;

    [defaults synchronize];
    [self refreshFont];
        
    // aqua: why not enable these settings by default?
    if ([defaults objectForKey:WLRestoreConnectionKeyName] == nil)
        [defaults setBool:YES forKey:WLRestoreConnectionKeyName];
    if ([defaults objectForKey:WLCommandRHotkeyEnabledKeyName] == nil)
        [defaults setBool:YES forKey:WLCommandRHotkeyEnabledKeyName];
    if ([defaults objectForKey:WLConfirmOnCloseEnabledKeyName] == nil)
        [defaults setBool:YES forKey:WLConfirmOnCloseEnabledKeyName];
    if ([defaults objectForKey:WLSafePasteEnabledKeyName] == nil)
        [defaults setBool:YES forKey:WLSafePasteEnabledKeyName];
    if ([defaults objectForKey:WLCoverFlowModeEnabledKeyName] == nil)
        [defaults setBool:YES forKey:WLCoverFlowModeEnabledKeyName];
	
	// Initialize Cache
	[isa initializeCache];

    return self;
}

- (void)dealloc {	
	[super dealloc];
}

- (void)setFontSizeRatio:(CGFloat)ratio {
	[self setEnglishFontSize:_englishFontSize * ratio];
	[self setChineseFontSize:_chineseFontSize * ratio];
	[self setCellWidth:_cellWidth * ratio];
	[self setCellHeight:_cellHeight * ratio];
}

- (void)refreshFont {
    int i, j;
    
    if (_cCTFont) 
		CFRelease(_cCTFont);
    _cCTFont = CTFontCreateWithName((CFStringRef)_chineseFontName, _chineseFontSize, NULL);
    if (_eCTFont)
		CFRelease(_eCTFont);
    _eCTFont = CTFontCreateWithName((CFStringRef)_englishFontName, _englishFontSize, NULL);
    if (_cCGFont)
		CFRelease(_cCGFont);
    _cCGFont = CTFontCopyGraphicsFont(_cCTFont, NULL);
    if (_eCGFont)
		CFRelease(_eCGFont);
    _eCGFont = CTFontCopyGraphicsFont(_eCTFont, NULL);
    
    for (i = 0; i < NUM_COLOR; i++) 
        for (j = 0; j < 2; j++) {
            int zero = 0;
            CFNumberRef number = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &zero);
            CFStringRef cfKeys[] = {kCTFontAttributeName, kCTForegroundColorAttributeName, kCTLigatureAttributeName};
            
            CFTypeRef cfValues[] = {_cCTFont, _colorTable[j][i], number};
            if (_cCTAttribute[j][i])CFRelease(_cCTAttribute[j][i]);
            _cCTAttribute[j][i] = CFDictionaryCreate(kCFAllocatorDefault, 
                                                     (const void **)cfKeys, 
                                                     (const void **)cfValues, 
                                                     3, 
                                                     &kCFTypeDictionaryKeyCallBacks, 
                                                     &kCFTypeDictionaryValueCallBacks);

            cfValues[0] = _eCTFont;
            if (_eCTAttribute[j][i])CFRelease(_eCTAttribute[j][i]);
            _eCTAttribute[j][i] = CFDictionaryCreate(kCFAllocatorDefault, 
                                                     (const void **)cfKeys, 
                                                     (const void **)cfValues, 
                                                     3, 
                                                     &kCFTypeDictionaryKeyCallBacks, 
                                                     &kCFTypeDictionaryValueCallBacks);
            CFRelease(number);
        }
    
}

#pragma mark -
#pragma mark Accessor
- (CGFloat)cellWidth {
	return (CGFloat)((int)(_cellWidth + 0.5));
}

- (void)setCellWidth:(CGFloat)value {
    if (value == 0) 
		value = WLDefaultCellWidth;
    _cellWidth = value;
    [[NSUserDefaults standardUserDefaults] setFloat:value forKey:@"CellWidth"];
}

- (CGFloat)cellHeight {
	return (CGFloat)((int)(_cellHeight + 0.5));
}


- (void)setCellHeight:(CGFloat)value {
    if (value == 0) 
		value = WLDefaultCellHeight;
    _cellHeight = value;
    [[NSUserDefaults standardUserDefaults] setFloat:value forKey:@"CellHeight"];
}

- (NSColor *)colorAtIndex:(int)i 
				   hilite:(BOOL)h {
	if (i >= 0 && i < NUM_COLOR) 
		return _colorTable[h][i];
	return _colorTable[0][NUM_COLOR - 1];
}

- (NSColor *)bgColorAtIndex:(int)i 
					 hilite:(BOOL)h {
	return [[self colorAtIndex:i hilite:h] colorWithAlphaComponent:[[self colorBG] alphaComponent]];
}

- (void)setColor:(NSColor *)c 
		  hilite:(BOOL)h 
		 atIndex:(int)i {
	if (i >= 0 && i < NUM_COLOR) {
		[_colorTable[h][i] autorelease];
		_colorTable[h][i] = [[c colorUsingColorSpaceName:NSCalibratedRGBColorSpace] retain];
	}
}

- (void)setShowsHiddenText:(BOOL)value {
    _showsHiddenText = value;
    [[NSUserDefaults standardUserDefaults] setBool:value forKey:@"ShowHiddenText"];
}

- (void)setShouldSmoothFonts:(BOOL)value {
    _shouldSmoothFonts = value;
    [[NSUserDefaults standardUserDefaults] setBool:value forKey:@"ShouldSmoothFonts"];
}

- (void)setShouldRepeatBounce:(BOOL)value {
    _shouldRepeatBounce = value;
    [[NSUserDefaults standardUserDefaults] setBool:value forKey:@"RepeatBounce"];
}

- (void)setShouldDetectDoubleByte:(BOOL)value {
    _shouldDetectDoubleByte = value;
    [[NSUserDefaults standardUserDefaults] setBool:value forKey:@"DetectDoubleByte"];
}

- (void)setShouldEnableMouse:(BOOL)value {
    _shouldEnableMouse = value;
    [[NSUserDefaults standardUserDefaults] setBool:value forKey:@"EnableMouse"];
}

- (void)setDefaultEncoding:(WLEncoding)value {
    _defaultEncoding = value;
    [[NSUserDefaults standardUserDefaults] setInteger:(NSInteger)value forKey:@"DefaultEncoding"];
}

- (void)setDefaultANSIColorKey:(YLANSIColorKey)value {
    _defaultANSIColorKey = value;
    [[NSUserDefaults standardUserDefaults] setInteger:(NSInteger)value forKey:@"DefaultANSIColorKey"];
}

- (void)updateBlinkTicker {
    [self setBlinkTicker:!_blinkTicker];
}

- (CGFloat)chineseFontSize {
	return (CGFloat)((int)(_chineseFontSize + 0.5));
}

- (void)setChineseFontSize:(CGFloat)value {
    if (value == 0) 
		value = WLDefaultChineseFontSize;
    _chineseFontSize = value;
    [[NSUserDefaults standardUserDefaults] setFloat:value forKey:@"ChineseFontSize"];
}

- (CGFloat)englishFontSize {
	return (CGFloat)((int)(_englishFontSize + 0.5));
}

- (void)setEnglishFontSize:(CGFloat)value {
    if (value == 0) 
		value = WLDefaultEnglishFontSize;
    _englishFontSize = value;
    [[NSUserDefaults standardUserDefaults] setFloat:value forKey:@"EnglishFontSize"];
}

- (void)setChineseFontPaddingLeft:(CGFloat)value {
    _chineseFontPaddingLeft = value;
    [[NSUserDefaults standardUserDefaults] setFloat:value forKey:@"ChinesePaddingLeft"];
}

- (void)setEnglishFontPaddingLeft:(CGFloat)value {
    _englishFontPaddingLeft = value;
    [[NSUserDefaults standardUserDefaults] setFloat:value forKey:@"EnglishPaddingLeft"];
}

- (void)setChineseFontPaddingBottom:(CGFloat)value {
    _chineseFontPaddingBottom = value;
    [[NSUserDefaults standardUserDefaults] setFloat:value forKey:@"ChinesePaddingBottom"];
}

- (void)setEnglishFontPaddingBottom:(CGFloat)value {
    _englishFontPaddingBottom = value;
    [[NSUserDefaults standardUserDefaults] setFloat:value forKey:@"EnglishPaddingBottom"];
}

//- (NSString *)chineseFontName { return [[_chineseFontName copy] autorelease]; }
- (void)setChineseFontName:(NSString *)value {
    if (!value) value = WLDefaultChineseFontName;
    if (_chineseFontName != value) {
        [_chineseFontName release];
        _chineseFontName = [value copy];
        [[NSUserDefaults standardUserDefaults] setObject:value forKey:@"ChineseFontName"];
    }
}

//- (NSString *)englishFontName { return [[_englishFontName copy] autorelease]; }
- (void)setEnglishFontName:(NSString *)value {
    if (!value) value = WLDefaultEnglishFontName;
    if (_englishFontName != value) {
        [_englishFontName release];
        _englishFontName = [value copy];
        [[NSUserDefaults standardUserDefaults] setObject:value forKey:@"EnglishFontName"];
    }
}

#pragma mark -
#pragma mark Colors
- (NSColor *)colorBlack { return _colorTable[0][0]; }
- (void)setColorBlack:(NSColor *)c {
    if (!c)
		c = [NSColor colorWithDeviceRed:0.00 green:0.00 blue:0.00 alpha:1.0];
    if (c != _colorTable[0][0]) {
        [_colorTable[0][0] release];
        _colorTable[0][0] = [[c colorUsingColorSpaceName:NSCalibratedRGBColorSpace] retain];
    }
    [[NSUserDefaults standardUserDefaults] setMyColor:c forKey:@"ColorBlack"];
}
- (NSColor *)colorBlackHilite { return _colorTable[1][0]; }
- (void)setColorBlackHilite:(NSColor *)c {
    if (!c)c = [NSColor colorWithDeviceRed:0.25 green:0.25 blue:0.25 alpha:1.0];
    if (c != _colorTable[1][0]) {
        [_colorTable[1][0] release];
        _colorTable[1][0] = [[c colorUsingColorSpaceName:NSCalibratedRGBColorSpace] retain];
    }
    [[NSUserDefaults standardUserDefaults] setMyColor:c forKey:@"ColorBlackHilite"];
}

- (NSColor *)colorRed { return _colorTable[0][1]; }
- (void)setColorRed:(NSColor *)c {
    if (!c)c = [NSColor colorWithDeviceRed:0.50 green:0.00 blue:0.00 alpha:1.0];
    if (c != _colorTable[0][1]) {
        [_colorTable[0][1] release];
        _colorTable[0][1] = [[c colorUsingColorSpaceName:NSCalibratedRGBColorSpace] retain];
    }
    [[NSUserDefaults standardUserDefaults] setMyColor:c forKey:@"ColorRed"];
}
- (NSColor *)colorRedHilite { return _colorTable[1][1]; }
- (void)setColorRedHilite:(NSColor *)c {
    if (!c)c = [NSColor colorWithDeviceRed:1.00 green:0.00 blue:0.00 alpha:1.0];
    if (c != _colorTable[1][1]) {
        [_colorTable[1][1] release];
        _colorTable[1][1] = [[c colorUsingColorSpaceName:NSCalibratedRGBColorSpace] retain];
    }
    [[NSUserDefaults standardUserDefaults] setMyColor:c forKey:@"ColorRedHilite"];
}

- (NSColor *)colorGreen { return _colorTable[0][2]; }
- (void)setColorGreen:(NSColor *)c {
    if (!c)c = [NSColor colorWithDeviceRed:0.00 green:0.50 blue:0.00 alpha:1.0];
    if (c != _colorTable[0][2]) {
        [_colorTable[0][2] release];
        _colorTable[0][2] = [[c colorUsingColorSpaceName:NSCalibratedRGBColorSpace] retain];
    }
    [[NSUserDefaults standardUserDefaults] setMyColor:c forKey:@"ColorGreen"];
}
- (NSColor *)colorGreenHilite { return _colorTable[1][2]; }
- (void)setColorGreenHilite:(NSColor *)c {
    if (!c)c = [NSColor colorWithDeviceRed:0.00 green:1.00 blue:0.00 alpha:1.0];
    if (c != _colorTable[1][2]) {
        [_colorTable[1][2] release];
        _colorTable[1][2] = [[c colorUsingColorSpaceName:NSCalibratedRGBColorSpace] retain];
    }
    [[NSUserDefaults standardUserDefaults] setMyColor:c forKey:@"ColorGreenHilite"];
}

- (NSColor *)colorYellow { return _colorTable[0][3]; }
- (void)setColorYellow:(NSColor *)c {
    if (!c)c = [NSColor colorWithDeviceRed:0.50 green:0.50 blue:0.00 alpha:1.0];
    if (c != _colorTable[0][3]) {
        [_colorTable[0][3] release];
        _colorTable[0][3] = [[c colorUsingColorSpaceName:NSCalibratedRGBColorSpace] retain];
    }
    [[NSUserDefaults standardUserDefaults] setMyColor:c forKey:@"ColorYellow"];
}
- (NSColor *)colorYellowHilite { return _colorTable[1][3]; }
- (void)setColorYellowHilite:(NSColor *)c {
    if (!c)c = [NSColor colorWithDeviceRed:1.00 green:1.00 blue:0.00 alpha:1.0];
    if (c != _colorTable[1][3]) {
        [_colorTable[1][3] release];
        _colorTable[1][3] = [[c colorUsingColorSpaceName:NSCalibratedRGBColorSpace] retain];
    }
    [[NSUserDefaults standardUserDefaults] setMyColor:c forKey:@"ColorYellowHilite"];
}

- (NSColor *)colorBlue { return _colorTable[0][4]; }
- (void)setColorBlue:(NSColor *)c {
    if (!c)c = [NSColor colorWithDeviceRed:0.00 green:0.00 blue:0.50 alpha:1.0];
    if (c != _colorTable[0][4]) {
        [_colorTable[0][4] release];
        _colorTable[0][4] = [[c colorUsingColorSpaceName:NSCalibratedRGBColorSpace] retain];
    }
    [[NSUserDefaults standardUserDefaults] setMyColor:c forKey:@"ColorBlue"];
}
- (NSColor *)colorBlueHilite { return _colorTable[1][4]; }
- (void)setColorBlueHilite:(NSColor *)c {
    if (!c)c = [NSColor colorWithDeviceRed:0.00 green:0.00 blue:1.00 alpha:1.0];
    if (c != _colorTable[1][4]) {
        [_colorTable[1][4] release];
        _colorTable[1][4] = [[c colorUsingColorSpaceName:NSCalibratedRGBColorSpace] retain];
    }
    [[NSUserDefaults standardUserDefaults] setMyColor:c forKey:@"ColorBlueHilite"];
}

- (NSColor *)colorMagenta { return _colorTable[0][5]; }
- (void)setColorMagenta:(NSColor *)c {
    if (!c)c = [NSColor colorWithDeviceRed:0.50 green:0.00 blue:0.50 alpha:1.0];
    if (c != _colorTable[0][5]) {
        [_colorTable[0][5] release];
        _colorTable[0][5] = [[c colorUsingColorSpaceName:NSCalibratedRGBColorSpace] retain];
    }
    [[NSUserDefaults standardUserDefaults] setMyColor:c forKey:@"ColorMagenta"];
}
- (NSColor *)colorMagentaHilite { return _colorTable[1][5]; }
- (void)setColorMagentaHilite:(NSColor *)c {
    if (!c)c = [NSColor colorWithDeviceRed:1.00 green:0.00 blue:1.00 alpha:1.0];
    if (c != _colorTable[1][5]) {
        [_colorTable[1][5] release];
        _colorTable[1][5] = [[c colorUsingColorSpaceName:NSCalibratedRGBColorSpace] retain];
    }
    [[NSUserDefaults standardUserDefaults] setMyColor:c forKey:@"ColorMagentaHilite"];
}

- (NSColor *)colorCyan { return _colorTable[0][6]; }
- (void)setColorCyan:(NSColor *)c {
    if (!c)c = [NSColor colorWithDeviceRed:0.00 green:0.50 blue:0.50 alpha:1.0];
    if (c != _colorTable[0][6]) {
        [_colorTable[0][6] release];
        _colorTable[0][6] = [[c colorUsingColorSpaceName:NSCalibratedRGBColorSpace] retain];
    }
    [[NSUserDefaults standardUserDefaults] setMyColor:c forKey:@"ColorCyan"];
}
- (NSColor *)colorCyanHilite { return _colorTable[1][6]; }
- (void)setColorCyanHilite:(NSColor *)c {
    if (!c)c = [NSColor colorWithDeviceRed:0.00 green:1.00 blue:1.00 alpha:1.0];
    if (c != _colorTable[1][6]) {
        [_colorTable[1][6] release];
        _colorTable[1][6] = [[c colorUsingColorSpaceName:NSCalibratedRGBColorSpace] retain];
    }
    [[NSUserDefaults standardUserDefaults] setMyColor:c forKey:@"ColorCyanHilite"];
}

- (NSColor *)colorWhite { return _colorTable[0][7]; }
- (void)setColorWhite:(NSColor *)c {
    if (!c)c = [NSColor colorWithDeviceRed:0.50 green:0.50 blue:0.50 alpha:1.0];
    if (c != _colorTable[0][7]) {
        [_colorTable[0][7] release];
        _colorTable[0][7] = [[c colorUsingColorSpaceName:NSCalibratedRGBColorSpace] retain];
    }
    [[NSUserDefaults standardUserDefaults] setMyColor:c forKey:@"ColorWhite"];
}
- (NSColor *)colorWhiteHilite { return _colorTable[1][7]; }
- (void)setColorWhiteHilite:(NSColor *)c {
    if (!c)c = [NSColor colorWithDeviceRed:1.00 green:1.00 blue:1.00 alpha:1.0];
    if (c != _colorTable[1][7]) {
        [_colorTable[1][7] release];
        _colorTable[1][7] = [[c colorUsingColorSpaceName:NSCalibratedRGBColorSpace] retain];
    }
    [[NSUserDefaults standardUserDefaults] setMyColor:c forKey:@"ColorWhiteHilite"];
}

- (NSColor *)colorBG { return _colorTable[0][9]; }
- (void)setColorBG:(NSColor *)c {
    if (!c)c = [NSColor colorWithDeviceRed:0.00 green:0.00 blue:0.00 alpha:1.0];
    if (c != _colorTable[0][9]) {
        [_colorTable[0][9] release];
        _colorTable[0][9] = [[c colorUsingColorSpaceName:NSCalibratedRGBColorSpace] retain];
//        if ([self colorBGHilite] != c) [self setColorBGHilite: c];
    }
    [[NSUserDefaults standardUserDefaults] setMyColor:c forKey:@"ColorBG"];
}

- (NSColor *)colorBGHilite { return _colorTable[1][9]; }
- (void)setColorBGHilite:(NSColor *)c {
    if (!c)c = [NSColor colorWithDeviceRed:0.00 green:0.00 blue:0.00 alpha:1.0];
    if (c != _colorTable[1][9]) {
        [_colorTable[1][9] release];
        _colorTable[1][9] = [[c colorUsingColorSpaceName:NSCalibratedRGBColorSpace] retain];
//        if ([self colorBG] != c) [self setColorBG: c];
    }
    [[NSUserDefaults standardUserDefaults] setMyColor:c forKey:@"ColorBGHilite"];
}

+ (NSString *)cacheDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSAssert([paths count] > 0, @"~/Library/Caches");
    NSString *cacheDir = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Welly"];
    return cacheDir;
}

+ (void)initializeCache {
    // clean cache at startup
    NSString *cacheDir = [WLGlobalConfig cacheDirectory];
    BOOL flag = NO;
    int pid = [[NSProcessInfo processInfo] processIdentifier];
    // detect if another Welly exists
    for (NSDictionary *dict in [[NSWorkspace sharedWorkspace] launchedApplications]) {
        if ([[dict objectForKey:@"NSApplicationName"] isEqual:@"Welly"] &&
            [[dict objectForKey:@"NSApplicationProcessIdentifier"] intValue] != pid) {
            flag = YES;
            break;
        }
    }
    // no other Welly
    if (!flag)
        [[NSFileManager defaultManager] removeItemAtPath:cacheDir error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:cacheDir withIntermediateDirectories:YES attributes:nil error:NULL];
}

#pragma mark -
#pragma mark Query Global Config
+ (BOOL)shouldEnableCoverFlow {
	return [[NSUserDefaults standardUserDefaults] boolForKey:WLCoverFlowModeEnabledKeyName];
}

- (NSSize)contentSize {
	// Return the proper size of all the content
	return NSMakeSize(_column * [self cellWidth], _row * [self cellHeight]);
}
@end
