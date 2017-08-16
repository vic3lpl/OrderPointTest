//
//  LaunchCheckingViewController.m
//  IpadOrder
//
//  Created by IRS on 23/05/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import "LaunchCheckingViewController.h"
#import "LibraryAPI.h"
#import <FMDB.h>
#import <KVNProgress.h>
#import <AFNetworking/AFNetworking.h>
#import "DBManager.h"
#import "ViewController.h"
#import "ePOS-Print.h"

@class EposPrint;
extern NSString *baseUrl;
extern NSString *orderPointVersion;
@interface LaunchCheckingViewController ()
{
    NSMutableArray *appRegArray;
    NSString *dbPath;
}
@property (nonatomic, strong) DBManager *dbManager;
-(void)callGetWebRegistrationDataWithNotification:(NSNotification *)notification;
@end

@implementation LaunchCheckingViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    UIGraphicsBeginImageContext(self.view.frame.size);
    [[UIImage imageNamed:@"FlashScreen"] drawInRect:self.view.bounds];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:image];
    image = nil;
    
    appRegArray = [[NSMutableArray alloc]init];
    self.navigationController.navigationBar.hidden = YES;
    self.dbManager = [[DBManager alloc] initWithDatabaseFilename:@"iorder.db"];
    
    NSArray *docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [docPaths objectAtIndex:0];
    dbPath = [documentsDir   stringByAppendingPathComponent:@"iorder.db"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(callGetWebRegistrationDataWithNotification:)
                                                 name:@"CallGetWebRegistrationDataWithNotification"
                                               object:nil];
    
    [[LibraryAPI sharedInstance]setDbPath:dbPath];
    [self updateTableStructure];
    [self getLocalRegistrationDataWithFlag:@"Launch"];
    [self getAppRegistrationData];
    
}

-(NSString *)formatNumberWithComma:(NSNumber *)number
{
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc]init];
    //設顯示小數點下第二位
    [formatter setMaximumFractionDigits:2];
    //設千分位的逗點
    [formatter setUsesGroupingSeparator:YES];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    
    double entryFieldFloat = [number doubleValue];
    if ([number.stringValue rangeOfString:@"."].length == 1) {
        formatter.alwaysShowsDecimalSeparator = YES;
        return [formatter stringFromNumber:[NSNumber numberWithDouble:entryFieldFloat]];
    }
    
    formatter.alwaysShowsDecimalSeparator = NO;
    return [formatter stringFromNumber:[NSNumber numberWithDouble:entryFieldFloat]];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - afnetworking part

-(void)callGetWebRegistrationDataWithNotification:(NSNotification *)notification
{
    
    [self getLocalRegistrationDataWithFlag:@"BecomeActive"];
    
}

