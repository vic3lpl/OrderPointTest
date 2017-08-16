//
//  OrderCustomerInfoViewController.m
//  IpadOrder
//
//  Created by IRS on 05/12/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import "OrderCustomerInfoViewController.h"
#import "LibraryAPI.h"

@interface OrderCustomerInfoViewController ()
{
    
}
@end

@implementation OrderCustomerInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.preferredContentSize = CGSizeMake(393, 414);
    //dbPath = [[LibraryAPI sharedInstance] getDbPath];
    // Do any additional setup after loading the view from its nib.
    self.textOrderCustomerName.text = [_custDict objectForKey:@"Name"];
    self.textOrderCustomerAddress1.text = [_custDict objectForKey:@"Add1"];
    self.textOrderCustomerAddress2.text = [_custDict objectForKey:@"Add2"];
    self.textOrderCustomerAddress3.text = [_custDict objectForKey:@"Add3"];
    self.textOrderCustomerTelNo.text = [_custDict objectForKey:@"TelNo"];
    self.textOrderCustomerGstNo.text = [_custDict objectForKey:@"GstNo"];
}

-(void)viewDidAppear:(BOOL)animated
{
    
    [self.textOrderCustomerName becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnCancelOrderCustomer:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}

- (IBAction)btnSaveOrderCustomer:(id)sender {
    if (_delegate != nil) {
        /*
        if ([self.textOrderCustomerName.text length] == 0 || [self.textOrderCustomerName.text isEqualToString:@" "]) {
            [self showAlertView:@"Customer name cannot empty" title:@"Warning"];
            return;
        }
        
        if ([self.textOrderCustomerAddress1.text length] == 0 || [self.textOrderCustomerAddress1.text isEqualToString:@" "]) {
            [self showAlertView:@"Address1 cannot empty" title:@"Warning"];
            return;
        }
        
        if ([self.textOrderCustomerAddress2.text length] == 0 || [self.textOrderCustomerAddress2.text isEqualToString:@" "]) {
            [self showAlertView:@"Address2 cannot empty" title:@"Warning"];
            return;
        }
        */
        [_delegate passBackCustomerInfoWithCustName:self.textOrderCustomerName.text CustAdd1:self.textOrderCustomerAddress1.text CustAdd2:self.textOrderCustomerAddress2.text CustAdd3:self.textOrderCustomerAddress3.text TelNo:self.textOrderCustomerTelNo.text CustGstNo:self.textOrderCustomerGstNo.text];
    }
}


#pragma mark - alertView

-(void)showAlertView:(NSString *)msg title:(NSString *)title
{
    UIAlertController * alert = [[LibraryAPI sharedInstance] showAlertViewWithMsg:msg Title:title];
    
    [self presentViewController:alert animated:YES completion:nil];
    
    alert = nil;
    
}


@end
