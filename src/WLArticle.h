//  MyDataObject.h
//  025-NSTableView
//
#import <Cocoa/Cocoa.h>

@interface WLArticle : NSObject {
    NSString *board;
    NSString *title;
    NSString *url;
    NSString *aid;
    NSString *ownTime;
    NSString *lastLineHash;
    NSString *author;
    int needTrack;

}

@property (copy) NSString *board;
@property (copy) NSString *title;
@property (copy) NSString *url;
@property (copy) NSString *aid;
@property (copy) NSString *ownTime;
@property (copy) NSString *lastLineHash;
@property (copy) NSString *author;
@property(nonatomic, assign) int needTrack;

- (id)initWithString1:(NSString *)pStr1 andString2:(NSString *)pStr2
           andString3:(NSString *)pStr3
           andString4:(NSString *)pStr4
           andString5:(NSString *)pStr5
           andString6:(NSString *)pStr6
           andString7:(NSString *)pStr7
           andString8:(int)pStr8;

@end
