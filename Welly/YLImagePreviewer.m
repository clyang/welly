//
//  YLImagePreviewer.m
//  MacBlueTelnet
//
//  Created by Jjgod Jiang on 2/17/08.
//  Copyright 2008 Jjgod Jiang. All rights reserved.
//

#import "CommonType.h"
#import "YLSite.h"
#import "YLImagePreviewer.h"
#import "YLGrowlDelegate.h"
#import "GTShowImageFacade.h"
#import <PDFKit/PDFDocument.h>

@implementation YLImagePreviewer

- (id) initWithURL: (NSURL *) url
{
    if ([super init])
    {
        // create the request
		_currentURL = url;
        NSURLRequest *request = [NSURLRequest requestWithURL: url
                                                 cachePolicy: NSURLRequestUseProtocolCachePolicy
                                             timeoutInterval: 60.0];
        
        // create the connection with the request
        // and start loading the data
        _connection = [[NSURLConnection alloc] initWithRequest: request 
                                                      delegate: self];
        if (_connection)
        {
            // Create the NSMutableData that will hold
            // the received data
            // receivedData is declared as a method instance elsewhere
            _receivedData = [[NSMutableData data] retain];
            
            [self showLoadingWindow];
        } else {
            // inform the user that the download could not be made
            NSLog(@"inform the user that the download could not be made");
        }        
    }
    
    return self;
}

- (void) dealloc
{
    // NSLog(@"dealloc everything in YLImagePreviewer");
    
    // if we are still connecting, should cancel now and release
    // related resource.
    if (_connection)
    {
        [_connection cancel];
        [self releaseConnection];
    }

    [_window release];

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
    // [_indicator release];

    [_indicator startAnimation: self];
}

