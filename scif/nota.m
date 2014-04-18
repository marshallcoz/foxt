//
//  nota.m
//  scif
//
//  Created by Marcial Contreras Zazueta on 11/1/12.
//  Copyright (c) 2012 UNAM Facultad de Ingeniería. All rights reserved.
//

#import "nota.h"
#import <Quartz/Quartz.h>

@implementation nota

@synthesize txt = _txt;
@synthesize indice_inicial = _indice;
@synthesize Typefort = _Typefort;
@synthesize TypeTEX = _TypeTEX;
@synthesize TypeComm = _TypeComm;
@synthesize Mi_modo_actual = _Mi_modo_actual;
@synthesize NoDeLineas_reciente = _NoDeLineas_reciente;
@synthesize Nota_linesToMarkers = _Nota_linesToMarkers;
@synthesize nada_interesante = _nada_interesante;
@synthesize resaltar = _resaltar;
@synthesize printable = _printable;
@synthesize lastvisibleRange = _lastvisibleRange;
//@synthesize update_me = _update_me;
@synthesize title = _title;
@synthesize ATtitle = _ATtitle;
//@synthesize imprimible = _imprimible;

-(id)init {
    self = [super init];
    if (self) {
        _txt = [[NSAttributedString alloc] initWithString:@""];
        _ATtitle = [[NSAttributedString alloc] initWithString:@""];
        _title = [[NSString alloc] initWithString:@""];
        _Typefort = false;
        _TypeTEX = true;
        _TypeComm = true;
        _indice = 0;
        _Mi_modo_actual = 0;
        _NoDeLineas_reciente = 0;
        _Nota_linesToMarkers = [[NSDictionary alloc] init];
        _nada_interesante = false;
        _resaltar = true;
        _printable = true;
        _lastvisibleRange = NSMakeRange(0, 0);
//        _update_me = NO;
    }
    return self;
}
/*
-(void)comboBoxSelectionDidChange:(NSNotification *)notification{
    NSLog(@"in: %i",_indice);
    NSNumber* opcion = [[NSNumber alloc] initWithUnsignedLong:
                        [(NSComboBox*)[notification object] indexOfSelectedItem]];
    NSDictionary* dic = [[NSDictionary alloc] initWithObjectsAndKeys:opcion,@"opcion",_indice,@"indiceUnico",self,@"nota", nil];
    if ([opcion integerValue] == 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MoverArriba" object:nil userInfo:dic];
    } else if ([opcion integerValue] == 1) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MoverAbajo" object:nil userInfo:dic];
    } else if ([opcion integerValue] == 2) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Borrar" object:nil userInfo:dic];
    }
    
}
*/
@end
