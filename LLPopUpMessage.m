//
//  LLPopUpMessage.m
//  Welly
//
//  Created by gtCarrera @ 9# on 08-9-11.
//  Copyright 2008. All rights reserved.
//

#import "LLPopUpMessage.h"


@implementation LLPopUpMessage

#pragma mark Class methods
+ (void) hidePopUpMessage {
	if(_effectView) {
		[_effectView removePopUpMessage];
	}
}

+ (void)showPopUpMessage: (NSString*) message 
				duration: (CGFloat) duration 
			  effectView: (KOEffectView *) effectView {
	[effectView drawPopUpMessage:message];
	_effectView = [effectView retain];
	[NSTimer scheduledTimerWithTimeInterval:duration 
									  target:self 
									selector:@selector(hidePopUpMessage)
									userInfo:nil
									 repeats:NO];
}

@end
