//  MyTableController.m
//  025-NSTableView
//
#import "WLTrackArticlePanel.h"
#import "WLGlobalConfig.h"
#import "WLConnection.h"
#import "WLTerminal.h"
#import "WLTrackDB.h"
#import "SynthesizeSingleton.h"
#import <CommonCrypto/CommonDigest.h>

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

- (NSString *)MD5String {
    const char *cStr = [self UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), result );
    
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

@end


#define kTrackArticlePanelNibFilename @"WLTrackArticlePanel"
@implementation WLTrackArticlePanel
SYNTHESIZE_SINGLETON_FOR_CLASS(WLTrackArticlePanel);
@synthesize nsMutaryDataObj;
@synthesize idTableView;

- (void)awakeFromNib {
    
}

- (void)loadArticleFromDB {
    
    [[WLTrackDB sharedDBTools].queue inDatabase:^(FMDatabase *db) {
        NSUInteger count = [db intForQuery:@"SELECT COUNT(arID) FROM PttArticle"];
        
        if(count > 0) {
            FMResultSet *set = [db executeQuery:@"SELECT * FROM PttArticle"];
            self.nsMutaryDataObj = [[NSMutableArray alloc]init];
            
            while ([set next]) {
                /*
                 "arID integer PRIMARY KEY AUTOINCREMENT NOT NULL,"
                 "owner text," // who wants to track this article
                 "author text," // article author
                 "aid text,"
                 "board text,"
                 "title text,"
                 "url text,"
                 "lastLineHash text,"
                 "ownTime text"
                 
                 self.board = pStr1;
                 self.title = pStr2;
                 self.url = pStr3;
                 self.aid = pStr4;
                 self.ownTime = pStr5;
                 self.lastLineHash = pStr6;
                 self.author = pStr7;
                 self.needTrack = pStr8;
                 */
                //NSMutableDictionary *dictM = [NSMutableDictionary dictionary];
                 
                NSInteger needTrack = [set intForColumn:@"needTrack"];
                NSString *board = [set stringForColumn:@"board"];
                NSString *author = [set stringForColumn:@"author"];
                NSString *title = [set stringForColumn:@"title"];
                NSString *url = [set stringForColumn:@"url"];
                NSString *aid = [set stringForColumn:@"aid"];
                NSString *lastLineHash = [set stringForColumn:@"lastLineHash"];
                NSString *ownTime = [set stringForColumn:@"ownTime"];
                
                WLArticle * zDataObject = [[WLArticle alloc]initWithString1:board
                                                                 andString2:title
                                                                 andString3:url
                                                                 andString4:aid
                                                                 andString5:ownTime
                                                                 andString6:lastLineHash
                                                                 andString7:author
                                                                 andString8:(int)needTrack];
                [self.nsMutaryDataObj addObject:zDataObject];
                
            }
            [set close];
        }
        
        
        
        //self.companyes = arrayM;
        
        // 让pickerView更新数据
        //[self.pickerView reloadAllComponents];
    }];
    
    /*self.nsMutaryDataObj = [[NSMutableArray alloc]init];
    int i;
    for (i = 0; i < 10; i ++) {
        NSString *zStr1 = [[NSString alloc]initWithFormat:@"%d",(i+1)*10];
        NSString *zStr2 = [[NSString alloc]initWithFormat:@"%d",(i+1)*100];
        NSString *zStr3 = [[NSString alloc]initWithFormat:@"%d",(i+1)*1000];
        NSString *zStr4 = [[NSString alloc]initWithFormat:@"%d",(i+1)*10];
        NSString *zStr5 = [[NSString alloc]initWithFormat:@"%d",(i+1)*10];
        NSString *zStr6 = [[NSString alloc]initWithFormat:@"%d",(i+1)*100];
        NSString *zStr7 = [[NSString alloc]initWithFormat:@"%d",(i+1)*1000];
        int zStr8 = 0;
        
        WLArticle * zDataObject = [[WLArticle alloc]initWithString1:zStr1
                                                         andString2:zStr2
                                                         andString3:zStr3
                                                         andString4:zStr4
                                                         andString5:zStr5
                                                         andString6:zStr6
                                                         andString7:zStr7
                                                         andString8:zStr8];
        [self.nsMutaryDataObj addObject:zDataObject];
    } // end for */
}

- (NSString *)getTerminalBottomLine:(WLTerminal *) terminal {
    const int linesPerPage = [[WLGlobalConfig sharedInstance] row] - 1;
    return [terminal stringAtIndex:linesPerPage * [[WLGlobalConfig sharedInstance] column] length:[[WLGlobalConfig sharedInstance] column]] ?: @"";
}

