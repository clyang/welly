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
#import "WLArticle.h"
#import "WLPTY.h"
#import "STHTTPRequest.h"
#import "HTMLParser.h"
#import <CommonCrypto/CommonDigest.h>
#import "FMDB.h"
#import "WLTrackDB.h"
#import "WLMainFrameController.h"
#import "WLTrackArticlePanel.h"

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
    [self setConnected:NO];
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

- (void)monitorArticleAtBackground {
    if([self isPTT] && ![[self loginID] isEqualToString:@""]){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            // wait 10 secs before we start. This also help use to wait login thread to fill-in _loginID
            [NSThread sleepForTimeInterval:10];
            NSUserNotificationCenter* notification_center = [NSUserNotificationCenter defaultUserNotificationCenter];
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"tag\">([推噓→]).*userid\">(\\w{2,12}).*content\">: (.+)</span><span.*ipdatetime\"> +(.*)" options:NSRegularExpressionSearch error:nil];
            NSString *identifyString;
            NSError *error = nil;
            
            // let's rock'n'roll
            while(_connected){
                __block NSMutableArray *resultArray = [[NSMutableArray alloc] init];
                [[WLTrackDB sharedDBTools].queue inDatabase:^(FMDatabase *db) {
                    NSUInteger count = [db intForQuery:[NSString stringWithFormat:@"SELECT COUNT(arID) FROM PttArticle WHERE owner='%@'", _loginID]];
                    if(count > 0) {
                        FMResultSet *set = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM PttArticle WHERE owner='%@'", _loginID]];
                        
                        while ([set next]) {
                            NSInteger needTrack = [set intForColumn:@"needTrack"];
                            NSInteger astatus = [set intForColumn:@"astatus"];
                            NSString *board = [set stringForColumn:@"board"];
                            NSString *author = [set stringForColumn:@"author"];
                            NSString *title = [set stringForColumn:@"title"];
                            NSString *url = [set stringForColumn:@"url"];
                            NSString *aid = [set stringForColumn:@"aid"];
                            NSString *lastLineHash = [set stringForColumn:@"lastLineHash"];
                            NSString *ownTime = [set stringForColumn:@"ownTime"];
                            
                            if(needTrack>0) {
                                WLArticle *article = [[[WLArticle alloc]initWithString1:board
                                                                             andString2:title
                                                                             andString3:url
                                                                             andString4:aid
                                                                             andString5:ownTime
                                                                             andString6:lastLineHash
                                                                             andString7:author
                                                                             andString8:(int)needTrack
                                                                             andString9:(int)astatus] autorelease];
                                
                                [resultArray addObject:article];
                            }
                        }
                        [set release];
                    }
                }];
                
                if([resultArray count] > 0) {
                    NSTextCheckingResult *result;
                    NSString *combinedString=@"";
                    for( WLArticle* article in resultArray) {
                        if(article.needTrack > 0 && article.astatus < 2) { // need track AND article is not delteed
                            STHTTPRequest *r = [STHTTPRequest requestWithURLString:[NSString stringWithFormat:@"https://www.ptt.cc/bbs/%@.html", article.url]];
                            [r addCookieWithName:@"over18" value:@"1"];
                            [r setHeaderWithName:@"User-Agent" value:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Safari/604.1.38"];
                            NSString *body = [r startSynchronousWithError:&error];
                            if(r.responseStatus == 200) {
#ifdef _DEBUG
                                NSLog(@"Checking: %@", article.title);
#endif
                                HTMLParser *parser = [[HTMLParser alloc] initWithString:body error:&error];
                                
                                if (error) {
                                    NSLog(@"Error: %@", error);
                                    [parser release];
                                    continue;
                                }
                                
                                HTMLNode *bodyNode = [parser body];
                                NSArray *spanNodes = [bodyNode findChildTags:@"div"];
                                NSString *lastComment;
                                BOOL isHashMatchedAtLast, doesHashAppears=NO;
                                for (HTMLNode *spanNode in spanNodes) {
                                    if ([[spanNode getAttributeNamed:@"class"] isEqualToString:@"push"]) {
                                        lastComment = [spanNode rawContents];
                                        result = [regex firstMatchInString:lastComment options:0 range:NSMakeRange(0, [lastComment length])];
                                        
                                        if (result) {
                                            isHashMatchedAtLast = NO;
                                            NSRange group1 = [result rangeAtIndex:1]; // push or dislike
                                            NSRange group2 = [result rangeAtIndex:2]; // user id withspace
                                            NSRange group3 = [result rangeAtIndex:3]; // comment with space
                                            NSRange group4 = [result rangeAtIndex:4]; // user ip (if required by board) + date
                                            
                                            combinedString = [NSString stringWithFormat:@"%@%@%@%@",[lastComment substringWithRange:group1],[lastComment substringWithRange:group2],[lastComment substringWithRange:group3],[lastComment substringWithRange:group4]];
                                            if([[combinedString MD5String] isEqualToString:article.lastLineHash]) {
                                                isHashMatchedAtLast = YES;
                                                doesHashAppears = YES;
                                            } else if([article.lastLineHash isEqualToString:@""]) {
                                                // stored last line is empty, but we now found new comment
                                                doesHashAppears = YES;
                                            }
                                        }
                                    }
                                }
                                
                                if(doesHashAppears && !isHashMatchedAtLast) {
                                    // hash matched AND it's not at the last line
                                    // it means that we have new comment
                                    // need to alert user and update lastLineHash
                                    NSLog(@"Found new comment!!!");
                                    [[WLTrackDB sharedDBTools].queue inDatabase:^(FMDatabase *db) {
                                        [db beginTransaction];
                                        NSString *sql = [NSString stringWithFormat:@"UPDATE PttArticle SET astatus='%d', lastLineHash='%@' WHERE board='%@' AND aid='%@' AND owner='%@'", 1, [combinedString MD5String], article.board, article.aid, _loginID];
                                        [db executeUpdate: sql];
                                        [db commit];
                                    }];
                                    
                                    // alert user
                                    // remove old notification (if user hasn't clicked yet)
                                    identifyString = [NSString stringWithFormat:@"%@%@", article.title, article.lastLineHash];
                                    
                                    for (NSUserNotification* existing_notification in [notification_center deliveredNotifications]) {
                                        NSString* identifier = [existing_notification valueForKey:@"identifier"];
                                        if ([identifier isEqualToString:[identifyString MD5String]]) {
#ifdef _DEBUG
                                            NSLog(@"Found old notifification, remove it!!!");
#endif
                                            [notification_center removeDeliveredNotification:existing_notification];
                                            break;
                                        }
                                    }
                                    
                                    // create a notification with new lastLineofHash
                                    NSUserNotification *notification = [[NSUserNotification alloc] init];
                                    notification.title = NSLocalizedString(@"Tracked article has new comment!", @"Article Tracking");
                                    notification.subtitle = [NSString stringWithFormat:@"%@版 - %@", article.board, article.title];
                                    identifyString = [NSString stringWithFormat:@"%@%@", article.title, [combinedString MD5String]];
                                    notification.identifier = [identifyString MD5String];
                                    
                                    [notification_center deliverNotification:notification];
                                    [notification_center setDelegate:self];
                                } else if (doesHashAppears && isHashMatchedAtLast) {
                                    // hash match but it's at the last line
                                    // do nothing
#ifdef _DEBUG
                                    NSLog(@"%@ nothing new.", article.title);
#endif
                                }
                                [parser release];
                            } else if(r.responseStatus == 404) {
                                // post deleted
                                // disable tracking && change article status
                                [[WLTrackDB sharedDBTools].queue inDatabase:^(FMDatabase *db) {
                                    [db beginTransaction];
                                    NSString *sql = [NSString stringWithFormat:@"UPDATE PttArticle SET needTrack='%d', astatus='%d' WHERE board='%@' AND aid='%@' AND owner='%@'", 0, 2, article.board, article.aid, _loginID];
                                    [db executeUpdate: sql];
                                    [db commit];
                                }];
                                
                                // alert user
                                // remove old notification (if user hasn't clicked yet)
                                identifyString = [NSString stringWithFormat:@"%@%@", article.title, article.lastLineHash];
                                //NSUserNotificationCenter* notification_center = [NSUserNotificationCenter defaultUserNotificationCenter];
                                for (NSUserNotification* existing_notification in [notification_center deliveredNotifications]) {
                                    NSString* identifier = [existing_notification valueForKey:@"identifier"];
                                    if ([identifier isEqualToString:[identifyString MD5String]]) {
                                        [notification_center removeDeliveredNotification:existing_notification];
                                        break;
                                    }
                                }
                                
                                // create a new notification
                                NSUserNotification *notification = [[NSUserNotification alloc] init];
                                notification.title = NSLocalizedString(@"Tracked article has been deleted!", @"Article Tracking");
                                notification.subtitle = [NSString stringWithFormat:@"自動取消追蹤%@版 - %@", article.board, article.title];
                                notification.identifier = [identifyString MD5String];
                                
                                [notification_center deliverNotification:notification];
                                [notification_center setDelegate:self];
                            } else {
                                // just skip and see if we can have good luck on next try
                                continue;
                            }
                        }
                        // sleep 0.5 second before moving to next article
                        [NSThread sleepForTimeInterval:0.8f];
                    }
                    [resultArray removeAllObjects];
                }
                [resultArray release];
                [NSThread sleepForTimeInterval:300];
            } // end for inifinte loop
        });
    }
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
    if([NSApp isRunning]){
        [NSApp activateIgnoringOtherApps:YES];
        
        WLTabView *view = [[WLMainFrameController sharedInstance] tabView];
        [[view window] makeKeyAndOrderFront:nil];
        // select the tab
        [view selectTabViewItemWithIdentifier:[self tabViewItemController]];
        [[WLTrackArticlePanel sharedInstance] openTrackArticleWindow:[view window]
                                                         forTerminal:self.terminal];
        [[NSUserNotificationCenter defaultUserNotificationCenter] removeDeliveredNotification:notification];
    }
    
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
    [self monitorArticleAtBackground];
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

- (void)alertArticleNewComment:(WLArticle *)article
                  fromCaller:(NSString *)caller {
    // If there is a new message, we should notify the auto-reply delegate.
    [_messageDelegate connectionDidReceiveArticleAlert:article
                                          fromCaller:caller];
}

@end
