//
//  PublicSqliteMethod.m
//  IpadOrder
//
//  Created by IRS on 31/03/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import "PublicSqliteMethod.h"
#import "LibraryAPI.h"
#import <AFNetworking/AFNetworking.h>
#import "TerminalData.h"


@implementation PublicSqliteMethod

+(NSArray *)checkCompanyProfileWithDbPath:(NSString *)dbPath
{
    __block NSMutableArray *companyData = [[NSMutableArray alloc] initWithCapacity:1];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        NSString *appStatus;
        NSString *appTerminalQty;
        NSString *appPurchaseID;
        NSString *appDeviceID;
        NSString *appExpDate;
        NSString *appAction;
        NSString *appProductKey;
        
        FMResultSet *rsAppReg = [db executeQuery:@"Select *, ifnull(App_PurchaseID,'') as PurchaseID, ifnull(App_LicenseID,'') as LicenseID, ifnull(App_ReqExpDate,'') as ReqExpDate,ifnull(App_Action,'') as Action,ifnull(App_ProductKey,'') as ProductKey from AppRegistration"];
        
        if ([rsAppReg next]) {
            appStatus = [rsAppReg stringForColumn:@"App_Status"];
            appTerminalQty = [rsAppReg stringForColumn:@"App_TerminalQty"];
            appPurchaseID = [rsAppReg stringForColumn:@"PurchaseID"];
            appDeviceID = [rsAppReg stringForColumn:@"LicenseID"];
            appExpDate = [rsAppReg stringForColumn:@"ReqExpDate"];
            appAction = [rsAppReg stringForColumn:@"Action"];
            appProductKey = [rsAppReg stringForColumn:@"ProductKey"];
        }
        else
        {
            appStatus = @"";
            appPurchaseID = @"";
            appTerminalQty = @"";
            appExpDate = @"";
            appAction = @"";
            appProductKey = @"";
            appDeviceID = @"";
        }
        [rsAppReg close];
        
        FMResultSet *rs = [db executeQuery:@"select Comp_Company,Comp_Address1,Comp_Address2,ifnull(Comp_Address3,'') as Address3,ifnull(Comp_City,'') as City, ifnull(Comp_State,'') as State,ifnull(Comp_PostCode,'') as PostCode, Comp_Country,ifnull(Comp_Telephone,'') as Telephone,ifnull(Comp_Email,'') as Email,ifnull(Comp_WebSite,'') as WebSite,ifnull(Comp_GstNo,'') as GstNo,ifnull(Comp_RegistrationNo,'') as RegistrationNo,ifnull(Comp_RegKey,'') as RegKey, ifnull(Comp_LicenseID, '') as LicenseID, ifnull(Comp_ProductKey,'') as ProductKey  from company"];
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        
        if ([rs next]) {
            [dict setObject:appStatus forKey:@"App_Status"];
            [dict setObject:appTerminalQty forKey:@"App_TerminalQty"];
            [dict setObject:appPurchaseID forKey:@"App_PurchaseID"];
            [dict setObject:appDeviceID forKey:@"App_LicenseID"];
            [dict setObject:appExpDate forKey:@"App_ReqExpDate"];
            [dict setObject:appAction forKey:@"App_Action"];
            [dict setObject:appProductKey forKey:@"App_ProductKey"];
            [dict setObject:[rs stringForColumn:@"Comp_Company"] forKey:@"Comp_Company"];
            [dict setObject:[rs stringForColumn:@"Comp_Address1"] forKey:@"Comp_Address1"];
            [dict setObject:[rs stringForColumn:@"Comp_Address2"] forKey:@"Comp_Address2"];
            [dict setObject:[rs stringForColumn:@"Address3"] forKey:@"Comp_Address3"];
            [dict setObject:[rs stringForColumn:@"City"] forKey:@"Comp_City"];
            [dict setObject:[rs stringForColumn:@"PostCode"] forKey:@"Comp_PostCode"];
            [dict setObject:[rs stringForColumn:@"State"] forKey:@"Comp_State"];
            [dict setObject:[rs stringForColumn:@"Comp_Country"] forKey:@"Comp_Country"];
            [dict setObject:[rs stringForColumn:@"Telephone"] forKey:@"Comp_Telephone"];
            [dict setObject:[rs stringForColumn:@"Email"] forKey:@"Comp_Email"];
            [dict setObject:[rs stringForColumn:@"WebSite"] forKey:@"Comp_WebSite"];
            [dict setObject:[rs stringForColumn:@"GstNo"] forKey:@"Comp_GstNo"];
            [dict setObject:[rs stringForColumn:@"RegistrationNo"] forKey:@"Comp_RegistrationNo"];
            [dict setObject:@"Edit" forKey:@"User_Action"];
            
            
        }
        else
        {
            //self.companyName.enabled = YES;
            [dict setObject:@"New" forKey:@"User_Action"];
            [dict setObject:@"" forKey:@"App_Status"];
        }
        
        [companyData addObject:dict];
        dict = nil;
        
        appStatus = nil;
        appTerminalQty = nil;
        appPurchaseID = nil;
        appDeviceID = nil;
        appExpDate = nil;
        appAction = nil;
        
        [rs close];
        
    }];
    return companyData;
}


+(BOOL)updateWebApiRegitration
{
    
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc]initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    NSDictionary *parameters = @{@"DealerID":@"azlim",@"Password":@"12334",@"Version":@"2016-11.19"};
    NSMutableURLRequest *req = [[AFJSONRequestSerializer serializer]requestWithMethod:@"POST" URLString:@"http://idealeraspxoffice.azurewebsites.net/DealerLogin.aspx" parameters:parameters error:nil];
    req.timeoutInterval = [[[NSUserDefaults standardUserDefaults]valueForKey:@"timeoutInterval"]longValue];
    
    [[manager dataTaskWithRequest:req completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if (!error) {
            NSDictionary* json = [NSJSONSerialization JSONObjectWithData:responseObject
                                                                 options:kNilOptions
                                                                   error:&error];
            NSLog(@"%@",[json objectForKey:@"Result"]);
            
            
        } else {
            
            NSLog(@"Error: %@, %@, %@", error, response, responseObject);
            
        }
    }]resume];
    
    return true;
}

+(NSString *)insertIntoCompanyTableWithDataArray:(NSArray *)compArray
{
 
    __block NSString *result;
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:[[compArray objectAtIndex:0]objectForKey:@"SqlPath"]];
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        //[dbComp beginTransaction];
        [db executeUpdate:@"insert into company (Comp_Company, Comp_Country, Comp_State, Comp_Address1, Comp_Address2, Comp_Address3, Comp_City, Comp_Telephone, Comp_PostCode, Comp_WebSite, Comp_Email, Comp_GstNo, Comp_RegistrationNo) values (?,?,?,?,?,?,?,?,?,?,?,?,?)",[[compArray objectAtIndex:0]objectForKey:@"CompName"], [[compArray objectAtIndex:0]objectForKey:@"CompCountry"], [[compArray objectAtIndex:0]objectForKey:@"CompState"],[[compArray objectAtIndex:0]objectForKey:@"CompAdd1"],[[compArray objectAtIndex:0]objectForKey:@"CompAdd2"],[[compArray objectAtIndex:0]objectForKey:@"CompAdd3"],[[compArray objectAtIndex:0]objectForKey:@"CompCity"],[[compArray objectAtIndex:0]objectForKey:@"CompTel"],[[compArray objectAtIndex:0]objectForKey:@"CompPost"],[[compArray objectAtIndex:0]objectForKey:@"CompWebsite"],[[compArray objectAtIndex:0]objectForKey:@"CompEmail"],[[compArray objectAtIndex:0]objectForKey:@"CompGst"],[[compArray objectAtIndex:0]objectForKey:@"CompReg"]];
        //[dbComp commit];
        
        if (![db hadError]) {
            result = @"Success";
        }
        else
        {
            //[self showAlertView:[dbComp lastErrorMessage] title:@"Error"];
            result = [db lastErrorMessage];
            *rollback = YES;
            //NSLog(@"Err %d: %@", [dbComp lastErrorCode], [dbComp lastErrorMessage]);
        }
        
        NSDate *today = [NSDate date];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"yyyy-MM-dd"];
        //[dateFormat setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
        NSString *dateStartDemo;    // = [dateFormat stringFromDate:today];
        
        dateStartDemo = [self convertDateFormatWithDate:[dateFormat stringFromDate:today]];
        
        
        NSDate *dateEnd = [today dateByAddingTimeInterval:60*60*24*30];
        NSString *dateEndDemo; //= [dateFormat stringFromDate:dateEnd];
        
        dateEndDemo = [self convertDateFormatWithDate:[dateFormat stringFromDate:dateEnd]];
        
        if ([result isEqualToString:@"Success"]) {
            [db executeUpdate:@"Insert into AppRegistration ( "
             " App_CompanyName, App_Status, App_StartDate, App_EndDate, App_DemoDay, App_DeviceActivateDate, App_TerminalQty) values(?,?,?,?,?,?,?)",[[compArray objectAtIndex:0] objectForKey:@"CompName"],@"DEMO",dateStartDemo,dateEndDemo,@"30",dateStartDemo,[NSNumber numberWithInt:5]];
            
            if ([db hadError]) {
                result = [db lastErrorMessage];
                *rollback = YES;
            }
            else
            {
                result = @"Success";
            }
            
        }
        
        dateEndDemo = nil;
        dateStartDemo = nil;
        dateFormat = nil;
        
    }];
    
    
    
    [queue close];
    
    return result;
}

+(NSString *)convertDateFormatWithDate:(NSString *)date{
    NSString *returnDate;
    NSDateFormatter *dateFormat2 = [[NSDateFormatter alloc] init];
    [dateFormat2 setDateFormat:@"yyyy-MM-dd"];
    NSDate *dateTmp  = [dateFormat2 dateFromString:date]; // getting date from string with english locale
    [dateFormat2 setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    [dateFormat2 setDateFormat:@"yyyy-MMM-dd"];
    returnDate = [dateFormat2 stringFromDate:dateTmp];
    dateFormat2 = nil;
    return returnDate;
}

+(NSString *)updateIntoCompanyTableWithDataArray:(NSArray *)compArray
{
    __block NSString *result;
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:[[compArray objectAtIndex:0]objectForKey:@"SqlPath"]];
    
    [queue inDatabase:^(FMDatabase *db) {
        //[dbComp beginTransaction];
        
        [db executeUpdate:@"Update Company set Comp_Company = ?,"
                      " Comp_Country = ?, Comp_State = ?, Comp_Address1 = ?,"
                      "Comp_Address2 = ?, Comp_Address3 = ?, Comp_City = ?,"
                      "Comp_Telephone = ?, Comp_PostCode = ?, Comp_WebSite = ?,"
                      "Comp_Email = ?, Comp_GstNo = ?, Comp_RegistrationNo = ?"
                      ,[[compArray objectAtIndex:0]objectForKey:@"CompName"], [[compArray objectAtIndex:0]objectForKey:@"CompCountry"], [[compArray objectAtIndex:0]objectForKey:@"CompState"], [[compArray objectAtIndex:0]objectForKey:@"CompAdd1"], [[compArray objectAtIndex:0]objectForKey:@"CompAdd2"], [[compArray objectAtIndex:0]objectForKey:@"CompAdd3"], [[compArray objectAtIndex:0]objectForKey:@"CompCity"],[[compArray objectAtIndex:0]objectForKey:@"CompTel"],[[compArray objectAtIndex:0]objectForKey:@"CompPost"],[[compArray objectAtIndex:0]objectForKey:@"CompWebsite"], [[compArray objectAtIndex:0]objectForKey:@"CompEmail"], [[compArray objectAtIndex:0]objectForKey:@"CompGst"],[[compArray objectAtIndex:0]objectForKey:@"CompReg"]];
        
        if (![db hadError]) {
            result = @"Success";
        }
        else
        {
            //[self showAlertView:[dbComp lastErrorMessage] title:@"Error"];
            result = [db lastErrorMessage];
            
        }
        if ([result isEqualToString:@"Success"]) {
            [db executeUpdate:@"Update AppRegistration set App_CompanyName = ?, App_Status = ?, App_ProductKey = ?, App_ReqExpdate = ?, App_Action = ?",[[compArray objectAtIndex:0]objectForKey:@"CompName"],[[compArray objectAtIndex:0] objectForKey:@"AppStatus"],[[compArray objectAtIndex:0] objectForKey:@"AppProductKey"],[[compArray objectAtIndex:0] objectForKey:@"AppExpDate"],[[compArray objectAtIndex:0]objectForKey:@"AppAction"]];
            
            if (![db hadError]) {
                result = @"Success";
            }
            else
            {
                result = [db lastErrorMessage];
            }
            
        }
        
    }];
    
    [queue close];
    
    return result;
}

+(NSMutableDictionary *)getGeneralnTableSettingWithTableName:(NSString *)tbName dbPath:(NSString *)dbPath
{
    __block  NSMutableDictionary *data = [NSMutableDictionary dictionary];
    
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        NSString *enableGst;
        FMResultSet *rsTax = [db executeQuery:@"Select * from GeneralSetting"];
        
        if ([rsTax next]) {
            if ([rsTax intForColumn:@"GS_EnableGST"] == 1) {
                enableGst = @"Yes";
            }
            else
            {
                enableGst = @"No";
            }
            [data setObject:[rsTax stringForColumn:@"GS_EnableGST"] forKey:@"EnableGst"];
            [data setObject:[rsTax stringForColumn:@"GS_EnableSVG"] forKey:@"EnableSVG"];
            
            
        }
        [rsTax close];
        
        if ([enableGst isEqualToString:@"Yes"]) {
            FMResultSet *rsServiceTaxGst = [db executeQuery:@"Select T_Percent from GeneralSetting gs inner join Tax t on gs.GS_ServiceGstCode = t.T_Name"
                                            " where gs.GS_ServiceTaxGst  = 1"];
            
            if ([rsServiceTaxGst next]) {
                //[[LibraryAPI sharedInstance] setServiceTaxGstPercent:[rsServiceTaxGst doubleForColumn:@"T_Percent"]];
                [data setObject:[rsServiceTaxGst stringForColumn:@"T_Percent"] forKey:@"ServiceTaxGstPercent"];
            }
            else
            {
                //[[LibraryAPI sharedInstance] setServiceTaxGstPercent:0.00];
                [data setObject:@"0.00" forKey:@"ServiceTaxGstPercent"];
            }
            
            [rsServiceTaxGst close];
        }
        else
        {
            //[[LibraryAPI sharedInstance] setServiceTaxGstPercent:0.00];
            [data setObject:@"0.00" forKey:@"ServiceTaxGstPercent"];
            
        }
        
        FMResultSet *rsTable = [db executeQuery:@"Select TP_Name,TP_Percent, TP_Overide,TP_DineType from TablePlan where TP_Name = ?",tbName];
        
        if ([rsTable next]) {
            
            if ([rsTable intForColumn:@"TP_Overide"] == 1) {
                [data setObject:@"1" forKey:@"TableSVGOverRide"];
                if ( [rsTable doubleForColumn:@"TP_Percent"] > 0.0) {
                    //get service tax percent follow table
                    //[[LibraryAPI sharedInstance] setServiceTaxPercent:[rsTable stringForColumn:@"TP_Percent"]];
                    [data setObject:[rsTable stringForColumn:@"TP_Percent"] forKey:@"TableSVGPercent"];
                }
                else if ([rsTable doubleForColumn:@"TP_Percent"] == 0.0) {
                    //[[LibraryAPI sharedInstance] setServiceTaxPercent:@"0.00"];
                    [data setObject:@"0.00" forKey:@"TableSVGPercent"];
                    
                }
                else
                {
                    //[[LibraryAPI sharedInstance] setServiceTaxPercent:@"0.00"];
                    [data setObject:@"0.00" forKey:@"TableSVGPercent"];
                }
                
            }
            else
            {
                //[[LibraryAPI sharedInstance] setServiceTaxPercent:@"-"];
                [data setObject:@"0" forKey:@"TableSVGOverRide"];
                [data setObject:@"0.00" forKey:@"TableSVGPercent"];
                
            }
            [rsTable close];
            
            
        }
        else
        {
            [rsTable close];
        }
        
    }];
    
    [queue close];
    
    return data;

}

