//
//  YLConnection.h
//  MacBlueTelnet
//
//  Created by Lan Yung-Luen on 12/7/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "XIProtocol.h"

@class YLSite, YLTerminal;

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

- (id)protocol;
- (void)setProtocol:(id)proto;

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
- (void)sendBytes:(const void *)msg length:(NSInteger)length;
- (void)sendText:(NSString *)text;
- (void)sendText:(NSString *)text withDelay:(int)microsecond;

@end
