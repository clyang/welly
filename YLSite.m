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
NSString *const WLSiteProxyTypeAttributeName = @"proxytype";
NSString *const WLSiteProxyAddressAttributeName = @"proxyaddress";

NSString *const WLDefaultAutoReplyString = @"DefaultAutoReplyString";
NSString *const WLDefaultSiteName = @"DefaultSiteName";

@implementation YLSite
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
    if ([super init]) {
        [self setName:NSLocalizedString(WLDefaultSiteName, @"Site")];

        [self setAddress:@""];

        [self setEncoding:[[YLLGlobalConfig sharedInstance] defaultEncoding]];
        [self setShouldDetectDoubleByte:[[YLLGlobalConfig sharedInstance] shouldDetectDoubleByte]];
        [self setShouldEnableMouse:[[YLLGlobalConfig sharedInstance] shouldEnableMouse]];
        [self setAnsiColorKey:[[YLLGlobalConfig sharedInstance] defaultANSIColorKey]];
        [self setShouldAutoReply:NO];
        [self setAutoReplyString:NSLocalizedString(WLDefaultAutoReplyString, @"Site")];
        [self setProxyType:0];
        [self setProxyAddress:@""];
    }
    return self;
}

+ (YLSite *)site {
    return [[YLSite new] autorelease];
}

+ (YLSite *)siteWithDictionary:(NSDictionary *)d {
    YLSite *s = [YLSite site];
    [s setName:[d valueForKey:YLSiteNameAttributeName] ?: @""];
    [s setAddress:[d valueForKey:YLSiteAddressAttributeName] ?: @""];
    [s setEncoding:(YLEncoding)[[d valueForKey:YLSiteEncodingAttributeName] unsignedShortValue]];
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

- (BOOL)empty {
    return [_address length] == 0;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@:%@", [self name], [self address]];
}

- (id)copyWithZone:(NSZone *)zone {
    YLSite *s = [[YLSite allocWithZone:zone] init];
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
