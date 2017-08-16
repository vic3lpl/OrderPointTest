//
//  PaymentAmtViewController.m
//  IpadOrder
//
//  Created by IRS on 8/20/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "PaymentAmtViewController.h"
#import "NumPadTextField/NumericKeypadTextField.h"
#import "NumericKeypadViewController.h"
#import "LibraryAPI.h"
#import <FMDB.h>

@interface PaymentAmtViewController ()
{
    FMDatabase *dbTable;
    NSString *dbPath;
    //NSMutableArray *paymentArray;
    NSString *SONo;
}
@end

@implementation PaymentAmtViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.textPaymentAmt.numericKeypadDelegate = self;
    dbPath = [[LibraryAPI sharedInstance]getDbPath];
    SONo = [[LibraryAPI sharedInstance]getDocNo];
    bigBtn = @"Hide";
    [self getSalesOrderAmount];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - NumberPadDelegate
-(void)saveActionFormTextField:(UITextField *)textField
{
    [textField resignFirstResponder];
    NSLog(@"Password is %@",textField.text);
}


#pragma mark - sqlite3 function

-(void)getSalesOrderAmount
{
    NSDictionary *data;
    dbTable = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTable open]) {
        NSLog(@"Fail To Open Database");
        return;
    }
    
    FMResultSet *rs = [dbTable executeQuery:@"Select * from SalesOrderHdr where SOH_DocNo = ?",SONo];
    
    if ([rs next]) {
        self.labelAmountDue.text = [NSString stringWithFormat:@"%0.2f",[rs doubleForColumn:@"SOH_DocAmt"]];
        data =[rs resultDictionary];
    }
    
    [rs close];
    [dbTable close];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)btnOne:(id)sender {
    self.textPaymentAmt.text =  [NSString stringWithFormat:@"%0.2f",[self.textPaymentAmt.text doubleValue] + 1.00];
}

- (IBAction)btnPaymentAmtViewBack:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)btnFive:(id)sender {
    self.textPaymentAmt.text =  [NSString stringWithFormat:@"%0.2f",[self.textPaymentAmt.text doubleValue] + 5.00];
}

- (IBAction)btnTen:(id)sender {
    self.textPaymentAmt.text =  [NSString stringWithFormat:@"%0.2f",[self.textPaymentAmt.text doubleValue] + 10.00];
}

- (IBAction)btnTwenty:(id)sender {
    self.textPaymentAmt.text =  [NSString stringWithFormat:@"%0.2f",[self.textPaymentAmt.text doubleValue] + 20.00];
}

- (IBAction)btnFity:(id)sender {
    self.textPaymentAmt.text =  [NSString stringWithFormat:@"%0.2f",[self.textPaymentAmt.text doubleValue] + 50.00];
}

- (IBAction)btnHundred:(id)sender {
    self.textPaymentAmt.text =  [NSString stringWithFormat:@"%0.2f",[self.textPaymentAmt.text doubleValue] + 100.00];
}



@end