-(void)callGetAppStatusWebApiWithRegistrationData:(NSMutableArray *)regArray
{
    
    NSMutableArray *jsonArray = [[NSMutableArray alloc] initWithCapacity:1];
    NSString *toDay;
    NSDate *toDayDate = [NSDate date];
    //NSDateFormatter *dateFormater = [[NSDateFormatter alloc] init];
    NSDateFormatter *dateFormater = [[LibraryAPI sharedInstance] getDateFormateryyyymmdd];
    //[dateFormater setDateFormat:@"yyyy-MM-dd"];
    toDay = [dateFormater stringFromDate:toDayDate];
    
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc]initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    NSDictionary *parameters = @{@"DeviceID":[[regArray objectAtIndex:0] objectForKey:@"App_LicenseID"],@"DealerID":[[regArray objectAtIndex:0] objectForKey:@"DealerID"],@"PurchaseID":[[regArray objectAtIndex:0] objectForKey:@"App_PurchaseID"],@"Status":[[regArray objectAtIndex:0] objectForKey:@"App_Status"],@"DateFrom":toDay,@"DateTo":toDay,@"Device_YN":@"1",@"AllDealer_YN":@"1"};
    //NSLog(@"%@",parameters);
    NSMutableURLRequest *req = [[AFJSONRequestSerializer serializer]requestWithMethod:@"POST" URLString:[NSString stringWithFormat:@"%@%@",baseUrl, @"/GetDeviceStatus.aspx"] parameters:parameters error:nil];
    
    [req setTimeoutInterval:25];
    
    //dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    [[manager dataTaskWithRequest:req completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        
        if (!error) {
            NSDictionary* json = [NSJSONSerialization JSONObjectWithData:responseObject
                                                                 options:kNilOptions
                                                                   error:&error];
            
            
            [jsonArray addObjectsFromArray:[json objectForKey:@"AppList"]];
            //NSLog(@"%@",jsonArray);
            if (jsonArray.count > 0) {
                if ([[[jsonArray objectAtIndex:0] objectForKey:@"Result"] isEqualToString:@"True"]) {
                    
                    [[LibraryAPI sharedInstance] setAppApiVersion:[[jsonArray objectAtIndex:0] objectForKey:@"AppVersion"]];
                    
                    if ([[[regArray objectAtIndex:0] objectForKey:@"Flag"] isEqualToString:@"Launch"]) {
                        if ([self updateAppRegistrationNCompanyProfileWithGetAppStatusApiResult:jsonArray]) {
                            [self goToViewController];
                        }
                    }
                    else
                    {
                        [self updateAppRegistrationNCompanyProfileWithGetAppStatusApiResult:jsonArray];
                        
                        appRegArray = nil;
                    }
                    
                    [[NSUserDefaults standardUserDefaults] setObject:[[jsonArray objectAtIndex:0] objectForKey:@"DatabaseID"] forKey:@"databaseID"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    
                }
                else
                {
                    if ([[[appRegArray objectAtIndex:0] objectForKey:@"Flag"] isEqualToString:@"Launch"]) {
                        [self goToViewController];
                    }
                    else if ([[[appRegArray objectAtIndex:0] objectForKey:@"Flag"] isEqualToString:@"BecomeActive"])
                    {
                        
                    }
                    else
                    {
                        [self goToViewController];
                    }
                    
                    //ViewController *viewController = [[ViewController alloc] init];
                    //[self.navigationController pushViewController:viewController animated:NO];
                }
            }
            else
            {
                
                if (appRegArray.count == 0)
                {
                    [self goToViewController];
                }
                
                if ([[[appRegArray objectAtIndex:0] objectForKey:@"Flag"] isEqualToString:@"Launch"]) {
                    [self goToViewController];
                }
                //ViewController *viewController = [[ViewController alloc] init];
                //[self.navigationController pushViewController:viewController animated:NO];
                NSLog(@"%@",@"Check Status Return Empty json");
            }
            json = nil;
            //updateReturnResult = YES;
            
        } else {
            
            if (appRegArray.count == 0) {
                [self goToViewController];
            }
            
            if ([[[appRegArray objectAtIndex:0] objectForKey:@"Flag"] isEqualToString:@"Launch"]) {
                [self goToViewController];
            }
            
            //ViewController *viewController = [[ViewController alloc] init];
            //[self.navigationController pushViewController:viewController animated:NO];
            
            //updateReturnResult = YES;
        }
        //dispatch_semaphore_signal(sem);
    }] resume];
    jsonArray = nil;
    
    //dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    //[req setHTTPBody:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];

}

-(void)goToViewController
{
    ViewController *viewController = [[ViewController alloc] init];
    [self.navigationController pushViewController:viewController animated:NO];
}

#pragma mark - sqlite part

