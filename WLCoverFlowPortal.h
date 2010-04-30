//
//  WLPortal.h
//  Welly
//
//  Created by boost on 9/6/09.
//  Copyright 2009 Xi Wang. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class WLPortalItem;
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
@interface WLCoverFlowPortal : NSView <NSComboBoxDataSource> {
#else
@interface WLCoverFlowPortal : NSView {
#endif
    NSArray *_portalItems;
    id _imageFlowView;
	WLPortalItem *_draggingItem;
}

//@property (readonly) NSView *view;

- (void)setPortalItems:(NSArray *)portalItems;
	
- (void)keyDown:(NSEvent *)theEvent;
- (void)mouseDown:(NSEvent *)theEvent;

@end
