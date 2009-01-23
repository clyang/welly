//
//  YLConnection.mm
//  MacBlueTelnet
//
//  Created by Lan Yung-Luen on 12/7/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import "YLConnection.h"
#import "YLTerminal.h"
#import "KOTerminalFeeder.h"
#import "encoding.h"
#import "YLLGlobalConfig.h"
#import "YLApplication.h"
#import "TYGrowlBridge.h"
#import "YLController.h"
#import "YLView.h"

@interface YLConnection ()
- (void)login;
@end

@implementation YLConnection

- (id)init {
    if (self == [super initWithContent:self]) {
    }
    return self;
}

- (id)initWithSite:(YLSite *)site {
    if (self == [super initWithContent:self]) {
        [self setSite:site];
        [self setTerminalFeeder:[[KOTerminalFeeder alloc] initWithConnection:self]];
        _autoReplyDelegate = [[KOAutoReplyDelegate alloc] init];
        [_autoReplyDelegate setConnection: self];
    }
    return self;
}

- (void)dealloc {
    [_lastTouchDate release];
    [_icon release];
    [_terminal release];
    [_feeder release];
    [_protocol release];
    [_autoReplyDelegate release];
    [_site release];
    [super dealloc];
}

- (YLSite *)site {
    return _site;
}

- (void)setSite:(YLSite *)value {
    if (_site != value) {
        [_site release];
        _site = [value retain];
    }
}

- (YLTerminal *)terminal {
	return _terminal;
}

- (void) setTerminal:(YLTerminal *)value {
	if (_terminal != value) {
		[_terminal release];
		_terminal = [value retain];
        [_terminal setConnection:self];
		[_feeder setTerminal: _terminal];
	}
}

- (KOTerminalFeeder *)terminalFeeder {
	return _feeder;
}

- (void) setTerminalFeeder:(KOTerminalFeeder *)value {
	if (_feeder != value) {
		[_feeder release];
		_feeder = [value retain];
        //[_feeder setConnection:self];
	}
}

- (id)protocol {
    return _protocol;
}

- (void)setProtocol:(id)value {
    if (_protocol != value) {
        [_protocol release];
        _protocol = [value retain];
    }
}

- (BOOL)connected {
    return _connected;
}

- (void)setConnected:(BOOL)value {
    _connected = value;
    if (_connected) 
        [self setIcon:[NSImage imageNamed:@"online.pdf"]];
    else {
        [self resetMessageCount];
        [self setIcon:[NSImage imageNamed:@"offline.pdf"]];
    }
}

- (NSImage *)icon {
    return _icon;
}

- (void)setIcon:(NSImage *)value {
    if (_icon != value) {
        [_icon release];
        _icon = [value retain];
    }
}

- (BOOL)isProcessing {
    return _processing;
}

- (void)setIsProcessing:(BOOL)value {
    if (_processing != value)
        _processing = value;
}

- (int)objectCount {
    return _objectCount;
}

- (void)setObjectCount:(int)value {
    _objectCount = value;
}

- (NSDate *)lastTouchDate {
    return _lastTouchDate;
}

- (void)setLastTouchDate {
    [_lastTouchDate release];
    _lastTouchDate = [[NSDate date] retain];
}

#pragma mark -
#pragma mark XIProtocol delegate methods

- (void)protocolWillConnect:(id)protocol {
    [self setIsProcessing:YES];
    [self setConnected:NO];
	// TODO: Set a connecting icon here
	[self setIcon:[NSImage imageNamed:@"waiting.pdf"]];
}

- (void)protocolDidConnect:(id)protocol {
    [self setIsProcessing:NO];
    [self setConnected:YES];
    [NSThread detachNewThreadSelector:@selector(login) toTarget:self withObject:nil];
    //[self login];
}

- (void)protocolDidRecv:(id)protocol data:(NSData*)data {
    //[_terminal feedData:data connection:self];
	[_feeder feedData:data connection:self];
}

- (void)protocolWillSend:(id)protocol data:(NSData*)data {
    [self setLastTouchDate];
}

- (void)protocolDidClose:(id)protocol {
    [self setIsProcessing:NO];
    [self setConnected:NO];
	[_feeder clearAll];
    [_terminal clearAll];
}

#pragma mark -
#pragma mark network

- (void)close {
    [_protocol close];
}

- (void)reconnect {
    [_protocol close];
    [_protocol connect:[_site address]];
	[self resetMessageCount];
}

- (void)sendMessage:(NSData *)msg {
    [_protocol send:msg];
}

- (void)sendBytes:(const void *)msg length:(NSInteger)length {
    [_protocol send:[NSData dataWithBytes:msg length:length]];
}

- (void)sendText:(NSString *)s {
    [self sendText:s withDelay:0];
}

