//
//  makeScrPrefs.h
//  scif
//
//  Created by Marcial Contreras Zazueta on 6/7/13.
//  Copyright (c) 2013 UNAM Facultad de Ingeniería. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface makeScrPrefs : NSView {
    IBOutlet NSPanel *makeScrPrefsPanel;
    NSString*actlineaCompilador;
    NSString*actlineaArgumentos;
    NSString*actlineaDepurador;
    NSString*actlineaPreCompilador;
    NSString*actlineaExtension;
}
@property (assign) Boolean *visible;
@property (assign) IBOutlet NSSegmentedControl *selectedSet;

@property (assign) IBOutlet NSTextField *lineaCompilador;
@property (assign) IBOutlet NSTextField *lineaArgumentos;
@property (assign) IBOutlet NSTextField *lineaDepurador;
@property (assign) IBOutlet NSTextField *lineaPreCompilador;
@property (assign) IBOutlet NSTextField *lineaExtension;

- (IBAction)selectedPreset:(id)sender;
-(IBAction) showTerm: (NSWindow*)owner;
-(IBAction) hideTerm:(id)sender;
-(void)termDidEnd: (NSWindow*)sheet returnCode: (int)returnCode contextInfo: (void*)contextInfo;


@end
