//
//  rightPane.m
//  scif
//
//  Created by Marcial Contreras Zazueta on 9/16/13.
//  Copyright (c) 2013 UNAM Facultad de Ingeniería. All rights reserved.
//

#import "rightPane.h"

@implementation rightPane


-(void)swipeWithEvent:(NSEvent *)event{
    if ([event deltaX] > 0) {
        //            NSLog(@"mostrar lateral2");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"mostLateral2" object:nil];
        return;
    }
    if ([event deltaX] < 0) {
        //            NSLog(@"ocultar lateral2");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ocultLateral2" object:nil];
        return;
    } 
    
}
@end
