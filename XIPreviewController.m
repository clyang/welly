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
    // This progress bar is restored by gtCarrera
    // boost: don't put it in XIPreviewController
    HMBlkProgressIndicator *_indicator;
    NSPanel         *_window;
    long long _contentLength, _transferredLength;
    NSString *_filename, *_path;
}
- (void)showLoadingWindow;
@end

@implementation XIPreviewController

// current downloading URLs
static NSMutableSet *sURLs;
static NSString *sCacheDir;

+ (void)initialize {
    sURLs = [[NSMutableSet alloc] initWithCapacity:10];
    // locate the cache directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSAssert([paths count] > 0, @"~/Library/Caches");
    sCacheDir = [[[paths objectAtIndex:0] stringByAppendingPathComponent:@"Welly"] retain];
    // clean it at startup
    BOOL flag = NO;
    int pid = [[NSProcessInfo processInfo] processIdentifier];
    // detect if another Welly exists
    for (NSDictionary *dict in [[NSWorkspace sharedWorkspace] launchedApplications]) {
        if ([[dict objectForKey:@"NSApplicationName"] isEqual:@"Welly"] &&
            [[dict objectForKey:@"NSApplicationProcessIdentifier"] intValue] != pid) {
            flag = YES;
            break;
        }
    }
    // no other Welly
    if (!flag)
        [[NSFileManager defaultManager] removeFileAtPath:sCacheDir handler:nil];
}

- (IBAction)openPreview:(id)sender {
    [XIQuickLookBridge orderFront];
}

