//
//  PrinterFunctions.m
//  IOS_SDK
//
//  Created by Tzvi on 8/2/11.
//  Copyright 2011 - 2013 STAR MICRONICS CO., LTD. All rights reserved.
//

#import "PrinterFunctions.h"
#import <StarIO/SMPort.h>
#import <StarIO/SMBluetoothManager.h>
#import "RasterDocument.h"
#import "StarBitmap.h"
#import <sys/time.h>
#import <unistd.h>
#import "AppDelegate.h"
#import "LibraryAPI.h"
#import <FMDB.h>

@implementation PrinterFunctions

#pragma mark Get Firmware Version

/*!
 *  This function shows the printer firmware information
 *
 *  @param  portName        Port name to use for communication
 *  @param  portSettings    Set following settings
 *                          - Desktop USB Printer + Apple AirPort: @"9100" - @"9109" (Port Number)
 *                          - Portable Printer (Star Line Mode)  : @"portable"
 *                          - Others                             : @"" (blank)
 */
+ (void)showFirmwareVersion:(NSString *)portName portSettings:(NSString *)portSettings
{
    SMPort *starPort = nil;
    NSDictionary *dict = nil;
    
    @try
    {
        starPort = [SMPort getPort:portName :portSettings :10000];
        if (starPort == nil) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Fail to Open Port.\nRefer to \"getPort API\" in the manual."
                                                            message:@""
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            return;
        }

        NSMutableString *message = [NSMutableString string];
        dict = [starPort getFirmwareInformation];
        for (id key in dict.keyEnumerator) {
            [message appendFormat:@"%@: %@\n", key, dict[key]];
        }
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Firmware"
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil];
        [alert show];
        
    }
    @catch (PortException *exception)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Printer Error"
                                                        message:@"Get firmware information failed"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    @finally
    {
        [SMPort releasePort:starPort];
    }
}

#pragma mark Check whether supporting bluetooth setting

+ (NSInteger)hasBTSettingSupportWithPortName:(NSString *)portName portSettings:(NSString *)portSettings {
    // Check Interface
    if ([portName.uppercaseString hasPrefix:@"BLE:"]) {
        return 0;
    }
    
    if ([portName.uppercaseString hasPrefix:@"BT:"] == NO) {
        return 1;
    }
    
    // Check firmware version
    SMPort *port = nil;
    NSDictionary *dict = nil;
    @try {
        port = [SMPort getPort:portName :portSettings :10000];
        if (port == nil) {
            return 2;
        }
        
        dict = [port getFirmwareInformation];
    }
    @catch (NSException *e) {
        return 2;
    }
    @finally {
        [SMPort releasePort:port];
    }
    
    NSString *modelName = dict[@"ModelName"];
    if ([modelName hasPrefix:@"SM-S21"] ||
        [modelName hasPrefix:@"SM-S22"] ||
        [modelName hasPrefix:@"SM-T30"] ||
        [modelName hasPrefix:@"SM-T40"]) {
        
        NSString *fwVersionStr = dict[@"FirmwareVersion"];
        float fwVersion = fwVersionStr.floatValue;
        if (fwVersion < 3.0) {
            return 3;
        }
    }
    
    return 0;
}

#pragma mark Open Cash Drawer

/*!
 *  This function opens the cash drawer connected to the printer
 *  This function just send the byte 0x07 to the printer which is the open Cash Drawer command
 *
 *  @param  portName        Port name to use for communication. This should be (TCP:<IP Address>), (BT:<iOS Port Name>),
 *                          or (BLE:<Device Name>).
 *  @param  portSettings    Set following settings
 *                          - Desktop USB Printer + Apple AirPort: @"9100" - @"9109" (Port Number)
 *                          - Portable Printer (Star Line Mode)  : @"portable"
 *                          - Others                             : @"" (blank)
 */
+ (void)OpenCashDrawerWithPortname:(NSString *)portName portSettings:(NSString *)portSettings drawerNumber:(NSUInteger)drawerNumber
{
    unsigned char opencashdrawer_command = 0x00;
    
    if (drawerNumber == 1) {
        opencashdrawer_command = 0x07; // BEL
    }
    else if (drawerNumber == 2) {
        opencashdrawer_command = 0x1a; // SUB
    }
    
    NSData *commands = [NSData dataWithBytes:&opencashdrawer_command length:1];
    [self sendCommand:commands portName:portName portSettings:portSettings timeoutMillis:10000];
}


#pragma mark Check Status

/*!
 *  This function checks the status of the printer.
 *  The check status function can be used for both portable and non portable printers.
 *
 *  @param  portName        Port name to use for communication. This should be (TCP:<IP Address>), (BT:<iOS Port Name>),
 *                          or (BLE:<Device Name>).
 *  @param  portSettings    Set following settings
 *                          - Desktop USB Printer + Apple AirPort: @"9100" - @"9109" (Port Number)
 *                          - Portable Printer (Star Line Mode)  : @"portable"
 *                          - Others                             : @"" (blank)
 *
 */
+ (void)CheckStatusWithPortname:(NSString *)portName portSettings:(NSString *)portSettings sensorSetting:(SensorActive)sensorActiveSetting
{
    SMPort *starPort = nil;
    @try
    {
        starPort = [SMPort getPort:portName :portSettings :10000];
        if (starPort == nil) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Fail to Open Port.\nRefer to \"getPort API\" in the manual."
                                                            message:@""
                                                           delegate:nil 
                                                  cancelButtonTitle:@"OK" 
                                                  otherButtonTitles:nil];
            [alert show];
            return;
        }
        usleep(1000 * 1000);
        
        StarPrinterStatus_2 status;
        [starPort getParsedStatus:&status :2];
        
        NSString *message = @"";
        if (status.offline == SM_TRUE)
        {
            message = @"The printer is offline";
            if (status.coverOpen == SM_TRUE)
            {
                message = [message stringByAppendingString:@"\nCover is Open"];
            }
            else if (status.receiptPaperEmpty == SM_TRUE)
            {
                message = [message stringByAppendingString:@"\nOut of Paper"];
            }
        }
        else
        {
            message = @"The Printer is online";
        }

        NSString *drawerStatus;
        if (sensorActiveSetting == SensorActiveHigh)
        {
            drawerStatus = (status.compulsionSwitch == SM_TRUE) ? @"Open" : @"Close";
            message = [message stringByAppendingFormat:@"\nCash Drawer: %@", drawerStatus];
        }
        else if (sensorActiveSetting == SensorActiveLow)
        {
            drawerStatus = (status.compulsionSwitch == SM_FALSE) ? @"Open" : @"Close";
            message = [message stringByAppendingFormat:@"\nCash Drawer: %@", drawerStatus];
        }
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Printer Status"
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];

        [alert show];
    }
    @catch (PortException *exception)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Printer Error" 
                                                        message:@"Get status failed"
                                                       delegate:nil 
                                              cancelButtonTitle:@"OK" 
                                              otherButtonTitles:nil];
        [alert show];
    }
    @finally 
    {
        [SMPort releasePort:starPort];
    }
}

#pragma mark 1D Barcode

/**
 *  This function is used to print bar codes in the 39 format
 *
 *  @param  portName        Port name to use for communication. This should be (TCP:<IP Address>), (BT:<iOS Port Name>),
 *                          or (BLE:<Device Name>).
 *  @param  portSettings    Set following settings
 *                          - Desktop USB Printer + Apple AirPort: @"9100" - @"9109" (Port Number)
 *                          - Portable Printer (Star Line Mode)  : @"portable"
 *                          - Others                             : @"" (blank)
 *  @param  barcodeData     These are the characters that will be printed in the bar code. The characters available for
 *                          this bar code are listed in section 3-43 (Rev. 1.12).
 *  @param  barcodeDataSize This is the number of characters in the barcode.  This should be the size of the preceding
 *                          parameter
 *  @param  option          This tell the printer weather put characters under the printed bar code or not.  This may
 *                          also be used to line feed after the bar code is printed.
 *  @param  height          The height of the bar code.  This is measured in pixels
 *  @param  width           The Narrow wide width of the bar code.  This value should be between 1 to 9.  See section
 *                          3-42 (Rev. 1.12) for more information on the values.
 */
+ (void)PrintCode39WithPortname:(NSString*)portName portSettings:(NSString*)portSettings barcodeData:(unsigned char *)barcodeData barcodeDataSize:(unsigned int)barcodeDataSize barcodeOptions:(BarCodeOptions)option height:(unsigned char)height narrowWide:(NarrowWide)width
{
    unsigned char n1 = 0x34;
    unsigned char n2 = 0;
    switch (option) {
        case No_Added_Characters_With_Line_Feed:
            n2 = 49;
            break;
        case Adds_Characters_With_Line_Feed:
            n2 = 50;
            break;
        case No_Added_Characters_Without_Line_Feed:
            n2 = 51;
            break;
        case Adds_Characters_Without_Line_Feed:
            n2 = 52;
            break;
    }
    unsigned char n3 = 0;
    switch (width)
    {
        case NarrowWide_2_6:
            n3 = 49;
            break;
        case NarrowWide_3_9:
            n3 = 50;
            break;
        case NarrowWide_4_12:
            n3 = 51;
            break;
        case NarrowWide_2_5:
            n3 = 52;
            break;
        case NarrowWide_3_8:
            n3 = 53;
            break;
        case NarrowWide_4_10:
            n3 = 54;
            break;
        case NarrowWide_2_4:
            n3 = 55;
            break;
        case NarrowWide_3_6:
            n3 = 56;
            break;
        case NarrowWide_4_8:
            n3 = 57;
            break;
    }
    unsigned char n4 = height;
    
    unsigned char *command = (unsigned char*)malloc(6 + barcodeDataSize + 1);
    command[0] = 0x1b;
    command[1] = 0x62;
    command[2] = n1;
    command[3] = n2;
    command[4] = n3;
    command[5] = n4;
    for (int index = 0; index < barcodeDataSize; index++)
    {
        command[index + 6] = barcodeData[index];
    }
    command[6 + barcodeDataSize] = 0x1e;
    
    int commandSize = 6 + barcodeDataSize + 1;
    
    NSData *dataToSentToPrinter = [[NSData alloc] initWithBytes:command length:commandSize];
    
    [self sendCommand:dataToSentToPrinter portName:portName portSettings:portSettings timeoutMillis:10000];
    
    free(command);
}

/**
 *  This function is used to print bar codes in the 93 format
 *
 *  @param   portName        Port name to use for communication. This should be (TCP:<IP Address>), (BT:<iOS Port Name>),
 *                           or (BLE:<Device Name>).
 *  @param  portSettings    Set following settings
 *                          - Desktop USB Printer + Apple AirPort: @"9100" - @"9109" (Port Number)
 *                          - Portable Printer (Star Line Mode)  : @"portable"
 *                          - Others                             : @"" (blank)
 * @param   barcodeData     These are the characters that will be printed in the bar code. The characters available for
 *                          this bar code are listed in section 3-43 (Rev. 1.12).
 * @param   barcodeDataSize This is the number of characters in the barcode.  This should be the size of the preceding
 *                          parameter
 * @param   option          This tell the printer weather put characters under the printed bar code or not. This may
 *                          also be used to line feed after the bar code is printed.
 * @param   height          The height of the bar code.  This is measured in pixels
 * @param   width           This is the number of dots per module.  This value should be between 1 to 3.  See section
 *                          3-42 (Rev. 1.12) for more information on the values.
 */
+ (void)PrintCode93WithPortname:(NSString*)portName portSettings:(NSString*)portSettings barcodeData: (unsigned char *)barcodeData barcodeDataSize:(unsigned int)barcodeDataSize barcodeOptions:(BarCodeOptions)option height:(unsigned char)height min_module_dots:(Min_Mod_Size)width
{
    unsigned char n1 = 0x37;
    unsigned char n2 = 0;
    switch (option)
    {
        case No_Added_Characters_With_Line_Feed:
            n2 = 49;
            break;
        case Adds_Characters_With_Line_Feed:
            n2 = 50;
            break;
        case No_Added_Characters_Without_Line_Feed:
            n2 = 51;
            break;
        case Adds_Characters_Without_Line_Feed:
            n2 = 52;
            break;
    }
    unsigned char n3 = 0;
    switch (width)
    {
        case _2_dots:
            n3 = 49;
            break;
        case _3_dots:
            n3 = 50;
            break;
        case _4_dots:
            n3 = 51;
            break;
    }
    unsigned char n4 = height;
    unsigned char *command = (unsigned char*)malloc(6 + barcodeDataSize + 1);
    command[0] = 0x1b;
    command[1] = 0x62;
    command[2] = n1;
    command[3] = n2;
    command[4] = n3;
    command[5] = n4;
    for (int index = 0; index < barcodeDataSize; index++)
    {
        command[index + 6] = barcodeData[index];
    }
    command[6 + barcodeDataSize] = 0x1e;
    
    int commandSize = 6 + barcodeDataSize + 1;
    
    NSData *dataToSentToPrinter = [[NSData alloc] initWithBytes:command length:commandSize];
    
    [self sendCommand:dataToSentToPrinter portName:portName portSettings:portSettings timeoutMillis:10000];
    
    free(command);
}

/**
 * This function is used to print bar codes in the ITF format
 *
 *  @param  portName        Port name to use for communication. This should be (TCP:<IP Address>), (BT:<iOS Port Name>),
 *                          or (BLE:<Device Name>).
 *  @param  portSettings    Set following settings
 *                          - Desktop USB Printer + Apple AirPort: @"9100" - @"9109" (Port Number)
 *                          - Portable Printer (Star Line Mode)  : @"portable"
 *                          - Others                             : @"" (blank)
 *  @param  barcodeData     These are the characters that will be printed in the bar code. The characters available for
 *                          this bar code are listed in section 3-43 (Rev. 1.12).
 *  @param  barcodeDataSize This is the number of characters in the barcode.  This should be the size of the preceding
 *                          parameter
 *  @param  option          This tell the printer weather put characters under the printed bar code or not.  This may
 *                          also be used to line feed after the bar code is printed.
 *  @param  height          The height of the bar code.  This is measured in pixels
 *  @param  width           This is the number of dots per module.  This value should be between 1 to 3.  See section
 *                          3-42 (Rev. 1.12) for more information on the values.
 */
+ (void)PrintCodeITFWithPortname:(NSString*)portName portSettings:(NSString*)portSettings barcodeData:(unsigned char *)barcodeData barcodeDataSize:(unsigned int)barcodeDataSize barcodeOptions:(BarCodeOptions)option height:(unsigned char)height narrowWide:(NarrowWideV2)width
{
    unsigned char n1 = 0x35;
    unsigned char n2 = 0;
    switch (option)
    {
        case No_Added_Characters_With_Line_Feed:
            n2 = 49;
            break;
        case Adds_Characters_With_Line_Feed:
            n2 = 50;
            break;
        case No_Added_Characters_Without_Line_Feed:
            n2 = 51;
            break;
        case Adds_Characters_Without_Line_Feed:
            n2 = 52;
            break;
    }
    unsigned char n3 = 0;
    switch (width)
    {
        case NarrowWideV2_2_5:
            n3 = 49;
            break;
        case NarrowWideV2_4_10:
            n3 = 50;
            break;
        case NarrowWideV2_6_15:
            n3 = 51;
            break;
        case NarrowWideV2_2_4:
            n3 = 52;
            break;
        case NarrowWideV2_4_8:
            n3 = 53;
            break;
        case NarrowWideV2_6_12:
            n3 = 54;
            break;
        case NarrowWideV2_2_6:
            n3 = 55;
            break;
        case NarrowWideV2_3_9:
            n3 = 56;
            break;
        case NarrowWideV2_4_12:
            n3 = 57;
            break;
    }
    
    unsigned char n4 = height;
    unsigned char *command = (unsigned char*)malloc(6 + barcodeDataSize + 1);
    command[0] = 0x1b;
    command[1] = 0x62;
    command[2] = n1;
    command[3] = n2;
    command[4] = n3;
    command[5] = n4;
    for (int index = 0; index < barcodeDataSize; index++)
    {
        command[index + 6] = barcodeData[index];
    }
    command[barcodeDataSize + 6] = 0x1e;
    int commandSize = 6 + barcodeDataSize + 1;
    
    NSData *dataToSentToPrinter = [[NSData alloc] initWithBytes:command length:commandSize];
    
    [self sendCommand:dataToSentToPrinter portName:portName portSettings:portSettings timeoutMillis:10000];
    
    free(command);
}

/**
 * This function is used to print bar codes in the 128 format
 *
 *  @param  portName        Port name to use for communication. This should be (TCP:<IP Address>), (BT:<iOS Port Name>),
 *                          or (BLE:<Device Name>).
 *  @param  portSettings    Set following settings
 *                          - Desktop USB Printer + Apple AirPort: @"9100" - @"9109" (Port Number)
 *                          - Portable Printer (Star Line Mode)  : @"portable"
 *                          - Others                             : @"" (blank)
 *  @param  barcodeData     These are the characters that will be printed in the bar code. The characters available for
 *                          this bar code are listed in section 3-43 (Rev. 1.12).
 *  @param  barcodeDataSize This is the number of characters in the barcode.  This should be the size of the preceding
 *                          parameter
 *  @param  option          This tell the printer weather put characters under the printed bar code or not.  This may
 *                          also be used to line feed after the bar code is printed.
 *  @param  height          The height of the bar code.  This is measured in pixels
 *  @param  width           This is the number of dots per module.  This value should be between 1 to 3.  See section
 *                          3-42 (Rev. 1.12) for more information on the values.
 */
+ (void)PrintCode128WithPortname:(NSString*)portName portSettings:(NSString*)portSettings barcodeData:(unsigned char *)barcodeData barcodeDataSize:(unsigned int)barcodeDataSize barcodeOptions:(BarCodeOptions)option height:(unsigned char)height min_module_dots:(Min_Mod_Size)width
{
    unsigned char n1 = 0x36;
    unsigned char n2 = 0;
    switch (option)
    {
        case No_Added_Characters_With_Line_Feed:
            n2 = 49;
            break;
        case Adds_Characters_With_Line_Feed:
            n2 = 50;
            break;
        case No_Added_Characters_Without_Line_Feed:
            n2 = 51;
            break;
        case Adds_Characters_Without_Line_Feed:
            n2 = 52;
            break;
    }
    unsigned char n3 = 0;
    switch (width)
    {
        case _2_dots:
            n3 = 49;
            break;
        case _3_dots:
            n3 = 50;
            break;
        case _4_dots:
            n3 = 51;
            break;
    }
    unsigned char n4 = height;
    unsigned char *command = (unsigned char*)malloc(6 + barcodeDataSize + 1);
    command[0] = 0x1b;
    command[1] = 0x62;
    command[2] = n1;
    command[3] = n2;
    command[4] = n3;
    command[5] = n4;
    for (int index = 0; index < barcodeDataSize; index++)
    {
        command[index + 6] = barcodeData[index];
    }
    command[barcodeDataSize + 6] = 0x1e;
    int commandSize = 6 + barcodeDataSize + 1;
    
    NSData *dataToSentToPrinter = [[NSData alloc] initWithBytes:command length:commandSize];
    
    [self sendCommand:dataToSentToPrinter portName:portName portSettings:portSettings timeoutMillis:10000];
    
    free(command);
}

#pragma mark 2D Barcode

/**
 * This function is used to print a QR Code on standard star printers
 *
 *  @param  portName        Port name to use for communication. This should be (TCP:<IP Address>), (BT:<iOS Port Name>),
 *                          or (BLE:<Device Name>).
 *  @param  portSettings    Set following settings
 *                          - Desktop USB Printer + Apple AirPort: @"9100" - @"9109" (Port Number)
 *                          - Portable Printer (Star Line Mode)  : @"portable"
 *                          - Others                             : @"" (blank)
 *  @param  correctionLevel The correction level for the QR Code.  The correction level can be 7, 15, 25, or 30.  See
 *                          section 3-129 (Rev. 1.12).
 *  @param  model           The model to use when printing the QR Code. See section 3-129 (Rev. 1.12).
 *  @param  cellSize        The cell size of the QR Code.  This value of this should be between 1 and 8. It is
 *                          recommended that this value be 2 or less.
 *  @param  barCodeData     This is the characters in the QR Code.
 *  @param  barcodeDataSize This is the number of characters that will be written into the QR Code. This is the size of
 *                          the preceding parameter
 */
+ (void)PrintQrcodeWithPortname:(NSString*)portName portSettings:(NSString*)portSettings correctionLevel:(CorrectionLevelOption)correctionLevel model:(Model)model cellSize:(unsigned char)cellSize barcodeData:(unsigned char*)barCodeData barcodeDataSize:(unsigned int)barCodeDataSize
{
    NSMutableData *commands = [[NSMutableData alloc] init];
    
    unsigned char modelCommand[] = {0x1b, 0x1d, 0x79, 0x53, 0x30, 0x00};
    switch(model)
    {
        case Model1:
            modelCommand[5] = 1;
            break;
        case Model2:
            modelCommand[5] = 2;
            break;
    }
    
    [commands appendBytes:modelCommand length:6];
    
    unsigned char correctionLevelCommand[] = {0x1b, 0x1d, 0x79, 0x53, 0x31, 0x00};
    switch (correctionLevel)
    {
        case Low:
            correctionLevelCommand[5] = 0;
            break;
        case Middle:
            correctionLevelCommand[5] = 1;
            break;
        case Q:
            correctionLevelCommand[5] = 2;
            break;
        case High:
            correctionLevelCommand[5] = 3;
            break;
    }
    [commands appendBytes:correctionLevelCommand length:6];
    
    unsigned char cellCodeSize[] = {0x1b, 0x1d, 0x79, 0x53, 0x32, 0x00};
    cellCodeSize[5] = cellSize;
    [commands appendBytes:cellCodeSize length:6];
    
    unsigned char qrcodeStart[] = {0x1b, 0x1d, 0x79, 0x44, 0x31, 0x00};
    [commands appendBytes:qrcodeStart length:6];
    unsigned char qrcodeLow = barCodeDataSize % 256;
    unsigned char qrcodeHigh = barCodeDataSize / 256;
    [commands appendBytes:&qrcodeLow length:1];
    [commands appendBytes:&qrcodeHigh length:1];
    [commands appendBytes:barCodeData length:barCodeDataSize];
    
    unsigned char printQrcodeCommand[] = {0x1b, 0x1d, 0x79, 0x50};
    [commands appendBytes:printQrcodeCommand length:4];
    
    [self sendCommand:commands portName:portName portSettings:portSettings timeoutMillis:10000];
    
}

/**
 * This function is used to print a PDF417 bar code in a standard star printer
 *
 *  @param  portName        Port name to use for communication. This should be (TCP:<IP Address>),
 *                          (BT:<iOS Port Name>), or (BLE:<Device Name>).
 *  @param  portSettings    Set following settings
 *                          - Desktop USB Printer + Apple AirPort: @"9100" - @"9109" (Port Number)
 *                          - Portable Printer (Star Line Mode)  : @"portable"
 *                          - Others                             : @"" (blank)
 *  @param  limit           Selection of the Method to use so specify the bar code size. This is either 0 or 1. 0 is
 *                          Use Limit method and 1 is Use Fixed method. See section 3-122 of the manual (Rev 1.12).
 *  @param  p1              The vertical proportion to use.  The value changes with the limit select.  See section
 *                          3-122 of the manual (Rev 1.12).
 *  @param  p2              The horizontal proportion to use.  The value changes with the limit select.  See section
 *                          3-122 of the manual (Rev 1.12).
 *  @param  securityLevel   This represents how well the bar code can be recovered if it is damaged. This value
 *                          should be 0 to 8.
 *  @param  xDirection      Specifies the X direction size. This value should be from 1 to 10. It is recommended
 *                          that the value be 2 or less.
 *  @param  aspectRatio     Specifies the ratio of the PDF417.  This values should be from 1 to 10.  It is
 *                          recommended that this value be 2 or less.
 *  @param  barcodeData     Specifies the characters in the PDF417 bar code.
 *  @param  barcodeDataSize Specifies the amount of characters to put in the barcode. This should be the size of the
 *                          preceding parameter.
 */
+ (void)PrintPDF417CodeWithPortname:(NSString *)portName portSettings:(NSString *)portSettings limit:(Limit)limit p1:(unsigned char)p1 p2:(unsigned char)p2 securityLevel:(unsigned char)securityLevel xDirection:(unsigned char)xDirection aspectRatio:(unsigned char)aspectRatio barcodeData:(unsigned char[])barcodeData barcodeDataSize:(unsigned int)barcodeDataSize
{
    NSMutableData *commands = [[NSMutableData alloc] init];
    
    unsigned char setBarCodeSize[] = {0x1b, 0x1d, 0x78, 0x53, 0x30, 0x00, 0x00, 0x00};
    switch (limit)
    {
        case USE_LIMITS:
            setBarCodeSize[5] = 0;
            break;
        case USE_FIXED:
            setBarCodeSize[5] = 1;
            break;
    }
    setBarCodeSize[6] = p1;
    setBarCodeSize[7] = p2;
    
    [commands appendBytes:setBarCodeSize length:8];
    
    unsigned char setSecurityLevel[] = {0x1b, 0x1d, 0x78, 0x53, 0x31, 0x00};
    setSecurityLevel[5] = securityLevel;
    [commands appendBytes:setSecurityLevel length:6];
    
    unsigned char setXDirections[] = {0x1b, 0x1d, 0x78, 0x53, 0x32, 0x00};
    setXDirections[5] = xDirection;
    [commands appendBytes:setXDirections length:6];
    
    unsigned char setAspectRatio[] = {0x1b, 0x1d, 0x78, 0x53, 0x33, 0x00};
    setAspectRatio[5] = aspectRatio;
    [commands appendBytes:setAspectRatio length:6];
    
    unsigned char *setBarcodeData = (unsigned char*)malloc(6 + barcodeDataSize);
    setBarcodeData[0] = 0x1b;
    setBarcodeData[1] = 0x1d;
    setBarcodeData[2] = 0x78;
    setBarcodeData[3] = 0x44;
    setBarcodeData[4] = barcodeDataSize % 256;
    setBarcodeData[5] = barcodeDataSize / 256;
    for (int index = 0; index < barcodeDataSize; index++)
    {
        setBarcodeData[index + 6] = barcodeData[index];
    }
    [commands appendBytes:setBarcodeData length:6 + barcodeDataSize];
    free(setBarcodeData);
    
    unsigned char printBarcode[] = {0x1b, 0x1d, 0x78, 0x50};
    [commands appendBytes:printBarcode length:4];
    
    [self sendCommand:commands portName:portName portSettings:portSettings timeoutMillis:10000];
    
}

