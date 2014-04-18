//
//  nota.h
//  scif
//
//  Created by Marcial Contreras Zazueta on 11/1/12.
//  Copyright (c) 2012 UNAM Facultad de Ingeniería. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface nota : NSView{
    
}

@property (strong) NSAttributedString *txt;
@property (strong) NSAttributedString *ATtitle;
@property (strong) NSString *title;
@property bool Typefort;
@property bool TypeTEX;
@property bool TypeComm;
@property (assign) unsigned long indice_inicial;
@property int Mi_modo_actual;
@property (assign) NSNumber *NoDeLineas_reciente;
@property (assign) NSDictionary	*Nota_linesToMarkers;
@property bool nada_interesante;
@property bool resaltar;
@property bool printable;
@property NSRange lastvisibleRange;
//@property bool update_me;
//@property bool imprimible;

@end
