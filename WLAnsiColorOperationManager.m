//
//  WLAnsiColorOperationManager.m
//  Welly
//
//  Created by K.O.ed on 09-4-1.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "WLAnsiColorOperationManager.h"
#import "YLTerminal.h"
#import "YLConnection.h"
#import "YLSite.h"
#import "YLLGlobalConfig.h"
#import "encoding.h"

inline void clearNonANSIAttribute(cell *aCell);

void clearNonANSIAttribute(cell *aCell) {
	/* Clear non-ANSI related properties. */
	aCell->attr.f.doubleByte = 0;
	aCell->attr.f.url = 0;
	aCell->attr.f.nothing = 0;
}

unsigned short doubleByteToEncodingCode(unsigned char left, unsigned char right) {
	return (left << 8) + right - 0x8000;
}

unsigned char encodingCodeToLeftByte(unsigned short code) {
	return code >> 8;
}

unsigned char encodingCodeToRightByte(unsigned short code) {
	return code & 0xFF;
}

void convertToUTF8(cell *buffer, int bufferLength, YLEncoding encoding) {
	for (int i = 0; i < bufferLength; ++i) {
		if (buffer[i].attr.f.doubleByte == 1) {
			unsigned short code = doubleByteToEncodingCode(buffer[i].byte, buffer[i+1].byte);
			unichar ch = (encoding == YLBig5Encoding) ? B2U[code] : G2U[code];
			buffer[i].byte = encodingCodeToLeftByte(ch);
			buffer[i+1].byte = encodingCodeToRightByte(ch);
			++i;	// Skip next one
		}
	}
}

void convertFromUTF8(cell *buffer, int bufferLength, YLEncoding encoding) {
	for (int i = 0; i < bufferLength; ++i) {
		if (buffer[i].attr.f.doubleByte == 1) {
			unsigned short code = doubleByteToEncodingCode(buffer[i].byte, buffer[i+1].byte) + 0x8000;
			unichar ch = (encoding == YLBig5Encoding) ? U2B[code] : U2G[code];
			buffer[i].byte = encodingCodeToLeftByte(ch);
			buffer[i+1].byte = encodingCodeToRightByte(ch);
			++i;	// Skip next one
		}
	}
}

@implementation WLAnsiColorOperationManager
const cell WLWhiteSpaceCell = {WLWhitespaceCharacter, 0};

+ (NSData *)ansiColorDataFromTerminal:(YLTerminal *)terminal 
						   atLocation:(int)location 
							   length:(int)length {
	int maxRow = [[YLLGlobalConfig sharedInstance] row];
	int maxColumn = [[YLLGlobalConfig sharedInstance] column];
	cell *buffer = (cell *)malloc((length + maxRow + maxColumn + 1) * sizeof(cell));
    int i, j;
    int bufferLength = 0;
    int emptyCount = 0;
	
	for (i = 0; i < length; i++) {
		int index = location + i;
		cell *currentRow = [terminal cellsOfRow:(index / maxColumn)];
		
		if ((index % maxColumn == 0) && (index != location)) {
			buffer[bufferLength].byte = WLNewlineCharacter;
			buffer[bufferLength].attr = buffer[bufferLength - 1].attr;
			bufferLength++;
			emptyCount = 0;
		}
		if (!isEmptyCell(currentRow[index % maxColumn])) {
			for (j = 0; j < emptyCount; j++) {
				buffer[bufferLength] = WLWhiteSpaceCell;
				bufferLength++;
			}
			buffer[bufferLength] = currentRow[index % maxColumn];
			if (buffer[bufferLength].byte == WLNullTerminator)
				buffer[bufferLength].byte = WLWhitespaceCharacter;

			//clearNonANSIAttribute(&buffer[bufferLength]);
			bufferLength++;
			emptyCount = 0;
		} else {
			emptyCount++;
		}
	}
	
	convertToUTF8(buffer, bufferLength, [[[terminal connection] site] encoding]);
	NSData *returnValue = [NSData dataWithBytes:buffer length:bufferLength * sizeof(cell)];
	free(buffer);
	return returnValue;
}

