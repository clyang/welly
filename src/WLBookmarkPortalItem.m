//
//  WLPortalImage.m
//  Welly
//
//  Created by boost on 9/6/2009.
//  Copyright 2009 Xi Wang. All rights reserved.
//

#import <Quartz/Quartz.h>
#import "WLBookmarkPortalItem.h"
#import "WLSite.h"
#import "WLMainFrameController.h"
@implementation WLBookmarkPortalItem
@synthesize path = _path;
@synthesize site = _site;

#pragma mark -
#pragma mark Init & dealloc
- (id)initWithSite:(WLSite *)site {
	if (self = [self init]) {
		[self setSite:site];
	}
	return self;
}

- (id)initWithPath:(NSString *)path 
			 title:(NSString *)title {
	self = [super initWithTitle:title];
    if (self) {
		[self setPath:path];
	}
    return self;
}

- (void)dealloc {
	[_site release];
    [_path release];
    [super dealloc];
}

#pragma mark -
#pragma mark Site Cover related
+ (NSString*)directoryForSiteCovers {
    static NSString *sCoverDir = nil;
    if (sCoverDir == nil) {
        NSFileManager *fileMgr = [NSFileManager defaultManager];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
        NSAssert([paths count] > 0, @"~/Library/Application Support");
        NSString *dir = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Welly"];
        [fileMgr createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
        sCoverDir = [[dir stringByAppendingPathComponent:@"Covers"] retain];
        [fileMgr createDirectoryAtPath:sCoverDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return sCoverDir;
}

- (void)loadCover {
	if (!_site)
		return;
	NSString *siteName = [_site name];
	if ([siteName length] == 0)
		return;
	// guess the image file name
	NSArray *paths = nil;
    NSString *dir = [[self class] directoryForSiteCovers];
	[[[dir stringByAppendingPathComponent:siteName] stringByAppendingString:@"."]
	 completePathIntoString:nil caseSensitive:NO matchesIntoArray:&paths filterTypes:nil];
	NSString *path = nil;
	if ([paths count])
		path = [paths objectAtIndex:0];
	[self setPath:path];
}

- (BOOL)setCoverWithFile:(NSString *)src {
	NSFileManager *fileMgr = [NSFileManager defaultManager];
    // remove the original one
    if (_path)
        [fileMgr removeItemAtPath:_path error:nil];
	
    NSString *dst = nil;
    if (src) {
        NSString *dir = [[self class] directoryForSiteCovers];
        dst = [[dir stringByAppendingPathComponent:_title] stringByAppendingPathExtension:[src pathExtension]];
        // try to clean up dst first
        [fileMgr removeItemAtPath:dst error:nil];
        NSError *error = nil;
        // copy
        [fileMgr copyItemAtPath:src toPath:dst error:&error];
        if (error) {
            [NSApp presentError:error];
            return NO;
        }
    }
	
    // update
    [self setPath:dst];
	return YES;
}

#pragma mark -
#pragma mark Accessor
- (void)setPath:(NSString *)path {
	[_path release];	
	[_image release];
    _path = [path copy];
    if (_path)
        _image = [[NSImage alloc] initByReferencingFile:_path];
    else
        _image = nil;
}

- (void)setSite:(WLSite *)site {
	[_site release];
	_site = [site retain];
	_title = [_site name];
	[self loadCover];
}

#pragma mark -
#pragma mark Override
- (void)didSelect:(id)sender {
	WLMainFrameController *controller = [WLMainFrameController sharedInstance];
    [controller newConnectionWithSite:_site];
}

#pragma mark -
#pragma mark WLPBoardReceiver protocol
- (BOOL)acceptsPBoard:(NSPasteboard *)pboard {
	if (![[pboard types] containsObject:NSFilenamesPboardType])
		return NO;
	
    id files = [pboard propertyListForType:NSFilenamesPboardType];
    // only one file supported
    if ([files count] != 1)
        return NO;
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSString *path = [files objectAtIndex:0];
    BOOL isDir;
    if (![fileMgr fileExistsAtPath:path isDirectory:&isDir] || isDir)
        return NO;
    if (![fileMgr isReadableFileAtPath:path])
        return NO;
    return YES;
}

- (BOOL)didReceivePBoard:(NSPasteboard *)pboard {
	if (![self acceptsPBoard:pboard])
		return NO;
	
    id files = [pboard propertyListForType:NSFilenamesPboardType];
    NSString *src = [files objectAtIndex:0];
	return [self setCoverWithFile:src];
}

#pragma mark -
#pragma mark WLDraggingSource protocol
- (BOOL)acceptsDragging {
    // Do not allow to drag & drop default image
	if (!_path)
		return NO;
	return YES;
}

- (NSImage *)draggingImage {
	return [[NSWorkspace sharedWorkspace] iconForFile:_path];
}

- (NSPasteboard *)draggingPasteboard {
	NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
    [pboard declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType] owner:nil];
    [pboard setString:_path forType:NSFilenamesPboardType];
	return pboard;
}

- (void)draggedToRemove:(id)sender {
	NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Are you sure you want to delete the cover?", @"Sheet Title")
                                     defaultButton:NSLocalizedString(@"Delete", @"Default Button")
                                   alternateButton:NSLocalizedString(@"Cancel", @"Cancel Button")
                                       otherButton:nil
                         informativeTextWithFormat:NSLocalizedString(@"Welly will delete this cover file, please confirm.", @"Sheet Message")];
    if ([alert runModal] == NSAlertDefaultReturn)
        [self setCoverWithFile:nil];
}
@end
