//
//  LLURLManager.m
//  Welly
//
//  Created by K.O.ed on 09-3-16.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "WLURLManager.h"
#import "WLMouseBehaviorManager.h"
#import "YLView.h"
#import "YLTerminal.h"
#import "YLConnection.h"
#import "WLPreviewController.h"
#import "YLLGlobalConfig.h"

NSString *const WLMenuTitleCopyURL = @"Copy URL";
NSString *const WLMenuTitleOpenWithBrowser = @"Open With Browser";

@implementation WLURLManager
- (id)init {
	[super init];
	_currentURLList = [[NSMutableArray alloc] initWithCapacity:10];
	_currentURLStringBuffer = [[NSMutableString alloc] initWithCapacity:40];
	return self;
}

- (void)dealloc {
	[_currentURLList release];
	[_currentURLStringBuffer release];
    [super dealloc];
}
#pragma mark -
#pragma mark Mouse Event Handler
- (void)mouseUp:(NSEvent *)theEvent {
	NSString *url = [[_manager activeTrackingAreaUserInfo] objectForKey:WLURLUserInfoName];
	if (url != nil) {
		if (([theEvent modifierFlags] & NSShiftKeyMask) == NSShiftKeyMask) {
			// click while holding shift key or navigate web pages
			// open the URL with browser
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
		} else {
			// open with previewer
			[WLPreviewController downloadWithURL:[NSURL URLWithString:url]];
		}
	}
}

- (void)mouseEntered:(NSEvent *)theEvent {
	NSDictionary *userInfo = [[theEvent trackingArea] userInfo];
	if([[_view frontMostConnection] isConnected]) {
		[_manager setActiveTrackingAreaUserInfo:userInfo];
		[[NSCursor pointingHandCursor] set];
	}
}

- (void)mouseExited:(NSEvent *)theEvent {
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
	NSString *urlString = [userInfo objectForKey:WLURLUserInfoName];
    [pb setString:urlString forType:NSStringPboardType];
	[pb setString:urlString forType:NSURLPboardType];
}

