//
//  scifDocument.m
//  scif
//
//  Created by Marcial Contreras Zazueta on 10/31/12.
//  Copyright (c) 2012 UNAM Facultad de Ingeniería. All rights reserved.
//

#import "scifDocument.h"
#import "nota.h"

#import "NSArray+Color.h"
#import "NSScanner+SkipUpToCharset.h"

#import "PrefMenuControll.h"

#import "MarkerLineNumberView.h"
#import "NoodleLineNumberView.h"
#import "NoodleLineNumberMarker.h"

#import "VarModel.h"
#import "WarnModel.h"



static BOOL	sSyntaxColoredTextDocPrefsInited = NO;
static BOOL sPrefInits = NO;
static NSString * s = @"";
static NSString* inPut = @".programInput.txt";
static NSString* outPut = @".programOutput.txt";


@implementation scifDocument
#pragma mark synth
@synthesize ARRAYcontroller;
@synthesize txtx;
@synthesize LayoutVerticalScroller;
@synthesize TheSplitView;
@synthesize gdbSplitView;
@synthesize gdbWarnSplitView;
@synthesize SectionMode;
@synthesize RunStopPrint;
@synthesize Debug_panel;
@synthesize Debug_actions;
@synthesize togglecomment;
@synthesize OpcionesNota;
@synthesize OpcionesNotaImprimir;
@synthesize MainTAB;
@synthesize terminal_out;
@synthesize modo_seleccionado;
@synthesize tablaOutline;

@synthesize nombreArchivo;
@synthesize nombreArchivoFORTRAN;
@synthesize nombreArchivoTeX;
@synthesize directorioBase;
@synthesize nombreOUTput;
@synthesize ToggleBreakpoints;
@synthesize ToggleMakeScriptPrefs;
@synthesize VarsArray;
@synthesize WarnsArray;
@synthesize NotaiDisclosureBut;
@synthesize View2Drawer;
@synthesize NotaiDisclosureTxt;
@synthesize NotaiDisclosureTitleBut;
@synthesize AWAKE;
@synthesize BPs;
@synthesize palabra;
@synthesize palabraRange;

#pragma mark -
#pragma mark Life cycle

- (id)init
{
    modo_seleccionado = 0;
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
        // If an error occurs here, return nil.
        sourceCode = nil;
		autoSyntaxColoring = YES;
		maintainIndentation = YES;
		recolorTimer = nil;
		syntaxColoringBusy = NO;
        VarsArray = [[NSMutableArray alloc] init];
        WarnsArray = [[NSMutableArray alloc] init];
        palabra = @"";
        palabraRange = NSMakeRange(0, 0);
        
        lineaArgumentos = [[NSString alloc] initWithString:@""];
        lineaCompilador = [[NSString alloc] initWithString:@""];
        lineaDepurador =  [[NSString alloc] initWithString:@""];
        lineaExtension = [[NSString alloc] initWithString:@""];
        lineaPreCompilador = [[NSString alloc] initWithString:@""];
        lineaRunArgs = [[NSString alloc] initWithString:@""];
    }
    return self;
}

-(void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSNotificationCenter *notCenter;
    notCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
    [notCenter removeObserver:self];
    
    //dejar de obscultar los archivos de la terminal
    //[observadorINPUT removePathFromQueue:[NSString stringWithFormat:@"%@/%@",directorioBase,inPut]];
    //[observadorOUTPUT removePathFromQueue:[NSString stringWithFormat:@"%@/%@",directorioBase,outPut]];
    [self clean_and_close];
    //[self Stop_button_click:nil];
    
    [ARRAYcontroller removeObserver:self forKeyPath:@"selectionIndexes"];
    [sourceCode release];
    sourceCode = nil;
	[recolorTimer invalidate];
	[recolorTimer release];
	recolorTimer = nil;
	[replacementString release];
	replacementString = nil;
	[VarsArray release];
    [WarnsArray release];
	[super dealloc];
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"scifDocument";
    [txtx setString:@"texto"];
    nombreArchivo = @"";
}

+(void) asegurarQuePfrefsYaIniciaron{
    
    NSFileManager *fm = [NSFileManager defaultManager];
    s = NSHomeDirectory();
    NSString *dir = [s stringByAppendingString:@"/.scifex"];
    s = [s stringByAppendingString:@"/.scifex/RunPrefs.plist"];
    //NSLog(@"%@",s);
    if (![fm fileExistsAtPath:s]) {
        //crearlo y copiar desde el bundle
        BOOL isDir;
        if (![fm fileExistsAtPath:dir isDirectory:&isDir]) {
            //primero crear el directorio
            if (![fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:Nil error:NULL]) {
                NSLog(@"Error creando directorio %@",dir);
            }
        }
        //el directorio existe y falta el archivo
        NSData *dat = [[NSData alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"RunPrefs" ofType:@"plist"]] ;
        if (![fm createFileAtPath:s contents:dat attributes:Nil]) {
            NSLog(@"Error creando archivo %@",s);
        }
    }
    
    
    if (!sPrefInits) {
        NSUserDefaults*	prefs = [NSUserDefaults standardUserDefaults];
        [prefs registerDefaults:[NSDictionary dictionaryWithContentsOfFile:s]];
        sPrefInits = YES;
    }
}

+(void) makeSurePrefsAreInited
{
	if( !sSyntaxColoredTextDocPrefsInited )
	{
		NSUserDefaults*	prefs = [NSUserDefaults standardUserDefaults];
		[prefs registerDefaults: [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"SyntaxColorDefaults" ofType: @"plist"]]];
        
		sSyntaxColoredTextDocPrefsInited = YES;
	}
}


- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
    
    [[self class] makeSurePrefsAreInited];
    [[self class] asegurarQuePfrefsYaIniciaron];
    
    if (lineaCompilador == NULL) {
        // si es un archivo nuevo o de una versión anterior precargamos scripts
        NSString *ruta = NSHomeDirectory();
        ruta = [ruta stringByAppendingString:@"/.scifex/RunPrefs.plist"];
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithContentsOfFile:ruta];
        int preset = [[info objectForKey:@"set"] intValue];
        
        lineaCompilador = [[NSString alloc] initWithString:[info objectForKey:[NSString stringWithFormat:@"Compilador - %i",preset]]];
        lineaDepurador = [[NSString alloc] initWithString:[info objectForKey:[NSString stringWithFormat:@"Depurador - %i",preset]]];
        lineaArgumentos = [[NSString alloc] initWithString:[info objectForKey:[NSString stringWithFormat:@"Argumentos - %i",preset]]];
        lineaPreCompilador = [[NSString alloc] initWithString:[info objectForKey:[NSString stringWithFormat:@"PreDepurador - %i",preset]]];
        lineaExtension = [[NSString alloc] initWithString:[info objectForKey:[NSString stringWithFormat:@"extension - %i", preset]]];
        lineaRunArgs = [[NSString alloc] initWithString:[info objectForKey:[NSString stringWithFormat:@"RunArgs - %i", preset]]];
        
        //        [[makeScrPrefsPanel lineaArgumentos] setStringValue:lineaArgumentos];
        //        [[makeScrPrefsPanel lineaCompilador] setStringValue:lineaCompilador];
        //        [[makeScrPrefsPanel lineaDepurador] setStringValue:lineaDepurador];
        //        [[makeScrPrefsPanel lineaExtension] setStringValue:lineaExtension];
        //        [[makeScrPrefsPanel lineaPreCompilador] setStringValue:lineaPreCompilador];
    }    
    if (AWAKE != Nil) {
        NSArray *a = [[NSArray alloc] initWithArray: AWAKE] ;
        int i;
        //        
        //        NSLog(@"%@\n%@\n%@\n%@\n%@\n",lineaCompilador,
        //              lineaDepurador,lineaArgumentos,
        //              lineaPreCompilador,lineaExtension);
        
        for (i=0; i<[a count]; i++) {
            nota* t = [[nota alloc] init] ;
            [t setTxt: [[(nota*)[a objectAtIndex:i] txt] copy]];
            [t setTypefort: [(nota*)[a objectAtIndex:i] Typefort] ];
            [t setTypeTEX: [(nota*)[a objectAtIndex:i] TypeTEX]];
            [t setTypeComm: [(nota*)[a objectAtIndex:i] TypeComm]];
            [t setPrintable:[(nota*)[a objectAtIndex:i] printable]];
            //[t setIndice_inicial:[(nota*)[a objectAtIndex:i] indice_inicial]];
            [t setMi_modo_actual:[(nota*)[a objectAtIndex:i] Mi_modo_actual]];
            
            [ARRAYcontroller addObject:t];
        }
        
        //determinar los .indice_inicial de todos
        unsigned long suma_lineas = 0;
        for (i=0; i<[[ARRAYcontroller arrangedObjects] count]; i++) {
            nota *n = [[nota alloc] init];
            n = (nota*)[[ARRAYcontroller arrangedObjects] objectAtIndex:i];
            if (n.Mi_modo_actual == 0) {
                // es un fortran
                unsigned long letra = 0;
                unsigned long numberOfLines = 0;
                unsigned long stringLength = [[[n txt]string] length];
                do {
                    letra = NSMaxRange([[[n txt]string] lineRangeForRange:NSMakeRange(letra, 0)]);
                    numberOfLines++;
                } while (letra < stringLength);
                suma_lineas = suma_lineas + numberOfLines;
                n.NoDeLineas_reciente = [[NSNumber alloc] initWithUnsignedLong:numberOfLines];
                //[n setNoDeLineas_reciente:[NSNumber numberWithUnsignedLong:numberOfLines]];
                n.indice_inicial = suma_lineas;
            }
        }
        
        sourceCode = [[(nota*)[[ARRAYcontroller arrangedObjects] objectAtIndex:0] txt] string];
        //NSLog(@"son %li objetos\n",[[ARRAYcontroller arrangedObjects] count]);
        [ARRAYcontroller  rearrangeObjects];
        
        
    } else { 
        
        // ponemos unos cuantos BLOCKS para empezar:
        nota *t = [[nota alloc] init];
        [t setTxt:[[NSAttributedString alloc] initWithAttributedString:[self preProssText:@"\\documentclass [11pt,spanish]{article}\n\\usepackage [spanish,activeacute]{babel}\n\\usepackage [latin1]{inputenc}\n\\usepackage { amsmath }\n\\usepackage { upgreek }\n\\usepackage { mathrsfs }\n\\usepackage { graphicx }\n\\usepackage { framed,color }\n\\setlength {\\topmargin}{-.5in}\n\\setlength {\\textheight}{9in}\n\\setlength {\\oddsidemargin}{.125in}\n\\setlength {\\textwidth}{6.25in}\n\\begin {document}\n\\title {Program report}\n\\author {MACZ\\\\\nUniversidad Nacional Aut\\'onoma de M\\'exico}\n\\maketitle \n" oftype:@"Latex"]]];
        //        t.txt = [[NSAttributedString alloc] initWithString:@"\\documentclass [11pt,spanish]{article}\n\\usepackage [spanish,activeacute]{babel}\n\\usepackage [latin1]{inputenc}\n\\usepackage { amsmath }\n\\usepackage { upgreek }\n\\usepackage { mathrsfs }\n\\usepackage { graphicx }\n\\usepackage { framed,color }\n\\setlength {\\topmargin}{-.5in}\n\\setlength {\\textheight}{9in}\n\\setlength {\\oddsidemargin}{.125in}\n\\setlength {\\textwidth}{6.25in}\n\\begin {document}\n\\title {Program report}\n\\author {MACZ\\\\\nUniversidad Nacional Aut\\'onoma de M\\'exico}\n\\maketitle \n"] ;
        //        t.txt = [self preProssText:[t.txt string] oftype:@"Fortran"];
        t.Typefort = true;
        t.TypeTEX = false;
        t.TypeComm = true;
        t.indice_inicial = 99999;
        t.Mi_modo_actual = 1;
        t.nada_interesante = true;
        [ARRAYcontroller addObject:t];
        //[t autorelease];
        nota *n = [[nota alloc] init] ;
        [n setTxt:[[NSAttributedString alloc] initWithAttributedString:[self preProssText:@"! THIS IS A FORTRAN/LATEX/NOTE\n! MADE WITH SCIF\n\n      program one\n      integer :: x,y \n      x = 7.\n      call sleep(2)\n      write(6,*)\"hello\"\n      write(6,*)x\n      end" oftype:@"Fortran"]]];
        //        n.txt = [[NSAttributedString alloc] initWithString:@"! THIS IS A FORTRAN/LATEX/NOTE\n! MADE WITH SCIF\n\n      program one\n      integer :: x,y \n      x = 7.\n      call sleep(2)\n      write(6,*)\"hello\"\n      write(6,*)x\n      end"];
        n.Typefort = false;
        n.TypeTEX = true;
        n.TypeComm = true;
        n.indice_inicial = 0;
        n.Mi_modo_actual = 0;
        n.nada_interesante = true;
        [ARRAYcontroller addObject:n];
        
        //NSLog(@"son %li objetos\n",[[ARRAYcontroller arrangedObjects] count]);
        sourceCode = [n.txt string];
    }
    // Do initial syntax coloring of our file:
	[self recolorCompleteFile:nil];
    
    [ARRAYcontroller setSelectionIndex:0];
    [txtx setNeedsDisplay:YES];
    [self turnOffWrapping: NotaiDisclosureTxt];
    // Set up some sensible defaults for syntax coloring:
	//[[self class] makeSurePrefsAreInited];
    
    [[self class] asegurarQuePfrefsYaIniciaron];
    
	
	// Load source code into text view, if necessary:
	if( sourceCode != nil )
	{
        [txtx setString: sourceCode];
        
		[sourceCode release];
		sourceCode = nil;
	}
    
    // Register for "text changed" notifications of our text storage:
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processEditing:)
                                                 name: NSTextStorageDidProcessEditingNotification
                                               object: [txtx textStorage]];
	// un método para que cuando escribes en la ventana anexa, se acutaliza el array:
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shouldUpdateArrayController:) 
                                                 name:NSTextStorageDidProcessEditingNotification 
                                               object:[NotaiDisclosureTxt textStorage]];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fdf:) 
                                                 name:NSTextViewDidChangeSelectionNotification
                                               object:txtx];
    
    
    
	// Put selection at top like Project Builder has it, so user sees it:
	[txtx setSelectedRange: NSMakeRange(0,0)];
    
	// Make sure text isn't wrapped:
	//[self turnOffWrapping];
	
	// Do initial syntax coloring of our file:
	[self recolorCompleteFile:nil];
    
    //add some initial search results
    recentSearches = [[[NSMutableArray alloc] initWithObjects:
                       @"Favorite",@"Personal", nil] mutableCopy];
    
    predebugscriptdone = false;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    /*
     Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
     You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
     */
    NSException *exception = [NSException exceptionWithName:@"NoGuardado" reason:[NSString stringWithFormat:@"%@ no se guardó", NSStringFromSelector(_cmd)] userInfo:nil];
    NSString *tt = [[NSString alloc] init] ;
    NSArray *CurrArr = [ARRAYcontroller arrangedObjects];
    int i;
    int modo_i;
    if ([CurrArr count] < 1) {
        NSLog(@"No hay cosas");
        @throw exception;
        return nil;
    }
    
    NSDictionary *textos_dic = [self textos_de_salida_para_el_arreglo:[ARRAYcontroller arrangedObjects]];
    if (textos_dic == nil) {
        NSLog(@"\n\nError: Document contents could not be grouped.");
        [self postthis:@"Error: Document contents could not be grouped.\n" withcoolor:[NSColor redColor]];
        @throw exception;
        return nil;
    }
    NSString *textoFortran = [textos_dic objectForKey:@"t_fort"];
    NSString *textoLatex = [textos_dic objectForKey:@"t_late"];
    //NSString *textoLatex = [textos_dic objectForKey:@"t_todo"];
    
    if (![self guardadoTextoFortran:textoFortran TextoLatex:textoLatex]) {
        NSLog(@"\nSave again to save fortran and latex individual files\n");
        [self postthis:@"\nSave again to save fortran and latex individual files\n" withcoolor:[NSColor redColor]];
    }
    
    NSMutableArray *datos_mutARR = [[NSMutableArray alloc] init] ;
    
    for (i=0; i<[CurrArr count]; i++) {
        modo_i = [(nota*)[[ARRAYcontroller arrangedObjects] objectAtIndex:i] Mi_modo_actual];
        //hay que quitarle el formato
        NSAttributedString *txt = [(nota*)[[ARRAYcontroller arrangedObjects] objectAtIndex:i] txt];
        NSData *txt_data = [[txt string] dataUsingEncoding:NSMacOSRomanStringEncoding allowLossyConversion:YES];
        NSString *txt_str = [[NSString alloc] initWithData:txt_data encoding:NSMacOSRomanStringEncoding] ;
        // NSLog(@"%@",txt_str);
        if (txt_str != nil) {
            if (modo_i == 0) {
                tt = [@"#INI_FOR:\n" stringByAppendingString:txt_str];
            }
            if (modo_i == 1) {
                tt = [@"#INI_TEX:\n" stringByAppendingString:txt_str];
            }
            if (modo_i == 2) {
                tt = [@"#INI_TEC:\n" stringByAppendingString:txt_str];
            }
            if (modo_i == 3) {
                tt = [@"#INI_INV:\n" stringByAppendingString:txt_str];
            }
            tt = [tt stringByAppendingString:@"\n"];
            [datos_mutARR addObject:tt];
        } else {
            //            NSLog(@"apilando");
            @throw exception;
            return nil;
        }
    }
    //agregamos si es printable o no
    tt = @"#printables";
    for (i=0; i<[CurrArr count]; i++) {
        bool printMe = [(nota*)[[ARRAYcontroller arrangedObjects] objectAtIndex:i] printable];
        if (printMe) {
            tt = [tt stringByAppendingString:@",0"];
        } else {
            tt = [tt stringByAppendingString:@",1"];
        }
    }
    //    NSLog(@"los printables se guardan como: \n%@",tt);
    [datos_mutARR addObject:tt];
    
    //agregamos los breakpoints
    tt = @"";
    //NSMutableArray *todos_los_breakpoints = [[NSMutableArray alloc] init];
    for (i = 0; i < [[ARRAYcontroller arrangedObjects] count]; i++) {
        nota* n = (nota*)[[ARRAYcontroller arrangedObjects] objectAtIndex:i];
        if ([n Mi_modo_actual] == 0) {
            NSEnumerator *UnMarcador = [[n Nota_linesToMarkers] keyEnumerator];
            NSNumber *Key_en_nota = nil;
            unsigned long num_lin_inicial = [n indice_inicial];
            while (Key_en_nota = [UnMarcador nextObject]) {
                //NSLog(@"\nBreakpoint en: %lu",num_lin_inicial + [Key_en_nota unsignedLongValue] + 1);
                //[todos_los_breakpoints addObject:[NSNumber numberWithUnsignedLong:num_lin_inicial + [Key_en_nota unsignedLongValue] + 1]];
                
                tt = [tt stringByAppendingFormat:@",%i",[[NSNumber numberWithUnsignedLong:num_lin_inicial + [Key_en_nota unsignedLongValue] + 1] intValue]];
            }
        }
    }
    if (![tt isEqualToString:@""]) {
        tt = [@"BPs" stringByAppendingString:tt];
        //        NSLog(@"los breakpoints se guardan como: \n %@",tt);
        [datos_mutARR addObject:tt];
    }
    
    //scripts
    tt = [@"l_compilador:" stringByAppendingString:lineaCompilador];
    //    NSLog(@"%@",tt);
    [datos_mutARR addObject:tt];
    tt = [@"l_Depurador:" stringByAppendingString:lineaDepurador];
    //    NSLog(@"%@",tt);
    [datos_mutARR addObject:tt];
    tt = [@"l_Argumentos:" stringByAppendingString:lineaArgumentos];
    //    NSLog(@"%@",tt);
    [datos_mutARR addObject:tt];
    tt = [@"l_PreCompilador:" stringByAppendingString:lineaPreCompilador];
    //    NSLog(@"%@",tt);
    [datos_mutARR addObject:tt];
    tt = [@"l_extension:" stringByAppendingString:lineaExtension];
    //    NSLog(@"%@",tt);
    [datos_mutARR addObject:tt];
    tt = [@"l_runArgs:" stringByAppendingString:lineaRunArgs];
    //    NSLog(@"%@",tt);
    [datos_mutARR addObject:tt];
    
    tt=@"";
    //guardar el numero de preset (será descontinuado).. mejor no. no afecta y podría servir
    NSString *ruta = NSHomeDirectory();
    ruta = [ruta stringByAppendingString:@"/.scifex/RunPrefs.plist"];
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithContentsOfFile:ruta];
    tt = [info objectForKey:@"set"];
    if (![tt isEqualToString:@""]) {
        tt = [@"#presets" stringByAppendingString:tt];
        //NSLog(@"El preset guardado es: \n %@",tt);
        [datos_mutARR addObject:tt];
    }
    
    NSData *datos = [NSKeyedArchiver archivedDataWithRootObject:datos_mutARR];
    // NSLog(@"success saving");
    return datos;
}


//-(NSData*) dataRepresentationOfType:(NSString *)type {
//Save raw text to a file as MacRoman text.
//return [[txtx string] dataUsingEncoding: NSMacOSRomanStringEncoding allowLossyConversion:YES];
//}
/*
 -(BOOL)	loadDataRepresentation: (NSData*)data ofType: (NSString*)aType
 {
 //Load plain MacRoman text from a text file.
 
 // sourceCode is a member variable:
 if( sourceCode )
 {
 [sourceCode release];   // Release any old text.
 sourceCode = nil;
 }
 sourceCode = [[NSString alloc] initWithData:data encoding: NSMacOSRomanStringEncoding]; // Load the new text.
 
 // Try to load it into textView and syntax colorize it:
 Since this may be called before the NIB has been loaded, we keep around
 sourceCode as a data member and try these two calls again in windowControllerDidLoadNib: //
 [txtx setString: sourceCode];
 [self recolorCompleteFile:nil];
 
 // Try to get selection info if possible:
 NSAppleEventDescriptor*  evt = [[NSAppleEventManager sharedAppleEventManager] currentAppleEvent];
 if( evt )
 {
 NSAppleEventDescriptor*  param = [evt paramDescriptorForKeyword: keyAEPosition];
 if( param )		// This is always false when xCode calls us???
 {
 NSData*					data = [param data];
 struct SelectionRange   range;
 
 memmove( &range, [data bytes], sizeof(range) );
 
 if( range.lineNum >= 0 )
 [self goToLine: range.lineNum +1];
 else
 [self goToRangeFrom: (int)range.startRange toChar: (int)range.endRange];
 }
 }
 
 return YES;
 }
 */

