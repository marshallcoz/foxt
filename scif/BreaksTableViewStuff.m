//
//  BreaksTableViewStuff.m
//  scif
//
//  Created by Marcial Contreras on 20/02/15.
//  Copyright (c) 2015 UNAM Facultad de Ingeniería. All rights reserved.
//

#import "BreaksTableViewStuff.h"

@implementation BreaksTableViewStuff

-(void)tableViewSelectionIsChanging:(NSNotification *)notification{
    //NSLog(@"%@",[notification description]);
    NSTableView *tb = [notification object];
    NSNumber *selecInd = [[NSNumber alloc] initWithInteger:[tb selectedRow]];
    //NSLog(@"selected: %d",[selecInd intValue]);
    
    NSDictionary* dic = [[NSDictionary alloc] initWithObjectsAndKeys:
                         selecInd,@"renglon",nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"GotoBreakLine" object:nil userInfo:dic];
}


@end
