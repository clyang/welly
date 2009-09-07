//
//  WLPortalImage.h
//  Welly
//
//  Created by boost on 9/6/2009.
//  Copyright 2009 Xi Wang. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface WLPortalImage : NSObject {
    NSString * _title;
    NSImage  * _image;
}

- (id)initWithImage:(NSImage *)image title:(NSString *)title;

#pragma mark -
#pragma mark IKImageBrowserItem protocol
- (NSString *)imageUID;
- (NSString *)imageRepresentationType;
- (id)imageRepresentation;
- (NSString*)imageTitle;

@end