+ (NSData *)ansiColorDataFromTerminal:(YLTerminal *)terminal 
							   inRect:(NSRect)rect {
	int maxRow = [[YLLGlobalConfig sharedInstance] row];
	int maxColumn = [[YLLGlobalConfig sharedInstance] column];
	cell *buffer = (cell *)malloc(((rect.size.height * rect.size.width) + maxRow + maxColumn + 1) * sizeof(cell));
    int j;
    int bufferLength = 0;
    int emptyCount = 0;
	for (int r = rect.origin.y; r < rect.origin.y + rect.size.height; ++r) {
		cell *currentRow = [terminal cellsOfRow:r];
		// Copy 'selectedRect.size.width' bytes from (r, selectedRect.origin.x)
		for (int c = rect.origin.x; c < rect.origin.x + rect.size.width; ++c) {
			if (!isEmptyCell(currentRow[c])) {
				for (j = 0; j < emptyCount; j++) {
					buffer[bufferLength] = WLWhiteSpaceCell;
					bufferLength++;   
				}
				buffer[bufferLength] = currentRow[c];
				if (buffer[bufferLength].byte == WLNullTerminator)
					buffer[bufferLength].byte = WLWhitespaceCharacter;
				
				//clearNonANSIAttribute(&buffer[bufferLength]);
				bufferLength++;
				emptyCount = 0;
			} else {
				emptyCount++;
			}
		}
		// Check if we should fill remaining empty count:
		if (emptyCount > 0) {
			for (int c = rect.origin.x + rect.size.width; c < maxColumn; ++c) {
				if (!isEmptyCell(currentRow[c])) {
					for (j = 0; j < emptyCount; j++) {
						buffer[bufferLength] = WLWhiteSpaceCell;
						bufferLength++;   
					}
					buffer[bufferLength] = currentRow[c];
					if (buffer[bufferLength].byte == WLNullTerminator)
						buffer[bufferLength].byte = WLWhitespaceCharacter;
					
					//clearNonANSIAttribute(&buffer[bufferLength]);
					bufferLength++;
					emptyCount = 0;
					break;
				}
			}
		}
		// add '\n'
		if (r == rect.origin.y + rect.size.height - 1)
			break;
		buffer[bufferLength].byte = WLNewlineCharacter;
		buffer[bufferLength].attr = buffer[bufferLength - 1].attr;
		bufferLength++;
		emptyCount = 0;
	}
	
	convertToUTF8(buffer, bufferLength, [[[terminal connection] site] encoding]);
	NSData *returnValue = [NSData dataWithBytes:buffer length:bufferLength * sizeof(cell)];
	free(buffer);
	return returnValue;
}

