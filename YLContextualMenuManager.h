//
//  YLContextualMenuManager.h
//  MacBlueTelnet
//
//  Created by Lan Yung-Luen on 11/28/07.
//  Copyright 2007 yllan.org. All rights reserved.
//
//  new interface, by boost @ 9#

#import <Cocoa/Cocoa.h>


@interface YLContextualMenuManager : NSObject {

}

+ (NSMenu *)menuWithSelectedString:(NSString*)s;

@end
