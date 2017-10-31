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
#import <Crashlytics/Crashlytics.h>

#define kPostPushPanelNibFilename @"PostPushPanel"

@implementation NSString (TrimmingAdditions)

- (NSString *)stringByTrimmingLeadingCharactersInSet:(NSCharacterSet *)characterSet {
    NSUInteger location = 0;
    NSUInteger length = [self length];
    unichar charBuffer[length];
    [self getCharacters:charBuffer];
    
    for (location; location < length; location++) {
        if (![characterSet characterIsMember:charBuffer[location]]) {
            break;
        }
    }
    
    return [self substringWithRange:NSMakeRange(location, length - location)];
}

- (NSString *)stringByTrimmingTrailingCharactersInSet:(NSCharacterSet *)characterSet {
    NSUInteger location = 0;
    NSUInteger length = [self length];
    unichar charBuffer[length];
    [self getCharacters:charBuffer];
    
    for (length; length > 0; length--) {
        if (![characterSet characterIsMember:charBuffer[length - 1]]) {
            break;
        }
    }
    
    return [self substringWithRange:NSMakeRange(location, length - location)];
}

@end

@implementation WLPostPushDelegate

#pragma mark -
#pragma mark init and dealloc
SYNTHESIZE_SINGLETON_FOR_CLASS(WLPostPushDelegate);

int postFU;
WLTerminal *term;
NSString *finalPushResult;

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
    [_pushWindow endEditingFor:nil];
    [NSApp endSheet:_pushWindow];
    [_pushWindow orderOut:self];
}

- (void)showNotificationWindow:(NSString *)titleMsg withSheetMsg:(NSString *)sheetMsg{
    [Answers logCustomEventWithName:@"Long Push window" customAttributes:@{@"failed" : sheetMsg}];
    NSBeginAlertSheet(NSLocalizedString(titleMsg, @"Sheet Title"),
                      nil,
                      nil,
                      nil,
                      _pushWindow,
                      self,
                      nil,
                      nil,
                      nil,
                      NSLocalizedString(sheetMsg, @"Sheet Message"));
}

- (IBAction)sendPostPushText:(id)sender {
    NSString *pushText = [[_pushText string] stringByTrimmingCharactersInSet:
                          [NSCharacterSet whitespaceCharacterSet]];
    int pushLen = [pushText length];
    if (pushLen == 0) {
        [self showNotificationWindow:@"Miss something?" withSheetMsg:@"Empty comment will not be sent to BBS"];
    } else if (pushLen > 600){
        [self showNotificationWindow:@"Cooment too loooong" withSheetMsg:@"Comment should be less than 500 characters. Please reduce your comment or use reply instead."];
    }else if(postFU == 0) {
        [self showNotificationWindow:@"Miss something?" withSheetMsg:@"Please select your feeling of the comment!"];
    } else {
        [self loadNibFile];
        [_sendButton setEnabled:NO];
        [_cancelButton setEnabled:NO];
        [_progressCircle setHidden:NO];
        [_pushText setEditable:NO];
        [_progressCircle setIndeterminate:YES];
        [_progressCircle setUsesThreadedAnimation:YES];
        [_progressCircle startAnimation:nil];
        
        [NSThread detachNewThreadSelector:@selector(preparePostPush:)
                                 toTarget:self
                               withObject:pushText];
    }
}

- (void)endThread {
    usleep(100000);
    [_sendButton setEnabled:YES];
    [_cancelButton setEnabled:YES];
    [_progressCircle setHidden:YES];
    [_progressCircle setIndeterminate:YES];
    [_progressCircle setUsesThreadedAnimation:YES];
    [_progressCircle stopAnimation:nil];
    [_pushText setEditable:YES];
    
    if([finalPushResult isEqualToString:@"DONE"]){
        //[self showNotificationWindow:@"Auto Comment Result" withSheetMsg:@"Successfully leave the comment!"];
        [_pushText setString:@""];
        [Answers logCustomEventWithName:@"Long Push window" customAttributes:@{@"action" : @"Successfully leave the comment!"}];
        NSBeginAlertSheet(NSLocalizedString(@"Auto Comment Result", @"Sheet Title"),
                          nil,
                          nil,
                          nil,
                          _pushWindow,
                          self,
                          @selector(sheetDidEnd:resultCode:contextInfo:),
                          nil,
                          nil,
                          NSLocalizedString(@"Successfully leave the comment!", @"Sheet Message"));
    } else if (finalPushResult) {
        [self showNotificationWindow:@"Auto Comment Result" withSheetMsg:finalPushResult];
    }
}

