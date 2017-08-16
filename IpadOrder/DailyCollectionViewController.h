//
//  DailyCollectionViewController.h
//  IpadOrder
//
//  Created by IRS on 10/27/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseDetailViewController.h"
#import "DatePickerViewController.h"
#import "PosCommand.h"
#import "TscCommand.h"
#import "ImageTranster.h"
#import "XYSDK.h"

@interface DailyCollectionViewController : BaseDetailViewController <UITextFieldDelegate,DatePickerDelegate,XYWIFIManagerDelegate>
@property (strong, nonatomic) IBOutlet UITextField *textDailyDateFrom;
@property (strong, nonatomic) IBOutlet UITextField *textDailyDateTo;
- (IBAction)btnDailySearch:(id)sender;
@property (weak, nonatomic) IBOutlet UIView *viewRptDailyCollectionBg;
@property (nonatomic, strong) XYWIFIManager *wifiManager;
@end
