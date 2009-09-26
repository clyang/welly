//
//  WLAnsiColorOperationManager.h
//  Welly
//
//  Created by K.O.ed on 09-4-1.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CommonType.h"

@class WLTerminal;
@interface WLAnsiColorOperationManager : NSObject {

}
+ (NSData *)ansiColorDataFromTerminal:(WLTerminal *)terminal 
						   atLocation:(int)location 
							   length:(int)length;
+ (NSData *)ansiColorDataFromTerminal:(WLTerminal *)terminal 
							   inRect:(NSRect)rect;
+ (NSData *)ansiCodeFromANSIColorData:(NSData *)ansiColorData 
					  forANSIColorKey:(YLANSIColorKey)ansiColorKey 
							 encoding:(YLEncoding)encoding;
+ (NSString *)ansiCodeStringFromAttributedString:(NSAttributedString *)storage
								 forANSIColorKey:(YLANSIColorKey)ansiColorKey;
@end
