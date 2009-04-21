/*
 *  CommonType.c
 *  MacBlueTelnet
 *
 *  Created by Lan Yung-Luen on 12/7/07.
 *  Copyright 2007 yllan.org. All rights reserved.
 *
 */

#import "CommonType.h"

#pragma mark -
#pragma mark Constants


#pragma mark -
#pragma mark Functions
inline int isHiddenAttribute(attribute a) {
    return (!a.f.bold && ((a.f.fgColor == a.f.bgColor) ||
                          (a.f.fgColor == 0 && a.f.bgColor == 9))); 
}

inline int isBlinkCell(cell c) {
    if (c.attr.f.blink && (c.attr.f.doubleByte != 0 || (c.byte != ' ' && c.byte != '\0')))
        return 1;
    return 0;
}

inline BOOL isLetter(unsigned char c) { 
	return (c >= 'a' && c <= 'z') || (c >= 'A' && c<= 'Z'); 
}

inline BOOL isNumber(unsigned char c) {
	return (c >= '0' && c <= '9'); 
}

inline int bgColorIndexOfAttribute(attribute a) {
    return (a.f.reverse ? a.f.fgColor : a.f.bgColor);
}

inline int fgColorIndexOfAttribute(attribute a) {
    return (a.f.reverse ? a.f.bgColor : a.f.fgColor);
}

inline int bgBoldOfAttribute(attribute a) {
    return (a.f.reverse && a.f.bold);
}

inline int fgBoldOfAttribute(attribute a) {
    return (!a.f.reverse && a.f.bold);
}

inline BOOL isEmptyCell(cell aCell) {
	if (aCell.byte != WLNullTerminator)
		return NO;
	if (aCell.attr.f.bgColor != 9)
		return NO;
	if (aCell.attr.f.underline != 0)
		return NO;
	if (aCell.attr.f.reverse != 0)
		return NO;
	return YES;
}

inline BOOL shouldBeDirty(cell prevCell, cell newCell) {
	return (prevCell.byte != newCell.byte) || (prevCell.attr.v != newCell.attr.v);
}