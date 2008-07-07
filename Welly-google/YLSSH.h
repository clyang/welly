//
//  YLSSH.h
//  MacBlueTelnet
//
//  Created by Lan Yung-Luen on 12/7/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "YLConnection.h"

@interface YLSSH : YLConnection <YLConnectionProtocol> {
    pid_t _pid;
    int _fileDescriptor;
	BOOL _loginAsBBS;
}

@end
