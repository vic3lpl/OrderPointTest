//
//  XReadingViewController.h
//  IpadOrder
//
//  Created by IRS on 9/14/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseDetailViewController.h"
#import "DatePickerViewController.h"

@interface XReadingViewController : BaseDetailViewController <UITextFieldDelegate,DatePickerDelegate>
@property (strong, nonatomic) IBOutlet UITextField *textXReadingDateFrom;
@property (strong, nonatomic) IBOutlet UITextField *textXReadingDateTo;
- (IBAction)btnXReadingSearch:(id)sender;
@property (weak, nonatomic) IBOutlet UIView *viewRptXReadBg;

@end
