//
//  KOClickEntryHotspotHandler.m
//  Welly
//
//  Created by K.O.ed on 09-1-12.
//  Copyright 2009 Welly Group. All rights reserved.
//

#import "KOClickEntryHotspotHandler.h"
#import "KOMouseBehaviorManager.h"
#import "KOEffectView.h"
#import "YLLGlobalConfig.h"
#import "YLApplication.h"
#import "YLController.h"
#import "YLTerminal.h"
#import "YLView.h"
#import "YLConnection.h"
#import "encoding.h"

NSString *const KOMenuTitleDownloadPost = @"Download post";
NSString *const KOMenuTitleThreadTop = @"Thread top";
NSString *const KOMenuTitleThreadBottom = @"Thread bottom";
NSString *const KOMenuTitleSameAuthorReading = @"Same author reading";
NSString *const KOMenuTitleSameThreadReading = @"Same thread reading";

NSString *const KOCommandSequenceThreadTop = @"=";
NSString *const KOCommandSequenceThreadBottom = @"\\";
NSString *const KOCommandSequenceSameThreadReading = @"\030";	// ^X
NSString *const KOCommandSequenceSameAuthorReading = @"\025";	// ^U

@implementation KOClickEntryHotspotHandler
- (void)dealloc {
	[super dealloc];
}

#pragma mark -
#pragma mark Mouse Event Handler
- (void)moveCursorToRow:(int)moveToRow {
	unsigned char cmd[_maxRow * _maxColumn + 1];
	unsigned int cmdLength = 0;
	YLTerminal *ds = [_view frontMostTerminal];
	int cursorRow = [ds cursorRow];
	
	// Moving Command
	if (moveToRow > cursorRow) {
		for (int i = cursorRow; i < moveToRow; i++) {
			cmd[cmdLength++] = 0x1B;
			cmd[cmdLength++] = 0x4F;
			cmd[cmdLength++] = 0x42;
		} 
	} else if (moveToRow < cursorRow) {
		for (int i = cursorRow; i > moveToRow; i--) {
			cmd[cmdLength++] = 0x1B;
			cmd[cmdLength++] = 0x4F;
			cmd[cmdLength++] = 0x41;
		} 
	}

	[[_view frontMostConnection] sendBytes:cmd length:cmdLength];
}

- (void)enterEntryAtRow:(int)moveToRow {
	[self moveCursorToRow:moveToRow];
	
	// Enter
	[_view sendText:termKeyEnter];
}

- (void)mouseUp:(NSEvent *)theEvent {
	NSString *commandSequence = [_manager.activeTrackingAreaUserInfo objectForKey:KOMouseCommandSequenceUserInfoName];
	if (commandSequence != nil) {
		[_view sendText: commandSequence];
		return;
	}
	int moveToRow = [[_manager.activeTrackingAreaUserInfo objectForKey:KOMouseRowUserInfoName] intValue];
	
	[self enterEntryAtRow:moveToRow];
}

- (void)mouseEntered:(NSEvent *)theEvent {
	//NSLog(@"mouseEntered: ");
	[[_view effectView] drawClickEntry: [[theEvent trackingArea] rect]];
	_manager.activeTrackingAreaUserInfo = [[theEvent trackingArea] userInfo];
}

- (void)mouseExited:(NSEvent *)theEvent {
	//NSLog(@"mouseExited: ");
	[[_view effectView] clearClickEntry];
	_manager.activeTrackingAreaUserInfo = nil;
	// FIXME: Temporally solve the problem in full screen mode.
	if ([NSCursor currentCursor] == [NSCursor pointingHandCursor])
		[_manager restoreNormalCursor];
}

- (void)mouseMoved:(NSEvent *)theEvent {
	if ([NSCursor currentCursor] != [NSCursor pointingHandCursor])
		[[NSCursor pointingHandCursor] set];
}

