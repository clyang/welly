//
//  YLConnection.h
//  MacBlueTelnet
//
//  Created by Lan Yung-Luen on 12/7/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WLProtocol.h"

@class YLSite, YLTerminal, WLTerminalFeeder, WLMessageDelegate;

// modified by boost @ 9#
// inhert from NSObjectController for PSMTabBarControl
@interface YLConnection : NSObjectController {
    NSImage * _icon;
    BOOL _isProcessing;
    int _objectCount;

    BOOL _connected;

    NSDate *_lastTouchDate;
    
    YLTerminal *_terminal;
	WLTerminalFeeder *_feeder;
    NSObject <WLProtocol> *_protocol;
    YLSite * _site;
	
	WLMessageDelegate *_messageDelegate;
	int _messageCount;
}
@property (readwrite, retain) YLSite *site;
@property (readwrite, retain, setter=setTerminal:) YLTerminal *terminal;
@property (readwrite, retain) WLTerminalFeeder *terminalFeeder;
@property (readwrite, retain) NSObject <WLProtocol> *protocol;
@property (readwrite, assign, setter=setConnected:) BOOL isConnected;
@property (readonly) NSDate *lastTouchDate;
@property (readonly) int messageCount;
@property (readonly) WLMessageDelegate *messageDelegate;
// for PSMTabBarControl
@property (readwrite, retain) NSImage *icon;
@property (readwrite, assign) BOOL isProcessing;
@property (readwrite, assign) int objectCount;

- (id)initWithSite:(YLSite *)site;

- (void)close;
- (void)reconnect;
- (void)sendMessage:(NSData *)msg;
- (void)sendBytes:(const void *)buf length:(NSInteger)length;
- (void)sendText:(NSString *)text;
- (void)sendText:(NSString *)text withDelay:(int)microsecond;

/* message */
- (void)didReceiveNewMessage:(NSString *)message
				  fromCaller:(NSString *)caller;
- (void)increaseMessageCount:(int)value;
- (void)resetMessageCount;
@end
