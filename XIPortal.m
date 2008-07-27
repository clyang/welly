//
//  XIPortal.m
//  Welly
//
//  Created by boost @ 9# on 7/16/08.
//  Copyright 2008 Xi Wang. All rights reserved.
//
//  Modified from Apple CovertFlow.

#import "XIPortal.h"
#import "PortalImage.h"
#import "PortalImageLayout.h"
//#import "YLLGlobalConfig.h"
#import "YLApplication.h"
#import "YLController.h"

@implementation XIPortal

/* useful color values to have around */
enum colors {
    C_WHITE,
    C_BLACK,
    C_GRAY,
    C_LIGHT_GRAY,
    C_TRANSPARENT,
    C_COUNT
};

static const CGFloat colorValues[C_COUNT][4] = {
    {1.0, 1.0, 1.0, 1.0},
    {0.0, 0.0, 0.0, 1.0},
    {1.0, 1.0, 1.0, 0.5},
    {1.0, 1.0, 1.0, 0.1},
    {0.0, 0.0, 0.0, 0.0}
};

/* create a CGColor based on the array above */
+ (CGColorRef)color:(int)name {
    static CGColorRef colors[C_COUNT];
    static CGColorSpaceRef space;
    
    if (colors[name] == NULL) {
        if (space == NULL)
            space = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
        colors[name] = CGColorCreate(space, colorValues[name]);
    }
    
    return colors[name];
}

