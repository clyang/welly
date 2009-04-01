//
//  WLAutoReplyDelegate.h
//  MacBlueTelnet
//
//  Created by K.O.ed on 08-3-28.
//  Copyright 2008 9# Dept. Water. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CommonType.h"

@class YLConnection;
@class YLSite;

@interface WLMessageDelegate : NSObject {
	YLConnection *_connection;
	NSMutableString *_unreadMessage;
	int _unreadCount;
}
@property (readonly) int unreadCount;

- (id)initWithConnection:(YLConnection *)connection;

- (void)setConnection:(YLConnection *)connection;
- (void)connectionDidReceiveNewMessage:(NSString *)message
		   fromCaller:(NSString *)callerName;
- (void)showUnreadMessagesOnTextView:(NSTextView *)textView;
@end