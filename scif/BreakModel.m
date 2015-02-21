//
//  BreakModel.m
//  scif
//
//  Created by Marcial Contreras on 20/02/15.
//  Copyright (c) 2015 UNAM Facultad de Ingeniería. All rights reserved.
//

#import "BreakModel.h"

@implementation BreakModel
@synthesize titulo;
@synthesize linea;
-(id)init {
    self = [super init];
    if (self) {
        titulo = [[NSString alloc] initWithString:@"---"];
        linea = [[NSNumber alloc] initWithInteger:1];
    }
    return self;
}
-(void)dealloc{
    [linea dealloc];
    [titulo dealloc];
    [super dealloc];
}
@end