- (id)initWithView:(NSView *)view {
    NSSize cellSpacing = {5, 5}, cellSize = {240, 240};

    self = [super init];
    if (self == nil)
        return nil;

    // sign up to be informed when a new image loads
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(imageDidLoadNotification:)
                                                 name:desktopImageImageDidLoadNotification
                                               object:nil];
    
    _layerDictionary = [[NSMapTable mapTableWithStrongToStrongObjects] retain];
    
    // this enables a perspective transform.
    // The value of zDistance affects the sharpness of the transform
    float zDistance = 420.;
    _sublayerTransform = CATransform3DIdentity; 
    _sublayerTransform.m34 = 1. / -zDistance;
    
    NSDictionary *textStyle = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithInteger:12], @"cornerRadius",
        [NSValue valueWithSize:NSMakeSize(5, 0)], @"margin",
        @"LucidaGrande", @"font",
        [NSNumber numberWithInteger:18], @"fontSize",
        kCAAlignmentCenter, @"alignmentMode",
        nil];
    
    // here we set up the hierarchy of layers.
    //   This means child/parent relationships as well as
    //   constraint (position) relationships.
    // the root layer for the view--serves to attach the hierarchy to an NSView
    CALayer *rootLayer = [CALayer layer];
    rootLayer.layoutManager = [CAConstraintLayoutManager layoutManager];
    rootLayer.backgroundColor = [XIPortal color:C_BLACK];

    // informative header text
    _headerTextLayer = [CATextLayer layer];
    _headerTextLayer.name = @"header";
    [_headerTextLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX]];
    [_headerTextLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX]];
    [_headerTextLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY offset:-30]];
    [_headerTextLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"header" attribute:kCAConstraintMaxY offset:-32]];
    _headerTextLayer.string = @"Loading...";
    _headerTextLayer.style = textStyle;
    _headerTextLayer.fontSize = 24;
    _headerTextLayer.wrapped = YES;
    [rootLayer addSublayer:_headerTextLayer];
    
    // the background canvas on which we'll arrange the other layers
    CALayer *containerLayer = [CALayer layer];
    containerLayer.name = @"body";
    [containerLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX]];
    [containerLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth offset:-20]];
    [containerLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"status" attribute:kCAConstraintMaxY offset:10]];
    [containerLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"header" attribute:kCAConstraintMinY offset:-10]];
    [rootLayer addSublayer:containerLayer];
    
    // the central scrolling layer; this will contain the images
    _bodyLayer = [CAScrollLayer layer];
    _bodyLayer.scrollMode = kCAScrollHorizontally;
    _bodyLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    _bodyLayer.layoutManager = [DesktopImageLayout layoutManager];
    [_bodyLayer setValue:[NSValue valueWithSize:cellSpacing] forKey:@"spacing"];
    [_bodyLayer setValue:[NSValue valueWithSize:cellSize] forKey:@"desktopImageCellSize"];
    [containerLayer addSublayer:_bodyLayer];
    
    // the footer containing status info...
    CALayer *statusLayer = [CALayer layer];
    statusLayer.name = @"status";
    statusLayer.layoutManager = [CAConstraintLayoutManager layoutManager];
    [statusLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"body" attribute:kCAConstraintMidX]];
    [statusLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"body" attribute:kCAConstraintWidth]];
    [statusLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY offset:10]];
    [statusLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"status" attribute:kCAConstraintMinY offset:32]];
    [rootLayer addSublayer:statusLayer];
    
    //...such as the image count
    _desktopImageCountLayer = [CATextLayer layer];
    _desktopImageCountLayer.name = @"desktopImage-count";
    _desktopImageCountLayer.style = textStyle;
    [_desktopImageCountLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY]];
    [_desktopImageCountLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX]];
    [statusLayer addSublayer:_desktopImageCountLayer];

    // done
    _desktopImageSize = *(CGSize *)&cellSize;
    [view setLayer:rootLayer];
    [_bodyLayer setDelegate:self];
    
    // create a gradient image to use for our image shadows
    CGRect r;
    r.origin = CGPointZero;
    r.size = _desktopImageSize;
    size_t bytesPerRow = 4*r.size.width;
    void* bitmapData = malloc(bytesPerRow * r.size.height);
    CGContextRef context = CGBitmapContextCreate(bitmapData, r.size.width,
                r.size.height, 8,  bytesPerRow, 
                CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB), kCGImageAlphaPremultipliedFirst);
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0 alpha:.5] endingColor:[NSColor colorWithDeviceWhite:0 alpha:1.]];
    NSGraphicsContext *nsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:context flipped:YES];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:nsContext];
    [gradient drawInRect:NSMakeRect(0, 0, r.size.width, r.size.height) angle:90];
    [NSGraphicsContext restoreGraphicsState];
    _shadowImage = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    free(bitmapData);
    [gradient release];
    
    /* create a pleasant gradient mask around our central layer.
       We don't have to worry about re-creating these when the window
       size changes because the images will be automatically interpolated
       to their new sizes; and as gradients, they are very well suited to
       interpolation. */
    CALayer *maskLayer = [CALayer layer];
    CALayer *leftGradientLayer = [CALayer layer];
    CALayer *rightGradientLayer = [CALayer layer];
    CALayer *bottomGradientLayer = [CALayer layer];
    
    // left
    r.origin = CGPointZero;
    r.size.width = [view frame].size.width;
    r.size.height = [view frame].size.height;
    bytesPerRow = 4*r.size.width;
    bitmapData = malloc(bytesPerRow * r.size.height);
    context = CGBitmapContextCreate(bitmapData, r.size.width,
                r.size.height, 8,  bytesPerRow, 
                CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB), kCGImageAlphaPremultipliedFirst);
    gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0. alpha:1.] endingColor:[NSColor colorWithDeviceWhite:0. alpha:0]];
    nsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:context flipped:YES];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:nsContext];
    [gradient drawInRect:NSMakeRect(0, 0, r.size.width, r.size.height) angle:0];
    [NSGraphicsContext restoreGraphicsState];
    CGImageRef gradientImage = CGBitmapContextCreateImage(context);
    leftGradientLayer.contents = (id)gradientImage;
    CGContextRelease(context);
    CGImageRelease(gradientImage);
    free(bitmapData);
    
    // right
    bitmapData = malloc(bytesPerRow * r.size.height);
    context = CGBitmapContextCreate(bitmapData, r.size.width,
                r.size.height, 8,  bytesPerRow, 
                CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB), kCGImageAlphaPremultipliedFirst);
    nsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:context flipped:YES];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:nsContext];
    [gradient drawInRect:NSMakeRect(0, 0, r.size.width, r.size.height) angle:180];
    [NSGraphicsContext restoreGraphicsState];
    gradientImage = CGBitmapContextCreateImage(context);
    rightGradientLayer.contents = (id)gradientImage;
    CGContextRelease(context);
    CGImageRelease(gradientImage);
    free(bitmapData);
    
    // bottom
    r.size.width = [view frame].size.width;
    r.size.height = 32;
    bytesPerRow = 4*r.size.width;
    bitmapData = malloc(bytesPerRow * r.size.height);
    context = CGBitmapContextCreate(bitmapData, r.size.width,
                r.size.height, 8,  bytesPerRow, 
                CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB), kCGImageAlphaPremultipliedFirst);
    nsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:context flipped:YES];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:nsContext];
    [gradient drawInRect:NSMakeRect(0, 0, r.size.width, r.size.height) angle:90];
    [NSGraphicsContext restoreGraphicsState];
    gradientImage = CGBitmapContextCreateImage(context);
    bottomGradientLayer.contents = (id)gradientImage;
    CGContextRelease(context);
    CGImageRelease(gradientImage);
    free(bitmapData);
    [gradient release];
    
    // the autoresizing mask allows it to change shape with the parent layer
    maskLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    maskLayer.layoutManager = [CAConstraintLayoutManager layoutManager];
    [leftGradientLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX]];
    [leftGradientLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY]];
    [leftGradientLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY]];
    [leftGradientLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX scale:.5 offset:-_desktopImageSize.width / 2]];
    [rightGradientLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX]];
    [rightGradientLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY]];
    [rightGradientLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY]];
    [rightGradientLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMaxX scale:.5 offset:_desktopImageSize.width / 2]];
    [bottomGradientLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX]];
    [bottomGradientLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY]];
    [bottomGradientLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX]];
    [bottomGradientLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMinY offset:32]];
    
    bottomGradientLayer.masksToBounds = YES;
    
    [maskLayer addSublayer:rightGradientLayer];
    [maskLayer addSublayer:leftGradientLayer];
    [maskLayer addSublayer:bottomGradientLayer];
    // we make it a sublayer rather than a mask so that the overlapping alpha will work correctly
    // without the use of a compositing filter
    [containerLayer addSublayer:maskLayer];
    
    [self performSelectorOnMainThread:@selector(loadCovers) withObject:nil waitUntilDone:NO];
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    CGImageRelease(_shadowImage);  
    [_layerDictionary release];
    [super dealloc];
}