+(BOOL)autosavesInPlace
{
    return YES;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    AWAKE = [[NSArray alloc] init];
    BPs = [[NSArray alloc] init];
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    
    NSException *exception = [NSException exceptionWithName:@"ReadDataError" reason:[NSString stringWithFormat:@"%@ no pudo leerse", NSStringFromSelector(_cmd)] userInfo:nil];
    NSMutableArray *datos_mutARR = [[NSMutableArray alloc] init] ;
    datos_mutARR = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    if ([datos_mutARR count]<1) {
        NSLog(@"no hay datos");
        @throw exception;
        return NO;
    }
    NSArray *arrr = [[NSArray alloc] init];
    NSEnumerator *enumerator = [datos_mutARR objectEnumerator];
    id element;
    
    int i;
    NSArray *PRarr = [[NSArray alloc] init];
    while (element = [enumerator nextObject] ) {
        NSString *tt = [[NSString alloc] initWithString:(NSString*)element] ;
        //NSLog(@"%@",tt);
        nota *n = [[nota alloc] init] ;
        if ([tt hasPrefix:@"#INI_FOR:\n"]) {
            tt = [tt substringFromIndex:10];
            tt = [tt substringToIndex:[tt length]-1];
            //NSLog(@"%@",tt);
            //n.txt = [[[NSAttributedString alloc] initWithString:tt] autorelease];
            [n setTxt:[[NSAttributedString alloc] initWithAttributedString:[self preProssText:tt oftype:@"Fortran"]]];
            [n setTypefort:false];
            [n setTypeTEX:true];
            [n setTypeComm:true];
            [n setMi_modo_actual:0];
            [n setIndice_inicial:0];
            //n.Typefort = false;
            //n.TypeTEX = true;
            //n.TypeComm = true;
            //n.Mi_modo_actual = 0;
            //n.indice_inicial = 0;
        }
        if ([tt hasPrefix:@"#INI_TEX:\n"]) {
            tt = [tt substringFromIndex:10];
            tt = [tt substringToIndex:[tt length]-1];
            //NSLog(@"%@",tt);
            n.txt = [[NSAttributedString alloc] initWithAttributedString:[self preProssText:tt oftype:@"Latex"]];
            n.Typefort = true;
            n.TypeTEX = false;
            n.TypeComm = true;
            n.Mi_modo_actual = 1;
        }
        if ([tt hasPrefix:@"#INI_TEC:\n"]) {
            tt = [tt substringFromIndex:10];
            tt = [tt substringToIndex:[tt length]-1];
            //NSLog(@"%@",tt);
            n.txt = [[NSAttributedString alloc] initWithString:tt];
            n.Typefort = true;
            n.TypeTEX = true;
            n.TypeComm = true;
            n.Mi_modo_actual = 2;
        }
        if ([tt hasPrefix:@"#INI_INV:\n"]) {
            tt = [tt substringFromIndex:10];
            tt = [tt substringToIndex:[tt length]-1];
            //NSLog(@"%@",tt);
            n.txt = [[NSAttributedString alloc] initWithString:tt];
            n.Typefort = true;
            n.TypeTEX = true;
            n.TypeComm = false;
            n.Mi_modo_actual = 3;
        }
        if ([tt hasPrefix:@"#printables,"]) {
            tt = [tt substringFromIndex:12];
            //NSLog(@"%@",tt);
            PRarr = [tt componentsSeparatedByString:@","]; //sólo esperamos un bloque de breakpoints
        } else if ([tt hasPrefix:@"BPs,"]) {
            tt = [tt substringFromIndex:4];
            //NSLog(@"%@",tt);
            NSArray *BParr = [[NSArray alloc] init];
            BParr = [tt componentsSeparatedByString:@","]; //sólo esperamos un bloque de breakpoints
            [self setBPs:BParr];
        } else if ([tt hasPrefix:@"l_compilador:"]) {
            tt = [tt substringFromIndex:13];
            lineaCompilador = [[NSString alloc] initWithString:tt];
        } else if ([tt hasPrefix:@"l_Depurador:"]) {
            tt = [tt substringFromIndex:12];
            lineaDepurador = [[NSString alloc] initWithString:tt];
        } else if ([tt hasPrefix:@"l_Argumentos:"]) {
            tt = [tt substringFromIndex:13];
            lineaArgumentos = [[NSString alloc] initWithString:tt];
        } else if ([tt hasPrefix:@"l_PreCompilador:"]) {
            tt = [tt substringFromIndex:16];
            lineaPreCompilador = [[NSString alloc] initWithString:tt];
        } else if ([tt hasPrefix:@"l_extension:"]) {
            tt = [tt substringFromIndex:12];
            lineaExtension = [[NSString alloc] initWithString:tt];
        } else if ([tt hasPrefix:@"l_runArgs:"]) {    
            tt = [tt substringFromIndex:10];
            lineaRunArgs = [[NSString alloc] initWithString:tt];
        } else if ([tt hasPrefix:@"#presets"]) {
            tt = [tt substringFromIndex:8];
            //NSLog(@"to set preset number: %@",tt);
            my_presets = [tt intValue];
            [self grabar:[NSString stringWithFormat:@"%i",my_presets] to:@"set"];
        } else {
            
            arrr = [arrr arrayByAddingObject:n]; 
        }
    }
    
    [[makeScrPrefsPanel lineaArgumentos] setStringValue:lineaArgumentos];
    [[makeScrPrefsPanel lineaCompilador] setStringValue:lineaCompilador];
    [[makeScrPrefsPanel lineaDepurador] setStringValue:lineaDepurador];
    [[makeScrPrefsPanel lineaExtension] setStringValue:lineaExtension];
    [[makeScrPrefsPanel lineaPreCompilador] setStringValue:lineaPreCompilador];
    [[makeScrPrefsPanel lineaRunArgs] setStringValue:lineaRunArgs];
    
    //asignar los printables
    if ([PRarr count] > 0) {
        for (i=0; i<[PRarr count]; i++) {
            if ([[PRarr objectAtIndex:i] intValue] == 1) {
                [(nota*)[arrr objectAtIndex:i] setPrintable:NO];
            }
        }
    }
    
    //determinar los .indice_inicial de todos
    unsigned long suma_lineas = 0;
    for (i=0; i<[arrr count]; i++) {
        nota *n = [[nota alloc] init];
        n = (nota*)[arrr objectAtIndex:i];
        if (n.Mi_modo_actual == 0) {
            // es un fortran
            unsigned long letra = 0;
            unsigned long numberOfLines = 0;
            unsigned long stringLength = [[[n txt]string] length];
            do {
                letra = NSMaxRange([[[n txt]string] lineRangeForRange:NSMakeRange(letra, 0)]);
                numberOfLines++;
            } while (letra < stringLength);
            suma_lineas = suma_lineas + numberOfLines;
            n.NoDeLineas_reciente = [[NSNumber alloc] initWithUnsignedLong:numberOfLines];
            //[n setNoDeLineas_reciente:[NSNumber numberWithUnsignedLong:numberOfLines]];
            n.indice_inicial = suma_lineas;
        }
    }
    
    
    //NSLog(@"se cargaron %lu elementos",[arrr count]);
    [self setAWAKE:arrr];
    [AWAKE retain];
    
    return YES;
    
    
}

-(void)grabar:(NSString*)linea to:(NSString*)key {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *ruta = NSHomeDirectory();
    ruta = [ruta stringByAppendingString:@"/.scifex/RunPrefs.plist"];
    if ([fm isWritableFileAtPath:ruta]) {
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithContentsOfFile:ruta];
        [info setObject:linea forKey:key];
        [info writeToFile:ruta atomically:NO];
        [fm setAttributes:[NSDictionary dictionaryWithObject:[NSDate date] forKey:NSFileModificationDate] ofItemAtPath:ruta error:nil];
    }
}

-(void)awakeFromNib {    
    [ARRAYcontroller addObserver:self forKeyPath:@"selectionIndexes" options:NSKeyValueObservingOptionNew context:nil];
    
    [scrollView setPostsBoundsChangedNotifications:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrolled:) 
                                                 name:NSViewBoundsDidChangeNotification 
                                               object:[[scrollView subviews] objectAtIndex:0]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(GotoWarningLine:) 
                                                 name:@"GotoWarningLine" 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateNota_Marcador:) 
                                                 name:@"updateNota_marker" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(printVariable:) 
                                                 name:@"printVar" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateSpripts:) 
                                                 name:@"updateSpripts" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(seleccionarSiguiente:) 
                                                 name:@"selecSig" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(seleccionarAnterior:) 
                                                 name:@"selecAnt" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mostLateral:) 
                                                 name:@"mostLateral" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ocultLateral:) 
                                                 name:@"ocultLateral" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mostLateral2:) 
                                                 name:@"mostLateral2" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ocultLateral2:) 
                                                 name:@"ocultLateral2" object:nil];
    
    LineNumberVW = [[MarkerLineNumberView alloc] initWithScrollView:scrollView];
    [scrollView setVerticalRulerView:LineNumberVW];
    [scrollView setHasHorizontalRuler:NO];
    [scrollView setHasVerticalRuler:YES];
    [scrollView setRulersVisible:NO];
    [scrollView setHasHorizontalScroller:NO];
	
    num_de_lineas = [[NSNumber alloc] initWithInt:0];
    [num_de_lineas retain];
    //[txtx setFont:[NSFont userFixedPitchFontOfSize:[NSFont smallSystemFontSize]]];
    
    [TheSplitView setPosition:250 ofDividerAtIndex:0];
    [TheSplitView setPosition:TheSplitView.frame.size.width ofDividerAtIndex:1];
    [gdbSplitView setPosition:gdbSplitView.frame.size.height ofDividerAtIndex:0];
    
    id searchCell = [searchField cell];
    [searchCell setMaximumRecents:10];
    todoEldocumento = false;
}

-(void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem{
    //NSLog(@"cambió el tab seleccionado a %@", [tabViewItem label]);
    /* if ([[tabViewItem label] isEqualToString:@"preprint"]) {
     
     }   */ 
}

-(void)scrolled:(NSNotification*)notification{
    //NSLog(@"Scrolled:\n%@",[notification description]);
    if([[ARRAYcontroller selectedObjects] count] > 0) {
        nota* n = (nota*)[[ARRAYcontroller selectedObjects] objectAtIndex:0];
        if ([n Mi_modo_actual] == 0) {        
            NSNumber *n_indice_inicial = [[NSNumber alloc] initWithUnsignedLong:[n indice_inicial]];
            
            NSDictionary *Nota_marcadores = [n Nota_linesToMarkers];
            
            NSDictionary* dic = [[NSDictionary alloc] initWithObjectsAndKeys:
                                 n_indice_inicial,@"indice_inicial_en_seccion",
                                 Nota_marcadores,@"Diccionario_de_marcadores",nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ActualizarNumLineaMarcadores" object:nil userInfo:dic];
        }  
    }
}


#pragma mark -
// Se selecciona una nota
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualTo:@"selectionIndexes"])
    {
        //True if in the array controller of the collection view really exists at least a selected object
        if([[ARRAYcontroller selectedObjects] count] > 0)
        {
            nota *n = (nota*)[[ARRAYcontroller selectedObjects] objectAtIndex:0];
            // titulo
            NSString * tit = [[NSString alloc] initWithString:[[n.txt string] substringToIndex: MIN(35,[[n.txt string] length] )]];
            if ([tit rangeOfString:@"\n"].length > 0) {
                tit = [tit substringToIndex:[tit rangeOfString:@"\n"].location ];
            }
            tit = [tit stringByReplacingOccurrencesOfString:@"  " withString:@""];
            tit = [tit stringByAppendingString:@"..."];
            NSString *tipo = [[NSString alloc] initWithString:@"Fortran"];
            if ([n Mi_modo_actual] != 0) {
                tipo = [self syntaxDefinitionFilename];
            }
            if (tit != nil || tipo != nil) {
                NSAttributedString *at = [[NSAttributedString alloc] initWithString:tit];
                at = [self preProssText:tit oftype:tipo];
                if (at != nil) {
                    NSTextView* tv = [[NSTextView alloc] init];
                    [[tv textStorage] setAttributedString:at];
                    
                    [[tv textStorage] enumerateAttributesInRange:NSMakeRange(0, [[tv textStorage] length]) 
                                                         options:0 
                                                      usingBlock:^(NSDictionary *attributesDictionary,
                                                                   NSRange range,
                                                                   BOOL *stop)
                     {
#pragma unused(stop)
                         NSFont *font = [attributesDictionary objectForKey:NSFontAttributeName];
                         if (font) {
                             [[tv textStorage] removeAttribute:NSFontAttributeName range:range];
                             font = [[NSFontManager sharedFontManager] convertFont:font toSize:[font pointSize] - 3];
                             [[tv textStorage] addAttribute:NSFontAttributeName value:font range:range];
                         }
                     }];
                    at = [tv attributedString];
                }
                [n setATtitle:at];
            }
            [n setTitle:tit];
            
            long indice_actual = [[ARRAYcontroller arrangedObjects] indexOfObject:n];
            modo_seleccionado = [(nota*)[[ARRAYcontroller arrangedObjects] objectAtIndex:indice_actual] Mi_modo_actual];
            //NSLog(@"Modo: %d",modo_seleccionado);
            //NSLog(@"Selected objects: %@", [[(nota*)[[ARRAYcontroller selectedObjects] objectAtIndex:0] txt] string]);
            
            long i;
            //NSLog(@"\n son: %lu",[[ARRAYcontroller arrangedObjects] count]);
            for (i=0; i<[[ARRAYcontroller arrangedObjects] count]; i++) {
                nota *n_i = (nota*)[[ARRAYcontroller arrangedObjects] objectAtIndex:i];
                [n_i setResaltar:false];
            }
            [n setResaltar:true];
            if (n.printable) {
                [OpcionesNotaImprimir setState:0];
            } else {
                [OpcionesNotaImprimir setState:1];
            }
            
            
            if (modo_seleccionado == 0) {
                //es un fortran, debemos preparar los markers nuevos.
                
                
                [txtx setContinuousSpellCheckingEnabled:FALSE];
                
                
                //[(nota*)[[ARRAYcontroller arrangedObjects] objectAtIndex:indice_actual] Nota_linesToMarkers]
                
                //es un fortran, recalculamos el indice inicial por si las moscas
                long j;
                unsigned long suma_lineas = 0;
                
                for (j=0; j<indice_actual; j++) {
                    nota* nota_actual = (nota*)[[ARRAYcontroller arrangedObjects] objectAtIndex:j];
                    if ([nota_actual Mi_modo_actual] == 0) {
                        // es un fortran
                        unsigned long letra = 0;
                        unsigned long numberOfLines = 0;
                        unsigned long stringLength = [[[nota_actual txt]string] length];
                        do {
                            letra = NSMaxRange([[[nota_actual txt]string] lineRangeForRange:NSMakeRange(letra, 0)]);
                            numberOfLines++;
                        } while (letra < stringLength);
                        suma_lineas = suma_lineas + numberOfLines;
                    }
                }
                if (suma_lineas == 0) {
                    [n setIndice_inicial:0];
                } else {
                    [n setIndice_inicial:suma_lineas];
                }
                
                [self turnOffWrapping:txtx];
                /*
                 [(nota*)[[ARRAYcontroller arrangedObjects] objectAtIndex:indice_actual] setIndice_inicial:suma_lineas];
                 
                 {
                 unsigned long letra = 0;
                 unsigned long numberOfLines = 0;
                 unsigned long stringLength = [[[n txt]string] length];
                 
                 NSLog(@"Era: %f",[L_vertical bounds].origin.x);
                 
                 do {
                 letra = NSMaxRange([[[n txt]string] lineRangeForRange:NSMakeRange(letra, 0)]);
                 numberOfLines++;
                 } while (letra < stringLength);
                 
                 NSRect coord_linea;
                 CGFloat pos_x = 71;
                 coord_linea = [L_vertical bounds];
                 if (suma_lineas + numberOfLines >=100) {
                 //[L_vertical bounds].origin.x = 79;
                 pos_x = 90;
                 } else {
                 // [L_vertical bounds].origin.x = 71;
                 pos_x = 71;
                 }
                 //[L_vertical setBounds:NSMakeRect(pos_x, coord_linea.origin.y, coord_linea.size.width, coord_linea.size.height)];
                 
                 } */
                //NSLog(@"debe ser: %f",[L_vertical bounds].origin.x);
                [scrollView setRulersVisible:YES];
                [L_vertical setHidden:NO];
                [L_vertical_final setHidden:NO];
                
                
                NSNumber *n_indice_inicial = [[NSNumber alloc] initWithUnsignedLong:[n indice_inicial]];
                
                NSDictionary *Nota_marcadores = [n Nota_linesToMarkers];
                
                NSDictionary* dic = [[NSDictionary alloc] initWithObjectsAndKeys:
                                     n_indice_inicial,@"indice_inicial_en_seccion",
                                     Nota_marcadores,@"Diccionario_de_marcadores", nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ActualizarNumLineaMarcadores" object:nil userInfo:dic];
                
                
                
                
                //[L_vertical setNeedsDisplay:YES];
                
                /*
                 NSNumber *n_indice_inicial = [[NSNumber alloc] initWithUnsignedLong:suma_lineas];
                 NSDictionary* dic = [[NSDictionary alloc] initWithObjectsAndKeys:n_indice_inicial,@"indice_inicial_en_seccion", nil];
                 [scrollView setRulersVisible:YES];
                 [[NSNotificationCenter defaultCenter] postNotificationName:@"ActualizarNumLineaMarcadores" object:nil userInfo:dic];
                 */
            } else {
                [scrollView setRulersVisible:NO];
                [L_vertical setHidden:YES];
                [L_vertical_final setHidden:YES];
                [self turnOnWrapping:txtx];
                
                [txtx setContinuousSpellCheckingEnabled:TRUE];
                
                //                n.update_me=NO;
            }
            NSRange ra = n.lastvisibleRange;
            if (ra.length > 0) {
                [self goToCharacter:(int)NSMaxRange(ra)];
            }
            
        }
        else
        {
            NSLog(@"Observer called but no objects where selected. Selecting last one");
            NSUInteger cant = [[ARRAYcontroller arrangedObjects] count];
            [ARRAYcontroller setSelectionIndex:cant-1];
            
        }
    }
}

-(void)updateNota_Marcador:(NSNotification*)notification{
    //NSDictionary *dic = [[NSDictionary alloc] initWithObjectsAndKeys:[linesToMarkers copy],@"marcadores", nil];
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"updateNota_marker" object:nil userInfo:dic];
    
    NSDictionary * dic = [[NSDictionary alloc] initWithDictionary: (NSDictionary*)[[notification userInfo]objectForKey:@"marcadores"]];
    //NSLog(@"%@",dic);
    
    [(nota*)[[ARRAYcontroller selectedObjects] objectAtIndex:0] setNota_linesToMarkers:dic];
    
    if ([gdbtask isRunning]) {
        NSData* data = [[NSData alloc] init];
        data = [@"delete\n" dataUsingEncoding:NSUTF8StringEncoding];
        [stdinHandle writeData:data];
        
        //ahora agregamos los breakpoints
        int i;
        for (i = 0; i < [[ARRAYcontroller arrangedObjects] count]; i++) {
            nota* n = (nota*)[[ARRAYcontroller arrangedObjects] objectAtIndex:i];
            if ([n Mi_modo_actual] == 0) {
                NSEnumerator *UnMarcador = [[n Nota_linesToMarkers] keyEnumerator];
                NSNumber *Key_en_nota = nil;
                unsigned long num_lin_inicial = [n indice_inicial];
                while (Key_en_nota = [UnMarcador nextObject]) {
                    data = [[NSString stringWithFormat:@"break %i\n",(int)num_lin_inicial +  [Key_en_nota intValue] +1] dataUsingEncoding:NSUTF8StringEncoding];
                    //NSLog(@"b: %@", [data description]);
                    [stdinHandle writeData:data];
                }
            }
        }
    }
}


-(void)updateSpripts:(NSNotification*)notification{
    lineaArgumentos = [[makeScrPrefsPanel lineaArgumentos] stringValue];
    lineaCompilador = [[makeScrPrefsPanel lineaCompilador] stringValue];
    lineaDepurador = [[makeScrPrefsPanel lineaDepurador] stringValue];
    lineaExtension = [[makeScrPrefsPanel lineaExtension] stringValue];
    lineaPreCompilador = [[makeScrPrefsPanel lineaPreCompilador] stringValue];
    lineaRunArgs = [[makeScrPrefsPanel lineaRunArgs] stringValue];
    
    //NSLog(@"updated:\n%@\n%@\n%@\n%@\n%@\n",lineaCompilador,
    //     lineaDepurador,lineaArgumentos,
    //     lineaPreCompilador,lineaExtension);
    
    //NSLog(@"updated scripts");
}

-(CGFloat)splitView:(NSSplitView *)splitView 
constrainMinCoordinate:(CGFloat)proposedMinimumPosition 
        ofSubviewAt:(NSInteger)dividerIndex {
    if ([splitView isEqualTo:TheSplitView]) {
        if (dividerIndex == 0) {
            return proposedMinimumPosition + 12.0;
        }
        //        if ([LayoutVerticalScroller isHidden]) {
        //        } else {
        //            return proposedMinimumPosition + 27.0;
        //        }
    }
    return proposedMinimumPosition;
    
}

-(CGFloat)splitView:(NSSplitView *)splitView 
constrainMaxCoordinate:(CGFloat)proposedMaximumPosition 
        ofSubviewAt:(NSInteger)dividerIndex {
    if ([splitView isEqualTo:TheSplitView]) {
        if (dividerIndex == 0) {
            return 183;
        }
        //        if ([LayoutVerticalScroller isHidden]) {
        
        //        } else {
        //            return 183 + 15;
        //        }
    }
    return proposedMaximumPosition;
}

-(void)textStorageDidProcessEditing:(NSNotification *)notification {
    NSLog(@"algo pasó");
}


-(void) fdf: (NSNotification*)noti {
    if([[ARRAYcontroller selectedObjects] count] > 0) {
        nota *n = (nota*)[[ARRAYcontroller selectedObjects] objectAtIndex:0];
        // titulo
        NSString * tit = [[NSString alloc] init];
        if ([n.txt string] != nil) {
            tit = [n.txt string];
            tit = [tit substringToIndex: MIN(35,[[n.txt string] length] )];
            
            tit = [tit stringByReplacingOccurrencesOfString:@"  " withString:@""];
            
            if ([tit rangeOfString:@"\n"].length > 0 && [tit length] > 2 ) {
                tit = [tit substringToIndex:[tit rangeOfString:@"\n"].location ];
            }
            tit = [tit stringByAppendingString:@"..."];
            NSString *tipo = [[NSString alloc] initWithString:@"Fortran"];
            if ([n Mi_modo_actual] != 0) {
                tipo = [self syntaxDefinitionFilename];
            }
            if (tit != nil || tipo != nil || ![tit  isEqual: @""]) {
                NSAttributedString *at = [[NSAttributedString alloc] initWithString:tit];
                at = [self preProssText:tit oftype:tipo];
                if (at != nil) {
                    //--
                    NSTextView* tv = [[NSTextView alloc] init];
                    [[tv textStorage] setAttributedString:at];
                    [[tv textStorage] enumerateAttributesInRange:NSMakeRange(0, [[tv textStorage] length]) 
                                                         options:0 
                                                      usingBlock:^(NSDictionary *attributesDictionary,
                                                                   NSRange range,
                                                                   BOOL *stop)
                     {
#pragma unused(stop)
                         NSFont *font = [attributesDictionary objectForKey:NSFontAttributeName];
                         if (font) {
                             [[tv textStorage] removeAttribute:NSFontAttributeName range:range];
                             font = [[NSFontManager sharedFontManager] convertFont:font toSize:[font pointSize] - 3];
                             [[tv textStorage] addAttribute:NSFontAttributeName value:font range:range];
                         }
                     }];
                    at = [tv attributedString];
                    
                }
                //--
                [n setATtitle:at];
                
            }
            [n setTitle:tit];
        }
    }
    
    //NSLog(@"%@",[noti description]);
    // NSDictionary* dic = [[NSDictionary alloc] initWithDictionary:(NSDictionary*)[noti userInfo]];
    //NSLog(@"%@",[dic description]);
    
    //NSLog(@"%@",[[dic objectForKey:@"NSOldSelectedCharacterRange"] description]);
    
    // NSUInteger lastloc = [[dic objectForKey:@"NSOldSelectedCharacterRange"] rangeValue].location;
    //NSLog(@"last loc: %lu",lastloc);
    
    //NSLog(@"%@", [[dic objectForKey:@"NSOldSelectedCharacterRange"] rangeValue].location);
    //nota*n = (nota*)[[ARRAYcontroller selectedObjects] objectAtIndex:0];
    //     if (n.update_me) {
    //         n.lastvisibleRange = lastloc;
    //         //NSLog(@"at loc: %lu ",n.lastvisibleRange);
    //     }
}

-(void) seleccionarSiguiente: (NSNotification*)noti {
    if ([[ARRAYcontroller selectedObjects] count] > 0) {
        NSUInteger ini = [ARRAYcontroller selectionIndex];
        if (ini < [[ARRAYcontroller arrangedObjects] count]) {
            [ARRAYcontroller selectNext:nil]; 
        }
    }
}
-(void) seleccionarAnterior: (NSNotification*)noti {
    if ([[ARRAYcontroller selectedObjects] count] > 0) {
        NSUInteger ini = [ARRAYcontroller selectionIndex];
        if (ini > 0) {
            [ARRAYcontroller selectPrevious:nil];
        }
    }
}

