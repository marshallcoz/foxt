//
//  WarnTableViewStuff.m
//  scif
//
//  Created by Marcial Contreras Zazueta on 9/17/13.
//  Copyright (c) 2013 UNAM Facultad de Ingeniería. All rights reserved.
//

#import "WarnTableViewStuff.h"

@implementation WarnTableViewStuff

-(void)tableViewSelectionDidChange:(NSNotification *)notification{
    //NSLog(@"%@",[notification description]);
    NSTableView *tb = [notification object];
    NSNumber *selecInd = [[NSNumber alloc] initWithInteger:[tb selectedRow]];
    //NSLog(@"selected: %d",[selecInd intValue]);
    
    NSDictionary* dic = [[NSDictionary alloc] initWithObjectsAndKeys:
                         selecInd,@"numLinea",nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"GotoWarningLine" object:nil userInfo:dic];
}


@end
