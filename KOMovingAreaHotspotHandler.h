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
	NSDictionary *_currentMovingAreaUserInfo;
}

- (void) update;
@end
