//
//  EncontradoModel.h
//  scif
//
//  Created by Marcial Contreras on 11/03/15.
//  Copyright (c) 2015 UNAM Facultad de Ingeniería. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EncontradoModel : NSObject{
@private
    NSNumber* linea;
    NSString* titulo;
    NSString* txlinea;
}
@property (copy) NSNumber* linea;
@property (copy) NSString* titulo;
@property (copy) NSString* txlinea;
@end

