//
//  PrefMenuControll.h
//  scif
//
//  Created by Marcial Contreras Zazueta on 11/13/12.
//  Copyright (c) 2012 UNAM Facultad de Ingeniería. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PrefMenuControll : NSView
@property (assign) IBOutlet NSTextField *lineaCompilador;
@property (assign) IBOutlet NSTextField *lineaArgumentos;
@property (assign) IBOutlet NSTextField *lineaDepurador;
@property (assign) IBOutlet NSTextField *lineaPreCompilador;
@property (assign) IBOutlet NSSegmentedControl *presetControll;
@property (assign) int preset;
@property (assign) IBOutlet NSTextField *lineaExtension;

- (IBAction)clickBuscaCompilador:(id)sender;
- (IBAction)clickBuscaArgumentos:(id)sender;
- (IBAction)clickBuscaDepurador:(id)sender;
- (IBAction)clickBuscaPreCompilador:(id)sender;
- (IBAction)clickBuscaExtension:(id)sender;
- (IBAction)cerrando:(id)sender;
- (IBAction)selectedApreset:(id)sender;

@property bool visible;



@end
