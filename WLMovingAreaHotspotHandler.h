//
//  WLExitAreaHotspotHandler.h
//  Welly
//
//  Created by K.O.ed on 09-1-26.
//  Copyright 2009 Welly Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WLMouseHotspotHandler.h"

NSString *const WLCommandSequencePageUp;
NSString *const WLCommandSequencePageDown;
NSString *const WLCommandSequenceLeftArrow;
NSString *const WLCommandSequenceHome;
NSString *const WLCommandSequenceEnd;

NSString *const WLToolTipPageUp;
NSString *const WLToolTipPageDown;

@interface WLMovingAreaHotspotHandler : WLMouseHotspotHandler <WLMouseUpHandler, WLUpdatable, WLContextualMenuHandler> {
	NSCursor *_leftArrowCursor;
	NSCursor *_pageUpCursor;
	NSCursor *_pageDownCursor;
}
@end
