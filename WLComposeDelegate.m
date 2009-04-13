//
//  TYComposeDelegate.m
//  Welly
//
//  Created by aqua9 on 17/1/2009.
//  Copyright 2009 TANG Yang. All rights reserved.
//

#import "WLComposeDelegate.h"
#import "WLAnsiColorOperationManager.h"
#import "YLLGlobalConfig.h"
#import "YLView.h"
#import "YLTerminal.h"
#import "YLSite.h"

@implementation WLComposeDelegate
NSString *const WLComposeFontName = @"Helvetica";

- (void)awakeFromNib {
	[_composeText setString:@""];
	[_composeText setBackgroundColor:[NSColor whiteColor]];
    [_composeText setTextColor:[NSColor blackColor]];
    [_composeText setInsertionPointColor:[NSColor blackColor]];
    [_composeText setFont:[NSFont fontWithName:WLComposeFontName size:[[YLLGlobalConfig sharedInstance] englishFontSize]*0.8]];
	
	// Prepare Color Panel
	[[NSUserDefaults standardUserDefaults] setObject:@"1Welly" forKey:@"NSColorPickerPageableNameListDefaults"];
    YLLGlobalConfig *config = [YLLGlobalConfig sharedInstance];
    NSColorPanel *colorPanel = [NSColorPanel sharedColorPanel];
    [colorPanel setMode:NSColorListModeColorPanel];
    NSColorList *colorList = [[NSColorList alloc] initWithName:@"Welly"];
    [colorList insertColor:[config colorBlack] key:NSLocalizedString(@"Black", @"Color") atIndex:0];
    [colorList insertColor:[config colorRed] key:NSLocalizedString(@"Red", @"Color") atIndex:1];
    [colorList insertColor:[config colorGreen] key:NSLocalizedString(@"Green", @"Color") atIndex:2];
    [colorList insertColor:[config colorYellow] key:NSLocalizedString(@"Yellow", @"Color") atIndex:3];
    [colorList insertColor:[config colorBlue] key:NSLocalizedString(@"Blue", @"Color") atIndex:4];
    [colorList insertColor:[config colorMagenta] key:NSLocalizedString(@"Magenta", @"Color") atIndex:5];
    [colorList insertColor:[config colorCyan] key:NSLocalizedString(@"Cyan", @"Color") atIndex:6];
    [colorList insertColor:[config colorWhite] key:NSLocalizedString(@"White", @"Color") atIndex:7];
    [colorList insertColor:[config colorBlackHilite] key:NSLocalizedString(@"BlackHilite", @"Color") atIndex:8];
    [colorList insertColor:[config colorRedHilite] key:NSLocalizedString(@"RedHilite", @"Color") atIndex:9];
    [colorList insertColor:[config colorGreenHilite] key:NSLocalizedString(@"GreenHilite", @"Color") atIndex:10];
    [colorList insertColor:[config colorYellowHilite] key:NSLocalizedString(@"YellowHilite", @"Color") atIndex:11];
    [colorList insertColor:[config colorBlueHilite] key:NSLocalizedString(@"BlueHilite", @"Color") atIndex:12];
    [colorList insertColor:[config colorMagentaHilite] key:NSLocalizedString(@"MagentaHilite", @"Color") atIndex:13];
    [colorList insertColor:[config colorCyanHilite] key:NSLocalizedString(@"CyanHilite", @"Color") atIndex:14];
    [colorList insertColor:[config colorWhiteHilite] key:NSLocalizedString(@"WhiteHilite", @"Color") atIndex:15];
    [colorPanel attachColorList:colorList];
    [colorList release];
	
	_shadowForBlink = [[NSShadow alloc] init];
	[_shadowForBlink setShadowOffset:NSMakeSize(3.0, -3.0)];
	[_shadowForBlink setShadowBlurRadius:5.0];
	
	// Use a partially transparent color for shapes that overlap.
	[_shadowForBlink setShadowColor:[[NSColor blackColor] colorWithAlphaComponent:0.8]];
}