#pragma mark Cut

/**
 *  This function is intended to show how to get a legacy printer to cut the paper
 *
 *  @param  portName        Port name to use for communication. This should be (TCP:<IP Address>), (BT:<iOS Port Name>),
 *                          or (BLE:<Device Name>).
 *  @param  portSettings    Set following settings
 *                          - Desktop USB Printer + Apple AirPort: @"9100" - @"9109" (Port Number)
 *                          - Portable Printer (Star Line Mode)  : @"portable"
 *                          - Others                             : @"" (blank)
 *  @param  cuttype         The cut type to perform, the cut types are full cut, full cut with feed, partial cut, and
 *                          partial cut with feed
 */
+ (void)PerformCutWithPortname:(NSString *)portName portSettings:(NSString*)portSettings cutType:(CutType)cuttype
{
    unsigned char autocutCommand[] = {0x1b, 0x64, 0x00};
    switch (cuttype)
    {
        case FULL_CUT:
            autocutCommand[2] = 48;
            break;
        case PARTIAL_CUT:
            autocutCommand[2] = 49;
            break;
        case FULL_CUT_FEED:
            autocutCommand[2] = 50;
            break;
        case PARTIAL_CUT_FEED:
            autocutCommand[2] = 51;
            break;
    }
    
    int commandSize = 3;
    
    NSData *dataToSentToPrinter = [[NSData alloc] initWithBytes:autocutCommand length:commandSize];
    
    [self sendCommand:dataToSentToPrinter portName:portName portSettings:portSettings timeoutMillis:10000];
    
}

#pragma mark Text Formatting

/**
 *  This function prints raw text to the print.  It show how the text can be formated.  For example changing its size.
 *
 *  @param  portName        Port name to use for communication. This should be (TCP:<IP Address>), (BT:<iOS Port Name>),
 *                          or (BLE:<Device Name>).
 *  @param  portSettings    Set following settings
 *                          - Desktop USB Printer + Apple AirPort: @"9100" - @"9109" (Port Number)
 *                          - Portable Printer (Star Line Mode)  : @"portable"
 *                          - Others                             : @"" (blank)
 *  @param  slashedZero     boolean variable to tell the printer to weather to put a slash in the zero characters that
 *                          it print
 *  @param  underline       boolean variable that Tells the printer if should underline the text
 *  @param  invertColor     boolean variable that tells the printer if it should invert the text its printing.  All
 *                          White space will become black and the characters will be left white
 *  @param  emphasized      boolean variable that tells the printer if it should emphasize the printed text.  This is
 *                          sort of like bold but not as dark, but darker then regular characters.
 *  @param  upperline       boolean variable that tells the printer if to place a line above the text.  This only
 *                          supported by new printers.
 *  @param  upsideDown      boolean variable that tells the printer if the text should be printed upside-down
 *  @param  heightExpansion This integer tells the printer what multiple the character height should be, this should be
 *                          from 0 to 5 representing multiples from 1 to 6
 *  @param  widthExpansion  This integer tell the printer what multiple the character width should be, this should be
 *                          from 0 to 5 representing multiples from 1 to 6.
 *  @param  leftMargin      The left margin for the text.  Although the max value for this can be 255, the value
 *                          shouldn't get that high or the text could be pushed off the page.
 *  @param  alignment       The alignment of the text. The printers support left, right, and center justification
 *  @param  textData        The text to print
 *  @param  textDataSize    The amount of text to send to the printer
 */
+ (void)PrintTextWithPortname:(NSString *)portName portSettings:(NSString*)portSettings slashedZero:(bool)slashedZero underline:(bool)underline invertColor:(bool)invertColor emphasized:(bool)emphasized upperline:(bool)upperline upsideDown:(bool)upsideDown heightExpansion:(int)heightExpansion widthExpansion:(int)widthExpansion leftMargin:(unsigned char)leftMargin alignment: (Alignment)alignment textData:(unsigned char *)textData textDataSize:(unsigned int)textDataSize
{
    NSMutableData *commands = [[NSMutableData alloc] init];
    
	unsigned char initial[] = {0x1b, 0x40};
	[commands appendBytes:initial length:2];
	
    unsigned char slashedZeroCommand[] = {0x1b, 0x2f, 0x00};
    if (slashedZero)
    {
        slashedZeroCommand[2] = 49;
    }
    else
    {
        slashedZeroCommand[2] = 48;
    }
    [commands appendBytes:slashedZeroCommand length:3];
    
    unsigned char underlineCommand[] = {0x1b, 0x2d, 0x00};
    if (underline)
    {
        underlineCommand[2] = 49;
    }
    else
    {
        underlineCommand[2] = 48;
    }
    [commands appendBytes:underlineCommand length:3];
    
    unsigned char invertColorCommand[] = {0x1b, 0x00};
    if (invertColor)
    {
        invertColorCommand[1] = 0x34;
    }
    else
    {
        invertColorCommand[1] = 0x35;
    }
    [commands appendBytes:invertColorCommand length:2];
    
    unsigned char emphasizedPrinting[] = {0x1b, 0x00};
    if (emphasized)
    {
        emphasizedPrinting[1] = 69;
    }
    else
    {
        emphasizedPrinting[1] = 70;
    }
    [commands appendBytes:emphasizedPrinting length:2];
    
    unsigned char upperLineCommand[] = {0x1b, 0x5f, 0x00};
    if (upperline)
    {
        upperLineCommand[2] = 49;
    }
    else
    {
        upperLineCommand[2] = 48;
    }
    [commands appendBytes:upperLineCommand length:3];
    
    if (upsideDown)
    {
        unsigned char upsd = 0x0f;
        [commands appendBytes:&upsd length:1];
    }
    else
    {
        unsigned char upsd = 0x12;
        [commands appendBytes:&upsd length:1];
    }
    
    unsigned char characterExpansion[] = {0x1b, 0x69, 0x00, 0x00};
    characterExpansion[2] = heightExpansion + '0';
    characterExpansion[3] = widthExpansion + '0';
    [commands appendBytes:characterExpansion length:4];
    
    unsigned char leftMarginCommand[] = {0x1b, 0x6c, 0x00};
    leftMarginCommand[2] = leftMargin;
    [commands appendBytes:leftMarginCommand length:3];
    
    unsigned char alignmentCommand[] = {0x1b, 0x1d, 0x61, 0x00};
    switch (alignment)
    {
        case Left:
            alignmentCommand[3] = 48;
            break;
        case Center:
            alignmentCommand[3] = 49;
            break;
        case Right:
            alignmentCommand[3] = 50;
            break;
    }
    [commands appendBytes:alignmentCommand length:4];
    
    [commands appendBytes:textData length:textDataSize];
    
    unsigned char lf = 0x0a;
    [commands appendBytes:&lf length:1];
    
    [self sendCommand:commands portName:portName portSettings:portSettings timeoutMillis:10000];
    
}

/**
 *  This function prints raw Kanji text to the print.  It show how the text can be formated. For example changing its
 *  size.
 *
 *  @param  portName        Port name to use for communication. This should be (TCP:<IP Address>), (BT:<iOS Port Name>),
 *                          or (BLE:<Device Name>).
 *  @param  portSettings    Set following settings
 *                          - Desktop USB Printer + Apple AirPort: @"9100" - @"9109" (Port Number)
 *                          - Portable Printer (Star Line Mode)  : @"portable"
 *                          - Others                             : @"" (blank)
 *  @param  kanjiMode       The segment index of Japanese Kanji mode that Tells the printer to weather Shift-JIS or JIS.
 *  @param  underline       boolean variable that Tells the printer if should underline the text
 *  @param  invertColor     boolean variable that tells the printer if it should invert the text its printing.  All
 *                          White space will become black and the characters will be left white
 *  @param  emphasized      boolean variable that tells the printer if it should emphasize the printed text.  This is
 *                          sort of like bold but not as dark, but darker then regular characters.
 *  @param  upperline       boolean variable that tells the printer if to place a line above the text.  This only
 *                          supported by new printers.
 *  @param  upsideDown      boolean variable that tells the printer if the text should be printed upside-down
 *  @param  heightExpansion This integer tells the printer what multiple the character height should be, this should be
 *                          from 0 to 5 representing multiples from 1 to 6
 *  @param  widthExpansion  This integer tell the printer what multiple the character width should be, this should be
 *                          from 0 to 5 representing multiples from 1 to 6.
 *  @param  leftMargin      The left margin for the text.  Although the max value for this can be 255, the value
 *                          shouldn't get that high or the text could be pushed off the page.
 *  @param  alignment       The alignment of the text. The printers support left, right, and center justification
 *  @param  textData        The text to print
 *  @param  textDataSize    The amount of text to send to the printer
 */
+ (void)PrintKanjiTextWithPortname:(NSString *)portName portSettings:(NSString*)portSettings kanjiMode:(int)kanjiMode underline:(bool)underline invertColor:(bool)invertColor emphasized:(bool)emphasized upperline:(bool)upperline upsideDown:(bool)upsideDown heightExpansion:(int)heightExpansion widthExpansion:(int)widthExpansion leftMargin:(unsigned char)leftMargin alignment:(Alignment)alignment textData:(unsigned char*)textData textDataSize:(unsigned int)textDataSize
{
    NSMutableData *commands = [[NSMutableData alloc] init];

	unsigned char initial[] = {0x1b, 0x40};
	[commands appendBytes:initial length:2];
		
    unsigned char kanjiModeCommand[] = {0x1b, 0x24, 0x00, 0x1b, 0x00};
    if (kanjiMode == 0)	// Shift-JIS
    {
        kanjiModeCommand[2] = 0x01;
        kanjiModeCommand[4] = 0x71;
    }
    else				// JIS
    {
        kanjiModeCommand[2] = 0x00;
        kanjiModeCommand[4] = 0x70;
    }
    [commands appendBytes:kanjiModeCommand length:5];
    
    unsigned char underlineCommand[] = {0x1b, 0x2d, 0x00};
    if (underline)
    {
        underlineCommand[2] = 49;
    }
    else
    {
        underlineCommand[2] = 48;
    }
    [commands appendBytes:underlineCommand length:3];
    
    unsigned char invertColorCommand[] = {0x1b, 0x00};
    if (invertColor)
    {
        invertColorCommand[1] = 0x34;
    }
    else
    {
        invertColorCommand[1] = 0x35;
    }
    [commands appendBytes:invertColorCommand length:2];
    
    unsigned char emphasizedPrinting[] = {0x1b, 0x00};
    if (emphasized)
    {
        emphasizedPrinting[1] = 69;
    }
    else
    {
        emphasizedPrinting[1] = 70;
    }
    [commands appendBytes:emphasizedPrinting length:2];
    
    unsigned char upperLineCommand[] = {0x1b, 0x5f, 0x00};
    if (upperline)
    {
        upperLineCommand[2] = 49;
    }
    else
    {
        upperLineCommand[2] = 48;
    }
    [commands appendBytes:upperLineCommand length:3];
    
    if (upsideDown)
    {
        unsigned char upsd = 0x0f;
        [commands appendBytes:&upsd length:1];
    }
    else
    {
        unsigned char upsd = 0x12;
        [commands appendBytes:&upsd length:1];
    }
    
    unsigned char characterExpansion[] = {0x1b, 0x69, 0x00, 0x00};
    characterExpansion[2] = heightExpansion + '0';
    characterExpansion[3] = widthExpansion + '0';
    [commands appendBytes:characterExpansion length:4];
    
    unsigned char leftMarginCommand[] = {0x1b, 0x6c, 0x00};
    leftMarginCommand[2] = leftMargin;
    [commands appendBytes:leftMarginCommand length:3];
    
    unsigned char alignmentCommand[] = {0x1b, 0x1d, 0x61, 0x00};
    switch (alignment)
    {
        case Left:
            alignmentCommand[3] = 48;
            break;
        case Center:
            alignmentCommand[3] = 49;
            break;
        case Right:
            alignmentCommand[3] = 50;
            break;
    }
    [commands appendBytes:alignmentCommand length:4];
    
    [commands appendBytes:textData length:textDataSize];
    
    unsigned char lf = 0x0a;
    [commands appendBytes:&lf length:1];
    
    [self sendCommand:commands portName:portName portSettings:portSettings timeoutMillis:10000];

}

/**
 *  This function prints raw Simplified Chinese text to the print. It show how the text can be formated. For example
 *  changing its size.
 *
 *  @param  portName        Port name to use for communication. This should be (TCP:<IP Address>), (BT:<iOS Port Name>),
 *                          or (BLE:<Device Name>).
 *  @param  portSettings    Set following settings
 *                          - Desktop USB Printer + Apple AirPort: @"9100" - @"9109" (Port Number)
 *                          - Portable Printer (Star Line Mode)  : @"portable"
 *                          - Others                             : @"" (blank)
 *  @param  underline       boolean variable that Tells the printer if should underline the text
 *  @param  invertColor     boolean variable that tells the printer if it should invert the text its printing.  All
 *                          White space will become black and the characters will be left white
 *  @param  emphasized      boolean variable that tells the printer if it should emphasize the printed text.  This is
 *                          sort of like bold but not as dark, but darker then regular characters.
 *  @param  upperline       boolean variable that tells the printer if to place a line above the text.  This only
 *                          supported by new printers.
 *  @param  upsideDown      boolean variable that tells the printer if the text should be printed upside-down
 *  @param  heightExpansion This integer tells the printer what multiple the character height should be, this should be
 *                          from 0 to 5 representing multiples from 1 to 6
 *  @param  widthExpansion  This integer tell the printer what multiple the character width should be, this should be
 *                          from 0 to 5 representing multiples from 1 to 6.
 *  @param  leftMargin      The left margin for the text.  Although the max value for this can be 255, the value
 *                          shouldn't get that high or the text could be pushed off the page.
 *  @param  alignment       The alignment of the text. The printers support left, right, and center justification
 *  @param  textData        The text to print
 *  @param  textDataSize    The amount of text to send to the printer
 */
+ (void)PrintCHSTextWithPortname:(NSString *)portName portSettings:(NSString*)portSettings underline:(bool)underline invertColor:(bool)invertColor emphasized:(bool)emphasized upperline:(bool)upperline upsideDown:(bool)upsideDown heightExpansion:(int)heightExpansion widthExpansion:(int)widthExpansion leftMargin:(unsigned char)leftMargin alignment:(Alignment)alignment textData:(unsigned char*)textData textDataSize:(unsigned int)textDataSize
{
    NSMutableData *commands = [[NSMutableData alloc] init];
    
	unsigned char initial[] = {0x1b, 0x40};
	[commands appendBytes:initial length:2];
    
    unsigned char underlineCommand[] = {0x1b, 0x2d, 0x00};
    if (underline)
    {
        underlineCommand[2] = 49;
    }
    else
    {
        underlineCommand[2] = 48;
    }
    [commands appendBytes:underlineCommand length:3];
    
    unsigned char invertColorCommand[] = {0x1b, 0x00};
    if (invertColor)
    {
        invertColorCommand[1] = 0x34;
    }
    else
    {
        invertColorCommand[1] = 0x35;
    }
    [commands appendBytes:invertColorCommand length:2];
    
    unsigned char emphasizedPrinting[] = {0x1b, 0x00};
    if (emphasized)
    {
        emphasizedPrinting[1] = 69;
    }
    else
    {
        emphasizedPrinting[1] = 70;
    }
    [commands appendBytes:emphasizedPrinting length:2];
    
    unsigned char upperLineCommand[] = {0x1b, 0x5f, 0x00};
    if (upperline)
    {
        upperLineCommand[2] = 49;
    }
    else
    {
        upperLineCommand[2] = 48;
    }
    [commands appendBytes:upperLineCommand length:3];
    
    if (upsideDown)
    {
        unsigned char upsd = 0x0f;
        [commands appendBytes:&upsd length:1];
    }
    else
    {
        unsigned char upsd = 0x12;
        [commands appendBytes:&upsd length:1];
    }
    
    unsigned char characterExpansion[] = {0x1b, 0x69, 0x00, 0x00};
    characterExpansion[2] = heightExpansion + '0';
    characterExpansion[3] = widthExpansion + '0';
    [commands appendBytes:characterExpansion length:4];
    
    unsigned char leftMarginCommand[] = {0x1b, 0x6c, 0x00};
    leftMarginCommand[2] = leftMargin;
    [commands appendBytes:leftMarginCommand length:3];
    
    unsigned char alignmentCommand[] = {0x1b, 0x1d, 0x61, 0x00};
    switch (alignment)
    {
        case Left:
            alignmentCommand[3] = 48;
            break;
        case Center:
            alignmentCommand[3] = 49;
            break;
        case Right:
            alignmentCommand[3] = 50;
            break;
    }
    [commands appendBytes:alignmentCommand length:4];
    
    [commands appendBytes:textData length:textDataSize];
    
    unsigned char lf = 0x0a;
    [commands appendBytes:&lf length:1];
    
    [self sendCommand:commands portName:portName portSettings:portSettings timeoutMillis:10000];
    
}

/**
 *  This function prints raw Traditional Chinese text to the print. It show how the text can be formated.  For example
 *  changing its size.
 *
 *  @param  portName        Port name to use for communication. This should be (TCP:<IP Address>), (BT:<iOS Port Name>),
 *                          or (BLE:<Device Name>).
 *  @param  portSettings    Set following settings
 *                          - Desktop USB Printer + Apple AirPort: @"9100" - @"9109" (Port Number)
 *                          - Portable Printer (Star Line Mode)  : @"portable"
 *                          - Others                             : @"" (blank)
 *  @param  underline       boolean variable that Tells the printer if should underline the text
 *  @param  invertColor     boolean variable that tells the printer if it should invert the text its printing. All White
 *                          space will become black and the characters will be left white
 *  @param  emphasized      boolean variable that tells the printer if it should emphasize the printed text. This is
 *                          sort of like bold but not as dark, but darker then regular characters.
 *  @param  upperline       boolean variable that tells the printer if to place a line above the text.  This only
 *                          supported by new printers.
 *  @param  upsideDown      boolean variable that tells the printer if the text should be printed upside-down
 *  @param  heightExpansion This integer tells the printer what multiple the character height should be, this should be
 *                          from 0 to 5 representing multiples from 1 to 6
 *  @param  widthExpansion  This integer tell the printer what multiple the character width should be, this should be
 *                          from 0 to 5 representing multiples from 1 to 6.
 *  @param  leftMargin      The left margin for the text.  Although the max value for this can be 255, the value
 *                          shouldn't get that high or the text could be pushed off the page.
 *  @param  alignment       The alignment of the text. The printers support left, right, and center justification
 *  @param  textData        The text to print
 *  @param  textDataSize    The amount of text to send to the printer
 */
+ (void)PrintCHTTextWithPortname:(NSString *)portName portSettings:(NSString*)portSettings underline:(bool)underline invertColor:(bool)invertColor emphasized:(bool)emphasized upperline:(bool)upperline upsideDown:(bool)upsideDown heightExpansion:(int)heightExpansion widthExpansion:(int)widthExpansion leftMargin:(unsigned char)leftMargin alignment:(Alignment)alignment textData:(unsigned char*)textData textDataSize:(unsigned int)textDataSize
{
    NSMutableData *commands = [[NSMutableData alloc] init];
    
	unsigned char initial[] = {0x1b, 0x40};
	[commands appendBytes:initial length:2];
    
    unsigned char underlineCommand[] = {0x1b, 0x2d, 0x00};
    if (underline)
    {
        underlineCommand[2] = 49;
    }
    else
    {
        underlineCommand[2] = 48;
    }
    [commands appendBytes:underlineCommand length:3];
    
    unsigned char invertColorCommand[] = {0x1b, 0x00};
    if (invertColor)
    {
        invertColorCommand[1] = 0x34;
    }
    else
    {
        invertColorCommand[1] = 0x35;
    }
    [commands appendBytes:invertColorCommand length:2];
    
    unsigned char emphasizedPrinting[] = {0x1b, 0x00};
    if (emphasized)
    {
        emphasizedPrinting[1] = 69;
    }
    else
    {
        emphasizedPrinting[1] = 70;
    }
    [commands appendBytes:emphasizedPrinting length:2];
    
    unsigned char upperLineCommand[] = {0x1b, 0x5f, 0x00};
    if (upperline)
    {
        upperLineCommand[2] = 49;
    }
    else
    {
        upperLineCommand[2] = 48;
    }
    [commands appendBytes:upperLineCommand length:3];
    
    if (upsideDown)
    {
        unsigned char upsd = 0x0f;
        [commands appendBytes:&upsd length:1];
    }
    else
    {
        unsigned char upsd = 0x12;
        [commands appendBytes:&upsd length:1];
    }
    
    unsigned char characterExpansion[] = {0x1b, 0x69, 0x00, 0x00};
    characterExpansion[2] = heightExpansion + '0';
    characterExpansion[3] = widthExpansion + '0';
    [commands appendBytes:characterExpansion length:4];
    
    unsigned char leftMarginCommand[] = {0x1b, 0x6c, 0x00};
    leftMarginCommand[2] = leftMargin;
    [commands appendBytes:leftMarginCommand length:3];
    
    unsigned char alignmentCommand[] = {0x1b, 0x1d, 0x61, 0x00};
    switch (alignment)
    {
        case Left:
            alignmentCommand[3] = 48;
            break;
        case Center:
            alignmentCommand[3] = 49;
            break;
        case Right:
            alignmentCommand[3] = 50;
            break;
    }
    [commands appendBytes:alignmentCommand length:4];
    
    [commands appendBytes:textData length:textDataSize];
    
    unsigned char lf = 0x0a;
    [commands appendBytes:&lf length:1];
    
    [self sendCommand:commands portName:portName portSettings:portSettings timeoutMillis:10000];
    
}

#pragma mark common

/**
 * This function is used to print a UIImage directly to the printer.
 * There are 2 ways a printer can usually print images, one is through raster commands the other is through line mode
 * commands.
 * This function uses raster commands to print an image. Raster is support on the tsp100 and all legacy thermal
 * printers. The line mode printing is not supported by the TSP100 so its not used
 *
 *  @param  portName        Port name to use for communication. This should be (TCP:<IP Address>), (BT:<iOS Port Name>),
 *                          or (BLE:<Device Name>).
 *  @param  portSettings    Set following settings
 *                          - Desktop USB Printer + Apple AirPort: @"9100" - @"9109" (Port Number)
 *                          - Portable Printer (Star Line Mode)  : @"portable"
 *                          - Others                             : @"" (blank)
 *  @param  source          The uiimage to convert to star raster data
 *  @param  maxWidth        The maximum with the image to print. This is usually the page with of the printer. If the
 *                          image exceeds the maximum width then the image is scaled down. The ratio is maintained.
 */
+ (void)PrintImageWithPortname:(NSString *)portName
                  portSettings:(NSString*)portSettings
                  imageToPrint:(UIImage*)imageToPrint
                      maxWidth:(int)maxWidth
             compressionEnable:(BOOL)compressionEnable
                withDrawerKick:(BOOL)drawerKick
{
    NSMutableData *commandsToPrint = [NSMutableData new];
    
    SMPrinterType printerType = [AppDelegate parsePortSettings:portSettings];
    StarBitmap *starbitmap = [[StarBitmap alloc] initWithUIImage:imageToPrint :maxWidth :false];
    
    if (printerType == SMPrinterTypeDesktopPrinterStarLine) {
        RasterDocument *rasterDoc = [[RasterDocument alloc] initWithDefaults:RasSpeed_Medium endOfPageBehaviour:RasPageEndMode_FeedAndFullCut endOfDocumentBahaviour:RasPageEndMode_FeedAndFullCut topMargin:RasTopMargin_Standard pageLength:0 leftMargin:0 rightMargin:0];
        
        NSData *shortcommand = [rasterDoc BeginDocumentCommandData];
        [commandsToPrint appendData:shortcommand];
        
        shortcommand = [starbitmap getImageDataForPrinting:compressionEnable];
        [commandsToPrint appendData:shortcommand];
        
        shortcommand = [rasterDoc EndDocumentCommandData];
        [commandsToPrint appendData:shortcommand];
        
    } else if (printerType == SMPrinterTypePortablePrinterStarLine) {
        NSData *shortcommand = [starbitmap getGraphicsDataForPrinting:compressionEnable];
        [commandsToPrint appendData:shortcommand];
    } else {
        return;
    }
    
    
    // Kick Cash Drawer
    if (drawerKick == YES) {
        [commandsToPrint appendBytes:"\x07"
                              length:sizeof("\x07") - 1];
    }
    
    [self sendCommand:commandsToPrint portName:portName portSettings:portSettings timeoutMillis:10000];

}

