//
//  YLConnection.h
//  MacBlueTelnet
//
//  Created by Lan Yung-Luen on 12/7/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "YLTerminal.h"

@class YLSite;

@protocol YLConnectionProtocol 
- (void) close ;
- (void) reconnect ;

- (BOOL) connectToSite: (YLSite *) s;
- (BOOL) connectToAddress: (NSString *) addr;
- (BOOL) connectToAddress: (NSString *) addr port: (unsigned int) port ;

- (void) receiveBytes: (unsigned char *) bytes length: (NSUInteger) length ;
- (void) sendBytes: (unsigned char *) msg length: (NSInteger) length ;
- (void) sendMessage: (NSData *) msg;

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
@end

@interface YLConnection : NSObject <YLConnectionProtocol> {
    NSString        * _connectionName;
    NSString        * _connectionAddress;
    NSImage         * _icon;
    BOOL              _processing;
    BOOL              _connected;

    NSDate          * _lastTouchDate;
    
    YLTerminal		* _terminal;
    YLSite          * _site;
}

+ (YLConnection *) connectionWithAddress: (NSString *) addr;
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
- (void) sendText: (id) aString;
- (void) sendText: (id) aString withDelay: (int) microsecond;
@end