+ (NSData *)ansiCodeFromANSIColorData:(NSData *)ansiColorData 
					  forANSIColorKey:(YLANSIColorKey)ansiColorKey 
							 encoding:(YLEncoding)encoding {
	NSData *escData;
	if (ansiColorKey == YLCtrlUANSIColorKey) {
		escData = [NSData dataWithBytes:"\x15" length:1];
	} else if (ansiColorKey == YLEscEscANSIColorKey) {
		escData = [NSData dataWithBytes:"\x1B\x1B" length:2];
	} else {
		escData = [NSData dataWithBytes:"\x1B" length:1];
	}
	
	cell *buffer = (cell *)[ansiColorData bytes];
	int bufferLength = [ansiColorData length] / sizeof(cell);
	convertFromUTF8(buffer, bufferLength, encoding);
	
	attribute defaultANSI;
	unsigned int bgColorIndex = [YLLGlobalConfig sharedInstance]->_bgColorIndex;
	unsigned int fgColorIndex = [YLLGlobalConfig sharedInstance]->_fgColorIndex;
	defaultANSI.f.bgColor = bgColorIndex;
	defaultANSI.f.fgColor = fgColorIndex;
	defaultANSI.f.blink = 0;
	defaultANSI.f.bold = 0;
	defaultANSI.f.underline = 0;
	defaultANSI.f.reverse = 0;
	
	attribute previousANSI = defaultANSI;
	NSMutableData *writeBuffer = [NSMutableData data];
	
	int i;
	for (i = 0; i < bufferLength; i++) {
		if (buffer[i].byte == '\n' ) {
			previousANSI = defaultANSI;
			[writeBuffer appendData:escData];
			[writeBuffer appendBytes:"[m\r" length:3];
			continue;
		}
		
		attribute currentANSI = buffer[i].attr;
		
		char tmp[100];
		tmp[0] = '\0';
		
		/* Unchanged */
		if ((currentANSI.f.blink == previousANSI.f.blink) &&
			(currentANSI.f.bold == previousANSI.f.bold) &&
			(currentANSI.f.underline == previousANSI.f.underline) &&
			(currentANSI.f.reverse == previousANSI.f.reverse) &&
			(currentANSI.f.bgColor == previousANSI.f.bgColor) &&
			(currentANSI.f.fgColor == previousANSI.f.fgColor)) {
			[writeBuffer appendBytes: &(buffer[i].byte) length: 1];
			continue;
		}
		
		/* Clear */        
		if ((currentANSI.f.blink == 0 && previousANSI.f.blink == 1) ||
			(currentANSI.f.bold == 0 && previousANSI.f.bold == 1) ||
			(currentANSI.f.underline == 0 && previousANSI.f.underline == 1) ||
			(currentANSI.f.reverse == 0 && previousANSI.f.reverse == 1) ||
			(currentANSI.f.bgColor ==  bgColorIndex && previousANSI.f.reverse != bgColorIndex) ) {
			strcpy(tmp, "[0");
			if (currentANSI.f.blink == 1) strcat(tmp, ";5");
			if (currentANSI.f.bold == 1) strcat(tmp, ";1");
			if (currentANSI.f.underline == 1) strcat(tmp, ";4");
			if (currentANSI.f.reverse == 1) strcat(tmp, ";7");
			if (currentANSI.f.fgColor != fgColorIndex) sprintf(tmp, "%s;%d", tmp, currentANSI.f.fgColor + 30);
			if (currentANSI.f.bgColor != bgColorIndex) sprintf(tmp, "%s;%d", tmp, currentANSI.f.bgColor + 40);
			strcat(tmp, "m");
			[writeBuffer appendData:escData];
			[writeBuffer appendBytes:tmp length:strlen(tmp)];
			[writeBuffer appendBytes:&(buffer[i].byte) length:1];
			previousANSI = currentANSI;
			continue;
		}
		
		/* Add attribute */
		strcpy(tmp, "[");
		if (currentANSI.f.blink == 1 && previousANSI.f.blink == 0) 
			strcat(tmp, "5;");
		if (currentANSI.f.bold == 1 && previousANSI.f.bold == 0) 
			strcat(tmp, "1;");
		if (currentANSI.f.underline == 1 && previousANSI.f.underline == 0) 
			strcat(tmp, "4;");
		if (currentANSI.f.reverse == 1 && previousANSI.f.reverse == 0) 
			strcat(tmp, "7;");
		if (currentANSI.f.fgColor != previousANSI.f.fgColor) 
			sprintf(tmp, "%s%d;", tmp, currentANSI.f.fgColor + 30);
		if (currentANSI.f.bgColor != previousANSI.f.bgColor) 
			sprintf(tmp, "%s%d;", tmp, currentANSI.f.bgColor + 40);
		tmp[strlen(tmp) - 1] = 'm';
		sprintf(tmp, "%s%c", tmp, buffer[i].byte);
		[writeBuffer appendData:escData];
		[writeBuffer appendBytes:tmp length:strlen(tmp)];
		previousANSI = currentANSI;
		continue;
	}
	[writeBuffer appendData:escData];
	[writeBuffer appendBytes:"[m" length:2];
	
	return writeBuffer;
}

