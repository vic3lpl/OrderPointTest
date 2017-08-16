//
//  AppDelegate.h
//  IpadOrder
//
//  Created by IRS on 6/29/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MCManager.h"

typedef enum _SMPrinterType {
    SMPrinterTypeUnknown = 0,
    SMPrinterTypeDesktopPrinterStarLine,
    SMPrinterTypePortablePrinterStarLine,
    SMPrinterTypePortablePrinterESCPOS
} SMPrinterType;

typedef enum _SMPaperWidth {
    SMPaperTestPrint,
    SMPaperWidth2inch,
    SMPaperWidth3inch,
    SMPaperWidth3inchSO,
    SMKitchenSingleReceipt,
    SMPaperWidth4inch
} SMPaperWidth;

typedef enum _SMLanguage {
    SMLanguageEnglish,
    SMLanguageFrench,
    SMLanguagePortuguese,
    SMLanguageSpanish,
    SMLanguageRussian,
    SMLanguageJapanese,
    SMLanguageSimplifiedChinese,
    SMLanguageTraditionalChinese,
} SMLanguage;

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
    NSString *relinkUserId;
    
}

@property (strong, nonatomic) UIWindow *window;
@property(strong,nonatomic)UIViewController *viewController;
@property (nonatomic, strong) MCManager *mcManager;

+ (SMPrinterType)parsePortSettings:(NSString *)portSettings;

+ (NSString *)getPortName;
+ (void)setPortName:(NSString *)m_portName;
+ (NSString*)getPortSettings;
+ (void)setPortSettings:(NSString *)m_portSettings;

@end

