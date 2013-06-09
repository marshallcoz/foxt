//
//  PrefMenuControll.m
//  scif
//
//  Created by Marcial Contreras Zazueta on 11/13/12.
//  Copyright (c) 2012 UNAM Facultad de Ingeniería. All rights reserved.
//

#import "PrefMenuControll.h"

@implementation PrefMenuControll
@synthesize lineaCompilador = _lineaCompilador;
@synthesize lineaDepurador = _lineaDepurador;
@synthesize lineaArgumentos = _lineaArgumentos;
@synthesize lineaPreCompilador = _lineaPreCompilador;
@synthesize visible = _visible;
@synthesize presetControll = _presetControll;
@synthesize lineaExtension = _lineaExtension;
@synthesize preset = _preset;

-(id)init{
    self = [super init];
    if (self) {
        _lineaCompilador = [[NSTextField alloc]init];
        _lineaDepurador = [[NSTextField alloc]init];
        _lineaArgumentos = [[NSTextField alloc]init];
        _lineaPreCompilador = [[NSTextField alloc]init];
        _lineaExtension = [[NSTextField alloc]init];
        _presetControll = [[NSSegmentedControl alloc] init];
        _visible = false;
        _preset = 1;
    }
    return self;
}


-(void)viewWillDraw{
    if (!_visible) {
        //NSUserDefaults*	prefs = [NSUserDefaults standardUserDefaults];
        /*
        [prefs registerDefaults: [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"RunPrefs" ofType: @"plist"]]];
        NSLog(@"cargando : comp : %@",[prefs objectForKey:@"Compilador"]);
        */
        NSString *ruta = NSHomeDirectory();
        ruta = [ruta stringByAppendingString:@"/.scifex/RunPrefs.plist"];
        
        //[prefs registerDefaults:[NSDictionary dictionaryWithContentsOfFile:ruta]];
        //NSLog(@"cargando : comp : %@",[prefs objectForKey:@"Compilador"]);
        
        //_preset = 1;
        //NSLog(@"%@",[NSString stringWithFormat:@"Compilador - %i",_preset]);
        //NSLog(@"cargando : comp : %@",[info objectForKey:[NSString stringWithFormat:@"Compilador - %i",_preset]]);

        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithContentsOfFile:ruta];
        _preset = [[info objectForKey:@"set"] intValue];
        [_presetControll setSelectedSegment:_preset-1];
        NSLog(@"Preset = %i",_preset);
        [_lineaCompilador setStringValue:[info objectForKey:[NSString stringWithFormat:@"Compilador - %i",_preset]]];
        [_lineaDepurador setStringValue:[info objectForKey:[NSString stringWithFormat:@"Depurador - %i",_preset]]];
        [_lineaArgumentos setStringValue:[info objectForKey:[NSString stringWithFormat:@"Argumentos - %i",_preset]]];
        [_lineaPreCompilador setStringValue:[info objectForKey:[NSString stringWithFormat:@"PreDepurador - %i",_preset]]];
        [_lineaExtension setStringValue:[info objectForKey:[NSString stringWithFormat:@"extension - %i",_preset]]];
        _visible = true;
    }
}

-(void)grabar:(NSString*)linea to:(NSString*)key {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *ruta = NSHomeDirectory();
    ruta = [ruta stringByAppendingString:@"/.scifex/RunPrefs.plist"];
    if ([fm isWritableFileAtPath:ruta]) {
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithContentsOfFile:ruta];
        [info setObject:linea forKey:key];
        [info writeToFile:ruta atomically:NO];
        [fm setAttributes:[NSDictionary dictionaryWithObject:[NSDate date] forKey:NSFileModificationDate] ofItemAtPath:ruta error:nil];
    }
}

- (IBAction)clickBuscaCompilador:(id)sender {
    NSString *linea = [NSString stringWithString:[_lineaCompilador stringValue]];
    NSLog(@"comp: %@",linea);
    [self grabar:linea to:[NSString stringWithFormat:@"Compilador - %i",_preset]];
}

- (IBAction)clickBuscaDepurador:(id)sender {
    NSString *linea = [NSString stringWithString:[_lineaDepurador stringValue]];
    NSLog(@"dep: %@",linea);
    [self grabar:linea to:[NSString stringWithFormat:@"Depurador - %i",_preset]];
}

- (IBAction)clickBuscaArgumentos:(id)sender{
    NSString *linea = [NSString stringWithString:[_lineaArgumentos stringValue]];
    NSLog(@"args: %@",linea);
    [self grabar:linea to:[NSString stringWithFormat:@"Argumentos - %i",_preset]];
}

- (IBAction)clickBuscaPreCompilador:(id)sender{
    NSString *linea = [NSString stringWithString:[_lineaPreCompilador stringValue]];
    NSLog(@"precompScript: %@",linea);
    [self grabar:linea to:[NSString stringWithFormat:@"PreDepurador - %i",_preset]];
}

- (IBAction)clickBuscaExtension:(id)sender{
    NSString *linea = [NSString stringWithString:[_lineaExtension stringValue]];
    NSLog(@"extension: %@",linea);
    [self grabar:linea to:[NSString stringWithFormat:@"extension - %i",_preset]];
}


- (IBAction)selectedApreset:(id)sender{
    if (sender == _presetControll) {
        NSLog(@"seleccionado el preset = %ld",[_presetControll selectedSegment]+1);
        
        [self setPreset:(int)[_presetControll selectedSegment]+1];
        
        NSString *ruta = NSHomeDirectory();
        ruta = [ruta stringByAppendingString:@"/.scifex/RunPrefs.plist"];
        
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithContentsOfFile:ruta];
        [_lineaCompilador setStringValue:[info objectForKey:[NSString stringWithFormat:@"Compilador - %i",_preset]]];
        [_lineaDepurador setStringValue:[info objectForKey:[NSString stringWithFormat:@"Depurador - %i",_preset]]];
        [_lineaArgumentos setStringValue:[info objectForKey:[NSString stringWithFormat:@"Argumentos - %i",_preset]]];
        [_lineaPreCompilador setStringValue:[info objectForKey:[NSString stringWithFormat:@"PreDepurador - %i",_preset]]];
        [_lineaExtension setStringValue:[info objectForKey:[NSString stringWithFormat:@"extension - %i",_preset]]];
    }
}


- (IBAction)cerrando:(id)sender{
    [self setPreset:(int)[_presetControll selectedSegment]+1];
    [self grabar:[NSString stringWithFormat:@"%i",_preset] to:@"set"];
    
    [self clickBuscaCompilador:nil];
    
    [self clickBuscaDepurador:nil];
    
    [self clickBuscaArgumentos:nil];
    
    [self clickBuscaPreCompilador:nil]; 
    
    [[self window]close];
}

@end
