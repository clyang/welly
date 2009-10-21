//
//  WLPostDownloader.m
//  Welly
//
//  Created by K.O.ed on 08-7-21.
//  Copyright 2008 Welly Group. All rights reserved.
//

#import "WLPostDownloadDelegate.h"
#import "WLGlobalConfig.h"
#import "WLConnection.h"
#import "WLTerminal.h"
#import "SynthesizeSingleton.h"

#define kPostDownloadPanelNibFilename @"PostDownloadPanel"

@implementation WLPostDownloadDelegate

#pragma mark -
#pragma mark init and dealloc
SYNTHESIZE_SINGLETON_FOR_CLASS(WLPostDownloadDelegate);

- (void)loadNibFile {
	if (!_postWindow) {
		[NSBundle loadNibNamed:kPostDownloadPanelNibFilename owner:self];
	}
}

- (void)awakeFromNib {
    [_postText setFont:[NSFont fontWithName:@"Monaco" size:12]];
}

#pragma mark -
#pragma mark Class Method
+ (NSString *)downloadPostFromTerminal:(WLTerminal *)terminal {
    const int sleepTime = 100000, maxAttempt = 300000;

	WLConnection *connection = [terminal connection];

    const int linesPerPage = [[WLGlobalConfig sharedInstance] row] - 1;
    NSString *lastPage[linesPerPage], *newPage[linesPerPage];

    NSString *bottomLine = [terminal stringFromIndex:linesPerPage * [[WLGlobalConfig sharedInstance] column] length:[[WLGlobalConfig sharedInstance] column]] ?: @"";
    NSString *newBottomLine = bottomLine;

    NSMutableString *buf = [NSMutableString string];

    BOOL isFinished = NO;

    for (int i = 0; i < maxAttempt && !isFinished; ++i) {
        int j = 0, lastline = linesPerPage;
        // read in the whole page, and store in 'newPage' array
        for (; j < linesPerPage; ++j) {
            // read one line
            NSString *line = [terminal stringFromIndex:j * [[WLGlobalConfig sharedInstance] column] length:[[WLGlobalConfig sharedInstance] column]] ?: @"";
            newPage[j] = line;
            // check the post ending symbol "※"
            // ptt may include the symbol in the middle for re post
            // NOTE: should we just remove them?
            if ([line hasPrefix:@"※ 来源"] || [line hasPrefix:@"※ 发信站"] || [line hasPrefix:@"※ 發信站"]) {
                isFinished = YES;
                lastline = j;
                break;
            }
        }
        // smth && ptt
        if ((![bottomLine hasPrefix:@"下面还有喔"]) && ([bottomLine length] > 10)
            && ((![bottomLine rangeOfString:@"瀏覽"].length) || ([bottomLine rangeOfString:@"(100%)"].length > 0))) {
			// bottom line should have this prefix if the post has not ended.
            isFinished = YES;
        }

        int k = linesPerPage - 1;
        // if it is the last page, we should check if there are duplicated pages
        if (isFinished && i != 0) {
            while (j > 0) {
                // first, we should locate the last line of last page in the new page.
                // i.e. find a newPage[j] that equals the last line of last page.
                while (j > 0) {
                    --j;
                    if ([newPage[j] isEqualToString:lastPage[k]])
                        break;
                }
                NSAssert(j == 0 || [newPage[j] isEqualToString:lastPage[k]], @"bbs post layout tradition");
                
                // now check if it is really duplicated
                for (int jj = j - 1; jj >= 0; --jj) {
                    --k;
                    if (![newPage[jj] isEqualToString:lastPage[k]]) {
                        // it is not really duplicated by last page effect, but only duplicated by the author of the post
                        j = jj;
                        // k = linesPerPage - 1;
                        break;
                    }
                }
                // jj verified, quit
                break;
            }
        } else {
            j = (i == 0) ? -1 : 0; // except the first page, every time page down would lead to the first line duplicated
        }
        
        // Now copy the content into the buffer
        //[buf setString:@""];    // clear out
        for (j = j + 1; j < lastline; ++j) {
            assert(newPage[j]);
            [buf appendFormat:@"%@\r", newPage[j]];
            lastPage[j] = newPage[j];
        }
        
        if (isFinished)
            break;
        
        // invoke a "page down" command
        [connection sendBytes:" " length:1];
        while ([newBottomLine isEqualToString:bottomLine] && i < maxAttempt) {
            // wait for the screen to refresh
            usleep(sleepTime);
            newBottomLine = [terminal stringFromIndex:linesPerPage * [[WLGlobalConfig sharedInstance] column] length:[[WLGlobalConfig sharedInstance] column]] ?: @"";
            ++i;
        }
        bottomLine = newBottomLine;
    }

    return buf;
}

#pragma mark -
#pragma mark Post Download
- (void)preparePostDownload:(WLTerminal *)terminal {
    // clear s
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; 
    NSString *s = [WLPostDownloadDelegate downloadPostFromTerminal:terminal];
    [_postText performSelectorOnMainThread:@selector(setString:) 
								withObject:s 
							 waitUntilDone:TRUE];
    [pool release];
}

- (void)beginPostDownloadInWindow:(NSWindow *)window 
					  forTerminal:(WLTerminal *)terminal {
	[self loadNibFile];
	
    [_postText setString:@""];
    [NSThread detachNewThreadSelector:@selector(preparePostDownload:) 
							 toTarget:self
						   withObject:terminal];
    [NSApp beginSheet:_postWindow 
	   modalForWindow:window 
		modalDelegate:nil 
	   didEndSelector:nil
		  contextInfo:nil];
}

- (IBAction)cancelPostDownload:(id)sender {
    [_postWindow endEditingFor:nil];
    [NSApp endSheet:_postWindow];
    [_postWindow orderOut:self];
}

@end
