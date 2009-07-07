//
//  WLIPAddrHotspotHandler.m
//  Welly
//
//  Created by K.O.ed on 09-1-27.
//  Copyright 2009 Welly Group. All rights reserved.
//

#import "WLIPAddrHotspotHandler.h"
#import "WLMouseBehaviorManager.h"

#import "YLView.h"
#import "YLConnection.h"
#import "YLTerminal.h"
#import "YLLGlobalConfig.h"
#import "IPSeeker.h"
#import "WLEffectView.h"

@implementation WLIPAddrHotspotHandler
#pragma mark -
#pragma mark Event Handler
- (void)mouseEntered:(NSEvent *)theEvent {
	if([_view isMouseActive]) {
		[[_view effectView] drawIPAddrBox:[[theEvent trackingArea] rect]];
	}
}

- (void)mouseExited:(NSEvent *)theEvent {
	[[_view effectView] clearIPAddrBox];
}

#pragma mark -
#pragma mark Generate User Info
- (NSDictionary *)userInfo {
	return [NSDictionary dictionaryWithObject:self forKey:WLMouseHandlerUserInfoName];
}

#pragma mark -
#pragma mark Update State
- (void)addIPRect:(const char *)ip
			  row:(int)r
		   column:(int)c
		   length:(int)length {
	/* ip tooltip */
	NSRect rect = [_view rectAtRow:r column:c height:1 width:length];
	NSString *tooltip = [[IPSeeker shared] getLocation:ip];
	[_view addToolTipRect:rect owner:_manager userData:tooltip];
	
	NSDictionary *userInfo = [self userInfo];
	[_trackingAreas addObject:[_manager addTrackingAreaWithRect:rect userInfo:userInfo]];
}

- (void)updateIPStateForRow:(int)r {
	cell *currRow = [[_view frontMostTerminal] cellsOfRow:r];
	int state = 0;
	char ip[4] = {0};
	int seg = 0;
	int start = 0, length = 0, lengthInSeg = 0;
	for (int i = 0; i < _maxColumn; i++) {
		unsigned char b = currRow[i].byte;
		switch (state) {
			case 0:
				if (b >= '0' && b <= '9') { // numeric, beginning of an ip
					start = i;
					length = 1;
					ip[0] = ip[1] = ip[2] = ip[3];
					seg = b - '0';
					state = 1;
				}
				break;
			case 1:
			case 2:
			case 3:
				if (b == '.') {	// segment ended
					if (seg > 255) {	// invalid number
						state = 0;
						break;
					}
					// valid number
					ip[state-1] = seg & 0xff;
					seg = 0;
					state++;
					length++;
				} else if (b >= '0' && b <= '9') {	// continue to be numeric
					seg = seg * 10 + (b - '0');
					length++;
				} else {	// invalid character
					state = 0;
					break;
				}
				break;
            case 4:
                if (b >= '0' && b <= '9') {	// continue to be numeric
                    seg = seg * 10 + (b - '0');
                    length++;
					++lengthInSeg;
					if ((seg < 255) && (i == _maxColumn - 1)) {	// available ip at the end of a row
                        ip[state-1] = seg & 255;
                        [self addIPRect:ip row:r column:start length:length];
					}
                } else {	// non-numeric, then the string should be finished.
                    if (b == '*') { // for ip address 255.255.255.*
                        ++length;
					} else if (lengthInSeg == 0) { // for non-address: Apple released Mac OS 10.5.6.
						break;
					}
                    if (seg < 255) {	// available ip
                        ip[state-1] = seg & 255;
                        [self addIPRect:ip row:r column:start length:length];
                    }
                    state = 0;
					lengthInSeg = 0;
                }
                break;
			default:
				break;
		}
	}
}

- (void)clear {
	// Since only IP use tooltips, remove all should be okay. Change this when adding new tooltips to the view!
	[_view removeAllToolTips];
	
	[self removeAllTrackingAreas];
}

- (BOOL)shouldUpdate {
	return YES;
}

- (void)update {
	[self clear];
	
	if (![_view isConnected]) {
		return;	
	}
	
	for (int r = 0; r < _maxRow; ++r) {
		[self updateIPStateForRow:r];
	}
}
@end

@implementation NSObject(NSToolTipOwner)
- (NSString *)view:(NSView *)view 
  stringForToolTip:(NSToolTipTag)tag 
			 point:(NSPoint)point 
		  userData:(void *)userData {
	return (NSString *)userData;
}
@end