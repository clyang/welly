//
//  WLTrackArticlePanelController.h
//  Welly
//
//  Created by Cheng-Lin Yang on 2017/10/19.
//  Copyright © 2017年 Welly Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

@class WLTerminal;

@interface WLTrackArticlePanelController : NSObject{
    IBOutlet NSPanel *_trackArticleWindow;
    IBOutlet NSButton *_removeButton;
    IBOutlet NSButton *_closeButton;
    IBOutlet NSTableView *_tableView;
}
@property (assign) NSPanel *trackArticleWindow;


+ (WLTrackArticlePanelController *)sharedInstance;

/* post download actions */
- (void)openTrackArticleWindow:(NSWindow *)window
                  forTerminal:(WLTerminal *)terminal;

- (void)addTrackArticle:(NSWindow *)window
                   forTerminal:(WLTerminal *)terminal;

- (IBAction)closeTrackArticleWindow:(id)sender;
@end

