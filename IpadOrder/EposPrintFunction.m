//
//  EposPrintFunction.m
//  IpadOrder
//
//  Created by IRS on 10/23/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "EposPrintFunction.h"
#import <FMDB.h>
#import "LibraryAPI.h"
#import "PublicMethod.h"

@implementation EposPrintFunction

+(int)getCompress:(int)connection
{
    if(connection == EPOS_OC_DEVTYPE_BLUETOOTH) {
        return EPOS_OC_COMPRESS_DEFLATE;
    }
    else
    {
        return EPOS_OC_COMPRESS_NONE;
    }
}

+(void)print:(EposBuilder *)builder Result:(Result *)result PortName:(NSString *)portName
{
    EposPrint *printer = nil;
    int errStatus = EPOS_OC_SUCCESS;
    unsigned long status = 0;
    unsigned long battery = 0;
    // sendData API timeout setting(10000 msec)
    const int sendTimeout = 30000;
    
    // nil check
    if((builder == nil) || (result == nil)) {
        return;
    }
    
    // init result
    result.printerStatus = 0;
    result.batteryStatus = 0;
    result.errStatus = 0;
    result.errType = RESULT_ERR_NONE;
    
    // do printing
    printer = [[EposPrint alloc] init];
    if(printer == nil) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:EPOS_OC_ERR_FAILURE];
        return;
    }
    
    errStatus = [printer openPrinter:EPOS_OC_DEVTYPE_TCP
                          DeviceName:portName
                             Enabled:EPOS_OC_FALSE
                            Interval:EPOS_OC_PARAM_DEFAULT
                             Timeout:50000];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT Status:errStatus];
        return;
    }
    
    errStatus = [printer getStatus:&status
                           Battery:&battery];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        [printer closePrinter];
        return;
    }
    
    result.printerStatus = status;
    result.batteryStatus = battery;
    
    if([self isPrintable:result]) {
        status = 0;
        battery = 0;
        
        errStatus = [printer beginTransaction];
        if(errStatus != EPOS_OC_SUCCESS) {
            [result setErrInfo:RESULT_ERR_EPOSPRINT
                        Status:errStatus];
            
            [printer closePrinter];
            return;
        }
        
        errStatus = [printer sendData:builder
                              Timeout:sendTimeout
                               Status:&status
                              Battery:&battery];
        
        result.printerStatus = status;
        result.batteryStatus = battery;
        
        if(errStatus != EPOS_OC_SUCCESS) {
            [result setErrInfo:RESULT_ERR_EPOSPRINT
                        Status:errStatus];
            
            [printer endTransaction];
            [printer closePrinter];
            return;
        }
        
        errStatus = [printer endTransaction];
        if(errStatus != EPOS_OC_SUCCESS) {
            [result setErrInfo:RESULT_ERR_EPOSPRINT
                        Status:errStatus];
            
            [printer closePrinter];
            return;
        }
    }
    
    // close and release printer object
    [printer closePrinter];
    
    
    return;

}

+(NSString *)displayMsg:(Result *)result
{
    // nil check
    if(result == nil) {
        return @"-";
    }
    
    NSString *errorMsg = [MsgMaker makeErrorMessage:result];
    if(errorMsg != nil){
        if([errorMsg length] > 0) {
            //[ShowMsg show:self Message:errorMsg];
            //[self showAlertView:errorMsg title:@"Printer Error"];
            NSLog(@"Printer Error %@",errorMsg);
            //[AppUtility showAlertView:@"Printer Error" message:errorMsg];
        }
    }
    
    NSString *warningMsg = [MsgMaker makeWarningMessage:result];
    if(warningMsg != nil){
        if([warningMsg length] > 0) {
            // _textWarnings.text = warningMsg;
            //[self showAlertView:errorMsg title:@"Printer Warning"];
            NSLog(@"Printer Warning %@",warningMsg);
        }
    }
    
    return errorMsg;
}

+ (BOOL)isPrintable:(Result *)result
{
    // nil check
    if(result == nil) {
        return NO;
    }
    
    if(IS_INCLUDE_STATUS(result.printerStatus, EPOS_OC_ST_OFF_LINE)) {
        return NO;
    }
    
    if(IS_INCLUDE_STATUS(result.printerStatus, EPOS_OC_ST_NO_RESPONSE)) {
        return NO;
    }
    
    return YES;
}

+(EposBuilder *)createKitchenReceiptFormatDataArray:(NSArray *)dataArray Result:(Result *)result
{
    int errStatus = EPOS_OC_SUCCESS;
    EposBuilder *builder = nil;
    
    // nil check
    if(result == nil){
        return nil;
    }
    
    result.printerStatus = 0;
    result.batteryStatus = 0;
    result.errStatus = 0;
    result.errType = RESULT_ERR_NONE;
    
    // Create builder
    builder = [[EposBuilder alloc] initWithPrinterModel:@"TM-T88V"
                                                   Lang:2];
    if(builder == nil) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:EPOS_OC_ERR_FAILURE];
        return nil;
    }
    
    // Set alignment to left
    errStatus = [builder addTextAlign:EPOS_OC_ALIGN_LEFT];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    // Text Buffer
    NSMutableString *textData = [[NSMutableString alloc] init];
    NSMutableString *textData2 = [[NSMutableString alloc] init];
    if(textData == nil){
        //[builder release];
        return nil;
    }
    
    errStatus = [builder addTextSize:2 Height:2];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"KR_Brand MATCHES[cd] %@",
                               @"Asterix"];
    
    NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"KR_OrderType MATCHES[cd] %@",
                               @"ItemOrder"];
    
    NSPredicate *finalPredicate1 = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate1, predicate2]];
    
    NSArray * itemOrderObject = [dataArray filteredArrayUsingPredicate:finalPredicate1];
    
    for (int i = 0; i < itemOrderObject.count; i++) {
        NSPredicate *predicate3 = [NSPredicate predicateWithFormat:@"KR_ManualID MATCHES[cd] %@", [[itemOrderObject objectAtIndex:i] objectForKey:@"KR_ManualID"]];
        NSPredicate *predicate4 = [NSPredicate predicateWithFormat:@"KR_OrderType MATCHES[cd] %@",
                                   @"CondimentOrder"];
        
        NSPredicate *finalPredicate2 = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate3, predicate4]];
        
        NSArray * condimentOrderObject = [dataArray filteredArrayUsingPredicate:finalPredicate2];
        
        [textData appendString:[NSString stringWithFormat:@"Table No: %@\r\n",[[itemOrderObject objectAtIndex:i] objectForKey:@"KR_TableName"]]];
        [textData appendString:[NSString stringWithFormat:@"%@\r\n",[[itemOrderObject objectAtIndex:i] objectForKey:@"KR_Desc"]]];
        [textData appendString:[NSString stringWithFormat:@"%@\r\n",[[itemOrderObject objectAtIndex:i] objectForKey:@"KR_Qty"]]];
        
        if (condimentOrderObject.count > 0) {
            
            for (int i = 0; i < dataArray.count; i++) {
                [textData2 appendString:@"\r\n"];
                [textData2 appendString:[NSString stringWithFormat:@" - %@ %@\r\n",[[condimentOrderObject objectAtIndex:i] objectForKey:@"KR_Desc"],[[condimentOrderObject objectAtIndex:i] objectForKey:@"KR_Qty"]]];
                
                
            }
        }
        
        
        errStatus = [builder addText:textData];
        if(errStatus != EPOS_OC_SUCCESS) {
            [result setErrInfo:RESULT_ERR_EPOSPRINT
                        Status:errStatus];
            
            return nil;
        }
        
        errStatus = [builder addTextSize:2 Height:2];
        if(errStatus != EPOS_OC_SUCCESS) {
            [result setErrInfo:RESULT_ERR_EPOSPRINT
                        Status:errStatus];
            
            return nil;
        }
        
        errStatus = [builder addTextFont:EPOS_OC_FONT_B];
        if(errStatus != EPOS_OC_SUCCESS) {
            [result setErrInfo:RESULT_ERR_EPOSPRINT
                        Status:errStatus];
            
            return nil;
        }
        
        errStatus = [builder addText:textData2];
        if(errStatus != EPOS_OC_SUCCESS) {
            [result setErrInfo:RESULT_ERR_EPOSPRINT
                        Status:errStatus];
            
            return nil;
        }
        
        [textData setString:@""];
        
        errStatus = [builder addFeedLine:1];
        if(errStatus != EPOS_OC_SUCCESS) {
            [result setErrInfo:RESULT_ERR_EPOSPRINT
                        Status:errStatus];
            
            return nil;
        }
        
        // Add command to cut receipt to command buffer
        
    }
    
    errStatus = [builder addCut:EPOS_OC_CUT_FEED];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    return builder;

}

+(EposBuilder *)createKitchenReceiptFormat:(Result *)result TableNo:(NSString *)tableNo ItemNo:(NSString *)itemName Qty:(NSString *)qty DataArray:(NSArray *)dataArray
{
    int errStatus = EPOS_OC_SUCCESS;
    EposBuilder *builder = nil;
    
    // nil check
    if(result == nil){
        return nil;
    }
    
    result.printerStatus = 0;
    result.batteryStatus = 0;
    result.errStatus = 0;
    result.errType = RESULT_ERR_NONE;
    
    // Create builder
    builder = [[EposBuilder alloc] initWithPrinterModel:@"TM-T88V"
                                                   Lang:2];
    if(builder == nil) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:EPOS_OC_ERR_FAILURE];
        return nil;
    }
    
    // Set alignment to left
    errStatus = [builder addTextAlign:EPOS_OC_ALIGN_LEFT];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    //errStatus = [builder addPageBegin];
    // Text Buffer
    NSMutableString *textData = [[NSMutableString alloc] init];
    NSMutableString *textData2 = [[NSMutableString alloc] init];
    if(textData == nil){
        //[builder release];
        return nil;
    }
    
    errStatus = [builder addTextSize:2 Height:2];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    
    [textData appendString:[NSString stringWithFormat:@"Table No: %@\r\n",tableNo]];
    [textData appendString:[NSString stringWithFormat:@"%@\r\n",itemName]];
    [textData appendString:[NSString stringWithFormat:@"%@\r\n",qty]];
    
    errStatus = [builder addText:textData];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    if (dataArray.count > 0) {
        //[textData appendString:[NSString stringWithFormat:@"%@\r\n",@"Condiment"]];
        for (int i = 0; i < dataArray.count; i++) {
                [textData2 appendString:@"\r\n"];
                [textData2 appendString:[NSString stringWithFormat:@" - %@ %@\r\n",[[dataArray objectAtIndex:i] objectForKey:@"KR_Desc"],[[dataArray objectAtIndex:i] objectForKey:@"KR_Qty"]]];
            
            
        }
        
    }
    
    errStatus = [builder addTextSize:2 Height:2];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    errStatus = [builder addTextFont:EPOS_OC_FONT_B];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    errStatus = [builder addText:textData2];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    [textData setString:@""];
    
    errStatus = [builder addFeedLine:1];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    // Add command to cut receipt to command buffer

    //errStatus = [builder addPageEnd];
    
    errStatus = [builder addCut:EPOS_OC_CUT_FEED];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    return builder;
}

