//
//  DBPrefsWindowController.m
//

#import "DBPrefsWindowController.h"
#import "YLLGlobalConfig.h"
#import <ApplicationServices/ApplicationServices.h>

static DBPrefsWindowController *_sharedPrefsWindowController = nil;

@interface DBPrefsWindowController (Private)
- (void) setupMenuOfURLScheme: (NSString *) scheme forPopUpButton: (NSPopUpButton *) button ;
+ (NSArray *) applicationIdentifierArrayForURLScheme: (NSString *) scheme ;
@end

@implementation DBPrefsWindowController

#pragma mark -
#pragma mark Class Methods


+ (DBPrefsWindowController *)sharedPrefsWindowController
{
	if (!_sharedPrefsWindowController) {
		_sharedPrefsWindowController = [[self alloc] initWithWindowNibName:[self nibName]];
	}
	return _sharedPrefsWindowController;
}

+ (NSArray *) applicationIdentifierArrayForURLScheme: (NSString *) scheme {
    CFArrayRef array = LSCopyAllHandlersForURLScheme((CFStringRef)scheme);
    NSMutableArray *result = [NSMutableArray arrayWithArray: (NSArray *) array];
    CFRelease(array);
    return result;
}


+ (NSString *)nibName
	// Subclasses can override this to use a nib with a different name.
{
   return @"Preferences";
}

#pragma mark -
#pragma mark Setup & Teardown

- (void)setupMenuOfURLScheme:(NSString *)scheme 
			  forPopUpButton:(NSPopUpButton *)button {
    NSString *wellyIdentifier = [[[NSBundle mainBundle] bundleIdentifier] lowercaseString];
    NSMutableArray *array = [NSMutableArray arrayWithArray: [DBPrefsWindowController applicationIdentifierArrayForURLScheme: scheme]];
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    NSMutableArray *menuItems = [NSMutableArray array];

    int wellyCount = 0;
    for (NSString *appId in array) 
        if ([[appId lowercaseString] isEqualToString: wellyIdentifier]) 
            wellyCount++;
    if (wellyCount == 0)
        [array addObject: [[NSBundle mainBundle] bundleIdentifier]];
        
    for (NSString *appId in array) {
        CFStringRef appNameInCFString;
        NSString *appPath = [ws absolutePathForAppBundleWithIdentifier: appId];
        if (appPath) {
            NSURL *appURL = [NSURL fileURLWithPath: appPath];
            if (LSCopyDisplayNameForURL((CFURLRef)appURL, &appNameInCFString) == noErr) {                
                NSString *appName = [NSString stringWithString: (NSString *) appNameInCFString];
                CFRelease(appNameInCFString);
                
                if (wellyCount > 1 && [[appId lowercaseString] isEqualToString: wellyIdentifier])
                    appName = [NSString stringWithFormat:@"%@ (%@)", appName, [[[NSBundle bundleWithPath: appPath] infoDictionary] objectForKey: @"CFBundleVersion"]];
                
                NSImage *appIcon = [ws iconForFile:appPath];
                [appIcon setSize: NSMakeSize(16, 16)];
                
                NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle: (NSString *)appName action: NULL keyEquivalent: @""] autorelease];
                [item setRepresentedObject: appId];
                if (appIcon) [item setImage: appIcon];
                [menuItems addObject: item];
            }            
        }
    }
    
    NSMenu *menu = [[[NSMenu alloc] initWithTitle: @"PopUp Menu"] autorelease];
    for (NSMenuItem *item in menuItems) 
        [menu addItem: item];
    [button setMenu: menu];
    
    /* Select the default client */
    CFStringRef defaultHandler = LSCopyDefaultHandlerForURLScheme((CFStringRef) scheme);
    if (defaultHandler) {
        NSInteger index = [button indexOfItemWithRepresentedObject: (NSString *) defaultHandler];
        if (index != NSNotFound) 
            [button selectItemAtIndex: index];
        CFRelease(defaultHandler);
    }
}

- (void) awakeFromNib {
    [self setupMenuOfURLScheme: @"telnet" forPopUpButton: _telnetPopUpButton];
    [self setupMenuOfURLScheme: @"ssh" forPopUpButton: _sshPopUpButton];
}

