//
//  XIPortal.m
//  Welly
//
//  Created by boost @ 9# on 7/16/08.
//  Copyright 2008 Xi Wang. All rights reserved.
//
//  Modified from Apple CovertFlow.

#import "WLPortal.h"
#import "PortalImage.h"
#import "PortalImageLayout.h"
#import "YLLGlobalConfig.h"
#import "YLApplication.h"
#import "YLController.h"

@implementation WLPortal
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
    NSSize cellSpacing = {10, 10}, cellSize = {230, 230};

    self = [super init];
    if (self == nil)
        return nil;

	NSAutoreleasePool *pool = [NSAutoreleasePool new];
    // sign up to be informed when a new image loads
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(imageDidLoadNotification:)
                                                 name:desktopImageImageDidLoadNotification
                                               object:nil];
    
    _layerDictionary = [[NSMapTable mapTableWithStrongToStrongObjects] retain];
    
    // this enables a perspective transform.
    // The value of zDistance affects the sharpness of the transform
    float zDistance = 300.;
    _sublayerTransform = CATransform3DIdentity; 
    _sublayerTransform.m34 = 1. / -zDistance;
    
    NSDictionary *textStyle = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithInteger:12], @"cornerRadius",
       // [NSValue valueWithSize:NSMakeSize(10, 0)], @"margin",
        @"LucidaGrande-Bold", @"font",
        [NSNumber numberWithFloat:[[YLLGlobalConfig sharedInstance] englishFontSize] * 1.5], @"fontSize",
        kCAAlignmentCenter, @"alignmentMode",
        nil];
	NSDictionary *tipStyle = [NSDictionary dictionaryWithObjectsAndKeys:
							   [NSValue valueWithSize:NSMakeSize(5, 0)], @"margin",
							   @"LucidaGrande", @"font",
							   [NSNumber numberWithFloat:12], @"fontSize",
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
    rootLayer.backgroundColor = [WLPortal color:C_BLACK];
    rootLayer.name = @"root";

    // informative header text
    _headerTextLayer = [CATextLayer layer];
	_headerTextLayer.name = @"header";
    [_headerTextLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX]];
    [_headerTextLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX]];
    [_headerTextLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY offset:-20]];
    [_headerTextLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"header" attribute:kCAConstraintMaxY offset:-60]];	
	//[_headerTextLayer setBackgroundColor:CGColorCreateGenericRGB(1.0, 0, 0, 1.0f)];
	_headerTextLayer.contentsGravity = @"kCAGravityCenter";
	
	_headerTextLayer.string = @"Loading...";
    _headerTextLayer.style = textStyle;
    _headerTextLayer.wrapped = YES;	
	[rootLayer addSublayer: _headerTextLayer];
    
    // the background canvas on which we'll arrange the other layers
    CALayer *containerLayer = [CALayer layer];
    containerLayer.name = @"body";
    [containerLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX]];
    [containerLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth offset:-20]];
    [containerLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"status" attribute:kCAConstraintMaxY offset:10]];
    [containerLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"header" attribute:kCAConstraintMinY offset:-5]];
	   // [containerLayer setBackgroundColor:CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1.0f)];
	[rootLayer addSublayer:containerLayer];
    
    // the central scrolling layer; this will contain the images
    _bodyLayer = [CAScrollLayer layer];
    _bodyLayer.scrollMode = kCAScrollHorizontally;
    _bodyLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    _bodyLayer.layoutManager = [PortalImageLayout layoutManager];
	[_bodyLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY]];
    [_bodyLayer setValue:[NSValue valueWithSize:cellSpacing] forKey:@"spacing"];
    [_bodyLayer setValue:[NSValue valueWithSize:cellSize] forKey:@"desktopImageCellSize"];
	//[_bodyLayer setBackgroundColor:CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1.0f)];
    [containerLayer addSublayer:_bodyLayer];
    
    // the footer containing status info...
    CALayer *statusLayer = [CALayer layer];
    statusLayer.name = @"status";
    statusLayer.layoutManager = [CAConstraintLayoutManager layoutManager];
	//[statusLayer setBackgroundColor:CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1.0f)];
    [statusLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"body" attribute:kCAConstraintMidX]];
    [statusLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"body" attribute:kCAConstraintWidth]];
    [statusLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY offset:10]];
    [statusLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"status" attribute:kCAConstraintMinY offset:30]];
    [rootLayer addSublayer:statusLayer];
    
    //...such as the image count
    _footerTextLayer = [CATextLayer layer];
    _footerTextLayer.name = @"footer";
    _footerTextLayer.style = tipStyle;
    _footerTextLayer.string = NSLocalizedString(@"Drag an image file to Welly to set the cover of this site. ", @"Drag an image file to Welly to set the cover of this site. \n Drag the cover out to remove.");
    _footerTextLayer.hidden = true;
    [_footerTextLayer setForegroundColor:CGColorCreateGenericRGB(1.0, 1.0, 1.0, 0.7f)];
    [_footerTextLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY]];
    [_footerTextLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX]];
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
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0 alpha:.2] endingColor:[NSColor colorWithDeviceWhite:0 alpha:1.]];
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
    r.size.width = (int)([view frame].size.width + 0.5f);
    r.size.height = (int)([view frame].size.height + 0.5f);
	NSLog(@"width=%f, height=%f", r.size.width, r.size.height);
    bytesPerRow = 4*r.size.width;
    bitmapData = malloc(bytesPerRow * r.size.height);
    context = CGBitmapContextCreate(bitmapData, r.size.width,
                r.size.height, 8,  bytesPerRow, 
                CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB), kCGImageAlphaPremultipliedFirst);
    gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0. alpha:0.9] endingColor:[NSColor colorWithDeviceWhite:0. alpha:0]];
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
    r.size.width = (int)([view frame].size.width + 0.5f);
    r.size.height = 10;
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
	
	// register for dragged types
	[self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
	[pool release];
    return self;
}

