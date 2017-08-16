//
//  PrintOptionViewController.h
//  IpadOrder
//
//  Created by IRS on 07/12/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseDetailViewController.h"

@interface PrintOptionViewController : BaseDetailViewController<UITextFieldDelegate,UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UITextView *textReceiptFooter;
@property (weak, nonatomic) IBOutlet UITextField *textReceiptHeader;
@property (weak, nonatomic) IBOutlet UISwitch *switchCustInfo;
@property (weak, nonatomic) IBOutlet UISwitch *switchPaymentMode;
@property (weak, nonatomic) IBOutlet UISwitch *switchGstSummary;
@property (weak, nonatomic) IBOutlet UISwitch *switchCompanyTelNo;
@property (weak, nonatomic) IBOutlet UISwitch *switchDiscount;
@property (weak, nonatomic) IBOutlet UISwitch *switchServiceCharge;
@property (weak, nonatomic) IBOutlet UISwitch *switchSubTotalIncGst;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentReceiptContent;
@property (weak, nonatomic) IBOutlet UITextView *textViewReceiptFormat;
- (IBAction)clickSegmentReceiptContent:(id)sender;
//@property (weak, nonatomic) IBOutlet UILabel *labelReceiptFormat;
@property (weak, nonatomic) IBOutlet UISwitch *switchItemDesc2;
@property (weak, nonatomic) IBOutlet UISwitch *switchPackageItemDtl;

@end
