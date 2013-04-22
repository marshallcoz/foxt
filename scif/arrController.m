//
//  arrController.m
//  scif
//
//  Created by Marcial Contreras Zazueta on 11/1/12.
//  Copyright (c) 2012 UNAM Facultad de Ingeniería. All rights reserved.
//

#import "arrController.h"
#import "nota.h"


@implementation arrController

@synthesize notas = _notas;

-(void)awakeFromNib {
    _notas = [[NSMutableArray alloc] init];
    /*
    nota *t = [[nota alloc] init];
    t.txt = [[NSAttributedString alloc] initWithString:@"\\documentclass [11pt,spanish]{article}\n\\usepackage [spanish,activeacute]{babel}\n\\usepackage [latin1]{inputenc}\n\\usepackage {framed,color}\n\\setlength {\\topmargin}{-.5in}\n\\setlength {\\textheight}{9in}\n\\setlength {\\oddsidemargin}{.125in}\n\\setlength {\\textwidth}{6.25in}\n\\begin {document}\n\\title {Program report}\n\\author {FJSS\\\\\nUniversidad Nacional Aut'onoma de M'exico}\n\\maketitle \n"];
    t.Typefort = true;
    t.TypeTEX = false;
    t.TypeComm = true;
    t.indice_inicial = 99999;
    t.Mi_modo_actual = 1;
    t.nada_interesante = true;
    [arrayController addObject:t];
    */
    
    /*
    nota *n = [[nota alloc] init];
    n.txt = [[NSAttributedString alloc] initWithString:@"C THIS IS A FORTRAN/LATEX/NOTE\nC MADE WITH SCIF\n\n      program one\n      integer :: x,y \n      x = 7.\n      call sleep(2)\n      write(6,*)\"hello\"\n      write(6,*)x\n      end"];
    n.Typefort = false;
    n.TypeTEX = true;
    n.TypeComm = true;
    n.indice_inicial = 0;
    n.Mi_modo_actual = 0;
    n.nada_interesante = true;
    [arrayController addObject:n];
    */
}


- (void)clickCerrar:(id)unaHoja{
    [arrayController removeObject:unaHoja];  
}




@end