- (CALayer *)layerForDesktopImage:(DesktopImage *)desktopImage {
    // we have to do this sublayer thing because the actual layer
    //   stored for the key is the layer containing both the desktop image
    //   and its reflection.
    CALayer *containerLayer = (CALayer *)[_layerDictionary objectForKey:desktopImage];
    return (CALayer *)[[containerLayer sublayers] objectAtIndex:0];
}

- (void)updateImageForLayer:(CALayer *)layer fromDesktopImage:(DesktopImage *)desktopImage {
    CGSize size = [layer bounds].size;
    CGImageRef image = [desktopImage imageOfSize:size];

    if (image != NULL) {
        // set the image for the layer...
        [layer setContents:(id) image];
        // ...and for its shadow (which we know to be the first sublayer)
        NSArray *sublayers = layer.sublayers;
        CALayer *sublayer = (CALayer *)[sublayers objectAtIndex:0];
        [sublayer setContents:(id)image];
        [sublayer setBackgroundColor:NULL];
    } else
        [desktopImage requestImageOfSize:size];
}

- (void)updateImage {
    DesktopImage *desktopImage;
    
    CGRect visRect = [_bodyLayer visibleRect];
    DesktopImageLayout *layout = [_bodyLayer layoutManager];
    CFArrayRef indices = [layout desktopImageIndicesOfLayer:_bodyLayer inRect:visRect];
    
    if (indices != NULL) {
        size_t count = CFArrayGetCount(indices);
        for (size_t i = 0; i < count; i++) {
            size_t idx = (uintptr_t) CFArrayGetValueAtIndex(indices, i);
            if (idx < _totalDesktopImages) {
                desktopImage = [_desktopImages objectAtIndex:idx];
                [self updateImageForLayer:[self layerForDesktopImage:desktopImage] fromDesktopImage:desktopImage];
            }
        }
        CFRelease(indices);
    }
    [DesktopImage sweepImageQueue];
}

- (void)updateSelection {
    DesktopImageLayout *layout = [_bodyLayer layoutManager];
    [_bodyLayer setValue:[NSNumber numberWithInteger:_selectedDesktopImageIndex] forKey:selectedDesktopImage];

    // here is where we ask the layout manager to reflect the new selected image
    [_bodyLayer layoutIfNeeded];

    CALayer *layer = [self layerForDesktopImage:[_desktopImages objectAtIndex:_selectedDesktopImageIndex]];
    if (layer == nil)
        return;
    
    CGRect r = [layer frame];
    // we scroll so the selected image is centered, but the layout manager
    //   doesn't know about this--as far as it is concerned everything takes
    //   place in a very wide frame
    [_bodyLayer scrollToPoint:CGPointMake([layout positionOfSelectedDesktopImageInLayer:_bodyLayer], r.origin.y)];
    [_headerTextLayer setString:[(DesktopImage *)[layer delegate] name]];

    [self updateImage];
}

- (void)moveSelection:(int)dx {
    _selectedDesktopImageIndex += dx;

    if (_selectedDesktopImageIndex >= _totalDesktopImages) {
        _selectedDesktopImageIndex = _totalDesktopImages - 1;
        NSBeep();
    }
    if (_selectedDesktopImageIndex < 0) {
        _selectedDesktopImageIndex = 0;
        NSBeep();
    }

    [self updateSelection];
}

