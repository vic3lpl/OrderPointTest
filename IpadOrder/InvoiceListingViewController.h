//
//  InvoiceListingViewController.h
//  IpadOrder
//
//  Created by IRS on 9/10/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "ReaderViewController.h"

@interface InvoiceListingViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,MFMailComposeViewControllerDelegate,ReaderViewControllerDelegate>
@property (strong, nonatomic) IBOutlet UITableView *tableViewInvListing;
@property (strong,nonatomic)NSString *invListingDateFrom;
@property (strong,nonatomic)NSString *invListingDateTo;
@property (strong,nonatomic)NSString *invListingDateFromDisplay;
@property (strong,nonatomic)NSString *invListingDateToDisplay;

@end