- (id)initWithWindow:(NSWindow *)window
  // -initWithWindow: is the designated initializer for NSWindowController.
{
	self = [super initWithWindow:nil];
	if (self != nil) {
			// Set up an array and some dictionaries to keep track
			// of the views we'll be displaying.
		toolbarIdentifiers = [[NSMutableArray alloc] init];
		toolbarViews = [[NSMutableDictionary alloc] init];
		toolbarItems = [[NSMutableDictionary alloc] init];

			// Set up an NSViewAnimation to animate the transitions.
		viewAnimation = [[NSViewAnimation alloc] init];
		[viewAnimation setAnimationBlockingMode:NSAnimationNonblocking];
		[viewAnimation setAnimationCurve:NSAnimationEaseInOut];
		[viewAnimation setDelegate:self];
		
		[self setCrossFade:YES]; 
		[self setShiftSlowsAnimation:YES];
	}
	return self;

	(void)window;  // To prevent compiler warnings.
}




- (void)windowDidLoad
{
		// Create a new window to display the preference views.
		// If the developer attached a window to this controller
		// in Interface Builder, it gets replaced with this one.
	NSWindow *window = [[[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,1000,1000)
												    styleMask:(NSTitledWindowMask |
															   NSClosableWindowMask |
															   NSMiniaturizableWindowMask)
													  backing:NSBackingStoreBuffered
													    defer:YES] autorelease];
	[self setWindow:window];
	contentSubview = [[[NSView alloc] initWithFrame:[[[self window] contentView] frame]] autorelease];
	[contentSubview setAutoresizingMask:(NSViewMinYMargin | NSViewWidthSizable)];
	[[[self window] contentView] addSubview:contentSubview];
	[[self window] setShowsToolbarButton:NO];
}




- (void) dealloc {
	[toolbarIdentifiers release];
	[toolbarViews release];
	[toolbarItems release];
	[viewAnimation release];
	[super dealloc];
}


#pragma mark -
#pragma mark Actions


- (IBAction) setChineseFont: (id) sender {
    [[NSFontManager sharedFontManager] setAction: @selector(changeChineseFont:)];
    [[sender window] makeFirstResponder: [sender window]];
    NSFontPanel *fp = [NSFontPanel sharedFontPanel];
    [fp setPanelFont: [NSFont fontWithName: [[YLLGlobalConfig sharedInstance] chineseFontName] size: [[YLLGlobalConfig sharedInstance] chineseFontSize]] isMultiple: NO];
    [fp orderFront: self];
}

- (IBAction) setEnglishFont: (id) sender {
    [[NSFontManager sharedFontManager] setAction: @selector(changeEnglishFont:)];
    [[sender window] makeFirstResponder: [sender window]];
    NSFontPanel *fp = [NSFontPanel sharedFontPanel];
    [fp setPanelFont: [NSFont fontWithName: [[YLLGlobalConfig sharedInstance] englishFontName] size: [[YLLGlobalConfig sharedInstance] englishFontSize]] isMultiple: NO];
    [fp orderFront: self];
}

- (void) changeChineseFont: (id) sender {
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
	NSFont *selectedFont = [fontManager selectedFont];
    
    if (selectedFont == nil) {
		selectedFont = [NSFont systemFontOfSize:[NSFont systemFontSize]];
	}
    
	NSFont *panelFont = [fontManager convertFont:selectedFont];
    [[YLLGlobalConfig sharedInstance] setChineseFontName: [panelFont fontName]];
    [[YLLGlobalConfig sharedInstance] setChineseFontSize: [panelFont pointSize]];
}

- (void) changeEnglishFont: (id) sender {
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
	NSFont *selectedFont = [fontManager selectedFont];
    
    if (selectedFont == nil) {
		selectedFont = [NSFont systemFontOfSize:[NSFont systemFontSize]];
	}
    
	NSFont *panelFont = [fontManager convertFont:selectedFont];
    [[YLLGlobalConfig sharedInstance] setEnglishFontName: [panelFont fontName]];
    [[YLLGlobalConfig sharedInstance] setEnglishFontSize: [panelFont pointSize]];
    
}

- (IBAction) setDefaultTelnetClient: (id) sender {
    NSString *appId = [[sender selectedItem] representedObject];
    if (appId) 
        LSSetDefaultHandlerForURLScheme(CFSTR("telnet"), (CFStringRef)appId);
}

