//
//  KOMenuItem.m
//  Welly
//
//  Created by K.O.ed on 08-12-8.
//  Copyright 2008 Welly Group. All rights reserved.
//

#import "KOMenuItem.h"


@implementation KOMenuItem
@synthesize name = _name;

+ (KOMenuItem *)initWithName:(NSString *)name {
	KOMenuItem *item = [[KOMenuItem alloc] init];
	item->_name = name;
	return item;
}
@end