- (void)getArticleDetail:(WLTerminal *) terminal {
    int i=0, arID;
    const int sleepTime = 100000, maxAttempt = 500;
    NSString *owner, *author, *aid, *board, *title, *url, *lastLineHash, *ownTime, *bottomLine, *tmp;
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
    
    // 2nd step: retrieve author/title/board from 1st page
    tmp = [self getTerminalNthLine:1 forTerminal: terminal];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"作者[: ]+([a-zA-Z0-9]{2,12}).+看板[ ]+([a-zA-Z0-9]+)" options:0 error:nil];
    NSTextCheckingResult *match = [regex firstMatchInString:tmp options:NSAnchoredSearch range:NSMakeRange(0, tmp.length)];
    author = [tmp substringWithRange:[match rangeAtIndex: 1]];
    board = [tmp substringWithRange:[match rangeAtIndex: 2]];
    
    tmp = [self getTerminalNthLine:2 forTerminal: terminal];
    regex = [NSRegularExpression regularExpressionWithPattern:@"標題[: ](.+)" options:0 error:nil];
    match = [regex firstMatchInString:tmp options:NSAnchoredSearch range:NSMakeRange(0, tmp.length)];
    NSRange needleRange = [match rangeAtIndex: 1];
    title = [[tmp substringWithRange:needleRange] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    title = [title stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
    
    // 3rd step: retrieve aid/url/lastLineHash
    // lastLineHash first
    [conn sendBytes:"$" length:1];
    while(i< maxAttempt) {
        // wait for the screen to refresh
        ++i;
        usleep(sleepTime);
        bottomLine = [self getTerminalBottomLine:terminal];
        if([bottomLine containsString:@"頁 (100%)  目前顯示: 第"]){
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
    
    // now detect the last comment line number
    cell **_grid = [terminal grid];
    int lastLine = 0;
    for(i=0; i< [terminal maxRow]-1; ++i) {
        if(_grid[i][75].byte == ':' && (
                                        (_grid[i][0].byte == 0xA1 && _grid[i][1].byte == 0xF7) ||
                                        (_grid[i][0].byte == 0xB1 && _grid[i][1].byte == 0xC0) ||
                                        (_grid[i][0].byte == 0xBC && _grid[i][1].byte == 0x4E) )
           ){
            lastLine = i;
        }
    }
    if(!lastLine) {
        NSLog(@"no match");
        lastLineHash = @"";
    } else {
        lastLineHash = [[self getTerminalNthLine:(lastLine+1) forTerminal: terminal] MD5String];
    }
    
    // get AID/URL
    i = 0;
    [conn sendBytes:"Q" length:1];
    while(i< maxAttempt) {
        // wait for the screen to refresh
        ++i;
        usleep(sleepTime);
        bottomLine = [self getTerminalBottomLine:terminal];
        if([bottomLine containsString:@"請按任意鍵繼續"]){
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
    
    tmp = [self getTerminalNthLine:20 forTerminal: terminal];
    regex = [NSRegularExpression regularExpressionWithPattern:@"文章代碼\\(AID\\): ([a-zA-Z0-9#]{9})" options:0 error:nil];
    match = [regex firstMatchInString:tmp options:NSAnchoredSearch range:NSMakeRange(0, tmp.length)];
    needleRange = [match rangeAtIndex: 1];
    aid = [tmp substringWithRange:needleRange];
    
    tmp = [self getTerminalNthLine:21 forTerminal: terminal];
    regex = [NSRegularExpression regularExpressionWithPattern:@"文章網址: https://www.ptt.cc/bbs/(.+)\\.html" options:0 error:nil];
    match = [regex firstMatchInString:tmp options:NSAnchoredSearch range:NSMakeRange(0, tmp.length)];
    needleRange = [match rangeAtIndex: 1];
    url = [tmp substringWithRange:needleRange];
    
    // send final enter to restore terminal
    [conn sendBytes:"\r" length:1];
    
    if( [author length] == 0 || [aid length] == 0 || [board length] == 0 || [title length] == 0 || [url length] ==0) {
        // show warn
        return;
    } else {
        // check if already in db
        __block BOOL alreadyInDB = NO;
        [[WLTrackDB sharedDBTools].queue inDatabase:^(FMDatabase *db) {
            NSString *sql = [NSString stringWithFormat:@"SELECT COUNT(arID) FROM PttArticle WHERE board='%@' AND aid='%@'", board, aid];
            //FMResultSet *resultSet = [db executeQuery:sql];
            NSUInteger count = [db intForQuery:sql];
            if(count > 0) {
                alreadyInDB = YES;
            }
            //[resultSet close];
            
        }];
        
        if(!alreadyInDB){
            // add to db and show good
            owner = @"ycl94";
            [[WLTrackDB sharedDBTools].queue inDatabase:^(FMDatabase *db) {
                NSString *sql = [NSString stringWithFormat:@"INSERT INTO PttArticle(owner, author, aid, board, title, url, lastLineHash, needTrack) VALUES ('%@','%@','%@','%@','%@','%@','%@', '%d')", owner, author, aid, board, title, url, lastLineHash, 0];
                
                
                [db executeUpdate: sql];
            }];
        }
    }
}

- (NSString *)getTerminalNthLine:(int) i forTerminal:(WLTerminal *) terminal{
    const int line = i - 1;
    return [terminal stringAtIndex:line * [[WLGlobalConfig sharedInstance] column] length:[[WLGlobalConfig sharedInstance] column]] ?: @"";
}

- (void)addTrackArticle:(NSWindow *) window forTerminal:(WLTerminal *) terminal {
    if(![[terminal connection] isPTT] && (![[self getTerminalBottomLine:terminal] containsString:@"文章選讀"] || ![[self getTerminalBottomLine:terminal] containsString:@"目前顯示: 第"])){
        //show warn
    } else {
        [NSThread detachNewThreadSelector:@selector(getArticleDetail:)
                                 toTarget:self
                               withObject:terminal];
    }
}

- (void)openTrackArticleWindow:(NSWindow *)window forTerminal:(WLTerminal *)terminal {
    
    if (!articleWindow) {
        [NSBundle loadNibNamed:kTrackArticlePanelNibFilename owner:self];
    }
    
    [self loadArticleFromDB];
    [idTableView reloadData];
    
    [NSApp beginSheet:articleWindow
       modalForWindow:window
        modalDelegate:nil
       didEndSelector:NULL
          contextInfo:nil];
    
}

- (IBAction)addAtSelectedRow:(id)pId {
    if ([idTableView selectedRow] > -1) {
        NSString * zStr1 = @"Text Cell 1";
        NSString * zStr2 = @"Text Cell 2";
        NSString * zStr3 = @"Text Cell 3";
        WLArticle * zDataObject = [[WLArticle alloc]initWithString1:zStr1
                                                         andString2:zStr2
                                                         andString3:zStr3];
        [self.nsMutaryDataObj insertObject:zDataObject
                                   atIndex:[idTableView selectedRow]];
        [idTableView reloadData];
    } // end if
    
} // end deleteSelectedRow


- (IBAction)deleteSelectedRow:(id)pId {
    if ([idTableView selectedRow] > -1) {
        [self.nsMutaryDataObj removeObjectAtIndex:[idTableView selectedRow]];
        [idTableView reloadData];
    } // end if
} // end deleteSelectedRow

- (IBAction)closeTrackArticleWindow:(id)sender {
    [[self nsMutaryDataObj] removeAllObjects];
    
    [articleWindow endEditingFor:nil];
    [NSApp endSheet:articleWindow];
    [articleWindow orderOut:self];
}

- (void)addRow:(WLArticle *)pDataObj {
    // wont allow user to add article via ui
    return;
    
    //[self.nsMutaryDataObj addObject:pDataObj];
    //[idTableView reloadData];
} // end addRow


- (int)numberOfRowsInTableView:(NSTableView *)pTableViewObj {
    return [self.nsMutaryDataObj count];
} // end numberOfRowsInTableView


- (id) tableView:(NSTableView *)pTableViewObj objectValueForTableColumn:(NSTableColumn *)pTableColumn row:(int)pRowIndex {
    WLArticle * zDataObject = (WLArticle *) [self.nsMutaryDataObj objectAtIndex:pRowIndex];
    if (! zDataObject) {
        NSLog(@"tableView: objectAtIndex:%d = NULL",pRowIndex);
        return NULL;
    } // end if
    //NSLog(@"pTableColumn identifier = %@",[pTableColumn identifier]);
    
    if ([[pTableColumn identifier] isEqualToString:@"Col_ID1"]) {
        return [zDataObject author];
    }
    
    if ([[pTableColumn identifier] isEqualToString:@"Col_ID2"]) {
        return [zDataObject board];
    }
    
    if ([[pTableColumn identifier] isEqualToString:@"Col_ID3"]) {
        return [zDataObject title];
    }
    
    if ([[pTableColumn identifier] isEqualToString:@"Col_ID4"]) {
        return [zDataObject ownTime];
    }
    
    if ([[pTableColumn identifier] isEqualToString:@"Col_ID5"]) {
        if([zDataObject needTrack] == 0){
            return @"N";
        }else {
            return @"Y";
        }
    }

    NSLog(@"***ERROR** dropped through pTableColumn identifiers");
    return NULL;
    
} // end tableView:objectValueForTableColumn:row:


- (void)tableView:(NSTableView *)pTableViewObj setObjectValue:(id)pObject forTableColumn:(NSTableColumn *)pTableColumn row:(int)pRowIndex {
    
    /*WLArticle * zDataObject = (WLArticle *) [self.nsMutaryDataObj objectAtIndex:pRowIndex];
    
    if ([[pTableColumn identifier] isEqualToString:@"Col_ID1"]) {
        [zDataObject setNsStrName1:(NSString *)pObject];
    }
    
    if ([[pTableColumn identifier] isEqualToString:@"Col_ID2"]) {
        [zDataObject setNsStrName2:(NSString *)pObject];
    }
    
    if ([[pTableColumn identifier] isEqualToString:@"Col_ID3"]) {
        [zDataObject setNsStrName3:(NSString *)pObject];
    }*/
} // end tableView:setObjectValue:forTableColumn:row:



@end