-(void)updateTableStructure
{
    //NSString *version;
    
    FMDatabase *db = [FMDatabase databaseWithPath:dbPath];
    
    if (![db open])
    {
        NSLog(@"open failed");
        return;
    }
    /*
    if (![db columnExists:@"App_Version" inTableWithName:@"AppRegistration"])
    {
        [db executeUpdate:@"ALTER TABLE AppRegistration ADD COLUMN App_Version TEXT"];
        [db executeUpdate:@"Update AppRegistration set App_Version = ?",@"v1.4.03.2016"];
        FMResultSet *rs = [db executeQuery:@"Select App_Version from AppRegistration"];
        
        if ([rs next]) {
            version = [rs stringForColumn:@"App_Version"];
        }
        else
        {
            version = @"Old";
        }
        [rs close];
    }
    else
    {
        FMResultSet *rs = [db executeQuery:@"Select App_Version from AppRegistration"];
        
        if ([rs next]) {
            version = [rs stringForColumn:@"App_Version"];
        }
        else
        {
            version = @"Old";
        }
        [rs close];
    }
    */
    
    //if (![version isEqualToString:orderPointVersion]) {
        
        if (![db columnExists:@"PQ_PrinterName" inTableWithName:@"PrintQueue"])
        {
            [db executeUpdate:@"ALTER TABLE PrintQueue ADD COLUMN PQ_PrinterName TEXT"];
        }
        
        if (![db columnExists:@"PQ_ManualID" inTableWithName:@"PrintQueue"])
        {
            [db executeUpdate:@"ALTER TABLE PrintQueue ADD COLUMN PQ_ManualID TEXT"];
        }
        
        if (![db columnExists:@"T_AccTaxCode" inTableWithName:@"Tax"])
        {
            [db executeUpdate:@"ALTER TABLE Tax ADD COLUMN T_AccTaxCode TEXT"];
        }
        
        if (![db columnExists:@"PT_AccCode" inTableWithName:@"PaymentType"])
        {
            [db executeUpdate:@"ALTER TABLE PaymentType ADD COLUMN PT_AccCode TEXT"];
        }
        
        if (![db columnExists:@"PT_ImgName" inTableWithName:@"PaymentType"]) {
            [db executeUpdate:@"ALTER TABLE PaymentType ADD COLUMN PT_ImgName TEXT"];
            [db executeUpdate:@"ALTER TABLE PaymentType ADD COLUMN PT_Description TEXT"];
            [db executeUpdate:@"Update PaymentType set PT_Description = PT_Code, PT_ImgName = PT_Code"];
            
        }
        
        if (![db columnExists:@"UL_ReprintBillPermission" inTableWithName:@"UserLogin"])
        {
            [db executeUpdate:@"ALTER TABLE UserLogin ADD COLUMN UL_ReprintBillPermission INTEGER DEFAULT 0"];
            
            [db executeUpdate:@"Update UserLogin set UL_ReprintBillPermission = 0"];
        }
        
        
        
        //--------------------SalesOrder Part-----------------------------------
        
        if (![db columnExists:@"SOD_ModifierID" inTableWithName:@"SalesOrderDtl"])
        {
            [db executeUpdate:@"ALTER TABLE SalesOrderDtl ADD COLUMN SOD_ModifierID TEXT DEFAULT ''"];
            [db executeUpdate:@"ALTER TABLE SalesOrderDtl ADD COLUMN SOD_ModifierHdrCode TEXT DEFAULT ''"];
            
        }
        
        if (![db columnExists:@"SOH_VoidDate" inTableWithName:@"SalesOrderHdr"])
        {
            [db executeUpdate:@"ALTER TABLE SalesOrderHdr ADD COLUMN SOH_VoidDate TEXT"];
            [db executeUpdate:@"Update SalesOrderHdr set SOH_VoidDate = SOH_Date where SOH_Status = ?",@"Void"];
        }
        
        if (![db columnExists:@"SOH_CustName" inTableWithName:@"SalesOrderHdr"])
        {
            [db executeUpdate:@"ALTER TABLE SalesOrderHdr ADD COLUMN SOH_CustName TEXT"];
            [db executeUpdate:@"ALTER TABLE SalesOrderHdr ADD COLUMN SOH_CustAdd1 TEXT"];
            [db executeUpdate:@"ALTER TABLE SalesOrderHdr ADD COLUMN SOH_CustAdd2 TEXT"];
            [db executeUpdate:@"ALTER TABLE SalesOrderHdr ADD COLUMN SOH_CustAdd3 TEXT"];
            [db executeUpdate:@"ALTER TABLE SalesOrderHdr ADD COLUMN SOH_CustTelNo TEXT"];
            [db executeUpdate:@"ALTER TABLE SalesOrderHdr ADD COLUMN SOH_CustGstNo TEXT"];
            
            [db executeUpdate:@"Update SalesOrderHdr set SOH_CustName = ?, SOH_CustAdd1 = ?, SOH_CustAdd2 = ?, SOH_CustAdd3 = ?, SOH_CustTelNo = ?, SOH_CustGstNo = ?",@"",@"",@"",@"",@"",@""];
        }
        
        
        if (![db columnExists:@"SOH_ServiceTaxGstCode" inTableWithName:@"SalesOrderHdr"])
        {
            [db executeUpdate:@"ALTER TABLE SalesOrderHdr ADD COLUMN SOH_ServiceTaxGstCode TEXT"];
        }
        
        if (![db columnExists:@"SOH_TaxIncluded_YN" inTableWithName:@"SalesOrderHdr"])
        {
            [db executeUpdate:@"ALTER TABLE SalesOrderHdr ADD COLUMN SOH_TaxIncluded_YN INTEGER DEFAULT 0"];
        }
        
        if (![db columnExists:@"SOH_TerminalName" inTableWithName:@"SalesOrderHdr"])
        {
            [db executeUpdate:@"ALTER TABLE SalesOrderHdr ADD COLUMN SOH_TerminalName TEXT"];
        }
        
        if (![db columnExists:@"SOH_PaxNo" inTableWithName:@"SalesOrderHdr"])
        {
            [db executeUpdate:@"ALTER TABLE SalesOrderHdr ADD COLUMN SOH_PaxNo TEXT"];
            [db executeUpdate:@"Update SalesOrderHdr set SOH_PaxNo = ?",@"1"];
        }
        
        if (![db columnExists:@"SOD_ManualID" inTableWithName:@"SalesOrderDtl"])
        {
            [db executeUpdate:@"ALTER TABLE SalesOrderDtl ADD COLUMN SOD_ManualID TEXT"];
        }
        
        if (![db columnExists:@"SOD_TotalCondimentSurCharge" inTableWithName:@"SalesOrderDtl"])
        {
            [db executeUpdate:@"ALTER TABLE SalesOrderDtl ADD COLUMN SOD_TotalCondimentSurCharge REAL DEFAULT 0.00"];
            [db executeUpdate:@"Update SalesOrderDtl set SOD_TotalCondimentSurCharge = ?",@"0"];
        }
        
        if (![db columnExists:@"SOD_TotalCondimentUnitPrice" inTableWithName:@"SalesOrderDtl"])
        {
            [db executeUpdate:@"ALTER TABLE SalesOrderDtl ADD COLUMN SOD_TotalCondimentUnitPrice REAL DEFAULT 0.00"];
            [db executeUpdate:@"Update SalesOrderDtl set SOD_TotalCondimentUnitPrice = ?",@"0"];
        }
        
        //--------------------invoice part--------------------------------------------
        
        if (![db columnExists:@"IvD_ModifierID" inTableWithName:@"InvoiceDtl"])
        {
            [db executeUpdate:@"ALTER TABLE InvoiceDtl ADD COLUMN IvD_ModifierID TEXT DEFAULT ''"];
            [db executeUpdate:@"ALTER TABLE InvoiceDtl ADD COLUMN IvD_ModifierHdrCode TEXT DEFAULT ''"];
            
        }
        
        if (![db columnExists:@"IvH_CustName" inTableWithName:@"InvoiceHdr"])
        {
            [db executeUpdate:@"ALTER TABLE InvoiceHdr ADD COLUMN IvH_CustName TEXT"];
            [db executeUpdate:@"ALTER TABLE InvoiceHdr ADD COLUMN IvH_CustAdd1 TEXT"];
            [db executeUpdate:@"ALTER TABLE InvoiceHdr ADD COLUMN IvH_CustAdd2 TEXT"];
            [db executeUpdate:@"ALTER TABLE InvoiceHdr ADD COLUMN IvH_CustAdd3 TEXT"];
            [db executeUpdate:@"ALTER TABLE InvoiceHdr ADD COLUMN IvH_CustTelNo TEXT"];
            [db executeUpdate:@"ALTER TABLE InvoiceHdr ADD COLUMN IvH_CustGstNo TEXT"];
            
            [db executeUpdate:@"Update InvoiceHdr set IvH_CustName = ?, IvH_CustAdd1 = ?, IvH_CustAdd2 = ?, IvH_CustAdd3 = ?, IvH_CustTelNo = ?, IvH_CustGstNo = ?",@"",@"",@"",@"",@"",@""];
        }
        
        
        if (![db columnExists:@"IvH_PaymentType8" inTableWithName:@"InvoiceHdr"])
        {
            [db executeUpdate:@"ALTER TABLE InvoiceHdr ADD COLUMN IvH_PaymentType8 TEXT"];
            
            [db executeUpdate:@"ALTER TABLE InvoiceHdr ADD COLUMN IvH_PaymentAmt8 REAL DEFAULT 0.00"];
            
            [db executeUpdate:@"ALTER TABLE InvoiceHdr ADD COLUMN IvH_PaymentRef8 TEXT"];
        }
        
        
        if (![db columnExists:@"IvH_ServiceTaxGstCode" inTableWithName:@"InvoiceHdr"])
        {
            [db executeUpdate:@"ALTER TABLE InvoiceHdr ADD COLUMN IvH_ServiceTaxGstCode TEXT"];
        }
        
        if (![db columnExists:@"IvH_SoNo" inTableWithName:@"InvoiceHdr"])
        {
            [db executeUpdate:@"ALTER TABLE InvoiceHdr ADD COLUMN IvH_SoNo TEXT"];
        }
        
        if (![db columnExists:@"IvH_TaxIncluded_YN" inTableWithName:@"InvoiceHdr"])
        {
            [db executeUpdate:@"ALTER TABLE InvoiceHdr ADD COLUMN IvH_TaxIncluded_YN INTEGER DEFAULT 0"];
        }
        
        if (![db columnExists:@"IvH_TerminalName" inTableWithName:@"InvoiceHdr"])
        {
            [db executeUpdate:@"ALTER TABLE InvoiceHdr ADD COLUMN IvH_TerminalName TEXT"];
        }
        
        if (![db columnExists:@"IvD_ManualID" inTableWithName:@"InvoiceDtl"])
        {
            [db executeUpdate:@"ALTER TABLE InvoiceDtl ADD COLUMN IvD_ManualID TEXT"];
        }
        if (![db columnExists:@"IvD_TotalCondimentSurCharge" inTableWithName:@"InvoiceDtl"])
        {
            [db executeUpdate:@"ALTER TABLE InvoiceDtl ADD COLUMN IvD_TotalCondimentSurCharge REAL DEFAULT 0.00"];
            [db executeUpdate:@"Update InvoiceDtl set IvD_TotalCondimentSurCharge = ?",@"0"];
        }
        
        if (![db columnExists:@"IvH_PaxNo" inTableWithName:@"InvoiceHdr"])
        {
            [db executeUpdate:@"ALTER TABLE InvoiceHdr ADD COLUMN IvH_PaxNo TEXT"];
            [db executeUpdate:@"Update InvoiceHdr set IvH_PaxNo = ?",@"1"];
        }
        
        if (![db tableExists:@"PrintOption"]) {
            [db executeUpdate:@"CREATE TABLE PrintOption ("
             @" `PO_ID`	INTEGER PRIMARY KEY AUTOINCREMENT,"
             @" `PO_ReceiptHeader`	TEXT,"
             @" `PO_ReceiptFooter`	BLOB,"
             @" `PO_ShowCustomerInfo`	INTEGER DEFAULT 1,"
             //@" `PO_ShowPaymentMode`	INTEGER DEFAULT 1,"
             @" `PO_ShowGstSummary`	INTEGER DEFAULT 1,"
             @" `PO_ShowCompanyTelNo`	INTEGER DEFAULT 1,"
             @" `PO_ShowDiscount`	INTEGER DEFAULT 1,"
             @" `PO_ShowServiceCharge`	INTEGER DEFAULT 1,"
             @" `PO_ShowItemDescription2` INTEGER DEFAULT 1,"
             @" `PO_ReceiptContent`	INTEGER DEFAULT 0,"
             @" `PO_ShowPackageItemDetail`	INTEGER DEFAULT 1,"
             @" `PO_ShowSubTotalIncGst`	INTEGER DEFAULT 1)"
             ];
            
            [db executeUpdate:@"Insert into PrintOption (PO_ReceiptHeader, PO_ReceiptFooter, PO_ShowCustomerInfo, PO_ShowGstSummary, PO_ShowCompanyTelNo, PO_ShowDiscount, PO_ShowServiceCharge, PO_ShowSubTotalIncGst, PO_ReceiptContent,PO_ShowItemDescription2,PO_ShowPackageItemDetail) values(?,?,?,?,?,?,?,?,?,?,?)",@"Cash Sales",@"Thanks you. Please come again.",@"1",@"1",@"1",@"1",@"1",@"1",@"0",@"1",@"1"];
            
        }
        
        //--------------------add in table----------------------------------
        if (![db tableExists:@"SalesOrderCondiment"]) {
            [db executeUpdate:@"Drop Table CondimentHdr"];
            [db executeUpdate:@"Drop Table CondimentDtl"];
            
            [db executeUpdate:@"CREATE TABLE SalesOrderCondiment ('SOC_ID'	INTEGER PRIMARY KEY AUTOINCREMENT,'SOC_DocNo'	TEXT,'SOC_ItemCode'	TEXT,'SOC_CHCode'	TEXT,'SOC_CDCode'	TEXT,'SOC_CDDescription'	TEXT,'SOC_CDQty'	REAL DEFAULT 0.00,'SOC_CDPrice'	REAL DEFAULT 0.00,'SOC_CDDiscount'	REAL DEFAULT 0.00, 'SOC_DateTime'	TEXT,'SOC_CDManualKey'	TEXT)"];
        }
        
        if (![db tableExists:@"InvoiceCondiment"]) {
            [db executeUpdate:@"CREATE TABLE InvoiceCondiment ('IVC_ID'	INTEGER PRIMARY KEY AUTOINCREMENT,'IVC_DocNo'	TEXT,'IVC_ItemCode'	TEXT,'IVC_CHCode'	TEXT,'IVC_CDCode'	TEXT,'IVC_CDDescription'	TEXT,'IVC_CDQty'	REAL DEFAULT 0.00,'IVC_CDPrice'	REAL DEFAULT 0.00,'IVC_CDDiscount'	REAL DEFAULT 0.00, 'IVC_DateTime'	TEXT,'IVC_CDManualKey'	TEXT)"];
        }
        
        if (![db tableExists:@"CondimentHdr"]) {
            [db executeUpdate:@"CREATE TABLE CondimentHdr (CH_ID integer PRIMARY KEY AUTOINCREMENT,CH_Code	TEXT,CH_Description	TEXT)"];
        }
        
        if (![db tableExists:@"CondimentDtl"])
        {
            [db executeUpdate:@"CREATE TABLE CondimentDtl (CD_ID	integer PRIMARY KEY AUTOINCREMENT,CD_Code	text,CD_Description	text,CD_Price	text,CD_CondimentHdrCode	TEXT)"];
        }
        
        if (![db tableExists:@"LinkAccount"]) {
            
            [db executeUpdate:@"CREATE TABLE LinkAccount (LA_No	INTEGER PRIMARY KEY AUTOINCREMENT, LA_ClientID	TEXT, LA_AccUserID	TEXT,LA_AccPassword	TEXT,LA_Company	TEXT,LA_CashSalesAC	TEXT,LA_CashSalesRoundingAC	TEXT,LA_ServiceChargeAC	TEXT,LA_CashSalesDesc	TEXT,LA_AccUrl	TEXT,LA_CustomerAC	TEXT)"];
            
        }
        
        if(![db tableExists:@"ItemCondiment"])
        {
            [db executeUpdate:@"CREATE TABLE ItemCondiment(`IC_ID`	INTEGER PRIMARY KEY AUTOINCREMENT,`IC_ItemCode`	TEXT,`IC_CondimentHdrCode`	TEXT) "];
            
        }
        
        if (![db tableExists:@"PrintQueue"]) {
            [db executeUpdate:@"CREATE TABLE PrintQueue ("
             @"'PQ_No'	INTEGER PRIMARY KEY AUTOINCREMENT,"
             @"'PQ_ItemCode'	TEXT,"
             @"'PQ_ItemDesc'	TEXT,"
             @"'PQ_PrinterIP'	TEXT,"
             @"'PQ_PrinterBrand'	TEXT,"
             @"'PQ_PrinterMode'	TEXT,"
             @"'PQ_DocType'	TEXT,"
             @"'PQ_DocNo'	TEXT,"
             @"'PQ_TableName'	TEXT,"
             @"'PQ_ItemQty'	TEXT,"
             @"'PQ_Status'	TEXT,"
             @"'PQ_OrderType'	TEXT,"
             @"'PQ_ManualID'	TEXT"
             ")"];
        }
        
        //-------------------- latest version---------------------
        
        if (![db columnExists:@"PO_ShowPackageItemDetail" inTableWithName:@"PrintOption"])
        {
            [db executeUpdate:@"ALTER TABLE PrintOption ADD COLUMN PO_ShowPackageItemDetail INTEGER DEFAULT 1"];
            [db executeUpdate:@"Update PrintOption set PO_ShowPackageItemDetail = ?",@"1"];
        }
        
        if (![db columnExists:@"IM_ServiceType" inTableWithName:@"ItemMast"])
        {
            [db executeUpdate:@"ALTER TABLE ItemMast ADD COLUMN IM_ServiceType INTEGER DEFAULT 0"];
            
            [db executeUpdate:@"Update ItemMast set IM_ServiceType = 0"];
        }
        
        if (![db columnExists:@"PQ_PackageName" inTableWithName:@"PrintQueue"])
        {
            [db executeUpdate:@"ALTER TABLE PrintQueue ADD COLUMN PQ_PackageName TEXT"];
        }
        
        if (![db columnExists:@"PQ_OrderType" inTableWithName:@"PrintQueue"])
        {
            [db executeUpdate:@"ALTER TABLE PrintQueue ADD COLUMN PQ_OrderType TEXT"];
        }
        
        if (![db tableExists:@"ModifierDtl"]) {
            [db executeUpdate:@"CREATE TABLE ModifierDtl ("
             @"'MD_ID'	INTEGER PRIMARY KEY AUTOINCREMENT,"
             @"'MD_MGCode'	TEXT,"
             @"'MD_Price'	REAL,"
             @"'MD_ItemCode'	TEXT,"
             @"'MD_ItemDescription'	TEXT,"
             @"'MD_ItemFileName'	TEXT"
             @")"
             ];
        }
        
        if (![db tableExists:@"ModifierHdr"]) {
            [db executeUpdate:@"CREATE TABLE ModifierHdr ("
             @"'MH_ID'	INTEGER PRIMARY KEY AUTOINCREMENT,"
             @"'MH_Code'	TEXT,"
             @"'MH_Description'	TEXT,"
             @"'MH_MinChoice'	INTEGER"
             @")"
             ];
        }
        
        if (![db tableExists:@"PackageItemDtl"]) {
            [db executeUpdate:@"CREATE TABLE PackageItemDtl ("
             @"'PD_ID'	INTEGER PRIMARY KEY AUTOINCREMENT,"
             @"'PD_Code'	TEXT,"
             @"'PD_ItemCode'	TEXT,"
             @"'PD_ItemDescription'	TEXT,"
             @"'PD_ItemType'	TEXT,"
             @"'PD_Price'	REAL,"
             @"'PD_MinChoice'	INTEGER"
             
             @")"
             ];
        }

    //}
    //else
    //{
        
    //}
    
    
    [db executeUpdate:@"Delete from PrintQueue"];
    
    //[db executeUpdate:@"Update AppRegistration set App_Version = ?",@"v1.4.05.2017"];
    
    [db close];
}

