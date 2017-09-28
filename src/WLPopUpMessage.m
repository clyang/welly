//
//  LLPopUpMessage.m
//  Welly
//
//  Created by gtCarrera @ 9# on 08-9-11.
//  Copyright 2008. All rights reserved.
//

#import "WLPopUpMessage.h"
#import "WLEffectView.h"

@implementation WLPopUpMessage

WLEffectView *_effectView;
NSTimer *_prevTimer;

#pragma mark Class methods
+ (void)hidePopUpMessage {
	if (_effectView) {
		[_effectView removePopUpMessage];
		[_effectView release];
	}
    _prevTimer = nil;
}

+ (void)showPopUpMessage:(NSString*)message 
				duration:(CGFloat)duration 
			  effectView:(WLEffectView *)effectView {
    if (_prevTimer) {
        [_prevTimer invalidate];
    }
	[effectView drawPopUpMessage:message];
	_effectView = [effectView retain];
	_prevTimer = [NSTimer scheduledTimerWithTimeInterval:duration
                                                  target:self 
                                                selector:@selector(hidePopUpMessage)
                                                userInfo:nil
                                                 repeats:NO];
}

@end