-(void) mostLateral: (NSNotification*)noti {
    //las animaciones se ven bonitas.
    {
        NSView *left = [[TheSplitView subviews]objectAtIndex:0];
        //        NSView *center = [[TheSplitView subviews]objectAtIndex:1];
        NSView *right = [[TheSplitView subviews]objectAtIndex:2];
        
        
        NSMutableDictionary *animL = [NSMutableDictionary dictionaryWithCapacity:2];
        [animL setObject:left forKey:NSViewAnimationTargetKey];
        NSRect newLeftSubViewFrame = left.frame;
        newLeftSubViewFrame.size.width = 183.0f;
        [animL setObject:[NSValue valueWithRect:newLeftSubViewFrame] forKey:NSViewAnimationEndFrameKey];
        
        NSMutableDictionary *animR = [NSMutableDictionary dictionaryWithCapacity:2];
        [animR setObject:right forKey:NSViewAnimationTargetKey];
        NSRect newRightSubViewFrame = right.frame;
        [animR setObject:[NSValue valueWithRect:newRightSubViewFrame] forKey:NSViewAnimationEndFrameKey];
        
        NSViewAnimation *Animate = [[NSViewAnimation alloc] 
                                    initWithViewAnimations:[NSArray arrayWithObjects: animL,animR, nil]];        
        
        [Animate setDuration:0.40f];
        [Animate startAnimation];
        //        [TheSplitView adjustSubviews];
        [TheSplitView setNeedsDisplay:YES];
    }
}

-(void) ocultLateral: (NSNotification*)noti {
    //las animaciones se ven bonitas.
    {
        NSView *left = [[TheSplitView subviews]objectAtIndex:0];
        //        NSView *center = [[TheSplitView subviews]objectAtIndex:1];
        NSView *right = [[TheSplitView subviews]objectAtIndex:2];
        
        
        NSMutableDictionary *animL = [NSMutableDictionary dictionaryWithCapacity:2];
        [animL setObject:left forKey:NSViewAnimationTargetKey];
        NSRect newLeftSubViewFrame = left.frame;
        newLeftSubViewFrame.size.width = 12.0f;
        [animL setObject:[NSValue valueWithRect:newLeftSubViewFrame] forKey:NSViewAnimationEndFrameKey];
        
        NSMutableDictionary *animR = [NSMutableDictionary dictionaryWithCapacity:2];
        [animR setObject:right forKey:NSViewAnimationTargetKey];
        NSRect newRightSubViewFrame = right.frame;
        [animR setObject:[NSValue valueWithRect:newRightSubViewFrame] forKey:NSViewAnimationEndFrameKey];
        
        NSViewAnimation *Animate = [[NSViewAnimation alloc] 
                                    initWithViewAnimations:[NSArray arrayWithObjects: animL,animR, nil]];        
        
        [Animate setDuration:0.40f];
        [Animate startAnimation];
        //        [TheSplitView adjustSubviews];
        [TheSplitView setNeedsDisplay:YES];
    }
}
-(void) mostLateral2: (NSNotification*)noti {
    //las animaciones se ven bonitas.
    {
        NSView *left = [[TheSplitView subviews]objectAtIndex:0];
        //        NSView *center = [[TheSplitView subviews]objectAtIndex:1];
        NSView *right = [[TheSplitView subviews]objectAtIndex:2];
        
        
        NSMutableDictionary *animL = [NSMutableDictionary dictionaryWithCapacity:2];
        [animL setObject:left forKey:NSViewAnimationTargetKey];
        NSRect newLeftSubViewFrame = left.frame;
        [animL setObject:[NSValue valueWithRect:newLeftSubViewFrame] forKey:NSViewAnimationEndFrameKey];
        
        NSMutableDictionary *animR = [NSMutableDictionary dictionaryWithCapacity:2];
        [animR setObject:right forKey:NSViewAnimationTargetKey];
        NSRect newRightSubViewFrame = right.frame;
        newRightSubViewFrame.size.width = 500.0f;
        [animR setObject:[NSValue valueWithRect:newRightSubViewFrame] forKey:NSViewAnimationEndFrameKey];
        
        NSViewAnimation *Animate = [[NSViewAnimation alloc] 
                                    initWithViewAnimations:[NSArray arrayWithObjects: animL,animR, nil]];        
        
        [Animate setDuration:0.40f];
        [Animate startAnimation];
        //        [TheSplitView adjustSubviews];
        [TheSplitView setNeedsDisplay:YES];
    }
}

-(void) ocultLateral2: (NSNotification*)noti {
    //las animaciones se ven bonitas.
    {
        NSView *left = [[TheSplitView subviews]objectAtIndex:0];
        //        NSView *center = [[TheSplitView subviews]objectAtIndex:1];
        NSView *right = [[TheSplitView subviews]objectAtIndex:2];
        
        
        NSMutableDictionary *animL = [NSMutableDictionary dictionaryWithCapacity:2];
        [animL setObject:left forKey:NSViewAnimationTargetKey];
        NSRect newLeftSubViewFrame = left.frame;
        [animL setObject:[NSValue valueWithRect:newLeftSubViewFrame] forKey:NSViewAnimationEndFrameKey];
        
        NSMutableDictionary *animR = [NSMutableDictionary dictionaryWithCapacity:2];
        [animR setObject:right forKey:NSViewAnimationTargetKey];
        NSRect newRightSubViewFrame = right.frame;
        newRightSubViewFrame.size.width = 0.0f;
        [animR setObject:[NSValue valueWithRect:newRightSubViewFrame] forKey:NSViewAnimationEndFrameKey];
        
        NSViewAnimation *Animate = [[NSViewAnimation alloc] 
                                    initWithViewAnimations:[NSArray arrayWithObjects: animL,animR, nil]];        
        
        [Animate setDuration:0.40f];
        [Animate startAnimation];
        //        [TheSplitView adjustSubviews];
        [TheSplitView setNeedsDisplay:YES];
    }
}
#pragma mark -
#pragma mark search
// -------------------------------------------------------------------------------
//	control:textView:completions:forPartialWordRange:indexOfSelectedItem:
//
//	Use this method to override NSFieldEditor's default matches (which is a much bigger
//	list of keywords).  By not implementing this method, you will then get back
//	NSSearchField's default feature.
// -------------------------------------------------------------------------------
- (NSArray *)control:(NSControl *)control textView:(NSTextView *)textView completions:(NSArray *)words
 forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(int*)index
{
    NSMutableArray*	matches = NULL;
    NSString*		partialString;
    NSArray*		keywords;
    unsigned long int	i,count;
    NSString*		string;
    
    partialString = [[textView string] substringWithRange:charRange];
    keywords      = recentSearches;
    count         = [keywords count];
    matches       = [NSMutableArray array];
    
    // find any match in our keyword array against what was typed -
	for (i=0; i< count; i++)
	{
        string = [keywords objectAtIndex:i];
        if ([string rangeOfString:partialString
						  options:NSAnchoredSearch | NSCaseInsensitiveSearch
							range:NSMakeRange(0, [string length])].location != NSNotFound)
		{
            [matches addObject:string];
            
        }
    }
    [matches sortUsingSelector:@selector(compare:)];
    
	return matches;
}

// -------------------------------------------------------------------------------
//	controlTextDidChange:
//
//	The text in NSSearchField has changed, try to attempt type completion.
// -------------------------------------------------------------------------------
- (void)controlTextDidChange:(NSNotification *)obj
{
	NSTextView* textView = [[obj userInfo] objectForKey:@"NSFieldEditor"];
    
    if (!completePosting && !commandHandling)	// prevent calling "complete" too often
	{
        completePosting = YES;
        [textView complete:nil];
        completePosting = NO;
        punto_ant = 0;
    }
}
// -------------------------------------------------------------------------------
//	control:textView:commandSelector
//
//	Handle all commend selectors that we can handle here
// -------------------------------------------------------------------------------
- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector
{
    BOOL result = NO;
	
	if ([textView respondsToSelector:commandSelector])
	{
        commandHandling = YES;
        [textView performSelector:commandSelector withObject:nil];
        commandHandling = NO;
        result = YES;
        
        //agregar a las busqeudas recientes si no está ya.
        int i;
        NSString *string = [textView string];
        
        //NSLog(@"searching: %@\n",string);
        bool estuvo = NO;
        for (i=0; i< [recentSearches count]; i++) {
            //NSLog(@"comparing contra: %@",[recentSearches objectAtIndex:i]);
            if ([string isEqualToString:[recentSearches objectAtIndex:i]]) {
                estuvo = YES;
                break;
            }
        }
        if (estuvo == NO && ![string isEqualToString:@""]) {
            [recentSearches addObject:[textView string]];
            //NSLog(@"added %@ to recentSearches\n",string);
        }
        
        
        //resaltar en el texto los resultados, si los hay.
        NSMutableArray *coincidencias = [[NSMutableArray alloc] init];
        NSString *texto = [[NSString alloc] init];
        if (todoEldocumento) {
            NSDictionary *textos_dic = [self textos_de_salida_para_el_arreglo:[ARRAYcontroller arrangedObjects]];
            if (textos_dic == nil) {
                NSLog(@"\n\nsorry");
                result = NO;
                return result;
            }
            texto = [textos_dic objectForKey:@"t_fort"];
        } else {
            texto = [[(nota*)[[ARRAYcontroller selectedObjects] objectAtIndex:0] txt] string];
        }
        
        //NSLog(@"buscando %@ dentro de : \n%@\n",string,texto);
        
        int k;
        NSRange res;
        for (k=0; k<[texto length]; k = MIN((int)[texto length], k)+1 ) {
            res = [texto rangeOfString:string 
                               options:NSCaseInsensitiveSearch 
                                 range:NSMakeRange(k, [texto length]-k)];
            if (res.location != NSNotFound) {
                //si hay, guradamos donde encontrarlo y buscamos de nuevo
                NSValue *v = [NSValue valueWithRange:res];
                
                [coincidencias addObject:v];
                //NSLog(@"Encontrado en: %lu \n",res.location);
                k = (int)res.location;
            } else {
                break;
            }
        }
        
        for (NSValue *v in coincidencias) {
            NSRange range = [v rangeValue];
            if (range.length > 0) {
                [[txtx layoutManager] addTemporaryAttributes:[NSDictionary dictionaryWithObject:[NSColor yellowColor] forKey:NSBackgroundColorAttributeName]
                                           forCharacterRange:range];
                [[txtx layoutManager] addTemporaryAttributes:[NSDictionary dictionaryWithObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName] forCharacterRange:range];
            }
            
        }
        
        
        //nos movemos a la primera coincidencia
        //transformar el range a un line number
        //sacar un indice de la coincidencia y resetarlo cada que se modifique la busqueda
        //ciclar dentro de las coincidencias
        NSRange range0;
        if (punto_ant >= [coincidencias count]) {
            punto_ant = 0; 
        }
        range0 = [[coincidencias objectAtIndex:punto_ant] rangeValue];
        
        NSRange ra;
        unsigned long numberOfLines = 0;
        unsigned long ind_letra = 0;
        do {
            ra = [texto lineRangeForRange:NSMakeRange(ind_letra, 0)];
            ind_letra = NSMaxRange(ra);
            numberOfLines++;
            
        } while (ind_letra < range0.location);
        
        if (todoEldocumento) {
            [self goToLine:(int)numberOfLines];
            //todoEldocumento = false;
        } else {
            [self toToLineinThisTxt:(int)numberOfLines];
        }
        [txtx setSelectedRange:range0];
        punto_ant++;
    }
	
    return result;
} 

- (IBAction)sheetDoneButtonAction:(id)sender{
    [[txtx layoutManager] removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:NSMakeRange(0, [[txtx string]length])];
    [[txtx layoutManager] removeTemporaryAttribute:NSForegroundColorAttributeName forCharacterRange:NSMakeRange(0, [[txtx string]length])];
    punto_ant = 0;
}


#pragma mark -
#pragma mark funciones textos

-(BOOL) pedirArchivo:(NSString*)mensaje {
    NSSavePanel *panel = [NSSavePanel savePanel];
    [panel setMessage:mensaje];
    [panel setCanCreateDirectories:YES];
    [panel setExtensionHidden:YES];
    
    nombreArchivo = nil;
    
    NSURL *url_file_name = [self fileURL];
    if ([url_file_name isNotEqualTo:nil] && [url_file_name isFileURL]) {
        //hay un nombre de archivo asociado
        
        nombreArchivo = [[[url_file_name absoluteString] stringByReplacingOccurrencesOfString:@"file://localhost" withString:@""] stringByReplacingOccurrencesOfString:@".scif" withString:@""];
        directorioBase = [[[url_file_name URLByDeletingLastPathComponent] absoluteString] stringByReplacingOccurrencesOfString:@"file://localhost" withString:@""];
        NSLog(@"\n\nNom arch: %@\nDir base: %@",nombreArchivo,directorioBase);
        
        return YES;
    }
    return NO;
    
}

-(bool) guardarTexto:(NSString*)t en:(NSString*)ruta{
    //NSLog(@"\n\n\t\tEscribiendo archivo en:\n\t\t%@",ruta);
    //NSLog(@"\n\t\tWe will save this:\n\n%@",t);    
    
    FILE* f_log = fopen([[ruta stringByReplacingOccurrencesOfString:@"file://" withString:@""] cStringUsingEncoding:NSUTF8StringEncoding],"w");
    fprintf(f_log, "%s\n", [t cStringUsingEncoding:NSUTF8StringEncoding]);
    fflush(f_log);
    fclose(f_log);
    
    //NSLog(@"\n\t\ttermiando escribir.\n");
    return TRUE;
}

-(BOOL) guardadoTextoFortran:(NSString*)textoFortran TextoLatex:(NSString*)textoLatex {
    //hace falta guardar primero el archivo o recuperar el nombre desde el nombre de archivo guardado
    NSURL *url_file_name = [self fileURL];
    if (url_file_name == Nil) {
        
        return false;
    }
    if (url_file_name != Nil) {
        //hay un nombre de archivo asociado
        
        nombreArchivo = [[[url_file_name absoluteString] stringByReplacingOccurrencesOfString:@"file://localhost" withString:@""] stringByReplacingOccurrencesOfString:@".scif" withString:@""];
        directorioBase = [[[url_file_name URLByDeletingLastPathComponent] absoluteString] stringByReplacingOccurrencesOfString:@"file://localhost" withString:@""];
        //NSLog(@"\n\nNom arch: %@\nDir base: %@",nombreArchivo,directorioBase);
        nombreArchivo = [nombreArchivo stringByReplacingOccurrencesOfString:@"file://" withString:@""];
        directorioBase = [directorioBase stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    } else {
        return false;
    }
    
    //NSLog(@"guardado");
    //nombres
    nombreArchivoTeX = nombreArchivo;
    if (![nombreArchivo hasSuffix:@".tex"]) {
        nombreArchivoTeX = [nombreArchivo stringByAppendingString:@".tex"];
    }
    nombreArchivoFORTRAN = nombreArchivo;
    if (![nombreArchivo hasSuffix:@".f"] || 
        ![nombreArchivo hasSuffix:@".for"] ||
        ![nombreArchivo hasSuffix:@".f90"] ||
        ![nombreArchivo hasSuffix:@".f95"]) {
        
        //        NSString *ruta = NSHomeDirectory();
        //        ruta = [ruta stringByAppendingString:@"/.scifex/RunPrefs.plist"];
        //        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithContentsOfFile:ruta];
        //int preset = [[info objectForKey:@"set"] intValue];
        //[info objectForKey:[NSString stringWithFormat:@"extension - %i",_preset]]
        
        //nombreArchivoFORTRAN = [nombreArchivo stringByAppendingString:[info objectForKey:[NSString stringWithFormat:@"extension - %i", preset]]];
        //NSLog(@"line: %@",lineaExtension);
        nombreArchivoFORTRAN = [nombreArchivo stringByAppendingString:lineaExtension];
    }
    nombreOUTput = [nombreArchivo stringByAppendingString:@".out"];
    if (![nombreArchivo hasSuffix:@".scif"]) {
        nombreArchivo = [nombreArchivo stringByAppendingString:@".scif"];
    } else {
        nombreOUTput = [[nombreArchivo substringToIndex:[nombreArchivo length]-5] stringByAppendingString:@".out"];
    }
    
    [nombreOUTput retain];
    [nombreArchivoTeX retain];
    [nombreArchivoFORTRAN retain];
    [nombreArchivo retain];
    [directorioBase retain];
    
    
    if ([self guardarTexto:textoLatex en:nombreArchivoTeX]) {
        //NSLog(@"LATEX guardado con éxito en %@", nombreArchivoTeX);
    } else {
        return FALSE;
    }
    if ([self guardarTexto:textoFortran en:nombreArchivoFORTRAN]) {
        //NSLog(@"FORTRAN guardado con éxito en %@", nombreArchivoFORTRAN);
    }
    return TRUE;
}

-(NSDictionary*)textos_de_salida_para_el_arreglo:(NSArray*)ARR{
    if ([ARR count] < 1) {
        NSLog(@"No hay cosas");
        return nil;
    } else {
        //NSLog(@"Son %lu",[ARR count]);
    }
    int i;
    int j = 0; //contador para fortran code
    int modo_i;
    NSString *textoFortran = [[NSString alloc] initWithString:@""];
    NSString *textoTodo = [[NSString alloc] initWithString:@"C Made with sciFxT\n"];
    NSString *textoLatex = [[NSString alloc] initWithString:@"\%% LatexFile made with sciFxt\n"];
    
    for (i = 0; i < [ARR count]; i++) {
        //algunos no se imprimen:
        bool print = [(nota*)[ARR objectAtIndex:i] printable];
        
        modo_i = [(nota*)[ARR objectAtIndex:i] Mi_modo_actual];
        //hay que quitarle el formato
        NSAttributedString *txt = [(nota*)[ARR objectAtIndex:i] txt];
        NSData *txt_data = [[txt string] dataUsingEncoding:NSMacOSRomanStringEncoding allowLossyConversion:YES];
        NSString *txt_str = [[NSString alloc] initWithData:txt_data encoding:NSMacOSRomanStringEncoding];
        //NSLog(@"%@",txt_str);
        if (txt_str != Nil) 
        {
            // si es fortran juntar y compilar:
            if (modo_i == 0) 
            {
                textoFortran = [textoFortran stringByAppendingString:txt_str];
                textoFortran = [textoFortran stringByAppendingString:@"\n"];
                j = j+1;
                
                textoTodo = [textoTodo stringByAppendingString:@"\n#INI_FOR \n"];
                textoTodo = [textoTodo stringByAppendingString:txt_str];
                textoTodo = [textoTodo stringByAppendingString:@"\n#FIN_FOR \n"];
                if (print) {
                    textoLatex = [textoLatex stringByAppendingString:@"\n\\begingroup\n\\fontsize{10pt}{12pt}\n\\selectfont\n\\definecolor{shadecolor}{rgb}{0.925,0.925,0.925}\n\\begin{shaded}\n\\begin{verbatim}\n"];
                    textoLatex = [textoLatex stringByAppendingString:txt_str];
                    textoLatex = [textoLatex stringByAppendingString:@"\n\\end{verbatim}\n\\end{shaded}\n\\endgroup\n"];
                }
            }
            if (modo_i == 1) {
                textoTodo = [textoTodo stringByAppendingString:@"\n#INI_TEX \n"];
                textoTodo = [textoTodo stringByAppendingString:txt_str];
                textoTodo = [textoTodo stringByAppendingString:@"\n#FIN_TEX \n"];
                if (print) {
                    textoLatex = [textoLatex stringByAppendingString:txt_str];
                }
            }
            if (modo_i == 2) {
                textoTodo = [textoTodo stringByAppendingString:@"\n#INI_TEC \n"];
                textoTodo = [textoTodo stringByAppendingString:txt_str];
                textoTodo = [textoTodo stringByAppendingString:@"\n#FIN_TEC \n"];
                if (print) {
                    textoLatex = [textoLatex stringByAppendingString:@"\n\\definecolor{shadecolor}{rgb}{0.2,0.2,0.2}\n\\begin{shaded}\n"];
                    textoLatex = [textoLatex stringByAppendingString:txt_str];
                    textoLatex = [textoLatex stringByAppendingString:@"\n\\end{shaded}\n"];
                }                
            }
            if (modo_i == 3) {
                textoTodo = [textoTodo stringByAppendingString:@"\n#INI_INV \n"];
                textoTodo = [textoTodo stringByAppendingString:txt_str];
                textoTodo = [textoTodo stringByAppendingString:@"\n#FIN_INV \n"];
            }
        } else {
            NSLog(@"got some troble with the strings... sorry");
            return nil;
        } 
    }
    
    textoLatex = [textoLatex stringByAppendingString:@"\n\\end{document}"];
    if (j == 0) {
        NSLog(@"Ningun bloque fue código fortran");
        //return nil;
    } else {
        //NSLog(@"%d fueron bloques de fortran",(int)j);
    }
    
    NSDictionary *OUT = [[NSDictionary alloc] initWithObjectsAndKeys:textoFortran,@"t_fort",textoLatex,@"t_late",textoTodo,@"t_todo", nil];
    return OUT;
}

- (NSRange)getViewableRange:(NSTextView *)tv{
    NSScrollView *sv = [tv enclosingScrollView];
    if(!sv) return NSMakeRange(0,0);
    NSLayoutManager *lm = [tv layoutManager];
    NSRect visRect = [tv visibleRect];
    
    NSPoint tco = [tv textContainerOrigin];
    visRect.origin.x -= tco.x;
    visRect.origin.y -= tco.y;
    
    NSRange glyphRange = [lm glyphRangeForBoundingRect:visRect
                          
                                       inTextContainer:[tv textContainer]];
    NSRange charRange = [lm characterRangeForGlyphRange:glyphRange
                         
                                       actualGlyphRange:nil];
    return charRange;
}

- (NSString*)currentHour{
    // In practice, these calls can be combined
    NSDate *now = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSHourCalendarUnit fromDate:now];
    NSString *hora = [[NSString alloc] initWithFormat:@"%li:",(long)[components hour]];
    components = [calendar components:NSMinuteCalendarUnit fromDate:now];
    hora = [hora stringByAppendingFormat:@"%li",(long)[components minute]];
    
    return hora;
}

#pragma mark -
#pragma mark ToolBAR

- (IBAction)RunStopPrint_click:(id)sender {
    switch ([RunStopPrint selectedSegment]) {
        case 0:
            [self Run_button_click:nil];
            break;
        case 1:
            [self Stop_button_click:nil];
            break;
        case 2:
            [self make_pdf:nil];
            break;
        default:
            break;
    }
}

-(void)splitThisFortranBlock:(id)sender  {
    nota *n = (nota*)[[ARRAYcontroller selectedObjects] objectAtIndex:0];
    NSUInteger ind_n = [ARRAYcontroller selectionIndex];
    nota *n_new1 = [[nota alloc] init];
    if ([n Mi_modo_actual] == 0) {
        NSRange rangoParaCompletar = [txtx rangeForUserCompletion];
        NSUInteger punto = rangoParaCompletar.location + rangoParaCompletar.length;
        //NSLog(@"spliting from %lu",punto);
        
        //es un fotran que podemos dividir
        NSString * A_string = [[[n txt] string] substringToIndex:punto];
        NSString * B_string = [[[n txt] string] substringFromIndex:punto];
        
        [n setTxt:[[NSAttributedString alloc] initWithString:A_string]];
        {
            //NSLog(@"inserting fortran");
            n_new1.txt = [[NSAttributedString alloc] initWithString:B_string];
            n_new1.Typefort = false;
            n_new1.TypeTEX = true;
            n_new1.TypeComm = true;
            n_new1.Mi_modo_actual = 0;
            
            //averiguar si hay otros antes y cuantas lineas tienen
            if ([[ARRAYcontroller arrangedObjects] count ] != 0 ) {
                //hay otros bloques antes
                long j = 0;
                unsigned long suma_lineas = 0;
                for (j = 0; j < [[ARRAYcontroller arrangedObjects] count]; j++) {
                    nota* nota_actual = (nota*)[[ARRAYcontroller arrangedObjects] objectAtIndex:j];
                    if ([nota_actual Mi_modo_actual] == 0) {
                        // es un fortran
                        unsigned long letra = 0;
                        unsigned long numberOfLines = 0;
                        unsigned long stringLength = [[[nota_actual txt]string] length];
                        do {
                            letra = NSMaxRange([[[nota_actual txt]string] lineRangeForRange:NSMakeRange(letra, 0)]);
                            numberOfLines++;
                        } while (letra < stringLength);
                        suma_lineas = suma_lineas + numberOfLines;
                        n_new1.indice_inicial = suma_lineas;
                    }
                }
                if (suma_lineas == 0) {
                    n_new1.indice_inicial = 0;
                } else {
                    //n.indice_inicial++;
                }
                
                //NSLog(@"El indice inicial de este segmento es = %lu", n_new1.indice_inicial);
            }
        }
        
        //[ARRAYcontroller addObject:n_new1];
        
        [ARRAYcontroller insertObject:n_new1 atArrangedObjectIndex:ind_n + 1];
        [TheSplitView adjustSubviews]; 
        
    }
}

