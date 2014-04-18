//
//  WarnModel.m
//  scif
//
//  Created by Marcial Contreras Zazueta on 9/17/13.
//  Copyright (c) 2013 UNAM Facultad de Ingeniería. All rights reserved.
//

#import "WarnModel.h"

@implementation WarnModel
@synthesize Warn;
@synthesize linea;
@synthesize Extra;

-(id)init {
    self = [super init];
    if (self) {
        Warn = [[NSString alloc] initWithString:@"---"];
        Extra = [[NSString alloc] initWithString:@"---"];
        linea = [[NSNumber alloc] initWithInteger:1];
    }
    return self;
}
-(void)dealloc{
    [Extra dealloc];
    [linea dealloc];
    [Warn dealloc];
    [super dealloc];
}
@end
