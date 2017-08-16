//
//  PaymentTypeEditViewController.h
//  IpadOrder
//
//  Created by IRS on 24/11/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PaymentTypeImgViewController.h"

@interface PaymentTypeEditViewController : UIViewController<PaymentTypeImgDelegate>

@property (weak, nonatomic) IBOutlet UITextField *textPaymentTypeCode;
@property (weak, nonatomic) IBOutlet UITextField *textPaymentTypeDescription;
@property (weak, nonatomic) IBOutlet UISwitch *switchPaymentTypeSelected;
@property (nonatomic, weak) NSString *editPaymentTypeAction;
@property (nonatomic, weak) NSString *editPaymentTypeCode;
@property (weak, nonatomic) IBOutlet UISwitch *switchExchange;
@property (weak, nonatomic) IBOutlet UIImageView *imgPaymentType;

@end