-(void)splitThisLatexBlock:(id)sender {
    nota *n = (nota*)[[ARRAYcontroller selectedObjects] objectAtIndex:0];
    NSUInteger ind_n = [ARRAYcontroller selectionIndex];
    nota *n_new1 = [[nota alloc] init];
    if ([n Mi_modo_actual] == 1) {
        NSRange rangoParaCompletar = [txtx rangeForUserCompletion];
        NSUInteger punto = rangoParaCompletar.location + rangoParaCompletar.length;
        // NSLog(@"spliting from %lu",punto);
        
        //es un fotran que podemos dividir
        NSString * A_string = [[[n txt] string] substringToIndex:punto];
        NSString * B_string = [[[n txt] string] substringFromIndex:punto];
        
        [n setTxt:[[NSAttributedString alloc] initWithString:A_string]];
        {
            //NSLog(@"inserting latex");
            n_new1.txt = [[NSAttributedString alloc] initWithString:B_string];
            n_new1.Typefort = true;
            n_new1.TypeTEX = false;
            n_new1.TypeComm = true;
            n_new1.Mi_modo_actual = 1;
            n_new1.indice_inicial = 0;
            [ARRAYcontroller insertObject:n_new1 atArrangedObjectIndex:ind_n+1];
            [TheSplitView adjustSubviews];
        }
    }
}

- (IBAction)make_pdf:(id)sender {
    //sacamos un latex
    NSDictionary *textos_dic = [self textos_de_salida_para_el_arreglo:[ARRAYcontroller arrangedObjects]];
    if (textos_dic == nil) {
        NSLog(@"\n\nsorry");
        return;
    }
    NSString *textoFortran = [textos_dic objectForKey:@"t_fort"];
    NSString *textoLatex = [textos_dic objectForKey:@"t_late"];
    //NSString *textoTodo = [textos_dic objectForKey:@"t_todo"];
    
    
    
    if (![self guardadoTextoFortran:textoFortran TextoLatex:textoLatex]) {
        NSLog(@"sorry");
        return;
    }
    
    //ejecutar PDFLATEX desde fuera para evitar problemas.
    
    NSString *pdfRuta = [[NSString alloc] init];
    pdfRuta = [nombreArchivoTeX stringByReplacingOccurrencesOfString:@".tex" withString:@".pdf"];
    NSString *s = [NSString stringWithFormat:
                   @"tell application \"Terminal\" to do script \"cd / \n cd %@ \n clear \n pdflatex -output-directory %@ %@  \n exit \n\" ",directorioBase,directorioBase,nombreArchivoTeX];
    NSAppleScript *as = [[NSAppleScript alloc] initWithSource: s];
    [as executeAndReturnError:nil];
    s = [NSString stringWithFormat:@"tell application \"Terminal\" to do script \" open %@ \n exit \n\" ",pdfRuta];
    as = [[NSAppleScript alloc] initWithSource: s];
    [as executeAndReturnError:nil];
}

- (IBAction)click_makeScript:(id)sender {
    [[makeScrPrefsPanel selectedSet] setSelectedSegment:6];
    if ([makeScrPrefsPanel visible] == NO) {
        [[makeScrPrefsPanel lineaArgumentos] setStringValue:lineaArgumentos];
        [[makeScrPrefsPanel lineaCompilador] setStringValue:lineaCompilador];
        [[makeScrPrefsPanel lineaDepurador] setStringValue:lineaDepurador];
        [[makeScrPrefsPanel lineaExtension] setStringValue:lineaExtension];
        [[makeScrPrefsPanel lineaPreCompilador] setStringValue:lineaPreCompilador];
        //NSLog(@"linrunarg:%@",lineaRunArgs);
        [[makeScrPrefsPanel lineaRunArgs] setStringValue:lineaRunArgs];
        [makeScrPrefsPanel showTerm:[self windowForSheet]];
    } else {
        [makeScrPrefsPanel hideTerm:[self windowForSheet]];
    }
    
}

- (IBAction)Section_buttons_click:(id)sender {
    nota *n = [[nota alloc] init];
    //nota *m = (nota*)[[ARRAYcontroller selectedObjects] objectAtIndex:0];
    NSUInteger ind_n_actual = [ARRAYcontroller selectionIndex];
    switch ([SectionMode selectedSegment]) {
        case 0:
            //NSLog(@"inserting fortran");
            n.txt = [[NSAttributedString alloc] initWithString:@"C Fortran code...\n      "];
            n.Typefort = false;
            n.TypeTEX = true;
            n.TypeComm = true;
            n.Mi_modo_actual = 0;
            
            //averiguar si hay otros antes y cuantas lineas tienen
            if ([[ARRAYcontroller arrangedObjects] count ] != 0 ) {
                //hay otros bloques antes
                long j = 0;
                unsigned long suma_lineas = 0;
                for (j = 0; j < [[ARRAYcontroller arrangedObjects] count]; j++) {
                    nota* nota_actual = (nota*)[[ARRAYcontroller arrangedObjects] objectAtIndex:j];
                    if ([nota_actual Mi_modo_actual] == 0) {
                        // es un fortran
                        unsigned long letra = 0;
                        unsigned long numberOfLines = 0;
                        unsigned long stringLength = [[[nota_actual txt]string] length];
                        do {
                            letra = NSMaxRange([[[nota_actual txt]string] lineRangeForRange:NSMakeRange(letra, 0)]);
                            numberOfLines++;
                        } while (letra < stringLength);
                        suma_lineas = suma_lineas + numberOfLines;
                        n.indice_inicial = suma_lineas;
                    }
                }
                if (suma_lineas == 0) {
                    n.indice_inicial = 0;
                } else {
                    //n.indice_inicial++;
                }
                // NSLog(@"El indice inicial de este segmento es = %lu", n.indice_inicial);
            }
            //n.indice_inicial = 0;
            [ARRAYcontroller insertObject:n atArrangedObjectIndex:ind_n_actual+1];
            [TheSplitView adjustSubviews];
            break;
        case 1:
            // NSLog(@"inserting latex");
            n.txt = [[NSAttributedString alloc] initWithString:@"\\begin{equation}\ne^x = 1 + x + \\frac{x^2}{2} + \\frac{x^3}{6} + \\cdots = \\sum_{n\\geq 0} \\frac{x^n}{n!} \n\\end{equation}"];
            n.Typefort = true;
            n.TypeTEX = false;
            n.TypeComm = true;
            n.Mi_modo_actual = 1;
            n.indice_inicial = 0;
            [ARRAYcontroller insertObject:n atArrangedObjectIndex:ind_n_actual+1];
            [TheSplitView adjustSubviews];
            break;
            //        case 2:
            //            if (m.Mi_modo_actual == 0) {
            //               // NSLog(@"inserting split fortran");
            //                [self splitThisFortranBlock:nil];
            //            }
            //            
            //            if (m.Mi_modo_actual == 1) {
            //               // NSLog(@"inserting split latex");
            //                [self splitThisLatexBlock:nil];
            //            }
            //            
            //            break;
        case 2:
            //NSLog(@"inserting invisible");
            n.txt = [[NSAttributedString alloc] initWithString:@"Invisible comments only on sciFeX\n"];
            n.Typefort = true;
            n.TypeTEX = true;
            n.TypeComm = false;
            n.Mi_modo_actual = 3;
            n.indice_inicial = 0;
            [ARRAYcontroller insertObject:n atArrangedObjectIndex:ind_n_actual+1];
            [TheSplitView adjustSubviews];
            break;
        default:
            NSLog(@"inserting something weird");
            break;
    }    
}

- (IBAction)click_split:(id)sender {
    nota *m = (nota*)[[ARRAYcontroller selectedObjects] objectAtIndex:0];
    if (m.Mi_modo_actual == 0) {
        // NSLog(@"inserting split fortran");
        [self splitThisFortranBlock:nil];
    }
    
    if (m.Mi_modo_actual == 1) {
        // NSLog(@"inserting split latex");
        [self splitThisLatexBlock:nil];
    }
}


- (IBAction)Toggle_breakpoints:(id)sender{
    
}



- (IBAction)click_debug_actions:(id)sender {
    if ([gdbtask isRunning] && (stdinHandle != nil)) {
        NSString * ttt = [NSString alloc];
        if ([Debug_actions selectedSegment] == 0) {
            ttt = @"continue\n";
        } else if ([Debug_actions selectedSegment] == 1) {
            //s-o
            ttt = @"next\n";
        } else {
            //s-i
            ttt = @"step\n";
        }
        [self postthis:[NSString stringWithFormat:@"%@\n",ttt] withcoolor:[NSColor orangeColor]];
        NSData *data = [ttt dataUsingEncoding:NSUTF8StringEncoding];
        [stdinHandle writeData:data];
        
        NSData *new_input = [@"info locals\n" dataUsingEncoding:NSUTF8StringEncoding];
        [stdinHandle writeData:new_input];
    }
}

- (IBAction)continue_menuclick:(id)sender{
    [self postthis:@"continue\n" withcoolor:[NSColor orangeColor]];
    NSString * ttt = [NSString alloc];
    ttt = @"continue\n";
    NSData *data = [ttt dataUsingEncoding:NSUTF8StringEncoding];
    [stdinHandle writeData:data];
    
    NSData *new_input = [@"info locals\n" dataUsingEncoding:NSUTF8StringEncoding];
    [stdinHandle writeData:new_input];
}
- (IBAction)StepInto_menuclick:(id)sender{
    [self postthis:@"next\n" withcoolor:[NSColor orangeColor]];
    
    NSString * ttt = [NSString alloc];
    ttt = @"next\n";
    NSData *data = [ttt dataUsingEncoding:NSUTF8StringEncoding];
    [stdinHandle writeData:data];
    
    NSData *new_input = [@"info locals\n" dataUsingEncoding:NSUTF8StringEncoding];
    [stdinHandle writeData:new_input];
}
- (IBAction)StepOut_menuclick:(id)sender{
    [self postthis:@"step\n" withcoolor:[NSColor orangeColor]];
    
    NSString * ttt = [NSString alloc];
    ttt = @"step\n";
    NSData *data = [ttt dataUsingEncoding:NSUTF8StringEncoding];
    [stdinHandle writeData:data];
    
    NSData *new_input = [@"info locals\n" dataUsingEncoding:NSUTF8StringEncoding];
    [stdinHandle writeData:new_input];
}
- (IBAction)OpenTerminal_menuclick:(id)sender{
    NSURL *url_file_name = [self fileURL];
    if ([url_file_name isNotEqualTo:nil]) {
        directorioBase = [[[url_file_name URLByDeletingLastPathComponent] absoluteString] stringByReplacingOccurrencesOfString:@"file://localhost" withString:@""];
        NSString *s = [NSString stringWithFormat:
                       @"tell application \"Terminal\" to do script \"cd / \n cd %@ \n clear \"",directorioBase];
        NSAppleScript *as = [[NSAppleScript alloc] initWithSource: s];
        [as executeAndReturnError:nil];
        s = @"tell application \"Terminal\" to activate";
        as = [[NSAppleScript alloc] initWithSource: s];
        [as executeAndReturnError:nil];
    }
}
- (IBAction)RunScript_menuclick:(id)sender{
    // TODO
    
}

- (IBAction)click_Debug_panels:(id)sender {
//    if ([Debug_panel selectedSegment] == 0) {
//        // out
//        //[gdbSplitView setPosition:300 ofDividerAtIndex:0];
//        
//        //las animaciones se ven bonitas.
//        {
//            //NSView *upS = [[gdbSplitView subviews]objectAtIndex:0];
//            NSView *doS = [[gdbSplitView subviews]objectAtIndex:1];
//            NSLog(@"%f",doS.frame.size.height);
//            if (doS.frame.size.height < 10.0f) {
//                NSLog(@"mostrar");
//                [gdbSplitView setPosition:300 ofDividerAtIndex:0];
//
//            } else {
//                NSLog(@"ocultar");
//                //si está abierto
//                NSMutableDictionary *collapseAnimDic = [NSMutableDictionary dictionaryWithCapacity:2];
//                [collapseAnimDic setObject:doS forKey:NSViewAnimationTargetKey];
//                NSRect newRect = doS.frame;
//                newRect.size.height = 0.0f;
//                [collapseAnimDic setObject:[NSValue valueWithRect:newRect] forKey:NSViewAnimationEndFrameKey];
//                NSViewAnimation *collapseAnim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:collapseAnimDic, nil]];
//                [collapseAnim setDuration:0.40f];
//                [collapseAnim startAnimation];
//                //[gdbSplitView adjustSubviews];
//                [gdbSplitView setNeedsDisplay:YES];
//            }
//            
//        }
//    } else
        
    if ([Debug_panel selectedSegment] == 0) {
        // W
        if ([VarsPanel isVisible]) {
            [VarsPanel orderOut:self];
        } else {
            [VarsPanel orderFront:self];
        }
    } else if ([Debug_panel selectedSegment] == 1) {
        // >_
        NSURL *url_file_name = [self fileURL];
        if ([url_file_name isNotEqualTo:nil]) {
            directorioBase = [[[url_file_name URLByDeletingLastPathComponent] absoluteString] stringByReplacingOccurrencesOfString:@"file://localhost" withString:@""];
            NSString *s = [NSString stringWithFormat:
                           @"tell application \"Terminal\" to do script \"cd / \n cd %@ \n clear \"",directorioBase];
            NSAppleScript *as = [[NSAppleScript alloc] initWithSource: s];
            [as executeAndReturnError:nil];
        }
    }
}

-(IBAction)toggle_comment_with_spacebar:(id)sender{
    nota *n = (nota*)[[ARRAYcontroller selectedObjects] objectAtIndex:0];
    NSString* texto = [[n txt] string];
    if ([n Mi_modo_actual] == 0) {
        NSRange sel_ra = [txtx selectedRange];
        
        
        
        NSString *tx = [[NSString alloc] initWithString:@"!"];
        //        if ([togglecomment selectedSegment] == 1) {
        //            tx = [NSString stringWithString:@" "];
        //        }
        
        //par cada line_break al principio
        NSRange ra;
        unsigned long numberOfLines = 0;
        unsigned long ind_letra = sel_ra.location;
        do {
            ra = [texto lineRangeForRange:NSMakeRange(ind_letra, 0)];
            
            if ([[texto substringWithRange:NSMakeRange(ra.location, 1)] isEqualToString:@" "]) {
                tx = @"!";
            } else {
                tx = @" ";
            }
            
            [txtx insertText:tx replacementRange:NSMakeRange(ra.location, 1)];
            
            ind_letra = NSMaxRange(ra);
            numberOfLines++;
            
        } while (ind_letra < NSMaxRange(sel_ra));
        
    }
}

- (IBAction)toggle_comment:(id)sender {
    nota *n = (nota*)[[ARRAYcontroller selectedObjects] objectAtIndex:0];
    NSString* texto = [[n txt] string];
    if ([n Mi_modo_actual] == 0) {
        NSRange sel_ra = [txtx selectedRange];
        
        NSString *tx = [[NSString alloc] initWithString:@"!"];
        if ([togglecomment selectedSegment] == 1) {
            tx = @" ";
        }
        
        //par cada line_break al principio
        NSRange ra;
        unsigned long numberOfLines = 0;
        unsigned long ind_letra = sel_ra.location;
        do {
            ra = [texto lineRangeForRange:NSMakeRange(ind_letra, 0)];
            
            [txtx insertText:tx replacementRange:NSMakeRange(ra.location, 1)];
            
            ind_letra = NSMaxRange(ra);
            numberOfLines++;
            
        } while (ind_letra < NSMaxRange(sel_ra));
        
    }
    
}

- (IBAction)NotaOpcionesSectionClick:(id)sender {
    if ([[ARRAYcontroller selectedObjects] count]>0) {
        nota *n = (nota*)[[ARRAYcontroller selectedObjects] objectAtIndex:0];
        // NSLog(@"%lu",[n indice_inicial]);
        if ([n indice_inicial] == (unsigned long)99999 ) {
            return;
        }
        
        switch ([OpcionesNota selectedSegment]) {
            case 0:
                // recorrer hacia arriba
                if ([ARRAYcontroller selectionIndex] > 0) {
                    NSUInteger ind_anterior = [ARRAYcontroller selectionIndex] -1;
                    
                    //si alguno anterior es fortran, hay que arreglar los numeros de linea
                    int j = 0;
                    int K = (int)[[ARRAYcontroller arrangedObjects] indexOfObject:n];
                    unsigned long suma_lineas = 0;
                    //  NSLog(@"index del elemento seleccionado = %i", K);
                    if ([(nota*)[[ARRAYcontroller arrangedObjects] objectAtIndex:K-1] Mi_modo_actual] == 0) {
                        //se está brincando un fortran, le contamos las  lineas entonces.
                        for (j = 0; j < [[ARRAYcontroller arrangedObjects] indexOfObject:n] - 1; j++) {
                            nota* nota_actual = (nota*)[[ARRAYcontroller arrangedObjects] objectAtIndex:j];
                            if ([nota_actual Mi_modo_actual] == 0) {
                                // es un fortran
                                unsigned long letra = 0;
                                unsigned long numberOfLines = 0;
                                unsigned long stringLength = [[[nota_actual txt]string] length];
                                do {
                                    letra = NSMaxRange([[[nota_actual txt]string] lineRangeForRange:NSMakeRange(letra, 0)]);
                                    numberOfLines++;
                                } while (letra < stringLength);
                                suma_lineas = suma_lineas + numberOfLines;
                                n.indice_inicial = suma_lineas;
                            }
                        }
                        if (suma_lineas == 0) {
                            n.indice_inicial = 0;
                        } else {
                            //las lineas se cuentan desde cero.
                            
                        }
                    }
                    //  NSLog(@"nuevo indice inicial es = %lu", n.indice_inicial);
                    
                    [ARRAYcontroller removeObject:n];
                    [ARRAYcontroller insertObject:n atArrangedObjectIndex:ind_anterior];
                    
                    //luego indicamos el sum_lineas al bloque que quedo despues
                    unsigned long letra = 0;
                    unsigned long numberOfLines = 0;
                    unsigned long stringLength = [[[n txt]string] length];
                    do {
                        letra = NSMaxRange([[[n txt]string] lineRangeForRange:NSMakeRange(letra, 0)]);
                        numberOfLines++;
                    } while (letra < stringLength);
                    [(nota*)[[ARRAYcontroller arrangedObjects] objectAtIndex:ind_anterior+1] setIndice_inicial:numberOfLines];
                    
                }
                break;
            case 1:
                //recorrer hacia abajo
                if ([ARRAYcontroller selectionIndex] < [[ARRAYcontroller arrangedObjects]count]-1) {
                    NSUInteger ind_siguiente = [ARRAYcontroller selectionIndex] +1;
                    
                    //si alguno anterior es fortran, hay que arreglar los numeros de linea
                    int j = 0;
                    //int K = (int)[[ARRAYcontroller arrangedObjects] indexOfObject:n];
                    unsigned long suma_lineas = 0;
                    //  NSLog(@"index del elemento seleccionado = %i", K);
                    if ([(nota*)[[ARRAYcontroller arrangedObjects] objectAtIndex:ind_siguiente] Mi_modo_actual] == 0) {
                        //se está brincando un fortran, contamos las  lineas de los que están antes del actual y del de adelante.
                        for (j=0; j < (int)ind_siguiente - 2 ; j++) {
                            nota* nota_actual = (nota*)[[ARRAYcontroller arrangedObjects] objectAtIndex:j];
                            if ([nota_actual Mi_modo_actual] == 0) {
                                // es un fortran
                                unsigned long letra = 0;
                                unsigned long numberOfLines = 0;
                                unsigned long stringLength = [[[nota_actual txt]string] length];
                                do {
                                    letra = NSMaxRange([[[nota_actual txt]string] lineRangeForRange:NSMakeRange(letra, 0)]);
                                    numberOfLines++;
                                } while (letra < stringLength);
                                suma_lineas = suma_lineas + numberOfLines;
                                
                            }
                        }
                        
                        // mas las lineas del que se mueve.
                        nota* nota_actual = (nota*)[[ARRAYcontroller arrangedObjects] objectAtIndex:ind_siguiente];
                        unsigned long letra = 0;
                        unsigned long numberOfLines = 0;
                        unsigned long stringLength = [[[nota_actual txt]string] length];
                        do {
                            letra = NSMaxRange([[[nota_actual txt]string] lineRangeForRange:NSMakeRange(letra, 0)]);
                            numberOfLines++;
                        } while (letra < stringLength);
                        suma_lineas = suma_lineas + numberOfLines;
                        n.indice_inicial = suma_lineas;
                    }
                    //  NSLog(@"nuevo indice inicial es = %lu", n.indice_inicial);
                    
                    [ARRAYcontroller removeObject:n];
                    [ARRAYcontroller insertObject:n atArrangedObjectIndex:ind_siguiente];
                }
                break;
            case 2:
                
                NSBeginAlertSheet(
                                  @"Delete this block?",
                                  @"Oh no! sorry", 
                                  @"Delete it", 
                                  NULL, 
                                  [self windowForSheet], 
                                  self, 
                                  @selector(deleteBlock:returnCode:contextInfo:),  
                                  NULL,
                                  [NSDictionary dictionaryWithObject:@"Some context info" forKey:@"in a dictionary"],
                                  @"Deleting a block can not be undone."
                                  );
                
                break;
            default:
                break;
        }
    }
}

- (IBAction)NotaiDisclosureClick:(id)sender {
    
}

- (void)deleteBlock:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertAlternateReturn) {
        nota *n = (nota*)[[ARRAYcontroller selectedObjects] objectAtIndex:0];
        [ARRAYcontroller removeObject:n];
    }
}

- (IBAction)click_printable:(id)sender {
    if ([[ARRAYcontroller selectedObjects] count]>0) {
        nota *n = (nota*)[[ARRAYcontroller selectedObjects] objectAtIndex:0];
        if ([OpcionesNotaImprimir state] == 0 ) {
            //  NSLog(@"Mejor si imprimir el objeto: %@",n.title);
            [n setPrintable:YES];
        } else {
            // no imprimir
            //  NSLog(@"No imprimir el objeto: %@",n.title);
            [n setPrintable:NO];
        }
    }
}

- (IBAction)ShowOuts:(id)sender {
    NSView *doS = [[gdbSplitView subviews]objectAtIndex:1];
    //NSLog(@"%f",doS.frame.size.height);
    if (doS.frame.size.height < 10.0f) {
        //NSLog(@"mostrar");
        [gdbSplitView setPosition:500 ofDividerAtIndex:0];
        
    } else {
        //NSLog(@"ocultar");
        //si está abierto
        NSMutableDictionary *collapseAnimDic = [NSMutableDictionary dictionaryWithCapacity:2];
        [collapseAnimDic setObject:doS forKey:NSViewAnimationTargetKey];
        NSRect newRect = doS.frame;
        newRect.size.height = 0.0f;
        [collapseAnimDic setObject:[NSValue valueWithRect:newRect] forKey:NSViewAnimationEndFrameKey];
        NSViewAnimation *collapseAnim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:collapseAnimDic, nil]];
        [collapseAnim setDuration:0.40f];
        [collapseAnim startAnimation];
        //[gdbSplitView adjustSubviews];
        [gdbSplitView setNeedsDisplay:YES];
    }
}

- (IBAction)Popout:(id)sender{
    [popwindow makeKeyAndOrderFront:nil];
}

#pragma mark -
#pragma mark Run-Debugg 

