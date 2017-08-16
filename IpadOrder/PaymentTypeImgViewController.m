//
//  PaymentTypeImgViewController.m
//  IpadOrder
//
//  Created by IRS on 29/11/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import "PaymentTypeImgViewController.h"

@interface PaymentTypeImgViewController ()

@end

@implementation PaymentTypeImgViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.preferredContentSize = CGSizeMake(300, 300);
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)btnSelectPaymentTypeImg:(id)sender {
    UIButton *button = (UIButton *)sender;
    NSString *name;
    if (_delegate != nil) {
        
        if (button.tag == 1) {
            name = @"Cash";
        }
        else if (button.tag == 2)
        {
            name = @"Master";
        }
        else if (button.tag == 3)
        {
            name = @"Visa";
        }
        else if (button.tag == 4)
        {
            name = @"Amex";
        }
        else if (button.tag == 5)
        {
            name = @"Diner";
        }
        else if (button.tag == 6)
        {
            name = @"Debit";
        }
        else if (button.tag == 7)
        {
            name = @"UnionPay";
        }
        else if (button.tag == 8)
        {
            name = @"Voucher";
        }
        else if (button.tag == 9)
        {
            name = @"Other1";
        }
        else if (button.tag == 10)
        {
            name = @"Other2";
        }
        else if (button.tag == 11)
        {
            name = @"Other3";
        }
        else if (button.tag == 12)
        {
            name = @"Other4";
        }
        
        [_delegate getSelectedPaymentTypeImgNameWithImgName:name];
        
        //[self dismissViewControllerAnimated:YES completion:nil];
    }
    
}
@end
