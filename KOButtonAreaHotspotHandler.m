//
//  KOButtonAreaHotspotHandler.m
//  Welly
//
//  Created by K.O.ed on 09-1-27.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "KOButtonAreaHotspotHandler.h"
#import "YLView.h"
#import "YLConnection.h"
#import "YLSite.h"
#import "KOEffectView.h"

@implementation KOButtonAreaHotspotHandler

- (id) initWithView: (YLView *)view 
			   rect: (NSRect)rect 
		 buttonType: (KOButtonType) buttonType
	commandSequence: (NSString *)cmd {
	_buttonType = buttonType;
	_commandSequence = [cmd retain];
	[super initWithView:view rect:rect];
	[_view addCursorRect:rect cursor:[NSCursor pointingHandCursor]];
	return self;
}

- (void) dealloc {
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
}

- (void) mouseEntered: (NSEvent *)theEvent {
	//NSLog(@"mouseEntered: ");
	if([[_view frontMostConnection] connected] && [[[_view frontMostConnection] site] enableMouse]) {
		[_effectView drawButton:_rect withMessage:[self getButtonText]];
	}
	[_view setActiveHandler: self];
}

- (void) mouseExited: (NSEvent *)theEvent {
	//NSLog(@"mouseExited: ");
	[_effectView clearButton];
	[_view removeActiveHandler];
}

- (void) mouseMoved: (NSEvent *)theEvent {
	if ([NSCursor currentCursor] != [NSCursor pointingHandCursor])
		[[NSCursor pointingHandCursor] set];
}

- (NSString *)getButtonText {
	switch (_buttonType) {
		case COMPOSE_POST:
			return @"发表文章";
		case DELETE_POST:
			return @"自宫";
		case SHOW_NOTE:
			return @"备忘录";
		case SHOW_HELP:
			return @"求助";
		case NORMAL_TO_DIGEST:
			return @"切换到文摘模式";
		case DIGEST_TO_THREAD:
			return @"切换到主题模式";
		case THREAD_TO_MARK:
			return @"切换到精华模式";
		case MARK_TO_ORIGIN:
			return @"切换到原作模式";
		case ORIGIN_TO_NORMAL:
			return @"切换到一般模式";
		default:
			break;
	}
	return @"";
}
@end
