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
#import "YLConnection.h"
#import "XIPreviewController.h"
#import "YLLGlobalConfig.h"

NSString *const KOMenuTitleCopyURL = @"Copy URL";
NSString *const KOMenuTitleOpenWithBrowser = @"Open With Browser";

@implementation LLURLManager
- (void)dealloc {
	[_currentURLList release];
    [super dealloc];
}
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
	if([[_view frontMostConnection] isConnected]) {
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
#pragma mark URL indicator
- (NSPoint)currentSelectedURLPos {
	NSPoint ret;
	ret.x = -1.0;
	ret.y = -1.0;
	// Return if there's no url in current terminal
	if([_currentURLList count] < 1)
		return ret;
	// Get current URL info
	NSDictionary *urlInfo = [_currentURLList objectAtIndex:_currentSelectedURLIndex];
	int index = [[urlInfo objectForKey:KORangeLocationUserInfoName] intValue];
	int length = [[urlInfo objectForKey:KORangeLengthUserInfoName] intValue];
	int column_start = index % _maxColumn;
	int row_start = index / _maxColumn;
	int column_end = (index + length) % _maxColumn;
	int row_end = (index + length) / _maxColumn;
	// Here, the x pos of the indicator should have 3 different conditions
	float col_in_grid;
	// For the urls over two lines, we make the indicator in the center of the "full" lines
	if(length >= (2 * _maxColumn - column_start))
		col_in_grid = (_maxColumn / 2.0f);
	// For the urls over one line, make the indicator in the "main" part of the url
	else if(length >= (_maxColumn - column_start))
		col_in_grid = ((_maxColumn - column_start) >= (length + column_start - _maxColumn)) ? (column_start + _maxColumn) / 2 : (length + column_start - _maxColumn) / 2;
	// Fot the urls no more than one line, it is easy...
	else
		col_in_grid = (column_start + column_end) / 2.0f;
	float row_in_grid = (row_start + row_end) / 2.0f;
	ret.x = col_in_grid * [[YLLGlobalConfig sharedInstance] cellWidth];
	ret.y = (_maxRow - row_in_grid - 0.6) * [[YLLGlobalConfig sharedInstance] cellHeight];
	return ret;
}

- (NSPoint)moveNext {
	_currentSelectedURLIndex = (_currentSelectedURLIndex + 1) % [_currentURLList count];
	return [self currentSelectedURLPos];
}

- (NSPoint)movePrev {
	_currentSelectedURLIndex = (_currentSelectedURLIndex - 1 + [_currentURLList count]) % [_currentURLList count];
	return [self currentSelectedURLPos];
}

- (BOOL)openCurrentURL:(NSEvent *)theEvent {
	NSDictionary *urlInfo = [_currentURLList objectAtIndex:_currentSelectedURLIndex];
	NSString *url = [urlInfo objectForKey:KOURLUserInfoName];
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
	if([_currentURLList count] > 2)
		return NO;
	else
		return YES;
}

#pragma mark -
#pragma mark Update State
- (void)addURL:(NSString *)urlString 
	   AtIndex:(int)index 
		length:(int)length {
	//NSLog(@"[LLURLManager addURL:%@ AtIndex:%d length:%d]", urlString, index, length);
	// If there's no url before, make the pointer point to the first URL element
	if(_currentSelectedURLIndex < 0)
		_currentSelectedURLIndex = 1;
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

- (void)clearAllURL {
	for (NSDictionary *urlInfo in _currentURLList) {
		int index = [[urlInfo objectForKey:KORangeLocationUserInfoName] intValue];
		int length = [[urlInfo objectForKey:KORangeLengthUserInfoName] intValue];
		
		YLTerminal *ds = [_view frontMostTerminal];
		// Set all involved row to be dirty. Reduce the number of [ds setDirty] call.
		while (length > 0) {
			int row = index / _maxColumn;
			[ds setDirtyForRow:row];
			index += _maxColumn;
			length -= _maxColumn;
		}
	}
	[_currentURLList removeAllObjects];
}

- (void)update {
	// REVIEW: this might lead to leak, check it
	if(!_currentURLList)
		_currentURLList = [[NSMutableArray alloc] initWithCapacity:10];
	[self clearAllURL];
	
	// Resotre the url list pointer
	_currentSelectedURLIndex = 0;
	
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
	[currURL release];
}

@end
