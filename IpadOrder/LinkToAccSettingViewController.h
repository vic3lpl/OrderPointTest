//
//  LinkToAccSettingViewController.h
//  IpadOrder
//
//  Created by IRS on 17/10/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import "ViewController.h"
#import "BaseDetailViewController.h"

@interface LinkToAccSettingViewController : BaseDetailViewController <UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITextField *textAccClientID;
@property (weak, nonatomic) IBOutlet UITextField *textAccUserID;
@property (weak, nonatomic) IBOutlet UITextField *textAccUserPassword;
@property (weak, nonatomic) IBOutlet UITextField *textAccCompanyName;
@property (weak, nonatomic) IBOutlet UITextField *textAccURL;
@property (weak, nonatomic) IBOutlet UITextField *textCSAcc;
@property (weak, nonatomic) IBOutlet UITextField *textCSRAcc;
@property (weak, nonatomic) IBOutlet UITextField *textSCAcc;
@property (weak, nonatomic) IBOutlet UITextField *textCSDesc;
@property (weak, nonatomic) IBOutlet UITableView *tablePaymentType;
@property (weak, nonatomic) IBOutlet UITextField *textCustomerAcc;




@end
