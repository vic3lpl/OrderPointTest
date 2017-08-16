//
//  UserNameViewController.h
//  IpadOrder
//
//  Created by IRS on 7/7/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseDetailViewController.h"

@interface UserNameViewController : BaseDetailViewController<UITableViewDataSource,UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *userTableView;

@end
