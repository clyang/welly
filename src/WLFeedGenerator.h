//
//  TYFeedGenerator.h
//  Welly
//
//  Created by aqua on 11/2/2009.
//  Copyright 2009 TANG Yang. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface WLFeedGenerator : NSObject {
    NSString *_siteName;
    NSXMLDocument *_xmlDoc;
}

- (id)initWithSiteName:(NSString *)siteName;
- (void)addItemWithTitle:(NSString *)aTitle description:(NSString *)aDescription author:(NSString *) anAuthor pubDate:(NSString *)aPubDate;
- (BOOL)writeFeedToFile:(NSString *)fileName;

@end
