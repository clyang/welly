//
//  YLGrowlDelegate.h
//  MacBlueTelnet
//
//  Created by aqua9 on 20/3/2008.
//  Copyright 2008 TANG Yang. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl-WithInstaller/GrowlApplicationBridge.h>
//#import "YLConnection.h"
#import "CommonType.h"

#define kContextNotificationName @"NotificationName"
#define kContextYLView @"YLView"
#define kContextTabID @"TabID"
#define kContextYLTerminal @"YLTerminal"

enum growlNotificationType {gNotificationMessage};

@class YLView;
@class YLController;
@class YLConnection;

@interface NSObject (YLGrowlNotifyHelper)
	- (void) newMessage: (NSString *)callerName
				message: (NSString *)message 
				context: (NSDictionary *)context;
@end

@interface NSObject (YLController)
	- (void) forceFront;
@end

@interface YLGrowlDelegate : NSObject <GrowlApplicationBridgeDelegate> {
	NSMutableDictionary* m_contexts;
	YLController *ylcontroller;
}

- (void) setup;
- (void) setController : (YLController *)controller;

@end
