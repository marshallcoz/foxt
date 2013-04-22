//
//  VarModel.h
//  scif
//
//  Created by Marcial Contreras Zazueta on 12/19/12.
//  Copyright (c) 2012 UNAM Facultad de Ingeniería. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VarModel : NSObject{
@private
    NSString *varName;
    NSString *varValue;
}
@property (copy) NSString *varName;
@property (copy) NSString *varValue;

@end
