//
//  PublicMethod.m
//  IpadOrder
//
//  Created by IRS on 28/09/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import "PublicMethod.h"
#import "EposPrintFunction.h"
#import "PrinterFunctions.h"
#import "Result.h"
@class EposPrint;
@implementation PublicMethod

+(void)settingServiceTaxPercentWithOverRide:(NSString *)overRide Percent:(NSString *)tbServicePercent
{
    if ([overRide integerValue] == 1) {
        if ( [tbServicePercent doubleValue] > 0.0) {
            //get service tax percent follow table
            
            [[LibraryAPI sharedInstance] setServiceTaxPercent:tbServicePercent];
        }
        else if ([tbServicePercent doubleValue] == 0.0) {
            [[LibraryAPI sharedInstance] setServiceTaxPercent:@"0.00"];
        }
        else
        {
            [[LibraryAPI sharedInstance] setServiceTaxPercent:@"0.00"];
        }
        
    }
    else
    {
        //non override svc
        [[LibraryAPI sharedInstance] setServiceTaxPercent:@"-"];
        
    }
}

+(void)printAsterixKitchenReceiptWithItemDesc:(NSString *)imDesc IPAdd:(NSString *)ipAdd imQty:(NSString *)imQty TableName:(NSString *)tableName DataArray:(NSArray *)dataArray
{
    //EposPrint *printer_;
    Result *result = nil;
    int result2;
    EposBuilder *builder = [[EposBuilder alloc] init];
    
    result = [[Result alloc] init];
    //EposPrint *printer = [[EposPrint alloc] init];
    
    builder = [EposPrintFunction createKitchenReceiptFormat:result TableNo:tableName ItemNo:imDesc Qty:imQty DataArray:dataArray];
    
    //builder = [EposPrintFunction createKitchenReceiptFormatDataArray:dataArray Result:result];
    
    //[printer openPrinter:EPOS_OC_DEVTYPE_TCP DeviceName:@"192.168.0.13" Enabled:0 Interval:3000];
    
    if(result.errType == RESULT_ERR_NONE) {
        
        //Do background work
        [EposPrintFunction print:builder Result:result PortName:ipAdd];
        //unsigned long status = 0;
        //unsigned long battery = 0;
        //result2 = [printer sendData:builder Timeout:30000 Status:&status Battery:&battery];
        
    }
    
    NSLog(@"Result2 : %d",result2);
    if (builder != nil) {
        [builder clearCommandBuffer];
    }
    
    [EposPrintFunction displayMsg:result];
    
    if(result != nil) {
        result = nil;
    }
    
    //[printer closePrinter];
    //printer = nil;
}

+(void)printAsterixSalesOrderWithIpAdd:(NSString *)ipAdd CompanyArray:(NSMutableArray *)compArray SalesOrderArray:(NSMutableArray *)soArray
{
    NSString *printErrorMsg;
    Result *result = nil;
    EposBuilder *builder = nil;
    
    result = [[Result alloc] init];
    
    builder = [EposPrintFunction createSalesOrderRceiptData:result ComapnyArray:compArray SalesOrderArray:soArray EnableGst:[[LibraryAPI sharedInstance] getEnableGst]];
    
    if(result.errType == RESULT_ERR_NONE) {
        [EposPrintFunction print:builder Result:result PortName:ipAdd];
    }
    else
    {
        NSLog(@"Testing Data %@",@"Print Fail");
    }
    
    if (builder != nil) {
        [builder clearCommandBuffer];
    }
    
    printErrorMsg = [EposPrintFunction displayMsg:result];
    
    if ([printErrorMsg length] > 0) {
        //[self showAlertView:printErrorMsg title:@"Warning"];
        [[LibraryAPI sharedInstance] showAlertViewWithTitlw:printErrorMsg Title:@"Warning"];
    }
    
    if(result != nil) {
        result = nil;
    }
}

