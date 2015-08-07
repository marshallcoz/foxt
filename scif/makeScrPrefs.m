//
//  makeScrPrefs.m
//  scif
//
//  Created by Marcial Contreras Zazueta on 6/7/13.
//  Copyright (c) 2013 UNAM Facultad de Ingeniería. All rights reserved.
//

#import "makeScrPrefs.h"

@implementation makeScrPrefs

@synthesize visible = _visible;
@synthesize selectedSet = _selectedSet;
@synthesize lineaCompilador = _lineaCompilador;
@synthesize lineaArgumentos = _lineaArgumentos;
@synthesize lineaDepurador = _lineaDepurador;
@synthesize lineaPreCompilador = _lineaPreCompilador;
@synthesize lineaExtension = _lineaExtension;
@synthesize lineaRunArgs = _lineaRunArgs;


-(id)init {
    self = [super init];
    if (self) {
        _visible = NO;
        _lineaCompilador = [[NSTextField alloc]init];
        _lineaDepurador = [[NSTextField alloc]init];
        _lineaArgumentos = [[NSTextField alloc]init];
        _lineaPreCompilador = [[NSTextField alloc]init];
        _lineaExtension = [[NSTextField alloc]init];
        _lineaRunArgs = [[NSTextField alloc]init];
        _selectedSet = [[NSSegmentedControl alloc] init];
        actlineaCompilador = [[NSString alloc] init];
        actlineaArgumentos = [[NSString alloc] init];
        actlineaDepurador = [[NSString alloc] init];
        actlineaPreCompilador = [[NSString alloc] init];
        actlineaExtension = [[NSString alloc] init];
        actlineaRunArgs = [[NSString alloc] init];
    }
    return self;
}

//-(void)viewWillDraw{
//    if (!_visible) {
//        // cargar los valores actuales
//        //[_selectedSet setSelectedSegment:6];
////        actlineaCompilador = [_lineaCompilador stringValue];
////        actlineaArgumentos = [_lineaArgumentos stringValue];
////        actlineaDepurador = [_lineaDepurador stringValue];
////        actlineaExtension = [_lineaExtension stringValue];
////        actlineaPreCompilador = [_lineaPreCompilador stringValue];
////        [_selectedSet setSelectedSegment:6];
//    }
//}

- (IBAction)selectedPreset:(id)sender {
    NSString *ruta = NSHomeDirectory();
    ruta = [ruta stringByAppendingString:@"/.scifex/RunPrefs.plist"];
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithContentsOfFile:ruta];
    int preset = (int)[_selectedSet selectedSegment] + 1;
    
    if (preset <= 6) {
        [_lineaCompilador setStringValue:[[NSString alloc] initWithString:[info objectForKey:[NSString stringWithFormat:@"Compilador - %i",preset]]]];
        [_lineaDepurador setStringValue:[[NSString alloc] initWithString:[info objectForKey:[NSString stringWithFormat:@"Depurador - %i",preset]]]];
        [_lineaArgumentos setStringValue:[[NSString alloc] initWithString:[info objectForKey:[NSString stringWithFormat:@"Argumentos - %i",preset]]]];
        [_lineaPreCompilador setStringValue:[[NSString alloc] initWithString:[info objectForKey:[NSString stringWithFormat:@"PreDepurador - %i",preset]]]];
        [_lineaExtension setStringValue:[[NSString alloc] initWithString:[info objectForKey:[NSString stringWithFormat:@"extension - %i", preset]]]];
        [_lineaRunArgs setStringValue:[[NSString alloc] initWithString:[info objectForKey:[NSString stringWithFormat:@"RunArgs - %i", preset]]]];
        
        
//        [_lineaArgumentos setEditable:false];
//        [_lineaCompilador setEditable:false];
//        [_lineaDepurador setEditable:false];
//        [_lineaExtension setEditable:false];
//        [_lineaPreCompilador setEditable:false];
    }
    
    if (preset == 7) {
        [_lineaCompilador resignFirstResponder];
        [_lineaArgumentos resignFirstResponder];
        [_lineaDepurador resignFirstResponder];
        [_lineaExtension resignFirstResponder];
        [_lineaPreCompilador resignFirstResponder];
        [_lineaRunArgs resignFirstResponder];
        // es el actual.
        [_lineaCompilador setStringValue:actlineaCompilador];
        [_lineaDepurador setStringValue:actlineaDepurador];
        [_lineaArgumentos setStringValue:actlineaArgumentos];
        [_lineaPreCompilador setStringValue:actlineaPreCompilador];
        [_lineaExtension setStringValue:actlineaExtension];
        [_lineaRunArgs setStringValue:actlineaRunArgs];
//        [_lineaArgumentos setEditable:true];
//        [_lineaCompilador setEditable:true];
//        [_lineaDepurador setEditable:true];
//        [_lineaExtension setEditable:true];
//        [_lineaPreCompilador setEditable:true];
    }
    
}

-(IBAction) showTerm: (NSWindow*)owner{
    
    actlineaCompilador = [_lineaCompilador stringValue];
    actlineaArgumentos = [_lineaArgumentos stringValue];
    actlineaDepurador = [_lineaDepurador stringValue];
    actlineaExtension = [_lineaExtension stringValue];
    actlineaPreCompilador = [_lineaPreCompilador stringValue];
    actlineaRunArgs = [_lineaRunArgs stringValue];
    
    // mostrar la hoja
    //[[NSApplication sharedApplication] beginSheet:makeScrPrefsPanel modalForWindow:owner modalDelegate:self didEndSelector:@selector(termDidEnd:returnCode:contextInfo:) contextInfo:nil];
    [[[NSApplication sharedApplication] mainWindow] beginSheet:makeScrPrefsPanel completionHandler:^(NSModalResponse returnCode) {
        NSLog(@"en makeScrPrefs : showTerm");
    }];
}

-(IBAction) hideTerm:(id)sender{
    [[[NSApplication sharedApplication] mainWindow] endSheet: makeScrPrefsPanel];
}

-(void)termDidEnd: (NSWindow*)sheet returnCode: (int)returnCode contextInfo: (void*)contextInfo{
    [sheet orderOut:nil];
    //mandar mensaje para que tomen los valores
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateSpripts" object:nil];
}

@end
