//
//  KOClickEntryHotspotHandler.m
//  Welly
//
//  Created by K.O.ed on 09-1-12.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "KOClickEntryHotspotHandler.h"
#import "YLView.h"
#import "YLConnection.h"
#import "YLSite.h"
#import "KOEffectView.h"
#import "YLLGlobalConfig.h"
#import "YLTerminal.h"

@implementation KOClickEntryHotspotHandler

- (id) initWithView: (YLView *)view 
			   rect: (NSRect)rect
				row: (int)row {
	[super initWithView:view rect:rect];
	_row = row;
	[_view addCursorRect:rect cursor:[NSCursor pointingHandCursor]];
	return self;
}

- (id) initWithView: (YLView *)view 
			   rect: (NSRect)rect 
	commandSequence: (NSString *)commandSequence {
	[super initWithView:view rect:rect];
	_commandSequence = [commandSequence retain];
	[_view addCursorRect:rect cursor:[NSCursor pointingHandCursor]];
	return self;
}

- (void) dealloc {
	//NSLog(@"KOClickEntryHotspotHandler dealloc:");
	if (_commandSequence)
		[_commandSequence release];
	[_view removeCursorRect:_rect cursor:[NSCursor pointingHandCursor]];
	[super dealloc];
}

#pragma mark -
#pragma mark Mouse Event Handler
- (void) mouseUp: (NSEvent *)theEvent {
	if (_commandSequence != nil) {
		[[_view frontMostConnection] sendText: _commandSequence];
		return;
	}
	YLLGlobalConfig *globalConfig = [YLLGlobalConfig sharedInstance];
	unsigned char cmd[[globalConfig row] * [globalConfig column] + 1];
	unsigned int cmdLength = 0;
	YLTerminal *ds = [_view frontMostTerminal];
	int moveToRow = _row;
	int cursorRow = [ds cursorRow];
	//NSLog(@"KOClickEntryHotspotHandler mouseUp: move to %d, cursor at %d", moveToRow, cursorRow);
	
	if (moveToRow > cursorRow) {
		//cmd[cmdLength++] = 0x01;
		for (int i = cursorRow; i < moveToRow; i++) {
			cmd[cmdLength++] = 0x1B;
			cmd[cmdLength++] = 0x4F;
			cmd[cmdLength++] = 0x42;
		} 
	} else if (moveToRow < cursorRow) {
		//cmd[cmdLength++] = 0x01;
		for (int i = cursorRow; i > moveToRow; i--) {
			cmd[cmdLength++] = 0x1B;
			cmd[cmdLength++] = 0x4F;
			cmd[cmdLength++] = 0x41;
		} 
	}
	
	cmd[cmdLength++] = 0x0D;
	
	[[_view frontMostConnection] sendBytes: cmd length: cmdLength];
}

- (void) mouseEntered: (NSEvent *)theEvent {
	//NSLog(@"mouseEntered: ");
	if([[[_view frontMostConnection] site] enableMouse]) {
		[_effectView drawClickEntry: _rect];
		[_view setActiveHandler: self];
	}
}

- (void) mouseExited: (NSEvent *)theEvent {
	//NSLog(@"mouseExited: ");
	[_effectView clearClickEntry];
	[_view removeActiveHandler];
}

- (void) mouseMoved: (NSEvent *)theEvent {
	if ([NSCursor currentCursor] != [NSCursor pointingHandCursor])
		[[NSCursor pointingHandCursor] set];
}

@end