+(NSMutableArray *)calcGSTWithDbPath:(NSString *)dbPath SoDocNo:(NSString *)soNo CompEnableGst:(int)compEnableGst CompEnableSVG:(int)compEnableSVG TaxType:(NSString *)taxType OrderDataStatus:(NSString *)orderDataStatus TableName:(NSString *)tableName TableDineType:(int)tableDineStatus TableSVC:(double)tableSVC OverrideSVG:(NSString *)overRideSVG TerminalType:(NSString *)terminalType
{
    NSString *textTotalTax;
    NSString *textSubTotal;
    NSString *textTotal;
    NSMutableArray *salesArray;
    
    NSString *textServiceTax;
    NSString *itemServiceTaxGst;
    NSString *itemServiceTaxGstLong;
    
    NSString *textDiscountAmt;
    NSString *b4Discount;
    
    double serviceTaxRate;
    double gst;
    double itemSellingPrice;
    double itemTaxAmt = 0;
    double totalItemSellingAmt;
    double totalItemTaxAmt;
    double itemInPriceAfterDis = 0;
    
    salesArray = [[NSMutableArray alloc]init];
    FMDatabase *dbTable = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTable open]) {
        NSLog(@"Fail To Open Database");
    }
    
    FMResultSet *rs = [dbTable executeQuery:@"Select SOD_ItemCode, SOD_ItemDescription, SOD_Quantity, SOD_Price, SOD_UnitPrice as IM_SalesPrice, SOD_DiscInPercent, SOD_DiscValue ,SOD_DiscType, SOD_TotalDisc, IFNULL(SOD_TaxCode,'-') as SOD_TaxCode, SOD_TaxRate, IFNULL(SOD_ServiceTaxCode,'-') as SOD_ServiceTaxCode, SOD_ServiceTaxRate, SOD_Remark,SOD_TakeAwayYN, SOH_PaxNo, substr(SOD_ManualID,13) as 'Index',IFNULL(SOD_TotalCondimentSurCharge,'0.00') as IM_TotalCondimentSurCharge from SalesOrderHdr SOH left join SalesOrderDtl SOD on SOH.SOH_DocNo = SOD.SOD_DocNo "
                       " where SOD_DocNo = ?",soNo];
    
    while ([rs next]) {
        if (compEnableGst == 1) {
            gst = [rs doubleForColumn:@"SOD_TaxRate"];
        }
        else
        {
            gst = 0.00;
        }
        
        
        if ([taxType isEqualToString:@"Inc"]) {
            //gst inc
            itemSellingPrice = [rs doubleForColumn:@"SOD_Price"] / ((gst / 100)+1);
            
            textSubTotal = [NSString stringWithFormat:@"%.02f",[rs doubleForColumn:@"SOD_Price"] * [rs doubleForColumn:@"SOD_Quantity"]];
            if ([rs doubleForColumn:@"SOD_DiscValue"] == 0) {
                //itemTaxAmt = [rs doubleForColumn:@"SOD_Price"] - itemSellingPrice;
                itemTaxAmt = [[NSString stringWithFormat:@"%.06f",[rs doubleForColumn:@"SOD_Price"] - itemSellingPrice] doubleValue];
                textTotalTax = [NSString stringWithFormat:@"%f",itemTaxAmt * [rs doubleForColumn:@"SOD_Quantity"]];
                textTotal = textSubTotal;
                
                totalItemSellingAmt = [textSubTotal doubleValue] / ((gst / 100)+1);
                totalItemTaxAmt = [textTotalTax doubleValue];
            }
            else
            {
                textDiscountAmt = [NSString stringWithFormat:@"%0.2f",[textSubTotal doubleValue] * ([rs doubleForColumn:@"SOD_DiscInPercent"] / 100)];
                b4Discount = [NSString stringWithFormat:@"%0.2f",([rs doubleForColumn:@"SOD_Quantity"] * [rs doubleForColumn:@"SOD_Price"]) - [textDiscountAmt doubleValue]];
                itemInPriceAfterDis = [b4Discount doubleValue] / ((gst / 100)+1);
                
                textTotalTax = [NSString stringWithFormat:@"%.02f",[textSubTotal doubleValue] - [textDiscountAmt doubleValue] - itemInPriceAfterDis];
                
                textTotal = [NSString stringWithFormat:@"%0.2f",[textSubTotal doubleValue] - [textDiscountAmt doubleValue]];
                totalItemSellingAmt = itemInPriceAfterDis;
                
                totalItemTaxAmt = [textSubTotal doubleValue] - [textDiscountAmt doubleValue] - itemInPriceAfterDis;
            }
            
        }
        else
        {
            // gst ex
            itemSellingPrice = [rs doubleForColumn:@"SOD_Price"];
            textSubTotal = [NSString stringWithFormat:@"%.02f",[rs doubleForColumn:@"SOD_Price"] * [rs doubleForColumn:@"SOD_Quantity"]];
            if ([rs doubleForColumn:@"SOD_DiscValue"] == 0) {
                textTotalTax = [NSString stringWithFormat:@"%.02f",[textSubTotal doubleValue] * (gst / 100)];
                
                itemTaxAmt = [rs doubleForColumn:@"SOD_Price"] * (gst / 100);
                
                textTotal = [NSString stringWithFormat:@"%.02f",[textSubTotal doubleValue] + [textTotalTax doubleValue]];
                totalItemSellingAmt = [textSubTotal doubleValue];
                //totalItemTaxAmt = [textTotalTax doubleValue];
                totalItemTaxAmt = [[NSString stringWithFormat:@"%.06f",([textSubTotal doubleValue] - 0.00) * (gst/100)]doubleValue];
            }
            else
            {
                textDiscountAmt = [NSString stringWithFormat:@"%0.2f",[textSubTotal doubleValue] * ([rs doubleForColumn:@"SOD_DiscInPercent"] / 100)];
                textTotalTax = [NSString stringWithFormat:@"%.02f",([textSubTotal doubleValue] - [textDiscountAmt doubleValue]) * (gst/100)];
                textTotal = [NSString stringWithFormat:@"%.02f", [textSubTotal doubleValue] + [textTotalTax doubleValue] - [textDiscountAmt doubleValue]];
                totalItemSellingAmt = [textSubTotal doubleValue];
                totalItemTaxAmt = [[NSString stringWithFormat:@"%.06f",([textSubTotal doubleValue] - [textDiscountAmt doubleValue]) * (gst/100)]doubleValue];
                
            }
            
            
        }
        
        if (compEnableSVG == 1) {
            if ([rs intForColumn:@"SOD_TakeAwayYN"] == 0) {
                if ([overRideSVG isEqualToString:@"0"]) {
                    serviceTaxRate = [rs doubleForColumn:@"SOD_ServiceTaxRate"];
                }
                else
                {
                    serviceTaxRate = tableSVC;
                }
                if (serviceTaxRate != 0.00) {
                    
                    if ([taxType isEqualToString:@"Inc"]) {
                        
                        if ([rs doubleForColumn:@"SOD_DiscValue"] == 0) {
                            textServiceTax = [NSString stringWithFormat:@"%.06f",totalItemSellingAmt * (serviceTaxRate / 100.0)];
                            itemServiceTaxGst = [NSString stringWithFormat:@"%0.2f",[textServiceTax doubleValue] * ([[LibraryAPI sharedInstance]getServiceTaxGstPercent] / 100)];
                            itemServiceTaxGstLong = [NSString stringWithFormat:@"%0.6f",[textServiceTax doubleValue] * ([[LibraryAPI sharedInstance]getServiceTaxGstPercent] / 100)];
                        }
                        else
                        {
                            textServiceTax = [NSString stringWithFormat:@"%0.6f",itemInPriceAfterDis * (serviceTaxRate / 100.0)] ;
                            itemServiceTaxGst = [NSString stringWithFormat:@"%0.2f",[textServiceTax doubleValue] * ([[LibraryAPI sharedInstance]getServiceTaxGstPercent] / 100)];
                            itemServiceTaxGstLong = [NSString stringWithFormat:@"%0.6f",[textServiceTax doubleValue] * ([[LibraryAPI sharedInstance]getServiceTaxGstPercent] / 100)];
                        }
                        
                        
                    }
                    else
                    {
                        if ([rs doubleForColumn:@"SOD_DiscValue"] == 0) {
                            textServiceTax = [NSString stringWithFormat:@"%0.6f",totalItemSellingAmt * (serviceTaxRate / 100.0)];
                            itemServiceTaxGst = @"0.00";
                            itemServiceTaxGstLong = textServiceTax;
                        }
                        else
                        {
                            textServiceTax = [NSString stringWithFormat:@"%0.6f",(totalItemSellingAmt - [textDiscountAmt doubleValue]) * (serviceTaxRate / 100.0)];
                            itemServiceTaxGst = @"0.00";
                            itemServiceTaxGstLong = textServiceTax;
                        }
                        
                    }
                    
                }
                else
                {
                    serviceTaxRate = 0.00;
                    textServiceTax = @"0.00";
                    itemServiceTaxGst = @"0.00";
                    itemServiceTaxGstLong = @"0.00";
                }

            }
            else
            {
                serviceTaxRate = 0.00;
                textServiceTax = @"0.00";
                itemServiceTaxGst = @"0.00";
                itemServiceTaxGstLong = @"0.00";
            }
            
        }
        else
        {
            serviceTaxRate = 0.00;
            textServiceTax = @"0.00";
            itemServiceTaxGst = @"0.00";
            itemServiceTaxGstLong = @"0.00";
        }
        
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        
        [data setObject:orderDataStatus forKey:@"Status"];
        [data setObject:soNo forKey:@"SOH_DocNo"];
        [data setObject:[rs stringForColumn:@"SOD_ItemCode"] forKey:@"IM_ItemCode"];
        [data setObject:[rs stringForColumn:@"SOD_ItemDescription"] forKey:@"IM_Description"];
        [data setObject:[NSString stringWithFormat:@"%.02f",[rs doubleForColumn:@"SOD_Price"]] forKey:@"IM_Price"];
        [data setObject:[NSString stringWithFormat:@"%.02f",[rs doubleForColumn:@"IM_SalesPrice"]] forKey:@"IM_SalesPrice"];
        //one item selling price not included tax
        [data setObject:[NSString stringWithFormat:@"%0.6f",itemSellingPrice] forKey:@"IM_SellingPrice"];
        [data setObject:[NSString stringWithFormat:@"%0.6f",itemTaxAmt] forKey:@"IM_Tax"];
        [data setObject:[rs stringForColumn:@"SOD_Quantity"] forKey:@"IM_Qty"];
        [data setObject:[rs stringForColumn:@"SOD_DiscInPercent"] forKey:@"IM_DiscountInPercent"];
        
        [data setObject:[NSString stringWithFormat:@"%ld",(long)gst] forKey:@"IM_Gst"];
        
        [data setObject:textTotalTax forKey:@"IM_TotalTax"]; //sum tax amt
        [data setObject:[rs stringForColumn:@"SOD_DiscType"] forKey:@"IM_DiscountType"];
        [data setObject:[rs stringForColumn:@"SOD_DiscValue"] forKey:@"IM_Discount"]; // discount given
        [data setObject:[rs stringForColumn:@"SOD_TotalDisc"] forKey:@"IM_DiscountAmt"];  // sum discount
        [data setObject:textSubTotal forKey:@"IM_SubTotal"];
        [data setObject:textTotal forKey:@"IM_Total"];
        
        //------------tax code-----------------
        [data setObject:[rs stringForColumn:@"SOD_TaxCode"] forKey:@"IM_GSTCode"];
        
        //-------------service tax-------------
        [data setObject:[rs stringForColumn:@"SOD_ServiceTaxCode"] forKey:@"IM_ServiceTaxCode"];  //svc tax code
        [data setObject:textServiceTax forKey:@"IM_ServiceTaxAmt"]; // service tax amount
        [data setObject:[NSString stringWithFormat:@"%ld",(long)serviceTaxRate] forKey:@"IM_ServiceTaxRate"];
        //[data setObject:textServiceTaxGst forKey:@"IM_ServiceTaxGstAmt"];
        
        //------------------------------------------------------------------------------------------
        [data setObject:[NSString stringWithFormat:@"%0.2f", totalItemSellingAmt] forKey:@"IM_totalItemSellingAmt"];  // subtotal not include tax n will replace this
        [data setObject:[NSString stringWithFormat:@"%0.6f", totalItemSellingAmt] forKey:@"IM_totalItemSellingAmtLong"];  // subtotal not include tax
        [data setObject:[NSString stringWithFormat:@"%0.6f", totalItemTaxAmt] forKey:@"IM_totalItemTaxAmtLong"];  // total tax amt
        
        [data setObject:[NSString stringWithFormat:@"%0.3f", [textServiceTax doubleValue]] forKey:@"IM_totalServiceTaxAmt"];  // total service tax amt
        [data setObject:itemServiceTaxGst forKey:@"IM_ServiceTaxGstAmt"];
        [data setObject:itemServiceTaxGstLong forKey:@"IM_ServiceTaxGstAmtLong"];
        
        [data setObject:[rs stringForColumn:@"SOD_Remark"] forKey:@"IM_Remark"];
        [data setObject:tableName forKey:@"IM_TableName"];
        //---------for print kitchen receipt----------------
        
        [data setObject:@"Printed" forKey:@"IM_Print"];
        [data setObject:[rs stringForColumn:@"SOD_Quantity"] forKey:@"IM_OrgQty"];
        
        //---------for item dine in or take away ------------
        [data setObject:[NSString stringWithFormat:@"%d",[rs intForColumn:@"SOD_TakeAwayYN"]] forKey:@"IM_TakeAwayYN"];
        
        //--------- for table pax -----------------------
        [data setObject:[rs stringForColumn:@"SOH_PaxNo"] forKey:@"SOH_PaxNo"];
        [data setObject:@"ItemOrder" forKey:@"OrderType"];
        [data setObject:[rs stringForColumn:@"Index"] forKey:@"Index"];
        
        //---------for main to decide this array-------------
        if ([terminalType isEqualToString:@"Terminal"]) {
            [data setObject:@"Order" forKey:@"IM_Flag"];
            [data setObject:@"0.00" forKey:@"IM_labelTotal"];
            [data setObject:@"0.00" forKey:@"IM_labelTotalDiscount"];
            [data setObject:@"0.00" forKey:@"IM_labelRound"];
            [data setObject:@"0.00" forKey:@"IM_labelSubTotal"];
            [data setObject:@"0.00" forKey:@"IM_labelTaxTotal"];
            [data setObject:@"0.00" forKey:@"IM_labelServiceTaxTotal"];
            [data setObject:@"0.00" forKey:@"IM_serviceTaxGstTotal"];
            [data setObject:tableName forKey:@"IM_Table"];
            
        }

        [salesArray addObject:data];
        
    }
    
    [rs close];
    [dbTable close];
    return  salesArray;
    //salesArray = nil;
}