+ (void)sendCommand:(NSData *)commandsToPrint portName:(NSString *)portName portSettings:(NSString *)portSettings timeoutMillis:(u_int32_t)timeoutMillis
{
    int commandSize = (int)commandsToPrint.length;
    unsigned char *dataToSentToPrinter = (unsigned char *)malloc(commandSize);
    [commandsToPrint getBytes:dataToSentToPrinter length:commandSize];
    
    SMPort *starPort = nil;
    @try
    {
        starPort = [SMPort getPort:portName :portSettings :timeoutMillis];
        if (starPort == nil)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Fail to Open Port.\nRefer to \"getPort API\" in the manual."
                                                            message:@""
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            return;
        }
        
        StarPrinterStatus_2 status;
        [starPort beginCheckedBlock:&status :2];
        if (status.offline == SM_TRUE) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:@"Printer is offline"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            return;
        }
        
        struct timeval endTime;
        gettimeofday(&endTime, NULL);
        endTime.tv_sec += 30;
        
        int totalAmountWritten = 0;
        while (totalAmountWritten < commandSize)
        {
            int remaining = commandSize - totalAmountWritten;
            int amountWritten = [starPort writePort:dataToSentToPrinter :totalAmountWritten :remaining];
            totalAmountWritten += amountWritten;
            
            struct timeval now;
            gettimeofday(&now, NULL);
            if (now.tv_sec > endTime.tv_sec)
            {
                break;
            }
        }
        
        if (totalAmountWritten < commandSize)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Printer Error"
                                                            message:@"Write port timed out"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            return;
        }
        
        starPort.endCheckedBlockTimeoutMillis = 30000;
        [starPort endCheckedBlock:&status :2];
        if (status.offline == SM_TRUE) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:@"Printer is offline"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            return;
        }
    }
    @catch (PortException *exception)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Printer Error"
                                                        message:@"Write port timed out"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    @finally
    {
        free(dataToSentToPrinter);
        [SMPort releasePort:starPort];
    }
}

#pragma mark Sample Receipt (Line)

/*!
 *  Sample Receipt 3inch
 */

