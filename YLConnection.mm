//
//  YLConnection.mm
//  MacBlueTelnet
//
//  Created by Lan Yung-Luen on 12/7/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import "YLConnection.h"
#import "encoding.h"


@implementation YLConnection

+ (YLConnection *) connectionWithAddress: (NSString *) addr {
    Class c; 
    if ([addr hasPrefix: @"ssh://"])
        c = NSClassFromString(@"YLSSH");
    else
        c = NSClassFromString(@"YLTelnet");
//    NSLog(@"CONNECTION wih addr: %@ %@", addr, c);
    return (YLConnection *)[[[c alloc] init] autorelease];
}

- (void) dealloc {
    [_lastTouchDate release];
    [_icon release];
    [_connectionName release];
    [_connectionAddress release];
    [_terminal release];
    [super dealloc];
}

- (YLTerminal *) terminal {
	return _terminal;
}

- (void) setTerminal: (YLTerminal *) term {
	if (term != _terminal) {
		[_terminal release];
		_terminal = [term retain];
        [_terminal setConnection: self];
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

- (NSString *)connectionName {
    return _connectionName;
}

- (void)setConnectionName:(NSString *)value {
    if (_connectionName != value) {
        [_connectionName release];
        _connectionName = [value retain];
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

- (NSString *)connectionAddress {
    return _connectionAddress;
}

- (void)setConnectionAddress:(NSString *)value {
    if (_connectionAddress != value) {
        [_connectionAddress release];
        _connectionAddress = [value retain];
    }
}

- (BOOL)isProcessing {
    return _processing;
}

- (void)setIsProcessing:(BOOL)value {
    _processing = value;
}

- (NSDate *) lastTouchDate {
    return _lastTouchDate;
}

- (YLSite *) site {
    return _site;
}

- (void)setSite:(YLSite *)value {
    if (_site != value) {
        [_site release];
        _site = [value retain];
    }
}

- (void) sendText: (id) aString {
	[self sendText: aString withDelay: 0];
}

- (void) sendText: (id) aString withDelay: (int) microsecond{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
	// Send text 'aString' to this connection    
	NSMutableString *mStr = [NSMutableString stringWithString: aString];

	// replace all '\n' with '\r'
    [mStr replaceOccurrencesOfString: @"\n"
                          withString: @"\r"
                             options: NSLiteralSearch
                               range: NSMakeRange(0, [aString length])];
    
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

/* Empty */
- (void) close {}
- (void) reconnect {}

- (BOOL) connectToSite: (YLSite *) s { 
    [self setSite: s];
    return [self connectToAddress: [s address]];
}

- (BOOL) connectToAddress: (NSString *) addr { return YES; }
- (BOOL) connectToAddress: (NSString *) addr port: (unsigned int) port { return YES;}

- (void) receiveBytes: (unsigned char *) bytes length: (NSUInteger) length { }
- (void) sendBytes: (unsigned char *) msg length: (NSInteger) length { }
- (void) sendMessage: (NSData *) msg { }

@end