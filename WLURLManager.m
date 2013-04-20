//
//  LLURLManager.m
//  Welly
//
//  Created by K.O.ed on 09-3-16.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "WLURLManager.h"
#import "WLMouseBehaviorManager.h"
#import "WLTerminalView.h"
#import "WLTerminal.h"
#import "WLConnection.h"
#import "WLPreviewController.h"
#import "WLGlobalConfig.h"

NSString *const WLMenuTitleCopyURL = @"Copy URL";
NSString *const WLMenuTitleOpenWithBrowser = @"Open With Browser";

@interface WLURLParser : NSObject {
	NSMutableString *_currentURLStringBuffer;
	WLURLManager *_manager;

	cell **_grid;
	BOOL _isReadingURL;
	
	int _maxRow, _maxColumn;
	
	int _index, _startIndex, _urlLength;
}

- (void)parse:(WLTerminal *)terminal;
@end

@implementation WLURLParser
- (id)initWithManager:(WLURLManager *)manager {
	self = [self init];
	if (self) {
		_maxRow = [[WLGlobalConfig sharedInstance] row];
		_maxColumn = [[WLGlobalConfig sharedInstance] column];
		_currentURLStringBuffer = [[NSMutableString alloc] initWithCapacity:40];
		_manager = manager;
	}
	return self;
}

- (void)addURL {
	// Trimming spaces for multi-line url
	NSString *urlString = [_currentURLStringBuffer stringByReplacingOccurrencesOfString:@"\\" withString:@""];
	urlString = [urlString stringByReplacingOccurrencesOfString:@" " withString:@""];
	
	// Trimming special characters at the end of url
	NSCharacterSet *trimmingSet = [NSCharacterSet characterSetWithCharactersInString:@",.:;?!"];
	int lenBeforeTrimming = [urlString length];
	urlString = [urlString stringByTrimmingCharactersInSet:trimmingSet];
	int trimmedLength = lenBeforeTrimming - [urlString length];
	for (int index=_index-1; index>_index-1-trimmedLength; --index) {
		_grid[index/_maxColumn][index%_maxColumn].attr.f.url = NO;
	}

	[_manager addURL:urlString atIndex:_startIndex length:_urlLength-trimmedLength];
	[_currentURLStringBuffer setString:@""];
	_isReadingURL = NO;
}

- (void)parse:(WLTerminal *)terminal {
	_grid = [terminal grid];
	_isReadingURL = NO;
	const char *protocols[] = {"http://", "https://", "ftp://", "telnet://", "bbs://", "ssh://", "mailto:", "www."};
	const int protocolNum = 8;
    const int realProtocalNum = 7; // only the first 7 protocols are real, the others are fake.
	_startIndex = 0;
	_urlLength = 0;
	int par = 0;
	
	[_currentURLStringBuffer setString:@""];
	
	for (_index = 0; _index < _maxRow * _maxColumn; ++_index) {
		if (_isReadingURL) {
			// Push current char in!
            unsigned char c = _grid[_index/_maxColumn][_index%_maxColumn].byte;
			// ']' is a legal url char actually, but it is seldom used
			// Most of time, it is something like [http://someurl] so we just ignore the ']'
			if (0x21 > c || c > 0x7E || c == '"' || c == '\'' || c == ']') {
				// Not URL anymore, add previous one
				[self addURL];
			} else if (c == '(') {
                ++par;
			} else if (c == ')') {
                if (--par < 0) {
					// Not URL anymore, add previous one
					[self addURL];
				}
            } else if (c == '\\') {
				if (_maxColumn - _index%_maxColumn <= 2) {
					// This '\\' is for connecting two lines
					_urlLength += (_maxColumn - _index%_maxColumn) - 1;
					_index += (_maxColumn - _index%_maxColumn) - 1;
				} else {
					// Not URL anymore, add previous one
					[self addURL];
				}
			}
			if (_isReadingURL) {
				[_currentURLStringBuffer appendFormat:@"%c", c];
				_urlLength++;
				
				// Mark as url to draw url underlines
				_grid[_index/_maxColumn][_index%_maxColumn].attr.f.url = YES;
			}
		} else {
			// Try to match the url header
			for (int p = 0; p < protocolNum; p++) {
                int len = strlen(protocols[p]);
                BOOL isMatched = YES;
                for (int s = 0; s < len; s++)
                    if (_grid[(_index+s)/_maxColumn][(_index+s)%_maxColumn].byte != protocols[p][s] || _grid[(_index+s)/_maxColumn][(_index+s)%_maxColumn].attr.f.doubleByte) {
                        isMatched = NO;
                        break;
                    }
                
                if (isMatched) {
					// Push current prefix into current url
                    if (p >= realProtocalNum) [_currentURLStringBuffer appendString:@"http://"];
					[_currentURLStringBuffer appendFormat:@"%c", protocols[p][0]];
                    _isReadingURL = YES;
					_startIndex = _index;
					par = 0;
					_urlLength = 1;
					// Mark as url to draw url underlines
					_grid[_index/_maxColumn][_index%_maxColumn].attr.f.url = YES;
					[terminal setDirtyForRow:_index/_maxColumn];
                    break;
                }
            }
		}
	}
}


@end

@interface WLURLManager () {
	WLURLParser *_parser;
}

@end

@implementation WLURLManager
- (id)init {
	self = [super init];
	if (self) {
		_currentURLList = [[NSMutableArray alloc] initWithCapacity:10];
		_parser = [[WLURLParser alloc] initWithManager:self];
	}
	return self;
}

- (void)dealloc {
	[_currentURLList release];
	//[_currentURLStringBuffer release];
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
	ret.x = col_in_grid * [[WLGlobalConfig sharedInstance] cellWidth];
	ret.y = (_maxRow - row_in_grid - 0.6) * [[WLGlobalConfig sharedInstance] cellHeight];
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
	   atIndex:(int)index 
		length:(int)length {
	// If there's no url before, make the pointer point to the first URL element
	if(_currentSelectedURLIndex < 0)
		_currentSelectedURLIndex = 1;
	
	// Generate User Info
	NSRange range;
	range.location = index;
	range.length = length;
	
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
			break;
		} else {
			NSRect rect = [_view rectAtRow:row column:column height:1 width:_maxColumn - column];
			[_trackingAreas addObject:[_manager addTrackingAreaWithRect:rect userInfo:userInfo]];
			index += _maxColumn - column;
			length -= _maxColumn - column;
		}
	}
}

- (void)clearAllURL {
	// If we are in URL mode, exit it first to avoid crash
	if ([_view isInUrlMode]) {
		[_view exitURL];
	}
	
	for (NSDictionary *urlInfo in _currentURLList) {
		int index = [[urlInfo objectForKey:WLRangeLocationUserInfoName] intValue];
		int length = [[urlInfo objectForKey:WLRangeLengthUserInfoName] intValue];
		
		WLTerminal *ds = [_view frontMostTerminal];
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
	// Restore the url list pointer
	_currentSelectedURLIndex = 0;
	[_parser parse:[_view frontMostTerminal]];
}
@end
