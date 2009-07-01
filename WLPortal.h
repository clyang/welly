//
//  XIPortal.h
//  Welly
//
//  Created by boost @ 9# on 7/16/08.
//  Copyright 2008 Xi Wang. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "YLView.h"

@class YLSite;

@interface WLPortal : NSView {
    CAScrollLayer *_bodyLayer;
    CATextLayer *_headerTextLayer, *_footerTextLayer;
    CATransform3D _sublayerTransform;
    CGImageRef _shadowImage;

    CGSize _imageSize;
    NSMutableArray *_images;
    NSInteger _totalImages, _selectedImageIndex;

    NSMapTable *_layerDictionary;
	
	// test...
	NSView *_mainView;
	
	NSUInteger _clickedIndex;
	CALayer *_clickedLayer;
}

+ (CGColorRef)color:(int)name;
- (id)initWithView:(NSView *)view;
- (BOOL)needsInit;
- (void)loadCovers;
- (void)moveSelection:(int)dx;
- (void)select;
- (YLSite *)selectedSite;
- (void)clickAtPoint:(NSPoint)aPoint 
			   count:(NSUInteger)count;

- (void)addPortalPicture:(NSString *)source 
				 forSite:(NSString *)siteName;

- (NSString *)portalImageFilePathForSite:(NSString *)siteName 
						   withExtention:(BOOL)withExtention;
@end