- (bool)Correr_programa:(NSString*)path withArgs:(NSArray*)args {
    NSTask *task = [[NSTask alloc] init];
    NSLog(@"\n passed task = \n%@",path);
    [self postthis:[NSString stringWithFormat:@"\n passed task = \n%@",path] withcoolor:[NSColor orangeColor]];
    [task setLaunchPath:@"/bin/bash"];
    NSArray *args2 = [[NSArray alloc] initWithObjects:@"-l", nil]; //para que se comporte como un shell invocado (y carge .profile)
    [task setArguments:args2];
    
    //    NSLog(@"%@\n%@",lineaDepurador,nombreOUTput);
    
    
    NSString *actividad = [[NSString alloc] initWithFormat:@"%@ %@ \n exit \n",path,[args componentsJoinedByString:@" "]]; 
    NSLog(@"\n passed args = \n%@",actividad);
    [self postthis:[NSString stringWithFormat:@"\n passed args = \n%@",actividad] withcoolor:[NSColor orangeColor]];
    //    [task setLaunchPath:path];
    //    [task setArguments:args];
    
    NSPipe *pipe; 
    pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    [task setStandardError:[task standardOutput]];
    [task setStandardInput:[NSPipe pipe]];
    
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    
    NSMutableData *data = [NSMutableData dataWithCapacity:512];
    NSString *string;
    
    [task setCurrentDirectoryPath:directorioBase];
    
    NSFileHandle *FW;
    FW = [[task standardInput] fileHandleForWriting];
    
    [self postthis:@"Launched task...\n" withcoolor:[NSColor orangeColor]];
    [task launch];
    
    NSData *tarea;
    tarea = [[NSString stringWithFormat:@"%@ \n",actividad] dataUsingEncoding:NSUTF8StringEncoding];
    [FW writeData:tarea];
    
    if (![task isRunning]) {
        //que no corre o que no se logró iniciar
        [self postthis:[NSString stringWithFormat:@"Task returned %d",[task terminationStatus]] withcoolor:[NSColor greenColor]];
        return 1;
    }
    
    
    [data appendData:[file readDataToEndOfFile]];
    bool entro = NO;
    while ([task isRunning]) {
        [data appendData:[file readDataToEndOfFile]];
        
        string = [[NSString alloc] initWithData:[file readDataToEndOfFile] encoding:NSUTF8StringEncoding];
        entro = YES;
        [self postthis:[NSString stringWithFormat:@"%@\n",string] withcoolor:[NSColor whiteColor]];
    }
    if (!entro) {
        [data appendData:[file readDataToEndOfFile]];
        string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
        [self postthis:[NSString stringWithFormat:@"%@\n",string] withcoolor:[NSColor whiteColor]];
    }
    
    [task waitUntilExit];
    [task release];
    
    
    
    //revisamos si hubo errores o warnings
    NSRange rE = {0, 0};
    NSRange rW = {0, 0};
    NSRange rN = {0, 0};
    NSString *lineTxt = [[NSString alloc] initWithFormat:@"%@:",lineaExtension];
    
    rE = [[dbgTextOut string] rangeOfString:@"Error"]; //el primero que encuentra
    rW = [[dbgTextOut string] rangeOfString:@"Warning"]; //el primero que encuentra
    unsigned long Enter = 0;
    unsigned long Start = 0;
    int ReturnValue = 0;
    if ((rE.length + rW.length) > 0) {
        if (rE.length > 0) {
            ReturnValue = 1;
        }
        NSMutableArray* thisWarnArray = [[NSMutableArray alloc] init];
        NSString *Ot = [[dbgTextOut string] copy]; 
        NSString *Extracted = [[NSString alloc] init];
        NSString *lineT = [[NSString alloc] init];
        int lineN;
        //digerir lo que hay en dbgTextOut
        //primero los errores
        do {
            //NSLog(@"check:\n%@",Ot);
            rE = [Ot rangeOfString:@"Error"];
            rW = [Ot rangeOfString:@"Warning"];
            rN = [Ot rangeOfString:lineTxt];
            //limite inicial
            Start = [Ot lineRangeForRange:rN].location;
            
            //hasta el fin de linea es:
            Enter = MIN(rE.location, rW.location);
            Enter = NSMaxRange([Ot lineRangeForRange:NSMakeRange(Enter, 5)]);
            
            Extracted = [Ot substringWithRange:NSMakeRange(Start, Enter-Start)]; 
            //NSLog(@"%@",Extracted);
            rN = [Extracted rangeOfString:lineTxt];
            lineT = [Extracted substringFromIndex:NSMaxRange(rN)];
            lineT = [lineT substringToIndex:[lineT rangeOfString:@"."].location];
            lineN = [lineT intValue];
            //agregar al vector ese feo
            WarnModel* wm = [[WarnModel alloc]init];
            rE = [Extracted rangeOfString:@"Error"];
            rW = [Extracted rangeOfString:@"Warning"];
            Start = MIN(rE.location, rW.location);
            [wm setWarn:[Extracted substringFromIndex:Start]];
            [wm setLinea:[[NSNumber alloc] initWithInt:lineN]];
            [wm setExtra:Extracted];
            [thisWarnArray addObject:wm];
            
            Ot = [Ot substringFromIndex:Enter];
            rN = [Ot rangeOfString:lineTxt];
        } while (rN.length>0);
        if ([thisWarnArray count] >= 1) {
            self.WarnsArray = [[NSMutableArray alloc] initWithArray:thisWarnArray];
            [self.WarnsArray retain];
        }
        
    }
    return ReturnValue;
}
-(void)postthis:(NSString*)st withcoolor:(NSColor*)color {
    NSAttributedString *Satrib = [[NSAttributedString alloc] initWithString:st attributes:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSFont userFixedPitchFontOfSize:11.0],color, nil] forKeys:[NSArray arrayWithObjects:NSFontAttributeName,NSForegroundColorAttributeName, nil]]] ;
    //[gdbSplitView setPosition:500 ofDividerAtIndex:0];
    //[gdbWarnSplitView setPosition:gdbWarnSplitView.frame.size.width ofDividerAtIndex:0];
    [[dbgTextOut textStorage] appendAttributedString:Satrib];
    [dbgTextOut scrollToEndOfDocument:nil];
}

-(void)GotoWarningLine:(NSNotification*)notification{
    NSNumber *n = [[notification userInfo]objectForKey:@"numLinea"];
    if ([self.WarnsArray count] > 0) {
        if ([self.WarnsArray count] >= n.intValue) {
            NSColor* color = [NSColor yellowColor];
            if ([[[self.WarnsArray objectAtIndex:[n integerValue]] Warn] rangeOfString:@"Error"].length > 0) {
                color = [NSColor redColor];
            }
            [self postthis:[[self.WarnsArray objectAtIndex:[n integerValue]] Extra] withcoolor:color];
            
            n = [[self.WarnsArray objectAtIndex:[n integerValue]] linea];
            [self goToLine:[n intValue]];
        }
    }
    
}



- (IBAction)Run_button_click:(id)sender {
    // NSLog(@"Run button click");
    [self performSelectorOnMainThread:@selector(clean_and_close) withObject:nil waitUntilDone:YES];
    //    [self clean_and_close];
    
    {
        [gdbSplitView setPosition:500 ofDividerAtIndex:0];
        [[dbgTextOut textStorage] setAttributedString:[[NSAttributedString alloc] initWithString:@""]];
        NSString* ts = [[NSString alloc]initWithString: [NSString stringWithFormat:@"\n......................\n%@\n",[self currentHour]]];
        [self postthis:ts withcoolor:[NSColor orangeColor]];
        NSMutableArray* thisWarnArray = [[NSMutableArray alloc] initWithObjects:nil];
        self.WarnsArray = [[NSMutableArray alloc] initWithArray:thisWarnArray];
        [self.WarnsArray retain];
    }
    
    NSDictionary *textos_dic = [self textos_de_salida_para_el_arreglo:[ARRAYcontroller arrangedObjects]];
    if (textos_dic == nil) {
        NSLog(@"\n\nError: Document contents could not be grouped.");
        [self postthis:@"Error: Document contents could not be grouped.\n" withcoolor:[NSColor redColor]];
        return;
    }
    NSString *textoFortran = [textos_dic objectForKey:@"t_fort"];
    NSString *textoLatex = [textos_dic objectForKey:@"t_late"];
    
    if (![self guardadoTextoFortran:textoFortran TextoLatex:textoLatex]) {
        NSLog(@"sorry");
        [self postthis:@"\nNot saved... quitting\n" withcoolor:[NSColor redColor]];
        return;
    }
    
    NSArray *nombreOUTput_array = [nombreOUTput componentsSeparatedByString:@"/"];
    NSString *compiledProgram_name = [nombreOUTput_array lastObject];
    //NSTask *task = [[NSTask alloc] init];
    if ([ToggleBreakpoints state] == 0) {
        [self clearSlate:nil];
        
        NSString *argum_txt = lineaArgumentos;
        NSLog(@"Arguemnt line form:\n%@\n",argum_txt);
        
        argum_txt = [argum_txt stringByReplacingOccurrencesOfString:@"%F" withString:nombreArchivoFORTRAN];
        argum_txt = [argum_txt stringByReplacingOccurrencesOfString:@"%G" withString:
                     [nombreArchivo stringByReplacingOccurrencesOfString:@".scif" withString:@""]];
        argum_txt = [argum_txt stringByReplacingOccurrencesOfString:@"%A" withString:nombreOUTput];
        argum_txt = [argum_txt stringByReplacingOccurrencesOfString:@"%O" withString:[nombreOUTput stringByReplacingOccurrencesOfString:@".out" withString:@".o"]];
        NSArray *argum = [argum_txt componentsSeparatedByString:@" "];
        
        if ([self Correr_programa:lineaCompilador withArgs:argum] == 1) {
            [gdbSplitView setPosition:500 ofDividerAtIndex:0];
            [gdbWarnSplitView setPosition:500 ofDividerAtIndex:0];
            return;
        }
        
        NSString *_lineaRunArgs = lineaRunArgs;
        
        _lineaRunArgs = [_lineaRunArgs stringByReplacingOccurrencesOfString:@"%F" withString:nombreArchivoFORTRAN];
        _lineaRunArgs = [_lineaRunArgs stringByReplacingOccurrencesOfString:@"%G" withString:
                         [nombreArchivo stringByReplacingOccurrencesOfString:@".scif" withString:@""]];
        _lineaRunArgs = [_lineaRunArgs stringByReplacingOccurrencesOfString:@"%A" withString:nombreOUTput];
        _lineaRunArgs = [_lineaRunArgs stringByReplacingOccurrencesOfString:@"%O" withString:[nombreOUTput stringByReplacingOccurrencesOfString:@".out" withString:@".o"]];
        _lineaRunArgs = [_lineaRunArgs stringByReplacingOccurrencesOfString:@";" withString:@"\n"];
        
        //OFF sólo ejecutar programa compilado
        NSString *s = [NSString stringWithFormat:
                       @"tell application \"Terminal\" to do script \"cd / \n cd %@ \n clear \n echo %@ \n %@ \n ./%@ \n \""
                       ,directorioBase,[self currentHour],_lineaRunArgs,compiledProgram_name];
        NSAppleScript *as = [[NSAppleScript alloc] initWithSource: s];
        [as executeAndReturnError:nil];
        s = @"tell application \"Terminal\" to activate";
        as = [[NSAppleScript alloc] initWithSource: s];
        [as executeAndReturnError:nil];
    } 
    else if ([ToggleBreakpoints state] == 1) 
    {
        //Tareas pre depurador/ es un scrip que ejecutamos en una terminal
        if (!predebugscriptdone) {
            
            NSString *processedlineaPreCompilador = [[NSString alloc] init];
            processedlineaPreCompilador = [lineaPreCompilador copy];
            processedlineaPreCompilador = [processedlineaPreCompilador stringByReplacingOccurrencesOfString:@"%F" withString:nombreArchivoFORTRAN];
            processedlineaPreCompilador = [processedlineaPreCompilador stringByReplacingOccurrencesOfString:@"%G" withString:
                                           [nombreArchivo stringByReplacingOccurrencesOfString:@".scif" withString:@""]];
            processedlineaPreCompilador = [processedlineaPreCompilador stringByReplacingOccurrencesOfString:@"%A" withString:nombreOUTput];                            
            processedlineaPreCompilador = [processedlineaPreCompilador stringByReplacingOccurrencesOfString:@"%O" withString:[nombreOUTput stringByReplacingOccurrencesOfString:@".out" withString:@".o"]];
            processedlineaPreCompilador = [processedlineaPreCompilador stringByReplacingOccurrencesOfString:@";" withString:@"\n"];
            
            //NSLog(@"launching: \n %@",processedlineaPreCompilador);
            
            NSString *s = [NSString stringWithFormat:
                           @"tell application \"Terminal\" to do script \"cd / \n cd %@ \n echo %@ \n %@ \n\""
                           ,directorioBase,[self currentHour],processedlineaPreCompilador];
            NSAppleScript *as = [[NSAppleScript alloc] initWithSource: s];
            NSDictionary **errorInfo = NULL;
            [as executeAndReturnError:errorInfo];
            {
                [self postthis:@"Precompile script executed. Run again to debug.\n" withcoolor:[NSColor redColor]];
            }
            
            [terminal hideTerm:nil];            
            predebugscriptdone = true;
            
        } else {
            predebugscriptdone = false;
            
            {
                [self postthis:[NSString stringWithFormat:@"Pre Debug, compiler script: \n%@",lineaPreCompilador] withcoolor:[NSColor redColor]];
            }
            //limpiamos archivos de in y out del programa
            {
                if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/%@",directorioBase,inPut]]) {
                    [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@",directorioBase,inPut] error:nil];
                }
                if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/%@",directorioBase,outPut]]) {
                    [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@",directorioBase,outPut] error:nil];
                } 
                
                [[NSFileManager defaultManager] createFileAtPath:[NSString stringWithFormat:@"%@/%@",directorioBase,inPut] contents:nil attributes:nil];
                [[NSFileManager defaultManager] createFileAtPath:[NSString stringWithFormat:@"%@/%@",directorioBase,outPut] contents:nil attributes:nil];
            }
            
            //ON entonces depurar
            {
                [self postthis:@"debugging compiled program\n" withcoolor:[NSColor redColor]];
            }
            // juntar los breakpoints en un mutablearray
            NSMutableArray *todos_los_breakpoints = [[NSMutableArray alloc] init];
            int i;
            for (i = 0; i < [[ARRAYcontroller arrangedObjects] count]; i++) {
                nota* n = (nota*)[[ARRAYcontroller arrangedObjects] objectAtIndex:i];
                if ([n Mi_modo_actual] == 0) {
                    NSEnumerator *UnMarcador = [[n Nota_linesToMarkers] keyEnumerator];
                    NSNumber *Key_en_nota = nil;
                    unsigned long num_lin_inicial = [n indice_inicial];
                    while (Key_en_nota = [UnMarcador nextObject]) {
                        //NSLog(@"\nBreakpoint en: %lu",num_lin_inicial + [Key_en_nota unsignedLongValue] + 1);
                        [todos_los_breakpoints addObject:[NSNumber numberWithUnsignedLong:num_lin_inicial + [Key_en_nota unsignedLongValue] + 1]];
                    }
                }
            }
            
            // ahora lanzar el gdb
            gdbtask = [[NSTask alloc] init];
            [gdbtask setLaunchPath:@"/bin/bash"];
            //    NSLog(@"%@\n%@",lineaDepurador,nombreOUTput);
            NSArray *argum_gdb = [[NSArray alloc] initWithObjects:@"-l", nil]; //para que se comporte como un shell invocado (y carge .profile)
            [gdbtask setArguments:argum_gdb];
            [gdbtask setCurrentDirectoryPath:directorioBase];
            [gdbtask setStandardOutput:[NSPipe pipe]];
            [gdbtask setStandardError:[gdbtask standardOutput]];
            [gdbtask setStandardInput:[NSPipe pipe]];
            stdinHandle = [[gdbtask standardInput] fileHandleForWriting];
            
            //apple documentation:
            // Here we register as an observer of the NSFileHandleReadCompletionNotification, which lets
            // us know when there is data waiting for us to grab it in the task's file handle (the pipe
            // to which we connected stdout and stderr above).  -getData: will be called when there
            // is data waiting.  The reason we need to do this is because if the file handle gets
            // filled up, the task will block waiting to send data and we'll never get anywhere.
            // So we have to keep reading data from the file handle as we go.
            [[NSNotificationCenter defaultCenter] addObserver:self 
                                                     selector:@selector(getData:) 
                                                         name: NSFileHandleReadCompletionNotification 
                                                       object: [[gdbtask standardOutput] fileHandleForReading]];
            // We tell the file handle to go ahead and read in the background asynchronously, and notify
            // us via the callback registered above when we signed up as an observer.  The file handle will
            // send a NSFileHandleReadCompletionNotification when it has data that is available.
            [[[gdbtask standardOutput] fileHandleForReading] readInBackgroundAndNotify];
            [gdbtask launch];
            
            NSData *data;
            //data = [[NSString stringWithFormat:@"tty %@ \n",thisTTY] dataUsingEncoding:NSUTF8StringEncoding];
            //[stdinHandle writeData:data];
            
            data = [[NSString stringWithFormat:@"%@ \n",lineaDepurador] dataUsingEncoding:NSUTF8StringEncoding];
            [stdinHandle writeData:data];
            
            data = [[NSString stringWithFormat:@"file %@ \n",compiledProgram_name] dataUsingEncoding:NSUTF8StringEncoding];
            [stdinHandle writeData:data];
            
            //ahora agregamos los breakpoints
            for (i=0; i < [todos_los_breakpoints count]; i++) {
                data = [[NSString stringWithFormat:@"break %i\n",[(NSNumber*)[todos_los_breakpoints objectAtIndex:i] intValue]] dataUsingEncoding:NSUTF8StringEncoding];
                [stdinHandle writeData:data];
            }
            // y un break para cuando la regamos en los vectores
            data = [@"break malloc_error_break\n" dataUsingEncoding:NSUTF8StringEncoding];
            [stdinHandle writeData:data];
            
            data = [[NSString stringWithFormat:@"run < %@ > %@ \n",inPut,outPut] dataUsingEncoding:NSUTF8StringEncoding];
            [stdinHandle writeData:data];
            
            //[terminal hideTerm:[self windowForSheet]];
            
            // mostrar las variables
            if ([todos_los_breakpoints count] > 0) {
                //enviarmos mensajes sobre las variables
                [txtx setEnviar:true];
                
                [VarsPanel orderFront:self];
            }
        }
    } else {
    }
}

- (IBAction)Run_last_click:(id)sender {
    if (nombreOUTput != nil) {
        NSArray *nombreOUTput_array = [nombreOUTput componentsSeparatedByString:@"/"];
        NSString *script_txt = [nombreOUTput_array lastObject];
        
        NSString *s = [NSString stringWithFormat:
                       @"tell application \"Terminal\" to do script \"cd / \n cd %@ \n clear \n ./%@\"",directorioBase,script_txt];
        NSAppleScript *as = [[NSAppleScript alloc] initWithSource: s];
        [as executeAndReturnError:nil];
        s = @"tell application \"Terminal\" to activate";
        as = [[NSAppleScript alloc] initWithSource: s];
        [as executeAndReturnError:nil];
    }
}

//apple documentation:
// This method is called asynchronously when data is available from the task's file handle.
// We just pass the data along to the controller as an NSString.
-(void)getData:(NSNotification*)notification{
    //NSLog(@"get data:\n%@",[notification description]);
    NSData *data = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    
    // If the length of the data is zero, then the task is basically over - there is nothing
    // more to get from the handle so we may as well shut down.
    if ([data length])
    {     
        NSMutableArray* thisVarArray = [[NSMutableArray alloc] init];
        NSColor* color = [NSColor whiteColor];
        NSString * db = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        {
            if ([db hasPrefix:@"(gdb) No symbol"]) {
                // no tiene nada util
                [[notification object] readInBackgroundAndNotify];
                return;
            }
        }
        {
            //antes de tratar de procesarla, la mandamos al raw dump como texto
            [VarsDumptxt setString:[[VarsDumptxt string] stringByAppendingString:db]];
            [VarsDumptxt scrollToEndOfDocument:nil];
        }
        db = [db stringByReplacingOccurrencesOfString:@"(gdb)" withString:@""];
        db = [db stringByReplacingOccurrencesOfString:@" \n" withString:@""];
        //NSLog(@"data:\n%@",db);
        // una variable por línea
        db = [db stringByReplacingOccurrencesOfString:@"{\n" withString:@"{"];
        db = [db stringByReplacingOccurrencesOfString:@"{ " withString:@"{"];
        db = [db stringByReplacingOccurrencesOfString:@"\n}" withString:@"}"];
        db = [db stringByReplacingOccurrencesOfString:@" }" withString:@"}"];
        db = [db stringByReplacingOccurrencesOfString:@", \n" withString:@","];
        db = [db stringByReplacingOccurrencesOfString:@",\n" withString:@","];
        db = [db stringByReplacingOccurrencesOfString:@"  " withString:@" "];
        //NSLog(@"data again:\n%@",db);
        {
            // revisamos si comienza con $ eso quiere decir que es la salida de un print
            if ([db hasPrefix:@"$"]) {
                db = [db stringByReplacingOccurrencesOfString:@" " withString:@""];
                db = [db stringByReplacingOccurrencesOfString:@"\n" withString:@";"];
                db = [db stringByReplacingOccurrencesOfString:@"\t" withString:@""];
                db = [db stringByReplacingOccurrencesOfString:@", " withString:@","];
                NSNumber* loc = [[NSNumber alloc] initWithUnsignedLong:palabraRange.location];
                NSNumber* len = [[NSNumber alloc] initWithUnsignedLong:palabraRange.length];
                //NSLog(@"original:\n%@",db);
                db = [db substringFromIndex:NSMaxRange([db rangeOfString:@"="])];
                //NSLog(@"trimmed:\n%@",db);
                if ([db length] == 0) {
                    [[notification object] readInBackgroundAndNotify];
                    return;
                }
                db = [@"" stringByAppendingFormat:@"%@ = %@",palabra,db];
                //NSLog(@"final:\n%@",db);
                NSDictionary* dada = [[NSDictionary alloc] initWithObjectsAndKeys:
                                      db,@"varVal",
                                      loc,@"loc",
                                      len,@"len",
                                      nil];
                [txtx mostrarValor:dada];
                [[notification object] readInBackgroundAndNotify];
                return; //no hacemos más para no fregar la lista si es que se pobló
            }
            
            if ([db hasPrefix:@"No symbol"]) {
                // no tiene nada util
                [[notification object] readInBackgroundAndNotify];
                return;
            }
        }
        
        NSArray * db_arr = [db componentsSeparatedByString:@"\n"]; //por renglones
        NSArray * aux_arr = [NSArray alloc];
        int i;
        for (i=0; i<[db_arr count]; i++) 
        {
            NSString *db_arr_i = [[NSString alloc] init];
            db_arr_i = (NSString*)[db_arr objectAtIndex:i];
            do {
                if ([db_arr_i hasPrefix:@" "]) {
                    db_arr_i = [db_arr_i substringFromIndex:1];
                }
            } while ([db_arr_i hasPrefix:@" "]);
            
            //NSLog(@"NOW:.....\n(%d/%lu):%@",i,[db_arr count],db_arr_i);
            color = [NSColor whiteColor];
            aux_arr = [db_arr_i componentsSeparatedByString:@" "];
            if ([aux_arr count]) {
                NSString* palabraCero = [aux_arr objectAtIndex:0];
                //NSLog(@"%@",palabraCero);
                if ([palabraCero isEqualToString:@"\n"]) {
                    continue;
                }
                
                if ([palabraCero isEqualToString:@"Breakpoint"]) {
                    if ([aux_arr count] > 4) {
                        db = [aux_arr objectAtIndex:4];
                        if ([db isEqualToString:@"at"]) {
                            //entonces si es un breakpoint
                            //                            int num_lin_break = 1;
                            //                            db = [[db_arr_i componentsSeparatedByString:@":"] lastObject];
                            //                            num_lin_break = [db intValue];
                            //                            [self goToLine:num_lin_break];
                            
                            //una notificación para que se muestre la página de ese código, se viaje hasta la línea de código y se resalte el breakpoint.
                            //                            int kk,acumulado;
                            //                            acumulado = 0;
                            //                            for (kk=0; kk < [[ARRAYcontroller arrangedObjects] count]; kk++) {
                            //                                nota *n = (nota*)[[ARRAYcontroller arrangedObjects] objectAtIndex:kk];
                            //                                if ([n Mi_modo_actual] == 0) {
                            //                                    //NSNumber * nm = [n NoDeLineas_reciente];
                            //                                    //NSLog(@"%@", [nm stringValue]);
                            //                                    if ([n NoDeLineas_reciente] != nil) {
                            //                                        //NSLog(@"%i", [[n NoDeLineas_reciente] intValue]);
                            //                                    }
                            //                                    
                            //                                    acumulado = acumulado + [[n NoDeLineas_reciente] intValue];
                            //                                    if (acumulado >= num_lin_break) {
                            //                                        //aquí está el break
                            //                                        [ARRAYcontroller setSelectionIndex:kk];
                            //                                        [self goToLine:num_lin_break - (int)[n indice_inicial]];
                            //                                        break;
                            //                                    }
                            //                                }
                            //                            }
                            
                            color = [NSColor whiteColor];
                            
                            NSData *new_input = [@"info locals\n" dataUsingEncoding:NSUTF8StringEncoding];
                            [stdinHandle writeData:new_input];
                            NSError *ReadErr = nil;
                            NSString *readText = [[NSString alloc] initWithContentsOfFile:[[NSString alloc] initWithFormat:@"%@/%@",directorioBase,outPut] encoding:NSUTF8StringEncoding error:&ReadErr];
                            if (ReadErr != nil) {
                                color = [NSColor redColor];
                                readText = [[NSString alloc] initWithFormat:@"Read Error: %@",[ReadErr userInfo]];
                            }
                            {
                                [self postthis:readText withcoolor:color];
                            }
                        }
                    }
                } else if ([palabraCero isEqualToString:@"Program"]) {
                    //NSLog(@"should exit?");
                    NSString* db_arr_i_st = [[NSString alloc] initWithString:db_arr_i];
                    //NSLog(@"%@",db_arr_i_st);
                    if ([db_arr_i_st hasPrefix:@"Program exited"]) {
                        [self clean_and_close];
                        //actualizamos el programOUTtxt desde [NSString stringWithFormat:@"%@/%@",directorioBase,outPut]
                        NSError *ReadErr = nil;
                        NSString *readText = [[NSString alloc] initWithContentsOfFile:[[NSString alloc] initWithFormat:@"%@/%@",directorioBase,outPut] encoding:NSUTF8StringEncoding error:&ReadErr];
                        color = [NSColor whiteColor];
                        if (ReadErr != nil) {
                            color = [NSColor redColor];
                            readText = [[NSString alloc] initWithFormat:@"Read Error: %@",[ReadErr userInfo]];
                        }
                        //limpiamos el archivo
                        FILE* f_log = fopen([[NSString stringWithFormat:@"%@/%@",directorioBase,outPut] cStringUsingEncoding:NSUTF8StringEncoding],"w");
                        //fprintf(f_log, "");
                        fclose(f_log); 
                        //presentamos
                        {
                            [self postthis:readText withcoolor:color];
                            [self postthis:[NSString stringWithFormat:@"\n%@",db_arr_i] withcoolor:color];
                        }
                        [[notification object] readInBackgroundAndNotify];
                        return;
                    }
                    
                    
                } else if ([aux_arr count] >= 2) {
                    if ([[aux_arr objectAtIndex:1] isEqualToString:@"="]) {
                        // entonces tenemos variables de un 'print' o un 'info locals'
                        VarModel* vm = [[VarModel alloc]init];
                        [vm setVarName:[aux_arr objectAtIndex:0]];                        
                        NSString* db_arr_i_st = [[NSString alloc] initWithString:db_arr_i];
                        db_arr_i_st =  [db_arr_i_st substringFromIndex:NSMaxRange([db_arr_i_st rangeOfString:@"="])];
                        //NSLog(@"variable %@  =  %@",[aux_arr objectAtIndex:0],db_arr_i_st);
                        [vm setVarValue:db_arr_i_st];
                        [thisVarArray addObject:vm];
                    }
                    
                    // el número de línea después de un breakpoint
                    if ([(NSString*)[aux_arr objectAtIndex:0] rangeOfString:@"\t"].location != NSNotFound ) {
                        NSString *num_lin_str = [(NSString*)[aux_arr objectAtIndex:0] stringByReplacingOccurrencesOfString:@"\t" withString:@""];
                        int num_lin_break = [num_lin_str intValue];
                        [self goToLine:num_lin_break];
                        break;
                        //                        int kk,acumulado;
                        //                        acumulado = 0;
                        //                        for (kk=0; kk < [[ARRAYcontroller arrangedObjects] count]; kk++) {
                        //                            nota *n = (nota*)[[ARRAYcontroller arrangedObjects] objectAtIndex:kk];
                        //                            if ([n Mi_modo_actual] == 0) {
                        //                                //NSLog(@"%i", [[n NoDeLineas_reciente] intValue]);
                        //                                acumulado = acumulado + [[n NoDeLineas_reciente] intValue];
                        //                                if (acumulado >= num_lin_break) {
                        //                                    //aquí está el break
                        //                                    [ARRAYcontroller setSelectionIndex:kk];
                        //                                    [self goToLine:num_lin_break - (int)[n indice_inicial]];
                        //                                    NSLog(@"going to: %d",num_lin_break);
                        //                                    break;
                        //                                }
                        //                            }
                        //                        }
                    }
                }
                
                // todo el resto del output:
                if (![thisVarArray count]) {
                    if ([[db_arr objectAtIndex:i] length] > 1) {
                        [self postthis:[NSString stringWithFormat:@"\n%@",db_arr_i] withcoolor:[NSColor whiteColor]];
                    }
                }
            }
        }
        if ([thisVarArray count]>=1) {
            self.VarsArray = [[NSMutableArray alloc] initWithArray:thisVarArray];
        } 
        
    } else {
        // We're finished here
        //[self clean_and_close];
        [self Stop_button_click:nil];
        [[notification object] readInBackgroundAndNotify];
        return;
    }
    
    // we need to schedule the file handle go read more data in the background again.
    [[notification object] readInBackgroundAndNotify];
}


