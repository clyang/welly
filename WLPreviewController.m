//
//  XIPreviewController.m
//  Welly
//
//  Created by boost @ 9# on 7/15/08.
//  Copyright 2008 Xi Wang. All rights reserved.
//

#import "WLPreviewController.h"
#import "WLQuickLookBridge.h"
#import "WLGrowlBridge.h"
#import "WLGlobalConfig.h"

NSString *const WLGIFToHTMLFormat = @"<html><body bgcolor='Black'><center><img scalefit='1' style='position: absolute; top: 0; right: 0; bottom: 0; left: 0; height:100%%; margin: auto;' src='%@'></img></center></body></html>";

#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
@interface WLDownloadDelegate : NSObject <NSWindowDelegate> {
#else
@interface WLDownloadDelegate : NSObject {
#endif
    // This progress bar is restored by gtCarrera
    // boost: don't put it in XIPreviewController
    HMBlkProgressIndicator *_indicator;
    NSPanel         *_window;
    long long _contentLength, _transferredLength;
    NSString *_filename, *_path;
    NSURLDownload *_download;
}
@property(readwrite, assign) NSURLDownload *download;
- (void)showLoadingWindow;
@end

@implementation WLPreviewController

// current downloading URLs
static NSMutableSet *sURLs;
// current downloaded URLs
static NSMutableDictionary *sDownloadedURLInfo;
// Current init info
static BOOL sHasCacheDir = NO;

+ (void)initialize {
    sURLs = [[NSMutableSet alloc] initWithCapacity:10];
    // Check whether now the default Welly cache dir has been created
    // If not, create it
    if (!sHasCacheDir) {
        // Mark it as created
        sHasCacheDir = YES;
        // Get default cache dir
        NSString *cacheDir = [WLGlobalConfig cacheDirectory];
        // Create the dir
        NSFileManager *dirCheckerFileManager = [NSFileManager defaultManager];
        BOOL isDir;
        if(![dirCheckerFileManager fileExistsAtPath:cacheDir isDirectory:&isDir]) {
            if(![dirCheckerFileManager createDirectoryAtPath:cacheDir withIntermediateDirectories:YES attributes:nil error:NULL]) {
                // If error, report in console and roll back the flag
                NSLog(@"Error: Create folder failed %@", cacheDir);
                sHasCacheDir = NO;
            }
        }
    }
    sDownloadedURLInfo = [[NSMutableDictionary alloc] initWithCapacity:10];
}

- (IBAction)openPreview:(id)sender {
    [WLQuickLookBridge orderFront];
}

+ (NSURLDownload *)downloadWithURL:(NSURL *)URL {
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
        WLDownloadDelegate *delegate = [[WLDownloadDelegate alloc] init];
        download = [[NSURLDownload alloc] initWithRequest:request delegate:delegate];
        [delegate setDownload:download];
        [delegate release];
    }
    if (download == nil)
        [[NSWorkspace sharedWorkspace] openURL:URL];
    return download;
}

@end

#pragma mark -
#pragma mark XIDownloadDelegate

@implementation WLDownloadDelegate
@synthesize download = _download;

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
    float p = 0;
    if (_contentLength > 0)
        p = 100.0f * _transferredLength / _contentLength;
    return [NSString stringWithFormat:@"%1.1f%% (%@ of %@)", p,
        stringFromFileSize(_transferredLength),
        stringFromFileSize(_contentLength)];
}

