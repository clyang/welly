//
//  YLImagePreviewer.m
//  MacBlueTelnet
//
//  Created by Jjgod Jiang on 2/17/08.
//  Copyright 2008 Jjgod Jiang. All rights reserved.

//  Modified by gtCarrera @ 9# & boost @ 9#
//  bug fixes and Quick Look support.
//  July 2008.

#import "CommonType.h"
#import "YLSite.h"
#import "YLImagePreviewer.h"
#import "XIQuickLookDelegate.h"

@implementation YLImagePreviewer

- (id) initWithURL: (NSURL *) url
{
    if ([super init])
    {
        // create the request
		_currentURL = url;
        NSURLRequest *request = [NSURLRequest requestWithURL: url
                                                 cachePolicy: NSURLRequestReturnCacheDataElseLoad
                                             timeoutInterval: 60.0];
        
        // download the data
        _download = [[NSURLDownload alloc] initWithRequest: request 
                                           delegate: self];
        if (_download) {
            [self showLoadingWindow];
        } else {
            // inform the user that the download could not be made
            NSLog(@"inform the user that the download could not be made");
            [self showBrowser];
        }        
    }
    
    return self;
}

- (void) dealloc
{
    // NSLog(@"dealloc everything in YLImagePreviewer");
    
    // if we are still connecting, should cancel now and release
    // related resource.
    if (_download) {
        [_download cancel];
        [_download release];
        _download = nil;
    }

    if (_window) {
        [_window release];
        _window = nil;
    }
    
    if (_currentFileDownloading) {
        [_currentFileDownloading release];
        _currentFileDownloading = nil;
    }

    [super dealloc];
}

- (void) windowWillClose: (NSNotification *) notification
{
    if ([_window isReleasedWhenClosed])
        _window = nil;
    
    [self autorelease];
}

- (void) showLoadingWindow
{
    unsigned int style = NSTitledWindowMask | 
        NSMiniaturizableWindowMask | NSClosableWindowMask | 
        NSHUDWindowMask | NSUtilityWindowMask;
    _window = [[NSPanel alloc] initWithContentRect: NSMakeRect(0, 0, 400, 30)
                                         styleMask: style
                                           backing: NSBackingStoreBuffered 
                                             defer: NO];
   // [_window setFloatingPanel: NO];
    [_window setDelegate: self];
    [_window setOpaque: YES];
    [_window center];
    [_window setTitle: @"Loading..."];
    [_window setViewsNeedDisplay: NO];
    [_window makeKeyAndOrderFront: nil];
	[_window setLevel:kCGStatusWindowLevel+1];
    
    _indicator = [[HMBlkProgressIndicator alloc] initWithFrame: NSMakeRect(10, 10, 380, 10)];
    [[_window contentView] addSubview: _indicator];

    [_indicator startAnimation: self];
    [_indicator setIndeterminate: NO];
    [_indicator setDoubleValue: 0];
}

NSStringEncoding encodingFromYLEncoding(YLEncoding ylenc)
{
    CFStringEncoding cfenc;
    
    switch (ylenc)
    {
        case YLGBKEncoding:
            cfenc = kCFStringEncodingGB_18030_2000;
            break;
            
        case YLBig5Encoding:
            cfenc = kCFStringEncodingBig5_E;
            break;
    }
    
    return CFStringConvertEncodingToNSStringEncoding(cfenc);
}

- (void) download: (NSURLDownload *) download 
         didReceiveResponse: (NSURLResponse *) response
{ 
    _totalLength = [response expectedContentLength];
    [_indicator setMaxValue: (double) _totalLength];
}

- (void) download: (NSURLDownload *) download 
         didReceiveDataOfLength: (unsigned) length
{ 
    [_indicator incrementBy: (double) length];
}

- (void) download: (NSURLDownload *) download
         decideDestinationWithSuggestedFilename: (NSString *) filename
{
    // this method is called when download has determined a suggested filename

    // fix incorrectly encoded filename
    int max = [filename length];
    char *nbytes = (char *) malloc(max + 1);
    for (int i = 0; i < max; i++) {
        unichar ch = [filename characterAtIndex: i];
        nbytes[i] = (char) ch;
    }
    nbytes[max] = '\0';
    NSStringEncoding enc = encodingFromYLEncoding(YLGBKEncoding);
    _currentFileDownloading = [NSString stringWithCString: nbytes encoding: enc];
    free(nbytes);
    
    // prepare for downloading
    [_window setTitle: [NSString stringWithFormat: @"Loading %@...", _currentFileDownloading]];

    NSString *cacheDir = [NSHomeDirectory() stringByAppendingPathComponent: @"Library/Caches/Welly"];
    [[NSFileManager defaultManager] createDirectoryAtPath: cacheDir attributes: nil];
    _currentFileDownloading = [[cacheDir stringByAppendingPathComponent: _currentFileDownloading] retain];
    [download setDestination: _currentFileDownloading allowOverwrite: YES];

	// Try to dectect the file type
	// Avoid useless download
	// By gtCarrera @ 9#
	// Modified by boost @ 9#
	fileType = [_currentFileDownloading substringFromIndex: [_currentFileDownloading length] - 3];
	fileType = [fileType lowercaseString];
	NSArray *allowedTypes = [NSArray arrayWithObjects: @"jpg", @"bmp", @"png", @"gif", @"tiff", @"pdf", nil];
	Boolean canView = [allowedTypes containsObject: fileType];
	if (!canView) {
        [download cancel];
        [self showBrowser];
	}
}

- (void) download: (NSURLDownload *) download
         didFailWithError: (NSError *) error
{
    // inform the user
    NSLog(@"Download failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey: NSErrorFailingURLStringKey]);

    [self showBrowser];
}

- (void) downloadDidFinish: (NSURLDownload *) download
{
    // update URLs for quick look
    NSURL *URL = [NSURL fileURLWithPath:_currentFileDownloading];
    [[XIQuickLookDelegate sharedPanel] add:URL];
    // end
    [_window close];
}

- (void) showBrowser
{
    [[NSWorkspace sharedWorkspace] openURL: _currentURL];
    if (_window)
        [_window close];
}

@end
