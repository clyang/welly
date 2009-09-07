//
//  WLPortalImage.m
//  Welly
//
//  Created by boost on 9/6/2009.
//  Copyright 2009 Xi Wang. All rights reserved.
//

#import <Quartz/Quartz.h>
#import "WLPortalImage.h"

const float imageWidth = 100, imageHeight = 100;

@implementation WLPortalImage

- (id)initWithImage:(NSImage *)image title:(NSString *)title {
    self = [super init];
    if (self == nil)
        return nil;
    _image = [image retain];
    _title = [title copy];
    return self;
}

- (void)dealloc {
    [_title release];
    [_image release];
    [super dealloc];
}

- (NSString *)imageUID {
    return _title;
}

- (NSString *)imageRepresentationType {
    return IKImageBrowserNSImageRepresentationType;
}

- (id)imageRepresentation {
    return _image;
}

- (NSString*)imageTitle {
    return _title;
}

@end
