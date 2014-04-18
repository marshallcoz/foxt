//
//  WarnModel.h
//  scif
//
//  Created by Marcial Contreras Zazueta on 9/17/13.
//  Copyright (c) 2013 UNAM Facultad de Ingeniería. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WarnModel : NSObject{
    @private
    NSString *Warn;
    NSString *Extra;
    NSNumber *linea;
}
@property (copy) NSString *Warn;
@property (copy) NSString *Extra;
@property (copy) NSNumber *linea;

@end
