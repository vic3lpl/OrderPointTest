//
//  ChangeAmtViewController.h
//  IpadOrder
//
//  Created by IRS on 11/24/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PosCommand.h"
#import "TscCommand.h"
#import "ImageTranster.h"
#import "XYSDK.h"
#import "EposPrintFunction.h"

@protocol ChangeAmtDelegate <NSObject>
@required
-(void)CloseFinalChangeAmt;

@end

@interface ChangeAmtViewController : UIViewController<XYWIFIManagerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *labelFinalChangeAmt;
- (IBAction)btnDone:(id)sender;
@property (nonatomic,weak) id<ChangeAmtDelegate>delegate;
@property NSString *changeAmt;
@property (nonatomic, strong) XYWIFIManager *wifiManager;
@property NSString *tableName;
@property NSString *printerBrand;
@property NSString *csNo;
@property NSString *receiptPrinterIpAdd;

@end
