//
//  WLMainFrameController+RemoteControl.m
//  Welly
//
//  Created by K.O.ed on 10-4-30.
//  Copyright 2010 Welly Group. All rights reserved.
//

#import "WLMainFrameController+RemoteControl.h"
#import "WLMainFrameController+TabControl.h"

#import "WLTabView.h"
#import "WLConnection.h"
#import "CommonType.h"

// for remote control
#import "AppleRemote.h"
#import "KeyspanFrontRowControl.h"
#import "RemoteControlContainer.h"
#import "MultiClickRemoteBehavior.h"

@implementation WLMainFrameController (RemoteControl)
const NSTimeInterval DEFAULT_CLICK_TIME_DIFFERENCE = 0.25;	// for remote control

#pragma mark -
#pragma mark Remote Control
- (void)initializeRemoteControl {
	// set remote control
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"RemoteSupport"]) {
		// 1. instantiate the desired behavior for the remote control device
		_remoteControlBehavior = [[MultiClickRemoteBehavior alloc] init];	
		// 2. configure the behavior
		[_remoteControlBehavior setDelegate:self];
		[_remoteControlBehavior setClickCountingEnabled:YES];
		[_remoteControlBehavior setSimulateHoldEvent:YES];
		[_remoteControlBehavior setMaximumClickCountTimeDifference:DEFAULT_CLICK_TIME_DIFFERENCE];
		// 3. a Remote Control Container manages a number of devices and conforms to the RemoteControl interface
		//    Therefore you can enable or disable all the devices of the container with a single "startListening:" call.
		NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
		RemoteControlContainer *container = [[RemoteControlContainer alloc] initWithDelegate:_remoteControlBehavior];
		[container instantiateAndAddRemoteControlDeviceWithClass:[AppleRemote class]];	
		[container instantiateAndAddRemoteControlDeviceWithClass:[KeyspanFrontRowControl class]];
		// to give the binding mechanism a chance to see the change of the attribute
		[self setValue:container forKey:@"remoteControl"];
		[container startListening:self];
		_remoteControl = container;
		[pool release];
	}
}

/* Remote Control */
- (void)remoteButton:(RemoteControlEventIdentifier)buttonIdentifier 
		 pressedDown:(BOOL)pressedDown 
		  clickCount:(unsigned int)clickCount {
	NSString *cmd = nil;
	
	if (!pressedDown) {	// release
		switch(buttonIdentifier) {
			case kRemoteButtonPlus:		// up
				if (clickCount == 1)
					cmd = termKeyUp;
				else
					cmd = termKeyPageUp;
				break;
			case kRemoteButtonMinus:	// down
				if (clickCount == 1)
					cmd = termKeyDown;
				else
					cmd = termKeyPageDown;
				break;			
			case kRemoteButtonMenu:
				break;
			case kRemoteButtonPlay:
				cmd = termKeyEnter;
				break;			
			case kRemoteButtonRight:	// right
				if (clickCount == 1)
					cmd = termKeyRight;
				else
					cmd = termKeyEnd;
				break;			
			case kRemoteButtonLeft:		// left
				if (clickCount == 1)
					cmd = termKeyLeft;
				else
					cmd = termKeyHome;
				break;			
			case kRemoteButtonPlus_Hold:
				[self disableTimer];
				break;				
			case kRemoteButtonMinus_Hold:
				[self disableTimer];
				break;				
			case kRemoteButtonPlay_Hold:
				break;
			default:
				break;
		}
	}
	else { // Key Press
		switch(buttonIdentifier) {
			case kRemoteButtonRight_Hold:	// Right Tab
				[self selectNextTab:self];
				break;
			case kRemoteButtonLeft_Hold:	// Left Tab
				[self selectPrevTab:self];
				break;
			case kRemoteButtonPlus_Hold:
				// Enable timer!
				[self disableTimer];
				_scrollTimer = [NSTimer scheduledTimerWithTimeInterval:scrollTimerInterval 
																target:self 
															  selector:@selector(doScrollUp:)
															  userInfo:nil
															   repeats:YES];
				break;
			case kRemoteButtonMinus_Hold:
				// Enable timer!
				[self disableTimer];
				_scrollTimer = [NSTimer scheduledTimerWithTimeInterval:scrollTimerInterval
																target:self 
															  selector:@selector(doScrollDown:)
															  userInfo:nil
															   repeats:YES];
				break;
			case kRemoteButtonMenu_Hold:
				[self togglePresentationMode:nil];
				break;
			default:
				break;
		}
	}
	
	if (cmd != nil) {
		[[_tabView frontMostConnection] sendText:cmd];
	}
}

// TODO: use responder instead of finding the connection!!
// for timer
- (void)doScrollDown:(NSTimer*)timer {
    [[_tabView frontMostConnection] sendText:termKeyDown];
}

- (void)doScrollUp:(NSTimer*)timer {
    [[_tabView frontMostConnection] sendText:termKeyUp];
}

- (void)disableTimer {
    [_scrollTimer invalidate];
    [_scrollTimer release];
    _scrollTimer = nil;
}

// for bindings access
- (RemoteControl*)remoteControl {
    return _remoteControl;
}

- (MultiClickRemoteBehavior*)remoteBehavior {
    return _remoteControlBehavior;
}

@end