- (void)sheetDidEnd:(NSWindow *)sheet
         resultCode:(NSInteger)resultCode
        contextInfo:(void *)contextInfo {
    if (resultCode == NSAlertDefaultReturn) {
        [self performSelector: @selector(cancelPush:) withObject:self afterDelay: 0.0];
    }
}

+ (NSString *)getTerminalBottomLine {
    const int linesPerPage = [[WLGlobalConfig sharedInstance] row] - 1;
    
    return [term stringAtIndex:linesPerPage * [[WLGlobalConfig sharedInstance] column] length:[[WLGlobalConfig sharedInstance] column]] ?: @"";
}

+ (NSString *)performPostPushToTerminal:(NSString *)pushText{
    const int sleepTime = 100000, maxAttempt = 500;
    BOOL isPushError = NO, isFinished = NO, tooFrequent = NO;
    WLConnection *connection = [term connection];
    int i=0, maxPushLen;
    NSString *bottomLine, *partialText, *leftText;
    
    // First, remove annonying newline "\r" and "\n" char at the very beginning.
    // Trailing space will also be removed.
    pushText = [pushText stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    pushText = [pushText stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    pushText = [pushText stringByTrimmingTrailingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // send "%" to see if this article can be pushed
    [connection sendBytes:"%" length:1];
    while(i< maxAttempt) {
        // wait for the screen to refresh
        ++i;
        usleep(sleepTime);
        bottomLine = [WLPostPushDelegate getTerminalBottomLine];
        if([bottomLine hasPrefix:@"您覺得這篇文章 1.值得推薦"]){
            i = 0;
            break;
        } else if([bottomLine hasPrefix:@"→"]) {
            // push too freqent
            tooFrequent = YES;
            i = 0;
            break;
        } else if ([bottomLine hasPrefix:@" ◆ "]) {
            [connection sendBytes:"\r" length:1];
            usleep(sleepTime*2);
            return @"Unable to leave comment on this artile";
        }
    }
    
    // second stage
    // Great, this article is "pushable". Now check user's post feeling.
    // If feeling is "bu~~" but the board disables "bu~~" comment (eg. Suckcomic)
    // Then return error
    bottomLine = [WLPostPushDelegate getTerminalBottomLine];
    if (postFU == 2 && ![bottomLine containsString:@"2.給它噓聲"]) {
        [connection sendBytes:"\r" length:1];
        usleep(sleepTime*2);
        [connection sendBytes:"\r" length:1];
        usleep(sleepTime*2);
        return @"This article cannot be bu~~~";
    }
    
    // All checks out, now send post feelng and get max push length/message
    if(!tooFrequent){
        NSString *postFUString = [NSString stringWithFormat:@"%d", postFU];
        [connection sendText:postFUString];
        while(i< maxAttempt) {
            ++i;
            usleep(sleepTime);
            bottomLine = [WLPostPushDelegate getTerminalBottomLine];
            if([bottomLine hasPrefix:@"推"] || [bottomLine hasPrefix:@"噓"] || [bottomLine hasPrefix:@"→"]) {
                i = 0;
                isPushError = NO;
                break;
            }
            isPushError = YES;
        }
        
        if(isPushError){
            return @"Unable to set post feeling";
        }
        
    }
    
    // Start to process pushtext. test string:
    // 35歲的韋德手握3枚冠軍戒指，即將進入生涯末期的他希望能再拼一冠，「沒有什麼地方比這裡更能讓我打出高水準，克里夫蘭相信我的天份以及我能帶給球隊許多奪冠因子。」
    maxPushLen = 65 - ([bottomLine rangeOfString:@":"].location + 3); // why 3? It's a magic number!!
    leftText = pushText;
    while(!isFinished){
        partialText = [WLPostPushDelegate processPostPush:leftText withPushLen:maxPushLen];
        leftText = [leftText substringFromIndex:[partialText length]];
        
        [connection sendText:partialText];
        [connection sendBytes:"\r" length:1];
        while(i< maxAttempt) {
            ++i;
            usleep(sleepTime);
            bottomLine = [WLPostPushDelegate getTerminalBottomLine];
            if([bottomLine containsString:@"確定[y/N]:"]) {
                [connection sendBytes:"Y\r" length:2];
                i = 0;
                isPushError = NO;
                break;
            }
            isPushError = YES;
        }
        
        if(isPushError){
            return @"Unable to send the comment confirmation";
        }
        
        while(i< maxAttempt) {
            ++i;
            usleep(sleepTime);
            bottomLine = [WLPostPushDelegate getTerminalBottomLine];
            if ([bottomLine containsString:@"文章選讀"]) {
                i = 0;
                isPushError = NO;
                break;
            }
            isPushError = YES;
        }
        
        if(isPushError){
            return @"Something goes wrong during leaving comment process (1)";
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
                    isPushError = NO;
                    break;
                } else if([bottomLine containsString:@"本板禁止快速連續推文"]) {
                    // get the pause seconds
                    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"請再等 ?(\\d+) ?秒" options:0 error:nil];
                    NSTextCheckingResult *match = [regex firstMatchInString:bottomLine options:NSAnchoredSearch range:NSMakeRange(0, bottomLine.length)];
                    NSRange needleRange = [match rangeAtIndex: 1];
                    NSString *needle = [bottomLine substringWithRange:needleRange];
                    
                    // the board bans fast comment, just sleep for 1 second
                    // and give it another try.
                    [connection sendBytes:" " length:1];
                    sleep([needle intValue]);
                    [connection sendBytes:"%" length:1];
                    usleep(sleepTime);
                }
                isPushError = YES;
            }
            if(isPushError){
                return @"Something goes wrong during leaving comment process (2)";
            }
        }
    }
    return @"DONE";
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
                textPointer = i-1;
                break;
            }
        }
        return [pushText substringToIndex:textPointer];
    }
}

