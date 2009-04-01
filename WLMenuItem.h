//
//  WLMenuItem.h
//  Welly
//
//  Created by K.O.ed on 08-12-8.
//  Copyright 2008 Welly Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface WLMenuItem : NSObject {
	NSString *_name;	
}
@property (readonly) NSString *name;

+ (WLMenuItem *)initWithName:(NSString *)name;
@end
