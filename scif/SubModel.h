//
//  SubModel.h
//  scif
//
//  Created by Marcial Contreras on 19/02/15.
//  Copyright (c) 2015 UNAM Facultad de Ingeniería. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SubModel : NSObject{
    @private
    NSString *titulo;
    NSString *tipo;
    NSColor *colorTipo;
    NSNumber *linea;
    NSString *txlinea;
}
@property (copy) NSString *titulo;
@property (copy) NSString *tipo;
@property (copy) NSColor *colorTipo;
@property (copy) NSNumber *linea;
@property (copy) NSString *txlinea;
@end
