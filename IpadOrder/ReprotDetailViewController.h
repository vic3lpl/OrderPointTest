//
//  ReprotDetailViewController.h
//  IpadOrder
//
//  Created by IRS on 9/9/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DatePickerViewController.h"
#import "BaseDetailViewController.h"

@interface ReprotDetailViewController : BaseDetailViewController <UITextFieldDelegate,DatePickerDelegate>

//@property (nonatomic, retain) UIPopoverController *popoverController;
@property (nonatomic,retain) id detailStruct;
@property (strong, nonatomic) IBOutlet UITextField *textInvoiceDateFrom;
@property (strong, nonatomic) IBOutlet UITextField *textInvoiceDateTo;
- (IBAction)btnSearchInvListing:(id)sender;
@property (weak, nonatomic) IBOutlet UIView *viewRptInvListingBg;

@end
