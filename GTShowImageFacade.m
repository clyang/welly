//
//  GTShowImageFacade.m
//  MacBlueTelnet
//
//  Created by lv li on 08-4-3.


#import "GTShowImageFacade.h"
#import <PDFKit/PDFView.h>


@implementation GTShowImageFacade

- (id) initWithInfo: (NSPanel *) window
			   type: (NSString *) filetype
			  image: (NSObject *) image
			  size : (NSSize) size
			  origin : (NSPoint) orig
			  preTitle: (NSString*) title
{
    if ([super init])
    {
        _window = window;
		_fileType = filetype; 
		_image = image;
		_size = size; 
		_origin = orig;  
		_title = title;
    }
    return self;
}


- (void) dealloc
{
	[_window release];
	[_image release];
	[_fileType release];
	[super dealloc];
}

- (void) setPanel : (NSPanel *) window
{
	_window = window;
	[window release];
}

- (void) setFileType : (NSString *) fileType
{
	_fileType = fileType;
}

- (void) drawImage
{
	if(_window == nil)
		return;
	NSRect viewRect = NSMakeRect(0, 0, _size.width, _size.height);
	
	NSSize frameSize = [_window frame].size;
	NSSize viewSize = [[_window contentView] frame].size;
	// If is a pdf file, change the window style
	if([_fileType isEqual : @"pdf"])
	{
		[_window setIsVisible: NO];
		unsigned int style = NSTitledWindowMask | 
        NSMiniaturizableWindowMask | NSClosableWindowMask;

		_window = [[NSPanel alloc] initWithContentRect: NSMakeRect(0, 0, 400, 30)
											 styleMask: style
											   backing: NSBackingStoreBuffered 
												 defer: NO];
		[_window setIsVisible: YES];
	   // [_window setFloatingPanel: NO];
		[_window setDelegate: self];
		[_window setOpaque: YES];
		[_window center];
		[_window setViewsNeedDisplay: NO];
		[_window makeKeyAndOrderFront: nil];
		PDFView *view = [[PDFView alloc] initWithFrame:viewRect];
		[view setAutoScales:YES];
		NSScrollView * scrollView = [[NSScrollView alloc] initWithFrame: NSMakeRect(0, 0, _size.width, _size.height)];
		[scrollView setDocumentView:view];
		//[[scrollView contentView] addSubview:view];
		[[_window contentView] addSubview: scrollView];
		[_window setTitle:_title];
		[view setDocument: _image];
		[_image release];
		[view release];
		[scrollView release];
	}
	else
	{
		NSButton * showedImg = [[NSButton alloc] initWithFrame:viewRect];
		[showedImg setButtonType: NSSwitchButton];
		[showedImg setKeyEquivalent: @" "];
		[showedImg setImage: _image];
		[showedImg setTitle: @""];
		[_image release];
		[[_window contentView] addSubview: showedImg];
		[showedImg sendActionOn:NSLeftMouseDownMask];
		[showedImg setTarget:self];
		[showedImg setAction: @selector(closeWindow:)];
		[showedImg release];
	}
	// End here

	[_window setFrame: NSMakeRect(_origin.x, _origin.y,
                                  _size.width + frameSize.width - viewSize.width,
                                  _size.height + frameSize.height - viewSize.height)
              display: YES 
              animate: YES];

}

- (void) closeWindow: (id) sender
{
	[_window close];
}
@end
