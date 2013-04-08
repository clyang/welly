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

#import "IPSeeker.h"

// 一些固定常量，比如记录长度等等
#define IP_RECORD_LENGTH 7
#define REDIRECT_MODE_1 0x01
#define REDIRECT_MODE_2 0x02

static IPSeeker* s_instance = nil;

@implementation IPSeeker

NSString* L(NSString* key) {
	return NSLocalizedString(key, nil);
}

+ (IPSeeker*)shared; {
	if(s_instance == nil)
		s_instance = [[IPSeeker alloc] init];
	return s_instance;
}

- (id)init {
	self = [super init];
	if(self) {
		m_cache = [[NSMutableDictionary dictionary] retain];
		NSString* path = [[NSBundle mainBundle] pathForResource:@"QQWry" ofType:@"dat"];
		if(path) {
			m_file = [[NSFileHandle fileHandleForReadingAtPath:path] retain];
			if(m_file) {
				m_indexBegin = [self readInt4:0];
				m_indexEnd = [self readInt4:4];
				if(m_indexBegin == -1 || m_indexEnd == -1) {
					[m_file closeFile];
					[m_file release];
					m_file = nil;
				}
			}			
		}
	}
	return self;
}

- (void)dealloc {
	[m_cache release];
	[m_file closeFile];
	[m_file release];
	[super dealloc];
}

#pragma mark -
#pragma mark API

- (NSString*)getLocation:(const char*)ip {
	return [self getLocation:ip locationOnly:YES];
}

- (NSString*)getLocation:(const char*)ip locationOnly:(BOOL)locationOnly {
	if(m_file == nil)
		return L(@"LQIPBadFile");
	
	NSString* ipStr = [NSString stringWithFormat:@"%d.%d.%d.%d", ip[0] & 0xFF, ip[1] & 0xFF, ip[2] & 0xFF, ip[3] & 0xFF];
	NSString* loc = [m_cache objectForKey:ipStr];
	if(loc == nil) {
		UInt32 offset = [self locateIP:ip];
		if(offset != -1) {
			loc = [self getLocationByOffset:offset];
			[m_cache setObject:loc forKey:ipStr];
		} else
			loc = [NSString stringWithFormat:@"%@ %@", L(@"LQCountryUnknown"), L(@"LQAreaUnknown")];
	} else
		loc = [m_cache objectForKey:ipStr];
	
	if(locationOnly)
		return loc;
	else
		return [NSString stringWithFormat:L(@"LQIPLocation"), [NSString stringWithFormat:@"%d.%d.%d.%d", ip[0] & 0xFF, ip[1] & 0xFF, ip[2] & 0xFF, ip[3] & 0xFF], loc];
}

- (NSString*)getLocationByOffset:(unsigned long long)offset {
	if(m_file == nil)
		return L(@"LQIPBadFile");
	
	NSString* country;
	NSString* area;
	
	// skip 4 bytes ip
	[m_file seekToFileOffset:(offset + 4)];
	
	// check whether first byte is a flag byte
	NSData* data = [m_file readDataOfLength:1];
	char byte = ((const char*)[data bytes])[0];
	if(byte == REDIRECT_MODE_1) {
		// read offset of country
		UInt32 countryOffset = [self readInt3];
		
		// skip to country
		[m_file seekToFileOffset:countryOffset];
		
		// check first byte again because it could still be flag byte
		data = [m_file readDataOfLength:1];
		byte = ((const char*)[data bytes])[0];
		if(byte == REDIRECT_MODE_2) {
			country = [self readString:[self readInt3]];
			[m_file seekToFileOffset:(countryOffset + 4)];
		} else
			country = [self readString:countryOffset];
		
		// read area
		area = [self readArea:[m_file offsetInFile]];
	} else if(byte == REDIRECT_MODE_2) {
		country = [self readString:[self readInt3]];
		area = [self readArea:(offset + 8)];
	} else {
		country = [self readString:([m_file offsetInFile] - 1)];
		area = [self readArea:[m_file offsetInFile]];
	}
	
	return [NSString stringWithFormat:@"%@ %@", country, area];
}

#pragma mark -
#pragma mark helper

- (int)compareIP:(const char*)ip withIP:(const char*)beginIp {
	for(int i = 0; i < 4; i++) {
		int r = [self compareByte:ip[i] withByte:beginIp[i]];
		if(r != 0)
			return r;
	}
	return 0;
}

