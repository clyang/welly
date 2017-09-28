//
//  WLPostPushDelegate.m
//  Welly
//
//  Created by Cheng-Lin Yang on 2017/9/26.
//  Copyright © 2017年 Welly Group. All rights reserved.
//

#import "WLPostPushDelegate.h"
#import "WLGlobalConfig.h"
#import "WLConnection.h"
#import "WLTerminal.h"
#import "SynthesizeSingleton.h"

#define kPostPushPanelNibFilename @"PostPushPanel"

@implementation WLPostPushDelegate

#pragma mark -
#pragma mark init and dealloc
SYNTHESIZE_SINGLETON_FOR_CLASS(WLPostPushDelegate);

int postFU;
WLTerminal *term;
BOOL finalPushResult;

- (void)loadNibFile {
    if (!_pushWindow) {
        [NSBundle loadNibNamed:kPostPushPanelNibFilename owner:self];
    }
}

- (void)awakeFromNib {
    [_pushText setFont:[NSFont fontWithName:@"Monaco" size:18]];
    postFU = 0;
}

- (IBAction)cancelPush:(id)sender {
    [_pushText setString:@""];
    [_pushWindow endEditingFor:nil];
    [NSApp endSheet:_pushWindow];
    [_pushWindow orderOut:self];
}

- (IBAction)sendPostPushText:(id)sender {
    NSString *pushText = [[_pushText string] stringByTrimmingCharactersInSet:
                          [NSCharacterSet whitespaceCharacterSet]];
    int pushLen = [pushText length];
    if (pushLen == 0) {
        NSBeginAlertSheet(NSLocalizedString(@"Miss something?", @"Sheet Title"),
                          nil,
                          nil,
                          nil,
                          _pushWindow,
                          self,
                          nil,
                          nil,
                          nil,
                          NSLocalizedString(@"Empty comment will not be sent to BBS", @"Sheet Message"));
    } else if (pushLen > 500){
        NSBeginAlertSheet(NSLocalizedString(@"Cooment too loooong", @"Sheet Title"),
                          nil,
                          nil,
                          nil,
                          _pushWindow,
                          self,
                          nil,
                          nil,
                          nil,
                          NSLocalizedString(@"Comment should be less than 500 characters. Please reduce your comment or use reply instead.", @"Sheet Message"));
    }else if(postFU == 0) {
        NSBeginAlertSheet(NSLocalizedString(@"Miss something?", @"Sheet Title"),
                          nil,
                          nil,
                          nil,
                          _pushWindow,
                          self,
                          nil,
                          nil,
                          nil,
                          NSLocalizedString(@"Please select your feeling of the comment!", @"Sheet Message"));
    } else {
        [self loadNibFile];
        [NSThread detachNewThreadSelector:@selector(preparePostPush:)
                                 toTarget:self
                               withObject:pushText];
    }
}

+ (NSString *)getTerminalBottomLine {
    const int linesPerPage = [[WLGlobalConfig sharedInstance] row] - 1;
    
    return [term stringAtIndex:linesPerPage * [[WLGlobalConfig sharedInstance] column] length:[[WLGlobalConfig sharedInstance] column]] ?: @"";
}

