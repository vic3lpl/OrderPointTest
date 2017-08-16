//
//  PrintBillSelectionViewController.m
//  IpadOrder
//
//  Created by IRS on 04/05/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import "PrintBillSelectionViewController.h"


@interface PrintBillSelectionViewController ()

@end

@implementation PrintBillSelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.preferredContentSize = CGSizeMake(307, 459);
}

-(void)viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBar.hidden = YES;
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

- (IBAction)dismissPrintBillSelectionView:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)clickPrintCurrentBill:(id)sender {
    if (_delegate != nil) {
        [_delegate printSelectedSalesOrderWithSalesOrderNo:@"-" BillStatus:@"Current"];
    }
}

- (IBAction)clickBtnFindBill:(id)sender {
    BillListingViewController *billListingViewController = [[BillListingViewController alloc] init];
    billListingViewController.delegate = self;
    [self.navigationController pushViewController:billListingViewController animated:YES];
    
}

#pragma mark - delegate from billlisting
-(void)passBackDataWithSelectedDocNo:(NSString *)selectedDocno
{
    if (_delegate != nil) {
        [_delegate printSelectedSalesOrderWithSalesOrderNo:selectedDocno BillStatus:@"Selected"];
    }
}
@end