//- (IBAction)terminal_enter:(id)sender {
//    if (sender == gdbinput) {
//        NSData *data = [[[gdbinput stringValue] stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding];
//        if (stdinHandle != nil && [gdbtask isRunning]) { 
//            NSAttributedString * t = [[[NSAttributedString alloc] initWithString:[[gdbinput stringValue] stringByAppendingString:@"\n"] attributes:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSFont userFixedPitchFontOfSize:9.0],[NSColor orangeColor], nil] forKeys:[NSArray arrayWithObjects:NSFontAttributeName,NSForegroundColorAttributeName, nil]]] autorelease];
//            
//            [[dbgTextOut textStorage] appendAttributedString:t];
//            [stdinHandle writeData:data];
//            
//            [gdbinput setStringValue:@""];
//        }
//        
//        if ([[gdbinput stringValue] isEqualToString:@"quit"]) {
//            //[terminal hideTerm:[self windowForSheet]];
//            [self Stop_button_click:nil];
//        }
//    } else if (sender == programINPUTtxt) {
//        if (stdinHandle != nil && [gdbtask isRunning]) {
//            //escribir en archivo inPut
//            FILE* f_log = fopen([[NSString stringWithFormat:@"%@/%@",directorioBase,inPut] cStringUsingEncoding:NSUTF8StringEncoding],"w");
//            fprintf(f_log,"%s\n",[[programINPUTtxt stringValue] cStringUsingEncoding:NSUTF8StringEncoding]);
//            fclose(f_log); 
//            
//            [programINPUTtxt setStringValue:@""];
//        }
//    }
//}

-(void)clean_and_close{
    if ([gdbtask isRunning]) {
        [txtx setEnviar:false];
        
        NSData *data = [[[NSString alloc] initWithString:@"kill\n"] dataUsingEncoding:NSUTF8StringEncoding];
        [stdinHandle writeData:data];
        data = [[[NSString alloc] initWithString:@"quit\n"] dataUsingEncoding:NSUTF8StringEncoding];
        [stdinHandle writeData:data];
    }
    
    /*    // we tell the controller that we finished, via the callback, and then blow away our connection
     // to the controller.  NSTasks are one-shot (not for reuse), so we might as well be too.
     [controller processFinished];
     controller = nil;*/
    NSData *data = [[NSData alloc] init];
    
    // It is important to clean up after ourselves so that we don't leave potentially deallocated
    // objects as observers in the notification center; this can lead to crashes.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadCompletionNotification object: [[gdbtask standardOutput] fileHandleForReading]];
    
    //dejar de obscultar los archivos de la terminal
    //[observadorINPUT removePathFromQueue:[NSString stringWithFormat:@"%@/%@",directorioBase,inPut]];
    //    if ([directorioBase isNotEqualTo:nil] && [outPut isNotEqualTo:nil]) {
    [observadorOUTPUT removePathFromQueue:[NSString stringWithFormat:@"%@/%@",directorioBase,outPut]];
    //    }
    
    // Make sure the task has actually stopped!
    [gdbtask terminate];
    //[execTask terminate];
    while ((data = [[[gdbtask standardOutput] fileHandleForReading] availableData]) && [data length])
    {
        [self postthis:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] withcoolor:[NSColor whiteColor]];
    }
    
}

- (IBAction)Stop_button_click:(id)sender {
    predebugscriptdone = false;
    [VarsPanel orderOut:self];
    
    [self performSelectorOnMainThread:@selector(clean_and_close) withObject:nil waitUntilDone:NO];
    //    [self clean_and_close];
    
    //[terminal hideTerm:[self windowForSheet]];
//    if ([View2Drawer state] == 2) {
//        [View2Drawer toggle:self];
//    }
    //las animaciones se ven bonitas.
    {
        NSView *upS = [[gdbSplitView subviews]objectAtIndex:0];
        NSView *doS = [[gdbSplitView subviews]objectAtIndex:1];
        
        NSMutableDictionary *collapseMainAnimationDict = [NSMutableDictionary dictionaryWithCapacity:2];
        [collapseMainAnimationDict setObject:upS forKey:NSViewAnimationTargetKey];
        NSRect newRightSubViewFrame = upS.frame;
        newRightSubViewFrame.size.width =  gdbSplitView.frame.size.height;
        [collapseMainAnimationDict setObject:[NSValue valueWithRect:newRightSubViewFrame] forKey:NSViewAnimationEndFrameKey];
        
        NSMutableDictionary *collapseInspectorAnimationDict = [NSMutableDictionary dictionaryWithCapacity:2];
        [collapseInspectorAnimationDict setObject:doS forKey:NSViewAnimationTargetKey];
        NSRect newLeftSubViewFrame = doS.frame;
        newLeftSubViewFrame.size.height = 0.0f;
        newLeftSubViewFrame.origin.y = gdbSplitView.frame.size.width;
        [collapseInspectorAnimationDict setObject:[NSValue valueWithRect:newLeftSubViewFrame] forKey:NSViewAnimationEndFrameKey];
        
        NSViewAnimation *collapseAnimation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:collapseMainAnimationDict, collapseInspectorAnimationDict, nil]];
        [collapseAnimation setDuration:0.40f];
        [collapseAnimation startAnimation];
        [gdbSplitView adjustSubviews];
        [gdbSplitView setNeedsDisplay:YES];
    }
    
    // decir STOP
    [self postthis:@"\n stopping " withcoolor:[NSColor redColor]];
}


-(IBAction)clearSlate:(id)sender{
    // clear working directory of any output
    if (nombreOUTput != nil) {  
        //NSLog(@"cleaning %@ ",[nombreArchivo stringByReplacingOccurrencesOfString:@".scif" withString:@""]);
        
        NSString *s = [NSString stringWithFormat:
                       @"tell application \"Terminal\" to do script \"cd / \n cd %@ \n rm *.o *.out %@ \n exit \n\"",directorioBase,[nombreArchivo stringByReplacingOccurrencesOfString:@".scif" withString:@""]];
        NSAppleScript *as = [[NSAppleScript alloc] initWithSource: s];
        [as executeAndReturnError:nil];
    } else {
        NSLog(@"couldn't clean  ;) \n \t staying dirty");
    }
    
}

- (IBAction)changedDrawerSelection:(id)sender {
    //    NSLog(@"%ld",[botonListaDelDrawer indexOfSelectedItem]);
    hoja_anterior = (int)[botonListaDelDrawer indexOfSelectedItem];
    nota *n = (nota*)[[ARRAYcontroller arrangedObjects] objectAtIndex:[botonListaDelDrawer indexOfSelectedItem]];
    NSAttributedString *AtStr = [[NSAttributedString alloc] initWithAttributedString:[n txt]];
    [[NotaiDisclosureTxt textStorage] setAttributedString:AtStr]; 
    [NotaiDisclosureTitleBut setTitle:[n title]];
    [NotaiDisclosureTxt setNeedsDisplay:YES];
}

- (IBAction)closeTheDrawer:(id)sender {
    [NotaiDisclosureButReminder setState:0];
    [View2Drawer toggle:self];
}

-(void)returnPrintVarValue:(NSString*)value{
    
}

-(void)printVariable:(NSNotification*)notification{
    //NSLog(@"%@",[notification description]);
    
    if ([[ARRAYcontroller selectedObjects] count]>0) {
        nota *n = (nota*)[[ARRAYcontroller selectedObjects] objectAtIndex:0];
        if ([n Mi_modo_actual] == 0) {
            if ([gdbtask isRunning]) {
                if (stdinHandle != Nil) {
                    NSString* NewPalabra = [[NSString alloc] initWithString:(NSString*)[[notification userInfo] objectForKey:@"palabra"]];
                    if (![NewPalabra isEqualToString:palabra]) {
                        palabra = NewPalabra;
                        palabraRange = NSMakeRange(
                                                   [(NSNumber*)[[notification userInfo] objectForKey:@"loc"] unsignedLongValue], 
                                                   [(NSNumber*)[[notification userInfo] objectForKey:@"len"] unsignedLongValue]);
                        
                        //NSLog(@"palabra: %@",palabra);
                        
                        //   OPCION 1
                        //    checamos si dicha palabra arroja algún resultado en el gdb
                        
                        NSData *new_input = [[NSString stringWithFormat:@"print %@\n",palabra] dataUsingEncoding:NSUTF8StringEncoding];
                        [stdinHandle writeData:new_input];
                        
                        //   OPCION 2                    
                        
                        //ahora tomamos esa palabra de la lista de variables, El problema con esto es que cuando se usan arrays allocatable, gdb no muestra todas las variables
                        
                        /*
                         if ([self.VarsArray count] > 0) {
                         int i;
                         VarModel* vm = [[VarModel alloc]init];
                         for (i=0; i<[self.VarsArray count]; i++) {
                         vm = (VarModel*)[self.VarsArray objectAtIndex:i];
                         if ([palabra isEqualToString:[vm varName]]) {
                         //bingo
                         NSString* varVal = [[NSString alloc] initWithString:[vm varValue]];
                         varVal = [@" " stringByAppendingFormat:@"%@: %@",palabra,varVal];
                         //[self showOff:varVal here:palabraRange];
                         
                         NSNumber* loc = [[NSNumber alloc] initWithUnsignedLong:palabraRange.location];
                         NSNumber* len = [[NSNumber alloc] initWithUnsignedLong:palabraRange.length];
                         NSDictionary* dada = [[NSDictionary alloc] initWithObjectsAndKeys:
                         varVal,@"varVal",
                         loc,@"loc",
                         len,@"len",
                         nil];
                         [[NSNotificationCenter defaultCenter] postNotificationName:@"mostrarValor" object:nil userInfo:dada];
                         }
                         }
                         }// if varsArray.count
                         */
                        
                    }
                }
            }
        }
    }
}

#pragma mark -
#pragma mark syntax specific
-(void) shouldUpdateArrayController : (NSNotification*)notification
{
    //hoja_anterior
    if ([[ARRAYcontroller arrangedObjects] count] > hoja_anterior) {
        nota*n = [[nota alloc] init];
        n = (nota*)[[ARRAYcontroller arrangedObjects] objectAtIndex:hoja_anterior];
        //NSLog(@"ini:\n%@",n.txt);
        
        n.txt = [[NSAttributedString alloc] initWithAttributedString:[NotaiDisclosureTxt attributedString]];
        
        //NSLog(@"fin:\n%@",n.txt);
        
        nota*nselected = [[ARRAYcontroller selectedObjects] objectAtIndex:0];
        
        if ([nselected isEqual:n]) {
            // es la misma y vale actualizar
            [txtx setNeedsDisplay:YES];
        }
    }
}


/* -----------------------------------------------------------------------------
 processEditing:
 Part of the text was changed. Recolor it.
 -------------------------------------------------------------------------- */

