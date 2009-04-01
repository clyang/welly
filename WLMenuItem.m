//
//  WLMenuItem.m
//  Welly
//
//  Created by K.O.ed on 08-12-8.
//  Copyright 2008 Welly Group. All rights reserved.
//

#import "WLMenuItem.h"


@implementation WLMenuItem
@synthesize name = _name;

+ (WLMenuItem *)initWithName:(NSString *)name {
	WLMenuItem *item = [[WLMenuItem alloc] init];
	item->_name = name;
	return item;
}
@end
