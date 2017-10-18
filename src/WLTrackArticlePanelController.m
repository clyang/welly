//
//  WLTrackArticlePanelController.m
//  Welly
//
//  Created by Cheng-Lin Yang on 2017/10/19.
//  Copyright © 2017年 Welly Group. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WLTrackArticlePanelController.h"
#import "WLGlobalConfig.h"
#import "WLConnection.h"
#import "WLTerminal.h"
#import "SynthesizeSingleton.h"
#import "FMDB.h"

#define kTrackArticleWindowNibFilename @"TrackArticleWindow"

@implementation WLTrackArticlePanelController
@synthesize trackArticleWindow = _trackArticleWindow;

#pragma mark -
#pragma mark init and dealloc
SYNTHESIZE_SINGLETON_FOR_CLASS(WLTrackArticlePanelController);

- (void)loadNibFile {
    if (!_trackArticleWindow) {
        [NSBundle loadNibNamed:kTrackArticleWindowNibFilename owner:self];
    }
}

- (void)awakeFromNib {
}

- (void)openTrackArticleWindow:(NSWindow *) window forTerminal:(WLTerminal *) terminal {
    [self loadNibFile];
    
    [NSApp beginSheet:_trackArticleWindow
       modalForWindow:window
        modalDelegate:nil
       didEndSelector:nil
          contextInfo:nil];
}

- (IBAction)closeTrackArticleWindow:(id)sender {
    [_trackArticleWindow endEditingFor:nil];
    [NSApp endSheet:_trackArticleWindow];
    [_trackArticleWindow orderOut:self];
}

@end
