//
//  WLNewBookmarkPortalItem.m
//  Welly
//
//  Created by K.O.ed on 10-5-11.
//  Copyright 2010 Welly Group. All rights reserved.
//

#import "WLNewBookmarkPortalItem.h"
#import "WLSitesPanelController.h"
#import "WLSite.h"

NSString *const WLNewBookmarkPortalItemTitle = @"New Bookmark";

@implementation WLNewBookmarkPortalItem

- (id)init {
	self = [super initWithTitle:NSLocalizedString(WLNewBookmarkPortalItemTitle, 
												  @"The title for New Bookmark Portal Item")];
	if (self) {
		// TODO: set a proper image
	}
	return self;
}

#pragma mark -
#pragma mark WLPortalSource protocol
- (void)didSelect:(id)sender {
	[[WLSitesPanelController sharedInstance] openSitesPanelInWindow:[NSApp keyWindow] 
														 andAddSite:[WLSite site]];
}

@end
