//
//  WLPTY.m
//  Welly
//
//  Created by boost @ 9# on 7/13/08.
//  Copyright 2008 Xi Wang. All rights reserved.

//  YLSSH.m
//  MacBlueTelnet
//
//  Created by Lan Yung-Luen on 12/7/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

/* Code from iTerm : PTYTask.m */

#include <util.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <termios.h>
#import "WLGlobalConfig.h"
#import "WLPTY.h"
#import "WLProxy.h"

#define CTRLKEY(c)   ((c)-'A'+1)

@implementation WLPTY
@synthesize delegate = _delegate;
@synthesize proxyType = _proxyType;
@synthesize proxyAddress = _proxyAddress;

+ (NSString *)parse:(NSString *)addr {
    // trim whitespaces
    addr = [addr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    // command, not "URL"
    if ([addr rangeOfString:@" "].length > 0)
        return addr;
    // check protocol
    BOOL ssh;
    NSString *port = nil;
    NSRange range;
    if ([[addr lowercaseString] hasPrefix: @"ssh://"]) {
        ssh = YES;
        addr = [addr substringFromIndex:6];
    } else {
        ssh = NO;
        range = [addr rangeOfString:@"://"];
        if (range.length > 0)
            addr = [addr substringFromIndex:range.location + range.length];
    }
    // check port
    range = [addr rangeOfString:@":"];
    if (range.length > 0) {
        port = [addr substringFromIndex:range.location + range.length];
        addr = [addr substringToIndex:range.location];
    }
    // make the command
    NSString *fmt;
    if (ssh) {
        if (port == nil)
            port = @"22";
        fmt = @"/usr/bin/ssh -p %2$@ -x %1$@";
    } else {
        if (port == nil)
            port = @"23";
        range = [addr rangeOfString:@"@"];
        // remove username for telnet
        if (range.length > 0)
            addr = [addr substringFromIndex:range.location + range.length];
        // "-" before the port number forces the initial option negotiation
        fmt = @"/usr/bin/telnet -8 %@ -%@";
    }
    NSString *r = [NSString stringWithFormat:fmt, addr, port];
    return r;
} 

- (id)init {
    if (self == [super init]) {
        _pid = 0;
        _fd = nil;
    }
    return self;
}

- (void)dealloc {
    [self close];
    [super dealloc];
}

- (void)close {
    if (_pid > 0) {
        kill(_pid, SIGKILL);
        _pid = 0;
    }
    if (_fd) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [_fd release];
        _fd = nil;
        [_delegate protocolDidClose:self];
    }
}

- (BOOL)connect:(NSString *)addr {
    char slaveName[PATH_MAX];
    struct termios term;
    struct winsize size;
    
    term.c_iflag = ICRNL | IXON | IXANY | IMAXBEL | BRKINT;
    term.c_oflag = OPOST | ONLCR;
    term.c_cflag = CREAD | CS8 | HUPCL;
    term.c_lflag = ICANON | ISIG | IEXTEN | ECHO | ECHOE | ECHOK | ECHOKE | ECHOCTL;
	
    term.c_cc[VEOF]      = CTRLKEY('D');
    term.c_cc[VEOL]      = -1;
    term.c_cc[VEOL2]     = -1;
    term.c_cc[VERASE]    = 0x7f;	// DEL
    term.c_cc[VWERASE]   = CTRLKEY('W');
    term.c_cc[VKILL]     = CTRLKEY('U');
    term.c_cc[VREPRINT]  = CTRLKEY('R');
    term.c_cc[VINTR]     = CTRLKEY('C');
    term.c_cc[VQUIT]     = 0x1c;	// Control+backslash
    term.c_cc[VSUSP]     = CTRLKEY('Z');
    term.c_cc[VDSUSP]    = CTRLKEY('Y');
    term.c_cc[VSTART]    = CTRLKEY('Q');
    term.c_cc[VSTOP]     = CTRLKEY('S');
    term.c_cc[VLNEXT]    = -1;
    term.c_cc[VDISCARD]  = -1;
    term.c_cc[VMIN]      = 1;
    term.c_cc[VTIME]     = 0;
    term.c_cc[VSTATUS]   = -1;
	
    term.c_ispeed = B38400;
    term.c_ospeed = B38400;
    size.ws_col = [[WLGlobalConfig sharedInstance] column];
    size.ws_row = [[WLGlobalConfig sharedInstance] row];
    size.ws_xpixel = 0;
    size.ws_ypixel = 0;

    int fd;
    _pid = forkpty(&fd, slaveName, &term, &size);
    if (_pid == 0) { /* child */
        NSArray *a = [[WLPTY parse:addr] componentsSeparatedByString:@" "];
        if ([(NSString *)[a objectAtIndex:0] hasSuffix:@"ssh"]) {
            NSString *proxyCommand = [WLProxy proxyCommandWithAddress:_proxyAddress type:_proxyType];
            if (proxyCommand) {
                a = [[a arrayByAddingObject:@"-o"] arrayByAddingObject:proxyCommand];
            }
        }
        int n = [a count];
        char *argv[n+1];
        for (int i = 0; i < n; ++i)
            argv[i] = (char *)[[a objectAtIndex:i] UTF8String];
        argv[n] = NULL;
        execvp(argv[0], argv);
        perror(argv[0]);
        sleep(-1); // don't bother
    } else { /* parent */
        int one = 1;
        ioctl(fd, TIOCPKT, &one);
        _fd = [[NSFileHandle alloc] initWithFileDescriptor:fd closeOnDealloc:YES];
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(readCallback:) name:NSFileHandleReadCompletionNotification object:_fd];
        _connecting = YES;
        _length = 0;
        [_fd readInBackgroundAndNotify];
    }

    [_delegate protocolWillConnect:self];
    return YES;
}

- (void)recv:(NSData *)data {
    if (_connecting) {
        _length += [data length];
        if (_length > 10) {
            _connecting = NO;
            [_delegate protocolDidConnect:self];
        }
    }
    [_delegate protocolDidRecv:self data:data];
}

- (void)send:(NSData *)data {
    if (_fd == nil || _connecting) // disable input when connecting
        return;
    [_delegate protocolWillSend:self data:data];
    [_fd writeData:data];
}

- (void)readCallback:(NSNotification *)notification {
    NSData *data = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];

    if ([data length] == 0) {
        [self close];
        return;
    }
 
    [self recv:data];
    [[notification object] readInBackgroundAndNotify];
}
@end
