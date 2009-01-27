//
//  KOButtonAreaHotspotHandler.h
//  Welly
//
//  Created by K.O.ed on 09-1-27.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KOMouseHotspotHandler.h"
#import "KOTrackingRectData.h"

@class YLView;
@interface KOButtonAreaHotspotHandler : KOMouseHotspotHandler <KOMouseHotspotDelegate> {
	KOButtonType _buttonType;
	NSString *_commandSequence;
}

- (id) initWithView: (YLView *)view 
			   rect: (NSRect)rect 
		 buttonType: (KOButtonType) buttonType
	commandSequence: (NSString *)cmd;

- (NSString *)getButtonText;

@end
