/*
 * LumaQQ - Cross platform QQ client, special edition for Mac
 *
 * Copyright (C) 2007 luma <stubma@163.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */

#import <Cocoa/Cocoa.h>

@interface IPSeeker : NSObject {
	NSFileHandle* m_file;
	UInt32 m_indexBegin;
	UInt32 m_indexEnd;
	
	// cache
	NSMutableDictionary* m_cache;
}

+ (IPSeeker*)shared;

// API
- (NSString*)getLocation:(const char*)ip locationOnly:(BOOL)locationOnly;
- (NSString*)getLocation:(const char*)ip;
- (NSString*)getLocationByOffset:(unsigned long long)offset;

// helper
- (int)compareByte:(char)b1 withByte:(char)b2;
- (int)compareIP:(const char*)ip withIP:(const char*)beginIp;
- (UInt32)getMiddleOffset:(UInt32)begin end:(UInt32)end;
- (UInt32)locateIP:(const char*)ip;

// basic reading
- (UInt32)readInt3;
- (UInt32)readInt3:(unsigned long long)offset;
- (UInt32)readInt4;
- (UInt32)readInt4:(unsigned long long)offset;
- (NSString*)readString:(unsigned long long)offset;

// advanced reading
- (NSString*)readArea:(unsigned long long)offset;
- (NSData*)readIP:(unsigned long long)offset;

@end
