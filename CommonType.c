/*
 *  CommonType.c
 *  MacBlueTelnet
 *
 *  Created by Lan Yung-Luen on 12/7/07.
 *  Copyright 2007 yllan.org. All rights reserved.
 *
 */

#import "CommonType.h"

int isHiddenAttribute(attribute a) {
    return (!a.f.bold && ((a.f.fgColor == a.f.bgColor) ||
                          (a.f.fgColor == 0 && a.f.bgColor == 9))); 
}

int isBlinkCell(cell c) {
    if (c.attr.f.blink && (c.attr.f.doubleByte != 0 || (c.byte != ' ' && c.byte != '\0')))
        return 1;
    return 0;
}

int bgColorIndexOfAttribute(attribute a) {
    return (a.f.reverse ? a.f.fgColor : a.f.bgColor);
}

int fgColorIndexOfAttribute(attribute a) {
    return (a.f.reverse ? a.f.bgColor : a.f.fgColor);
}

int bgBoldOfAttribute(attribute a) {
    return (a.f.reverse && a.f.bold);
}

int fgBoldOfAttribute(attribute a) {
    return (!a.f.reverse && a.f.bold);
}