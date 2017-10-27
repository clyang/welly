//
//  WLTrackDB.h
//  Welly
//
//  Created by Cheng-Lin Yang on 2017/10/19.
//  Copyright © 2017年 Welly Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FMDB.h"

@interface WLTrackDB : NSObject

+ (instancetype)sharedDBTools;

@property (nonatomic, strong) FMDatabaseQueue *queue;
@property (nonatomic, strong) NSMutableArray *resultArray;
@end
