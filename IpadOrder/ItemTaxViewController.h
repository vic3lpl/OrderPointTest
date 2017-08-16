//
//  ItemTaxViewController.h
//  IpadOrder
//
//  Created by IRS on 7/10/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseDetailViewController.h"

@interface ItemTaxViewController : BaseDetailViewController <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *itemTaxTableView;

@end
