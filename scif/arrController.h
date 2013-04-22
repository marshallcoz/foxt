//
//  arrController.h
//  scif
//
//  Created by Marcial Contreras Zazueta on 11/1/12.
//  Copyright (c) 2012 UNAM Facultad de Ingeniería. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface arrController : NSObject {
    IBOutlet NSArrayController *arrayController;
}

@property (strong) NSMutableArray *notas;
- (void)clickCerrar:(id)unaHoja;


@end
