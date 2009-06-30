// modified by boost @ 9#

/* CovertFlow - DesktopImage.m
 *
 * Abstract: The DesktopImage object represents an individual desktop image.
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

#import "PortalImage.h"

#import "WLPortal.h"

#import <pthread.h>
#import <QuartzCore/QuartzCore.h>

NSString *desktopImageImageDidLoadNotification = @"desktopImageImageDidLoadNotification";

@implementation PortalImage
@synthesize name = _name;
@synthesize path = _path;

- (id)initWithPath:(NSString *)path isExist:(BOOL)exist {
    self = [super init];
    if (self == nil)
        return nil;
    _path = [path copy];
    if(exist)
		_name = [[[path lastPathComponent] stringByDeletingPathExtension] copy];
	else
		_name = [path copy];
	//NSLog(@"_name = %@", path);
    return self;
}

- (void)dealloc {
    [_name release];
    [_path release];
    CGImageRelease(_image);
    [super dealloc];
}

- (CGImageRef)imageOfSize:(CGSize)sz {
    @synchronized (self) {
        if (_image == NULL || CGImageGetWidth (_image) != sz.width || CGImageGetHeight (_image) != sz.height)
            return NULL;
        return CGImageRetain(_image);
    }
    return NULL;
}

static pthread_t thread;
static pthread_mutex_t imageMutex = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t imageCond = PTHREAD_COND_INITIALIZER;
static NSMutableArray *imageQueue;

// asynchronously read images
static void * imageThread (void *arg) {
    while (1) {
        pthread_mutex_lock(&imageMutex);

        while ([imageQueue count] == 0)
            pthread_cond_wait(&imageCond, &imageMutex);

        PortalImage *desktopImage = [[imageQueue objectAtIndex:0] retain];
        [imageQueue removeObjectAtIndex:0];

        pthread_mutex_unlock(&imageMutex);
        
        // load in the next image
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSString *path = [desktopImage path];
        NSURL *url = [NSURL fileURLWithPath:path];
        CGImageSourceRef isr = CGImageSourceCreateWithURL((CFURLRef)url, NULL);
        if (isr == NULL)
            isr = CGImageSourceCreateWithData((CFDataRef)[[NSImage imageNamed:@"default_site.png"] TIFFRepresentation], NULL);
        CGImageRef image = NULL;
        if (isr) {
            image = CGImageSourceCreateImageAtIndex(isr, 0, NULL);
            CFRelease(isr);
        }

        // redraw the image the correct size
        CGRect r;
        @synchronized (desktopImage) {
            r.origin = CGPointZero;
            r.size = desktopImage->_imageSize;
        }
        //CGImageAlphaInfo alpha = (image != NULL ? kCGImageAlphaNoneSkipFirst : kCGImageAlphaPremultipliedFirst);
        CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
        CGContextRef ctx = CGBitmapContextCreate(NULL, r.size.width, r.size.height, 8, 0, space,
                                                     kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Host);
        CGColorSpaceRelease(space);
        if (ctx == NULL)
            break;

        CGContextSetInterpolationQuality(ctx, kCGInterpolationHigh);
        // draw the frame
        CGContextSetFillColorWithColor(ctx, [WLPortal color:3]);
        CGContextFillRect(ctx, r);
        CGContextSetStrokeColorWithColor(ctx, [WLPortal color:0]);
        CGContextStrokeRect(ctx, r);

        { //if (image) {
            CGFloat w0 = CGImageGetWidth(image), h0 = CGImageGetHeight(image);
            CGFloat w = r.size.width, h = r.size.height;
            if (w0 / h0 < w / h) {
                r.size.width = w0 * h / h0;
                r.origin.x = (w - r.size.width) / 2;
            } else {
                CGFloat h = r.size.height;
                r.size.height = h0 * w / w0;
                r.origin.y = (h - r.size.height) / 2;
            }
            CGContextDrawImage(ctx, r, image);
            CGImageRelease(image);
        //} else {
        }
        CGContextFlush(ctx);
        CGImageRef scaledImage = CGBitmapContextCreateImage(ctx);
        CGContextRelease(ctx);
            
        @synchronized (desktopImage) {
            CGImageRelease(desktopImage->_image);
            desktopImage->_image = scaledImage;
            desktopImage->_requestedImage = false;
        }
        
        // let the controller know we've got a new image loaded
        [desktopImage performSelectorOnMainThread:@selector(postNotificationName:)
        withObject:desktopImageImageDidLoadNotification waitUntilDone:NO];

        [desktopImage release];
        [pool release];
    }
    
    pthread_mutex_unlock (&imageMutex);

    thread = 0;
    return NULL;
}

- (void)postNotificationName:(NSString *)n {
    [[NSNotificationCenter defaultCenter] postNotificationName:n object:self];
}

- (bool)requestImageOfSize:(CGSize)size; {
    if (_imageFailed)
    return false;
    
    @synchronized (self) {
        _markedImage = true;
        
        if (_image != nil && CGSizeEqualToSize(size, _imageSize)) {
            [self postNotificationName:desktopImageImageDidLoadNotification];
        } else {
            _imageSize = size;
            
            if (!_requestedImage) {
                pthread_mutex_lock(&imageMutex);
                
                if (imageQueue == nil)
                    imageQueue = [[NSMutableArray alloc] init];
                
                if (thread == 0) {
                    pthread_attr_t attr;
                    pthread_attr_init(&attr);
                    pthread_attr_setscope(&attr, PTHREAD_SCOPE_SYSTEM);
                    pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
                    pthread_create(&thread, &attr, imageThread, NULL);
                    pthread_attr_destroy(&attr);
                }
                
                [imageQueue addObject:self];
                
                pthread_cond_signal(&imageCond);
                pthread_mutex_unlock(&imageMutex);
            }
        }
    }
    
    return true;
}

- (bool)exists {
    return [[NSFileManager defaultManager] fileExistsAtPath:_path];
}

+ (void)sweepImageQueue {
    if (imageQueue == nil)
        return;

    pthread_mutex_lock (&imageMutex);

    size_t count = [imageQueue count];
    for (size_t i = 0; i < count;) {
        PortalImage *desktopImage = [imageQueue objectAtIndex:i];
        if (!desktopImage->_markedImage) {
            [imageQueue removeObjectAtIndex:i];
            count--;
        } else
            i++;
        desktopImage->_markedImage = false;
    }

    pthread_mutex_unlock (&imageMutex);
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<PortalImage: %p; %@>", self, [self name]];
}

@end
