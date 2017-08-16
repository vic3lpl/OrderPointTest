//
//  BillListingViewController.h
//  IpadOrder
//
//  Created by IRS on 04/05/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppUtility.h"
#import "PosCommand.h"
#import "TscCommand.h"
#import "ImageTranster.h"
#import "XYSDK.h"

@protocol BillListingDelegate <NSObject>

@required
-(void)passBackDataWithSelectedDocNo:(NSString *)selectedDocno;

@end

@interface BillListingViewController : UIViewController<UITableViewDataSource,UITableViewDelegate, UISearchBarDelegate,POS_APIDelegate,XYWIFIManagerDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableViewBillListing;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBarForBillListing;
- (IBAction)btnClickPrintSelectedDoc:(id)sender;
@property(nonatomic,weak)id<BillListingDelegate>delegate;
@property (weak, nonatomic) IBOutlet UIButton *btnClose;
@property (weak, nonatomic) IBOutlet UIButton *btnPrint;
@property (nonatomic, strong) XYWIFIManager *wifiManager;

@end
