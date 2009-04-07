//
//  TYProxy.h
//  Welly
//
//  Created by aqua9 on 26/3/2009.
//  Copyright 2009 TANG Yang. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CommonType.h"


@interface WLProxy : NSObject {

}

+ (NSString *)proxyCommandWithAddress:(NSString *)proxyAddress type:(WLProxyType)proxyType;

@end
