//
//  XIPortal.h
//  Welly
//
//  Created by boost @ 9# on 7/16/08.
//  Copyright 2008 Xi Wang. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@interface XIPortal : NSObject {
    CAScrollLayer *_bodyLayer;
    CATextLayer *_headerTextLayer, *_footerTextLayer;
    CATransform3D _sublayerTransform;
    CGImageRef _shadowImage;

    CGSize _imageSize;
    NSMutableArray *_images;
    int _totalImages, _selectedImageIndex;

    NSMapTable *_layerDictionary;
}

+ (CGColorRef)color:(int)name;
- initWithView:(NSView *)view;
- (void)loadCovers;
- (NSUInteger)selected;
- (void)moveSelection:(int)dx;
- (void)select;
- (void)clickAtPoint:(NSPoint)aPoint count:(NSUInteger)count;

@end
