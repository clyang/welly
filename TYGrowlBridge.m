//
//  TYGrowlBridge.m
//  Welly
//
//  Created by aqua9 on 20/3/2008.
//  Copyright 2008 TANG Yang. All rights reserved.
//
//  Modified by boost @ 9#
//  Extend for convenience.

#import "TYGrowlBridge.h"

typedef struct TYClickContext {
    id context, object;
    SEL selector; 
}TYClickContext;

@implementation TYGrowlBridge

+ (void)setup {
    static TYGrowlBridge *sTYGrowlBridge = nil;
    if (sTYGrowlBridge == nil) {
        sTYGrowlBridge = [[TYGrowlBridge alloc] init];
        [GrowlApplicationBridge setGrowlDelegate:sTYGrowlBridge];
    }
}

+ (void)notifyWithTitle:(NSString *)title
			 description:(NSString *)description
		notificationName:(NSString *)notifName {
    [GrowlApplicationBridge notifyWithTitle:title
                                description:description
                           notificationName:notifName
                                   iconData:nil
                                   priority:0
                                   isSticky:NO
                                   clickContext:nil];
}

+ (void)notifyWithTitle:(NSString *)title
            description:(NSString *)description
       notificationName:(NSString *)notifName
               iconData:(NSData *)iconData
               priority:(signed int)priority
               isSticky:(BOOL)isSticky
           clickContext:(id)clickContext
          clickSelector:(SEL)clickSelector
             withObject:(id)object {
    TYClickContext *c = malloc(sizeof(TYClickContext));
    c->context = clickContext;
    c->selector = clickSelector;
    c->object = object;
    // workaround: clickContext must be plist-encodable
    NSNumber* contextId = [NSNumber numberWithLong:(long)c];
    [GrowlApplicationBridge notifyWithTitle:title
                                description:description
                           notificationName:notifName
                                   iconData:nil
                                   priority:0
                                   isSticky:NO
                               clickContext:contextId];
}

- (void)growlNotificationWasClicked:(id)contextId {
	// get context
	TYClickContext *c = (TYClickContext *)[(NSNumber *)contextId longValue];
    [c->context performSelector:c->selector withObject:c->object];
    free(c);
}

- (void)growlNotificationTimedOut:(id)contextId {
	// deal with the event that the notification disappear
    TYClickContext *c = (TYClickContext *)[(NSNumber *)contextId longValue];
    free(c);
}

@end
