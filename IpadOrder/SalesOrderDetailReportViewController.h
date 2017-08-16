//
//  SalesOrderDetailReportViewController.h
//  IpadOrder
//
//  Created by IRS on 28/06/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SalesOrderDetailReportViewController.h"

@interface SalesOrderDetailReportViewController : UIViewController <UITableViewDataSource,UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableViewSODetail;
@property(nonatomic,weak)NSString *docNo;
@property (weak, nonatomic) IBOutlet UILabel *labelSalesOrderExSubTotalAmt;
@property (weak, nonatomic) IBOutlet UILabel *labelSalesOrderDiscAmt;
@property (weak, nonatomic) IBOutlet UILabel *labelSalesOrderSVCAmt;
@property (weak, nonatomic) IBOutlet UILabel *labelSalesOrderTaxAmt;
@property (weak, nonatomic) IBOutlet UILabel *labelSalesOrderTotalAmt;


@end
