//
//  MouseOverTV.h
//  scif
//
//  Created by Marcial Contreras Zazueta on 4/20/13.
//  Copyright (c) 2013 UNAM Facultad de Ingeniería. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface MouseOverTV : NSTextView{
    @private
    NSString *oldPalabra;
    bool      enviarMensajes;
    NSTextField *tf;
}
-(void)definirEnviarMensajes:(NSNotification*)noti;
-(void)mostrarValor:(NSNotification*)noti;
- (NSRect)overlayRectForRange:(NSRange)aRange;
@end
