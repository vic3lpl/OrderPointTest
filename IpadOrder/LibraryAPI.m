//
//  LibraryAPI.m
//  BlueLibrary
//
//  Created by IRS on 8/2/14.
//  Copyright (c) 2014 Eli Ganem. All rights reserved.
//

#import "LibraryAPI.h"
#import <FMDB.h>

//#import "HTTPClient.h"

// provate variable
@interface LibraryAPI () {
    
    BOOL isOnline;
    int valueS;
    float myCurrentLat;
    float myCurrentLng;
    NSString *imNo;
    NSString *dbPath;
    NSInteger tableID;
    NSString *tax_Type;
    NSString *doc_No;
    double serviceGstPercent;
    NSString * serviceTaxPercent;
    int enableGst;
    int enableSVG;
    int enableKiosk;
    
    BOOL isLinkDropBox;
    FMDatabase *dbTable;
    //NSMutableArray *order_DetailArray;
    // kitchen receipt
    int kitchenReceiptGroup;
    int userRole;
    NSString *currency;
    NSString *myIpAddress;
    
    NSString *tRefresh;
    NSString *tWorkMode;
    
    NSString *tMTMode;
    NSArray *tServerReturnSODtlArray;
    
    NSArray *tSplitBillSalesOrderNoArray;
    NSString *userName;
    NSString *appStatus;
    NSString *pbrand;
    NSString *pPortName;
    NSString *pUUID;
    NSString *terminalDeviceName;
    NSString *tbName;
    NSString *tablePaxNo;
    NSString *openOptionViewName;
    NSString *serviceTaxGstCode;
    NSString *appApiVersion;
    
    NSUInteger showPackageDetail;
}

@end

@implementation LibraryAPI
+(LibraryAPI *)sharedInstance
{
    //1
    static LibraryAPI *_sharedInstance = nil;
    
    //2
    static dispatch_once_t oncePredicate;
    
    //3
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[LibraryAPI alloc] init];
        _sharedInstance.order_DetailArray = [[NSMutableArray alloc]init];
        _sharedInstance.dCData = [NSMutableData data];
        _sharedInstance.cashSalesDetailArray = [[NSMutableArray alloc] init];
        _sharedInstance.asterixPrinterArray = [[NSMutableArray alloc] init];
        
    });
    
    return _sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        
        
    }
    return self;
}

-(void)setAppStatus:(NSString *)status
{
    appStatus = status;
}

-(NSString *)getAppStatus
{
    return appStatus;
}

-(void)setUserRole:(int)uRole
{
    userRole = uRole;
}

-(int)getUserRole
{
    return userRole;
}

-(void)setUserName:(NSString *)uName
{
    userName = uName;
}

-(NSString *)getUserName
{
    return userName;
}

//----------------------------------
-(void)setInteger:(int)zCount
{
    valueS = zCount;
}

-(int)getInteger
{
    return valueS;//[persistencyManager getInt];
}

-(void)setItemMastNo:(NSString *)imKey
{
    imNo = imKey;
}

-(NSString *)getItemMastNo
{
    return imNo;
}
//---------- dbpath  ------------
-(void)setDbPath:(NSString *)path
{
    dbPath = path;
}

-(NSString *)getDbPath
{
    return dbPath;
}

//------- table no -----------
-(void)setTableNo:(NSInteger)tableNo
{
    tableID = tableNo;
}

-(NSInteger)getTableNo
{
    return tableID;
}

-(void)setTableName:(NSString *)tableName
{
    tbName = tableName;
}

-(NSString *)getTableName
{
    return tbName;
}

//------- enable gst---------
-(void)setEnableGst:(int)gst
{
    enableGst = gst;
}

-(int)getEnableGst
{
    return enableGst;
}

//------- tax type ----------
-(void)setTaxType:(NSString *)taxType
{
    tax_Type = taxType;
}
-(NSString *)getTaxType
{
    return tax_Type;
}

//----------doc no---------------
-(void)setDocNo:(NSString *)docNo
{
    doc_No = docNo;
}

-(NSString *)getDocNo
{
    return doc_No;
}

//------- order array --------
-(void)setEditOrderDetail:(NSMutableArray *)orderDetailArray
{
    [_order_DetailArray removeAllObjects];
    [_order_DetailArray addObject:orderDetailArray];
}
-(NSMutableArray *)getEditOrderDetailArray
{
    return _order_DetailArray;
}

//-------direct bill array -------------------
-(void)setDirectOrderDetail:(NSMutableArray *)directDetailArray
{
    [_order_DetailArray removeAllObjects];
    [_order_DetailArray addObjectsFromArray:directDetailArray];
}

-(NSMutableArray *)getDirectOrderDetailArray
{
    return _order_DetailArray;
}

