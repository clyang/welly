//
//  YLEmoticon.h
//  MacBlueTelnet
//
//  Created by Lan Yung-Luen on 12/4/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface YLEmoticon : NSObject {
    NSString *_name;
    NSString *_content;
}

- (NSString *)content;
- (void)setContent:(NSString *)value;
- (NSString *)name;
- (void)setName:(NSString *)value;


+ (YLEmoticon *)emoticonWithDictionary:(NSDictionary *)d;
- (NSDictionary *)dictionaryOfEmoticon;

@end
