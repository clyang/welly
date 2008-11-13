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
#import "YLLGlobalConfig.h"
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
	self = [super initWithFrame:[view frame]];
	_mainView = [view retain];
	[self setWantsLayer:YES];
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
        //@"BankGothic-Medium", @"font",
        [NSNumber numberWithFloat:[[YLLGlobalConfig sharedInstance] englishFontSize] * 1.3], @"fontSize",
        kCAAlignmentCenter, @"alignmentMode",
        nil];
    
    // here we set up the hierarchy of layers.
    //   This means child/parent relationships as well as
    //   constraint (position) relationships.
    // the root layer for the view--serves to attach the hierarchy to an NSView
    CALayer *rootLayer = [CALayer layer];
    rootLayer.layoutManager = [CAConstraintLayoutManager layoutManager];
    //NSColor *bgColor = [[YLLGlobalConfig sharedInstance] colorBG];
    //rootLayer.backgroundColor = CGColorCreateGenericRGB(bgColor.redComponent, bgColor.greenComponent, bgColor.blueComponent, bgColor.alphaComponent);
    rootLayer.backgroundColor = [XIPortal color:C_BLACK];
    rootLayer.name = @"root";

    // informative header text
    _headerTextLayer = [CATextLayer layer];
    _headerTextLayer.name = @"header";
    [_headerTextLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX]];
    [_headerTextLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX]];
    [_headerTextLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY offset:-30]];
    [_headerTextLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"header" attribute:kCAConstraintMaxY offset:-32]];
    _headerTextLayer.string = @"Loading...";
    _headerTextLayer.style = textStyle;
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
    _footerTextLayer = [CATextLayer layer];
    _footerTextLayer.name = @"footer";
    _footerTextLayer.style = textStyle;
    [_footerTextLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY]];
    [_footerTextLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX]];
    [statusLayer addSublayer:_footerTextLayer];

    // done
    _imageSize = *(CGSize *)&cellSize;
    [self setLayer:rootLayer];
    [_bodyLayer setDelegate:self];
    
    // create a gradient image to use for our image shadows
    CGRect r;
    r.origin = CGPointZero;
    r.size = _imageSize;
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
    
    // create a pleasant gradient mask around our central layer.
    // We don't have to worry about re-creating these when the window
    // size changes because the images will be automatically interpolated
    // to their new sizes; and as gradients, they are very well suited to
    // interpolation.
    CALayer *maskLayer = [CALayer layer];
    maskLayer.name = @"mask";
    CALayer *leftGradientLayer = [CALayer layer];
    leftGradientLayer.name = @"leftGradient";
    CALayer *rightGradientLayer = [CALayer layer];
    rightGradientLayer.name = @"rightGradient";
    CALayer *bottomGradientLayer = [CALayer layer];
    bottomGradientLayer.name = @"bottomGradient";
    
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
    [leftGradientLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX scale:.5 offset:-_imageSize.width / 2]];
    [rightGradientLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX]];
    [rightGradientLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY]];
    [rightGradientLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY]];
    [rightGradientLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMaxX scale:.5 offset:_imageSize.width / 2]];
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

    //[self loadCovers];
    [self performSelectorOnMainThread:@selector(loadCovers) withObject:nil waitUntilDone:NO];
    // restore last selection
    [self performSelectorOnMainThread:@selector(restoreSelection) withObject:nil waitUntilDone:NO];
    return self;
}

- (void)dealloc {
	NSLog(@"XIPortal dealloced!");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    CGImageRelease(_shadowImage);  
    [_layerDictionary release];
    [super dealloc];
}

- (BOOL)needsInit {
	return _images || _layerDictionary || _mainView;
}

- (CALayer *)layerForImage:(DesktopImage *)desktopImage {
    // we have to do this sublayer thing because the actual layer
    //   stored for the key is the layer containing both the desktop image
    //   and its reflection.
    CALayer *containerLayer = (CALayer *)[_layerDictionary objectForKey:desktopImage];
    return (CALayer *)[[containerLayer sublayers] objectAtIndex:0];
}

- (void)updateImageForLayer:(CALayer *)layer fromImage:(DesktopImage *)desktopImage {
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
    CGRect visRect = [_bodyLayer visibleRect];
    DesktopImageLayout *layout = [_bodyLayer layoutManager];
    NSPointerArray *indices = [layout imageIndicesOfLayer:_bodyLayer inRect:visRect];
    
    if (indices != NULL) {
        for (NSUInteger i = 0; i < [indices count]; ++i) {
            int idx = (int)[indices pointerAtIndex:i];
            if (idx >= _totalImages)
                continue;
            DesktopImage *image = [_images objectAtIndex:idx];
            [self updateImageForLayer:[self layerForImage:image] fromImage:image];
        }
    }
    [DesktopImage sweepImageQueue];
}

