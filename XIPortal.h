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
    CATextLayer *_headerTextLayer, *_desktopImageCountLayer;
    CATransform3D _sublayerTransform;
    CGImageRef _shadowImage;

    CGSize _desktopImageSize;
    NSMutableArray *_desktopImages;
    int _totalDesktopImages, _selectedDesktopImageIndex;

    NSMapTable *_layerDictionary;
}

+ (CGColorRef)color:(int)name;
- initWithView:(NSView *)view;
- (void)loadCovers;
- (void)moveSelection:(int)dx;
- (void)select;

@end
