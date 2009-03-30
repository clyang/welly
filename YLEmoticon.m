//
//  YLEmoticon.m
//  MacBlueTelnet
//
//  Created by Lan Yung-Luen on 12/4/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import "YLEmoticon.h"


@implementation YLEmoticon
@synthesize name = _name;
@synthesize content = _content;

+ (YLEmoticon *)emoticonWithDictionary:(NSDictionary *)d {
    YLEmoticon *e = [[YLEmoticon alloc] init];
//    [e setName: [d valueForKey: @"name"]];
    [e setContent:[d valueForKey:@"content"]];
    return [e autorelease];    
}

+ (void)initialize {
    [self setKeys:[NSArray arrayWithObjects:@"content", nil] triggerChangeNotificationsForDependentKey:@"description"];
}

- (NSDictionary *)dictionaryOfEmoticon {
    return [NSDictionary dictionaryWithObjectsAndKeys:[self content], @"content", nil];
}
     
+ (YLEmoticon *)emoticonWithName:(NSString *)n 
						 content:(NSString *)c {
    YLEmoticon *e = [[YLEmoticon alloc] init];
//    [e setName: n];
    [e setContent:c];
    return [e autorelease];
}

- (id)init {
    if (self = [super init]) {
        [self setContent: @":)"];
//        [self setName: @"smile"];
    }
    return self;
}

- (void)dealloc {
    [_content release];
    [_name release];
    [super dealloc];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@", [[[self content]componentsSeparatedByString:@"\n"] componentsJoinedByString:@""]];
}

- (void)setDescription:(NSString *)d { }

@end
