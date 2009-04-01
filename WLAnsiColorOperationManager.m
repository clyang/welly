//
//  WLAnsiColorOperationManager.m
//  Welly
//
//  Created by K.O.ed on 09-4-1.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "WLAnsiColorOperationManager.h"
#import "YLTerminal.h"
#import "YLLGlobalConfig.h"

@implementation WLAnsiColorOperationManager
inline void clearNonANSIAttribute(cell *aCell) {
	/* Clear non-ANSI related properties. */
	aCell->attr.f.doubleByte = 0;
	aCell->attr.f.url = 0;
	aCell->attr.f.nothing = 0;
}

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

			clearNonANSIAttribute(&buffer[bufferLength]);
			bufferLength++;
			emptyCount = 0;
		} else {
			emptyCount++;
		}
	}
	
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
				
				clearNonANSIAttribute(&buffer[bufferLength]);
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
					
					clearNonANSIAttribute(&buffer[bufferLength]);
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
	
	NSData *returnValue = [NSData dataWithBytes:buffer length:bufferLength * sizeof(cell)];
	free(buffer);
	return returnValue;
}

+ (NSData *)ansiCodeFromANSIColorData:(NSData *)ansiColorData 
					  forANSIColorKey:(YLANSIColorKey)ansiColorKey {
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
@end