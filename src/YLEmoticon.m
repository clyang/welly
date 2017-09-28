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

#pragma mark -
#pragma mark init and dealloc
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

- (id)initWithName:(NSString *)name 
		   content:(NSString *)content {
	if (self = [self init]) {
		//_name = name;
		//_content = content;
		[self setName:name];
		[self setContent:content];
	}
	return self;
}

#pragma mark -
#pragma mark Create Emoticons
+ (YLEmoticon *)emoticonWithDictionary:(NSDictionary *)d {
    YLEmoticon *e = [[YLEmoticon alloc] init];
//    [e setName: [d valueForKey: @"name"]];
    [e setContent:[d valueForKey:@"content"]];
    return [e autorelease];    
}

+ (YLEmoticon *)emoticonWithName:(NSString *)n 
						 content:(NSString *)c {
    YLEmoticon *e = [[YLEmoticon alloc] initWithName:n content:c];
    return [e autorelease];
}

+ (YLEmoticon *)emoticonWithString:(NSString *)string {
	YLEmoticon *e = [[YLEmoticon alloc] initWithName:string content:string];
	return [e autorelease];
}

#pragma mark -
#pragma mark Access Emoticons
+ (NSSet *)keyPathsForValuesAffectingDescription {
    return [NSSet setWithObjects:@"content", nil];
}

- (NSDictionary *)dictionaryOfEmoticon {
    return [NSDictionary dictionaryWithObjectsAndKeys:[self content], @"content", nil];
}
     
- (NSString *)description {
    return [NSString stringWithFormat:@"%@", [[[self content] componentsSeparatedByString:@"\n"] componentsJoinedByString:@""]];
}

- (void)setDescription:(NSString *)d { }

@end
