//
//  PackageHdrViewController.h
//  IpadOrder
//
//  Created by IRS on 08/03/2017.
//  Copyright © 2017 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseDetailViewController.h"

@interface PackageHdrViewController : BaseDetailViewController <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableViewPackageItem;

@end
