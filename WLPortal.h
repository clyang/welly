//
//  WLPortal.h
//  Welly
//
//  Created by boost on 9/6/09.
//  Copyright 2009 Xi Wang. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface WLPortal : NSObject {
    NSMutableArray * _data;
    id _view;
}

@property (readonly) NSView *view;

- (void)show;
- (void)hide;

- (void)keyDown:(NSEvent *)theEvent;
- (void)mouseUp:(NSEvent *)theEvent;

@end
