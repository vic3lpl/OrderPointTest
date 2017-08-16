//
//  SplitBillViewController.h
//  IpadOrder
//
//  Created by IRS on 8/21/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PaymentViewController.h"
#import "KeyNumericViewController.h"

@protocol SplitBillDelegate <NSObject>
@required
-(void)cancelSplitBill:(NSString *)cancelMethod;

@end

@interface SplitBillViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,PaymentViewDelegate,NumericKeyDelegate,UIPopoverControllerDelegate,UIPopoverPresentationControllerDelegate>
@property (strong, nonatomic) IBOutlet UILabel *soO;
- (IBAction)splitBillViewCancel:(id)sender;
@property (strong, nonatomic) IBOutlet UITableView *splitBillTableView;
@property (strong, nonatomic) IBOutlet UILabel *labelSubTotal;
@property (strong, nonatomic) IBOutlet UILabel *labelTotalDiscount;
@property (strong, nonatomic) IBOutlet UILabel *labelTotalTax;
@property (strong, nonatomic) IBOutlet UILabel *labelTotalAmt;
@property (strong, nonatomic) IBOutlet UILabel *labelRounding;
@property (strong, nonatomic) IBOutlet UILabel *labelTotalServiceCharge;
@property (weak, nonatomic) IBOutlet UILabel *labelExSubTotal;


@property (strong, nonatomic) IBOutlet UILabel *soN;
- (IBAction)btnPayClick:(id)sender;
@property (strong, nonatomic) IBOutlet UITableView *subSplitBillTableView;
@property(nonatomic,retain)NSMutableArray *splitBillArray;
@property (strong, nonatomic) IBOutlet UILabel *labelOrgSubTotal;
@property (strong, nonatomic) IBOutlet UILabel *labelOrgTotalDiscount;
@property (strong, nonatomic) IBOutlet UILabel *labelOrgTotalTax;
@property (strong, nonatomic) IBOutlet UILabel *labelOrgTotal;
@property (strong, nonatomic) IBOutlet UILabel *labelOrgRounding;
@property (strong, nonatomic) IBOutlet UILabel *labelOrgServiceCharge;
- (IBAction)btnPayOrgSO:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *label1;
@property (weak, nonatomic) IBOutlet UILabel *label2;
@property (weak, nonatomic) IBOutlet UILabel *labelOrgExSubTotal;

@property (weak,nonatomic)id<SplitBillDelegate>delegate;
@property NSString *splitTableName;
@property NSString *splitPaxNo;
@property NSString *splitTableDineType;

@property(nonatomic,retain)NSMutableDictionary *splitCustomerInfoDict;
@end
