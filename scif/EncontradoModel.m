//
//  EncontradoModel.m
//  scif
//
//  Created by Marcial Contreras on 11/03/15.
//  Copyright (c) 2015 UNAM Facultad de Ingeniería. All rights reserved.
//

#import "EncontradoModel.h"

@implementation EncontradoModel
@synthesize titulo;
@synthesize linea;
@synthesize txlinea;
-(id)init {
    self = [super init];
    if (self) {
        titulo = [[NSString alloc] initWithString:@"---"];
        txlinea = [[NSString alloc] initWithString:@"1"];
        linea = [[NSNumber alloc] initWithInteger:1];
    }
    return self;
}
-(void)dealloc{
    [linea dealloc];
    [titulo dealloc];
    [txlinea dealloc];
    [super dealloc];
}
@end