- (void)dealloc {
	//NSLog(@"Portal dealloced");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    CGImageRelease(_shadowImage);
    [_layerDictionary release];
	[_mainView release];
	[_images release];
    [super dealloc];
}

- (BOOL)needsInit {
	return _images || _layerDictionary || _mainView;
}

- (CALayer *)layerForImage:(PortalImage *)desktopImage {
    // we have to do this sublayer thing because the actual layer
    //   stored for the key is the layer containing both the desktop image
    //   and its reflection.
    CALayer *containerLayer = (CALayer *)[_layerDictionary objectForKey:desktopImage];
    return (CALayer *)[[containerLayer sublayers] objectAtIndex:0];
}

- (void)updateImageForLayer:(CALayer *)layer fromImage:(PortalImage *)portalImage {
    CGSize size = [layer bounds].size;
    CGImageRef image = [portalImage imageOfSize:size];

    if (image != NULL) {
        // set the image for the layer...
        [layer setContents:(id)image];
        // ...and for its shadow (which we know to be the first sublayer)
        NSArray *sublayers = layer.sublayers;
        CALayer *sublayer = (CALayer *)[sublayers objectAtIndex:0];
        [sublayer setContents:(id)image];
        [sublayer setBackgroundColor:NULL];
    } else
        [portalImage requestImageOfSize:size];
}

- (void)updateImage { 
    CGRect visRect = [_bodyLayer visibleRect];
    PortalImageLayout *layout = [_bodyLayer layoutManager];
    NSPointerArray *indices = [layout imageIndicesOfLayer:_bodyLayer inRect:visRect];
    
    if (indices != NULL) {
        for (NSUInteger i = 0; i < [indices count]; ++i) {
            NSUInteger idx = (NSUInteger)[indices pointerAtIndex:i];
            if (idx >= _totalImages)
                continue;
            PortalImage *image = [_images objectAtIndex:idx];
            [self updateImageForLayer:[self layerForImage:image] fromImage:image];
        }
    }
    [PortalImage sweepImageQueue];
}