- (void)select {
    YLController *controller = [((YLApplication *)NSApp) controller];
    [controller newConnectionWithSite:[controller objectInSitesAtIndex:_selectedDesktopImageIndex]];
}

- (void)loadCovers {
    // cover directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSAssert([paths count] > 0, @"~/Library/Application Support");
    NSString *dir = [[[paths objectAtIndex:0] stringByAppendingPathComponent:@"Welly"] stringByAppendingPathComponent:@"Covers"];
    // load sites
    NSArray *sites = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Sites"];
    [_desktopImages release];
    _desktopImages = [[NSMutableArray arrayWithCapacity:0] retain];
    for (NSDictionary *d in sites) {
        NSString *key = [d objectForKey:@"name"];
        if ([key length] == 0)
            continue;
        // guess the image file name
        NSString *file = nil;
        [[[dir stringByAppendingPathComponent:key] stringByAppendingString:@"."]
            completePathIntoString:&file caseSensitive:NO matchesIntoArray:nil filterTypes:nil];
        // nonexistent file
        if (file == nil)
            file = key;
        DesktopImage *desktopImage = [[DesktopImage alloc] initWithPath:file];
        [_desktopImages addObject:desktopImage];
        [desktopImage release];
    }
    
    size_t count = [_desktopImages count];
    id *values = malloc (count * sizeof (values[0]));
    [_desktopImages getObjects:values];
    
    for (size_t i = 0; i < count; i++) {
        DesktopImage *desktopImage = values[i];
        CALayer *desktopImageLayer = [self layerForDesktopImage:desktopImage];
        
        if (desktopImageLayer == nil) {
            CALayer *layer = [CALayer layer];
            desktopImageLayer = [CALayer layer];
            [_layerDictionary setObject:layer forKey:desktopImage];
            
            [desktopImageLayer setDelegate:desktopImage];
            
            // default appearance - will persist until image loads
            CGRect r;
            r.origin = CGPointZero;
            r.size = _desktopImageSize;
            [desktopImageLayer setBounds:r];
            [desktopImageLayer setBackgroundColor:[XIPortal color:C_GRAY]];
            desktopImageLayer.name = @"desktopImage";
            [layer setBounds:r];
            [layer setBackgroundColor:[XIPortal color:C_TRANSPARENT]];
            [layer setSublayers:[NSArray arrayWithObject:desktopImageLayer]];
            [layer setSublayerTransform:_sublayerTransform];
            
            // and the desktop image's reflection layer
            CALayer *sublayer = [CALayer layer];
            r.origin = CGPointMake(0, -r.size.height);
            [sublayer setFrame:r];
            sublayer.name = @"reflection";
            CATransform3D transform = CATransform3DMakeScale(1,-1,1);
            sublayer.transform = transform;
            [sublayer setBackgroundColor:[XIPortal color:C_GRAY]];
            [desktopImageLayer addSublayer:sublayer];
            CALayer *gradientLayer = [CALayer layer];
            r.origin.y += r.size.height;
            // if the gradient rect is exactly the correct size,
            // antialiasing sometimes gives us a line of bright pixels
            // at the edges
            r.origin.x -= .5;
            r.size.height += 1;
            r.size.width += 1;
            [gradientLayer setFrame:r];
            [gradientLayer setContents:(id)_shadowImage];
            [gradientLayer setOpaque:NO];
            [sublayer addSublayer:gradientLayer];
        }     
        [desktopImageLayer setValue:[NSNumber numberWithInt:i] forKey:desktopImageIndex];
        values[i] = [desktopImageLayer superlayer];
    }
    
    _totalDesktopImages = count;
    [_bodyLayer setValue:[NSNumber numberWithInt:_totalDesktopImages] forKey:desktopImageCount];
    
    [_bodyLayer setSublayers:[NSArray arrayWithObjects:values count:count]];
    free(values);
    //[_desktopImageCountLayer setString:[NSString stringWithFormat:@"%d sites", _totalDesktopImages]];
    
    [self updateSelection];
}

- (void)imageDidLoadNotification:(NSNotification *)note {
    DesktopImage *desktopImage = [note object];
    CALayer *layer = [self layerForDesktopImage:desktopImage];
    if (layer != nil) {
        CGImageRef image = [desktopImage imageOfSize:[layer bounds].size];
        if (image != NULL) {
            // main image
            [layer setContents:(id)image];
            [layer setBackgroundColor:NULL];
            NSArray *sublayers = layer.sublayers;
            // reflection
            CALayer *sublayer = (CALayer *)[sublayers objectAtIndex:0];
            [sublayer setContents:(id)image];
            [sublayer setBackgroundColor:NULL];
            CGImageRelease (image);
        }
    }
}

@end
