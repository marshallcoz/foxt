//
//  scifDocument.h
//  scif
//
//  Created by Marcial Contreras Zazueta on 10/31/12.
//  Copyright (c) 2012 UNAM Facultad de Ingeniería. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UKTextDocGotoBox.h"
#import "termOut.h"
#import "UKKQueue.h"
#import "MouseOverTV.h"
#import "makeScrPrefs.h"

// Define the constant below to 0 if you don't need support for old-style
//  (pre-0.2.0) syntax definition files. Old-style syntax definitions are being
//  phased out. Remember to update your definitions to the new one!
#ifndef TD_BACKWARDS_COMPATIBLE
#define TD_BACKWARDS_COMPATIBLE		1
#endif

// Attribute values for TD_SYNTAX_COLORING_MODE_ATTR added along with styles to program text:
//		These are only used for old-style syntax definitions. The post-0.2 style allows whatever
//		names you choose for the styles.
#if TD_BACKWARDS_COMPATIBLE
#define	TD_MULTI_LINE_COMMENT_ATTR			@"SyntaxColoring:MultiLineComment"		// Multi-line comment.
#define	TD_MULTI_LINE_COMMENT2_ATTR			@"SyntaxColoring:MultiLineComment2"		// A second kind of multi-line comment.
#define	TD_ONE_LINE_COMMENT_ATTR			@"SyntaxColoring:OneLineComment"		// One-line comment.
#define	TD_DOUBLE_QUOTED_STRING_ATTR		@"SyntaxColoring:DoubleQuotedString"	// Double-quoted string.
#define	TD_SINGLE_QUOTED_STRING_ATTR		@"SyntaxColoring:SingleQuotedString"	// ** unused **
#define	TD_PREPROCESSOR_ATTR				@"SyntaxColoring:Preprocessor"			// Preprocessor directive.
#define	TD_IDENTIFIER_ATTR					@"SyntaxColoring:Identifier"			// Identifier.
#define	TD_IDENTIFIER2_ATTR					@"SyntaxColoring:Identifier2"			// Identifier from group 2.
#define	TD_TAG_ATTR							@"SyntaxColoring:Tag"					// An HTML tag.
#endif

#define TD_USER_DEFINED_IDENTIFIERS			@"SyntaxColoring:UserIdentifiers"		// Key in user defaults holding user-defined identifiers to colorize.
#define TD_SYNTAX_COLORING_MODE_ATTR		@"UKTextDocumentSyntaxColoringMode"		// Anything we colorize gets this attribute.

@class NoodleLineNumberView;

@interface scifDocument : NSDocument <NSTextViewDelegate,NSSplitViewDelegate,NSTextStorageDelegate,NSTabViewDelegate> {
    
@private
    //scripts
    NSString *lineaCompilador; 
    NSString *lineaDepurador;
    NSString *lineaArgumentos;
    NSString *lineaPreCompilador;
    NSString *lineaExtension;
    NSString *lineaRunArgs;
    
    //debugging
    IBOutlet termOut        *terminal;
    NSTask                  *gdbtask;
    NSTask                  *execTask;
    NSFileHandle            *stdinHandle;
    NSFileHandle            *stdOutHandle;
    bool                    predebugscriptdone;
    
    //el set de preferencias elegido
    int                     my_presets;
    IBOutlet makeScrPrefs   *makeScrPrefsPanel;
    
    //NSFileHandle            *execinHandle;
    IBOutlet NSTextView     *dbgTextOut;
    IBOutlet NSTextField    *gdbinput;
    IBOutlet NSTextView     *programOUTtxt;
    IBOutlet NSTextField    *programINPUTtxt;
    IBOutlet NSPanel        *VarsPanel;
    NSMutableArray          *VarsArray;
    IBOutlet NSTextView     *VarsDumptxt;
    
    
    IBOutlet NSBox          *L_vertical;
    IBOutlet NSBox          *L_vertical_final;
        
    //searching
    IBOutlet NSSearchField	*searchField;
    BOOL					completePosting;
    BOOL					commandHandling;
    NSMutableArray          *recentSearches;
    unsigned long           punto_ant;
    NSString                *busqueda_ant;
    bool                    todoEldocumento;
    
    //entrada y salida del programa que ejecuta el gdb
    UKKQueue                *observadorINPUT;
    UKKQueue                *observadorOUTPUT;
    
