//
//  WLAsciiArtRender.h
//  Welly
//
//  Created by K.O.ed on 10-6-25.
//  Copyright 2010 Welly Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CommonType.h"

@interface WLAsciiArtRender : NSObject {
	CGFloat _fontWidth;
	CGFloat _fontHeight;
	
	int _maxRow;
	int _maxColumn;
}

+ (BOOL)isAsciiArtSymbol:(unichar)ch;
- (void)drawSpecialSymbol:(unichar)ch 
				   forRow:(int)r 
				   column:(int)c 
			leftAttribute:(attribute)attr1 
		   rightAttribute:(attribute)attr2;
- (void)configure;

@end
