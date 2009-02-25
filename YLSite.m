//
//  YLSite.m
//  MacBlueTelnet
//
//  Created by Lan Yung-Luen on 11/20/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import "YLSite.h"
#import "YLLGlobalConfig.h"

NSString *const YLSiteNameAttributeName = @"name";
NSString *const YLSiteAddressAttributeName = @"address";
NSString *const YLSiteEncodingAttributeName = @"encoding";
NSString *const YLSiteAnsiColorKeyAttributeName = @"ansicolorkey";
NSString *const YLSiteDetectDoubleByteAttributeName = @"detectdoublebyte";
NSString *const YLSiteEnableMouseAttributeName = @"enablemouse";
NSString *const YLSiteAutoReplyStringAttributeName = @"autoreplystring";

NSString *const KODefaultAutoReplyString = @"DefaultAutoReplyString";
NSString *const KODefaultSiteName = @"DefaultSiteName";

@implementation YLSite

- (id)init {
    if ([super init]) {
        [self setName:NSLocalizedString(KODefaultSiteName, @"Site")];

        [self setAddress:@""];

        //[self setEncoding:YLGBKEncoding];
        [self setEncoding:[[YLLGlobalConfig sharedInstance] defaultEncoding]];
        [self setDetectDoubleByte:[[YLLGlobalConfig sharedInstance] detectDoubleByte]];
        [self setEnableMouse:[[YLLGlobalConfig sharedInstance] enableMouse]];
		//[self setAnsiColorKey:YLEscEscEscANSIColorKey];
        [self setAnsiColorKey: [[YLLGlobalConfig sharedInstance] defaultANSIColorKey]];
        [self setAutoReply:NO];
        [self setAutoReplyString:NSLocalizedString(KODefaultAutoReplyString, @"Site")];
    }
    return self;
}

+ (YLSite *)site {
    return [[YLSite new] autorelease];
}

+ (YLSite *)siteWithDictionary:(NSDictionary *)d {
    YLSite *s = [YLSite site];
    [s setName: [d valueForKey: YLSiteNameAttributeName] ?: @""];
    [s setAddress: [d valueForKey: YLSiteAddressAttributeName] ?: @""];
    [s setEncoding: (YLEncoding)[[d valueForKey: YLSiteEncodingAttributeName] unsignedShortValue]];
    [s setAnsiColorKey: (YLANSIColorKey)[[d valueForKey: YLSiteAnsiColorKeyAttributeName] unsignedShortValue]];
    [s setDetectDoubleByte: [[d valueForKey: YLSiteDetectDoubleByteAttributeName] boolValue]];
	[s setEnableMouse: [[d valueForKey: YLSiteEnableMouseAttributeName] boolValue]];
	[s setAutoReply: NO];
	[s setAutoReplyString: [d valueForKey: YLSiteAutoReplyStringAttributeName] ?: NSLocalizedString(KODefaultAutoReplyString, @"Site")];
    return s;
}

- (NSDictionary *)dictionaryOfSite {
    return [NSDictionary dictionaryWithObjectsAndKeys: [self name] ?: @"",YLSiteNameAttributeName, [self address], YLSiteAddressAttributeName,
            [NSNumber numberWithUnsignedShort: [self encoding]], YLSiteEncodingAttributeName, 
            [NSNumber numberWithUnsignedShort: [self ansiColorKey]], YLSiteAnsiColorKeyAttributeName, 
            [NSNumber numberWithBool: [self detectDoubleByte]], YLSiteDetectDoubleByteAttributeName,
			[NSNumber numberWithBool: [self enableMouse]], YLSiteEnableMouseAttributeName,
			[self autoReplyString] ?: @"", YLSiteAutoReplyStringAttributeName, nil];
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