- (void)updateSelection {
    DesktopImageLayout *layout = [_bodyLayer layoutManager];
    [_bodyLayer setValue:[NSNumber numberWithInteger:_selectedImageIndex] forKey:selectedDesktopImage];

    // here is where we ask the layout manager to reflect the new selected image
    [_bodyLayer layoutIfNeeded];

    CALayer *layer = [self layerForImage:[_images objectAtIndex:_selectedImageIndex]];
    if (layer == nil)
        return;
    
    CGRect r = [layer frame];
    // we scroll so the selected image is centered, but the layout manager
    //   doesn't know about this--as far as it is concerned everything takes
    //   place in a very wide frame
    [_bodyLayer scrollToPoint:CGPointMake([layout positionOfSelectedImageInLayer:_bodyLayer], r.origin.y)];
    [_headerTextLayer setString:[(DesktopImage *)[layer delegate] name]];

    [self updateImage];
}

- (void)moveSelection:(int)dx {
    _selectedImageIndex += dx;

    if (_selectedImageIndex >= _totalImages) {
        _selectedImageIndex = _totalImages - 1;
        //NSBeep();
    }
    if (_selectedImageIndex < 0) {
        _selectedImageIndex = 0;
        //NSBeep();
    }

    // store the selection
    [[NSUserDefaults standardUserDefaults] setInteger:_selectedImageIndex forKey:@"PortalSelection"];

    [self updateSelection];
}

- (void)restoreSelection {
    NSInteger dx = [[NSUserDefaults standardUserDefaults] integerForKey:@"PortalSelection"];
    [self moveSelection:dx];
}

- (void)select {
	YLController *controller = [((YLApplication *)NSApp) controller];
    [controller newConnectionWithSite:[controller objectInSitesAtIndex:_selectedImageIndex]];
}

- (void)clickAtPoint:(NSPoint)aPoint count:(NSUInteger)count {
    CALayer *containerLayer = [_bodyLayer superlayer], *rootLayer = [containerLayer superlayer];
    NSAssert([rootLayer superlayer] == nil, @"root layer");
    CGPoint p = [rootLayer convertPoint:*(CGPoint*)&aPoint toLayer:containerLayer];
    CALayer *layer = [_bodyLayer hitTest:p];
    id image = [layer delegate];
    // something weird; see below
    BOOL patch = NO;
    // image container
    if (image == nil) {
        layer = [[layer sublayers] objectAtIndex:0];
        image = [layer delegate];
        patch = YES;
    }
    NSUInteger index = [_images indexOfObject:image];
    if (index == NSNotFound)
        return;
    if (index == _selectedImageIndex) {
        // double click to open
        // if (count > 1)
            [self select];
    } else {
        // move
        int dx = index - _selectedImageIndex;
        // ugly patch
        if (patch) {
            if (dx > 0) --dx;
            else if (dx < 0) ++dx;
        }
        [self moveSelection:dx];
    }
}

- (void)loadCovers {
    // cover directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSAssert([paths count] > 0, @"~/Library/Application Support");
    NSString *dir = [[[paths objectAtIndex:0] stringByAppendingPathComponent:@"Welly"] stringByAppendingPathComponent:@"Covers"];
    // load sites
    NSArray *sites = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Sites"];
    [_images release];
    _images = [[NSMutableArray arrayWithCapacity:0] retain];
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
        DesktopImage *image = [[DesktopImage alloc] initWithPath:file];
        [_images addObject:image];
        [image release];
    }
    
    size_t count = [_images count];
    id *values = malloc(count * sizeof (values[0]));
    [_images getObjects:values];
    
    for (size_t i = 0; i < count; i++) {
        DesktopImage *desktopImage = values[i];
        CALayer *desktopImageLayer = [self layerForImage:desktopImage];
        
        if (desktopImageLayer == nil) {
            CALayer *layer = [CALayer layer];
            desktopImageLayer = [CALayer layer];
            [_layerDictionary setObject:layer forKey:desktopImage];
            
            [desktopImageLayer setDelegate:desktopImage];
            
            // default appearance - will persist until image loads
            CGRect r;
            r.origin = CGPointZero;
            r.size = _imageSize;
            [desktopImageLayer setBounds:r];
            [desktopImageLayer setBackgroundColor:[XIPortal color:C_GRAY]];
            desktopImageLayer.name = @"desktopImage";
            [layer setBounds:r];
            [layer setBackgroundColor:[XIPortal color:C_TRANSPARENT]];
            [layer setSublayers:[NSArray arrayWithObject:desktopImageLayer]];
            [layer setSublayerTransform:_sublayerTransform];
            layer.name = @"desktopImageContainer";
            
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
            gradientLayer.name = @"reflectionGradient";
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
    
    _totalImages = count;
    [_bodyLayer setValue:[NSNumber numberWithInt:_totalImages] forKey:desktopImageCount];
    
    [_bodyLayer setSublayers:[NSArray arrayWithObjects:values count:count]];
    free(values);
    //[_footerTextLayer setString:[NSString stringWithFormat:@"%d sites", _totalImages]];
    
    [self updateSelection];
}

- (void)imageDidLoadNotification:(NSNotification *)note {
    DesktopImage *desktopImage = [note object];
    CALayer *layer = [self layerForImage:desktopImage];
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

- (void)mouseDown:(NSEvent *)theEvent {
    [[self window] makeFirstResponder:self];
	
    NSPoint p = [theEvent locationInWindow];
    p = [self convertPoint:p toView:nil];
	
	[self clickAtPoint:p count:[theEvent clickCount]];
	return;
}

@end