-(void)getLocalRegistrationDataWithFlag:(NSString *)flag
{
    
    if (![flag isEqualToString:@"Launch"]) {
        appRegArray = [[NSMutableArray alloc] init];
    }
    
    [appRegArray removeAllObjects];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSString *command;
        
        command = [NSString stringWithFormat:@"%@,'%@' as Flag from AppRegistration",@"Select *,ifnull(App_DealerID,'') as DealerID",flag];
        
        FMResultSet *rsAppReg = [db executeQuery:command];
        
        if ([rsAppReg next])
        {
            [appRegArray addObject:[rsAppReg resultDictionary]];
        }
        [rsAppReg close];
        
        /*
        if (appRegArray.count > 0) {
            if ([[[appRegArray objectAtIndex:0] objectForKey:@"App_Status"] isEqualToString:@"DEMO"] && [[[appRegArray objectAtIndex:0] objectForKey:@"App_CompanyName"] isEqualToString:@"FARM VILLE CAFE"]) {
                [db executeUpdate:@"Delete from SalesOrderHdr where SOH_DocNo = ?",@"SO000000036"];
                [db executeUpdate:@"Delete from SalesOrderHdr where SOH_DocNo = ?",@"SO000000044"];
                [db executeUpdate:@"Delete from SalesOrderCondiment where SOC_DocNo = ?",@"SO000000044"];
                [db executeUpdate:@"Delete from SalesOrderCondiment where SOC_DocNo = ?",@"SO000000036"];
            }
        }
        */
        
        if([flag isEqualToString:@"BecomeActive"])
        {
            if (appRegArray.count > 0) {
                [self callGetAppStatusWebApiWithRegistrationData:appRegArray];
            }
        }
        
    }];
    
    [queue close];
}


