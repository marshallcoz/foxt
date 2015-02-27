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
    //cant = (int)[tb selectedRow];
    //NSLog(@"%i",cant);
    
   // NSView* vie = [self.tbview viewAtColumn:2 row:[tb selectedRow] makeIfNecessary:NO];
    
    //NSView*v =[self.tbview rowViewAtRow:1 makeIfNecessary:NO];
    //NSTableColumn *tcol = [[self.tbview tableColumns] objectAtIndex:1];
    //NSTextFieldCell*ce = [tcol dataCellForRow:0];
    //NSLog(@"%@",[ce stringValue]);
    
    //NSInteger row = [notification.object selectedRow];
    //NSTextField *tf = [[[notification.object viewAtColumn:0 row:row makeIfNecessary:NO]subviews] lastObject];
    //[tf selectText:tf.stringValue];
    
    // Get row at specified index
    //NSTableCellView *selectedRow = [tb viewAtColumn:0 row:[tb selectedRow] makeIfNecessary:NO];
    
    
    //NSView* selv = [tb viewAtColumn:2 row:[tb selectedRow] makeIfNecessary:NO];
    //NSTableRowView* trv = [tb rowViewAtRow:[tb selectedRow] makeIfNecessary:NO];
    
    //cant = (int)[tb clickedRow];
    //NSLog(@"%i",cant);
    NSDictionary* dic = [[NSDictionary alloc] initWithObjectsAndKeys:
                         selecInd,@"renglon",nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"GotoFunctionLine" object:nil userInfo:dic];
    
}



//-(void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
//    if ((int)[tableView numberOfRows] == 1){
//        //[tableView deselectAll:nil];
//        if (cant > 0){
//            NSLog(@"%i",cant);
//            NSNumber *selecInd = [[NSNumber alloc] initWithInt:cant];
//            NSDictionary* dic = [[NSDictionary alloc] initWithObjectsAndKeys:
//                                 selecInd,@"renglon",nil];
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"GotoFunctionLine" object:nil userInfo:dic];
//            cant = -1;
//        }
//        
//    }
//}


@end
