//
//  ModifierHdrViewController.h
//  IpadOrder
//
//  Created by IRS on 07/03/2017.
//  Copyright © 2017 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseDetailViewController.h"

@interface ModifierHdrViewController : BaseDetailViewController <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableViewModifierHdr;

@end
