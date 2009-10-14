//
//  WLEmoticonDelegate.h
//  Welly
//
//  Created by K.O.ed on 09-9-27.
//  Copyright 2009 Welly Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface WLEmoticonsPanelController : NSObject {
    IBOutlet NSPanel *_emoticonsPanel;
    IBOutlet NSArrayController *_emoticonsController;
	
    NSMutableArray *_emoticons;
}
@property (readonly) NSArray *emoticons;
+ (WLEmoticonsPanelController *)sharedInstance;

/* emoticon actions */
- (void)openEmoticonsPanel;
- (IBAction)closeEmoticonsPanel:(id)sender;
- (IBAction)inputSelectedEmoticon:(id)sender;

/* emoticon accessors */
- (void)addEmoticonFromString:(NSString *)string;
@end
