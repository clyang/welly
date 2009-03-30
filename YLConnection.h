//
//  YLConnection.h
//  MacBlueTelnet
//
//  Created by Lan Yung-Luen on 12/7/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "XIProtocol.h"

@class YLSite, YLTerminal, KOTerminalFeeder, KOAutoReplyDelegate;

// modified by boost @ 9#
// inhert from NSObjectController for PSMTabBarControl
@interface YLConnection : NSObjectController {
    NSImage * _icon;
    BOOL _isProcessing;
    int _objectCount;

    BOOL _connected;

    NSDate *_lastTouchDate;
    
    YLTerminal *_terminal;
	KOTerminalFeeder *_feeder;
    NSObject <XIProtocol> *_protocol;
    YLSite * _site;
	
	KOAutoReplyDelegate *_autoReplyDelegate;
	int _messageCount;
}
@property (readwrite, retain) YLSite *site;
@property (readwrite, retain, setter=setTerminal:) YLTerminal *terminal;
@property (readwrite, retain) KOTerminalFeeder *terminalFeeder;
@property (readwrite, retain) NSObject <XIProtocol> *protocol;
@property (readwrite, assign, setter=setConnected:) BOOL isConnected;
@property (readwrite, retain) NSImage *icon;
@property (readwrite, assign, setter=setProcessing:) BOOL isProcessing;
@property (readwrite, assign) int objectCount;
@property (readonly) NSDate *lastTouchDate;
@property (readonly) int messageCount;
@property (readonly) KOAutoReplyDelegate *autoReplyDelegate;

- (id)initWithSite:(YLSite *)site;

- (void)close;
- (void)reconnect;
- (void)sendMessage:(NSData *)msg;
- (void)sendBytes:(const void *)msg length:(NSInteger)length;
- (void)sendText:(NSString *)text;
- (void)sendText:(NSString *)text 
	   withDelay:(int)microsecond;

/* message */
- (void)didReceiveNewMessage:(NSString *)message
				  fromCaller:(NSString *)caller;
- (void)increaseMessageCount:(int)value;
- (void)resetMessageCount;
- (void)didClickGrowlNewMessage:(id)connection;

@end
