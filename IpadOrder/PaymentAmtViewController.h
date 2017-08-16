//
//  PaymentAmtViewController.h
//  IpadOrder
//
//  Created by IRS on 8/20/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NumericKeypadDelegate.h"

@interface PaymentAmtViewController : UIViewController <NumericKeypadDelegate>


@property (strong, nonatomic) IBOutlet NumericKeypadTextField *textPaymentAmt;
@property (strong, nonatomic) IBOutlet UILabel *labelAmountDue;

- (IBAction)btnOne:(id)sender;
- (IBAction)btnPaymentAmtViewBack:(id)sender;
- (IBAction)btnFive:(id)sender;

- (IBAction)btnTen:(id)sender;
- (IBAction)btnTwenty:(id)sender;

- (IBAction)btnFity:(id)sender;

- (IBAction)btnHundred:(id)sender;

@end
