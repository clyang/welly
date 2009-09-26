//
//  WLPostDownloader.h
//  Welly
//
//  Created by K.O.ed on 08-7-21.
//  Copyright 2008 Welly Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class WLConnection;

@interface WLPostDownloader : NSObject {

}

+ (NSString *)downloadPostFromConnection:(WLConnection *)connection;

@end
