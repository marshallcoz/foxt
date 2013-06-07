//
//  MouseOverTV.m
//  scif
//
//  Created by Marcial Contreras Zazueta on 4/20/13.
//  Copyright (c) 2013 UNAM Facultad de Ingeniería. All rights reserved.
//

#import "MouseOverTV.h"

@implementation MouseOverTV

@synthesize enviar;

- (void)awakeFromNib {
    tf = [[NSTextField alloc] init];
    [[self window] setAcceptsMouseMovedEvents:YES];
    oldPalabra = [[NSString alloc]initWithString:@""];
    [self setEnviar:false];    
}


-(void)mostrarValor:(NSDictionary*)noti{
    
    NSString * varVal = (NSString*)[noti objectForKey:@"varVal"];
    unsigned long loc = [(NSNumber*)[noti objectForKey:@"loc"] unsignedLongValue];
    //unsigned long len = [(NSNumber*)[[noti userInfo] objectForKey:@"len"] unsignedLongValue];
    NSRange  wordRange = NSMakeRange(loc, 2+varVal.length);
    
    //NSLog(@"varVal:\n%@",varVal);
    
    [tf removeFromSuperview];
    NSRect rect = [self overlayRectForRange:wordRange];
    rect.origin.y -= 18;
    [tf setBordered:NO];
    [tf setFrame:rect];
    //tf = [[NSTextField alloc] initWithFrame:rect];
    [tf setEditable:NO];
    [tf setBezelStyle:NSTextFieldRoundedBezel];
    [tf setBezeled:YES];
    
    [tf setTextColor:[NSColor blackColor]];
    [tf setBackgroundColor:[NSColor colorWithCalibratedRed:155 green:234 blue:208 alpha:0.75]];
    
    [tf setStringValue:varVal];
    [self addSubview:tf];
}

- (NSRect)overlayRectForRange:(NSRange)aRange {
    NSRange activeRange = [[self layoutManager] glyphRangeForCharacterRange:aRange actualCharacterRange:NULL];
    NSRect neededRect = [[self layoutManager] boundingRectForGlyphRange:activeRange inTextContainer:[self textContainer]];
    NSPoint containerOrigin = [self textContainerOrigin];
    neededRect.origin.x += containerOrigin.x;
    neededRect.origin.y += containerOrigin.y; 
    //neededRect.size.height = 16;
    neededRect.size.width = 600;
    
    return neededRect;
}
//
//
//-(void)setString:(NSString *)string{
//    [tf removeFromSuperview];
//}

- (void)mouseMoved:(NSEvent *)theEvent {
    if (enviar) 
    {
    
    NSLayoutManager *layoutManager = [self layoutManager];
    NSTextContainer *textContainer = [self textContainer];
    NSUInteger glyphIndex, charIndex, textLength = [[self textStorage] length];
    NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSRange lineGlyphRange, lineCharRange, wordCharRange, textCharRange = NSMakeRange(0, textLength);
    NSRect glyphRect;
    
    // Remove any existing coloring.
    [layoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:textCharRange];
    
    // Convert view coordinates to container coordinates
    point.x -= [self textContainerOrigin].x;
    point.y -= [self textContainerOrigin].y;
    
    // Convert those coordinates to the nearest glyph index
    glyphIndex = [layoutManager glyphIndexForPoint:point inTextContainer:textContainer];
    
    // Check to see whether the mouse actually lies over the glyph it is nearest to
    glyphRect = [layoutManager boundingRectForGlyphRange:NSMakeRange(glyphIndex, 1) inTextContainer:textContainer];
    if (NSPointInRect(point, glyphRect)) {
        // Convert the glyph index to a character index
        charIndex = [layoutManager characterIndexForGlyphAtIndex:glyphIndex];
        
        // Determine the range of glyphs, and of characters, in the corresponding line
        (void)[layoutManager lineFragmentRectForGlyphAtIndex:glyphIndex effectiveRange:&lineGlyphRange];        
        lineCharRange = [layoutManager characterRangeForGlyphRange:lineGlyphRange actualGlyphRange:NULL];
        
        // Determine the word containing that character
        wordCharRange = NSIntersectionRange(lineCharRange, [self selectionRangeForProposedRange:NSMakeRange(charIndex, 0) granularity:NSSelectByWord]);
        
        // Color the characters using temporary attributes
        [layoutManager addTemporaryAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor blackColor], NSBackgroundColorAttributeName, nil] forCharacterRange:lineCharRange];
        //[layoutManager addTemporaryAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor grayColor], NSBackgroundColorAttributeName, nil] forCharacterRange:wordCharRange];
        //[layoutManager addTemporaryAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor magentaColor], NSBackgroundColorAttributeName, nil] forCharacterRange:NSMakeRange(charIndex, 1)];

        if (wordCharRange.length > 0) {
            NSString* palabra = [[NSString alloc] initWithString:[[self string] substringWithRange:wordCharRange]];
            if (![palabra isEqualToString:oldPalabra]) {
                oldPalabra = palabra;
                [tf removeFromSuperview];
                if ([palabra rangeOfString:@" "].length == 0 &&
                    [palabra rangeOfString:@"\n"].length == 0 ) {
                    if (![palabra hasPrefix:@"1"] && 
                        ![palabra hasPrefix:@"2"] && 
                        ![palabra hasPrefix:@"3"] && 
                        ![palabra hasPrefix:@"4"] && 
                        ![palabra hasPrefix:@"5"] && 
                        ![palabra hasPrefix:@"6"] && 
                        ![palabra hasPrefix:@"7"] && 
                        ![palabra hasPrefix:@"8"] && 
                        ![palabra hasPrefix:@"9"] && 
                        ![palabra hasPrefix:@"0"] && 
                        ![palabra hasPrefix:@","] && 
                        ![palabra hasPrefix:@"*"] && 
                        ![palabra hasPrefix:@"/"] && 
                        ![palabra hasPrefix:@"-"] && 
                        ![palabra hasPrefix:@"+"] && 
                        ![palabra hasPrefix:@":"] && 
                        ![palabra hasPrefix:@"."] && 
                        ![palabra hasPrefix:@"}"] && 
                        ![palabra hasPrefix:@"{"] && 
                        ![palabra hasPrefix:@"["] && 
                        ![palabra hasPrefix:@"]"] && 
                        ![palabra hasPrefix:@"("] && 
                        ![palabra hasPrefix:@")"]) {
                        palabra = [palabra lowercaseString];
                        //   NSLog(@"palabra: %@",palabra);
                        NSNumber *loc = [[NSNumber alloc] initWithUnsignedLong:wordCharRange.location];
                        NSNumber *len = [[NSNumber alloc] initWithUnsignedLong:wordCharRange.length];
//                        Palabraloc = [[NSNumber alloc] initWithUnsignedLong:wordCharRange.location];
//                        Palabralen = [[NSNumber alloc] initWithUnsignedLong:wordCharRange.length];
                        NSDictionary *oo = [[NSDictionary alloc] initWithObjectsAndKeys:
                                            palabra,@"palabra",
                                            loc,@"loc",
                                            len,@"len",
                                            nil];
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"printVar" object:nil userInfo:oo];
                        
                    }
                }
            }
        }
    }
    } else {
        [tf removeFromSuperview];
    }
}


@end

