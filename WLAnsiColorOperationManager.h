//
//  WLAnsiColorOperationManager.h
//  Welly
//
//  Created by K.O.ed on 09-4-1.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class YLTerminal;
@interface WLAnsiColorOperationManager : NSObject {

}
+ (NSData *)ansiColorDataFromTerminal:(YLTerminal *)terminal 
						   atLocation:(int)location 
							   length:(int)length;
+ (NSData *)ansiColorDataFromTerminal:(YLTerminal *)terminal 
							   inRect:(NSRect)rect;
@end
