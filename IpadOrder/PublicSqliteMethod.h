//
//  PublicSqliteMethod.h
//  IpadOrder
//
//  Created by IRS on 31/03/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FMDB.h>
#import "PosCommand.h"
#import "TscCommand.h"
#import "ImageTranster.h"
#import "XYSDK.h"

@interface PublicSqliteMethod : NSObject
+(BOOL)updateWebApiRegitration;

+(NSMutableArray *)checkCompanyProfileWithDbPath:(NSString *)dbPath;

+(NSString *)insertIntoCompanyTableWithDataArray:(NSArray *)compArray;

+(NSString *)updateIntoCompanyTableWithDataArray:(NSArray *)compArray;

+(NSMutableDictionary *)getGeneralnTableSettingWithTableName:(NSString *)tbName dbPath:(NSString *)dbPath;

+(NSMutableArray *)calcGSTWithDbPath:(NSString *)dbPath SoDocNo:(NSString *)soNo CompEnableGst:(int)compEnableGst CompEnableSVG:(int)compEnableSVG TaxType:(NSString *)taxType OrderDataStatus:(NSString *)orderDataStatus TableName:(NSString *)tableName TableDineType:(int)tableDineStatus TableSVC:(double)tableSVC OverrideSVG:(NSString *)overRideSVG TerminalType:(NSString *)terminalType;

+(NSArray *)recalculateGSTSalesOrderWithSalesOrderArray:(NSMutableArray *)salesOrderArray TaxType:(NSString *)taxType;

+(BOOL)updateAppRegistrationTableWithLicenseID:(NSString *)licenseID ProductKey:(NSString *)productKey DeviceStatus:(NSString *)deviceStatus PurchaseID:(NSString *)purchaseID TerminalQty:(NSString *)qty DBPath:(NSString *)dbPath RequestExpDate:(NSString *)resExpDate RequestAction:(NSString *)action;

+(BOOL)updateAppRegistrationTableWhenAddTerminalWithLicenseID:(NSString *)licenseID ProductKey:(NSString *)productKey DeviceStatus:(NSString *)deviceStatus TerminalQty:(NSString *)qty DBPath:(NSString *)dbPath RequestAction:(NSString *)action;

+(BOOL)updateAppRegistrationTableWhenDemoWithTerminalQty:(NSString *)qty DBPath:(NSString *)dbPath;

+(NSMutableArray *)calcGSTByItemNo:(int)itemNo DBPath:(NSString *)dbPath ItemPrice:(NSString *)itemPrice CompEnableGst:(int)compEnableGst CompEnableSVG:(int)compEnableSVG TableSVC:(NSString *)tableSVC OverrideSVG:(NSString *)overRideSVG SalesOrderStatus:(NSString *)soStatus TaxType:(NSString *)taxType TableName:(NSString *)tableName ItemDineStatus:(NSString *)itemDineStatus TerminalType:(NSString *)terminalType SalesDict:(NSDictionary *)salesDict IMQty:(NSString *)imQty KitchenStatus:(NSString *)kitchenStatus PaxNo:(NSString *)paxNo DocType:(NSString *)docType CondimentSubTotal:(double)condimentSubtotal ServiceChargeGstPercent:(double)svgGstPercent TableDineStatus:(NSString *)tableDineStatus;

+(NSDictionary *)calclateSalesTotalWith:(NSMutableArray *)orderFinalArray TaxType:(NSString *)taxType ServiceTaxGst:(double)serviceTaxGst DBPath:(NSString *)dbPath;

+(NSMutableArray *)getAllItemPrinterIpAddWithDBPath:(NSString *)dbPath;

+(NSMutableArray *)getItemPrinterIpAddWithDBPath:(NSString *)dbPath IPAddress:(NSString *)ipAddress;

+(NSString *)generateSalesOrderDataArray;
+(NSString *)generateCSOrderDataArray;

+(NSMutableArray *)getSalesOrderCondimentWithDBPath:(NSString *)dbPath SalesOrderNo:(NSString *)docNo ItemCode:(NSString *)itemCode ManualID:(NSString *)manualID ParentIndex:(NSUInteger)parentIndex;

+(NSMutableArray *)getInvoiceCondimentWithDBPath:(NSString *)dbPath InvoiceNo:(NSString *)docNo ItemCode:(NSString *)itemCode ManualID:(NSString *)manualID ParentIndex:(NSUInteger)parentIndex;

+(NSMutableArray *)getAsterixSalesOrderDetailWithDBPath:(NSString *)dbPath SalesOrderNo:(NSString *)docNo;

+(NSMutableArray *)getAsterixCashSalesDetailWithDBPath:(NSString *)dbPath CashSalesNo:(NSString *)docNo ViewName:(NSString *)viewName;

+(double)doAdjustmentForTaxIncWithAdjTaxShort:(NSString *)adjTaxShort AdjTaxLong:(NSString *)adjTaxLong TaxType:(NSString *)taxType ServiceTaxGstAmt:(double)svcGstAmt; //used to adjust 0.01 sen for service charge

+(NSMutableArray *)getTransferSalesOrderDetailWithDbPath:(NSString *)dbPath SalesOrderNo:(NSString *)salesOrderNo;

+(NSMutableArray *)getAllTableListWithDbPath:(NSString *)dbPath FromTableName:(NSString *)fromTableName;

+(NSMutableArray *)getCombineTableListWithDbPath:(NSString *)dbPath FromTableName:(NSString *)fromTableName ;

+(NSMutableArray *)publicCombineTwoTableWithFromSalesOrder:(NSString *)fromSalesOrder ToSalesOrder:(NSString *)toSalesOrder DBPath:(NSString *)dbPath;

+(NSMutableArray *)recalculateSalesOrderResultWithFromSalesOrderNo:(NSString *)fromSalesOrderNo SelectedTbName:(NSString *)selectedTbName SelectedDineType:(int)dineType Date:(NSString *)todayDate ItemServeTypeFlag:(NSString *)itemServeTypeFlag OptionSelected:(NSString *)optionSelected ToSalesOrderNo:(NSString *)toSalesOrderNo DBPath:(NSString *)dbPath;

+(void)askForReprintKitchenReceiptWithDBPath:(NSString *)dbPath SalesOrderArray:(NSMutableArray *)soArray FromTable:(NSString *)fromTable ToTable:(NSString *)toTable SelectedOption:(NSString *)selectedOption;

+(NSMutableArray *)getParticularCombineTableListWithDbPath:(NSString *)dbPath TableName:(NSString *)TableName;

+(NSMutableArray *)getItemMastGroupingWithDbPath:(NSString *)dbPath Description:(NSString *)desc ModifierDetailArray:(NSMutableArray *)modifierDetailArray ViewName:(NSString *)viewName ItemServiceType:(NSString *)itemServiceType;

@end
