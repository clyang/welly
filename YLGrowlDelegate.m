//
//  YLGrowlDelegate.m
//  MacBlueTelnet
//
//  Created by aqua9 on 20/3/2008.
//  Copyright 2008 TANG Yang. All rights reserved.
//

#import "YLGrowlDelegate.h"

@implementation YLGrowlDelegate

static int s_contextId = 0;
- (id) init {
	self = [super init];
	if (self != nil) {
		m_contexts = [[NSMutableDictionary dictionary] retain];
	}
	return self;
}

- (void) setup {
	NSBundle *myBundle = [NSBundle mainBundle];
	NSString *growlPath = [[myBundle privateFrameworksPath] stringByAppendingPathComponent: @"Growl-WithInstaller.framework"];
	NSBundle *growlBundle = [NSBundle bundleWithPath: growlPath];
	if (growlBundle && [growlBundle load]) {
		// Register ourselves as a Growl delegate
		[GrowlApplicationBridge setGrowlDelegate: self];
	} else {
		NSLog(@"Could not load Growl-WithInstaller.framework");
	}
}

- (NSDictionary *) registrationDictionaryForGrowl {
	NSArray *notifications = [NSArray arrayWithObjects: @"YLNotificationNewMessage", @"YLNotificationIPSeeker", nil];
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	[dict setObject:notifications forKey: GROWL_NOTIFICATIONS_ALL];
	[dict setObject:notifications forKey: GROWL_NOTIFICATIONS_DEFAULT];
	return dict;
}

- (void) setController: (YLController *)controller {
	ylcontroller = controller;
}

- (void) newMessage: (NSString *)callerName 
			message: (NSString *)message
			context: (NSDictionary *) context {
		// invoke a growl notification when there is new message coming
		// make context infomation
		NSNumber* contextId = [NSNumber numberWithInt:s_contextId++];
			
		[m_contexts setObject:context forKey:contextId];
		// invoke the growl notification
		[GrowlApplicationBridge notifyWithTitle: callerName
									description: message
							   notificationName: @"YLNotificationNewMessage"
									   iconData: [NSData data]
									   priority: 0
									   isSticky: NO
								   clickContext: contextId];
}

- (void) growlNotificationWasClicked : (id)clickContext {
	// deal with clicking on the notifications.
	// force the welly window to be fronted
	[ylcontroller forceFront];
	
	// get context
	NSDictionary* context = [[[m_contexts objectForKey:clickContext] retain] autorelease];
	[m_contexts removeObjectForKey:clickContext];
	
	if ([context objectForKey:kContextNotificationName] == gNotificationMessage) {
		id tabId = [context objectForKey:kContextTabID];
		YLView *view = [context objectForKey:kContextYLView];
	
		// switch to the tab received message
		[view selectTabViewItemWithIdentifier: tabId];
	} else {
		// default
	}
}

- (void) growlNotificationTimedOut : (id)clickContext {
	// deal with the event that the notification disappear
	NSDictionary* context = [[[m_contexts objectForKey:clickContext] retain] autorelease];
	[m_contexts removeObjectForKey:clickContext];
	
	if ([context objectForKey:kContextNotificationName] == gNotificationMessage) {
		// do something
	} else {
		// default
	}

}

@end