// get Exclude amount in long and short format. only for GST(include)
+(NSMutableArray *)recalculateGSTSalesOrderWithSalesOrderArray:(NSMutableArray *)salesOrderArray TaxType:(NSString *)taxType
{
    double itemExShort = 0.00;
    double itemExLong = 0.00;
    
    NSString *stringItemExLong;
    NSString *stringItemExShort;
    NSString *temp;
    double diffCent = 0.00;
    NSMutableArray *soArray = [[NSMutableArray alloc]init];
    
    if ([taxType isEqualToString:@"Inc"]) {
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        for (int i = 0; i < salesOrderArray.count; i++) {
            data = [salesOrderArray objectAtIndex:i];
            [data setValue:[NSString stringWithFormat:@"%0.2f",[[[salesOrderArray objectAtIndex:i]objectForKey:@"IM_totalItemSellingAmtLong" ] doubleValue]] forKey:@"IM_totalItemSellingAmt"];
            
            [data setValue:[NSString stringWithFormat:@"%0.2f",[[[salesOrderArray objectAtIndex:i]objectForKey:@"IM_totalItemTaxAmtLong" ] doubleValue]] forKey:@"IM_TotalTax"];
            
            [salesOrderArray replaceObjectAtIndex:i withObject:data];
            
            itemExShort = itemExShort + [[[salesOrderArray objectAtIndex:i] objectForKey:@"IM_totalItemSellingAmt"] doubleValue];
            stringItemExShort = [NSString stringWithFormat:@"%0.2f",itemExShort];
            
            itemExLong = itemExLong + [[[salesOrderArray objectAtIndex:i] objectForKey:@"IM_totalItemSellingAmtLong"] doubleValue];
            stringItemExLong = [NSString stringWithFormat:@"%0.2f",itemExLong];
            
        }
        
        if ([stringItemExLong doubleValue] != [stringItemExShort doubleValue]) {
            //itemExLong = [stringItemExLong doubleValue] - [stringItemExShort doubleValue];
            itemExLong = itemExLong - itemExShort;
            temp = [NSString stringWithFormat:@"%0.2f",itemExLong];
            diffCent = [temp doubleValue];
            
        }
        else
        {
            diffCent = 0.00;
        }
        
    }
    soArray = salesOrderArray;
    return soArray;

}

+(BOOL)updateAppRegistrationTableWithLicenseID:(NSString *)licenseID ProductKey:(NSString *)productKey DeviceStatus:(NSString *)deviceStatus PurchaseID:(NSString *)purchaseID TerminalQty:(NSString *)qty DBPath:(NSString *)dbPath RequestExpDate:(NSString *)resExpDate RequestAction:(NSString *)action
{
    __block BOOL result;
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"Update AppRegistration set App_LicenseID = ?, App_ProductKey = ?, App_Status = ?, App_PurchaseID = ?, App_TerminalQty = ?, App_ReqExpDate = ?, App_Action = ?",licenseID, productKey, deviceStatus,purchaseID,qty,resExpDate,action];
        
        if (![db hadError]) {
            result = true;
            [[LibraryAPI sharedInstance] setAppStatus:deviceStatus];
        }
        else
        {
            result = false;
        }
    }];
    
    [queue close];
    
    return result;
}

+(BOOL)updateAppRegistrationTableWhenAddTerminalWithLicenseID:(NSString *)licenseID ProductKey:(NSString *)productKey DeviceStatus:(NSString *)deviceStatus TerminalQty:(NSString *)qty DBPath:(NSString *)dbPath RequestAction:(NSString *)action
{
    __block BOOL result;
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"Update AppRegistration set App_LicenseID = ?, App_ProductKey = ?, App_Status = ?,  App_TerminalQty = ?, App_Action = ?",licenseID, productKey, deviceStatus,qty,action];
        
        if (![db hadError]) {
            result = true;
            [[LibraryAPI sharedInstance] setAppStatus:deviceStatus];
        }
        else
        {
            result = false;
        }
    }];
    
    [queue close];
    
    return result;
}

+(BOOL)updateAppRegistrationTableWhenDemoWithTerminalQty:(NSString *)qty DBPath:(NSString *)dbPath
{
    __block BOOL result;
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"Update AppRegistration set App_TerminalQty = ?",qty];
        
        if (![db hadError]) {
            result = true;
            //[[LibraryAPI sharedInstance] setAppStatus:deviceStatus];
        }
        else
        {
            result = false;
        }
    }];
    
    [queue close];
    
    return result;
}


