//
//  TYProxy.m
//  Welly
//
//  Created by aqua9 on 26/3/2009.
//  Copyright 2009 TANG Yang. All rights reserved.
//

#include <SystemConfiguration/SystemConfiguration.h>
#import "WLProxy.h"


@implementation WLProxy

// source code adapted from http://developer.apple.com/qa/qa2001/qa1234.html
Boolean GetProxySetting(const char *protocol, char *host, size_t hostSize, UInt16 *port)
// Returns the current HTTP proxy settings as a C string 
// (in the buffer specified by host and hostSize) and 
// a port number.
{
    Boolean             result;
    CFDictionaryRef     proxyDict;
    CFNumberRef         enableNum;
    int                 enable;
    CFStringRef         hostStr;
    CFNumberRef         portNum;
    int                 portInt;
    
    assert(host != NULL);
    assert(port != NULL);
    
    // Get the dictionary.
    
    proxyDict = SCDynamicStoreCopyProxies(NULL);
    result = (proxyDict != NULL);
    
    // Get the enable flag.  This isn't a CFBoolean, but a CFNumber.
    
    if (result) {
        // kSCPropNetProxiesHTTPEnable
        enableNum = (CFNumberRef) CFDictionaryGetValue(proxyDict,
                                                       [NSString stringWithFormat:@"%sEnable", protocol]);
        
        result = (enableNum != NULL)
        && (CFGetTypeID(enableNum) == CFNumberGetTypeID());
    }
    if (result) {
        result = CFNumberGetValue(enableNum, kCFNumberIntType,
                                  &enable) && (enable != 0);
    }
    
    // Get the proxy host.  DNS names must be in ASCII.  If you 
    // put a non-ASCII character  in the "Secure Web Proxy"
    // field in the Network preferences panel, the CFStringGetCString
    // function will fail and this function will return false.
    
    if (result) {
        // kSCPropNetProxiesHTTPProxy
        hostStr = (CFStringRef) CFDictionaryGetValue(proxyDict,
                                                     [NSString stringWithFormat:@"%sProxy", protocol]);
        
        result = (hostStr != NULL)
        && (CFGetTypeID(hostStr) == CFStringGetTypeID());
    }
    if (result) {
        result = CFStringGetCString(hostStr, host,
                                    (CFIndex) hostSize, kCFStringEncodingASCII);
    }
    
    // Get the proxy port.
    
    if (result) {
        // kSCPropNetProxiesHTTPPort
        portNum = (CFNumberRef) CFDictionaryGetValue(proxyDict,
                                                     [NSString stringWithFormat:@"%sPort", protocol]);
        
        result = (portNum != NULL)
        && (CFGetTypeID(portNum) == CFNumberGetTypeID());
    }
    if (result) {
        result = CFNumberGetValue(portNum, kCFNumberIntType, &portInt);
    }
    if (result) {
        *port = (UInt16) portInt;
    }
    
    // Clean up.
    
    if (proxyDict != NULL) {
        CFRelease(proxyDict);
    }
    if ( ! result ) {
        *host = 0;
        *port = 0;
    }
    return result;
}

+ (NSString *)proxyCommandWithAddress:(NSString *)proxyAddress
                                 type:(WLProxyType)proxyType {
    const size_t hostSize = 64;
    char host[hostSize];
    UInt16 port;
    if (proxyType == WLNoneProxy)
        return nil;
    if (proxyType == WLAutoProxy) {
        GetProxySetting("SOCKS", host, hostSize, &port);
        if (*host) {
            if (port == 0) port = 1080;
            return [NSString stringWithFormat:@"ProxyCommand=/usr/bin/nc -x %s:%hu %%h %%p", host, port];
        }
        GetProxySetting("HTTP", host, hostSize, &port);
        if (*host) {
            if (port == 0) port = 80;
            return [NSString stringWithFormat:@"ProxyCommand=/usr/bin/nc -X connect -x %s:%hu %%h %%p", host, port];
        }
        GetProxySetting("HTTPS", host, hostSize, &port);
        if (*host) {
            if (port == 0) port = 443;
            return [NSString stringWithFormat:@"ProxyCommand=/usr/bin/nc -X connect -x %s:%hu %%h %%p", host, port];
        }
        return nil;
    }
    NSUInteger colon = [proxyAddress rangeOfString:@":"].location;
    NSString *hostString, *portString;
    if (colon == NSNotFound) {
        if ([proxyAddress length] != 0)
            hostString = [NSString stringWithString:proxyAddress];
        else
            hostString = @"localhost";
        switch (proxyType) {
            case WLSocksProxy:
                portString = @"1080";                
                break;
            case WLHttpProxy:
                portString = @"80";
                break;
            case WLHttpsProxy:
                portString = @"443";
            default:
                break;
        }
    } else {
        hostString = [proxyAddress substringToIndex:colon];
        portString = [proxyAddress substringFromIndex:colon + 1];
    }
    switch (proxyType) {
        case WLSocksProxy:
            return [NSString stringWithFormat:@"ProxyCommand=/usr/bin/nc -x %@:%@ %%h %%p", hostString, portString];
        case WLHttpProxy:
        case WLHttpsProxy:
            return [NSString stringWithFormat:@"ProxyCommand=/usr/bin/nc -X connect -x %@:%@ %%h %%p", hostString, portString];
        default:
            break;
    }
    return nil;
}

@end