#pragma mark -
#pragma mark Compose
// TODO: Move all these code into independent controller class
/* compose actions */
- (void)clearAll {
    [_composeText setString:@"\n"];
    [[_composeText textStorage] removeAttribute:NSBackgroundColorAttributeName
                                          range:NSMakeRange(0, 1)];
    [_composeText setSelectedRange:NSMakeRange(0, 0)];
    [_composeText setString:@""];
	[_composeText setBackgroundColor:[NSColor whiteColor]];
    [_composeText setTextColor:[NSColor blackColor]];
	[_composeText setFont:[NSFont fontWithName:WLComposeFontName size:[[YLLGlobalConfig sharedInstance] englishFontSize]*0.8]];
	// TODO: reset the background color
}

- (IBAction)commitCompose:(id)sender {
    YLSite *s = [[_telnetView frontMostConnection] site];
	
	NSString *ansiCode = [WLAnsiColorOperationManager ansiCodeStringFromAttributedString:[_composeText textStorage] 
																		 forANSIColorKey:[s ansiColorKey]];
	
	[[_telnetView frontMostConnection] sendText:ansiCode];
    [self clearAll];
    [_composeWindow endEditingFor:nil];
    [NSApp endSheet:_composeWindow];
    [_composeWindow orderOut:self];
}

- (IBAction)cancelCompose:(id)sender {
	[self clearAll];
    [_composeWindow endEditingFor:nil];
    [NSApp endSheet:_composeWindow];
    [_composeWindow orderOut:self];
}

- (IBAction)setUnderline:(id)sender {
	NSTextStorage *storage = [_composeText textStorage];
	NSRange selectedRange = [_composeText selectedRange];
	// get the underline style attribute of the first character in the text view
	id underlineStyle = [storage attribute:NSUnderlineStyleAttributeName atIndex:selectedRange.location effectiveRange:nil];
	// if already underlined, then the user is meant to remove the line.
	if ([underlineStyle intValue] == NSUnderlineStyleNone) {
		[storage addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleThick] range:selectedRange];
	}
	else
		[storage removeAttribute:NSUnderlineStyleAttributeName range:selectedRange];
}

- (IBAction)setBlink:(id)sender {
	NSTextStorage *storage = [_composeText textStorage];
	NSRange selectedRange = [_composeText selectedRange];
	
	NSShadow *shadowAttribute = [storage attribute:NSShadowAttributeName atIndex:selectedRange.location effectiveRange:nil];
	
	if (shadowAttribute == nil) {
		[storage addAttribute:NSShadowAttributeName value:_shadowForBlink range:selectedRange];
	} else {
		[storage removeAttribute:NSShadowAttributeName range:selectedRange];
	}
	
	// get the bold style attribute of the first character in the text view
	/* Commented by K.O.ed: Do not use bold, but use shadow
	NSFontManager *fontManager = [NSFontManager sharedFontManager];
	NSFont *font = [storage attribute:NSFontAttributeName atIndex:selectedRange.location effectiveRange:nil];
	NSFontTraitMask traits = [fontManager traitsOfFont:font];
	NSFont *newFont;
	if (traits & NSBoldFontMask)
		newFont = [fontManager convertFont:font toNotHaveTrait:NSBoldFontMask];
	else
		newFont = [fontManager convertFont:font toHaveTrait:NSBoldFontMask];
	
	[storage addAttribute:NSFontAttributeName value:newFont range:[_composeText selectedRange]];
	 */
}

- (IBAction)changeBackgroundColor:(id)sender {
    [[_composeText textStorage] addAttribute:NSBackgroundColorAttributeName
                                       value:[sender color]
                                       range:[_composeText selectedRange]];
}

#pragma mark -
#pragma mark Delegate Method
- (void)textViewDidChangeSelection:(NSNotification *)aNotification {
    NSTextView *textView = [aNotification object];
    NSTextStorage *storage = [textView textStorage];
    int location = [textView selectedRange].location;
    if (location > 0) 
		--location;
    [_bgColorWell setColor:[[YLLGlobalConfig sharedInstance] colorBG]];
    if (location < [storage length]) {
        NSColor *bgColor = [storage attribute:NSBackgroundColorAttributeName
                                      atIndex:location
                               effectiveRange:nil];
        if (bgColor) {
            [_bgColorWell setColor:bgColor];
        }
    }
}
@end
