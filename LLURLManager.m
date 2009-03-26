//
//  LLURLManager.m
//  Welly
//
//  Created by K.O.ed on 09-3-16.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "LLURLManager.h"
#import "KOMouseBehaviorManager.h"
#import "YLView.h"
#import "YLTerminal.h"
#import "XIPreviewController.h"

NSString *const KOMenuTitleCopyURL = @"Copy URL";
NSString *const KOMenuTitleOpenWithBrowser = @"Open With Browser";

@implementation LLURLManager
#pragma mark -
#pragma mark Mouse Event Handler
- (void)mouseUp:(NSEvent *)theEvent {
	NSString *url = [[_manager activeTrackingAreaUserInfo] objectForKey:KOURLUserInfoName];
	if (url != nil) {
		if (([theEvent modifierFlags] & NSShiftKeyMask) == NSShiftKeyMask) {
			// click while holding shift key or navigate web pages
			// open the URL with browser
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
		} else {
			// open with previewer
			[XIPreviewController dowloadWithURL:[NSURL URLWithString:url]];
		}
	}
}

- (void)mouseEntered:(NSEvent *)theEvent {
	//NSLog(@"mouseEntered: ");
	NSDictionary *userInfo = [[theEvent trackingArea] userInfo];
	if([[_view frontMostConnection] connected]) {
		[_manager setActiveTrackingAreaUserInfo:userInfo];
	}
}