-(void)getAppRegistrationData
{
    //[appRegArray removeAllObjects];
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rsPrinterSetting = [db executeQuery:@"Select P_Brand,P_PortName from Printer where P_Type = ?",@"Receipt"];
        
        if ([rsPrinterSetting next]) {
            [[LibraryAPI sharedInstance] setPrinterBand:[rsPrinterSetting stringForColumn:@"P_Brand"]];
            [[LibraryAPI sharedInstance] setPrinterPortName:[rsPrinterSetting stringForColumn:@"P_PortName"]];
        }
        else
        {
            [[LibraryAPI sharedInstance] setPrinterBand:@"-"];
            [[LibraryAPI sharedInstance] setPrinterPortName:@"0.0.0.0"];
        }
        [rsPrinterSetting close];
        
        FMResultSet *rs = [db executeQuery:@"select * from GeneralSetting"];
        
        if ([rs next]) {
            if ([rs doubleForColumn:@"GS_EnableMTO"] == 1) {
                [[LibraryAPI sharedInstance]setMultipleTerminalMode:@"True"];
                if ([rs doubleForColumn:@"GS_WorkMode"] == 0) {
                    [[LibraryAPI sharedInstance] setWorkMode:@"Main"];
                    
                }
                else
                {
                    [[LibraryAPI sharedInstance] setWorkMode:@"Terminal"];
                }
                
            }
            else
            {
                [[LibraryAPI sharedInstance] setWorkMode:@"Main"];
                [[LibraryAPI sharedInstance] setMultipleTerminalMode:@"False"];
            }
            
        }
        [rs close];
        
        FMResultSet *rsPQ = [db executeQuery:@"Select PO_ShowPackageItemDetail from PrintOption"];
        
        if ([rsPQ next]) {
            [[LibraryAPI sharedInstance] setShowPackageDetail:[rsPQ intForColumn:@"PO_ShowPackageItemDetail"]];
        }
        else
        {
            [[LibraryAPI sharedInstance] setShowPackageDetail:1];
        }
        [rsPQ close];
        
        FMResultSet *rsFlyTechPrinter = [db executeQuery:@"Select * from Printer where P_Brand = ?",@"FlyTech"];
            
        if ([rsFlyTechPrinter next]) {
            [[LibraryAPI sharedInstance] setPrinterUUID:[rsFlyTechPrinter stringForColumn:@"P_MacAddress"]];
        }
        else
        {
            [[LibraryAPI sharedInstance] setPrinterUUID:@"Non"];
        }
        
    }];
    
    [queue close];
    
    if (appRegArray.count > 0) {
        if (![[[appRegArray objectAtIndex:0] objectForKey:@"App_Status"] isEqualToString:@"DEMO"]) {
            [self callGetAppStatusWebApiWithRegistrationData:appRegArray];
        }
        else
        {
            ViewController *viewController = [[ViewController alloc] init];
            [self.navigationController pushViewController:viewController animated:NO];
        }
    }
    else
    {
        ViewController *viewController = [[ViewController alloc] init];
        [self.navigationController pushViewController:viewController animated:NO];
    }
    appRegArray = nil;
    
}

