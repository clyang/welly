//
//  KOExitAreaHotspotHandler.h
//  Welly
//
//  Created by K.O.ed on 09-1-26.
//  Copyright 2009 Welly Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KOMouseHotspotHandler.h"

NSString *const KOCommandSequencePageUp;
NSString *const KOCommandSequencePageDown;
NSString *const KOCommandSequenceLeftArrow;
NSString *const KOCommandSequenceHome;
NSString *const KOCommandSequenceEnd;

NSString *const KOToolTipPageUp;
NSString *const KOToolTipPageDown;

@interface KOMovingAreaHotspotHandler : KOMouseHotspotHandler <KOMouseUpHandler, KOUpdatable, KOContextualMenuHandler> {
	NSCursor *_leftArrowCursor;
	NSCursor *_pageUpCursor;
	NSCursor *_pageDownCursor;
}
@end