+(void)printAsterixReceiptWithIpAdd:(NSString *)ipAdd CompanyArray:(NSMutableArray *)compArray CSArray:(NSMutableArray *)csArray
{
    NSString *printErrorMsg;
    
    Result *result = nil;
    EposBuilder *builder = nil;
    
    result = [[Result alloc] init];
    
    //builder = [EposPrintFunction createSalesOrderRceiptData:result DBPath:dbPath GetInvNo:docNo EnableGst:enableGST];
    
    builder = [EposPrintFunction createReceiptData:result ComapnyArray:compArray CSArray:csArray EnableGst:[[LibraryAPI sharedInstance] getEnableGst] KickOutDrawerYN:@"Y"];
    
    if(result.errType == RESULT_ERR_NONE) {
        [EposPrintFunction print:builder Result:result PortName:ipAdd];
    }
    else
    {
        NSLog(@"Testing Data %@",@"Print Fail");
    }
    
    if (builder != nil) {
        [builder clearCommandBuffer];
    }
    
    printErrorMsg = [EposPrintFunction displayMsg:result];
    
    if ([printErrorMsg length] > 0) {
        [[LibraryAPI sharedInstance] showAlertViewWithTitlw:printErrorMsg Title:@"Warning"];
    }
    
    if(result != nil) {
        result = nil;
    }

}

+(NSMutableString *)makeKitchenGroupReceiptFormatWithItemDesc:(NSString *)desc ItemQty:(NSString *)qty PackageName:(NSString *)packageName ShowPackageDetail:(NSUInteger)showPackageDetail PrinterBrand:(NSString *)printerBrand
{
    
    NSUInteger spaceAdd = 0;
    NSString *detail2;
    NSMutableString *mString2 = [[NSMutableString alloc]init];
    NSString *pName;
    NSString *detail1;
    
    //item = [[orderDetail objectAtIndex:i] objectForKey:@"IM_Description"];
    if ([desc length] > 30) desc = [desc substringToIndex:30];
    qty = [NSString stringWithFormat:@"%0.2f",[qty doubleValue]];
    if ([qty length] > 6) qty = [qty substringToIndex:6];
    
    
    if ([packageName length] > 0) {
        if (![printerBrand isEqualToString:@"XinYe"]) {
            spaceAdd = 25 - packageName.length;
            detail1 = [NSString stringWithFormat:@"%@%@",
                                 packageName,
                                 [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0]];
            pName = [PublicMethod processChineseOrEnglishCharWithDetail1:packageName ItemDesc:packageName FixLength:25];
            
            [mString2 appendString:[NSString stringWithFormat:@"%@\n\n",pName]];
        }
        
        spaceAdd = 30 - desc.length;
        detail1 = [NSString stringWithFormat:@"Item : %@%@",
                   desc,
                   [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0]];
        detail1 = [PublicMethod processChineseOrEnglishCharWithDetail1:detail1 ItemDesc:desc FixLength:25];
        [mString2 appendString:[NSString stringWithFormat:@"%@\n",detail1]];
        
    }
    else
    {
        spaceAdd = 30 - desc.length;
        detail1 = [NSString stringWithFormat:@"Item : %@%@",
                             desc,
                             [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0]];
        detail1 = [PublicMethod processChineseOrEnglishCharWithDetail1:detail1 ItemDesc:desc FixLength:25];
        [mString2 appendString:[NSString stringWithFormat:@"%@\n",detail1]];
    }
    
    
    spaceAdd = 6 - qty.length;
    if (spaceAdd > 0) {
        detail2 = [NSString stringWithFormat:@"Qty :%@%@",
                   [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0],
                   qty];
    }
    
    
    [mString2 appendString:[NSString stringWithFormat:@"%@\n\n",detail2]];
    return mString2;
}

+(void)printAsterixKRGroupWithIpAdd:(NSString *)ipAdd TableName:(NSString *)tbName Data:(NSMutableString *)data
{
    Result *result = nil;
    EposBuilder *builder = nil;
    
    result = [[Result alloc] init];
    
    builder = [EposPrintFunction createKitchenReceiptGroupFormat:result OrderDetail:data TableName:tbName];
    
    if(result.errType == RESULT_ERR_NONE) {
        [EposPrintFunction print:builder Result:result PortName:ipAdd];
    }
    
    if (builder != nil)
    {
        [builder clearCommandBuffer];
    }
    
    //[EposPrintFunction displayMsg:result];
    
    if(result != nil) {
        result = nil;
    }
    
    return;
}

