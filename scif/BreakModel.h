//
//  BreakModel.h
//  scif
//
//  Created by Marcial Contreras on 20/02/15.
//  Copyright (c) 2015 UNAM Facultad de Ingeniería. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BreakModel : NSObject{
    @private
    NSNumber* linea;
    NSString* titulo;
}
@property (copy) NSNumber* linea;
@property (copy) NSString* titulo;
@end