+ (int) countBig5GBKChars:(NSString *)pushText {
    int lengthInBytes = 0;
    
    for (int i = 0; i < [pushText length]; i++) {
        unichar ch = [pushText characterAtIndex:i];
        if (ch < 0x007F) {
            ++lengthInBytes;
        } else {
            lengthInBytes += 2;
        }
    }
    
    return lengthInBytes;
}

- (void)preparePostPush:(NSString *)pushText {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    finalPushResult = [WLPostPushDelegate performPostPushToTerminal:pushText];
    [self performSelectorOnMainThread:@selector(endThread) withObject:nil waitUntilDone:NO];
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
        
        // check if user is in a board or article
        if([WLPostPushDelegate checkPushable]){
            [Answers logCustomEventWithName:@"Long Push window" customAttributes:@{@"action" : @"open successfully"}];
            // Open panel in window
            [NSApp beginSheet:_pushWindow
               modalForWindow:window
                modalDelegate:nil
               didEndSelector:nil
                  contextInfo:nil];
        } else {
            [Answers logCustomEventWithName:@"Long Push window" customAttributes:@{@"failed" : @"You cannot use Long Comment function at current status"}];
            NSBeginAlertSheet(NSLocalizedString(@"You cannot use Long Comment function at current status", @"Sheet Title"),
                              nil,
                              nil,
                              nil,
                              window,
                              self,
                              nil,
                              nil,
                              nil,
                              NSLocalizedString(@"", @"Sheet Message"));
        }
    } else {
        [Answers logCustomEventWithName:@"Long Push window" customAttributes:@{@"failed" : @"This function only works on PTT"}];
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