- (void) showImage: (NSImage *) image withTitle: (NSString *) title
{
	NSImageRep *rep = [[image representations] objectAtIndex: 0];
	NSSize size = NSMakeSize([rep pixelsWide], [rep pixelsHigh]);
    NSSize visibleSize = [[NSScreen mainScreen] visibleFrame].size;
	NSPoint origin = [[NSScreen mainScreen] visibleFrame].origin;
    visibleSize.width -= 20;
    visibleSize.height -= 20;
    
    double aspect = size.height / size.width;
    // Do some auto resizing in case the image size is too large
    if (size.width > visibleSize.width)
    {
        size.width = visibleSize.width;
        size.height = aspect * size.width;
    }

    if (size.height > visibleSize.height)
    {
        size.height = visibleSize.height;
        size.width = size.height / aspect;
    }
	[image setSize: size];
	NSObject * data = [[NSObject alloc] init];
	
	if([fileType isEqual: @"pdf"]) 
	{
		//rep = [[NSPDFImageRep alloc] initWithData: _receivedData];
		data = [[PDFDocument alloc] initWithData:_receivedData];
		size.width *= 2;
	}
	else
	{
		data = image;
	}
	    
    origin.x += ([[NSScreen mainScreen] visibleFrame].size.width - size.width) / 2;
    
    // use Golden Ratio to place the window vertically
    origin.y += ([[NSScreen mainScreen] visibleFrame].size.height - size.height) / 1.61803399;
    // NSLog(@"image size: %g %g", size.width, size.height);
    
	//[_window setBackgroundColor: (NSColor *)whiteColor];
	 
    //view = [[NSImageView alloc] initWithFrame: viewRect];
    
    [_indicator removeFromSuperview];
    [_indicator release];
	
	GTShowImageFacade * myFacade = [[GTShowImageFacade alloc] initWithInfo:_window
																type:fileType
																image:data
																size : size
															   origin:origin
															   preTitle: title];
	[myFacade drawImage];
	//[myFacade release];
	[_window setTitle: title];
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

- (void) connection: (NSURLConnection *) connection 
 didReceiveResponse: (NSURLResponse *) response
{
    // this method is called when the server has determined that it
    // has enough information to create the NSURLResponse
    // NSLog(@"didReceiveResponse");
    NSString *fileName = [response suggestedFilename];

    // Decode incorrectly encoded NSString
    int max = [fileName length];
    char *nbytes = (char *) malloc(max + 1);
    
    int i;
    for (i = 0; i < max; i++)
    {
        unichar ch = [fileName characterAtIndex: i];
        nbytes[i] = (char) ch;
    }
    
    nbytes[i] = '\0';
    NSStringEncoding enc = encodingFromYLEncoding(YLGBKEncoding);
    _currentFileDownloading = [[NSString alloc] initWithCString: nbytes
                                                       encoding: enc];
	// Try to dectect the file type
	// Avoid useless download
	// By gtCarrera @ 9#
	fileType = [_currentFileDownloading substringFromIndex: [_currentFileDownloading length] - 3];
	fileType = [fileType lowercaseString];
	//NSArray * allowedTypes[5] = {@"jpg", @"bmp", @"png", @"gif", @"tiff"};
	Boolean canView = [fileType isEqual : @"jpg"] || [fileType isEqual : @"bmp"] 
					 || [fileType isEqual : @"png"] || [fileType isEqual : @"gif"]  
					 || [fileType isEqual : @"tiff"] || [fileType isEqual : @"pdf"] ;
	if(!canView)
	{
		[[NSWorkspace sharedWorkspace] openURL: _currentURL];
		[_window close];
		free(nbytes);
	}
	// End
	
    free(nbytes);
    
    _totalLength = [response expectedContentLength];

    [_window setTitle: [NSString stringWithFormat: @"Loading %@...", _currentFileDownloading]];
    [_indicator setIndeterminate: NO];
    [_indicator setMaxValue: (double) _totalLength];
    [_indicator setDoubleValue: 0];

    [_receivedData setLength: 0];
}

- (void) connection: (NSURLConnection *) connection 
     didReceiveData: (NSData *) data
{
    // NSLog(@"didReceiveData: %d bytes", [data length]);
    // append the new data to the receivedData
    // receivedData is declared as a method instance elsewhere
    [_receivedData appendData: data]; 
    [_indicator incrementBy: (double) [data length]];
}

- (void)connection: (NSURLConnection *) connection
  didFailWithError: (NSError *) error
{
    [self releaseConnection];

    // inform the user
    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey: NSErrorFailingURLStringKey]);
}

- (void) connectionDidFinishLoading: (NSURLConnection *) connection
{
    // do something with the data
    // receivedData is declared as a method instance elsewhere
    // NSLog(@"Succeeded! Received %d bytes of data", [_receivedData length]);
    
    [_indicator setDoubleValue: (double) [_receivedData length]];

    NSImage *image = [[NSImage alloc] initWithData: _receivedData];
	// Oringinal code
	/*
	if(image == nil || [[image representations] count] == 0)
	{
		NSString *text = [NSString stringWithFormat: @"Failed to download file %@", _currentFileDownloading];
		NSAlert *alert = [NSAlert alertWithMessageText: @"Failed to download image." 
                                         defaultButton: @"OK" 
                                       alternateButton: nil 
                                           otherButton: nil 
                             informativeTextWithFormat: text];
        [alert runModal];
	}*/
	
	// Modified by gtCarrera
	//NSString * fileType;
	fileType = [_currentFileDownloading substringFromIndex: [_currentFileDownloading length] - 3];
    if (image == nil || [[image representations] count] == 0)
    {
		// It's a piece of shit... 
		//[[NSWorkspace sharedWorkspace] openURL: _currentURL];
		[_window close];
	}
    else
	{
        [self showImage: image withTitle: _currentFileDownloading];
	}
	// End
    [self releaseConnection];
}

- (void) releaseConnection
{
    [_connection release];
    _connection = nil;

    [_receivedData release];
    _receivedData = nil;
    
    [_currentFileDownloading release];
    _currentFileDownloading = nil;
}

@end
