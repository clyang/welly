//
//  WLTrackDB.m
//  Welly
//
//  Created by Cheng-Lin Yang on 2017/10/19.
//  Copyright © 2017年 Welly Group. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WLTrackDB.h"

@implementation WLTrackDB

+ (instancetype)sharedDBTools {
    static WLTrackDB *_instance;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    
    return _instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // store db to "/Volumes/User/OOXX/Library/Application Support"
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
        NSString *dbPath = [paths firstObject];
        
        dbPath = [dbPath stringByAppendingPathComponent:@"Welly/PttArticle.db"];
        _queue = [[FMDatabaseQueue alloc] initWithPath:dbPath];
        
        [self createTables];
    }
    
    return self;
    
}

- (void)createTables {
    [self.queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL result = NO;
        
        result = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS PttArticle ("
                  "arID integer PRIMARY KEY AUTOINCREMENT NOT NULL,"
                  "owner text," // who wants to track this article
                  "author text," // article author
                  "aid text,"
                  "board text,"
                  "title text,"
                  "url text,"
                  "lastLineHash text,"
                  "needTrack integer,"
                  "astatus integer,"
                  "ownTime DATETIME DEFAULT CURRENT_TIMESTAMP"
                  ");"];
        
        if (!result) {
            NSLog(@"Failed to create DB, rollback");
            *rollback = YES;
            return ; // must return
        }
    }];
}



@end
