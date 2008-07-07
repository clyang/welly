//
//  YLTelnet.m
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/9/10.
//  Copyright 2006 yllan.org. All rights reserved.
//

#import "YLTelnet.h"
#import "YLTerminal.h"
#import "YLSite.h"
#import <sys/types.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <stdlib.h>
#import <netdb.h>
#import <deque>

#ifdef __DUMPPACKET__
char *_commandName[] = { "SE", "NOP", "DM", "BRK", "IP", "AO", "AYT", "EC", "EL", "GA", "SB", "WILL", "WONT", "DO", "DONT", "IAC" };

void dump_packet(unsigned char *s, int length) {
	int i;
	char tmp[1024 * 512]; tmp[0] = '\0';
	for (i = 0; i < length; i++) {
		if (s[i] >= SE) sprintf(tmp, "%s(%s)", tmp, _commandName[s[i] - SE]);
		else if (s[i] == 13) sprintf(tmp, "%s(CR)", tmp);
		else if (s[i] == 10) sprintf(tmp, "%s(LF)", tmp);
		else if (s[i] >= 127 || s[i] < 32) sprintf(tmp, "%s[%#x]", tmp, s[i]);
		else sprintf(tmp, "%s%c", tmp, s[i]);
	}
	NSLog(@"%s", tmp);
}
#endif

@interface YLTelnet (Private)
- (void) close ;
- (void) reconnect ;
- (void) connectWithDictionary: (NSDictionary *) d ;
- (void) stream: (NSStream *) stream handleEvent: (NSStreamEvent) eventCode ;
- (NSString *) lastError;
- (NSHost *)host;
- (void)setHost:(NSHost *)value;
@end

@implementation YLTelnet

- (void) dealloc {
    [self close];
    [_host release];
    [_sbBuffer release];
    [super dealloc];
}

- (void) lookUpDomainName: (NSDictionary *) d {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    NSString *addr = [d valueForKey: @"addr"];
    int port = [[d valueForKey: @"port"] intValue];
    NSHost *host = [NSHost hostWithName: addr];

    if (host) {
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys: host, @"host", [NSNumber numberWithInt: port], @"port", nil];
        [self performSelectorOnMainThread: @selector(connectWithDictionary:) withObject: dict waitUntilDone: NO];
    } else {
        [self setIsProcessing: NO];
    }
    [pool release];
}

- (void) close {
    [self setIsProcessing: NO];
    [_inputStream close];
    [_inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_inputStream release];
    _inputStream = nil;
    [_outputStream close];
    [_outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_outputStream release];
    _outputStream = nil;
    [self setConnected: NO];
    [[self terminal] closeConnection];
}

- (void) reconnect {
    if (_host) {
        [self close];
        [self connectWithDictionary: [NSDictionary dictionaryWithObjectsAndKeys: _host, @"host", [NSNumber numberWithInt: _port], @"port", nil]];
    }
}

- (void) connectWithDictionary: (NSDictionary *) d {
    NSHost *host = [d valueForKey: @"host"];
    int port = [[d valueForKey: @"port"] intValue];
    
    if (!host) return;
    [self setHost: host];
    [_terminal clearAll];
    [NSStream getStreamsToHost: host 
                          port: port 
                   inputStream: &_inputStream
                  outputStream: &_outputStream];
    [_inputStream retain];
    [_outputStream retain];
    [_inputStream setDelegate: self];
    [_outputStream setDelegate: self];
    [_inputStream scheduleInRunLoop: [NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_outputStream scheduleInRunLoop: [NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_inputStream open];
    [_outputStream open];
}

- (BOOL) connectToAddress: (NSString *) addr {
    NSArray *a = [addr componentsSeparatedByCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @": "]];
    if ([a count] == 2) {
        int p = [[a objectAtIndex: 1] intValue];
        if (p > 0) {
            return [self connectToAddress: [a objectAtIndex: 0] port: p];            
        } else {
            return [self connectToAddress: [a objectAtIndex: 0] port: 23];
        }
    } else if ([a count] == 1) {
        return [self connectToAddress: addr port: 23];
    }
    return NO;
}

- (BOOL) connectToAddress: (NSString *) addr port: (unsigned int) port {
    if (!addr) return NO;
    [self setIsProcessing: YES];
    if (port == 23)
        [self setConnectionAddress: addr];
    else
        [self setConnectionAddress: [NSString stringWithFormat: @"%@:%d", addr, port]];
    _port = port;
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys: addr, @"addr", [NSNumber numberWithInt: port], @"port", nil];
    [self performSelectorInBackground: @selector(lookUpDomainName:) withObject: dict];

    return YES;
}

