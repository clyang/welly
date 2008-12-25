//
//  LLUrlData.m
//  Welly
//
//  Created by gtCarrera on 08-12-25.
//  Copyright 2008 9＃. All rights reserved.
//

#import "LLUrlData.h"


@implementation LLUrlData

#pragma mark Init and dealloc
- (id) init {
	if(self = [super init]) {
		_currUrl = [[NSString alloc] initWithString:@""];
		_name = [[NSString alloc] initWithString:@"No Name"];
	}
	return self;
}

- (id) initWithUrl: (NSString *) url 
			  name: (NSString *) name 
		  position: (NSPoint) position {
	if(self = [super init]) {
		_currUrl = [[NSString alloc] initWithString:url];
		_name = [[NSString alloc] initWithString:name];
		pos = position;
	}
	return self;
}

- (void) dealloc {
	[_currUrl release];
	[_name release];
	[super dealloc];
}

#pragma mark -
#pragma mark Accessors
- (NSString *) url {
	return _currUrl;
}

- (NSString *) name {
	return _name;
}

- (NSPoint) pos {
	return pos;
}

- (void) setName: (NSString *) name {
	[_name release];
	_name = [name retain];
}

@end
