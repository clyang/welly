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
@end