- (void)sendText:(NSString *)text withDelay:(int)microsecond {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    // replace all '\n' with '\r' 
    NSString *s = [text stringByReplacingOccurrencesOfString:@"\n" withString:@"\r"];

    // translate into proper encoding of the site
    NSMutableData *data = [NSMutableData data];
    for (int i = 0; i < [s length]; i++) {
        unichar ch = [s characterAtIndex:i];
        char buf[2];
        if (ch < 0x007F) {
            buf[0] = ch;
            [data appendBytes:buf length:1];
        } else {
            YLEncoding encoding = [_site encoding];
            unichar code = (encoding == YLBig5Encoding ? U2B[ch] : U2G[ch]);
            buf[0] = code >> 8;
            buf[1] = code & 0xFF;
            [data appendBytes:buf length:2];
        }
    }

    // Now send the message
    if (microsecond == 0) {
        // send immediately
        [self sendMessage:data];
    } else {
        // send with delay
        const char *buf = (const char *)[data bytes];
        for (int i = 0; i < [data length]; i++) {
            [self sendBytes:buf+i length:1];
            usleep(microsecond);
        }
    }

    [pool release];
}

- (void)login {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    NSString *addr = [_site address];
    const char *account = [addr UTF8String];
    // telnet; send username
    if (![addr hasPrefix:@"ssh"]) {
        char *pe = strchr(account, '@');
        if (pe) {
            char *ps = pe;
            for (; ps >= account; --ps)
                if (*ps == ' ' || *ps == '/')
                    break;
            if (ps != pe) {
                while (_feeder->_cursorY <= 3)
                    sleep(1);
                [self sendBytes:ps+1 length:pe-ps-1];
                [self sendBytes:"\r" length:1];
            }
        }
    }
    // send password
    const char *service = "Welly";
    UInt32 len = 0;
    void *pass = 0;
/*
    len = 8;
    pass = "password";
    SecKeychainAddGenericPassword(nil,
        strlen(service), service,
        strlen(account), account,
        len, pass,
        nil);
*/
    SecKeychainFindGenericPassword(nil,
        strlen(service), service,
        strlen(account), account,
        &len, &pass,
        nil);
    if (len) {
        [self sendBytes:pass length:len];
        [self sendBytes:"\r" length:1];
        SecKeychainItemFreeContent(nil, pass);
    }
	
	[pool release];
}

#pragma mark -
#pragma mark message
- (KOAutoReplyDelegate *)autoReplyDelegate {
	return _autoReplyDelegate;
}

- (int)messageCount {
	return _messageCount;
}

- (void)increaseMessageCount:(int)value {
	// increase the '_messageCount' by 'value'
	if (value <= 0)
		return;
	
	YLLGlobalConfig *config = [YLLGlobalConfig sharedInstance];
	
	// we should let the icon on the deck bounce
	[NSApp requestUserAttention: ([config repeatBounce] ? NSCriticalRequest : NSInformationalRequest)];
	//if (_connection != [[_view selectedTabViewItem] identifier] || ![NSApp isActive]) { /* Not selected tab */
	//[_connection setIcon: [NSImage imageNamed: @"message.pdf"]];
	[config setMessageCount: [config messageCount] + value];
	_messageCount += value;
    [self setObjectCount:_messageCount];
	//} else {
	//	_hasMessage = NO;
	//}
}

- (void)resetMessageCount {
	// reset '_messageCount' to zero
	if (_messageCount <= 0)
		return;
	
	YLLGlobalConfig *config = [YLLGlobalConfig sharedInstance];
	[config setMessageCount: [config messageCount] - _messageCount];
	_messageCount = 0;
    [self setObjectCount:_messageCount];
}

- (void) newMessage: (NSString *)message
		 fromCaller: (NSString *)caller {
	// If there is a new message, we should notify the auto-reply delegate.
	[_autoReplyDelegate newMessage: message
						fromCaller: caller];
	
	YLView *view = [[((YLApplication *)NSApp) controller] getView];
	if (self != [view frontMostConnection] || ![NSApp isActive] || [_site autoReply]) {
		// not in focus
		[self increaseMessageCount: 1];
		// notify auto replied
		if ([_site autoReply]) {
			message = [NSString stringWithFormat: @"%@\n(已自动回复)", message];
		}
		// should invoke growl notification
		[TYGrowlBridge notifyWithTitle:caller
						   description:message
					  notificationName:@"New Message Received"
							  iconData:[NSData data]
							  priority:0
							  isSticky:NO
						  clickContext:self
						 clickSelector:@selector(didClickGrowlNewMessage:)
							identifier:self];
	}
}

- (void)didClickGrowlNewMessage:(id)connection {
    // bring the window to front
    [NSApp activateIgnoringOtherApps:YES];
	YLView *view = [[((YLApplication *)NSApp) controller] getView];
    [[view window] makeKeyAndOrderFront:nil];
    // select the tab
    [view selectTabViewItemWithIdentifier:connection];
}

@end
