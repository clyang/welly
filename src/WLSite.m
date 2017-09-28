//
//  WLSite.h
//  Welly
//
//  YLSite.m
//  MacBlueTelnet
//
//  Created by Lan Yung-Luen on 11/20/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import "WLSite.h"
#import "WLGlobalConfig.h"

NSString *const YLSiteNameAttributeName = @"name";
NSString *const YLSiteAddressAttributeName = @"address";
NSString *const YLSiteEncodingAttributeName = @"encoding";
NSString *const YLSiteAnsiColorKeyAttributeName = @"ansicolorkey";
NSString *const YLSiteDetectDoubleByteAttributeName = @"detectdoublebyte";
NSString *const YLSiteEnableMouseAttributeName = @"enablemouse";
NSString *const YLSiteAutoReplyStringAttributeName = @"autoreplystring";
NSString *const WLSiteProxyTypeAttributeName = @"proxytype";
NSString *const WLSiteProxyAddressAttributeName = @"proxyaddress";

NSString *const WLDefaultAutoReplyString = @"DefaultAutoReplyString";
NSString *const WLDefaultSiteName = @"DefaultSiteName";

@implementation WLSite
@synthesize name = _name;
@synthesize address = _address;
@synthesize encoding = _encoding;
@synthesize ansiColorKey = _ansiColorKey;
@synthesize shouldDetectDoubleByte = _shouldDetectDoubleByte;
@synthesize shouldAutoReply = _shouldAutoReply;
@synthesize autoReplyString = _autoReplyString;
@synthesize shouldEnableMouse = _shouldEnableMouse;
@synthesize proxyType = _proxyType;
@synthesize proxyAddress = _proxyAddress;

- (id)init {
	self = [super init];
    if (self) {
        [self setName:NSLocalizedString(WLDefaultSiteName, @"Site")];

        [self setAddress:@""];

        [self setEncoding:[[WLGlobalConfig sharedInstance] defaultEncoding]];
        [self setShouldDetectDoubleByte:[[WLGlobalConfig sharedInstance] shouldDetectDoubleByte]];
        [self setShouldEnableMouse:[[WLGlobalConfig sharedInstance] shouldEnableMouse]];
        [self setAnsiColorKey:[[WLGlobalConfig sharedInstance] defaultANSIColorKey]];
        [self setShouldAutoReply:NO];
        [self setAutoReplyString:NSLocalizedString(WLDefaultAutoReplyString, @"Site")];
        [self setProxyType:0];
        [self setProxyAddress:@""];
    }
    return self;
}

+ (WLSite *)site {
    return [[WLSite new] autorelease];
}

+ (WLSite *)siteWithDictionary:(NSDictionary *)d {
    WLSite *s = [WLSite site];
    [s setName:[d valueForKey:YLSiteNameAttributeName] ?: @""];
    [s setAddress:[d valueForKey:YLSiteAddressAttributeName] ?: @""];
    [s setEncoding:(WLEncoding)[[d valueForKey:YLSiteEncodingAttributeName] unsignedShortValue]];
    [s setAnsiColorKey:(YLANSIColorKey)[[d valueForKey:YLSiteAnsiColorKeyAttributeName] unsignedShortValue]];
    [s setShouldDetectDoubleByte:[[d valueForKey:YLSiteDetectDoubleByteAttributeName] boolValue]];
	[s setShouldEnableMouse:[[d valueForKey:YLSiteEnableMouseAttributeName] boolValue]];
	[s setShouldAutoReply:NO];
	[s setAutoReplyString:[d valueForKey:YLSiteAutoReplyStringAttributeName] ?: NSLocalizedString(WLDefaultAutoReplyString, @"Site")];
    [s setProxyType:[[d valueForKey:WLSiteProxyTypeAttributeName] unsignedShortValue]];
    [s setProxyAddress:[d valueForKey:WLSiteProxyAddressAttributeName] ?: @""];
    return s;
}

- (NSDictionary *)dictionaryOfSite {
    return [NSDictionary dictionaryWithObjectsAndKeys:[self name] ?: @"",YLSiteNameAttributeName, [self address], YLSiteAddressAttributeName,
            [NSNumber numberWithUnsignedShort:[self encoding]], YLSiteEncodingAttributeName, 
            [NSNumber numberWithUnsignedShort:[self ansiColorKey]], YLSiteAnsiColorKeyAttributeName, 
            [NSNumber numberWithBool:[self shouldDetectDoubleByte]], YLSiteDetectDoubleByteAttributeName,
			[NSNumber numberWithBool:[self shouldEnableMouse]], YLSiteEnableMouseAttributeName,
			[self autoReplyString] ?: @"", YLSiteAutoReplyStringAttributeName,
            [NSNumber numberWithUnsignedShort:[self proxyType]], WLSiteProxyTypeAttributeName,
            [self proxyAddress] ?: @"", WLSiteProxyAddressAttributeName, nil];
}

- (BOOL)isDummy {
    return [_address length] == 0;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@:%@", [self name], [self address]];
}

- (id)copyWithZone:(NSZone *)zone {
    WLSite *s = [[WLSite allocWithZone:zone] init];
    [s setName:[self name]];
    [s setAddress:[self address]];
    [s setEncoding:[self encoding]];
    [s setAnsiColorKey:[self ansiColorKey]];
    [s setShouldDetectDoubleByte:[self shouldDetectDoubleByte]];
	[s setShouldAutoReply:NO];
	[s setAutoReplyString:[self autoReplyString]];
	[s setShouldEnableMouse:[self shouldEnableMouse]];
    [s setProxyType:[self proxyType]];
    [s setProxyAddress:[self proxyAddress]];
    return s;
}

@end
