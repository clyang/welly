//
//  WLPortalImage.h
//  Welly
//
//  Created by boost on 9/6/2009.
//  Copyright 2009 Xi Wang. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface WLPortalImage : NSObject {
    NSString *_path, *_title;
    NSImage  *_image;
}

@property (readonly) NSString *path;
@property (readonly) NSImage *image;

- (id)initWithPath:(NSString *)path title:(NSString *)title;
- (void)setPath:(NSString *)path;

#pragma mark -
#pragma mark IKImageBrowserItem protocol
- (NSString *)imageUID;
- (NSString *)imageRepresentationType;
- (id)imageRepresentation;
- (NSString*)imageTitle;

@end
