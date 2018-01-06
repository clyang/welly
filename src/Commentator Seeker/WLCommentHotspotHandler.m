//
//  WLCommentHotspotHandler.m
//  Welly
//
//  Created by Cheng-Lin Yang on 2018/1/6.
//  Copyright © 2018年 Welly Group. All rights reserved.
//

#import "WLCommentHotspotHandler.h"
#import "WLMouseBehaviorManager.h"
#import <CommonCrypto/CommonDigest.h>

#import "WLTerminalView.h"
#import "WLConnection.h"
#import "WLTerminal.h"
#import "WLGlobalConfig.h"
#import "WLEffectView.h"

@implementation NSString (TrimmingAdditions)

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

@implementation WLCommentHotspotHandler
#pragma mark -
#pragma mark Event Handler
- (void)mouseEntered:(NSEvent *)theEvent {
    if([_view isMouseActive]) {
        [[_view effectView] drawCommentBox:[[theEvent trackingArea] rect]];
    }
}

- (void)mouseExited:(NSEvent *)theEvent {
    [[_view effectView] clearCommentBox];
}

#pragma mark -
#pragma mark Generate User Info
- (NSDictionary *)userInfo {
    return [NSDictionary dictionaryWithObject:self forKey:WLMouseHandlerUserInfoName];
}

#pragma mark -
#pragma mark Update State
- (void)addCommentRect:(int)thisFloor
              row:(int)r
           column:(int)c
           length:(int)length {
    /* comment tooltip */
    NSRect rect = [_view rectAtRow:r column:c height:1 width:length];
    NSString *tooltip = [NSString stringWithFormat:@"%d F", thisFloor];
    NSToolTipTag tipTag = [_view addToolTipRect:rect owner:_manager userData:tooltip];
    NSMutableArray *_commentTooltipsSet = [_view getCommentTooltipsArray];
    [_commentTooltipsSet addObject:tipTag];
    
    NSDictionary *userInfo = [self userInfo];
    [_trackingAreas addObject:[_manager addTrackingAreaWithRect:rect userInfo:userInfo]];
}

- (void)updateCommentStateForRow:(int)r {
    //[self addIPRect:ip row:r column:start length:length];
    int i, floorCount;
    unichar idBuf[13]; // ptt id max length = 12
    cell *currRow = [[_view frontMostTerminal] cellsOfRow:r];
    
    if(currRow[75].byte == ':' && (
                                   (currRow[0].byte == 0xA1 && currRow[1].byte == 0xF7) ||
                                   (currRow[0].byte == 0xB1 && currRow[1].byte == 0xC0) ||
                                   (currRow[0].byte == 0xBC && currRow[1].byte == 0x4E) )
       ){
        // obtain comment's userid
        for(i=3;  currRow[i].byte != ':' && i < 15 ; ++i){
            idBuf[i-3] = currRow[i].byte;
        }
        floorCount = [self getCommentFloor:r];
        NSString *commentID = [[NSString stringWithCharacters:idBuf length:i-3] stringByReplacingOccurrencesOfString:@" " withString:@""];
        [self addCommentRect:floorCount row:r column:3 length:commentID.length];
    }
    
}

- (int)getCommentFloor:(int)r {
    int i=0;
    
    NSMutableArray *_commentHashTable = [_view getCommentHashTableArray];
    
    NSString* row = [[_view frontMostTerminal] stringAtIndex:r * [[WLGlobalConfig sharedInstance] column] length:[[WLGlobalConfig sharedInstance] column]] ?: @"";
    if([_commentHashTable count] == 0) {
        [_commentHashTable addObject: [row MD5String]];
        return 1;
    } else {
        for(id md5 in _commentHashTable){
            ++i;
            if([(NSString *)md5 isEqualToString:[row MD5String]]){
                return i;
            }
        }
        // not in table, add it
        ++i;
        [_commentHashTable addObject: [row MD5String]];
        return i;
    }
}

- (void)clearTooltipsAndTrackingAreas {
    NSMutableArray *_commentTooltipsSet = [_view getCommentTooltipsArray];
    
    for(id tipTag in _commentTooltipsSet){
        [_view removeToolTip:(NSToolTipTag)tipTag];
    }
    
    [self removeAllTrackingAreas];
}

- (BOOL)shouldUpdate {
    return YES;
}

- (void)update {
    //[self clear];
    
    if (![_view isConnected]) {
        return;
    }


    NSMutableArray *_commentTooltipsSet = [_view getCommentTooltipsArray];
    NSMutableArray *_commentHashTable = [_view getCommentHashTableArray];
    
    NSString *lastLine = [[_view frontMostTerminal] stringAtIndex:23 * [[WLGlobalConfig sharedInstance] column] length:[[WLGlobalConfig sharedInstance] column]] ?: @"";
    
    [self clearTooltipsAndTrackingAreas];
    if([[_view frontMostTerminal] bbsState].state != BBSViewPost){
        [_commentTooltipsSet removeAllObjects];
        [_commentHashTable removeAllObjects];
        return;
    } else if ([lastLine containsString:@"第 1/"]) {
        [_commentTooltipsSet removeAllObjects];
        [_commentHashTable removeAllObjects];
    }
    
    for (int r = 0; r < _maxRow; ++r) {
        [self updateCommentStateForRow:r];
    }
}
@end

@implementation NSObject(NSToolTipOwner)
- (NSString *)view:(NSView *)view
  stringForToolTip:(NSToolTipTag)tag
             point:(NSPoint)point
          userData:(void *)userData {
    return (NSString *)userData;
}
@end