+(void)printAsterixKitchenReceiptWithKitchenData:(NSMutableArray *)kitchenData
{
    
    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"KR_Brand MATCHES[cd] %@",
                               @"Asterix"];
    
    NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"KR_OrderType MATCHES[cd] %@",
                               @"ItemOrder"];
    
    NSPredicate *finalPredicate1 = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate1, predicate2]];
    
    NSArray * itemOrderObject = [kitchenData filteredArrayUsingPredicate:finalPredicate1];
    
    for (int i = 0; i < itemOrderObject.count; i++) {
        NSPredicate *predicate3 = [NSPredicate predicateWithFormat:@"KR_ManualID MATCHES[cd] %@", [[itemOrderObject objectAtIndex:i] objectForKey:@"KR_ManualID"]];
        NSPredicate *predicate4 = [NSPredicate predicateWithFormat:@"KR_OrderType MATCHES[cd] %@",
                                   @"CondimentOrder"];
        
        NSPredicate *finalPredicate2 = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate3, predicate4]];
        
        NSArray * condimentOrderObject = [kitchenData filteredArrayUsingPredicate:finalPredicate2];
        
        if (condimentOrderObject.count > 0)
        {
            [PublicMethod printAsterixKitchenReceiptWithItemDesc:[[itemOrderObject objectAtIndex:i] objectForKey:@"KR_Desc"] IPAdd:[[itemOrderObject objectAtIndex:i] objectForKey:@"KR_IpAddress"] imQty:[[itemOrderObject objectAtIndex:i] objectForKey:@"KR_Qty"] TableName:[[itemOrderObject objectAtIndex:i] objectForKey:@"KR_TableName"] DataArray:condimentOrderObject];
        }
        else
        {
            [PublicMethod printAsterixKitchenReceiptWithItemDesc:[[itemOrderObject objectAtIndex:i] objectForKey:@"KR_Desc"] IPAdd:[[itemOrderObject objectAtIndex:i] objectForKey:@"KR_IpAddress"] imQty:[[itemOrderObject objectAtIndex:i] objectForKey:@"KR_Qty"] TableName:[[itemOrderObject objectAtIndex:i] objectForKey:@"KR_TableName"] DataArray:nil];
        }
        predicate3 = nil;
        predicate4 = nil;
        
    }
    predicate1 = nil;
    predicate2 = nil;
    
    //[PublicMethod printAsterixKitchenReceiptWithItemDesc:@"" IPAdd:@"192.168.0.13" imQty:@"" TableName:@"" DataArray:kitchenGroup];
    
}