+ (NSURLDownload *)dowloadWithURL:(NSURL *)URL {
    // already downloading
    if ([sURLs containsObject:URL])
        return nil;
    // check validity
    NSURLDownload *download;
    NSString *s = [URL absoluteString];
    NSString *suffix = [[s componentsSeparatedByString:@"."] lastObject];
    NSArray *suffixes = [NSArray arrayWithObjects:@"htm", @"html", @"shtml", @"com", @"net", @"org", nil];
    if ([s hasSuffix:@"/"] || [suffixes containsObject:suffix])
        download = nil;
    else {
		// Here, if a download is necessary, show the download window
        [sURLs addObject:URL];
        NSURLRequest *request = [NSURLRequest requestWithURL:URL
                                                 cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                             timeoutInterval:30.0];
        XIDownloadDelegate *delegate = [[XIDownloadDelegate alloc] init];
        download = [[NSURLDownload alloc] initWithRequest:request delegate:delegate];
        [delegate release];
    }
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
	if (size < 1023) {
        if (size > 1)
            fmt = @"%i bytes";
        else
            fmt = @"%i byte";
    }
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

- init {
    if (self = [super init]) {
        [self showLoadingWindow];
    }
    return self;
}

- (void)dealloc {
    [_filename release];
    [_path release];
    // close window
    [_window close];
    [_indicator release];
    [_window release];
    [super dealloc];
}

- (void)showLoadingWindow
{
    unsigned int style = NSTitledWindowMask
        | NSMiniaturizableWindowMask | NSClosableWindowMask
        | NSHUDWindowMask | NSUtilityWindowMask;

    // init
    _window = [[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, 400, 30)
                                         styleMask:style
                                           backing:NSBackingStoreBuffered 
                                             defer:NO];
    [_window setFloatingPanel:NO];
    [_window setDelegate:self];
    [_window setOpaque:YES];
    [_window center];
    [_window setTitle:@"Loading..."];
    [_window setViewsNeedDisplay:NO];
    [_window makeKeyAndOrderFront:nil];

    // Init progress bar
    _indicator = [[HMBlkProgressIndicator alloc] initWithFrame:NSMakeRect(10, 10, 380, 10)];
    [[_window contentView] addSubview:_indicator];
    [_indicator startAnimation:self];
}

- (void)downloadDidBegin:(NSURLDownload *)download {
    [TYGrowlBridge notifyWithTitle:[[[download request] URL] absoluteString]
                       description:NSLocalizedString(@"Connecting", @"Download begin")
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
    [[NSFileManager defaultManager] createDirectoryAtPath:sCacheDir attributes:nil];
    _path = [[sCacheDir stringByAppendingPathComponent:_filename] retain];
    [download setDestination:_path allowOverwrite:YES];

	// dectect file type to avoid useless download
	// by gtCarrera @ 9#
	NSString *fileType = [[_filename pathExtension] lowercaseString];
	NSArray *allowedTypes = [NSArray arrayWithObjects:@"jpg", @"jpeg", @"bmp", @"png", @"gif", @"tiff", @"tif", @"pdf", nil];
	Boolean canView = [allowedTypes containsObject: fileType];
	if (!canView) {
		// Close the progress bar window
		[_window close];
		
        [self retain]; // "didFailWithError" may release the delegate
        [download cancel];
        [self download:download didFailWithError:nil];
        [self release];
        return; // or next may crash
	}

    // Or, set the window to show the download progress
    [_window setTitle:[NSString stringWithFormat:@"Loading %@...", _filename]];
    [_indicator setIndeterminate:NO];
    [_indicator setMaxValue:(double)_contentLength];
    [_indicator setDoubleValue:0];
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(NSUInteger)length { 
    _transferredLength += length;
    [TYGrowlBridge notifyWithTitle:_filename
                       description:[self stringFromTransfer]
                  notificationName:@"File Transfer"
                          isSticky:YES
                        identifier:download];
	// Add the incremented value
	[_indicator incrementBy: (double)length];
}

- (void)downloadDidFinish:(NSURLDownload *)download {
    [sURLs removeObject:[[download request] URL]];
    [XIQuickLookBridge add:[NSURL fileURLWithPath:_path]];
    [TYGrowlBridge notifyWithTitle:_filename
                       description:NSLocalizedString(@"Completed", "Download completed; will open previewer")
                  notificationName:@"File Transfer"
                          isSticky:NO
                        identifier:download];

    // For read exif info by gtCarrera
    // boost: pool (leaks), check nil (crash), readable values
    CGImageSourceRef exifSource = CGImageSourceCreateWithURL((CFURLRef)([NSURL fileURLWithPath:_path]), nil);
    if (exifSource) {
        NSDictionary *metaData = (NSDictionary*) CGImageSourceCopyPropertiesAtIndex(exifSource, 0, nil);
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

        NSString *exifString = @"";
        NSDictionary *exifData = [metaData objectForKey:(NSString *)kCGImagePropertyExifDictionary];
        if (exifData) {
            NSString *dateTime = [exifData objectForKey:(NSString *)kCGImagePropertyExifDateTimeOriginal];
            NSNumber *eTime = [exifData objectForKey:(NSString *)kCGImagePropertyExifExposureTime];
            NSNumber *fLength = [exifData objectForKey:(NSString *)kCGImagePropertyExifFocalLength];
            NSNumber *fNumber = [exifData objectForKey:(NSString *)kCGImagePropertyExifFNumber];
            // readable exposure time
            NSString *eTimeStr;
            double eTimeVal = [eTime doubleValue];
            if (eTimeVal < 1) {
                eTimeStr = [NSString stringWithFormat:@"1/%g", 1/eTimeVal];
            } else
                eTimeStr = [eTime stringValue];
            exifString = [NSString stringWithFormat:
                          NSLocalizedString(@"exifStringFormat", 
                                            "Original Date Time: %@\n\nExposure Time: %@ s\nFocal Length%@ mm\nf-Number: %@\n"), 
                          dateTime, eTimeStr, fLength, fNumber];
        }

        NSString *tiffString = @"";
        NSDictionary *tiffData = [metaData objectForKey:(NSString *)kCGImagePropertyTIFFDictionary];
        if (tiffData) {
            NSString *makeName = [tiffData objectForKey:(NSString *)kCGImagePropertyTIFFMake];
            NSString *modelName = [tiffData objectForKey:(NSString *)kCGImagePropertyTIFFModel];
            tiffString = [NSString stringWithFormat:
                          NSLocalizedString(@"tiffStringFormat", 
                                            "\nManufacturer and Model: \n%@ %@"), 
                          makeName, modelName];
        }

        NSString *content = [exifString stringByAppendingString:tiffString];
        if([content length]) 
            [TYGrowlBridge notifyWithTitle:_filename
                               description:content
                          notificationName:@"File Transfer"
                                  isSticky:NO
                                identifier:download];
        // release
        [pool release];
        CFRelease(exifSource);
    }

    [download release];
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error {
    NSURL *URL = [[download request] URL];
    [sURLs removeObject:URL];
    [[NSWorkspace sharedWorkspace] openURL:URL];
    [TYGrowlBridge notifyWithTitle:[URL absoluteString]
                       description:NSLocalizedString(@"Opening browser", "Download failed or unsupported formats")
                  notificationName:@"File Transfer"
                          isSticky:NO
                        identifier:download];
    [download release];
}

@end
