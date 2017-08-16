//
//  VoidReportListingViewController.h
//  IpadOrder
//
//  Created by IRS on 11/05/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReaderViewController.h"

@interface VoidReportListingViewController : UIViewController<UITableViewDataSource,UITableViewDelegate, ReaderViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableVoidReason;
@property NSString *voidReasonDateFrom;
@property NSString *voidReasonDateTo;

@property NSString *voidReasonDateFromDisplay;
@property NSString *voidReasonDateToDisplay;
@end
