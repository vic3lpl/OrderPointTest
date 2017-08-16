//
//  ItemMastViewController.h
//  IpadOrder
//
//  Created by IRS on 7/2/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseDetailViewController.h"

@interface ItemMastViewController : BaseDetailViewController <UITableViewDataSource,UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *itemMastTableView;

@end
