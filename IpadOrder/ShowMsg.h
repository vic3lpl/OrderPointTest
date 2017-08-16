#import <Foundation/Foundation.h>

@interface ShowMsg : NSObject
    //show error code
    + (void)showExceptionEpsonIo:(int)result method:(NSString*)method;
    + (void)showExceptionEpos:(int)result method:(NSString*)method;
    + (void)showExceptionEposBt:(int)result method:(NSString*)method;

    //show error message
    + (void)showError:(NSString*)errMsg;

    //show printer status(EposPrint.sendData)
    + (void)showStatus:(int)result status:(unsigned long)status battery:(unsigned long)battery;

    //show printer name
    + (void)showPrinterName:(NSString*)printerName languageName:(NSString*)languageName;

    //show status change event
    + (void)showStatusChangeEvent:(NSString*)deviceName Status:(unsigned long)status;

    //show battery status change event
    + (void)showBatteryStatusChangeEvent:(NSString*)deviceName Battery:(unsigned long)battery;

@end
