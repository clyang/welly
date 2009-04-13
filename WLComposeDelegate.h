//
//  TYComposeDelegate.h
//  Welly
//
//  Created by aqua9 on 17/1/2009.
//  Copyright 2009 TANG Yang. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class YLView;
@interface WLComposeDelegate : NSObject {
    IBOutlet YLView *_telnetView;
	
    IBOutlet NSColorWell *_bgColorWell;
	
    /* composeWindow */
    IBOutlet NSTextView *_composeText;
    IBOutlet NSPanel *_composeWindow;
	
    IBOutlet NSWindow *_mainWindow;
	
	NSShadow *_shadowForBlink;
}

/* compose actions */
- (IBAction)commitCompose:(id)sender;
- (IBAction)cancelCompose:(id)sender;
- (IBAction)setUnderline:(id)sender;
- (IBAction)setBlink:(id)sender;
- (IBAction)changeBackgroundColor:(id)sender;
- (void)clearAll;
@end
