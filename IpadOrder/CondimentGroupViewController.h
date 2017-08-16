//
//  CondimentGroupViewController.h
//  IpadOrder
//
//  Created by IRS on 02/09/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseDetailViewController.h"

@interface CondimentGroupViewController : BaseDetailViewController<UITableViewDelegate,UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *TableCondimentGroup;

@end
