//
//  InvoiceDetailViewController.h
//  IpadOrder
//
//  Created by IRS on 9/10/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InvoiceDetailViewController : UIViewController <UITableViewDataSource,UITableViewDelegate>
@property (strong, nonatomic) IBOutlet UITableView *tableViewInvDetail;
@property (nonatomic, weak)NSString *invNo;
@property (strong, nonatomic) IBOutlet UILabel *labelDetailTotal;
@property (strong, nonatomic) IBOutlet UILabel *labelDetailDiscount;
@property (strong, nonatomic) IBOutlet UILabel *labelDetailTax;
@property (strong, nonatomic) IBOutlet UILabel *labelDetailGTotal;
@property (weak, nonatomic) IBOutlet UILabel *labelDetailSVG;
@end
