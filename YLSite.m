//
//  YLSite.m
//  MacBlueTelnet
//
//  Created by Lan Yung-Luen on 11/20/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import "YLSite.h"
#import "YLLGlobalConfig.h"

@implementation YLSite

- (id)init {
    if ([super init]) {
        [self setName:@"Untitled"];
        [self setAddress:@"ssh://id@site:port OR telnet.site"];
        //[self setEncoding:YLGBKEncoding];
        [self setEncoding:[[YLLGlobalConfig sharedInstance] defaultEncoding]];
        [self setDetectDoubleByte:[[YLLGlobalConfig sharedInstance] detectDoubleByte]];
        [self setEnableMouse:[[YLLGlobalConfig sharedInstance] enableMouse]];
		//[self setAnsiColorKey:YLEscEscEscANSIColorKey];
        [self setAnsiColorKey: [[YLLGlobalConfig sharedInstance] defaultANSIColorKey]];
        [self setAutoReply:NO];
        [self setAutoReplyString:@"[Welly] Sorry, I am not around."];
    }
    return self;
}

+ (YLSite *)site {
    return [[YLSite new] autorelease];
}

+ (YLSite *)siteWithDictionary:(NSDictionary *)d {
    YLSite *s = [YLSite site];
    [s setName: [d valueForKey: @"name"] ?: @""];
    [s setAddress: [d valueForKey: @"address"] ?: @""];
    [s setEncoding: (YLEncoding)[[d valueForKey: @"encoding"] unsignedShortValue]];
    [s setAnsiColorKey: (YLANSIColorKey)[[d valueForKey: @"ansicolorkey"] unsignedShortValue]];
    [s setDetectDoubleByte: [[d valueForKey: @"detectdoublebyte"] boolValue]];
	[s setEnableMouse: [[d valueForKey: @"enablemouse"] boolValue]];
	[s setAutoReply: NO];
	[s setAutoReplyString: [d valueForKey: @"autoreplystring"] ?: @"[Welly] Sorry, I am not around."];
    return s;
}

- (NSDictionary *)dictionaryOfSite {
    return [NSDictionary dictionaryWithObjectsAndKeys: [self name] ?: @"", @"name", [self address], @"address",
            [NSNumber numberWithUnsignedShort: [self encoding]], @"encoding", 
            [NSNumber numberWithUnsignedShort: [self ansiColorKey]], @"ansicolorkey", 
            [NSNumber numberWithBool: [self detectDoubleByte]], @"detectdoublebyte",
			[NSNumber numberWithBool: [self enableMouse]], @"enablemouse",
			[self autoReplyString] ?: @"", @"autoreplystring", nil];
}

- (BOOL)empty {
    return [_address length] == 0;
}

- (NSString *)name {
    return [[_name retain] autorelease];
}

- (void)setName:(NSString *)value {
    if (_name != value) {
        [_name release];
        _name = [value copy];
    }
}

- (NSString *)address {
    return [[_address retain] autorelease];
}

- (void)setAddress:(NSString *)value {
    if (_address != value) {
        [_address release];
        _address = [value copy];
    }
}

- (YLEncoding)encoding {
    return _encoding;
}

- (void)setEncoding:(YLEncoding)encoding {
    _encoding = encoding;
}

- (YLANSIColorKey)ansiColorKey {
    return _ansiColorKey;
}

- (void)setAnsiColorKey: (YLANSIColorKey)value {
    _ansiColorKey = value;
}

- (BOOL)detectDoubleByte {
    return _detectDoubleByte;
}

- (void)setDetectDoubleByte:(BOOL)value {
    _detectDoubleByte = value;
}

- (BOOL)enableMouse {
    return _enableMouse;
}

- (void)setEnableMouse:(BOOL)value {
    _enableMouse = value;
}

- (BOOL)autoReply {
	return _autoReply;
}

- (void)setAutoReply:(BOOL)value {
	_autoReply = value;
}

- (NSString *)autoReplyString {
    return [[_autoReplyString retain] autorelease];
}

- (void)setAutoReplyString:(NSString *)value {
    if (_autoReplyString != value) {
        [_autoReplyString release];
        _autoReplyString = [value copy];
    }
}

- (NSString *) description {
    return [NSString stringWithFormat: @"%@:%@", [self name], [self address]];
}

- (id) copyWithZone:(NSZone *)zone {
    YLSite *s = [[YLSite allocWithZone: zone] init];
    [s setName: [self name]];
    [s setAddress: [self address]];
    [s setEncoding: [self encoding]];
    [s setAnsiColorKey: [self ansiColorKey]];
    [s setDetectDoubleByte: [self detectDoubleByte]];
	[s setAutoReply: NO];
	[s setAutoReplyString: [self autoReplyString]];
	[s setEnableMouse:[self enableMouse]];
    return s;
}

@end
