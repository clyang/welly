//
//  KOPostDownloader.h
//  Welly
//
//  Created by K.O.ed on 08-7-21.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class YLTerminal;

@interface KOPostDownloader : NSObject {

}

+ (NSString *) downloadPostFromTerminal: (YLTerminal *) terminal
							  sleepTime: (int) sleepTime
							 maxAttempt: (int) maxAttempt;

@end
