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
@interface WLCoverFlowPortal : NSObject <NSComboBoxDataSource> {
#else
@interface WLCoverFlowPortal : NSObject {
#endif
    NSMutableArray * _data;
    id _view, _contentView;
	WLPortalItem *_draggingItem;
}

@property (readonly) NSView *view;

- (id)initWithView:(NSView *)view;

- (void)loadCovers;
- (void)show;
- (void)hide;
//- (BOOL)updateCoverAtIndex:(NSUInteger)index withFile:(NSString*)path;

- (void)keyDown:(NSEvent *)theEvent;
- (void)mouseDown:(NSEvent *)theEvent;

@end
