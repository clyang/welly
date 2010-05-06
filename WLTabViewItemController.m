//
//  WLTabViewItemObjectController.m
//  Welly
//
//  Created by K.O.ed on 10-4-30.
//  Copyright 2010 Welly Group. All rights reserved.
//

#import "WLTabViewItemController.h"
#import "WLTabBarCellContentProvider.h"

// A dummy tab bar cell content provider, for default use
@interface WLDummyCellContentProvider : NSObject <WLTabBarCellContentProvider> {
	
}
@end

@implementation WLDummyCellContentProvider
- (BOOL)isProcessing {
	return NO;
}

- (NSImage *)icon {
	return nil;
}

- (NSInteger)objectCount {
	return 0;
}

+ (WLDummyCellContentProvider *)dummyContentProvider {
	return [[[WLDummyCellContentProvider alloc] init] autorelease];
}
@end

@implementation WLTabViewItemController
+ (WLTabViewItemController *)emptyTabViewItemController {
	return [[[WLTabViewItemController alloc] initWithContent:nil] autorelease];
}

- (id)initWithContent:(id)content {
	NSAssert(!content || [content conformsToProtocol:@protocol(WLTabBarCellContentProvider)], @"should be tab bar cell content provider!!");
	return [super initWithContent:content];
}

- (void)setContent:(id)content {
	NSAssert(!content || [content conformsToProtocol:@protocol(WLTabBarCellContentProvider)], @"should be tab bar cell content provider!!");
	if (content) {
		[super setContent:content];
	} else {
		[super setContent:[WLDummyCellContentProvider dummyContentProvider]];
	}
}

@end