- (IBAction)openWithBrower:(id)sender {
	NSDictionary *userInfo = [sender representedObject];
	NSString *urlString = [userInfo objectForKey:WLURLUserInfoName];
	
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
	NSMenu *menu = [[[NSMenu alloc] init] autorelease];
	[menu addItemWithTitle:NSLocalizedString(WLMenuTitleCopyURL, @"Contextual Menu")
					action:@selector(copyURL:)
			 keyEquivalent:@""];
	[menu addItemWithTitle:NSLocalizedString(WLMenuTitleOpenWithBrowser, @"Contextual Menu")
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
	int index = [[urlInfo objectForKey:WLRangeLocationUserInfoName] intValue];
	int length = [[urlInfo objectForKey:WLRangeLengthUserInfoName] intValue];
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
	NSString *url = [urlInfo objectForKey:WLURLUserInfoName];
	if (url != nil) {
		if (([theEvent modifierFlags] & NSShiftKeyMask) == NSShiftKeyMask) {
			// click while holding shift key or navigate web pages
			// open the URL with browser
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
		} else {
			// open with previewer
			[WLPreviewController downloadWithURL:[NSURL URLWithString:url]];
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
	urlString = [urlString stringByReplacingOccurrencesOfString:@"\\" withString:@""];
	urlString = [urlString stringByReplacingOccurrencesOfString:@" " withString:@""];
	NSArray *keys = [NSArray arrayWithObjects:WLMouseHandlerUserInfoName, WLURLUserInfoName, WLRangeLocationUserInfoName, WLRangeLengthUserInfoName, nil];
	NSArray *objects = [NSArray arrayWithObjects:self, [[urlString copy] autorelease], [NSNumber numberWithInt:index], [NSNumber numberWithInt:length], nil];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	[_currentURLList addObject:userInfo];
	
	// Calculate rects to add, notice that we might have multiline url
	while (length > 0) {
		int column = index % _maxColumn;
		int row = index / _maxColumn;
		if (column + length < _maxColumn) {
			NSRect rect = [_view rectAtRow:row column:column height:1 width:length];
			[_trackingAreas addObject:[_manager addTrackingAreaWithRect:rect userInfo:userInfo]];
			[_view drawURLUnderlineAtRow:row fromColumn:column toColumn:column + length];
			break;
		} else {
			NSRect rect = [_view rectAtRow:row column:column height:1 width:_maxColumn - column];
			[_trackingAreas addObject:[_manager addTrackingAreaWithRect:rect userInfo:userInfo]];
			[_view drawURLUnderlineAtRow:row fromColumn:column toColumn:_maxColumn];
			index += _maxColumn - column;
			length -= _maxColumn - column;
		}
	}
}

- (void)clearAllURL {
	for (NSDictionary *urlInfo in _currentURLList) {
		int index = [[urlInfo objectForKey:WLRangeLocationUserInfoName] intValue];
		int length = [[urlInfo objectForKey:WLRangeLengthUserInfoName] intValue];
		
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

- (void)clear {
	[self clearAllURL];
	
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
	// Resotre the url list pointer
	_currentSelectedURLIndex = 0;
	
	YLTerminal *ds = [_view frontMostTerminal];
	cell **grid = [ds grid];
	BOOL isReadingURL = NO;
	const char *protocols[] = {"http://", "https://", "ftp://", "telnet://", "bbs://", "ssh://", "mailto:", "www."};
	const int protocolNum = 8;
    const int realProtocalNum = 7; // only the first 7 protocols are real, the others are fake.
	int startIndex = 0;
	int par = 0;
	int urlLength = 0;
	
	[_currentURLStringBuffer setString:@""];
	
	for (int index = 0; index < _maxRow * _maxColumn; ++index) {
		if (isReadingURL) {
			// Push current char in!
            unsigned char c = grid[index/_maxColumn][index%_maxColumn].byte;
			if (0x21 > c || c > 0x7E || c == '"' || c == '\'') {
				// Not URL anymore, add previous one
				[self addURL:_currentURLStringBuffer AtIndex:startIndex length:urlLength];
				[_currentURLStringBuffer setString:@""];
                isReadingURL = NO;
			} else if (c == '(') {
                ++par;
			} else if (c == ')') {
                if (--par < 0) {
					// Not URL anymore, add previous one
					[self addURL:_currentURLStringBuffer AtIndex:startIndex length:urlLength];
					[_currentURLStringBuffer setString:@""];
                    isReadingURL = NO;
				}
            } else if (c == '\\') {
				if (_maxColumn - index%_maxColumn <= 2) {
					// This '\\' is for connecting two lines
					urlLength += (_maxColumn - index%_maxColumn) - 1;
					index += (_maxColumn - index%_maxColumn) - 1;
				} else {
					// Not URL anymore, add previous one
					[self addURL:_currentURLStringBuffer AtIndex:startIndex length:urlLength];
					[_currentURLStringBuffer setString:@""];
					isReadingURL = NO;
				}
			}
			if (isReadingURL) {
				[_currentURLStringBuffer appendFormat:@"%c", c];
				urlLength++;
			}
		} else {
			// Try to match the url header
			for (int p = 0; p < protocolNum; p++) {
                int len = strlen(protocols[p]);
                BOOL isMatched = YES;
                for (int s = 0; s < len; s++)
                    if (grid[(index+s)/_maxColumn][(index+s)%_maxColumn].byte != protocols[p][s] || grid[(index+s)/_maxColumn][(index+s)%_maxColumn].attr.f.doubleByte) {
                        isMatched = NO;
                        break;
                    }
                
                if (isMatched) {
					// Push current prefix into current url
                    if (p >= realProtocalNum) [_currentURLStringBuffer appendString:@"http://"];
					[_currentURLStringBuffer appendFormat:@"%c", protocols[p][0]];
                    isReadingURL = YES;
					startIndex = index;
					par = 0;
					urlLength = 1;
                    break;
                }
            }
		}
	}
}
@end
