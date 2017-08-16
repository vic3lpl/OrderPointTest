//
//  TablePlanViewController.h
//  IpadOrder
//
//  Created by IRS on 7/14/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseDetailViewController.h"

@interface TablePlanViewController : BaseDetailViewController <UITableViewDataSource,UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tablePlanTableView;
@end
