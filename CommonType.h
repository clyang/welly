/*
 *  CommonType.h
 *  MacBlueTelnet
 *
 *  Created by Yung-Luen Lan on 9/11/07.
 *  Copyright 2007 yllan.org. All rights reserved.
 *
 */

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
    YLEscEscEscANSIColorKey = 0
} YLANSIColorKey;

typedef enum {
	TYFirebird, TYMaple, TYUnix
} TYBBSType;

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