-(BOOL)updateAppRegistrationNCompanyProfileWithGetAppStatusApiResult:(NSMutableArray *)dict
{
    __block BOOL updateResult;
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback){
        //[dbComp beginTransaction];
        
        [db executeUpdate:@"Update Company set Comp_Company = ?,"
         " Comp_Country = ?, Comp_Address1 = ?,"
         "Comp_Address2 = ?,"
         "Comp_PostCode = ?"
         ,[[dict objectAtIndex:0] objectForKey:@"CompanyName1"], [[dict objectAtIndex:0] objectForKey:@"Country"], [[dict objectAtIndex:0] objectForKey:@"Address1"], [[dict objectAtIndex:0] objectForKey:@"Address2"],[[dict objectAtIndex:0] objectForKey:@"Postcode"]];
        
        if (![db hadError]) {
            //result = @"Success";
            [db executeUpdate:@"Update AppRegistration set App_CompanyName = ?, App_RegKey = ?, App_TerminalQty = ?,App_DealerID = ?,App_ReqExpDate = ?, App_LicenseID = ?, App_ProductKey = ?, App_Status = ?, App_PurchaseID = ?, App_Action = ?",[[dict objectAtIndex:0] objectForKey:@"CompanyName1"],[[dict objectAtIndex:0] objectForKey:@"RegisterKey"],[[dict objectAtIndex:0] objectForKey:@"TerminalNo"],[[dict objectAtIndex:0] objectForKey:@"DealerID"],[[dict objectAtIndex:0] objectForKey:@"ExpDate"],[[dict objectAtIndex:0] objectForKey:@"DeviceID"], [[dict objectAtIndex:0] objectForKey:@"ProductKey"],[[dict objectAtIndex:0] objectForKey:@"Status"],[[dict objectAtIndex:0] objectForKey:@"PurchaseID"], [[dict objectAtIndex:0] objectForKey:@"Action"]];
            
            if (![db hadError]) {
                updateResult = true;
            }
            else
            {
                [self showAlertView:[db lastErrorMessage] title:@"Fail"];
                *rollback = YES;
                updateResult = false;
            }
        }
        else
        {
            [self showAlertView:[db lastErrorMessage] title:@"Fail"];
            *rollback = YES;
            updateResult = false;
            
        }
        
    }];
    
    [queue close];
    
    return updateResult;
}

