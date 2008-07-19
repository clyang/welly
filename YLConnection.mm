//
//  YLConnection.mm
//  MacBlueTelnet
//
//  Created by Lan Yung-Luen on 12/7/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import "YLConnection.h"
#import "YLTerminal.h"
#import "encoding.h"


@implementation YLConnection

- (id)init {
    if (self == [super initWithContent:self]) {
    }
    return self;
}

- (id)initWithSite:(YLSite *)site {
    if (self == [super initWithContent:self]) {
        [self setSite:site];
    }
    return self;
}

- (void)dealloc {
    [_lastTouchDate release];
    [_icon release];
    [_terminal release];
    [_protocol release];
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
        [_terminal setConnection: self];
	}
}

- (NSObject <XIProtocol> *)protocol {
    return _protocol;
}

- (void)setProtocol:(NSObject <XIProtocol> *)value {
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
        [self setIcon: [NSImage imageNamed: @"connect.pdf"]];
    else {
        //[[self terminal] setHasMessage: NO];
		[[self terminal] resetMessageCount];
        [self setIcon: [NSImage imageNamed: @"offline.pdf"]];
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

- (NSDate *) lastTouchDate {
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
}

- (void)protocolDidConnect:(id)protocol {
    [self setIsProcessing:NO];
    [self setConnected:YES];
}

- (void)protocolDidRecv:(id)protocol data:(NSData*)data {
    [_terminal feedBytes:(const unsigned char *)[data bytes] length:[data length] connection:self];
}

- (void)protocolWillSend:(id)protocol data:(NSData*)data {
    [self setLastTouchDate];
}

- (void)protocolDidClose:(id)protocol {
    [self setIsProcessing:NO];
    [self setConnected:NO];
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
}

- (void)sendMessage:(NSData *)msg {
    [_protocol send:msg];
}

- (void)sendBytes:(unsigned char *)msg length:(NSInteger)length {
    [_protocol send:[NSData dataWithBytes:msg length:length]];
}

- (void)sendText:(NSString *)s {
	[self sendText:s withDelay:0];
}

- (void)sendText:(NSString *)text withDelay:(int)microsecond {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
	// Send text 'aString' to this connection    
	NSMutableString *mStr = [NSMutableString stringWithString:text];

	// replace all '\n' with '\r'
    [mStr replaceOccurrencesOfString: @"\n"
                          withString: @"\r"
                             options: NSLiteralSearch
                               range: NSMakeRange(0, [text length])];
    
	// translate into proper encoding of the site
	int i;
	NSMutableData *data = [NSMutableData data];
	for (i = 0; i < [mStr length]; i++) {
		unichar ch = [mStr characterAtIndex: i];
		unsigned char buf[2];
		if (ch < 0x007F) {
			buf[0] = ch;
			[data appendBytes: buf length: 1];
		} else {
            YLEncoding encoding = [_site encoding];
            unichar code = (encoding == YLBig5Encoding ? U2B[ch] : U2G[ch]);
			buf[0] = code >> 8;
			buf[1] = code & 0xFF;
			[data appendBytes: buf length: 2];
		}
	}
	
	// Now send the message
	if (microsecond == 0) {
		// send immediately
        [self sendMessage: data];
    } else {
		// send with delay
        int i;
        unsigned char *buf = (unsigned char *) [data bytes];
        for (i = 0; i < [data length]; i++) {
            [self sendBytes: buf + i length: 1];
            usleep(microsecond);
        }
    }
	
	[pool release];
}

@end
