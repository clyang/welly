//
//  YLContextualMenuManager.h
//  MacBlueTelnet
//
//  Created by Lan Yung-Luen on 11/28/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface YLContextualMenuManager : NSObject {

}
+ (YLContextualMenuManager *) sharedInstance ;
- (id) init ;
- (NSArray *) availableMenuItemForSelectionString: (NSString *) s ;
- (NSString *) extractShortURL: (NSString *) s ;
- (NSString *) extractLongURL: (NSString *) s ;

@end
