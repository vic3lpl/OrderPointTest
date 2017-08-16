//
//  ReportViewController.h
//  IpadOrder
//
//  Created by IRS on 9/9/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReportTableViewController.h"
#import "ReprotDetailViewController.h"

@interface ReportViewController : UIViewController
{
    UISplitViewController  *splitViewController;
}
@property (nonatomic, retain) IBOutlet UISplitViewController *splitViewController;

@property (nonatomic, retain) IBOutlet ReprotDetailViewController *detailViewController;

@property (nonatomic, retain) IBOutlet ReportTableViewController *rootViewController;
@end
