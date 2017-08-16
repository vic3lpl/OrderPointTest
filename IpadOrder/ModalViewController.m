//
//  ModalViewController.m
//  IpadOrder
//
//  Created by IRS on 6/30/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "ModalViewController.h"
#import "NumPadTextField/NumericKeypadTextField.h"
#import "NumericKeypadViewController.h"
//#import "TestViewController.h"

@interface ModalViewController ()

@end

@implementation ModalViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.ttt.numericKeypadDelegate = self;
    bigBtn = @"Confirm";
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    self.view.superview.bounds = CGRectMake(0, 0, 850, 700);
    //[self getItemMast];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    /*
    TestViewController *paymentAmtViewController = [[TestViewController alloc]init];
    
    [paymentAmtViewController setModalPresentationStyle:UIModalPresentationFormSheet];
    [self presentViewController:paymentAmtViewController animated:YES completion:nil];
     */
}
@end
