//
//  LLUrlData.h
//  Welly
//
//  Created by gtCarrera on 08-12-25.
//  Copyright 2008 9＃. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface LLUrlData : NSObject {
	NSString * _currUrl;
	NSString * _name;
	NSPoint pos;
}

// Constructor
- (id) initWithUrl:(NSString *)url 
			  name:(NSString *)name 
		  position:(NSPoint)position;

- (id) init;

// Accessor
- (NSString *)url;
- (NSString *)name;
- (NSPoint)pos;
- (void)setName:(NSString *)name;

@end
