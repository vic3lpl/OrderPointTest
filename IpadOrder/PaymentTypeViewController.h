//
//  PaymentTypeViewController.h
//  IpadOrder
//
//  Created by IRS on 11/5/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseDetailViewController.h"

@interface PaymentTypeViewController : BaseDetailViewController <UITableViewDataSource,UITableViewDelegate>
@property (strong, nonatomic) IBOutlet UITableView *tableViewPaymentType;

@end
