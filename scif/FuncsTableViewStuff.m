//
//  FuncsTableViewStuff.m
//  scif
//
//  Created by Marcial Contreras on 19/02/15.
//  Copyright (c) 2015 UNAM Facultad de Ingeniería. All rights reserved.
//

#import "FuncsTableViewStuff.h"

@implementation FuncsTableViewStuff

-(void)tableViewSelectionIsChanging:(NSNotification *)notification{
    //NSLog(@"%@",[notification description]);
    NSTableView *tb = [notification object];
    NSNumber *selecInd = [[NSNumber alloc] initWithInteger:[tb selectedRow]];
    //NSLog(@"selected: %d",[selecInd intValue]);
    
    NSDictionary* dic = [[NSDictionary alloc] initWithObjectsAndKeys:
                         selecInd,@"renglon",nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"GotoFunctionLine" object:nil userInfo:dic];
}


@end