- (void)mouseExited:(NSEvent *)theEvent {
	//NSLog(@"mouseExited: ");
	[_manager setActiveTrackingAreaUserInfo:nil];
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
- (IBAction)copyURL:(id)sender {
	NSPasteboard *pb = [NSPasteboard generalPasteboard];
    NSMutableArray *types = [NSMutableArray arrayWithObjects: NSStringPboardType, NSURLPboardType, nil];
    [pb declareTypes:types owner:self];
	
	NSDictionary *userInfo = [sender representedObject];
	NSString *urlString = [userInfo objectForKey:KOURLUserInfoName];
    [pb setString:urlString forType:NSStringPboardType];
	[pb setString:urlString forType:NSURLPboardType];
}

- (IBAction)openWithBrower:(id)sender {
	NSDictionary *userInfo = [sender representedObject];
	NSString *urlString = [userInfo objectForKey:KOURLUserInfoName];
	
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
	NSMenu *menu = [[[NSMenu alloc] init] autorelease];
	[menu addItemWithTitle:NSLocalizedString(KOMenuTitleCopyURL, @"Contextual Menu")
					action:@selector(copyURL:)
			 keyEquivalent:@""];
	[menu addItemWithTitle:NSLocalizedString(KOMenuTitleOpenWithBrowser, @"Contextual Menu")
					action:@selector(openWithBrower:)
			 keyEquivalent:@""];
	
	for (NSMenuItem *item in [menu itemArray]) {
		if ([item isSeparatorItem])
			continue;
		[item setTarget:self];
		[item setRepresentedObject:_manager.activeTrackingAreaUserInfo];
	}
	return menu;
}

#pragma mark -
#pragma mark Update State
- (void)addURL:(NSString *)urlString 
	   AtIndex:(int)index 
		length:(int)length {
	//NSLog(@"[LLURLManager addURL:%@ AtIndex:%d length:%d]", urlString, index, length);
	
	// Generate User Info
	NSRange range;
	range.location = index;
	range.length = length;
	NSArray *keys = [NSArray arrayWithObjects:KOMouseHandlerUserInfoName, KOURLUserInfoName, KORangeLocationUserInfoName, KORangeLengthUserInfoName, nil];
	NSArray *objects = [NSArray arrayWithObjects:self, [[urlString copy] autorelease], [NSNumber numberWithInt:index], [NSNumber numberWithInt:length], nil];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	[_currentURLList addObject:userInfo];
	
	// Calculate rects to add, notice that we might have multiline url
	//NSRect rect = [_view rectAtRow:r column:c height:1 width:len];
	while (length > 0) {
		int column = index % _maxColumn;
		int row = index / _maxColumn;
		if (column + length < _maxColumn) {
			//NSLog(@"add rect at row:%d, column:%d, length:%d", row, column, length);
			NSRect rect = [_view rectAtRow:row column:column height:1 width:length];
			[_manager addTrackingAreaWithRect:rect userInfo:userInfo cursor:[NSCursor pointingHandCursor]];
			[_view drawURLUnderlineAtRow:row fromColumn:column toColumn:column + length];
			break;
		} else {
			//NSLog(@"add rect at row:%d, column:%d, length:%d", row, column, _maxColumn - column);
			NSRect rect = [_view rectAtRow:row column:column height:1 width:_maxColumn - column];
			[_manager addTrackingAreaWithRect:rect userInfo:userInfo cursor:[NSCursor pointingHandCursor]];
			[_view drawURLUnderlineAtRow:row fromColumn:column toColumn:_maxColumn];
			index += _maxColumn - column;
			length -= _maxColumn - column;
		}
	}
}

- (void)update {
	// REVIEW: this might lead to leak, check it
	[_currentURLList removeAllObjects];
	
	YLTerminal *ds = [_view frontMostTerminal];
	//cell **grid = [ds grid];
	BOOL isReadingURL = NO;
	char *protocols[] = {"http://", "https://", "ftp://", "telnet://", "bbs://", "ssh://", "mailto:"};
	int protocolNum = 7;
	NSMutableString *currURL = [[NSMutableString alloc] initWithCapacity:40];
	int startIndex = 0;
	int par = 0;
	int urlLength = 0;
	
	for (int index = 0; index < _maxRow * _maxColumn; ++index) {
		if (isReadingURL) {
			// Push current char in!
            unsigned char c = [ds cellAtIndex:index].byte;
            if (0x21 > c || c > 0x7E || c == '"' || c == '\'') {
				//NSLog(@"URL: %@", currURL);
				// Here we store the row and column number in the NSPoint
				// to convert it to an actual pos, see
				// NSMakeRect(x * _fontWidth, (gRow - y - 1) * _fontHeight, _fontWidth * length, _fontHeight);
				/*
				NSPoint cp;
				cp.x = index;
				cp.y = row;
				LLUrlData * currUrlData = [[LLUrlData alloc] initWithUrl:currURL 
																	name:currURL 
																position:cp];
				 [_currentURLList addObject:currUrlData];
				 */
				// Not URL anymore, add previous one
				[self addURL:currURL AtIndex:startIndex length:urlLength];
				[currURL setString:@""];
                isReadingURL = NO;
			}
            else if (c == '(')
                ++par;
            else if (c == ')') {
                if (--par < 0) {
					//NSLog(@"URL: %@", currURL);
					/*
					NSPoint cp;
					cp.x = i;
					cp.y = r;
					LLUrlData * currUrlData = [[LLUrlData alloc] initWithUrl:_currURL 
																		name:_currURL 
																	position:cp];
					[_currentURLList addObject:currUrlData];
					 */
					// Not URL anymore, add previous one
					[self addURL:currURL AtIndex:startIndex length:urlLength];
					[currURL setString:@""];
                    isReadingURL = NO;
				}
            }
			if (isReadingURL) {
				[currURL appendFormat:@"%c", c];
				urlLength++;
			}
		} else {
			// Try to match the url header
			for (int p = 0; p < protocolNum; p++) {
                int len = strlen(protocols[p]);
                BOOL isMatched = YES;
                for (int s = 0; s < len; s++)
                    if ([ds cellAtIndex:index + s].byte != protocols[p][s] || [ds cellAtIndex:index + s].attr.f.doubleByte) {
                        isMatched = NO;
                        break;
                    }
                
                if (isMatched) {
					// Push current prefix into current url
					[currURL appendFormat:@"%c", protocols[p][0]];
                    isReadingURL = YES;
					startIndex = index;
					par = 0;
					urlLength = 1;
                    break;
                }
            }
		}
		/*		
		int row = index / _maxColumn;
		int column = index % _maxColumn;

		if (grid[row][column].attr.f.url != isReadingURL) {
            grid[row][column].attr.f.url = isReadingURL;
            [ds setDirty:YES atRow:row column:column];
            // TODO: Do not regenerate the region. Draw the url line instead.
        }
		 */
	}
}

@end