#pragma mark -
#pragma mark Contextual Menu
- (void)doDownloadPost:(id)sender {
	NSDictionary *userInfo = [sender representedObject];
	
	// Enter the entry
	int moveToRow = [[userInfo objectForKey:KOMouseRowUserInfoName] intValue];
	[self enterEntryAtRow:moveToRow];
	
	// Wait until state change
	const int sleepTime = 100000, maxAttempt = 300000;
	int count = 0;
	while ([[_view frontMostTerminal] bbsState].state != BBSViewPost && count < maxAttempt) {
		++count;
		usleep(sleepTime);
	}
	
	// Do Post Download
	[(YLController *)[(YLApplication *)NSApp controller] openPostDownload:sender];
}

- (IBAction)downloadPost:(id)sender {
	// Do this in new thread to avoid blocking the main thread
	[NSThread detachNewThreadSelector:@selector(doDownloadPost:) toTarget:self withObject:sender];
}

- (void)moveCursorBySender:(id)sender {
	NSDictionary *userInfo = [sender representedObject];
	
	// Move the cursor to the entry
	int moveToRow = [[userInfo objectForKey:KOMouseRowUserInfoName] intValue];
	[self moveCursorToRow:moveToRow];
}

- (IBAction)threadTop:(id)sender {
	[self moveCursorBySender:sender];
	[_view sendText:KOCommandSequenceThreadTop];
}

- (IBAction)threadBottom:(id)sender {
	[self moveCursorBySender:sender];	
	[_view sendText:KOCommandSequenceThreadBottom];
}

- (IBAction)sameAuthorReading:(id)sender {
	[self moveCursorBySender:sender];
	[_view sendText:KOCommandSequenceSameAuthorReading];
}

- (IBAction)sameThreadReading:(id)sender {
	[self moveCursorBySender:sender];	
	[_view sendText:KOCommandSequenceSameThreadReading];
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
	NSMenu *menu = [[[NSMenu alloc] init] autorelease];
	if ([[_view frontMostTerminal] bbsState].state == BBSBrowseBoard) {
		[menu addItemWithTitle:NSLocalizedString(KOMenuTitleDownloadPost, @"Contextual Menu")
						action:@selector(downloadPost:)
				 keyEquivalent:@""];
		[menu addItemWithTitle:NSLocalizedString(KOMenuTitleThreadTop, @"Contextual Menu") 
						action:@selector(threadTop:) 
				 keyEquivalent:@""];
		[menu addItemWithTitle:NSLocalizedString(KOMenuTitleThreadBottom, @"Contextual Menu") 
						action:@selector(threadBottom:) 
				 keyEquivalent:@""];
		[menu addItemWithTitle:NSLocalizedString(KOMenuTitleSameAuthorReading, @"Contextual Menu") 
						action:@selector(sameAuthorReading:) 
				 keyEquivalent:@""];
		[menu addItemWithTitle:NSLocalizedString(KOMenuTitleSameThreadReading, @"Contextual Menu") 
						action:@selector(sameThreadReading:) 
				 keyEquivalent:@""];
	}
	
	for (NSMenuItem *item in [menu itemArray]) {
		if ([item isSeparatorItem])
			continue;
		[item setTarget:self];
		[item setRepresentedObject:_manager.activeTrackingAreaUserInfo];
	}
	return menu;
}

#pragma mark -
#pragma mark Add Tracking Areas
- (void)addClickEntryRect:(NSString *)title
					  row:(int)r
				   column:(int)c
				   length:(int)length {
	NSRect rect = [_view rectAtRow:r column:c height:1 width:length];
	// Generate User Info
	NSArray *keys = [NSArray arrayWithObjects: KOMouseHandlerUserInfoName, KOMouseRowUserInfoName, nil];
	NSArray *objects = [NSArray arrayWithObjects: self, [NSNumber numberWithInt:r], nil];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	[_manager addTrackingAreaWithRect:rect userInfo:userInfo cursor:[NSCursor pointingHandCursor]];
}

- (void)addClickEntryRectAtRow:(int)r column:(int)c length:(int)length {
    NSString *title = [[_view frontMostTerminal] stringFromIndex:c+r*_maxColumn length:length];
    [self addClickEntryRect:title row:r column:c length:length];
}