//-----------pay order detail --------------
-(void)setPayOrderDetail:(NSMutableArray *)payOrderDetail
{
    [_order_DetailArray removeAllObjects];
    [_order_DetailArray addObjectsFromArray:payOrderDetail];
}

-(NSMutableArray *)getPayOrderDetailArray
{
    return _order_DetailArray;
}

//--------check dropbox ------------
-(void)setLinkToDropBox:(BOOL)linkToDropBox
{
    isLinkDropBox = linkToDropBox;
}

-(BOOL)getLinkToDropBox
{
    return isLinkDropBox;
}

//------------Service Tax Part-------------------

-(void)setEnableSVG:(int)svg
{
    enableSVG = svg;
}

-(int)getEnableSVG
{
    return enableSVG;
}

-(void)setServiceTaxGstPercent:(double)gstPercent
{
    serviceGstPercent = gstPercent;
}

-(double)getServiceTaxGstPercent
{
    return serviceGstPercent;
}

-(void)setServiceTaxPercent:(NSString *)Percent
{
    serviceTaxPercent = Percent;
}

-(NSString *)getServiceTaxPercent
{
    return serviceTaxPercent;
}

-(void)setServiceTaxGstCode:(NSString *)code
{
    serviceTaxGstCode = code;
}

-(NSString *)getServiceTaxGstCode
{
    return serviceTaxGstCode;
}
//---------kitchen receipt group------------
-(void)setKitchenReceiptGroup:(int)receiptGroup
{
    kitchenReceiptGroup = receiptGroup;
}

-(int)getKitchenReceiptGrouping
{
    return  kitchenReceiptGroup;
}

//---------enable kiosk mode --------------
-(void)setKioskMode:(int)kioskMode
{
    enableKiosk = kioskMode;
}

-(int)getKioskMode
{
    return enableKiosk;
}

//-------- currency display --------------
-(void)setCurrencySymbol:(NSString *)cSymbol
{
    currency = cSymbol;
}

-(NSString *)getCurrencySymbol
{
    return currency;
}

//--------------ip address---------------
-(void)setIpAddress:(NSString *)ipAddress
{
    myIpAddress = ipAddress;
}

-(NSString *)getIpAddress
{
    return myIpAddress;
}

//-----------workmode refresh-------------------
-(void)setRefreshTB:(NSString *)workMode
{
    tRefresh = workMode;
}

-(NSString *)getRefreshTB
{
    return tRefresh;
}

//------------ workmode-------------------
-(void)setWorkMode:(NSString *)workMode
{
    tWorkMode = workMode;
}

-(NSString *)getWorkMode
{
    return tWorkMode;
}

//--------------multiple terminal mode-------------
-(void)setMultipleTerminalMode:(NSString *)mtMode
{
    tMTMode = mtMode;
}

-(NSString *)getMultipleTerminalMode
{
    return tMTMode;
}

// server return SO Dtl
-(void)setServerReturnSOStl:(NSArray *)soDtlArray
{
    tServerReturnSODtlArray = soDtlArray;
}

-(NSArray *)getServerReturnSODtl
{
    return tServerReturnSODtlArray;
}

//-------------- server return splitbill sales order no to terminal -----------
-(void)setTerminalSplitBillSalesOrderNoInArray:(NSArray *)soNo
{
    tSplitBillSalesOrderNoArray = soNo;
}

-(NSArray *)getTerminalSplitBillSalesOrderNoInArray
{
    return tSplitBillSalesOrderNoArray;
}

//-------------printer------------------
-(void)setPrinterBand:(NSString *)brand
{
    pbrand = brand;
}

-(NSString *)getPrinterBrand
{
    return pbrand;
}

-(void)setPrinterPortName:(NSString *)portName
{
    pPortName = portName;
}

-(NSString *)getPrinterPortName
{
    return pPortName;
}

-(void)setPrinterUUID:(NSString *)uuid
{
    pUUID = uuid;
}

-(NSString *)getPrinterUUID
{
    return pUUID;
}

-(void)setDailyCollectionData:(NSMutableData *)data
{
    _dCData = data;
}

-(NSMutableData *)getDailyCollectionData
{
    return _dCData;
}

//--------------------------------------------
-(void)setTerminalDeviceName:(NSString *)deviceName
{
    terminalDeviceName = deviceName;
}

-(NSString *)getTerminalDeviceName
{
    return terminalDeviceName;
}

//---------------------------------------------
-(void)setEditCashSalesDetail:(NSMutableArray *)editCashSalesDetail
{
    _cashSalesDetailArray = editCashSalesDetail;
}

-(NSMutableArray *)getEditCashSalesDetailArray
{
    return _cashSalesDetailArray;
}

-(void)removeCashSalesArray
{
    [_cashSalesDetailArray removeAllObjects];
}
//---------------------------------------------

-(void)setOpenOptionViewName:(NSString *)viewName
{
    openOptionViewName = viewName;
}

