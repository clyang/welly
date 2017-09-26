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
        NSBeginAlertSheet(NSLocalizedString(@"Is this a joke?", @"Sheet Title"),
                          nil,
                          nil,
                          nil,
                          _pushWindow,
                          self,
                          nil,
                          nil,
                          nil,
                          NSLocalizedString(@"Empty comment will not be sent to BBS", @"Sheet Message"));
    } else if(postFU == 0) {
        NSBeginAlertSheet(NSLocalizedString(@"Is this a joke?", @"Sheet Title"),
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
        // everything is checked, now try to push the comment
        const int sleepTime = 100000, maxAttempt = 300000;
        BOOL isFinished = NO, isPushError;
        WLConnection *connection = [term connection];
        const int linesPerPage = [[WLGlobalConfig sharedInstance] row] - 1;
        int i=0;
        NSString *bottomLine = [term stringAtIndex:linesPerPage * [[WLGlobalConfig sharedInstance] column] length:[[WLGlobalConfig sharedInstance] column]] ?: @"";
        NSString *newBottomLine = bottomLine;

        
        // First, send "%" to see if this article can be pushed
        [connection sendBytes:"%" length:1];
        while ([newBottomLine containsString:@"您覺得這篇文章 1.值得推薦"] && i < maxAttempt) {
            // wait for the screen to refresh
            usleep(sleepTime);
            newBottomLine = [term stringAtIndex:linesPerPage * [[WLGlobalConfig sharedInstance] column] length:[[WLGlobalConfig sharedInstance] column]] ?: @"";
            ++i;
        }
        bottomLine = newBottomLine;
        
        if([bottomLine hasPrefix:@"您覺得這篇文章 1.值得推薦"]){
            isPushError = NO;
            NSLog(@"can push");
        } else {
            isPushError = YES;
            NSLog(@"nonononononono push");
        }
    }
}

- (IBAction)setPostPushFu:(NSButton *)sender {
    if([sender.title isEqualToString:@"\U0001F44D"]) {
        postFU = 1;
    } else if([sender.title isEqualToString:@"\U0001F449"]) {
        postFU = 2;
    } else {
        postFU = 3;
    }
}

+ (BOOL)checkPushable {
    //WLConnection *connection = [term connection];
    const int linesPerPage = [[WLGlobalConfig sharedInstance] row] - 1;
    NSString *bottomLine = [term stringAtIndex:linesPerPage * [[WLGlobalConfig sharedInstance] column] length:[[WLGlobalConfig sharedInstance] column]] ?: @"";
    
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