static NSColor* colorUsingNearestAnsiColor(NSColor *rawColor, BOOL isBackground) {
    if (!rawColor)
        return nil;
    YLLGlobalConfig *config = [YLLGlobalConfig sharedInstance];
    if ([rawColor isEqual:[config colorBG]] ||
        [rawColor isEqual:[config colorBlack]] ||
        [rawColor isEqual:[config colorRed]] ||
        [rawColor isEqual:[config colorGreen]] ||
        [rawColor isEqual:[config colorYellow]] ||
        [rawColor isEqual:[config colorBlue]] ||
        [rawColor isEqual:[config colorMagenta]] ||
        [rawColor isEqual:[config colorCyan]] ||
        [rawColor isEqual:[config colorWhite]] ||
        [rawColor isEqual:[config colorBGHilite]] ||
        [rawColor isEqual:[config colorBlackHilite]] ||
        [rawColor isEqual:[config colorRedHilite]] ||
        [rawColor isEqual:[config colorGreenHilite]] ||
        [rawColor isEqual:[config colorYellowHilite]] ||
        [rawColor isEqual:[config colorBlueHilite]] ||
        [rawColor isEqual:[config colorMagentaHilite]] ||
        [rawColor isEqual:[config colorCyanHilite]] ||
        [rawColor isEqual:[config colorWhiteHilite]])
        return rawColor;
    CGFloat h, s, b;
    [[rawColor colorUsingColorSpaceName:@"NSCalibratedRGBColorSpace"] getHue:&h saturation:&s brightness:&b alpha:nil];
    if (s < 0.05) {
        if (isBackground)
            return [config colorBG];
        if (!isBackground && b < 0.05)
            return [config colorWhite];
        switch ((int)(b * 4)) {
            case 0:
                return [config colorBlack];
            case 1:
                return [config colorBlackHilite];
            case 2:
                return [config colorWhite];
            default:
                return [config colorWhiteHilite];
        }
    }
    if (b < 0.05)
        return [config colorBlack];
    switch ((int)((h + 1.0/6/2) * 6)) {
        case 0:
        case 6:
            return (b < 0.5) ? [config colorRed] : [config colorRedHilite];
        case 1:
            return (b < 0.5) ? [config colorYellow] : [config colorYellowHilite];
        case 2:
            return (b < 0.5) ? [config colorGreen] : [config colorGreenHilite];
        case 3:
            return (b < 0.5) ? [config colorCyan] : [config colorCyanHilite];
        case 4:
            return (b < 0.5) ? [config colorBlue] : [config colorBlueHilite];
        case 5:
            return (b < 0.5) ? [config colorMagenta] : [config colorMagentaHilite];
        default:
            return [config colorWhite];
    }
}