-(NSString *)getOpenOptionViewName
{
    return openOptionViewName;
}

//---------------------------------------------

-(void)setEditAsterixPrinterArray:(NSMutableArray *)printerArray
{
    NSMutableArray *test;
    test = [[NSMutableArray alloc] init];
    
    [test addObjectsFromArray:printerArray];
    
    [_asterixPrinterArray addObjectsFromArray:printerArray];
}

-(NSMutableArray *)getAsterixPrinterArray
{
    return _asterixPrinterArray;
}

//-------------------------------------------------
-(void)setAppApiVersion:(NSString *)version
{
    appApiVersion = version;
}

-(NSString *)getAppApiVersion
{
    return appApiVersion;
}

//------------kitchen receipt setting---------------
-(void)setShowPackageDetail:(NSUInteger)index
{
    showPackageDetail = index;
}

-(NSUInteger)getShowPackageDetail
{
    return showPackageDetail;
}

/*
-(void)setTablePaxNo:(NSString *)paxNo
{
    tablePaxNo = paxNo;
}

-(NSString *)getTablePaxNo
{
    return tablePaxNo;
}
 */
//--------------date formater ---------------
-(NSDateFormatter *)getDateFormaterhhmmss
{
    static NSDateFormatter *formatterhhmmss;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatterhhmmss = [[NSDateFormatter alloc] init];
        formatterhhmmss.dateFormat = @"yyyy-MM-dd HH:mm:ss"; // twitter date format
    });
    return formatterhhmmss;
}

-(NSDateFormatter *)getDateFormateryyyymmdd
{
    static NSDateFormatter *formatteryyyymmdd;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatteryyyymmdd = [[NSDateFormatter alloc] init];
        formatteryyyymmdd.dateFormat = @"yyyy-MM-dd HH:mm:ss"; // twitter date format
    });
    return formatteryyyymmdd;
}

-(NSDateFormatter *)getDateFormaterhh_mm
{
    static NSDateFormatter *formatterhhmmss;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatterhhmmss = [[NSDateFormatter alloc] init];
        formatterhhmmss.dateFormat = @"yyyy-MM-dd hh-mm-ss"; // twitter date format
    });
    return formatterhhmmss;
}

//-------------rounding-----------------
-(NSString *)getCalcRounding:(NSString *)labelTotal DatabasePath:(NSString *)dbPath2
{
    NSString *strDollar;
    NSString *strCent;
    NSString *lastDigit;
    NSString *secondLastDigit;
    NSString *finalCent;
    
    NSString *final;
    NSString *sqlCommand;
    
    lastDigit = [labelTotal substringFromIndex:[labelTotal length] - 1];
    strCent = [NSString stringWithFormat:@"0.%@",[labelTotal substringFromIndex:[labelTotal length] - 2]];
    secondLastDigit = [labelTotal substringWithRange:NSMakeRange([labelTotal length] - 2, 1)];
    NSLog(@"rounding %@",lastDigit);
    
    if ([lastDigit isEqualToString:@"0"]) {
        finalCent = [NSString stringWithFormat:@"0.%@0",secondLastDigit];
        final = labelTotal;
    }
    else
    {
        dbTable = [FMDatabase databaseWithPath:dbPath2];
        
        if (![dbTable open]) {
            NSLog(@"Fail To Open Database");
            return @"False";
        }
        
        sqlCommand = [NSString stringWithFormat:@"Select R%@ from Rounding",lastDigit];
        
        //secondLastDigit = [NSString stringWithFormat:@"0.%02d",100];
        
        strDollar = [labelTotal substringWithRange:NSMakeRange(0, [labelTotal length] - 3)];
        FMResultSet *rs = [dbTable executeQuery:sqlCommand];
        
        if ([rs next]) {
            NSLog(@"%@",[rs stringForColumnIndex:0]);
            
            finalCent = [NSString stringWithFormat:@"0.%@0",secondLastDigit];
            finalCent = [NSString stringWithFormat:@"%f",[finalCent doubleValue] + [[NSString stringWithFormat:@"0.%02d",[rs intForColumnIndex:0]] doubleValue]];
            
            final = [NSString stringWithFormat:@"%0.2f",[strDollar doubleValue] + [finalCent doubleValue]];
        }
        [rs close];
        [dbTable close];
    }
    
    return finalCent;
}

- (UIAlertController *)showAlertViewWithtitlw:(NSString *)message Title:(NSString *)title
{
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }]];
    
    
    return alertController;
    
}

- (UIAlertController *)showAlertViewWithMsg:(NSString *)message Title:(NSString *)title
{
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }]];
    
    
    return alertController;
    
}

-(void)showAlertMessageBox
{
    UIAlertView *alter = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Printer disconnect" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: @"Cancel"];
    [alter show];
    //UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(errorAlert, animated: true, completion: nil)
}


@end
