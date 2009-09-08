//
//  WLPortalImage.m
//  Welly
//
//  Created by boost on 9/6/2009.
//  Copyright 2009 Xi Wang. All rights reserved.
//

#import <Quartz/Quartz.h>
#import "WLPortalImage.h"

static NSImage *default_image;

@implementation WLPortalImage

@synthesize path = _path;
@synthesize image = _image;

- (id)initWithPath:(NSString *)path title:(NSString *)title {
    if (self != [super init])
        return nil;
    [self setPath:path];
    _title = [title copy];
    return self;
}

- (void)dealloc {
    [_image release];
    [_title release];
    [_path release];
    [super dealloc];
}

- (void)setPath:(NSString *)path {
    [_path release];
    [_image release];
    _path = [path copy];
    if (_path)
        _image = [[NSImage alloc] initByReferencingFile:_path];
    else
        _image = nil;
}

- (NSString *)imageUID {
    return _title;
}

- (NSString *)imageRepresentationType {
    return IKImageBrowserNSImageRepresentationType;
}

- (id)imageRepresentation {
    if (_image == nil) {
        if (default_image == nil)
            default_image = [NSImage imageNamed:@"default_site.png"];
        return default_image;
    }
    return _image;
}

- (NSString*)imageTitle {
    return _title;
}

@end
