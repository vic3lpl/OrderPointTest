//
//  GeneralSettingViewController.h
//  IpadOrder
//
//  Created by IRS on 8/25/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseDetailViewController.h"
#import "SelectCatTableViewController.h"



@interface GeneralSettingViewController : BaseDetailViewController <UITextFieldDelegate,SelectCatDelegate>
{
    
}
@property (strong, nonatomic) IBOutlet UISwitch *switchTax;
//@property (strong, nonatomic) IBOutlet UISwitch *switchPrintMode;
@property (strong, nonatomic) IBOutlet UISwitch *switchServiceGst;
//@property (strong, nonatomic) UIPopoverController *popOver;
@property (strong, nonatomic) IBOutlet UITextField *textServiceGst;
- (IBAction)switchServiceGstAction:(id)sender;
@property (weak, nonatomic) IBOutlet UISwitch *switchKitchenReceiptGroup;
@property (weak, nonatomic) IBOutlet UITextField *textCurrency;
@property (weak, nonatomic) IBOutlet UIView *viewGeneralBg;
@property (weak, nonatomic) IBOutlet UISwitch *switchEnableGST;
@property (weak, nonatomic) IBOutlet UITextField *textDefaultGSTCode;
- (IBAction)switchActionEnableGST:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *textDefaultSVGCode;
@property (weak, nonatomic) IBOutlet UISwitch *switchEnableSVG;
- (IBAction)switchActionEnableSVG:(id)sender;
@property (weak, nonatomic) IBOutlet UISwitch *switchEnableKioskMode;
- (IBAction)switchActionEnableKioskMode:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *textKioskName;

@end
