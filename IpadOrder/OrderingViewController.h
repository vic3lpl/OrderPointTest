//
//  OrderingViewController.h
//  IpadOrder
//
//  Created by IRS on 8/3/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OrderDetailViewController.h"
#import "PaymentViewController.h"
#import "SplitBillViewController.h"
#import "TestAZViewController.h"
#import "VoidOrderReasonViewController.h"
#import "PrintBillSelectionViewController.h"
//#import "PayMethodViewController.h"
#import "AppUtility.h"
#import "PosCommand.h"
#import "TscCommand.h"
#import "ImageTranster.h"
#import "XYSDK.h"
#import "PaxEntryViewController.h"
#import "OptionSelectTableViewController.h"
#import "OrderAddCondimentViewController.h"
#import "EditBillViewController.h"
#import "OrderCustomerInfoViewController.h"
#import "OrderPackageItemViewController.h"

@interface OrderingViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,OrderDetailDelegate,UISearchBarDelegate,PaymentViewDelegate,SplitBillDelegate,UIPopoverControllerDelegate,UICollectionViewDataSource,UICollectionViewDelegate,UIScrollViewDelegate,UICollectionViewDelegateFlowLayout,VoidOrderReasonDelegate,PrintBillDelegate,POS_APIDelegate,XYWIFIManagerDelegate,PaxEntryDelegate,OrderAddCondimentDelegate,OptionSelectTableDelegate,EditBillDelegate,UIPopoverPresentationControllerDelegate,OrderCustomerInfoDelegate, OrderPackageItemDelegate>

@property (strong, nonatomic) IBOutlet UITableView *orderCatTableView;
//@property (strong, nonatomic) IBOutlet UITableView *orderItemTableView;
@property (strong, nonatomic) IBOutlet UITableView *orderFinalTableView;
@property (strong, nonatomic) IBOutlet UISearchBar *orderSearchBar;
@property (strong, nonatomic) IBOutlet UILabel *labelSubTotal;
@property (strong, nonatomic) IBOutlet UILabel *labelTaxTotal;
@property (strong, nonatomic) IBOutlet UILabel *labelTotal;
@property (strong, nonatomic) IBOutlet UILabel *labelTotalDiscount;
@property (strong, nonatomic) IBOutlet UILabel *labelTaxType;
- (IBAction)btnVoidOrder:(id)sender;
- (IBAction)btnPayOrder:(id)sender;
@property (strong, nonatomic) IBOutlet UILabel *labelRound;

@property (strong, nonatomic) IBOutlet UIButton *btnSplitBill;
@property (strong, nonatomic) IBOutlet UIButton *btnPrintSO;
@property (strong, nonatomic) IBOutlet UILabel *labelServiceTaxTotal;
@property (weak, nonatomic) IBOutlet UIButton *btnVoidOrderBtn;

@property (weak, nonatomic) IBOutlet UIButton *clickPayOrder;

@property (nonatomic,strong) NSString *tableName;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollViewSecret;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionViewMenu;
@property (weak, nonatomic) IBOutlet UILabel *labelServiceChargeDisplay;


@property (nonatomic,strong) NSString *tbStatus;
@property (nonatomic, strong)NSString *connectedStatus;
@property (weak, nonatomic) IBOutlet UIButton *btnConfirm;
@property (weak, nonatomic) IBOutlet UILabel *labelTotalQty;
@property (weak, nonatomic) IBOutlet UILabel *labelExSubtotal;
@property (nonatomic, strong)NSString *overrideTableSVC;
@property (nonatomic, strong)NSString *paxData;
@property (weak, nonatomic) IBOutlet UILabel *labelOrderingPaxNo;
@property (nonatomic,strong) NSString *docType;
@property (nonatomic,strong) NSString *csDocNo;

- (IBAction)clickBtnCustomer:(id)sender;

@property (nonatomic, strong) XYWIFIManager *wifiManager;
@end
