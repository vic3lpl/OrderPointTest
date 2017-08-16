//
//  LibraryAPI.h
//  BlueLibrary
//
//  Created by IRS on 8/2/14.
//  Copyright (c) 2014 Eli Ganem. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface LibraryAPI : NSObject

+ (LibraryAPI*)sharedInstance;
@property (nonatomic,retain) NSMutableArray *order_DetailArray;
@property (nonatomic,retain) NSMutableData *dCData;
@property (nonatomic,retain) NSMutableArray *cashSalesDetailArray;
@property (nonatomic,retain) NSMutableArray *asterixPrinterArray;

// EXPOSE TO OTHER CLASS
-(NSString *)getAppStatus;
-(void)setAppStatus:(NSString *)status;

- (int)getUserRole;
-(void)setUserRole:(int)uRole;

- (NSString *)getUserName;
-(void)setUserName:(NSString *)uName;

- (int)getInteger;
-(void)setInteger:(int)zCount;

-(void)setItemMastNo:(NSString *)im_No;
-(NSString *)getItemMastNo;

-(void)setDbPath:(NSString *)path;
-(NSString *)getDbPath;

-(void)setTableNo:(NSInteger)tableNo;
-(NSInteger)getTableNo;

-(void)setTableName:(NSString *)tableName;
-(NSString *)getTableName;

-(void)setEnableGst:(int)gst;
-(int)getEnableGst;

-(void)setEnableSVG:(int)svg;
-(int)getEnableSVG;

-(void)setTaxType:(NSString *)taxType;
-(NSString *)getTaxType;

-(void)setServiceTaxGstPercent:(double)gstPercent;
-(double)getServiceTaxGstPercent;

-(void)setServiceTaxPercent:(NSString *)Percent;
-(NSString *)getServiceTaxPercent;

-(void)setDocNo:(NSString *)docNo;
-(NSString *)getDocNo;

-(void)setEditOrderDetail:(NSMutableArray *)orderDetailArray;
-(NSMutableArray *)getEditOrderDetailArray;

-(void)setDirectOrderDetail:(NSMutableArray *)directDetailArray;
-(NSMutableArray *)getDirectOrderDetailArray;

-(void)setPayOrderDetail:(NSMutableArray *)payOrderDetail;
-(NSMutableArray *)getPayOrderDetailArray;

-(BOOL)getLinkToDropBox;
-(void)setLinkToDropBox:(BOOL)linkToDropBox;

-(void)setKitchenReceiptGroup:(int)receiptGroup;
-(int)getKitchenReceiptGrouping;

-(void)setCurrencySymbol:(NSString *)cSymbol;
-(NSString *)getCurrencySymbol;

-(void)setIpAddress:(NSString *)ipAddress;
-(NSString *)getIpAddress;

-(void)setRefreshTB:(NSString *)workMode;
-(NSString *)getRefreshTB;

-(void)setWorkMode:(NSString *)workMode;
-(NSString *)getWorkMode;

-(void)setKioskMode:(int)kioskMode;
-(int)getKioskMode;

-(void)setMultipleTerminalMode:(NSString *)mtMode;
-(NSString *)getMultipleTerminalMode;

-(void)setServerReturnSOStl:(NSArray *)soDtlArray;
-(NSArray *)getServerReturnSODtl;

-(void)setTerminalSplitBillSalesOrderNoInArray:(NSArray *)soNo;
-(NSArray *)getTerminalSplitBillSalesOrderNoInArray;

-(void)setPrinterBand:(NSString *)brand;
-(NSString *)getPrinterBrand;

-(void)setPrinterPortName:(NSString *)portName;
-(NSString *)getPrinterPortName;

-(void)setPrinterUUID:(NSString *)uuid;
-(NSString *)getPrinterUUID;

-(void)setDailyCollectionData:(NSMutableData *)data;
-(NSMutableData *)getDailyCollectionData;

-(void)setEditCashSalesDetail:(NSMutableArray *)editCashSalesDetail;
-(NSMutableArray *)getEditCashSalesDetailArray;
-(void)removeCashSalesArray;

-(void)setOpenOptionViewName:(NSString *)viewName;
-(NSString *)getOpenOptionViewName;

-(void)setEditAsterixPrinterArray:(NSMutableArray *)printerArray;
-(NSMutableArray *)getAsterixPrinterArray;

-(void)setServiceTaxGstCode:(NSString *)code;
-(NSString *)getServiceTaxGstCode;

-(void)setAppApiVersion:(NSString *)version;
-(NSString *)getAppApiVersion;

-(void)setShowPackageDetail:(NSUInteger)index;
-(NSUInteger) getShowPackageDetail;

//-(void)setTablePaxNo:(NSString *)paxNo;
//-(NSString *)getTablePaxNo;

-(NSDateFormatter *)getDateFormaterhhmmss;
-(NSDateFormatter *)getDateFormateryyyymmdd;
-(NSDateFormatter *)getDateFormaterhh_mm;

-(NSString *)getCalcRounding:(NSString *)labelTotal DatabasePath:(NSString *)dbPath2;

-(void)setTerminalDeviceName:(NSString *)deviceName;
-(NSString *)getTerminalDeviceName;
- (UIAlertController *)showAlertViewWithTitlw:(NSString *)message Title:(NSString *)title;
- (UIAlertController *)showAlertViewWithMsg:(NSString *)message Title:(NSString *)title;
-(void)showAlertMessageBox;

@end