+(EposBuilder *)createReceiptData:(Result *)result ComapnyArray:(NSMutableArray *)compArray CSArray:(NSMutableArray *)receiptArray EnableGst:(int)enableGST KickOutDrawerYN:(NSString *)kickOutDraweYN
{
    
    int errStatus = EPOS_OC_SUCCESS;
    EposBuilder *builder = nil;
    
    // nil check
    if(result == nil){
        return nil;
    }
    
    result.printerStatus = 0;
    result.batteryStatus = 0;
    result.errStatus = 0;
    result.errType = RESULT_ERR_NONE;
    
    // Create builder
    builder = [[EposBuilder alloc] initWithPrinterModel:@"TM-T88V"
                                                   Lang:2];
    if(builder == nil) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:EPOS_OC_ERR_FAILURE];
        return nil;
    }
    
    if ([kickOutDraweYN isEqualToString:@"Y"]) {
        errStatus = [builder addPulse:EPOS_OC_DRAWER_1 Time:EPOS_OC_PULSE_100];
    }
    
    
    // Set alignment to center
    errStatus = [builder addTextAlign:EPOS_OC_ALIGN_CENTER];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    // Add receipt text to command buffer
    // Section 1 : Store infomation
    
    errStatus = [builder addFeedLine:1];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        //[builder release];
        return nil;
    }
    
    // Text Buffer
    NSMutableString *textData = [[NSMutableString alloc] init];
    if(textData == nil){
        //[builder release];
        return nil;
    }
    
   
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
    //spaceCount = (int)(38 - shopName.length)/2;
    
    shopName = [NSString stringWithFormat:@"%@",
                shopName];
    
    NSString *add1 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address1"]];
    //spaceCount = (int)(38 - add1.length)/2;
    
    add1 = [NSString stringWithFormat:@"%@",
            add1];
    
    NSString *add2 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address2"]];
    //spaceCount = (int)(38 - add2.length)/2;
    
    add2 = [NSString stringWithFormat:@"%@",
            add2];
    
    NSString *add3 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address3"]];
    //spaceCount = (int)(38 - add3.length)/2;
    
    add3 = [NSString stringWithFormat:@"%@",
            add3];
    
    NSString *tel = [NSString stringWithFormat:@"Tel : %@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Telephone"]];
    //spaceCount = (int)(38 - tel.length)/2;
    
    tel = [NSString stringWithFormat:@"%@",
           tel];
    
    NSString *gstNo = [NSString stringWithFormat:@"GST ID : %@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_GstNo"]];
    //spaceCount = (int)(38 - gstNo.length)/2;
    
    gstNo = [NSString stringWithFormat:@"%@",
             gstNo];
    
    NSString *invNo = [NSString stringWithFormat:@"Receipt : %@\r\n",[[receiptArray objectAtIndex:0] objectForKey:@"IvH_DocNo"]];
    spaceCount = (int)(38 - invNo.length)/2;
    
    invNo = [NSString stringWithFormat:@"%@",
             invNo];
    
    NSString *gstTitle = @"Tax Invocie \r\n";
    
    NSString *date = [NSString stringWithFormat:@"Date : %@",dateString];
    NSString *time = timeString;
    
    spaceCount = (int)(38 - date.length - time.length);
    NSString *dateTime;
    dateTime = [NSString stringWithFormat:@"%@%@%@\r\n\r\n",
                date,[@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
                time];
    //NSString *header = @"SALE                                  \r\n";
    NSString *header;
    //NSString *tableName;
    header = [NSString stringWithFormat:@"SALE Table:%@ Pax: %@",[[receiptArray objectAtIndex:0] objectForKey:@"IvH_Table"],[[receiptArray objectAtIndex:0] objectForKey:@"IvH_PaxNo"]];
    spaceCount = (int)(38 - date.length - time.length);
    
    header = [NSString stringWithFormat:@"%@%@\r\n",
                header,[@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0]];
    
    
    NSString *title =    @"Item              Qty   Price    Total\r\n";
    NSString *dashline = @"--------------------------------------\r\n";
    /*
    NSString *currencyLine = [NSString stringWithFormat:@"%@%@%@%@%@%@%@\r\n",
                          [@" " stringByPaddingToLength:24 withString:@" " startingAtIndex:0],@"(",[[LibraryAPI sharedInstance] getCurrencySymbol],@")",@"    (",[[LibraryAPI sharedInstance] getCurrencySymbol],@")"];
     */
    NSString *item = @"";
    NSString *qty = @"";
    NSString *price = @"";
    NSString *itemTotal = @"";
    NSString *itemDesc2 = @"";
    double subTotalB4Gst = 0.00;
    long spaceAdd = 0;
    
    NSString *detail2;
    NSString *detail3;
    NSString *detail4;
    NSMutableString *mString2 = [[NSMutableString alloc]init];
    
    for (int i = 0; i<receiptArray.count; i++) {
        if ([[[receiptArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"]) {
            if (enableGST == 0) {
                item = [[receiptArray objectAtIndex:i] objectForKey:@"ItemDesc2"];
            }
            else
            {
                if ([[[receiptArray objectAtIndex:i]objectForKey:@"Flag"] isEqualToString:@"-"]) {
                    item = [[receiptArray objectAtIndex:i] objectForKey:@"ItemDesc2"];
                }
                else
                {
                    item = [[receiptArray objectAtIndex:i] objectForKey:@"ItemDesc"];
                }
                
            }
            subTotalB4Gst = subTotalB4Gst + [[[receiptArray objectAtIndex:i] objectForKey:@"IvD_TotalEx"] doubleValue];
            //NSLog(@"%d",[item length]);
            if ([item length] > 15) item = [item substringToIndex:15];
            qty = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:i] objectForKey:@"IvD_Quantity"] doubleValue]];
            if ([qty length] > 6) qty = [qty substringToIndex:6];
            price = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:i] objectForKey:@"IvD_UnitPrice"] doubleValue]];
            if ([price length] > 8) price = [price substringToIndex:8];
            itemTotal = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:i] objectForKey:@"IvD_SubTotal"] doubleValue]];
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
            
            itemDesc2 = [[receiptArray objectAtIndex:i] objectForKey:@"IM_Description2"];
            
            [mString2 appendString:[NSString stringWithFormat:@"%@%@%@%@\n",detail1,detail2,detail3,detail4]];
            
            //spaceAdd = 34 - itemDesc2.length;
            //NSString *detail5 = [NSString stringWithFormat:@"%@%@%@",@"  ",
            //                   itemDesc2,
            //                 [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0]];
            if ([itemDesc2 length] > 0) {
                [mString2 appendString:[NSString stringWithFormat:@"%@\n",itemDesc2]];
            }

        }
        else
        {
            item = [NSString stringWithFormat:@" - %@",[[receiptArray objectAtIndex:i] objectForKey:@"IVC_CDDescription"]];
            
            if ([item length] > 15) item = [item substringToIndex:15];
            spaceAdd = 15 - item.length;
            
            qty = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:i] objectForKey:@"IVC_CDQty"] doubleValue]];
            if ([qty length] > 6) qty = [qty substringToIndex:6];
            
            
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
        
    }
    
    NSString *footer;
    NSString *footerTitle;
    
    footer = [NSString stringWithFormat:@"%0.2f",subTotalB4Gst];
    footerTitle = @"SubTotal Exclude GST";
    NSString *subTotalEx = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"IvH_DocSubTotal"] doubleValue]];
    footerTitle = @"SubTotal";
    NSString *subTotal = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"IvH_DiscAmt"] doubleValue]];
    footerTitle = @"Discount";
    NSString *discount = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"IvH_DocServiceTaxAmt"] doubleValue]];
    footerTitle = @"Service Charge";
    NSString *serviceCharge = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"IvH_DocTaxAmt"] doubleValue]];
    footerTitle = @"Total GST";
    NSString *gst = [NSString stringWithFormat:@"%@%@%@\r\n",
                     footerTitle,
                     [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"IvH_Rounding"] doubleValue]];
    footerTitle = @"Rounding";
    NSString *rounding = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"IvH_DocAmt"] doubleValue]];
    footerTitle = @"Total";
    NSString *granTotal = [NSString stringWithFormat:@"%@%@%@\r\n",
                           footerTitle,
                           [@" " stringByPaddingToLength:19-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"IvH_TotalPay"] doubleValue]];
    footerTitle = @"Pay";
    NSString *pay = [NSString stringWithFormat:@"%@%@%@\r\n",
                     footerTitle,
                     [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"IvH_ChangeAmt"] doubleValue]];
    footerTitle = @"Change";
    NSString *change = [NSString stringWithFormat:@"%@%@%@\r\n\r\n",
                        footerTitle,
                        [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = @"Goods Sold Are Not Refundable";
    
    //NSString *remind = footer;
    
    errStatus = [builder addTextLang:2];
    //[textData appendString:eposSection1];
    
    [textData appendString:shopName];
    [textData appendString:add1];
    [textData appendString:add2];
    if (![add3 isEqualToString:@"\r\n"]) {
        [textData appendString:add3];
    }
    [textData appendString:tel];
    if (enableGST == 1) {
        [textData appendString:gstNo];
        [textData appendString:gstTitle];
    }
    //[textData appendString:gstNo];
    [textData appendString:invNo];
    
    errStatus = [builder addText:textData];
    
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    errStatus = [builder addFeedLine:1];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    [textData setString:@""];
    [textData appendString:dateTime];
    errStatus = [builder addTextAlign:EPOS_OC_ALIGN_LEFT];
    errStatus = [builder addText:textData];
    
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    [textData setString:@""];
    [textData appendString:header];
    //errStatus = [builder addTextAlign:EPOS_OC_ALIGN_LEFT];
    errStatus = [builder addText:textData];
    
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    [textData setString:@""];
    //errStatus = [builder addTextAlign:EPOS_OC_ALIGN_CENTER];
    
    [textData appendString:title];
    //[textData appendString:currencyLine];
    [textData appendString:dashline];
    errStatus = [builder addText:textData];
    
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    // Section 2 : Purchaced items
    errStatus = [builder addTextLang:2];
    [textData setString:@""];
    [textData appendString:mString2];
    
    errStatus = [builder addText:textData];
    
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    [textData setString:@""];
    
    [textData appendString:dashline];
    [textData appendString:subTotalEx];
    [textData appendString:subTotal];
    [textData appendString:discount];
    [textData appendString:serviceCharge];
    if (enableGST == 1) {
        [textData appendString:gst];
    }
    
    [textData appendString:rounding];
    
    //[textData appendString:eposSection2];
    
    errStatus = [builder addText:textData];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    
    [textData setString:@""];
    errStatus = [builder addFeedLine:1];
    //[textData appendString:eposSection3];
    errStatus = [builder addTextDouble:EPOS_OC_TRUE
                                    Dh:EPOS_OC_TRUE];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    [textData appendString:granTotal];
    errStatus = [builder addText:textData];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    errStatus = [builder addTextDouble:EPOS_OC_FALSE
                                    Dh:EPOS_OC_FALSE];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    errStatus = [builder addFeedLine:1];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    [textData setString:@""];
    
    [textData appendString:pay];
    [textData appendString:change];
    
    errStatus = [builder addText:textData];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    [textData setString:@""];
    errStatus = [builder addTextAlign:EPOS_OC_ALIGN_CENTER];
    //[textData appendString:remind];
    
    //[textData appendString:eposSection4];
    errStatus = [builder addText:textData];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    [textData setString:@""];
    
    // release temporary text object
    //[textData release];
    
    errStatus = [builder addFeedLine:2];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    // Add command to cut receipt to command buffer
    errStatus = [builder addCut:EPOS_OC_CUT_FEED];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    return builder;
}

+(EposBuilder *)createSalesOrderRceiptData:(Result *)result ComapnyArray:(NSMutableArray *)compArray SalesOrderArray:(NSMutableArray *)receiptArray EnableGst:(int)enableGST
{
    int errStatus = EPOS_OC_SUCCESS;
    EposBuilder *builder = nil;
    
    // nil check
    if(result == nil){
        return nil;
    }
    
    result.printerStatus = 0;
    result.batteryStatus = 0;
    result.errStatus = 0;
    result.errType = RESULT_ERR_NONE;
    
    // Create builder
    builder = [[EposBuilder alloc] initWithPrinterModel:@"TM-T88V"
                                                   Lang:2];
    if(builder == nil) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:EPOS_OC_ERR_FAILURE];
        return nil;
    }
    
    // Set alignment to center
    errStatus = [builder addTextAlign:EPOS_OC_ALIGN_CENTER];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    // Add receipt text to command buffer
    // Section 1 : Store infomation
    
    errStatus = [builder addFeedLine:1];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        //[builder release];
        return nil;
    }
    
    // Text Buffer
    NSMutableString *textData = [[NSMutableString alloc] init];
    if(textData == nil){
        //[builder release];
        return nil;
    }
    
    //NSMutableArray *receiptArray = [[NSMutableArray alloc]init];
    //NSMutableArray *compArray = [[NSMutableArray alloc]init];
    
    //[receiptArray removeAllObjects];
    
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
    //spaceCount = (int)(38 - shopName.length)/2;
    
    shopName = [NSString stringWithFormat:@"%@",
                shopName];
    
    NSString *add1 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address1"]];
    //spaceCount = (int)(38 - add1.length)/2;
    
    add1 = [NSString stringWithFormat:@"%@",
            add1];
    
    NSString *add2 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address2"]];
    //spaceCount = (int)(38 - add2.length)/2;
    
    add2 = [NSString stringWithFormat:@"%@",
            add2];
    
    NSString *add3 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address3"]];
    //spaceCount = (int)(38 - add3.length)/2;
    
    add3 = [NSString stringWithFormat:@"%@",
            add3];
    
    NSString *tel = [NSString stringWithFormat:@"Tel : %@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Telephone"]];
    //spaceCount = (int)(38 - tel.length)/2;
    
    tel = [NSString stringWithFormat:@"%@",
           tel];
    
    NSString *gstNo = [NSString stringWithFormat:@"GST ID : %@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_GstNo"]];
    //spaceCount = (int)(38 - gstNo.length)/2;
    
    gstNo = [NSString stringWithFormat:@"%@",
             gstNo];
    
    NSString *invNo = [NSString stringWithFormat:@"SO : %@\r\n",[[receiptArray objectAtIndex:0] objectForKey:@"SOH_DocNo"]];
    spaceCount = (int)(38 - invNo.length)/2;
    
    invNo = [NSString stringWithFormat:@"%@",
             invNo];
    
    NSString *date = [NSString stringWithFormat:@"Date : %@",dateString];
    NSString *time = timeString;
    
    spaceCount = (int)(38 - date.length - time.length);
    NSString *dateTime;
    dateTime = [NSString stringWithFormat:@"%@%@%@\r\n\r\n",
                date,[@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
                time];
    //NSString *header = @"SALE                                  \r\n";
    NSString *header;
    //NSString *tableName;in    
    header = [NSString stringWithFormat:@"SALE Table:%@ Pax: %@",[[receiptArray objectAtIndex:0] objectForKey:@"SOH_Table"],[[receiptArray objectAtIndex:0] objectForKey:@"SOH_PaxNo"]];
    spaceCount = (int)(38 - date.length - time.length);
    
    header = [NSString stringWithFormat:@"%@%@\r\n",
              header,[@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0]];
    
    NSString *title =    @"Item              Qty   Price    Total\r\n";
    NSString *dashline = @"--------------------------------------\r\n";
    
    NSString *item = @"";
    NSString *qty = @"";
    NSString *price = @"";
    NSString *itemTotal = @"";
    NSString *itemDesc2 = @"";
    int spaceAdd = 0;
    double subTotalB4Gst = 0.00;
    
    NSString *detail2;
    NSString *detail3;
    NSString *detail4;
    NSMutableString *mString2 = [[NSMutableString alloc]init];
    
    for (int i = 0; i<receiptArray.count; i++) {
        
        if ([[[receiptArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"]) {
            if (enableGST == 0) {
                item = [[receiptArray objectAtIndex:i] objectForKey:@"ItemDesc2"];
            }
            else
            {
                if ([[[receiptArray objectAtIndex:i]objectForKey:@"Flag"] isEqualToString:@"-"]) {
                    item = [[receiptArray objectAtIndex:i] objectForKey:@"ItemDesc2"];
                }
                else
                {
                    item = [[receiptArray objectAtIndex:i] objectForKey:@"ItemDesc"];
                }
                
            }
            
            //item = [[receiptArray objectAtIndex:i] objectForKey:@"ItemDesc"];
            if ([item length] > 15) item = [item substringToIndex:15];
            qty = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:i] objectForKey:@"SOD_Quantity"] doubleValue]];
            if ([qty length] > 6) qty = [qty substringToIndex:6];
            price = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:i] objectForKey:@"SOD_UnitPrice"] doubleValue]];
            if ([price length] > 8) price = [price substringToIndex:8];
            itemTotal = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:i] objectForKey:@"SOD_SubTotal"] doubleValue]];
            if ([itemTotal length] > 9) itemTotal = [itemTotal substringToIndex:9];
            
            subTotalB4Gst = subTotalB4Gst + [[[receiptArray objectAtIndex:i] objectForKey:@"SOD_TotalEx"] doubleValue];
            
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
            itemDesc2 = [[receiptArray objectAtIndex:i] objectForKey:@"IM_Description2"];
            [mString2 appendString:[NSString stringWithFormat:@"%@%@%@%@\n",detail1,detail2,detail3,detail4]];
            
            if ([itemDesc2 length] > 0) {
                [mString2 appendString:[NSString stringWithFormat:@"%@\n",itemDesc2]];
            }
        }
        else
        {
            item = [NSString stringWithFormat:@" - %@",[[receiptArray objectAtIndex:i] objectForKey:@"SOC_CDDescription"]];
            
            if ([item length] > 15) item = [item substringToIndex:15];
                spaceAdd = 15 - item.length;

            qty = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:i] objectForKey:@"SOC_CDQty"] doubleValue]];
            if ([qty length] > 6) qty = [qty substringToIndex:6];
            
            
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
        
        
        //[mString2 appendString:[NSString stringWithFormat:@"%@\n",itemDesc2]];
        
    }
    
    NSString *footer;
    NSString *footerTitle;
    
    footer = [NSString stringWithFormat:@"%0.2f",subTotalB4Gst];
    footerTitle = @"SubTotal Exclude GST";
    NSString *subTotalEx = [NSString stringWithFormat:@"%@%@%@\r\n",
                            footerTitle,
                            [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"SOH_DocSubTotal"] doubleValue]];
    footerTitle = @"SubTotal";
    NSString *subTotal = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"SOH_DiscAmt"] doubleValue]];
    footerTitle = @"Discount";
    NSString *discount = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"SOH_DocServiceTaxAmt"] doubleValue]];
    footerTitle = @"Service Charge";
    NSString *svc = [NSString stringWithFormat:@"%@%@%@\r\n",
                     footerTitle,
                     [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"SOH_DocTaxAmt"] doubleValue]];
    footerTitle = @"Total GST";
    NSString *gst = [NSString stringWithFormat:@"%@%@%@\r\n",
                     footerTitle,
                     [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"SOH_Rounding"] doubleValue]];
    footerTitle = @"Rounding";
    NSString *rounding = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"SOH_DocAmt"] doubleValue]];
    footerTitle = @"Total";
    NSString *granTotal = [NSString stringWithFormat:@"%@%@%@\r\n",
                           footerTitle,
                           [@" " stringByPaddingToLength:19-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"IvH_TotalPay"] doubleValue]];
    footerTitle = @"Pay";
    NSString *pay = [NSString stringWithFormat:@"%@%@%@\r\n",
                     footerTitle,
                     [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"IvH_ChangeAmt"] doubleValue]];
    footerTitle = @"Change";
    NSString *change = [NSString stringWithFormat:@"%@%@%@\r\n\r\n",
                        footerTitle,
                        [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    //footer = @"Goods Sold Are Not Refundable";
    //spaceCount = (int)(38 - footer.length)/2;
    /*
    NSString *remind = [NSString stringWithFormat:@"%@%@",
                        [@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
                        footer];
    */
    //errStatus = [builder addTextLang:2];
    //[textData appendString:eposSection1];
    
    [textData appendString:shopName];
    [textData appendString:add1];
    [textData appendString:add2];
    if (![add3 isEqualToString:@"\r\n"]) {
        [textData appendString:add3];
    }
    [textData appendString:tel];
    [textData appendString:gstNo];
    [textData appendString:invNo];
    
    errStatus = [builder addText:textData];
    
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    errStatus = [builder addFeedLine:1];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    [textData setString:@""];
    [textData appendString:dateTime];
    errStatus = [builder addTextAlign:EPOS_OC_ALIGN_LEFT];
    errStatus = [builder addText:textData];
    
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    [textData setString:@""];
    [textData appendString:header];
    //errStatus = [builder addTextAlign:EPOS_OC_ALIGN_LEFT];
    errStatus = [builder addText:textData];
    
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    [textData setString:@""];
    //errStatus = [builder addTextAlign:EPOS_OC_ALIGN_CENTER];
    [textData appendString:dashline];
    [textData appendString:title];
    
    errStatus = [builder addText:textData];
    
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    // Section 2 : Purchaced items
    errStatus = [builder addTextLang:2];
    [textData setString:@""];
    
    [textData appendString:mString2];
    
    errStatus = [builder addText:textData];
    
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    [textData setString:@""];
    [textData appendString:dashline];
    [textData appendString:subTotalEx];
    [textData appendString:subTotal];
    [textData appendString:discount];
    [textData appendString:svc];
    [textData appendString:gst];
    [textData appendString:rounding];
    
    //[textData appendString:eposSection2];
    
    errStatus = [builder addText:textData];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    
    [textData setString:@""];
    errStatus = [builder addFeedLine:1];
    //[textData appendString:eposSection3];
    errStatus = [builder addTextDouble:EPOS_OC_TRUE
                                    Dh:EPOS_OC_TRUE];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    [textData appendString:granTotal];
    errStatus = [builder addText:textData];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    errStatus = [builder addTextDouble:EPOS_OC_FALSE
                                    Dh:EPOS_OC_FALSE];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    errStatus = [builder addFeedLine:1];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    /*
    [textData setString:@""];
    
    [textData appendString:pay];
    [textData appendString:change];
    
    //errStatus = [builder addTextAlign:EPOS_OC_ALIGN_CENTER];
    //[textData appendString:remind];
    
    //[textData appendString:eposSection4];
    errStatus = [builder addText:textData];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    [textData setString:@""];
    
    // release temporary text object
    //[textData release];
    
    errStatus = [builder addFeedLine:];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    */
    
    // Add command to cut receipt to command buffer
    errStatus = [builder addCut:EPOS_OC_CUT_FEED];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    return builder;
}

+(EposBuilder *)createDailyCollectionData:(Result *)result DBPath:(NSString *)dbPath DateFrom:(NSString *)dateFrom DateTo:(NSString *)dateTo
{
    int errStatus = EPOS_OC_SUCCESS;
    EposBuilder *builder = nil;
    
    // nil check
    if(result == nil){
        return nil;
    }
    
    // init result
    result.printerStatus = 0;
    result.batteryStatus = 0;
    result.errStatus = 0;
    result.errType = RESULT_ERR_NONE;
    
    // Create builder
    builder = [[EposBuilder alloc] initWithPrinterModel:@"TM-T88V"
                                                   Lang:2];
    if(builder == nil) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:EPOS_OC_ERR_FAILURE];
        return nil;
    }
    
    // Set alignment to center
    //errStatus = [builder addTextFont:EPOS_OC_FONT_B];
    errStatus = [builder addTextAlign:EPOS_OC_ALIGN_CENTER];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    // Add receipt text to command buffer
    // Section 1 : Store infomation
    
    errStatus = [builder addFeedLine:1];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        //[builder release];
        return nil;
    }
    
    // Text Buffer
    NSMutableString *textData = [[NSMutableString alloc] init];
    if(textData == nil){
        //[builder release];
        return nil;
    }
    
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
        
        
        FMResultSet *rsTotal = [db executeQuery:@"select sum(IvH_DocAmt) DocAmt, sum(IvH_DiscAmt) DocDisAmt, sum(IvH_DoctaxAmt) DocTaxAmt,IvH_Status  from InvoiceHdr where date(IvH_Date) between date(?) and date(?) and IvH_Status = ? group by IvH_Status ",dateFrom,dateTo,@"Pay"];
        
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
        
        
        //[dbTable close];
        
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
    //spaceCount = (int)(38 - shopName.length)/2;
    
    shopName = [NSString stringWithFormat:@"%@",
                shopName];
    
    NSString *add1 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address1"]];
    //spaceCount = (int)(38 - add1.length)/2;
    
    add1 = [NSString stringWithFormat:@"%@",
            add1];
    
    NSString *add2 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address2"]];
    //spaceCount = (int)(38 - add2.length)/2;
    
    add2 = [NSString stringWithFormat:@"%@",
            add2];
    
    NSString *add3 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address3"]];
    //spaceCount = (int)(38 - add3.length)/2;
    
    add3 = [NSString stringWithFormat:@"%@",
            add3];
    
    NSString *tel = [NSString stringWithFormat:@"Tel : %@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Telephone"]];
    //spaceCount = (int)(38 - tel.length)/2;
    
    tel = [NSString stringWithFormat:@"%@",
           tel];
    
    NSString *salesDate = [NSString stringWithFormat:@"%@ to %@\r\n",dateFrom, dateTo];
    //spaceCount = (int)(38 - add2.length)/2;
    
    salesDate = [NSString stringWithFormat:@"Sales Date : %@",
            salesDate];
    
    NSString *date = [NSString stringWithFormat:@"Date : %@",dateString];
    NSString *time = timeString;
    
    spaceCount = (int)(38 - date.length - time.length);
    NSString *dateTime;
    dateTime = [NSString stringWithFormat:@"%@%@%@\r\n\r\n",
                date,[@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
                time];
    
    NSString *title = @"Daily Collection\r\n";
    NSString *dashline = @"--------------------------------------\r\n";
    NSString *masterTrans = @"Master TRANSACTION            \r\n";
    NSString *cashTrans = @"Cash TRANSACTION                \r\n";
    NSString *visaTrans = @"Visa TRANSACTION                \r\n";
    NSString *debitTrans = @"Debit TRANSACTION              \r\n";
    
    NSString *amexTrans = @"Amex TRANSACTION                \r\n";
    NSString *unionTrans = @"UnionPay TRANSACTION           \r\n";
    NSString *dinerTrans = @"Diners TRANSACTION             \r\n";
    NSString *voucherTrans = @"Voucher TRANSACTION          \r\n";
    
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
    
    //--------- cash trans --------------
    
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
    
    //-------visa trans -----------------
    
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
    
    //-------debit trans -----------------
    
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
    
    //-------amex trans -----------------
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
    
    //-------union trans -----------------
    
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
    
    //-------diner trans -----------------
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
    
    
    //-------voucher trans -----------------
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
    
    
    errStatus = [builder addTextLang:2];
    //[textData appendString:eposSection1];
    
    [textData appendString:shopName];
    [textData appendString:add1];
    [textData appendString:add2];
    
    if (![add3 isEqualToString:@"\r\n"]) {
        [textData appendString:add3];
    }
    
    [textData appendString:tel];
    [textData appendString:salesDate];
    
    errStatus = [builder addText:textData];
    
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    errStatus = [builder addFeedLine:1];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    [textData setString:@""];
    [textData appendString:dateTime];
    errStatus = [builder addText:textData];
    
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    [textData setString:@""];
    [textData appendString:title];
    errStatus = [builder addTextStyle:EPOS_OC_PARAM_UNSPECIFIED Ul:EPOS_OC_PARAM_UNSPECIFIED Em:EPOS_OC_TRUE Color:EPOS_OC_PARAM_UNSPECIFIED];
    errStatus = [builder addText:textData];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    
    [textData setString:@""];
    [textData appendString:dashline];
    errStatus = [builder addTextStyle:EPOS_OC_PARAM_UNSPECIFIED Ul:EPOS_OC_PARAM_UNSPECIFIED Em:EPOS_OC_FALSE Color:EPOS_OC_PARAM_UNSPECIFIED];
    errStatus = [builder addText:textData];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    // cash
    errStatus = [builder addFeedLine:1];
    [textData setString:@""];
    [textData appendString:cashTrans];
    [textData appendString:cashAmt];
    errStatus = [builder addTextAlign:EPOS_OC_ALIGN_LEFT];
    errStatus = [builder addText:textData];
    
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    // master
    errStatus = [builder addFeedLine:1];
    [textData setString:@""];
    [textData appendString:masterTrans];
    [textData appendString:masterAmt];
    //[textData appendString:dashline];
    //errStatus = [builder addTextAlign:EPOS_OC_ALIGN_LEFT];
    errStatus = [builder addText:textData];
    
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    // visa
    errStatus = [builder addFeedLine:1];
    [textData setString:@""];
    [textData appendString:visaTrans];
    [textData appendString:visaAmt];
    //[textData appendString:dashline];
    //errStatus = [builder addTextAlign:EPOS_OC_ALIGN_LEFT];
    errStatus = [builder addText:textData];
    
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    // debit
    errStatus = [builder addFeedLine:1];
    [textData setString:@""];
    [textData appendString:debitTrans];
    [textData appendString:debitAmt];
    //[textData appendString:dashline];
    //errStatus = [builder addTextAlign:EPOS_OC_ALIGN_LEFT];
    errStatus = [builder addText:textData];
    
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    
    // amex
    errStatus = [builder addFeedLine:1];
    [textData setString:@""];
    [textData appendString:amexTrans];
    [textData appendString:amexAmt];
    //[textData appendString:dashline];
    //errStatus = [builder addTextAlign:EPOS_OC_ALIGN_LEFT];
    errStatus = [builder addText:textData];
    
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    
    // union
    errStatus = [builder addFeedLine:1];
    [textData setString:@""];
    [textData appendString:unionTrans];
    [textData appendString:unionAmt];
    //[textData appendString:dashline];
    //errStatus = [builder addTextAlign:EPOS_OC_ALIGN_LEFT];
    errStatus = [builder addText:textData];
    
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    // diner
    errStatus = [builder addFeedLine:1];
    [textData setString:@""];
    [textData appendString:dinerTrans];
    [textData appendString:dinerAmt];
    //errStatus = [builder addTextAlign:EPOS_OC_ALIGN_LEFT];
    errStatus = [builder addText:textData];
    
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    // voucher
    errStatus = [builder addFeedLine:1];
    [textData setString:@""];
    [textData appendString:voucherTrans];
    [textData appendString:voucherAmt];
    [textData appendString:dashline];
    //errStatus = [builder addTextAlign:EPOS_OC_ALIGN_LEFT];
    errStatus = [builder addText:textData];
    
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }

    
    [textData setString:@""];
    [textData appendString:totalAmt];
    [textData appendString:dashline];
    //errStatus = [builder addTextAlign:EPOS_OC_ALIGN_LEFT];
    errStatus = [builder addText:textData];
    
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    errStatus = [builder addFeedLine:1];
    [textData setString:@""];
    [textData appendString:@"SUMMARY:\r\n"];
    [textData appendString:dashline];
    [textData appendString:totalSales];
    [textData appendString:discountAmt];
    [textData appendString:taxAmt];
    [textData appendString:totalVoidSales];
    //errStatus = [builder addTextAlign:EPOS_OC_ALIGN_LEFT];
    errStatus = [builder addText:textData];
    
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    [textData setString:@""];
    
    // release temporary text object
    //[textData release];
    
    errStatus = [builder addFeedLine:2];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    // Add command to cut receipt to command buffer
    errStatus = [builder addCut:EPOS_OC_CUT_FEED];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    compArray = nil;
    masterArray = nil;
    visaArray = nil;
    cashArray = nil;
    debitArray = nil;
    amexAmt = nil;
    unionArray = nil;
    dinerArray = nil;
    
    sumTotalArray = nil;
    
    return builder;
    
}

