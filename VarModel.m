//
//  VarModel.m
//  scif
//
//  Created by Marcial Contreras Zazueta on 12/19/12.
//  Copyright (c) 2012 UNAM Facultad de Ingeniería. All rights reserved.
//

#import "VarModel.h"

@implementation VarModel
@synthesize varName;
@synthesize varValue;


-(id)init {
    self = [super init];
    if (self) {
        varName = [[NSString alloc] initWithString:@"var"];
        varValue = [[NSString alloc] initWithString:@"000"];
    }
    return self;
}
-(void)dealloc{
    [varName release];
    [varValue release];
    [super dealloc];
}
@end