- (void)addMainMenuClickEntry:(NSString *)cmd 
						  row:(int)r
					   column:(int)c 
					   length:(int)len {
	NSRect rect = [_view rectAtRow:r column:c height:1 width:len];
	// Generate User Info
	NSArray *keys = [NSArray arrayWithObjects:KOMouseHandlerUserInfoName, KOMouseCommandSequenceUserInfoName, nil];
	NSArray *objects = [NSArray arrayWithObjects:self, cmd, nil];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	[_manager addTrackingAreaWithRect:rect userInfo:userInfo cursor:[NSCursor pointingHandCursor]];
}

#pragma mark -
#pragma mark Update State
- (BOOL)startsAtRow:(int)row 
			 column:(int)column 
			   with:(NSString *)s {
    cell *currRow = [[_view frontMostTerminal] cellsOfRow:row];
    int i = 0, n = [s length];
    for (; i < n && column < _maxColumn - 1; ++i, ++column)
        if (currRow[column].byte != [s characterAtIndex:i])
            return NO;
    if (i != n)
        return NO;
    return YES;
}

BOOL isPostTitleStarter(unichar c) {
	// smth: 0x25cf (solid circle "●"), 0x251c ("├"), 0x2514 ("└"), 0x2605("★")
	// free/sjtu: 0x25c6 (solid diamond "◆")
	// ptt: 0x25a1 (hollow square "□")
	return (c == 0x25cf || c == 0x251c || c == 0x2514 || c == 0x2605 
			|| c == 0x25c6 || c == 0x25a1);
}

