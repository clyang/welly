//
//  YLConnection.h
//  MacBlueTelnet
//
//  Created by Lan Yung-Luen on 12/7/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "YLTerminal.h"
#import "XIProtocol.h"

@class YLSite;
/*
@protocol YLConnectionProtocol 
- (void) close ;
- (void) reconnect ;

- (BOOL) connectToAddress: (NSString *) addr port: (unsigned int) port ;
- (BOOL) connectToAddress: (NSString *) addr;

- (void) receiveBytes: (unsigned char *) bytes length: (NSUInteger) length ;
- (void) sendBytes: (unsigned char *) msg length: (NSInteger) length ;
*/
/* commented out by boost @ 9# : what the hell...
- (BOOL) connectToAddress: (NSString *) addr port: (unsigned int) port ;
- (void) sendMessage: (NSData *) msg;
- (BOOL) connectToSite: (YLSite *) s;

- (YLTerminal *) terminal ;
- (void) setTerminal: (YLTerminal *) term;

- (BOOL)connected;
- (void)setConnected:(BOOL)value;
- (NSString *)connectionName;
- (void)setConnectionName:(NSString *)value;
- (NSImage *)icon;
- (void)setIcon:(NSImage *)value;
- (NSString *)connectionAddress;
- (void)setConnectionAddress:(NSString *)value;
- (BOOL)isProcessing;
- (void)setIsProcessing:(BOOL)value;

- (NSDate *) lastTouchDate;

- (YLSite *)site;
- (void)setSite:(YLSite *)value;
*/
//@end

// modified by boost @ 9#
// inhert from NSObjectController for PSMTabBarControl
@interface YLConnection : NSObjectController {

    NSImage * _icon;
    BOOL _processing;
    int _objectCount;

    BOOL _connected;

    NSDate *_lastTouchDate;
    
    YLTerminal *_terminal;
    NSObject <XIProtocol> *_protocol;
    YLSite * _site;
}

- (id)initWithSite:(YLSite *)site;
- (YLSite *)site;
- (void)setSite:(YLSite *)value;

- (YLTerminal *)terminal;
- (void)setTerminal:(YLTerminal *)term;

- (NSObject <XIProtocol> *)protocol;
- (void)setProtocol:(NSObject <XIProtocol> *)proto;

- (BOOL)connected;
- (void)setConnected:(BOOL)value;

// for PSMTabBarControl
- (NSImage *)icon;
- (void)setIcon:(NSImage *)value;
- (BOOL)isProcessing;
- (void)setIsProcessing:(BOOL)value;
- (int)objectCount;
- (void)setObjectCount:(int)value;

- (NSDate *)lastTouchDate;
- (void)setLastTouchDate;

- (void)close;
- (void)reconnect;
- (void)sendMessage:(NSData *)msg;
- (void)sendBytes:(unsigned char *)msg length:(NSInteger)length;
- (void)sendText:(NSString *)text;
- (void)sendText:(NSString *)text withDelay:(int)microsecond;

@end
