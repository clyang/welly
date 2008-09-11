//
//  LLPopUpMessage.h
//  Welly
//
//  Created by gtCarrera @ 9# on 08-9-11.
//  Copyright 2008. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KOEffectView.h"

KOEffectView * _effectView;

@interface LLPopUpMessage : NSObject {
}

+ (void)showPopUpMessage: (NSString*) message 
				duration: (CGFloat) duration 
			  effectView: (KOEffectView *) effectView;

+ (void) hidePopUpMessage;

@end