- (void) stream: (NSStream *) stream handleEvent: (NSStreamEvent) eventCode {
    switch(eventCode) {
        case NSStreamEventOpenCompleted: {
            [self setConnected: YES];
            [self setIsProcessing: NO];
            [[self terminal] startConnection];
            break;
        }
        case NSStreamEventHasBytesAvailable: {
            uint8_t buf[4096];
            while ([(NSInputStream *)stream hasBytesAvailable]) {
                NSInteger len = [(NSInputStream *)stream read: buf maxLength: 4096];
                if (len > 0) {
                    [self receiveBytes: buf length: len];
                }
            }
            break;
        }
        case NSStreamEventHasSpaceAvailable: {
            break;
        }
        case NSStreamEventErrorOccurred: {
            [self setIsProcessing: NO];
            NSLog(@"Error: %@", [stream streamError]);
        }
        case NSStreamEventEndEncountered: {
            [self setIsProcessing: NO];
            [stream close];
            [stream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [stream release];
            if (stream == _inputStream)
                _inputStream = nil;
            else if (stream == _outputStream)
                _outputStream = nil;
            [self setConnected: NO];
            [[self terminal] closeConnection];
            break;
        }
    }
}

/* Send telnet command */
- (void) sendCommand: (unsigned char) _command option: (unsigned char) _opt {
	unsigned char b[3];
	b[0] = IAC;
	b[1] = _command;
	b[2] = _opt;
    NSData *d = [NSData dataWithBytes: b length: 3];
    [self performSelector: @selector(sendMessage:) withObject: d afterDelay: 0.001];
}

- (void) receiveBytes: (unsigned char *) bytes length: (NSUInteger) length {

	unsigned char *stream = (unsigned char *) bytes;
	std::deque<unsigned char> terminalBuf;
	
	/* parse the telnet command. */
	int L = length;
#ifdef __DUMPPACKET__
//	dump_packet(stream, L);
#endif
	
	while (L--) {
		unsigned char c = *stream++;
		switch (_state) {
			case TOP_LEVEL:
			case SEENCR:
				if (c == NUL && _state == SEENCR)
					_state = TOP_LEVEL;
				else if (c == IAC)
					_state = SEENIAC;
				else {
					if (!_synch)
						terminalBuf.push_back(c);
					else if (c == DM)
						_synch = NO;
					
					if (c == CR) 
						_state = SEENCR;
					else
						_state = TOP_LEVEL;
				}
				break;
			case SEENIAC:
				if (c == DO || c == DONT || c == WILL || c == WONT) {
					_typeOfOperation = c;
					if (c == DO)
						_state = SEENDO;
					else if (c == DONT)
						_state = SEENDONT;
					else if (c == WILL)
						_state = SEENWILL;
					else if (c == WONT)
						_state = SEENWONT;
				} else if (c == SB)
					_state = SEENSB;
				else if (c == DM) {
					_synch = NO;
					_state = TOP_LEVEL;
				} else {
					/* ignore everything else; print it if it's IAC */
					if (c == IAC) {
						// TODO: cwrite(c);
					}
					_state = TOP_LEVEL;
				}
				break;
			case SEENWILL: 
			{
				if (c == TELOPT_ECHO || c == TELOPT_SGA) 
					[self sendCommand: DO option: c];
				else
					[self sendCommand: DONT option: c];
				
				_state = TOP_LEVEL;
				break;
			}
			case SEENWONT:
				[self sendCommand: DONT option: c];
				_state = TOP_LEVEL;
				break;
			case SEENDO: 
			{
				if (c == TELOPT_TTYPE) 
					[self sendCommand: WILL option: TELOPT_TTYPE];
				else if (c == TELOPT_NAWS) {
					unsigned char b[] = {IAC, SB, TELOPT_NAWS, 0, 80, 0, 24, IAC, SE};
					[self sendCommand: WILL option: TELOPT_NAWS];
                    [self performSelector: @selector(sendMessage:) withObject: [NSData dataWithBytes:b length:9] afterDelay: 0.001];
//					[self sendBytes: b length: 9];
				} else 
					[self sendCommand: WONT option: c];
				_state = TOP_LEVEL;
				break;
			}
			case SEENDONT:
				[self sendCommand: WONT option: c];
				_state = TOP_LEVEL;
				break;
			case SEENSB:
				_sbOption = c;
                [_sbBuffer release];
				_sbBuffer = [[NSMutableData data] retain];
				_state = SUBNEGOT;
				break;
			case SUBNEGOT:
				if (c == IAC)
					_state = SUBNEG_IAC;
				else 
					[_sbBuffer appendBytes: &c length: 1];
				break;
			case SUBNEG_IAC:
				/*  [IAC,SB,<option code number>,SEND,IAC],SE */
				if (c != SE) {
					[_sbBuffer appendBytes: &c length: 1];
					_state = SUBNEGOT;
				} else {
					const unsigned char *buf = (const unsigned char *)[_sbBuffer bytes];
					if (_sbOption == TELOPT_TTYPE && [_sbBuffer length] == 1 && buf[0] == TELQUAL_SEND) {
						unsigned char b[] = {IAC, SB, TELOPT_TTYPE, TELQUAL_IS, 'v', 't', '1', '0', '0', IAC, SE};
                        [self performSelector:@selector(sendMessage:) withObject: [NSData dataWithBytes: b length: 11] afterDelay: 0.001];
//						[self sendBytes: b length: 11];
					}
					_state = TOP_LEVEL;
                    [_sbBuffer release];
                    _sbBuffer = nil;
				}
				break;
		}
	}
	
	unsigned char chunkBuf[1024];
	while (!terminalBuf.empty()) {
		int length = 1024;
		if (terminalBuf.size() < 1024) 
			length = terminalBuf.size();
		int i;
		for (i = 0; i < length; i++) {
			chunkBuf[i] = terminalBuf.front();
			terminalBuf.pop_front();
		}
		[_terminal feedBytes: chunkBuf length: length connection: self];
	}
}

- (void) sendBytes: (unsigned char *) msg length: (NSInteger) length {
    if (length <= 0) return;
    if (!_outputStream) return;
    
    [_lastTouchDate release];
    _lastTouchDate = [[NSDate date] retain];
    int status = [_outputStream streamStatus];
    if (status == NSStreamStatusNotOpen ||
        status == NSStreamStatusError ||
        status == NSStreamStatusClosed ||
        status == NSStreamStatusAtEnd) return;
    int result = [_outputStream write: msg maxLength: length];
    if (result == length) return;
    if (result <= 0) {
        [self performSelector: @selector(sendMessage:) withObject: [NSData dataWithBytes: msg length: length] afterDelay: 0.001];
    } else {
        [self performSelector: @selector(sendMessage:) withObject: [NSData dataWithBytes: msg + result length: length - result] afterDelay: 0.001];        
    }
}

- (void) sendMessage: (NSData *) msg {
    if (!_outputStream) return;
    [self sendBytes: (unsigned char *)[msg bytes] length: [msg length]];
}


- (NSString *) lastError {
	return @"I don't know what error.";
}

- (NSHost *)host {
    return _host;
}

- (void)setHost:(NSHost *)value {
    if (_host != value) {
        [_host release];
        _host = [value retain];
    }
}

@end