+ (NSString *)ansiCodeStringFromAttributedString:(NSAttributedString *)storage
								 forANSIColorKey:(YLANSIColorKey)ansiColorKey {
	NSString *escString;
    if (ansiColorKey == YLCtrlUANSIColorKey) {
        escString = @"\x15";
    } else if (ansiColorKey == YLEscEscANSIColorKey) {
        escString = @"\x1B\x1B";
    } else {
        escString = @"\x1B";
    }
    
    //NSFontManager *fontManager = [NSFontManager sharedFontManager];
    NSMutableString *writeBuffer = [NSMutableString string];
    NSString *rawString = [storage string];
    BOOL underline, preUnderline = NO;
    BOOL blink, preBlink = NO;
    YLLGlobalConfig *config = [YLLGlobalConfig sharedInstance];
    NSColor *color, *preColor = [config colorWhite];
    NSColor *bgColor, *preBgColor = nil;
    BOOL hasColor = NO;
    
    for (int i = 0; i < [storage length]; ++i) {
        char tmp[100] = "";
        // get attributes of i-th character
        
        underline = ([[storage attribute:NSUnderlineStyleAttributeName atIndex:i effectiveRange:nil] intValue] != NSUnderlineStyleNone);
        //blink = [fontManager traitsOfFont:[storage attribute:NSFontAttributeName atIndex:i effectiveRange:nil]] & NSBoldFontMask;
		blink = ([storage attribute:NSShadowAttributeName atIndex:i effectiveRange:nil] != nil);
        color = colorUsingNearestAnsiColor([storage attribute:NSForegroundColorAttributeName atIndex:i effectiveRange:nil], NO);
        bgColor = colorUsingNearestAnsiColor([storage attribute:NSBackgroundColorAttributeName atIndex:i effectiveRange:nil], YES);
        
        /* Add attributes */
        if ((underline != preUnderline) || 
            (blink != preBlink) ||
            (color != preColor) ||
            (bgColor && ![bgColor isEqual:preBgColor]) || (!bgColor && preBgColor)) {
            // pre-calculate background color
            char bgColorCode[4] = "";
            if (!bgColor || [bgColor isEqual:[config colorBG]] || [bgColor isEqual:[config colorBGHilite]])
			/* do nothing */;
            else if ([bgColor isEqual:[config colorBlack]] || [bgColor isEqual:[config colorBlackHilite]])
                strcpy(bgColorCode, ";40");
            else if ([bgColor isEqual:[config colorRed]] || [bgColor isEqual:[config colorRedHilite]])
                strcpy(bgColorCode, ";41");
            else if ([bgColor isEqual:[config colorGreen]] || [bgColor isEqual:[config colorGreenHilite]])
                strcpy(bgColorCode, ";42");
            else if ([bgColor isEqual:[config colorYellow]] || [bgColor isEqual:[config colorYellowHilite]])
                strcpy(bgColorCode, ";43");
            else if ([bgColor isEqual:[config colorBlue]] || [bgColor isEqual:[config colorBlueHilite]])
                strcpy(bgColorCode, ";44");
            else if ([bgColor isEqual:[config colorMagenta]] || [bgColor isEqual:[config colorMagentaHilite]])
                strcpy(bgColorCode, ";45");
            else if ([bgColor isEqual:[config colorCyan]] || [bgColor isEqual:[config colorCyanHilite]])
                strcpy(bgColorCode, ";46");
            else if ([bgColor isEqual:[config colorWhite]] || [bgColor isEqual:[config colorWhiteHilite]])
                strcpy(bgColorCode, ";47");
            // merge foreground color, underline, blink and background color
            if (color == [config colorBlack])
                sprintf(tmp, "[0;%s%s30%sm", underline ? "4;" : "", blink ? "5;" : "", bgColorCode);
            else if (color == [config colorRed])
                sprintf(tmp, "[0;%s%s31%sm", underline ? "4;" : "", blink ? "5;" : "", bgColorCode);
            else if (color == [config colorGreen])
                sprintf(tmp, "[0;%s%s32%sm", underline ? "4;" : "", blink ? "5;" : "", bgColorCode);
            else if (color == [config colorYellow])
                sprintf(tmp, "[0;%s%s33%sm", underline ? "4;" : "", blink ? "5;" : "", bgColorCode);
            else if (color == [config colorBlue])
                sprintf(tmp, "[0;%s%s34%sm", underline ? "4;" : "", blink ? "5;" : "", bgColorCode);
            else if (color == [config colorMagenta])
                sprintf(tmp, "[0;%s%s35%sm", underline ? "4;" : "", blink ? "5;" : "", bgColorCode);
            else if (color == [config colorCyan])
                sprintf(tmp, "[0;%s%s36%sm", underline ? "4;" : "", blink ? "5;" : "", bgColorCode);
            else if (color == [config colorWhite])
                sprintf(tmp, "[0;%s%s37%sm", underline ? "4;" : "", blink ? "5;" : "", bgColorCode);
            else if (color == [config colorBlackHilite])
                sprintf(tmp, "[0;1;%s%s30%sm", underline ? "4;" : "", blink ? "5;" : "", bgColorCode);
            else if (color == [config colorRedHilite])
                sprintf(tmp, "[0;1;%s%s31%sm", underline ? "4;" : "", blink ? "5;" : "", bgColorCode);
            else if (color == [config colorGreenHilite])
                sprintf(tmp, "[0;1;%s%s32%sm", underline ? "4;" : "", blink ? "5;" : "", bgColorCode);
            else if (color == [config colorYellowHilite])
                sprintf(tmp, "[0;1;%s%s33%sm", underline ? "4;" : "", blink ? "5;" : "", bgColorCode);
            else if (color == [config colorBlueHilite])
                sprintf(tmp, "[0;1;%s%s34%sm", underline ? "4;" : "", blink ? "5;" : "", bgColorCode);
            else if (color == [config colorMagentaHilite])
                sprintf(tmp, "[0;1;%s%s35%sm", underline ? "4;" : "", blink ? "5;" : "", bgColorCode);
            else if (color == [config colorCyanHilite])
                sprintf(tmp, "[0;1;%s%s36%sm", underline ? "4;" : "", blink ? "5;" : "", bgColorCode);
            else if (color == [config colorWhiteHilite])
                sprintf(tmp, "[0;1;%s%s37%sm", underline ? "4;" : "", blink ? "5;" : "", bgColorCode);
            else
                sprintf(tmp, "[%s%s%s%sm", (underline || blink || *bgColorCode) ? "0" : "", underline ? ";4" : "", blink ? ";5" : "", bgColorCode);
            [writeBuffer appendString:escString];
            [writeBuffer appendString:[NSString stringWithCString:tmp]];
            preUnderline = underline;
            preBlink = blink;
            preColor = color;
            preBgColor = bgColor;
            hasColor = YES;
        }
        
        // get i-th character
        unichar ch = [rawString characterAtIndex:i];
        
        // write to the buffer
        [writeBuffer appendString:[NSString stringWithCharacters:&ch length:1]];
    }
    
    if (hasColor) {
        [writeBuffer appendString:escString];
        [writeBuffer appendString:@"[m"];
    }
	
	return writeBuffer;
}
@end