+(NSData *)testPrintSampleReceipt:(NSString *)docNo
{
    NSMutableData *commands = [NSMutableData data];
    
    [commands appendBytes:"\x1b\x1d\x61\x01"
                   length:sizeof("\x1b\x1d\x61\x01") - 1];    // center
    
    [commands appendData:[@"Star Clothing Boutique\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
    
    [commands appendData:[@"123 Star Road\r\nCity, State 12345\r\nTel : 03-45458888\r\nGST Id : 7557585-09\r\nReceipt : IV000000091\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
    
    [commands appendBytes:"\x1b\x1d\x61\x00"
                   length:sizeof("\x1b\x1d\x61\x00") - 1];    // Alignment(left)
    
    [commands appendBytes:"\x1b\x44\x02\x10\x22\x00"
                   length:sizeof("\x1b\x44\x02\x10\x22\x00") - 1];    // SetHT
    
    [commands appendData:[@"Date: MM/DD/YYYY" dataUsingEncoding:NSASCIIStringEncoding]];
    
    [commands appendBytes:" \x09 "
                   length:sizeof(" \x09 ") - 1];
    
    [commands appendData:[@"Time:HH:MM PM\r\n------------------------------------------------\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
    
    [commands appendBytes:"\x1b\x45"
                   length:sizeof("\x1b\x45") - 1];    // SetBold
    
    [commands appendData:[@"SALE \r\n" dataUsingEncoding:NSASCIIStringEncoding]];
    
    [commands appendBytes:"\x1b\x46"
                   length:sizeof("\x1b\x46") - 1];    // CancelBold
    
    [commands appendData:[@"SKU " dataUsingEncoding:NSASCIIStringEncoding]];
    
    [commands appendBytes:"\x09"
                   length:sizeof("\x09") - 1];    // HT
    
    [commands appendData:[@"  Description   \x09         Total\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
    
    [commands appendData:[@"300678566 \x09  PLAIN T-SHIRT\x09         10.99\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
    
    [commands appendData:[@"300692003 \x09  BLACK DENIM\x09         29.99\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
    
    [commands appendData:[@"300651148 \x09  BLUE DENIM\x09         29.99\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
    
    [commands appendData:[@"300642980 \x09  STRIPED DRESS\x09         49.99\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
    
    [commands appendData:[@"300638471 \x09  BLACK BOOTS\x09         35.99\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
    
    [commands appendData:[@"------------------------------------------------\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
    
    [commands appendData:[@"SubTotal                                  156.95\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
    
    [commands appendData:[@"Discount                                    0.00\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
    
    [commands appendData:[@"Total GST                                   0.00\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
    
    [commands appendData:[@"Rounding                                    0.00\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
    
    [commands appendData:[@"Total" dataUsingEncoding:NSASCIIStringEncoding]];
    
    [commands appendBytes:"\x09\x09\x1b\x69\x01\x01"
                   length:sizeof("\x09\x09\x1b\x69\x01\x01") - 1];    // SetDoubleHW
    
    [commands appendData:[@"156.95\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
    
    [commands appendBytes:"\x1b\x69\x00\x00"
                   length:sizeof("\x1b\x69\x00\x00") - 1];    // CancelDoubleHW
    
    [commands appendData:[@"Pay                                       156.95\r\n" dataUsingEncoding:NSASCIIStringEncoding]];

    [commands appendData:[@"Change                                      0.00\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
    
    [commands appendData:[@"------------------------------------------------\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
    
    [commands appendBytes:"\x1b\x1d\x61\x01"
                   length:sizeof("\x1b\x1d\x61\x01") - 1];    // Alignment(center)
    
    [commands appendData:[@"\x1b\x34Goods Sold Are Not Refundable\x1b\x35\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
    
    [commands appendBytes:"\x1b\x1d\x61\x01"
                   length:sizeof("\x1b\x1d\x61\x01") - 1];    // Alignment(center)
    
    [commands appendData:[@"\x1b\x34Thanks You\x1b\x35\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
    
    [commands appendBytes:"\x1b\x64\x02"
                   length:sizeof("\x1b\x64\x02") - 1];    // CutPaper
    
    return commands;
}

+ (NSData *)english3inchSampleReceipt:(NSString *)docNo EnableGstYN:(int)enablestYN
{
    NSString *dbPath = [[LibraryAPI sharedInstance]getDbPath];
    //FMDatabase *dbTable;
    NSMutableArray *invArray = [[NSMutableArray alloc]init];
    NSMutableArray *compArray = [[NSMutableArray alloc]init];
    NSString *tableName;
    [invArray removeAllObjects];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    
        FMResultSet *rsCompany = [db executeQuery:@"Select * from Company"];
        while ([rsCompany next]) {
            [compArray addObject:[rsCompany resultDictionary]];
        }
        
        
        FMResultSet *rs = [db executeQuery:@"Select *,IFNULL(IvD_ItemTaxCode,'') || ': ' || IvD_ItemDescription as ItemDesc,IvD_ItemDescription as ItemDesc2,IFNULL(IvD_ItemTaxCode,'-') as Flag from InvoiceHdr InvH "
                       " left join InvoiceDtl InvD on InvH.IvH_DocNo = InvD.IvD_DocNo"
                           " left join ItemMast IM on IM.IM_ItemCode = InvD.IvD_ItemCode"
                       " where InvH.IvH_DocNo = ?",docNo];
    
        while ([rs next]) {
            [invArray addObject:[rs resultDictionary]];
        }
    
        [rs close];
    //[dbTable close];
    
    }];
    
    int count;
    
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    NSString *dateString = [dateFormat stringFromDate:today];
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
    NSString *timeString = [timeFormat stringFromDate:today];
    NSString *hdr;
    NSString *gstTitle = @"Tax Invocie";
    
    if (enablestYN == 1) {
        hdr = [NSString stringWithFormat:@"%@\r\n%@\r\n%@\r\n%@\r\nTel :%@\r\nGST ID: %@\r\n%@\r\nReceipt :%@\r\n",[[compArray objectAtIndex:0]objectForKey:@"Comp_Company"],[[compArray objectAtIndex:0]objectForKey:@"Comp_Address1"],[[compArray objectAtIndex:0]objectForKey:@"Comp_Address2"],[[compArray objectAtIndex:0]objectForKey:@"Comp_Address3"],[[compArray objectAtIndex:0]objectForKey:@"Comp_Telephone"],[[compArray objectAtIndex:0]objectForKey:@"Comp_GstNo"],gstTitle,[[invArray objectAtIndex:0]objectForKey:@"IvH_DocNo"]];
    }
    else
    {
        hdr = [NSString stringWithFormat:@"%@\r\n%@\r\n%@\r\n%@\r\nTel :%@\r\nReceipt :%@\r\n",[[compArray objectAtIndex:0]objectForKey:@"Comp_Company"],[[compArray objectAtIndex:0]objectForKey:@"Comp_Address1"],[[compArray objectAtIndex:0]objectForKey:@"Comp_Address2"],[[compArray objectAtIndex:0]objectForKey:@"Comp_Address3"],[[compArray objectAtIndex:0]objectForKey:@"Comp_Telephone"],[[invArray objectAtIndex:0]objectForKey:@"IvH_DocNo"]];
    }
    
    
    //----------
    tableName = [[invArray objectAtIndex:0] objectForKey:@"IvH_Table"];
    count = 18 - [dateString length];
    
    NSString *hcol = dateString;
    hcol = [NSString stringWithFormat:@"%@%@",hcol,
            [@" " stringByPaddingToLength:count withString:@" " startingAtIndex:0]];
    
    count = 24 - [timeString length];
    hcol = [NSString stringWithFormat:@"Date:%@ %@",hcol,[NSString stringWithFormat:@"%@%@\r\n\r\n",
                                                               [@" " stringByPaddingToLength:count withString:@" " startingAtIndex:0],
                                                               timeString]];
    //---------------------------
    
    
    
    //NSString *detail = @"%@ %@ %@ %@\r\n";
    
    NSString *data1 = @"";
    NSString *data2 = @"";
    NSString *data3 = @"";
    NSString *data4 = @"";
    NSString *data5 = @"";
    double subTotalB4Gst = 0.00;
    NSMutableString *combineData = [[NSMutableString alloc]init];

    
    for (int i = 0; i<invArray.count; i++) {
        
        if (enablestYN == 1) {
            if ([[[invArray objectAtIndex:i]objectForKey:@"Flag"] isEqualToString:@"-"]) {
                data1 = [[invArray objectAtIndex:i] objectForKey:@"ItemDesc2"];
            }
            else
            {
                data1 = [[invArray objectAtIndex:i] objectForKey:@"ItemDesc"];
            }
            
        }
        else
        {
            data1 = [[invArray objectAtIndex:i] objectForKey:@"ItemDesc2"];
        }
        
        
        
        if ([[[invArray objectAtIndex:i] objectForKey:@"ItemDesc"] length] > 18) data1 = [[[invArray objectAtIndex:i] objectForKey:@"ItemDesc"] substringToIndex:18];
        
        subTotalB4Gst = subTotalB4Gst + [[[invArray objectAtIndex:i] objectForKey:@"IvD_TotalEx"] doubleValue];
        
        data2 = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:i] objectForKey:@"IvD_Quantity"] doubleValue]];
        if ([[[[invArray objectAtIndex:i] objectForKey:@"IvD_Quantity"] stringValue] length] > 9) data2 = [[[[invArray objectAtIndex:i] objectForKey:@"IvD_Quantity"] stringValue] substringToIndex:7];
        
        data3 = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:i] objectForKey:@"IvD_Price"] doubleValue]];
        if ([[[[invArray objectAtIndex:i] objectForKey:@"IvD_Price"] stringValue] length] > 9) data2 = [[[[invArray objectAtIndex:i] objectForKey:@"IvD_Price"] stringValue] substringToIndex:7];
        
        data4 = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:i] objectForKey:@"IvD_SubTotal"] doubleValue]];
        if ([[[[invArray objectAtIndex:i] objectForKey:@"IvD_SubTotal"] stringValue]length] > 9) data4 = [[[[invArray objectAtIndex:i] objectForKey:@"IvD_SubTotal"] stringValue] substringToIndex:7];
        
        
        [combineData appendString:[NSString stringWithFormat:@"%@ %@ %@ %@",
                                   [NSString stringWithFormat:@"%@%@",data1,[@" " stringByPaddingToLength:18-[data1 length] withString:@" " startingAtIndex:0]],
                                   [NSString stringWithFormat:@"%@%@",
                                    [@" " stringByPaddingToLength:9 - [data2 length] withString:@" " startingAtIndex:0],
                                    data2],
                                   [NSString stringWithFormat:@"%@%@",
                                    [@" " stringByPaddingToLength:9 - [data3 length] withString:@" " startingAtIndex:0],
                                    data3],
                                   [NSString stringWithFormat:@"%@%@",
                                    [@" " stringByPaddingToLength:9 - [data4 length] withString:@" " startingAtIndex:0],
                                    data4]
                                   ]];
        
        if ([[[invArray objectAtIndex:i] objectForKey:@"IM_Description2"]length] > 0)
        {
            data5 = [[invArray objectAtIndex:i] objectForKey:@"IM_Description2"];
        }
        
        [combineData appendString:data5];
        
    }
    
    //-------------------------------------------
    NSMutableData *commands = [NSMutableData data];

    [commands appendBytes:"\x1b\x1d\x61\x01"
            length:sizeof("\x1b\x1d\x61\x01") - 1];    // center
    
    
    [commands appendData:[hdr dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    [commands appendBytes:"\x1b\x1d\x61\x00"
            length:sizeof("\x1b\x1d\x61\x00") - 1];    // Alignment(left)

    [commands appendBytes:"\x1b\x44\x02\x10\x22\x00"
            length:sizeof("\x1b\x44\x02\x10\x22\x00") - 1];    // SetHT

    [commands appendData:[hcol dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    [commands appendBytes:"\x1b\x45"
            length:sizeof("\x1b\x45") - 1];    // SetBold

    [commands appendData:[[NSString stringWithFormat:@"%@%@\r\n",@"SALE Table:",tableName] dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];

    [commands appendBytes:"\x1b\x46"
            length:sizeof("\x1b\x46") - 1];    // CancelBold

    [commands appendData:[@"Item                     Qty     Price     Total\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
    
    [commands appendData:[combineData dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    
    [commands appendData:[@"------------------------------------------------\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
    
    [commands appendBytes:"\x1b\x45"
                   length:sizeof("\x1b\x45") - 1];    // SetBold
    
    NSString *footAmt;
    NSString *docAmt;
    
    
    docAmt = [NSString stringWithFormat:@"%0.2f",subTotalB4Gst];
    footAmt = [NSString stringWithFormat:@"%@ %@\r\n",
               [NSString stringWithFormat:@"%@%@",@"Subtotal Exlude GST",[@" " stringByPaddingToLength:40-19 withString:@" " startingAtIndex:0]],
               [NSString stringWithFormat:@"%@%@",
                [@" " stringByPaddingToLength:7 - [docAmt length] withString:@" " startingAtIndex:0],
                docAmt]
               ];
    
    [commands appendData:[footAmt dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    docAmt = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:0] objectForKey:@"IvH_DocSubTotal"] doubleValue]];
    footAmt = [NSString stringWithFormat:@"%@ %@\r\n",
               [NSString stringWithFormat:@"%@%@",@"Subtotal",[@" " stringByPaddingToLength:40-8 withString:@" " startingAtIndex:0]],
               [NSString stringWithFormat:@"%@%@",
                [@" " stringByPaddingToLength:7 - [docAmt length] withString:@" " startingAtIndex:0],
                docAmt]
               ];
    
    
    [commands appendData:[footAmt dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    docAmt = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:0] objectForKey:@"IvH_DiscAmt"] doubleValue]];
    footAmt = [NSString stringWithFormat:@"%@ %@\r\n",
               [NSString stringWithFormat:@"%@%@",@"Discount",[@" " stringByPaddingToLength:40-8 withString:@" " startingAtIndex:0]],
               [NSString stringWithFormat:@"%@%@",
                [@" " stringByPaddingToLength:7 - [docAmt length] withString:@" " startingAtIndex:0],
                docAmt]
               ];
    
    [commands appendData:[footAmt dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    
    docAmt = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:0] objectForKey:@"IvH_DocServiceTaxAmt"] doubleValue]];
    footAmt = [NSString stringWithFormat:@"%@ %@\r\n",
               [NSString stringWithFormat:@"%@%@",@"Service Charge",[@" " stringByPaddingToLength:40-14 withString:@" " startingAtIndex:0]],
               [NSString stringWithFormat:@"%@%@",
                [@" " stringByPaddingToLength:7 - [docAmt length] withString:@" " startingAtIndex:0],
                docAmt]
               ];
    
    [commands appendData:[footAmt dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    if (enablestYN == 1) {
        docAmt = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:0] objectForKey:@"IvH_DocTaxAmt"] doubleValue]];
        footAmt = [NSString stringWithFormat:@"%@ %@\r\n",
               [NSString stringWithFormat:@"%@%@",@"Total GST",[@" " stringByPaddingToLength:40-9 withString:@" " startingAtIndex:0]],
               [NSString stringWithFormat:@"%@%@",
                [@" " stringByPaddingToLength:7 - [docAmt length] withString:@" " startingAtIndex:0],
                docAmt]
               ];
    
        [commands appendData:[footAmt dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    }
    
    docAmt = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:0] objectForKey:@"IvH_Rounding"] doubleValue]];
    footAmt = [NSString stringWithFormat:@"%@ %@\r\n",
               [NSString stringWithFormat:@"%@%@",@"Rounding",[@" " stringByPaddingToLength:40-8 withString:@" " startingAtIndex:0]],
               [NSString stringWithFormat:@"%@%@",
                [@" " stringByPaddingToLength:7 - [docAmt length] withString:@" " startingAtIndex:0],
                docAmt]
               ];
    
    [commands appendData:[footAmt dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    [commands appendBytes:"\x1b\x46"
                   length:sizeof("\x1b\x46") - 1];    // CancelBold
    
    [commands appendData:[@"Total" dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    [commands appendBytes:"\x09\x09\x1b\x69\x01\x01"
            length:sizeof("\x09\x09\x1b\x69\x01\x01") - 1];    // SetDoubleHW

    
    docAmt = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:0] objectForKey:@"IvH_DocAmt"] doubleValue]];
    footAmt = [NSString stringWithFormat:@"%@\r\n",
               [NSString stringWithFormat:@"%@%@",
                [@" " stringByPaddingToLength:7 - [docAmt length] withString:@" " startingAtIndex:0],
                docAmt]
               ];
    
    [commands appendData:[footAmt dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];

    [commands appendBytes:"\x1b\x69\x00\x00"
            length:sizeof("\x1b\x69\x00\x00") - 1];    // CancelDoubleHW
    
    
    [commands appendBytes:"\x1b\x45"
                   length:sizeof("\x1b\x45") - 1];    // SetBold
    
    docAmt = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:0] objectForKey:@"IvH_TotalPay"] doubleValue]];
    footAmt = [NSString stringWithFormat:@"%@ %@\r\n",
               [NSString stringWithFormat:@"%@%@",@"Pay",[@" " stringByPaddingToLength:40-3 withString:@" " startingAtIndex:0]],
               [NSString stringWithFormat:@"%@%@",
                [@" " stringByPaddingToLength:7 - [docAmt length] withString:@" " startingAtIndex:0],
                docAmt]
               ];
    
    [commands appendData:[footAmt dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    docAmt = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:0] objectForKey:@"IvH_ChangeAmt"] doubleValue]];
    footAmt = [NSString stringWithFormat:@"%@ %@\r\n",
               [NSString stringWithFormat:@"%@%@",@"Change",[@" " stringByPaddingToLength:40-6 withString:@" " startingAtIndex:0]],
               [NSString stringWithFormat:@"%@%@",
                [@" " stringByPaddingToLength:7 - [docAmt length] withString:@" " startingAtIndex:0],
                docAmt]
               ];
    
    [commands appendData:[footAmt dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    [commands appendBytes:"\x1b\x46"
                   length:sizeof("\x1b\x46") - 1];    // CancelBold
    
    [commands appendData:[@"------------------------------------------------\r\n\r\n" dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];

    /*
    [commands appendBytes:"\x1b\x1d\x61\x01"
                   length:sizeof("\x1b\x1d\x61\x01") - 1];    // Alignment(center)
    
    [commands appendData:[@"\x1b\x34Goods Sold Are Not Refundable\x1b\x35\r\n" dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    [commands appendBytes:"\x1b\x1d\x61\x01"
                   length:sizeof("\x1b\x1d\x61\x01") - 1];    // Alignment(center)
    
    [commands appendData:[@"\x1b\x34Thanks You\x1b\x35\r\n" dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
     */
    
    [commands appendBytes:"\x1b\x64\x02"
            length:sizeof("\x1b\x64\x02") - 1];    // CutPaper

    return commands;
}


+ (NSData *)english3inchSOReceipt:(NSString *)docNo EnableGstYN:(int)enableGstYN
{
    NSString *dbPath = [[LibraryAPI sharedInstance]getDbPath];
    //FMDatabase *dbTable;
    NSMutableArray *invArray = [[NSMutableArray alloc]init];
    NSMutableArray *compArray = [[NSMutableArray alloc]init];
    NSString *tableName;
    [invArray removeAllObjects];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rsCompany = [db executeQuery:@"Select * from Company"];
        while ([rsCompany next]) {
            [compArray addObject:[rsCompany resultDictionary]];
        }
        
        
        FMResultSet *rs = [db executeQuery:@"Select *, SOD_ItemDescription as ItemDesc from SalesOrderHdr Hdr "
                           " left join SalesOrderDtl Dtl on Hdr.SOH_DocNo = Dtl.SOD_DocNo"
                           " left join ItemMast IM on IM.IM_ItemCode = Dtl.SOD_ItemCode"
                           " where Hdr.SOH_DocNo = ?",docNo];
        
        while ([rs next]) {
            [invArray addObject:[rs resultDictionary]];
        }
        
        [rs close];
        //[dbTable close];
        
    }];
    
    int count;
    
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    NSString *dateString = [dateFormat stringFromDate:today];
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
    NSString *timeString = [timeFormat stringFromDate:today];
    NSString *hdr;
    
    if (enableGstYN == 1) {
        hdr = [NSString stringWithFormat:@"%@\r\n%@\r\n%@\r\n%@\r\nTel :%@\r\nGST ID: %@\r\nRecipt :%@\r\n",[[compArray objectAtIndex:0]objectForKey:@"Comp_Company"],[[compArray objectAtIndex:0]objectForKey:@"Comp_Address1"],[[compArray objectAtIndex:0]objectForKey:@"Comp_Address2"],[[compArray objectAtIndex:0]objectForKey:@"Comp_Address3"],[[compArray objectAtIndex:0]objectForKey:@"Comp_Telephone"],[[compArray objectAtIndex:0]objectForKey:@"Comp_GstNo"],[[invArray objectAtIndex:0]objectForKey:@"SOH_DocNo"]];
    }
    else
    {
        hdr = [NSString stringWithFormat:@"%@\r\n%@\r\n%@\r\n%@\r\nTel :%@\r\nRecipt :%@\r\n",[[compArray objectAtIndex:0]objectForKey:@"Comp_Company"],[[compArray objectAtIndex:0]objectForKey:@"Comp_Address1"],[[compArray objectAtIndex:0]objectForKey:@"Comp_Address2"],[[compArray objectAtIndex:0]objectForKey:@"Comp_Address3"],[[compArray objectAtIndex:0]objectForKey:@"Comp_Telephone"],[[invArray objectAtIndex:0]objectForKey:@"SOH_DocNo"]];
    }
    
    
    //----------
    tableName = [[invArray objectAtIndex:0] objectForKey:@"IvH_Table"];
    count = 18 - [dateString length];
    
    NSString *hcol = dateString;
    hcol = [NSString stringWithFormat:@"%@%@",hcol,
            [@" " stringByPaddingToLength:count withString:@" " startingAtIndex:0]];
    
    count = 24 - [timeString length];
    hcol = [NSString stringWithFormat:@"Date:%@ %@",hcol,[NSString stringWithFormat:@"%@%@\r\n\r\n",
                                                          [@" " stringByPaddingToLength:count withString:@" " startingAtIndex:0],
                                                          timeString]];
    //---------------------------
    
    
    
    //NSString *detail = @"%@ %@ %@ %@\r\n";
    
    NSString *data1 = @"";
    NSString *data2 = @"";
    NSString *data3 = @"";
    NSString *data4 = @"";
    NSString *data5 = @"";
    double subTotalB4Gst = 0.00;
    NSMutableString *combineData = [[NSMutableString alloc]init];
    
    
    for (int i = 0; i<invArray.count; i++) {
        data5 = [[invArray objectAtIndex:i] objectForKey:@"IM_Description2"];
        data1 = [[invArray objectAtIndex:i] objectForKey:@"ItemDesc"];
        if ([[[invArray objectAtIndex:i] objectForKey:@"ItemDesc"] length] > 18) data1 = [[[invArray objectAtIndex:i] objectForKey:@"ItemDesc"] substringToIndex:18];
        
        data2 = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:i] objectForKey:@"IvD_Quantity"] doubleValue]];
        if ([[[[invArray objectAtIndex:i] objectForKey:@"IvD_Quantity"] stringValue] length] > 9) data2 = [[[[invArray objectAtIndex:i] objectForKey:@"SOD_Quantity"] stringValue] substringToIndex:7];
        
        data3 = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:i] objectForKey:@"IvD_Price"] doubleValue]];
        if ([[[[invArray objectAtIndex:i] objectForKey:@"IvD_Price"] stringValue] length] > 9) data2 = [[[[invArray objectAtIndex:i] objectForKey:@"SOD_Price"] stringValue] substringToIndex:7];
        
        data4 = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:i] objectForKey:@"IvD_SubTotal"] doubleValue]];
        if ([[[[invArray objectAtIndex:i] objectForKey:@"IvD_SubTotal"] stringValue]length] > 9) data4 = [[[[invArray objectAtIndex:i] objectForKey:@"SOD_SubTotal"] stringValue] substringToIndex:7];
        
        subTotalB4Gst = subTotalB4Gst + [[[invArray objectAtIndex:i] objectForKey:@"IvD_TotalEx"] doubleValue];
        
        [combineData appendString:[NSString stringWithFormat:@"%@ %@ %@ %@",
                                   [NSString stringWithFormat:@"%@%@",data1,[@" " stringByPaddingToLength:18-[data1 length] withString:@" " startingAtIndex:0]],
                                   [NSString stringWithFormat:@"%@%@",
                                    [@" " stringByPaddingToLength:9 - [data2 length] withString:@" " startingAtIndex:0],
                                    data2],
                                   [NSString stringWithFormat:@"%@%@",
                                    [@" " stringByPaddingToLength:9 - [data3 length] withString:@" " startingAtIndex:0],
                                    data3],
                                   [NSString stringWithFormat:@"%@%@",
                                    [@" " stringByPaddingToLength:9 - [data4 length] withString:@" " startingAtIndex:0],
                                    data4]
                                   ]];
        
        if ([data5 length] > 0) {
            [combineData appendString:data5];
        }
        
        
    }
    
    //-------------------------------------------
    NSMutableData *commands = [NSMutableData data];
    
    [commands appendBytes:"\x1b\x1d\x61\x01"
                   length:sizeof("\x1b\x1d\x61\x01") - 1];    // center
    
    
    [commands appendData:[hdr dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    [commands appendBytes:"\x1b\x1d\x61\x00"
                   length:sizeof("\x1b\x1d\x61\x00") - 1];    // Alignment(left)
    
    [commands appendBytes:"\x1b\x44\x02\x10\x22\x00"
                   length:sizeof("\x1b\x44\x02\x10\x22\x00") - 1];    // SetHT
    
    [commands appendData:[hcol dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    [commands appendBytes:"\x1b\x45"
                   length:sizeof("\x1b\x45") - 1];    // SetBold
    
    [commands appendData:[[NSString stringWithFormat:@"%@%@\r\n",@"SALE Table:",tableName] dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    //[commands appendData:[@"SALE \r\n" dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    [commands appendBytes:"\x1b\x46"
                   length:sizeof("\x1b\x46") - 1];    // CancelBold
    
    [commands appendData:[@"Item                     Qty     Price     Total\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
    
    [commands appendData:[combineData dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    
    [commands appendData:[@"------------------------------------------------\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
    
    [commands appendBytes:"\x1b\x45"
                   length:sizeof("\x1b\x45") - 1];    // SetBold
    
    NSString *footAmt;
    NSString *docAmt;
    
    docAmt = [NSString stringWithFormat:@"%0.2f",subTotalB4Gst];
    footAmt = [NSString stringWithFormat:@"%@ %@\r\n",
               [NSString stringWithFormat:@"%@%@",@"Subtotal Exlude GST",[@" " stringByPaddingToLength:40-19 withString:@" " startingAtIndex:0]],
               [NSString stringWithFormat:@"%@%@",
                [@" " stringByPaddingToLength:7 - [docAmt length] withString:@" " startingAtIndex:0],
                docAmt]
               ];
    
    [commands appendData:[footAmt dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    docAmt = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:0] objectForKey:@"SOH_DocSubTotal"] doubleValue]];
    footAmt = [NSString stringWithFormat:@"%@ %@\r\n",
               [NSString stringWithFormat:@"%@%@",@"Subtotal",[@" " stringByPaddingToLength:40-8 withString:@" " startingAtIndex:0]],
               [NSString stringWithFormat:@"%@%@",
                [@" " stringByPaddingToLength:7 - [docAmt length] withString:@" " startingAtIndex:0],
                docAmt]
               ];
    
    
    [commands appendData:[footAmt dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    docAmt = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:0] objectForKey:@"SOH_DiscAmt"] doubleValue]];
    footAmt = [NSString stringWithFormat:@"%@ %@\r\n",
               [NSString stringWithFormat:@"%@%@",@"Discount",[@" " stringByPaddingToLength:40-8 withString:@" " startingAtIndex:0]],
               [NSString stringWithFormat:@"%@%@",
                [@" " stringByPaddingToLength:7 - [docAmt length] withString:@" " startingAtIndex:0],
                docAmt]
               ];
    
    [commands appendData:[footAmt dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    docAmt = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:0] objectForKey:@"SOH_DocServiceTaxAmt"] doubleValue]];
    footAmt = [NSString stringWithFormat:@"%@ %@\r\n",
               [NSString stringWithFormat:@"%@%@",@"Service Charge",[@" " stringByPaddingToLength:40-14 withString:@" " startingAtIndex:0]],
               [NSString stringWithFormat:@"%@%@",
                [@" " stringByPaddingToLength:7 - [docAmt length] withString:@" " startingAtIndex:0],
                docAmt]
               ];
    
    [commands appendData:[footAmt dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    if (enableGstYN == 1) {
        docAmt = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:0] objectForKey:@"SOH_DocTaxAmt"] doubleValue]];
        footAmt = [NSString stringWithFormat:@"%@ %@\r\n",
                   [NSString stringWithFormat:@"%@%@",@"Total GST",[@" " stringByPaddingToLength:40-9 withString:@" " startingAtIndex:0]],
                   [NSString stringWithFormat:@"%@%@",
                    [@" " stringByPaddingToLength:7 - [docAmt length] withString:@" " startingAtIndex:0],
                    docAmt]
                   ];
        
        [commands appendData:[footAmt dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    }
    
    docAmt = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:0] objectForKey:@"SOH_Rounding"] doubleValue]];
    footAmt = [NSString stringWithFormat:@"%@ %@\r\n",
               [NSString stringWithFormat:@"%@%@",@"Rounding",[@" " stringByPaddingToLength:40-8 withString:@" " startingAtIndex:0]],
               [NSString stringWithFormat:@"%@%@",
                [@" " stringByPaddingToLength:7 - [docAmt length] withString:@" " startingAtIndex:0],
                docAmt]
               ];
    
    [commands appendData:[footAmt dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    [commands appendBytes:"\x1b\x46"
                   length:sizeof("\x1b\x46") - 1];    // CancelBold
    
    [commands appendData:[@"Total" dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    [commands appendBytes:"\x09\x09\x1b\x69\x01\x01"
                   length:sizeof("\x09\x09\x1b\x69\x01\x01") - 1];    // SetDoubleHW
    
    
    docAmt = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:0] objectForKey:@"SOH_DocAmt"] doubleValue]];
    footAmt = [NSString stringWithFormat:@"%@\r\n",
               [NSString stringWithFormat:@"%@%@",
                [@" " stringByPaddingToLength:7 - [docAmt length] withString:@" " startingAtIndex:0],
                docAmt]
               ];
    
    [commands appendData:[footAmt dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    [commands appendBytes:"\x1b\x69\x00\x00"
                   length:sizeof("\x1b\x69\x00\x00") - 1];    // CancelDoubleHW
    
    [commands appendData:[@"------------------------------------------------\r\n\r\n" dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    [commands appendBytes:"\x1b\x1d\x61\x01"
                   length:sizeof("\x1b\x1d\x61\x01") - 1];    // Alignment(center)
    
    [commands appendData:[@"\x1b\x34Goods Sold Are Not Refundable\x1b\x35\r\n" dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    [commands appendBytes:"\x1b\x1d\x61\x01"
                   length:sizeof("\x1b\x1d\x61\x01") - 1];    // Alignment(center)
    
    [commands appendData:[@"\x1b\x34Thanks You\x1b\x35\r\n" dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    [commands appendBytes:"\x1b\x64\x02"
                   length:sizeof("\x1b\x64\x02") - 1];    // CutPaper
    
    return commands;
}


+ (NSData *)printLineSingleKitchenReceiptFormat:(NSString *)itemName TableName:(NSString *)tbName Qty:(NSString *)qty
{
    
    //NSString *detail = @"%@ %@ %@ %@\r\n";
    
    NSString *data1 = @"";
    NSString *data2 = @"";
    NSString *data3 = @"";
    //NSString *data4 = @"";
    //NSString *data5 = @"";
    //NSMutableString *combineData = [[NSMutableString alloc]init];
    
    //-------------------------------------------
    NSMutableData *commands = [NSMutableData data];
    
    
    //[commands appendData:[hdr dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    [commands appendBytes:"\x1b\x1d\x61\x00"
                   length:sizeof("\x1b\x1d\x61\x00") - 1];    // Alignment(left)
    
    [commands appendBytes:"\x09\x09\x1b\x69\x01\x01"
                   length:sizeof("\x09\x09\x1b\x69\x01\x01") - 1];    // SetDoubleHW
    
    //[commands appendData:[hcol dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    data1 = [NSString stringWithFormat:@"Table No : %@\r\n",tbName];
    data2 = [NSString stringWithFormat:@"%@\r\n",itemName];
    data3 = [NSString stringWithFormat:@"Qty %@",qty];
    
    
    [commands appendData:[data1 dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    [commands appendData:[data2 dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    [commands appendData:[data3 dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    [commands appendBytes:"\x1b\x69\x00\x00"
                   length:sizeof("\x1b\x69\x00\x00") - 1];    // CancelDoubleHW
    
    
    [commands appendBytes:"\x1b\x64\x02"
                   length:sizeof("\x1b\x64\x02") - 1];    // CutPaper
    
    return commands;
}


+ (NSData *)printLineGroupKitchenReceiptFormat:(NSMutableArray *)orderArray TableName:(NSString *)tableName
{
    NSString *data1 = @"";
    NSString *data2 = @"";
    //NSString *data3 = @"";
    NSString *tbName = @"";
    NSMutableString *combineData = [[NSMutableString alloc]init];
    
    tbName = [NSString stringWithFormat:@"Table No : %@\r\n",tableName];
    
    for (int i = 0; i<orderArray.count; i++) {
        //data5 = [[orderArray objectAtIndex:i] objectForKey:@"IM_Description2"];
        data1 = [[orderArray objectAtIndex:i] objectForKey:@"IM_Description"];
        if ([[[orderArray objectAtIndex:i] objectForKey:@"ItemDesc"] length] > 18) data1 = [[[orderArray objectAtIndex:i] objectForKey:@"ItemDesc"] substringToIndex:18];
        
        data2 = [NSString stringWithFormat:@"%0.2f",[[[orderArray objectAtIndex:i] objectForKey:@"IM_Qty"] doubleValue]];
        if ([[[[orderArray objectAtIndex:i] objectForKey:@"IM_Qty"] stringValue] length] > 9) data2 = [[[[orderArray objectAtIndex:i] objectForKey:@"IM_Qty"] stringValue] substringToIndex:7];
        
        
        [combineData appendString:[NSString stringWithFormat:@"%@ %@",
                                   [NSString stringWithFormat:@"%@%@",data1,[@" " stringByPaddingToLength:18-[data1 length] withString:@" " startingAtIndex:0]],
                                   [NSString stringWithFormat:@"%@%@",
                                    [@" " stringByPaddingToLength:9 - [data2 length] withString:@" " startingAtIndex:0],
                                    data2]
                                   ]];
        
        
    }

    //-------------------------------------------
    NSMutableData *commands = [NSMutableData data];
    
    [commands appendBytes:"\x1b\x1d\x61\x00"
                   length:sizeof("\x1b\x1d\x61\x00") - 1];    // Alignment(left)
    
    [commands appendBytes:"\x09\x09\x1b\x69\x01\x01"
                   length:sizeof("\x09\x09\x1b\x69\x01\x01") - 1];    // SetDoubleHW
    
    [commands appendData:[tableName dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    [commands appendData:[combineData dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    [commands appendBytes:"\x1b\x69\x00\x00"
                   length:sizeof("\x1b\x69\x00\x00") - 1];    // CancelDoubleHW
    
    [commands appendBytes:"\x1b\x64\x02"
                   length:sizeof("\x1b\x64\x02") - 1];    // CutPaper
    
    return commands;
    
}


+ (NSData *)english3inchDailyCollection:(NSString *)dateFrom DateTo:(NSString *)dateTo
{
    NSString *dbPath = [[LibraryAPI sharedInstance]getDbPath];
    //FMDatabase *dbTable;
    
    NSMutableArray *cashArray = [[NSMutableArray alloc]init];
    NSMutableArray *masterArray = [[NSMutableArray alloc]init];
    
    NSMutableArray *visaArray = [[NSMutableArray alloc]init];
    NSMutableArray *debitArray = [[NSMutableArray alloc] init];
    NSMutableArray *amexArray = [[NSMutableArray alloc] init];
    NSMutableArray *unionArray = [[NSMutableArray alloc] init];
    NSMutableArray *dinerArray = [[NSMutableArray alloc] init];
    NSMutableArray *voucherArray = [[NSMutableArray alloc] init];
    
    NSMutableArray *compArray = [[NSMutableArray alloc]init];
    NSMutableArray *paymentTypeArray = [[NSMutableArray alloc]init];
    NSMutableArray *sumTotalArray = [[NSMutableArray alloc]init];
    
    [masterArray removeAllObjects];
    [cashArray removeAllObjects];
    [visaArray removeAllObjects];
    [debitArray removeAllObjects];
    [amexArray removeAllObjects];
    [unionArray removeAllObjects];
    [dinerArray removeAllObjects];
    [voucherArray removeAllObjects];
    __block NSString *voidAmt;
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rsCompany = [db executeQuery:@"Select * from Company"];
        while ([rsCompany next]) {
            [compArray addObject:[rsCompany resultDictionary]];
        }
        [rsCompany close];
        
        FMResultSet *rsPaymentType = [db executeQuery:@"Select * from PaymentType"];
        
        while ([rsPaymentType next]) {
            [paymentTypeArray addObject:[rsPaymentType resultDictionary]];
        }
        
        [rsPaymentType close];
        
        
        for (int j = 0; j < paymentTypeArray.count; j++) {
            FMResultSet *rs = [db executeQuery:@"select sum(qty) qty, Type, sum(amt) amt from ( "
                               "select count(*) qty, IvH_PaymentType1 as Type, sum(IvH_PaymentAmt1) Amt from InvoiceHdr where date(IvH_Date) between date(?) and date(?) and IvH_PaymentType1 = ? group by Ivh_PaymentType1 "
                               " union "
                               "select count(*) qty, IvH_PaymentType2 as Type, sum(IvH_PaymentAmt2) Amt from InvoiceHdr where date(IvH_Date) between date(?) and date(?) and IvH_PaymentType2 = ? group by Ivh_PaymentType2 "
                               " union "
                               "select count(*) qty, IvH_PaymentType3 as Type, sum(IvH_PaymentAmt3) Amt from InvoiceHdr where date(IvH_Date) between date(?) and date(?) and IvH_PaymentType3 = ? group by Ivh_PaymentType3 "
                               " union "
                               "select count(*) qty, IvH_PaymentType4 as Type, sum(IvH_PaymentAmt4) Amt from InvoiceHdr where date(IvH_Date) between date(?) and date(?) and IvH_PaymentType4 = ? group by Ivh_PaymentType4 "
                               " union "
                               "select count(*) qty, IvH_PaymentType5 as Type, sum(IvH_PaymentAmt5) Amt from InvoiceHdr where date(IvH_Date) between date(?) and date(?) and IvH_PaymentType5 = ? group by Ivh_PaymentType5 "
                               " union "
                               "select count(*) qty, IvH_PaymentType6 as Type, sum(IvH_PaymentAmt6) Amt from InvoiceHdr where date(IvH_Date) between date(?) and date(?) and IvH_PaymentType6 = ? group by Ivh_PaymentType6 "
                               " union "
                               "select count(*) qty, IvH_PaymentType7 as Type, sum(IvH_PaymentAmt7) Amt from InvoiceHdr where date(IvH_Date) between date(?) and date(?) and IvH_PaymentType7 = ? group by Ivh_PaymentType7 "
                               ") where Type != ''  group by Type",dateFrom,dateTo,[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"],dateFrom,dateTo,[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"],dateFrom,dateTo,[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"],dateFrom,dateTo,[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"],dateFrom,dateTo,[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"],dateFrom,dateTo,[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"],dateFrom,dateTo,[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"]];
            
            while ([rs next]) {
                if ([[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"] isEqualToString:@"Cash"]) {
                    [cashArray addObject:[rs resultDictionary]];
                }
                else if ([[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"] isEqualToString:@"Master"])
                {
                    [masterArray addObject:[rs resultDictionary]];
                }
                else if ([[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"] isEqualToString:@"Visa"])
                {
                    [visaArray addObject:[rs resultDictionary]];
                }
                else if ([[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"] isEqualToString:@"Debit"])
                {
                    [debitArray addObject:[rs resultDictionary]];
                }
                else if ([[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"] isEqualToString:@"Amex"])
                {
                    [amexArray addObject:[rs resultDictionary]];
                }
                else if ([[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"] isEqualToString:@"UnionPay"])
                {
                    [unionArray addObject:[rs resultDictionary]];
                }
                else if ([[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"] isEqualToString:@"Diners"])
                {
                    [dinerArray addObject:[rs resultDictionary]];
                }
                else if ([[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"] isEqualToString:@"Voucher"])
                {
                    [voucherArray addObject:[rs resultDictionary]];
                }
                
            }
            
            [rs close];
        }

        
        
        /*
        FMResultSet *rs = [db executeQuery:@"select sum(qty) qty, Type, sum(amt) amt from ( "
                           "select count(*) qty, IvH_PaymentType1 as Type, sum(IvH_PaymentAmt1) Amt from InvoiceHdr where date(IvH_Date) between date(?) and date(?) and IvH_PaymentType1 = ? group by Ivh_PaymentType1 "
                           " union "
                           "select count(*) qty, IvH_PaymentType2 as Type, sum(IvH_PaymentAmt2) Amt from InvoiceHdr where date(IvH_Date) between date(?) and date(?) and IvH_PaymentType1 = ? group by Ivh_PaymentType2 "
                           ") where Type != '' group by Type",dateFrom,dateTo,@"Cash",dateFrom,dateTo,@"Cash"];
        
        while ([rs next]) {
            [cashArray addObject:[rs resultDictionary]];
        }
        
        [rs close];
        
        FMResultSet *rsCard = [db executeQuery:@"select sum(qty) qty, Type, sum(amt) amt from ( "
                               "select count(*) qty, IvH_PaymentType1 as Type, sum(IvH_PaymentAmt1) Amt from InvoiceHdr where date(IvH_Date) between date(?) and date(?) and IvH_PaymentType1 = ? group by Ivh_PaymentType1 "
                               " union "
                               "select count(*) qty, IvH_PaymentType2 as Type, sum(IvH_PaymentAmt2) Amt from InvoiceHdr where date(IvH_Date) between date(?) and date(?) and IvH_PaymentType1 = ? group by Ivh_PaymentType2 "
                               ") where Type != '' group by Type",dateFrom,dateTo,@"Card",dateFrom,dateTo,@"Card"];
        
        while ([rsCard next]) {
            [masterArray addObject:[rsCard resultDictionary]];
        }
        
        [rsCard close];
        */
        FMResultSet *rsTotal = [db executeQuery:@"select sum(IvH_DocAmt) DocAmt, sum(IvH_DiscAmt) DocDisAmt, sum(IvH_DoctaxAmt) DocTaxAmt from InvoiceHdr where date(IvH_Date) between date(?) and date(?) and IvH_Status = ? group by IvH_Status ",dateFrom,dateTo,@"Pay"];
        
        if ([rsTotal next]) {
            [sumTotalArray addObject:[rsTotal resultDictionary]];
            //totalAmt = [NSString stringWithFormat:@"%0.2f",[rsTotal doubleForColumn:@"DocAmt"]];
        }
        
        [rsTotal close];

        //[dbTable close];
        FMResultSet *rsVoidTotal = [db executeQuery:@"select sum(SOH_DocAmt) DocAmt, sum(SOH_DiscAmt) DocDisAmt, sum(SOH_DoctaxAmt) DocTaxAmt from SalesOrderHdr where date(SOH_Date) between date(?) and date(?) and SOH_Status = ? group by SOH_Status ",dateFrom,dateTo,@"Void"];
        
        if ([rsVoidTotal next]) {
            //[sumTotalArray addObject:[rsVoidTotal resultDictionary]];
            voidAmt = [NSString stringWithFormat:@"%0.2f",[rsVoidTotal doubleForColumn:@"DocAmt"]];
        }
        else
        {
            voidAmt = @"0.00";
        }
        
        [rsVoidTotal close];
        
    }];
    [queue close];
    int count;
    
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    NSString *dateString = [dateFormat stringFromDate:today];
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
    NSString *timeString = [timeFormat stringFromDate:today];
    
    NSString *salesDate = [NSString stringWithFormat:@"Sales Date : %@ to %@\r\n",dateFrom, dateTo];
    //spaceCount = (int)(38 - add2.length)/2;
    
    //salesDate = [NSString stringWithFormat:@"Sales Date : %@",
      //           salesDate];
    
    //NSString *date = [NSString stringWithFormat:@"Date : %@",dateString];
    //NSString *time = timeString;
    
    NSString *hdr = [NSString stringWithFormat:@"%@\r\n%@\r\n%@\r\n%@\r\nTel :%@\r\n%@\r\n",[[compArray objectAtIndex:0]objectForKey:@"Comp_Company"],[[compArray objectAtIndex:0]objectForKey:@"Comp_Address1"],[[compArray objectAtIndex:0]objectForKey:@"Comp_Address2"],[[compArray objectAtIndex:0]objectForKey:@"Comp_Address3"],[[compArray objectAtIndex:0]objectForKey:@"Comp_Telephone"],salesDate];
    
    //----------
    count = 18 - [dateString length];
    
    NSString *hcol = dateString;
    hcol = [NSString stringWithFormat:@"%@%@",hcol,
            [@" " stringByPaddingToLength:count withString:@" " startingAtIndex:0]];
    
    count = 24 - [timeString length];
    hcol = [NSString stringWithFormat:@"Date:%@ %@",hcol,[NSString stringWithFormat:@"%@%@\r\n\r\n",
                                                          [@" " stringByPaddingToLength:count withString:@" " startingAtIndex:0],
                                                          timeString]];
    //---------------------------
    
    
    
    //NSString *detail = @"%@ %@ %@ %@\r\n";
    
    
    NSString *masterTrans = @"Master TRANSACTION            \r\n";
    NSString *cashTrans = @"CASH TRANSACTION                \r\n";
    NSString *visaTrans = @"Visa TRANSACTION                \r\n";
    NSString *debitTrans = @"Debit TRANSACTION              \r\n";
    
    NSString *amexTrans = @"Amex TRANSACTION                \r\n";
    NSString *unionTrans = @"UnionPay TRANSACTION           \r\n";
    NSString *dinerTrans = @"Diners TRANSACTION             \r\n";
    NSString *voucherTrans = @"Voucher TRANSACTION          \r\n";
    
   // NSMutableString *combineData = [[NSMutableString alloc]init];
    

    //-------------------------------------------
    NSMutableData *commands = [NSMutableData data];
    
    [commands appendBytes:"\x1b\x1d\x61\x01"
                   length:sizeof("\x1b\x1d\x61\x01") - 1];    // center
    
    
    [commands appendData:[hdr dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    [commands appendBytes:"\x1b\x1d\x61\x00"
                   length:sizeof("\x1b\x1d\x61\x00") - 1];    // Alignment(left)
    
    [commands appendBytes:"\x1b\x44\x02\x10\x22\x00"
                   length:sizeof("\x1b\x44\x02\x10\x22\x00") - 1];    // SetHT
    
    [commands appendData:[hcol dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    [commands appendBytes:"\x1b\x45"
                   length:sizeof("\x1b\x45") - 1];    // SetBold
    
    [commands appendBytes:"\x1b\x1d\x61\x01"
                   length:sizeof("\x1b\x1d\x61\x01") - 1];    // center
    
    [commands appendData:[@"Daily Collection \r\n" dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    [commands appendBytes:"\x1b\x46"
                   length:sizeof("\x1b\x46") - 1];    // CancelBold
    
    //[commands appendData:[@"Item                     Qty     Price     Total\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
    
    //[commands appendData:[combineData dataUsingEncoding:NSASCIIStringEncoding]];
    
    
    [commands appendData:[@"------------------------------------------------\r\n" dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    [commands appendBytes:"\x1b\x45"
                   length:sizeof("\x1b\x45") - 1];    // SetBold
    
    
    [commands appendBytes:"\x1b\x1d\x61\x00"
                   length:sizeof("\x1b\x1d\x61\x00") - 1];    // Alignment(left)
    
    
    NSString *footAmt;
    NSString *docAmt;
    
    NSString *middle;
    NSString *middleTitle;
    
    int qtyLength;
    //-------- cash
    
    [commands appendData:[cashTrans dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    if (cashArray.count > 0) {
        middle = [NSString stringWithFormat:@"%0.2f",[[[cashArray objectAtIndex:0] objectForKey:@"amt"] doubleValue]];
        qtyLength = [[[cashArray objectAtIndex:0] objectForKey:@"qty"] stringValue].length;
        middleTitle = [NSString stringWithFormat:@"%@ %@\r\n",
                       [NSString stringWithFormat:@"SALES (%@)%@",[[[cashArray objectAtIndex:0] objectForKey:@"qty"] stringValue],[@" " stringByPaddingToLength:40-9-qtyLength withString:@" " startingAtIndex:0]],
                       [NSString stringWithFormat:@"%@%@",
                        [@" " stringByPaddingToLength:7 - [middle length] withString:@" " startingAtIndex:0],
                        middle]
                       ];
    }
    else
    {
        middle = [NSString stringWithFormat:@"%@",@"0.00"];
        qtyLength = 0;
        middleTitle = [NSString stringWithFormat:@"%@ %@\r\n",
                       [NSString stringWithFormat:@"SALES (%@)%@",@"0",[@" " stringByPaddingToLength:40-9-qtyLength withString:@" " startingAtIndex:0]],
                       [NSString stringWithFormat:@"%@%@",
                        [@" " stringByPaddingToLength:7 - [middle length] withString:@" " startingAtIndex:0],
                        middle]
                       ];
    }
    
    [commands appendData:[middleTitle dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    // master card
    [commands appendData:[masterTrans dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    if (masterArray.count > 0) {
        middle = [NSString stringWithFormat:@"%0.2f",[[[masterArray objectAtIndex:0] objectForKey:@"amt"] doubleValue]];
        qtyLength = [[[masterArray objectAtIndex:0] objectForKey:@"qty"] stringValue].length;
        middleTitle = [NSString stringWithFormat:@"%@ %@\r\n",
                       [NSString stringWithFormat:@"SALES (%@)%@",[[[masterArray objectAtIndex:0] objectForKey:@"qty"] stringValue],[@" " stringByPaddingToLength:40-9-qtyLength withString:@" " startingAtIndex:0]],
                       [NSString stringWithFormat:@"%@%@",
                        [@" " stringByPaddingToLength:7 - [middle length] withString:@" " startingAtIndex:0],
                        middle]
                       ];
    }
    else
    {
        middle = [NSString stringWithFormat:@"%@",@"0.00"];
        qtyLength = 0;
        middleTitle = [NSString stringWithFormat:@"%@ %@\r\n",
                       [NSString stringWithFormat:@"SALES (%@)%@",@"0",[@" " stringByPaddingToLength:40-9-qtyLength withString:@" " startingAtIndex:0]],
                       [NSString stringWithFormat:@"%@%@",
                        [@" " stringByPaddingToLength:7 - [middle length] withString:@" " startingAtIndex:0],
                        middle]
                       ];
    }
    
    [commands appendData:[middleTitle dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    //-------
    
    // ------------ visa ------------
    [commands appendData:[visaTrans dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    if (visaArray.count > 0) {
        middle = [NSString stringWithFormat:@"%0.2f",[[[visaArray objectAtIndex:0] objectForKey:@"amt"] doubleValue]];
        qtyLength = [[[visaArray objectAtIndex:0] objectForKey:@"qty"] stringValue].length;
        middleTitle = [NSString stringWithFormat:@"%@ %@\r\n",
                       [NSString stringWithFormat:@"SALES (%@)%@",[[[visaArray objectAtIndex:0] objectForKey:@"qty"] stringValue],[@" " stringByPaddingToLength:40-9-qtyLength withString:@" " startingAtIndex:0]],
                       [NSString stringWithFormat:@"%@%@",
                        [@" " stringByPaddingToLength:7 - [middle length] withString:@" " startingAtIndex:0],
                        middle]
                       ];
    }
    else
    {
        middle = [NSString stringWithFormat:@"%@",@"0.00"];
        qtyLength = 0;
        middleTitle = [NSString stringWithFormat:@"%@ %@\r\n",
                       [NSString stringWithFormat:@"SALES (%@)%@",@"0",[@" " stringByPaddingToLength:40-9-qtyLength withString:@" " startingAtIndex:0]],
                       [NSString stringWithFormat:@"%@%@",
                        [@" " stringByPaddingToLength:7 - [middle length] withString:@" " startingAtIndex:0],
                        middle]
                       ];
    }
    
    [commands appendData:[middleTitle dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    //----------------
    
    //-------- debit ---------------
    [commands appendData:[debitTrans dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    if (debitArray.count > 0) {
        middle = [NSString stringWithFormat:@"%0.2f",[[[debitArray objectAtIndex:0] objectForKey:@"amt"] doubleValue]];
        qtyLength = [[[debitArray objectAtIndex:0] objectForKey:@"qty"] stringValue].length;
        middleTitle = [NSString stringWithFormat:@"%@ %@\r\n",
                       [NSString stringWithFormat:@"SALES (%@)%@",[[[debitArray objectAtIndex:0] objectForKey:@"qty"] stringValue],[@" " stringByPaddingToLength:40-9-qtyLength withString:@" " startingAtIndex:0]],
                       [NSString stringWithFormat:@"%@%@",
                        [@" " stringByPaddingToLength:7 - [middle length] withString:@" " startingAtIndex:0],
                        middle]
                       ];
    }
    else
    {
        middle = [NSString stringWithFormat:@"%@",@"0.00"];
        qtyLength = 0;
        middleTitle = [NSString stringWithFormat:@"%@ %@\r\n",
                       [NSString stringWithFormat:@"SALES (%@)%@",@"0",[@" " stringByPaddingToLength:40-9-qtyLength withString:@" " startingAtIndex:0]],
                       [NSString stringWithFormat:@"%@%@",
                        [@" " stringByPaddingToLength:7 - [middle length] withString:@" " startingAtIndex:0],
                        middle]
                       ];
    }
    
    [commands appendData:[middleTitle dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    //-------------------------
    
    //---------- Amex ---------------
    [commands appendData:[amexTrans dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    if (amexArray.count > 0) {
        middle = [NSString stringWithFormat:@"%0.2f",[[[amexArray objectAtIndex:0] objectForKey:@"amt"] doubleValue]];
        qtyLength = [[[amexArray objectAtIndex:0] objectForKey:@"qty"] stringValue].length;
        middleTitle = [NSString stringWithFormat:@"%@ %@\r\n",
                       [NSString stringWithFormat:@"SALES (%@)%@",[[[amexArray objectAtIndex:0] objectForKey:@"qty"] stringValue],[@" " stringByPaddingToLength:40-9-qtyLength withString:@" " startingAtIndex:0]],
                       [NSString stringWithFormat:@"%@%@",
                        [@" " stringByPaddingToLength:7 - [middle length] withString:@" " startingAtIndex:0],
                        middle]
                       ];
    }
    else
    {
        middle = [NSString stringWithFormat:@"%@",@"0.00"];
        qtyLength = 0;
        middleTitle = [NSString stringWithFormat:@"%@ %@\r\n",
                       [NSString stringWithFormat:@"SALES (%@)%@",@"0",[@" " stringByPaddingToLength:40-9-qtyLength withString:@" " startingAtIndex:0]],
                       [NSString stringWithFormat:@"%@%@",
                        [@" " stringByPaddingToLength:7 - [middle length] withString:@" " startingAtIndex:0],
                        middle]
                       ];
    }
    
    [commands appendData:[middleTitle dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    //-------------------
    
    //---------- union ----------------
    [commands appendData:[unionTrans dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    if (unionArray.count > 0) {
        middle = [NSString stringWithFormat:@"%0.2f",[[[unionArray objectAtIndex:0] objectForKey:@"amt"] doubleValue]];
        qtyLength = [[[unionArray objectAtIndex:0] objectForKey:@"qty"] stringValue].length;
        middleTitle = [NSString stringWithFormat:@"%@ %@\r\n",
                       [NSString stringWithFormat:@"SALES (%@)%@",[[[unionArray objectAtIndex:0] objectForKey:@"qty"] stringValue],[@" " stringByPaddingToLength:40-9-qtyLength withString:@" " startingAtIndex:0]],
                       [NSString stringWithFormat:@"%@%@",
                        [@" " stringByPaddingToLength:7 - [middle length] withString:@" " startingAtIndex:0],
                        middle]
                       ];
    }
    else
    {
        middle = [NSString stringWithFormat:@"%@",@"0.00"];
        qtyLength = 0;
        middleTitle = [NSString stringWithFormat:@"%@ %@\r\n",
                       [NSString stringWithFormat:@"SALES (%@)%@",@"0",[@" " stringByPaddingToLength:40-9-qtyLength withString:@" " startingAtIndex:0]],
                       [NSString stringWithFormat:@"%@%@",
                        [@" " stringByPaddingToLength:7 - [middle length] withString:@" " startingAtIndex:0],
                        middle]
                       ];
    }
    
    [commands appendData:[middleTitle dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    //----------------
    
    //-------------- diners --------------
    [commands appendData:[dinerTrans dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    if (dinerArray.count > 0) {
        middle = [NSString stringWithFormat:@"%0.2f",[[[dinerArray objectAtIndex:0] objectForKey:@"amt"] doubleValue]];
        qtyLength = [[[dinerArray objectAtIndex:0] objectForKey:@"qty"] stringValue].length;
        middleTitle = [NSString stringWithFormat:@"%@ %@\r\n",
                       [NSString stringWithFormat:@"SALES (%@)%@",[[[dinerArray objectAtIndex:0] objectForKey:@"qty"] stringValue],[@" " stringByPaddingToLength:40-9-qtyLength withString:@" " startingAtIndex:0]],
                       [NSString stringWithFormat:@"%@%@",
                        [@" " stringByPaddingToLength:7 - [middle length] withString:@" " startingAtIndex:0],
                        middle]
                       ];
    }
    else
    {
        middle = [NSString stringWithFormat:@"%@",@"0.00"];
        qtyLength = 0;
        middleTitle = [NSString stringWithFormat:@"%@ %@\r\n",
                       [NSString stringWithFormat:@"SALES (%@)%@",@"0",[@" " stringByPaddingToLength:40-9-qtyLength withString:@" " startingAtIndex:0]],
                       [NSString stringWithFormat:@"%@%@",
                        [@" " stringByPaddingToLength:7 - [middle length] withString:@" " startingAtIndex:0],
                        middle]
                       ];
    }
    
    [commands appendData:[middleTitle dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    ///------------------------
    
    //---------- voucher ----------
    [commands appendData:[voucherTrans dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    if (voucherArray.count > 0) {
        middle = [NSString stringWithFormat:@"%0.2f",[[[voucherArray objectAtIndex:0] objectForKey:@"amt"] doubleValue]];
        qtyLength = [[[voucherArray objectAtIndex:0] objectForKey:@"qty"] stringValue].length;
        middleTitle = [NSString stringWithFormat:@"%@ %@\r\n",
                       [NSString stringWithFormat:@"SALES (%@)%@",[[[voucherArray objectAtIndex:0] objectForKey:@"qty"] stringValue],[@" " stringByPaddingToLength:40-9-qtyLength withString:@" " startingAtIndex:0]],
                       [NSString stringWithFormat:@"%@%@",
                        [@" " stringByPaddingToLength:7 - [middle length] withString:@" " startingAtIndex:0],
                        middle]
                       ];
    }
    else
    {
        middle = [NSString stringWithFormat:@"%@",@"0.00"];
        qtyLength = 0;
        middleTitle = [NSString stringWithFormat:@"%@ %@\r\n",
                       [NSString stringWithFormat:@"SALES (%@)%@",@"0",[@" " stringByPaddingToLength:40-9-qtyLength withString:@" " startingAtIndex:0]],
                       [NSString stringWithFormat:@"%@%@",
                        [@" " stringByPaddingToLength:7 - [middle length] withString:@" " startingAtIndex:0],
                        middle]
                       ];
    }
    
    [commands appendData:[middleTitle dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    //--------------------------------
    
    [commands appendData:[@"------------------------------------------------\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
    
    docAmt = [NSString stringWithFormat:@"%0.2f",[[[sumTotalArray objectAtIndex:0] objectForKey:@"DocAmt"] doubleValue]];
    footAmt = [NSString stringWithFormat:@"%@ %@\r\n",
               [NSString stringWithFormat:@"%@%@",@"TOTAL AMOUNT",[@" " stringByPaddingToLength:40-12 withString:@" " startingAtIndex:0]],
               [NSString stringWithFormat:@"%@%@",
                [@" " stringByPaddingToLength:7 - [docAmt length] withString:@" " startingAtIndex:0],
                docAmt]
               ];
    
    [commands appendData:[footAmt dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    [commands appendData:[@"------------------------------------------------\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
    [commands appendData:[@"\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
    [commands appendData:[@"SUMMARY :                                       \r\n" dataUsingEncoding:NSASCIIStringEncoding]];
    [commands appendData:[@"------------------------------------------------\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
    
    
    docAmt = [NSString stringWithFormat:@"%0.2f",[[[sumTotalArray objectAtIndex:0] objectForKey:@"DocAmt"] doubleValue]];
    footAmt = [NSString stringWithFormat:@"%@ %@\r\n",
               [NSString stringWithFormat:@"%@%@",@"Total Sales",[@" " stringByPaddingToLength:40-11 withString:@" " startingAtIndex:0]],
               [NSString stringWithFormat:@"%@%@",
                [@" " stringByPaddingToLength:7 - [docAmt length] withString:@" " startingAtIndex:0],
                docAmt]
               ];
    
    [commands appendData:[footAmt dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    
    docAmt = [NSString stringWithFormat:@"%0.2f",[[[sumTotalArray objectAtIndex:0] objectForKey:@"DocDisAmt"] doubleValue]];
    footAmt = [NSString stringWithFormat:@"%@ %@\r\n",
               [NSString stringWithFormat:@"%@%@",@"Total Discount",[@" " stringByPaddingToLength:40-14 withString:@" " startingAtIndex:0]],
               [NSString stringWithFormat:@"%@%@",
                [@" " stringByPaddingToLength:7 - [docAmt length] withString:@" " startingAtIndex:0],
                docAmt]
               ];
    
    [commands appendData:[footAmt dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    docAmt = [NSString stringWithFormat:@"%0.2f",[[[sumTotalArray objectAtIndex:0] objectForKey:@"DocTaxAmt"] doubleValue]];
    footAmt = [NSString stringWithFormat:@"%@ %@\r\n",
               [NSString stringWithFormat:@"%@%@",@"Total GST",[@" " stringByPaddingToLength:40-9 withString:@" " startingAtIndex:0]],
               [NSString stringWithFormat:@"%@%@",
                [@" " stringByPaddingToLength:7 - [docAmt length] withString:@" " startingAtIndex:0],
                docAmt]
               ];
    
    [commands appendData:[footAmt dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    //-------------------------------
    docAmt = [NSString stringWithFormat:@"%0.2f",[voidAmt doubleValue]];
    footAmt = [NSString stringWithFormat:@"%@ %@\r\n",
               [NSString stringWithFormat:@"%@%@",@"Total Void",[@" " stringByPaddingToLength:40-9 withString:@" " startingAtIndex:0]],
               [NSString stringWithFormat:@"%@%@",
                [@" " stringByPaddingToLength:7 - [docAmt length] withString:@" " startingAtIndex:0],
                docAmt]
               ];
    
    [commands appendData:[footAmt dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    [commands appendBytes:"\x1b\x46"
                   length:sizeof("\x1b\x46") - 1];    // CancelBold
    
    [commands appendBytes:"\x1b\x64\x02"
                   length:sizeof("\x1b\x64\x02") - 1];    // CutPaper
    
    return commands;
}


/*!
 *  Japanese Sample Receipt (3inch)
 */
+ (NSData *)japanese3inchSampleReceipt
{
    NSMutableData *commands = [NSMutableData data];

    [commands appendBytes:"\x1b\x40"
            length:sizeof("\x1b\x40") - 1];    // 初期化

    [commands appendBytes:"\x1b\x24\x31"
            length:sizeof("\x1b\x24\x31") - 1];    // 漢字モード設定

    [commands appendBytes:"\x1b\x1d\x61\x31"
            length:sizeof("\x1b\x1d\x61\x31") - 1];    // 中央揃え設定

    [commands appendBytes:"\x1b\x69\x02\x00"
            length:sizeof("\x1b\x69\x02\x00") - 1];    // 文字縦拡大設定

    [commands appendBytes:"\x1b\x45"
            length:sizeof("\x1b\x45") - 1];    // 強調印字設定

    [commands appendData:[@"スター電機\n" dataUsingEncoding:NSShiftJISStringEncoding]];

    [commands appendBytes:"\x1b\x69\x01\x00"
            length:sizeof("\x1b\x69\x01\x00") - 1];    // 文字縦拡大設定

    [commands appendData:[@"修理報告書　兼領収書\n" dataUsingEncoding:NSShiftJISStringEncoding]];

    [commands appendBytes:"\x1b\x69\x00\x00"
            length:sizeof("\x1b\x69\x00\x00") - 1];    // 文字縦拡大解除

    [commands appendBytes:"\x1b\x46"
            length:sizeof("\x1b\x46") - 1];    // 強調印字解除

    [commands appendData:[@"------------------------------------------------\n" dataUsingEncoding:NSShiftJISStringEncoding]];

    [commands appendBytes:"\x1b\x1d\x61\x30"
            length:sizeof("\x1b\x1d\x61\x30") - 1];    // 左揃え設定

    [commands appendData:[@"発行日時：YYYY年MM月DD日HH時MM分" "\n" dataUsingEncoding:NSShiftJISStringEncoding]];

    [commands appendData:[@"TEL：054-347-XXXX\n\n" dataUsingEncoding:NSShiftJISStringEncoding]];

    [commands appendData:[@"           ｲｹﾆｼ  ｼｽﾞｺ   ｻﾏ\n" dataUsingEncoding:NSShiftJISStringEncoding]];

    [commands appendData:[@"　お名前：池西　静子　様\n"
                           "　御住所：静岡市清水区七ツ新屋\n"
                           "　　　　　５３６番地\n"
                           "　伝票番号：No.12345-67890\n\n"
                           "　この度は修理をご用命頂き有難うございます。\n"
                           " 今後も故障など発生した場合はお気軽にご連絡ください。\n\n"
                          dataUsingEncoding:NSShiftJISStringEncoding]];
    
    [commands appendBytes:"\x1b\x52\x08" length:sizeof("\x1b\x52\x08") - 1];  // 国際文字:日本

    [commands appendData:[@"品名／型名　          数量      金額　   備考\n"
                           "------------------------------------------------\n"
                           "制御基板　          　  1      10,000     配達\n"
                           "操作スイッチ            1       3,800     配達\n"
                           "パネル　　          　  1       2,000     配達\n"
                           "技術料　          　　  1      15,000\n"
                           "出張費用　　            1       5,000\n"
                           "------------------------------------------------\n"
                          dataUsingEncoding:NSShiftJISStringEncoding]];
    
    [commands appendData:[@"\n"
                           "                            小計       \\ 35,800\n"
                           "                            内税       \\  1,790\n"
                           "                            合計       \\ 37,590\n\n"
                           "　お問合わせ番号　　12345-67890\n\n\n\n"
                          dataUsingEncoding:NSShiftJISStringEncoding]];

    [commands appendBytes:"\x1b\x64\x33"
            length:sizeof("\x1b\x64\x33") - 1];    // カット

    return commands;
}

/**
 *  Simplified Chinese Sample Receipt (3inch)
 */
+ (NSData *)simplifiedChinese3inchSampleReceipt
{
    NSMutableData *commands = [NSMutableData data];
    
    [commands appendBytes:"\x1b\x40"
                   length:sizeof("\x1b\x40") - 1];            // Initialize
    
    [commands appendBytes:"\x1b\x44\x10\x00"
                   length:sizeof("\x1b\x44\x10\x00") - 1];    // Set HT
    
    [commands appendBytes:"\x1b\x1d\x61\x31"
                   length:sizeof("\x1b\x1d\x61\x31") - 1];    // Alignment (Center)
    
    [commands appendBytes:"\x1b\x69\x02\x00"
                   length:sizeof("\x1b\x69\x02\x00") - 1];    // Set Double HW
    
    [commands appendBytes:"\x1b\x45"
                   length:sizeof("\x1b\x45") - 1];            // Set Bold
    
    [commands appendData:[@"STAR便利店\n" dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    [commands appendBytes:"\x1b\x69\x01\x00"
                   length:sizeof("\x1b\x69\x01\x00") - 1];    // Set Double HW
    
    [commands appendData:[@"欢迎光临\n" dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];

    [commands appendBytes:"\x1b\x69\x00\x00"
                   length:sizeof("\x1b\x69\x00\x00") - 1];    // Cancel Double HW

    [commands appendBytes:"\x1b\x46"
                   length:sizeof("\x1b\x46") - 1];            // Cancel Bold
    
    [commands appendData:[@"Unit 1906-08, 19/F, Enterprise Square 2,\n"
                           "　3 Sheung Yuet Road, Kowloon Bay, KLN\n"
                           "\n"
                           "Tel : (852) 2795 2335\n"
                           "\n"
                          dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    [commands appendBytes:"\x1b\x1d\x61\x30"
                   length:sizeof("\x1b\x1d\x61\x30") - 1];    // Alignment (Left)
 
    [commands appendData:[@"货品名称   　          数量  　   价格\n"
                           "--------------------------------------------\n"
                           "\n"
                           "罐装可乐\n"
                           "* Coke  \x09         1        7.00\n"
                           "纸包柠檬茶\n"
                           "* Lemon Tea  \x09         2       10.00\n"
                           "热狗\n"
                           "* Hot Dog   \x09         1       10.00\n"
                           "薯片(50克装)\n"
                           "* Potato Chips(50g)\x09      1       11.00\n"
                           "--------------------------------------------\n"
                           "\n"
                           "\x09      总数 :\x09     38.00\n"
                           "\x09      现金 :\x09     38.00\n"
                           "\x09      找赎 :\x09      0.00\n"
                           "\n"
                           "卡号码 Card No.       : 88888888\n"
                           "卡余额 Remaining Val. : 88.00\n"
                           "机号   Device No.     : 1234F1\n"
                           "\n"
                           "\n"
                           "DD/MM/YYYY  HH:MM:SS  交易编号 : 88888\n"
                           "\n"
                          dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
 
    [commands appendBytes:"\x1b\x1d\x61\x31"
                   length:sizeof("\x1b\x1d\x61\x31") - 1];    // Alignment (Center)

    [commands appendData:[@"收银机 : 001  收银员 : 180\n" dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];

    [commands appendBytes:"\x1b\x1d\x61\x30"
                   length:sizeof("\x1b\x1d\x61\x30") - 1];    // Alignment (Left)
    
    [commands appendBytes:"\x1b\x64\x33"
                   length:sizeof("\x1b\x64\x33") - 1];        // Cut

    return commands;
}


/**
 *  Traditional Chinese Sample Receipt (3inch)
 */
+ (NSData *)traditionalChinese3inchSampleReceipt
{
    NSMutableData *commands = [NSMutableData data];
    
    [commands appendBytes:"\x1b\x40"
                   length:sizeof("\x1b\x40") - 1];            // Initialize
    
    [commands appendBytes:"\x1b\x44\x10\x00"
                   length:sizeof("\x1b\x44\x10\x00") - 1];    // Set HT
    
    [commands appendBytes:"\x1b\x1d\x61\x31"
                   length:sizeof("\x1b\x1d\x61\x31") - 1];    // Alignment (Center)
    
    [commands appendBytes:"\x1b\x69\x02\x00"
                   length:sizeof("\x1b\x69\x02\x00") - 1];    // Set Double HW
    
    [commands appendBytes:"\x1b\x45"
                   length:sizeof("\x1b\x45") - 1];            // Set Bold
    
    [commands appendData:[@"Star Micronics\n" dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingBig5)]];

    [commands appendBytes:"\x1b\x69\x00\x00"
                   length:sizeof("\x1b\x69\x00\x00") - 1];    // Cancel Double HW
    
    [commands appendBytes:"\x1b\x46"
                   length:sizeof("\x1b\x46") - 1];            // Cancel Bold

    [commands appendData:[@"--------------------------------------------\n" dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingBig5)]];

    [commands appendBytes:"\x1b\x69\x01\x01"
                   length:sizeof("\x1b\x69\x01\x01") - 1];    // Set Double HW
    
    [commands appendData:[@"電子發票證明聯\n"
                           "103年01-02月\n"
                           "EV-99999999\n"
                          dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingBig5)]];
    
    [commands appendBytes:"\x1b\x69\x00\x00"
                   length:sizeof("\x1b\x69\x00\x00") - 1];    // Cancel Double HW
    
    [commands appendBytes:"\x1b\x1d\x61\x30"
                   length:sizeof("\x1b\x1d\x61\x30") - 1];    // Alignment (Left)

    [commands appendData:[@"2014/01/15 13:00\n"
                           "隨機碼 : 9999    總計 : 999\n"
                           "賣方 : 99999999\n"
                          dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingBig5)]];

    // 1D barcode example
    [commands appendBytes:"\x1b\x1d\x61\x01"
                   length:sizeof("\x1b\x1d\x61\x01") - 1];
    [commands appendBytes:"\x1b\x62\x34\x31\x32\x50"
                   length:sizeof("\x1b\x62\x34\x31\x32\x50") - 1];
    
    [commands appendBytes:"999999999\x1e\r\n"
                   length:sizeof("999999999\x1e\r\n") - 1];
    
    
    [commands appendBytes:"\x1b\x1d\x61\x31"
                   length:sizeof("\x1b\x1d\x61\x31") - 1];    // Alignment (Center)
    // QR Code
    [commands appendBytes:"\x1b\x1d\x79\x53\x30\x02"
                   length:sizeof("\x1b\x1d\x79\x53\x30\x02") - 1];            // Model
    [commands appendBytes:"\x1b\x1d\x79\x53\x31\x02"
                   length:sizeof("\x1b\x1d\x79\x53\x31\x02") - 1];            // Error Correction Level
    [commands appendBytes:"\x1b\x1d\x79\x53\x32\x05"
                   length:sizeof("\x1b\x1d\x79\x53\x32\x05") - 1];            // Cell size
    [commands appendBytes:"\x1b\x1d\x79\x44\x31\x00\x23\x00"
                   length:sizeof("\x1b\x1d\x79\x44\x31\x00\x23\x00") - 1];    // Data

    [commands appendBytes:"http://www.star-m.jp/eng/index.html"
                   length:sizeof("http://www.star-m.jp/eng/index.html") - 1];
   
    [commands appendBytes:"\x1b\x1d\x79\x50\x0a"
                   length:sizeof("\x1b\x1d\x79\x50\x0a") - 1];                // Print QR Code
    
    [commands appendBytes:"\x1b\x1d\x61\x30"
                   length:sizeof("\x1b\x1d\x61\x30") - 1];    // Alignment (Left)
    
    [commands appendData:[@"商品退換請持本聯及銷貨明細表。\n"
                           "9999999-9999999 999999-999999 9999\n\n\n"
                          dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingBig5)]];

    [commands appendBytes:"\x1b\x1d\x61\x31"
                   length:sizeof("\x1b\x1d\x61\x31") - 1];    // Alignment (Center)
    
    [commands appendData:[@"銷貨明細表 　(銷售)\n" dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingBig5)]];

    [commands appendBytes:"\x1b\x1d\x61\x32"
                   length:sizeof("\x1b\x1d\x61\x32") - 1];    // Alignment (Right)
    
    [commands appendData:[@"2014-01-15 13:00:02\n" dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingBig5)]];
    
    [commands appendBytes:"\x1b\x1d\x61\x30"
                   length:sizeof("\x1b\x1d\x61\x30") - 1];    // Alignment (Left)

    [commands appendData:[@"\n"
                           "烏龍袋茶2g20入  \x09           55 x2 110TX\n"
                           "茉莉烏龍茶2g20入  \x09         55 x2 110TX\n"
                           "天仁觀音茶2g*20   \x09         55 x2 110TX\n"
                          dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingBig5)]];
    
    [commands appendBytes:"\x1b\x45"
                   length:sizeof("\x1b\x45") - 1];            // Set Bold
    
    [commands appendData:[@"      小　 計 :\x09             330\n"
                           "      總   計 :\x09             330\n"
                          dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingBig5)]];

    [commands appendBytes:"\x1b\x46"
                   length:sizeof("\x1b\x46") - 1];            // Cancel Bold
    
    [commands appendData:[@"--------------------------------------------\n"
                           "現 金\x09             400\n"
                           "      找　 零 :\x09              70\n"
                          dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingBig5)]];

    [commands appendBytes:"\x1b\x45"
                   length:sizeof("\x1b\x45") - 1];            // Set Bold
    
    [commands appendData:[@" 101 發票金額 :\x09             330\n" dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingBig5)]];
    
    [commands appendBytes:"\x1b\x46"
                   length:sizeof("\x1b\x46") - 1];            // Cancel Bold

    [commands appendData:[@"2014-01-15 13:00\n" dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingBig5)]];
    
    
    // 1D barcode example
    [commands appendBytes:"\x1b\x1d\x61\x01"
                   length:sizeof("\x1b\x1d\x61\x01") - 1];
    [commands appendBytes:"\x1b\x62\x34\x31\x32\x50"
                   length:sizeof("\x1b\x62\x34\x31\x32\x50") - 1];
    
    [commands appendBytes:"999999999\x1e\r\n"
                   length:sizeof("999999999\x1e\r\n") - 1];
    
    [commands appendBytes:"\x1b\x1d\x61\x30"
                   length:sizeof("\x1b\x1d\x61\x30") - 1];    // Alignment (Left)

    [commands appendData:[@"商品退換、贈品及停車兌換請持本聯。\n"
                           "9999999-9999999 999999-999999 9999\n"
                          dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingBig5)]];

    [commands appendBytes:"\x1b\x64\x33"
                   length:sizeof("\x1b\x64\x33") - 1];        // Cut

    return commands;
}

// single kitchen receipt
+(NSData *)printKitchenReceiptWithPaperWidth:(SMPaperWidth)paperWidth language:(SMLanguage)language Item:(NSString *)itemName TableName:(NSString *)tbName Qty:(NSString *)qty
{
    NSString *languageName = nil;
    switch (language) {
        case SMLanguageEnglish:
            languageName = @"english";
            break;
        case SMLanguageJapanese:
            languageName = @"japanese";
            break;
        case SMLanguageSimplifiedChinese:
            languageName = @"simplifiedChinese";
            break;
        case SMLanguageTraditionalChinese:
            languageName = @"traditionalChinese";
            break;
    }
    
    NSString *paperWidthName = nil;
    switch (paperWidth) {
        case SMPaperTestPrint:
            paperWidthName = @"3inch";
            break;
        case SMPaperWidth2inch:
            paperWidthName = @"2inch";
            break;
        case SMPaperWidth3inch:
            paperWidthName = @"3inch";
            break;
        case SMPaperWidth4inch:
            paperWidthName = @"4inch";
            break;
        case SMPaperWidth3inchSO:
            paperWidthName = @"3inchSO";
            break;
    }
    
    NSData *kitchenReceiptData;
    
    kitchenReceiptData = [self printLineSingleKitchenReceiptFormat:itemName TableName:tbName Qty:qty];
    NSMutableData *commands = [NSMutableData dataWithData:kitchenReceiptData];
    
    return commands;
    
    
}


// Group kitchen receipt
+(NSData *)printGroupKitchenReceiptWithPaperWidth:(SMPaperWidth)paperWidth language:(SMLanguage)language OrderArray:(NSMutableArray *)orderArray TableName:(NSString *)tbName
{
    NSString *languageName = nil;
    switch (language) {
        case SMLanguageEnglish:
            languageName = @"english";
            break;
        case SMLanguageJapanese:
            languageName = @"japanese";
            break;
        case SMLanguageSimplifiedChinese:
            languageName = @"simplifiedChinese";
            break;
        case SMLanguageTraditionalChinese:
            languageName = @"traditionalChinese";
            break;
    }
    
    NSString *paperWidthName = nil;
    switch (paperWidth) {
        case SMPaperTestPrint:
            paperWidthName = @"3inch";
            break;
        case SMPaperWidth2inch:
            paperWidthName = @"2inch";
            break;
        case SMPaperWidth3inch:
            paperWidthName = @"3inch";
            break;
        case SMPaperWidth4inch:
            paperWidthName = @"4inch";
            break;
        case SMPaperWidth3inchSO:
            paperWidthName = @"3inchSO";
            break;
    }
    
    NSData *kitchenGroupReceiptData;
    
    kitchenGroupReceiptData = [self printLineGroupKitchenReceiptFormat:orderArray TableName:tbName];
    
    NSMutableData *commands = [NSMutableData dataWithData:kitchenGroupReceiptData];
    
    return commands;
    
    
}




+ (NSData *)sampleReceiptWithPaperWidth:(SMPaperWidth)paperWidth language:(SMLanguage)language kickDrawer:(BOOL)kickDrawer invDocNo:(NSString *)invDocNo docType:(NSString *)docType EnableGST:(int)enableGST {
    NSString *languageName = nil;
    switch (language) {
        case SMLanguageEnglish:
            languageName = @"english";
            break;
        case SMLanguageJapanese:
            languageName = @"japanese";
            break;
        case SMLanguageSimplifiedChinese:
            languageName = @"simplifiedChinese";
            break;
        case SMLanguageTraditionalChinese:
            languageName = @"traditionalChinese";
            break;
    }
    
    NSString *paperWidthName = nil;
    switch (paperWidth) {
        case SMPaperTestPrint:
            paperWidthName = @"3inch";
            break;
        case SMPaperWidth2inch:
            paperWidthName = @"2inch";
            break;
        case SMPaperWidth3inch:
            paperWidthName = @"3inch";
            break;
        case SMPaperWidth4inch:
            paperWidthName = @"4inch";
            break;
        case SMPaperWidth3inchSO:
            paperWidthName = @"3inchSO";
            break;
    }
    
    NSData *receiptData;
    if ([docType isEqualToString:@"SO"]) {
        // print bill only
        receiptData = [self english3inchSOReceipt:invDocNo EnableGstYN:enableGST];
    }
    else
    {
        //print real receipt
        receiptData = [self english3inchSampleReceipt:invDocNo EnableGstYN:enableGST];
    }
    

    // Kick cash drawer
    NSMutableData *commands = [NSMutableData dataWithData:receiptData];
    if (kickDrawer) {
        [commands appendBytes:"\x07" length:sizeof("\x07") - 1];
    }

    return commands;
}

+(NSData *)PrinLineCollectionLineWithDocType:(NSString *)docType DateFrom:(NSString *)dateFrom DateTo:(NSString *)dateTo
{
    NSData *receiptData;
    if ([docType isEqualToString:@"Daily"]) {
        receiptData = [self english3inchDailyCollection:dateFrom DateTo:dateTo];
    }

    // Kick cash drawer
    NSMutableData *commands = [NSMutableData dataWithData:receiptData];
    //if (kickDrawer) {
     //   [commands appendBytes:"\x07" length:sizeof("\x07") - 1];
    //}
    
    return commands;
}

#pragma mark Sample Receipt (Raster)

+ (UIImage *)imageWithString:(NSString *)string font:(UIFont *)font width:(CGFloat)width
{
    CGSize size = CGSizeMake(width, 10000);
    float systemVersion = UIDevice.currentDevice.systemVersion.floatValue;
    
    CGSize messuredSize;
    if (systemVersion >= 7.0) {
        messuredSize = [string boundingRectWithSize:size
                                            options:NSStringDrawingUsesLineFragmentOrigin
                                         attributes:@{NSFontAttributeName: font}
                                            context:nil].size;
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        messuredSize = [string sizeWithFont:font constrainedToSize:size];
#pragma clang diagnostic pop
    }
	
	if ([UIScreen.mainScreen respondsToSelector:@selector(scale)]) {
		if (UIScreen.mainScreen.scale == 2.0) {
			UIGraphicsBeginImageContextWithOptions(messuredSize, NO, 1.0);
		} else {
			UIGraphicsBeginImageContext(messuredSize);
		}
	} else {
		UIGraphicsBeginImageContext(messuredSize);
	}
    
    CGContextRef ctr = UIGraphicsGetCurrentContext();
    UIColor *color = [UIColor whiteColor];
    [color set];
    
    CGRect rect = CGRectMake(0, 0, messuredSize.width + 1, messuredSize.height + 1);
    CGContextFillRect(ctr, rect);
    
    color = [UIColor blackColor];
    [color set];
    
    if (systemVersion >= 7.0) {
        [string drawInRect:rect withAttributes:@{NSFontAttributeName: font}];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [string drawInRect:rect withFont:font];
#pragma clang diagnostic pop
    }
    
    UIImage *imageToPrint = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return imageToPrint;
}

+ (void)PrintRasterSampleReceiptWithPortname:(NSString *)portName portSettings:(NSString *)portSettings paperWidth:(SMPaperWidth)paperWidth Language:(SMLanguage)language invDocno:(NSString *)invDocNo EnableGst:(int)enableGst KickOutDrawer:(BOOL)kickOutDrawer {
    switch (language) {
        case SMLanguageEnglish:
            switch (paperWidth) {
                
                case SMPaperWidth3inch:
                    [self PrintRasterSampleReceipt3InchWithPortname:portName portSettings:portSettings invDocNo:invDocNo EnableGstYN:enableGst KickDrawer:kickOutDrawer];
                    break;
                case SMPaperWidth3inchSO:
                    [self PrintRasterSOReceipt3InchWithPortname:portName portSettings:portSettings invDocNo:invDocNo];
                
                //case SMKitchenSingleReceipt:
            }
            break;
            }
}

/**
 *  Print raster sample receipt (3inch)
 *
 *  @param  portName        Port name to use for communication. This should be (TCP:<IP Address>), (BT:<iOS Port Name>),
 *                          or (BLE:<Device Name>).
 *  @param  portSettings    Set following settings
 *                          - Desktop USB Printer + Apple AirPort: @"9100" - @"9109" (Port Number)
 *                          - Portable Printer (Star Line Mode)  : @"portable"
 *                          - Others                             : @"" (blank)
 */


+ (void)PrintRasterSampleReceipt3InchWithPortname:(NSString *)portName portSettings:(NSString *)portSettings invDocNo:(NSString *)invDocNo EnableGstYN:(int)enableGstYN KickDrawer:(BOOL)kickDrawer
{
    
    
    NSString *dbPath = [[LibraryAPI sharedInstance]getDbPath];
    NSMutableArray *invArray = [[NSMutableArray alloc]init];
    NSMutableArray *compArray = [[NSMutableArray alloc]init];
    NSMutableString *mString = [[NSMutableString alloc]init];
    
    [invArray removeAllObjects];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rsCompany = [db executeQuery:@"Select * from Company"];
        while ([rsCompany next]) {
            [compArray addObject:[rsCompany resultDictionary]];
        }
        
        
        FMResultSet *rs = [db executeQuery:@"Select *,IFNULL(IvD_ItemTaxCode,'') || ': ' || IvD_ItemDescription as ItemDesc,IvD_ItemDescription as ItemDesc2,IFNULL(IvD_ItemTaxCode,'-') as Flag from InvoiceHdr InvH "
                           " left join InvoiceDtl InvD on InvH.IvH_DocNo = InvD.IvD_DocNo"
                           " left join ItemMast IM on IM.IM_ItemCode = InvD.IvD_ItemCode"
                           " where InvH.IvH_DocNo = ?",invDocNo];
        
        while ([rs next]) {
            [invArray addObject:[rs resultDictionary]];
        }
        
        [rs close];
        //[dbTable close];
        
    }];
    
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    NSString *dateString = [dateFormat stringFromDate:today];
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
    NSString *timeString = [timeFormat stringFromDate:today];
    NSString *tableName = [[invArray objectAtIndex:0] objectForKey:@"IvH_Table"];
    //NSMutableArray *compname = [NSMutableArray arrayWithObjects:
    //compArray, nil];
    
    int spaceCount = 0;
    
    NSString *shopName = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Company"]];
    spaceCount = (int)(38 - shopName.length)/2;
    
    shopName = [NSString stringWithFormat:@"%@%@",
                [@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
                shopName];
    
    NSString *add1 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address1"]];
    spaceCount = (int)(38 - add1.length)/2;
    
    add1 = [NSString stringWithFormat:@"%@%@",
            [@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
            add1];
    
    NSString *add2 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address2"]];
    spaceCount = (int)(38 - add2.length)/2;
    
    add2 = [NSString stringWithFormat:@"%@%@",
            [@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
            add2];
    
    NSString *add3 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address3"]];
    spaceCount = (int)(38 - add3.length)/2;
    
    add3 = [NSString stringWithFormat:@"%@%@",
            [@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
            add3];
    
    NSString *tel = [NSString stringWithFormat:@"Tel : %@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Telephone"]];
    spaceCount = (int)(38 - tel.length)/2;
    
    tel = [NSString stringWithFormat:@"%@%@",
            [@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
            tel];
    
    NSString *gstNo = [NSString stringWithFormat:@"GST ID : %@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_GstNo"]];
    spaceCount = (int)(38 - gstNo.length)/2;
    
    gstNo = [NSString stringWithFormat:@"%@%@",
           [@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
           gstNo];
    
    NSString *invNo = [NSString stringWithFormat:@"Receipt : %@\r\n",[[invArray objectAtIndex:0] objectForKey:@"IvH_DocNo"]];
    spaceCount = (int)(38 - invNo.length)/2;
    
    invNo = [NSString stringWithFormat:@"%@%@",
             [@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
             invNo];
    NSString *gstTitle = @"Tax Invocie\r\n";
    
    NSString *date = [NSString stringWithFormat:@"Date : %@",dateString];
    NSString *time = timeString;
    
    spaceCount = (int)(38 - date.length - time.length);
    NSString *dateTime;
    dateTime = [NSString stringWithFormat:@"%@%@%@\r\n\r\n",
             date,[@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
             time];
    NSString *header = [NSString stringWithFormat:@"SALE Table:%@\r\n",tableName];
    
    NSString *title =    @"Item              Qty   Price    Total\r\n";
    NSString *dashline = @"--------------------------------------\r\n";
    
    NSString *item = @"";
    NSString *qty = @"";
    NSString *price = @"";
    NSString *itemTotal = @"";
    NSString *itemDesc = @"";
    int spaceAdd = 0;
    
    NSString *detail2;
    NSString *detail3;
    NSString *detail4;
    NSString *detail5;
    double subTotalB4Gst = 0.00;
    NSMutableString *mString2 = [[NSMutableString alloc]init];
    
    for (int i = 0; i<invArray.count; i++) {
        if (enableGstYN == 1) {
            if ([[[invArray objectAtIndex:i]objectForKey:@"Flag"] isEqualToString:@"-"]) {
                item = [[invArray objectAtIndex:i] objectForKey:@"ItemDesc2"];
            }
            else
            {
                item = [[invArray objectAtIndex:i] objectForKey:@"ItemDesc"];
            }
            
        }
        else
        {
            item = [[invArray objectAtIndex:i] objectForKey:@"ItemDesc2"];
        }
        
        subTotalB4Gst = subTotalB4Gst + [[[invArray objectAtIndex:i]objectForKey:@"IvD_TotalEx"] doubleValue];
        itemDesc = [[invArray objectAtIndex:i] objectForKey:@"IM_Description2"];
        
        if ([item length] > 15) item = [item substringToIndex:15];
        qty = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:i] objectForKey:@"IvD_Quantity"] doubleValue]];
        if ([qty length] > 6) qty = [qty substringToIndex:6];
        price = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:i] objectForKey:@"IvD_Price"] doubleValue]];
        if ([price length] > 8) price = [price substringToIndex:8];
        itemTotal = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:i] objectForKey:@"IvD_SubTotal"] doubleValue]];
        if ([itemTotal length] > 9) itemTotal = [itemTotal substringToIndex:9];
        
        spaceAdd = 15 - item.length;
        NSString *detail1 = [NSString stringWithFormat:@"%@%@",
                             item,
                             [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0]];
        
        spaceAdd = 6 - qty.length;
        if (spaceAdd > 0) {
            detail2 = [NSString stringWithFormat:@"%@%@",
                     [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0],
                     qty];
        }
        
        spaceAdd = 8 - price.length;
        if (spaceAdd > 0) {
            detail3 = [NSString stringWithFormat:@"%@%@",
                      [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0],
                      price];
        }
        
        spaceAdd = 9 - itemTotal.length;
        if (spaceAdd > 0) {
            detail4 = [NSString stringWithFormat:@"%@%@",
                       [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0],
                       itemTotal];
        }
        
        spaceAdd = 38 - itemDesc.length;
        if (spaceAdd > 0) {
            detail5 = [NSString stringWithFormat:@"%@%@",
                       [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0],
                       itemDesc];
        }
        
        
        [mString2 appendString:[NSString stringWithFormat:@"%@%@%@%@\n",detail1,detail2,detail3,detail4]];
        if ([detail5 length] > 0) {
            [mString2 appendString:[NSString stringWithFormat:@"%@\n",detail5]];
        }
        
    }
    
    NSString *footer;
    NSString *footerTitle;
    
    footer = [NSString stringWithFormat:@"%0.2f",subTotalB4Gst];
    footerTitle = @"SubTotal Exlude GST";
    NSString *subTotalEx = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
                                          
                                          
    footer = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:0] objectForKey:@"IvH_DocSubTotal"] doubleValue]];
    footerTitle = @"SubTotal";
    NSString *subTotal = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:0] objectForKey:@"IvH_DiscAmt"] doubleValue]];
    footerTitle = @"Discount";
    NSString *discount = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:0] objectForKey:@"IvH_DocServiceTaxAmt"] doubleValue]];
    footerTitle = @"Service Charge";
    NSString *serviceCharge = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:0] objectForKey:@"IvH_DocTaxAmt"] doubleValue]];
    footerTitle = @"Total GST";
    NSString *gst = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:0] objectForKey:@"IvH_Rounding"] doubleValue]];
    footerTitle = @"Rounding";
    NSString *rounding = [NSString stringWithFormat:@"%@%@%@\r\n",
                     footerTitle,
                     [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:0] objectForKey:@"IvH_DocAmt"] doubleValue]];
    footerTitle = @"Total";
    NSString *granTotal = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:0] objectForKey:@"IvH_TotalPay"] doubleValue]];
    footerTitle = @"Pay";
    NSString *pay = [NSString stringWithFormat:@"%@%@%@\r\n",
                           footerTitle,
                           [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:0] objectForKey:@"IvH_ChangeAmt"] doubleValue]];
    footerTitle = @"Change";
    NSString *change = [NSString stringWithFormat:@"%@%@%@\r\n\r\n",
                     footerTitle,
                     [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = @"Goods Sold Are Not Refundable";
    spaceCount = (int)(38 - footer.length)/2;
    
    NSString *remind = [NSString stringWithFormat:@"%@%@",
           [@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
           footer];
    
    [mString appendString:shopName];
    [mString appendString:add1];
    [mString appendString:add2];
    [mString appendString:add3];
    [mString appendString:tel];
    if (enableGstYN == 1) {
        [mString appendString:gstNo];
        [mString appendString:gstTitle];
    }
    
    [mString appendString:invNo];
    [mString appendString:dateTime];
    [mString appendString:header];
    [mString appendString:title];
    [mString appendString:mString2];
    [mString appendString:dashline];
    [mString appendString:subTotalEx];
    [mString appendString:subTotal];
    [mString appendString:discount];
    [mString appendString:serviceCharge];
    if (enableGstYN == 1) {
        [mString appendString:gst];
    }
    [mString appendString:rounding];
    [mString appendString:granTotal];
    [mString appendString:pay];
    [mString appendString:change];
    [mString appendString:remind];
    
    const char *gb2312Text = [mString UTF8String];
    NSString *textToPrint = [NSString stringWithCString:gb2312Text encoding:NSUTF8StringEncoding];
    //NSString *textToPrint = mString;
    
    CGFloat width = 576;
    UIFont *font = [UIFont fontWithName:@"Courier" size:(12.0 * 2)];
    
    UIImage *imageToPrint = [self imageWithString:textToPrint font:font width:width];
    
    [PrinterFunctions PrintImageWithPortname:portName portSettings:portSettings imageToPrint:imageToPrint maxWidth:width compressionEnable:YES withDrawerKick:kickDrawer];
    
    footer = nil;
    
}

+ (void)PrintRasterSOReceipt3InchWithPortname:(NSString *)portName portSettings:(NSString *)portSettings invDocNo:(NSString *)invDocNo
{
    
    
    NSString *dbPath = [[LibraryAPI sharedInstance]getDbPath];
    NSMutableArray *invArray = [[NSMutableArray alloc]init];
    NSMutableArray *compArray = [[NSMutableArray alloc]init];
    NSMutableString *mString = [[NSMutableString alloc]init];
    
    [invArray removeAllObjects];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rsCompany = [db executeQuery:@"Select * from Company"];
        while ([rsCompany next]) {
            [compArray addObject:[rsCompany resultDictionary]];
        }
        
        
        FMResultSet *rs = [db executeQuery:@"Select *, SOD_ItemDescription as ItemDesc from SalesOrderHdr Hdr "
                           " left join SalesOrderDtl Dtl on Hdr.SOH_DocNo = Dtl.SOD_DocNo"
                           " left join ItemMast IM on IM.IM_ItemCode = Dtl.SOD_ItemCode"
                           " where Hdr.SOH_DocNo = ?",invDocNo];
        
        while ([rs next]) {
            [invArray addObject:[rs resultDictionary]];
        }
        
        [rs close];
        //[dbTable close];
        
    }];
    
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    NSString *dateString = [dateFormat stringFromDate:today];
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
    NSString *timeString = [timeFormat stringFromDate:today];
    NSString *tableName = [[invArray objectAtIndex:0] objectForKey:@"IvH_Table"];
    //NSMutableArray *compname = [NSMutableArray arrayWithObjects:
    //compArray, nil];
    
    int spaceCount = 0;
    
    NSString *shopName = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Company"]];
    spaceCount = (int)(38 - shopName.length)/2;
    
    shopName = [NSString stringWithFormat:@"%@%@",
                [@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
                shopName];
    
    NSString *add1 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address1"]];
    spaceCount = (int)(38 - add1.length)/2;
    
    add1 = [NSString stringWithFormat:@"%@%@",
            [@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
            add1];
    
    NSString *add2 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address2"]];
    spaceCount = (int)(38 - add2.length)/2;
    
    add2 = [NSString stringWithFormat:@"%@%@",
            [@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
            add2];
    
    NSString *add3 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address3"]];
    spaceCount = (int)(38 - add3.length)/2;
    
    add3 = [NSString stringWithFormat:@"%@%@",
            [@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
            add3];
    
    NSString *tel = [NSString stringWithFormat:@"Tel : %@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Telephone"]];
    spaceCount = (int)(38 - tel.length)/2;
    
    tel = [NSString stringWithFormat:@"%@%@",
           [@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
           tel];
    
    NSString *gstNo = [NSString stringWithFormat:@"GST ID : %@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_GstNo"]];
    spaceCount = (int)(38 - gstNo.length)/2;
    
    gstNo = [NSString stringWithFormat:@"%@%@",
             [@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
             gstNo];
    
    NSString *invNo = [NSString stringWithFormat:@"SO : %@\r\n",[[invArray objectAtIndex:0] objectForKey:@"SOH_DocNo"]];
    spaceCount = (int)(38 - invNo.length)/2;
    
    invNo = [NSString stringWithFormat:@"%@%@",
             [@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
             invNo];
    
    NSString *date = [NSString stringWithFormat:@"Date : %@",dateString];
    NSString *time = timeString;
    
    spaceCount = (int)(38 - date.length - time.length);
    NSString *dateTime;
    dateTime = [NSString stringWithFormat:@"%@%@%@\r\n\r\n",
                date,[@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
                time];
    
    NSString *header = [NSString stringWithFormat:@"SALE Table:%@\r\n",tableName];
    //NSString *header = @"SALE\r\n";
    
    NSString *title =    @"Item              Qty   Price    Total\r\n";
    NSString *dashline = @"--------------------------------------\r\n";
    
    NSString *item = @"";
    NSString *qty = @"";
    NSString *price = @"";
    NSString *itemTotal = @"";
    NSString *itemDesc = @"";
    int spaceAdd = 0;
    double subTotalB4Gst = 0.00;
    
    NSString *detail2;
    NSString *detail3;
    NSString *detail4;
    NSString *detail5;
    NSMutableString *mString2 = [[NSMutableString alloc]init];
    
    for (int i = 0; i<invArray.count; i++) {
        item = [[invArray objectAtIndex:i] objectForKey:@"ItemDesc"];
        itemDesc = [[invArray objectAtIndex:i] objectForKey:@"IM_Description2"];
        
        if ([item length] > 15) item = [item substringToIndex:15];
        qty = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:i] objectForKey:@"SOD_Quantity"] doubleValue]];
        if ([qty length] > 6) qty = [qty substringToIndex:6];
        price = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:i] objectForKey:@"SOD_Price"] doubleValue]];
        if ([price length] > 8) price = [price substringToIndex:8];
        itemTotal = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:i] objectForKey:@"SOD_SubTotal"] doubleValue]];
        if ([itemTotal length] > 9) itemTotal = [itemTotal substringToIndex:9];
        
        subTotalB4Gst = subTotalB4Gst + [[[invArray objectAtIndex:i]objectForKey:@"SOD_TotalEx"] doubleValue];
        
        spaceAdd = 15 - item.length;
        NSString *detail1 = [NSString stringWithFormat:@"%@%@",
                             item,
                             [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0]];
        
        spaceAdd = 6 - qty.length;
        if (spaceAdd > 0) {
            detail2 = [NSString stringWithFormat:@"%@%@",
                       [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0],
                       qty];
        }
        
        spaceAdd = 8 - price.length;
        if (spaceAdd > 0) {
            detail3 = [NSString stringWithFormat:@"%@%@",
                       [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0],
                       price];
        }
        
        spaceAdd = 9 - itemTotal.length;
        if (spaceAdd > 0) {
            detail4 = [NSString stringWithFormat:@"%@%@",
                       [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0],
                       itemTotal];
        }
        
        spaceAdd = 38 - itemTotal.length;
        if (spaceAdd > 0) {
            detail5 = [NSString stringWithFormat:@"%@%@",
                       [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0],
                       itemDesc];
        }
        
        [mString2 appendString:[NSString stringWithFormat:@"%@%@%@%@\n",detail1,detail2,detail3,detail4]];
        if ([detail5 length] > 0) {
            [mString2 appendString:[NSString stringWithFormat:@"%@\n",detail5]];
        }
        
    }
    
    NSString *footer;
    NSString *footerTitle;
    
    footer = [NSString stringWithFormat:@"%0.2f",subTotalB4Gst];
    footerTitle = @"SubTotal Exlude GST";
    NSString *subTotalEx = [NSString stringWithFormat:@"%@%@%@\r\n",
                            footerTitle,
                            [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:0] objectForKey:@"SOH_DocSubTotal"] doubleValue]];
    footerTitle = @"SubTotal";
    NSString *subTotal = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:0] objectForKey:@"SOH_DiscAmt"] doubleValue]];
    footerTitle = @"Discount";
    NSString *discount = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:0] objectForKey:@"SOH_DocServiceTaxAmt"] doubleValue]];
    footerTitle = @"Service Charge";
    NSString *svc = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:0] objectForKey:@"SOH_DocTaxAmt"] doubleValue]];
    footerTitle = @"Total GST";
    NSString *gst = [NSString stringWithFormat:@"%@%@%@\r\n",
                     footerTitle,
                     [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:0] objectForKey:@"SOH_Rounding"] doubleValue]];
    footerTitle = @"Rounding";
    NSString *rounding = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[invArray objectAtIndex:0] objectForKey:@"SOH_DocAmt"] doubleValue]];
    footerTitle = @"Total";
    NSString *granTotal = [NSString stringWithFormat:@"%@%@%@\r\n",
                           footerTitle,
                           [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = @"Goods Sold Are Not Refundable";
    spaceCount = (int)(38 - footer.length)/2;
    
    NSString *remind = [NSString stringWithFormat:@"%@%@",
                        [@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
                        footer];
    
    [mString appendString:shopName];
    [mString appendString:add1];
    [mString appendString:add2];
    [mString appendString:add3];
    [mString appendString:tel];
    [mString appendString:gstNo];
    [mString appendString:invNo];
    [mString appendString:dateTime];
    [mString appendString:header];
    [mString appendString:title];
    [mString appendString:mString2];
    [mString appendString:dashline];
    [mString appendString:subTotalEx];
    [mString appendString:subTotal];
    [mString appendString:discount];
    [mString appendString:svc];
    [mString appendString:gst];
    [mString appendString:rounding];
    [mString appendString:granTotal];
    //[mString appendString:pay];
    //[mString appendString:change];
    [mString appendString:remind];
    
    const char *gb2312Text = [mString UTF8String];
    NSString *textToPrint = [NSString stringWithCString:gb2312Text encoding:NSUTF8StringEncoding];
    
    CGFloat width = 576;
    UIFont *font = [UIFont fontWithName:@"Courier" size:(12.0 * 2)];
    
    UIImage *imageToPrint = [self imageWithString:textToPrint font:font width:width];
    
    [PrinterFunctions PrintImageWithPortname:portName portSettings:portSettings imageToPrint:imageToPrint maxWidth:width compressionEnable:YES withDrawerKick:YES];
    
    footer = nil;
    
}


+ (void)PrintRasterSingleKitchenWithPortname:(NSString *)portName portSettings:(NSString *)portSettings ItemName:(NSString *)itemName TableName:(NSString *)tableName OrderQty:(NSString *)orderQty
{
    
    NSString *data1 = @"";
    NSString *data2 = @"";
    NSString *data3 = @"";
    
    NSMutableString *mString = [[NSMutableString alloc]init];
    
    data1 = [NSString stringWithFormat:@"%@%@\r\n",
             @"Table No : ",
             tableName];
    
    data2 = [NSString stringWithFormat:@"%@\r\n",
             itemName];
    
    data3 = [NSString stringWithFormat:@"%@%@\r\n",
             @"Qty : ",
             orderQty];
    
    [mString appendString:data1];
    [mString appendString:data2];
    [mString appendString:data3];
    //[mString appendString:pay];
    
    const char *gb2312Text = [mString UTF8String];
    NSString *textToPrint = [NSString stringWithCString:gb2312Text encoding:NSUTF8StringEncoding];
    
    CGFloat width = 576;
    UIFont *font = [UIFont fontWithName:@"Courier" size:(12.0 * 2)];
    
    UIImage *imageToPrint = [self imageWithString:textToPrint font:font width:width];
    
    [PrinterFunctions PrintImageWithPortname:portName portSettings:portSettings imageToPrint:imageToPrint maxWidth:width compressionEnable:YES withDrawerKick:NO];
    
    
    //footer = nil;
    
}


+ (void)PrintRasterGroupKitchenWithPortname:(NSString *)portName portSettings:(NSString *)portSettings OrderDetail:(NSMutableArray *)orderArray TableName:(NSString *)tableName
{
    
    NSString *item = @"";
    NSString *qty = @"";
    NSString *tbName = @"";
    int spaceAdd = 0;
    
    NSString *detail2;
   
    NSMutableString *mString = [[NSMutableString alloc]init];
    NSMutableString *mString2 = [[NSMutableString alloc]init];
    
    tbName = [NSString stringWithFormat:@"Table No : %@",tableName];
    
    for (int i = 0; i<orderArray.count; i++) {
        item = [[orderArray objectAtIndex:i] objectForKey:@"IM_Description"];
        //itemDesc = [[orderArray objectAtIndex:i] objectForKey:@"IM_Description2"];
        
        if ([item length] > 15) item = [item substringToIndex:15];
        qty = [NSString stringWithFormat:@"%0.2f",[[[orderArray objectAtIndex:i] objectForKey:@"IM_Qty"] doubleValue]];
        if ([qty length] > 6) qty = [qty substringToIndex:6];
        
        spaceAdd = 15 - item.length;
        NSString *detail1 = [NSString stringWithFormat:@"%@%@",
                             item,
                             [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0]];
        
        spaceAdd = 6 - qty.length;
        if (spaceAdd > 0) {
            detail2 = [NSString stringWithFormat:@"%@%@",
                       [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0],
                       qty];
        }
        
        [mString2 appendString:[NSString stringWithFormat:@"%@%@\n",detail1,detail2]];
    }

    [mString appendString:tbName];
    [mString appendString:mString2];
    
    const char *gb2312Text = [mString UTF8String];
    NSString *textToPrint = [NSString stringWithCString:gb2312Text encoding:NSUTF8StringEncoding];
    
    CGFloat width = 576;
    UIFont *font = [UIFont fontWithName:@"Courier" size:(12.0 * 2)];
    
    UIImage *imageToPrint = [self imageWithString:textToPrint font:font width:width];
    
    [PrinterFunctions PrintImageWithPortname:portName portSettings:portSettings imageToPrint:imageToPrint maxWidth:width compressionEnable:YES withDrawerKick:NO];
    
    
    //footer = nil;
    
}


+(void)PrintRasterDailyCollectionWithPortName:(NSString *)portName portSettings:(NSString *)portSettings dateFrom:(NSString *)dateFrom dateTo:(NSString *)dateTo
{
    
     NSString *dbPath = [[LibraryAPI sharedInstance]getDbPath];
    
    NSMutableArray *cashArray = [[NSMutableArray alloc]init];
    NSMutableArray *masterArray = [[NSMutableArray alloc]init];
    NSMutableArray *visaArray = [[NSMutableArray alloc]init];
    NSMutableArray *debitArray = [[NSMutableArray alloc] init];
    NSMutableArray *amexArray = [[NSMutableArray alloc] init];
    NSMutableArray *unionArray = [[NSMutableArray alloc] init];
    NSMutableArray *dinerArray = [[NSMutableArray alloc] init];
    NSMutableArray *voucherArray = [[NSMutableArray alloc] init];
    
    NSMutableArray *compArray = [[NSMutableArray alloc]init];
    NSMutableArray *sumTotalArray = [[NSMutableArray alloc]init];
    NSMutableArray *paymentTypeArray = [[NSMutableArray alloc]init];
    
    NSMutableString *mString = [[NSMutableString alloc]init];
    
    [masterArray removeAllObjects];
    [cashArray removeAllObjects];
    [visaArray removeAllObjects];
    [debitArray removeAllObjects];
    [amexArray removeAllObjects];
    [unionArray removeAllObjects];
    [dinerArray removeAllObjects];
    [voucherArray removeAllObjects];
    __block NSString *voidAmt;
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rsCompany = [db executeQuery:@"Select * from Company"];
        while ([rsCompany next]) {
            [compArray addObject:[rsCompany resultDictionary]];
        }
        [rsCompany close];
        
        FMResultSet *rsPaymentType = [db executeQuery:@"Select * from PaymentType"];
        
        while ([rsPaymentType next]) {
            [paymentTypeArray addObject:[rsPaymentType resultDictionary]];
        }
        
        [rsPaymentType close];
        
        
        for (int j = 0; j < paymentTypeArray.count; j++) {
            FMResultSet *rs = [db executeQuery:@"select sum(qty) qty, Type, sum(amt) amt from ( "
                               "select count(*) qty, IvH_PaymentType1 as Type, sum(IvH_PaymentAmt1) Amt from InvoiceHdr where date(IvH_Date) between date(?) and date(?) and IvH_PaymentType1 = ? group by Ivh_PaymentType1 "
                               " union "
                               "select count(*) qty, IvH_PaymentType2 as Type, sum(IvH_PaymentAmt2) Amt from InvoiceHdr where date(IvH_Date) between date(?) and date(?) and IvH_PaymentType2 = ? group by Ivh_PaymentType2 "
                               " union "
                               "select count(*) qty, IvH_PaymentType3 as Type, sum(IvH_PaymentAmt3) Amt from InvoiceHdr where date(IvH_Date) between date(?) and date(?) and IvH_PaymentType3 = ? group by Ivh_PaymentType3 "
                               " union "
                               "select count(*) qty, IvH_PaymentType4 as Type, sum(IvH_PaymentAmt4) Amt from InvoiceHdr where date(IvH_Date) between date(?) and date(?) and IvH_PaymentType4 = ? group by Ivh_PaymentType4 "
                               " union "
                               "select count(*) qty, IvH_PaymentType5 as Type, sum(IvH_PaymentAmt5) Amt from InvoiceHdr where date(IvH_Date) between date(?) and date(?) and IvH_PaymentType5 = ? group by Ivh_PaymentType5 "
                               " union "
                               "select count(*) qty, IvH_PaymentType6 as Type, sum(IvH_PaymentAmt6) Amt from InvoiceHdr where date(IvH_Date) between date(?) and date(?) and IvH_PaymentType6 = ? group by Ivh_PaymentType6 "
                               " union "
                               "select count(*) qty, IvH_PaymentType7 as Type, sum(IvH_PaymentAmt7) Amt from InvoiceHdr where date(IvH_Date) between date(?) and date(?) and IvH_PaymentType7 = ? group by Ivh_PaymentType7 "
                               ") where Type != ''  group by Type",dateFrom,dateTo,[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"],dateFrom,dateTo,[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"],dateFrom,dateTo,[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"],dateFrom,dateTo,[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"],dateFrom,dateTo,[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"],dateFrom,dateTo,[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"],dateFrom,dateTo,[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"]];
            
            while ([rs next]) {
                if ([[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"] isEqualToString:@"Cash"]) {
                    [cashArray addObject:[rs resultDictionary]];
                }
                else if ([[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"] isEqualToString:@"Master"])
                {
                    [masterArray addObject:[rs resultDictionary]];
                }
                else if ([[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"] isEqualToString:@"Visa"])
                {
                    [visaArray addObject:[rs resultDictionary]];
                }
                else if ([[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"] isEqualToString:@"Debit"])
                {
                    [debitArray addObject:[rs resultDictionary]];
                }
                else if ([[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"] isEqualToString:@"Amex"])
                {
                    [amexArray addObject:[rs resultDictionary]];
                }
                else if ([[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"] isEqualToString:@"UnionPay"])
                {
                    [unionArray addObject:[rs resultDictionary]];
                }
                else if ([[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"] isEqualToString:@"Diners"])
                {
                    [dinerArray addObject:[rs resultDictionary]];
                }
                else if ([[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"] isEqualToString:@"Voucher"])
                {
                    [voucherArray addObject:[rs resultDictionary]];
                }
                
            }
            
            [rs close];
        }


        
        /*
        FMResultSet *rs = [db executeQuery:@"select sum(qty) qty, Type, sum(amt) amt from ( "
                           "select count(*) qty, IvH_PaymentType1 as Type, sum(IvH_PaymentAmt1) Amt from InvoiceHdr where date(IvH_Date) between date(?) and date(?) and IvH_PaymentType1 = ? group by Ivh_PaymentType1 "
                           " union "
                           "select count(*) qty, IvH_PaymentType2 as Type, sum(IvH_PaymentAmt2) Amt from InvoiceHdr where date(IvH_Date) between date(?) and date(?) and IvH_PaymentType1 = ? group by Ivh_PaymentType2 "
                           ") where Type != '' group by Type",dateFrom,dateTo,@"Cash",dateFrom,dateTo,@"Cash"];
        
        while ([rs next]) {
            [cashArray addObject:[rs resultDictionary]];
        }
        
        [rs close];
        
        FMResultSet *rsMaster = [db executeQuery:@"select sum(qty) qty, Type, sum(amt) amt from ( "
                               "select count(*) qty, IvH_PaymentType1 as Type, sum(IvH_PaymentAmt1) Amt from InvoiceHdr where date(IvH_Date) between date(?) and date(?) and IvH_PaymentType1 = ? group by Ivh_PaymentType1 "
                               " union "
                               "select count(*) qty, IvH_PaymentType2 as Type, sum(IvH_PaymentAmt2) Amt from InvoiceHdr where date(IvH_Date) between date(?) and date(?) and IvH_PaymentType1 = ? group by Ivh_PaymentType2 "
                               ") where Type != '' group by Type",dateFrom,dateTo,@"Card",dateFrom,dateTo,@"Card"];
        
        while ([rsMaster next]) {
            [masterArray addObject:[rsMaster resultDictionary]];
        }
        
        [rsMaster close];
        */
        
        FMResultSet *rsTotal = [db executeQuery:@"select sum(IvH_DocAmt) DocAmt, sum(IvH_DiscAmt) DocDisAmt, sum(IvH_DoctaxAmt) DocTaxAmt from InvoiceHdr where date(IvH_Date) between date(?) and date(?) and IvH_Status = ? group by IvH_Status ",dateFrom,dateTo,@"Pay"];
        
        if ([rsTotal next]) {
            [sumTotalArray addObject:[rsTotal resultDictionary]];
            //totalAmt = [NSString stringWithFormat:@"%0.2f",[rsTotal doubleForColumn:@"DocAmt"]];
        }
        
        [rsTotal close];
        
        FMResultSet *rsVoidTotal = [db executeQuery:@"select sum(SOH_DocAmt) DocAmt, sum(SOH_DiscAmt) DocDisAmt, sum(SOH_DoctaxAmt) DocTaxAmt from SalesOrderHdr where date(SOH_Date) between date(?) and date(?) and SOH_Status = ? group by SOH_Status ",dateFrom,dateTo,@"Void"];
        
        if ([rsVoidTotal next]) {
            //[sumTotalArray addObject:[rsVoidTotal resultDictionary]];
            voidAmt = [NSString stringWithFormat:@"%0.2f",[rsVoidTotal doubleForColumn:@"DocAmt"]];
        }
        else
        {
            voidAmt = @"0.00";
        }
        
        [rsVoidTotal close];

        
    }];
    
    [queue close];
    
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    NSString *dateString = [dateFormat stringFromDate:today];
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
    NSString *timeString = [timeFormat stringFromDate:today];
    
    //NSMutableArray *compname = [NSMutableArray arrayWithObjects:
    //compArray, nil];
    
    int spaceCount = 0;
    
    NSString *shopName = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Company"]];
    spaceCount = (int)(38 - shopName.length)/2;
    
    shopName = [NSString stringWithFormat:@"%@%@",
                [@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
                shopName];
    
    NSString *add1 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address1"]];
    spaceCount = (int)(38 - add1.length)/2;
    
    add1 = [NSString stringWithFormat:@"%@%@",
            [@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
            add1];
    
    NSString *add2 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address2"]];
    spaceCount = (int)(38 - add2.length)/2;
    
    add2 = [NSString stringWithFormat:@"%@%@",
            [@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
            add2];
    
    NSString *add3 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address3"]];
    spaceCount = (int)(38 - add3.length)/2;
    
    add3 = [NSString stringWithFormat:@"%@%@",
            [@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
            add3];
    
    NSString *tel = [NSString stringWithFormat:@"Tel : %@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Telephone"]];
    spaceCount = (int)(38 - tel.length)/2;
    
    tel = [NSString stringWithFormat:@"%@%@",
           [@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
           tel];
    
    NSString *date = [NSString stringWithFormat:@"Date : %@",dateString];
    NSString *time = timeString;
    
    spaceCount = (int)(38 - date.length - time.length);
    NSString *dateTime;
    dateTime = [NSString stringWithFormat:@"%@%@%@\r\n\r\n",
                date,[@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
                time];
    //NSString *header = @"           DAILY COLLECTION          \r\n";
    
    
    NSString *header = [NSString stringWithFormat:@"%@\r\n",@"DAILY COLLECTION "];
    spaceCount = (int)(38 - header.length)/2;
    
    header = [NSString stringWithFormat:@"%@%@",
            [@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
            header];
    
    
    NSString *salesDate = [NSString stringWithFormat:@"Sales Date : %@ to %@\r\n",dateFrom, dateTo];
    spaceCount = (int)(38 - salesDate.length)/2;
    
    salesDate = [NSString stringWithFormat:@"%@%@",
              [@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
              salesDate];
    
    //NSString *title =    @"Item              Qty   Price    Total\r\n";
    NSString *dashline = @"--------------------------------------\r\n";
    NSString *masterTrans = @"CARD TRANSACTION                      \r\n";
    NSString *cashTrans = @"CASH TRANSACTION                      \r\n";
    
    NSString *visaTrans = @"Visa TRANSACTION                      \r\n";
    NSString *debitTrans = @"Debit TRANSACTION                     \r\n";
    
    NSString *amexTrans = @"Amex TRANSACTION                      \r\n";
    NSString *unionTrans = @"UnionPay TRANSACTION                  \r\n";
    NSString *dinerTrans = @"Diners TRANSACTION                    \r\n";
    NSString *voucherTrans = @"Voucher TRANSACTION                  \r\n";
    
    
    NSString *summary = @"SUMMARY :                             \r\n";
    
    NSString *middle;
    NSString *middleTitle;
    NSString *masterAmt;
    NSString *cashAmt;
    
    NSString *visaAmt;
    NSString *debitAmt;
    NSString *amexAmt;
    NSString *unionAmt;
    NSString *dinerAmt;
    NSString *voucherAmt;
    
    
    if (masterArray.count > 0) {
        middle = [NSString stringWithFormat:@"%0.2f",[[[masterArray objectAtIndex:0] objectForKey:@"amt"] doubleValue]];
        middleTitle = [NSString stringWithFormat:@"SALES (%@)", [[[masterArray objectAtIndex:0] objectForKey:@"qty"] stringValue]];
        masterAmt = [NSString stringWithFormat:@"%@%@%@\r\n",
                   middleTitle,
                   [@" " stringByPaddingToLength:38-middleTitle.length-middle.length withString:@" " startingAtIndex:0],middle];
    }
    else
    {
        middle = [NSString stringWithFormat:@"%@",@"0.00"];
        middleTitle = [NSString stringWithFormat:@"SALES (%@)", @"0"];
        masterAmt = [NSString stringWithFormat:@"%@%@%@\r\n",
                   middleTitle,
                   [@" " stringByPaddingToLength:38-middleTitle.length-middle.length withString:@" " startingAtIndex:0],middle];
    }
    
    //---- cash --------
    if (cashArray.count > 0) {
        middle = [NSString stringWithFormat:@"%0.2f",[[[cashArray objectAtIndex:0] objectForKey:@"amt"] doubleValue]];
        middleTitle = [NSString stringWithFormat:@"SALES (%@)", [[[cashArray objectAtIndex:0] objectForKey:@"qty"] stringValue]];
        cashAmt = [NSString stringWithFormat:@"%@%@%@\r\n",
                   middleTitle,
                   [@" " stringByPaddingToLength:38-middleTitle.length-middle.length withString:@" " startingAtIndex:0],middle];
    }
    else
    {
        middle = [NSString stringWithFormat:@"%@",@"0.00"];
        middleTitle = [NSString stringWithFormat:@"SALES (%@)", @"0"];
        cashAmt = [NSString stringWithFormat:@"%@%@%@\r\n",
                   middleTitle,
                   [@" " stringByPaddingToLength:38-middleTitle.length-middle.length withString:@" " startingAtIndex:0],middle];
    }
    
    //------ visa ---------
    if (visaArray.count > 0) {
        middle = [NSString stringWithFormat:@"%0.2f",[[[visaArray objectAtIndex:0] objectForKey:@"amt"] doubleValue]];
        middleTitle = [NSString stringWithFormat:@"SALES (%@)", [[[visaArray objectAtIndex:0] objectForKey:@"qty"] stringValue]];
        visaAmt = [NSString stringWithFormat:@"%@%@%@\r\n",
                   middleTitle,
                   [@" " stringByPaddingToLength:38-middleTitle.length-middle.length withString:@" " startingAtIndex:0],middle];
    }
    else
    {
        middle = [NSString stringWithFormat:@"%@",@"0.00"];
        middleTitle = [NSString stringWithFormat:@"SALES (%@)", @"0"];
        visaAmt = [NSString stringWithFormat:@"%@%@%@\r\n",
                   middleTitle,
                   [@" " stringByPaddingToLength:38-middleTitle.length-middle.length withString:@" " startingAtIndex:0],middle];
    }
    
    //------- debit ---------
    if (debitArray.count > 0) {
        middle = [NSString stringWithFormat:@"%0.2f",[[[debitArray objectAtIndex:0] objectForKey:@"amt"] doubleValue]];
        middleTitle = [NSString stringWithFormat:@"SALES (%@)", [[[debitArray objectAtIndex:0] objectForKey:@"qty"] stringValue]];
        debitAmt = [NSString stringWithFormat:@"%@%@%@\r\n",
                   middleTitle,
                   [@" " stringByPaddingToLength:38-middleTitle.length-middle.length withString:@" " startingAtIndex:0],middle];
    }
    else
    {
        middle = [NSString stringWithFormat:@"%@",@"0.00"];
        middleTitle = [NSString stringWithFormat:@"SALES (%@)", @"0"];
        debitAmt = [NSString stringWithFormat:@"%@%@%@\r\n",
                   middleTitle,
                   [@" " stringByPaddingToLength:38-middleTitle.length-middle.length withString:@" " startingAtIndex:0],middle];
    }
    
    //------ amex --------
    if (amexArray.count > 0) {
        middle = [NSString stringWithFormat:@"%0.2f",[[[amexArray objectAtIndex:0] objectForKey:@"amt"] doubleValue]];
        middleTitle = [NSString stringWithFormat:@"SALES (%@)", [[[amexArray objectAtIndex:0] objectForKey:@"qty"] stringValue]];
        amexAmt = [NSString stringWithFormat:@"%@%@%@\r\n",
                   middleTitle,
                   [@" " stringByPaddingToLength:38-middleTitle.length-middle.length withString:@" " startingAtIndex:0],middle];
    }
    else
    {
        middle = [NSString stringWithFormat:@"%@",@"0.00"];
        middleTitle = [NSString stringWithFormat:@"SALES (%@)", @"0"];
        amexAmt = [NSString stringWithFormat:@"%@%@%@\r\n",
                   middleTitle,
                   [@" " stringByPaddingToLength:38-middleTitle.length-middle.length withString:@" " startingAtIndex:0],middle];
    }
    
    //-------- union ---------
    if (unionArray.count > 0) {
        middle = [NSString stringWithFormat:@"%0.2f",[[[unionArray objectAtIndex:0] objectForKey:@"amt"] doubleValue]];
        middleTitle = [NSString stringWithFormat:@"SALES (%@)", [[[unionArray objectAtIndex:0] objectForKey:@"qty"] stringValue]];
        unionAmt = [NSString stringWithFormat:@"%@%@%@\r\n",
                   middleTitle,
                   [@" " stringByPaddingToLength:38-middleTitle.length-middle.length withString:@" " startingAtIndex:0],middle];
    }
    else
    {
        middle = [NSString stringWithFormat:@"%@",@"0.00"];
        middleTitle = [NSString stringWithFormat:@"SALES (%@)", @"0"];
        unionAmt = [NSString stringWithFormat:@"%@%@%@\r\n",
                   middleTitle,
                   [@" " stringByPaddingToLength:38-middleTitle.length-middle.length withString:@" " startingAtIndex:0],middle];
    }
    
    //---------- diners -----------
    if (dinerArray.count > 0) {
        middle = [NSString stringWithFormat:@"%0.2f",[[[dinerArray objectAtIndex:0] objectForKey:@"amt"] doubleValue]];
        middleTitle = [NSString stringWithFormat:@"SALES (%@)", [[[dinerArray objectAtIndex:0] objectForKey:@"qty"] stringValue]];
        dinerAmt = [NSString stringWithFormat:@"%@%@%@\r\n",
                   middleTitle,
                   [@" " stringByPaddingToLength:38-middleTitle.length-middle.length withString:@" " startingAtIndex:0],middle];
    }
    else
    {
        middle = [NSString stringWithFormat:@"%@",@"0.00"];
        middleTitle = [NSString stringWithFormat:@"SALES (%@)", @"0"];
        dinerAmt = [NSString stringWithFormat:@"%@%@%@\r\n",
                   middleTitle,
                   [@" " stringByPaddingToLength:38-middleTitle.length-middle.length withString:@" " startingAtIndex:0],middle];
    }
    
    
    //---------- voucher -----------
    if (voucherArray.count > 0) {
        middle = [NSString stringWithFormat:@"%0.2f",[[[voucherArray objectAtIndex:0] objectForKey:@"amt"] doubleValue]];
        middleTitle = [NSString stringWithFormat:@"SALES (%@)", [[[voucherArray objectAtIndex:0] objectForKey:@"qty"] stringValue]];
        voucherAmt = [NSString stringWithFormat:@"%@%@%@\r\n",
                   middleTitle,
                   [@" " stringByPaddingToLength:38-middleTitle.length-middle.length withString:@" " startingAtIndex:0],middle];
    }
    else
    {
        middle = [NSString stringWithFormat:@"%@",@"0.00"];
        middleTitle = [NSString stringWithFormat:@"SALES (%@)", @"0"];
        voucherAmt = [NSString stringWithFormat:@"%@%@%@\r\n",
                   middleTitle,
                   [@" " stringByPaddingToLength:38-middleTitle.length-middle.length withString:@" " startingAtIndex:0],middle];
    }
    
    NSString *footer;
    NSString *footerTitle;
    NSString *totalAmt;
    NSString *taxAmt;
    NSString *discountAmt;
    NSString *totalSales;
    NSString *totalVoidSales;
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[sumTotalArray objectAtIndex:0] objectForKey:@"DocAmt"] doubleValue]];
    footerTitle = @"TOTAL AMOUNT";
    totalAmt = [NSString stringWithFormat:@"%@%@%@\r\n",footerTitle,[@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[sumTotalArray objectAtIndex:0] objectForKey:@"DocAmt"] doubleValue]];
    footerTitle = @"Total Sales";
    totalSales = [NSString stringWithFormat:@"%@%@%@\r\n",footerTitle,[@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[sumTotalArray objectAtIndex:0] objectForKey:@"DocDisAmt"] doubleValue]];
    footerTitle = @"Total Discount";
    discountAmt = [NSString stringWithFormat:@"%@%@%@\r\n",footerTitle,[@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[sumTotalArray objectAtIndex:0] objectForKey:@"DocTaxAmt"] doubleValue]];
    footerTitle = @"Total GST";
    taxAmt = [NSString stringWithFormat:@"%@%@%@\r\n",footerTitle,[@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[voidAmt doubleValue]];
    footerTitle = @"Total Void";
    totalVoidSales = [NSString stringWithFormat:@"%@%@%@\r\n",footerTitle,[@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];

    
    [mString appendString:shopName];
    [mString appendString:add1];
    [mString appendString:add2];
    [mString appendString:add3];
    [mString appendString:tel];
    [mString appendString:salesDate];
    [mString appendString:dateTime];
    [mString appendString:header];
    [mString appendString:dashline];
    
    [mString appendString:cashTrans];
    [mString appendString:cashAmt];
    [mString appendString:@"\r\n"];
    
    [mString appendString:masterTrans];
    [mString appendString:masterAmt];
    [mString appendString:@"\r\n"];
    
    // visa
    [mString appendString:visaTrans];
    [mString appendString:visaAmt];
    [mString appendString:@"\r\n"];
    
    // debit
    [mString appendString:debitTrans];
    [mString appendString:debitAmt];
    [mString appendString:@"\r\n"];
    
    //amex
    [mString appendString:amexTrans];
    [mString appendString:amexAmt];
    [mString appendString:@"\r\n"];
    
    //union
    [mString appendString:unionTrans];
    [mString appendString:unionAmt];
    [mString appendString:@"\r\n"];
    
    //diners
    [mString appendString:dinerTrans];
    [mString appendString:dinerAmt];
    [mString appendString:@"\r\n"];
    
    // voucher
    [mString appendString:voucherTrans];
    [mString appendString:voucherAmt];
    [mString appendString:@"\r\n"];
    
    [mString appendString:dashline];
    [mString appendString:totalAmt];
    [mString appendString:dashline];
    [mString appendString:@"\r\n"];
    [mString appendString:summary];
    [mString appendString:dashline];
    [mString appendString:totalSales];
    [mString appendString:discountAmt];
    [mString appendString:taxAmt];
    [mString appendString:totalVoidSales];
    
    const char *gb2312Text = [mString UTF8String];
    NSString *textToPrint = [NSString stringWithCString:gb2312Text encoding:NSUTF8StringEncoding];
    
    //NSString *textToPrint = mString;
    
    CGFloat width = 576;
    UIFont *font = [UIFont fontWithName:@"Courier" size:(12.0 * 2)];
    
    UIImage *imageToPrint = [self imageWithString:textToPrint font:font width:width];
    
    [PrinterFunctions PrintImageWithPortname:portName portSettings:portSettings imageToPrint:imageToPrint maxWidth:width compressionEnable:YES withDrawerKick:YES];
    
    footer = nil;
    
    masterArray = nil;
    visaArray = nil;
    cashArray = nil;
    debitArray = nil;
    amexAmt = nil;
    unionArray = nil;
    dinerArray = nil;
    
}


+ (void)PrintRasterTestPrint3InchWithPortname:(NSString *)portName portSettings:(NSString *)portSettings
{
    
    NSString *textToPrint = @"        Star Clothing Boutique\r\n"
    "             123 Star Road\r\n"
    "           City, State 12345\r\n"
    "           Tel : 03-88888888\r\n"
    "         GST ID : 78875565-09\r\n"
    "        Receipt : IV000000094\r\n"
    "\r\n"
    "Date: MM/DD/YYYY         Time:HH:MM PM\r\n"
    "SALE\r\n"
    "SKU            Description       Total\r\n"
    "300678566      PLAIN T-SHIRT    910.99\n"
    "300692003      BLACK DENIM       29.99\n"
    "300651148      BLUE DENIM        29.99\n"
    "Volkswagen     Eos                2.00\n"
    "300642980      STRIPED DRESS     49.99\n"
    "30063847       BLACK BOOTS       35.99\n"
    "--------------------------------------\r\n"
    "Subtotal                        156.95\r\n"
    "Discount                          0.00\r\n"
    "Total GST                         0.00\r\n"
    "Rounding                          0.00\r\n"
    "Total                           156.95\r\n"
    "Pay                             156.95\r\n"
    "Change                          156.95\r\n"
    "\r\n"
    "Charge\r\n159.95\r\n"
    "Refunds and Exchanges\r\n"
    "Within 30 days with receipt\r\n"
    "And tags attached\r\n";
    
    CGFloat width = 576;
    UIFont *font = [UIFont fontWithName:@"Courier" size:(12.0 * 2)];
    
    UIImage *imageToPrint = [self imageWithString:textToPrint font:font width:width];
    
    [PrinterFunctions PrintImageWithPortname:portName portSettings:portSettings imageToPrint:imageToPrint maxWidth:width compressionEnable:YES withDrawerKick:YES];
}


/**
 *  This function print the Raster Kanji sample receipt (3inch)
 *
 *  @param  portName        Port name to use for communication. This should be (TCP:<IP Address>), (BT:<iOS Port Name>),
 *                          or (BLE:<Device Name>).
 *  @param  portSettings    Set following settings
 *                          - Desktop USB Printer + Apple AirPort: @"9100" - @"9109" (Port Number)
 *                          - Portable Printer (Star Line Mode)  : @"portable"
 *                          - Others                             : @"" (blank)
 */
+ (void)PrintRasterKanjiSampleReceipt3InchWithPortname:(NSString *)portName portSettings:(NSString *)portSettings
{
    char *sjisText = "　　　　　　　　　　スター電機\n"
                     "　　　　　　　　修理報告書　兼領収書\n"
                     "------------------------------------------------------------------------\r\n"
                     "発行日時：YYYY年MM月DD日HH時MM分\n"
                     "TEL：054-347-XXXX\n\n"
                     "　　　　　ｲｹﾆｼ  ｼｽﾞｺ   ｻﾏ\n"
                     "　お名前：池西　静子　様\n"
                     "　御住所：静岡市清水区七ツ新屋\n"
                     "　　　　　５３６番地\n"
                     "　伝票番号：No.12345-67890\n\n"
                     "　この度は修理をご用命頂き有難うございます。\n"
                     " 今後も故障など発生した場合はお気軽にご連絡ください。\n"
                     "\n"
                     "品名／型名　　　　数量　　　金額　　　　　備考\n"
                     "------------------------------------------------------------------------\r\n"
                     "制御基板　　　　　　１　１０，０００　　　配達\n"
                     "操作スイッチ　　　　１　　３，８００　　　配達\n"
                     "パネル　　　　　　　１　　２，０００　　　配達\n"
                     "技術料　　　　　　　１　１５，０００\n"
                     "出張費用　　　　　　１　　５，０００\n"
                     "------------------------------------------------------------------------\r\n"
                     "\n"
                     "　　　　　　　　　　　　　小計　¥ ３５，８００\n"
                     "　　　　　　　　　　　　　内税　¥ 　１，７９０\n"
                     "　　　　　　　　　　　　　合計　¥ ３７，５９０\n"
                     "\n"
                     "　お問合わせ番号　　12345-67890\n\n";

    NSString *textToPrint = [NSString stringWithCString:sjisText encoding:NSUTF8StringEncoding];

    CGFloat width = 576;
    UIFont *font = [UIFont fontWithName:@"STHeitiJ-Light" size:(12.0 * 2)];
    
    UIImage *imageToPrint = [self imageWithString:textToPrint font:font width:width];
    
    [PrinterFunctions PrintImageWithPortname:portName portSettings:portSettings imageToPrint:imageToPrint maxWidth:width compressionEnable:YES withDrawerKick:YES];
}


/**
 *  This function print the Raster Simplified Chainese sample receipt (3inch)
 *
 *  @param  portName        Port name to use for communication. This should be (TCP:<IP Address>), (BT:<iOS Port Name>),
 *                          or (BLE:<Device Name>).
 *  @param  portSettings    Set following settings
 *                          - Desktop USB Printer + Apple AirPort: @"9100" - @"9109" (Port Number)
 *                          - Portable Printer (Star Line Mode)  : @"portable"
 *                          - Others                             : @"" (blank)
 */
+ (void)PrintRasterCHSSampleReceipt3InchWithPortname:(NSString *)portName portSettings:(NSString *)portSettings
{
    char *gb2312Text = "　　　　　　  　　STAR便利店\n"
                       "                欢迎光临\n"
                       "\n"
                       "Unit 1906-08,19/F,Enterprise Square 2,\n"
                       "  3 Sheung Yuet Road, Kowloon Bay, KLN\n"
                       "\n"
                       "Tel: (852) 2795 2335\n"
                       "\n"
                       "货品名称                 数量   　  价格\n"
                       "---------------------------------------\r\n"
                       "罐装可乐\n"
                       "* Coke                   1        7.00\n"
                       "纸包柠檬茶\n"
                       "* Lemon Tea              2       10.00\n"
                       "热狗\n"
                       "* Hot Dog                1       10.00\n"
                       "薯片(50克装)\n"
                       "* Potato Chips(50g)      1       11.00\n"
                       "---------------------------------------\r\n"
                       "\n"
                       "                        总　数 :  38.00\n"
                       "                        现　金 :  38.00\n"
                       "                        找　赎 :   0.00\n"
                       "\n"
                       "卡号码 Card No.        :       88888888\n"
                       "卡余额 Remaining Val.  :       88.00\n"
                       "机号　 Device No.      :       1234F1\n"
                       "\n"
                       "DD/MM/YYYY   HH:MM:SS   交易编号: 88888\n"
                       "\n"
                       "          收银机:001  收银员:180\n";
    
    NSString *textToPrint = [NSString stringWithCString:gb2312Text encoding:NSUTF8StringEncoding];
    
    CGFloat width = 576;
    
    UIFont *font = [UIFont fontWithName:@"Courier" size:(12.0 * 2)];

    UIImage *imageToPrint = [self imageWithString:textToPrint font:font width:width];
    
    [PrinterFunctions PrintImageWithPortname:portName portSettings:portSettings imageToPrint:imageToPrint maxWidth:width compressionEnable:YES withDrawerKick:YES];
}

/**
 *  This function print the Raster Traditional Chainese sample receipt (3inch)
 *
 *  @param  portName        Port name to use for communication. This should be (TCP:<IP Address>), (BT:<iOS Port Name>),
 *                          or (BLE:<Device Name>).
 *  @param  portSettings    Set following settings
 *                          - Desktop USB Printer + Apple AirPort: @"9100" - @"9109" (Port Number)
 *                          - Portable Printer (Star Line Mode)  : @"portable"
 *                          - Others                             : @"" (blank)
 */
+ (void)PrintRasterCHTSampleReceipt3InchWithPortname:(NSString *)portName portSettings:(NSString *)portSettings
{
    char *gig5Text = "　 　　　  　　Star Micronics\n"
                     "---------------------------------------\r\n"
                     "              電子發票證明聯\n"
                     "              103年01-02月\n"
                     "              EV-99999999\n"
                     "2014/01/15 13:00\n"
                     "隨機碼 : 9999      總計 : 999\n"
                     "賣　方 : 99999999\n"
                     "\n"
                     "商品退換請持本聯及銷貨明細表。\n"
                     "9999999-9999999 999999-999999 9999\n"
                     "\n"
                     "\n"
                     "         銷貨明細表 　(銷售)\n"
                     "                    2014-01-15 13:00:02\n"
                     "\n"
                     "烏龍袋茶2g20入　         55 x2    110TX\n"
                     "茉莉烏龍茶2g20入         55 x2    110TX\n"
                     "天仁觀音茶2g*20　        55 x2    110TX\n"
                     "     小　　計 :　　        330\n"
                     "     總　　計 :　　        330\n"
                     "---------------------------------------\r\n"
                     "現　金　　　               400\n"
                     "     找　　零 :　　         70\n"
                     " 101 發票金額 :　　        330\n"
                     "2014-01-15 13:00\n"
                     "\n"
                     "商品退換、贈品及停車兌換請持本聯。\n"
                     "9999999-9999999 999999-999999 9999\n";
    
    NSString *textToPrint = [NSString stringWithCString:gig5Text encoding:NSUTF8StringEncoding];
    
    CGFloat width = 576;
    UIFont *font = [UIFont fontWithName:@"Courier" size:(12.0 * 2)];
    
    UIImage *imageToPrint = [self imageWithString:textToPrint font:font width:width];
    
    [PrinterFunctions PrintImageWithPortname:portName portSettings:portSettings imageToPrint:imageToPrint maxWidth:width compressionEnable:YES withDrawerKick:YES];
}


#pragma mark Sample Receipt (Line) - without drawer kick

/**
 *  This function print the sample receipt (3inch)
 *
 *  @param  portName        Port name to use for communication. This should be (TCP:<IP Address>), (BT:<iOS Port Name>),
 *                          or (BLE:<Device Name>).
 *  @param  portSettings    Set following settings
 *                          - Desktop USB Printer + Apple AirPort: @"9100" - @"9109" (Port Number)
 *                          - Portable Printer (Star Line Mode)  : @"portable"
 *                          - Others                             : @"" (blank)
 */
+ (void)printSampleReceiptWithoutDrawerKickWithPortname:(NSString *)portName
                                           portSettings:(NSString *)portSettings
                                             paperWidth:(SMPaperWidth)paperWidth
                                           errorMessage:(NSMutableString *)message {
    NSData *commands = nil;

    switch (paperWidth) {
        case SMPaperWidth2inch:
            //commands = [self english2inchSampleReceipt];
            break;
        case SMPaperWidth3inch:
            commands = [self english3inchSampleReceipt:@"-" EnableGstYN:0]; //not call this so preset -
            break;
        case SMPaperWidth4inch:
            //commands = [self english4inchSampleReceipt];
            break;
    }
    
    [self sendCommand:commands portName:portName portSettings:portSettings timeoutMillis:10000 errorMessage:message];
    
}

+ (void)sendCommand:(NSData *)commandsToPrint portName:(NSString *)portName portSettings:(NSString *)portSettings
      timeoutMillis:(u_int32_t)timeoutMillis errorMessage:(NSMutableString *)message
{
    int commandSize = (int)commandsToPrint.length;
    unsigned char *dataToSentToPrinter = (unsigned char *)malloc(commandSize);
    [commandsToPrint getBytes:dataToSentToPrinter length:commandSize];
    
    SMPort *starPort = nil;
    @try
    {
        starPort = [SMPort getPort:portName :portSettings :timeoutMillis];
        if (starPort == nil)
        {
            [message appendString:@"Fail to Open Port.\nRefer to \"getPort API\" in the manual."];
            return;
        }
        
        StarPrinterStatus_2 status;
        [starPort beginCheckedBlock:&status :2];
        if (status.offline == SM_TRUE) {
            [message appendString:@"Printer is offline"];
            return;
        }
        
        struct timeval endTime;
        gettimeofday(&endTime, NULL);
        endTime.tv_sec += 30;
        
        int totalAmountWritten = 0;
        while (totalAmountWritten < commandSize)
        {
            int remaining = commandSize - totalAmountWritten;
            int amountWritten = [starPort writePort:dataToSentToPrinter :totalAmountWritten :remaining];
            totalAmountWritten += amountWritten;
            
            struct timeval now;
            gettimeofday(&now, NULL);
            if (now.tv_sec > endTime.tv_sec) {
                break;
            }
        }
        
        if (totalAmountWritten < commandSize) {
            [message appendString:@"Write port timed out"];
            return;
        }

        [starPort endCheckedBlock:&status :2];
        if (status.offline == SM_TRUE) {
            [message appendString:@"Printer is offline"];
            return;
        }
    }
    @catch (PortException *exception)
    {
        [message appendString:@"Write port timed out"];
    }
    @finally
    {
        free(dataToSentToPrinter);
        [SMPort releasePort:starPort];
    }
}

#pragma mark MSR

/**
 *  This function shows how to read the MCR data(credit card) of a portable printer.
 *  The function first puts the printer into MCR read mode, then asks the user to swipe a credit card
 *  This object then acts as a delegate for the UIAlertView.  See alert view responce for seeing how to read the MCR
 *  data
 *  one a card has been swiped.
 *  The user can cancel the MCR mode or the read the printer
 *
 *  @param  portName        Port name to use for communication. This should be (TCP:<IP Address>), (BT:<iOS Port Name>),
 *                          or (BLE:<Device Name>).
 *  @param  portSettings    Set following settings
 *                          - Desktop USB Printer + Apple AirPort: @"9100" - @"9109" (Port Number)
 *                          - Portable Printer (Star Line Mode)  : @"portable"
 *                          - Others                             : @"" (blank)
 */
- (void)MCRStartWithPortName:(NSString*)portName portSettings:(NSString*)portSettings
{
    starPort = nil;
    @try
    {
        starPort = [SMPort getPort:portName :portSettings :10000];
        if (starPort == nil)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Fail to Open Port.\nRefer to \"getPort API\" in the manual."
                                                            message:@""
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            return;
        }
        
        struct timeval endTime;
        gettimeofday(&endTime, NULL);
        endTime.tv_sec += 30;
        
        unsigned char startMCRCommand[] = {0x1b, 0x4d, 0x45};
        int commandSize = 3;
        
        int totalAmountWritten = 0;
        while (totalAmountWritten < 3)
        {
            int remaining = commandSize - totalAmountWritten;
            
            int blockSize = (remaining > 1024) ? 1024 : remaining;
            
            int amountWritten = [starPort writePort:startMCRCommand :totalAmountWritten :blockSize];
            totalAmountWritten += amountWritten;
            
            struct timeval now;
            gettimeofday(&now, NULL);
            if (now.tv_sec > endTime.tv_sec)
            {
                break;
            }
        }
        
        if (totalAmountWritten < commandSize)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Printer Error"
                                                            message:@"Write port timed out"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            [SMPort releasePort:starPort];
            return;
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"MCR"
                                                            message:@"Swipe a credit card"
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"OK", nil];
            [alert show];
        }
    }
    @catch (PortException *exception)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Printer Error"
                                                        message:@"Write port timed out"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

/**
 *  This is the responce function for reading MCR data.
 *  This will eather cancel the MCR function or read the data
 */
- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // Read MCR data
    if (buttonIndex != alertView.cancelButtonIndex) {
        @try
        {
            unsigned char dataToRead[100];
            
            int readSize = [starPort readPort:dataToRead :0 :100];
            
            NSString *MCRData = nil;
            if (readSize > 0) {
                MCRData = [NSString stringWithFormat:@"%s",dataToRead];
            } else {
                MCRData = @"NO DATA";
            }
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Card Data"
                                                            message:MCRData
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
        @catch (PortException *exception)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Card Data"
                                                            message:@"Failed to read port"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }
    
    // End MCR Mode
    unsigned char endMcrComman = 4;
    int dataWritten = [starPort writePort:&endMcrComman :0 :1];
    if (dataWritten == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Printer Error"
                                                        message:@"Write port timed out"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    
    [SMPort releasePort:starPort];
}


#pragma mark Bluetooth Setting

+ (SMBluetoothManager *)loadBluetoothSetting:(NSString *)portName portSettings:(NSString *)portSettings {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                     message:@""
                                                    delegate:nil
                                           cancelButtonTitle:nil
                                           otherButtonTitles:@"OK", nil];
    
    if (([portName.lowercaseString hasPrefix:@"bt:"] == NO) &&
        ([portName.lowercaseString hasPrefix:@"ble:"] == NO)) {
        alert.message = @"This function is available via the bluetooth interface only.";
        [alert show];
        return nil;
    }

    SMDeviceType deviceType;
    SMPrinterType printerType = [AppDelegate parsePortSettings:portSettings];
    if (printerType == SMPrinterTypeDesktopPrinterStarLine) {
        deviceType = SMDeviceTypeDesktopPrinter;
    } else {
        deviceType = SMDeviceTypePortablePrinter;
    }

    SMBluetoothManager *manager = [[SMBluetoothManager alloc] initWithPortName:portName
                                                                     deviceType:deviceType];
    if (manager == nil) {
        alert.message = @"initWithPortName:deviceType: is failure.";
        [alert show];
        return nil;
    }
    
    if ([manager open] == NO) {
        alert.message = @"open is failure.";
        [alert show];
        return nil;
    }
    
    if ([manager loadSetting] == NO) {
        alert.message = @"loadSetting is failure.";
        [alert show];
        [manager close];
        return nil;
    }
    
    [manager close];
    
    return manager;
}

#pragma mark diconnect bluetooth

+ (void)disconnectPort:(NSString *)portName portSettings:(NSString *)portSettings timeout:(u_int32_t)timeout {
    SMPort *port = [SMPort getPort:portName :portSettings :timeout];
    if (port == nil) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Fail to Open Port.\nRefer to \"getPort API\" in the manual."
                                                        message:@""
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    BOOL result = [port disconnect];
    if (result == NO) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Fail to Disconnect"
                                                        message:@""
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil];
        [alert show];
        return;
    }
    
    [SMPort releasePort:port];
}

@end
