//
//  WLEmoticonDelegate.h
//  Welly
//
//  Created by K.O.ed on 09-9-27.
//  Copyright 2009 Welly Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class YLView;

@interface WLEmoticonDelegate : NSObject {
    IBOutlet NSPanel *_emoticonsWindow;
    IBOutlet NSArrayController *_emoticonsController;
	IBOutlet YLView *_telnetView;
	
    NSMutableArray *_emoticons;
}
@property (readonly) NSArray *emoticons;
+ (WLEmoticonDelegate *)sharedInstance;

/* emoticon actions */
- (IBAction)closeEmoticons:(id)sender;
- (IBAction)inputEmoticons:(id)sender;
- (IBAction)openEmoticonsWindow:(id)sender;

/* emoticon accessors */
- (void)saveEmoticonFromString:(NSString *)string;
@end
