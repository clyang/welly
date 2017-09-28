//
//  XIPTY.h
//  Welly
//
//  Created by boost @ 9# on 7/13/08.
//  Copyright 2008 Xi Wang. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WLProtocol.h"

@interface WLPTY : NSObject <WLProtocol> {
    pid_t _pid;
    int _fd;
    id _delegate;
    BOOL _connecting;
    WLProxyType _proxyType;
    NSString *_proxyAddress;
}
@property (readwrite, assign) id delegate;
@property (readwrite, assign) WLProxyType proxyType;
@property (readwrite, copy) NSString *proxyAddress;
@end
