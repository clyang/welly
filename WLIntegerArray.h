//
//  XIIntegerArray.h
//  Welly
//
//  Created by boost @ 9# on 7/28/08.
//  Copyright 2008 Xi Wang. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// simulate std::deque for legacy code
@interface WLIntegerArray : NSObject {
    NSPointerArray *_array;
}

+ integerArray;

- (void)push_back:(NSInteger)integer;
- (void)pop_front;
- (NSInteger)at:(NSUInteger)index;
- (void)set:(NSInteger)value at:(NSUInteger)index;
- (NSInteger)front;
- (BOOL)empty;
- (NSUInteger)size;
- (void)clear;

@end
