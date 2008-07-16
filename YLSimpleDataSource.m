//
//  YLSimpleDataSource.m
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 9/1/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import "YLSimpleDataSource.h"
#import "YLLGlobalConfig.h"

static char *templateString = "我達達的馬蹄是美麗的錯誤。我不是歸人，是個澳客。";

@implementation YLSimpleDataSource
- (int) row {
	return 24;
}
- (int) column {
	return 80;
}

- (NSColor *) fgColorAtRow: (int) r column: (int) c {
	return [[YLLGlobalConfig sharedInstance] colorAtIndex: [self fgColorIndexAtRow: r column: c] hilite: NO];}

- (NSColor *) bgColorAtRow: (int) r column: (int) c {
	return [[YLLGlobalConfig sharedInstance] colorAtIndex: [self bgColorIndexAtRow: r column: c] hilite: NO];
}

- (int) fgColorIndexAtRow: (int) r column: (int) c {
	if (r == 5) {
		if (c == 2 || c== 3) 
			return 3;
	}
	
	if (r == 3) {
		if (c == 2 || c== 4 || c == 7 || c == 10) 
			return 4;
		if (c == 3)
			return 6;
	}
	return 7;
}

- (int) bgColorIndexAtRow: (int) r column: (int) c {
	if (r == 6) {
		if (c >= 2 && c <= 10) 
			return 1;
	}
	return 9;
}

- (BOOL) isDirtyAtRow: (int) r column:(int) c {
	return YES;
}

- (unichar) charAtRow: (int) r column: (int) c {
	NSString *s = [NSString stringWithUTF8String: templateString];
	if (c/2 >= [s length]) return 0;
	
	if (c & 1) return 0;
	return [s characterAtIndex: (c / 2)];
}

- (int) isDoubleByteAtRow: (int) r column:(int) c {
	NSString *s = [NSString stringWithUTF8String: templateString];
	if (c/2 >= [s length]) return 0;
	if (c & 1) return 2;
	return 1;
}

@end
