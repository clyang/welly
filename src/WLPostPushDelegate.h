//
//  WLPostPushDelegate.h
//  Welly
//
//  Created by Cheng-Lin Yang on 2017/9/26.
//  Copyright © 2017年 Welly Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class WLTerminal;

#import <Foundation/Foundation.h>

@interface WLPostPushDelegate : NSObject{
    IBOutlet NSPanel *_pushWindow;
    IBOutlet NSTextView *_pushText;
    IBOutlet NSButton *_sendButton;
    IBOutlet NSButton *_cancelButton;
    IBOutlet NSProgressIndicator *_progressCircle;
}

+ (WLPostPushDelegate *)sharedInstance;

/* post download actions */
- (void)beginPostPushInWindow:(NSWindow *)window
                      forTerminal:(WLTerminal *)terminal;
@end