- (IBAction) setDefaultSSHClient: (id) sender {
    NSString *appId = [[sender selectedItem] representedObject];
    if (appId) 
        LSSetDefaultHandlerForURLScheme(CFSTR("ssh"), (CFStringRef)appId);    
}

#pragma mark -
#pragma mark Configuration


- (void)setupToolbar
{
    [self addView: _generalPrefView label: NSLocalizedString(@"General", @"Preferences") image: [NSImage imageNamed: @"NSPreferencesGeneral"]];
    [self addView: _connectionPrefView label: NSLocalizedString(@"Connection", @"Preferences") image: [NSImage imageNamed: @"NSApplicationIcon"]];
    [self addView: _fontsPrefView label: NSLocalizedString(@"Fonts", @"Preferences") image: [NSImage imageNamed: @"NSFontPanel"]];
    [self addView: _colorsPrefView label: NSLocalizedString(@"Colors", @"Preferences") image: [NSImage imageNamed: @"NSColorPanel"]];
}




- (void)addView:(NSView *)view label:(NSString *)label
{
	[self addView:view
			label:label
			image:[NSImage imageNamed:label]];
}


- (void)addView:(NSView *)view label:(NSString *)label image:(NSImage *)image
{
	NSAssert (view != nil,
			  @"Attempted to add a nil view when calling -addView:label:image:.");
	
	NSString *identifier = [[label copy] autorelease];
	
	[toolbarIdentifiers addObject:identifier];
	[toolbarViews setObject:view forKey:identifier];
	
	NSToolbarItem *item = [[[NSToolbarItem alloc] initWithItemIdentifier:identifier] autorelease];
	[item setLabel:label];
	[item setImage:image];
	[item setTarget:self];
	[item setAction:@selector(toggleActivePreferenceView:)];
	
	[toolbarItems setObject:item forKey:identifier];
}


#pragma mark -
#pragma mark Accessor Methods


- (BOOL)crossFade
{
    return _crossFade;
}




- (void)setCrossFade:(BOOL)fade
{
    _crossFade = fade;
}




- (BOOL)shiftSlowsAnimation
{
    return _shiftSlowsAnimation;
}




- (void)setShiftSlowsAnimation:(BOOL)slows
{
    _shiftSlowsAnimation = slows;
}




#pragma mark -
#pragma mark Overriding Methods


- (IBAction)showWindow:(id)sender 
{
		// This forces the resources in the nib to load.
	(void)[self window];

		// Clear the last setup and get a fresh one.
	[toolbarIdentifiers removeAllObjects];
	[toolbarViews removeAllObjects];
	[toolbarItems removeAllObjects];
	[self setupToolbar];

	NSAssert (([toolbarIdentifiers count] > 0),
			  @"No items were added to the toolbar in -setupToolbar.");
	
	if ([[self window] toolbar] == nil) {
		NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"DBPreferencesToolbar"];
		[toolbar setAllowsUserCustomization:NO];
		[toolbar setAutosavesConfiguration:NO];
		[toolbar setSizeMode:NSToolbarSizeModeDefault];
		[toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
		[toolbar setDelegate:self];
		[[self window] setToolbar:toolbar];
		[toolbar release];
	}
	
	NSString *firstIdentifier = [toolbarIdentifiers objectAtIndex:0];
	[[[self window] toolbar] setSelectedItemIdentifier:firstIdentifier];
	[self displayViewForIdentifier:firstIdentifier animate:NO];
	
	[[self window] center];

	[super showWindow:sender];
}




#pragma mark -
#pragma mark Toolbar


- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
	return toolbarIdentifiers;

	(void)toolbar;
}




- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar 
{
	return toolbarIdentifiers;

	(void)toolbar;
}




- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
	return toolbarIdentifiers;
	(void)toolbar;
}




- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)identifier willBeInsertedIntoToolbar:(BOOL)willBeInserted 
{
	return [toolbarItems objectForKey:identifier];
	(void)toolbar;
	(void)willBeInserted;
}




- (void)toggleActivePreferenceView:(NSToolbarItem *)toolbarItem
{
	[self displayViewForIdentifier:[toolbarItem itemIdentifier] animate:YES];
}