- (void)updateSelection {
    PortalImageLayout *layout = [_bodyLayer layoutManager];
    [_bodyLayer setValue:[NSNumber numberWithInteger:_selectedImageIndex] forKey:selectedDesktopImage];

    // here is where we ask the layout manager to reflect the new selected image
    [_bodyLayer layoutIfNeeded];

    PortalImage *portalImage = [_images objectAtIndex:_selectedImageIndex];
    CALayer *layer = [self layerForImage:portalImage];
    if (layer == nil)
        return;
    
    CGRect r = [layer frame];
    // we scroll so the selected image is centered, but the layout manager
    //   doesn't know about this--as far as it is concerned everything takes
    //   place in a very wide frame
    [CATransaction begin];
    [CATransaction setValue:[NSNumber numberWithFloat:0.275f]
                     forKey:kCATransactionAnimationDuration];
    // TODO: It might be possible to change the timing function. 
    // Linear timing's effect is not quite satisfying.
    [_bodyLayer scrollToPoint:CGPointMake([layout positionOfSelectedImageInLayer:_bodyLayer], r.origin.y)];
    [CATransaction commit];
    [_headerTextLayer setString:[portalImage name]];
    // weird: shouldn't be the inverse?
    [_footerTextLayer setHidden:[portalImage exists]];

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

- (YLSite *)siteAtIndex:(NSUInteger)index {
	YLController *controller = [((YLApplication *)NSApp) controller];
	return [controller objectInSitesAtIndex:index];	
}

- (YLSite *)selectedSite {
	return [self siteAtIndex:_selectedImageIndex];
}

- (void)select {
	YLController *controller = [((YLApplication *)NSApp) controller];
    [controller newConnectionWithSite:[self selectedSite]];
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
        BOOL exist = YES;
		if (file == nil) {
            file = key;
			exist = NO;
		}
        PortalImage *image = [[PortalImage alloc] initWithPath:file isExist:exist];
        [_images addObject:image];
        [image release];
    }
    
    size_t count = [_images count];
    id *values = malloc(count * sizeof (values[0]));
    [_images getObjects:values];
    
    for (size_t i = 0; i < count; i++) {
        PortalImage *desktopImage = values[i];
        CALayer *desktopImageLayer = [self layerForImage:desktopImage];
        
        if (desktopImageLayer == nil) {
            CALayer *layer = [CALayer layer];
			desktopImageLayer = [CALayer layer];
            [_layerDictionary setObject:layer forKey:desktopImage];
            
            [desktopImageLayer setDelegate:desktopImage];
            
			float gap = 30.0f;
            // default appearance - will persist until image loads
            CGRect r;
            r.origin = CGPointZero;
			r.origin.y -= gap;
            r.size = _imageSize;
            [desktopImageLayer setBounds:r];
            [desktopImageLayer setBackgroundColor:[WLPortal color:C_GRAY]];
            desktopImageLayer.name = @"desktopImage";
            [layer setBounds:r];
            [layer setBackgroundColor:[WLPortal color:C_TRANSPARENT]];
            [layer setSublayers:[NSArray arrayWithObject:desktopImageLayer]];
            [layer setSublayerTransform:_sublayerTransform];
            layer.name = @"desktopImageContainer";
            
            // and the desktop image's reflection layer
            CALayer *sublayer = [CALayer layer];
            r.origin = CGPointMake(0, -r.size.height - gap + 1);
            [sublayer setFrame:r];
            sublayer.name = @"reflection";
            CATransform3D transform = CATransform3DMakeScale(1,-1,1);
            sublayer.transform = transform;
			// TODO: Perhaps we should add a CIFilter here to process the reflection?
            [sublayer setBackgroundColor:[WLPortal color:C_GRAY]];
            [desktopImageLayer addSublayer:sublayer];
            CALayer *gradientLayer = [CALayer layer];
            gradientLayer.name = @"reflectionGradient";
            r.origin.y += r.size.height;
			r.origin.y += gap;
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
    //[self updateSelection];
}

- (void)imageDidLoadNotification:(NSNotification *)note {
    PortalImage *desktopImage = [note object];
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

- (NSImage *)imageForDraggingAtIndex:(NSUInteger)index {
	NSString *imageFilePath = [[_images objectAtIndex:index] path];
	NSImage *dragImage = [[NSWorkspace sharedWorkspace] iconForFile:imageFilePath];
	return dragImage;//[_images objectAtIndex:_selectedImageIndex];
}

#pragma mark -
#pragma mark Event Handle
- (CALayer *)layerAtPoint:(NSPoint)aPoint {
	CALayer *containerLayer = [_bodyLayer superlayer], *rootLayer = [containerLayer superlayer];
    NSAssert([rootLayer superlayer] == nil, @"root layer");
    CGPoint p = [rootLayer convertPoint:*(CGPoint*)&aPoint toLayer:containerLayer];
    CALayer *layer = [_bodyLayer hitTest:p];
	return layer;
}

- (NSUInteger)indexAtPoint:(NSPoint)aPoint {
    CALayer *layer = [self layerAtPoint:aPoint];
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
		return NSNotFound;
	
	// ugly patch
	if (patch) {
		if (index > _selectedImageIndex) 
			--index;
		else if (index < _selectedImageIndex) 
			++index;
	}
	return index;
}

- (void)clickAtPoint:(NSPoint)aPoint count:(NSUInteger)count {
	/*
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
	 */
	NSUInteger index = [self indexAtPoint:aPoint];
    if (index == NSNotFound)
        return;
    if (index == _selectedImageIndex) {
        // double click to open
        // if (count > 1)
		[self select];
    } else {
        // move
        int dx = index - _selectedImageIndex;
		/*
        // ugly patch
        if (patch) {
            if (dx > 0) --dx;
            else if (dx < 0) ++dx;
        }
		 */
        [self moveSelection:dx];
    }
}

- (void)mouseDown:(NSEvent *)theEvent {
    NSPoint p = [theEvent locationInWindow];
    p = [self convertPoint:p toView:nil];

	_clickedIndex = [self indexAtPoint:p];
	_clickedLayer = [self layerAtPoint:p];
}

- (void)mouseDragged:(NSEvent *)theEvent {
	// Drag a cover
	if (_clickedIndex == NSNotFound)
		return;
	YLSite *site = [[[((YLApplication *)NSApp) controller] sites] objectAtIndex:_clickedIndex];
	if (site == NULL)
		return;
	NSString *siteName = [site name];
	
	// Do not allow to drag & drop default image
	if ([self portalImageFilePathForSite:siteName withExtention:YES] == nil)
		return;
	
    NSPoint p = [theEvent locationInWindow];
    p = [self convertPoint:p toView:nil];
	
	NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
	
	[pboard declareTypes:[NSArray arrayWithObject: NSStringPboardType] owner:nil];
	[pboard setString:siteName forType:NSStringPboardType];
	NSImage *dragImage = [self imageForDraggingAtIndex:_clickedIndex];
	[self dragImage:dragImage
				 at:p
			 offset:NSZeroSize 
			  event:theEvent 
		 pasteboard:pboard 
			 source:self
		  slideBack:YES];
	return;
}

- (void)mouseUp:(NSEvent *)theEvent {
	// Click on a cover
	[[self window] makeFirstResponder:self];
	
    NSPoint p = [theEvent locationInWindow];
    p = [self convertPoint:p toView:nil];
	
	[self clickAtPoint:p count:[theEvent clickCount]];
}

#pragma mark -
#pragma mark Manage Portal Images
- (NSString *)portalImageFilePathForSite:(NSString *)siteName 
						   withExtention:(BOOL)withExtention {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	// Create the dir if necessary
	// by gtCarrera
	NSString *destDir = [[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] 
						  stringByAppendingPathComponent:@"Application Support"] 
						 stringByAppendingPathComponent:@"Welly"];
	[fileManager createDirectoryAtPath:destDir attributes:nil];
	destDir = [destDir stringByAppendingPathComponent:@"Covers"];
	[fileManager createDirectoryAtPath:destDir attributes:nil];
	
	NSString *destination = [destDir stringByAppendingPathComponent:siteName];
	if (!withExtention)
		return destination;
	else {
		destination = [destination stringByAppendingString:@"."];
		NSString *file = nil;
		// Guess the extension
		[destination completePathIntoString:&file caseSensitive:NO matchesIntoArray:nil filterTypes:nil];
		return file;
	}
}

- (void)removePortalPictureForSite:(NSString *)siteName {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	// Remove all existing picture for this site
	NSArray *allowedTypes = supportedCoverExtensions;
	for (NSString *ext in allowedTypes) {
		[fileManager removeItemAtPath:[[self portalImageFilePathForSite:siteName withExtention:NO] stringByAppendingPathExtension:ext] error:NULL];
	}
	[(YLView *)_mainView resetPortal];
}

- (void)removePortalPictureAtIndex:(NSUInteger)index {
	NSString *siteName = [[self siteAtIndex:index] name];
	[self removePortalPictureForSite:siteName];
}

- (void)addPortalPicture:(NSString *)source 
				 forSite:(NSString *)siteName {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	[self removePortalPictureForSite:siteName];
	[fileManager copyItemAtPath:source toPath:[[self portalImageFilePathForSite:siteName withExtention:NO] stringByAppendingPathExtension:[source pathExtension]] error:NULL];
	[(YLView *)_mainView resetPortal];
}

#pragma mark -
#pragma mark Drag & Drop
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
	// Check if site is available
	if ([self selectedSite] == NULL)
		return NSDragOperationNone;
	
	// Need the delegate hooked up to accept the dragged item(s) into the model	
	// Check pboard type
	NSPasteboard *pboard = [sender draggingPasteboard];
	
	if (![[pboard types] containsObject:NSFilenamesPboardType])
		return NSDragOperationNone;
	
	// Check file number. We only support drag one image file in.
	NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
	int numberOfFiles = [files count];
	if (numberOfFiles != 1)
		return NSDragOperationNone;
	
	// Check the file type
	NSString *filename = [files objectAtIndex: 0];
	NSString *suffix = [[filename componentsSeparatedByString:@"."] lastObject];
	NSArray *suffixes = supportedCoverExtensions;
	if ([filename hasSuffix: @"/"] || ![suffixes containsObject:[suffix lowercaseString]])
		return NSDragOperationNone;;
	
	// Passed all check points
	return NSDragOperationCopy;
}

// Work around a bug from 10.2 onwards
- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
	return NSDragOperationEvery;
}

