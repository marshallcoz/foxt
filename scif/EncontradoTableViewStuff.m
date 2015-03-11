//
//  EncontradoTableViewStuff.m
//  scif
//
//  Created by Marcial Contreras on 11/03/15.
//  Copyright (c) 2015 UNAM Facultad de Ingeniería. All rights reserved.
//

#import "EncontradoTableViewStuff.h"

@implementation EncontradoTableViewStuff

-(void)tableViewSelectionIsChanging:(NSNotification *)notification{
    //NSLog(@"%@",[notification description]);
    NSTableView *tb = [notification object];
    NSNumber *selecInd = [[NSNumber alloc] initWithInteger:[tb selectedRow]];
    NSDictionary* dic = [[NSDictionary alloc] initWithObjectsAndKeys:
                         selecInd,@"renglon",nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"GotoEncontradoLine" object:nil userInfo:dic];
}

@end
