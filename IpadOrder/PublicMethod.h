//
//  PublicMethod.h
//  IpadOrder
//
//  Created by IRS on 28/09/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LibraryAPI.h"
#import "AppDelegate.h"
#import "ePOS-Print.h"
#import <AFNetworking/AFNetworking.h>

@interface PublicMethod : NSObject

+(void)settingServiceTaxPercentWithOverRide:(NSString *)overRide Percent:(NSString *)tbServicePercent;

+(void)printAsterixKitchenReceiptWithItemDesc:(NSString *)imDesc IPAdd:(NSString *)ipAdd imQty:(NSString *)imQty TableName:(NSString *)tableName DataArray:(NSArray *)dataArray;
+(void)printAsterixSalesOrderWithIpAdd:(NSString *)ipAdd CompanyArray:(NSMutableArray *)compArray SalesOrderArray:(NSMutableArray *)soArray;

+(void)printAsterixReceiptWithIpAdd:(NSString *)ipAdd CompanyArray:(NSMutableArray *)compArray CSArray:(NSMutableArray *)csArray;

+(NSMutableString *)makeKitchenGroupReceiptFormatWithItemDesc:(NSString *)desc ItemQty:(NSString *)qty PackageName:(NSString *)packageName ShowPackageDetail:(NSUInteger)showPackageDetail PrinterBrand:(NSString *)printerBrand;

+(void)printAsterixKRGroupWithIpAdd:(NSString *)ipAdd TableName:(NSString *)tbName Data:(NSMutableString *)data;

+(void)printAsterixKitchenReceiptWithKitchenData:(NSMutableArray *)kitchenData;
+(void)printAsterixKitchenReceiptGroupFormatKitchenData:(NSMutableArray *)kitchenData;

+(NSArray *)manuallyConvertAccReturnJsonWithData:(NSData *)data;

+(void)removeExistingFileFromDirectoryWithFileName:(NSString *)fileName;

+(NSString *)processChineseOrEnglishCharWithDetail1:(NSString *)detail1 ItemDesc:(NSString *)itemDesc FixLength:(NSUInteger) fixLength;

+(NSMutableArray *)softingOrderCondimentWithEditedCondimentDtl:(NSMutableArray *)array DisplayFormat:(NSString *)displayFormat TotalCondimentPrice:(double)totalCondimentPrice ParentIndex:(NSString *)parentIndex CondimentUnitPrice:(double)condimentUnitPrice OriginalArray:(NSMutableArray *)orgArray FromView:(NSString *)fromView KeyName:(NSString *)keyName;

+(UIViewController *) getTopViewController;

@end
