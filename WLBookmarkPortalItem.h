//
//  WLPortalImage.h
//  Welly
//
//  Created by boost on 9/6/2009.
//  Copyright 2009 Xi Wang. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WLPortalItem.h"
#import "WLSite.h"

@interface WLBookmarkPortalItem : WLPortalItem <WLPasteboardReceiver, WLDraggingSource> {
	WLSite *_site;
    NSString *_path;
}
@property (readwrite, copy, nonatomic) NSString *path;
@property (readwrite, retain, nonatomic) WLSite *site;
- (id)initWithSite:(WLSite *)site;
- (id)initWithPath:(NSString *)path title:(NSString *)title;
//- (void)setPath:(NSString *)path;


@end
