//
//  SynthesizeSingleton.h
//  Welly
//
//  Created by K.O.ed on 09-10-6.
//  Copyright 2009 Welly Group. All rights reserved.
//

#define SYNTHESIZE_SINGLETON_FOR_CLASS(classname) \
 \
static classname *sSharedInstance = nil; \
 \
+ (classname *)sharedInstance \
{ \
	@synchronized(self) \
	{ \
		if (sSharedInstance == nil) \
		{ \
			sSharedInstance = [[self alloc] init]; \
		} \
	} \
	 \
	return sSharedInstance; \
} \
 \
+ (id)allocWithZone:(NSZone *)zone \
{ \
	@synchronized(self) \
	{ \
		if (sSharedInstance == nil) \
		{ \
			sSharedInstance = [super allocWithZone:zone]; \
		} \
	} \
	 \
	return sSharedInstance; \
} \
 \
- (id)copyWithZone:(NSZone *)zone \
{ \
	return self; \
} \
 \
- (id)retain \
{ \
	return self; \
} \
 \
- (NSUInteger)retainCount \
{ \
	return NSUIntegerMax; \
} \
 \
- (oneway void)release \
{ \
} \
 \
- (id)autorelease \
{ \
	return self; \
}
