//
//  WLSiteDelegate.m
//  Welly
//
//  Created by K.O.ed on 09-9-29.
//  Copyright 2009 Welly Group. All rights reserved.
//

#import "WLSiteDelegate.h"
#import "WLSite.h"
#import "YLView.h"
#import "YLController.h"
#import "WLGlobalConfig.h"

#define SiteTableViewDataType @"SiteTableViewDataType"

@interface WLSiteDelegate()
- (void)loadSites;

/* sites accessors */
- (id)objectInSitesAtIndex:(NSUInteger)index;
- (void)getSites:(id *)objects 
		   range:(NSRange)range;
- (void)insertObject:(id)anObject 
	  inSitesAtIndex:(NSUInteger)index;
- (void)removeObjectFromSitesAtIndex:(NSUInteger)index;
- (void)replaceObjectInSitesAtIndex:(NSUInteger)index 
						 withObject:(id)anObject;
@end


@implementation WLSiteDelegate
@synthesize sites = _sites;

#pragma mark -
#pragma mark Initialize and Destruction
static WLSiteDelegate *sInstance;

+ (WLSiteDelegate *)sharedInstance {
    assert(sInstance);
    return sInstance;
}

- (id)init {
    if (self = [super init]) {
        _sites = [[NSMutableArray alloc] init];
        assert(sInstance == nil);
        sInstance = self;
    }
    return self;
}

- (void)updateSitesMenu {
    int total = [[_sitesMenu submenu] numberOfItems];
    int i = total - 1;
    // search the last seperator from the bottom
    for (; i > 0; i--)
        if ([[[_sitesMenu submenu] itemAtIndex:i] isSeparatorItem])
            break;
	
    // then remove all menuitems below it, since we need to refresh the site menus
    ++i;
    for (int j = i; j < total; j++) {
        [[_sitesMenu submenu] removeItemAtIndex:i];
    }
    
    // Now add items of site one by one
    for (WLSite *s in _sites) {
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[s name] ?: @"" action:@selector(openSiteMenu:) keyEquivalent:@""];
        [menuItem setRepresentedObject:s];
        [[_sitesMenu submenu] addItem:menuItem];
        [menuItem release];
    }
    
    // Reset portal if necessary
	if([[NSUserDefaults standardUserDefaults] boolForKey:WLCoverFlowModeEnabledKeyName]) {
		[_telnetView resetPortal];
	}
}

- (void)awakeFromNib {
	[self updateSitesMenu];
	
	// register drag & drop in site view
    [_tableView registerForDraggedTypes:[NSArray arrayWithObject:SiteTableViewDataType]];

    [self loadSites];
}

- (void)dealloc {
    [_sites release];
    [super dealloc];
}

#pragma mark -
#pragma mark Save/Load Sites Array
- (void)loadSites {
    NSArray *array = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Sites"];
    for (NSDictionary *d in array)
        [self insertObject:[WLSite siteWithDictionary:d] inSitesAtIndex:[self countOfSites]];    
}

- (void)saveSites {
    NSMutableArray *a = [NSMutableArray array];
    for (WLSite *s in _sites)
        [a addObject:[s dictionaryOfSite]];
    [[NSUserDefaults standardUserDefaults] setObject:a forKey:@"Sites"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self updateSitesMenu];
}

#pragma mark -
#pragma mark Site Panel Actions
- (IBAction)openSitePanel:(id)sender {
    [NSApp beginSheet:_sitesWindow
       modalForWindow:_mainWindow
        modalDelegate:nil
       didEndSelector:NULL
          contextInfo:nil];
	[_sitesWindow setLevel:floatWindowLevel];
}

- (IBAction)connectSite:(id)sender {
    NSArray *a = [_sitesController selectedObjects];
    [self closeSitePanel:sender];
    
    if ([a count] == 1) {
        WLSite *s = [a objectAtIndex:0];
        [[YLController sharedInstance] newConnectionWithSite:[[s copy] autorelease]];
    }
}

- (IBAction)closeSitePanel:(id)sender {
    [_sitesWindow endEditingFor:nil];
    [NSApp endSheet:_sitesWindow];
    [_sitesWindow orderOut:self];
    [self saveSites];
}

- (IBAction)addCurrentSite:(id)sender {
    if ([_telnetView numberOfTabViewItems] == 0) return;
    NSString *address = [[[_telnetView frontMostConnection] site] address];
    
    for (WLSite *s in _sites) 
        if ([[s address] isEqualToString:address]) 
            return;
    
    WLSite *site = [[[[_telnetView frontMostConnection] site] copy] autorelease];
    [_sitesController addObject:site];
    [_sitesController setSelectedObjects:[NSArray arrayWithObject:site]];
    [self performSelector:@selector(openSitePanel:) withObject:sender afterDelay:0.1];
    if ([_siteNameField acceptsFirstResponder])
        [_sitesWindow makeFirstResponder:_siteNameField];
}

