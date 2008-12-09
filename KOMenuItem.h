//
//  KOMenuItem.h
//  Welly
//
//  Created by K.O.ed on 08-12-8.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface KOMenuItem : NSObject {
	NSString *_name;	
}

+ (KOMenuItem *) itemWithName: (NSString *) name;

- (NSString *) name;

@end
