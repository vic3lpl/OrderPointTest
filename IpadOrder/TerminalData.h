//
//  TerminalData.h
//  IpadOrder
//
//  Created by IRS on 28/01/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FMDB.h>

@interface TerminalData : NSObject

@property (nonatomic, strong) NSString *splitSONo;

+(BOOL)insertSalesOrderIntoMainWithOrderType:(NSString *)orderType sqlitePath:(NSString *)dbPath OrderData:(NSArray *)orderFinalArray OrderDate:(NSString *)date terminalArray:(NSArray *)terminalArray terminalName:(NSString *)terminalName PayType:(NSString *)payType;

+(BOOL)updateSalesOrderIntoMainWithOrderType:(NSString *)orderType sqlitePath:(NSString *)dbPath OrderData:(NSArray *)orderFinalArray OrderDate:(NSString *)date DocNo:(NSString *)docNo terminalArray:(NSArray *)terminalArray terminalName:(NSString *)terminalName ToWhichView:(NSString *)toView PayType:(NSString *)payType OptionSelected:(NSString *)optionSelected FromSalesOrderNo:(NSString *)fromSalesOrderNo ;

+(BOOL)insertInvoiceIntoMainWithSqlitePath:(NSString *)dbPath InvData:(NSArray *)invData InvDate:(NSString *)date terminalArray:(NSArray *)terminalArray TerminalName:(NSString *)terminalName;

+(BOOL)insertSplitSalesOrderIntoMainWithSqlitePath:(NSString *)dbPath SplitData:(NSArray *)splitData SplitDate:(NSString *)date terminalArray:(NSArray *)terminalArray TerminalName:(NSString *)temrinalName;

+(NSString *)asterixRequestServerToPrintTerminalReqWithSONo:(NSString *)soNo PortName:(NSString *)portName;

+(NSString *)asterixRequestServerToPrintTerminalReqWithCSNo:(NSString *)csNo PortName:(NSString *)portName;

+(NSString *)startRasterRequestServerToPrintTerminalReqWithSONo:(NSString *)soNo PortName:(NSString *)portName PrinterSetting:(NSString *)printerSetting EnableGst:(int)enableGst;

+(NSString *)startRasterRequestServerToPrintTerminalReqWithCSNo:(NSString *)csNo PortName:(NSString *)portName PrinterSetting:(NSString *)printerSetting EnableGst:(int)enableGst;

+(NSString *)startLineRequestServerToPrintTerminalReqWithSONo:(NSString *)soNo PortName:(NSString *)portName PrinterSetting:(NSString *)printerSetting EnableGst:(int)enableGst;

+(NSString *)startLineRequestServerToPrintTerminalReqWithCSNo:(NSString *)csNo PortName:(NSString *)portName PrinterSetting:(NSString *)printerSetting EnableGst:(int)enableGst;

+(void)flyTechRequestCSDataWithCSNo:(NSString *)csNo;

+(void)flyTechRequestSODataWithSONo:(NSString *)soNo;

+(NSString *)xinYeRequestServerToPrintTerminalReqWithReceiptArray:(NSMutableArray *)array;


@end