-(void)getLocalRegistrationInfo
{
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback){
        //[dbComp beginTransaction];
        
        FMResultSet *rs = [db executeQuery:@"Select * from AppRegistration"];
        
        if ([rs next]) {
            if ([[rs stringForColumn:@"App_Status"]isEqualToString:@"ffff"]) {
                
            }
        }
        
        
    }];
    
    [queue close];
}


#pragma mark - alertView

-(void)showAlertView:(NSString *)msg title:(NSString *)title
{
    UIAlertController * alert = [[LibraryAPI sharedInstance] showAlertViewWithMsg:msg Title:title];
    
    [self presentViewController:alert animated:YES completion:nil];
    
    alert = nil;
    /*
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:msg
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
     */
}

#pragma mark - init once nsdateformater
- (NSDateFormatter *)formatter {
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd"; // twitter date format
    });
    return formatter;
}

/*
-(void)userDefaultDateCount
{
    NSMutableArray *userDefaultDateArray = [[NSMutableArray alloc] init];
    NSDate *dateAfterAddingDay;
    NSString *dateSave;
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    userDefaultDateArray = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"Key"]];
    if (userDefaultDateArray.count == 0) {
        for (int i = 0; i <= 30; i++) {
            NSMutableDictionary *dictDate = [NSMutableDictionary dictionary];
            dateAfterAddingDay = [today dateByAddingTimeInterval:60*60*24*i];
            dateSave = [dateFormat stringFromDate:dateAfterAddingDay];
            [dictDate setObject:dateSave forKey:@"Date"];
            [dictDate setObject:@"UnUsed" forKey:@"Status"];
            [userDefaultDateArray addObject:dictDate];
            dictDate = nil;
        }
        
        [[NSUserDefaults standardUserDefaults] setObject:userDefaultDateArray forKey:@"Key"];
    }
    else
    {
        
        //NSLog(@"%@",[[userDefaultDateArray objectAtIndex:0] objectForKey:@"Date"]);
    }
    
}
 */
/*
-(void)checkingDateExp
{
    NSArray *dateArrayFilter;
    NSMutableArray *userDefaultDateArray = [[NSMutableArray alloc] init];
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    NSString *todayDate = [dateFormat stringFromDate:today];
    userDefaultDateArray = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"Key"]];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"Date CONTAINS[cd] %@",
                              todayDate];
    
    dateArrayFilter = [userDefaultDateArray filteredArrayUsingPredicate:predicate];
    
    if (dateArrayFilter.count > 0 && [[[dateArrayFilter objectAtIndex:0] objectForKey:@"Status"] isEqualToString:@"UnUsed"]) {
        
    }
    
}
*/
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
