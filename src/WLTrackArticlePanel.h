//  MyTableController.h
//  025-NSTableView
//
#import <Cocoa/Cocoa.h>
#import "WLArticle.h"
#import "WLTerminal.h"

@class WLTerminal;
@interface WLTrackArticlePanel : NSObject <NSTableViewDelegate, NSTableViewDataSource>{
    NSMutableArray * nsMutaryDataObj;
    IBOutlet NSTableView *idTableView;
    IBOutlet NSPanel *articleWindow;
    WLTerminal *terminal;
    NSWindow *mainWindow;
   
}
@property (assign) NSMutableArray *nsMutaryDataObj;
@property (assign) WLTerminal *terminal;
@property (assign) NSWindow *mainWindow;
@property (assign) IBOutlet NSTableView *idTableView;

- (IBAction)addAtSelectedRow:(id)pId;
- (IBAction)deleteSelectedRow:(id)pId;

- (void)addRow:(WLArticle *)pDataObj;
   
- (int)numberOfRowsInTableView:(NSTableView *)pTableViewObj;

- (id) tableView:(NSTableView *)pTableViewObj 
                objectValueForTableColumn:(NSTableColumn *)pTableColumn 
                                      row:(int)pRowIndex;

- (void)tableView:(NSTableView *)pTableViewObj 
                           setObjectValue:(id)pObject 
                           forTableColumn:(NSTableColumn *)pTableColumn
                                      row:(int)pRowIndex;

- (void)openTrackArticleWindow:(NSWindow *)window
                  forTerminal:(WLTerminal *)terminal;

+ (WLTrackArticlePanel *)sharedInstance;


@end


