/*
 *  YLDataSourceProtocol.h
 *  MacBlueTelnet
 *
 *  Created by Yung-Luen Lan on 9/1/07.
 *  Copyright 2007 yllan.org. All rights reserved.
 *
 */



@interface NSObject (YLDataSourceProtocol) 
- (int) row;
- (int) column;
- (BOOL) isDirtyAtRow: (int) r column:(int) c;
- (NSColor *) fgColorAtRow: (int) r column: (int) c;
- (NSColor *) bgColorAtRow: (int) r column: (int) c;
- (int) fgColorIndexAtRow: (int) r column: (int) c ;
- (int) bgColorIndexAtRow: (int) r column: (int) c ;
- (unichar) charAtRow: (int) r column: (int) c;
- (int) isDoubleByteAtRow: (int) r column:(int) c;
@end