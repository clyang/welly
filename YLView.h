//
//  YLView.h
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/6/9.
//  Copyright 2006 yllan.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CommonType.h"

@class YLTerminal;
@class YLConnection;
@class YLMarkedTextView;
@class KOEffectView;
@class XIPortal;
@class KOMouseBehaviorManager;

#define disableMouseByKeyingTimerInterval 0.3

@interface YLView : NSTabView <NSTextInput> {	
	CGFloat _fontWidth;
	CGFloat _fontHeight;
	
	NSImage *_backedImage;
	
	NSTimer *_timer;
	int _x;
	int _y;
	
	id _markedText;
	NSRange _selectedRange;
	NSRange _markedRange;
	
	IBOutlet YLMarkedTextView *_textField;
	IBOutlet KOEffectView *_effectView;
    
    int _selectionLocation;
    int _selectionLength;
	BOOL _wantRectangleSelection;
	BOOL _hasRectangleSelected;
    
    XIPortal *_portal;
	
	BOOL _isInPortalMode;
	BOOL _isInUrlMode;
	BOOL _isNotCancelingSelection;
	BOOL _isKeying;
	BOOL _isMouseActive;
	
	NSTimer *_activityCheckingTimer;
	
	KOMouseBehaviorManager *_mouseBehaviorDelegate;
}
@property BOOL isInPortalMode;
@property BOOL isInUrlMode;
@property BOOL isMouseActive;
//@property int x;
//@property int y;

- (void)configure;

- (void)copy:(id)sender;
- (void)pasteWrap:(id)sender;
- (void)paste:(id)sender;
- (void)pasteColor:(id)sender;

- (void)displayCellAtRow:(int)r column:(int)c;
- (void)updateBackedImage;
- (void)drawSelection;
- (void)drawBlink;
- (void)refreshHiddenRegion;
- (void)updateMouseHotspot;

- (void)clearSelection;

- (YLTerminal *)frontMostTerminal;
- (YLConnection *)frontMostConnection;
- (BOOL)connected;

- (void)extendBottomFrom:(int)start 
					  to:(int)end;
- (void)extendTopFrom:(int)start 
				   to:(int)end ;

- (void)drawStringForRow:(int)r 
				 context:(CGContextRef)myCGContext ;
- (void)updateBackgroundForRow:(int)r 
						  from:(int)start 
							to:(int)end;

- (float)fontWidth;
- (void)setFontWidth:(float)value;

- (float)fontHeight;
- (void)setFontHeight:(float)value;

- (NSRect)rectAtRow:(int)r 
			 column:(int)c 
			 height:(int)h 
			  width:(int)w;

- (KOEffectView *)effectView ;

- (void)sendText:(NSString *)text;
- (BOOL)mouseEnabled;

- (NSString *)selectedPlainString ;
- (BOOL)hasBlinkCell ;

- (void)insertText:(id)aString withDelay:(int)microsecond;
/* Url Menu */
- (void)switchURL;
- (void)exitURL;
/* Portal */
- (void)updatePortal;
- (void)removePortal;
- (void)checkPortal;
- (void)resetPortal;
- (void)addPortalPicture:(NSString *)source
				 forSite:(NSString *)siteName;

// safe_paste
- (void)confirmPaste:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)confirmPasteWrap:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)confirmPasteColor:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)performPaste;
- (void)performPasteWrap;
- (void)performPasteColor;
// Mouse operation
- (void)deactivateMouseForKeying;
- (void)activateMouseForKeying:(NSTimer*)timer;

- (int)convertIndexFromPoint:(NSPoint)aPoint;
@end
