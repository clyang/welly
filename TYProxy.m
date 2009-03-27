//
//  TYProxy.m
//  Welly
//
//  Created by aqua9 on 26/3/2009.
//  Copyright 2009 TANG Yang. All rights reserved.
//

#include <SystemConfiguration/SystemConfiguration.h>
#import "TYProxy.h"


@implementation TYProxy

// source code adapted from http://developer.apple.com/qa/qa2001/qa1234.html
Boolean GetHTTPProxySetting(char *host, size_t hostSize, UInt16 *port)
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
        enableNum = (CFNumberRef) CFDictionaryGetValue(proxyDict,
                                                       kSCPropNetProxiesHTTPEnable);
        
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
        hostStr = (CFStringRef) CFDictionaryGetValue(proxyDict,
                                                     kSCPropNetProxiesHTTPProxy);
        
        result = (hostStr != NULL)
        && (CFGetTypeID(hostStr) == CFStringGetTypeID());
    }
    if (result) {
        result = CFStringGetCString(hostStr, host,
                                    (CFIndex) hostSize, kCFStringEncodingASCII);
    }
    
    // Get the proxy port.
    
    if (result) {
        portNum = (CFNumberRef) CFDictionaryGetValue(proxyDict,
                                                     kSCPropNetProxiesHTTPPort);
        
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

Boolean GetHTTPSProxySetting(char *host, size_t hostSize, UInt16 *port)
// Returns the current HTTPS proxy settings as a C string 
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
        enableNum = (CFNumberRef) CFDictionaryGetValue(proxyDict,
                                                       kSCPropNetProxiesHTTPSEnable);
        
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
        hostStr = (CFStringRef) CFDictionaryGetValue(proxyDict,
                                                     kSCPropNetProxiesHTTPSProxy);
        
        result = (hostStr != NULL)
        && (CFGetTypeID(hostStr) == CFStringGetTypeID());
    }
    if (result) {
        result = CFStringGetCString(hostStr, host,
                                    (CFIndex) hostSize, kCFStringEncodingASCII);
    }
    
    // Get the proxy port.
    
    if (result) {
        portNum = (CFNumberRef) CFDictionaryGetValue(proxyDict,
                                                     kSCPropNetProxiesHTTPSPort);
        
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

Boolean GetSOCKSProxySetting(char *host, size_t hostSize, UInt16 *port)
// Returns the current SOCKS proxy settings as a C string 
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
        enableNum = (CFNumberRef) CFDictionaryGetValue(proxyDict,
                                                       kSCPropNetProxiesSOCKSEnable);
        
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
        hostStr = (CFStringRef) CFDictionaryGetValue(proxyDict,
                                                     kSCPropNetProxiesSOCKSProxy);
        
        result = (hostStr != NULL)
        && (CFGetTypeID(hostStr) == CFStringGetTypeID());
    }
    if (result) {
        result = CFStringGetCString(hostStr, host,
                                    (CFIndex) hostSize, kCFStringEncodingASCII);
    }
    
    // Get the proxy port.
    
    if (result) {
        portNum = (CFNumberRef) CFDictionaryGetValue(proxyDict,
                                                     kSCPropNetProxiesSOCKSPort);
        
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

+ (NSString *)proxyCommand {
    const size_t hostSize = 64;
    char host[hostSize];
    UInt16 port;
    char answer[10];
    GetSOCKSProxySetting(host, hostSize, &port);
    if (*host) {
        if (port == 0) port = 1080;
        printf("Do you want to use SOCKS proxy %s:%hu (y/N)? ", host, port);
        fgets(answer, 10, stdin);
        if (*answer == 'Y' || *answer == 'y')
            return [NSString stringWithFormat:@"ProxyCommand=/usr/bin/nc -x %s:%hu %%h %%p", host, port];
    }
    GetHTTPProxySetting(host, hostSize, &port);
    if (*host) {
        if (port == 0) port = 80;
        printf("Do you want to use HTTP proxy %s:%hu (y/N)? ", host, port);
        fgets(answer, 10, stdin);
        if (*answer == 'Y' || *answer == 'y')
            return [NSString stringWithFormat:@"ProxyCommand=/usr/bin/nc -X connect -x %s:%hu %%h %%p", host, port];
    }
    GetHTTPSProxySetting(host, hostSize, &port);
    if (*host) {
        if (port == 0) port = 443;
        printf("Do you want to use HTTPS proxy %s:%hu (y/N)? ", host, port);
        fgets(answer, 10, stdin);
        if (*answer == 'Y' || *answer == 'y')
            return [NSString stringWithFormat:@"ProxyCommand=/usr/bin/nc -X connect -x %s:%hu %%h %%p", host, port];
    }
    return nil;
}

@end
