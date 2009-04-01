//
//  WLPostDownloader.h
//  Welly
//
//  Created by K.O.ed on 08-7-21.
//  Copyright 2008 Welly Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class YLConnection;

@interface WLPostDownloader : NSObject {

}

+ (NSString *)downloadPostFromConnection:(YLConnection *)connection;

@end
