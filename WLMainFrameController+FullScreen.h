//
//  WLMainFrameController+FullScreen.h
//  Welly
//
//  Created by KOed on 13-3-26.
//  Copyright (c) 2013年 Welly Group. All rights reserved.
//

#import "WLMainFrameController.h"


@interface WLMainFrameController (FullScreen)
- (BOOL)isInFullScreenMode;
+ (NSDictionary *)sizeParametersForZoomRatio:(CGFloat)zoomRatio;
@end
