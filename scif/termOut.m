//
//  termOut.m
//  scif
//
//  Created by Marcial Contreras Zazueta on 11/13/12.
//  Copyright (c) 2012 UNAM Facultad de Ingeniería. All rights reserved.
//

#import "termOut.h"

@implementation termOut

@synthesize txt = _txt;
@synthesize visible = _visible;
//@synthesize windowed = _windowed;

-(id)init {
    self = [super init];
    if (self) {
//        _txt = @"";
        _visible = NO;
       // _windowed = [[NSWindow alloc] init];
    }
    return self;
}

-(IBAction) showTerm: (NSWindow*)owner{
    [[NSApplication sharedApplication] beginSheet:termOUTpanel modalForWindow:owner modalDelegate:self didEndSelector:@selector(termDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

-(IBAction) hideTerm:(id)sender{
    [[NSApplication sharedApplication] endSheet: termOUTpanel];
}

//-(IBAction) popOut:(id)sender{
//    [self hideTerm:nil];
//    
//    NSRect frame = NSMakeRect(0, 0, 200, 200);
//    _windowed  = [[[NSWindow alloc] initWithContentRect:frame
//                                                     styleMask:NSBorderlessWindowMask
//                                                       backing:NSBackingStoreBuffered
//                                                         defer:NO] autorelease];
//    [_windowed setBackgroundColor:[NSColor blueColor]];
//    [_windowed makeKeyAndOrderFront:[NSApplication sharedApplication]];
//    
//    
//}

-(void)termDidEnd: (NSWindow*)sheet returnCode: (int)returnCode contextInfo: (void*)contextInfo{
    [sheet orderOut:nil];
}

@end