+(void)printAsterixKitchenReceiptGroupFormatKitchenData:(NSMutableArray *)kitchenData
{
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:[[LibraryAPI sharedInstance] getDbPath]];
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rsPrinter = [db executeQuery:@"Select * from Printer where P_Type = ? and P_Brand = ?",@"Kitchen", @"Asterix"];
        while ([rsPrinter next]) {
            NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"KR_Brand MATCHES[cd] %@",
                                       @"Asterix"];
            
            NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"KR_IpAddress MATCHES[cd] %@",
                                       [rsPrinter stringForColumn:@"P_PortName"]];
            
            NSPredicate *finalPredicate1 = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate1, predicate2]];
            
            NSArray * itemOrderObject = [kitchenData filteredArrayUsingPredicate:finalPredicate1];
            NSMutableString *mString = [[NSMutableString alloc]init];
            NSString *tableName;
            for (int i = 0; i < itemOrderObject.count; i++) {
                if ([[[itemOrderObject objectAtIndex:i] objectForKey:@"KR_OrderType"]isEqualToString:@"ItemOrder"]) {
                    tableName = [[itemOrderObject objectAtIndex:i] objectForKey:@"KR_TableName"];
                    
                    NSPredicate *predicate3 = [NSPredicate predicateWithFormat:@"KR_ManualID MATCHES[cd] %@", [[itemOrderObject objectAtIndex:i] objectForKey:@"KR_ManualID"]];
                    NSPredicate *predicate4 = [NSPredicate predicateWithFormat:@"KR_OrderType MATCHES[cd] %@",
                                               @"CondimentOrder"];
                    
                    NSPredicate *finalPredicate2 = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate3, predicate4]];
                    
                    NSArray * condimentOrderObject = [kitchenData filteredArrayUsingPredicate:finalPredicate2];
                    
                    [mString appendString:[PublicMethod makeKitchenGroupReceiptFormatWithItemDesc:[[itemOrderObject objectAtIndex:i] objectForKey:@"KR_Desc"] ItemQty:[[itemOrderObject objectAtIndex:i] objectForKey:@"KR_Qty"]PackageName:@"" ShowPackageDetail:0 PrinterBrand:@"Asterix"]];
                    
                    for (int j = 0; j < condimentOrderObject.count; j++) {
                        [mString appendString:[NSString stringWithFormat:@" - %@ %@\r\n",[[condimentOrderObject objectAtIndex:j]objectForKey:@"KR_Desc"],[[condimentOrderObject objectAtIndex:j] objectForKey:@"KR_Qty"]]];
                        [mString appendString:@"\r\n"];
                    }
                    
                    condimentOrderObject = nil;
                    predicate3 = nil;
                    predicate4 = nil;
                    
                }
            }
            itemOrderObject = nil;
            
            [PublicMethod printAsterixKRGroupWithIpAdd:[rsPrinter stringForColumn:@"P_PortName"] TableName:tableName Data:mString];
            
            predicate1 = nil;
            predicate2 = nil;
            
        }
    }];
    
}


+(NSArray *)manuallyConvertAccReturnJsonWithData:(NSData *)data
{
    NSString* responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSLog(@"response1: %@",responseString);
    
    responseString = [responseString stringByReplacingOccurrencesOfString:@"\""
                                                               withString:@""];
    responseString = [responseString stringByReplacingOccurrencesOfString:@"'"
                                                               withString:@"\""];
    
    
    responseString = [NSString stringWithFormat:@"[%@]",responseString];
    
    NSData* data2 = [responseString dataUsingEncoding:NSUTF8StringEncoding];
    
    return [NSJSONSerialization JSONObjectWithData:data2 options:NSJSONReadingMutableContainers error:nil];
}

+(void)removeExistingFileFromDirectoryWithFileName:(NSString *)fileName
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSString *filePath = [NSString stringWithFormat:@"%@/%@",
                          documentsPath,fileName];
    NSError *error;
    
    if([fileManager fileExistsAtPath:filePath])
    {
        [fileManager removeItemAtPath:filePath error:&error];
    }
}

// detail1 is itemdesc with space itemDesc is original item desc
+(NSString *)processChineseOrEnglishCharWithDetail1:(NSString *)detail1 ItemDesc:(NSString *)itemDesc FixLength:(NSUInteger)fixLength
{
    NSString * nsText = [NSString stringWithFormat:@"%@", itemDesc];
    NSUInteger chineseChar = 0;
    NSUInteger englishChar = 0;
    
    for (int i = 0; i < [nsText length]; i++)
    {
        unichar current = [nsText characterAtIndex:i];
        NSString *rr = [NSString stringWithFormat:@"%C",current];
        NSRegularExpression *regex = [[NSRegularExpression alloc]
                                      initWithPattern:@"[A-Za-z0-9?/;*+_ :()-.,#~&%=@<>{}|`!]" options:0 error:NULL];
        
        // Assuming you have some NSString `myString`.
        NSUInteger matches = [regex numberOfMatchesInString:rr options:0
                                                      range:NSMakeRange(0, [rr length])];
        
        if (matches > 0) {
            englishChar++;
        }
        else{
            chineseChar++;
        }
        
    }
    
    if (chineseChar > 0) {
        if (chineseChar > 10) {
            detail1 = [detail1 substringToIndex:fixLength - chineseChar];
            detail1 = [NSString stringWithFormat:@"%@ ",detail1];
        }
        else
        {
            detail1 = [detail1 substringToIndex:fixLength - chineseChar];
        }
    }
    else
    {
        detail1 = detail1;
    }
    
    return detail1;
}

