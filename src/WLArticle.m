//  MyDataObject.m
//  025-NSTableView
//
#import "WLArticle.h"

@implementation WLArticle
@synthesize board;
@synthesize title;
@synthesize url;
@synthesize aid;
@synthesize ownTime;
@synthesize lastLineHash;
@synthesize author;
@synthesize needTrack;
@synthesize astatus;

- (id)initWithString1:(NSString *)pStr1 andString2:(NSString *)pStr2
           andString3:(NSString *)pStr3
           andString4:(NSString *)pStr4
           andString5:(NSString *)pStr5
           andString6:(NSString *)pStr6
           andString7:(NSString *)pStr7
           andString8:(int)pStr8
           andString9:(int)pStr9
{
    if (! (self = [super init])) {
        NSLog(@"MyDataObject **** ERROR : [super init] failed ***");
        return self;
    } // end if
    
    self.board = pStr1;
    self.title = pStr2;
    self.url = pStr3;
    self.aid = pStr4;
    self.ownTime = pStr5;
    self.lastLineHash = pStr6;
    self.author = pStr7;
    self.needTrack = pStr8;
    self.astatus = pStr9;
    
    return self;
    
} // end initWithString1:andString2:andString3:
@end
