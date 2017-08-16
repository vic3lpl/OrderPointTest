//
//  CondimentViewController.h
//  IpadOrder
//
//  Created by IRS on 03/09/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseDetailViewController.h"

@interface CondimentViewController : BaseDetailViewController<UITableViewDataSource,UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableCondimentDetail;

@end
