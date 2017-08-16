//
//  EposPrintFunction.h
//  IpadOrder
//
//  Created by IRS on 10/23/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ePOS-Print.h"
#import "Result.h"
#import "MsgMaker.h"
#import "AppUtility.h"
#import "PosCommand.h"
//#import "LibraryAPI.h"

@interface EposPrintFunction : NSObject

+ (int) getCompress:(int)connection;

+ (void)print:(EposBuilder *)builder Result:(Result *)result PortName:(NSString *)portName;

+ (NSString *)displayMsg:(Result *)result;

+(BOOL)isPrintable:(Result *)result;

+ (EposBuilder *)createKitchenReceiptFormat:(Result *)result TableNo:(NSString *)tableNo ItemNo:(NSString *)itemName Qty:(NSString *)qty DataArray:(NSArray *)dataArray;

+ (EposBuilder *)createReceiptData:(Result *)result ComapnyArray:(NSMutableArray *)compArray CSArray:(NSMutableArray *)receiptArray EnableGst:(int)enableGST KickOutDrawerYN:(NSString *)kickOutDraweYN;

+ (EposBuilder *)createSalesOrderRceiptData:(Result *)result ComapnyArray:(NSMutableArray *)compArray SalesOrderArray:(NSMutableArray *)receiptArray EnableGst:(int)enableGST;

+ (EposBuilder *)createDailyCollectionData:(Result *)result DBPath:(NSString *)dbPath DateFrom:(NSString *)dateFrom DateTo:(NSString *)dateTo;

+ (EposBuilder *)createKitchenReceiptGroupFormat:(Result *)result OrderDetail:(NSMutableString *)orderDetail TableName:(NSString *)tableCode;

+(EposBuilder *)stepOpenCashDrawer;
+(void)runPrintKicthenSequence:(int)indexNo IPAdd:(NSString *)ipAdd;

//--------- flytech -----------------
+(void)createFlyTechReceiptWithCompanyArray:(NSMutableArray *)compArray ReceiptArray:(NSMutableArray *)receiptArray EnableGst:(int)enableGST KickOutDrawerYN:(NSString *)kickOutDraweYN PrintOption:(NSMutableArray *)printOption PrintType:(NSString *)printType;

+(void)createFlyTechKitchenReceiptWithDBPath:(NSString *)dbPath TableNo:(NSString *)tableNo ItemNo:(NSString *)itemName Qty:(NSString *)qty DataArray:(NSMutableArray *)array;

+ (void)createFlyTechKitReceiptGroupWithOrderDetail:(NSMutableString *)orderDetail TableName:(NSString *)tableName;

+(void)createFlyTechSalesOrderReceiptWithComapnyArray:(NSMutableArray *)compArray SalesOrderArray:(NSMutableArray *)receiptArray EnableGst:(int)enableGST;

+(void)terminalCreateFlyTechSalesOrderRceiptWithDBPath:(NSString *)dbPath soArray:(NSMutableArray *)orderDetail EnableGst:(int)enableGST;

+(NSMutableData *)createDailyCollectionWithDbPath:(NSString *)dbPath DateFrom:(NSString *)dateFrom DateTo:(NSString *)dateTo PrinterBrand:(NSString *)printerBrand;

//------- xinye ---------------
+(NSMutableData *)generateReceiptFormatWithDBPath:(NSString *)dbPath GetInvNo:(NSString *)getInvNo EnableGst:(int)enableGST KickOutDrawerYN:(NSString *)kickOutDraweYN PrinterBrand:(NSString *)printerBrand ReceiptLength:(int)receiptLength DataArray:(NSMutableArray *)array;

+(NSMutableData *)generateReceiptFormatWithComapnyArray:(NSMutableArray *)compArray ReceiptArray:(NSMutableArray *)receiptArray EnableGst:(int)enableGST KickOutDrawerYN:(NSString *)kickOutDraweYN PrinterBrand:(NSString *)printerBrand ReceiptLength:(int)receiptLength GstArray:(NSMutableArray *)gstArray PrintOptionArray:(NSMutableArray *)printOptionArray PrintType:(NSString *)printType;

+(NSMutableData *)generateSalesOrderReceiptFormatWithComapnyArray:(NSMutableArray *)compArray SalesOrderArray:(NSMutableArray *)receiptArray EnableGst:(int)enableGST PrinterBrand:(NSString *)printerBrand ReceiptLength:(int)receiptLength;

+(NSMutableData *)xinYeReceiptPrintOutWithHeader:(NSString *)header Middle:(NSString *)middle FooterP1:(NSString *)footerP1 FooterP2:(NSString *)footerP2 FooterP3:(NSString *)footerP3 KickOutDrawerYN:(NSString *)kickOutDraweYN ReceiptTitle:(NSString *)receiptTitle ReceiptNo:(NSString *)receiptNo;

+(NSMutableData *)xinYeSalesOrderReceiptWithHeader:(NSString *)header Middle:(NSString *)middle FooterP1:(NSString *)footerP1 FooterP2:(NSString *)footerP2 FooterP3:(NSString *)footerP3 KickOutDrawerYN:(NSString *)kickOutDraweYN;

+(NSMutableData *)createXinYeKitchenReceiptWithDBPath:(NSString *)dbPath TableNo:(NSString *)tableNo ItemNo:(NSString *)itemName Qty:(NSString *)qty DataArray:(NSMutableArray *)dataArray PackageName:(NSString *)packageName ShowPackageDetail:(NSUInteger)showPackageDetail;

+(NSMutableData *)createXinYeKitReceiptGroupWithOrderDetail:(NSMutableArray *)orderDetail TableName:(NSString *)tableCode;

+(NSMutableData *)createXinYeKitReceiptGroupWithTableName:(NSString *)tableName ItemName:(NSString *)itemName Qty:(NSString *)qty;

+(NSMutableData *)createXinYeKitchenNoticeWithMsg:(NSString *)msg;

+ (EposBuilder *)createKitchenReceiptFormatDataArray:(NSArray *)dataArray Result:(Result *)result;
@end
