//
//  YLImagePreviewer.h
//  MacBlueTelnet
//
//  Created by Jjgod Jiang on 2/17/08.
//  Copyright 2008 Jjgod Jiang. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <HMBlkAppKit/HMBlkProgressIndicator.h>
//#import <iLifeControls/NFHUDWindow.h>

@interface YLImagePreviewer : NSObject {
    NSString        *_currentFileDownloading;
    NSMutableData   *_receivedData;
    NSURLConnection *_connection;
    HMBlkProgressIndicator *_indicator;
    long long        _totalLength;
	NSPanel         *_window;
	// Added by gtCarrera @ 9#
	NSString		* fileType;
	NSURL			*_currentURL;
	// End 
}

- (void) showLoadingWindow;
- (void) releaseConnection;

@end
