//
//  XReadingReportViewController.h
//  IpadOrder
//
//  Created by IRS on 9/14/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReaderViewController.h"

@interface XReadingReportViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,ReaderViewControllerDelegate>
@property (strong, nonatomic) IBOutlet UIButton *btnItemSales;
@property (strong, nonatomic) IBOutlet UIButton *btnHourlySales;
@property (strong, nonatomic) IBOutlet UILabel *labelReportTitle;
@property (strong, nonatomic) IBOutlet UITableView *tableViewXReading;
@property (strong, nonatomic) IBOutlet UIButton *btnPaymentType;



@property NSString *xReadingDateFrom;
@property NSString *xReadingDateTo;

@property NSString *xReadingDateFromDisplay;
@property NSString *xReadingDateToDisplay;

@property (strong, nonatomic) IBOutlet UILabel *labelFLabel;
@property (strong, nonatomic) IBOutlet UILabel *labelSLabel;
@property (strong, nonatomic) IBOutlet UILabel *labelTLabel;

@end
