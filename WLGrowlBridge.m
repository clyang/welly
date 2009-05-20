//
//  WLGrowlBridge.m
//  Welly
//
//  Created by aqua9 on 20/3/2008.
//  Copyright 2008 TANG Yang. All rights reserved.
//
//  Modified by boost @ 9#
//  Extend for convenience.

#import "WLGrowlBridge.h"

typedef struct WLClickContext {
    id context, identifier;
    SEL selector; 
}WLClickContext;

@implementation WLGrowlBridge

+ (void)initialize {
    static WLGrowlBridge *sTYGrowlBridge = nil;
    if (sTYGrowlBridge == nil) {
        sTYGrowlBridge = [[WLGrowlBridge alloc] init];
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
               isSticky:(BOOL)isSticky
             identifier:(id)identifier {
    // hack identifier that must be a string
    NSString *stringId = [[NSNumber numberWithLong:(long)identifier] stringValue];
    [GrowlApplicationBridge notifyWithTitle:title
                                description:description
                           notificationName:notifName
                                   iconData:nil
                                   priority:0
                                   isSticky:isSticky
                               clickContext:nil
                                 identifier:stringId];
}

+ (void)notifyWithTitle:(NSString *)title
            description:(NSString *)description
       notificationName:(NSString *)notifName
               isSticky:(BOOL)isSticky
           clickContext:(id)clickContext
          clickSelector:(SEL)clickSelector
             identifier:(id)identifier {
    [self notifyWithTitle:title
              description:description
         notificationName:notifName
                 iconData:nil
                 priority:0
                 isSticky:isSticky
             clickContext:clickContext
            clickSelector:clickSelector
               identifier:identifier];
}

+ (void)notifyWithTitle:(NSString *)title
            description:(NSString *)description
       notificationName:(NSString *)notifName
               iconData:(NSData *)iconData
               priority:(signed int)priority
               isSticky:(BOOL)isSticky
           clickContext:(id)clickContext
          clickSelector:(SEL)clickSelector
             identifier:(id)identifier {
    WLClickContext *c = malloc(sizeof(WLClickContext));
    c->context = clickContext;
    c->selector = clickSelector;
    c->identifier = identifier;
    // workaround: clickContext must be plist-encodable
    NSNumber* contextId = [NSNumber numberWithLong:(long)c];
    // hack identifier that must be a string
    NSString *stringId = [[NSNumber numberWithLong:(long)identifier] stringValue];
    [GrowlApplicationBridge notifyWithTitle:title
                                description:description
                           notificationName:notifName
                                   iconData:nil
                                   priority:0
                                   isSticky:NO
                               clickContext:contextId
                                 identifier:stringId];
}

- (void)growlNotificationWasClicked:(id)contextId {
    // get context
    WLClickContext *c = (WLClickContext *)[(NSNumber *)contextId longValue];
    [c->context performSelector:c->selector withObject:c->identifier];
    free(c);
}

- (void)growlNotificationTimedOut:(id)contextId {
    // deal with the event that the notification disappear
    WLClickContext *c = (WLClickContext *)[(NSNumber *)contextId longValue];
    free(c);
}

@end