+(EposBuilder *)createKitchenReceiptGroupFormat:(Result *)result OrderDetail:(NSMutableString *)orderDetail TableName:(NSString *)tableCode
{
    int errStatus = EPOS_OC_SUCCESS;
    EposBuilder *builder = nil;
    
    // nil check
    if(result == nil){
        return nil;
    }
    
    // init result
    result.printerStatus = 0;
    result.batteryStatus = 0;
    result.errStatus = 0;
    result.errType = RESULT_ERR_NONE;
    
    // Create builder
    builder = [[EposBuilder alloc] initWithPrinterModel:@"TM-T88V"
                                                   Lang:2];
    if(builder == nil) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:EPOS_OC_ERR_FAILURE];
        return nil;
    }
    errStatus = [builder addTextSize:1 Height:2];
    // Set alignment to center
    //errStatus = [builder addTextFont:EPOS_OC_FONT_B];
    errStatus = [builder addTextAlign:EPOS_OC_ALIGN_LEFT];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    errStatus = [builder addFeedLine:1];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        //[builder release];
        return nil;
    }
    
    NSMutableString *textData = [[NSMutableString alloc] init];
    if(textData == nil){
        //[builder release];
        return nil;
    }
    
    NSString *tableName;
    //NSString *dashline = @"--------------------------------------\r\n";
    /*
    NSString *item = @"";
    NSString *qty = @"";
    int spaceAdd = 0;
    
    NSString *detail2;
    NSMutableString *mString2 = [[NSMutableString alloc]init];
    
    for (int i = 0; i<orderDetail.count; i++) {
        item = [[orderDetail objectAtIndex:i] objectForKey:@"IM_Description"];
        if ([item length] > 15) item = [item substringToIndex:14];
        qty = [NSString stringWithFormat:@"%0.2f",[[[orderDetail objectAtIndex:i] objectForKey:@"IM_Qty"] doubleValue]];
        if ([qty length] > 6) qty = [qty substringToIndex:6];
        
        
        spaceAdd = 15 - item.length;
        NSString *detail1 = [NSString stringWithFormat:@"Item : %@%@",
                             item,
                             [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0]];
        
        spaceAdd = 6 - qty.length;
        if (spaceAdd > 0) {
            detail2 = [NSString stringWithFormat:@"Qty : %@%@",
                       [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0],
                       qty];
        }
        
        [mString2 appendString:[NSString stringWithFormat:@"%@%@\n",detail1,detail2]];
    }
     */
    tableName = [NSString stringWithFormat:@"%@ : %@\n",@"Table No",tableCode];
    
    errStatus = [builder addTextLang:2];
    
    [textData appendString:tableName];
    
    errStatus = [builder addText:textData];
    
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    errStatus = [builder addFeedLine:2];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    [textData setString:@""];
    //errStatus = [builder addTextAlign:EPOS_OC_ALIGN_CENTER];
    [textData appendString:orderDetail];
    
    errStatus = [builder addText:textData];
    
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    [textData setString:@""];
    
    // release temporary text object
    //[textData release];
    
    errStatus = [builder addFeedLine:2];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    // Add command to cut receipt to command buffer
    errStatus = [builder addCut:EPOS_OC_CUT_FEED];
    if(errStatus != EPOS_OC_SUCCESS) {
        [result setErrInfo:RESULT_ERR_EPOSPRINT
                    Status:errStatus];
        
        return nil;
    }
    
    return builder;
}

+(EposBuilder *)stepOpenCashDrawer
{
    int errStatus = EPOS_OC_SUCCESS;
    EposBuilder *builder = nil;
    
    // Create builder
    builder = [[EposBuilder alloc] initWithPrinterModel:@"TM-T88V"
                                                   Lang:2];
    if(builder == nil) {
        //[result setErrInfo:RESULT_ERR_EPOSPRINT
          //          Status:EPOS_OC_ERR_FAILURE];
        return nil;
    }
    
    // Set alignment to center
    errStatus = [builder addPulse:EPOS_OC_DRAWER_1 Time:EPOS_OC_PULSE_100];
    
    return builder;
}

+(void)runPrintKicthenSequence:(int)indexNo IPAdd:(NSString *)ipAdd
{
    
}

