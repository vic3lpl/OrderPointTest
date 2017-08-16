//
//  CondimentGroupEditViewController.h
//  IpadOrder
//
//  Created by IRS on 03/09/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CondimentDetailViewController.h"

@interface CondimentGroupEditViewController : UIViewController<UITableViewDelegate,UITableViewDataSource, CondimentDetailViewDelegate>

@property(nonatomic,weak)NSString *chCode;
@property(nonatomic,weak)NSString *action;
@property (weak, nonatomic) IBOutlet UITextField *textCondimentGroupCode;
@property (weak, nonatomic) IBOutlet UITextField *textCondimentDesc;
- (IBAction)btnAddCondimentDetailClick:(id)sender;
@property (weak, nonatomic) IBOutlet UITableView *tableCondimentDetail;

@end