- init {
    if ((self = [super init])) {
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
	
	[_download release];
    [super dealloc];
}

- (void)showLoadingWindow {
    unsigned int style = NSTitledWindowMask
        | NSMiniaturizableWindowMask | NSClosableWindowMask
        | NSDocModalWindowMask;

    // init
    _window = [[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, 400, 30)
                                         styleMask:style
                                           backing:NSBackingStoreBuffered 
                                             defer:NO];
    [_window setFloatingPanel:YES];
    [_window setDelegate:self];
    [_window setOpaque:YES];
    [_window center];
    [_window setTitle:@"Loading..."];
    [_window setViewsNeedDisplay:NO];
    [_window makeKeyAndOrderFront:nil];
	[[_window windowController] setDelegate:self];

    // Init progress bar
    _indicator = [[HMBlkProgressIndicator alloc] initWithFrame:NSMakeRect(10, 10, 380, 10)];
    [[_window contentView] addSubview:_indicator];
    [_indicator startAnimation:self];
}

// Window delegate for _window, finallize the download 
- (BOOL)windowShouldClose:(id)window {
    NSURL *URL = [[_download request] URL];
    // Show the canceled message
    [WLGrowlBridge notifyWithTitle:[URL absoluteString]
                       description:NSLocalizedString(@"Canceled", @"Download canceled")
                  notificationName:kGrowlNotificationNameFileTransfer
                          isSticky:NO
                        identifier:_download];
    // Remove current url from the url list
    [sURLs removeObject:URL];
    // Cancel the download
    [_download cancel];
	
	// Commented out by K.O.ed: Don't release here, release when the delegate dealloc.
	// Otherwise this would crash when cancelling a download
    // Release if necessary
    //[_download release];
    return YES;
}

- (void)downloadDidBegin:(NSURLDownload *)download {
    [WLGrowlBridge notifyWithTitle:[[[download request] URL] absoluteString]
                       description:NSLocalizedString(@"Connecting", @"Download begin")
                  notificationName:kGrowlNotificationNameFileTransfer
                          isSticky:YES
                        identifier:download];
}

- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response { 
    _contentLength = [response expectedContentLength];
    _transferredLength = 0;

    // extract & fix incorrectly encoded filename (GB18030 only)
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    _filename = [response suggestedFilename];
    NSData *data = [_filename dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES];
    NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    _filename = [[NSString alloc] initWithData:data encoding:encoding];
    [pool release];
    [WLGrowlBridge notifyWithTitle:_filename
                       description:[self stringFromTransfer]
                  notificationName:kGrowlNotificationNameFileTransfer
                          isSticky:YES
                        identifier:download];

    // set local path
    NSString *cacheDir = [WLGlobalConfig cacheDirectory];
    _path = [[cacheDir stringByAppendingPathComponent:_filename] retain];
	if([sDownloadedURLInfo objectForKey:[[[download request] URL] absoluteString]]) { // URL in cache
		// Get local file size
		NSString * tempPath = [sDownloadedURLInfo valueForKey:[[[download request] URL] absoluteString]];
		NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:tempPath error:nil];
		long long fileSizeOnDisk = -1;
		if (fileAttributes != nil)
			fileSizeOnDisk = [[fileAttributes objectForKey:NSFileSize] longLongValue];
		if(fileSizeOnDisk == _contentLength) { // If of the same size, use current cache
			[download cancel];
			[self downloadDidFinish:download];
			return;
		}
	}
    [download setDestination:_path allowOverwrite:YES];

	// dectect file type to avoid useless download
	// by gtCarrera @ 9#
	NSString *fileType = [[_filename pathExtension] lowercaseString];
	NSArray *allowedTypes = [NSArray arrayWithObjects:@"jpg", @"jpeg", @"bmp", @"png", @"gif", @"tiff", @"tif", @"pdf", nil];
	Boolean canView = [allowedTypes containsObject:fileType];
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
    [WLGrowlBridge notifyWithTitle:_filename
                       description:[self stringFromTransfer]
                  notificationName:kGrowlNotificationNameFileTransfer
                          isSticky:YES
                        identifier:download];
	// Add the incremented value
	[_indicator incrementBy:(double)length];
}

static void formatProps(NSMutableString *s, id *fmt, id *val) {
    for (; *fmt; ++fmt, ++val) {
        id obj = *val;
        if (obj == nil)
            continue;
        [s appendFormat:NSLocalizedString(*fmt, nil), obj];
    }
}

