//
//  YLEmoticon.m
//  MacBlueTelnet
//
//  Created by Lan Yung-Luen on 12/4/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import "YLEmoticon.h"


@implementation YLEmoticon

+ (YLEmoticon *) emoticonWithDictionary: (NSDictionary *) d {
    YLEmoticon *e = [[YLEmoticon alloc] init];
//    [e setName: [d valueForKey: @"name"]];
    [e setContent: [d valueForKey: @"content"]];
    return [e autorelease];    
}

+ (void) initialize 
{
    [self setKeys: [NSArray arrayWithObjects: @"content", nil] triggerChangeNotificationsForDependentKey: @"description"];
}

- (NSDictionary *) dictionaryOfEmoticon {
    return [NSDictionary dictionaryWithObjectsAndKeys: [self content], @"content", nil];
}
     
+ (YLEmoticon *) emoticonWithName: (NSString *) n content: (NSString *) c {
    YLEmoticon *e = [[YLEmoticon alloc] init];
//    [e setName: n];
    [e setContent: c];
    return [e autorelease];
}

- (id) init {
    if (self = [super init]) {
        [self setContent: @":)"];
//        [self setName: @"smile"];
    }
    return self;
}

- (void) dealloc {
    [_content release];
    [_name release];
    [super dealloc];
}

- (NSString *)content {
    return [[_content retain] autorelease];
}

- (void)setContent:(NSString *)value {
    if (_content != value) {
        [_content release];
        _content = [value copy];
    }
}

- (NSString *)name {
    return [[_name retain] autorelease];
}

- (void)setName:(NSString *)value {
    if (_name != value) {
        [_name release];
        _name = [value copy];
    }
}

- (NSString *) description {
    return [NSString stringWithFormat: @"%@", [[[self content] componentsSeparatedByString: @"\n"] componentsJoinedByString: @""]];
}

- (void) setDescription: (NSString *) d { }

@end