// used to recalculate item price bcos of gst
+(NSMutableArray *)calcGSTByItemNo:(int)itemNo DBPath:(NSString *)dbPath ItemPrice:(NSString *)itemPrice CompEnableGst:(int)compEnableGst CompEnableSVG:(int)compEnableSVG TableSVC:(NSString *)tableSVC OverrideSVG:(NSString *)overRideSVG SalesOrderStatus:(NSString *)soStatus TaxType:(NSString *)taxType TableName:(NSString *)tableName ItemDineStatus:(NSString *)itemDineStatus TerminalType:(NSString *)terminalType SalesDict:(NSDictionary *)salesDict IMQty:(NSString *)imQty KitchenStatus:(NSString *)kitchenStatus PaxNo:(NSString *)paxNo DocType:(NSString *)docType CondimentSubTotal:(double)condimentSubtotal ServiceChargeGstPercent:(double)svgGstPercent TableDineStatus:(NSString *)tableDineStatus
{
    
    //IM_Price is for SOD_UnitPrice and SOD_UnitPrice will show on all ordering view
    NSMutableArray *salesArray;
    salesArray = [[NSMutableArray alloc]init];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        
        NSString *itemSalesTax;
        
        NSString *sqlCommand;
        NSString *itemTotalTax;
        NSString *itemSubTotal;
        NSString *itemCondimentSubTotal;
        NSString *itemTotal;
        
        NSString *itemServiceTax;
        NSString *itemServiceTaxGst;
        NSString *itemServiceTaxGstLong;
        
        NSString *itemDiscountAmt;
        NSString *b4Discount;
        
        double serviceTaxRate;
        double gstRate;
        double itemSellingPrice;
        double itemTaxAmt = 0;
        double itemTotalSellingAmt;
        double itemTotalTaxAmt;
        double itemInPriceAfterDis = 0;
        
        if([soStatus isEqualToString:@"Edit"])
        {
            sqlCommand = [NSString stringWithFormat:@"%@ %@ as FinalSellPrice, '%@' as DiscountInPercent,'%@' as ItemQty, '%@' as DiscType, '%@' as DiscValue, '%@' as TotalDisc, '%@' as Remark, '%@' as IM_Qty, '%@' as IM_TotalCondimentSurCharge,'%0.2f' as IM_NewTotalCondimentSurCharge, '%@' as IM_OrgQty ",@"Select ItemMast.*, IFNULL(t1.T_Percent,'0') as T_Percent, IFNULL(t1.T_Name,'-') as T_Name, IFNULL(t2.T_Percent,'0') as Svc_Percent, IFNULL(t2.T_Name,'-') as Svc_Name,",itemPrice,[salesDict objectForKey:@"DiscInPercent"],[salesDict objectForKey:@"ItemQty"],[salesDict objectForKey:@"DiscType"], [salesDict objectForKey:@"DiscValue"],[salesDict objectForKey:@"TotalDisc"],[salesDict objectForKey:@"Remark"],[salesDict objectForKey:@"ItemQty"],[salesDict objectForKey:@"IM_TotalCondimentSurCharge"],condimentSubtotal, [salesDict objectForKey:@"OrgQty"]];
        }
        else
        {
            sqlCommand = [NSString stringWithFormat:@"%@,'%@' as IM_Qty, '0.00' as IM_TotalCondimentSurCharge, '%0.2f' as IM_NewTotalCondimentSurCharge, '%@' as IM_OrgQty",@"Select ItemMast.*, IFNULL(t1.T_Percent,'0') as T_Percent, IFNULL(t1.T_Name,'-') as T_Name, IFNULL(t2.T_Percent,'0') as Svc_Percent, IFNULL(t2.T_Name,'-') as Svc_Name, IM_SalesPrice as FinalSellPrice, '0.00' as DiscountInPercent, '1' as ItemQty, '0' as DiscType,'0' as DiscValue, '0.00' as TotalDisc,'' as Remark",imQty,condimentSubtotal,@"1"];
        }
        
        FMResultSet *rs = [db executeQuery:[NSString stringWithFormat:@"%@ %@",sqlCommand,@",IFNULL(P.P_PortName,'0.0.0.0') as IM_IpAddress, IFNULL(P.P_PrinterName,'NonPrinter') as IM_PrinterName, IM_ServiceType from ItemMast "
                                                 "left join Tax t1 on ItemMast.IM_Tax = t1.T_Name "
                                                 " left join Tax t2 on ItemMast.IM_ServiceTax = t2.T_Name "
                                            //" left join ModifierDtl MD on ItemMast.IM_Itemcode = MD_ItemCode "
                                            //" left join ItemPrinter IP on IP.IP_ItemNo = ItemMast.IM_ItemCode"
                                            " left join (select IP_ItemNo, IP_PrinterName from ItemPrinter group by IP_ItemNo) as IP on  IP.IP_ItemNo = ItemMast.IM_ItemCode"
                                            " left join Printer P on IP.IP_PrinterName = P.P_PrinterName"
                                                 " where IM_ItemNo = ?"],[NSNumber numberWithInt:itemNo]];
        
        if ([rs next])
        {
            if (compEnableGst == 1) {
                gstRate = [rs doubleForColumn:@"T_Percent"];
            }
            else
            {
                gstRate = 0.00;
            }
            
            //NSLog(@"disvalue %f",[rs doubleForColumn:@"DiscountInPercent"]);
            if ([taxType isEqualToString:@"Inc"]) {
                //gst inc
                
                itemSubTotal = [NSString stringWithFormat:@"%.02f",([rs doubleForColumn:@"FinalSellPrice"] - [rs doubleForColumn:@"IM_TotalCondimentSurCharge"] + [rs doubleForColumn:@"IM_NewTotalCondimentSurCharge"]) * [rs doubleForColumn:@"IM_Qty"]];
                
                itemCondimentSubTotal = [NSString stringWithFormat:@"%.02f",([rs doubleForColumn:@"FinalSellPrice"] - [rs doubleForColumn:@"IM_TotalCondimentSurCharge"] + [rs doubleForColumn:@"IM_NewTotalCondimentSurCharge"]) * [rs doubleForColumn:@"IM_Qty"]];
                
                itemSellingPrice = [itemCondimentSubTotal doubleValue] / ((gstRate / 100)+1);
                
                
                if ([rs doubleForColumn:@"DiscValue"] == 0) {
                    
                    itemSalesTax = [NSString stringWithFormat:@"%.02f",([rs doubleForColumn:@"FinalSellPrice"] - [rs doubleForColumn:@"IM_TotalCondimentSurCharge"] + [rs doubleForColumn:@"IM_NewTotalCondimentSurCharge"])];
                    
                    itemSalesTax = [NSString stringWithFormat:@"%0.6f",[itemSalesTax doubleValue] - ([itemSalesTax doubleValue] / ((gstRate / 100)+1))];
                    
                    itemTaxAmt = [itemCondimentSubTotal doubleValue] - itemSellingPrice;
                    itemTotalTax = [NSString stringWithFormat:@"%f",itemTaxAmt];;
                    itemTotal = itemCondimentSubTotal;
                    itemTotalSellingAmt = [itemCondimentSubTotal doubleValue] / ((gstRate / 100)+1);;
                    //itemTotalTaxAmt = [itemTotalTax doubleValue];
                    itemTotalTaxAmt = [itemCondimentSubTotal doubleValue] - itemTotalSellingAmt;
                }
                else
                {
                    
                    itemSalesTax = [NSString stringWithFormat:@"%.02f",([rs doubleForColumn:@"FinalSellPrice"] - [rs doubleForColumn:@"IM_TotalCondimentSurCharge"] + [rs doubleForColumn:@"IM_NewTotalCondimentSurCharge"])];
                    
                    itemSalesTax = [NSString stringWithFormat:@"%0.6f",[itemSalesTax doubleValue] - ([itemSalesTax doubleValue] * ([rs doubleForColumn:@"DiscountInPercent"] / 100))];
                    
                    itemSalesTax = [NSString stringWithFormat:@"%0.6f",[itemSalesTax doubleValue] - ([itemSalesTax doubleValue] / ((gstRate / 100)+1))];
                    
                    itemDiscountAmt = [NSString stringWithFormat:@"%0.2f",[itemCondimentSubTotal doubleValue] * ([rs doubleForColumn:@"DiscountInPercent"] / 100)];
                    b4Discount = [NSString stringWithFormat:@"%0.2f",([rs doubleForColumn:@"IM_Qty"] * [rs doubleForColumn:@"FinalSellPrice"]) - [itemDiscountAmt doubleValue]];
                    itemInPriceAfterDis = [b4Discount doubleValue] / ((gstRate / 100)+1);
                    
                    itemTotalTax = [NSString stringWithFormat:@"%.02f",[itemCondimentSubTotal doubleValue] - [itemDiscountAmt doubleValue] - itemInPriceAfterDis];
                    
                    itemTotal = [NSString stringWithFormat:@"%0.2f",[itemCondimentSubTotal doubleValue] - [itemDiscountAmt doubleValue]];
                    itemTotalSellingAmt = itemInPriceAfterDis;
                    
                    itemTotalTaxAmt = [itemCondimentSubTotal doubleValue] - [itemDiscountAmt doubleValue] - itemInPriceAfterDis;
                    
                    itemTaxAmt = itemTotalTaxAmt;
                }
                
                
                
            }
            else
            {
                // gst ex
                
                //itemSellingPrice = [rs doubleForColumn:@"FinalSellPrice"];
                itemSubTotal = [NSString stringWithFormat:@"%.02f",([rs doubleForColumn:@"FinalSellPrice"] - [rs doubleForColumn:@"IM_TotalCondimentSurCharge"] + [rs doubleForColumn:@"IM_NewTotalCondimentSurCharge"]) * [rs doubleForColumn:@"IM_Qty"]];
                
                 itemCondimentSubTotal = [NSString stringWithFormat:@"%.02f",([rs doubleForColumn:@"FinalSellPrice"] - [rs doubleForColumn:@"IM_TotalCondimentSurCharge"] + [rs doubleForColumn:@"IM_NewTotalCondimentSurCharge"]) * [rs doubleForColumn:@"IM_Qty"]];
                
                itemSalesTax = [NSString stringWithFormat:@"%.02f",([rs doubleForColumn:@"FinalSellPrice"] - [rs doubleForColumn:@"IM_TotalCondimentSurCharge"] + [rs doubleForColumn:@"IM_NewTotalCondimentSurCharge"])];
                
                itemSellingPrice = [itemCondimentSubTotal doubleValue];
                
                if ([rs doubleForColumn:@"DiscValue"] == 0) {
                    
                    itemSalesTax = [NSString stringWithFormat:@"%.02f",[itemSalesTax doubleValue] * (gstRate / 100)];
                    
                    itemTotalTax = [NSString stringWithFormat:@"%.02f",[itemCondimentSubTotal doubleValue] * (gstRate / 100)];
                    itemTaxAmt = [itemTotalTax doubleValue];
                    
                    itemTotal = [NSString stringWithFormat:@"%.02f",[itemCondimentSubTotal doubleValue] + [itemTotalTax doubleValue]];
                    
                    itemTotalSellingAmt = [itemCondimentSubTotal doubleValue];
                    
                    itemTotalTaxAmt = [[NSString stringWithFormat:@"%.06f",[itemCondimentSubTotal doubleValue] * (gstRate / 100)]doubleValue];
                }
                else
                {
                    //NSLog(@"%f",[rs doubleForColumn:@"DiscountInPercent"]);
                    
                    itemDiscountAmt = [NSString stringWithFormat:@"%0.2f",[itemCondimentSubTotal doubleValue] * ([rs doubleForColumn:@"DiscountInPercent"] / 100)];
                    
                    itemSalesTax = [NSString stringWithFormat:@"%0.6f",([itemSalesTax doubleValue] - ([itemSalesTax doubleValue] * ([rs doubleForColumn:@"DiscountInPercent"] / 100))) * (gstRate/100)];
                    
                    itemTotalTax = [NSString stringWithFormat:@"%.02f",([itemCondimentSubTotal doubleValue] - [itemDiscountAmt doubleValue]) * (gstRate/100)];
                    itemTotal = [NSString stringWithFormat:@"%.02f", [itemCondimentSubTotal doubleValue] + [itemTotalTax doubleValue] - [itemDiscountAmt doubleValue]];
                    itemTotalSellingAmt = [itemCondimentSubTotal doubleValue];
                    itemTotalTaxAmt = [[NSString stringWithFormat:@"%.06f",([itemCondimentSubTotal doubleValue] - [itemDiscountAmt doubleValue]) * (gstRate/100)]doubleValue];
                }
                
                //itemSubTotal = [NSString stringWithFormat:@"%.02f",[rs doubleForColumn:@"FinalSellPrice"]];
                
                
            }
            
            if (compEnableSVG == 1) {
                if ([tableDineStatus isEqualToString:@"0"]) {
                    if ([itemDineStatus isEqualToString:@"0"]) {
                        if ([overRideSVG isEqualToString:@"0"]) {
                            serviceTaxRate = [rs doubleForColumn:@"Svc_Percent"];
                        }
                        else
                        {
                            if ([rs doubleForColumn:@"Svc_Percent"] == 0.00) {
                                serviceTaxRate = [rs doubleForColumn:@"Svc_Percent"];
                            }
                            else
                            {
                                serviceTaxRate = [tableSVC doubleValue];
                            }
                            
                        }
                    }
                    else
                    {
                        serviceTaxRate = 0.00;
                    }
                }
                else
                {
                    if ([rs doubleForColumn:@"Svc_Percent"] == 0.00) {
                        serviceTaxRate = [rs doubleForColumn:@"Svc_Percent"];
                    }
                    else
                    {
                        if ([tableSVC isEqualToString:@"-"]) {
                            serviceTaxRate = 0;
                        }
                        else
                        {
                            serviceTaxRate = [tableSVC doubleValue];
                        }
                        
                    }
                }
                
                
                if ([taxType isEqualToString:@"Inc"]) {
                    // mark 20161020 hardcode
                    if ([rs doubleForColumn:@"DiscValue"] == 0) {
                        itemServiceTax = [NSString stringWithFormat:@"%.06f",itemTotalSellingAmt * (serviceTaxRate / 100.0)];
                        itemServiceTaxGst = [NSString stringWithFormat:@"%0.2f",[itemServiceTax doubleValue] * (svgGstPercent / 100)];
                        itemServiceTaxGstLong = [NSString stringWithFormat:@"%0.6f",[itemServiceTax doubleValue] * (svgGstPercent/100)];
                    }
                    else
                    {
                        itemServiceTax = [NSString stringWithFormat:@"%.06f",itemInPriceAfterDis * (serviceTaxRate / 100.0)];
                        
                        itemServiceTaxGst = [NSString stringWithFormat:@"%0.2f",[itemServiceTax doubleValue] * (svgGstPercent / 100)];
                        itemServiceTaxGstLong = [NSString stringWithFormat:@"%0.6f",[itemServiceTax doubleValue] * (svgGstPercent/100)];
                        
                    }
                    
                    
                }
                else
                {
                    if ([rs doubleForColumn:@"DiscValue"] == 0) {
                        itemServiceTax = [NSString stringWithFormat:@"%.06f",itemTotalSellingAmt * (serviceTaxRate / 100.0)];
                        itemServiceTaxGst = @"0.00";
                        itemServiceTaxGstLong = itemServiceTax;
                    }
                    else
                    {
                        itemServiceTax = [NSString stringWithFormat:@"%0.6f",(itemTotalSellingAmt - [itemDiscountAmt doubleValue]) * (serviceTaxRate / 100.0)];
                        itemServiceTaxGst = @"0.00";
                        itemServiceTaxGstLong = itemServiceTax;
                    }
                    
                }
                

            }
            else
            {
                serviceTaxRate = 0.00;
                itemServiceTax = @"0.00";
                itemServiceTaxGst = @"0.00";
                itemServiceTaxGstLong = @"0.00";
            }
            
            NSMutableDictionary *data = [NSMutableDictionary dictionary];
            
            [data setObject:soStatus forKey:@"Status"];
            [data setObject:@"NonSONo" forKey:@"SOH_DocNo"];
            
            [data setObject:[rs stringForColumn:@"IM_ItemNo"] forKey:@"IM_ItemNo"];
            
            [data setObject:[rs stringForColumn:@"IM_ItemCode"] forKey:@"IM_ItemCode"];
            [data setObject:[rs stringForColumn:@"IM_Description"] forKey:@"IM_Description"];
            //--------------item with condiment unit price = condiment unitprice + item unitprice------------
            //[data setObject:[NSString stringWithFormat:@"%.02f",[rs doubleForColumn:@"FinalSellPrice"]] forKey:@"IM_Price"]; // old calculation
            
            [data setObject:[NSString stringWithFormat:@"%.02f",[rs doubleForColumn:@"FinalSellPrice"] - [rs doubleForColumn:@"IM_TotalCondimentSurCharge"] + [rs doubleForColumn:@"IM_NewTotalCondimentSurCharge"]] forKey:@"IM_Price"];
            //NSLog(@"%f,,,,,%f,,,,,,,%f",[rs doubleForColumn:@"FinalSellPrice"], [rs doubleForColumn:@"IM_TotalCondimentSurCharge"], condimentSubtotal);
            //----------------------------------------------------------------------------------------
            [data setObject:[NSString stringWithFormat:@"%.02f",[rs doubleForColumn:@"IM_SalesPrice"]] forKey:@"IM_SalesPrice"];
            //one item selling price not included tax
            [data setObject:[NSString stringWithFormat:@"%0.6f",itemSellingPrice] forKey:@"IM_SellingPrice"];
            //[data setObject:[NSString stringWithFormat:@"%0.6f",itemTaxAmt] forKey:@"IM_Tax"];
            [data setObject:itemSalesTax forKey:@"IM_Tax"];
            [data setObject:[rs stringForColumn:@"IM_Qty"] forKey:@"IM_Qty"];
            [data setObject:[rs stringForColumn:@"DiscountInPercent"] forKey:@"IM_DiscountInPercent"];
            
            [data setObject:[NSString stringWithFormat:@"%ld",(long)gstRate] forKey:@"IM_Gst"];
            
            [data setObject:itemTotalTax forKey:@"IM_TotalTax"]; //sum tax amt
            [data setObject:[rs stringForColumn:@"DiscType"] forKey:@"IM_DiscountType"];
            [data setObject:[rs stringForColumn:@"DiscValue"] forKey:@"IM_Discount"]; // discount given
            [data setObject:[rs stringForColumn:@"TotalDisc"] forKey:@"IM_DiscountAmt"];  // sum discount
            [data setObject:itemSubTotal forKey:@"IM_SubTotal"];
            [data setObject:itemTotal forKey:@"IM_Total"];
            
            //------------tax code-----------------
            [data setObject:[rs stringForColumn:@"T_Name"] forKey:@"IM_GSTCode"];
            
            //-------------service tax-------------
            [data setObject:[rs stringForColumn:@"Svc_Name"] forKey:@"IM_ServiceTaxCode"];  //svc tax code
            [data setObject:itemServiceTax forKey:@"IM_ServiceTaxAmt"]; // service tax amount
            [data setObject:[NSString stringWithFormat:@"%ld",(long)serviceTaxRate] forKey:@"IM_ServiceTaxRate"];
            [data setObject:itemServiceTaxGst forKey:@"IM_ServiceTaxGstAmt"];
            [data setObject:itemServiceTaxGstLong forKey:@"IM_ServiceTaxGstAmtLong"];
            //[data setObject:textServiceTaxGst forKey:@"IM_ServiceTaxGstAmt"];
            
            //------------------------------------------------------------------------------------------
            [data setObject:[NSString stringWithFormat:@"%0.2f", itemTotalSellingAmt] forKey:@"IM_totalItemSellingAmt"];  // subtotal not include tax n will replace this
            [data setObject:[NSString stringWithFormat:@"%0.6f", itemTotalSellingAmt] forKey:@"IM_totalItemSellingAmtLong"];  // subtotal not include tax
            [data setObject:[NSString stringWithFormat:@"%0.6f", itemTotalTaxAmt] forKey:@"IM_totalItemTaxAmtLong"];  // total tax amt
            
            [data setObject:[NSString stringWithFormat:@"%0.3f", [itemServiceTax doubleValue]] forKey:@"IM_totalServiceTaxAmt"];  // total service tax amt
            
            [data setObject:[rs stringForColumn:@"Remark"] forKey:@"IM_Remark"];
            [data setObject:tableName forKey:@"IM_TableName"];
            //---------for print kitchen receipt----------------
            
            [data setObject:kitchenStatus forKey:@"IM_Print"];
            [data setObject:[rs stringForColumn:@"IM_OrgQty"] forKey:@"IM_OrgQty"];
            [data setObject:[rs stringForColumn:@"IM_IpAddress"] forKey:@"IM_IpAddress"];
            [data setObject:[rs stringForColumn:@"IM_PrinterName"] forKey:@"IM_PrinterName"];
            //---------for item dine in or take away ------------
            [data setObject:itemDineStatus forKey:@"IM_TakeAwayYN"];
            
            //--------- for table pax no ---------------------
            [data setObject:paxNo forKey:@"SOH_PaxNo"];
            [data setObject:docType forKey:@"PayDocType"];
            [data setObject:@"ItemOrder" forKey:@"OrderType"];
            [data setObject:[NSString stringWithFormat:@"%0.2f",[rs doubleForColumn:@"IM_NewTotalCondimentSurCharge"]] forKey:@"IM_TotalCondimentSurCharge"];
            [data setObject:@"0.00" forKey:@"IM_NewTotalCondimentSurCharge"];
            
            //---------------modifier part----------------------
            [data setObject:[rs stringForColumn:@"IM_ServiceType"] forKey:@"IM_ServiceType"];
            //[data setObject:[rs stringForColumn:@"SOD_ModifierHdrCode"] forKey:@"PD_Modi//fierGroupCode"];
            
            
            //[data setObject:@"-" forKey:@"Index"];
            //---------for main to decide this array-------------
            if ([terminalType isEqualToString:@"Terminal"]) {
                [data setObject:@"Order" forKey:@"IM_Flag"];
                [data setObject:@"0.00" forKey:@"IM_labelTotal"];
                [data setObject:@"0.00" forKey:@"IM_labelTotalDiscount"];
                [data setObject:@"0.00" forKey:@"IM_labelRound"];
                [data setObject:@"0.00" forKey:@"IM_labelSubTotal"];
                [data setObject:@"0.00" forKey:@"IM_labelTaxTotal"];
                [data setObject:@"0.00" forKey:@"IM_labelServiceTaxTotal"];
                [data setObject:@"0.00" forKey:@"IM_serviceTaxGstTotal"];
                [data setObject:tableName forKey:@"IM_Table"];
                
                [data setObject:@"" forKey:@"CName"];
                [data setObject:@"" forKey:@"CAdd1"];
                [data setObject:@"" forKey:@"CAdd2"];
                [data setObject:@"" forKey:@"CAdd3"];
                [data setObject:@"" forKey:@"CTelNo"];
                [data setObject:@"" forKey:@"CGstNo"];
                
            }
            
            [salesArray addObject:data];
            
        }
        
        [rs close];

    }];

        
    //[self passSalesDataBack:salesArray dataStatus:@"New" tablePosition:0];
    //NSLog(@"%@",salesArray);
    
    [queue close];
    return salesArray;
}