- (void)displayViewForIdentifier:(NSString *)identifier animate:(BOOL)animate
{	
		// Find the view we want to display.
	NSView *newView = [toolbarViews objectForKey:identifier];

		// See if there are any visible views.
	NSView *oldView = nil;
	if ([[contentSubview subviews] count] > 0) {
			// Get a list of all of the views in the window. Usually at this
			// point there is just one visible view. But if the last fade
			// hasn't finished, we need to get rid of it now before we move on.
		NSEnumerator *subviewsEnum = [[contentSubview subviews] reverseObjectEnumerator];
		
			// The first one (last one added) is our visible view.
		oldView = [subviewsEnum nextObject];
		
			// Remove any others.
		NSView *reallyOldView = nil;
		while ((reallyOldView = [subviewsEnum nextObject]) != nil) {
			[reallyOldView removeFromSuperviewWithoutNeedingDisplay];
		}
	}
	
	if (![newView isEqualTo:oldView]) {		
		NSRect frame = [newView bounds];
		frame.origin.y = NSHeight([contentSubview frame]) - NSHeight([newView bounds]);
		[newView setFrame:frame];
		[contentSubview addSubview:newView];
		[[self window] setInitialFirstResponder:newView];

		if (animate && [self crossFade])
			[self crossFadeView:oldView withView:newView];
		else {
			[oldView removeFromSuperviewWithoutNeedingDisplay];
			[newView setHidden:NO];
			[[self window] setFrame:[self frameForView:newView] display:YES animate:animate];
		}
		
		[[self window] setTitle:[[toolbarItems objectForKey:identifier] label]];
	}
}




#pragma mark -
#pragma mark Cross-Fading Methods


- (void)crossFadeView:(NSView *)oldView withView:(NSView *)newView
{
	[viewAnimation stopAnimation];
	
    if ([self shiftSlowsAnimation] && [[[self window] currentEvent] modifierFlags] & NSShiftKeyMask)
		[viewAnimation setDuration:1.25];
    else
		[viewAnimation setDuration:0.25];
	
	NSDictionary *fadeOutDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
		oldView, NSViewAnimationTargetKey,
		NSViewAnimationFadeOutEffect, NSViewAnimationEffectKey,
		nil];

	NSDictionary *fadeInDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
		newView, NSViewAnimationTargetKey,
		NSViewAnimationFadeInEffect, NSViewAnimationEffectKey,
		nil];

	NSDictionary *resizeDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
		[self window], NSViewAnimationTargetKey,
		[NSValue valueWithRect:[[self window] frame]], NSViewAnimationStartFrameKey,
		[NSValue valueWithRect:[self frameForView:newView]], NSViewAnimationEndFrameKey,
		nil];
	
	NSArray *animationArray = [NSArray arrayWithObjects:
		fadeOutDictionary,
		fadeInDictionary,
		resizeDictionary,
		nil];
	
	[viewAnimation setViewAnimations:animationArray];
	[viewAnimation startAnimation];
}




- (void)animationDidEnd:(NSAnimation *)animation
{
	NSView *subview;
	
		// Get a list of all of the views in the window. Hopefully
		// at this point there are two. One is visible and one is hidden.
	NSEnumerator *subviewsEnum = [[contentSubview subviews] reverseObjectEnumerator];
	
		// This is our visible view. Just get past it.
	subview = [subviewsEnum nextObject];

		// Remove everything else. There should be just one, but
		// if the user does a lot of fast clicking, we might have
		// more than one to remove.
	while ((subview = [subviewsEnum nextObject]) != nil) {
		[subview removeFromSuperviewWithoutNeedingDisplay];
	}

		// This is a work-around that prevents the first
		// toolbar icon from becoming highlighted.
	[[self window] makeFirstResponder:nil];

	(void)animation;
}




- (NSRect)frameForView:(NSView *)view
	// Calculate the window size for the new view.
{
	NSRect windowFrame = [[self window] frame];
	NSRect contentRect = [[self window] contentRectForFrameRect:windowFrame];
	float windowTitleAndToolbarHeight = NSHeight(windowFrame) - NSHeight(contentRect);

	windowFrame.size.height = NSHeight([view frame]) + windowTitleAndToolbarHeight;
	windowFrame.size.width = NSWidth([view frame]);
	windowFrame.origin.y = NSMaxY([[self window] frame]) - NSHeight(windowFrame);
	
	return windowFrame;
}




@end
