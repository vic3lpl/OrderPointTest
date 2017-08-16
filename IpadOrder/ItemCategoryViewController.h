//
//  ItemCategoryViewController.h
//  IpadOrder
//
//  Created by IRS on 7/2/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseDetailViewController.h"
#import "ItemCategoryDetailViewController.h"
@interface ItemCategoryViewController : BaseDetailViewController <UITableViewDataSource, UITableViewDelegate,UIPopoverControllerDelegate,ItemCategoryDetailDelegate,UIPopoverPresentationControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *catTableView;


@end
