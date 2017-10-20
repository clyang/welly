//
//  WLTrackArticlePanelController.m
//  Welly
//
//  Created by Cheng-Lin Yang on 2017/10/19.
//  Copyright © 2017年 Welly Group. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WLTrackArticlePanelController.h"
#import "WLGlobalConfig.h"
#import "WLConnection.h"
#import "WLTerminal.h"
#import "SynthesizeSingleton.h"
#import "FMDB.h"
#import "WLTracDB.h"

#define kTrackArticleWindowNibFilename @"TrackArticleWindow"

@implementation WLTrackArticlePanelController
@synthesize trackArticleWindow = _trackArticleWindow;

#pragma mark -
#pragma mark init and dealloc
SYNTHESIZE_SINGLETON_FOR_CLASS(WLTrackArticlePanelController);

- (void)loadNibFile {
    if (!_trackArticleWindow) {
        [NSBundle loadNibNamed:kTrackArticleWindowNibFilename owner:self];
    }
}

- (void)awakeFromNib {
}

- (void)openTrackArticleWindow:(NSWindow *) window forTerminal:(WLTerminal *) terminal {
    [self loadNibFile];
    
    // load db
    [self loadArticleDB];
    
    [NSApp beginSheet:_trackArticleWindow
       modalForWindow:window
        modalDelegate:nil
       didEndSelector:nil
          contextInfo:nil];
}

- (NSString *)getTerminalBottomLine:(WLTerminal *) terminal {
    const int linesPerPage = [[WLGlobalConfig sharedInstance] row] - 1;
    return [terminal stringAtIndex:linesPerPage * [[WLGlobalConfig sharedInstance] column] length:[[WLGlobalConfig sharedInstance] column]] ?: @"";
}

- (void)getArticleDetail:(WLTerminal *) terminal {
    int i, arID;
    const int sleepTime = 100000, maxAttempt = 500;
    NSString *owner, *author, *aid, *board, *url, *lastLineHash, *ownTime, *bottomLine, *tmp;
    BOOL changePageStatus;
    WLConnection *conn = [terminal connection];
    
    // 1 step, go to 1st page of the selected article
    if([[self getTerminalBottomLine:terminal] containsString:@"目前顯示: 第"]){
        [conn sendText:termKeyHome];
        while(i< maxAttempt) {
            // wait for the screen to refresh
            ++i;
            usleep(sleepTime);
            bottomLine = [self getTerminalBottomLine:terminal];
            if([bottomLine containsString:@"目前顯示: 第 01~"]){
                changePageStatus = YES;
                i = 0;
                break;
            } else {
                changePageStatus = NO;
            }
        }
        if(!changePageStatus) {
            //show warn
            return;
        }
    } else if ([[self getTerminalBottomLine:terminal] containsString:@"文章選讀"]) {
        // send "enter" to get to 1st page of article
        [conn sendBytes:"\r" length:1];
        while(i< maxAttempt) {
            // wait for the screen to refresh
            ++i;
            usleep(sleepTime);
            bottomLine = [self getTerminalBottomLine:terminal];
            NSLog(@"%@", bottomLine);
            if([bottomLine containsString:@"目前顯示: 第 01~"]){
                changePageStatus = YES;
                i = 0;
                break;
            } else {
                changePageStatus = NO;
            }
        }
        if(!changePageStatus) {
            //show warn
            return;
        }
    }
    NSLog(@"33333");
    // 2nd step: retrieve author/title/board from 1st page
    tmp = [self getTerminalNthLine:1 forTerminal: terminal];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"作者[: ]+([a-zA-Z0-9]{2,12}).+看板[ ]+([a-zA-Z0-9]+)" options:0 error:nil];
    NSTextCheckingResult *match = [regex firstMatchInString:tmp options:NSAnchoredSearch range:NSMakeRange(0, tmp.length)];
    //NSRange needleRange = [match rangeAtIndex: 1];
    NSString *aTitle = [tmp substringWithRange:[match rangeAtIndex: 1]];
    NSString *aBoard = [tmp substringWithRange:[match rangeAtIndex: 2]];
    NSLog(@"title: %@ , board: %@", aTitle, aBoard);
}

- (NSString *)getTerminalNthLine:(int) i forTerminal:(WLTerminal *) terminal{
    const int line = i - 1;
    return [terminal stringAtIndex:line * [[WLGlobalConfig sharedInstance] column] length:[[WLGlobalConfig sharedInstance] column]] ?: @"";
}

- (void)addTrackArticle:(NSWindow *) window forTerminal:(WLTerminal *) terminal {
    if(![[terminal connection] isPTT] && (![[self getTerminalBottomLine:terminal] containsString:@"文章選讀"] || ![[self getTerminalBottomLine:terminal] containsString:@"目前顯示: 第"])){
        //show warn
        NSLog(@"%@", [self getTerminalBottomLine:terminal]);
    } else {
        [NSThread detachNewThreadSelector:@selector(getArticleDetail:)
                                 toTarget:self
                               withObject:terminal];
    }
}

- (void)loadArticleDB {
    //从数据库加载
    [[WLTracDB sharedDBTools].queue inDatabase:^(FMDatabase *db) {
        FMResultSet *set = [db executeQuery:@"SELECT * FROM PttArticle"];
        NSMutableArray *arrayM = [NSMutableArray array];

        while ([set next]) {
            NSLog(@"11111");
            /*
             "arID integer PRIMARY KEY AUTOINCREMENT NOT NULL,"
             "owner text," // who wants to track this article
             "author text," // article author
             "aid text,"
             "board text,"
             "url text,"
             "lastLineHash text,"
             "ownTime text"
             */
            /*NSMutableDictionary *dictM = [NSMutableDictionary dictionary];
            
            NSInteger companyId = [set intForColumn:@"companyId"];
            NSString *companyName = [set stringForColumn:@"companyName"];
            
            [dictM setObject:@(companyId) forKey:@"companyId"];
            [dictM setObject:companyName forKey:@"companyName"];
            
            
            [arrayM addObject:dictM];*/
        }
        
        //self.companyes = arrayM;
        
        // 让pickerView更新数据
        //[self.pickerView reloadAllComponents];
    }];
    
}

- (IBAction)closeTrackArticleWindow:(id)sender {
    [_trackArticleWindow endEditingFor:nil];
    [NSApp endSheet:_trackArticleWindow];
    [_trackArticleWindow orderOut:self];
}

@end
