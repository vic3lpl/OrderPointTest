//
//  DatePickerViewController.m
//  IpadOrder
//
//  Created by IRS on 9/10/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "DatePickerViewController.h"

@interface DatePickerViewController ()

@end

@implementation DatePickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.preferredContentSize = CGSizeMake(260, 277);
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

- (IBAction)btnSelectInvoiceDate:(id)sender {
    if (_delegate != nil) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"dd/MMM/yyyy"];
        NSString *strDate = [dateFormatter stringFromDate:self.dateInv.date];
        [_delegate getDatePickerDateValue:strDate returnTextName:_textType];
        
    }
}
@end