+(NSMutableArray *)softingOrderCondimentWithEditedCondimentDtl:(NSMutableArray *)array DisplayFormat:(NSString *)displayFormat TotalCondimentPrice:(double)totalCondimentPrice ParentIndex:(NSString *)parentIndex CondimentUnitPrice:(double)condimentUnitPrice OriginalArray:(NSMutableArray *)orgArray FromView:(NSString *)fromView KeyName:(NSString *)keyName
{
    NSMutableArray *discardedItems = [NSMutableArray array];
    NSString *flag;
    for (int i = 0; i < orgArray.count; i++) {
        if ([[[orgArray objectAtIndex:i] objectForKey:@"ParentIndex"] isEqualToString:parentIndex])
        {
            [discardedItems addObject:[orgArray objectAtIndex:i]];
        }
    }
    [orgArray removeObjectsInArray:discardedItems];
    
    NSUInteger insertIndex = 0;
    for (int i = 0; i < orgArray.count; i++) {
        if ([[[orgArray objectAtIndex:i] objectForKey:keyName] isEqualToString:parentIndex]) {
            if (orgArray.count == i+1) {
                insertIndex = i + 1;
                
            }
            else
            {
                insertIndex = i;
                
                
            }
            
        }
    }
    
    if (insertIndex == orgArray.count) {
        flag = @"FirstItem";
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        data = [orgArray objectAtIndex:insertIndex-1];
        if ([fromView isEqualToString:@"Ordering"]) {
            [data setValue:[NSString stringWithFormat:@"%0.2f",totalCondimentPrice] forKey:@"IM_NewTotalCondimentSurCharge"];
        }
        else{
            [data setValue:[NSString stringWithFormat:@"%0.2f",totalCondimentPrice] forKey:@"PD_NewTotalCondimentSurCharge"];
            [data setValue:[NSString stringWithFormat:@"%0.2f",totalCondimentPrice] forKey:@"IM_NewTotalCondimentSurCharge"];
            [data setValue:@"Yes" forKey:@"UnderPackageItemYN"];
        }
        
        [orgArray replaceObjectAtIndex:insertIndex-1 withObject:data];
        
        [orgArray addObjectsFromArray:array];
        data = nil;
    }
    else
    {
        flag = @"MoreItem";
        for (int j = 0; j < array.count; j++) {
            [orgArray insertObject:[array objectAtIndex:j] atIndex:insertIndex + 1];
        }
        
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        data = [orgArray objectAtIndex:insertIndex];
        
        if ([fromView isEqualToString:@"Ordering"]) {
            [data setValue:[NSString stringWithFormat:@"%0.2f",totalCondimentPrice] forKey:@"IM_NewTotalCondimentSurCharge"];
        }
        else{
            [data setValue:[NSString stringWithFormat:@"%0.2f",totalCondimentPrice] forKey:@"PD_NewTotalCondimentSurCharge"];
            [data setValue:[NSString stringWithFormat:@"%0.2f",totalCondimentPrice] forKey:@"IM_NewTotalCondimentSurCharge"];
            [data setValue:@"Yes" forKey:@"UnderPackageItemYN"];
        }
        
        //[data setValue:[NSString stringWithFormat:@"%0.2f",totalCondimentPrice] forKey:@"PD_NewTotalCondimentSurCharge"];
        [orgArray replaceObjectAtIndex:insertIndex withObject:data];
        data = nil;
    }
    
    NSMutableDictionary *insertIndexDict = [NSMutableDictionary dictionary];
    [insertIndexDict setObject:[NSString stringWithFormat:@"%lu",insertIndex] forKey:@"InsertIndex"];
    [insertIndexDict setObject:flag forKey:@"Flag"];
    
    [orgArray addObject:insertIndexDict];
    insertIndexDict = nil;
    return orgArray;

}


+(UIViewController *) getTopViewController {
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}

@end
