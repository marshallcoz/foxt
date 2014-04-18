//
//  CodeTextView.h
//  scif
//
//  Created by Marcial Contreras Zazueta on 6/28/13.
//  Copyright (c) 2013 UNAM Facultad de Ingeniería. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UKTextDocGotoBox.h"
#import "MouseOverTV.h"

#define TD_USER_DEFINED_IDENTIFIERS			@"SyntaxColoring:UserIdentifiers"		// Key in user defaults holding user-defined identifiers to colorize.
#define TD_SYNTAX_COLORING_MODE_ATTR		@"UKTextDocumentSyntaxColoringMode"		// Anything we colorize gets this attribute.

@class NoodleLineNumberView;

                            // subclassing the NSTextView bouh yeah!
@interface CodeTextView : NSTextView {
    int modo; // [ n Mi_modo_actual]
    unsigned long indice_inicial;
    
    //view stuff
    NoodleLineNumberView    *LineNumberVW;
    NSNumber                *num_de_lineas;
    int                     hoja_anterior;
    
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

-(void) processEditingHere: (NSNotification*)notification;

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
//#if TD_BACKWARDS_COMPATIBLE
//-(void) oldRecolorRange: (NSRange)range;	// Called by recolorRange as needed.
//#endif

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



