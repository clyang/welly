//
//  KOAutoReplyDelegate.m
//  MacBlueTelnet
//
//  Created by K.O.ed on 08-3-28.
//  Copyright 2008 net9.org. All rights reserved.
//


#import "KOMessageDelegate.h"
#import "YLConnection.h"
#import "YLSite.h"
#import "YLView.h"
#import "YLApplication.h"
#import "YLController.h"
#import "encoding.h"
#import "TYGrowlBridge.h"

NSString *const KOAutoReplyGrowlTipFormat = @"AutoReplyGrowlTipFormat";
@interface KOMessageDelegate ()
- (void)didClickGrowlNewMessage:(id)connection;
@end


@implementation KOMessageDelegate
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
	
	YLView *view = [[((YLApplication *)NSApp) controller] telnetView];
	if (_connection != [view frontMostConnection] || ![NSApp isActive] || [_site shouldAutoReply]) {
		// not in focus
		[_connection increaseMessageCount:1];
		// notify auto replied
		if ([_site shouldAutoReply]) {
			message = [NSString stringWithFormat:NSLocalizedString(KOAutoReplyGrowlTipFormat, @"Auto Reply"), message];
		}
		// should invoke growl notification
		[TYGrowlBridge notifyWithTitle:callerName
						   description:message
					  notificationName:@"New Message Received"
							  iconData:[NSData data]
							  priority:0
							  isSticky:NO
						  clickContext:self
						 clickSelector:@selector(didClickGrowlNewMessage:)
							identifier:_connection];
	}
}

- (void)showUnreadMessagesOnTextView:(NSTextView *)textView {
	[[textView window] setTitle:[NSString stringWithFormat:NSLocalizedString(@"MessageWindowTitle", @"Auto Reply"), _unreadCount]];
	[textView setString:_unreadMessage];
	[textView setTextColor:[NSColor whiteColor]];
	[_unreadMessage setString:@""];
	_unreadCount = 0;
}

- (void)didClickGrowlNewMessage:(id)connection {
    // bring the window to front
    [NSApp activateIgnoringOtherApps:YES];
	
	YLView *view = [[((YLApplication *)NSApp) controller] telnetView];
    [[view window] makeKeyAndOrderFront:nil];
    // select the tab
    [view selectTabViewItemWithIdentifier:connection];
}
@end
