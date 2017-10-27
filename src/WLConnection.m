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
#import "STHTTPRequest.h"
#import "HTMLParser.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (TrimmingAdditions)

- (NSString *)stringByTrimmingTrailingCharactersInSet:(NSCharacterSet *)characterSet {
    NSUInteger location = 0;
    NSUInteger length = [self length];
    unichar charBuffer[length];
    [self getCharacters:charBuffer];
    
    for (length; length > 0; length--) {
        if (![characterSet characterIsMember:charBuffer[length - 1]]) {
            break;
        }
    }
    
    return [self substringWithRange:NSMakeRange(location, length - location)];
}

- (NSString *)MD5String {
    const char *cStr = [self UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), result );
    
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

@end

@interface WLConnection ()
- (void)login;
@end

@implementation WLConnection
@synthesize site = _site;
@synthesize terminal = _terminal;
@synthesize terminalFeeder = _feeder;
@synthesize protocol = _protocol;
@synthesize isConnected = _connected;
@synthesize isPTT = _isPTT;
@synthesize icon = _icon;
@synthesize isProcessing = _isProcessing;
@synthesize objectCount = _objectCount;
@synthesize lastTouchDate = _lastTouchDate;
@synthesize messageCount = _messageCount;
@synthesize messageDelegate = _messageDelegate;
@synthesize tabViewItemController = _tabViewItemController;
@synthesize loginID = _loginID;

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

- (void)setPTT:(BOOL)value {
    _isPTT = value;
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
    
    if([[_site address].lowercaseString containsString:@"ptt.cc"] || [[_site address].lowercaseString containsString:@"ptt2.cc"] || [[_site address].lowercaseString containsString:@"ptt3.cc"]){
        [self setPTT:YES];
    } else if([[_site address].lowercaseString containsString:@"140.112.172."] || [[_site address].lowercaseString containsString:@"13.64.244.51"]) {
        // Take entire class C as PTT is not an optimal solution
        // but I can't come out a good idea. Using nslookup to create
        // a list of ip might be a good idea. But I'm just to lazy to implement it
        // kerker
        [self setPTT:YES];
    }else {
        [self setPTT:NO];
    }
    
    [NSThread detachNewThreadSelector:@selector(login) toTarget:self withObject:nil];
    
    // create a thread to monitor article status
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        STHTTPRequest *r = [STHTTPRequest requestWithURLString:@"https://www.ptt.cc/bbs/MobileComm/M.1509029916.A.E89.html"];
        NSError *error = nil;
        [r addCookieWithName:@"over18" value:@"1"];
        [r setHeaderWithName:@"User-Agent" value:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Safari/604.1.38"];
        
        NSString *body = [r startSynchronousWithError:&error];
        if(r.responseStatus == 200) {
            HTMLParser *parser = [[HTMLParser alloc] initWithString:body error:&error];
            
            if (error) {
                NSLog(@"Error: %@", error);
                //continue;
            }
            HTMLNode *bodyNode = [parser body];
            NSArray *spanNodes = [bodyNode findChildTags:@"span"];
            for (HTMLNode *spanNode in spanNodes) {
                if ([[spanNode getAttributeNamed:@"class"] isEqualToString:@"f3 hl push-userid"]) {
                    NSLog(@"%d", [spanNode contents].length); //Answer to second question
                }
            }
            
            [parser release];            
        } else {
            // just skip and see if we can have good luck on next try
        }
        
    });
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
        if ([addr containsString:@"@"]) {
            NSString *tmp = [addr substringWithRange:NSMakeRange([addr rangeOfString:@"/"].location+2, [addr rangeOfString:@"@"].location-[addr rangeOfString:@"/"].location-2)];
            [self setLoginID:tmp];
        } else {
            [self setLoginID:@""];
        }
    } else if([addr hasPrefix:@"ssh://"] && [addr rangeOfString:@"/" options:NSBackwardsSearch].location > 5) {
        // user wants to autologin with shh
        addr = [addr substringFromIndex:[addr rangeOfString:@":"].location+3];
        NSString *account = [addr substringFromIndex: [addr rangeOfString:@"/"].location+1];
        [self sendText:account];
        [self sendBytes:"\r" length:1];
        [self setLoginID:account];
    }else if ([_feeder grid][[_feeder cursorY]][[_feeder cursorX] - 2].byte == '?') {
        [self sendBytes:"yes\r" length:4];
        sleep(1);
        [self setLoginID:@""];
    } else {
        [self setLoginID:@""];
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
