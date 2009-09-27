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

/* emoticon actions */
- (IBAction)closeEmoticons:(id)sender;
- (IBAction)inputEmoticons:(id)sender;
- (IBAction)openEmoticonsWindow:(id)sender;

// emoticons accessors
//- (NSArray *)emoticons;
- (unsigned)countOfEmoticons;
- (id)objectInEmoticonsAtIndex:(unsigned)theIndex;
- (void)getEmoticons:(id *)objsPtr 
			   range:(NSRange)range;
- (void)insertObject:(id)obj 
  inEmoticonsAtIndex:(unsigned)theIndex;
- (void)removeObjectFromEmoticonsAtIndex:(unsigned)theIndex;
- (void)replaceObjectInEmoticonsAtIndex:(unsigned)theIndex withObject:(id)obj;

@end
