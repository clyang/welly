//
//  WLEmoticonDelegate.m
//  Welly
//
//  Created by K.O.ed on 09-9-27.
//  Copyright 2009 Welly Group. All rights reserved.
//

#import "WLEmoticonsPanelController.h"
#import "WLTerminalView.h"
#import "YLController.h"
#import "YLEmoticon.h"
#import "SynthesizeSingleton.h"

#define kEmoticonPanelNibFilename @"EmoticonsPanel"

@interface WLEmoticonsPanelController ()
- (void)loadNibFile;
- (void)loadEmoticons;
- (void)saveEmoticons;

// emoticons accessors
- (void)addEmoticon:(YLEmoticon *)emoticon;
- (unsigned)countOfEmoticons;
- (id)objectInEmoticonsAtIndex:(unsigned)theIndex;
- (void)getEmoticons:(id *)objsPtr 
			   range:(NSRange)range;
- (void)insertObject:(id)obj 
  inEmoticonsAtIndex:(unsigned)theIndex;
- (void)removeObjectFromEmoticonsAtIndex:(unsigned)theIndex;
- (void)replaceObjectInEmoticonsAtIndex:(unsigned)theIndex withObject:(id)obj;
@end

@implementation WLEmoticonsPanelController
@synthesize emoticons = _emoticons;

SYNTHESIZE_SINGLETON_FOR_CLASS(WLEmoticonsPanelController);

- (id)init {
    if (self = [super init]) {
		@synchronized(self) {
			if (!_emoticons)
				_emoticons = [[NSMutableArray alloc] init];
			[self loadNibFile];
		}
    }
    return self;
}

- (void)dealloc {
    [_emoticons release];
    [super dealloc];
}

- (void)loadNibFile {
	if (_emoticonsPanel) {
		// Already loaded, return quietly
		return;
	}
	
	// Load Nib file and load all emoticons in
	if ([NSBundle loadNibNamed:kEmoticonPanelNibFilename owner:self]) {
		[self loadEmoticons];
	}
}

#pragma mark -
#pragma mark IBActions
- (void)openEmoticonsPanel {
	// Load Nib file if necessary
	[self loadNibFile];
    [_emoticonsPanel makeKeyAndOrderFront:self];
}

- (IBAction)closeEmoticonsPanel:(id)sender {
    [_emoticonsPanel endEditingFor:nil];
    [_emoticonsPanel makeFirstResponder:_emoticonsPanel];
    [_emoticonsPanel orderOut:self];
    [self saveEmoticons];
}

- (IBAction)inputSelectedEmoticon:(id)sender {
    [self closeEmoticonsPanel:sender];
    /*TODO:
	YLView *telnetView = [[YLController sharedInstance] telnetView];
	
    if ([telnetView isConnected]) {
        NSArray *a = [_emoticonsController selectedObjects];
        
        if ([a count] == 1) {
            YLEmoticon *e = [a objectAtIndex:0];
            [telnetView insertText:[e content]];
        }
    }
	 */
}

#pragma mark -
#pragma mark Save/Load Emoticons
- (void)loadEmoticons {
    NSArray *a = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Emoticons"];
    for (NSDictionary *d in a)
        [self addEmoticon:[YLEmoticon emoticonWithDictionary:d]];
}

- (void)saveEmoticons {
    NSMutableArray *a = [NSMutableArray array];
    for (YLEmoticon *e in _emoticons) 
        [a addObject:[e dictionaryOfEmoticon]];
    [[NSUserDefaults standardUserDefaults] setObject:a forKey:@"Emoticons"];    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark -
#pragma mark Emoticons Accessors
- (unsigned)countOfEmoticons {
    return [_emoticons count];
}

- (id)objectInEmoticonsAtIndex:(unsigned)theIndex {
    return [_emoticons objectAtIndex:theIndex];
}

- (void)getEmoticons:(id *)objsPtr 
			   range:(NSRange)range {
    [_emoticons getObjects:objsPtr range:range];
}

- (void)insertObject:(id)obj 
  inEmoticonsAtIndex:(unsigned)theIndex {
    [_emoticons insertObject:obj atIndex:theIndex];
}

- (void)removeObjectFromEmoticonsAtIndex:(unsigned)theIndex {
    [_emoticons removeObjectAtIndex:theIndex];
}

- (void)replaceObjectInEmoticonsAtIndex:(unsigned)theIndex withObject:(id)obj {
    [_emoticons replaceObjectAtIndex:theIndex withObject:obj];
}

- (void)addEmoticon:(YLEmoticon *)emoticon {
	[self insertObject:emoticon inEmoticonsAtIndex:[self countOfEmoticons]];
}

- (void)addEmoticonFromString:(NSString *)string {
	YLEmoticon *emoticon = [YLEmoticon emoticonWithString:string];
	[self addEmoticon:emoticon];
}

@end
