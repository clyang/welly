/*
 *  encoding.h
 *  MacBlueTelnet
 *
 *  Created by Yung-Luen Lan on 9/11/07.
 *  Copyright 2007 yllan.org. All rights reserved.
 *
 */

extern unsigned short G2U[32768];
extern unsigned short B2U[32768];
extern unsigned short U2B[65536];
extern unsigned short U2G[65536];

extern void init_table();
