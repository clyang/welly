//
//  LLURLManager.h
//  Welly
//
//  Created by K.O.ed on 09-3-16.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WLMouseHotspotHandler.h"

@interface WLURLManager : WLMouseHotspotHandler <WLUpdatable, WLMouseUpHandler, WLContextualMenuHandler> {
	NSMutableArray *_currentURLList;
	int _currentSelectedURLIndex;
	
	//NSMutableString *_currentURLStringBuffer;
}
- (NSPoint)currentSelectedURLPos;
- (BOOL)openCurrentURL:(NSEvent *)event;
- (NSPoint)moveNext;
- (NSPoint)movePrev;
- (void)addURL:(NSString *)urlString
	   atIndex:(int)index
		length:(int)length;
@end
