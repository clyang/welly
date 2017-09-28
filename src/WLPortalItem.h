//
//  WLPortalItem.h
//  Welly
//
//  Created by K.O.ed on 10-4-17.
//  Copyright 2010 Welly Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol WLPortalSource

- (NSImage *)image;
- (void)didSelect:(id)sender;

@end

@protocol WLDraggingSource

- (BOOL)acceptsDragging;
- (NSImage *)draggingImage;
- (NSPasteboard *)draggingPasteboard;
- (void)draggedToRemove:(id)sender;

@end

@protocol WLPasteboardReceiver

- (BOOL)acceptsPBoard:(NSPasteboard *)pboard;
- (BOOL)didReceivePBoard:(NSPasteboard *)pboard;

@end



@interface WLPortalItem : NSObject <WLPortalSource> {
    NSString *_title;
    NSImage  *_image;
}

@property (readonly) NSString *imageTitle;
@property (readonly) NSImage *image;

- (id)initWithTitle:(NSString *)title;
- (id)initWithImage:(NSImage *)theImage;
- (id)initWithImage:(NSImage *)theImage title:(NSString *)title;

#pragma mark -
#pragma mark IKImageBrowserItem protocol
- (NSString *)imageUID;
- (NSString *)imageRepresentationType;
- (id)imageRepresentation;
- (NSString *)imageTitle;

#pragma mark -
#pragma mark WLPortalSource protocol
- (void)didSelect:(id)sender;
@end
