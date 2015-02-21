//
//  SubModel.m
//  scif
//
//  Created by Marcial Contreras on 19/02/15.
//  Copyright (c) 2015 UNAM Facultad de Ingeniería. All rights reserved.
//

#import "SubModel.h"

@implementation SubModel
@synthesize titulo;
@synthesize tipo;
@synthesize colorTipo;
@synthesize linea;
@synthesize txlinea;
-(id)init {
    self = [super init];
    if (self) {
        titulo = [[NSString alloc] initWithString:@"---"];
        tipo = [[NSString alloc] initWithString:@"---"];
        colorTipo = [[NSColor alloc] init];
        linea = [[NSNumber alloc] initWithInteger:1];
        txlinea = [[NSString alloc] initWithString:@"1"];
    }
    return self;
}
-(void)dealloc{
    [tipo dealloc];
    [colorTipo dealloc];
    [titulo dealloc];
    [linea dealloc];
    [txlinea dealloc];
    [super dealloc];
}
@end