-(void) processEditing: (NSNotification*)notification
{    
    [NSGraphicsContext saveGraphicsState];
    //Este método parece ejecutarse dos veces al iniciar el programa, pero en realidad, 
    //la primera vez se ejecuta acarreando el texto plano, la segunda ya tiene el texto formateado
    
    
    NSTextStorage	*textStorage = [notification object];
	NSRange			range = [textStorage editedRange];
	int				changeInLen = (int)[textStorage changeInLength];
	BOOL			wasInUndoRedo = [[self undoManager] isUndoing] || [[self undoManager] isRedoing];
	BOOL			textLengthMayHaveChanged = NO;
    
    
	// Was delete op or undo that could have changed text length?
	if( wasInUndoRedo )
	{
		textLengthMayHaveChanged = YES;
		range = [txtx selectedRange];
	}
	if( changeInLen <= 0 )
		textLengthMayHaveChanged = YES;
	
	//	Try to get chars around this to recolor any identifier we're in:
	if( textLengthMayHaveChanged )
	{
		if( range.location > 0 )
			range.location--;
		if( (range.location +range.length +2) < [textStorage length] )
			range.length += 2;
		else if( (range.location +range.length +1) < [textStorage length] )
			range.length += 1;
	}
	
	NSRange						currRange = range;
    
    
	// Perform the syntax coloring:
	if( autoSyntaxColoring && range.length > 0 )
	{
		NSRange			effectiveRange;
		NSString*		rangeMode;
		
		
		rangeMode = [textStorage attribute: TD_SYNTAX_COLORING_MODE_ATTR
                                   atIndex: currRange.location
                            effectiveRange: &effectiveRange];
		
		unsigned int		x = (int)range.location;
		
		/* TODO: If we're in a multi-line comment and we're typing a comment-end
         character, or we're in a string and we're typing a quote character,
         this should include the rest of the text up to the next comment/string
         end character in the recalc. */
		
		// Scan up to prev line break:
		while( x > 0 )
		{
			unichar theCh = [[textStorage string] characterAtIndex: x];
			if( theCh == '\n' || theCh == '\r' )
				break;
			--x;
		}
		
		currRange.location = x;
		
		// Scan up to next line break:
		x = (int)range.location +(int)range.length;
		
		while( x < [textStorage length] )
		{
			unichar theCh = [[textStorage string] characterAtIndex: x];
			if( theCh == '\n' || theCh == '\r' )
				break;
			++x;
		}
		
		currRange.length = x -currRange.location;
		
		// Open identifier, comment etc.? Make sure we include the whole range.
		if( rangeMode != nil )
			currRange = NSUnionRange( currRange, effectiveRange );
		
		// Actually recolor the changed part:
		[self recolorRange: currRange];
	}
    // numero de lineas del bloque
    unsigned long letra, numberOfLines, stringLength;
    //el numero de líneas
    letra = 0;
    numberOfLines = 0;
    stringLength = [[txtx string] length];
    NSRange ra;
    long editado = 0;
    do {
        ra = [[txtx string] lineRangeForRange:NSMakeRange(letra, 0)];
        letra = NSMaxRange(ra);
        numberOfLines++;
        if (ra.location <= currRange.location) {
            editado = numberOfLines;
        }
    } while (letra < stringLength);
    //    {
    nota *n = (nota*)[[ARRAYcontroller selectedObjects] objectAtIndex:0];
    int indiceN = (int)[[ARRAYcontroller arrangedObjects] indexOfObject:n];
    if (hoja_anterior == indiceN) {
        if ([View2Drawer state] == 2) {
            NSAttributedString *AtStr = [[NSAttributedString alloc] initWithAttributedString:[n txt]];
            [[NotaiDisclosureTxt textStorage] setAttributedString:AtStr]; 
            [NotaiDisclosureTxt setNeedsDisplay:YES];
        }
    }
    
    
    //        int K = (int)[[ARRAYcontroller arrangedObjects] indexOfObject:n];
    //        hoja_anterior = K;
    [n setLastvisibleRange:[self getViewableRange:txtx]];
    //    }
    if([[ARRAYcontroller selectedObjects] count] > 0) {
        //    {
        //        nota *n = (nota*)[[ARRAYcontroller selectedObjects] objectAtIndex:0];
        //        [n setLastvisibleRange:[self getViewableRange:txtx]];
        //    }
        
        //NSLog(@"\nEsteTextoSeleccionado:\n%@",[[(nota*)[[ARRAYcontroller selectedObjects] objectAtIndex:0] txt] string]);
        //decidir si el numero de lineas en el documento ha cambiado en un bloque de fortran
        if ([(nota*)[[ARRAYcontroller selectedObjects] objectAtIndex:0] Mi_modo_actual] == 0) {
            
            
            //NSLog(@"This works");
            // pedir se actualice el numero de lineas.
            if ([num_de_lineas longValue] != numberOfLines) {
                //NSNumber *n_indice_inicial = [[NSNumber alloc] initWithUnsignedLong:[(nota*)[[ARRAYcontroller selectedObjects] objectAtIndex:0] indice_inicial]];
                NSNumber *n_indice_inicial = [[NSNumber alloc] initWithUnsignedLong:[(nota*)[[ARRAYcontroller selectedObjects] objectAtIndex:0] indice_inicial]];
                
                NSDictionary *Nota_marcadores = [(nota*)[[ARRAYcontroller selectedObjects] objectAtIndex:0] Nota_linesToMarkers];
                
                NSDictionary* dic = [[NSDictionary alloc] initWithObjectsAndKeys:
                                     n_indice_inicial,@"indice_inicial_en_seccion",
                                     Nota_marcadores,@"Diccionario_de_marcadores",
                                     nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ActualizarNumLineaMarcadores" object:nil userInfo:dic];
                
                num_de_lineas = [NSNumber numberWithLong:numberOfLines];
                [num_de_lineas retain];
                [(nota*)[[ARRAYcontroller selectedObjects] objectAtIndex:0] setNoDeLineas_reciente:[[NSNumber alloc] initWithUnsignedLong:numberOfLines]];
                //            [(nota*)[[ARRAYcontroller selectedObjects] objectAtIndex:0] setUpdate_me:YES];
                //n.NoDeLineas_reciente = [[NSNumber alloc] initWithUnsignedLong:numberOfLines];
            }
        }
    }
    [NSGraphicsContext restoreGraphicsState];
}

/* -----------------------------------------------------------------------------
 textView:shouldChangeTextinRange:replacementString:
 Perform indentation-maintaining if we're supposed to.
 -------------------------------------------------------------------------- */

-(BOOL) textView:(NSTextView *)tv shouldChangeTextInRange:(NSRange)afcr replacementString:(NSString *)rps
{
	if( maintainIndentation )
	{
		affectedCharRange = afcr;
		if( replacementString )
		{
			[replacementString release];
			replacementString = nil;
		}
		replacementString = [rps retain];
		
		[self performSelector: @selector(didChangeText) withObject: nil afterDelay: 0.0];	// Queue this up on the event loop. If we change the text here, we only confuse the undo stack.
	}
	
	return YES;
}


-(void)	didChangeText	// This actually does what we want to do in textView:shouldChangeTextInRange:
{
	if( maintainIndentation && replacementString && ([replacementString isEqualToString:@"\n"]
                                                     || [replacementString isEqualToString:@"\r"]) )
	{
		NSMutableAttributedString*  textStore = [txtx textStorage];
		BOOL						hadSpaces = NO;
		unsigned int				lastSpace = (int)affectedCharRange.location,
        prevLineBreak = 0;
		NSRange						spacesRange = { 0, 0 };
		unichar						theChar = 0;
		unsigned int				x = (int)((affectedCharRange.location == 0) ? 0 : affectedCharRange.location -1);
		NSString*					tsString = [textStore string];
		
		while( true )
		{
			if( x > ([tsString length] -1) )
				break;
			
			theChar = [tsString characterAtIndex: x];
			
			switch( theChar )
			{
				case '\n':
				case '\r':
					prevLineBreak = x +1;
					x = 0;  // Terminate the loop.
					break;
                    
				case ' ':
				case '\t':
					if( !hadSpaces )
					{
						lastSpace = x;
						hadSpaces = YES;
					}
					break;
                    
				default:
					hadSpaces = NO;
					break;
			}
			
			if( x == 0 )
				break;
			
			x--;
		}
		
		if( hadSpaces )
		{
			spacesRange.location = prevLineBreak;
			spacesRange.length = lastSpace -prevLineBreak +1;
			if( spacesRange.length > 0 )
				[txtx insertText: [tsString substringWithRange:spacesRange]];
		}
	}
}


/* -----------------------------------------------------------------------------
 toggleAutoSyntaxColoring:
 Action for menu item that toggles automatic syntax coloring on and off.
 -------------------------------------------------------------------------- */

-(IBAction)	toggleAutoSyntaxColoring: (id)sender
{
	[self setAutoSyntaxColoring: ![self autoSyntaxColoring]];
	[self recolorCompleteFile: nil];
}


/* -----------------------------------------------------------------------------
 setAutoSyntaxColoring:
 Accessor to turn automatic syntax coloring on or off.
 -------------------------------------------------------------------------- */

-(void)		setAutoSyntaxColoring: (BOOL)state
{
	autoSyntaxColoring = state;
}

/* -----------------------------------------------------------------------------
 autoSyntaxColoring:
 Accessor for determining whether automatic syntax coloring is on or off.
 -------------------------------------------------------------------------- */

-(BOOL)		autoSyntaxColoring
{
	return autoSyntaxColoring;
}


/* -----------------------------------------------------------------------------
 toggleMaintainIndentation:
 Action for menu item that toggles indentation maintaining on and off.
 -------------------------------------------------------------------------- */

-(IBAction)	toggleMaintainIndentation: (id)sender
{
	[self setMaintainIndentation: ![self maintainIndentation]];
}


/* -----------------------------------------------------------------------------
 setMaintainIndentation:
 Accessor to turn indentation maintaining on or off.
 -------------------------------------------------------------------------- */

-(void)		setMaintainIndentation: (BOOL)state
{
	maintainIndentation = state;
}

/* -----------------------------------------------------------------------------
 maintainIndentation:
 Accessor for determining whether indentation maintaining is on or off.
 -------------------------------------------------------------------------- */

-(BOOL)		maintainIndentation
{
	return maintainIndentation;
}



/* -----------------------------------------------------------------------------
 showGoToPanel:
 Action for menu item that shows the "Go to line" panel.
 -------------------------------------------------------------------------- */

-(IBAction) showGoToPanel: (id)sender
{
	[gotoPanel showGoToSheet: [self windowForSheet]];
}


/* -----------------------------------------------------------------------------
 goToLine:
 This selects the specified line of the document.
 -------------------------------------------------------------------------- */

-(void) toToLineinThisTxt: (int)lineNum {
	NSRange			theRange = { 0, 0 };
	NSString*		vString = [txtx string];
	unsigned		currLine = 1;
	NSCharacterSet* vSet = [NSCharacterSet characterSetWithCharactersInString: @"\n\r"];
	unsigned		x;
	unsigned		lastBreakOffs = 0;
	unichar			lastBreakChar = 0;
	
    
	for( x = 0; x < [vString length]; x++ )
	{
		unichar		theCh = [vString characterAtIndex: x];
		
		// Skip non-linebreak chars:
		if( ![vSet characterIsMember: theCh] )
			continue;
		
		// If this is the LF in a CRLF sequence, only count it as one line break:
		if( theCh == '\n' && lastBreakOffs == (x-1)
           && lastBreakChar == '\r' )
		{
			lastBreakOffs = 0;
			lastBreakChar = 0;
			theRange.location++;
			continue;
		}
		
		// Calc range and increase line number:
		theRange.length = x -theRange.location +1;
		if( currLine >= lineNum )
			break;
		currLine++;
		theRange.location = theRange.location +theRange.length;
		lastBreakOffs = x;
		lastBreakChar = theCh;
	}
	
	//[status setStringValue: [NSString stringWithFormat: @"Characters %u to %u", theRange.location +1, theRange.location +theRange.length]];
	[txtx scrollRangeToVisible: theRange];
	[txtx setSelectedRange: theRange];
}

-(void)	goToLine: (int)lineNum
{
    //    nota *m = (nota*)[[ARRAYcontroller selectedObjects] objectAtIndex:0];
    //    if (lineNum < (int)[m indice_inicial]  ||  lineNum >= [[m NoDeLineas_reciente] intValue]) {
    int kk,acumulado;
    acumulado = 0;
    for (kk=0; kk < [[ARRAYcontroller arrangedObjects] count]; kk++) {
        nota *n = (nota*)[[ARRAYcontroller arrangedObjects] objectAtIndex:kk];
        if ([n Mi_modo_actual] == 0) {
            //NSNumber * nm = [n NoDeLineas_reciente];
            //NSLog(@"%@", [nm stringValue]);
            if ([n NoDeLineas_reciente] != nil) {
                //NSLog(@"%i", [[n NoDeLineas_reciente] intValue]);
            }
            
            acumulado = acumulado + [[n NoDeLineas_reciente] intValue];
            if (acumulado >= lineNum) {
                //aquí está el break
                [ARRAYcontroller setSelectionIndex:kk]; 
                lineNum = lineNum - (int)[n indice_inicial];
                
                break;
            }
        }
    }
    //    }
	
    NSRange			theRange = { 0, 0 };
	NSString*		vString = [txtx string];
	unsigned		currLine = 1;
	NSCharacterSet* vSet = [NSCharacterSet characterSetWithCharactersInString: @"\n\r"];
	unsigned		x;
	unsigned		lastBreakOffs = 0;
	unichar			lastBreakChar = 0;
	
    
	for( x = 0; x < [vString length]; x++ )
	{
		unichar		theCh = [vString characterAtIndex: x];
		
		// Skip non-linebreak chars:
		if( ![vSet characterIsMember: theCh] )
			continue;
		
		// If this is the LF in a CRLF sequence, only count it as one line break:
		if( theCh == '\n' && lastBreakOffs == (x-1)
           && lastBreakChar == '\r' )
		{
			lastBreakOffs = 0;
			lastBreakChar = 0;
			theRange.location++;
			continue;
		}
		
		// Calc range and increase line number:
		theRange.length = x -theRange.location +1;
		if( currLine >= lineNum )
			break;
		currLine++;
		theRange.location = theRange.location +theRange.length;
		lastBreakOffs = x;
		lastBreakChar = theCh;
	}
	
	//[status setStringValue: [NSString stringWithFormat: @"Characters %u to %u", theRange.location +1, theRange.location +theRange.length]];
	[txtx scrollRangeToVisible: theRange];
	[txtx setSelectedRange: theRange];
}


/* -----------------------------------------------------------------------------
 turnOffWrapping:
 Makes the view so wide that text won't wrap anymore.
 -------------------------------------------------------------------------- */

-(void) turnOffWrapping: (NSTextView*) tv
{
    
	const float			LargeNumberForText = 1.0e7;
	NSTextContainer*	textContainer = [tv textContainer];
	NSRect				frame;
	NSScrollView*		ThisscrollView = [tv enclosingScrollView];
	
	// Make sure we can see right edge of line:
    [ThisscrollView setHasHorizontalScroller:YES];
	
	// Make text container so wide it won't wrap:
	[textContainer setContainerSize: NSMakeSize(LargeNumberForText, LargeNumberForText)];
	[textContainer setWidthTracksTextView:NO];    
    [textContainer setHeightTracksTextView:NO];
    
	// Make sure text view is wide enough:
	frame.origin = NSMakePoint(0.0, 0.0);
    frame.size = [ThisscrollView contentSize];
    
    [tv setMaxSize:NSMakeSize(LargeNumberForText, LargeNumberForText)];
    [tv setHorizontallyResizable:YES];
    [tv setVerticallyResizable:YES];
    [tv setAutoresizingMask:NSViewNotSizable];
    
    
}
-(void) turnOnWrapping: (NSTextView*) tv
{
    [[tv enclosingScrollView] setHasHorizontalScroller:NO];
    [[tv textContainer] setContainerSize:NSMakeSize(1000.000000, 10000000.000000)];
    //[[txtx textContainer] setContainerSize:[[txtx enclosingScrollView] contentSize]];
    [[tv textContainer] setWidthTracksTextView:FALSE];
    [[tv textContainer] setHeightTracksTextView:FALSE];
    
    [tv setMaxSize:NSMakeSize(1000, 10000000)];
    [tv setHorizontallyResizable:YES];
    [tv setVerticallyResizable:YES];
    [tv setAutoresizingMask:NSViewWidthSizable+NSViewHeightSizable];
    
    //[txtx textContainer] 
}



/* -----------------------------------------------------------------------------
 goToCharacter:
 This selects the specified character in the document.
 -------------------------------------------------------------------------- */

-(void)	goToCharacter: (int)charNum
{
	[self goToRangeFrom: charNum toChar: charNum +1];
}

-(void) goToRangeFrom: (int)startCh toChar: (int)endCh
{
	NSRange		theRange = { 0, 0 };
    
	theRange.location = startCh -1;
	theRange.length = endCh -startCh;
	
	if( startCh == 0 || startCh > [[txtx string] length] )
		return;
	
	//[status setStringValue: [NSString stringWithFormat: @"Characters %u to %u",theRange.location +1, theRange.location +theRange.length]];
	[txtx scrollRangeToVisible: theRange];
	[txtx setSelectedRange: theRange];
}

-(IBAction) indentSelection: (id)sender
{
	[[self undoManager] registerUndoWithTarget: self selector: @selector(unindentSelection:) object: nil];
	
	NSRange				selRange = [txtx selectedRange],
    nuSelRange = selRange;
	unsigned			x;
	NSMutableString*	str = [[txtx textStorage] mutableString];
	
	// Unselect any trailing returns so we don't indent the next line after a full-line selection.
	if( selRange.length > 1 && ([str characterAtIndex: selRange.location +selRange.length -1] == '\n'
                                || [str characterAtIndex: selRange.location +selRange.length -1] == '\r') )
		selRange.length--;
	
	for( x = (int)(selRange.location +selRange.length -1); x >= (int)selRange.location; x-- )
	{
		if( [str characterAtIndex: x] == '\n'
           || [str characterAtIndex: x] == '\r' )
		{
			[str insertString: @"\t" atIndex: x+1];
			nuSelRange.length++;
		}
		
		if( x == 0 )
			break;
	}
	
	[str insertString: @"\t" atIndex: nuSelRange.location];
	nuSelRange.length++;
	[txtx setSelectedRange: nuSelRange];
}

-(IBAction) unindentSelection: (id)sender
{
	NSRange				selRange = [txtx selectedRange],
    nuSelRange = selRange;
	unsigned			x, n;
	unsigned			lastIndex = (int)(selRange.location +selRange.length -1);
	NSMutableString*	str = [[txtx textStorage] mutableString];
	
	// Unselect any trailing returns so we don't indent the next line after a full-line selection.
	if( selRange.length > 1 && ([str characterAtIndex: selRange.location +selRange.length -1] == '\n'
                                || [str characterAtIndex: selRange.location +selRange.length -1] == '\r') )
		selRange.length--;
	
	if( selRange.length == 0 )
		return;
	
	[[self undoManager] registerUndoWithTarget: self selector: @selector(indentSelection:) object: nil];
	
	for( x = lastIndex; x >= selRange.location; x-- )
	{
		if( [str characterAtIndex: x] == '\n'
           || [str characterAtIndex: x] == '\r' )
		{
			if( (x +1) <= lastIndex)
			{
				if( [str characterAtIndex: x+1] == '\t' )
				{
					[str deleteCharactersInRange: NSMakeRange(x+1,1)];
					nuSelRange.length--;
				}
				else
				{
					for( n = x+1; (n <= (x+4)) && (n <= lastIndex); n++ )
					{
						if( [str characterAtIndex: x+1] != ' ' )
							break;
						[str deleteCharactersInRange: NSMakeRange(x+1,1)];
						nuSelRange.length--;
					}
				}
			}
		}
		
		if( x == 0 )
			break;
	}
	
	if( [str characterAtIndex: nuSelRange.location] == '\t' )
	{
		[str deleteCharactersInRange: NSMakeRange(nuSelRange.location,1)];
		nuSelRange.length--;
	}
	else
	{
		for( n = 1; (n <= 4) && (n <= lastIndex); n++ )
		{
			if( [str characterAtIndex: nuSelRange.location] != ' ' )
				break;
			[str deleteCharactersInRange: NSMakeRange(nuSelRange.location,1)];
			nuSelRange.length--;
		}
	}
	
	[txtx setSelectedRange: nuSelRange];
}

// esto no es del la sintaxis
-(IBAction) findSomething: (id)sender{
    todoEldocumento = false;
    [[txtx window] makeFirstResponder:searchField];
}

-(IBAction) findSomethingOnAllDocument:(id)sender{
    todoEldocumento = true;
    [[txtx window] makeFirstResponder:searchField];
}

/* -----------------------------------------------------------------------------
 validateMenuItem:
 Make sure check marks of the "Toggle auto syntax coloring" and "Maintain
 indentation" menu items are set up properly.
 -------------------------------------------------------------------------- */

-(BOOL)	validateMenuItem:(NSMenuItem*)menuItem
{
	if( [menuItem action] == @selector(toggleAutoSyntaxColoring:) )
	{
		[menuItem setState: [self autoSyntaxColoring]];
		return YES;
	}
	else if( [menuItem action] == @selector(toggleMaintainIndentation:) )
	{
		[menuItem setState: [self maintainIndentation]];
		return YES;
	}
	else
		return [super validateMenuItem: menuItem];
}


/* -----------------------------------------------------------------------------
 recolorCompleteFile:
 IBAction to do a complete recolor of the whole friggin' document.
 This is called once after the document's been loaded and leaves some
 custom styles in the document which are used by recolorRange to properly
 perform recoloring of parts.
 -------------------------------------------------------------------------- */

-(IBAction)	recolorCompleteFile: (id)sender
{
	if( sourceCode != nil && txtx )
	{
		[txtx setString: sourceCode]; // Causes recoloring notification.
		[sourceCode release];
		sourceCode = nil;
	}
	else
	{
		NSRange		range = NSMakeRange(0,[[txtx textStorage] length]);
		[self recolorRange: range];
	}
}

-(NSAttributedString*) preProssText:(NSString*)txt oftype:(NSString*)type {
    NSRange range = NSMakeRange(0, [txt length]);
    
    // Perform the syntax coloring:
	if( autoSyntaxColoring && range.length > 0 )
	{
		// Actually recolor:
        if( syntaxColoringBusy )	// Prevent endless loop when recoloring's replacement of text causes processEditing to fire again.
            return nil;
        if( recolorTimer)
            return nil;
        syntaxColoringBusy = YES;
        NSMutableAttributedString*	vString = [[NSMutableAttributedString alloc] initWithString: [txt substringWithRange: range]];
        [vString autorelease];
        
        // Load colors and fonts to use from preferences:
        
        // Load our dictionary which contains info on coloring this language:
        
        NSDictionary* vSyntaxDefinition = [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource: type ofType:@"plist"]];
        //NSDictionary*				vSyntaxDefinition = [self syntaxDefinitionDictionary];
        NSEnumerator*				vComponentsEnny = [[vSyntaxDefinition objectForKey: @"Components"] objectEnumerator];
        
        // Loop over all available components:
        NSDictionary*				vCurrComponent = nil;
        NSDictionary*				vStyles = [self defaultTextAttributes];
        NSDictionary*               vBlank = [self defaultTextAttributeBLANK];
        NSUserDefaults*				vPrefs = [NSUserDefaults standardUserDefaults];
        
        
        [vString addAttributes: vBlank range: NSMakeRange( 0, [vString length] )];
        //[[txtx textStorage] replaceCharactersInRange: range withAttributedString: vString];
        
        while( (vCurrComponent = [vComponentsEnny nextObject]) )
        {
            NSString*   vComponentType = [vCurrComponent objectForKey: @"Type"];
            NSString*   vComponentName = [vCurrComponent objectForKey: @"Name"];
            NSString*   vColorKeyName = [@"SyntaxColoring:Color:" stringByAppendingString: vComponentName];
            NSColor*	vColor = [[vPrefs arrayForKey: vColorKeyName] colorValue];
            
            if( !vColor )
                vColor = [[vCurrComponent objectForKey: @"Color"] colorValue];
            
            if( [vComponentType isEqualToString: @"BlockComment"] )
            {
                [self colorCommentsFrom: [vCurrComponent objectForKey: @"Start"]
                                     to: [vCurrComponent objectForKey: @"End"] inString: vString
                              withColor: vColor andMode: vComponentName];
            }
            else if( [vComponentType isEqualToString: @"OneLineComment"] )
            {
                [self colorOneLineComment: [vCurrComponent objectForKey: @"Start"]
                                 inString: vString withColor: vColor andMode: vComponentName];
            }
            else if( [vComponentType isEqualToString: @"String"] )
            {
                [self colorStringsFrom: [vCurrComponent objectForKey: @"Start"]
                                    to: [vCurrComponent objectForKey: @"End"]
                              inString: vString withColor: vColor andMode: vComponentName
                         andEscapeChar: [vCurrComponent objectForKey: @"EscapeChar"]]; 
            }
            else if( [vComponentType isEqualToString: @"Tag"] )
            {
                [self colorTagFrom: [vCurrComponent objectForKey: @"Start"]
                                to: [vCurrComponent objectForKey: @"End"] inString: vString
                         withColor: vColor andMode: vComponentName
                      exceptIfMode: [vCurrComponent objectForKey: @"IgnoredComponent"]];
            }
            else if( [vComponentType isEqualToString: @"Keywords"] )
            {
                NSArray* vIdents = [vCurrComponent objectForKey: @"Keywords"];
                if( !vIdents )
                    vIdents = [[NSUserDefaults standardUserDefaults] objectForKey: [@"SyntaxColoring:Keywords:" stringByAppendingString: vComponentName]];
                if( !vIdents && [vComponentName isEqualToString: @"UserIdentifiers"] )
                    vIdents = [[NSUserDefaults standardUserDefaults] objectForKey: TD_USER_DEFINED_IDENTIFIERS];
                if( vIdents )
                {
                    NSCharacterSet*		vIdentCharset = nil;
                    NSString*			vCurrIdent = nil;
                    NSString*			vCsStr = [vCurrComponent objectForKey: @"Charset"];
                    if( vCsStr )
                        vIdentCharset = [NSCharacterSet characterSetWithCharactersInString: vCsStr];
                    
                    NSEnumerator*	vItty = [vIdents objectEnumerator];
                    while( vCurrIdent = [vItty nextObject] )
                        [self colorIdentifier: vCurrIdent inString: vString withColor: vColor
                                      andMode: vComponentName charset: vIdentCharset];
                }
            }
        }
        
        // Replace the range with our recolored part:
        [vString addAttributes: vStyles range: NSMakeRange( 0, [vString length] )];
        //[[txtx textStorage] replaceCharactersInRange: range withAttributedString: vString];
        
        syntaxColoringBusy = NO;
        
        
        NSAttributedString* atSTR = [[NSAttributedString alloc] initWithAttributedString:vString];
        return atSTR;
        //[progress stopAnimation:nil];
        
	}
    NSAttributedString* atSTRnull = [[NSAttributedString alloc] initWithString:txt];
    return atSTRnull;
}

/* -----------------------------------------------------------------------------
 recolorRange:
 Try to apply syntax coloring to the text in our text view. This
 overwrites any styles the text may have had before. This function
 guarantees that it'll preserve the selection.
 
 Note that the order in which the different things are colorized is
 important. E.g. identifiers go first, followed by comments, since that
 way colors are removed from identifiers inside a comment and replaced
 with the comment color, etc. 
 
 The range passed in here is special, and may not include partial
 identifiers or the end of a comment. Make sure you include the entire
 multi-line comment etc. or it'll lose color.
 
 This calls oldRecolorRange to handle old-style syntax definitions.
 -------------------------------------------------------------------------- */

-(void)		recolorRange: (NSRange)range
{
	if( syntaxColoringBusy )	// Prevent endless loop when recoloring's replacement of text causes processEditing to fire again.
		return;
	
	if( txtx == nil || range.length == 0	// Don't like doing useless stuff.
       || recolorTimer )						// And don't like recoloring partially if a full recolorization is pending.
		return;
	
	// Kludge fix for case where we sometimes exceed text length:ra
	int diff = (int)([[txtx textStorage] length] -(range.location +range.length));
	if( diff < 0 )
		range.length += diff;
	
	NS_DURING
    syntaxColoringBusy = YES;
    //[progress startAnimation:nil];
    
    //[status setStringValue: [NSString stringWithFormat: @"Recoloring syntax in %@", NSStringFromRange(range)]];
    
    // Get the text we'll be working with:
    //NSRange						vOldSelection = [txtx selectedRange];
    NSMutableAttributedString*	vString = [[NSMutableAttributedString alloc] initWithString: [[[txtx textStorage] string] substringWithRange: range]];
    [vString autorelease];
    
    // Load colors and fonts to use from preferences:
    
    // Load our dictionary which contains info on coloring this language:
    NSDictionary*				vSyntaxDefinition = [self syntaxDefinitionDictionary];
    NSEnumerator*				vComponentsEnny = [[vSyntaxDefinition objectForKey: @"Components"] objectEnumerator];
    
    if( vComponentsEnny == nil )	// No new-style list of components to colorize? Use old code.
    {
#if TD_BACKWARDS_COMPATIBLE
        syntaxColoringBusy = NO;
        [self oldRecolorRange: range];
#endif
        NS_VOIDRETURN;
    }
    
    // Loop over all available components:
    NSDictionary*				vCurrComponent = nil;
    NSDictionary*				vStyles = [self defaultTextAttributes];
    NSDictionary*               vBlank = [self defaultTextAttributeBLANK];
    NSUserDefaults*				vPrefs = [NSUserDefaults standardUserDefaults];
    
    
    [vString addAttributes: vBlank range: NSMakeRange( 0, [vString length] )];
    [[txtx textStorage] replaceCharactersInRange: range withAttributedString: vString];
    
    while( (vCurrComponent = [vComponentsEnny nextObject]) )
    {
        NSString*   vComponentType = [vCurrComponent objectForKey: @"Type"];
        NSString*   vComponentName = [vCurrComponent objectForKey: @"Name"];
        NSString*   vColorKeyName = [@"SyntaxColoring:Color:" stringByAppendingString: vComponentName];
        NSColor*	vColor = [[vPrefs arrayForKey: vColorKeyName] colorValue];
        
        if( !vColor )
            vColor = [[vCurrComponent objectForKey: @"Color"] colorValue];
        
        if( [vComponentType isEqualToString: @"BlockComment"] )
        {
            [self colorCommentsFrom: [vCurrComponent objectForKey: @"Start"]
                                 to: [vCurrComponent objectForKey: @"End"] inString: vString
                          withColor: vColor andMode: vComponentName];
        }
        else if( [vComponentType isEqualToString: @"OneLineComment"] )
        {
            [self colorOneLineComment: [vCurrComponent objectForKey: @"Start"]
                             inString: vString withColor: vColor andMode: vComponentName];
        }
        else if( [vComponentType isEqualToString: @"String"] )
        {
            [self colorStringsFrom: [vCurrComponent objectForKey: @"Start"]
                                to: [vCurrComponent objectForKey: @"End"]
                          inString: vString withColor: vColor andMode: vComponentName
                     andEscapeChar: [vCurrComponent objectForKey: @"EscapeChar"]]; 
        }
        else if( [vComponentType isEqualToString: @"Tag"] )
        {
            [self colorTagFrom: [vCurrComponent objectForKey: @"Start"]
                            to: [vCurrComponent objectForKey: @"End"] inString: vString
                     withColor: vColor andMode: vComponentName
                  exceptIfMode: [vCurrComponent objectForKey: @"IgnoredComponent"]];
        }
        else if( [vComponentType isEqualToString: @"Keywords"] )
        {
            NSArray* vIdents = [vCurrComponent objectForKey: @"Keywords"];
            if( !vIdents )
                vIdents = [[NSUserDefaults standardUserDefaults] objectForKey: [@"SyntaxColoring:Keywords:" stringByAppendingString: vComponentName]];
            if( !vIdents && [vComponentName isEqualToString: @"UserIdentifiers"] )
                vIdents = [[NSUserDefaults standardUserDefaults] objectForKey: TD_USER_DEFINED_IDENTIFIERS];
            if( vIdents )
            {
                NSCharacterSet*		vIdentCharset = nil;
                NSString*			vCurrIdent = nil;
                NSString*			vCsStr = [vCurrComponent objectForKey: @"Charset"];
                if( vCsStr )
                    vIdentCharset = [NSCharacterSet characterSetWithCharactersInString: vCsStr];
                
                NSEnumerator*	vItty = [vIdents objectEnumerator];
                while( vCurrIdent = [vItty nextObject] )
                    [self colorIdentifier: vCurrIdent inString: vString withColor: vColor
                                  andMode: vComponentName charset: vIdentCharset];
            }
        }
    }
    
    // Replace the range with our recolored part:
    [vString addAttributes: vStyles range: NSMakeRange( 0, [vString length] )];
    [[txtx textStorage] replaceCharactersInRange: range withAttributedString: vString];
    
    //[progress stopAnimation:nil];
    syntaxColoringBusy = NO;
	NS_HANDLER
    syntaxColoringBusy = NO;
    //[progress stopAnimation:nil];
    [localException raise];
	NS_ENDHANDLER
}

