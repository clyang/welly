// modified by boost @ 9#

/* CovertFlow - DesktopImageLayout.m
 *
 * Abstract: The DesktopImageLayout determines the visual layout of the
 * desktop image elements.
 *
 * Copyright (c) 2006-2007 Apple Computer, Inc.
 * All rights reserved.
 */

/* IMPORTANT: This Apple software is supplied to you by Apple Computer,
 Inc. ("Apple") in consideration of your agreement to the following terms,
 and your use, installation, modification or redistribution of this Apple
 software constitutes acceptance of these terms.  If you do not agree with
 these terms, please do not use, install, modify or redistribute this Apple
 software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following text
 and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Computer,
 Inc. may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple. Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES
 NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE
 IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
 PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION
 ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND
 WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT
 LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY
 OF SUCH DAMAGE. */

#import "PortalImageLayout.h"
#import <Foundation/Foundation.h>
#import <QuartzCore/CoreImage.h>

NSString *desktopImageCellSize = @"desktopImageCellSize";
NSString *desktopImageCount = @"desktopImageCount";
NSString *desktopImageIndex = @"desktopImageIndex";
NSString *selectedDesktopImage = @"selectedDesktopImage";

@implementation PortalImageLayout

static PortalImageLayout *sharedLayoutManager;

+ (id)layoutManager {
    if (sharedLayoutManager == nil) {
        sharedLayoutManager = [[self alloc] init];
    }
    return sharedLayoutManager;
}

- (PortalImageLayout *)init {
    if ([super init]) {
        // there's no math behind these; they just happen to look right
        _zCenterPosition = 100.;
        _zSidePosition = 0;
        _sideSpacingFactor = .75;
        _rowScaleFactor = .85;
        float angle = .79;
        _leftTransform = CATransform3DMakeRotation(-angle, 0, -1, 0);
        _rightTransform = CATransform3DMakeRotation(angle, 0, -1, 0);
        return self;
    }
    return nil;
}

- (float)positionOfSelectedImageInLayer:(CALayer *)layer {
    // extract values from the layer: selected image index, and spacing information
    NSNumber *number = [layer valueForKey:selectedDesktopImage];
    int selected = number != nil ? [number integerValue] : 0;
    float margin = [[layer valueForKey:@"margin"] sizeValue].width;
    float bounds = [layer bounds].size.width;
    float cellSize = (float)[[layer valueForKey:desktopImageCellSize] sizeValue].width;
    cellSize = cellSize ? cellSize : 100.;
    float count = [[layer valueForKey:desktopImageCount] intValue];
    float spacing = [[layer valueForKey:@"spacing"] sizeValue].width;
    
    // this is the same math used in layoutSublayersOfLayer:, before tweaking
    float x = floor(margin + .5*(bounds - cellSize * count - spacing * (count - 1))) + selected * (cellSize + spacing) - .5 * bounds + .5 * cellSize;
    
    return x;
}

- (NSPointerArray *)imageIndicesOfLayer:(CALayer *)layer 
								 inRect:(CGRect)r {
    CGSize size = [layer bounds].size;
    NSSize margin = [[layer valueForKey:@"margin"] sizeValue];
    NSSize spacing = [[layer valueForKey:@"spacing"] sizeValue];
    NSValue *value = [layer valueForKey:desktopImageCellSize];
    NSSize cellSize = value != nil ? [value sizeValue] : NSMakeSize (100.0, 100.0);
    int total = [[layer valueForKey:desktopImageCount] intValue];
    NSNumber *number = [layer valueForKey:selectedDesktopImage];
    float selected = number != nil ? [number integerValue] : 0.;

    if (total == 0)
        return NULL;

    margin.width += (size.width - cellSize.width * total - spacing.width * (total - 1)) * .5;
    margin.width = floor (margin.width);

    // these are the inverse of the equations in layoutSublayersOfLayer:, below
    int x0 = floor((r.origin.x - margin.width - (cellSize.width * _sideSpacingFactor) * (selected + _rowScaleFactor)) / ((1. - _sideSpacingFactor) * cellSize.width + spacing.width));
    int x1 = ceil((r.origin.x + r.size.width - margin.width - (cellSize.width * _sideSpacingFactor) * (selected + _rowScaleFactor)) / (cellSize.width * (1. - _sideSpacingFactor) + spacing.width));
    if (x0 < 0)
        x0 = 0;
    if (x1 >= total)
        x1 = total - 1;

    int count = (x1 - x0 + 1);
    if (count <= 0)
        return NULL;

    NSPointerArray *values = [NSPointerArray pointerArrayWithWeakObjects];
    for (NSUInteger x = x0; x <= x1; x++)
        [values addPointer:(void *)x];
    return values;
}

// this is where the magic happens
- (void)layoutSublayersOfLayer:(CALayer *)layer {
    CGSize size = [layer bounds].size;
    NSSize margin = [[layer valueForKey:@"margin"] sizeValue];
    NSSize spacing = [[layer valueForKey:@"spacing"] sizeValue];
    NSNumber *number = [layer valueForKey:selectedDesktopImage];
    int selected = number != nil ? [number integerValue] : 0;
    NSValue *value = [layer valueForKey:desktopImageCellSize];
    NSSize cellSize = value != nil ? [value sizeValue] : NSMakeSize (100.0, 100.0);
    int total = [[layer valueForKey:desktopImageCount] intValue];
    if (total == 0)
        return;

    margin.width += (size.width - cellSize.width * total - spacing.width * (total - 1)) * .5;
    margin.width = floor (margin.width);

    NSArray *array = [layer sublayers];
    size_t count = [array count];

    for (size_t i = 0; i < count; i++) {
        CALayer *sublayer = [array objectAtIndex:i];
        CALayer *desktopImageLayer = [[sublayer sublayers] objectAtIndex:0];
        
        NSNumber *index = [desktopImageLayer valueForKey:desktopImageIndex];
        if (index == nil)
            continue;
        
        int x = [index intValue];
        
        CGRect rect = {CGPointZero, *(CGSize *)&cellSize};
        CGRect desktopImageRect = rect;
        // base position - this would be correct without perspective
        rect.origin.y = size.height / 2 - cellSize.height / 2;
        rect.origin.x = margin.width + x * (cellSize.width + spacing.width);
        
        // perspective and according position tweaks
        if (x < selected) {         // left
            rect.origin.x += cellSize.width * _sideSpacingFactor * (float)(selected - x - _rowScaleFactor);
            desktopImageLayer.transform = _leftTransform;
            desktopImageLayer.zPosition = _zSidePosition;
            sublayer.zPosition = _zSidePosition - .01 * (selected - x);
        } else if (x > selected) {  // right
            rect.origin.x -= cellSize.width * _sideSpacingFactor * (float)(x - selected - _rowScaleFactor);
            desktopImageLayer.transform = _rightTransform;
            desktopImageLayer.zPosition = _zSidePosition;
            sublayer.zPosition = _zSidePosition - .01 * (x - selected);
        } else {                    // center
            desktopImageLayer.transform = CATransform3DIdentity;
            desktopImageLayer.zPosition = _zCenterPosition;
            sublayer.zPosition = _zSidePosition;
        }
        [sublayer setFrame:rect];
        [desktopImageLayer setFrame:desktopImageRect];
    }
}

@end
