//
//  KOAutoReplyDelegate.h
//  MacBlueTelnet
//
//  Created by K.O.ed on 08-3-28.
//  Copyright 2008 9# Dept. Water. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CommonType.h"

//@class YLController
@class YLConnection;
@class YLSite;
//@class YLEncoding;

@interface KOAutoReplyDelegate : NSObject {
	YLConnection *_connection;
	YLSite *_site;
	NSMutableString *_unreadMessage;
	int _unreadCount;
}

- (id) init;
- (id) initWithConnection: (YLConnection *)connection;
- (void) dealloc;
- (void) setConnection: (YLConnection *)connection;
- (void) newMessage : (NSString *)message
		 fromCaller : (NSString *)callerName;
- (void) showUnreadMessagesOnTextView : (NSTextView *) textView;
- (int) unreadCount;
@end

@interface NSObject (YLConnection)
	- (YLSite *) site;
	- (void) sendMessage: (NSData *) msg;
	- (void) sendText: (id) aString;
	- (void) sendText: (id) aString withDelay: (int) microsecond;
@end

@interface NSObject (YLSite)
	- (YLEncoding) encoding;
	- (BOOL) autoReply;
	- (NSString *) autoReplyString;
@end