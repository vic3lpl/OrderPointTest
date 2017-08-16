//
//  KeyNumericViewController.m
//  IpadOrder
//
//  Created by IRS on 8/26/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "KeyNumericViewController.h"
#import "NumPadTextField/NumericKeypadTextField.h"
#import "NumericKeypadViewController.h"
#import "LibraryAPI.h"

@interface KeyNumericViewController ()

@end

@implementation KeyNumericViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.preferredContentSize = CGSizeMake(212, 268);
    self.textNumeric.numericKeypadDelegate = self;
    [self.textNumeric becomeFirstResponder];
    bigBtn = @"Confirm";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillLayoutSubviews
{
    //[super viewWillLayoutSubviews];
    //self.view.superview.bounds = CGRectMake(0, 0, 212, 268);
    //[self getItemMast];
}

#pragma mark - custom keyboard delegate
-(void)saveActionFormTextField:(UITextField *)textField
{
    //[self calcAmount];
    if (_orgSOQty<[self.textNumeric.text integerValue]) {
        [self showAlertView:@"Qty separate more than order qty" title:@"Warning"];
        return;
    }
    else if ([self.textNumeric.text isEqualToString:@""])
    {
        [self showAlertView:@"Qty cannot empty" title:@"Warning"];
        return;
    }
    else if ([self.textNumeric.text doubleValue] == 0)
    {
        [self showAlertView:@"Qty cannot be zero" title:@"Warning"];
        return;
    }
    else if ([self.textNumeric.text containsString:@"."])
    {
        //[self showAlertView:@"Qty Must Be Integer" title:@"Warning"];
        //return;
    }
    else if (_orgSOQty - [self.textNumeric.text integerValue] == 0 && _orgSOItemCount == 1)
    {
        [self showAlertView:@"Original sales order cannot empty" title:@"Warning"];
        return;
    }
    
    if (_delegate != nil) {
        [_delegate passNumericBack:[self.textNumeric.text doubleValue] flag:@"recalcSplitSO" splitBillArrayIndex:0 TotalCondimentSurCharge:_orgTotalCondimentSurcharge];
        [self dismissViewControllerAnimated:NO completion:nil];
    }
    [textField resignFirstResponder];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)btnConfirmNum:(id)sender {
    if (_orgSOQty<[self.textNumeric.text integerValue]) {
        [self showAlertView:@"Qty separate more than order qty" title:@"Warning"];
        return;
    }
    else if ([self.textNumeric.text isEqualToString:@""])
    {
        [self showAlertView:@"Qty cannot empty" title:@"Warning"];
        return;
    }
    else if ([self.textNumeric.text doubleValue] == 0)
    {
        [self showAlertView:@"Qty cannot be zero" title:@"Warning"];
        return;
    }
    else if ([self.textNumeric.text containsString:@"."])
    {
        //[self showAlertView:@"Qty Must Be Integer" title:@"Warning"];
        //return;
    }
    
    else if (_orgSOQty - [self.textNumeric.text integerValue] == 0 && _orgSOItemCount == 1)
    {
        [self showAlertView:@"Original sales order cannot empty" title:@"Warning"];
        return;
    }
    
    if (_delegate != nil) {
        [_delegate passNumericBack:[self.textNumeric.text doubleValue] flag:@"recalcSplitSO" splitBillArrayIndex:0 TotalCondimentSurCharge:_orgTotalCondimentSurcharge];
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}

- (IBAction)btnCancelNum:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark - alertView

-(void)showAlertView:(NSString *)msg title:(NSString *)title
{
    
    UIAlertController *alert = [[LibraryAPI sharedInstance] showAlertViewWithMsg:msg Title:title];
    
    [self presentViewController:alert animated:NO completion:nil];
    alert = nil;
    
    /*
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:msg
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
     */
}
@end
