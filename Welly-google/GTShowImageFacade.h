//
//  GTShowImageFacade.h
//  MacBlueTelnet
//
//  Created by lv li on 08-4-3.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GTShowImageFacade : NSObject {
	NSPanel * _window;
	NSString * _fileType;
	NSSize _size;
	NSObject *  _image;
	NSPoint _origin;
	NSString * _title;
}

- (id) initWithInfo: (NSPanel *) window
			   type: (NSString *) filetype
			  image: (NSObject *) image
			  size : (NSSize) size
			origin : (NSPoint) orig
			preTitle: (NSString*) title; 

- (void) setPanel : (NSPanel *) window;
- (void) setFileType : (NSString *) fileType;
- (void) drawImage;
- (void) closeWindow: (id) sender;
@end
