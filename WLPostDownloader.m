//
//  WLPostDownloader.m
//  Welly
//
//  Created by K.O.ed on 08-7-21.
//  Copyright 2008 Welly Group. All rights reserved.
//

#import "WLPostDownloader.h"
#import "YLLGlobalConfig.h"
#import "YLConnection.h"
#import "YLTerminal.h"


@implementation WLPostDownloader

+ (NSString *)downloadPostFromConnection:(YLConnection *)connection {
    const int sleepTime = 100000, maxAttempt = 300000;

    YLTerminal *terminal = [connection terminal];

    const int linesPerPage = [[YLLGlobalConfig sharedInstance] row] - 1;
    NSString *lastPage[linesPerPage], *newPage[linesPerPage];

    NSString *bottomLine = [terminal stringFromIndex:linesPerPage * [[YLLGlobalConfig sharedInstance] column] length:[[YLLGlobalConfig sharedInstance] column]] ?: @"";
    NSString *newBottomLine = bottomLine;

    NSMutableString *buf = [NSMutableString string];

    BOOL isFinished = NO;

    for (int i = 0; i < maxAttempt && !isFinished; ++i) {
        int j = 0, lastline = linesPerPage;
        // read in the whole page, and store in 'newPage' array
        for (; j < linesPerPage; ++j) {
            // read one line
            NSString *line = [terminal stringFromIndex:j * [[YLLGlobalConfig sharedInstance] column] length:[[YLLGlobalConfig sharedInstance] column]] ?: @"";
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
            newBottomLine = [terminal stringFromIndex:linesPerPage * [[YLLGlobalConfig sharedInstance] column] length:[[YLLGlobalConfig sharedInstance] column]] ?: @"";
            ++i;
        }
        bottomLine = newBottomLine;
    }

    return buf;
}
@end