/* -----------------------------------------------------------------------------
 oldRecolorRange:
 Try to apply syntax coloring to the text in our text view. This
 overwrites any styles the text may have had before. This function
 guarantees that it'll preserve the selection.
 
 Note that the order in which the different things are colorized is
 important. E.g. identifiers go first, followed by comments, since that
 way colors are removed from identifiers inside a comment and replaced
 with the comment color, etc. 
 
 The range passed in here is special, and may not include partial
 identifiers or the end of a comment. Make sure you include the entire
 multi-line comment etc. or it'll lose color.
 
 TODO: Anybody have any bright ideas how to refactor this?
 -------------------------------------------------------------------------- */

#if TD_BACKWARDS_COMPATIBLE
-(void)		oldRecolorRange: (NSRange)range
{
	if( syntaxColoringBusy )	// Prevent endless loop when recoloring's replacement of text causes processEditing to fire again.
		return;
	
	if( txtx == nil || range.length == 0	// Don't like doing useless stuff.
       || recolorTimer )						// And don't like recoloring partially if a full recolorization is pending.
		return;
	
	NS_DURING
    syntaxColoringBusy = YES;
    //[progress startAnimation:nil];
    
    //[status setStringValue: [NSString stringWithFormat: @"Recoloring syntax in %@", NSStringFromRange(range)]];
    
    // Get the text we'll be working with:
    NSRange						vOldSelection = [txtx selectedRange];
    NSMutableAttributedString*	vString = [[NSMutableAttributedString alloc] initWithString: [[[txtx textStorage] string] substringWithRange: range]];
    [vString autorelease];
    
    // The following should probably be loaded from a dictionary in some file, to allow adaptation to various languages:
    NSDictionary*				vSyntaxDefinition = [self syntaxDefinitionDictionary];
    NSString*					vBlockCommentStart = [vSyntaxDefinition objectForKey: @"BlockComment:Start"];
    NSString*					vBlockCommentEnd = [vSyntaxDefinition objectForKey: @"BlockComment:End"];
    NSString*					vBlockComment2Start = [vSyntaxDefinition objectForKey: @"BlockComment2:Start"];
    NSString*					vBlockComment2End = [vSyntaxDefinition objectForKey: @"BlockComment2:End"];
    NSString*					vOneLineCommentStart = [vSyntaxDefinition objectForKey: @"OneLineComment:Start"];
    NSString*					vTagStart = [vSyntaxDefinition objectForKey: @"Tag:Start"];
    NSString*					vTagEnd = [vSyntaxDefinition objectForKey: @"Tag:End"];
    NSString*					vTagIgnoredStyle = [vSyntaxDefinition objectForKey: @"Tag:IgnoredStyle"];
    NSString*					vStringEscapeCharacter = [vSyntaxDefinition objectForKey: @"String:EscapeChar"];
    NSCharacterSet*				vIdentCharset = nil;
    NSString*					vCsStr = [vSyntaxDefinition objectForKey: @"Identifiers:Charset"];
    if( vCsStr )
        vIdentCharset = [NSCharacterSet characterSetWithCharactersInString: vCsStr];
    
    // Load colors and fonts to use from preferences:
    NSUserDefaults*				vPrefs = [NSUserDefaults standardUserDefaults];
    NSColor*					vPreprocessorColor = [[vPrefs arrayForKey: @"SyntaxColoring:Color:Preprocessor"] colorValue];
    NSColor*					vCommentColor = [[vPrefs arrayForKey: @"SyntaxColoring:Color:Comments"] colorValue];
    NSColor*					vComment2Color = [[vPrefs arrayForKey: @"SyntaxColoring:Color:Comments2"] colorValue];
    NSColor*					vStringColor = [[vPrefs arrayForKey: @"SyntaxColoring:Color:Strings"] colorValue];
    NSColor*					vIdentifierColor = [[vPrefs arrayForKey: @"SyntaxColoring:Color:Identifiers"] colorValue];
    NSColor*					vIdentifier2Color = [[vPrefs arrayForKey: @"SyntaxColoring:Color:Identifiers2"] colorValue];
    NSColor*					vTagColor = [[vPrefs arrayForKey: @"SyntaxColoring:Color:Tags"] colorValue];
    NSDictionary*				vStyles = [self defaultTextAttributes];
    
    // Color identifiers listed in "Identifiers" entry:
    NSString*		vCurrIdent;
    NSArray*		vIdents = [vSyntaxDefinition objectForKey: @"Identifiers"];
    if( vIdents )
    {
        NSEnumerator*	vItty = [vIdents objectEnumerator];
        while( vCurrIdent = [vItty nextObject] )
            [self colorIdentifier: vCurrIdent inString:vString withColor: vIdentifierColor
                          andMode: TD_IDENTIFIER_ATTR charset: vIdentCharset];
    }
    
    // Color identifiers listed in "Identifiers2" entry:
    vIdents = [vSyntaxDefinition objectForKey: @"Identifiers2"];
    if( !vIdents )
        vIdents = [[NSUserDefaults standardUserDefaults] objectForKey: TD_USER_DEFINED_IDENTIFIERS];
    if( vIdents )
    {
        NSEnumerator*	vItty = [vIdents objectEnumerator];
        while( vCurrIdent = [vItty nextObject] )
            [self colorIdentifier: vCurrIdent inString:vString withColor: vIdentifier2Color
                          andMode: TD_IDENTIFIER2_ATTR charset: vIdentCharset];
    }
    
    // Colorize comments, strings etc, obliterating any identifiers inside them:
    [self colorStringsFrom: @"\"" to: @"\"" inString: vString withColor: vStringColor andMode: TD_DOUBLE_QUOTED_STRING_ATTR andEscapeChar: vStringEscapeCharacter];   // Strings.
	
    // Colorize colorize any tags:
    if( vTagStart )
        [self colorTagFrom: vTagStart to: vTagEnd inString: vString withColor: vTagColor andMode: TD_TAG_ATTR exceptIfMode: vTagIgnoredStyle];
    
    // Preprocessor directives:
    if( vIdents )
    {
        vIdents = [vSyntaxDefinition objectForKey: @"PreprocessorDirectives"];
        NSEnumerator* vItty = [vIdents objectEnumerator];
        while( vCurrIdent = [vItty nextObject] )
            [self colorOneLineComment: vCurrIdent inString: vString withColor: vPreprocessorColor andMode: TD_PREPROCESSOR_ATTR];	// TODO Preprocessor directives should make sure they're at the start of a line, and that whitespace follows the directive.
    }
    
    // Comments:
    if( vOneLineCommentStart )
        [self colorOneLineComment: vOneLineCommentStart inString: vString withColor: vCommentColor andMode: TD_ONE_LINE_COMMENT_ATTR];
    if( vBlockCommentStart )
        [self colorCommentsFrom: vBlockCommentStart to: vBlockCommentEnd inString: vString withColor:vCommentColor andMode: TD_MULTI_LINE_COMMENT_ATTR];
    if( vBlockComment2Start )
        [self colorCommentsFrom: vBlockComment2Start to: vBlockComment2End inString: vString withColor:vComment2Color andMode: TD_MULTI_LINE_COMMENT2_ATTR];
    
    // Replace the range with our recolored part:
    [vString addAttributes: vStyles range: NSMakeRange( 0, [vString length] )];
    [[txtx textStorage] replaceCharactersInRange: range withAttributedString: vString];
    
    NS_DURING
    [txtx setSelectedRange:vOldSelection];  // Restore selection.
    NS_HANDLER
    NS_ENDHANDLER
	
    //[progress stopAnimation:nil];
    syntaxColoringBusy = NO;
	NS_HANDLER
    syntaxColoringBusy = NO;
    //[progress stopAnimation:nil];
    [localException raise];
	NS_ENDHANDLER
}
#endif

/* -----------------------------------------------------------------------------
 textView:willChangeSelectionFromCharacterRange:toCharacterRange:
 Delegate method called when our selection changes. Updates our status
 display to indicate which characters are selected.
 -------------------------------------------------------------------------- */

-(NSRange)  textView: (NSTextView*)theTextView willChangeSelectionFromCharacterRange: (NSRange)oldSelectedCharRange
    toCharacterRange:(NSRange)newSelectedCharRange
{
	unsigned		startCh = (int)(newSelectedCharRange.location +1),
    endCh = (int)(newSelectedCharRange.location +newSelectedCharRange.length);
	unsigned		lineNo = 1,
    lastLineStart = 0,
    x;
	unsigned		startChLine, endChLine;
	unichar			lastBreakChar = 0;
	unsigned		lastBreakOffs = 0;
    
	// Calc line number:
	for( x = 0; (x < startCh) && (x < [[theTextView string] length]); x++ )
	{
		unichar		theCh = [[theTextView string] characterAtIndex: x];
		switch( theCh )
		{
			case '\n':
				if( lastBreakOffs == (x-1) && lastBreakChar == '\r' )   // LF in CRLF sequence? Treat this as a single line break.
				{
					lastBreakOffs = 0;
					lastBreakChar = 0;
					continue;
				}
				// Else fall through!
				
			case '\r':
				lineNo++;
				lastLineStart = x +1;
				lastBreakOffs = x;
				lastBreakChar = theCh;
				break;
		}
	}
	
	startChLine = (int)((newSelectedCharRange.location -lastLineStart) +1);
	endChLine = (int)((newSelectedCharRange.location -lastLineStart) +newSelectedCharRange.length);
	
	NSImage*	img = nil;
	
	// Display info:
	if( startCh > endCh )   // Insertion mark!
	{
		img = [NSImage imageNamed: @"InsertionMark"];
		//[status setStringValue: [NSString stringWithFormat: @"char %u, line %u (char %u in document)", startChLine, lineNo, startCh]];
	}
	else					// Selection
	{
		img = [NSImage imageNamed: @"SelectionRange"];
		//[status setStringValue: [NSString stringWithFormat: @"char %u to %u, line %u (char %u to %u in document)", startChLine, endChLine, lineNo, startCh, endCh]];
	}
	
	//[selectionKindImage setImage: img];
	
	return newSelectedCharRange;
}


/* -----------------------------------------------------------------------------
 syntaxDefinitionFilename:
 Like windowNibName, this should return the name of the syntax
 definition file to use. Advanced users may use this to allow different
 coloring to take place depending on the file extension by returning
 different file names here.
 
 Note that the ".plist" extension is automatically appended to the file
 name.
 -------------------------------------------------------------------------- */

-(NSString*)	syntaxDefinitionFilename
{
    NSString* modo;
    switch (modo_seleccionado) {
        case 0:
            modo = @"Fortran";
            break;
        case 1:
            modo = @"Latex";
            break;
        case 2:
            modo = @"LatexCalc";
            break;
        case 3:
            modo = @"invisible";
            break;
        default:
            modo = @"Fortran";
            break;
    }
	return modo;
}

/* -----------------------------------------------------------------------------
 syntaxDefinitionDictionary:
 This returns the syntax definition dictionary to use, which indicates
 what ranges of text to colorize. Advanced users may use this to allow
 different coloring to take place depending on the file extension by
 returning different dictionaries here.
 
 By default, this simply reads a dictionary from the .plist file
 indicated by -syntaxDefinitionFilename.
 -------------------------------------------------------------------------- */

-(NSDictionary*)	syntaxDefinitionDictionary
{
	return [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource: [self syntaxDefinitionFilename] ofType:@"plist"]];
}


/* -----------------------------------------------------------------------------
 colorStringsFrom:
 Apply syntax coloring to all strings. This is basically the same code
 as used for multi-line comments, except that it ignores the end
 character if it is preceded by a backslash.
 -------------------------------------------------------------------------- */

-(void)	colorStringsFrom: (NSString*) startCh to: (NSString*) endCh inString: (NSMutableAttributedString*) s
               withColor: (NSColor*) col andMode:(NSString*)attr andEscapeChar: (NSString*)vStringEscapeCharacter
{
	NS_DURING
    NSScanner*					vScanner = [NSScanner scannerWithString: [s string]];
    NSDictionary*				vStyles = [NSDictionary dictionaryWithObjectsAndKeys:
                                           col, NSForegroundColorAttributeName,
                                           attr, TD_SYNTAX_COLORING_MODE_ATTR,
                                           nil];
    BOOL						vIsEndChar = NO;
    unichar						vEscChar = '\\';
    
    if( vStringEscapeCharacter )
    {
        if( [vStringEscapeCharacter length] != 0 )
            vEscChar = [vStringEscapeCharacter characterAtIndex: 0];
    }
    
    while( ![vScanner isAtEnd] )
    {
        int		vStartOffs,
        vEndOffs;
        vIsEndChar = NO;
        
        // Look for start of string:
        [vScanner scanUpToString: startCh intoString: nil];
        vStartOffs = (int)[vScanner scanLocation];
        if( ![vScanner scanString:startCh intoString:nil] )
            NS_VOIDRETURN;
        
        while( !vIsEndChar && ![vScanner isAtEnd] )	// Loop until we find end-of-string marker or our text to color is finished:
        {
            [vScanner scanUpToString: endCh intoString: nil];
            if( ([vStringEscapeCharacter length] == 0) || [[s string] characterAtIndex: ([vScanner scanLocation] -1)] != vEscChar )	// Backslash before the end marker? That means ignore the end marker.
                vIsEndChar = YES;	// A real one! Terminate loop.
            if( ![vScanner scanString:endCh intoString:nil] )	// But skip this char before that.
                NS_VOIDRETURN;
            
            //[progress animate:nil];
        }
        
        vEndOffs = (int)[vScanner scanLocation];
        
        // Now mess with the string's styles:
        [s setAttributes: vStyles range: NSMakeRange( vStartOffs, vEndOffs -vStartOffs )];
    }
	NS_HANDLER
    // Just ignore it, syntax coloring isn't that important.
	NS_ENDHANDLER
}



/* -----------------------------------------------------------------------------
 colorCommentsFrom:
 Colorize block-comments in the text view.
 
 REVISIONS:
 2004-05-18  witness Documented.
 -------------------------------------------------------------------------- */

-(void)	colorCommentsFrom: (NSString*) startCh to: (NSString*) endCh inString: (NSMutableAttributedString*) s
                withColor: (NSColor*) col andMode:(NSString*)attr
{
	NS_DURING
    NSScanner*					vScanner = [NSScanner scannerWithString: [s string]];
    NSDictionary*				vStyles = [NSDictionary dictionaryWithObjectsAndKeys:
                                           col, NSForegroundColorAttributeName,
                                           attr, TD_SYNTAX_COLORING_MODE_ATTR,
                                           nil];
    
    while( ![vScanner isAtEnd] )
    {
        int		vStartOffs,
        vEndOffs;
        
        // Look for start of multi-line comment:
        [vScanner scanUpToString: startCh intoString: nil];
        vStartOffs = (int)[vScanner scanLocation];
        if( ![vScanner scanString:startCh intoString:nil] )
            NS_VOIDRETURN;
        
        // Look for associated end-of-comment marker:
        [vScanner scanUpToString: endCh intoString: nil];
        if( ![vScanner scanString:endCh intoString:nil] ){
            //NSLog(@" ");
            NS_VOIDRETURN;  // Don't exit. If user forgot trailing marker, indicate this by "bleeding" until end of string.
        }
        vEndOffs = (int)[vScanner scanLocation];
        
        // Now mess with the string's styles:
        [s setAttributes: vStyles range: NSMakeRange( vStartOffs, vEndOffs -vStartOffs )];
        
        //[progress animate:nil];
    }
	NS_HANDLER
    // Just ignore it, syntax coloring isn't that important.
	NS_ENDHANDLER
}


/* -----------------------------------------------------------------------------
 colorOneLineComment:
 Colorize one-line-comments in the text view.
 
 REVISIONS:
 2004-05-18  witness Documented.
 -------------------------------------------------------------------------- */

-(void)	colorOneLineComment: (NSString*) startCh inString: (NSMutableAttributedString*) s
                  withColor: (NSColor*) col andMode:(NSString*)attr
{
	NS_DURING
    NSScanner*					vScanner = [NSScanner scannerWithString: [s string]];
    NSDictionary*				vStyles = [NSDictionary dictionaryWithObjectsAndKeys:
                                           col, NSForegroundColorAttributeName,
                                           attr, TD_SYNTAX_COLORING_MODE_ATTR,
                                           nil];
    
    while( ![vScanner isAtEnd] )
    {
        int		vStartOffs,
        vEndOffs;
        
        // Look for start of one-line comment:
        [vScanner scanUpToString: startCh intoString: nil];
        vStartOffs = (int)[vScanner scanLocation];
        if( ![vScanner scanString:startCh intoString:nil] )
            NS_VOIDRETURN;
        
        // Look for associated line break:
        if( ![vScanner skipUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString: @"\n\r"]] ){}
            //NSLog(@" ");
        //;
        
        vEndOffs = (int)[vScanner scanLocation];
        
        // Now mess with the string's styles:
        [s setAttributes: vStyles range: NSMakeRange( vStartOffs, vEndOffs -vStartOffs )];
        
        //[progress animate:nil];
    }
	NS_HANDLER
    // Just ignore it, syntax coloring isn't that important.
	NS_ENDHANDLER
}


/* -----------------------------------------------------------------------------
 colorIdentifier:
 Colorize keywords in the text view.
 
 REVISIONS:
 2004-05-18  witness Documented.
 -------------------------------------------------------------------------- */

-(void)	colorIdentifier: (NSString*) ident inString: (NSMutableAttributedString*) s
              withColor: (NSColor*) col andMode:(NSString*)attr charset: (NSCharacterSet*)cset
{
	NS_DURING
    NSScanner*					vScanner = [NSScanner scannerWithString: [s string]];
    NSDictionary*				vStyles = [NSDictionary dictionaryWithObjectsAndKeys:
                                           col, NSForegroundColorAttributeName,
                                           attr, TD_SYNTAX_COLORING_MODE_ATTR,
                                           nil];
    int							vStartOffs = 0;
    
    // Skip any leading whitespace chars, somehow NSScanner doesn't do that:
    if( cset )
    {
        while( vStartOffs < [[s string] length] )
        {
            if( [cset characterIsMember: [[s string] characterAtIndex: vStartOffs]] )
                break;
            vStartOffs++;
        }
    }
    
    [vScanner setScanLocation: vStartOffs];
    
    while( ![vScanner isAtEnd] )
    {
        // Look for start of identifier:
        [vScanner scanUpToString: ident intoString: nil];
        vStartOffs = (int)[vScanner scanLocation];
        if( ![vScanner scanString:ident intoString:nil] )
            NS_VOIDRETURN;
        
        if( vStartOffs > 0 )	// Check that we're not in the middle of an identifier:
        {
            // Alphanum character before identifier start?
            if( [cset characterIsMember: [[s string] characterAtIndex: (vStartOffs -1)]] )  // If charset is NIL, this evaluates to NO.
                continue;
        }
        
        if( (vStartOffs +[ident length] +1) < [s length] )
        {
            // Alphanum character following our identifier?
            if( [cset characterIsMember: [[s string] characterAtIndex: (vStartOffs +[ident length])]] )  // If charset is NIL, this evaluates to NO.
                continue;
        }
        
        // Now mess with the string's styles:
        [s setAttributes: vStyles range: NSMakeRange( vStartOffs, [ident length] )];
        
        //[progress animate:nil];
    }
    
	NS_HANDLER
    // Just ignore it, syntax coloring isn't that important.
	NS_ENDHANDLER
}

/* -----------------------------------------------------------------------------
 colorTagFrom:
 Colorize HTML tags or similar constructs in the text view.
 
 REVISIONS:
 2004-05-18  witness Documented.
 -------------------------------------------------------------------------- */

-(void)	colorTagFrom: (NSString*) startCh to: (NSString*)endCh inString: (NSMutableAttributedString*) s
           withColor: (NSColor*) col andMode:(NSString*)attr exceptIfMode: (NSString*)ignoreAttr
{
	NS_DURING
    NSScanner*					vScanner = [NSScanner scannerWithString: [s string]];
    NSDictionary*				vStyles = [NSDictionary dictionaryWithObjectsAndKeys:
                                           col, NSForegroundColorAttributeName,
                                           attr, TD_SYNTAX_COLORING_MODE_ATTR,
                                           nil];
    
    while( ![vScanner isAtEnd] )
    {
        int		vStartOffs,
        vEndOffs;
        
        // Look for start of one-line comment:
        [vScanner scanUpToString: startCh intoString: nil];
        vStartOffs = (int)[vScanner scanLocation];
        if( vStartOffs >= [s length] )
            NS_VOIDRETURN;
        NSString*   scMode = [[s attributesAtIndex:vStartOffs effectiveRange: nil] objectForKey: TD_SYNTAX_COLORING_MODE_ATTR];
        if( ![vScanner scanString:startCh intoString:nil] )
            NS_VOIDRETURN;
        
        // If start lies in range of ignored style, don't colorize it:
        if( ignoreAttr != nil && [scMode isEqualToString: ignoreAttr] )
            continue;
        
        // Look for matching end marker:
        while( ![vScanner isAtEnd] )
        {
            // Scan up to the next occurence of the terminating sequence:
            [vScanner scanUpToString: endCh intoString:nil];
            
            // Now, if the mode of the end marker is not the mode we were told to ignore,
            //  we're finished now and we can exit the inner loop:
            vEndOffs = (int)[vScanner scanLocation];
            if( vEndOffs < [s length] )
            {
                scMode = [[s attributesAtIndex:vEndOffs effectiveRange: nil] objectForKey: TD_SYNTAX_COLORING_MODE_ATTR];
                [vScanner scanString: endCh intoString: nil];   // Also skip the terminating sequence.
                if( ignoreAttr == nil || ![scMode isEqualToString: ignoreAttr] )
                    break;
            }
            
            // Otherwise we keep going, look for the next occurence of endCh and hope it isn't in that style.
        }
        
        vEndOffs = (int)[vScanner scanLocation];
        
        // Now mess with the string's styles:
        [s setAttributes: vStyles range: NSMakeRange( vStartOffs, vEndOffs -vStartOffs )];
        
        //[progress animate:nil];
    }
	NS_HANDLER
    // Just ignore it, syntax coloring isn't that important.
	NS_ENDHANDLER
}


/* -----------------------------------------------------------------------------
 defaultTextAttributes:
 Returns the text attributes to use for the text in our text view.
 
 REVISIONS:
 2004-05-18  witness Documented.
 -------------------------------------------------------------------------- */

-(NSDictionary*)	defaultTextAttributes
{
    //Aqua font
    return [NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Menlo Regular" size:15] forKey:NSFontAttributeName];
	//return [NSDictionary dictionaryWithObject: [NSFont userFixedPitchFontOfSize:12.0] forKey: NSFontAttributeName];
}

-(NSDictionary*) defaultTextAttributeBLANK {
    //NSFontAttributeName es el tipo de letra original
    
    //    return [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSFont userFixedPitchFontOfSize:12.0],[NSColor whiteColor], nil] forKeys:[NSArray arrayWithObjects:NSFontAttributeName,NSForegroundColorAttributeName, nil]];
    //    
    //    return [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSFont userFixedPitchFontOfSize:12.0],[NSColor whiteColor], nil] forKeys:[NSArray arrayWithObjects:NSFontAttributeName,NSForegroundColorAttributeName, nil]];
    
    return [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSFont fontWithName:@"Menlo Regular" size:15],[NSColor whiteColor], nil] forKeys:[NSArray arrayWithObjects:NSFontAttributeName,NSForegroundColorAttributeName, nil]];
}


@end
