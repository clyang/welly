//
//  KOMenuItem.m
//  Welly
//
//  Created by K.O.ed on 08-12-8.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "KOMenuItem.h"


@implementation KOMenuItem

+ (KOMenuItem *) initWithName: (NSString *) name {
	KOMenuItem *item = [[KOMenuItem alloc] init];
	item->_name = name;
	return item;
}

- (NSString *) name {
	return _name;
}

@end
