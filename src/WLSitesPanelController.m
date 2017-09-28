//
//  WLSiteDelegate.m
//  Welly
//
//  Created by K.O.ed on 09-9-29.
//  Copyright 2009 Welly Group. All rights reserved.
//

#import "WLSitesPanelController.h"
#import "WLSite.h"
#import "WLMainFrameController.h"
#import "WLGlobalConfig.h"
#import "SynthesizeSingleton.h"

#define SiteTableViewDataType @"SiteTableViewDataType"
#define kSitePanelNibFilename @"SitesPanel"

@interface WLSitesPanelController()
- (void)loadSites;
- (void)sitesDidChanged;

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

@implementation WLSitesPanelController
@synthesize sites = _sites;

SYNTHESIZE_SINGLETON_FOR_CLASS(WLSitesPanelController);

#pragma mark -
#pragma mark Initialize and Destruction
- (id)init {
    if (self = [super init]) {
		@synchronized(self) {
			// init may be called multiple times, 
			// but there is only one shared instance.
			// So we need to make sure these arrays have been alloc only once
			if (!_sites) {
				_sites = [[NSMutableArray alloc] init];
				[self loadSites];
			}
			if (!_sitesObservers)
				_sitesObservers = [[NSMutableArray alloc] init];		}
    }
    return self;
}

- (void)loadNibFile {
	if (!_sitesPanel) {
		[NSBundle loadNibNamed:kSitePanelNibFilename owner:self];
	}
}

- (void)awakeFromNib {
	// register drag & drop in site view
	[_tableView registerForDraggedTypes:[NSArray arrayWithObject:SiteTableViewDataType]];
}

- (void)dealloc {
    [_sites release];
	[_sitesObservers release];
    [super dealloc];
}

#pragma mark -
#pragma mark Save/Load Sites Array
- (void)loadSites {
    NSArray *array = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Sites"];
    for (NSDictionary *d in array)
        [self insertObject:[WLSite siteWithDictionary:d] inSitesAtIndex:[self countOfSites]];

	[self sitesDidChanged];
}

- (void)saveSites {
    NSMutableArray *a = [NSMutableArray array];
    for (WLSite *s in _sites)
        [a addObject:[s dictionaryOfSite]];
    [[NSUserDefaults standardUserDefaults] setObject:a forKey:@"Sites"];
    [[NSUserDefaults standardUserDefaults] synchronize];
	
    [self sitesDidChanged];
}

/*
 * Inform all sitesObservers that _sites have been changed
 */
- (void)sitesDidChanged {
	for (NSObject *obj in _sitesObservers) {
		if ([obj conformsToProtocol:@protocol(WLSitesObserver)]) {
			NSObject <WLSitesObserver> *observer = (NSObject <WLSitesObserver> *) obj;
			[observer sitesDidChanged:_sites];
		}
	}
}

- (void)addSitesObserver:(NSObject<WLSitesObserver> *)observer {
	[_sitesObservers addObject:observer];
	[observer sitesDidChanged:_sites];
}

+ (void)addSitesObserver:(NSObject<WLSitesObserver> *)observer {
	[[self sharedInstance] addSitesObserver:observer];
}

#pragma mark -
#pragma mark Site Panel Actions
- (void)openSitesPanelInWindow:(NSWindow *)mainWindow {
	// Load Nib file if necessary
	[self loadNibFile];
    [NSApp beginSheet:_sitesPanel
       modalForWindow:mainWindow
        modalDelegate:nil
       didEndSelector:NULL
          contextInfo:nil];
	[_sitesPanel setLevel:floatWindowLevel];	
}

- (void)openSitesPanelInWindow:(NSWindow *)mainWindow 
				    andAddSite:(WLSite *)site {
	site = [[site copy] autorelease];
    //[self performSelector:@selector(openSitesPanelInWindow:) withObject:mainWindow afterDelay:0.1];
	[self openSitesPanelInWindow:mainWindow];
	[_sitesController addObject:site];
    [_sitesController setSelectedObjects:[NSArray arrayWithObject:site]];
    if ([_siteNameField acceptsFirstResponder])
        [_sitesPanel makeFirstResponder:_siteNameField];
}

- (IBAction)connectSelectedSite:(id)sender {
    NSArray *a = [_sitesController selectedObjects];
    [self closeSitesPanel:sender];
    
    if ([a count] == 1) {
        WLSite *s = [a objectAtIndex:0];
        [[WLMainFrameController sharedInstance] newConnectionWithSite:[[s copy] autorelease]];
    }
}

- (IBAction)closeSitesPanel:(id)sender {
    [_sitesPanel endEditingFor:nil];
    [NSApp endSheet:_sitesPanel];
    [_sitesPanel orderOut:self];
    [self saveSites];
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
	[_sitesPanel setLevel:0];
    if (![siteAddress hasPrefix:@"ssh"] && [siteAddress rangeOfString:@"@"].location == NSNotFound) {
        NSBeginAlertSheet(NSLocalizedString(@"Site address format error", @"Sheet Title"),
                          nil,
                          nil,
                          nil,
                          _sitesPanel,
                          self,
                          nil,
                          nil,
                          nil,
                          NSLocalizedString(@"Your BBS ID (username) should be provided explicitly by \"id@\" in the site address field in order to use auto-login for telnet connections.", @"Sheet Message"));
        return;
    }
    [NSApp beginSheet:_passwordPanel
       modalForWindow:_sitesPanel
        modalDelegate:nil
       didEndSelector:nil
          contextInfo:nil];
}

- (IBAction)confirmPassword:(id)sender {
    [_passwordPanel endEditingFor:nil];
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
    [NSApp endSheet:_passwordPanel];
    [_passwordPanel orderOut:self];
}

- (IBAction)cancelPassword:(id)sender {
    [_passwordPanel endEditingFor:nil];
    [_passwordField setStringValue:@""];
    [NSApp endSheet:_passwordPanel];
    [_passwordPanel orderOut:self];
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
	return [[self sharedInstance] sites];
}

+ (WLSite *)siteAtIndex:(NSUInteger)index {
	return [[self sharedInstance] objectInSitesAtIndex:index];
}

- (unsigned)countOfSites {
    return [_sites count];
}

- (id)objectInSitesAtIndex:(NSUInteger)index {
	if (index >= [_sites count])
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