- (int)compareByte:(char)b1 withByte:(char)b2 {
	if((b1 & 0xFF) > (b2 & 0xFF))
		return 1;
	else if((b1 ^ b2) == 0)
		return 0;
	else 
		return -1;
}

- (UInt32)getMiddleOffset:(UInt32)begin end:(UInt32)end {
	UInt32 records = (end - begin) / IP_RECORD_LENGTH;
	records >>= 1;
	if(records == 0) 
		records = 1;
	return begin + records * IP_RECORD_LENGTH;
}

- (UInt32)locateIP:(const char*)ip {
	UInt32 m = 0;
	int r;
	
	// compare first entry
	NSData* ipData = [self readIP:m_indexBegin];
	r = [self compareIP:ip withIP:(const char*)[ipData bytes]];
	if(r == 0) 
		return m_indexBegin;
	else if(r < 0) 
		return -1;
	
	// binary search
	for(UInt32 i = m_indexBegin, j = m_indexEnd; i < j; ) {
		m = [self getMiddleOffset:i end:j];
		ipData = [self readIP:m];
		r = [self compareIP:ip withIP:(const char*)[ipData bytes]];

		if(r > 0)
			i = m;
		else if(r < 0) {
			if(m == j) {
				j -= IP_RECORD_LENGTH;
				m = j;
			} else 
				j = m;
		} else
			return [self readInt3:(m + 4)];
	}
	
	// if loop is end, the i equals j and i points most possible record
	// but not sure, so we need a check
	m = [self readInt3:(m + 4)];
	ipData = [self readIP:m];
	r = [self compareIP:ip withIP:(const char*)[ipData bytes]];
	if(r <= 0) 
		return m;
	else 
		return -1;
}

#pragma mark -
#pragma mark basic read methods

- (UInt32)readInt3 {
	NSData* data = [m_file readDataOfLength:3];
	UInt32 ret = 0;
	const char* bytes = (const char*)[data bytes];
	ret |= bytes[0] & 0xFF;
	ret |= (bytes[1] << 8) & 0xFF00;
	ret |= (bytes[2] << 16) & 0xFF0000;
	return ret;
}

- (UInt32)readInt3:(unsigned long long)offset {
	[m_file seekToFileOffset:offset];
	return [self readInt3];
}

- (UInt32)readInt4 {
	NSData* data = [m_file readDataOfLength:4];
	UInt32 ret = 0;
	const char* bytes = (const char*)[data bytes];
	ret |= bytes[0] & 0xFF;
	ret |= (bytes[1] << 8) & 0xFF00;
	ret |= (bytes[2] << 16) & 0xFF0000;
	ret |= (bytes[3] << 24) & 0xFF000000;
	return ret;
}

- (UInt32)readInt4:(unsigned long long)offset {
	[m_file seekToFileOffset:offset];
	return [self readInt4];
}

- (NSString*)readString:(unsigned long long)offset {
    [m_file seekToFileOffset:offset];
    NSMutableData* data = [NSMutableData data];
    NSData* tmp;
    while ((tmp = [m_file readDataOfLength:1])) {
        char byte = ((const char*)[tmp bytes])[0];
        if (byte == 0)
            break;
        else
            [data appendBytes:[tmp bytes] length:1];
	}
	return [(NSString*)CFStringCreateFromExternalRepresentation(kCFAllocatorDefault, (CFDataRef)data, kCFStringEncodingGB_18030_2000) autorelease];
}

#pragma mark -
#pragma mark advanced reading methods

- (NSString*)readArea:(unsigned long long)offset {
	[m_file seekToFileOffset:offset];
	NSData* data = [m_file readDataOfLength:1];
	if(data) {
		char mode = ((const char*)[data bytes])[0];
		if(mode == REDIRECT_MODE_1 || mode == REDIRECT_MODE_2) {
			UInt32 areaOffset = [self readInt3:(offset + 1)];
			if(areaOffset != 0)
				return [self readString:areaOffset];
		}
		else
			return [self readString:offset];
	} 
	
	return @"";
}

- (NSData*)readIP:(unsigned long long)offset {
	[m_file seekToFileOffset:offset];
	NSMutableData* data = [NSMutableData dataWithData:[m_file readDataOfLength:4]];
	char* ip = (char*)[data mutableBytes];
	char tmp = ip[0];
	ip[0] = ip[3];
	ip[3] = tmp;
	tmp = ip[1];
	ip[1] = ip[2];
	ip[2] = tmp;
	return data;
}

@end