- (void)downloadDidFinish:(NSURLDownload *)download {
    [sURLs removeObject:[[download request] URL]];
	[sDownloadedURLInfo setValue:_path forKey:[[[download request] URL] absoluteString]];
	if ([[_path pathExtension] isEqualToString:@"gif"]) {
		NSURL *htmlURL = [NSURL fileURLWithPath:[[_path stringByDeletingPathExtension] stringByAppendingPathExtension:@"html"]];
		[[NSString stringWithFormat:WLGIFToHTMLFormat, [NSURL fileURLWithPath:_path]] writeToURL:htmlURL atomically:NO encoding:NSUTF8StringEncoding error:NULL];
		[WLQuickLookBridge add:htmlURL];
	} else {
		[WLQuickLookBridge add:[NSURL fileURLWithPath:_path]];
	}
    [WLGrowlBridge notifyWithTitle:_filename
                       description:NSLocalizedString(@"Completed", "Download completed; will open previewer")
                  notificationName:kGrowlNotificationNameFileTransfer
                          isSticky:NO
                        identifier:download];

    // For read exif info by gtCarrera
    // boost: pool (leaks), check nil (crash), readable values
    CGImageSourceRef exifSource = CGImageSourceCreateWithURL((CFURLRef)([NSURL fileURLWithPath:_path]), nil);
    if (exifSource) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSDictionary *metaData = (NSDictionary*) CGImageSourceCopyPropertiesAtIndex(exifSource, 0, nil);
		[metaData autorelease];
		NSMutableString *props = [NSMutableString string];
        NSDictionary *exifData = [metaData objectForKey:(NSString *)kCGImagePropertyExifDictionary];
		if (exifData) {
            NSString *dateTime = [exifData objectForKey:(NSString *)kCGImagePropertyExifDateTimeOriginal];
            NSNumber *eTime = [exifData objectForKey:(NSString *)kCGImagePropertyExifExposureTime];
            NSNumber *fLength = [exifData objectForKey:(NSString *)kCGImagePropertyExifFocalLength];
            NSNumber *fNumber = [exifData objectForKey:(NSString *)kCGImagePropertyExifFNumber];
            NSArray *isoArray = [exifData objectForKey:(NSString *)kCGImagePropertyExifISOSpeedRatings];
            // readable exposure time
            NSString *eTimeStr = nil;
            if (eTime) {
                double eTimeVal = [eTime doubleValue];
                // zero exposure time...
                if (eTimeVal < 1 && eTimeVal != 0) {
                    eTimeStr = [NSString stringWithFormat:@"1/%g", 1/eTimeVal];
                } else
                    eTimeStr = [eTime stringValue];
            }
            // iso
            NSNumber *iso = nil;
            if (isoArray && [isoArray count])
                iso = [isoArray objectAtIndex:0];
            // format
            id keys[] = {@"Original Date Time", @"Exposure Time", @"Focal Length", @"F Number", @"ISO", nil};
            id vals[] = {dateTime, eTimeStr, fLength, fNumber, iso};
            formatProps(props, keys,vals);
        }

        NSDictionary *tiffData = [metaData objectForKey:(NSString *)kCGImagePropertyTIFFDictionary];
        if (tiffData) {
            NSString *makeName = [tiffData objectForKey:(NSString *)kCGImagePropertyTIFFMake];
            NSString *modelName = [tiffData objectForKey:(NSString *)kCGImagePropertyTIFFModel];
            // some photos give null names
            if (makeName || modelName)
                [props appendFormat:NSLocalizedString(@"tiffStringFormat", "\nManufacturer and Model: \n%@ %@"), makeName, modelName];
        }

        if([props length]) 
            [WLGrowlBridge notifyWithTitle:_filename
                               description:props
                          notificationName:kGrowlNotificationNameEXIFInformation
                                  isSticky:NO
                                identifier:download];
        // release
        [pool release];
        CFRelease(exifSource);
    }

	// Commented out by K.O.ed: Don't release here, release when the delegate dealloc.
    //[download release];
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error {
    NSURL *URL = [[download request] URL];
    [sURLs removeObject:URL];
    [[NSWorkspace sharedWorkspace] openURL:URL];
    [WLGrowlBridge notifyWithTitle:[URL absoluteString]
                       description:NSLocalizedString(@"Opening browser", "Download failed or unsupported formats")
                  notificationName:kGrowlNotificationNameFileTransfer
                          isSticky:NO
                        identifier:download];
	// Commented out by K.O.ed: Don't release here, release when the delegate dealloc.
    //[download release];
}

@end
