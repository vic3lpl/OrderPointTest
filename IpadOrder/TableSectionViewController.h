//
//  TableSectionViewController.h
//  IpadOrder
//
//  Created by IRS on 8/5/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseDetailViewController.h"
@interface TableSectionViewController : BaseDetailViewController<UITableViewDataSource,UITableViewDelegate>
@property (strong, nonatomic) IBOutlet UITableView *tableSectionTableView;

@end