- (void)updateClickEntryForRow:(int)r {
	//NSLog(@"KOClickEntryHotspotHandler updateClickEntryForRow:%d", r);
    YLTerminal *ds = [_view frontMostTerminal];
    cell *currRow = [ds cellsOfRow:r];
    if ([ds bbsState].state == BBSBrowseBoard || [ds bbsState].state == BBSMailList) {
        // browsing a board
		// header/footer
		if (r < 3 || r == _maxRow - 1)
			return;
		
		int start = -1, end = -1;
		unichar textBuf[_maxColumn + 1];
		int bufLength = 0;
		
        // don't check the first two columns ("●" may be used as cursor)
        for (int i = 2; i < _maxColumn - 1; ++i) {
			int db = currRow[i].attr.f.doubleByte;
			if (db == 0) {
                if (start == -1) {
                    if ([self startsAtRow:r column:i with:@"Re: "] || // smth
                        [self startsAtRow:r column:i with:@"R: "])    // ptt
                        start = i;
                }
				if (currRow[i].byte > 0 && currRow[i].byte != ' ')
					end = i;
                if (start != -1)
                    textBuf[bufLength++] = 0x0000 + (currRow[i].byte ?: ' ');
            } else if (db == 2) {
				unsigned short code = (((currRow + i - 1)->byte) << 8) + ((currRow + i)->byte) - 0x8000;
				unichar ch = [[[_view frontMostConnection] site] encoding] == YLBig5Encoding ? B2U[code] : G2U[code];
                // smth: 0x25cf (solid circle "●"), 0x251c ("├"), 0x2514 ("└"), 0x2605("★")
                // free/sjtu: 0x25c6 (solid diamond "◆")
                // ptt: 0x25a1 (hollow square "□")
                if (start == -1 && isPostTitleStarter(ch))//ch >= 0x2510 && ch <= 0x260f)
					start = i - 1;
				end = i;
				if (start != -1)
					textBuf[bufLength++] = ch;
			}
		}
		
		if (start == -1)
			return;
		
		[self addClickEntryRect:[NSString stringWithCharacters:textBuf length:bufLength]
							row:r
						 column:start
						 length:end - start + 1];
		
	} else if ([ds bbsState].state == BBSBoardList) {
        // watching board list
		// header/footer
		if (r < 3 || r == _maxRow - 1)
			return;
		
        // TODO: fix magic numbers
        if (currRow[12].byte != 0 && currRow[12].byte != ' ' && (currRow[11].byte == ' ' || currRow[11].byte == '*'))
            [self addClickEntryRectAtRow:r column:12 length:80-28]; // smth
        else if (currRow[10].byte != 0 && currRow[10].byte != ' ' && currRow[7].byte == ' ' && currRow[27].byte == ' ')
            [self addClickEntryRectAtRow:r column:10 length:80-26]; // ptt
        else if (currRow[10].byte != 0 && currRow[10].byte != ' ' && (currRow[9].byte == ' ' || currRow[9].byte == '-') && currRow[30].byte == ' ')
            [self addClickEntryRectAtRow:r column:10 length:80-23]; // lqqm
        else if (currRow[10].byte != 0 && currRow[10].byte != ' ' && (currRow[9].byte == ' ' || currRow[9].byte == '-') && currRow[31].byte == ' ')
            [self addClickEntryRectAtRow:r column:10 length:80-30]; // zju88
        else if (currRow[11].byte != 0 && currRow[11].byte != ' ' && (currRow[10].byte == ' ' || currRow[10].byte == '*') && currRow[37].byte == ' ')
            [self addClickEntryRectAtRow:r column:11 length:80-33]; // fudan
        else if (currRow[10].byte != 0 && currRow[10].byte != ' ' && (currRow[9].byte == ' ' || currRow[9].byte == '-') && currRow[35].byte == ' ')
            [self addClickEntryRectAtRow:r column:10 length:80-29]; // nankai
        else if (currRow[8].byte != 0 && currRow[8].byte != ' ' && currRow[7].byte == ' ' && currRow[33].byte == ' ')
            [self addClickEntryRectAtRow:r column:8 length:80-24]; // tku
        else if (currRow[8].byte != 0 && currRow[8].byte != ' ' && (currRow[5].byte == ' ' || currRow[5].byte == '-') && currRow[25].byte == ' ')
            [self addClickEntryRectAtRow:r column:8 length:80-26]; // wdbbs
        else if (currRow[8].byte != 0 && currRow[8].byte != ' ' && currRow[7].byte == ' ' && currRow[20].byte == ' ')
            [self addClickEntryRectAtRow:r column:8 length:80-36]; // cia
    } else if ([ds bbsState].state == BBSFriendList) {
		// header/footer
		if (r < 3 || r == _maxRow - 1)
			return;
		
        // TODO: fix magic numbers
        if (currRow[7].byte == 0 || currRow[7].byte == ' ')
            return;
        [self addClickEntryRectAtRow:r column:7 length:80-13];
	} else if ([ds bbsState].state == BBSMainMenu || [ds bbsState].state == BBSMailMenu) {
		// main menu
		if (r < 3 || r == _maxRow - 1)
			return;
		
		enum {
			ST_START, ST_BRACKET_FOUND, ST_SPACE_FOUND, ST_NON_SPACE_FOUND, ST_SINGLE_SPACE_FOUND
		};
		
		int start = -1, end = -1;
		int state = ST_START;
		char shortcut = 0;
		
        // don't check the first two columns ("●" may be used as cursor)
        for (int i = 2; i < _maxColumn - 2; ++i) {
			int db = currRow[i].attr.f.doubleByte;
			switch (state) {
				case ST_START:
					if (currRow[i].byte == ')' && isalnum(currRow[i-1].byte)) {
						start = (currRow[i-2].byte == '(')? i-2: i-1;
						end = start;
						state = ST_BRACKET_FOUND;
						shortcut = currRow[i-1].byte;
					}
					break;
				case ST_BRACKET_FOUND:
					end = i;
					if (db == 1) {
						state = ST_NON_SPACE_FOUND;
					}
					break;
				case ST_NON_SPACE_FOUND:
					if (currRow[i].byte == ' ' || currRow[i].byte == 0) {
						state = ST_SINGLE_SPACE_FOUND;
					} else {
						end = i;
					}
					break;
				case ST_SINGLE_SPACE_FOUND:
					if (currRow[i].byte == ' ' || currRow[i].byte == 0) {
						state = ST_START;
						[self addMainMenuClickEntry:[NSString stringWithFormat:@"%c\n", shortcut] 
												row:r
											 column:start
											 length:end - start + 1];
						start = i;
						end = i;
					} else {
						state = ST_NON_SPACE_FOUND;
						end = i;
					}
					break;
				default:
					break;
			}
		}
	}
}

- (void)update {
	// For the mouse preference
	if (![_view mouseEnabled]) 
		return;
	for (int r = 0; r < _maxRow; ++r) {
		[self updateClickEntryForRow:r];
	}
}

@end
