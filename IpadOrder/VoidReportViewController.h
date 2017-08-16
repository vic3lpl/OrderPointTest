//
//  VoidReportViewController.h
//  IpadOrder
//
//  Created by IRS on 11/05/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseDetailViewController.h"
#import "DatePickerViewController.h"

@interface VoidReportViewController : BaseDetailViewController<UITextFieldDelegate,DatePickerDelegate>
@property (weak, nonatomic) IBOutlet UITextField *textVoidReportDateFrom;
@property (weak, nonatomic) IBOutlet UITextField *textVoidReportDateTo;
@property (strong, nonatomic) IBOutlet UIView *viewVoidReport;
- (IBAction)btnVoidReportSearch:(id)sender;

@end
