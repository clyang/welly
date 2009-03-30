//
//  KOAutoReplyDelegate.m
//  MacBlueTelnet
//
//  Created by K.O.ed on 08-3-28.
//  Copyright 2008 net9.org. All rights reserved.
//


#import "KOAutoReplyDelegate.h"
#import "YLConnection.h"
#import "YLSite.h"
#import "encoding.h"

@implementation KOAutoReplyDelegate
@synthesize unreadCount = _unreadCount;

- (id)init {
	self = [super init];
	if (self != nil) {
		_unreadMessage = [[NSMutableString alloc] init];
		[_unreadMessage setString:@""];
		_unreadCount = 0;
	}
	return self;
}

- (id)initWithConnection:(YLConnection *)connection {
	[self init];
	[self setConnection:connection];
	return self;
}

- (void)dealloc {
	[_unreadMessage dealloc];
	[super dealloc];
}

- (void)setConnection:(YLConnection *)connection {
	_connection = connection;
	_site = [connection site];
}

- (void)connectionDidReceiveNewMessage:(NSString *)message
						  fromCaller:(NSString *)callerName {
	if ([[_connection site] shouldAutoReply]) {
		// enclose the autoReplyString with two '\r'
		NSString *aString = [NSString stringWithFormat:@"\r%@\r", [[_connection site] autoReplyString]];
		
		// send to the connection
		[_connection sendText:aString];
		
		// now record this message
		[_unreadMessage appendFormat:@"%@\r%@\r\r", callerName, message];
		_unreadCount++;
	}
}

- (void)showUnreadMessagesOnTextView:(NSTextView *)textView {
	[[textView window] setTitle:[NSString stringWithFormat:NSLocalizedString(@"MessageWindowTitle", @"Auto Reply"), _unreadCount]];
	[textView setString:_unreadMessage];
	[textView setTextColor:[NSColor whiteColor]];
	[_unreadMessage setString:@""];
	_unreadCount = 0;
}
@end
