//
//  TerminalData.m
//  IpadOrder
//
//  Created by IRS on 28/01/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import "TerminalData.h"
#import "LibraryAPI.h"
#import "AppDelegate.h"

AppDelegate *appDelegate;

@implementation TerminalData

+(BOOL)insertSalesOrderIntoMainWithOrderType:(NSString *)orderType sqlitePath:(NSString *)dbPath OrderData:(NSArray *)orderFinalArray OrderDate:(NSString *)date terminalArray:(NSArray *)terminalArray terminalName:(NSString *)terminalName PayType:(NSString *)payType
{
    //FMDatabase *dbTable;
    __block BOOL result = YES;
    __block NSString *docNo;
    __block NSString *errMsg;
    
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSUInteger taxIncludedYN = 0;
        NSString *modifierID = @"";
        NSString *modifierHdrCode = @"";
        
        if ([[[LibraryAPI sharedInstance] getTaxType] isEqualToString:@"IEx"]) {
            taxIncludedYN = 0;
        }
        else
        {
            taxIncludedYN = 1;
        }
        
        FMResultSet *docRs = [db executeQuery:@"Select DOC_Number,DOC_Header from DocNo"
                              " where DOC_Header = 'SO'"];
        int updateDocNo = 0;
        
        if ([docRs next]) {
            updateDocNo = [docRs intForColumn:@"DOC_Number"] + 1;
            docNo = [NSString stringWithFormat:@"%@%09.f",[docRs stringForColumn:@"DOC_Header"],[[docRs stringForColumn:@"DOC_Number"]doubleValue] + 1];
        }
        [docRs close];
        
        @try {
            [db executeUpdate:@"Insert into SalesOrderHdr ("
             "SOH_DocNo,SOH_Date,SOH_DocAmt,SOH_DiscAmt,SOH_Rounding,SOH_Table,SOH_User,SOH_AcctCode,SOH_Status, SOH_DocSubTotal,SOH_DocTaxAmt,SOH_DocServiceTaxAmt,SOH_DocServiceTaxGstAmt,SOH_PaxNo,SOH_TerminalName,SOH_TaxIncluded_YN,SOH_ServiceTaxGstCode,SOH_CustName,SOH_CustAdd1,SOH_CustAdd2,SOH_CustAdd3,SOH_CustTelNo,SOH_CustGstNo)"
             "values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",docNo,date,[[orderFinalArray objectAtIndex:0] objectForKey:@"IM_labelTotal"],[[orderFinalArray objectAtIndex:0] objectForKey:@"IM_labelTotalDiscount"],[[orderFinalArray objectAtIndex:0] objectForKey:@"IM_labelRound"],[[orderFinalArray objectAtIndex:0] objectForKey:@"IM_Table"],[[LibraryAPI sharedInstance] getUserName],@"Cash",@"New",[[orderFinalArray objectAtIndex:0] objectForKey:@"IM_labelSubTotal"],[[orderFinalArray objectAtIndex:0] objectForKey:@"IM_labelTaxTotal"],[[orderFinalArray objectAtIndex:0] objectForKey:@"IM_labelServiceTaxTotal"],[[orderFinalArray objectAtIndex:0] objectForKey:@"IM_serviceTaxGstTotal"],[[orderFinalArray objectAtIndex:0] objectForKey:@"SOH_PaxNo"],terminalName,[NSNumber numberWithInteger:taxIncludedYN],[[LibraryAPI sharedInstance] getServiceTaxGstCode],[[orderFinalArray objectAtIndex:0] objectForKey:@"CName"],[[orderFinalArray objectAtIndex:0] objectForKey:@"CAdd1"],[[orderFinalArray objectAtIndex:0] objectForKey:@"CAdd2"],[[orderFinalArray objectAtIndex:0] objectForKey:@"CAdd3"],[[orderFinalArray objectAtIndex:0] objectForKey:@"CTelNo"],[[orderFinalArray objectAtIndex:0] objectForKey:@"CGstNo"]];
            
            if (![db hadError]) {
                for (int i = 0; i < orderFinalArray.count; i++) {
                    if ([[[orderFinalArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"] || [[[orderFinalArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"PackageItemOrder"])
                    {
                        
                        if ([[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_ServiceType"] isEqualToString:@"1"])
                        {
                            modifierID = [NSString stringWithFormat:@"M%@-%@",docNo,[[orderFinalArray objectAtIndex:i] objectForKey:@"Index"]];
                        }
                        else
                        {
                            if ([[[orderFinalArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"]) {
                                modifierID = @"";
                            }
                        }
                        
                        if ([[[orderFinalArray objectAtIndex:i] objectForKey:@"PD_ModifierHdrCode"] length] > 0) {
                            modifierHdrCode = [[orderFinalArray objectAtIndex:i] objectForKey:@"PD_ModifierHdrCode"];
                        }
                        else{
                            modifierHdrCode = @"";
                        }
                        
                        [db executeUpdate:@"Insert into SalesOrderDtl "
                         "(SOD_AcctCode, SOD_DocNo, SOD_ItemCode, SOD_ItemDescription, SOD_Quantity, SOD_Price, SOD_DiscValue, SOD_SellingPrice, SOD_UnitPrice, SOD_Remark, SOD_TakeAway_YN,SOD_DiscType,SOD_SellTax,SOD_TotalSalesTax,SOD_TotalSalesTaxLong,SOD_TotalEx,SOD_TotalExLong,SOD_TotalInc,SOD_TotalDisc,SOD_SubTotal,SOD_DiscInPercent, SOD_TaxCode, SOD_ServiceTaxCode, SOD_ServiceTaxAmt, SOD_TaxRate,SOD_ServiceTaxRate,SOD_TakeAwayYN,SOD_TerminalName,SOD_TotalCondimentSurCharge,SOD_ManualID, SOD_ModifierID, SOD_ModifierHdrCode) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",@"Cash",docNo,[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_ItemCode"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Description"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Qty"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_SalesPrice"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Discount"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_SellingPrice"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Price"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Remark"],[NSNumber numberWithInt:0],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_DiscountType"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Tax"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_TotalTax"],
                         [[orderFinalArray objectAtIndex:i] objectForKey:@"IM_totalItemTaxAmtLong"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_totalItemSellingAmt"],
                         [[orderFinalArray objectAtIndex:i] objectForKey:@"IM_totalItemSellingAmtLong"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Total"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_DiscountAmt"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_SubTotal"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_DiscountInPercent"],([[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_GSTCode"] isEqualToString:@"-"])?nil:[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_GSTCode"],([[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_ServiceTaxCode"] isEqualToString:@"-"])?nil:[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_ServiceTaxCode"],[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_ServiceTaxAmt"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Gst"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_ServiceTaxRate"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_TakeAwayYN"],terminalName,[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_TotalCondimentSurCharge"],[NSString stringWithFormat:@"%@-%@",docNo,[[orderFinalArray objectAtIndex:i] objectForKey:@"Index"]],modifierID, modifierHdrCode];
                    }
                    else
                    {
                        [db executeUpdate:@"Insert into SalesOrderCondiment"
                         " (SOC_DocNo, SOC_ItemCode, SOC_CHCode, SOC_CDCode, SOC_CDDescription, SOC_CDPrice, SOC_CDDiscount, SOC_DateTime,SOC_CDQty,SOC_CDManualKey) Values (?,?,?,?,?,?,?,?,?,?)",docNo,[[orderFinalArray objectAtIndex:i] objectForKey:@"ItemCode"],[[orderFinalArray objectAtIndex:i] objectForKey:@"CHCode"],[[orderFinalArray objectAtIndex:i] objectForKey:@"CDCode"],[[orderFinalArray objectAtIndex:i] objectForKey:@"CDDescription"],[[orderFinalArray objectAtIndex:i] objectForKey:@"CDPrice"],[NSNumber numberWithDouble:0.00],date,[[orderFinalArray objectAtIndex:i] objectForKey:@"UnitQty"],[NSString stringWithFormat:@"%@-%@",docNo,[[orderFinalArray objectAtIndex:i] objectForKey:@"ParentIndex"]]];
                    }
                    
                    
                    
                    if ([db hadError]) {
                        
                        //[self showAlertView:[dbTable lastErrorMessage] title:@"Fail"];
                        errMsg = [db lastErrorMessage];
                        *rollback = YES;
                        result = NO;
                        
                        //return;
                    }
                    else
                    {
                        [db executeUpdate:@"Update DocNo set DOC_Number = ? where DOC_Header = 'SO'",[NSNumber numberWithInt:updateDocNo]];
                        if ([db hadError]) {
                            
                            //[self showAlertView:[dbTable lastErrorMessage] title:@"Fail"];
                            errMsg = [db lastErrorMessage];
                            *rollback = YES;
                            result = NO;
                            //return;
                        }
                    }
                }
                if ([orderType isEqualToString:@"sales"] && result == YES) {
                    result = YES;
                }
                
            }
            else
            {
                errMsg = [db lastErrorMessage];
                result = NO;
                *rollback = YES;
            }
        } @catch (NSException *exception) {
            errMsg = @"Insert exception error";
            result = NO;
            *rollback = YES;
        } @finally {
            
        }
        
        
        
    }];
    
    NSError *error;
    NSMutableArray *returnData = [[NSMutableArray alloc] init];
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [returnData removeAllObjects];

    if (result == NO) {
        
        [data setObject:@"False" forKey:@"Result"];
        [data setObject:errMsg forKey:@"Message"];
        [data setObject:@"Server" forKey:@"IM_Flag"];
        
        [returnData addObject:data];
    }
    else if (result == YES)
    {
        [data setObject:@"True" forKey:@"Result"];
        [data setObject:@"Success" forKey:@"Message"];
        [data setObject:@"Server" forKey:@"IM_Flag"];
        [data setObject:docNo forKey:@"DocNo"];
        
        [returnData addObject:data];
    }
    //NSLog(@"Log Check 2: %@",@"Complete Sales Order");
    data = nil;
    NSData *dataToBeReturn = [NSKeyedArchiver archivedDataWithRootObject:returnData];
    returnData = nil;
    [appDelegate.mcManager.session sendData:dataToBeReturn
                                    toPeers:terminalArray
                                   withMode:MCSessionSendDataReliable
                                      error:&error];
    
    [queue close];
    
    //[dbTable close];

    return result;
    
}

+(BOOL)updateSalesOrderIntoMainWithOrderType:(NSString *)orderType sqlitePath:(NSString *)dbPath OrderData:(NSArray *)orderFinalArray OrderDate:(NSString *)date DocNo:(NSString *)docNo terminalArray:(NSArray *)terminalArray terminalName:(NSString *)terminalName ToWhichView:(NSString *)toView PayType:(NSString *)payType  OptionSelected:(NSString *)optionSelected FromSalesOrderNo:(NSString *)fromSalesOrderNo
{
    //NSLog(@"%@",orderFinalArray);
    
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    __block BOOL result = YES;
    __block NSString *errMsg;
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSUInteger taxIncludedYN = 0;
        NSString *modifierID = @"";
        NSString *modifierHdrCode = @"";
        
        if ([[[LibraryAPI sharedInstance] getTaxType] isEqualToString:@"IEx"]) {
            taxIncludedYN = 0;
        }
        else
        {
            taxIncludedYN = 1;
        }
        
        if ([optionSelected isEqualToString:@"CombineTable"]) {
            [db executeUpdate:@"Delete from SalesOrderHdr where SOH_DocNo = ? ", fromSalesOrderNo];
            [db executeUpdate:@"Delete from SalesOrderDtl where SOD_DocNo = ? ", fromSalesOrderNo];
            [db executeUpdate:@"Delete from SalesOrderCondiment where SOC_DocNo = ? ", fromSalesOrderNo];
            [db executeUpdate:@"Delete from SalesOrderCondiment where SOC_DocNo = ?", docNo];
        }
        else if ([optionSelected isEqualToString:@"TransferTable"])
        {
            [db executeUpdate:@"Delete from SalesOrderCondiment where SOC_DocNo = ?", docNo];
        }
        
        @try {
            [db executeUpdate:@"Update SalesOrderHdr set "
             " SOH_Date = ?, SOH_DocAmt = ?, SOH_DiscAmt = ?, SOH_Rounding = ?, SOH_Table = ?"
             ", SOH_User = ?, SOH_AcctCode = ?, SOH_Status = ?, SOH_DocSubTotal = ?,SOH_DocTaxAmt=?, SOH_DocServiceTaxAmt = ?, SOH_DocServiceTaxGstAmt =?, SOH_PaxNo = ?, SOH_TaxIncluded_YN = ?, SOH_ServiceTaxGstCode = ?, SOH_CustName = ?,SOH_CustAdd1 = ?,SOH_CustAdd2 = ?,SOH_CustAdd3 = ?,SOH_CustTelNo = ?,SOH_CustGstNo = ? where SOH_DocNo = ?",
             date,[[orderFinalArray objectAtIndex:0] objectForKey:@"IM_labelTotal"],[[orderFinalArray objectAtIndex:0] objectForKey:@"IM_labelTotalDiscount"],[[orderFinalArray objectAtIndex:0] objectForKey:@"IM_labelRound"] ,[[orderFinalArray objectAtIndex:0] objectForKey:@"IM_TableName"],[[LibraryAPI sharedInstance] getUserName],@"Cash",@"New",[[orderFinalArray objectAtIndex:0] objectForKey:@"IM_labelSubTotal"],[[orderFinalArray objectAtIndex:0] objectForKey:@"IM_labelTaxTotal"],[[orderFinalArray objectAtIndex:0] objectForKey:@"IM_labelServiceTaxTotal"],[[orderFinalArray objectAtIndex:0] objectForKey:@"IM_serviceTaxGstTotal"],[[orderFinalArray objectAtIndex:0] objectForKey:@"SOH_PaxNo"],[NSNumber numberWithInteger:taxIncludedYN],[[LibraryAPI sharedInstance] getServiceTaxGstCode],[[orderFinalArray objectAtIndex:0] objectForKey:@"CName"],[[orderFinalArray objectAtIndex:0] objectForKey:@"CAdd1"],[[orderFinalArray objectAtIndex:0] objectForKey:@"CAdd2"],[[orderFinalArray objectAtIndex:0] objectForKey:@"CAdd3"],[[orderFinalArray objectAtIndex:0] objectForKey:@"CTelNo"],[[orderFinalArray objectAtIndex:0] objectForKey:@"CGstNo"],docNo];
            
            if (![db hadError]) {
                [db executeUpdate:@"Delete from SalesOrderDtl where SOD_DocNo = ?", docNo];
                if ([toView isEqualToString:@"Ordering"]) {
                    [db executeUpdate:@"Delete from SalesOrderCondiment where SOC_DocNo = ?", docNo];
                }
                
                if ([db hadError])
                {
                    errMsg = [db lastErrorMessage];
                    *rollback = YES;
                    result = NO;;
                }
                else
                {
                    for (int i = 0; i < orderFinalArray.count; i++) {
                        
                        if ([[[orderFinalArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"] ||
                            [[[orderFinalArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"PackageItemOrder"])
                        {
                            
                            if ([[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_ServiceType"] isEqualToString:@"1"])
                            {
                                modifierID = [NSString stringWithFormat:@"M%@-%@",docNo,[[orderFinalArray objectAtIndex:i] objectForKey:@"Index"]];
                            }
                            else
                            {
                                if ([[[orderFinalArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"]) {
                                    modifierID = @"";
                                }
                            }
                            
                            //SOD_ModifierHdrCode
                            if ([[[orderFinalArray objectAtIndex:i] objectForKey:@"PD_ModifierHdrCode"] length] > 0) {
                                modifierHdrCode = [[orderFinalArray objectAtIndex:i] objectForKey:@"PD_ModifierHdrCode"];
                            }
                            else{
                                modifierHdrCode = @"";
                            }
                            
                            [db executeUpdate:@"Insert into SalesOrderDtl "
                             "(SOD_AcctCode, SOD_DocNo, SOD_ItemCode, SOD_ItemDescription, SOD_Quantity, SOD_Price, SOD_DiscValue, SOD_SellingPrice, SOD_UnitPrice, SOD_Remark, SOD_TakeAway_YN,SOD_DiscType,SOD_SellTax,SOD_TotalSalesTax,SOD_TotalSalesTaxLong,SOD_TotalEx,SOD_TotalExLong,SOD_TotalInc,SOD_TotalDisc,SOD_SubTotal,SOD_DiscInPercent,SOd_TaxCode,SOD_ServiceTaxCode, SOD_ServiceTaxAmt, SOD_TaxRate,SOD_ServiceTaxRate,SOD_TakeAwayYN,SOD_TerminalName,SOD_TotalCondimentSurCharge, SOD_ManualID, SOD_ModifierID, SOD_ModifierHdrCode) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",@"Cash",docNo,[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_ItemCode"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Description"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Qty"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_SalesPrice"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Discount"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_SellingPrice"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Price"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Remark"],[NSNumber numberWithInt:0],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_DiscountType"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Tax"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_TotalTax"],
                             [[orderFinalArray objectAtIndex:i] objectForKey:@"IM_totalItemTaxAmtLong"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_totalItemSellingAmt"],
                             [[orderFinalArray objectAtIndex:i] objectForKey:@"IM_totalItemSellingAmtLong"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Total"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_DiscountAmt"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_SubTotal"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_DiscountInPercent"],([[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_GSTCode"] isEqualToString:@"-"])?nil:[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_GSTCode"],([[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_ServiceTaxCode"] isEqualToString:@"-"])?nil:[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_ServiceTaxCode"],[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_ServiceTaxAmt"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Gst"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_ServiceTaxRate"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_TakeAwayYN"],terminalName,[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_TotalCondimentSurCharge"],[NSString stringWithFormat:@"%@-%@",docNo,[[orderFinalArray objectAtIndex:i] objectForKey:@"Index"]], modifierID, modifierHdrCode];
                            
                            
                        }
                        else if ([[[orderFinalArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"CondimentOrder"])
                        {
                            [db executeUpdate:@"Insert into SalesOrderCondiment"
                             " (SOC_DocNo, SOC_ItemCode, SOC_CHCode, SOC_CDCode, SOC_CDDescription, SOC_CDPrice, SOC_CDDiscount, SOC_DateTime,SOC_CDQty,SOC_CDManualKey) Values (?,?,?,?,?,?,?,?,?,?)",docNo,[[orderFinalArray objectAtIndex:i] objectForKey:@"ItemCode"],[[orderFinalArray objectAtIndex:i] objectForKey:@"CHCode"],[[orderFinalArray objectAtIndex:i] objectForKey:@"CDCode"],[[orderFinalArray objectAtIndex:i] objectForKey:@"CDDescription"],[[orderFinalArray objectAtIndex:i] objectForKey:@"CDPrice"],[NSNumber numberWithDouble:0.00],date,[[orderFinalArray objectAtIndex:i] objectForKey:@"UnitQty"],[NSString stringWithFormat:@"%@-%@",docNo,[[orderFinalArray objectAtIndex:i] objectForKey:@"ParentIndex"]]];
                        }
                        else
                        {
                            [db executeUpdate:@"Insert into Sa"];
                        }
                        
                        
                        if ([db hadError]) {
                            errMsg = [db lastErrorMessage];
                            *rollback = YES;
                            result = NO;
                        }
                        
                    }
                    if ([orderType isEqualToString:@"sales"] && result == YES) {
                        result = YES;
                        
                    }
                    
                    
                }
                
            }
            else
            {
                errMsg = [db lastErrorMessage];
                result = NO;
                *rollback = YES;
            }

        } @catch (NSException *exception) {
            errMsg = @"Update sales order exception error";
            result = NO;
            *rollback = YES;
        } @finally {
    
        }
        
    }];
    
    NSError *error;
    NSMutableArray *returnData = [[NSMutableArray alloc] init];
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [returnData removeAllObjects];
    
    if (result == NO) {
        
        [data setObject:@"False" forKey:@"Result"];
        [data setObject:@"Unable To Connect" forKey:@"Message"];
        [data setObject:@"Server" forKey:@"IM_Flag"];
        
        [returnData addObject:data];
    }
    else if (result == YES)
    {
        [data setObject:@"True" forKey:@"Result"];
        [data setObject:@"Success" forKey:@"Message"];
        if ([toView isEqualToString:@"Ordering"]) {
            [data setObject:@"Server" forKey:@"IM_Flag"];
        }
        else
        {
            [data setObject:@"RecalculateTablePlanTransferSalesOrderResult" forKey:@"IM_Flag"];
            /*
            if ([optionSelected isEqualToString:@"TransferTable"]) {
                [data setObject:@"RecalculateTablePlanTransferSalesOrderResult" forKey:@"IM_Flag"];
            }
            else
            {
                [data setObject:@"RecalculateTransferSalesOrderResult" forKey:@"IM_Flag"];
            }
             */
            
        }
        [data setObject:docNo forKey:@"DocNo"];
        
        [returnData addObject:data];
    }
    
    data = nil;
    if (![terminalName isEqualToString:@"Main"]) {
        NSData *dataToBeReturn = [NSKeyedArchiver archivedDataWithRootObject:returnData];
        returnData = nil;
        [appDelegate.mcManager.session sendData:dataToBeReturn
                                        toPeers:terminalArray
                                       withMode:MCSessionSendDataReliable
                                          error:&error];
    }
    
    
    [queue close];
    
    return result;
}

+(BOOL)insertInvoiceIntoMainWithSqlitePath:(NSString *)dbPath InvData:(NSArray *)invData InvDate:(NSString *)date terminalArray:(NSArray *)terminalArray TerminalName:(NSString *)terminalName
{
    __block BOOL result = YES;
    __block NSString *finalInvNo;
    __block NSString *errMsg;
    
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        //double totalPayAmt = 0.00;
        //NSString *tableName;
        NSString *invNo;
        NSUInteger taxIncludedYN = 0;
        NSString *invModifierID = @"";
        NSString *invModifierHdrCode = @"";
        
        if ([[[LibraryAPI sharedInstance] getTaxType] isEqualToString:@"IEx"]) {
            taxIncludedYN = 0;
        }
        else
        {
            taxIncludedYN = 1;
        }
        
        int updateDocNo = 0;
        @try {
            if ([[[invData objectAtIndex:0] objectForKey:@"PayDocType"] isEqualToString:@"CashSales"])
            {
                invNo = [[invData objectAtIndex:0] objectForKey:@"SOH_DocNo"];
                [db executeUpdate:@"Delete from InvoiceHdr where IvH_DocNo = ?",[[invData objectAtIndex:0] objectForKey:@"SOH_DocNo"]];
                [db executeUpdate:@"Delete from InvoiceDtl where IvD_DocNo = ?",[[invData objectAtIndex:0] objectForKey:@"SOH_DocNo"]];
                [db executeUpdate:@"Delete from InvoiceCondiment where IVC_DocNo = ?",[[invData objectAtIndex:0] objectForKey:@"SOH_DocNo"]];
            }
            else
            {
                FMResultSet *docRs = [db executeQuery:@"Select DOC_Number,DOC_Header from DocNo"
                                      " where DOC_Header = 'CS'"];
                
                if ([docRs next]) {
                    updateDocNo = [docRs intForColumn:@"DOC_Number"] + 1;
                    invNo = [NSString stringWithFormat:@"%@%09.f",[docRs stringForColumn:@"DOC_Header"],[[docRs stringForColumn:@"DOC_Number"]doubleValue] + 1];
                }
                [docRs close];
            }
        
        
            if ([[[invData objectAtIndex:0] objectForKey:@"IvH_PaymentTypeQty"] integerValue] == 1) {
                [db executeUpdate:@"Insert into InvoiceHdr ("
                 "IvH_DocNo,IvH_Date,IvH_DocAmt,IvH_DiscAmt,IvH_Rounding,IvH_Table,IvH_User,IvH_AcctCode,IvH_Status, IvH_DocSubTotal,IvH_DocTaxAmt,IvH_ChangeAmt,IvH_TotalPay,IvH_PaymentType1,IvH_PaymentAmt1,IvH_PaymentRef1,IvH_DocServiceTaxAmt,IvH_DocServiceTaxGstAmt,IvH_DocRef,IvH_PaxNo, IvH_SoNo,IvH_TerminalName,IvH_TaxIncluded_YN,IvH_ServiceTaxGstCode,IvH_CustName,IvH_CustAdd1,IvH_CustAdd2,IvH_CustAdd3,IvH_CustTelNo,IvH_CustGstNo)"
                 "values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",invNo,date,[[invData objectAtIndex:0] objectForKey:@"SOH_DocAmt"],[[invData objectAtIndex:0] objectForKey:@"SOH_DiscAmt"],[[invData objectAtIndex:0] objectForKey:@"SOH_Rounding"],[[invData objectAtIndex:0] objectForKey:@"IM_TableName"],[[invData objectAtIndex:0] objectForKey:@"IvH_UserName"],@"Cash",@"Pay",[[invData objectAtIndex:0] objectForKey:@"SOH_DocSubTotal"],[[invData objectAtIndex:0] objectForKey:@"SOH_DocTaxAmt"],[[invData objectAtIndex:0] objectForKey:@"SOH_ChangeAmt"],[[invData objectAtIndex:0] objectForKey:@"SOH_PayAmt"],[[invData objectAtIndex:0] objectForKey:@"IvH_PaymentType1"],[[invData objectAtIndex:0] objectForKey:@"IvH_PaymentAmt1"],[[invData objectAtIndex:0] objectForKey:@"IvH_PaymentRef1"],[[invData objectAtIndex:0] objectForKey:@"SOH_DocServiceTaxAmt"],[[invData objectAtIndex:0] objectForKey:@"SOH_DocServiceTaxGstAmt"],[[invData objectAtIndex:0] objectForKey:@"IvH_DocRef"],[[invData objectAtIndex:0] objectForKey:@"SOH_PaxNo"],[[invData objectAtIndex:0] objectForKey:@"SOH_DocNo"],terminalName,[NSNumber numberWithInteger:taxIncludedYN],[[LibraryAPI sharedInstance] getServiceTaxGstCode],[[invData objectAtIndex:0] objectForKey:@"CName"],[[invData objectAtIndex:0] objectForKey:@"CAdd1"],[[invData objectAtIndex:0] objectForKey:@"CAdd2"],[[invData objectAtIndex:0] objectForKey:@"CAdd3"],[[invData objectAtIndex:0] objectForKey:@"CTelNo"],[[invData objectAtIndex:0] objectForKey:@"CGstNo"]];
            }
            else
            {
                [db executeUpdate:@"Insert into InvoiceHdr ("
                 "IvH_DocNo,IvH_Date,IvH_DocAmt,IvH_DiscAmt,IvH_Rounding,IvH_Table,IvH_User,IvH_AcctCode,IvH_Status, IvH_DocSubTotal,IvH_DocTaxAmt,IvH_ChangeAmt,IvH_TotalPay,IvH_PaymentType1,IvH_PaymentAmt1,IvH_PaymentRef1,IvH_DocServiceTaxAmt,IvH_DocServiceTaxGstAmt"
                 
                 ",IvH_PaymentType2,IvH_PaymentAmt2,IvH_PaymentRef2"
                 ",IvH_PaymentType3,IvH_PaymentAmt3,IvH_PaymentRef3"
                 ",IvH_PaymentType4,IvH_PaymentAmt4,IvH_PaymentRef4"
                 ",IvH_PaymentType5,IvH_PaymentAmt5,IvH_PaymentRef5"
                 ",IvH_PaymentType6,IvH_PaymentAmt6,IvH_PaymentRef6"
                 ",IvH_PaymentType7,IvH_PaymentAmt7,IvH_PaymentRef7"
                 ",IvH_PaymentType8,IvH_PaymentAmt8,IvH_PaymentRef8"
                 ",IvH_DocRef, IvH_PaxNo, IvH_SoNo,IvH_TerminalName,IvH_TaxIncluded_YN,IvH_ServiceTaxGstCode"
                 ",IvH_CustName,IvH_CustAdd1,IvH_CustAdd2,IvH_CustAdd3,IvH_CustTelNo,IvH_CustGstNo)"
                 "values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",invNo,date,[[invData objectAtIndex:0] objectForKey:@"SOH_DocAmt"],[[invData objectAtIndex:0] objectForKey:@"SOH_DiscAmt"],[[invData objectAtIndex:0] objectForKey:@"SOH_Rounding"],[[invData objectAtIndex:0] objectForKey:@"IM_TableName"],[[invData objectAtIndex:0] objectForKey:@"IvH_UserName"],@"Cash",@"Pay",[[invData objectAtIndex:0] objectForKey:@"SOH_DocSubTotal"],[[invData objectAtIndex:0] objectForKey:@"SOH_DocTaxAmt"],[[invData objectAtIndex:0] objectForKey:@"SOH_ChangeAmt"],[[invData objectAtIndex:0] objectForKey:@"SOH_PayAmt"],[[invData objectAtIndex:0] objectForKey:@"IvH_PaymentType1"],[[invData objectAtIndex:0] objectForKey:@"IvH_PaymentAmt1"],[[invData objectAtIndex:0] objectForKey:@"IvH_PaymentRef1"],[[invData objectAtIndex:0] objectForKey:@"SOH_DocServiceTaxAmt"],[[invData objectAtIndex:0] objectForKey:@"SOH_DocServiceTaxGstAmt"]
                 ,[[invData objectAtIndex:0] objectForKey:@"IvH_PaymentType2"],[[invData objectAtIndex:0] objectForKey:@"IvH_PaymentAmt2"],[[invData objectAtIndex:0] objectForKey:@"IvH_PaymentRef2"]
                 ,[[invData objectAtIndex:0] objectForKey:@"IvH_PaymentType3"],[[invData objectAtIndex:0] objectForKey:@"IvH_PaymentAmt3"],[[invData objectAtIndex:0] objectForKey:@"IvH_PaymentRef3"]
                 ,[[invData objectAtIndex:0] objectForKey:@"IvH_PaymentType4"],[[invData objectAtIndex:0] objectForKey:@"IvH_PaymentAmt4"],[[invData objectAtIndex:0] objectForKey:@"IvH_PaymentRef4"]
                 ,[[invData objectAtIndex:0] objectForKey:@"IvH_PaymentType5"],[[invData objectAtIndex:0] objectForKey:@"IvH_PaymentAmt5"],[[invData objectAtIndex:0] objectForKey:@"IvH_PaymentRef5"]
                 ,[[invData objectAtIndex:0] objectForKey:@"IvH_PaymentType6"],[[invData objectAtIndex:0] objectForKey:@"IvH_PaymentAmt6"],[[invData objectAtIndex:0] objectForKey:@"IvH_PaymentRef6"]
                 ,[[invData objectAtIndex:0] objectForKey:@"IvH_PaymentType7"],[[invData objectAtIndex:0] objectForKey:@"IvH_PaymentAmt7"],[[invData objectAtIndex:0] objectForKey:@"IvH_PaymentRef7"]
                 
                 ,[[invData objectAtIndex:0] objectForKey:@"IvH_PaymentType8"],[[invData objectAtIndex:0] objectForKey:@"IvH_PaymentAmt8"],[[invData objectAtIndex:0] objectForKey:@"IvH_PaymentRef8"]
                 
                 ,[[invData objectAtIndex:0] objectForKey:@"IvH_DocRef"],[[invData objectAtIndex:0] objectForKey:@"SOH_PaxNo"]
                 ,[[invData objectAtIndex:0] objectForKey:@"SOH_DocNo"],terminalName,[NSNumber numberWithInteger:taxIncludedYN],[[LibraryAPI sharedInstance] getServiceTaxGstCode],[[invData objectAtIndex:0] objectForKey:@"CName"],[[invData objectAtIndex:0] objectForKey:@"CAdd1"],[[invData objectAtIndex:0] objectForKey:@"CAdd2"],[[invData objectAtIndex:0] objectForKey:@"CAdd3"],[[invData objectAtIndex:0] objectForKey:@"CTelNo"],[[invData objectAtIndex:0] objectForKey:@"CGstNo"]];
            }
            
            
            if (![db hadError]) {
                for (int i = 0; i < invData.count; i++) {
                    if ([[[invData objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"] ||
                        [[[invData objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"PackageItemOrder"]) {
                        
                        if ([[[invData objectAtIndex:i] objectForKey:@"IM_ServiceType"] isEqualToString:@"1"])
                        {
                            invModifierID = [NSString stringWithFormat:@"M%@-%@",invNo,[[invData objectAtIndex:i] objectForKey:@"Index"]];
                        }
                        else
                        {
                            if ([[[invData objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"]) {
                                invModifierID = @"";
                            }
                        }
                        
                        if ([[[invData objectAtIndex:i] objectForKey:@"SOD_ModifierHdrCode"] length] > 0) {
                            invModifierHdrCode = [[invData objectAtIndex:i] objectForKey:@"SOD_ModifierHdrCode"];
                        }
                        else{
                            invModifierHdrCode = @"";
                        }
                        
                        
                        [db executeUpdate:@"Insert into InvoiceDtl "
                         "(IvD_AcctCode, IvD_DocNo, IvD_ItemCode, IvD_ItemDescription, IvD_Quantity, IvD_Price, IvD_DiscValue, IvD_SellingPrice, IvD_UnitPrice, IvD_Remark, IvD_TakeAway_YN,IvD_DiscType,IvD_SellTax,IvD_TotalSalesTax,IvD_TotalSalesTaxLong,IvD_TotalEx,IvD_TotalExLong,IvD_TotalInc,IvD_TotalDisc,IvD_SubTotal,IvD_DiscInPercent,IvD_ItemTaxCode,IvD_ServiceTaxCode, IvD_TaxRate, IvD_ServiceTaxRate, IvD_ServiceTaxAmt,IvD_TakeAwayYN,IvD_TotalCondimentSurCharge,IvD_ManualID,IvD_ModifierID, IvD_ModifierHdrCode) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",@"Cash",invNo,[[invData objectAtIndex:i] objectForKey:@"IM_ItemCode"],[[invData objectAtIndex:i] objectForKey:@"IM_Description"],[[invData objectAtIndex:i] objectForKey:@"IM_Qty"],[[invData objectAtIndex:i] objectForKey:@"IM_SalesPrice"],[[invData objectAtIndex:i] objectForKey:@"IM_Discount"],[[invData objectAtIndex:i] objectForKey:@"IM_SellingPrice"],[[invData objectAtIndex:i] objectForKey:@"IM_Price"],[[invData objectAtIndex:i] objectForKey:@"IM_Remark"],[NSNumber numberWithInt:0],[[invData objectAtIndex:i] objectForKey:@"IM_DiscountType"],[[invData objectAtIndex:i] objectForKey:@"IM_Tax"],[[invData objectAtIndex:i] objectForKey:@"IM_TotalTax"],
                         [[invData objectAtIndex:i] objectForKey:@"IM_totalItemTaxAmtLong"],[[invData objectAtIndex:i] objectForKey:@"IM_totalItemSellingAmt"],
                         [[invData objectAtIndex:i] objectForKey:@"IM_totalItemSellingAmtLong"],[[invData objectAtIndex:i] objectForKey:@"IM_Total"],[[invData objectAtIndex:i] objectForKey:@"IM_DiscountAmt"],[[invData objectAtIndex:i] objectForKey:@"IM_SubTotal"],[[invData objectAtIndex:i] objectForKey:@"IM_DiscountInPercent"],([[[invData objectAtIndex:i]objectForKey:@"IM_GSTCode"] isEqualToString:@"-"])?nil:[[invData objectAtIndex:i]objectForKey:@"IM_GSTCode"],([[[invData objectAtIndex:i]objectForKey:@"IM_ServiceTaxCode"] isEqualToString:@"-"])?nil:[[invData objectAtIndex:i]objectForKey:@"IM_ServiceTaxCode"],[[invData objectAtIndex:i]objectForKey:@"IM_Gst"],[[invData objectAtIndex:i]objectForKey:@"IM_ServiceTaxRate"],[[invData objectAtIndex:i]objectForKey:@"IM_ServiceTaxAmt"],[[invData objectAtIndex:i]objectForKey:@"IM_TakeAwayYN"],[[invData objectAtIndex:i] objectForKey:@"IM_TotalCondimentSurCharge"],[NSString stringWithFormat:@"%@-%@",invNo,[[invData objectAtIndex:i] objectForKey:@"Index"]],invModifierID,invModifierHdrCode];
                        
                        //NSLog(@"Index Data %@",[[invData objectAtIndex:i] objectForKey:@"Index"]);
                    }
                    else
                    {
                        [db executeUpdate:@"Insert into InvoiceCondiment"
                         " (IVC_DocNo, IVC_ItemCode, IVC_CHCode, IVC_CDCode, IVC_CDDescription, IVC_CDPrice, IVC_CDDiscount, IVC_DateTime,IVC_CDQty,IVC_CDManualKey) Values (?,?,?,?,?,?,?,?,?,?)",invNo,[[invData objectAtIndex:i] objectForKey:@"ItemCode"],[[invData objectAtIndex:i] objectForKey:@"CHCode"],[[invData objectAtIndex:i] objectForKey:@"CDCode"],[[invData objectAtIndex:i] objectForKey:@"CDDescription"],[[invData objectAtIndex:i] objectForKey:@"CDPrice"],[NSNumber numberWithDouble:0.00],date,[[invData objectAtIndex:i] objectForKey:@"UnitQty"],[NSString stringWithFormat:@"%@-%@",invNo,[[invData objectAtIndex:i] objectForKey:@"ParentIndex"]]];
                    }
                    
                    
                    
                    if ([db hadError]) {
                        
                        errMsg = [db lastErrorMessage];
                        *rollback = YES;
                        result =NO;
                    }
                    else
                    {
                        if (![[[invData objectAtIndex:0] objectForKey:@"PayDocType"] isEqualToString:@"CashSales"])
                        {
                            [db executeUpdate:@"Update DocNo set DOC_Number = ? where DOC_Header = 'CS'",[NSNumber numberWithInt:updateDocNo]];
                            if ([db hadError]) {
                                errMsg = [db lastErrorMessage];
                                *rollback = YES;
                                result = NO;
                            }
                        }
                        
                    }
                }
                
                if (result == YES) {
                    //[db executeUpdate:@"Update SalesOrderHdr set SOH_Status = ? where SOH_DocNo = ?",@"Pay",[[invData objectAtIndex:0] objectForKey:@"SOH_DocNo"]];
                    [db executeUpdate:@"Delete from SalesOrderHdr where SOH_DocNo = ?",[[invData objectAtIndex:0] objectForKey:@"SOH_DocNo"]];
                    [db executeUpdate:@"Delete from SalesOrderDtl where SOD_DocNo = ?",[[invData objectAtIndex:0] objectForKey:@"SOH_DocNo"]];
                    [db executeUpdate:@"Delete from SalesOrderCondiment where SOC_DocNo = ?",[[invData objectAtIndex:0] objectForKey:@"SOH_DocNo"]];
                    if ([db hadError]) {
                        
                        //[self showAlertView:[db lastErrorMessage] title:@"Fail"];
                        errMsg = [db lastErrorMessage];
                        *rollback = YES;
                        result = NO;
                        finalInvNo = @"-";
                    }
                    else
                    {
                        finalInvNo = invNo;
                        result = YES;
                    }
                }
                
            }
            else
            {
                //NSLog(@"%@",[dbTable lastErrorMessage]);
                //[self showAlertView:[dbTable lastErrorMessage] title:@"Fail"];
                errMsg = [db lastErrorMessage];
                result = NO;
                *rollback = YES;
            }

        } @catch (NSException *exception) {
            errMsg = exception.reason;
            result = NO;
            *rollback = YES;
        } @finally {
            
        }
        
        
        
    }];
    
    [queue close];
    
    NSMutableArray *returnData = [[NSMutableArray alloc] init];
    [returnData removeAllObjects];
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    NSError *error;
    
    if (result == YES) {
        
        [data setObject:@"True" forKey:@"Result"];
        [data setObject:@"Success" forKey:@"Message"];
        [data setObject:@"InsertInvoiceResult" forKey:@"IM_Flag"];
        [data setObject:finalInvNo forKey:@"InvNo"];
        [returnData addObject:data];
        
    }
    else if(result == NO)
    {
        
        [data setObject:@"False" forKey:@"Result"];
        [data setObject:errMsg forKey:@"Message"];
        [data setObject:@"InsertInvoiceResult" forKey:@"IM_Flag"];
        [data setObject:finalInvNo forKey:@"InvNo"];
        [returnData addObject:data];
        
    }
    
    //NSLog(@"when want to return peer %@",terminalArray);
    NSData *dataToBeReturn = [NSKeyedArchiver archivedDataWithRootObject:returnData];
    
    [appDelegate.mcManager.session sendData:dataToBeReturn
                                    toPeers:terminalArray
                                   withMode:MCSessionSendDataReliable
                                      error:&error];
    
    if (error) {
        NSLog(@"error come out %@",[error localizedDescription]);
    }
    
    data = nil;
    returnData = nil;
    return result;
}

+(BOOL)insertSplitSalesOrderIntoMainWithSqlitePath:(NSString *)dbPath SplitData:(NSArray *)splitData SplitDate:(NSString *)date terminalArray:(NSArray *)terminalArray TerminalName:(NSString *)terminalName
{
    __block BOOL result = YES;
    __block NSString *newSONo;
    __block NSString *orgSONo;
    __block NSString *modifierID = @"";
    __block NSString *modifierHdrCode = @"";
    
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        //NSString *newSONo;
        NSMutableArray *orgSO;
        NSMutableArray *newSO;
        
        orgSO = [[NSMutableArray alloc] init];
        newSO = [[NSMutableArray alloc]init];
        
        for (int i = 0; i < splitData.count; i++) {
            if ([[[splitData objectAtIndex:i] objectForKey:@"SplitType"] isEqualToString:@"OldSO"]) {
                [orgSO addObject:[splitData objectAtIndex:i]];
            }
            else
            {
                [newSO addObject:[splitData objectAtIndex:i]];
            }
        }
        
        
        [db executeUpdate:@"Delete from SalesOrderHdr where SOH_DocNo = ?",[[orgSO objectAtIndex:0] objectForKey:@"IM_DocNo"]];
            
        [db executeUpdate:@"Delete from SalesOrderDtl where SOD_DocNo = ?",[[orgSO objectAtIndex:0] objectForKey:@"IM_DocNo"]];
        
        [db executeUpdate:@"Delete from SalesOrderCondiment where SOC_DocNo = ?",[[orgSO objectAtIndex:0] objectForKey:@"IM_DocNo"]];
        
        [db executeUpdate:@"Delete from SalesOrderHdr where SOH_DocNo = ?",[[newSO objectAtIndex:0] objectForKey:@"IM_DocNo"]];
            
        [db executeUpdate:@"Delete from SalesOrderDtl where SOD_DocNo = ?",[[newSO objectAtIndex:0] objectForKey:@"IM_DocNo"]];
        
        [db executeUpdate:@"Delete from SalesOrderCondiment where SOC_DocNo = ?",[[newSO objectAtIndex:0] objectForKey:@"IM_DocNo"]];
        
        //NSLog(@"%@",self.labelNewSubTotal.text);
        FMResultSet *docRs = [db executeQuery:@"Select DOC_Number,DOC_Header from DocNo"
                              " where DOC_Header = 'SO'"];
        int updateDocNo = 0;
        if ([docRs next]) {
            updateDocNo = [docRs intForColumn:@"DOC_Number"] + 1;
            orgSONo = [NSString stringWithFormat:@"%@%09.f",[docRs stringForColumn:@"DOC_Header"],[[docRs stringForColumn:@"DOC_Number"]doubleValue] + 1];
        }
        [docRs close];
        
        NSUInteger taxIncludedYN = 0;
        
        if ([[[LibraryAPI sharedInstance] getTaxType] isEqualToString:@"IEx"]) {
            taxIncludedYN = 0;
        }
        else
        {
            taxIncludedYN = 1;
        }
        
        //---------left side sales order
        if (orgSO.count > 0 && [[[orgSO objectAtIndex:0] objectForKey:@"IM_InsertSplitFlag"] isEqualToString:@"1"]) {
            [db executeUpdate:@"Insert into SalesOrderHdr ("
                         "SOH_DocNo,SOH_Date,SOH_DocAmt,SOH_DiscAmt,SOH_Rounding,SOH_Table,SOH_User,SOH_AcctCode,SOH_Status, SOH_DocSubTotal,SOH_DocTaxAmt,SOH_DocServiceTaxAmt,SOH_DocServiceTaxGstAmt, SOH_PaxNo,SOH_TerminalName,SOH_TaxIncluded_YN,SOH_ServiceTaxGstCode,SOH_CustName,SOH_CustAdd1,SOH_CustAdd2,SOH_CustAdd3,SOH_CustTelNo,SOH_CustGstNo)"
                         "values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",orgSONo,date,[[orgSO objectAtIndex:0] objectForKey:@"SOH_DocAmt"],[[orgSO objectAtIndex:0] objectForKey:@"SOH_DiscAmt"],[[orgSO objectAtIndex:0] objectForKey:@"SOH_Rounding"],[[orgSO objectAtIndex:0] objectForKey:@"SOH_TableName"],[[LibraryAPI sharedInstance] getUserName],@"Cash",@"New",[[orgSO objectAtIndex:0] objectForKey:@"SOH_DocSubTotal"],[[orgSO objectAtIndex:0] objectForKey:@"SOH_DocTaxAmt"],[[orgSO objectAtIndex:0] objectForKey:@"SOH_DocServiceTaxAmt"],[[orgSO objectAtIndex:0] objectForKey:@"SOH_DocServiceTaxGstAmt"],[[orgSO objectAtIndex:0] objectForKey:@"SOH_PaxNo"],terminalName,[NSNumber numberWithInteger:taxIncludedYN],[[LibraryAPI sharedInstance] getServiceTaxGstCode],[[orgSO objectAtIndex:0] objectForKey:@"Name"],[[orgSO objectAtIndex:0] objectForKey:@"Add1"],[[orgSO objectAtIndex:0] objectForKey:@"Add2"],[[orgSO objectAtIndex:0] objectForKey:@"Add3"],[[orgSO objectAtIndex:0] objectForKey:@"TelNo"],[[orgSO objectAtIndex:0] objectForKey:@"GstNo"]];
            if (![db hadError]) {
                for (int i = 0; i < orgSO.count; i++) {
                    if ([[[orgSO objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"] ||
                        [[[orgSO objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"PackageItemOrder"])
                    {
                        
                        if ([[[orgSO objectAtIndex:i] objectForKey:@"IM_ServiceType"] isEqualToString:@"1"])
                        {
                            modifierID = [NSString stringWithFormat:@"M%@-%@",newSONo,[[orgSO objectAtIndex:i] objectForKey:@"Index"]];
                        }
                        else
                        {
                            if ([[[orgSO objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"]) {
                                modifierID = @"";
                            }
                        }
                        
                        if ([[[orgSO objectAtIndex:i] objectForKey:@"SOD_ModifierHdrCode"] length] > 0) {
                            modifierHdrCode = [[orgSO objectAtIndex:i] objectForKey:@"SOD_ModifierHdrCode"];
                        }
                        else{
                            modifierHdrCode = @"";
                        }
                        
                        if ([[[orgSO objectAtIndex:i] objectForKey:@"IM_Qty"]doubleValue] > 0.00 || [[[orgSO objectAtIndex:i] objectForKey:@"SOD_ModifierHdrCode"] length] > 0)
                        {
                            [db executeUpdate:@"Insert into SalesOrderDtl "
                             "(SOD_AcctCode, SOD_DocNo, SOD_ItemCode, SOD_ItemDescription, SOD_Quantity, SOD_Price, SOD_DiscValue, SOD_SellingPrice, SOD_UnitPrice, SOD_Remark, SOD_TakeAway_YN,SOD_DiscType,SOD_SellTax,SOD_TotalSalesTax,SOD_TotalSalesTaxLong,SOD_TotalEx,SOD_TotalExLong,SOD_TotalInc,SOD_TotalDisc,SOD_SubTotal,SOD_DiscInPercent,SOD_TaxCode,SOD_ServiceTaxCode, SOD_ServiceTaxAmt, SOD_TaxRate,SOD_ServiceTaxRate,SOD_TakeAwayYN,SOD_TotalCondimentSurCharge,SOD_ManualID,SOD_TerminalName,SOD_ModifierID, SOD_ModifierHdrCode) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",@"Cash",orgSONo,[[orgSO objectAtIndex:i] objectForKey:@"IM_ItemCode"],[[orgSO objectAtIndex:i] objectForKey:@"IM_Description"],[[orgSO objectAtIndex:i] objectForKey:@"IM_Qty"],[[orgSO objectAtIndex:i] objectForKey:@"IM_SalesPrice"],[[orgSO objectAtIndex:i] objectForKey:@"IM_Discount"],[[orgSO objectAtIndex:i] objectForKey:@"IM_SellingPrice"],[[orgSO objectAtIndex:i] objectForKey:@"IM_Price"],[[orgSO objectAtIndex:i] objectForKey:@"IM_Remark"],[NSNumber numberWithInt:0],[[orgSO objectAtIndex:i] objectForKey:@"IM_DiscountType"],[[orgSO objectAtIndex:i] objectForKey:@"IM_Tax"],[[orgSO objectAtIndex:i] objectForKey:@"IM_TotalTax"],
                             [[orgSO objectAtIndex:i] objectForKey:@"IM_totalItemTaxAmtLong"],[[orgSO objectAtIndex:i] objectForKey:@"IM_totalItemSellingAmt"],
                             [[orgSO objectAtIndex:i] objectForKey:@"IM_totalItemSellingAmtLong"],[[orgSO objectAtIndex:i] objectForKey:@"IM_Total"],[[orgSO objectAtIndex:i] objectForKey:@"IM_DiscountAmt"],[[orgSO objectAtIndex:i] objectForKey:@"IM_SubTotal"],[[orgSO objectAtIndex:i] objectForKey:@"IM_DiscountInPercent"],[[orgSO objectAtIndex:i] objectForKey:@"IM_GSTCode"],[[orgSO objectAtIndex:i]objectForKey:@"IM_ServiceTaxCode"],[[orgSO objectAtIndex:i]objectForKey:@"IM_ServiceTaxAmt"],[[orgSO objectAtIndex:i] objectForKey:@"IM_Gst"],[[orgSO objectAtIndex:i] objectForKey:@"IM_ServiceTaxRate"],[[orgSO objectAtIndex:i] objectForKey:@"IM_TakeAwayYN"],[[orgSO objectAtIndex:i] objectForKey:@"IM_TotalCondimentSurCharge"],[NSString stringWithFormat:@"%@-%@",orgSONo,[[orgSO objectAtIndex:i] objectForKey:@"Index"]],terminalName, modifierID, modifierHdrCode];
                        }
                    }
                    else
                    {
                        [db executeUpdate:@"Insert into SalesOrderCondiment"
                         " (SOC_DocNo, SOC_ItemCode, SOC_CHCode, SOC_CDCode, SOC_CDDescription, SOC_CDPrice, SOC_CDDiscount, SOC_DateTime,SOC_CDQty,SOC_CDManualKey) Values (?,?,?,?,?,?,?,?,?,?)",orgSONo,[[orgSO objectAtIndex:i] objectForKey:@"ItemCode"],[[orgSO objectAtIndex:i] objectForKey:@"CHCode"],[[orgSO objectAtIndex:i] objectForKey:@"CDCode"],[[orgSO objectAtIndex:i] objectForKey:@"CDDescription"],[[orgSO objectAtIndex:i] objectForKey:@"CDPrice"],[NSNumber numberWithDouble:0.00],date,[[orgSO objectAtIndex:i] objectForKey:@"UnitQty"],[NSString stringWithFormat:@"%@-%@",orgSONo,[[orgSO objectAtIndex:i] objectForKey:@"ParentIndex"]]];
                    }
                    
                        
                        
                    if ([db hadError]) {
                        result = false;
                        //[self showAlertView:[dbTable lastErrorMessage] title:@"Fail"];
                        *rollback = YES;
                        //return;
                    }
                    else
                    {
                        [db executeUpdate:@"Update DocNo set DOC_Number = ? where DOC_Header = 'SO'",[NSNumber numberWithInt:updateDocNo]];
                        if ([db hadError]) {
                            result = false;
                            //[self showAlertView:[dbTable lastErrorMessage] title:@"Fail"];
                            *rollback = YES;
                            //return;
                        }
                        else
                        {
                            //self.soO.text = newSONo;
                        }
                    }
                    
                    
                }
                
            }
            else
            {
                result = false;
                //[self showAlertView:[dbTable lastErrorMessage] title:@"Fail"];
                *rollback = YES;
                //return;
            }
        }
        else
        {
            orgSONo = @"SO";
        }
        
        
        //----------change org so to new so--------------------
        
        if (newSO.count > 0 && [[[newSO objectAtIndex:0] objectForKey:@"IM_InsertSplitFlag"] isEqualToString:@"1"]) {
            FMResultSet *docRs2 = [db executeQuery:@"Select DOC_Number,DOC_Header from DocNo"
                                   " where DOC_Header = 'SO'"];
            if ([docRs2 next]) {
                updateDocNo = [docRs2 intForColumn:@"DOC_Number"] + 1;
                newSONo = [NSString stringWithFormat:@"%@%09.f",[docRs2 stringForColumn:@"DOC_Header"],[[docRs2 stringForColumn:@"DOC_Number"]doubleValue] + 1];
            }
            //NSLog(@"%@",newSONo);
            [docRs2 close];
            // right side sales order
            [db executeUpdate:@"Insert into SalesOrderHdr ("
                         "SOH_DocNo,SOH_Date,SOH_DocAmt,SOH_DiscAmt,SOH_Rounding,SOH_Table,SOH_User,SOH_AcctCode,SOH_Status, SOH_DocSubTotal,SOH_DocTaxAmt,SOH_DocServiceTaxAmt,SOH_DocServiceTaxGstAmt,SOH_PaxNo,SOH_TerminalName,SOH_TaxIncluded_YN,SOH_ServiceTaxGstCode,SOH_CustName,SOH_CustAdd1,SOH_CustAdd2,SOH_CustAdd3,SOH_CustTelNo,SOH_CustGstNo)"
                         "values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",newSONo,date,[[newSO objectAtIndex:0] objectForKey:@"SOH_DocAmt"],[[newSO objectAtIndex:0] objectForKey:@"SOH_DiscAmt"],[[newSO objectAtIndex:0] objectForKey:@"SOH_Rounding"],[[newSO objectAtIndex:0] objectForKey:@"SOH_TableName"],[[LibraryAPI sharedInstance] getUserName],@"Cash",@"New",[[newSO objectAtIndex:0] objectForKey:@"SOH_DocSubTotal"],[[newSO objectAtIndex:0] objectForKey:@"SOH_DocTaxAmt"],[[newSO objectAtIndex:0] objectForKey:@"SOH_DocServiceTaxAmt"],[[newSO objectAtIndex:0] objectForKey:@"SOH_DocServiceTaxGstAmt"],@"0",terminalName,[NSNumber numberWithInteger:taxIncludedYN],[[LibraryAPI sharedInstance] getServiceTaxGstCode],[[newSO objectAtIndex:0] objectForKey:@"Name"],[[newSO objectAtIndex:0] objectForKey:@"Add1"],[[newSO objectAtIndex:0] objectForKey:@"Add2"],[[newSO objectAtIndex:0] objectForKey:@"Add3"],[[newSO objectAtIndex:0] objectForKey:@"TelNo"],[[newSO objectAtIndex:0] objectForKey:@"GstNo"]];
            if (![db hadError]) {
                for (int i = 0; i < newSO.count; i++) {
                    if ([[[newSO objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"] ||
                        [[[newSO objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"PackageItemOrder"])
                    {
                        
                        if ([[[newSO objectAtIndex:i] objectForKey:@"IM_ServiceType"] isEqualToString:@"1"])
                        {
                            modifierID = [NSString stringWithFormat:@"M%@-%@",newSONo,[[newSO objectAtIndex:i] objectForKey:@"Index"]];
                        }
                        else
                        {
                            if ([[[newSO objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"]) {
                                modifierID = @"";
                            }
                        }
                        
                        if ([[[newSO objectAtIndex:i] objectForKey:@"SOD_ModifierHdrCode"] length] > 0) {
                            modifierHdrCode = [[newSO objectAtIndex:i] objectForKey:@"SOD_ModifierHdrCode"];
                        }
                        else{
                            modifierHdrCode = @"";
                        }
                        
                        [db executeUpdate:@"Insert into SalesOrderDtl "
                         "(SOD_AcctCode, SOD_DocNo, SOD_ItemCode, SOD_ItemDescription, SOD_Quantity, SOD_Price, SOD_DiscValue, SOD_SellingPrice, SOD_UnitPrice, SOD_Remark, SOD_TakeAway_YN,SOD_DiscType,SOD_SellTax,SOD_TotalSalesTax,SOD_TotalSalesTaxLong,SOD_TotalEx,SOD_TotalExLong,SOD_TotalInc,SOD_TotalDisc,SOD_SubTotal,SOD_DiscInPercent,SOD_TaxCode,SOD_ServiceTaxCode, SOD_ServiceTaxAmt, SOD_TaxRate,SOD_ServiceTaxRate,SOD_TakeAwayYN,SOD_TotalCondimentSurCharge,SOD_ManualID,SOD_TerminalName,SOD_ModifierID, SOD_ModifierHdrCode) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",@"Cash",newSONo,[[newSO objectAtIndex:i] objectForKey:@"IM_ItemCode"],[[newSO objectAtIndex:i] objectForKey:@"IM_Description"],[[newSO objectAtIndex:i] objectForKey:@"IM_Qty"],[[newSO objectAtIndex:i] objectForKey:@"IM_SalesPrice"],[[newSO objectAtIndex:i] objectForKey:@"IM_Discount"],[[newSO objectAtIndex:i] objectForKey:@"IM_SellingPrice"],[[newSO objectAtIndex:i] objectForKey:@"IM_Price"],[[newSO objectAtIndex:i] objectForKey:@"IM_Remark"],[NSNumber numberWithInt:0],[[newSO objectAtIndex:i] objectForKey:@"IM_DiscountType"],[[newSO objectAtIndex:i] objectForKey:@"IM_Tax"],[[newSO objectAtIndex:i] objectForKey:@"IM_TotalTax"],
                         [[newSO objectAtIndex:i] objectForKey:@"IM_totalItemTaxAmtLong"],[[newSO objectAtIndex:i] objectForKey:@"IM_totalItemSellingAmt"],
                         [[newSO objectAtIndex:i] objectForKey:@"IM_totalItemSellingAmtLong"],[[newSO objectAtIndex:i] objectForKey:@"IM_Total"],[[newSO objectAtIndex:i] objectForKey:@"IM_DiscountAmt"],[[newSO objectAtIndex:i] objectForKey:@"IM_SubTotal"],[[newSO objectAtIndex:i] objectForKey:@"IM_DiscountInPercent"],[[newSO objectAtIndex:i] objectForKey:@"IM_GSTCode"],[[newSO objectAtIndex:i]objectForKey:@"IM_ServiceTaxCode"],[[newSO objectAtIndex:i]objectForKey:@"IM_ServiceTaxAmt"],[[newSO objectAtIndex:i] objectForKey:@"IM_Gst"],[[newSO objectAtIndex:i] objectForKey:@"IM_ServiceTaxRate"],[[newSO objectAtIndex:i] objectForKey:@"IM_TakeAwayYN"],[[newSO objectAtIndex:i] objectForKey:@"IM_TotalCondimentSurCharge"],[NSString stringWithFormat:@"%@-%@",newSONo,[[newSO objectAtIndex:i] objectForKey:@"Index"]],terminalName, modifierID, modifierHdrCode];
                    }
                    else
                    {
                        [db executeUpdate:@"Insert into SalesOrderCondiment"
                         " (SOC_DocNo, SOC_ItemCode, SOC_CHCode, SOC_CDCode, SOC_CDDescription, SOC_CDPrice, SOC_CDDiscount, SOC_DateTime,SOC_CDQty,SOC_CDManualKey) Values (?,?,?,?,?,?,?,?,?,?)",newSONo,[[newSO objectAtIndex:i] objectForKey:@"ItemCode"],[[newSO objectAtIndex:i] objectForKey:@"CHCode"],[[newSO objectAtIndex:i] objectForKey:@"CDCode"],[[newSO objectAtIndex:i] objectForKey:@"CDDescription"],[[newSO objectAtIndex:i] objectForKey:@"CDPrice"],[NSNumber numberWithDouble:0.00],date,[[newSO objectAtIndex:i] objectForKey:@"UnitQty"],[NSString stringWithFormat:@"%@-%@",newSONo,[[newSO objectAtIndex:i] objectForKey:@"ParentIndex"]]];
                    }
                    
                    
                    
                    if ([db hadError]) {
                        result = false;
                        //[self showAlertView:[dbTable lastErrorMessage] title:@"Fail"];
                        *rollback = YES;
                        //return;
                    }
                    else
                    {
                        [db executeUpdate:@"Update DocNo set DOC_Number = ? where DOC_Header = 'SO'",[NSNumber numberWithInt:updateDocNo]];
                        if ([db hadError]) {
                            result= false;
                            //[self showAlertView:[dbTable lastErrorMessage] title:@"Fail"];
                            *rollback = YES;
                            //return;
                        }
                        else
                        {
                            //self.soN.text = newSONo;
                            
                            result = true;
                        }
                    }
                }
                
            }
            else
            {
                result = false;
                *rollback = YES;
                //[self showAlertView:[dbTable lastErrorMessage] title:@"Fail"];
                //return;
            }
            
        }
        else
        {
            newSONo = @"SO";
        }
        
        
    }];
    
    [queue close];
    
    NSArray *splitBillSalesOrderNo = @[orgSONo, newSONo, [[splitData objectAtIndex:0] objectForKey:@"PayForWhich"]];
    
    //[[LibraryAPI sharedInstance] setTerminalSplitBillSalesOrderNoInArray:splitBillSalesOrderNo];
    NSMutableArray *returnData = [[NSMutableArray alloc] init];
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    NSError *error;
    
    if (result == YES) {
        
        
        //[data setObject:[NSString stringWithFormat:@"%ld",(long)_im_ItemNo] forKey:@"IM_ItemNo"];
        [data setObject:@"True" forKey:@"Result"];
        [data setObject:@"-" forKey:@"Message"];
        [data setObject:splitBillSalesOrderNo[1] forKey:@"NewSODocNo"];
        [data setObject:splitBillSalesOrderNo[0] forKey:@"OrgSODocNo"];
        [data setObject:splitBillSalesOrderNo[2] forKey:@"PayForWhichSO"];
        [data setObject:@"SplitBillSOResult" forKey:@"IM_Flag"];
        
        [returnData addObject:data];
        

    }
    else if(result == NO)
    {
        //NSMutableArray *returnData = [[NSMutableArray alloc] init];
        //NSMutableDictionary *data = [NSMutableDictionary dictionary];
        
        //[data setObject:[NSString stringWithFormat:@"%ld",(long)_im_ItemNo] forKey:@"IM_ItemNo"];
        [data setObject:@"False" forKey:@"Result"];
        [data setObject:@"-" forKey:@"Message"];
        [data setObject:@"-" forKey:@"NewSODocNo"];
        [data setObject:@"-" forKey:@"OrgSODocNo"];
        [data setObject:@"-" forKey:@"PayForWhichSO"];
        [data setObject:@"SplitBillSOResult" forKey:@"IM_Flag"];
        
        [returnData addObject:data];
        
    }
    
    
    NSData *dataToBeReturn = [NSKeyedArchiver archivedDataWithRootObject:returnData];
    [appDelegate.mcManager.session sendData:dataToBeReturn
                                    toPeers:terminalArray
                                   withMode:MCSessionSendDataReliable
                                      error:&error];
    returnData = nil;
    data = nil;
    
    splitBillSalesOrderNo = nil;
    return result;
    
}

+(NSString *)asterixRequestServerToPrintTerminalReqWithSONo:(NSString *)soNo PortName :(NSString *)portName
{
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableArray *requestServerData = [[NSMutableArray alloc] init];
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    MCPeerID *specificPeer;
    [requestServerData removeAllObjects];
    [data setObject:@"Request" forKey:@"Result"];
    [data setObject:@"-" forKey:@"Message"];
    [data setObject:@"RequestPrintAsterixSalesOrder" forKey:@"IM_Flag"];
    [data setObject:soNo forKey:@"SOH_DocNo"];
    [data setObject:portName forKey:@"P_PortName"];
    
    [requestServerData addObject:data];
    NSData *dataToBeSend = [NSKeyedArchiver archivedDataWithRootObject:requestServerData];
    NSArray *allPeers = [[appDelegate.mcManager session] connectedPeers];
    NSError *error;
    
    for (int i = 0; i < allPeers.count; i++) {
        specificPeer = [allPeers objectAtIndex:i];
        
        if ([specificPeer.displayName isEqualToString:@"Server"]) {
            NSArray *oneArray = @[[appDelegate.mcManager.session.connectedPeers objectAtIndex:i]];
            [appDelegate.mcManager.session sendData:dataToBeSend
                                             toPeers:oneArray
                                            withMode:MCSessionSendDataReliable
                                               error:&error];
        }
        
    }
    data = nil;
    allPeers = nil;
    requestServerData = nil;
    if (error) {
        NSLog(@"Erro : %@", [error localizedDescription]);
        return [error localizedDescription];
    }
    else
    {
        return @"Success";
    }
    
}

+(NSString *)asterixRequestServerToPrintTerminalReqWithCSNo:(NSString *)csNo PortName :(NSString *)portName
{
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableArray *requestServerData = [[NSMutableArray alloc] init];
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    MCPeerID *specificPeer;
    [requestServerData removeAllObjects];
    [data setObject:@"Request" forKey:@"Result"];
    [data setObject:@"-" forKey:@"Message"];
    [data setObject:@"RequestPrintAsterixInvoice" forKey:@"IM_Flag"];
    [data setObject:csNo forKey:@"Inv_DocNo"];
    [data setObject:portName forKey:@"P_PortName"];
    [data setObject:@"N" forKey:@"P_KickDrawer"];
    
    [requestServerData addObject:data];
    NSData *dataToBeSend = [NSKeyedArchiver archivedDataWithRootObject:requestServerData];
    NSArray *allPeers = [[appDelegate.mcManager session] connectedPeers];
    NSError *error;
    
    for (int i = 0; i < allPeers.count; i++) {
        specificPeer = [allPeers objectAtIndex:i];
        
        if ([specificPeer.displayName isEqualToString:@"Server"]) {
            NSArray *oneArray = @[[appDelegate.mcManager.session.connectedPeers objectAtIndex:i]];
            [appDelegate.mcManager.session sendData:dataToBeSend
                                            toPeers:oneArray
                                           withMode:MCSessionSendDataReliable
                                              error:&error];
        }
        
    }
    data = nil;
    allPeers = nil;
    requestServerData = nil;
    if (error) {
        NSLog(@"Erro : %@", [error localizedDescription]);
        return [error localizedDescription];
    }
    else
    {
        return @"Success";
    }
    
}

+(NSString *)startRasterRequestServerToPrintTerminalReqWithSONo:(NSString *)soNo PortName:(NSString *)portName PrinterSetting:(NSString *)printerSetting EnableGst:(int)enableGst
{
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableArray *requestServerData = [[NSMutableArray alloc] init];
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    MCPeerID *specificPeer;
    
    [requestServerData removeAllObjects];
    [data setObject:@"Request" forKey:@"Result"];
    [data setObject:@"-" forKey:@"Message"];
    [data setObject:@"RequestStarRasterPrintSalesOrder" forKey:@"IM_Flag"];
    [data setObject:soNo forKey:@"SOH_DocNo"];
    [data setObject:printerSetting forKey:@"PortSetting"];
    [data setObject:portName forKey:@"P_PortName"];
    [data setObject:[NSString stringWithFormat:@"%d",enableGst] forKey:@"EnableGst"];
    [data setObject:@"English" forKey:@"Language"];
    
    [requestServerData addObject:data];
    NSData *dataToBeSend = [NSKeyedArchiver archivedDataWithRootObject:requestServerData];
    NSArray *allPeers = [[appDelegate.mcManager session] connectedPeers];
    NSError *error;
    
    for (int i = 0; i < allPeers.count; i++) {
        specificPeer = [allPeers objectAtIndex:i];
        
        if ([specificPeer.displayName isEqualToString:@"Server"]) {
            NSArray *oneArray = @[[appDelegate.mcManager.session.connectedPeers objectAtIndex:i]];
            [appDelegate.mcManager.session sendData:dataToBeSend
                                             toPeers:oneArray
                                            withMode:MCSessionSendDataReliable
                                               error:&error];
        }
        
    }
    data = nil;
    requestServerData = nil;
    allPeers = nil;
    if (error) {
        NSLog(@"Erro : %@", [error localizedDescription]);
        return [error localizedDescription];
    }
    else
    {
        return @"Success";
    }
}

+(NSString *)startRasterRequestServerToPrintTerminalReqWithCSNo:(NSString *)csNo PortName:(NSString *)portName PrinterSetting:(NSString *)printerSetting EnableGst:(int)enableGst
{
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableArray *requestServerData = [[NSMutableArray alloc] init];
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    MCPeerID *specificPeer;
    
    [requestServerData removeAllObjects];
    [data setObject:@"Request" forKey:@"Result"];
    [data setObject:@"-" forKey:@"Message"];
    [data setObject:@"RequestStarRasterPrintInvoice" forKey:@"IM_Flag"];
    [data setObject:csNo forKey:@"Inv_DocNo"];
    [data setObject:printerSetting forKey:@"PortSetting"];
    [data setObject:portName forKey:@"P_PortName"];
    [data setObject:[NSString stringWithFormat:@"%d",enableGst] forKey:@"EnableGst"];
    [data setObject:@"English" forKey:@"Language"];
    
    [requestServerData addObject:data];
    NSData *dataToBeSend = [NSKeyedArchiver archivedDataWithRootObject:requestServerData];
    NSArray *allPeers = [[appDelegate.mcManager session] connectedPeers];
    NSError *error;
    
    for (int i = 0; i < allPeers.count; i++) {
        specificPeer = [allPeers objectAtIndex:i];
        
        if ([specificPeer.displayName isEqualToString:@"Server"]) {
            NSArray *oneArray = @[[appDelegate.mcManager.session.connectedPeers objectAtIndex:i]];
            [appDelegate.mcManager.session sendData:dataToBeSend
                                            toPeers:oneArray
                                           withMode:MCSessionSendDataReliable
                                              error:&error];
        }
        
    }
    data = nil;
    requestServerData = nil;
    allPeers = nil;
    if (error) {
        NSLog(@"Erro : %@", [error localizedDescription]);
        return [error localizedDescription];
    }
    else
    {
        return @"Success";
    }

}

+(NSString *)startLineRequestServerToPrintTerminalReqWithSONo:(NSString *)soNo PortName:(NSString *)portName PrinterSetting:(NSString *)printerSetting EnableGst:(int)enableGst
{
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableArray *requestServerData = [[NSMutableArray alloc] init];
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    MCPeerID *specificPeer;
    
    [requestServerData removeAllObjects];
    [data setObject:@"Request" forKey:@"Result"];
    [data setObject:@"-" forKey:@"Message"];
    [data setObject:@"RequestStarLinePrintSalesOrder" forKey:@"IM_Flag"];
    [data setObject:soNo forKey:@"SOH_DocNo"];
    [data setObject:printerSetting forKey:@"PortSetting"];
    [data setObject:portName forKey:@"P_PortName"];
    [data setObject:[NSString stringWithFormat:@"%d",enableGst] forKey:@"EnableGst"];
    [data setObject:@"English" forKey:@"Language"];
    
    [requestServerData addObject:data];
    NSData *dataToBeSend = [NSKeyedArchiver archivedDataWithRootObject:requestServerData];
    NSArray *allPeers = [[appDelegate.mcManager session] connectedPeers];
    NSError *error;
    
    for (int i = 0; i < allPeers.count; i++) {
        specificPeer = [allPeers objectAtIndex:i];
        
        if ([specificPeer.displayName isEqualToString:@"Server"]) {
            NSArray *oneArray = @[[appDelegate.mcManager.session.connectedPeers objectAtIndex:i]];
            [appDelegate.mcManager.session sendData:dataToBeSend
                                            toPeers:oneArray
                                           withMode:MCSessionSendDataReliable
                                              error:&error];
        }
        
    }
    data = nil;
    requestServerData = nil;
    allPeers = nil;
    if (error) {
        NSLog(@"Erro : %@", [error localizedDescription]);
        return [error localizedDescription];
    }
    else
    {
        return @"Success";
    }
}

+(NSString *)startLineRequestServerToPrintTerminalReqWithCSNo:(NSString *)csNo PortName:(NSString *)portName PrinterSetting:(NSString *)printerSetting EnableGst:(int)enableGst
{
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableArray *requestServerData = [[NSMutableArray alloc] init];
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    MCPeerID *specificPeer;
    
    [requestServerData removeAllObjects];
    [data setObject:@"Request" forKey:@"Result"];
    [data setObject:@"-" forKey:@"Message"];
    [data setObject:@"RequestStarLinePrintInvoice" forKey:@"IM_Flag"];
    [data setObject:csNo forKey:@"Inv_DocNo"];
    [data setObject:printerSetting forKey:@"PortSetting"];
    [data setObject:portName forKey:@"P_PortName"];
    [data setObject:[NSString stringWithFormat:@"%d",enableGst] forKey:@"EnableGst"];
    [data setObject:@"English" forKey:@"Language"];
    
    [requestServerData addObject:data];
    NSData *dataToBeSend = [NSKeyedArchiver archivedDataWithRootObject:requestServerData];
    NSArray *allPeers = [[appDelegate.mcManager session] connectedPeers];
    NSError *error;
    
    for (int i = 0; i < allPeers.count; i++) {
        specificPeer = [allPeers objectAtIndex:i];
        
        if ([specificPeer.displayName isEqualToString:@"Server"]) {
            NSArray *oneArray = @[[appDelegate.mcManager.session.connectedPeers objectAtIndex:i]];
            [appDelegate.mcManager.session sendData:dataToBeSend
                                            toPeers:oneArray
                                           withMode:MCSessionSendDataReliable
                                              error:&error];
        }
        
    }
    data = nil;
    requestServerData = nil;
    allPeers = nil;
    if (error) {
        NSLog(@"Erro : %@", [error localizedDescription]);
        return [error localizedDescription];
    }
    else
    {
        return @"Success";
    }

}

+(void)flyTechRequestCSDataWithCSNo:(NSString *)csNo
{
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableArray *requestServerData = [[NSMutableArray alloc] init];
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    MCPeerID *specificPeer;
    
    [requestServerData removeAllObjects];
    [data setObject:@"Request" forKey:@"Result"];
    [data setObject:@"-" forKey:@"Message"];
    [data setObject:@"GeneralRequestInvoiceArray" forKey:@"IM_Flag"];
    [data setObject:csNo forKey:@"DocNo"];
    
    [requestServerData addObject:data];
    NSData *dataToBeSend = [NSKeyedArchiver archivedDataWithRootObject:requestServerData];
    NSArray *allPeers = [[appDelegate.mcManager session] connectedPeers];
    NSError *error;
    
    for (int i = 0; i < allPeers.count; i++) {
        specificPeer = [allPeers objectAtIndex:i];
        
        if ([specificPeer.displayName isEqualToString:@"Server"]) {
            NSArray *oneArray = @[[appDelegate.mcManager.session.connectedPeers objectAtIndex:i]];
            [appDelegate.mcManager.session sendData:dataToBeSend
                                            toPeers:oneArray
                                           withMode:MCSessionSendDataReliable
                                              error:&error];
        }
        
    }
    data = nil;
    requestServerData = nil;
    allPeers = nil;

}

+(void)flyTechRequestSODataWithSONo:(NSString *)soNo
{
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableArray *requestServerData = [[NSMutableArray alloc] init];
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    MCPeerID *specificPeer;
    
    [requestServerData removeAllObjects];
    [data setObject:@"Request" forKey:@"Result"];
    [data setObject:@"-" forKey:@"Message"];
    [data setObject:@"GeneralRequestSalesOrderArray" forKey:@"IM_Flag"];
    [data setObject:soNo forKey:@"DocNo"];
    
    [requestServerData addObject:data];
    NSData *dataToBeSend = [NSKeyedArchiver archivedDataWithRootObject:requestServerData];
    NSArray *allPeers = [[appDelegate.mcManager session] connectedPeers];
    NSError *error;
    
    for (int i = 0; i < allPeers.count; i++) {
        specificPeer = [allPeers objectAtIndex:i];
        
        if ([specificPeer.displayName isEqualToString:@"Server"]) {
            NSArray *oneArray = @[[appDelegate.mcManager.session.connectedPeers objectAtIndex:i]];
            [appDelegate.mcManager.session sendData:dataToBeSend
                                            toPeers:oneArray
                                           withMode:MCSessionSendDataReliable
                                              error:&error];
        }
        
    }
    data = nil;
    requestServerData = nil;
    allPeers = nil;
    
}

#pragma mark - XinYe Data
+(NSString *)xinYeRequestServerToPrintTerminalReqWithReceiptArray:(NSMutableArray *)array
{
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    MCPeerID *specificPeer;
    /*
    NSMutableArray *requestServerData = [[NSMutableArray alloc] init];
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    
    [requestServerData removeAllObjects];
    [data setObject:@"Request" forKey:@"Result"];
    [data setObject:@"-" forKey:@"Message"];
    [data setObject:@"RequestPrintXinYeCS" forKey:@"IM_Flag"];
    [data setObject:csNo forKey:@"Inv_DocNo"];
    [data setObject:portName forKey:@"P_PortName"];
    [data setObject:@"N" forKey:@"P_KickDrawer"];
    
    [requestServerData addObject:data];
     */
    NSData *dataToBeSend = [NSKeyedArchiver archivedDataWithRootObject:array];
    NSArray *allPeers = [[appDelegate.mcManager session] connectedPeers];
    NSError *error;
    
    for (int i = 0; i < allPeers.count; i++) {
        specificPeer = [allPeers objectAtIndex:i];
        
        if ([specificPeer.displayName isEqualToString:@"Server"]) {
            NSArray *oneArray = @[[appDelegate.mcManager.session.connectedPeers objectAtIndex:i]];
            [appDelegate.mcManager.session sendData:dataToBeSend
                                            toPeers:oneArray
                                           withMode:MCSessionSendDataReliable
                                              error:&error];
        }
        
    }
    //data = nil;
    allPeers = nil;
    //requestServerData = nil;
    if (error) {
        NSLog(@"Erro : %@", [error localizedDescription]);
        return [error localizedDescription];
    }
    else
    {
        return @"Success";
    }

}


@end
