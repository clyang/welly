//
//  WLConnection.h
//  Welly
//
//  YLConnection.mm
//  MacBlueTelnet
//
//  Created by Lan Yung-Luen on 12/7/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import "WLConnection.h"
#import "WLTerminal.h"
#import "WLTerminalFeeder.h"
#import "WLEncoder.h"
#import "WLGlobalConfig.h"
#import "WLMessageDelegate.h"
#import "WLSite.h"
#import "WLPTY.h"

@interface WLConnection ()
- (void)login;
@end

@implementation WLConnection
@synthesize site = _site;
@synthesize terminal = _terminal;
@synthesize terminalFeeder = _feeder;
@synthesize protocol = _protocol;
@synthesize isConnected = _connected;
@synthesize icon = _icon;
@synthesize isProcessing = _isProcessing;
@synthesize objectCount = _objectCount;
@synthesize lastTouchDate = _lastTouchDate;
@synthesize messageCount = _messageCount;
@synthesize messageDelegate = _messageDelegate;
@synthesize tabViewItemController = _tabViewItemController;

- (id)initWithSite:(WLSite *)site {
	self = [self init];
    if (self) {
		// Create a feeder to parse content from the connection
		_feeder = [[WLTerminalFeeder alloc] initWithConnection:self];

        [self setSite:site];
        if (![site isDummy]) {
			// WLPTY as the default protocol (a proxy)
			WLPTY *protocol = [[WLPTY new] autorelease];
			[self setProtocol:protocol];
			[protocol setDelegate:self];
			[protocol setProxyType:[site proxyType]];
			[protocol setProxyAddress:[site proxyAddress]];
			[protocol connect:[site address]];
		}
		
		// Setup the message delegate
        _messageDelegate = [[WLMessageDelegate alloc] init];
        [_messageDelegate setConnection: self];
    }
    return self;
}

- (void)dealloc {
    [_lastTouchDate release];
    [_icon release];
    [_terminal release];
    [_feeder release];
    [_protocol release];
    [_messageDelegate release];
    [_site release];
    [super dealloc];
}

#pragma mark -
#pragma mark Accessor
- (void)setTerminal:(WLTerminal *)value {
	if (_terminal != value) {
		[_terminal release];
		_terminal = [value retain];
        [_terminal setConnection:self];
		[_feeder setTerminal:_terminal];
	}
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

- (void)setLastTouchDate {
    [_lastTouchDate release];
    _lastTouchDate = [[NSDate date] retain];
}

#pragma mark -
#pragma mark WLProtocol delegate methods
- (void)protocolWillConnect:(id)protocol {
    [self setIsProcessing:YES];
    [self setConnected:NO];
    [self setIcon:[NSImage imageNamed:@"waiting.pdf"]];
}

- (void)protocolDidConnect:(id)protocol {
    [self setIsProcessing:NO];
    [self setConnected:YES];
    [NSThread detachNewThreadSelector:@selector(login) toTarget:self withObject:nil];
    //[self login];
}

- (void)protocolDidRecv:(id)protocol 
				   data:(NSData*)data {
	[_feeder feedData:data connection:self];
}

- (void)protocolWillSend:(id)protocol 
					data:(NSData*)data {
    [self setLastTouchDate];
}

- (void)protocolDidClose:(id)protocol {
    [self setIsProcessing:NO];
    [self setConnected:NO];
	[_feeder clearAll];
    [_terminal clearAll];
}

#pragma mark -
#pragma mark Network
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

- (void)sendBytes:(const void *)buf 
		   length:(NSInteger)length {
    NSData *data = [[NSData alloc] initWithBytes:buf length:length];
    [self sendMessage:data];
    [data release];
}

- (void)sendText:(NSString *)s {
    [self sendText:s withDelay:0];
}

- (void)sendText:(NSString *)text 
	   withDelay:(int)microsecond {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    // replace all '\n' with '\r' 
    NSString *s = [text stringByReplacingOccurrencesOfString:@"\n" withString:@"\r"];

    // translate into proper encoding of the site
    NSMutableData *data = [NSMutableData data];
	WLEncoding encoding = [_site encoding];
    for (int i = 0; i < [s length]; i++) {
        unichar ch = [s characterAtIndex:i];
        char buf[2];
        if (ch < 0x007F) {
            buf[0] = ch;
            [data appendBytes:buf length:1];
        } else {
            unichar code = [WLEncoder fromUnicode:ch encoding:encoding];
			if (code != 0) {
				buf[0] = code >> 8;
				buf[1] = code & 0xFF;
			} else {
                if (ch == 8943 && encoding == WLGBKEncoding) {
                    // hard code for the ellipsis
                    buf[0] = '\xa1';
                    buf[1] = '\xad';
                } else if (ch != 0) {
					buf[0] = ' ';
					buf[1] = ' ';
				}
			}
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
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
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
                while ([_feeder cursorY] <= 3)
                    sleep(1);
                [self sendBytes:ps+1 length:pe-ps-1];
                [self sendBytes:"\r" length:1];
            }
        }
    } else if ([_feeder grid][[_feeder cursorY]][[_feeder cursorX] - 2].byte == '?') {
        [self sendBytes:"yes\r" length:4];
        sleep(1);
    }
    // send password
    const char *service = "Welly";
    UInt32 len = 0;
    void *pass = 0;
	
    OSStatus status = SecKeychainFindGenericPassword(nil,
        strlen(service), service,
        strlen(account), account,
        &len, &pass,
        nil);
    if (status == noErr) {
        [self sendBytes:pass length:len];
        [self sendBytes:"\r" length:1];
		SecKeychainItemFreeContent(nil, pass);
    }
	
	[pool release];
}

#pragma mark -
#pragma mark Message
- (void)increaseMessageCount:(NSInteger)value {
	// increase the '_messageCount' by 'value'
	if (value <= 0)
		return;
	
	WLGlobalConfig *config = [WLGlobalConfig sharedInstance];
	
	// we should let the icon on the deck bounce
	[NSApp requestUserAttention: ([config shouldRepeatBounce] ? NSCriticalRequest : NSInformationalRequest)];
	[config setMessageCount:[config messageCount] + value];
	_messageCount += value;
    [self setObjectCount:_messageCount];
}

// reset '_messageCount' to zero
- (void)resetMessageCount {
	if (_messageCount <= 0)
		return;
	
	WLGlobalConfig *config = [WLGlobalConfig sharedInstance];
	[config setMessageCount:[config messageCount] - _messageCount];
	_messageCount = 0;
    [self setObjectCount:_messageCount];
}

- (void)didReceiveNewMessage:(NSString *)message
				  fromCaller:(NSString *)caller {
	// If there is a new message, we should notify the auto-reply delegate.
	[_messageDelegate connectionDidReceiveNewMessage:message
										  fromCaller:caller];
}

@end
