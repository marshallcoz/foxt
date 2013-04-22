//
//  termOut.h
//  scif
//
//  Created by Marcial Contreras Zazueta on 11/13/12.
//  Copyright (c) 2012 UNAM Facultad de Ingeniería. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface termOut : NSView {
    IBOutlet NSPanel *termOUTpanel;
}
//@property (strong) NSWindow* windowed;
@property (assign) Boolean *visible;
@property (strong) NSString *txt;

-(IBAction) showTerm: (NSWindow*)owner;
-(IBAction) hideTerm:(id)sender;
-(void)termDidEnd: (NSWindow*)sheet returnCode: (int)returnCode contextInfo: (void*)contextInfo;
//-(IBAction) popOut:(id)sender;

@end
