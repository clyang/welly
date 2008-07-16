//
//  XIPreviewController.m
//  Welly
//
//  Created by boost @ 9# on 7/15/08.
//  Copyright 2008 Xi Wang. All rights reserved.
//

#import "XIPreviewController.h"
#import "XIQuickLookBridge.h"
#import "TYGrowlBridge.h"

@interface XIDownloadDelegate : NSObject {
    long long _contentLength, _transferredLength;
    NSString *_filename, *_path;
}
@end

@implementation XIPreviewController

- (IBAction)openPreview:(id)sender {
    [XIQuickLookBridge orderFront];
}

+ (NSURLDownload *)dowloadWithURL:(NSURL *)URL {
    NSURLRequest *request = [NSURLRequest requestWithURL:URL
                                             cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                         timeoutInterval:30.0];
    XIDownloadDelegate *delegate = [[XIDownloadDelegate new] autorelease];
    NSURLDownload *download = [[NSURLDownload alloc] initWithRequest:request delegate:delegate];
    if (download == nil)
        [[NSWorkspace sharedWorkspace] openURL:URL];
    return download;
}

@end

#pragma mark -
#pragma mark XIDownloadDelegate

@implementation XIDownloadDelegate

static NSString * stringFromFileSize(long long size) {
    NSString *fmt;
    float fsize = size;
	if (size < 1023)
		fmt = @"%i bytes";
    else {
        fsize /= 1024;
        if (fsize < 1023)
            fmt = @"%1.1f KB";
        else {
            fsize /= 1024;
            if (fsize < 1023)
                fmt = @"%1.1f MB";
            else {
                fsize /= 1024;
                fmt = @"%1.1f GB";
            }
        }
    }
    return [NSString stringWithFormat:fmt, fsize];
}

- (NSString *)stringFromTransfer {
    float p = 100.0f * _transferredLength / _contentLength;
    return [NSString stringWithFormat:@"%1.1f%% (%@ of %@)", p,
        stringFromFileSize(_transferredLength),
        stringFromFileSize(_contentLength)];
}

- (void)dealloc {
    [_filename release];
    [_path release];
    [super dealloc];
}

- (void)downloadDidBegin:(NSURLDownload *)download {
    [TYGrowlBridge notifyWithTitle:[[[download request] URL] host]
                       description:@"Connecting"
                  notificationName:@"File Transfer"
                          isSticky:YES
                        identifier:download];
}

- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response { 
    _contentLength = [response expectedContentLength];
    _transferredLength = 0;

    // extract & fix incorrectly encoded filename (GB18030 only)
    _filename = [response suggestedFilename];
    NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    int length = [_filename length];
    char data[length+1];
    data[length] = 0;
    // drop the byte
    for (int i = 0; i < length; i++)
        data[i] = (char)[_filename characterAtIndex:i];
    _filename = [[NSString stringWithCString:data encoding:encoding] retain];
    [TYGrowlBridge notifyWithTitle:_filename
                       description:[self stringFromTransfer]
                  notificationName:@"File Transfer"
                          isSticky:YES
                        identifier:download];

    // set local path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSAssert([paths count] > 0, @"~/Library/Caches");
    NSString *cacheDir = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Welly"];
    [[NSFileManager defaultManager] createDirectoryAtPath:cacheDir attributes:nil];
    _path = [[cacheDir stringByAppendingPathComponent:_filename] retain];
    [download setDestination:_path allowOverwrite:YES];

	// dectect file type to avoid useless download
	// by gtCarrera @ 9#
	NSString *fileType = [[_filename pathExtension] lowercaseString];
	NSArray *allowedTypes = [NSArray arrayWithObjects: @"jpg", @"bmp", @"png", @"gif", @"tiff", @"pdf", nil];
	Boolean canView = [allowedTypes containsObject: fileType];
	if (!canView) {
        [download cancel];
        [self download:download didFailWithError:nil]; 
	}
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(NSUInteger)length { 
    _transferredLength += length;
    [TYGrowlBridge notifyWithTitle:_filename
                       description:[self stringFromTransfer]
                  notificationName:@"File Transfer"
                          isSticky:YES
                        identifier:download];
}

- (void)downloadDidFinish:(NSURLDownload *)download {
    [XIQuickLookBridge add:[NSURL fileURLWithPath:_path]];
    [TYGrowlBridge notifyWithTitle:_filename
                       description:@"Completed"
                  notificationName:@"File Transfer"
                          isSticky:NO
                        identifier:download];
    [download autorelease];
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error {
    [[NSWorkspace sharedWorkspace] openURL:[[download request] URL]];
    [TYGrowlBridge notifyWithTitle:_filename
                       description:@"Failed"
                  notificationName:@"File Transfer"
                          isSticky:NO
                        identifier:download];
    [download autorelease];
}

@end
