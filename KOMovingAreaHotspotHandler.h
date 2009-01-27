//
//  KOExitAreaHotspotHandler.h
//  Welly
//
//  Created by K.O.ed on 09-1-26.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KOMouseHotspotHandler.h"

@class YLView;

@interface KOMovingAreaHotspotHandler : KOMouseHotspotHandler <KOMouseHotspotDelegate> {
	enum {
		AREA_EXIT, AREA_PAGE_UP, AREA_PAGE_DOWN
	} _type;
}

- (id) initWithView: (YLView *)view 
			   rect: (NSRect)rect;
+ (KOMovingAreaHotspotHandler *) exitAreaHandlerForView: (YLView *)view 
												   rect: (NSRect)rect;
+ (KOMovingAreaHotspotHandler *) pageUpAreaHandlerForView: (YLView *)view 
												     rect: (NSRect)rect;
+ (KOMovingAreaHotspotHandler *) pageDownAreaHandlerForView: (YLView *)view 
													   rect: (NSRect)rect;
@end
