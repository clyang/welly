//
//  YLSite.h
//  MacBlueTelnet
//
//  Created by Lan Yung-Luen on 11/20/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CommonType.h"

@interface YLSite : NSObject {
    NSString *_name;
    NSString *_address;
    YLEncoding _encoding;
    YLANSIColorKey _ansiColorKey;
    BOOL _detectDoubleByte;
	BOOL _autoReply;
	BOOL _enableMouse;
	NSString *_autoReplyString;
}

+ (YLSite *) site;
+ (YLSite *) siteWithDictionary: (NSDictionary *) d ;
- (NSDictionary *) dictionaryOfSite ;

- (BOOL)empty;

- (NSString *)name;
- (void)setName:(NSString *)value;

- (NSString *)address;
- (void)setAddress:(NSString *)value;

- (YLEncoding)encoding;
- (void)setEncoding:(YLEncoding)encoding;

- (YLANSIColorKey)ansiColorKey;
- (void)setAnsiColorKey:(YLANSIColorKey)value;

- (BOOL)detectDoubleByte;
- (void)setDetectDoubleByte:(BOOL)value;

- (BOOL)autoReply;
- (void)setAutoReply:(BOOL)value;

- (BOOL)enableMouse;
- (void)setEnableMouse:(BOOL)value;

- (NSString *)autoReplyString;
- (void)setAutoReplyString:(NSString *)value;

@end