+(NSDictionary *)calclateSalesTotalWith:(NSMutableArray *)orderFinalArray TaxType:(NSString *)taxType ServiceTaxGst:(double)serviceTaxGst DBPath:(NSString *)dbPath
{
    NSString *labelSubTotal = @"0.00";
    NSString *labelTaxTotal = @"0.00";
    NSString *labelTotal = @"0.00";
    NSString *labelTotalDiscount = @"0.00";
    NSString *labelServiceTaxTotal = @"0.00";
    NSString *labelTotalQty = @"0";
    NSString *serviceTaxGstTotal = @"0.00";
    NSString *labelRound = @"0.00";
    NSString *labelTotalItemTax = @"0.00";
    NSString *labelTotalServiceTax = @"0.00";
    NSString *labelExSubtotal = @"0.00";
    
    //double sellingAmtLong = 0.00;
    NSString *labelServiceTaxShortTotal = @"0.00";
    NSString *compareAdjTaxShortTotal = @"0.00";
    NSString *compareAdjTaxLongTotal = @"0.00";
    NSString *compareAdjTaxLongTotal2 = @"0.00";
    NSString *roundingServiceTaxGst = @"0.00";
    NSString *finalTaxAmt = @"0.00";
    NSString *finalServiceCharge = @"0.00";
    
    //double adjTax = 0.00;
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    
    for (int i = 0; i < orderFinalArray.count; i++) {
        
        // current
        labelExSubtotal = [NSString stringWithFormat:@"%.02f",[labelExSubtotal doubleValue] + [[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_totalItemSellingAmt"]doubleValue]];
        
        labelTotalQty = [NSString stringWithFormat:@"%0.2f",[labelTotalQty doubleValue] + [[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Qty"] doubleValue]];
        
        labelSubTotal = [NSString stringWithFormat:@"%.02f",[labelSubTotal doubleValue] + [[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_SubTotal"]doubleValue]];
        
        labelServiceTaxTotal = [NSString stringWithFormat:@"%.06f",[labelServiceTaxTotal doubleValue] + [[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_ServiceTaxAmt"]doubleValue]];
        
        labelServiceTaxShortTotal = [NSString stringWithFormat:@"%.02f",[labelServiceTaxShortTotal doubleValue] + [[NSString stringWithFormat:@"%0.2f",[[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_ServiceTaxAmt"]doubleValue]] doubleValue]];
        
        labelTaxTotal = [NSString stringWithFormat:@"%.06f",[labelTaxTotal doubleValue] + [[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_totalItemTaxAmtLong"]doubleValue]];
        
        labelTotalDiscount = [NSString stringWithFormat:@"%.02f",[labelTotalDiscount doubleValue] + [[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_DiscountAmt"]doubleValue]];
        
        if ([taxType isEqualToString:@"IEx"])
        {
            labelTotal = [NSString stringWithFormat:@"%.02f",[labelSubTotal doubleValue] + 0 - [labelTotalDiscount doubleValue] + round([labelServiceTaxTotal doubleValue]*100)/100];
        }
        else
        {
            
            labelTotal = [NSString stringWithFormat:@"%.02f",[labelSubTotal doubleValue] - [labelTotalDiscount doubleValue] + [labelServiceTaxTotal doubleValue]];
        }
        
        //labelTotalItemTax = labelTaxTotal;
        
        //current
        labelTotalItemTax = [NSString stringWithFormat:@"%.06f",[labelTotalItemTax doubleValue] + [[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_TotalTax"] doubleValue]];
        
        //------ for include tax
        compareAdjTaxShortTotal = [NSString stringWithFormat:@"%0.2f",[compareAdjTaxShortTotal doubleValue] + [[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_ServiceTaxGstAmt"] doubleValue] + [[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_TotalTax"] doubleValue]];
        
        compareAdjTaxLongTotal = [NSString stringWithFormat:@"%0.6f",[compareAdjTaxLongTotal doubleValue] + [[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_ServiceTaxGstAmtLong"] doubleValue] + [[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_totalItemTaxAmtLong"] doubleValue]];
        
        roundingServiceTaxGst = [NSString stringWithFormat:@"%0.2f",[roundingServiceTaxGst doubleValue] + [[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_ServiceTaxGstAmt"] doubleValue]];
        //---------
        
    }
    
    compareAdjTaxLongTotal = [NSString stringWithFormat:@"%0.2f",[compareAdjTaxLongTotal doubleValue]];
    
    labelTotalServiceTax = labelServiceTaxTotal;
    NSString *serviceTaxGstTotal2 = @"0.00";
    
    //current
    labelServiceTaxTotal = [NSString stringWithFormat:@"%.2f",round([labelServiceTaxTotal doubleValue] * 100) / 100];
    
    serviceTaxGstTotal = [NSString stringWithFormat:@"%.06f",[labelServiceTaxTotal doubleValue] * (serviceTaxGst / 100.0)];
    
    serviceTaxGstTotal2 = [NSString stringWithFormat:@"%.06f",[labelTotalServiceTax doubleValue] * (serviceTaxGst / 100.0)];
    ////
    
    //double uuu = 0.00;
    NSString *totalOfAdjTaxShort;
    //uuu = [[NSString stringWithFormat:@"%0.2f",[labelTaxTotal doubleValue]] doubleValue] + [serviceTaxGstTotal doubleValue];
    //duuu = [NSString stringWithFormat:@"%0.2f",uuu];
    totalOfAdjTaxShort = compareAdjTaxShortTotal;
    
    
    
    //double ccc = 0.00;
    
    //NSString *serviceTaxGstTotal2 = [NSString stringWithFormat:@"%.02f",[labelServiceTaxTotal doubleValue] * (serviceTaxGst / 100.0)];
    NSString *totalOfAdjTaxLong;
    //ccc = [labelTotalItemTax doubleValue] + [serviceTaxGstTotal2 doubleValue];
    //dccc = [NSString stringWithFormat:@"%0.2f",ccc];
    totalOfAdjTaxLong = compareAdjTaxLongTotal;
    double adjTax = 0.00;
    ////
    
    adjTax = [self doAdjustmentForTaxIncWithAdjTaxShort:totalOfAdjTaxShort AdjTaxLong:totalOfAdjTaxLong TaxType:taxType ServiceTaxGstAmt:([serviceTaxGstTotal doubleValue]*100)/100];
    
    if (![taxType isEqualToString:@"IEx"]) {
        finalTaxAmt = [NSString stringWithFormat:@"%0.2f",[labelTotalItemTax doubleValue] + [roundingServiceTaxGst doubleValue] + adjTax];
        
        roundingServiceTaxGst = [NSString stringWithFormat:@"%0.2f",[roundingServiceTaxGst doubleValue] + adjTax];
        
        finalServiceCharge = [NSString stringWithFormat:@"%0.2f",[labelServiceTaxShortTotal doubleValue] - adjTax];
    }
    else
    {
        finalTaxAmt = [NSString stringWithFormat:@"%.6f",[labelTaxTotal doubleValue] + [serviceTaxGstTotal doubleValue]];
        
        finalTaxAmt = [NSString stringWithFormat:@"%.2f",round([finalTaxAmt doubleValue]*100)/100];
        
        finalServiceCharge = [NSString stringWithFormat:@"%.2f",round([labelServiceTaxTotal doubleValue] * 100) / 100];
    }
    
    //current
    
    
    if ([taxType isEqualToString:@"IEx"]) {
        
        labelTotal = [NSString stringWithFormat:@"%.02f",[labelTotal doubleValue] + round([finalTaxAmt doubleValue] * 100) / 100];
        
    }
    else
    {
        // azlim here
        //testing
        labelTotal = [NSString stringWithFormat:@"%.02f",[labelExSubtotal doubleValue] + [finalServiceCharge doubleValue] + [[NSString stringWithFormat:@"%0.2f",[finalTaxAmt doubleValue]] doubleValue]];
        
        //current
        //labelTotal = [NSString stringWithFormat:@"%.02f",[labelTotal doubleValue] + [[NSString stringWithFormat:@"%0.2f",[serviceTaxGstTotal doubleValue]] doubleValue]];
    }
    
    // rounding
    NSString *strDollar;
    NSString *strCent;
    NSString *lastDigit;
    NSString *secondLastDigit;
    NSString *finalCent;
    
    NSString *final;
    //NSString *sqlCommand;
    lastDigit = [labelTotal substringFromIndex:[labelTotal length] - 1];
    strCent = [NSString stringWithFormat:@"0.%@",[labelTotal substringFromIndex:[labelTotal length] - 2]];
    secondLastDigit = [labelTotal substringWithRange:NSMakeRange([labelTotal length] - 2, 1)];
    finalCent = [[LibraryAPI sharedInstance]getCalcRounding:labelTotal DatabasePath:dbPath];
    strDollar = [labelTotal substringWithRange:NSMakeRange(0, [labelTotal length] - 3)];
    
    if ([strDollar doubleValue] < 0) {
        //for negative value
        final = [NSString stringWithFormat:@"%0.2f",[strDollar doubleValue] - [finalCent doubleValue]];
    }
    else
    {
        final = [NSString stringWithFormat:@"%0.2f",[strDollar doubleValue] + [finalCent doubleValue]];
    }
    
    
    labelRound = [NSString stringWithFormat:@"%0.2f",[finalCent doubleValue] - [strCent doubleValue]];
    labelTotal = final;
    
    strDollar = nil;;
    strCent = nil;
    lastDigit = nil;
    secondLastDigit = nil;
    finalCent = nil;
    final = nil;

    [data setObject:labelTotalQty forKey:@"TotalQty"];
    [data setObject:labelSubTotal forKey:@"SubTotal"];
    [data setObject:labelTotalDiscount forKey:@"TotalDiscount"];
    [data setObject:finalServiceCharge forKey:@"ServiceCharge"];
    [data setObject:finalTaxAmt forKey:@"TotalGst"];
    [data setObject:labelRound forKey:@"Rounding"];
    [data setObject:labelTotal forKey:@"Total"];
    [data setObject:labelTotalItemTax forKey:@"TotalItemTax"];
    if ([taxType isEqualToString:@"IEx"])
    {
        [data setObject:serviceTaxGstTotal forKey:@"TotalServiceChargeGst"];
    }
    else
    {
        [data setObject:roundingServiceTaxGst forKey:@"TotalServiceChargeGst"];
    }
    
    [data setObject:labelExSubtotal forKey:@"SubTotalEx"];
    
    [data setObject:totalOfAdjTaxShort forKey:@"duuu"];
    [data setObject:totalOfAdjTaxLong forKey:@"dccc"];
    
    return data;
}

+(double)doAdjustmentForTaxIncWithAdjTaxShort:(NSString *)adjTaxShort AdjTaxLong:(NSString *)adjTaxLong TaxType:(NSString *)taxType ServiceTaxGstAmt:(double)svcGstAmt
{
    if (![taxType isEqualToString:@"IEx"]) {
        double adjTax = 0.00;
        //NSLog(@"%@   %@",duuu, dccc);
        adjTax = [[NSString stringWithFormat:@"%0.2f",[adjTaxLong doubleValue] - [adjTaxShort doubleValue]] doubleValue];
        if (adjTax != 0.00) {
            
            if ([[LibraryAPI sharedInstance] getEnableSVG] == 1 && svcGstAmt > 0.00) {
                
                return adjTax;
            }
            else
            {
                return 0.00;
            }
            
            
        }
        else
        {
            return 0.00;
        }
    }
    else
    {
        return 0.00;
    }

}

+(NSMutableArray *)getAllItemPrinterIpAddWithDBPath:(NSString *)dbPath
{
    NSMutableArray *printerIpArray = [[NSMutableArray alloc] init];
    [printerIpArray removeAllObjects];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback){
        
        FMResultSet *rsPrinterIP = [db executeQuery:@"Select PQ_PrinterIP, PQ_PrinterBrand, 'Disconnected' as 'PQ_Status' from PrintQueue group by PQ_PrinterIP,PQ_PrinterBrand"];
        
        while ([rsPrinterIP next]) {
            [printerIpArray addObject:[rsPrinterIP resultDictionary]];
        }
        [rsPrinterIP close];
    }];
    
    [queue close];
    
    return printerIpArray;
    
}

+(NSMutableArray *)getItemPrinterIpAddWithDBPath:(NSString *)dbPath IPAddress:(NSString *)ipAddress
{
    NSMutableArray *printerIpArray = [[NSMutableArray alloc] init];
    [printerIpArray removeAllObjects];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback){
        
        FMResultSet *rsPrinterIP = [db executeQuery:@"Select PQ_PrinterIP, PQ_PrinterBrand, 'Disconnected' as 'PQ_Status' from PrintQueue where PQ_PrinterIP = ? group by PQ_PrinterIP,PQ_PrinterBrand", ipAddress];
        
        while ([rsPrinterIP next]) {
            [printerIpArray addObject:[rsPrinterIP resultDictionary]];
        }
        [rsPrinterIP close];
    }];
    return printerIpArray;
    
}

+(NSString *)generateCSOrderDataArray
{
    return @"Select IvD_ItemCode as IM_ItemCode, IvD_ItemDescription as IM_Description,"
    "IvD_Price as IM_Price2,IvD_Quantity as IM_Qty,IvD_DiscValue as IM_Discount,IvD_SellingPrice as IM_SellingPrice,"
    "IvD_UnitPrice as IM_Price, IvD_Remark as IM_Remark, IvD_TakeAway_YN as IM_TakeAway_YN,"
    "IvD_DiscType as IM_DiscountType, IvD_SellTax as IM_Tax, IvD_TotalSalesTax as IM_TotalTax,"
    "IvD_TotalSalesTaxLong as IM_totalItemTaxAmtLong, IvD_TotalEx as IM_totalItemSellingAmt,"
    "IvD_TotalExLong as IM_totalItemSellingAmtLong, IvD_TotalInc as IM_Total, IvD_TotalDisc as IM_DiscountAmt,IvD_SubTotal as IM_SubTotal,IvD_DiscInPercent as IM_DiscountInPercent,IvH_DocNo as SOH_DocNo,IvD_DocNo as SOD_DocNo,IvH_Status as SOH_Status, IvH_DocAmt as SOH_DocAmt, IvH_DocSubTotal as SOH_DocSubTotal, IvH_DiscAmt as SOH_DiscAmt, IvH_DocTaxAmt as SOH_DocTaxAmt, IvH_DocServiceTaxAmt as SOH_DocServiceTaxAmt, IvH_DocServiceTaxGstAmt as SOH_DocServiceTaxGstAmt,IFNULL(T_Percent,'0') as T_Percent,IvH_Rounding as SOH_Rounding, IvH_DocServiceTaxAmt as SOH_DocServiceTaxAmt, TP_Name as IM_TableName, IFNULL(T_Name,'-') as IM_TaxCode,"
    " IFNULL(IvD_ServiceTaxCode,'-') as IM_ServiceTaxCode, IvD_ServiceTaxAmt as IM_ServiceTaxAmt, IvD_ServiceTaxRate as IM_ServiceTaxRate , IvD_TakeAwayYN as IM_TakeAwayYN, IM.IM_ItemNo"
    " ,IFNULL(P.P_PortName,'0.0.0.0') as IM_IpAddress, IFNULL(P.P_PrinterName,'NonPrinter') as IM_PrinterName, IvH_PaxNo as SOH_PaxNo, IvH_SoNo as DocNo,IFNULL(IvD_TotalCondimentSurCharge,'0.00') as IM_TotalCondimentSurCharge,IvD_ManualID as SOD_ManualID"
    ", IvH_CustName as SOH_CustName,IvH_CustAdd1 as SOH_CustAdd1,IvH_CustAdd2 as SOH_CustAdd2,IvH_CustAdd3 as SOH_CustAdd3,IvH_CustTelNo as SOH_CustTelNo,IvH_CustGstNo as SOH_CustGstNo, IM_ServiceType, IvD_ModifierID as SOD_ModifierID, IvD_ModifierHdrCode as SOD_ModifierHdrCode"
    
    " from InvoiceHdr s1"
    " left join InvoiceDtl s2"
    " on s1.IvH_DocNo = s2.IvD_DocNo"
    " left join ItemMast IM on s2.IvD_ItemCode = IM.IM_ItemCode"
    " left join Tax T1 on s2.IvD_ItemTaxCode = T1.T_Name"
    " left join TablePlan TP on s1.IvH_Table = TP.TP_Name"
    //" left join ItemPrinter IP on IP.IP_ItemNo = IM.IM_ItemCode"
     " left join (select IP_ItemNo, IP_PrinterName from ItemPrinter group by IP_ItemNo) as IP on  IP.IP_ItemNo = IM.IM_ItemCode"
    " left join Printer P on IP.IP_PrinterName = P.P_PrinterName"
    " where s1.IvH_DocNo = ? order by IvD_AutoNo";
}

+(NSString *)generateSalesOrderDataArray
{
    return @"Select SOD_ItemCode as IM_ItemCode, SOD_ItemDescription as IM_Description,"
    "SOD_Price as IM_Price2,SOD_Quantity as IM_Qty,SOD_DiscValue as IM_Discount,SOD_SellingPrice as IM_SellingPrice,"
    "SOD_UnitPrice as IM_Price, SOD_Remark as IM_Remark, SOD_TakeAway_YN as IM_TakeAway_YN,"
    "SOD_DiscType as IM_DiscountType, SOD_SellTax as IM_Tax, SOD_TotalSalesTax as IM_TotalTax,"
    "SOD_TotalSalesTaxLong as IM_totalItemTaxAmtLong, SOD_TotalEx as IM_totalItemSellingAmt,"
    "SOD_TotalExLong as IM_totalItemSellingAmtLong, SOD_TotalInc as IM_Total, SOD_TotalDisc as IM_DiscountAmt,SOD_SubTotal as IM_SubTotal,SOD_DiscInPercent as IM_DiscountInPercent,SOH_DocNo,SOD_DocNo,SOH_Status, SOH_DocAmt, SOH_DocSubTotal, SOH_DiscAmt, SOH_DocTaxAmt, SOH_DocServiceTaxAmt, SOH_DocServiceTaxGstAmt,IFNULL(T_Percent,'0') as T_Percent,SOH_Rounding, SOH_DocServiceTaxAmt, TP_Name as IM_TableName, IFNULL(T_Name,'-') as IM_TaxCode,"
    " IFNULL(SOD_ServiceTaxCode,'-') as IM_ServiceTaxCode, SOD_ServiceTaxAmt as IM_ServiceTaxAmt, SOD_ServiceTaxRate as IM_ServiceTaxRate , SOD_TakeAwayYN as IM_TakeAwayYN, IM.IM_ItemNo, IM_ServiceType"
    " ,IFNULL(P.P_PortName,'0.0.0.0') as IM_IpAddress, IFNULL(P.P_PrinterName,'NonPrinter') as IM_PrinterName, SOH_PaxNo, SOH_DocNo as DocNo, IFNULL(SOD_TotalCondimentSurCharge,'0.00') as IM_TotalCondimentSurCharge, SOD_ManualID, IFNULL(SOH_CustName,'') as SOH_CustName,IFNULL(SOH_CustAdd1,'') as SOH_CustAdd1,IFNULL(SOH_CustAdd2,'') as SOH_CustAdd2,IFNULL(SOH_CustAdd3,'') as SOH_CustAdd3,IFNULL(SOH_CustTelNo,'') as SOH_CustTelNo,IFNULL(SOH_CustGstNo,'') as SOH_CustGstNo,"
    " SOD_ModifierID, SOD_ModifierHdrCode, IM_ServiceType"
    " , IFNULL(MH_Description,'') as MH_Description"
    
    " from SalesOrderHdr s1"
    " left join SalesOrderDtl s2"
    " on s1.SOH_DocNo = s2.SOD_DocNo"
    " left join ItemMast IM on s2.SOD_ItemCode = IM.IM_ItemCode"
    " left join Tax T1 on s2.SOD_TaxCode = T1.T_Name"
    " left join TablePlan TP on s1.SOH_Table = TP.TP_Name"
    //" left join ItemPrinter IP on IP.IP_ItemNo = IM.IM_ItemCode"
    " left join ModifierHdr MH on s2.SOD_ModifierHdrCode = MH.MH_Code"
    " left join (select IP_ItemNo, IP_PrinterName from ItemPrinter group by IP_ItemNo) as IP on  IP.IP_ItemNo = IM.IM_ItemCode"
    " left join Printer P on IP.IP_PrinterName = P.P_PrinterName";
}


+(NSMutableArray *)getSalesOrderCondimentWithDBPath:(NSString *)dbPath SalesOrderNo:(NSString *)docNo ItemCode:(NSString *)itemCode ManualID:(NSString *)manualID ParentIndex:(NSUInteger)parentIndex
{
    __block NSMutableArray *condimentArray = [[NSMutableArray alloc] init];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rsCondiment = [db executeQuery:@"Select SOC.*, SOD.SOD_ModifierHdrCode"
                                    " from SalesOrderCondiment SOC"
                                    " left join SalesOrderDtl SOD on SOC.SOC_CDManualKey = SOD.SOD_ManualID"
                                    " where SOC.SOC_DocNo = ? and SOC.SOC_ItemCode = ? and SOC.SOC_CDManualKey = ? order by SOC.SOC_ID",docNo,itemCode,manualID];
        
        while ([rsCondiment next]) {
            NSMutableDictionary *data = [NSMutableDictionary dictionary];
            [data setObject:[rsCondiment stringForColumn:@"SOC_ItemCode"] forKey:@"ItemCode"];
            [data setObject:[rsCondiment stringForColumn:@"SOC_CHCode"] forKey:@"CHCode"];
            [data setObject:[rsCondiment stringForColumn:@"SOC_CDCode"] forKey:@"CDCode"];
            [data setObject:[rsCondiment stringForColumn:@"SOC_CDDescription"] forKey:@"CDDescription"];
            [data setObject:[NSString stringWithFormat:@"%0.2f",[[rsCondiment stringForColumn:@"SOC_CDQty"] doubleValue]]  forKey:@"UnitQty"];
            [data setObject:[rsCondiment stringForColumn:@"SOC_CDPrice"] forKey:@"CDPrice"];
            [data setObject:@"0.00" forKey:@"IM_DiscountAmt"];
            [data setObject:@"CondimentOrder" forKey:@"OrderType"];
            [data setObject:[NSString stringWithFormat:@"%ld",(unsigned long)parentIndex] forKey:@"ParentIndex"];
            
            if ([[rsCondiment stringForColumn:@"SOD_ModifierHdrCode"] length] > 0) {
                [data setObject:@"Yes" forKey:@"UnderPackageItemYN"];
            }
            else{
                [data setObject:@"No" forKey:@"UnderPackageItemYN"];
            }
            [condimentArray addObject:data];
            data = nil;
        }
        
    }];
    
    return condimentArray;
}

+(NSMutableArray *)getInvoiceCondimentWithDBPath:(NSString *)dbPath InvoiceNo:(NSString *)docNo ItemCode:(NSString *)itemCode ManualID:(NSString *)manualID ParentIndex:(NSUInteger)parentIndex
{
    __block NSMutableArray *condimentArray = [[NSMutableArray alloc] init];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rsCondiment = [db executeQuery:@"Select * from InvoiceCondiment where IVC_DocNo = ? and IVC_ItemCode = ? and IVC_CDManualKey = ? order by IVC_ID",docNo,itemCode,manualID];
        
        while ([rsCondiment next]) {
            NSMutableDictionary *data = [NSMutableDictionary dictionary];
            [data setObject:[rsCondiment stringForColumn:@"IVC_ItemCode"] forKey:@"ItemCode"];
            [data setObject:[rsCondiment stringForColumn:@"IVC_CHCode"] forKey:@"CHCode"];
            [data setObject:[rsCondiment stringForColumn:@"IVC_CDCode"] forKey:@"CDCode"];
            [data setObject:[rsCondiment stringForColumn:@"IVC_CDDescription"] forKey:@"CDDescription"];
            [data setObject:[rsCondiment stringForColumn:@"IVC_CDQty"]  forKey:@"UnitQty"];
            [data setObject:[rsCondiment stringForColumn:@"IVC_CDPrice"] forKey:@"CDPrice"];
            [data setObject:@"0.00" forKey:@"IM_DiscountAmt"];
            [data setObject:@"CondimentOrder" forKey:@"OrderType"];
            [data setObject:[NSString stringWithFormat:@"%ld",(unsigned long)parentIndex] forKey:@"ParentIndex"];
            [condimentArray addObject:data];
            data = nil;
        }
        
    }];
    
    return condimentArray;
}


+(NSMutableArray *)getAsterixSalesOrderDetailWithDBPath:(NSString *)dbPath SalesOrderNo:(NSString *)docNo
{
    NSMutableArray *data = [[NSMutableArray alloc] init];
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rsCompany = [db executeQuery:@"Select *, 'TerminalRequestSODtlResult' as IM_Flag from Company"];
        while ([rsCompany next]) {
            [data addObject:[rsCompany resultDictionary]];
        }
        [rsCompany close];
        //int i =0;
        FMResultSet *rs = [db executeQuery:@"Select *, IFNULL(SOD_TaxCode,'') || ': ' || SOD_ItemDescription as ItemDesc ,SOD_ItemDescription as ItemDesc2, 'ItemOrder' as OrderType, 'TerminalRequestSODtlResult' as IM_Flag from SalesOrderHdr Hdr "
                           " left join SalesOrderDtl Dtl on Hdr.SOH_DocNo = Dtl.SOD_DocNo"
                           " left join ItemMast IM on IM.IM_ItemCode = Dtl.SOD_ItemCode"
                           " where Hdr.SOH_DocNo = ?",docNo];
        
        while ([rs next]) {
            
            [data addObject:[rs resultDictionary]];
            
            FMResultSet *rsCdt = [db executeQuery:@"Select *,'CondimentOrder' as OrderType from SalesOrderCondiment where SOC_CDManualKey = ?",[rs stringForColumn:@"SOD_ManualID"]];
            
            while ([rsCdt next]) {
                [data addObject:[rsCdt resultDictionary]];
            }
            [rsCdt close];
        }
        
        [rs close];
        
    }];
    
    [queue close];
    
    return data;
}

+(NSMutableArray *)getAsterixCashSalesDetailWithDBPath:(NSString *)dbPath CashSalesNo:(NSString *)docNo ViewName:(NSString *)viewName
{
    
    NSMutableArray *data = [[NSMutableArray alloc] init];
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rsCompany = [db executeQuery:@"Select *,'TerminalRequestCashSalesResult' as IM_Flag, ? as ViewName from Company",viewName];
        while ([rsCompany next]) {
            [data addObject:[rsCompany resultDictionary]];
            
        }
        [rsCompany close];
        
        FMResultSet *rs = [db executeQuery:@"Select *,IFNULL(IvD_ItemTaxCode,'') || ': ' || IvD_ItemDescription as ItemDesc,IvD_ItemDescription as ItemDesc2, IFNULL(IvD_ItemTaxCode,'-') as Flag, 'ItemOrder' as OrderType,'TerminalRequestCashSalesResult' as IM_Flag, ? as ViewName from InvoiceHdr InvH "
                           " left join InvoiceDtl InvD on InvH.IvH_DocNo = InvD.IvD_DocNo"
                           " left join ItemMast IM on IM.IM_ItemCode = InvD.IvD_ItemCode"
                           " where InvH.IvH_DocNo = ?",viewName,docNo];
        
        while ([rs next]) {
            [data addObject:[rs resultDictionary]];
            
            FMResultSet *rsCdt = [db executeQuery:@"Select *,'CondimentOrder' as OrderType from InvoiceCondiment where IVC_CDManualKey = ?",[rs stringForColumn:@"IvD_ManualID"]];
            
            while ([rsCdt next]) {
                [data addObject:[rsCdt resultDictionary]];
            }
            [rsCdt close];
            
        }
        
        [rs close];
    }];
    
    return data;
}

+(NSMutableArray *)getTransferSalesOrderDetailWithDbPath:(NSString *)dbPath SalesOrderNo:(NSString *)salesOrderNo
{
    NSMutableArray *transferSODetail = [[NSMutableArray alloc] init];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    //[queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [queue inDatabase:^(FMDatabase *db) {
        int index = 0;
        FMResultSet *rs = [db executeQuery:@"Select SOD_DocNo,SOD_ItemCode, SOD_ItemDescription, SOD_Quantity, SOD_UnitPrice, SOD_DiscInPercent, SOD_DiscValue ,SOD_DiscType, SOD_TotalDisc, IFNULL(SOD_TaxCode,'-') as SOD_TaxCode, SOD_TaxRate, IFNULL(SOD_ServiceTaxCode,'-') as SOD_ServiceTaxCode, SOD_ServiceTaxRate, SOD_Remark,SOD_TakeAwayYN, IM_ItemNo, IFNULL(SOD_TotalCondimentSurCharge,'0.00') as IM_TotalCondimentSurCharge, SOD_ManualID, SOH_PaxNo, substr(SOD_ManualID,13) as 'CondimentKey'"
            " ,SOD_ModifierHdrCode, SOD_ModifierID"
            " from SalesOrderDtl"
            " left join SalesOrderHdr on SalesOrderDtl.SOD_DocNo = SalesOrderHdr.SOH_DocNo"
            " left join ItemMast on SalesOrderDtl.SOD_ItemCode = ItemMast.IM_ItemCode "
            " where SOD_DocNo = ?",salesOrderNo];
        
        while ([rs next]) {
            //[transferSODetail addObject:[rs resultDictionary]];
            index ++;
            //[partialSalesOrderArray addObject:[rs resultDictionary]];
            NSMutableDictionary *data = [NSMutableDictionary dictionary];
            
            [data setObject:[rs stringForColumn:@"SOD_ItemCode"] forKey:@"SOD_ItemCode"];
            [data setObject:[rs stringForColumn:@"SOD_ItemDescription"] forKey:@"SOD_ItemDescription"];
            [data setObject:[rs stringForColumn:@"SOD_Quantity"] forKey:@"SOD_Quantity"];
            [data setObject:[NSString stringWithFormat:@"%0.2f",[rs doubleForColumn:@"SOD_UnitPrice"]] forKey:@"SOD_UnitPrice"];
            //one item selling price not included tax
            [data setObject:[rs stringForColumn:@"SOD_DiscInPercent"] forKey:@"SOD_DiscInPercent"];
            [data setObject:[rs stringForColumn:@"SOD_DiscValue"] forKey:@"SOD_DiscValue"];
            [data setObject:[rs stringForColumn:@"SOD_DiscType"] forKey:@"SOD_DiscType"];
            
            [data setObject:[rs stringForColumn:@"SOD_TotalDisc"] forKey:@"SOD_TotalDisc"];
            [data setObject:[rs stringForColumn:@"SOD_TaxCode"] forKey:@"SOD_TaxCode"];
            [data setObject:[rs stringForColumn:@"SOD_TaxRate"] forKey:@"SOD_TaxRate"];
            [data setObject:[rs stringForColumn:@"SOD_ServiceTaxCode"] forKey:@"SOD_ServiceTaxCode"];
            [data setObject:[rs stringForColumn:@"SOD_ServiceTaxRate"] forKey:@"SOD_ServiceTaxRate"];
            [data setObject:[rs stringForColumn:@"SOD_Remark"] forKey:@"SOD_Remark"];
            
            [data setObject:[rs stringForColumn:@"SOD_TakeAwayYN"] forKey:@"SOD_TakeAwayYN"];
            [data setObject:[rs stringForColumn:@"IM_ItemNo"] forKey:@"IM_ItemNo"];
            [data setObject:[rs stringForColumn:@"IM_TotalCondimentSurCharge"] forKey:@"IM_TotalCondimentSurCharge"];
            [data setObject:[rs stringForColumn:@"SOD_ManualID"] forKey:@"OldSOD_ManualID"];
            [data setObject:[rs stringForColumn:@"SOH_PaxNo"] forKey:@"SOH_PaxNo"];
            [data setObject:[rs stringForColumn:@"CondimentKey"] forKey:@"CondimentKey"];
            [data setObject:[rs stringForColumn:@"SOD_ManualID"] forKey:@"SOD_ManualID"];
            [data setObject:[NSString stringWithFormat:@"%d",index] forKey:@"Index"];
            if ([[rs stringForColumn:@"SOD_ModifierHdrCode"] length] > 0) {
                [data setObject:@"PackageItemOrder" forKey:@"OrderType"];
            }
            else
            {
                [data setObject:@"ItemOrder" forKey:@"OrderType"];
            }
            
            [data setObject:[rs stringForColumn:@"SOD_DocNo"] forKey:@"OldSOD_DocNo"];
            [data setObject:[rs stringForColumn:@"SOD_ModifierID"] forKey:@"SOD_ModifierID"];
            
            [data setObject:[rs stringForColumn:@"SOD_ModifierHdrCode"] forKey:@"PD_ModifierHdrCode"];
            
            [transferSODetail addObject:data];
            data = nil;
        }
        
        [rs close];
        
    }];
    
    [queue close];
    
    return transferSODetail;
}

+(NSMutableArray *)getAllTableListWithDbPath:(NSString *)dbPath FromTableName:(NSString *)fromTableName
{
    NSMutableArray *resultArray;
    resultArray = [[NSMutableArray alloc]init];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rsTable = [db executeQuery:@"Select TP_Name, TP_Section, TP_ID, TP_DineType, '' as TP_SONo,"
                                " ifnull(SO_Count,'') as TP_Count, ifnull(SOH_DocAmt,'') as TP_Amt"
                                " from TablePlan"
                                " left join "
                                " (select SOH_Table, Count(*) as SO_Count, SOH_DocAmt from SalesOrderHdr where SOH_Status = 'New' group by SOH_Table) as TB1"
                                " on TablePlan.TP_Name = TB1.SOH_Table where TablePlan.TP_Name != ?  order by TP_Name",fromTableName];
        
        while ([rsTable next]) {
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            
            [dict setObject:@"AllTableResult" forKey:@"IM_Flag"];
            [dict setObject:@"True" forKey:@"Result"];
            
            [dict setObject:[rsTable stringForColumn:@"TP_Name"] forKey:@"TP_Name"];
            [dict setObject:[rsTable stringForColumn:@"TP_ID"] forKey:@"TP_ID"];
            [dict setObject:[rsTable stringForColumn:@"TP_DineType"] forKey:@"TP_DineType"];
            [dict setObject:[rsTable stringForColumn:@"TP_Section"] forKey:@"TP_Section"];
            
            [dict setObject:[rsTable stringForColumn:@"TP_SONo"] forKey:@"TP_SONo"];
            if ([[rsTable stringForColumn:@"TP_Count"] length] == 0 && [[rsTable stringForColumn:@"TP_Amt"] length] == 0)
            {
                [dict setObject:@"" forKey:@"TP_SODocAmt"];
            }
            else if ([rsTable intForColumn:@"TP_Count"] == 1 )
            {
                [dict setObject:[NSString stringWithFormat:@"%@ %0.2f",[[LibraryAPI sharedInstance] getCurrencySymbol],[rsTable doubleForColumn:@"TP_Amt"]] forKey:@"TP_SODocAmt"];
            }
            else if ([rsTable intForColumn:@"TP_Count"] > 1 )
            {
                [dict setObject:[NSString stringWithFormat:@"#%@",[rsTable stringForColumn:@"TP_Count"]] forKey:@"TP_SODocAmt"];
            }
            
            [resultArray addObject:dict];
            dict = nil;
            
        }
        
        [rsTable close];
        
    }];
    
    [queue close];
    
    return resultArray;
    
}

+(NSMutableArray *)getCombineTableListWithDbPath:(NSString *)dbPath FromTableName:(NSString *)fromTableName
{
    NSMutableArray *resultArray;
    resultArray = [[NSMutableArray alloc]init];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rsOccTable = [db executeQuery:@"Select TP_Name, TP_ID, TP_DineType, TP_Section from TablePlan where TP_Name In (Select SOH_Table from SalesOrderHdr where SOH_Status = ?) and TP_Name != ? order by TP_Name",@"New",fromTableName];
        
        while ([rsOccTable next]) {
            
            FMResultSet *rsSO = [db executeQuery:@"Select SOH_Table, SOH_DocAmt, SOH_DocNo from SalesOrderHdr where SOH_Table = ? and SOH_Status = ?",[rsOccTable stringForColumn:@"TP_Name"] ,@"New"];
            
            while([rsSO next]) {
                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                
                [dict setObject:@"AllTableResult" forKey:@"IM_Flag"];
                [dict setObject:@"True" forKey:@"Result"];
                
                [dict setObject:[rsOccTable stringForColumn:@"TP_Name"] forKey:@"TP_Name"];
                [dict setObject:[rsOccTable stringForColumn:@"TP_ID"] forKey:@"TP_ID"];
                [dict setObject:[rsOccTable stringForColumn:@"TP_DineType"] forKey:@"TP_DineType"];
                
                [dict setObject:[rsOccTable stringForColumn:@"TP_Section"] forKey:@"TP_Section"];
                [dict setObject:[rsSO stringForColumn:@"SOH_DocNo"] forKey:@"TP_SONo"];
                [dict setObject:[NSString stringWithFormat:@"%@ %0.2f",[[LibraryAPI sharedInstance] getCurrencySymbol],[rsSO doubleForColumn:@"SOH_DocAmt"]] forKey:@"TP_SODocAmt"];
                
                //[dict setObject:[NSString stringWithFormat:@"%@ %@",[[LibraryAPI sharedInstance] getCurrencySymbol],[rsSO stringForColumn:@"SOH_DocAmt"]] forKey:@"TP_SODocAmt"];
                
                [resultArray addObject:dict];
                dict = nil;
                //data= nil;
                
            }
            [rsSO close];
            
        }
        
        [rsOccTable close];
        
    }];
    
    [queue close];
    
    return resultArray;

}

+(NSMutableArray *)getParticularCombineTableListWithDbPath:(NSString *)dbPath TableName:(NSString *)TableName
{
    NSMutableArray *resultArray;
    resultArray = [[NSMutableArray alloc]init];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rsOccTable = [db executeQuery:@"Select TP_Name, TP_ID, TP_DineType, TP_Section from TablePlan where TP_Name In (Select SOH_Table from SalesOrderHdr where SOH_Status = ?) and TP_Name = ? order by TP_Name",@"New",TableName];
        
        while ([rsOccTable next]) {
            
            FMResultSet *rsSO = [db executeQuery:@"Select SOH_Table, SOH_DocAmt, SOH_DocNo from SalesOrderHdr where SOH_Table = ? and SOH_Status = ?",[rsOccTable stringForColumn:@"TP_Name"] ,@"New"];
            
            while([rsSO next]) {
                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                
                [dict setObject:@"AllTableResult" forKey:@"IM_Flag"];
                [dict setObject:@"True" forKey:@"Result"];
                
                [dict setObject:[rsOccTable stringForColumn:@"TP_Name"] forKey:@"TP_Name"];
                [dict setObject:[rsOccTable stringForColumn:@"TP_ID"] forKey:@"TP_ID"];
                [dict setObject:[rsOccTable stringForColumn:@"TP_DineType"] forKey:@"TP_DineType"];
                
                [dict setObject:[rsOccTable stringForColumn:@"TP_Section"] forKey:@"TP_Section"];
                [dict setObject:[rsSO stringForColumn:@"SOH_DocNo"] forKey:@"TP_SONo"];
                [dict setObject:[NSString stringWithFormat:@"%@ %0.2f",[[LibraryAPI sharedInstance] getCurrencySymbol],[rsSO doubleForColumn:@"SOH_DocAmt"]] forKey:@"TP_SODocAmt"];
                
                //[dict setObject:[NSString stringWithFormat:@"%@ %@",[[LibraryAPI sharedInstance] getCurrencySymbol],[rsSO stringForColumn:@"SOH_DocAmt"]] forKey:@"TP_SODocAmt"];
                
                [resultArray addObject:dict];
                dict = nil;
                //data= nil;
                
            }
            [rsSO close];
            
        }
        
        [rsOccTable close];
        
    }];
    
    [queue close];
    
    return resultArray;
    
}

+(NSMutableArray *)publicCombineTwoTableWithFromSalesOrder:(NSString *)fromSalesOrder ToSalesOrder:(NSString *)toSalesOrder DBPath:(NSString *)dbPath
{
    __block Boolean result;
    NSMutableArray *resultArray;
    resultArray = [[NSMutableArray alloc]init];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        result = true;
        NSUInteger index = 0;
        NSString *packageItemIndex = @"";
        FMResultSet *rs = [db executeQuery:@"Select SOD_DocNo, SOD_ItemCode, SOD_ItemDescription, SOD_Quantity, SOD_UnitPrice, SOD_DiscInPercent, SOD_DiscValue ,SOD_DiscType, SOD_TotalDisc, IFNULL(SOD_TaxCode,'-') as SOD_TaxCode, SOD_TaxRate, IFNULL(SOD_ServiceTaxCode,'-') as SOD_ServiceTaxCode, SOD_ServiceTaxRate, SOD_Remark,SOD_TakeAwayYN, IM_ItemNo, IFNULL(SOD_TotalCondimentSurCharge,'0.00') as IM_TotalCondimentSurCharge, SOD_ManualID, SOH_PaxNo, substr(SOD_ManualID,13) as 'CondimentKey'"
                           ", SOD_ModifierID, SOD_ModifierHdrCode, IM_ServiceType"
                           " from SalesOrderDtl"
                           " left join SalesOrderHdr on SalesOrderDtl.SOD_DocNo = SalesOrderHdr.SOH_DocNo"
                           " left join ItemMast on SalesOrderDtl.SOD_ItemCode = ItemMast.IM_ItemCode "
                           " where SOD_DocNo in (?,?)",toSalesOrder, fromSalesOrder];
        
        while ([rs next]) {
            index ++;
            //[partialSalesOrderArray addObject:[rs resultDictionary]];
            NSMutableDictionary *data = [NSMutableDictionary dictionary];
            
            [data setObject:@"CombineTableResult" forKey:@"IM_Flag"];
            
            [data setObject:[rs stringForColumn:@"SOD_ItemCode"] forKey:@"SOD_ItemCode"];
            [data setObject:[rs stringForColumn:@"SOD_ItemDescription"] forKey:@"SOD_ItemDescription"];
            [data setObject:[rs stringForColumn:@"SOD_Quantity"] forKey:@"SOD_Quantity"];
            [data setObject:[NSString stringWithFormat:@"%0.2f",[rs doubleForColumn:@"SOD_UnitPrice"]] forKey:@"SOD_UnitPrice"];
            //one item selling price not included tax
            [data setObject:[rs stringForColumn:@"SOD_DiscInPercent"] forKey:@"SOD_DiscInPercent"];
            [data setObject:[rs stringForColumn:@"SOD_DiscValue"] forKey:@"SOD_DiscValue"];
            [data setObject:[rs stringForColumn:@"SOD_DiscType"] forKey:@"SOD_DiscType"];
            
            [data setObject:[rs stringForColumn:@"SOD_TotalDisc"] forKey:@"SOD_TotalDisc"];
            [data setObject:[rs stringForColumn:@"SOD_TaxCode"] forKey:@"SOD_TaxCode"];
            [data setObject:[rs stringForColumn:@"SOD_TaxRate"] forKey:@"SOD_TaxRate"];
            [data setObject:[rs stringForColumn:@"SOD_ServiceTaxCode"] forKey:@"SOD_ServiceTaxCode"];
            [data setObject:[rs stringForColumn:@"SOD_ServiceTaxRate"] forKey:@"SOD_ServiceTaxRate"];
            [data setObject:[rs stringForColumn:@"SOD_Remark"] forKey:@"SOD_Remark"];
            
            [data setObject:[rs stringForColumn:@"SOD_TakeAwayYN"] forKey:@"SOD_TakeAwayYN"];
            [data setObject:[rs stringForColumn:@"IM_ItemNo"] forKey:@"IM_ItemNo"];
            [data setObject:[rs stringForColumn:@"IM_TotalCondimentSurCharge"] forKey:@"IM_TotalCondimentSurCharge"];
            [data setObject:[rs stringForColumn:@"SOD_ManualID"] forKey:@"OldSOD_ManualID"];
            [data setObject:[rs stringForColumn:@"SOH_PaxNo"] forKey:@"SOH_PaxNo"];
            [data setObject:[rs stringForColumn:@"CondimentKey"] forKey:@"CondimentKey"];
            [data setObject:[NSString stringWithFormat:@"%@-%lu",toSalesOrder,index] forKey:@"SOD_ManualID"];
            [data setObject:[NSString stringWithFormat:@"%lu",index] forKey:@"Index"];
            
            [data setObject:[rs stringForColumn:@"SOD_DocNo"] forKey:@"OldSOD_DocNo"];
            
            if ([[rs stringForColumn:@"IM_ServiceType"] isEqualToString:@"1"]) {
                packageItemIndex = [NSString stringWithFormat:@"%lu",index];
            }
            
            if ([[rs stringForColumn:@"SOD_ModifierHdrCode"] length] > 0) {
                [data setObject:@"PackageItemOrder" forKey:@"OrderType"];
                [data setObject:[NSString stringWithFormat:@"M%@-%@",toSalesOrder,packageItemIndex] forKey:@"SOD_ModifierID"];
            }
            else
            {
                [data setObject:@"ItemOrder" forKey:@"OrderType"];
                if ([[rs stringForColumn:@"IM_ServiceType"] isEqualToString:@"1"]) {
                    [data setObject:[NSString stringWithFormat:@"M%@-%@",toSalesOrder,packageItemIndex] forKey:@"SOD_ModifierID"];
                }
                else
                {
                    [data setObject:@"" forKey:@"SOD_ModifierID"];
                }
                
            }
            
            [data setObject:[rs stringForColumn:@"SOD_ModifierHdrCode"] forKey:@"PD_ModifierHdrCode"];
            
            [resultArray addObject:data];
            
        }
        [rs close];
        
    }];
    
    [queue close];
    
    return resultArray;
    
}

+(NSMutableArray *)recalculateSalesOrderResultWithFromSalesOrderNo:(NSString *)fromSalesOrderNo SelectedTbName:(NSString *)selectedTbName SelectedDineType:(int)dineType Date:(NSString *)todayDate ItemServeTypeFlag:(NSString *)itemServeTypeFlag OptionSelected:(NSString *)optionSelected ToSalesOrderNo:(NSString *)toSalesOrderNo DBPath:(NSString *)dbPath
{
    NSMutableDictionary *settingDict = [NSMutableDictionary dictionary];
    NSMutableArray *transferSalesArray = [[NSMutableArray alloc] init];
    NSMutableArray *recalcTransferSalesArray = [[NSMutableArray alloc] init];
    NSArray *recalcTransferArray;
    //NSDictionary *totalDict = [NSDictionary dictionary];
    
    NSMutableArray *salesOrderDetailArray = [[NSMutableArray alloc] init];
    
    if ([optionSelected isEqualToString:@"TransferTable"]) {
        salesOrderDetailArray = [PublicSqliteMethod getTransferSalesOrderDetailWithDbPath:dbPath SalesOrderNo:fromSalesOrderNo];
    }
    else
    {
        salesOrderDetailArray = [PublicSqliteMethod publicCombineTwoTableWithFromSalesOrder:fromSalesOrderNo ToSalesOrder:toSalesOrderNo DBPath:dbPath];
    }
    
    
    if (![itemServeTypeFlag isEqualToString:@"-"]) {
        for (int i = 0; i < salesOrderDetailArray.count; i++) {
            NSMutableDictionary *data = [NSMutableDictionary dictionary];
            data = [salesOrderDetailArray objectAtIndex:i];
            [data setValue:itemServeTypeFlag forKey:@"SOD_TakeAwayYN"];
            [salesOrderDetailArray replaceObjectAtIndex:i withObject:data];
            data = nil;
        }
    }
    
    
    for (int i = 0; i < salesOrderDetailArray.count; i++) {
        
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        
        [data setObject:[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"SOD_DiscInPercent"] forKey:@"DiscInPercent"];
        [data setObject:[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"SOD_Quantity"] forKey:@"ItemQty"];
        [data setObject:[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"SOD_DiscValue"] forKey:@"DiscValue"];
        [data setObject:[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"SOD_DiscType"] forKey:@"DiscType"];
        [data setObject:[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"SOD_TotalDisc"] forKey:@"TotalDisc"];
        [data setObject:[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"SOD_Remark"] forKey:@"Remark"];
        [data setObject:[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"IM_TotalCondimentSurCharge"] forKey:@"IM_TotalCondimentSurCharge"];
        [data setObject:[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"SOD_Quantity"] forKey:@"OrgQty"];
        
        settingDict = [PublicSqliteMethod getGeneralnTableSettingWithTableName:selectedTbName dbPath:dbPath];
        
        
        transferSalesArray = [PublicSqliteMethod calcGSTByItemNo:[[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"IM_ItemNo"] integerValue] DBPath:dbPath ItemPrice:[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"SOD_UnitPrice"] CompEnableGst:[[settingDict objectForKey:@"EnableGst"] integerValue] CompEnableSVG:[[settingDict objectForKey:@"EnableSVG"] integerValue] TableSVC:[settingDict objectForKey:@"TableSVGPercent"] OverrideSVG:[settingDict objectForKey:@"TableSVGOverRide"] SalesOrderStatus:@"Edit" TaxType:[[LibraryAPI sharedInstance] getTaxType] TableName:selectedTbName ItemDineStatus:[NSString stringWithFormat:@"%@",[NSNumber numberWithInt:[[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"SOD_TakeAwayYN"]integerValue]]] TerminalType:[[LibraryAPI sharedInstance] getWorkMode] SalesDict:data IMQty:@"0" KitchenStatus:@"Printed" PaxNo:[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"SOH_PaxNo"] DocType:@"SalesOrder" CondimentSubTotal:[[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"IM_TotalCondimentSurCharge"] doubleValue] ServiceChargeGstPercent:[[LibraryAPI sharedInstance] getServiceTaxGstPercent] TableDineStatus:[NSString stringWithFormat:@"%d",dineType]];
        
        NSDictionary *data2 = [NSDictionary dictionary];
        data2 = [transferSalesArray objectAtIndex:0];
        //[data2 setValue:[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"CondimentKey"] forKey:@"Index"];
        [data2 setValue:[NSString stringWithFormat:@"%ld",recalcTransferSalesArray.count + 1] forKey:@"Index"];
        
        [data2 setValue:[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"SOD_ManualID"]  forKey:@"SOD_ManualID"];
        [data2 setValue:[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"SOD_ModifierID"] forKey:@"SOD_ModifierID"];
        [data2 setValue:[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"PD_ModifierHdrCode"] forKey:@"PD_ModifierHdrCode"];
        [data2 setValue:[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"OrderType"] forKey:@"OrderType"];
        
        [transferSalesArray replaceObjectAtIndex:0 withObject:data2];
        data2 = nil;
        
        recalcTransferArray = [PublicSqliteMethod recalculateGSTSalesOrderWithSalesOrderArray:transferSalesArray TaxType:[[LibraryAPI sharedInstance] getTaxType]];
        
        [recalcTransferSalesArray addObjectsFromArray:recalcTransferArray];
        
        [recalcTransferSalesArray addObjectsFromArray:[PublicSqliteMethod getSalesOrderCondimentWithDBPath:dbPath SalesOrderNo:[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"OldSOD_DocNo"] ItemCode:[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"SOD_ItemCode"] ManualID:[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"OldSOD_ManualID"] ParentIndex:[[[transferSalesArray objectAtIndex:0] objectForKey:@"Index"] integerValue]]];
        
    }
    
    return recalcTransferSalesArray;

}

+(void)askForReprintKitchenReceiptWithDBPath:(NSString *)dbPath SalesOrderArray:(NSMutableArray *)soArray FromTable:(NSString *)fromTable ToTable:(NSString *)toTable SelectedOption:(NSString *)selectedOption
{
    NSMutableArray *kitchenReceiptArray = [[NSMutableArray alloc] init];
    int kitchenReceiptType = 0;
    [kitchenReceiptArray removeAllObjects];
    FMDatabase *dbTable;
    kitchenReceiptType = [[LibraryAPI sharedInstance] getKitchenReceiptGrouping];
    
    //if (kitchenReceiptType == 0) {
    for (int i = 0; i < soArray.count; i++) {
        dbTable = [FMDatabase databaseWithPath:dbPath];
        //makeXinYeDiscon++;
        //BOOL dbHadError;
        
        if (![dbTable open]) {
            NSLog(@"Fail To Open");
            return;
        }
        
        FMResultSet *rs = [dbTable executeQuery:@"Select IP_PrinterName, P_Mode, P_Brand, P_PortName from ItemPrinter IP inner join Printer p on IP.IP_PrinterName = P.P_PrinterName where IP.IP_ItemNo = ?",[[soArray objectAtIndex:i] objectForKey:@"SOD_ItemCode"]];
        
        while ([rs next]) {
            if ([[rs stringForColumn:@"P_Brand"] isEqualToString:@"Asterix"]) {
                NSMutableDictionary *data = [NSMutableDictionary dictionary];
                [data setObject:[rs stringForColumn:@"P_PortName"] forKey:@"KR_IpAddress"];
                //[asterixPrinterIPArray addObject:data];
                data = nil;
            }
            else
            {
                NSMutableDictionary *data = [NSMutableDictionary dictionary];
                [data setObject:@"Notice" forKey:@"KR_ItemCode"];
                [data setObject:@"Print" forKey:@"KR_Status"];
                [data setObject:@"0" forKey:@"KR_Qty"];
                if ([selectedOption isEqualToString:@"TransferTable"]) {
                    [data setObject:@"Transfer To" forKey:@"KR_Desc"];
                }
                else
                {
                    [data setObject:@"Combine To" forKey:@"KR_Desc"];
                }
                
                [data setObject:@"RequestPrintKitchenReceipt" forKey:@"IM_Flag"];
                [data setObject:[rs stringForColumn:@"P_Brand"] forKey:@"KR_Brand"];
                [data setObject:[rs stringForColumn:@"P_PortName"] forKey:@"KR_IpAddress"];
                [data setObject:[rs stringForColumn:@"P_Mode"] forKey:@"KR_PrintMode"];
                [data setObject:toTable forKey:@"KR_TableName"];
                [data setObject:@"KitchenNotice" forKey:@"KR_DocType"];
                //[data setObject:[NSString stringWithFormat:@"%@-%@",fromTable,[[soArray objectAtIndex:i] objectForKey:@"OldSOD_DocNo"]] forKey:@"KR_DocNo"];
                [data setObject:fromTable forKey:@"KR_DocNo"];
                [data setObject:[rs stringForColumn:@"IP_PrinterName"] forKey:@"KR_PrinterName"];
                [kitchenReceiptArray addObject:data];
                data = nil;
            }
            
            
        }
        
        [rs close];
        
        
    }
    
    NSOrderedSet *orderedSet = [NSOrderedSet orderedSetWithArray:kitchenReceiptArray];
    NSArray *arrayWithoutDuplicates = [orderedSet array];
    [kitchenReceiptArray removeAllObjects];
    [kitchenReceiptArray addObjectsFromArray:arrayWithoutDuplicates];
    
    
    if (kitchenReceiptArray.count > 0 && [[[LibraryAPI sharedInstance] getWorkMode] isEqualToString:@"Main"]) {
        [[NSNotificationCenter defaultCenter]postNotificationName:@"ServerCallConnectionArrayWithNotification" object:kitchenReceiptArray userInfo:nil];
    }
    else if (kitchenReceiptArray.count > 0 && [[[LibraryAPI sharedInstance] getWorkMode] isEqualToString:@"Terminal"])
    {
        [TerminalData xinYeRequestServerToPrintTerminalReqWithReceiptArray:kitchenReceiptArray];
    }
    
    kitchenReceiptArray = nil;
    arrayWithoutDuplicates = nil;
}

+(NSMutableArray *)getItemMastGroupingWithDbPath:(NSString *)dbPath Description:(NSString *)desc ModifierDetailArray:(NSMutableArray *)modifierDetailArray ViewName:(NSString *)viewName ItemServiceType:(NSString *)itemServiceType
{
    __block NSMutableArray *itemMastArray = [[NSMutableArray alloc] init];
    __block NSMutableArray *itemGroupArray = [[NSMutableArray alloc] init];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rsCategory = [db executeQuery:@"Select IC_Category,IC_Description from ItemCatg"];
        
        while ([rsCategory next]) {
            NSMutableDictionary *groupDict = [NSMutableDictionary dictionary];
            
            FMResultSet *rsItem = [db executeQuery:@"Select IM_ItemNo,IM_ItemCode, IM_Description,IM_SalesPrice,IFNULL(IM_FileName,'no_image.jpg') as IM_FileName from ItemMast where IM_Description like ? and IM_ServiceType like ? and IM_Category = ?",[NSString stringWithFormat:@"%@%@%@",@"%",desc,@"%"],[NSString stringWithFormat:@"%@%@%@",@"%",itemServiceType,@"%"],[rsCategory stringForColumn:@"IC_Category"]];
            
            while ([rsItem next]) {
                
                NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"IM_ItemCode MATCHES[cd] %@",
                                           [rsItem stringForColumn:@"IM_ItemCode"]];
                
                NSArray *modifierObject = [modifierDetailArray filteredArrayUsingPredicate:predicate1];
                
                if (modifierObject.count == 0) {
                    
                    NSMutableDictionary *sectionDic = [NSMutableDictionary dictionary];
                    if ([viewName isEqualToString:@"ModifierGroup"]) {
                        [sectionDic setObject:[rsItem stringForColumn:@"IM_ItemCode"] forKey:@"IM_ItemCode"];
                        [sectionDic setObject:[rsItem stringForColumn:@"IM_Description"] forKey:@"IM_Description"];
                        [sectionDic setObject:[rsItem stringForColumn:@"IM_SalesPrice"] forKey:@"IM_SalesPrice"];
                        [sectionDic setObject:[rsItem stringForColumn:@"IM_FileName"] forKey:@"IM_FileName"];
                        
                    }
                    else if ([viewName isEqualToString:@"PackageDetail"])
                    {
                        [sectionDic setObject:[rsItem stringForColumn:@"IM_ItemCode"] forKey:@"PD_Code"];
                        [sectionDic setObject:[rsItem stringForColumn:@"IM_ItemCode"] forKey:@"PD_ItemCode"];
                        [sectionDic setObject:[rsItem stringForColumn:@"IM_Description"] forKey:@"PD_Description"];
                        [sectionDic setObject:[rsItem stringForColumn:@"IM_SalesPrice"] forKey:@"PD_Price"];
                        [sectionDic setObject:@"ItemMast" forKey:@"PD_ItemType"];
                        
                        //[sectionDic setObject:@"ItemMast" forKey:@"PD_Type"];
                        [sectionDic setObject:@"1" forKey:@"PD_MinChoice"];
                    }
                    else if ([viewName isEqualToString:@"ItemMast"])
                    {
                        [sectionDic setObject:[rsItem stringForColumn:@"IM_ItemNo"] forKey:@"IM_ItemNo"];
                        [sectionDic setObject:[rsItem stringForColumn:@"IM_ItemCode"] forKey:@"IM_ItemCode"];
                        [sectionDic setObject:[rsItem stringForColumn:@"IM_Description"] forKey:@"IM_Description"];
                        [sectionDic setObject:[rsItem stringForColumn:@"IM_SalesPrice"] forKey:@"IM_SalesPrice"];
                        [sectionDic setObject:[rsItem stringForColumn:@"IM_FileName"] forKey:@"IM_FileName"];
                    }
                    
                    [itemMastArray addObject:sectionDic];
                    sectionDic = nil;
                    
                }
                
                modifierObject = nil;
                predicate1 = nil;
                
            }
            if (itemMastArray.count > 0) {
                
                //[itemSectionTitleArray addObject:[rsCategory resultDictionary]];
                
                [groupDict setObject:[itemMastArray mutableCopy] forKey:[rsCategory stringForColumn:@"IC_Description"]];
                [groupDict setObject:[rsCategory stringForColumn:@"IC_Description"] forKey:@"IC_Name"];
                [itemGroupArray addObject:groupDict];
            }
            
            [itemMastArray removeAllObjects];
            [rsItem close];
        }
        
    }];
    
    [queue close];
    itemMastArray = nil;
    return itemGroupArray;

}

@end