    //view stuff
    IBOutlet NSScrollView   *scrollView;
    NoodleLineNumberView    *LineNumberVW;
    NSNumber                *num_de_lineas;
    int                     hoja_anterior;
    NSButton                *NotaiDisclosureButReminder;
    IBOutlet NSPopUpButton  *botonListaDelDrawer;
    
    //sintaxis de código
    IBOutlet UKTextDocGoToBox*		gotoPanel;				// Controller for our "go to line" panel.
    NSString*						sourceCode;				// Temp. storage for data from file until NIB has been read.
    BOOL							autoSyntaxColoring;		// Automatically refresh syntax coloring when text is changed?
    BOOL							maintainIndentation;	// Keep new lines indented at same depth as their predecessor?
    NSTimer*						recolorTimer;			// Timer used to do the actual recoloring a little while after the last keypress.
    BOOL							syntaxColoringBusy;		// Set while recolorRange is busy, so we don't recursively call recolorRange.
    NSRange							affectedCharRange;
	NSString*						replacementString;
}
//objetos view
@property (assign) IBOutlet NSCollectionView *tablaOutline;
@property (assign) IBOutlet NSButton *ToggleBreakpoints;
@property (assign) IBOutlet NSButton *ToggleMakeScriptPrefs;
@property (assign) IBOutlet NSSegmentedCell *SectionMode;
@property (assign) IBOutlet NSSegmentedControl *RunStopPrint;
@property (assign) IBOutlet NSSegmentedControl *Debug_panel;
@property (assign) IBOutlet NSSegmentedControl *Debug_actions;
@property (assign) IBOutlet NSSegmentedControl *OpcionesNota;
@property (assign) IBOutlet NSButton *OpcionesNotaImprimir;
@property (assign) IBOutlet NSSegmentedControl *togglecomment;
@property (assign) IBOutlet NSTabView *MainTAB; //ya no se usa
@property (assign) IBOutlet NSTextView *terminal_out;
@property (assign) IBOutlet NSArrayController *ARRAYcontroller;
@property (assign) IBOutlet MouseOverTV *txtx; //La caja de texto que usamos para editar código.
@property (assign) IBOutlet NSScroller *LayoutVerticalScroller;
@property (assign) IBOutlet NSSplitView *TheSplitView;
@property (assign) IBOutlet NSSplitView *gdbSplitView;
@property (copy) NSMutableArray *VarsArray;
@property (assign) IBOutlet NSButton *NotaiDisclosureBut;
@property (assign) IBOutlet NSDrawer *View2Drawer;
@property (assign) IBOutlet NSTextView *NotaiDisclosureTxt;
@property (assign) IBOutlet NSButton *NotaiDisclosureTitleBut;


//variables globales
@property (assign) NSString *nombreArchivo;
@property (assign) NSString *nombreArchivoFORTRAN;
@property (assign) NSString *nombreArchivoTeX;
@property (assign) NSString *directorioBase;
@property (assign) NSString *nombreOUTput;
@property (assign) NSArray *AWAKE;
@property (assign) NSArray *BPs;
@property int modo_seleccionado; //0 fortran;  1 latex; 2 latex+calc; 3 invisible.
@property (assign) NSString *palabra;
@property (assign) NSRange  palabraRange;

//acciones del view
- (IBAction)RunStopPrint_click:(id)sender;
- (IBAction)Run_button_click:(id)sender;
- (IBAction)Run_last_click:(id)sender;
- (IBAction)Stop_button_click:(id)sender;
- (IBAction)make_pdf:(id)sender;
- (IBAction)click_makeScript:(id)sender;
- (IBAction)Section_buttons_click:(id)sender;
- (IBAction)click_split:(id)sender;
- (IBAction)Toggle_breakpoints:(id)sender;
- (IBAction)click_debug_actions:(id)sender;
- (IBAction)continue_menuclick:(id)sender;
- (IBAction)StepInto_menuclick:(id)sender;
- (IBAction)StepOut_menuclick:(id)sender;
- (IBAction)OpenTerminal_menuclick:(id)sender;
- (IBAction)RunScript_menuclick:(id)sender;
- (IBAction)click_Debug_panels:(id)sender;
- (IBAction)NotaOpcionesSectionClick:(id)sender;
- (IBAction)NotaiDisclosureClick:(id)sender;
- (IBAction)click_printable:(id)sender;
//-(void) showOff:(NSString*)tt here:(NSRange)ran;
//- (NSRect)overlayRectForRange:(NSRange)aRange;
- (IBAction)terminal_enter:(id)sender;
- (IBAction)toggle_comment:(id)sender;
-(IBAction)toggle_comment_with_spacebar:(id)sender;
-(void)splitThisFortranBlock:(id)sender;
-(void)splitThisLatexBlock:(id)sender;
-(void)grabar:(NSString*)linea to:(NSString*)key;
-(IBAction)clearSlate:(id)sender;
- (IBAction)changedDrawerSelection:(id)sender;
- (IBAction)closeTheDrawer:(id)sender;