- (IBAction)proxyTypeDidChange:(id)sender {
    [_proxyAddressField setEnabled:([_proxyTypeButton indexOfSelectedItem] >= 2)];
}

#pragma mark -
#pragma mark Password Window Actions
- (IBAction)openPasswordDialog:(id)sender {
    NSString *siteAddress = [_siteAddressField stringValue];
    if ([siteAddress length] == 0)
        return;
	[_sitesWindow setLevel:0];
    if (![siteAddress hasPrefix:@"ssh"] && [siteAddress rangeOfString:@"@"].location == NSNotFound) {
        NSBeginAlertSheet(NSLocalizedString(@"Site address format error", @"Sheet Title"),
                          nil,
                          nil,
                          nil,
                          _sitesWindow,
                          self,
                          nil,
                          nil,
                          nil,
                          NSLocalizedString(@"Your BBS ID (username) should be provided explicitly by \"id@\" in the site address field in order to use auto-login for telnet connections.", @"Sheet Message"));
        return;
    }
    [NSApp beginSheet:_passwordWindow
       modalForWindow:_sitesWindow
        modalDelegate:nil
       didEndSelector:nil
          contextInfo:nil];
}

- (IBAction)confirmPassword:(id)sender {
    [_passwordWindow endEditingFor:nil];
    const char *service = "Welly";
    const char *account = [[_siteAddressField stringValue] UTF8String];
    SecKeychainItemRef itemRef;
    if (!SecKeychainFindGenericPassword(nil,
                                        strlen(service), service,
                                        strlen(account), account,
                                        nil, nil,
                                        &itemRef))
        SecKeychainItemDelete(itemRef);
    const char *pass = [[_passwordField stringValue] UTF8String];
    if (*pass) {
        SecKeychainAddGenericPassword(nil,
                                      strlen(service), service,
                                      strlen(account), account,
                                      strlen(pass), pass,
                                      nil);
    }
    [_passwordField setStringValue:@""];
    [NSApp endSheet:_passwordWindow];
    [_passwordWindow orderOut:self];
}

- (IBAction)cancelPassword:(id)sender {
    [_passwordWindow endEditingFor:nil];
    [_passwordField setStringValue:@""];
    [NSApp endSheet:_passwordWindow];
    [_passwordWindow orderOut:self];
}

#pragma mark -
#pragma mark Site View Drag & Drop
- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard {
    // copy to the pasteboard.
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard declareTypes:[NSArray arrayWithObject:SiteTableViewDataType] owner:self];
    [pboard setData:data forType:SiteTableViewDataType];
    return YES;
}

- (NSDragOperation)tableView:(NSTableView*)tv 
				validateDrop:(id <NSDraggingInfo>)info
				 proposedRow:(NSInteger)row 
	   proposedDropOperation:(NSTableViewDropOperation)op {
    // don't hover
    if (op == NSTableViewDropOn)
        return NSDragOperationNone;
    return NSDragOperationEvery;
}

- (BOOL)tableView:(NSTableView *)aTableView 
	   acceptDrop:(id <NSDraggingInfo>)info
			  row:(NSInteger)row 
	dropOperation:(NSTableViewDropOperation)op {
    NSPasteboard* pboard = [info draggingPasteboard];
    NSData* rowData = [pboard dataForType:SiteTableViewDataType];
    NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
    int dragRow = [rowIndexes firstIndex];
    // move
    NSObject *obj = [_sites objectAtIndex:dragRow];
    [_sitesController insertObject:obj atArrangedObjectIndex:row];
    if (row < dragRow)
        ++dragRow;
    [_sitesController removeObjectAtArrangedObjectIndex:dragRow];
    // done
    return YES;
}

#pragma mark -
#pragma mark Sites Accessors
+ (NSArray *)sites {
	assert(sInstance);
	return [sInstance sites];
}

+ (WLSite *)siteAtIndex:(NSUInteger)index {
	assert(sInstance);
	return [sInstance objectInSitesAtIndex:index];
}

- (unsigned)countOfSites {
    return [_sites count];
}

- (id)objectInSitesAtIndex:(NSUInteger)index {
	if (index < 0 || index >= [_sites count])
		return NULL;
    return [_sites objectAtIndex:index];
}

- (void)getSites:(id *)objects 
		   range:(NSRange)range {
    [_sites getObjects:objects range:range];
}

- (void)insertObject:(id)anObject 
	  inSitesAtIndex:(NSUInteger)index {
    [_sites insertObject:anObject atIndex:index];
}

- (void)removeObjectFromSitesAtIndex:(NSUInteger)index {
    [_sites removeObjectAtIndex:index];
}

- (void)replaceObjectInSitesAtIndex:(NSUInteger)index 
						 withObject:(id)anObject {
    [_sites replaceObjectAtIndex:index withObject:anObject];
}
@end
