//
//  LLURLManager.h
//  Welly
//
//  Created by K.O.ed on 09-3-16.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <KOMouseHotspotHandler.h>

@interface LLURLManager : KOMouseHotspotHandler <KOUpdatable, KOMouseUpHandler, KOContextualMenuHandler> {
	NSMutableArray * _currentURLList;
}

@end
