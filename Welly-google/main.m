//
//  main.m
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/6/9.
//  Copyright yllan.org 2006. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "encoding.h"

int main(int argc, char *argv[])
{
	init_table();
    return NSApplicationMain(argc,  (const char **) argv);
}