//+(void)createFlyTechReceiptWithDBPath:(NSString *)dbPath GetInvNo:(NSString *)getInvNo EnableGst:(int)enableGST KickOutDrawerYN:(NSString *)kickOutDraweYN
+(void)createFlyTechReceiptWithCompanyArray:(NSMutableArray *)compArray ReceiptArray:(NSMutableArray *)receiptArray EnableGst:(int)enableGST KickOutDrawerYN:(NSString *)kickOutDraweYN PrintOption:(NSMutableArray *)printOption PrintType:(NSString *)printType
{
    
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    NSString *dateString = [dateFormat stringFromDate:today];
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
    NSString *timeString = [timeFormat stringFromDate:today];
    
    int spaceCount = 0;
    
    NSString *shopName = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Company"]];
    NSString *add1 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address1"]];
    NSString *add2 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address2"]];
    NSString *add3 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address3"]];
    NSString *tel = [NSString stringWithFormat:@"Tel : %@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Telephone"]];
    NSString *gstNo = [NSString stringWithFormat:@"GST ID : %@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_GstNo"]];
    NSString *invNo = [NSString stringWithFormat:@"Receipt : %@\r\n",[[receiptArray objectAtIndex:0] objectForKey:@"IvH_DocNo"]];
    //NSString *gstTitle = @"Tax Invoice\r\n";
    
    NSString *gstTitle = [NSString stringWithFormat:@"%@\r\n",[[printOption objectAtIndex:0] objectForKey:@"PO_ReceiptHeader"]];
    
    spaceCount = (int)(38 - invNo.length)/2;
    NSString *date = [NSString stringWithFormat:@"Date : %@",dateString];
    NSString *time = timeString;
    
    spaceCount = (int)(38 - date.length - time.length);
    NSString *dateTime;
    dateTime = [NSString stringWithFormat:@"%@%@%@\r\n\r\n",
                date,[@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
                time];
    
    /*
    NSString *header;
    header = [NSString stringWithFormat:@"Table:%@ Pax: %@",[[receiptArray objectAtIndex:0] objectForKey:@"IvH_Table"],[[receiptArray objectAtIndex:0] objectForKey:@"IvH_PaxNo"]];
    spaceCount = (int)(38 - date.length - time.length);
    
    header = [NSString stringWithFormat:@"%@%@\r\n",
              header,[@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0]];
     */
    
    NSString *header;
    NSString *headerP1;
    NSString *headerP2;
    
    headerP1 = [NSString stringWithFormat:@"Table: %@",[[receiptArray objectAtIndex:0] objectForKey:@"IvH_Table"]];
    headerP2 = [NSString stringWithFormat:@"Pax: %@",[[receiptArray objectAtIndex:0] objectForKey:@"IvH_Table"]];
    
    spaceCount = (int)(38 - [headerP1 length] - [headerP2 length]);
    
    header = [NSString stringWithFormat:@"%@%@%@\r\n\r\n",
              headerP1,[@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
              headerP2];
    
    NSString *title =    @"Item              Qty   Price    Total\r\n";
    //NSString *currencyLine = @"        ------------ (RM)----------------\r\n";
    NSString *dashline = @"--------------------------------------\r\n";
    
    NSString *item = @"";
    NSString *qty = @"";
    NSString *price = @"";
    NSString *itemTotal = @"";
    NSString *itemDesc2 = @"";
    double subTotalB4Gst = 0.00;
    long spaceAdd = 0;
    
    NSString *detail2;
    NSString *detail3;
    NSString *detail4;
    NSMutableString *mString2 = [[NSMutableString alloc]init];
    NSMutableString *paymentTypeString = [[NSMutableString alloc]init];
    NSMutableString *gstSummaryString = [[NSMutableString alloc]init];
    NSMutableString *customerInfo = [[NSMutableString alloc] init];
    
    NSUInteger defaultSpace1 = 0;
    NSUInteger defaultSpace2 = 0;
    double gstTotalSalesTax = 0.00;
    
    spaceAdd = 5 - [[NSString stringWithFormat:@"(%@)",[[LibraryAPI sharedInstance] getCurrencySymbol]] length];
    NSString *currency = [NSString stringWithFormat:@"%@%@",
                          [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0],
                          [NSString stringWithFormat:@"(%@)",[[LibraryAPI sharedInstance] getCurrencySymbol]]];
    
    
    NSString *currencyLine2 = [NSString stringWithFormat:@"%@%@\r\n",
                               [@" " stringByPaddingToLength:24 withString:@" " startingAtIndex:0],
                               currency];
    
    for (int i = 0; i<receiptArray.count; i++) {
        if ([[[receiptArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"]) {
            if (enableGST == 0) {
                item = [[receiptArray objectAtIndex:i] objectForKey:@"ItemDesc2"];
            }
            else
            {
                if ([[[receiptArray objectAtIndex:i]objectForKey:@"Flag"] isEqualToString:@"-"]) {
                    item = [[receiptArray objectAtIndex:i] objectForKey:@"ItemDesc2"];
                }
                else
                {
                    item = [[receiptArray objectAtIndex:i] objectForKey:@"ItemDesc"];
                }
                
            }
            subTotalB4Gst = subTotalB4Gst + [[[receiptArray objectAtIndex:i] objectForKey:@"IvD_TotalEx"] doubleValue];
            
            gstTotalSalesTax = gstTotalSalesTax + [[[receiptArray objectAtIndex:i] objectForKey:@"IvD_TotalSalesTax"] doubleValue];
            
            //NSLog(@"%d",[item length]);
            if ([item length] > 15) item = [item substringToIndex:15];
            qty = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:i] objectForKey:@"IvD_Quantity"] doubleValue]];
            if ([qty length] > 6) qty = [qty substringToIndex:6];
            price = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:i] objectForKey:@"IvD_UnitPrice"] doubleValue]];
            if ([price length] > 8) price = [price substringToIndex:8];
            itemTotal = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:i] objectForKey:@"IvD_SubTotal"] doubleValue]];
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
            
            itemDesc2 = [[receiptArray objectAtIndex:i] objectForKey:@"IM_Description2"];
            
            [mString2 appendString:[NSString stringWithFormat:@"%@%@%@%@\n",detail1,detail2,detail3,detail4]];
            
            if ([[[printOption objectAtIndex:0] objectForKey:@"PO_ShowItemDescription2"] integerValue] == 1)
            {
                if ([itemDesc2 length] > 0) {
                    [mString2 appendString:[NSString stringWithFormat:@"%@\n",itemDesc2]];
                }
            }

        }
        else
        {
            item = [NSString stringWithFormat:@" - %@",[[receiptArray objectAtIndex:i] objectForKey:@"IVC_CDDescription"]];
            
            if ([item length] > 15) item = [item substringToIndex:15];
            spaceAdd = 15 - item.length;
            
            qty = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:i] objectForKey:@"IVC_CDQty"] doubleValue]];
            if ([qty length] > 6) qty = [qty substringToIndex:6];
            
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
        
        if (i == 0) {
            for (int j = 1; j < 9; j++)
            {
                if ([[receiptArray objectAtIndex:0] objectForKey:[NSString stringWithFormat:@"IvH_PaymentAmt%d",j]] != [NSNull null]) {
                    if ([[[receiptArray objectAtIndex:0] objectForKey:[NSString stringWithFormat:@"IvH_PaymentAmt%d",j]] doubleValue] != 0.00)
                    {
                        [paymentTypeString appendString:[self autoGeneratePaymentTypeForReceiptWithTitle:[[receiptArray objectAtIndex:0] objectForKey:[NSString stringWithFormat:@"IvH_PaymentType%d",j]] Amount:[[[receiptArray objectAtIndex:0] objectForKey:[NSString stringWithFormat:@"IvH_PaymentAmt%d",j]] stringValue] ReceiptLength:38]];
                    }
                }
                
            }
            
            if ([[[printOption objectAtIndex:0] objectForKey:@"PO_ShowCustomerInfo"]integerValue] == 1)
            {
                if ([[[receiptArray objectAtIndex:0] objectForKey:@"IvH_CustName"] length] > 0) {
                    //[customerInfo appendString:dashline];
                    [customerInfo appendString:[NSString stringWithFormat:@"Bill to: %@\r\n",[[receiptArray objectAtIndex:0] objectForKey:@"IvH_CustName"]]];
                    [customerInfo appendString:[NSString stringWithFormat:@"%@\r\n",[[receiptArray objectAtIndex:0] objectForKey:@"IvH_CustAdd1"]]];
                    [customerInfo appendString:[NSString stringWithFormat:@"%@\r\n",[[receiptArray objectAtIndex:0] objectForKey:@"IvH_CustAdd2"]]];
                    
                    if ([[[receiptArray objectAtIndex:0] objectForKey:@"IvH_CustAdd3"] length] > 0)
                    {
                        [customerInfo appendString:[NSString stringWithFormat:@"%@\r\n",[[receiptArray objectAtIndex:0] objectForKey:@"IvH_CustAdd3"]]];
                    }
                    
                    if ([[[receiptArray objectAtIndex:0] objectForKey:@"IvH_CustTelNo"] length] > 0)
                    {
                        [customerInfo appendString:[NSString stringWithFormat:@"%@\r\n",[[receiptArray objectAtIndex:0] objectForKey:@"IvH_CustTelNo"]]];
                    }
                    
                    if ([[[receiptArray objectAtIndex:0] objectForKey:@"IvH_CustGstNo"] length] > 0)
                    {
                        [customerInfo appendString:[NSString stringWithFormat:@"%@\r\n\r\n",[[receiptArray objectAtIndex:0] objectForKey:@"IvH_CustGstNo"]]];
                    }
                    
                }
            }

        }
        
    }
    
    if (enableGST == 1)
    {
        if ([[[printOption objectAtIndex:0] objectForKey:@"PO_ShowGstSummary"] integerValue] == 1)
        {
            if ([[[receiptArray objectAtIndex:0] objectForKey:@"IvH_DocTaxAmt"] doubleValue] > 0.00) {
                
                NSString *gstSummaryline1 = @"    ---------------------------------\r\n";
                
                NSString *gstSummaryline3;
                NSString *gstSummaryline2;
                
                gstSummaryline2 = @"    | Tax Code   %       Amt     Tax|\r\n";
                gstSummaryline3 = @"    | GST Summary                   |\r\n";
                
                [gstSummaryString appendString:gstSummaryline1];
                [gstSummaryString appendString:gstSummaryline2];
                [gstSummaryString appendString:gstSummaryline3];
                
                [gstSummaryString appendString:[self autoGenerateGstSummaryContentWithTaxCode:[[receiptArray objectAtIndex:0] objectForKey:@"IvD_ItemTaxCode"] Percent:[[[receiptArray objectAtIndex:0] objectForKey:@"IvD_TaxRate"] stringValue] Amount:[NSString stringWithFormat:@"%0.2f",subTotalB4Gst] TaxAmount:[NSString stringWithFormat:@"%0.2f",gstTotalSalesTax]]];
                
                [gstSummaryString appendString:[self autoGenerateGstSummaryContentWithTaxCode:[NSString stringWithFormat:@"#%@",[[receiptArray objectAtIndex:0] objectForKey:@"IvD_ItemTaxCode"]] Percent:[[[receiptArray objectAtIndex:0] objectForKey:@"IvD_TaxRate"] stringValue] Amount:[NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"IvH_DocServiceTaxAmt"] doubleValue]] TaxAmount:[NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"IvH_DocServiceTaxGstAmt"] doubleValue]]]];
                
                [gstSummaryString appendString:[self autoGenerateGstSummaryContentWithTaxCode:@"Total" Percent:@"" Amount:[NSString stringWithFormat:@"%0.2f",subTotalB4Gst + [[[receiptArray objectAtIndex:0] objectForKey:@"IvH_DocServiceTaxAmt"] doubleValue]] TaxAmount:[NSString stringWithFormat:@"%0.2f",gstTotalSalesTax + [[[receiptArray objectAtIndex:0] objectForKey:@"IvH_DocServiceTaxGstAmt"] doubleValue]]]];
                
                [gstSummaryString appendString:gstSummaryline1];
                [gstSummaryString appendString:@"    # indicated this tax code belong\r\n"];
                [gstSummaryString appendString:@"    to service charges\r\n"];
            }
        }
    }

    NSString *footer;
    NSString *footerTitle;
    
    footer = [NSString stringWithFormat:@"%0.2f",subTotalB4Gst];
    footerTitle = @"SubTotal Exclude GST";
    NSString *subTotalEx = [NSString stringWithFormat:@"%@%@%@\r\n",
                            footerTitle,
                            [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"IvH_DocSubTotal"] doubleValue]];
    footerTitle = @"SubTotal";
    NSString *subTotal = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"IvH_DiscAmt"] doubleValue]];
    footerTitle = @"Discount";
    NSString *discount = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"IvH_DocServiceTaxAmt"] doubleValue]];
    footerTitle = @"Service Charge";
    NSString *serviceCharge = [NSString stringWithFormat:@"%@%@%@\r\n",
                               footerTitle,
                               [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"IvH_DocTaxAmt"] doubleValue]];
    footerTitle = @"Total GST";
    NSString *gst = [NSString stringWithFormat:@"%@%@%@\r\n",
                     footerTitle,
                     [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"IvH_Rounding"] doubleValue]];
    footerTitle = @"Rounding";
    NSString *rounding = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"IvH_DocAmt"] doubleValue]];
    footerTitle = @"Total";
    NSString *granTotal = [NSString stringWithFormat:@"%@%@%@\r\n",
                           footerTitle,
                           [@" " stringByPaddingToLength:19-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    /*
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"IvH_TotalPay"] doubleValue]];
    footerTitle = @"Pay";
    NSString *pay = [NSString stringWithFormat:@"%@%@%@\r\n",
                     footerTitle,
                     [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    */
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"IvH_ChangeAmt"] doubleValue]];
    footerTitle = @"Change";
    NSString *change = [NSString stringWithFormat:@"%@%@%@\r\n\r\n",
                        footerTitle,
                        [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    //footer = @"Goods Sold Are Not Refundable";
    //spaceCount = (int)(38 - footer.length)/2;
    
    //NSString *remind = [NSString stringWithFormat:@"%@%@",
    //                  [@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
    //                footer];
    //NSString *remind = footer;
    NSMutableString *headerPart = [[NSMutableString alloc] init];
    NSMutableString *middlePart = [[NSMutableString alloc] init];
    NSMutableString *footerPart = [[NSMutableString alloc] init];
    
    [headerPart appendString:@"\r\n"];
    if ([printType isEqualToString:@"ReprintReceipt"]) {
        [headerPart appendString:[NSString stringWithFormat:@"%@%@\r\n\r\n",@"\r\n",@"Reprint Receipt"]];
    }
    [headerPart appendString:shopName];
    [headerPart appendString:add1];
    [headerPart appendString:add2];
    if (![add3 isEqualToString:@"\r\n"]) {
        [headerPart appendString:add3];
    }
    
    if ([[[printOption objectAtIndex:0] objectForKey:@"PO_ShowCompanyTelNo"] integerValue] == 1) {
        [headerPart appendString:tel];
    }
    
    //[headerPart appendString:tel];
    if (enableGST == 1)
    {
        [headerPart appendString:gstNo];
        [headerPart appendString:gstTitle];
    }
    [headerPart appendString:invNo];
    
    [middlePart setString:@""];
    [middlePart appendString:dateTime];
    
    //---------customer info-------------
    [middlePart appendString:customerInfo];
    //--------------------------------
    
    [middlePart appendString:header];
    [middlePart appendString:title];
    [middlePart appendString:currencyLine2];
    [middlePart appendString:dashline];
    [middlePart appendString:mString2];
    //[middlePart setString:@""];
    
    [footerPart setString:@""];
    [footerPart appendString:dashline];
    [footerPart appendString:subTotalEx];
    
    if ([[[printOption objectAtIndex:0] objectForKey:@"PO_ShowSubTotalIncGst"] integerValue] == 1) {
        [footerPart appendString:subTotal];
    }
    
    
    if ([[[printOption objectAtIndex:0] objectForKey:@"PO_ShowDiscount"] integerValue] == 1) {
        [footerPart appendString:discount];
    }
    
    if ([[[printOption objectAtIndex:0] objectForKey:@"PO_ShowServiceCharge"] integerValue] == 1) {
        [footerPart appendString:serviceCharge];
    }
    
    //[footerPart appendString:subTotal];
    //[footerPart appendString:discount];
    //[footerPart appendString:serviceCharge];
    if (enableGST == 1) {
        [footerPart appendString:gst];
    }
    [footerPart appendString:rounding];
    //[footerPart appendString:granTotal];
    //[footerPart appendString:pay];
    //[footerPart appendString:change];
    
    [PosApi openCashBox];
    [PosApi setPrinterSettings:CHARSET_GBK leftMargin:0 printAreaWidth:576 printQuality:8];
    [PosApi setPrintFont:PRINT_FONT_12x24];
    
    [PosApi setPrintFormat:ALIGNMENT_CENTERD];
    [PosApi printText:headerPart];
    
    [PosApi setPrintFormat:ALIGNMENT_LEFT];
    [PosApi printText:middlePart];
    [PosApi printText:footerPart];
    [PosApi printText:@"\r\n"];
    [PosApi setPrintCharacterScale:FONT_SCALE_VERTICAL_2 hScale:FONT_SCALE_HORIZONTAL_2];
    [PosApi printText:granTotal];
    [PosApi printText:@"\r\n"];
    [PosApi setPrintCharacterScale:FONT_SCALE_VERTICAL_1 hScale:FONT_SCALE_HORIZONTAL_1];
    //[PosApi printText:pay];
    [PosApi printText:paymentTypeString];
    [PosApi printText:change];
    [PosApi printText:@"\r\n"];
    //[PosApi printText:[[printOption objectAtIndex:0] objectForKey:@"PO_ReceiptFooter"]];
    [PosApi printText:gstSummaryString];
    //[PosApi printText:@"\r\n"];
    [PosApi printText:@"\r\n"];
    [PosApi printText:[[printOption objectAtIndex:0] objectForKey:@"PO_ReceiptFooter"]];
    [PosApi printText:@"\r\n"];
    [PosApi cutPaper];
    
    headerPart = nil;
    middlePart = nil;
    footerPart = nil;
    
}

+(void)createFlyTechKitchenReceiptWithDBPath:(NSString *)dbPath TableNo:(NSString *)tableNo ItemNo:(NSString *)itemName Qty:(NSString *)qty DataArray:(NSMutableArray *)array
{
    NSMutableString *textData = [[NSMutableString alloc] init];
    NSMutableString *textData2 = [[NSMutableString alloc] init];
    [textData appendString:[NSString stringWithFormat:@"Table No: %@\r\n",tableNo]];
    [textData appendString:[NSString stringWithFormat:@"%@\r\n",itemName]];
    
    
    if (array.count > 0) {
        //[textData appendString:[NSString stringWithFormat:@"%@\r\n",@"Condiment"]];
        [textData appendString:[NSString stringWithFormat:@"%@\r\n",qty]];
        for (int i = 0; i < array.count; i++) {
            if ([[[array objectAtIndex:i] objectForKey:@"PQ_OrderType"] isEqualToString:@"CondimentOrder"]) {
                [textData2 appendString:@"\r\n"];
                [textData2 appendString:[NSString stringWithFormat:@" - %@ %@\r\n",[[array objectAtIndex:i] objectForKey:@"PQ_ItemDesc"],[[array objectAtIndex:i] objectForKey:@"PQ_ItemQty"]]];
            }
            
        }
        
    }
    else
    {
        [textData appendString:[NSString stringWithFormat:@"%@",qty]];
    }
    
    [PosApi setPrinterSettings:CHARSET_GBK leftMargin:0 printAreaWidth:576 printQuality:8];
    [PosApi setPrintFont:PRINT_FONT_12x24];
    [PosApi setPrintCharacterScale:FONT_SCALE_VERTICAL_2 hScale:FONT_SCALE_HORIZONTAL_2];
    [PosApi setPrintFormat:ALIGNMENT_LEFT];
    [PosApi printText:textData];
    [PosApi setPrintCharacterScale:FONT_SCALE_VERTICAL_2 hScale:FONT_SCALE_HORIZONTAL_2];
    [PosApi setPrintFont:2];
    [PosApi printText:textData2];
    [PosApi cutPaper];
}

+(void)createFlyTechKitReceiptGroupWithOrderDetail:(NSMutableString *)orderDetail TableName:(NSString *)tableName
{
    //NSString *item = @"";
    //NSString *qty = @"";
    //int spaceAdd = 0;
    //NSString *tbName;
    //NSString *detail2;
    /*
    NSMutableString *mString2 = [[NSMutableString alloc]init];
    
    for (int i = 0; i<orderDetail.count; i++) {
        item = [[orderDetail objectAtIndex:i] objectForKey:@"IM_Description"];
        if ([item length] > 15) item = [item substringToIndex:14];
        qty = [NSString stringWithFormat:@"%0.2f",[[[orderDetail objectAtIndex:i] objectForKey:@"IM_Qty"] doubleValue]];
        
        [mString2 appendString:[NSString stringWithFormat:@"%@\n",item]];
        [mString2 appendString:[NSString stringWithFormat:@"Qty : %@\n\n",qty]];
        
    }
     */
    tableName = [NSString stringWithFormat:@"%@ : %@\n\n",@"Table No",tableName];
    
    [PosApi setPrinterSettings:CHARSET_GBK leftMargin:0 printAreaWidth:576 printQuality:8];
    [PosApi setPrintFont:PRINT_FONT_12x24];
    [PosApi setPrintCharacterScale:FONT_SCALE_VERTICAL_2 hScale:FONT_SCALE_HORIZONTAL_2];
    [PosApi setPrintFormat:ALIGNMENT_LEFT];
    [PosApi printText:tableName];
    [PosApi printText:orderDetail];
    [PosApi cutPaper];
}

//+(void)createFlyTechSalesOrderRceiptWithDBPath:(NSString *)dbPath GetInvNo:(NSString *)getSoNo EnableGst:(int)enableGST
+(void)createFlyTechSalesOrderReceiptWithComapnyArray:(NSMutableArray *)compArray SalesOrderArray:(NSMutableArray *)receiptArray EnableGst:(int)enableGST
{

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
    //spaceCount = (int)(38 - shopName.length)/2;
    
    shopName = [NSString stringWithFormat:@"%@",
                shopName];
    
    NSString *add1 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address1"]];
    //spaceCount = (int)(38 - add1.length)/2;
    
    add1 = [NSString stringWithFormat:@"%@",
            add1];
    
    NSString *add2 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address2"]];
    //spaceCount = (int)(38 - add2.length)/2;
    
    add2 = [NSString stringWithFormat:@"%@",
            add2];
    
    NSString *add3 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address3"]];
    //spaceCount = (int)(38 - add3.length)/2;
    
    add3 = [NSString stringWithFormat:@"%@",
            add3];
    
    NSString *tel = [NSString stringWithFormat:@"Tel : %@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Telephone"]];
    //spaceCount = (int)(38 - tel.length)/2;
    
    tel = [NSString stringWithFormat:@"%@",
           tel];
    
    NSString *gstNo = [NSString stringWithFormat:@"GST ID : %@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_GstNo"]];
    //spaceCount = (int)(38 - gstNo.length)/2;
    
    gstNo = [NSString stringWithFormat:@"%@",
             gstNo];
    
    NSString *invNo = [NSString stringWithFormat:@"SO : %@\r\n",[[receiptArray objectAtIndex:0] objectForKey:@"SOH_DocNo"]];
    spaceCount = (int)(38 - invNo.length)/2;
    
    invNo = [NSString stringWithFormat:@"%@",
             invNo];
    
    NSString *date = [NSString stringWithFormat:@"Date : %@",dateString];
    NSString *time = timeString;
    
    spaceCount = (int)(38 - date.length - time.length);
    NSString *dateTime;
    dateTime = [NSString stringWithFormat:@"%@%@%@\r\n\r\n",
                date,[@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
                time];
    //NSString *header = @"SALE                                  \r\n";
    NSString *header;
    //NSString *tableName;
    header = [NSString stringWithFormat:@"Table: %@    Pax: %@",[[receiptArray objectAtIndex:0] objectForKey:@"SOH_Table"],[[receiptArray objectAtIndex:0] objectForKey:@"SOH_PaxNo"]];
    spaceCount = (int)(38 - date.length - time.length);
    
    header = [NSString stringWithFormat:@"%@%@\r\n",
              header,[@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0]];
    
    NSString *title =    @"Item              Qty   Price    Total\r\n";
    NSString *dashline = @"--------------------------------------\r\n";
    
    NSString *item = @"";
    NSString *qty = @"";
    NSString *price = @"";
    NSString *itemTotal = @"";
    NSString *itemDesc2 = @"";
    NSUInteger spaceAdd = 0;
    double subTotalB4Gst = 0.00;
    
    NSString *detail2;
    NSString *detail3;
    NSString *detail4;
    NSMutableString *mString2 = [[NSMutableString alloc]init];
    
    for (int i = 0; i<receiptArray.count; i++) {
        if ([[[receiptArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"]) {
            if (enableGST == 0) {
                item = [[receiptArray objectAtIndex:i] objectForKey:@"ItemDesc2"];
            }
            else
            {
                if ([[[receiptArray objectAtIndex:i]objectForKey:@"Flag"] isEqualToString:@"-"]) {
                    item = [[receiptArray objectAtIndex:i] objectForKey:@"ItemDesc2"];
                }
                else
                {
                    item = [[receiptArray objectAtIndex:i] objectForKey:@"ItemDesc"];
                }
                
            }
            
            //item = [[receiptArray objectAtIndex:i] objectForKey:@"ItemDesc"];
            if ([item length] > 15) item = [item substringToIndex:15];
            qty = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:i] objectForKey:@"SOD_Quantity"] doubleValue]];
            if ([qty length] > 6) qty = [qty substringToIndex:6];
            price = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:i] objectForKey:@"SOD_UnitPrice"] doubleValue]];
            if ([price length] > 8) price = [price substringToIndex:8];
            itemTotal = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:i] objectForKey:@"SOD_SubTotal"] doubleValue]];
            if ([itemTotal length] > 9) itemTotal = [itemTotal substringToIndex:9];
            
            subTotalB4Gst = subTotalB4Gst + [[[receiptArray objectAtIndex:i] objectForKey:@"SOD_TotalEx"] doubleValue];
            
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
            itemDesc2 = [[receiptArray objectAtIndex:i] objectForKey:@"IM_Description2"];
            [mString2 appendString:[NSString stringWithFormat:@"%@%@%@%@\n",detail1,detail2,detail3,detail4]];
            
            if ([itemDesc2 length] > 0) {
                [mString2 appendString:[NSString stringWithFormat:@"%@\n",itemDesc2]];
            }
        }
        else
        {
            item = [NSString stringWithFormat:@" - %@",[[receiptArray objectAtIndex:i] objectForKey:@"SOC_CDDescription"]];
            
            
            if ([item length] > 15) item = [item substringToIndex:15];
                spaceAdd = 15 - item.length;
            
            qty = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:i] objectForKey:@"SOC_CDQty"] doubleValue]];
            if ([qty length] > 6) qty = [qty substringToIndex:6];
            
            
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
        
    }
    
    NSString *footer;
    NSString *footerTitle;
    
    footer = [NSString stringWithFormat:@"%0.2f",subTotalB4Gst];
    footerTitle = @"SubTotal Exclude GST";
    NSString *subTotalEx = [NSString stringWithFormat:@"%@%@%@\r\n",
                            footerTitle,
                            [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"SOH_DocSubTotal"] doubleValue]];
    footerTitle = @"SubTotal";
    NSString *subTotal = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"SOH_DiscAmt"] doubleValue]];
    footerTitle = @"Discount";
    NSString *discount = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"SOH_DocServiceTaxAmt"] doubleValue]];
    footerTitle = @"Service Charge";
    NSString *svc = [NSString stringWithFormat:@"%@%@%@\r\n",
                     footerTitle,
                     [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"SOH_DocTaxAmt"] doubleValue]];
    footerTitle = @"Total GST";
    NSString *gst = [NSString stringWithFormat:@"%@%@%@\r\n",
                     footerTitle,
                     [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"SOH_Rounding"] doubleValue]];
    footerTitle = @"Rounding";
    NSString *rounding = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"SOH_DocAmt"] doubleValue]];
    footerTitle = @"Total";
    NSString *granTotal = [NSString stringWithFormat:@"%@%@%@\r\n",
                           footerTitle,
                           [@" " stringByPaddingToLength:19-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    //[textData appendString:eposSection1];
    
    NSMutableString *headerPart = [[NSMutableString alloc] init];
    NSMutableString *middlePart = [[NSMutableString alloc] init];
    NSMutableString *footerPart = [[NSMutableString alloc] init];
    
    [headerPart appendString:shopName];
    [headerPart appendString:add1];
    [headerPart appendString:add2];
    
    if (![add3 isEqualToString:@"\r\n"]) {
        [headerPart appendString:add3];
    }
    
    [headerPart appendString:tel];
    [headerPart appendString:gstNo];
    [headerPart appendString:invNo];
    
    [middlePart appendString:dateTime];
    [middlePart appendString:header];
    [middlePart appendString:title];
    [middlePart appendString:dashline];
    [middlePart appendString:mString2];
    
    [footerPart appendString:dashline];
    [footerPart appendString:subTotalEx];
    [footerPart appendString:subTotal];
    [footerPart appendString:discount];
    [footerPart appendString:svc];
    [footerPart appendString:gst];
    [footerPart appendString:rounding];
    //[footerPart appendString:granTotal];
    
    //[PosApi initPrinter];
    [PosApi setPrinterSettings:CHARSET_GBK leftMargin:0 printAreaWidth:576 printQuality:8];
    [PosApi setPrintFont:PRINT_FONT_12x24];
    [PosApi setPrintFormat:ALIGNMENT_CENTERD];
    [PosApi printText:headerPart];
    [PosApi setPrintFormat:ALIGNMENT_LEFT];
    [PosApi printText:middlePart];
    [PosApi printText:footerPart];
    [PosApi setPrintCharacterScale:FONT_SCALE_VERTICAL_2 hScale:FONT_SCALE_HORIZONTAL_2];
    [PosApi printText:granTotal];
    
    [PosApi cutPaper];
    headerPart = nil;
    footerPart = nil;
    middlePart = nil;
    
    
}
/*
+(void)terminalCreateFlyTechSalesOrderRceiptWithDBPath:(NSString *)dbPath soArray:(NSMutableArray *)soDetail EnableGst:(int)enableGST
{
    NSMutableArray *compArray = [[NSMutableArray alloc]init];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rsCompany = [db executeQuery:@"Select * from Company"];
        while ([rsCompany next]) {
            [compArray addObject:[rsCompany resultDictionary]];
        }
        
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
    //spaceCount = (int)(38 - shopName.length)/2;
    
    shopName = [NSString stringWithFormat:@"%@",
                shopName];
    
    NSString *add1 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address1"]];
    //spaceCount = (int)(38 - add1.length)/2;
    
    add1 = [NSString stringWithFormat:@"%@",
            add1];
    
    NSString *add2 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address2"]];
    //spaceCount = (int)(38 - add2.length)/2;
    
    add2 = [NSString stringWithFormat:@"%@",
            add2];
    
    NSString *add3 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address3"]];
    //spaceCount = (int)(38 - add3.length)/2;
    
    add3 = [NSString stringWithFormat:@"%@",
            add3];
    
    NSString *tel = [NSString stringWithFormat:@"Tel : %@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Telephone"]];
    //spaceCount = (int)(38 - tel.length)/2;
    
    tel = [NSString stringWithFormat:@"%@",
           tel];
    
    NSString *gstNo = [NSString stringWithFormat:@"GST ID : %@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_GstNo"]];
    //spaceCount = (int)(38 - gstNo.length)/2;
    
    gstNo = [NSString stringWithFormat:@"%@",
             gstNo];
    
    NSString *invNo = [NSString stringWithFormat:@"SO : %@\r\n",[[soDetail objectAtIndex:0] objectForKey:@"SOH_DocNo"]];
    spaceCount = (int)(38 - invNo.length)/2;
    
    invNo = [NSString stringWithFormat:@"%@",
             invNo];
    
    NSString *date = [NSString stringWithFormat:@"Date : %@",dateString];
    NSString *time = timeString;
    
    spaceCount = (int)(38 - date.length - time.length);
    NSString *dateTime;
    dateTime = [NSString stringWithFormat:@"%@%@%@\r\n\r\n",
                date,[@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
                time];
    //NSString *header = @"SALE                                  \r\n";
    NSString *header;
    //NSString *tableName;
    header = [NSString stringWithFormat:@"SALE Table:%@",[[soDetail objectAtIndex:0] objectForKey:@"SOH_Table"]];
    spaceCount = (int)(38 - date.length - time.length);
    
    header = [NSString stringWithFormat:@"%@%@\r\n",
              header,[@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0]];
    
    NSString *title =    @"Item              Qty   Price    Total\r\n";
    NSString *dashline = @"--------------------------------------\r\n";
    
    NSString *item = @"";
    NSString *qty = @"";
    NSString *price = @"";
    NSString *itemTotal = @"";
    NSString *itemDesc2 = @"";
    int spaceAdd = 0;
    double subTotalB4Gst = 0.00;
    
    NSString *detail2;
    NSString *detail3;
    NSString *detail4;
    NSMutableString *mString2 = [[NSMutableString alloc]init];
    
    for (int i = 0; i<soDetail.count; i++) {
        
        if (enableGST == 0) {
            item = [[soDetail objectAtIndex:i] objectForKey:@"ItemDesc2"];
        }
        else
        {
            if ([[[soDetail objectAtIndex:i]objectForKey:@"Flag"] isEqualToString:@"-"]) {
                item = [[soDetail objectAtIndex:i] objectForKey:@"ItemDesc2"];
            }
            else
            {
                item = [[soDetail objectAtIndex:i] objectForKey:@"ItemDesc"];
            }
            
        }
        
        //item = [[receiptArray objectAtIndex:i] objectForKey:@"ItemDesc"];
        if ([item length] > 15) item = [item substringToIndex:15];
        qty = [NSString stringWithFormat:@"%0.2f",[[[soDetail objectAtIndex:i] objectForKey:@"SOD_Quantity"] doubleValue]];
        if ([qty length] > 6) qty = [qty substringToIndex:6];
        price = [NSString stringWithFormat:@"%0.2f",[[[soDetail objectAtIndex:i] objectForKey:@"SOD_Price"] doubleValue]];
        if ([price length] > 8) price = [price substringToIndex:8];
        itemTotal = [NSString stringWithFormat:@"%0.2f",[[[soDetail objectAtIndex:i] objectForKey:@"SOD_SubTotal"] doubleValue]];
        if ([itemTotal length] > 9) itemTotal = [itemTotal substringToIndex:9];
        
        subTotalB4Gst = subTotalB4Gst + [[[soDetail objectAtIndex:i] objectForKey:@"SOD_TotalEx"] doubleValue];
        
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
        itemDesc2 = [[soDetail objectAtIndex:i] objectForKey:@"IM_Description2"];
        [mString2 appendString:[NSString stringWithFormat:@"%@%@%@%@\n",detail1,detail2,detail3,detail4]];
        
        if ([itemDesc2 length] > 0) {
            [mString2 appendString:[NSString stringWithFormat:@"%@\n",itemDesc2]];
        }
        
        //[mString2 appendString:[NSString stringWithFormat:@"%@\n",itemDesc2]];
        
    }
    
    NSString *footer;
    NSString *footerTitle;
    
    footer = [NSString stringWithFormat:@"%0.2f",subTotalB4Gst];
    footerTitle = @"SubTotal Exlude GST";
    NSString *subTotalEx = [NSString stringWithFormat:@"%@%@%@\r\n",
                            footerTitle,
                            [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[soDetail objectAtIndex:0] objectForKey:@"SOH_DocSubTotal"] doubleValue]];
    footerTitle = @"SubTotal";
    NSString *subTotal = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[soDetail objectAtIndex:0] objectForKey:@"SOH_DiscAmt"] doubleValue]];
    footerTitle = @"Discount";
    NSString *discount = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[soDetail objectAtIndex:0] objectForKey:@"SOH_DocServiceTaxAmt"] doubleValue]];
    footerTitle = @"Service Charge";
    NSString *svc = [NSString stringWithFormat:@"%@%@%@\r\n",
                     footerTitle,
                     [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[soDetail objectAtIndex:0] objectForKey:@"SOH_DocTaxAmt"] doubleValue]];
    footerTitle = @"Total GST";
    NSString *gst = [NSString stringWithFormat:@"%@%@%@\r\n",
                     footerTitle,
                     [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[soDetail objectAtIndex:0] objectForKey:@"SOH_Rounding"] doubleValue]];
    footerTitle = @"Rounding";
    NSString *rounding = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[soDetail objectAtIndex:0] objectForKey:@"SOH_DocAmt"] doubleValue]];
    footerTitle = @"Total";
    NSString *granTotal = [NSString stringWithFormat:@"%@%@%@\r\n",
                           footerTitle,
                           [@" " stringByPaddingToLength:19-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    //[textData appendString:eposSection1];
    
    NSMutableString *headerPart = [[NSMutableString alloc] init];
    NSMutableString *middlePart = [[NSMutableString alloc] init];
    NSMutableString *footerPart = [[NSMutableString alloc] init];
    
    [headerPart appendString:shopName];
    [headerPart appendString:add1];
    [headerPart appendString:add2];
    [headerPart appendString:add3];
    [headerPart appendString:tel];
    [headerPart appendString:gstNo];
    [headerPart appendString:invNo];
    
    [middlePart appendString:dateTime];
    [middlePart appendString:header];
    [middlePart appendString:title];
    [middlePart appendString:dashline];
    [middlePart appendString:mString2];
    
    [footerPart appendString:dashline];
    [footerPart appendString:subTotalEx];
    [footerPart appendString:subTotal];
    [footerPart appendString:discount];
    [footerPart appendString:svc];
    [footerPart appendString:gst];
    [footerPart appendString:rounding];
    
    [PosApi setPrinterSettings:CHARSET_USA leftMargin:0 printAreaWidth:576 printQuality:8];
    [PosApi setPrintFont:PRINT_FONT_12x24];
    [PosApi setPrintFormat:ALIGNMENT_CENTERD];
    [PosApi printText:headerPart];
    [PosApi setPrintFormat:ALIGNMENT_LEFT];
    [PosApi printText:middlePart];
    [PosApi printText:footerPart];
    [PosApi setPrintCharacterScale:FONT_SCALE_VERTICAL_2 hScale:FONT_SCALE_HORIZONTAL_2];
    [PosApi printText:granTotal];
    
    [PosApi cutPaper];
    headerPart = nil;
    footerPart = nil;
    middlePart = nil;

    
}
*/

+(NSMutableData *)createDailyCollectionWithDbPath:(NSString *)dbPath DateFrom:(NSString *)dateFrom DateTo:(NSString *)dateTo PrinterBrand:(NSString *)printerBrand
{
    //NSMutableString *textData = [[NSMutableString alloc] init];
    /*
    NSMutableArray *cashArray = [[NSMutableArray alloc]init];
    NSMutableArray *masterArray = [[NSMutableArray alloc]init];
    NSMutableArray *visaArray = [[NSMutableArray alloc]init];
    NSMutableArray *debitArray = [[NSMutableArray alloc] init];
    NSMutableArray *amexArray = [[NSMutableArray alloc] init];
    NSMutableArray *unionArray = [[NSMutableArray alloc] init];
    NSMutableArray *dinerArray = [[NSMutableArray alloc] init];
    NSMutableArray *voucherArray = [[NSMutableArray alloc] init];
    */
    
    NSMutableArray *payArray = [[NSMutableArray alloc] init];
    
    NSMutableArray *compArray = [[NSMutableArray alloc]init];
    
    NSMutableArray *paymentTypeArray = [[NSMutableArray alloc]init];
    NSMutableArray *sumTotalArray = [[NSMutableArray alloc]init];
    /*
    [masterArray removeAllObjects];
    [cashArray removeAllObjects];
    [visaArray removeAllObjects];
    [debitArray removeAllObjects];
    [amexArray removeAllObjects];
    [unionArray removeAllObjects];
    [dinerArray removeAllObjects];
    [voucherArray removeAllObjects];
     */
    [payArray removeAllObjects];
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
        
        double totalChange = 0.00;
        NSString *actualAmt;
        
        FMResultSet *rsChange = [db executeQuery:@"Select sum(IvH_ChangeAmt) as TotalChange from InvoiceHdr where date(IvH_Date) between date(?) and date(?) ",dateFrom,dateTo];
        
        if ([rsChange next]) {
            totalChange = [rsChange doubleForColumn:@"TotalChange"];
        }
        else
        {
            totalChange = 0.00;
        }
        [rsChange close];
        
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
                               " union "
                               "select count(*) qty, IvH_PaymentType8 as Type, sum(IvH_PaymentAmt8) Amt from InvoiceHdr where date(IvH_Date) between date(?) and date(?) and IvH_PaymentType8 = ? group by Ivh_PaymentType8 "
                               ") where Type != ''  group by Type",dateFrom,dateTo,[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"],dateFrom,dateTo,[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"],dateFrom,dateTo,[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"],dateFrom,dateTo,[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"],dateFrom,dateTo,[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"],dateFrom,dateTo,[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"],dateFrom,dateTo,[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"],dateFrom,dateTo,[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"]];
            
            if ([rs next]) {
                
                if ([[rs stringForColumn:@"Type"] isEqualToString:@"Cash"]) {
                    actualAmt = [NSString stringWithFormat:@"%0.2f",[rs doubleForColumn:@"amt"] - totalChange];
                }
                else
                {
                    actualAmt = [NSString stringWithFormat:@"%0.2f",[rs doubleForColumn:@"amt"]];
                }
                
                //[payArray addObject:[rs resultDictionary]];
                
                NSMutableDictionary *paymentData = [NSMutableDictionary dictionary];
                
                [paymentData setObject:[rs stringForColumn:@"qty"] forKey:@"qty"];
                [paymentData setObject:[rs stringForColumn:@"Type"] forKey:@"Type"];
                [paymentData setObject:actualAmt forKey:@"amt"];
                
                [payArray addObject:paymentData];
                paymentData = nil;
                
                /*
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
                 */
                
            }
            
            [rs close];
        }
        
        FMResultSet *rsTotal = [db executeQuery:@"select sum(IvH_DocAmt) DocAmt, sum(IvH_DiscAmt) DocDisAmt, sum(IvH_DoctaxAmt) DocTaxAmt,IvH_Status  from InvoiceHdr where date(IvH_Date) between date(?) and date(?) and IvH_Status = ? group by IvH_Status ",dateFrom,dateTo,@"Pay"];
        
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
        
        
        //[dbTable close];
        
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
    //spaceCount = (int)(38 - shopName.length)/2;
    
    shopName = [NSString stringWithFormat:@"%@",
                shopName];
    
    NSString *add1 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address1"]];
    //spaceCount = (int)(38 - add1.length)/2;
    
    add1 = [NSString stringWithFormat:@"%@",
            add1];
    
    NSString *add2 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address2"]];
    //spaceCount = (int)(38 - add2.length)/2;
    
    add2 = [NSString stringWithFormat:@"%@",
            add2];
    
    NSString *add3 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address3"]];
    //spaceCount = (int)(38 - add3.length)/2;
    
    add3 = [NSString stringWithFormat:@"%@",
            add3];
    
    NSString *tel = [NSString stringWithFormat:@"Tel : %@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Telephone"]];
    //spaceCount = (int)(38 - tel.length)/2;
    
    tel = [NSString stringWithFormat:@"%@",
           tel];
    
    NSString *salesDate = [NSString stringWithFormat:@"%@ to %@\r\n",dateFrom, dateTo];
    //spaceCount = (int)(38 - add2.length)/2;
    
    salesDate = [NSString stringWithFormat:@"Sales Date : %@",
                 salesDate];
    
    NSString *date = [NSString stringWithFormat:@"Date : %@",dateString];
    NSString *time = timeString;
    
    spaceCount = (int)(38 - date.length - time.length);
    NSString *dateTime;
    dateTime = [NSString stringWithFormat:@"%@%@%@\r\n\r\n",
                date,[@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
                time];
    
    NSString *title = @"Daily Collection\r\n";
    NSString *dashline = @"--------------------------------------\r\n";
    /*
    NSString *masterTrans = @"Master TRANSACTION            \r\n";
    NSString *cashTrans = @"Cash TRANSACTION                \r\n";
    NSString *visaTrans = @"Visa TRANSACTION                \r\n";
    NSString *debitTrans = @"Debit TRANSACTION              \r\n";
    
    NSString *amexTrans = @"Amex TRANSACTION                \r\n";
    NSString *unionTrans = @"UnionPay TRANSACTION           \r\n";
    NSString *dinerTrans = @"Diners TRANSACTION             \r\n";
    NSString *voucherTrans = @"Voucher TRANSACTION          \r\n";
    
    NSString *cashAmt;
    NSString *visaAmt;
    NSString *debitAmt;
    NSString *amexAmt;
    NSString *unionAmt;
    NSString *dinerAmt;
    NSString *voucherAmt;
     */
    //NSString *displayPayType;
    
    NSString *middle;
    NSString *middleTitle;
    NSString *autoTitle;
    NSString *autoContent;
    NSMutableString *autoMiddlePart = [[NSMutableString alloc] init];
    
    for (int i = 0; i < paymentTypeArray.count; i++) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"Type MATCHES[cd] %@",
                                  [[paymentTypeArray objectAtIndex:i] objectForKey:@"PT_Code"]];
        
        NSArray * selectedObject = [payArray filteredArrayUsingPredicate:predicate];
        
        if (selectedObject.count > 0) {
            NSUInteger indexOfArray = 0;
            indexOfArray = [payArray indexOfObject:selectedObject[0]];
            //displayPayType = [[payArray objectAtIndex:indexOfArray] objectForKey:@"Type"];
            autoTitle = [NSString stringWithFormat:@"%@%@",[[payArray objectAtIndex:indexOfArray] objectForKey:@"Type"],@" TRANSACTION            \r\n"];
            middle = [NSString stringWithFormat:@"%0.2f",[[[payArray objectAtIndex:indexOfArray] objectForKey:@"amt"] doubleValue]];
            middleTitle = [NSString stringWithFormat:@"SALES (%@)", [[payArray objectAtIndex:indexOfArray] objectForKey:@"qty"]];
            autoContent = [NSString stringWithFormat:@"%@%@%@\r\n",
                         middleTitle,
                         [@" " stringByPaddingToLength:38-middleTitle.length-middle.length withString:@" " startingAtIndex:0],middle];
            
            //[self manualDidSelectCollectionViewWithIndexNo:indexOfArray];
        }
        else
        {
           // displayPayType =[[paymentTypeArray objectAtIndex:i] objectForKey:@"PT_Code"];
            autoTitle = [NSString stringWithFormat:@"%@%@",[[paymentTypeArray objectAtIndex:i] objectForKey:@"PT_Code"],@" TRANSACTION            \r\n"];
            middle = [NSString stringWithFormat:@"%@",@"0.00"];
            middleTitle = [NSString stringWithFormat:@"SALES (%@)", @"0"];
            autoContent = [NSString stringWithFormat:@"%@%@%@\r\n",
                         middleTitle,
                         [@" " stringByPaddingToLength:38-middleTitle.length-middle.length withString:@" " startingAtIndex:0],middle];
            
            //[self manualDidSelectCollectionViewWithIndexNo:0];
        }
        [autoMiddlePart appendString:autoTitle];
        [autoMiddlePart appendString:autoContent];
        [autoMiddlePart appendString:@"\r\n"];
        selectedObject = nil;
    }
    
    /*
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
    
    //--------- cash trans --------------
    
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
    
    //-------visa trans -----------------
    
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
    
    //-------debit trans -----------------
    
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
    
    //-------amex trans -----------------
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
    
    //-------union trans -----------------
    
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
    
    //-------diner trans -----------------
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
    
    
    //-------voucher trans -----------------
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
    */
    
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
    
    NSMutableString *headerPart = [[NSMutableString alloc] init];
    NSMutableString *middlePart = [[NSMutableString alloc] init];
    NSMutableString *footerPart = [[NSMutableString alloc] init];
    
    [headerPart appendString:shopName];
    [headerPart appendString:add1];
    [headerPart appendString:add2];
    if (![add3 isEqualToString:@"\r\n"]) {
        [headerPart appendString:add3];
    }
    [headerPart appendString:tel];
    [headerPart appendString:salesDate];
    [headerPart appendString:@"\r\n"];
    [middlePart appendString:dateTime];
    [middlePart appendString:title];
    [middlePart appendString:dashline];
    [middlePart appendString:@"\r\n"];
    /*
    [middlePart appendString:cashTrans];
    [middlePart appendString:cashAmt];
    [middlePart appendString:@"\r\n"];
    [middlePart appendString:masterTrans];
    [middlePart appendString:masterAmt];
    [middlePart appendString:@"\r\n"];
    [middlePart appendString:visaTrans];
    [middlePart appendString:visaAmt];
    [middlePart appendString:@"\r\n"];
    [middlePart appendString:debitTrans];
    [middlePart appendString:debitAmt];
    [middlePart appendString:@"\r\n"];
    [middlePart appendString:amexTrans];
    [middlePart appendString:amexAmt];
    [middlePart appendString:@"\r\n"];
    [middlePart appendString:unionTrans];
    [middlePart appendString:unionAmt];
    [middlePart appendString:@"\r\n"];
    [middlePart appendString:dinerTrans];
    [middlePart appendString:dinerAmt];
    [middlePart appendString:@"\r\n"];
    [middlePart appendString:voucherTrans];
    [middlePart appendString:voucherAmt];
     */
    [middlePart appendString:autoMiddlePart];
    [middlePart appendString:dashline];
    [middlePart appendString:totalAmt];
    [middlePart appendString:dashline];
    [footerPart appendString:@"\r\n"];
    [footerPart appendString:@"SUMMARY:\r\n"];
    [footerPart appendString:dashline];
    [footerPart appendString:totalSales];
    [footerPart appendString:discountAmt];
    [footerPart appendString:taxAmt];
    [footerPart appendString:totalVoidSales];
    [footerPart appendString:@"\r\n\r\n"];
    
    compArray = nil;
    //masterArray = nil;
    //visaArray = nil;
    //cashArray = nil;
    //debitArray = nil;
    //amexAmt = nil;
    //unionArray = nil;
    //dinerArray = nil;
    
    sumTotalArray = nil;
    payArray = nil;
    paymentTypeArray = nil;
    
    if ([printerBrand isEqualToString:@"FlyTech"]) {
        [PosApi initPrinter];
        [PosApi setPrinterSettings:CHARSET_USA leftMargin:0 printAreaWidth:576 printQuality:8];
        [PosApi setPrintFont:PRINT_FONT_12x24];
        
        [PosApi setPrintFormat:ALIGNMENT_CENTERD];
        [PosApi printText:headerPart];
        
        [PosApi setPrintFormat:ALIGNMENT_LEFT];
        [PosApi printText:middlePart];
        [PosApi printText:footerPart];
        
        [PosApi cutPaper];
        headerPart = nil;
        middlePart = nil;
        footerPart = nil;
        return nil;
    }
    else
    {
        NSMutableData *commands = [NSMutableData data];
        [commands appendData:[PosCommand selectCharacterCodePage:0]];
        [commands appendData:[PosCommand selectAlignment:1]]; //align center
        [commands appendData:[PosCommand selectFont:2]];
        
        //[commands appendData:[headerPart dataUsingEncoding:NSASCIIStringEncoding]];
        [commands appendData:[headerPart dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
        [commands appendData:[PosCommand selectAlignment:0]]; //align left
        [commands appendData:[middlePart dataUsingEncoding:NSASCIIStringEncoding]];
        [commands appendData:[footerPart dataUsingEncoding:NSASCIIStringEncoding]];
        [commands appendData:[PosCommand printAndFeedLine]];
        [commands appendData:[PosCommand printAndFeedLine]];
        [commands appendData:[PosCommand printAndFeedLine]];
        [commands appendData:[PosCommand printAndFeedLine]];
        [commands appendData:[PosCommand printAndFeedLine]];
        [commands appendData:[PosCommand selectCutPageModelAndCutpage:0]];
        
        return commands;
    }
    
    
    

}

#pragma mark - Generate general Receipt format

+(NSMutableData *)generateReceiptFormatWithComapnyArray:(NSMutableArray *)compArray ReceiptArray:(NSMutableArray *)receiptArray EnableGst:(int)enableGST KickOutDrawerYN:(NSString *)kickOutDraweYN PrinterBrand:(NSString *)printerBrand ReceiptLength:(int)receiptLength GstArray:(NSMutableArray *)gstArray PrintOptionArray:(NSMutableArray *)printOptionArray PrintType:(NSString *)printType
{
    NSDate *docDate;
    NSDateFormatter *docDateFormat = [[NSDateFormatter alloc] init];
    
    if ([printType isEqualToString:@"ReprintReceipt"]) {
        [docDateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        docDate = [docDateFormat dateFromString:[[receiptArray objectAtIndex:0] objectForKey:@"IvH_Date"]];
    }
    else
    {
        docDate = [NSDate date];
    }
    
    //NSDate *today = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    NSString *dateString = [dateFormat stringFromDate:docDate];
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
    NSString *timeString = [timeFormat stringFromDate:docDate];
    
    int spaceCount = 0;
    
    
    NSString *shopName = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Company"]];
    NSString *add1 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address1"]];
    NSString *add2 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address2"]];
    NSString *add3 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address3"]];
    NSString *tel = [NSString stringWithFormat:@"Tel : %@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Telephone"]];
    NSString *gstNo = [NSString stringWithFormat:@"GST ID : %@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_GstNo"]];
    NSString *invNo = [NSString stringWithFormat:@"Receipt : %@\r\n",[[receiptArray objectAtIndex:0] objectForKey:@"IvH_DocNo"]];
    NSString *regNo = [NSString stringWithFormat:@"(%@)\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_RegistrationNo"]];
    //NSString *gstTitle = @"Tax Invoice\r\n";
    NSString *gstTitle = [NSString stringWithFormat:@"\r\n%@\r\n\r\n",[[printOptionArray objectAtIndex:0] objectForKey:@"PO_ReceiptHeader"]];
    
    //spaceCount = (int)(38 - invNo.length)/2;
    NSString *date = [NSString stringWithFormat:@"Date : %@",dateString];
    NSString *time = timeString;
    
    spaceCount = (int)(receiptLength - date.length - time.length);
    NSString *dateTime;
    dateTime = [NSString stringWithFormat:@"%@%@%@\r\n\r\n",
                date,[@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
                time];
    
    NSString *header;
    NSString *headerP1;
    NSString *headerP2;
    
    headerP1 = [NSString stringWithFormat:@"Table: %@",[[receiptArray objectAtIndex:0] objectForKey:@"IvH_Table"]];
    headerP2 = [NSString stringWithFormat:@"Pax: %@",[[receiptArray objectAtIndex:0] objectForKey:@"IvH_Table"]];
    
    spaceCount = (int)(receiptLength - [headerP1 length] - [headerP2 length]);
    
    header = [NSString stringWithFormat:@"%@%@%@\r\n\r\n",
              headerP1,[@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
              headerP2];
    
    NSString *title1 =    @"Item                        Qty   Price    Total\r\n";
    //NSString *currencyLine1 = [NSString stringWithFormat:@"                                  (%@)         \r\n",[[LibraryAPI sharedInstance] getCurrencySymbol]];
    
    NSString *title2 =    @"Item               Qty   Price     Disc    Total\r\n";
    //NSString *currencyLine2 = [NSString stringWithFormat:@"                          (%@)     (%@)\r\n",[[LibraryAPI sharedInstance] getCurrencySymbol],[[LibraryAPI sharedInstance] getCurrencySymbol]];
    
    NSString *dashline = @"------------------------------------------------\r\n";
    
    NSString *item = @"";
    NSString *qty = @"";
    NSString *price = @"";
    NSString *disc = @"";
    NSString *itemTotal = @"";
    NSString *itemDesc2 = @"";
    double subTotalB4Gst = 0.00;
    double gstTotalSalesTax = 0.00;
    long spaceAdd = 0;
    
    spaceAdd = 5 - [[NSString stringWithFormat:@"(%@)",[[LibraryAPI sharedInstance] getCurrencySymbol]] length];
    NSString *currency = [NSString stringWithFormat:@"%@%@",
                          [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0],
                          [NSString stringWithFormat:@"(%@)",[[LibraryAPI sharedInstance] getCurrencySymbol]]];
    
    
    NSString *currencyLine2 = [NSString stringWithFormat:@"%@%@%@%@\r\n",
                               [@" " stringByPaddingToLength:25 withString:@" " startingAtIndex:0],
                               currency,[@" " stringByPaddingToLength:4 withString:@" " startingAtIndex:0],currency];
    
    NSString *currencyLine1 = [NSString stringWithFormat:@"%@%@\r\n",
                            [@" " stringByPaddingToLength:34 withString:@" " startingAtIndex:0],
                            currency];
    
    NSString *detail2;
    NSString *detail3;
    NSString *detail4;
    NSString *detail5;
    
    NSMutableString *mString2 = [[NSMutableString alloc]init];
    NSMutableString *paymentTypeString = [[NSMutableString alloc]init];
    NSMutableString *gstSummaryString = [[NSMutableString alloc]init];
    NSMutableString *customerInfo = [[NSMutableString alloc] init];
    NSUInteger defaultSpace1 = 0;
    NSUInteger defaultSpace2 = 0;
    
    for (int i = 0; i<receiptArray.count; i++) {
        if ([[[receiptArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"])
        {
            if (enableGST == 0) {
                item = [[receiptArray objectAtIndex:i] objectForKey:@"ItemDesc2"];
            }
            else
            {
                if ([[[receiptArray objectAtIndex:i]objectForKey:@"Flag"] isEqualToString:@"-"]) {
                    item = [[receiptArray objectAtIndex:i] objectForKey:@"ItemDesc2"];
                }
                else
                {
                    item = [[receiptArray objectAtIndex:i] objectForKey:@"ItemDesc"];
                }
                
            }
            subTotalB4Gst = subTotalB4Gst + [[[receiptArray objectAtIndex:i] objectForKey:@"IvD_TotalEx"] doubleValue];
            
            gstTotalSalesTax = gstTotalSalesTax + [[[receiptArray objectAtIndex:i] objectForKey:@"IvD_TotalSalesTax"] doubleValue];
            
            if (receiptLength == 48) {
                if ([[[printOptionArray objectAtIndex:0] objectForKey:@"PO_ReceiptContent"] integerValue] == 0) {
                    if ([item length] > 25) item = [item substringToIndex:25];
                    defaultSpace1 = 25;
                }
                else
                {
                    if ([item length] > 16) item = [item substringToIndex:16];
                    defaultSpace1 = 16;
                }
                
            }
            else
            {
                if ([item length] > 15) item = [item substringToIndex:15];
                defaultSpace1 = 15;
            }
            
            qty = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:i] objectForKey:@"IvD_Quantity"] doubleValue]];
            if ([qty length] > 6) qty = [qty substringToIndex:6];
            
            price = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:i] objectForKey:@"IvD_UnitPrice"] doubleValue]];
            if ([price length] > 8) price = [price substringToIndex:8];
            
            itemTotal = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:i] objectForKey:@"IvD_SubTotal"] doubleValue] - [[[receiptArray objectAtIndex:i] objectForKey:@"IvD_TotalDisc"] doubleValue]];
            if ([itemTotal length] > 9) itemTotal = [itemTotal substringToIndex:9];
            
            disc = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:i] objectForKey:@"IvD_TotalDisc"] doubleValue]];
            if ([disc length] > 9) disc = [disc substringToIndex:9];
            
            spaceAdd = defaultSpace1 - item.length;
            NSString *detail1 = [NSString stringWithFormat:@"%@%@",
                                 item,
                                 [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0]];
            
            detail1 = [PublicMethod processChineseOrEnglishCharWithDetail1:detail1 ItemDesc:item FixLength:defaultSpace1];
            
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
            
            
            spaceAdd = 9 - disc.length;
            if (spaceAdd > 0) {
                detail5 = [NSString stringWithFormat:@"%@%@",
                           [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0],
                           disc];
            }
            
            
            itemDesc2 = [[receiptArray objectAtIndex:i] objectForKey:@"IM_Description2"];
            
            if ([[[printOptionArray objectAtIndex:0] objectForKey:@"PO_ReceiptContent"] integerValue] == 0) {
                [mString2 appendString:[NSString stringWithFormat:@"%@%@%@%@\n",detail1,detail2,detail3,detail4]];
            }
            else
            {
                [mString2 appendString:[NSString stringWithFormat:@"%@%@%@%@%@\n",detail1,detail2,detail3,detail5,detail4]];
            }
            
            if ([[[printOptionArray objectAtIndex:0] objectForKey:@"PO_ShowItemDescription2"] integerValue] == 1)
            {
                if ([itemDesc2 length] > 0) {
                    [mString2 appendString:[NSString stringWithFormat:@"%@\n",itemDesc2]];
                }
            }
            

        }
        else if([[[receiptArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"PackageItemOrder"])
        {
            item = [NSString stringWithFormat:@" - %@",[[receiptArray objectAtIndex:i] objectForKey:@"IvD_ItemDescription"]];
            
            if (receiptLength == 48) {
                if ([[[printOptionArray objectAtIndex:0] objectForKey:@"PO_ReceiptContent"] integerValue] == 0) {
                    if ([item length] > 25) item = [item substringToIndex:25];
                    defaultSpace2 = 25;
                }
                else
                {
                    if ([item length] > 16) item = [item substringToIndex:16];
                    defaultSpace2 = 16;
                }
                
            }
            else
            {
                if ([item length] > 15) item = [item substringToIndex:15];
                defaultSpace2 = 15;
            }
            
            
            qty = @"1.00";
            if ([qty length] > 6) qty = [qty substringToIndex:6];
            
            spaceAdd = defaultSpace2 - item.length;
            NSString *detail1 = [NSString stringWithFormat:@"%@%@",
                                 item,
                                 [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0]];
            
            detail1 = [PublicMethod processChineseOrEnglishCharWithDetail1:detail1 ItemDesc:item FixLength:defaultSpace2];
            
            spaceAdd = 6 - qty.length;
            if (spaceAdd > 0) {
                detail2 = [NSString stringWithFormat:@"%@%@",
                           [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0],
                           qty];
            }
            [mString2 appendString:[NSString stringWithFormat:@"%@%@\n",detail1,detail2]];
        }
        else
        {
            item = [NSString stringWithFormat:@" - - %@",[[receiptArray objectAtIndex:i] objectForKey:@"IVC_CDDescription"]];
            
            if (receiptLength == 48) {
                if ([[[printOptionArray objectAtIndex:0] objectForKey:@"PO_ReceiptContent"] integerValue] == 0) {
                    if ([item length] > 25) item = [item substringToIndex:25];
                    defaultSpace2 = 25;
                }
                else
                {
                    if ([item length] > 16) item = [item substringToIndex:16];
                    defaultSpace2 = 16;
                }
                
            }
            else
            {
                if ([item length] > 15) item = [item substringToIndex:15];
                defaultSpace2 = 15;
            }
            
            
            qty = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:i] objectForKey:@"IVC_CDQty"] doubleValue]];
            if ([qty length] > 6) qty = [qty substringToIndex:6];
            
            spaceAdd = defaultSpace2 - item.length;
            NSString *detail1 = [NSString stringWithFormat:@"%@%@",
                                 item,
                                 [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0]];
            
            detail1 = [PublicMethod processChineseOrEnglishCharWithDetail1:detail1 ItemDesc:item FixLength:defaultSpace2];
            
            spaceAdd = 6 - qty.length;
            if (spaceAdd > 0) {
                detail2 = [NSString stringWithFormat:@"%@%@",
                           [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0],
                           qty];
            }
            [mString2 appendString:[NSString stringWithFormat:@"%@%@\n",detail1,detail2]];
        }
        
        if (i == 0) {
            //if ([[[printOptionArray objectAtIndex:0] objectForKey:@"PO_ShowPaymentMode"]integerValue] == 1)
            //{
                for (int j = 1; j < 9; j++)
                {
                    if ([[receiptArray objectAtIndex:0] objectForKey:[NSString stringWithFormat:@"IvH_PaymentAmt%d",j]] != [NSNull null]) {
                        if ([[[receiptArray objectAtIndex:0] objectForKey:[NSString stringWithFormat:@"IvH_PaymentAmt%d",j]] doubleValue] != 0.00)
                        {
                            [paymentTypeString appendString:[self autoGeneratePaymentTypeForReceiptWithTitle:[[receiptArray objectAtIndex:0] objectForKey:[NSString stringWithFormat:@"IvH_PaymentType%d",j]] Amount:[[[receiptArray objectAtIndex:0] objectForKey:[NSString stringWithFormat:@"IvH_PaymentAmt%d",j]] stringValue] ReceiptLength:receiptLength]];
                        }
                    }
                    
                }
            //}
            
            
            if ([[[printOptionArray objectAtIndex:0] objectForKey:@"PO_ShowCustomerInfo"]integerValue] == 1)
            {
                //[customerInfo appendString:dashline];
                if ([[[receiptArray objectAtIndex:0] objectForKey:@"IvH_CustName"] length] > 0) {
                    
                    [customerInfo appendString:[NSString stringWithFormat:@"Bill to: %@\r\n",[[receiptArray objectAtIndex:0] objectForKey:@"IvH_CustName"]]];
                    
                }
                
                if ([[[receiptArray objectAtIndex:0] objectForKey:@"IvH_CustAdd1"] length] > 0) {
                    
                    [customerInfo appendString:[NSString stringWithFormat:@"%@\r\n",[[receiptArray objectAtIndex:0] objectForKey:@"IvH_CustAdd1"]]];
                    
                    
                }
                
                if ([[[receiptArray objectAtIndex:0] objectForKey:@"IvH_CustAdd2"] length] > 0) {
                    [customerInfo appendString:[NSString stringWithFormat:@"%@\r\n",[[receiptArray objectAtIndex:0] objectForKey:@"IvH_CustAdd2"]]];
                    
                }
                
                if ([[[receiptArray objectAtIndex:0] objectForKey:@"IvH_CustAdd3"] length] > 0)
                {
                    [customerInfo appendString:[NSString stringWithFormat:@"%@\r\n",[[receiptArray objectAtIndex:0] objectForKey:@"IvH_CustAdd3"]]];
                }
                
                if ([[[receiptArray objectAtIndex:0] objectForKey:@"IvH_CustTelNo"] length] > 0)
                {
                    [customerInfo appendString:[NSString stringWithFormat:@"Tel:%@\r\n",[[receiptArray objectAtIndex:0] objectForKey:@"IvH_CustTelNo"]]];
                }
                
                if ([[[receiptArray objectAtIndex:0] objectForKey:@"IvH_CustGstNo"] length] > 0)
                {
                    [customerInfo appendString:[NSString stringWithFormat:@"%@\r\n\r\n",[[receiptArray objectAtIndex:0] objectForKey:@"IvH_CustGstNo"]]];
                }
            }
            
        }
        
        
        
    }
    
    
    if (enableGST == 1)
    {
        if ([[[printOptionArray objectAtIndex:0] objectForKey:@"PO_ShowGstSummary"] integerValue] == 1)
        {
            if ([[[receiptArray objectAtIndex:0] objectForKey:@"IvH_DocTaxAmt"] doubleValue] > 0.00) {
                
                NSString *gstSummaryline1 = @"    ---------------------------------\r\n";
                
                NSString *gstSummaryline3;
                NSString *gstSummaryline2;
                
                gstSummaryline2 = @"    | Tax Code   %       Amt     Tax|\r\n";
                gstSummaryline3 = @"    | GST Summary                   |\r\n";
                
                [gstSummaryString appendString:gstSummaryline1];
                [gstSummaryString appendString:gstSummaryline2];
                [gstSummaryString appendString:gstSummaryline3];
                
                [gstSummaryString appendString:[self autoGenerateGstSummaryContentWithTaxCode:[[receiptArray objectAtIndex:0] objectForKey:@"IvD_ItemTaxCode"] Percent:[[[receiptArray objectAtIndex:0] objectForKey:@"IvD_TaxRate"] stringValue] Amount:[NSString stringWithFormat:@"%0.2f",subTotalB4Gst] TaxAmount:[NSString stringWithFormat:@"%0.2f",gstTotalSalesTax]]];
                
                [gstSummaryString appendString:[self autoGenerateGstSummaryContentWithTaxCode:[NSString stringWithFormat:@"#%@",[[receiptArray objectAtIndex:0] objectForKey:@"IvD_ItemTaxCode"]] Percent:[[[receiptArray objectAtIndex:0] objectForKey:@"IvD_TaxRate"] stringValue] Amount:[NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"IvH_DocServiceTaxAmt"] doubleValue]] TaxAmount:[NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"IvH_DocServiceTaxGstAmt"] doubleValue]]]];
                
                [gstSummaryString appendString:[self autoGenerateGstSummaryContentWithTaxCode:@"Total" Percent:@"" Amount:[NSString stringWithFormat:@"%0.2f",subTotalB4Gst + [[[receiptArray objectAtIndex:0] objectForKey:@"IvH_DocServiceTaxAmt"] doubleValue]] TaxAmount:[NSString stringWithFormat:@"%0.2f",gstTotalSalesTax + [[[receiptArray objectAtIndex:0] objectForKey:@"IvH_DocServiceTaxGstAmt"] doubleValue]]]];
                
                [gstSummaryString appendString:gstSummaryline1];
                [gstSummaryString appendString:@"    # indicated this tax code belong\r\n"];
                [gstSummaryString appendString:@"    to service charges\r\n"];
            }
        }
    }
    
    
    NSString *footer;
    NSString *footerTitle;
    
    footer = [NSString stringWithFormat:@"%0.2f",subTotalB4Gst];
    footerTitle = @"SubTotal Exclude GST";
    NSString *subTotalEx = [NSString stringWithFormat:@"%@%@%@\r\n",
                            footerTitle,
                            [@" " stringByPaddingToLength:receiptLength-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"IvH_DocSubTotal"] doubleValue]];
    footerTitle = @"SubTotal";
    NSString *subTotal = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:receiptLength-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"IvH_DiscAmt"] doubleValue]];
    footerTitle = @"Discount";
    NSString *discount = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:receiptLength-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"IvH_DocServiceTaxAmt"] doubleValue]];
    footerTitle = @"Service Charge";
    NSString *serviceCharge = [NSString stringWithFormat:@"%@%@%@\r\n",
                               footerTitle,
                               [@" " stringByPaddingToLength:48-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"IvH_DocTaxAmt"] doubleValue]];
    footerTitle = @"Total GST";
    NSString *gst = [NSString stringWithFormat:@"%@%@%@\r\n",
                     footerTitle,
                     [@" " stringByPaddingToLength:receiptLength-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"IvH_Rounding"] doubleValue]];
    footerTitle = @"Rounding";
    NSString *rounding = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:receiptLength-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"IvH_DocAmt"] doubleValue]];
    footerTitle = @"Total";
    NSString *granTotal = [NSString stringWithFormat:@"%@%@%@\r\n",
                           footerTitle,
                           [@" " stringByPaddingToLength:(receiptLength / 2)-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    /*
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"IvH_TotalPay"] doubleValue]];
    footerTitle = @"Pay";
    NSString *pay = [NSString stringWithFormat:@"%@%@%@\r\n",
                     footerTitle,
                     [@" " stringByPaddingToLength:receiptLength-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
     */
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"IvH_ChangeAmt"] doubleValue]];
    footerTitle = @"Change";
    NSString *change = [NSString stringWithFormat:@"%@%@%@\r\n\r\n",
                        footerTitle,
                        [@" " stringByPaddingToLength:receiptLength-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    NSMutableString *headerPart = [[NSMutableString alloc] init];
    NSMutableString *middlePart = [[NSMutableString alloc] init];
    NSMutableString *footerPart = [[NSMutableString alloc] init];
    NSMutableString *footerPart2 = [[NSMutableString alloc] init];
    NSMutableString *footerPart3 = [[NSMutableString alloc] init];
    
    if ([printType isEqualToString:@"ReprintReceipt"]) {
        [headerPart appendString:[NSString stringWithFormat:@"%@%@\r\n\r\n",@"\r\n",@"Reprint Receipt"]];
    }
    
    [headerPart appendString:shopName];
    
    if (![regNo isEqualToString:@"()"]) {
        [headerPart appendString:regNo];
    }
    
    [headerPart appendString:add1];
    [headerPart appendString:add2];
    if (![add3 isEqualToString:@"\r\n"]) {
        [headerPart appendString:add3];
    }
    
    if ([[[printOptionArray objectAtIndex:0] objectForKey:@"PO_ShowCompanyTelNo"] integerValue] == 1) {
        [headerPart appendString:tel];
    }
    
    if (enableGST == 1)
    {
        [headerPart appendString:gstNo];
        //[headerPart appendString:gstTitle];
    }
    //[headerPart appendString:invNo];
    
    [middlePart setString:@""];
    [middlePart appendString:dateTime];

    //---------customer info-------------
    [middlePart appendString:customerInfo];
    //--------------------------------

    [middlePart appendString:header];
    
    if ([[[printOptionArray objectAtIndex:0] objectForKey:@"PO_ReceiptContent"] integerValue] == 0) {
        [middlePart appendString:title1];
        [middlePart appendString:currencyLine1];
    }
    else
    {
        [middlePart appendString:title2];
        [middlePart appendString:currencyLine2];
    }
    
    
    [middlePart appendString:dashline];
    [middlePart appendString:mString2];
    //[middlePart setString:@""];
    
    [footerPart setString:@""];
    [footerPart appendString:dashline];
    [footerPart appendString:subTotalEx];
    if ([[[printOptionArray objectAtIndex:0] objectForKey:@"PO_ShowSubTotalIncGst"] integerValue] == 1) {
        [footerPart appendString:subTotal];
    }
    
    
    if ([[[printOptionArray objectAtIndex:0] objectForKey:@"PO_ShowDiscount"] integerValue] == 1) {
        [footerPart appendString:discount];
    }
    
    if ([[[printOptionArray objectAtIndex:0] objectForKey:@"PO_ShowServiceCharge"] integerValue] == 1) {
        [footerPart appendString:serviceCharge];
    }
    
    if (enableGST == 1) {
        [footerPart appendString:gst];
    }
    
    [footerPart appendString:rounding];
    [footerPart2 appendString:granTotal];
    [footerPart3 appendString:paymentTypeString];
    [footerPart3 appendString:change];
    [footerPart3 appendString:gstSummaryString];
    [footerPart3 appendString:@"\r\n"];
    NSLog(@"%@",[[printOptionArray objectAtIndex:0] objectForKey:@"PO_ReceiptFooter"]);
    [footerPart3 appendString:[[printOptionArray objectAtIndex:0] objectForKey:@"PO_ReceiptFooter"]];
    
    if ([printerBrand isEqualToString:@"XinYe"]) {
        return [self xinYeReceiptPrintOutWithHeader:headerPart Middle:middlePart FooterP1:footerPart FooterP2:footerPart2 FooterP3:footerPart3 KickOutDrawerYN:kickOutDraweYN ReceiptTitle:gstTitle ReceiptNo:invNo];
    }
    else
    {
        return nil;
    }

}

+(NSString *)autoGeneratePaymentTypeForReceiptWithTitle:(NSString *)title Amount:(NSString *)amt ReceiptLength:(int)length
{
    NSString *pay;
    NSString *finalAmt;
    
    finalAmt = [NSString stringWithFormat:@"%0.2f",[amt doubleValue]];
    //NSLog(@"%@",amt);
    pay = [NSString stringWithFormat:@"%@%@%@\r\n",
     title,
     [@" " stringByPaddingToLength:length-title.length-finalAmt.length withString:@" " startingAtIndex:0],finalAmt];
    
    return pay;
}

+(NSString *)autoGenerateGstSummaryContentWithTaxCode:(NSString *)taxCode Percent:(NSString *)percent Amount:(NSString *)amt TaxAmount:(NSString *)taxAmt
{
    NSString *gstSummaryContent;
    long spaceAdd = 0;
    
    gstSummaryContent = [NSString stringWithFormat:@"| %@",taxCode];
    spaceAdd = 10 - gstSummaryContent.length;
    NSString *sDetail1 = [NSString stringWithFormat:@"%@%@%@",
                          [@" " stringByPaddingToLength:4 withString:@" " startingAtIndex:0],gstSummaryContent,
                          [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0]];
    
    gstSummaryContent = percent;
    spaceAdd = 4 - gstSummaryContent.length;
    NSString *sDetail2 = [NSString stringWithFormat:@"%@%@",[@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0],gstSummaryContent];
    
    gstSummaryContent = amt;
    spaceAdd = 10 - gstSummaryContent.length;
    NSString *sDetail3 = [NSString stringWithFormat:@"%@%@",
                          [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0],gstSummaryContent];
    
    gstSummaryContent = [NSString stringWithFormat:@"%@|",taxAmt];
    spaceAdd = 9 - gstSummaryContent.length;
    NSString *sDetail4 = [NSString stringWithFormat:@"%@%@",
                          [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0],gstSummaryContent];
    
    return [NSString stringWithFormat:@"%@%@%@%@\r\n",sDetail1,sDetail2,sDetail3,sDetail4];
}

+(NSMutableData *)generateReceiptFormatWithDBPath:(NSString *)dbPath GetInvNo:(NSString *)getInvNo EnableGst:(int)enableGST KickOutDrawerYN:(NSString *)kickOutDraweYN PrinterBrand:(NSString *)printerBrand ReceiptLength:(int)receiptLength DataArray:(NSMutableArray *)array
{
    __block NSMutableArray *receiptArray = [[NSMutableArray alloc]init];
    NSMutableArray *compArray = [[NSMutableArray alloc]init];
    
    [receiptArray removeAllObjects];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rsCompany = [db executeQuery:@"Select * from Company"];
        while ([rsCompany next]) {
            [compArray addObject:[rsCompany resultDictionary]];
        }
        
        if ([[[LibraryAPI sharedInstance] getWorkMode] isEqualToString:@"Main"]) {
            FMResultSet *rs = [db executeQuery:@"Select *,IFNULL(IvD_ItemTaxCode,'') || ': ' || IvD_ItemDescription as ItemDesc,IvD_ItemDescription as ItemDesc2, IFNULL(IvD_ItemTaxCode,'-') as Flag from InvoiceHdr InvH "
                               " left join InvoiceDtl InvD on InvH.IvH_DocNo = InvD.IvD_DocNo"
                               " left join ItemMast IM on IM.IM_ItemCode = InvD.IvD_ItemCode"
                               " where InvH.IvH_DocNo = ?",getInvNo];
            
            while ([rs next]) {
                [receiptArray addObject:[rs resultDictionary]];
            }
            
            [rs close];
        }
        else if (![printerBrand isEqualToString:@"XinYe"])
        {
            FMResultSet *rs = [db executeQuery:@"Select *,IFNULL(IvD_ItemTaxCode,'') || ': ' || IvD_ItemDescription as ItemDesc,IvD_ItemDescription as ItemDesc2, IFNULL(IvD_ItemTaxCode,'-') as Flag from InvoiceHdr InvH "
                               " left join InvoiceDtl InvD on InvH.IvH_DocNo = InvD.IvD_DocNo"
                               " left join ItemMast IM on IM.IM_ItemCode = InvD.IvD_ItemCode"
                               " where InvH.IvH_DocNo = ?",getInvNo];
            
            while ([rs next]) {
                [receiptArray addObject:[rs resultDictionary]];
            }
            
            [rs close];
        }
        else
        {
            receiptArray = array;
        }
        
        
    }];
    [queue close];
    
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    NSString *dateString = [dateFormat stringFromDate:today];
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
    NSString *timeString = [timeFormat stringFromDate:today];
    
    int spaceCount = 0;
    
    NSString *shopName = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Company"]];
    NSString *add1 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address1"]];
    NSString *add2 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address2"]];
    NSString *add3 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address3"]];
    NSString *tel = [NSString stringWithFormat:@"Tel : %@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Telephone"]];
    NSString *gstNo = [NSString stringWithFormat:@"GST ID : %@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_GstNo"]];
    NSString *invNo = [NSString stringWithFormat:@"Receipt : %@\r\n",[[receiptArray objectAtIndex:0] objectForKey:@"IvH_DocNo"]];
    NSString *gstTitle = @"Tax Invoice\r\n";
    
    //spaceCount = (int)(38 - invNo.length)/2;
    NSString *date = [NSString stringWithFormat:@"Date : %@",dateString];
    NSString *time = timeString;
    
    spaceCount = (int)(receiptLength - date.length - time.length);
    NSString *dateTime;
    dateTime = [NSString stringWithFormat:@"%@%@%@\r\n\r\n",
                date,[@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
                time];
    
    NSString *header;
    //NSString *tableName;
    header = [NSString stringWithFormat:@"SALE Table:%@ Pax: %@",[[receiptArray objectAtIndex:0] objectForKey:@"IvH_Table"],[[receiptArray objectAtIndex:0] objectForKey:@"IvH_PaxNo"]];
    spaceCount = (int)(receiptLength - date.length - time.length);
    
    header = [NSString stringWithFormat:@"%@%@\r\n",
              header,[@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0]];
    
    NSString *title =    @"Item                        Qty   Price    Total\r\n";
    NSString *dashline = @"------------------------------------------------\r\n";
    
    NSString *item = @"";
    NSString *qty = @"";
    NSString *price = @"";
    NSString *itemTotal = @"";
    NSString *itemDesc2 = @"";
    double subTotalB4Gst = 0.00;
    long spaceAdd = 0;
    
    NSString *detail2;
    NSString *detail3;
    NSString *detail4;
    NSMutableString *mString2 = [[NSMutableString alloc]init];
    
    for (int i = 0; i<receiptArray.count; i++) {
        if (enableGST == 0) {
            item = [[receiptArray objectAtIndex:i] objectForKey:@"ItemDesc2"];
        }
        else
        {
            if ([[[receiptArray objectAtIndex:i]objectForKey:@"Flag"] isEqualToString:@"-"]) {
                item = [[receiptArray objectAtIndex:i] objectForKey:@"ItemDesc2"];
            }
            else
            {
                item = [[receiptArray objectAtIndex:i] objectForKey:@"ItemDesc"];
            }
            
        }
        subTotalB4Gst = subTotalB4Gst + [[[receiptArray objectAtIndex:i] objectForKey:@"IvD_TotalEx"] doubleValue];
        //NSLog(@"%d",[item length]);
        if (receiptLength == 48) {
            if ([item length] > 25) item = [item substringToIndex:25];
        }
        else
        {
            if ([item length] > 15) item = [item substringToIndex:15];
        }
        qty = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:i] objectForKey:@"IvD_Quantity"] doubleValue]];
        if ([qty length] > 6) qty = [qty substringToIndex:6];
        price = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:i] objectForKey:@"IvD_UnitPrice"] doubleValue]];
        if ([price length] > 8) price = [price substringToIndex:8];
        itemTotal = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:i] objectForKey:@"IvD_SubTotal"] doubleValue]];
        if ([itemTotal length] > 9) itemTotal = [itemTotal substringToIndex:9];
        
        spaceAdd = 25 - item.length;
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
        
        itemDesc2 = [[receiptArray objectAtIndex:i] objectForKey:@"IM_Description2"];
        
        [mString2 appendString:[NSString stringWithFormat:@"%@%@%@%@\n",detail1,detail2,detail3,detail4]];
        
        if ([itemDesc2 length] > 0) {
            [mString2 appendString:[NSString stringWithFormat:@"%@\n",itemDesc2]];
        }
        
    }
    
    NSString *footer;
    NSString *footerTitle;
    
    footer = [NSString stringWithFormat:@"%0.2f",subTotalB4Gst];
    footerTitle = @"SubTotal Exclude GST";
    NSString *subTotalEx = [NSString stringWithFormat:@"%@%@%@\r\n",
                            footerTitle,
                            [@" " stringByPaddingToLength:receiptLength-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"IvH_DocSubTotal"] doubleValue]];
    footerTitle = @"SubTotal";
    NSString *subTotal = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:receiptLength-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"IvH_DiscAmt"] doubleValue]];
    footerTitle = @"Discount";
    NSString *discount = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:receiptLength-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"IvH_DocServiceTaxAmt"] doubleValue]];
    footerTitle = @"Service Charge";
    NSString *serviceCharge = [NSString stringWithFormat:@"%@%@%@\r\n",
                               footerTitle,
                               [@" " stringByPaddingToLength:48-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"IvH_DocTaxAmt"] doubleValue]];
    footerTitle = @"Total GST";
    NSString *gst = [NSString stringWithFormat:@"%@%@%@\r\n",
                     footerTitle,
                     [@" " stringByPaddingToLength:receiptLength-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"IvH_Rounding"] doubleValue]];
    footerTitle = @"Rounding";
    NSString *rounding = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:receiptLength-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"IvH_DocAmt"] doubleValue]];
    footerTitle = @"Total";
    NSString *granTotal = [NSString stringWithFormat:@"%@%@%@\r\n",
                           footerTitle,
                           [@" " stringByPaddingToLength:(receiptLength / 2)-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"IvH_TotalPay"] doubleValue]];
    footerTitle = @"Pay";
    NSString *pay = [NSString stringWithFormat:@"%@%@%@\r\n",
                     footerTitle,
                     [@" " stringByPaddingToLength:receiptLength-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"IvH_ChangeAmt"] doubleValue]];
    footerTitle = @"Change";
    NSString *change = [NSString stringWithFormat:@"%@%@%@\r\n\r\n",
                        footerTitle,
                        [@" " stringByPaddingToLength:receiptLength-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    NSMutableString *headerPart = [[NSMutableString alloc] init];
    NSMutableString *middlePart = [[NSMutableString alloc] init];
    NSMutableString *footerPart = [[NSMutableString alloc] init];
    NSMutableString *footerPart2 = [[NSMutableString alloc] init];
    NSMutableString *footerPart3 = [[NSMutableString alloc] init];
    
    [headerPart appendString:shopName];
    [headerPart appendString:add1];
    [headerPart appendString:add2];
    if (![add3 isEqualToString:@"\r\n"]) {
        [headerPart appendString:add3];
    }
    
    [headerPart appendString:tel];
    if (enableGST == 1)
    {
        [headerPart appendString:gstNo];
        [headerPart appendString:gstTitle];
    }
    [headerPart appendString:invNo];
    
    [middlePart setString:@""];
    [middlePart appendString:dateTime];
    [middlePart appendString:header];
    [middlePart appendString:title];
    [middlePart appendString:dashline];
    [middlePart appendString:mString2];
    //[middlePart setString:@""];
    
    [footerPart setString:@""];
    [footerPart appendString:dashline];
    [footerPart appendString:subTotalEx];
    [footerPart appendString:subTotal];
    [footerPart appendString:discount];
    [footerPart appendString:serviceCharge];
    if (enableGST == 1) {
        [footerPart appendString:gst];
    }
    [footerPart appendString:rounding];
    [footerPart2 appendString:granTotal];
    [footerPart3 appendString:pay];
    [footerPart3 appendString:change];
    
    if ([printerBrand isEqualToString:@"XinYe"]) {
        return nil;
        /*
        return [self xinYeReceiptPrintOutWithHeader:headerPart Middle:middlePart FooterP1:footerPart FooterP2:footerPart2 FooterP3:footerPart3 KickOutDrawerYN:kickOutDraweYN];
         */
    }
    else
    {
        return nil;
    }
    
}


+(NSMutableData *)generateSalesOrderReceiptFormatWithComapnyArray:(NSMutableArray *)compArray SalesOrderArray:(NSMutableArray *)receiptArray EnableGst:(int)enableGST PrinterBrand:(NSString *)printerBrand ReceiptLength:(int)receiptLength
{
    
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
    //spaceCount = (int)(38 - shopName.length)/2;
    
    shopName = [NSString stringWithFormat:@"%@",
                shopName];
    
    NSString *regNo = [NSString stringWithFormat:@"(%@)\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_RegistrationNo"]];
    
    NSString *add1 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address1"]];
    //spaceCount = (int)(38 - add1.length)/2;
    
    add1 = [NSString stringWithFormat:@"%@",
            add1];
    
    NSString *add2 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address2"]];
    //spaceCount = (int)(38 - add2.length)/2;
    
    add2 = [NSString stringWithFormat:@"%@",
            add2];
    
    NSString *add3 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address3"]];
    //spaceCount = (int)(38 - add3.length)/2;
    
    add3 = [NSString stringWithFormat:@"%@",
            add3];
    
    NSString *tel = [NSString stringWithFormat:@"Tel : %@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Telephone"]];
    //spaceCount = (int)(38 - tel.length)/2;
    
    tel = [NSString stringWithFormat:@"%@",
           tel];
    
    NSString *gstNo = [NSString stringWithFormat:@"GST ID : %@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_GstNo"]];
    //spaceCount = (int)(38 - gstNo.length)/2;
    
    if ([[[compArray objectAtIndex:0] objectForKey:@"Comp_GstNo"] length] > 0) {
        gstNo = [NSString stringWithFormat:@"%@",
                 gstNo];
    }
    else
    {
        gstNo = @"";
    }
    
    NSString *invNo = [NSString stringWithFormat:@"SO : %@\r\n",[[receiptArray objectAtIndex:0] objectForKey:@"SOH_DocNo"]];
    spaceCount = (int)(receiptLength - invNo.length)/2;
    
    invNo = [NSString stringWithFormat:@"%@",
             invNo];
    
    NSString *date = [NSString stringWithFormat:@"Date : %@",dateString];
    NSString *time = timeString;
    
    spaceCount = (int)(receiptLength - date.length - time.length);
    NSString *dateTime;
    dateTime = [NSString stringWithFormat:@"%@%@%@\r\n\r\n",
                date,[@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
                time];
    //NSString *header = @"SALE                                  \r\n";
    NSString *header;
    //NSString *tableName;
    header = [NSString stringWithFormat:@"Table: %@   Pax: %@",[[receiptArray objectAtIndex:0] objectForKey:@"SOH_Table"],[[receiptArray objectAtIndex:0] objectForKey:@"SOH_PaxNo"]];
    spaceCount = (int)(receiptLength - date.length - time.length);
    
    header = [NSString stringWithFormat:@"%@%@\r\n",
              header,[@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0]];
    
    NSString *title =    @"Item                        Qty   Price    Total\r\n";
    NSString *dashline = @"------------------------------------------------\r\n";
    
    NSString *item = @"";
    NSString *qty = @"";
    NSString *price = @"";
    NSString *itemTotal = @"";
    NSString *itemDesc2 = @"";
    NSUInteger spaceAdd = 0;
    double subTotalB4Gst = 0.00;
    
    NSString *detail2;
    NSString *detail3;
    NSString *detail4;
    NSMutableString *mString2 = [[NSMutableString alloc]init];
    NSUInteger defaultSpace1 = 0;
    NSUInteger defaultSpace2 = 0;
    
    for (int i = 0; i<receiptArray.count; i++) {
        if ([[[receiptArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"]) {
            if (enableGST == 0) {
                item = [[receiptArray objectAtIndex:i] objectForKey:@"ItemDesc2"];
            }
            else
            {
                /*
                if ([[[receiptArray objectAtIndex:i]objectForKey:@"Flag"] isEqualToString:@"-"]) {
                    item = [[receiptArray objectAtIndex:i] objectForKey:@"ItemDesc2"];
                }
                else
                {
                    item = [[receiptArray objectAtIndex:i] objectForKey:@"ItemDesc"];
                }
                 */
                item = [[receiptArray objectAtIndex:i] objectForKey:@"ItemDesc"];
                
            }
            
            if (receiptLength == 48) {
                //NSLog(@"description : %lu",(unsigned long)[item length]);
                
                if ([item length] > 25) item = [item substringToIndex:25];
                spaceAdd = 25 - item.length ;
                defaultSpace1 = 25;
                
            }
            else
            {
                if ([item length] > 15) item = [item substringToIndex:15];
                spaceAdd = 15 - item.length;
                defaultSpace1 = 15;
            }
            qty = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:i] objectForKey:@"SOD_Quantity"] doubleValue]];
            if ([qty length] > 6) qty = [qty substringToIndex:6];
            price = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:i] objectForKey:@"SOD_UnitPrice"] doubleValue]];
            if ([price length] > 8) price = [price substringToIndex:8];
            itemTotal = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:i] objectForKey:@"SOD_SubTotal"] doubleValue]];
            if ([itemTotal length] > 9) itemTotal = [itemTotal substringToIndex:9];
            
            subTotalB4Gst = subTotalB4Gst + [[[receiptArray objectAtIndex:i] objectForKey:@"SOD_TotalEx"] doubleValue];
            
            
            NSString *detail1 = [NSString stringWithFormat:@"%@%@",
                                 item,
                                 [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0]];
            
            detail1 = [PublicMethod processChineseOrEnglishCharWithDetail1:detail1 ItemDesc:item FixLength:defaultSpace1];
            
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
            itemDesc2 = [[receiptArray objectAtIndex:i] objectForKey:@"IM_Description2"];
            [mString2 appendString:[NSString stringWithFormat:@"%@%@%@%@\n",detail1,detail2,detail3,detail4]];
            
            if ([itemDesc2 length] > 0) {
                [mString2 appendString:[NSString stringWithFormat:@"%@\n",itemDesc2]];
            }
        }
        else if([[[receiptArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"PackageItemOrder"])
        {
            item = [NSString stringWithFormat:@" - %@",[[receiptArray objectAtIndex:i] objectForKey:@"SOD_ItemDescription"]];
            
            if (receiptLength == 48) {
                if ([item length] > 25) item = [item substringToIndex:25];
                spaceAdd = 25 - item.length;
            }
            else
            {
                if ([item length] > 15) item = [item substringToIndex:15];
                spaceAdd = 15 - item.length;
            }
            qty = @"1.00";
            if ([qty length] > 6) qty = [qty substringToIndex:6];
            
            
            NSString *detail1 = [NSString stringWithFormat:@"%@%@",
                                 item,
                                 [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0]];
            
            detail1 = [PublicMethod processChineseOrEnglishCharWithDetail1:detail1 ItemDesc:item FixLength:defaultSpace2];
            
            //detail1 = [detail1 substringToIndex:21];
            
            spaceAdd = 6 - qty.length;
            if (spaceAdd > 0)
            {
                detail2 = [NSString stringWithFormat:@"%@%@",
                           [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0],
                           qty];
            }
            [mString2 appendString:[NSString stringWithFormat:@"%@%@\n",detail1,detail2]];
        }
        else
        {
            item = [NSString stringWithFormat:@" - %@",[[receiptArray objectAtIndex:i] objectForKey:@"SOC_CDDescription"]];
            
            if (receiptLength == 48) {
                if ([item length] > 25) item = [item substringToIndex:25];
                spaceAdd = 25 - item.length;
            }
            else
            {
                if ([item length] > 15) item = [item substringToIndex:15];
                spaceAdd = 15 - item.length;
            }
            qty = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:i] objectForKey:@"SOC_CDQty"] doubleValue]];
            if ([qty length] > 6) qty = [qty substringToIndex:6];
            
            
            NSString *detail1 = [NSString stringWithFormat:@"%@%@",
                                 item,
                                 [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0]];
            
            detail1 = [PublicMethod processChineseOrEnglishCharWithDetail1:detail1 ItemDesc:item FixLength:defaultSpace2];
            
            //detail1 = [detail1 substringToIndex:21];
            
            spaceAdd = 6 - qty.length;
            if (spaceAdd > 0)
            {
                detail2 = [NSString stringWithFormat:@"%@%@",
                           [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0],
                           qty];
            }
            [mString2 appendString:[NSString stringWithFormat:@"%@%@\n",detail1,detail2]];
            
        }
        
        //[mString2 appendString:[NSString stringWithFormat:@"%@\n",itemDesc2]];
        
    }
    
    NSString *footer;
    NSString *footerTitle;
    
    footer = [NSString stringWithFormat:@"%0.2f",subTotalB4Gst];
    footerTitle = @"SubTotal Exclude GST";
    NSString *subTotalEx = [NSString stringWithFormat:@"%@%@%@\r\n",
                            footerTitle,
                            [@" " stringByPaddingToLength:receiptLength-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"SOH_DocSubTotal"] doubleValue]];
    footerTitle = @"SubTotal";
    NSString *subTotal = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:receiptLength-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"SOH_DiscAmt"] doubleValue]];
    footerTitle = @"Discount";
    NSString *discount = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:receiptLength-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"SOH_DocServiceTaxAmt"] doubleValue]];
    footerTitle = @"Service Charge";
    NSString *svc = [NSString stringWithFormat:@"%@%@%@\r\n",
                     footerTitle,
                     [@" " stringByPaddingToLength:receiptLength-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"SOH_DocTaxAmt"] doubleValue]];
    footerTitle = @"Total GST";
    NSString *gst = [NSString stringWithFormat:@"%@%@%@\r\n",
                     footerTitle,
                     [@" " stringByPaddingToLength:receiptLength-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"SOH_Rounding"] doubleValue]];
    footerTitle = @"Rounding";
    NSString *rounding = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:receiptLength-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[receiptArray objectAtIndex:0] objectForKey:@"SOH_DocAmt"] doubleValue]];
    footerTitle = @"Total";
    NSString *granTotal = [NSString stringWithFormat:@"%@%@%@\r\n",
                           footerTitle,
                           [@" " stringByPaddingToLength:(receiptLength / 2)-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    //[textData appendString:eposSection1];
    
    NSMutableString *headerPart = [[NSMutableString alloc] init];
    NSMutableString *middlePart = [[NSMutableString alloc] init];
    NSMutableString *footerPart = [[NSMutableString alloc] init];
    NSMutableString *footerPart2 = [[NSMutableString alloc] init];
    
    [headerPart appendString:shopName];
    
    if (![regNo isEqualToString:@"()"]) {
        [headerPart appendString:regNo];
    }
    
    [headerPart appendString:add1];
    [headerPart appendString:add2];
    //[headerPart appendString:add3];
    if (![add3 isEqualToString:@"\r\n"]) {
        [headerPart appendString:add3];
    }
    
    [headerPart appendString:tel];
    if (![gstNo isEqualToString:@""]) {
        [headerPart appendString:gstNo];
    }
    [headerPart appendString:invNo];
    
    [middlePart appendString:dateTime];
    [middlePart appendString:header];
    [middlePart appendString:title];
    [middlePart appendString:dashline];
    [middlePart appendString:mString2];
    
    
    [footerPart appendString:dashline];
    [footerPart appendString:subTotalEx];
    [footerPart appendString:subTotal];
    [footerPart appendString:discount];
    [footerPart appendString:svc];
    [footerPart appendString:gst];
    [footerPart appendString:rounding];
    [footerPart2 appendString:granTotal];
    
    
    //[footerPart appendString:headerPart];
    //[footerPart appendString:middlePart];
    
    return [self xinYeSalesOrderReceiptWithHeader:headerPart Middle:middlePart FooterP1:footerPart FooterP2:footerPart2 FooterP3:@"-"];
}


+(NSMutableData *)xinYeSalesOrderReceiptWithHeader:(NSString *)headerPart Middle:(NSString *)middlePart FooterP1:(NSString *)footerP1 FooterP2:(NSString *)footerP2 FooterP3:(NSString *)footerP3
{
    NSMutableData *commands = [NSMutableData data];
    [commands appendData:[PosCommand selectCharacterCodePage:0]];
    [commands appendData:[PosCommand selectAlignment:1]]; //align center
    [commands appendData:[PosCommand selectFont:2]];
    //[commands appendData:[headerPart dataUsingEncoding:NSASCIIStringEncoding]];
    [commands appendData:[headerPart dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    [commands appendData:[PosCommand selectAlignment:0]]; //align left
    [commands appendData:[middlePart dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    [commands appendData:[footerP1 dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    [commands appendData:[PosCommand printAndFeedLine]];
    [commands appendData:[PosCommand selectCharacterSize:25]];
    [commands appendData:[footerP2 dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    [commands appendData:[PosCommand selectCharacterSize:0]];
    [commands appendData:[PosCommand printAndFeedLine]];
    [commands appendData:[PosCommand printAndFeedLine]];
    [commands appendData:[PosCommand printAndFeedLine]];
    [commands appendData:[PosCommand printAndFeedLine]];
    [commands appendData:[PosCommand printAndFeedLine]];
    [commands appendData:[PosCommand selectCutPageModelAndCutpage:0]];
    
    return commands;
}

+(NSMutableData *)xinYeReceiptPrintOutWithHeader:(NSString *)headerPart Middle:(NSString *)middlePart FooterP1:(NSString *)footerP1 FooterP2:(NSString *)footerP2 FooterP3:(NSString *)footerP3 KickOutDrawerYN:(NSString *)kickOutDraweYN ReceiptTitle:(NSString *)receiptTitle ReceiptNo:(NSString *)receiptNo
{
    NSMutableData *commands = [NSMutableData data];
    [commands appendData:[PosCommand openCashBoxRealTimeWithM:0 andT:1]];
    [commands appendData:[PosCommand selectCharacterCodePage:0]];
    [commands appendData:[PosCommand selectAlignment:1]]; //align center
    [commands appendData:[PosCommand selectFont:2]];
    [commands appendData:[headerPart dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    [commands appendData:[PosCommand selectCharacterSize:24]];
    [commands appendData:[receiptTitle dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    [commands appendData:[PosCommand selectCharacterSize:0]];
    [commands appendData:[receiptNo dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];;
    [commands appendData:[PosCommand selectAlignment:0]]; //align left
    [commands appendData:[middlePart dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    [commands appendData:[footerP1 dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    [commands appendData:[PosCommand printAndFeedLine]];
    [commands appendData:[PosCommand selectCharacterSize:25]];
    [commands appendData:[footerP2 dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    [commands appendData:[PosCommand printAndFeedLine]];
    [commands appendData:[PosCommand selectCharacterSize:0]];
    [commands appendData:[footerP3 dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    [commands appendData:[PosCommand printAndFeedLine]];
    [commands appendData:[PosCommand printAndFeedLine]];
    [commands appendData:[PosCommand printAndFeedLine]];
    [commands appendData:[PosCommand printAndFeedLine]];
    [commands appendData:[PosCommand printAndFeedLine]];
    [commands appendData:[PosCommand selectCutPageModelAndCutpage:0]];
    
    
    return commands;
}

+(NSMutableData *)createXinYeKitchenReceiptWithDBPath:(NSString *)dbPath TableNo:(NSString *)tableNo ItemNo:(NSString *)itemName Qty:(NSString *)qty DataArray:(NSMutableArray *)dataArray PackageName:(NSString *)packageName ShowPackageDetail:(NSUInteger)showPackageDetail
{
    NSMutableString *textData = [[NSMutableString alloc] init];
    NSMutableString *textData2 = [[NSMutableString alloc] init];
    NSMutableData *commands = [NSMutableData data];
    
    [textData appendString:[NSString stringWithFormat:@"Table No: %@\r\n",tableNo]];
    
    if ([packageName length] > 0) {
        [textData appendString:[NSString stringWithFormat:@"%@\r\n",packageName]];
        //if (showPackageDetail == 1) {
            [textData appendString:[NSString stringWithFormat:@"%@\r\n",itemName]];
        //}
        
    }
    else
    {
        [textData appendString:[NSString stringWithFormat:@"%@\r\n",itemName]];
    }
    
    [textData appendString:[NSString stringWithFormat:@"%@\r\n",qty]];
    //[textData appendString:[NSString stringWithFormat:@"line: %@\r\n",@"-------------"]];
    
    [commands appendData:[PosCommand selectAlignment:0]]; //align center
    [commands appendData:[PosCommand selectFont:2]];
    [commands appendData:[PosCommand selectCharacterSize:25]];
    [commands appendData:[textData dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    
    NSMutableArray *dataWithoutDuplicate = [[NSMutableArray alloc] init];
    
    // adding condiment data to kitchen receipt
    if (dataArray.count > 1)
    {
        for (int i = 0; i < dataArray.count; i++) {
            if (![dataWithoutDuplicate containsObject:[dataArray objectAtIndex:i]])
            {
                [dataWithoutDuplicate addObject:[dataArray objectAtIndex:i]];
            }
            
        }
        
        for (int i = 0; i < dataWithoutDuplicate.count; i++) {
            if ([[[dataWithoutDuplicate objectAtIndex:i] objectForKey:@"PQ_OrderType"] isEqualToString:@"CondimentOrder"]) {
                [textData2 appendString:@"\r\n"];
                [textData2 appendString:[NSString stringWithFormat:@" - %@ %@\r\n",[[dataWithoutDuplicate objectAtIndex:i] objectForKey:@"PQ_ItemDesc"],[[dataWithoutDuplicate objectAtIndex:i] objectForKey:@"PQ_ItemQty"]]];
            }
        }
        
        if ([packageName length] > 0) {
            if (showPackageDetail == 0) {
                textData2.string = @"";
            }
            else
            {
                [textData2 appendString:@""];
            }
        }
        
        dataWithoutDuplicate = nil;
        
    }
    
    
    //[commands appendData:[PosCommand selectCharacterSize:14]];
    [commands appendData:[PosCommand selectFont:2]];
    [commands appendData:[PosCommand selectCharacterSize:25]];
    [commands appendData:[textData2 dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
    [commands appendData:[PosCommand printAndFeedLine]];
    [commands appendData:[PosCommand printAndFeedLine]];
    [commands appendData:[PosCommand printAndFeedLine]];
    [commands appendData:[PosCommand printAndFeedLine]];
    [commands appendData:[PosCommand printAndFeedLine]];
    [commands appendData:[PosCommand selectCutPageModelAndCutpage:0]];
    
    return commands;
}



+(NSMutableData *)createXinYeKitReceiptGroupWithOrderDetail:(NSMutableArray *)orderDetail TableName:(NSString *)tableCode
{
    NSString *item = @"";
    NSString *qty = @"";
    //int spaceAdd = 0;
    NSString *tableName;
    //NSString *detail2;
    NSMutableString *mString2 = [[NSMutableString alloc]init];
    
    for (int i = 0; i<orderDetail.count; i++) {
        item = [[orderDetail objectAtIndex:i] objectForKey:@"IM_Description"];
        if ([item length] > 15) item = [item substringToIndex:14];
        qty = [NSString stringWithFormat:@"%0.2f",[[[orderDetail objectAtIndex:i] objectForKey:@"IM_Qty"] doubleValue]];
        
        [mString2 appendString:[NSString stringWithFormat:@"%@\n",item]];
        [mString2 appendString:[NSString stringWithFormat:@"Qty : %@\n\n",qty]];
        //[mString2 appendString:[NSString stringWithFormat:@"%%%%%%%% %@",qty]];
        
    }
    tableName = [NSString stringWithFormat:@"%@ : %@\n\n",@"Table No",tableCode];
    
    NSMutableData *commands = [NSMutableData data];
    [commands appendData:[PosCommand selectAlignment:0]]; //align left
    [commands appendData:[PosCommand selectFont:2]];
    [commands appendData:[PosCommand selectCharacterSize:25]];
    [commands appendData:[tableName dataUsingEncoding:NSASCIIStringEncoding]];
    [commands appendData:[mString2 dataUsingEncoding:NSASCIIStringEncoding]];
    [commands appendData:[PosCommand printAndFeedLine]];
    [commands appendData:[PosCommand selectCharacterSize:0]];
    [commands appendData:[PosCommand printAndFeedLine]];
    [commands appendData:[PosCommand printAndFeedLine]];
    [commands appendData:[PosCommand printAndFeedLine]];
    [commands appendData:[PosCommand printAndFeedLine]];
    [commands appendData:[PosCommand selectCutPageModelAndCutpage:0]];
    
    return commands;
    
}

+(NSMutableData *)createXinYeKitchenNoticeWithMsg:(NSString *)msg
{
    NSMutableData *commands = [NSMutableData data];
    [commands appendData:[PosCommand selectAlignment:0]]; //align left
    [commands appendData:[PosCommand selectFont:2]];
    [commands appendData:[PosCommand selectCharacterSize:25]];
    [commands appendData:[msg dataUsingEncoding:NSASCIIStringEncoding]];
    [commands appendData:[PosCommand printAndFeedLine]];
    [commands appendData:[PosCommand selectCharacterSize:0]];
    [commands appendData:[PosCommand printAndFeedLine]];
    [commands appendData:[PosCommand printAndFeedLine]];
    [commands appendData:[PosCommand printAndFeedLine]];
    [commands appendData:[PosCommand selectCutPageModelAndCutpage:0]];
    
    return commands;
}

@end
