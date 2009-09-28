//
//  WLEmoticonDelegate.m
//  Welly
//
//  Created by K.O.ed on 09-9-27.
//  Copyright 2009 Welly Group. All rights reserved.
//

#import "WLEmoticonDelegate.h"
#import "YLView.h"
#import "WLConnection.h"
#import "YLEmoticon.h"

@interface WLEmoticonDelegate ()
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

@implementation WLEmoticonDelegate
@synthesize emoticons = _emoticons;

static WLEmoticonDelegate *sInstance;
+ (WLEmoticonDelegate *)sharedInstance {
    assert(sInstance);
    return sInstance;
}

- (id)init {
    if (self = [super init]) {
        _emoticons = [[NSMutableArray alloc] init];
		assert(sInstance == nil);
		sInstance = self;
    }
    return self;
}

- (void)dealloc {
    [_emoticons release];
    [super dealloc];
}

- (void)awakeFromNib {
    [self loadEmoticons];
}

#pragma mark -
#pragma mark IBActions
- (IBAction)openEmoticonsWindow:(id)sender {
    [_emoticonsWindow makeKeyAndOrderFront:self];
}

- (IBAction)closeEmoticons:(id)sender {
    [_emoticonsWindow endEditingFor:nil];
    [_emoticonsWindow makeFirstResponder:_emoticonsWindow];
    [_emoticonsWindow orderOut:self];
    [self saveEmoticons];
}

- (IBAction)inputEmoticons:(id)sender {
    [self closeEmoticons:sender];
    
    if ([[_telnetView frontMostConnection] isConnected]) {
        NSArray *a = [_emoticonsController selectedObjects];
        
        if ([a count] == 1) {
            YLEmoticon *e = [a objectAtIndex:0];
            [_telnetView insertText:[e content]];
        }
    }
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

- (void)saveEmoticonFromString:(NSString *)string {
	YLEmoticon *emoticon = [YLEmoticon emoticonWithString:string];
	[self addEmoticon:emoticon];
}

@end