+ (BOOL)performPostPushToTerminal:(NSString *)pushText{
    const int sleepTime = 100000, maxAttempt = 3000;
    BOOL isPushError = NO, isFinished = NO;
    WLConnection *connection = [term connection];
    int i=0, maxPushLen;
    NSString *bottomLine, *partialText, *leftText;
    
    // First, send "%" to see if this article can be pushed
    [connection sendBytes:"%" length:1];
    while(i< maxAttempt) {
        // wait for the screen to refresh
        ++i;
        usleep(sleepTime);
        bottomLine = [WLPostPushDelegate getTerminalBottomLine];
        if([bottomLine hasPrefix:@"您覺得這篇文章 1.值得推薦"]){
            i = 0;
            break;
        } else {
            return NO;
        }
    }
    
    // second stage
    // Great, this article is "pushable". Now check user's post feeling.
    // If feeling is "bu~~" but the board disables "bu~~" comment (eg. Suckcomic)
    // Then return error
    bottomLine = [WLPostPushDelegate getTerminalBottomLine];
    if (postFU == 2 && ![bottomLine containsString:@"2.給它噓聲"]) {
        return NO;
    }
    
    // All checks out, now send post feelng and get max push length/message
    NSString *postFUString = [NSString stringWithFormat:@"%d", postFU];
    [connection sendText:postFUString];
    while(i< maxAttempt) {
        ++i;
        usleep(sleepTime);
        bottomLine = [WLPostPushDelegate getTerminalBottomLine];
        if([bottomLine hasPrefix:@"推"] || [bottomLine hasPrefix:@"噓"] || [bottomLine hasPrefix:@"→"]) {
            i = 0;
            break;
        }else {
            return NO;
        }
    }
    
    // Start to process pushtext. test string:
    // 35歲的韋德手握3枚冠軍戒指，即將進入生涯末期的他希望能再拼一冠，「沒有什麼地方比這裡更能讓我打出高水準，克里夫蘭相信我的天份以及我能帶給球隊許多奪冠因子。」
    maxPushLen = 65 - ([bottomLine rangeOfString:@":"].location + 3); // why 3? It's magic number!!
    leftText = pushText;
    while(!isFinished){
        partialText = [WLPostPushDelegate processPostPush:leftText withPushLen:maxPushLen];
        leftText = [leftText substringFromIndex:[partialText length]];
        
        [connection sendText:partialText];
        NSLog(@"Sending %@", partialText);
        [connection sendBytes:"\r" length:1];
        NSLog(@"Sending enter");
        while(i< maxAttempt) {
            ++i;
            usleep(sleepTime);
            bottomLine = [WLPostPushDelegate getTerminalBottomLine];
            if([bottomLine containsString:@"確定[y/N]:"]) {
                [connection sendBytes:"Y\r" length:2];
                i = 0;
                break;
            }
            isPushError = YES;
        }
        
        if(isPushError){
            return NO;
        }
        
        while(i< maxAttempt) {
            ++i;
            usleep(sleepTime);
            bottomLine = [WLPostPushDelegate getTerminalBottomLine];
            if ([bottomLine containsString:@"文章選讀"]) {
                i = 0;
                break;
            }
            isPushError = YES;
        }
        
        if(isPushError){
            return NO;
        }
        
        if([leftText length] == 0) {
            isFinished = YES;
        } else {
            [connection sendBytes:"%" length:1];
            while(i< maxAttempt) {
                ++i;
                usleep(sleepTime);
                bottomLine = [WLPostPushDelegate getTerminalBottomLine];
                if([bottomLine hasPrefix:@"→"]) {
                    i = 0;
                    break;
                }
                isPushError = YES;
            }
            if(isPushError){
                return NO;
            }
        }
    }

    return YES;
}

+ (NSString *) processPostPush:pushText withPushLen:(int)maxPushLen {
    int lengthInBytes, textPointer;
    
    if([WLPostPushDelegate countBig5GBKChars:pushText] <= maxPushLen){
        return pushText;
    } else {
        lengthInBytes = 0;
        for (int i = 0; i < [pushText length]; i++) {
            unichar ch = [pushText characterAtIndex:i];
            if (ch < 0x007F) {
                ++lengthInBytes;
            } else {
                lengthInBytes += 2;
            }
            if(lengthInBytes > maxPushLen){
                textPointer = i;
                break;
            }
        }
        return [pushText substringToIndex:textPointer];
    }
}

+ (int) countBig5GBKChars:(NSString *)pushText {
    int lengthInBytes = 0;
    // replace all '\n' with '\r'
    NSString *s = [pushText stringByReplacingOccurrencesOfString:@"\n" withString:@"\r"];
    
    for (int i = 0; i < [s length]; i++) {
        unichar ch = [s characterAtIndex:i];
        if (ch < 0x007F) {
            ++lengthInBytes;
        } else {
            lengthInBytes += 2;
        }
    }
    
    return lengthInBytes;
}

- (BOOL)preparePostPush:(NSString *)pushText {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    finalPushResult = [WLPostPushDelegate performPostPushToTerminal:pushText];
    [pool release];
}

- (IBAction)setPostPushFu:(NSButton *)sender {
    // postFU 1: push / 2: bu~~ / 3: just comment
    if([sender.title isEqualToString:@"\U0001F44D"]) {
        postFU = 1;
    } else if([sender.title isEqualToString:@"\U0001F449"]) {
        postFU = 3;
    } else {
        postFU = 2;
    }
}

+ (BOOL)checkPushable {
    NSString *bottomLine = [WLPostPushDelegate getTerminalBottomLine];
    
    if ([bottomLine containsString:@"文章選讀"] || [bottomLine containsString:@"瀏覽 第"]) {
        return YES;
    } else {
        return NO;
    }
}

- (void)beginPostPushInWindow:(NSWindow *)window
                  forTerminal:(WLTerminal *)terminal {
    term = terminal;
    WLConnection *connection = [term connection];
    if([connection isPTT] && [connection isConnected]) {
        [self loadNibFile];
        [_pushText setString:@""];
        
        // check if user is in a board or article
        if([WLPostPushDelegate checkPushable]){
            // Open panel in window
            [NSApp beginSheet:_pushWindow
               modalForWindow:window
                modalDelegate:nil
               didEndSelector:nil
                  contextInfo:nil];
        }
    } else {
        NSBeginAlertSheet(NSLocalizedString(@"This function only works on PTT", @"Sheet Title"),
                          nil,
                          nil,
                          nil,
                          window,
                          self,
                          nil,
                          nil,
                          nil,
                          NSLocalizedString(@"If you believe that this function also works on this BBS, create an issue on Github to tell me.", @"Sheet Message"));
    }
}

@end