// Stop the NSTableView implementation getting in the way
- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
	return [self draggingEntered:sender];
}

//
// drag a picture file into the portal view to change the cover picture
// 
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	YLSite *site = [self selectedSite];
	if (site == NULL)
		return NO;

	NSPasteboard *pboard = [sender draggingPasteboard];

	assert([[pboard types] containsObject:NSFilenamesPboardType]); 
	
	NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
	assert([files count] == 1);
	
	// Copy the image file into the cover folder
	NSString *filename = [files objectAtIndex: 0];
	NSString *suffix = [[filename componentsSeparatedByString:@"."] lastObject];
	NSArray *suffixes = supportedCoverExtensions;
	assert(![filename hasSuffix: @"/"] && [suffixes containsObject:[suffix lowercaseString]]);
	[self addPortalPicture:filename forSite:[site name]];
	
    return YES;
}

- (void)draggedImage:(NSImage *)image
			 movedTo:(NSPoint)screenPoint {
	// Convert screen point to the coordination in '_clickedLayer'
	screenPoint = [[self window] convertScreenToBase:screenPoint];
	screenPoint = [self convertPoint:screenPoint toView:nil];
	CALayer *containerLayer = [_bodyLayer superlayer], *rootLayer = [containerLayer superlayer];
    NSAssert([rootLayer superlayer] == nil, @"root layer");
    CGPoint p = [containerLayer convertPoint:[rootLayer convertPoint:*(CGPoint*)&screenPoint toLayer:containerLayer] toLayer:_clickedLayer];
	// Check the cursor position
	if ([_clickedLayer containsPoint:p]) {
		// If the cursor is inside the cover, we do not change the cursor
		[[NSCursor arrowCursor] set];
	} else {
		// If the cursor get outside the cover, 
		// we use the disappearing item cursor to represent the deleting operation
		[[NSCursor disappearingItemCursor] set];
	}
}

- (void)draggedImage:(NSImage *)image 
			 endedAt:(NSPoint)screenPoint 
		   operation:(NSDragOperation)operation {
	// Convert screen point to the coordination in '_clickedLayer'
	screenPoint = [[self window] convertScreenToBase:screenPoint];
	screenPoint = [self convertPoint:screenPoint toView:nil];
	CALayer *containerLayer = [_bodyLayer superlayer], *rootLayer = [containerLayer superlayer];
	NSAssert([rootLayer superlayer] == nil, @"root layer");
	CGPoint p = [containerLayer convertPoint:[rootLayer convertPoint:*(CGPoint*)&screenPoint toLayer:containerLayer] toLayer:_clickedLayer];
	// Check the cursor position
	if ([_clickedLayer containsPoint:p]) {
		// The cursor is inside the cover, do nothing
	} else {
		// The cursor is outside the cover, we remove the cover
		[self removePortalPictureAtIndex:_clickedIndex];
	}
}
@end