//otros métodos
-(bool) guardarTexto:(NSString*)t en:(NSString*)ruta;
-(BOOL) pedirArchivo:(NSString*)mensaje;
-(BOOL) guardadoTextoFortran:(NSString*)textoFortran TextoLatex:(NSString*)textoLatex;
-(NSDictionary*)textos_de_salida_para_el_arreglo:(NSArray*)ARR;
- (IBAction)sheetDoneButtonAction:(id)sender;
-(void)clean_and_close;

// objetos para manejar la sintaxis

-(void) processEditing: (NSNotification*)notification;

+(void) asegurarQuePfrefsYaIniciaron;

+(void) makeSurePrefsAreInited;		// No need to call this.

-(IBAction)	recolorCompleteFile: (id)sender;
-(IBAction)	toggleAutoSyntaxColoring: (id)sender;
-(IBAction)	toggleMaintainIndentation: (id)sender;
-(IBAction) showGoToPanel: (id)sender;
-(IBAction) indentSelection: (id)sender;
-(IBAction) unindentSelection: (id)sender;
-(IBAction) findSomething: (id)sender;

-(void)		setAutoSyntaxColoring: (BOOL)state;
-(BOOL)		autoSyntaxColoring;

-(void)		setMaintainIndentation: (BOOL)state;
-(BOOL)		maintainIndentation;
-(void) toToLineinThisTxt: (int)lineNum;
-(void)		goToLine: (int)lineNum;
-(void)		goToCharacter: (int)charNum;
-(void)		goToRangeFrom: (int)startCh toChar: (int)endCh;

// Override any of the following in one of your subclasses to customize this object further:
-(NSString*)		syntaxDefinitionFilename;   // Defaults to "SyntaxDefinition.plist" in the app bundle's "Resources" directory.
-(NSDictionary*)	syntaxDefinitionDictionary; // Defaults to loading from -syntaxDefinitionFilename.

-(NSDictionary*)	defaultTextAttributes;		// Style attributes dictionary for an NSAttributedString.
-(NSDictionary*) defaultTextAttributeBLANK;
// Private:
-(void) turnOffWrapping;
-(void) turnOnWrapping;

-(void) recolorRange: (NSRange) range;
#if TD_BACKWARDS_COMPATIBLE
-(void) oldRecolorRange: (NSRange)range;	// Called by recolorRange as needed.
#endif

-(void)	colorOneLineComment: (NSString*) startCh inString: (NSMutableAttributedString*) s
                  withColor: (NSColor*) col andMode:(NSString*)attr;
-(void)	colorCommentsFrom: (NSString*) startCh to: (NSString*) endCh inString: (NSMutableAttributedString*) s
				withColor: (NSColor*) col andMode:(NSString*)attr;
-(void)	colorIdentifier: (NSString*) ident inString: (NSMutableAttributedString*) s
              withColor: (NSColor*) col andMode:(NSString*)attr charset: (NSCharacterSet*)cset;
-(void)	colorStringsFrom: (NSString*) startCh to: (NSString*) endCh inString: (NSMutableAttributedString*) s
               withColor: (NSColor*) col andMode:(NSString*)attr andEscapeChar: (NSString*)vStringEscapeCharacter;
-(void)	colorTagFrom: (NSString*) startCh to: (NSString*)endCh inString: (NSMutableAttributedString*) s
           withColor: (NSColor*) col andMode:(NSString*)attr exceptIfMode: (NSString*)ignoreAttr;

@end



// Support for external editor interface:
//	(Doesn't really work yet ... *sigh*)

//#pragma options align=mac68k

struct SelectionRange
{
	short   unused1;	// 0 (not used)
	short   lineNum;	// line to select (< 0 to specify range)
	long	startRange; // start of selection range (if line < 0)
	long	endRange;   // end of selection range (if line < 0)
	long	unused2;	// 0 (not used)
	long	theDate;	// modification date/time
};

//#pragma options align=reset
