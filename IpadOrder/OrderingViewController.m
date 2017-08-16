//
//  OrderingViewController.m
//  IpadOrder
//
//  Created by IRS on 8/3/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "OrderingViewController.h"
#import "OrderCatTableViewCell.h"
#import "OrderItemCell.h"
#import "LibraryAPI.h"
#import <FMDB.h>
#import "OrderDetailViewController.h"
#import "OrderFinalCell.h"
#import "NumericKeypadTextField.h"
#import "OrderFinalDiscountCell.h"
#import "PaymentViewController.h"
#import "SplitBillViewController.h"
#import <MBProgressHUD.h>
#import "ePOS-Print.h"
#import "Result.h"
#import "MsgMaker.h"
#import "EposPrintFunction.h"
#import "PrinterFunctions.h"
#import <StarIO/SMPort.h>
#import <StarIO/SMBluetoothManager.h>
#import "TestAZViewController.h"
#import <Haneke.h>
#import <QuartzCore/QuartzCore.h>
#import "AppDelegate.h"

#import <Haneke.h>
#import "FullyHorizontalFlowLayout.h"
#import "OrderItemCollectionViewCell.h"
#import "AdminViewController.h"
#import "TerminalData.h"
#import "PublicSqliteMethod.h"
#import "OrderAddCondimentViewController.h"
#import <KVNProgress.h>
#import "EditBillViewController.h"
#import "PublicMethod.h"
#import "ShowMsg.h"

static NSString * const itemCellIdentifier = @"OrderItemCollectionViewCell";
@interface OrderingViewController ()
{
    NSString *dbPath;
    FMDatabase *dbTable;
    BOOL dbNoError;
    NSMutableArray *catergoryArray;
    NSMutableArray *itemMastArray;
    NSMutableArray *orderFinalArray;
    NSInteger selectedTableNo;
    NSString *taxType;
    NSString *orderDataStatus;
    NSString *docNo;
    NSString *directExit;
    NSString *alertType;
    NSString *soNo;
    
    //calc item price
    double gst;
    
    // no include tax
    double itemSellingPrice;
    double totalItemSellingAmt;
    
    // tax amt
    double itemTaxAmt;
    double totalItemTaxAmt;
    double itemDiscountInPercent;
    
    // for kitchen receipt
    NSOperationQueue *operationQue;
    NSString *tableDesc;
    
    //for sales order receipt
    NSMutableArray *printSOArray;
    NSString *printerMode;
    NSString *printerBrand;
    NSString *printerName;
    SMLanguage p_selectedLanguage;
    SMPaperWidth p_selectedWidthInch;
    NSString *printerPortSetting;
    
    // service tax
    NSString *tpServiceTax2;
    double serviceTaxGst;
    NSString *serviceTaxGstTotal;
    
    //kitchen receipt
    int kitchenReceiptGroup;
    NSMutableArray *kitchenGroup;
    
    //enable gst
    int compEnableGst;
    int compEnableSVG;
    
    //for image path;
    NSArray *arrPath;
    NSString *imgDir;
    NSString *imgPath;
    UIImage *imgBtn;
    
    //for terminal/main
    NSString *terminalType;
    MCPeerID *specificPeer;
    NSMutableArray *requestServerData;
    
    //for uicollection view
    int itemMastCount;
    
    //for filter uicollection view
    NSArray *itemMastArrayFilter;
    NSString *isFiltered;
    NSMutableArray *keepAllItemArray;
    
    //for item category
    NSString *categoryName;
    NSString *terminalPayType;
    
    NSMutableArray *partialSalesOrderArray;
    int makeXinYeDiscon;
    NSMutableArray *printerIpArray;
    NSMutableArray *xinYeConnectionArray;
    
    NSMutableArray *kReceiptArray222;
    XYWIFIManager *xinYeOrderingWfMng;
    
    long itemSelectedIndex;
    NSString *updateCondimentDtlQtyFrom;
    NSUInteger indexOfParentArray; // for condiment parent index
    
    NSMutableDictionary *orderCustomerInfo;
    double predicateItemPrice;
    NSString *predicateItemCode;
    
}

@property (nonatomic, strong)UIPopoverPresentationController *popOverPay;
//@property(nonatomic,strong)UIPopoverController *popOverOption;
@property (nonatomic, strong) AppDelegate *appDelegate;
//refresh tableview
-(void)confirmSalesOrderWithNotification:(NSNotification *)notification;

-(void)getSalesOrderDtlWithNotification:(NSNotification *)notification;

-(void)printSalesOrderDtlWithNotification:(NSNotification *)notification;
-(void)printAsterixSalesOrderDtlWithNotification:(NSNotification *)notification;
@end

@implementation OrderingViewController

- (IBAction)clickBtnCustomer:(id)sender {
    
    OrderCustomerInfoViewController *orderCustomerInfoViewController = [[OrderCustomerInfoViewController alloc] init];
    
    orderCustomerInfoViewController.delegate  = self;
    orderCustomerInfoViewController.custDict = orderCustomerInfo;
    [orderCustomerInfoViewController setModalPresentationStyle:UIModalPresentationFormSheet];
    [orderCustomerInfoViewController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    [self.navigationController presentViewController:orderCustomerInfoViewController animated:YES completion:nil];
    
}

- (XYWIFIManager *)wifiManager
{
    if (!_wifiManager)
    {
        _wifiManager = [XYWIFIManager shareWifiManager];
        _wifiManager.delegate = self;
    }
    return _wifiManager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(confirmSalesOrderWithNotification:)
                                                 name:@"ConfirmSalesOrderWithNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(getSalesOrderDtlWithNotification:)
                                                 name:@"GetSalesOrderDtlWithNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(printSalesOrderDtlWithNotification:)
                                                 name:@"PrintSalesOrderDtlWithNotification"
                                               object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(printAsterixSalesOrderDtlWithNotification:)
                                                 name:@"PrintAsterixSalesOrderDtlWithNotification"
                                               object:nil];
    
    // Do any additional setup after loading the view from its nib.
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    arrPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    imgDir = [arrPath objectAtIndex:0];
    
    //[self changeNaviBarTitle];
    
    UIGestureRecognizer *tapper = [[UITapGestureRecognizer alloc]
              initWithTarget:self action:@selector(handleSingleTap:)];
    tapper.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapper];
    
    
    orderDataStatus = @"New";
    
    directExit = @"Yes";
    makeXinYeDiscon = 0;
    kitchenGroup = [[NSMutableArray alloc] init];
    requestServerData = [[NSMutableArray alloc]init];
    keepAllItemArray = [[NSMutableArray alloc] init];
    partialSalesOrderArray = [[NSMutableArray alloc] init];
    printerIpArray = [[NSMutableArray alloc] init];
    xinYeConnectionArray = [[NSMutableArray alloc] init];
    xinYeOrderingWfMng = [[XYWIFIManager alloc] init];
    orderCustomerInfo = [NSMutableDictionary dictionary];
    indexOfParentArray = 0;
    
    self.orderCatTableView.delegate = self;
    self.orderCatTableView.dataSource = self;
    
    self.orderFinalTableView.delegate = self;
    self.orderFinalTableView.dataSource = self;
    self.orderFinalTableView.separatorColor = [UIColor clearColor];
    
    self.orderSearchBar.delegate = self;
    self.orderSearchBar.placeholder = @"Search Item";
    
    [self.btnSplitBill addTarget:self action:@selector(clickSplitBill:) forControlEvents:UIControlEventTouchUpInside];
    [self.btnPrintSO addTarget:self action:@selector(clickPrintSO:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.btnConfirm addTarget:self action:@selector(addToSalesOrder:) forControlEvents:UIControlEventTouchUpInside];
    
    selectedTableNo = [[LibraryAPI sharedInstance]getTableNo];
    compEnableGst = [[LibraryAPI sharedInstance]getEnableGst];
    compEnableSVG = [[LibraryAPI sharedInstance] getEnableSVG];
    
    catergoryArray = [[NSMutableArray alloc]init];
    itemMastArray = [[NSMutableArray alloc]init];
    orderFinalArray = [[NSMutableArray alloc]init];
    printSOArray = [[NSMutableArray alloc]init];
    dbPath = [[LibraryAPI sharedInstance]getDbPath];
    taxType = [[LibraryAPI sharedInstance]getTaxType];
    tpServiceTax2 = [[LibraryAPI sharedInstance]getServiceTaxPercent];
    serviceTaxGst = [[LibraryAPI sharedInstance]getServiceTaxGstPercent];
    kitchenReceiptGroup = [[LibraryAPI sharedInstance]getKitchenReceiptGrouping];
    
    if ([taxType isEqualToString:@"Inc"]) {
        self.labelTaxType.text = @"Total Tax(Inc)";
    }
    else
    {
        self.labelTaxType.text = @"Total Tax(Excl)";
    }
    
    if (![tpServiceTax2 isEqualToString:@"-"]) {
        self.labelServiceChargeDisplay.text = [NSString stringWithFormat:@"Service Charge %@%@",tpServiceTax2,@"%"];
    }
    else
    {
        self.labelServiceChargeDisplay.text = @"Service Charge";
    }
    
    UINib *catNib = [UINib nibWithNibName:@"OrderCatTableViewCell" bundle:nil];
    [[self orderCatTableView]registerNib:catNib forCellReuseIdentifier:@"OrderCatTableViewCell"];
    
    UINib *finalNib = [UINib nibWithNibName:@"OrderFinalCell" bundle:nil];
    [[self orderFinalTableView]registerNib:finalNib forCellReuseIdentifier:@"OrderFinalCell"];
    
    UINib *itemCollectionNib = [UINib nibWithNibName:itemCellIdentifier bundle:nil];
    
    [_collectionViewMenu registerNib:itemCollectionNib forCellWithReuseIdentifier:itemCellIdentifier];
    
    FullyHorizontalFlowLayout *collectionViewLayout = [FullyHorizontalFlowLayout new];
    
    collectionViewLayout.itemSize = CGSizeMake(130., 130.);
    [collectionViewLayout setSectionInset:UIEdgeInsetsMake(0, 5, 0, 5)];
    
    self.orderCatTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.orderFinalTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    for (id object in [[[self.orderSearchBar subviews] objectAtIndex:0] subviews])
    {
        if ([object isKindOfClass:[UITextField class]])
        {
            UITextField *textFieldObject = (UITextField *)object;
            textFieldObject.frame = CGRectMake(0, 0, 430, 44);
            textFieldObject.textColor = [UIColor blackColor];
            textFieldObject.layer.borderColor = [[UIColor colorWithRed:13/255.0 green:149/255.0 blue:226/255.0 alpha:1.0] CGColor];
            textFieldObject.layer.borderWidth = 1.0;
            textFieldObject.layer.cornerRadius = 5.0;
            break;
        }
    }
    
    if ([[LibraryAPI sharedInstance]getKioskMode] == 1) {
        self.navigationController.navigationBar.hidden = NO;
        
        [self.navigationController.navigationBar
         setBackgroundImage:[UIImage imageNamed:@"bluedeep_bar"]
         forBarMetrics:UIBarMetricsDefault];
        
        self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
        
        self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
        
        UIBarButtonItem *newBackButton =
        [[UIBarButtonItem alloc] initWithTitle:@"Logout"
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(backToLogInViewFromOrder)];
        self.navigationItem.leftBarButtonItem = newBackButton;
        
        UIBarButtonItem *btnGoToSetting = [[UIBarButtonItem alloc]initWithTitle:@"Option" style:UIBarButtonItemStylePlain target:self action:@selector(goToOption:)];
        self.navigationItem.rightBarButtonItem = btnGoToSetting;
        btnGoToSetting = nil;
        
        self.btnVoidOrderBtn.enabled = YES;
        self.btnConfirm.enabled = false;
        self.btnPrintSO.enabled = YES;
        
    }
    else
    {
        
        UIBarButtonItem *backSelectTableView = [[UIBarButtonItem alloc]initWithTitle:@"< Table" style:UIBarButtonItemStylePlain target:self action:@selector(btnBackSelectTable:)];
        self.navigationItem.leftBarButtonItem = backSelectTableView;
        [backSelectTableView setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor],NSForegroundColorAttributeName, nil] forState:UIControlStateNormal];
        
        self.btnVoidOrderBtn.enabled = NO;
        self.btnPrintSO.enabled = NO;
    }
    
    [self.collectionViewMenu setCollectionViewLayout:collectionViewLayout];
    _collectionViewMenu.dataSource = self;
    _collectionViewMenu.delegate = self;
    _collectionViewMenu.pagingEnabled = true;
    
    //_collectionViewMenu.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    
    self.scrollViewSecret.delegate = self;
    
    self.btnSplitBill.enabled = NO;
    
    [orderCustomerInfo setObject:@"" forKey:@"Name"];
    [orderCustomerInfo setObject:@"" forKey:@"Add1"];
    [orderCustomerInfo setObject:@"" forKey:@"Add2"];
    [orderCustomerInfo setObject:@"" forKey:@"Add3"];
    [orderCustomerInfo setObject:@"" forKey:@"TelNo"];
    [orderCustomerInfo setObject:@"" forKey:@"GstNo"];

    
    [self getItemCategory];
    
}

-(void)viewWillAppear:(BOOL)animated
{
    
    if (![[[LibraryAPI sharedInstance] getPrinterUUID] isEqualToString:@"Non"] && [[[LibraryAPI sharedInstance] getWorkMode] isEqualToString:@"Main"])
    {
        [PosApi setDelegate: self];
    }
    
    [self wifiManager];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0]; // set to whatever you want to be selected first
    [self.orderCatTableView selectRowAtIndexPath:indexPath animated:NO  scrollPosition:UITableViewScrollPositionNone];
    
    [self.collectionViewMenu.collectionViewLayout invalidateLayout];
    soNo = [[LibraryAPI sharedInstance]getDocNo];
    terminalType = [[LibraryAPI sharedInstance]getWorkMode];
    [self diffSalesOrderNCashSales];
}

-(void)diffSalesOrderNCashSales
{
    if ([terminalType isEqualToString:@"Terminal"])
    {
        
        if (![_docType isEqualToString:@"CashSales"]) {
            if (![soNo isEqualToString:@"-"]) {
                orderDataStatus = @"Edit";
                [self requestSODtlFromServer];
            }
            else
            {
                orderDataStatus = @"New";
                [self checkTableStatus];
                //self.labelOrderingPaxNo.text = _paxData;
                [self changeNaviBarTitle];
                
            }
        }
        else
        {
            orderDataStatus = @"Edit";
            soNo = _csDocNo;
            [self requestSODtlFromServer];
        }
        
        
    }
    else
    {
        [self checkTableStatus];
        //self.labelOrderingPaxNo.text = _paxData;
        [self changeNaviBarTitle];
    }
    
    if ([_docType isEqualToString:@"CashSales"]) {
        self.btnConfirm.enabled = false;
        self.btnPrintSO.enabled = false;
        self.btnSplitBill.enabled = false;
        self.btnVoidOrderBtn.enabled = false;
    }
    [self.orderFinalTableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
}

-(void)changeNaviBarTitle
{
    
    if([[orderCustomerInfo objectForKey:@"Name"] length] == 0)
    {
        self.title = [NSString stringWithFormat:@"%@ %@",_tableName,_connectedStatus];
    }
    else
    {
        self.title = [NSString stringWithFormat:@"%@ %@ (%@)",_tableName,_connectedStatus,[orderCustomerInfo objectForKey:@"Name"]];
    }
    
    if ([[LibraryAPI sharedInstance] getKioskMode] == 1) {
        return;
    }
    
    if ([[LibraryAPI sharedInstance] getKioskMode]==0) {
        UIButton* customButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [customButton setImage:[UIImage imageNamed:@"Pax_White32"] forState:UIControlStateNormal];
        [customButton setTitle:[NSString stringWithFormat:@" X %@",_paxData] forState:UIControlStateNormal];
        [customButton sizeToFit];
        [customButton addTarget:self action:@selector(clickLabelPaxNo) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem* customBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:customButton];
        self.navigationItem.rightBarButtonItem = customBarButtonItem;
        
        customBarButtonItem = nil;
        customButton = nil;
        /*
        UIBarButtonItem *btnPaxNo = [[UIBarButtonItem alloc]initWithTitle:[NSString stringWithFormat:@"Pax : %@",_paxData] style:UIBarButtonItemStylePlain target:self action:@selector(clickLabelPaxNo)];
        self.navigationItem.rightBarButtonItem = btnPaxNo;
        btnPaxNo = nil;
         */
    }
}

-(void)backToLogInViewFromOrder
{
    alertType = @"Logout";
    
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Warning"
                                 message:@"Are you sure to logout  ?"
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* yesButton = [UIAlertAction
                                actionWithTitle:@"OK"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
                                    partialSalesOrderArray = nil;
                                    [self.navigationController popViewControllerAnimated:NO];
                                }];
    
    UIAlertAction* noButton = [UIAlertAction
                               actionWithTitle:@"Cancel"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   //Handle no, thanks button
                               }];
    
    [alert addAction:yesButton];
    [alert addAction:noButton];
    
    [self presentViewController:alert animated:YES completion:nil];
    alert = nil;
    /*
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Alert"
                          message:@"Are you sure to logout ?"
                          delegate:self
                          cancelButtonTitle:@"Yes"
                          otherButtonTitles:@"No", nil];
     */
    //[alert show];
    
}

- (IBAction)goToOption:(id)sender {
    [[LibraryAPI sharedInstance] setOpenOptionViewName:@"OrderingView"];
    OptionSelectTableViewController *optionSelectedTableViewController = [[OptionSelectTableViewController alloc]init];
    optionSelectedTableViewController.delegate  = self;
    //optionSelectedTableViewController.optionViewFlag = @"OrderingView";
    
    optionSelectedTableViewController.modalPresentationStyle = UIModalPresentationPopover;
    optionSelectedTableViewController.popoverPresentationController.permittedArrowDirections = 0;
    optionSelectedTableViewController.popoverPresentationController.sourceView = self.view;
    optionSelectedTableViewController.popoverPresentationController.sourceRect = CGRectMake(950,0, 1, 1);
    [self presentViewController:optionSelectedTableViewController animated:YES completion:nil];
    
    /*
    self.popOverOption = [[UIPopoverController alloc]initWithContentViewController:optionSelectedTableViewController];
    
    [self.popOverOption presentPopoverFromRect:CGRectMake(950, 0, 1, 1) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:NO];
     */
    
    /*
    
    */
    
    //[self presentViewController:adminViewController animated:YES completion:nil];
}

-(void)kiosOpenMoreView
{
    [self dismissViewControllerAnimated:YES completion:nil];
    if (orderFinalArray.count > 0) {
        [self showAlertView:@"Order in progress. Cannot edit bill" title:@"Warning"];
        return;
    }
    
    //[self.popOverOption dismissPopoverAnimated:YES];
    
    int userRole;
    userRole = [[LibraryAPI sharedInstance]getUserRole];
    if (userRole == 1) {
        
        AdminViewController *adminViewController = [[AdminViewController alloc]init];
        [self.navigationController pushViewController:adminViewController animated:NO];
        
    }
    else
    {
        
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Warning"
                                     message:@"You have no permission to access."
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* yesButton = [UIAlertAction
                                    actionWithTitle:@"OK"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
                                        //[self alertActionSelection];
                                    }];
        
        [alert addAction:yesButton];
        
        [self presentViewController:alert animated:YES completion:nil];
        alert = nil;
        
        /*
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Alert"
                              message:@"You Have No Permission To Login."
                              delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil, nil];
        [alert show];
         */
    }
}


- (void)handleSingleTap:(UITapGestureRecognizer *) sender
{
    [self.view endEditing:YES];
}

-(void)viewDidLayoutSubviews
{
    if ([self.orderCatTableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.orderCatTableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([self.orderCatTableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.orderCatTableView setLayoutMargins:UIEdgeInsetsZero];
    }
    
    if ([self.orderFinalTableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.orderFinalTableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([self.orderFinalTableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.orderFinalTableView setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)btnBackSelectTable:(id)sender
{
    if ([_docType isEqualToString:@"CashSales"]) {
        orderFinalArray = nil;
        catergoryArray = nil;
        itemMastArray = nil;
        _tableName = nil;
        keepAllItemArray = nil;
        [self.navigationController popViewControllerAnimated:NO];
    }
    else
    {
        if ([directExit isEqualToString:@"No"]) {
            alertType = @"BackAlert";
            
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"Warning"
                                         message:@"Do you want to Save Current Order ?"
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* cancelButton = [UIAlertAction
                                           actionWithTitle:@"Cancel"
                                           style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction * action) {
                                               //[self alertActionSelection];
                                           }];
            
            UIAlertAction* yesButton = [UIAlertAction
                                        actionWithTitle:@"Yes"
                                        style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * action) {
                                            [self addToSalesOrder:alertType];
                                        }];
            
            UIAlertAction* noButton = [UIAlertAction
                                       actionWithTitle:@"No"
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction * action) {
                                           orderFinalArray = nil;
                                           catergoryArray = nil;
                                           itemMastArray = nil;
                                           _tableName = nil;
                                           keepAllItemArray = nil;
                                           [self.navigationController popViewControllerAnimated:NO];
                                       }];
            
            [alert addAction:yesButton];
            [alert addAction:noButton];
            [alert addAction:cancelButton];
            
            [self presentViewController:alert animated:YES completion:nil];
            alert = nil;
            
            /*
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:@"Alert"
                                  message:@"Are you want to Save Current Order ?"
                                  delegate:self
                                  cancelButtonTitle:@"Cancel"
                                  otherButtonTitles:@"Yes", @"No", nil];
            [alert show];
             */
        }
        else if ([directExit isEqualToString:@"Yes"])
        {
            //[self stopReconnectTimer];
            orderFinalArray = nil;
            catergoryArray = nil;
            itemMastArray = nil;
            _tableName = nil;
            keepAllItemArray = nil;
            
            [self.navigationController popViewControllerAnimated:NO];
        }
    }
    
    
}

-(void)clickLabelPaxNo
{
    PaxEntryViewController *paxEntryViewController = [[PaxEntryViewController alloc] init];
    
    paxEntryViewController.delegate  = self;
    paxEntryViewController.requirePaxEntryView = @"OrderingView";
    [paxEntryViewController setModalPresentationStyle:UIModalPresentationFormSheet];
    [paxEntryViewController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    [self.navigationController presentViewController:paxEntryViewController animated:NO completion:nil];
}

#pragma mark - edit pax no delegate
-(void)editKeyInPaxNumberWithPaxNo:(NSString *)paxNo
{
    _paxData = paxNo;
    //self.labelOrderingPaxNo.text = paxNo;
    [self dismissViewControllerAnimated:NO completion:nil];
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    for (int i = 0; i < orderFinalArray.count; i++) {
        
        data = [orderFinalArray objectAtIndex:i];
        
        [data setValue:_paxData forKey:@"SOH_PaxNo"];
        [orderFinalArray replaceObjectAtIndex:i withObject:data];
    }
    [self changeNaviBarTitle];
    data = nil;
}

#pragma mark - alertview response
/*
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    
    if ([alertType isEqualToString:@"BackAlert"]) {
        if (buttonIndex == 0) {
            NSLog(@"Nothing");
        }
        else if (buttonIndex == 1)
        {
            
            [self addToSalesOrder:alertType];
        }
        else if (buttonIndex == 2)
        {
            
            orderFinalArray = nil;
            catergoryArray = nil;
            itemMastArray = nil;
            _tableName = nil;
            keepAllItemArray = nil;
            [self.navigationController popViewControllerAnimated:NO];
        }
    }
    else if ([alertType isEqualToString:@"VoidOrder"])
    {
        if (orderFinalArray.count == 0) {
            [self showAlertView:@"Order list is empty" title:@"Warning"];
            return;
        }
        else if ([orderDataStatus isEqualToString:@"New"])
        {
            [self showAlertView:@"New order cannot void" title:@"Warning"];
            return;
        }
        if (buttonIndex == 0) {
            [self deleteSalesOrder];
        }
        
    }
    else if ([alertType isEqualToString:@"Logout"])
    {
        if (buttonIndex == 0) {
            partialSalesOrderArray = nil;
            [self.navigationController popViewControllerAnimated:NO];
        }
        
    }
    
    //[self.catTableView reloadData];
}
*/
#pragma mark - tableview delegate method

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
    
    //UIView *view = [[UIView alloc] init];
    //[view setBackgroundColor:[UIColor colorWithRed:153/255.0 green:153/255.0 blue:153/255.0 alpha:1.0]];
    //[view setBackgroundColor:[UIColor redColor]];
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    long dataCount;
    // Return the number of rows in the section.
    if (tableView == self.orderCatTableView) {
        dataCount = catergoryArray.count;
    }
    else if(tableView == self.orderFinalTableView)
    {
        dataCount = orderFinalArray.count;
    }
    return dataCount;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //static NSString *Identifier = @"Cell";
    id cellToReturn;
    
    if (tableView == self.orderCatTableView) {
        OrderCatTableViewCell *orderCatCell = [tableView dequeueReusableCellWithIdentifier:@"OrderCatTableViewCell"];
        
        [[orderCatCell catLabel] setText:[[catergoryArray objectAtIndex:indexPath.row]objectForKey:@"IC_Description"]];
        
        NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        
        NSString *filePath = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg",[[catergoryArray objectAtIndex:indexPath.row]objectForKey:@"IC_Category"]]];
        orderCatCell.imgCategory.layer.cornerRadius = 10.0;
        orderCatCell.imgCategory.layer.masksToBounds = YES;
        [[orderCatCell imgCategory] setImage:[UIImage imageWithContentsOfFile:filePath]];
        cellToReturn = orderCatCell;
        
        documentsPath = nil;
        filePath = nil;
    }
    
    else if (tableView == self.orderFinalTableView)
    {
        if ([[[orderFinalArray objectAtIndex:indexPath.row]objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"])
        {
            //IM_Price is final price / SOD_UnitPrice
            
            if ([[[orderFinalArray objectAtIndex:indexPath.row]objectForKey:@"IM_DiscountAmt"] isEqualToString:@"0.00"]) {
                OrderFinalCell *orderFinalCell = [tableView dequeueReusableCellWithIdentifier:@"OrderFinalCell"];
                
                UIImageView *line = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, orderFinalCell.bounds.size.width, 1)];
                line.backgroundColor = [UIColor colorWithRed:196/255.0 green:196/255.0 blue:196/255.0 alpha:1.0];
                [orderFinalCell addSubview:line];
                line = nil;
                
                
                [[orderFinalCell finalDesc] setText:[NSString stringWithFormat:@"%@",[[orderFinalArray objectAtIndex:indexPath.row] objectForKey:@"IM_Description"]]];
                
                [[orderFinalCell finalQty] setText:[NSString stringWithFormat:@"%.2f",[[[orderFinalArray objectAtIndex:indexPath.row]objectForKey:@"IM_Qty"] doubleValue]]];
                
                [[orderFinalCell finalPrice] setText:[[orderFinalArray objectAtIndex:indexPath.row]objectForKey:@"IM_Price"]];
                
                if ([[[orderFinalArray objectAtIndex:indexPath.row]objectForKey:@"IM_TakeAwayYN"] isEqualToString:@"1"]) {
                    [[orderFinalCell finalTakeAway] setText:@"T"];
                    orderFinalCell.finalTakeAwayImg.image = [UIImage imageNamed:@"takeaway"];
                }
                else
                {
                    [[orderFinalCell finalTakeAway] setText:@""];
                    orderFinalCell.finalTakeAwayImg.image = [UIImage imageNamed:@"dinein"];
                }
                
                orderFinalCell.finalAmt.text = [NSString stringWithFormat:@"%0.2f",round(([[[orderFinalArray objectAtIndex:indexPath.row] objectForKey:@"IM_Price"] doubleValue] * [[[orderFinalArray objectAtIndex:indexPath.row] objectForKey:@"IM_Qty"] doubleValue])*100)/100];
                
                cellToReturn = orderFinalCell;
            }
            else
            {
                UINib *nib = [UINib nibWithNibName:@"OrderFinalDiscountCell" bundle:nil];
                [tableView registerNib:nib forCellReuseIdentifier:@"OrderFinalDiscountCell"];
                OrderFinalDiscountCell *orderFinalDiscountCell = [tableView dequeueReusableCellWithIdentifier:@"OrderFinalDiscountCell"];
                
                UIImageView *line = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, orderFinalDiscountCell.bounds.size.width, 1)];
                line.backgroundColor = [UIColor colorWithRed:196/255.0 green:196/255.0 blue:196/255.0 alpha:1.0];
                [orderFinalDiscountCell addSubview:line];
                line = nil;
                
                
                [[orderFinalDiscountCell finalDisDesc] setText:[NSString stringWithFormat:@"%@",[[orderFinalArray objectAtIndex:indexPath.row] objectForKey:@"IM_Description"]]];
                //[[orderFinalDiscountCell finalDisQty] setText:[[orderFinalArray objectAtIndex:indexPath.row]objectForKey:@"IM_Qty"]];
                
                [[orderFinalDiscountCell finalDisQty] setText:[NSString stringWithFormat:@"%.2f",[[[orderFinalArray objectAtIndex:indexPath.row]objectForKey:@"IM_Qty"] doubleValue]]];
                
                [[orderFinalDiscountCell finalDisPrice] setText:[[orderFinalArray objectAtIndex:indexPath.row]objectForKey:@"IM_Price"]];
                
                if ([[[orderFinalArray objectAtIndex:indexPath.row]objectForKey:@"IM_TakeAwayYN"] isEqualToString:@"1"]) {
                    [[orderFinalDiscountCell finalDisTakeAway] setText:@"T"];
                    orderFinalDiscountCell.finalDisTakeAwayImg.image = [UIImage imageNamed:@"takeaway"];
                }
                else
                {
                    [[orderFinalDiscountCell finalDisTakeAway] setText:@""];
                    orderFinalDiscountCell.finalDisTakeAwayImg.image = [UIImage imageNamed:@"dinein"];
                }
                
                orderFinalDiscountCell.finalDisDis.text = [NSString stringWithFormat:@"(%@)",[[orderFinalArray objectAtIndex:indexPath.row]objectForKey:@"IM_DiscountAmt"]];
                
                orderFinalDiscountCell.finalDisAmt.text = [NSString stringWithFormat:@"%0.2f",[[[orderFinalArray objectAtIndex:indexPath.row] objectForKey:@"IM_Price"] doubleValue] * [[[orderFinalArray objectAtIndex:indexPath.row] objectForKey:@"IM_Qty"] doubleValue]];
                
                cellToReturn = orderFinalDiscountCell;
            }
            indexOfParentArray = indexPath.row;
            
        }
        else if ([[[orderFinalArray objectAtIndex:indexPath.row]objectForKey:@"OrderType"] isEqualToString:@"PackageItemOrder"])
        {
            OrderFinalCell *orderFinalCell = [tableView dequeueReusableCellWithIdentifier:@"OrderFinalCell"];
            
            UIImageView *line = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, orderFinalCell.bounds.size.width, 1)];
            line.backgroundColor = [UIColor whiteColor];
            [orderFinalCell addSubview:line];
            line = nil;
            
            
            [[orderFinalCell finalDesc] setText:[NSString stringWithFormat:@"  ~  %@",[[orderFinalArray objectAtIndex:indexPath.row] objectForKey:@"IM_Description"]]];
            
            [[orderFinalCell finalQty] setText:@"1.00"];
            
            orderFinalCell.finalPrice.text = @"";
            
            orderFinalCell.finalAmt.text = @"";
            
            cellToReturn = orderFinalCell;
        }
        else
        {
            OrderFinalCell *orderFinalCell = [tableView dequeueReusableCellWithIdentifier:@"OrderFinalCell"];
            
            UIImageView *line = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, orderFinalCell.bounds.size.width, 1)];
            line.backgroundColor = [UIColor whiteColor];
            [orderFinalCell addSubview:line];
            line = nil;
             
            
            [[orderFinalCell finalDesc] setText:[NSString stringWithFormat:@"  ~    ~   %@",[[orderFinalArray objectAtIndex:indexPath.row] objectForKey:@"CDDescription"]]];
            
            [[orderFinalCell finalQty] setText:[NSString stringWithFormat:@"%.2f",([[[orderFinalArray objectAtIndex:indexPath.row]objectForKey:@"UnitQty"] doubleValue])]];
            
            orderFinalCell.finalPrice.text = @"";
            //[[orderFinalCell finalPrice] setText:[NSString stringWithFormat:@"%0.2f",[[[orderFinalArray objectAtIndex:indexPath.row]objectForKey:@"CDPrice"] doubleValue]]];
            orderFinalCell.finalAmt.text = @"";
            
            
            //NSLog(@"1. %f,2. %f,3. %f",[[[orderFinalArray objectAtIndex:indexPath.row] objectForKey:@"CDPrice"] doubleValue],[[[orderFinalArray objectAtIndex:indexOfParentArray] objectForKey:@"IM_Qty"] doubleValue],[[[orderFinalArray objectAtIndex:indexPath.row] objectForKey:@"UnitQty"] doubleValue]);
            
             //orderFinalCell.separatorInset = UIEdgeInsetsMake(0, 1000, 0, 0);
            cellToReturn = orderFinalCell;
        }
        
        
    }
    
    return cellToReturn;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.orderCatTableView) {
        
        isFiltered = @"False";
        self.orderSearchBar.text = @"";
        [self getItemMast:[[catergoryArray objectAtIndex:indexPath.row]objectForKey:@"IC_Category"]];
        categoryName = [[catergoryArray objectAtIndex:indexPath.row]objectForKey:@"IC_Category"];
    }
    else if (tableView == self.orderFinalTableView)
    {
        
        OrderDetailViewController *orderDetailViewController = [[OrderDetailViewController alloc]init];
        orderDetailViewController.delegate = self;
        
        if ([[[orderFinalArray objectAtIndex:indexPath.row] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"]) {
            updateCondimentDtlQtyFrom = @"OrderDetailModalView";
            [[LibraryAPI sharedInstance]setEditOrderDetail:[orderFinalArray objectAtIndex:indexPath.row]];
            orderDetailViewController.dataStatus = @"Edit";
            orderDetailViewController.position = indexPath.row;
            orderDetailViewController.tbName = _tableName;
            orderDetailViewController.odDineStatus = _tbStatus;
            [orderDetailViewController setModalPresentationStyle:UIModalPresentationFormSheet];
            [self presentViewController:orderDetailViewController animated:YES completion:nil];
        }
        else
        {
            if ([[[orderFinalArray objectAtIndex:indexPath.row] objectForKey:@"UnderPackageItemYN"] isEqualToString:@"Yes"]) {
                //NSLog(@"%@",@"Under package item");
                [self editPackageItemSelectionViewWithPackageItemIndex:[[orderFinalArray objectAtIndex:indexPath.row] objectForKey:@"PackageItemIndex"]];
                
                
            }
            else{
                updateCondimentDtlQtyFrom = @"OrderAddCondimentView";
                
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ParentIndex MATCHES[cd] %@",
                                          [[orderFinalArray objectAtIndex:indexPath.row]objectForKey:@"ParentIndex"]];
                
                OrderAddCondimentViewController *orderAddCondimentViewController = [[OrderAddCondimentViewController alloc]initWithNibName:@"OrderAddCondimentViewController" bundle:nil];
                orderAddCondimentViewController.delegate = self;
                orderAddCondimentViewController.addCondimentFrom = @"OrderingView";
                orderAddCondimentViewController.icItemCode = [[orderFinalArray objectAtIndex:indexPath.row] objectForKey:@"ItemCode"];
                orderAddCondimentViewController.selectedCHCode = [[orderFinalArray objectAtIndex:indexPath.row] objectForKey:@"CHCode"];
                orderAddCondimentViewController.icStatus = @"Edit";
                orderAddCondimentViewController.icAddedArray = [orderFinalArray filteredArrayUsingPredicate:predicate];
                
                
                UINavigationController *navbar = [[UINavigationController alloc]  initWithRootViewController:orderAddCondimentViewController];
                
                navbar.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                navbar.modalPresentationStyle = UIModalPresentationFormSheet;
                //navbar.modalPresentationStyle = UIModalPresentationPopover;
                navbar.popoverPresentationController.sourceView = self.view;
                navbar.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2, 1, 1);
                
                [orderAddCondimentViewController setModalPresentationStyle:UIModalPresentationFormSheet];
                [orderAddCondimentViewController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
                
                [self presentViewController:navbar animated:NO completion:nil];

            }
            
        }
        
        
        //[tableView deselectRowAtIndexPath:indexPath animated:YES];
        
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int height;
    if (tableView == self.orderCatTableView) {
        height = 132;
    }
    //else if (tableView == self.orderItemTableView)
    //{
      //  height = 150;
    //}
    else if (tableView == self.orderFinalTableView)
    {
        if ([[[orderFinalArray objectAtIndex:indexPath.row] objectForKey:@"IM_DiscountAmt"] isEqualToString:@"0.00"]) {
            height = 44;
        }
        else
        {
            height = 70;
        }
        
        if ([[[orderFinalArray objectAtIndex:indexPath.row] objectForKey:@"IM_TakeAwayYN"] isEqualToString:@"1"]) {
            //height = 70;
        }
        
    }
    return height;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView == self.orderFinalTableView) {
        if ([[[orderFinalArray objectAtIndex:indexPath.row] objectForKey:@"UnderPackageItemYN"] isEqualToString:@"Yes"]) {
            return NO;
        }
        else{
            return YES;
        }
        
    }
    else
    {
        return NO;
    }
    
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        directExit = @"No";
        //NSLog(@"%ld",(long)indexPath.row);
        if ([[[orderFinalArray objectAtIndex:indexPath.row] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"]) {
            
            NSMutableArray *discardedItems = [NSMutableArray array];
            //SomeObjectClass *item;
            [discardedItems addObject:[orderFinalArray objectAtIndex:indexPath.row]];
            for (int i = 0; i < orderFinalArray.count; i++)
            {
                if ([[[orderFinalArray objectAtIndex:i] objectForKey:@"ParentIndex"] isEqualToString:[NSString stringWithFormat:@"%lu",indexPath.row + 1]])
                {
                    [discardedItems addObject:[orderFinalArray objectAtIndex:i]];
                }
                else if ([[[orderFinalArray objectAtIndex:i] objectForKey:@"PackageItemIndex"] isEqualToString:[NSString stringWithFormat:@"%lu",indexPath.row + 1]])
                {
                    [discardedItems addObject:[orderFinalArray objectAtIndex:i]];
                }
                
            }
            
            if ([[[orderFinalArray objectAtIndex:indexPath.row] objectForKey:@"IM_Print"] isEqualToString:@"Printed"])
            {
                if ([_docType isEqualToString:@"SalesOrder"]) {
                    [self makeOrderViewKitchenReceiptWithOrderListArray:discardedItems KitchenAction:-1];
                }
                
            }
            
            [orderFinalArray removeObjectsInArray:discardedItems];
            discardedItems = nil;
            
            [self reIndexOrderFinalArray];
            [self recalculateAllGSTSalesOrder];
            [self groupCalcTotalForSalesOrder];
        }
        else
        {
            [self removeItemCondimentFromItemOrderWithIndexPath:indexPath];
        }
        
    }
    
    
}

-(void)removeItemCondimentFromItemOrderWithIndexPath:(NSIndexPath *)indexPath
{
    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"ParentIndex MATCHES[cd] %@",
                              [[orderFinalArray objectAtIndex:indexPath.row] objectForKey:@"ParentIndex"]];
    
    NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"CDCode MATCHES[cd] %@",
                              [[orderFinalArray objectAtIndex:indexPath.row] objectForKey:@"CDCode"]];
    
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate1, predicate2]];
    
    NSArray * selectedObject = [orderFinalArray filteredArrayUsingPredicate:predicate];
    int index = 0;
    double condimentSurcharge = 0;
    double totalCondimentSurcharge = 0;
    if (selectedObject.count > 0) {
        NSUInteger indexOfArray = 0;
        indexOfArray = [orderFinalArray indexOfObject:selectedObject[0]];
        index = [[[selectedObject objectAtIndex:0] objectForKey:@"ParentIndex"] integerValue] - 1;
        condimentSurcharge = [[[selectedObject objectAtIndex:0] objectForKey:@"UnitQty"] doubleValue] * [[[selectedObject objectAtIndex:0] objectForKey:@"CDPrice"] doubleValue];
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        totalCondimentSurcharge = [[[orderFinalArray objectAtIndex:index] objectForKey:@"IM_TotalCondimentSurCharge"] doubleValue] - condimentSurcharge;
        data = [orderFinalArray objectAtIndex:index];
        [data setValue:[NSString stringWithFormat:@"%0.2f",totalCondimentSurcharge] forKey:@"IM_NewTotalCondimentSurCharge"];
        [orderFinalArray replaceObjectAtIndex:index withObject:data];
        data = nil;
        [orderFinalArray removeObjectsInArray:selectedObject];
        [self reIndexOrderFinalArray];
        [self passSalesDataBack:orderFinalArray dataStatus:@"Edit" tablePosition:index ArrayIndex:index];
    }
    selectedObject = nil;
    
}

-(void)reIndexOrderFinalArray
{
    NSString *parentIndex;
    NSString *packageItemIndex;
    for (int i = 0; i < orderFinalArray.count; i++) {
        NSDictionary *data2 = [NSDictionary dictionary];
        data2 = [orderFinalArray objectAtIndex:i];
        if ([[[orderFinalArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"] || [[[orderFinalArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"PackageItemOrder"]) {
            [data2 setValue:[NSString stringWithFormat:@"%d",i + 1] forKey:@"Index"];
            parentIndex = [NSString stringWithFormat:@"%d",i + 1];
            
            if ([[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_ServiceType"] isEqualToString:@"1"]) {
                packageItemIndex = [NSString stringWithFormat:@"%d",i + 1];
            }
            
            if ([[[orderFinalArray objectAtIndex:i] objectForKey:@"PackageItemIndex"] length] > 0) {
                [data2 setValue:packageItemIndex forKey:@"PackageItemIndex"];
            }
        }
        else
        {
            [data2 setValue:parentIndex forKey:@"ParentIndex"];
            if ([[[orderFinalArray objectAtIndex:i] objectForKey:@"UnderPackageItemYN"] isEqualToString:@"Yes"]){
                [data2 setValue:packageItemIndex forKey:@"PackageItemIndex"];
            }
            
        }
        
        [orderFinalArray replaceObjectAtIndex:i withObject:data2];
        data2 = nil;
    }
    
    //NSLog(@"Checking - %@", orderFinalArray);
}


#pragma mark - sqllite

-(void)getItemCategory
{

    dbTable = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTable open]) {
        NSLog(@"Fail To Open Database");
        return;
    }
    
    [catergoryArray removeAllObjects];
    FMResultSet *rs = [dbTable executeQuery:@"Select * from ItemCatg order by IC_Category"];
    
    while ([rs next]) {
        [catergoryArray addObject: [rs resultDictionary]];
        
    }
    [rs close];
    [dbTable close];
    
    [self.orderCatTableView reloadData];
    
    categoryName = [[catergoryArray objectAtIndex:0] objectForKey:@"IC_Category"];
    [self getItemMast:[[catergoryArray objectAtIndex:0] objectForKey:@"IC_Category"]];
    printerIpArray = [PublicSqliteMethod getAllItemPrinterIpAddWithDBPath:dbPath];
    
}

-(void)getItemMast:(NSString *)imCategory
{
    
    [itemMastArray removeAllObjects];
    [keepAllItemArray removeAllObjects];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
             
             
        FMResultSet *rsItem = [db executeQuery:@"Select * from ItemMast order by IM_ItemCode"];
        
        while ([rsItem next]) {
            NSMutableDictionary *item1 = [NSMutableDictionary dictionary];
            
            [item1 setObject:[rsItem stringForColumn:@"IM_ItemNo"] forKey:@"IM_No"];
            [item1 setObject:[rsItem stringForColumn:@"IM_ItemCode"] forKey:@"IM_Code"];
            [item1 setObject:[rsItem stringForColumn:@"IM_Description"] forKey:@"IM_Desc"];
            [item1 setObject:[NSString stringWithFormat:@"%@%@",[rsItem stringForColumn:@"IM_ItemCode"],[rsItem stringForColumn:@"IM_Description"]] forKey:@"IM_Search"];
            [item1 setObject:[NSString stringWithFormat:@"%@.jpg",[rsItem stringForColumn:@"IM_FileName"]] forKey:@"IM_File"];
            [item1 setObject:[rsItem stringForColumn:@"IM_ServiceType"] forKey:@"IM_ServiceType"];
            [item1 setObject:[rsItem stringForColumn:@"IM_SalesPrice"] forKey:@"IM_Price"];
            [keepAllItemArray addObject:item1];
            
        }
        
        [rsItem close];
        
        FMResultSet *rs = [db executeQuery:@"Select * from ItemMast where IM_Category = ? order by IM_ItemCode",imCategory];
        
        while ([rs next]) {
            NSMutableDictionary *item1 = [NSMutableDictionary dictionary];
            
            [item1 setObject:[rs stringForColumn:@"IM_ItemNo"] forKey:@"IM_No"];
            [item1 setObject:[rs stringForColumn:@"IM_ItemCode"] forKey:@"IM_Code"];
            [item1 setObject:[rs stringForColumn:@"IM_Description"] forKey:@"IM_Desc"];
            [item1 setObject:[NSString stringWithFormat:@"%@.jpg",[rs stringForColumn:@"IM_FileName"]] forKey:@"IM_File"];
            [item1 setObject:[rs stringForColumn:@"IM_ServiceType"] forKey:@"IM_ServiceType"];
            [item1 setObject:[rs stringForColumn:@"IM_SalesPrice"] forKey:@"IM_Price"];
            
            itemMastCount++;
            [itemMastArray addObject:item1];
            
        }
        
        if (itemMastCount % 12 == 0) {
            itemMastCount = itemMastCount / 12;
        }
        else
        {
            itemMastCount = (itemMastCount / 12) + 1;
        }

        [rs close];
    }];
    
    [queue close];
    
    [self makeUiCollectionView];
    //[self.orderItemTableView reloadData];
    
}

-(void)makeUiCollectionView
{
    
    //_collectionViewMenu.contentInset = UIEdgeInsetsMake(0, 20, 0, 20);
    _collectionViewMenu.contentSize = CGSizeMake(_collectionViewMenu.frame.size.width * itemMastCount, _collectionViewMenu.frame.size.height);
    
    self.scrollViewSecret.contentSize = _collectionViewMenu.contentSize;
    [_collectionViewMenu addGestureRecognizer:self.scrollViewSecret.panGestureRecognizer];
    _collectionViewMenu.panGestureRecognizer.enabled = NO;
    _collectionViewMenu.pagingEnabled = true;
    [_collectionViewMenu reloadData];
    
    
}

-(void)filterItemMast:(NSString *)itemDesc
{
    dbTable = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTable open]) {
        NSLog(@"Fail To Open Database");
        return;
    }
    
    [itemMastArray removeAllObjects];
    
    FMResultSet *rs = [dbTable executeQuery:@"Select * from ItemMast where IM_Description like ? and IM_Category = ?",@"%",categoryName];
    
    while ([rs next]) {
        NSMutableDictionary *item1 = [NSMutableDictionary dictionary];
        
        [item1 setObject:[rs stringForColumn:@"IM_ItemNo"] forKey:@"IM_No"];
        [item1 setObject:[rs stringForColumn:@"IM_ItemCode"] forKey:@"IM_Code"];
        [item1 setObject:[rs stringForColumn:@"IM_Description"] forKey:@"IM_Desc"];
        [item1 setObject:[NSString stringWithFormat:@"%@.jpg",[rs stringForColumn:@"IM_FileName"]] forKey:@"IM_File"];
        [item1 setObject:[rs stringForColumn:@"IM_SalesPrice"] forKey:@"IM_Price"];
        
        itemMastCount++;
        [itemMastArray addObject:item1];
        item1 = nil;
        
    }
    
    if (itemMastCount % 12 == 0) {
        itemMastCount = itemMastCount / 12;
    }
    else
    {
        itemMastCount = (itemMastCount / 12) + 1;
    }
    
    
    [rs close];
    [dbTable close];
    //[self.orderItemTableView reloadData];
    //[self makeUiCollectionView];
    //[_collectionViewMenu reloadData];
    [self.collectionViewMenu reloadData];
    
}

-(void)checkTableStatus
{
    self.labelExSubtotal.text = @"0.00";
    [orderFinalArray removeAllObjects];
    dbTable = [FMDatabase databaseWithPath:dbPath];
    [partialSalesOrderArray removeAllObjects];
    if (![dbTable open]) {
        NSLog(@"Fail To Open Database");
        return;
    }
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        double totalQty = 0;
        [printSOArray removeAllObjects];
        FMResultSet *rs = [db executeQuery:@"Select * from Printer where P_Type = ?",@"Receipt"];
        
        while ([rs next]) {
            printerMode = [rs stringForColumn:@"P_Mode"];
            printerBrand = [rs stringForColumn:@"P_Brand"];
            printerName = [rs stringForColumn:@"P_PrinterName"];
            [printSOArray addObject:[rs resultDictionary]];
        }
        
        [rs close];
        
        FMResultSet *rs2 = [db executeQuery:@"Select TP_Name from TablePlan where TP_ID = ?",[NSNumber numberWithInt:selectedTableNo]];
        
        if ([rs2 next]) {
            tableDesc = [rs2 stringForColumn:@"TP_Name"];
        }
        
        [rs2 close];
        
        NSString *sqlCommand;
        FMResultSet *rs1;
        if ([_docType isEqualToString:@"CashSales"]) {
            sqlCommand = [PublicSqliteMethod generateCSOrderDataArray];
            rs1 = [db executeQuery:sqlCommand,_csDocNo];
        }
        else
        {
            sqlCommand = [PublicSqliteMethod generateSalesOrderDataArray];
            sqlCommand = [NSString stringWithFormat:@"%@ %@",sqlCommand,@"where s1.SOH_Table = ? and s1.SOH_DocNo = ? and s1.SOH_Status = 'New' order by SOD_AutoNo"];
            rs1 = [db executeQuery:sqlCommand, tableDesc,soNo];
        }
        
        sqlCommand = nil;
        
        
        while ([rs1 next]) {
            
            totalQty = totalQty + [rs1 doubleForColumn:@"IM_Qty"];
            if ([[LibraryAPI sharedInstance] getKioskMode] == 0) {
                self.btnSplitBill.enabled = YES;
            }
            else
            {
                self.btnSplitBill.enabled  = NO;
            }
            
            self.btnPrintSO.enabled = YES;
            self.btnVoidOrderBtn.enabled = YES;
            self.btnPrintSO.enabled = YES;
            orderDataStatus = @"Edit";
            docNo = [rs1 stringForColumn:@"DocNo"];
            
            NSMutableDictionary *data = [NSMutableDictionary dictionary];
            
            [data setObject:[rs1 stringForColumn:@"IM_ServiceType"] forKey:@"IM_ServiceType"];
            [data setObject:[rs1 stringForColumn:@"IM_ItemCode"] forKey:@"IM_ItemCode"];
            [data setObject:[rs1 stringForColumn:@"IM_ItemNo"] forKey:@"IM_ItemNo"];
            [data setObject:[rs1 stringForColumn:@"IM_Description"] forKey:@"IM_Description"];
            [data setObject:[NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"IM_Price"]] forKey:@"IM_Price"];
            //one item selling price not included tax
            [data setObject:[rs1 stringForColumn:@"IM_SellingPrice"] forKey:@"IM_SellingPrice"];
            [data setObject:[rs1 stringForColumn:@"IM_DiscountInPercent"] forKey:@"IM_DiscountInPercent"];
            [data setObject:[rs1 stringForColumn:@"IM_Tax"] forKey:@"IM_Tax"];
            [data setObject:[NSString stringWithFormat:@"%f",[rs1 doubleForColumn:@"IM_Qty"]] forKey:@"IM_Qty"];
            
            // control enable gst
            if (compEnableGst == 0) {
                [data setObject:@"0.00" forKey:@"IM_Gst"];
            }
            else
            {
                [data setObject:[rs1 stringForColumn:@"T_Percent"] forKey:@"IM_Gst"];
            }
            
            [data setObject:[rs1 stringForColumn:@"IM_TotalTax"] forKey:@"IM_TotalTax"]; //sum tax amt
            [data setObject:[rs1 stringForColumn:@"IM_DiscountType"]forKey:@"IM_DiscountType"];
            [data setObject:[rs1 stringForColumn:@"IM_Discount"] forKey:@"IM_Discount"]; // discount given
            [data setObject:[NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"IM_DiscountAmt"] ] forKey:@"IM_DiscountAmt"];  // sum discount
            [data setObject:[rs1 stringForColumn:@"IM_SubTotal"] forKey:@"IM_SubTotal"];
            [data setObject:[rs1 stringForColumn:@"IM_Total"] forKey:@"IM_Total"];
            [data setObject:[rs1 stringForColumn:@"IM_totalItemSellingAmt"]forKey:@"IM_totalItemSellingAmt"];  // subtotal not include tax n will replace this
            [data setObject:[rs1 stringForColumn:@"IM_totalItemSellingAmtLong"]forKey:@"IM_totalItemSellingAmtLong"];  // subtotal not include tax
            [data setObject:[rs1 stringForColumn:@"IM_totalItemTaxAmtLong"] forKey:@"IM_totalItemTaxAmtLong"];  // total tax amt
            
            [data setObject:[rs1 stringForColumn:@"IM_Remark"] forKey:@"IM_Remark"];
            
            //-------for kitchen receipt ---------
            [data setObject:@"Printed" forKey:@"IM_Print"];
            [data setObject:[NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"IM_Qty"]] forKey:@"IM_OrgQty"];
            [data setObject:[rs1 stringForColumn:@"IM_IpAddress"] forKey:@"IM_IpAddress"];
            [data setObject:[rs1 stringForColumn:@"IM_PrinterName"] forKey:@"IM_PrinterName"];
            //------------tax code-----------------
            [data setObject:[rs1 stringForColumn:@"IM_TaxCode"] forKey:@"IM_GSTCode"];
            
            //-------------service tax-------------
            [data setObject:[rs1 stringForColumn:@"IM_ServiceTaxCode"] forKey:@"IM_ServiceTaxCode"];  //svc tax code
            [data setObject:[rs1 stringForColumn:@"IM_ServiceTaxAmt"] forKey:@"IM_ServiceTaxAmt"]; // service tax amount
            [data setObject:[rs1 stringForColumn:@"IM_ServiceTaxRate"] forKey:@"IM_ServiceTaxRate"];
            serviceTaxGstTotal = [NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"SOH_DocServiceTaxGstAmt"]];
            
            //------for take away----------------
            [data setObject:[rs1 stringForColumn:@"IM_TakeAwayYN"] forKey:@"IM_TakeAwayYN"];
            
            // for table name
            [data setObject:[rs1 stringForColumn:@"IM_TableName"] forKey:@"IM_Table"];
            
            // for total pax
            [data setObject:_paxData forKey:@"SOH_PaxNo"];
            [data setObject:_docType forKey:@"PayDocType"];
            [data setObject:[NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"IM_TotalCondimentSurCharge"]] forKey:@"IM_TotalCondimentSurCharge"];
            [data setObject:[rs1 stringForColumn:@"SOD_ManualID"] forKey:@"SOD_ManualID"];
            //NSLog(@"Modifier ID : %@",[rs1 stringForColumn:@"SOD_ModifierID"]);
            [data setObject:[rs1 stringForColumn:@"SOD_ModifierID"] forKey:@"SOD_ModifierID"];
            [data setObject:[rs1 stringForColumn:@"SOD_ModifierHdrCode"] forKey:@"SOD_ModifierHdrCode"];
            [data setObject:[rs1 stringForColumn:@"MH_Description"] forKey:@"MH_Description"];
            
            [data setObject:@"ItemOrder" forKey:@"OrderType"];
            
            if ([_docType isEqualToString:@"CashSales"]) {
                [data setObject:[rs1 stringForColumn:@"SOD_DocNo"] forKey:@"InvDocNo"];
                [data setObject:[rs1 stringForColumn:@"SOH_Rounding"] forKey:@"SOH_Rounding"];
                [data setObject:[rs1 stringForColumn:@"SOH_DocSubTotal"] forKey:@"SOH_DocSubTotal"];
                [data setObject:[rs1 stringForColumn:@"SOH_DiscAmt"] forKey:@"SOH_DiscAmt"];
                [data setObject:[rs1 stringForColumn:@"SOH_DocAmt"] forKey:@"SOH_DocAmt"];
                [data setObject:[rs1 stringForColumn:@"SOH_DocTaxAmt"] forKey:@"SOH_DocTaxAmt"];
                [data setObject:[rs1 stringForColumn:@"SOH_DocServiceTaxAmt"] forKey:@"SOH_DocServiceTaxAmt"];
                
            }
            
            //------------------------------------
            self.labelTotalQty.text = [NSString stringWithFormat:@"%0.2f",totalQty];
            self.labelRound.text = [NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"SOH_Rounding"]];
            self.labelSubTotal.text = [NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"SOH_DocSubTotal"]];
            self.labelTotalDiscount.text = [NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"SOH_DiscAmt"]];
            self.labelTotal.text = [NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"SOH_DocAmt"]];
            self.labelTaxTotal.text = [NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"SOH_DocTaxAmt"]];
            self.labelServiceTaxTotal.text = [NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"SOH_DocServiceTaxAmt"]];
            self.labelExSubtotal.text = [NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"IM_totalItemSellingAmt"] + [self.labelExSubtotal.text doubleValue]];
            
            [data setObject:[rs1 stringForColumn:@"SOH_CustName"] forKey:@"CName"];
            [data setObject:[rs1 stringForColumn:@"SOH_CustAdd1"] forKey:@"CAdd1"];
            [data setObject:[rs1 stringForColumn:@"SOH_CustAdd2"] forKey:@"CAdd2"];
            [data setObject:[rs1 stringForColumn:@"SOH_CustAdd3"] forKey:@"CAdd3"];
            [data setObject:[rs1 stringForColumn:@"SOH_CustTelNo"] forKey:@"CTelNo"];
            [data setObject:[rs1 stringForColumn:@"SOH_CustGstNo"] forKey:@"CGstNo"];
            
            [partialSalesOrderArray addObject:data];
            data = nil;
            
            // only for edit bill using
            if ([_docType isEqualToString:@"CashSales"]) {
                tableDesc = [rs1 stringForColumn:@"IM_TableName"];
            }
            
        }
        
    }];
    
    [queue close];
    [dbTable close];
    
    //if (partialSalesOrderArray.count > 0) {
        [self startRecalculate];
    //}
    
}


-(void)startRecalculate
{
    //NSMutableDictionary *settingDict = [NSMutableDictionary dictionary];
    NSMutableArray *transferSalesArray = [[NSMutableArray alloc] init];
    NSMutableArray *recalcTransferSalesArray = [[NSMutableArray alloc] init];
    NSArray *recalcTransferArray;
    int tempEnableGst = 0;
    int tempEnableSVC = 0;
    
    for (int i = 0; i < partialSalesOrderArray.count; i++) {
        
        [orderCustomerInfo setValue:[[partialSalesOrderArray objectAtIndex:0] objectForKey:@"CName"] forKey:@"Name"];
        [orderCustomerInfo setValue:[[partialSalesOrderArray objectAtIndex:0] objectForKey:@"CAdd1"] forKey:@"Add1"];
        [orderCustomerInfo setValue:[[partialSalesOrderArray objectAtIndex:0] objectForKey:@"CAdd2"] forKey:@"Add2"];
        [orderCustomerInfo setValue:[[partialSalesOrderArray objectAtIndex:0] objectForKey:@"CAdd3"] forKey:@"Add3"];
        [orderCustomerInfo setValue:[[partialSalesOrderArray objectAtIndex:0] objectForKey:@"CTelNo"] forKey:@"TelNo"];
        [orderCustomerInfo setValue:[[partialSalesOrderArray objectAtIndex:0] objectForKey:@"CGstNo"] forKey:@"GstNo"];
        
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        
        [data setObject:[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"IM_DiscountInPercent"] forKey:@"DiscInPercent"];
        [data setObject:[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"IM_Qty"] forKey:@"ItemQty"];
        [data setObject:[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"IM_Discount"] forKey:@"DiscValue"];
        [data setObject:[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"IM_DiscountType"] forKey:@"DiscType"];
        [data setObject:[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"IM_DiscountAmt"] forKey:@"TotalDisc"];
        [data setObject:[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"IM_Remark"] forKey:@"Remark"];
        [data setObject:[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"IM_TotalCondimentSurCharge"] forKey:@"IM_TotalCondimentSurCharge"];
        [data setObject:[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"IM_OrgQty"] forKey:@"OrgQty"];
        
        //settingDict = [PublicSqliteMethod getGeneralnTableSettingWithTableName:tableDesc dbPath:dbPath];
        
        if ([[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"SOD_ModifierHdrCode"] length] > 0)
        {
            tempEnableGst = 0;
            tempEnableSVC = 0;
        }
        else
        {
            tempEnableGst = compEnableGst;
            tempEnableSVC = compEnableSVG;
        }
        
        transferSalesArray = [PublicSqliteMethod calcGSTByItemNo:[[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"IM_ItemNo"] integerValue] DBPath:dbPath ItemPrice:[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"IM_Price"] CompEnableGst:tempEnableGst CompEnableSVG:tempEnableSVC TableSVC:tpServiceTax2 OverrideSVG:_overrideTableSVC SalesOrderStatus:@"Edit" TaxType:[[LibraryAPI sharedInstance] getTaxType] TableName:tableDesc ItemDineStatus:[NSString stringWithFormat:@"%@",[NSNumber numberWithInt:[[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"IM_TakeAwayYN"]integerValue]]] TerminalType:terminalType SalesDict:data IMQty:@"0" KitchenStatus:@"Printed" PaxNo:_paxData DocType:_docType CondimentSubTotal:[[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"IM_TotalCondimentSurCharge"] doubleValue] ServiceChargeGstPercent:[[LibraryAPI sharedInstance] getServiceTaxGstPercent] TableDineStatus:_tbStatus];
        
        NSDictionary *data2 = [NSDictionary dictionary];
        data2 = [transferSalesArray objectAtIndex:0];
        [data2 setValue:[NSString stringWithFormat:@"%ld",orderFinalArray.count + 1] forKey:@"Index"];
        
        if ([[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"SOD_ModifierID"] length] > 0) {
            if ([[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"IM_ServiceType"] isEqualToString:@"0"]) {
                [data2 setValue:@"Yes" forKey:@"UnderPackageItemYN"];
                [data2 setValue:@"00" forKey:@"PackageItemIndex"];
                [data2 setValue:@"PackageItemOrder" forKey:@"OrderType"];
                [data2 setValue:@"1" forKey:@"PD_MinChoice"];
                if ([[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"SOD_ModifierHdrCode"] isEqualToString:[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"IM_ItemCode"]])
                {
                    [data2 setValue:@"ItemMast" forKey:@"PD_ItemType"];
                }
                else{
                    [data2 setValue:@"Modifier" forKey:@"PD_ItemType"];
                }
                [data2 setValue:[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"MH_Description"] forKey:@"MH_Description"];
                [data2 setValue:[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"SOD_ModifierHdrCode"] forKey:@"PD_ModifierHdrCode"];
            }
            
        }
        
        [transferSalesArray replaceObjectAtIndex:0 withObject:data2];
        data2 = nil;
        
        recalcTransferArray = [PublicSqliteMethod recalculateGSTSalesOrderWithSalesOrderArray:transferSalesArray TaxType:[[LibraryAPI sharedInstance] getTaxType]];
        
        [orderFinalArray addObjectsFromArray:recalcTransferArray];
        
        if ([_docType isEqualToString:@"CashSales"]) {
            [orderFinalArray addObjectsFromArray:[PublicSqliteMethod getInvoiceCondimentWithDBPath:dbPath InvoiceNo:[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"InvDocNo"] ItemCode:[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"IM_ItemCode"] ManualID:[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"SOD_ManualID"] ParentIndex:orderFinalArray.count]];
        }
        else
        {
            [orderFinalArray addObjectsFromArray:[PublicSqliteMethod getSalesOrderCondimentWithDBPath:dbPath SalesOrderNo:docNo ItemCode:[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"IM_ItemCode"] ManualID:[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"SOD_ManualID"] ParentIndex:orderFinalArray.count]];
        }
        
    }
    
    [self groupCalcTotalForSalesOrder];
    
    //settingDict = nil;
    transferSalesArray = nil;
    recalcTransferArray = nil;
    recalcTransferSalesArray = nil;
    //partialSalesOrderArray = nil;
    
    //NSLog(@"OrderFinalArray : %@",orderFinalArray);
}

-(void)recalculateAllGSTSalesOrder
{
    double itemExShort = 0.00;
    double itemExLong = 0.00;
    
    NSString *stringItemExLong;
    NSString *stringItemExShort;
    NSString *temp;
    double diffCent = 0.00;
    
    if ([taxType isEqualToString:@"Inc"]) {
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        for (int i = 0; i < orderFinalArray.count; i++) {
            if (![[[orderFinalArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"CondimentOrder"]) {
                data = [orderFinalArray objectAtIndex:i];
                [data setValue:[NSString stringWithFormat:@"%0.2f",[[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_totalItemSellingAmtLong" ] doubleValue]] forKey:@"IM_totalItemSellingAmt"];
                
                [data setValue:[NSString stringWithFormat:@"%0.2f",[[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_totalItemTaxAmtLong" ] doubleValue]] forKey:@"IM_TotalTax"];
                
                [orderFinalArray replaceObjectAtIndex:i withObject:data];
                
                itemExShort = itemExShort + [[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_totalItemSellingAmt"] doubleValue];
                stringItemExShort = [NSString stringWithFormat:@"%0.2f",itemExShort];
                
                itemExLong = itemExLong + [[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_totalItemSellingAmtLong"] doubleValue];
                stringItemExLong = [NSString stringWithFormat:@"%0.2f",itemExLong];
            }
            
            
        }
        
        if ([stringItemExLong doubleValue] != [stringItemExShort doubleValue]) {
            //itemExLong = [stringItemExLong doubleValue] - [stringItemExShort doubleValue];
            itemExLong = itemExLong - itemExShort;
            temp = [NSString stringWithFormat:@"%0.2f",itemExLong];
            diffCent = [temp doubleValue];
            
        }
        else
        {
            diffCent = 0.00;
        }
        
    }
}

-(void)addToSalesOrder:(id)sender
{
    
    NSDate *today = [NSDate date];
    
    NSDateFormatter *dateFormat = [[LibraryAPI sharedInstance] getDateFormaterhhmmss];
    NSString *dateString = [dateFormat stringFromDate:today];
    
    //BOOL result;
    if (orderFinalArray.count == 0) {
        [self showAlertView:@"Order list is empty" title:@"Warning"];
        return;
    }
    
    if ([terminalType isEqualToString:@"Terminal"]) {
        
        NSArray *allPeers = [_appDelegate.mcManager.session connectedPeers];
        int connectionFlag = 0;
        for (int i = 0; i < allPeers.count; i++) {
            specificPeer = [allPeers objectAtIndex:i];
            
            if ([specificPeer.displayName isEqualToString:@"Server"]) {
                connectionFlag = 1;
                break;
            }
            
        }
        allPeers = nil;
        
        if (connectionFlag == 0) {
            [[_appDelegate mcManager] setupPeerAndSessionWithDisplayName:[[LibraryAPI sharedInstance] getTerminalDeviceName]];
            [[_appDelegate mcManager] setupMCBrowser];
            [self showAlertView:@"Server disconnect. Make sure server is on and try again." title:@"Warning"];
            return;
        }
    }
    
    [self makeOrderViewKitchenReceiptWithOrderListArray:orderFinalArray KitchenAction:1];
    
    if ([orderDataStatus isEqualToString:@"New"]) {
        if ([terminalType isEqualToString:@"Terminal"]) {
            [self sendOrderToServer];
        }
        else
        {
            [self insertIntoSalesOrder:dateString payType:@"sales"];
        }
        
    }
    else
    {
        if ([terminalType isEqualToString:@"Terminal"]) {
            [self sendOrderToServer];
        }
        else
        {
            [self updateSetSalesOrder:dateString PayType:@"sales"];
        }
        
    }
    
    if ([terminalType isEqualToString:@"Terminal"]) {
        //if([[_appDelegate.mcManager connectedPeerArray]count] > 0) {
            [self printOutKitchenReceipt];
        //}
    }
    else
    {
        [self printOutKitchenReceipt];
    }
    
    //[self makeKitchenReceipt];
    
}



-(BOOL)insertIntoSalesOrder:(NSString *)date payType:(NSString *)payType
{
    dbTable = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTable open]) {
        NSLog(@"Fail To Open Database");
        return false;
    }
    __block BOOL inserResult;
    
    
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSUInteger taxIncludedYN = 0;
        NSString *modifierID = @"";
        NSString *modifierHdrCode = @"";
        
        if ([[[LibraryAPI sharedInstance] getTaxType] isEqualToString:@"IEx"]) {
            taxIncludedYN = 0;
        }
        else
        {
            taxIncludedYN = 1;
        }
        
        FMResultSet *docRs = [db executeQuery:@"Select DOC_Number,DOC_Header from DocNo"
                              " where DOC_Header = 'SO'"];
        int updateDocNo = 0;
        if ([docRs next]) {
            updateDocNo = [docRs intForColumn:@"DOC_Number"] + 1;
            docNo = [NSString stringWithFormat:@"%@%09.f",[docRs stringForColumn:@"DOC_Header"],[[docRs stringForColumn:@"DOC_Number"]doubleValue] + 1];
        }
        [docRs close];
        
        
        
        dbNoError = [db executeUpdate:@"Insert into SalesOrderHdr ("
                     "SOH_DocNo,SOH_Date,SOH_DocAmt,SOH_DiscAmt,SOH_Rounding,SOH_Table,SOH_User,SOH_AcctCode,SOH_Status, SOH_DocSubTotal,SOH_DocTaxAmt,SOH_DocServiceTaxAmt,SOH_DocServiceTaxGstAmt,SOH_PaxNo,SOH_TerminalName,SOH_TaxIncluded_YN,SOH_ServiceTaxGstCode,SOH_CustName,SOH_CustAdd1,SOH_CustAdd2,SOH_CustAdd3,SOH_CustTelNo,SOH_CustGstNo)"
                     "values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",docNo,date,self.labelTotal.text,self.labelTotalDiscount.text,self.labelRound.text,_tableName,[[LibraryAPI sharedInstance] getUserName],@"Cash",@"New",self.labelSubTotal.text,self.labelTaxTotal.text,self.labelServiceTaxTotal.text,serviceTaxGstTotal,_paxData,@"Server",[NSNumber numberWithInteger:taxIncludedYN],[[LibraryAPI sharedInstance] getServiceTaxGstCode],[orderCustomerInfo objectForKey:@"Name"],[orderCustomerInfo objectForKey:@"Add1"],[orderCustomerInfo objectForKey:@"Add2"],[orderCustomerInfo objectForKey:@"Add3"],[orderCustomerInfo objectForKey:@"TelNo"],[orderCustomerInfo objectForKey:@"GstNo"]];
        if (dbNoError) {
            @try {
            for (int i = 0; i < orderFinalArray.count; i++) {
                if ([[[orderFinalArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"] ||
                    [[[orderFinalArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"PackageItemOrder"])
                {
                    if ([[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_ServiceType"] isEqualToString:@"1"])
                    {
                        modifierID = [NSString stringWithFormat:@"M%@-%@",docNo,[[orderFinalArray objectAtIndex:i] objectForKey:@"Index"]];
                    }
                    else
                    {
                        if ([[[orderFinalArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"]) {
                            modifierID = @"";
                        }
                    }
                    
                    if ([[[orderFinalArray objectAtIndex:i] objectForKey:@"PD_ModifierHdrCode"] length] > 0) {
                        modifierHdrCode = [[orderFinalArray objectAtIndex:i] objectForKey:@"PD_ModifierHdrCode"];
                    }
                    else{
                        modifierHdrCode = @"";
                    }
                    
                    dbNoError = [db executeUpdate:@"Insert into SalesOrderDtl "
                                 "(SOD_AcctCode, SOD_DocNo, SOD_ItemCode, SOD_ItemDescription, SOD_Quantity, SOD_Price, SOD_DiscValue, SOD_SellingPrice, SOD_UnitPrice, SOD_Remark, SOD_TakeAway_YN,SOD_DiscType,SOD_SellTax,SOD_TotalSalesTax,SOD_TotalSalesTaxLong,SOD_TotalEx,SOD_TotalExLong,SOD_TotalInc,SOD_TotalDisc,SOD_SubTotal,SOD_DiscInPercent, SOD_TaxCode, SOD_ServiceTaxCode, SOD_ServiceTaxAmt, SOD_TaxRate,SOD_ServiceTaxRate,SOD_TakeAwayYN, SOD_TotalCondimentSurCharge,SOD_ManualID,SOD_TerminalName, SOD_ModifierID, SOD_ModifierHdrCode) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",@"Cash",docNo,[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_ItemCode"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Description"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Qty"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_SalesPrice"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Discount"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_SellingPrice"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Price"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Remark"],[NSNumber numberWithInt:0],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_DiscountType"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Tax"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_TotalTax"],
                                 [[orderFinalArray objectAtIndex:i] objectForKey:@"IM_totalItemTaxAmtLong"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_totalItemSellingAmt"],
                                 [[orderFinalArray objectAtIndex:i] objectForKey:@"IM_totalItemSellingAmtLong"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Total"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_DiscountAmt"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_SubTotal"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_DiscountInPercent"],([[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_GSTCode"] isEqualToString:@"-"])?nil:[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_GSTCode"],([[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_ServiceTaxCode"] isEqualToString:@"-"])?nil:[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_ServiceTaxCode"],[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_ServiceTaxAmt"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Gst"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_ServiceTaxRate"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_TakeAwayYN"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_TotalCondimentSurCharge"],[NSString stringWithFormat:@"%@-%@",docNo,[[orderFinalArray objectAtIndex:i] objectForKey:@"Index"]],@"Server", modifierID, modifierHdrCode];
                }
                else if([[[orderFinalArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"CondimentOrder"])
                {
                    dbNoError = [db executeUpdate:@"Insert into SalesOrderCondiment"
                                 " (SOC_DocNo, SOC_ItemCode, SOC_CHCode, SOC_CDCode, SOC_CDDescription, SOC_CDPrice, SOC_CDDiscount, SOC_DateTime,SOC_CDQty,SOC_CDManualKey) Values (?,?,?,?,?,?,?,?,?,?)",docNo,[[orderFinalArray objectAtIndex:i] objectForKey:@"ItemCode"],[[orderFinalArray objectAtIndex:i] objectForKey:@"CHCode"],[[orderFinalArray objectAtIndex:i] objectForKey:@"CDCode"],[[orderFinalArray objectAtIndex:i] objectForKey:@"CDDescription"],[[orderFinalArray objectAtIndex:i] objectForKey:@"CDPrice"],[NSNumber numberWithDouble:0.00],date,[[orderFinalArray objectAtIndex:i] objectForKey:@"UnitQty"],[NSString stringWithFormat:@"%@-%@",docNo,[[orderFinalArray objectAtIndex:i] objectForKey:@"ParentIndex"]]];
                }
                else
                {
                    [db executeUpdate:@"Insert into Sa"];
                }
                
                
                
                if (!dbNoError) {
                    
                    [self showAlertView:[db lastErrorMessage] title:@"Fail"];
                    *rollback = YES;
                    inserResult = false;
                    return;
                }
                else
                {
                    dbNoError = [db executeUpdate:@"Update DocNo set DOC_Number = ? where DOC_Header = 'SO'",[NSNumber numberWithInt:updateDocNo]];
                    if (!dbNoError) {
                        
                        [self showAlertView:[db lastErrorMessage] title:@"Fail"];
                        *rollback = YES;
                        inserResult = false;
                        return;
                    }
                }
            }
                
            }
            
            @catch(NSException *theException) {
                [self showAlertView:theException.reason title:@"Exception error"];
                *rollback = YES;
                inserResult = false;
                return;
                
            } @finally {
                if ([payType isEqualToString:@"sales"]) {
                    //[self showAlertView:@"Data Save" title:@"Success"];
                    inserResult = true;
                    [self clearExistingArrayMemory];
                    [self.navigationController popViewControllerAnimated:NO];
                    
                }
                else if([payType isEqualToString:@"direct"])
                {
                    inserResult = true;
                }
            }
                
            
            
        }
        else
        {
            //NSLog(@"%@",[dbTable lastErrorMessage]);
            [self showAlertView:[dbTable lastErrorMessage] title:@"Fail"];
        }
        
        
    }];
    
    [queue close];
    
    [dbTable close];
    
    
    return inserResult;
}


-(BOOL)updateSetSalesOrder:(NSString *)date PayType:(NSString *)payType
{
    __block BOOL updateResult;
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSUInteger taxIncludedYN = 0;
        NSString *modifierID = @"";
        NSString *modifierHdrCode = @"";
        
        if ([[[LibraryAPI sharedInstance] getTaxType] isEqualToString:@"IEx"]) {
            taxIncludedYN = 0;
        }
        else
        {
            taxIncludedYN = 1;
        }
        
        dbNoError = [db executeUpdate:@"Update SalesOrderHdr set "
                     " SOH_Date = ?, SOH_DocAmt = ?, SOH_DiscAmt = ?, SOH_Rounding = ?, SOH_Table = ?"
                     ", SOH_User = ?, SOH_AcctCode = ?, SOH_Status = ?, SOH_DocSubTotal = ?,SOH_DocTaxAmt=?, SOH_DocServiceTaxAmt = ?, SOH_DocServiceTaxGstAmt =?, SOH_PaxNo = ?, SOH_TaxIncluded_YN = ?, SOH_ServiceTaxGstCode = ?, SOH_CustName = ?,SOH_CustAdd1 = ?,SOH_CustAdd2 = ?,SOH_CustAdd3 = ?,SOH_CustTelNo = ?,SOH_CustGstNo = ? where SOH_DocNo = ?",
                date,self.labelTotal.text,self.labelTotalDiscount.text,self.labelRound.text ,_tableName,[[LibraryAPI sharedInstance] getUserName],@"Cash",@"New",self.labelSubTotal.text,self.labelTaxTotal.text,self.labelServiceTaxTotal.text,serviceTaxGstTotal,_paxData,[NSNumber numberWithInteger:taxIncludedYN],[[LibraryAPI sharedInstance] getServiceTaxGstCode],[orderCustomerInfo objectForKey:@"Name"],[orderCustomerInfo objectForKey:@"Add1"],[orderCustomerInfo objectForKey:@"Add2"],[orderCustomerInfo objectForKey:@"Add3"],[orderCustomerInfo objectForKey:@"TelNo"],[orderCustomerInfo objectForKey:@"GstNo"],docNo];
    
        
        if (dbNoError) {
            dbNoError = [db executeUpdate:@"Delete from SalesOrderDtl where SOD_DocNo = ?", docNo];
            dbNoError = [db executeUpdate:@"Delete from SalesOrderCondiment where SOC_DocNo = ?", docNo];
            if (!dbNoError) {
                NSLog(@"%@",[dbTable lastErrorMessage]);
                *rollback = YES;
                updateResult = false;
                [self showAlertView:[dbTable lastErrorMessage] title:@"Fail"];
                return;
            }
            else
            {
                @try
                {
                for (int i = 0; i < orderFinalArray.count; i++) {
                    if ([[[orderFinalArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"] ||
                        [[[orderFinalArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"PackageItemOrder"])
                    {
                        if ([[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_ServiceType"] isEqualToString:@"1"])
                        {
                            modifierID = [NSString stringWithFormat:@"M%@-%@",docNo,[[orderFinalArray objectAtIndex:i] objectForKey:@"Index"]];
                        }
                        else
                        {
                            if ([[[orderFinalArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"]) {
                                modifierID = @"";
                            }
                        }
                        
                        if ([[[orderFinalArray objectAtIndex:i] objectForKey:@"PD_ModifierHdrCode"] length] > 0) {
                            modifierHdrCode = [[orderFinalArray objectAtIndex:i] objectForKey:@"PD_ModifierHdrCode"];
                        }
                        else{
                            modifierHdrCode = @"";
                        }
                        
                        dbNoError = [db executeUpdate:@"Insert into SalesOrderDtl "
                                     "(SOD_AcctCode, SOD_DocNo, SOD_ItemCode, SOD_ItemDescription, SOD_Quantity, SOD_Price, SOD_DiscValue, SOD_SellingPrice, SOD_UnitPrice, SOD_Remark, SOD_TakeAway_YN,SOD_DiscType,SOD_SellTax,SOD_TotalSalesTax,SOD_TotalSalesTaxLong,SOD_TotalEx,SOD_TotalExLong,SOD_TotalInc,SOD_TotalDisc,SOD_SubTotal,SOD_DiscInPercent,SOd_TaxCode,SOD_ServiceTaxCode, SOD_ServiceTaxAmt, SOD_TaxRate,SOD_ServiceTaxRate,SOD_TakeAwayYN,SOD_TotalCondimentSurCharge, SOD_ManualID, SOD_ModifierID, SOD_ModifierHdrCode) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",@"Cash",docNo,[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_ItemCode"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Description"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Qty"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_SalesPrice"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Discount"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_SellingPrice"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Price"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Remark"],[NSNumber numberWithInt:0],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_DiscountType"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Tax"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_TotalTax"],
                                     [[orderFinalArray objectAtIndex:i] objectForKey:@"IM_totalItemTaxAmtLong"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_totalItemSellingAmt"],
                                     [[orderFinalArray objectAtIndex:i] objectForKey:@"IM_totalItemSellingAmtLong"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Total"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_DiscountAmt"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_SubTotal"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_DiscountInPercent"],([[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_GSTCode"] isEqualToString:@"-"])?nil:[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_GSTCode"],([[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_ServiceTaxCode"] isEqualToString:@"-"])?nil:[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_ServiceTaxCode"],[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_ServiceTaxAmt"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Gst"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_ServiceTaxRate"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_TakeAwayYN"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_TotalCondimentSurCharge"],[NSString stringWithFormat:@"%@-%@",docNo,[[orderFinalArray objectAtIndex:i] objectForKey:@"Index"]], modifierID, modifierHdrCode];

                        
                    }
                    else
                    {
                        dbNoError = [db executeUpdate:@"Insert into SalesOrderCondiment"
                                     " (SOC_DocNo, SOC_ItemCode, SOC_CHCode, SOC_CDCode, SOC_CDDescription, SOC_CDPrice, SOC_CDDiscount, SOC_DateTime,SOC_CDQty,SOC_CDManualKey) Values (?,?,?,?,?,?,?,?,?,?)",docNo,[[orderFinalArray objectAtIndex:i] objectForKey:@"ItemCode"],[[orderFinalArray objectAtIndex:i] objectForKey:@"CHCode"],[[orderFinalArray objectAtIndex:i] objectForKey:@"CDCode"],[[orderFinalArray objectAtIndex:i] objectForKey:@"CDDescription"],[[orderFinalArray objectAtIndex:i] objectForKey:@"CDPrice"],[NSNumber numberWithDouble:0.00],date,[[orderFinalArray objectAtIndex:i] objectForKey:@"UnitQty"],[NSString stringWithFormat:@"%@-%@",docNo,[[orderFinalArray objectAtIndex:i] objectForKey:@"ParentIndex"]]];
                    }
                    
                    if (!dbNoError) {
                        //NSLog(@"%@",[dbTable lastErrorMessage]);
                        *rollback = YES;
                        updateResult = false;
                        [self showAlertView:[dbTable lastErrorMessage] title:@"Fail"];
                        return;
                    }
                    
                }
                
                    
                }
                @catch(NSException *theException){
                    [self showAlertView:theException.reason title:@"Exception Error"];
                    *rollback = YES;
                    updateResult = false;
                    return;
                }
                @finally
                {
                    if (![payType isEqualToString:@"direct"]) {
                        //[self showAlertView:@"Data Updated" title:@"Success"];
                        updateResult = true;
                        [self clearExistingArrayMemory];
                        [self.navigationController popViewControllerAnimated:NO];
                    }
                    else
                    {
                        updateResult = true;
                    }
                }

            }
            
        }
        else
        {
            //NSLog(@"%@",[dbTable lastErrorMessage]);
            updateResult = false;
            [self showAlertView:[dbTable lastErrorMessage] title:@"Fail"];
            return;
        }
        
        
    }];
    
    [queue close];
    return updateResult;
}

-(void)deleteSalesOrder
{
    dbTable = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTable open]) {
        NSLog(@"Fail To Open Database");
        return;
    }
    
    dbNoError = [dbTable executeUpdate:@"Update SalesOrderHdr set SOH_Status = ? where SOH_DocNo = ?",@"Void",docNo];
    if (!dbNoError) {
        [self showAlertView:[dbTable lastErrorMessage] title:@"Fail"];
        return;
    }
    else
    {
        [self.navigationController popViewControllerAnimated:YES];
        [self showAlertView:@"Order voided" title:@"Success"];
    }
    
    [dbTable close];
    
    
}

#pragma mark - alertView

-(void)showAlertView:(NSString *)msg title:(NSString *)title
{
    alertType = @"Alert";
    UIAlertController * alert = [[LibraryAPI sharedInstance] showAlertViewWithMsg:msg Title:title];
    
    [self presentViewController:alert animated:YES completion:nil];
    
    alert = nil;
    /*
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:msg
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
     */
}




#pragma mark - calc price
-(void)groupCalcItemPrice:(int)itemNo ItemQty:(NSString *)im_Qty KitchReceiptStatus:(NSString *)kRStatus TotalCondimentPrice:(double)totalCondimentPrice TotalCondimentUnitPrice:(double)totalCondimentUnitPrice ReplacedIndex:(NSString *)replacedIndex
{
    
    NSMutableArray *calculatedSalesArray;
    calculatedSalesArray = [[NSMutableArray alloc]init];
    NSArray *recalcSalesArray;
    [calculatedSalesArray removeAllObjects];
    NSDictionary *data = [NSDictionary dictionary];
    
    calculatedSalesArray = [PublicSqliteMethod calcGSTByItemNo:itemNo DBPath:dbPath ItemPrice:@"0.00" CompEnableGst:compEnableGst CompEnableSVG:compEnableSVG TableSVC:tpServiceTax2 OverrideSVG:_overrideTableSVC SalesOrderStatus:@"New" TaxType:taxType TableName:_tableName ItemDineStatus:_tbStatus TerminalType:terminalType SalesDict:nil IMQty:im_Qty KitchenStatus:kRStatus PaxNo:_paxData DocType:_docType CondimentSubTotal:totalCondimentPrice ServiceChargeGstPercent:[[LibraryAPI sharedInstance] getServiceTaxGstPercent] TableDineStatus:_tbStatus];
    
    data = [calculatedSalesArray objectAtIndex:0];
    [data setValue:[NSString stringWithFormat:@"%ld",orderFinalArray.count + 1] forKey:@"Index"];
    [calculatedSalesArray replaceObjectAtIndex:0 withObject:data];
    data = nil;
    
    
    recalcSalesArray = [PublicSqliteMethod recalculateGSTSalesOrderWithSalesOrderArray:calculatedSalesArray TaxType:[[LibraryAPI sharedInstance] getTaxType]];
    
    if (![replacedIndex isEqualToString:@"-"]) {
        [orderFinalArray replaceObjectAtIndex:[replacedIndex integerValue] withObject:[recalcSalesArray objectAtIndex:0]];
    }
    else
    {
        [orderFinalArray addObjectsFromArray:recalcSalesArray];
    }
    
    [self recalculateAllGSTSalesOrder]; // same as recalculateGSTSalesOrderWithSalesOrderArray to make sure calculation is correct
    
    [self groupCalcTotalForSalesOrder]; // sum the total of order
    
    calculatedSalesArray = nil;
    recalcSalesArray = nil;
    
}

-(void)groupCalcTotalForSalesOrder
{
    NSDictionary *totalDict = [NSDictionary dictionary];
    double adjTaxForSVCEnable = 0.00;
    NSString *totalTaxableAmt = @"0.00";
    NSString *totalTaxAmt = @"0.00";
    totalDict = [PublicSqliteMethod calclateSalesTotalWith:orderFinalArray TaxType:taxType ServiceTaxGst:serviceTaxGst DBPath:dbPath];
    
    adjTaxForSVCEnable = [self doAdjustmentForTaxIncWith:[totalDict objectForKey:@"TotalItemTax"] TaxTotal:[totalDict objectForKey:@"TotalGst"] duuu:[totalDict objectForKey:@"duuu"] dccc:[totalDict objectForKey:@"dccc"]];
    
    if ([[LibraryAPI sharedInstance] getEnableSVG] == 0) {
        for (int i = 0; i < orderFinalArray.count; i++) {
            totalTaxableAmt = [NSString stringWithFormat:@"%0.2f",[[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_totalItemSellingAmt"] doubleValue] + [totalTaxableAmt doubleValue]];
            totalTaxAmt = [NSString stringWithFormat:@"%0.2f",[[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_TotalTax"] doubleValue] + [totalTaxAmt doubleValue]];
        }
    }
    else
    {
        totalTaxableAmt = [totalDict objectForKey:@"SubTotalEx"];
        totalTaxAmt = [totalDict objectForKey:@"TotalGst"];
    }
    
    self.labelExSubtotal.text = totalTaxableAmt;
    serviceTaxGstTotal = [totalDict objectForKey:@"TotalServiceChargeGst"];
    
    self.labelSubTotal.text = [totalDict objectForKey:@"SubTotal"];
    self.labelTaxTotal.text = totalTaxAmt;
    self.labelTotal.text = [totalDict objectForKey:@"Total"];
    self.labelTotalDiscount.text = [totalDict objectForKey:@"TotalDiscount"];
    self.labelServiceTaxTotal.text = [totalDict objectForKey:@"ServiceCharge"];
    self.labelTotalQty.text = [totalDict objectForKey:@"TotalQty"];
    self.labelRound.text = [totalDict objectForKey:@"Rounding"];
    
    if ([terminalType isEqualToString:@"Terminal"]) {
        if (orderFinalArray.count > 0) {
            NSMutableDictionary *data2 = [NSMutableDictionary dictionary];
            
            data2 = [orderFinalArray objectAtIndex:0];
            [data2 setValue:self.labelTotal.text forKey:@"IM_labelTotal"];
            [data2 setValue:self.labelTotalDiscount.text forKey:@"IM_labelTotalDiscount"];
            [data2 setValue:self.labelRound.text forKey:@"IM_labelRound"];
            [data2 setValue:self.labelSubTotal.text forKey:@"IM_labelSubTotal"];
            [data2 setValue:self.labelTaxTotal.text forKey:@"IM_labelTaxTotal"];
            [data2 setValue:self.labelServiceTaxTotal.text forKey:@"IM_labelServiceTaxTotal"];
            [data2 setValue:serviceTaxGstTotal forKey:@"IM_serviceTaxGstTotal"];
            
            [orderFinalArray replaceObjectAtIndex:0 withObject:data2];
            data2 = nil;
        }
    }
    
    if ([_docType isEqualToString:@"CashSales"]) {
        if (orderFinalArray.count > 0) {
            NSMutableDictionary *data2 = [NSMutableDictionary dictionary];
            
            data2 = [orderFinalArray objectAtIndex:0];
            [data2 setValue:self.labelTotal.text forKey:@"SOH_DocAmt"];
            [data2 setValue:self.labelTotalDiscount.text forKey:@"SOH_DiscAmt"];
            [data2 setValue:self.labelRound.text forKey:@"SOH_Rounding"];
            [data2 setValue:self.labelSubTotal.text forKey:@"SOH_DocSubTotal"];
            [data2 setValue:self.labelTaxTotal.text forKey:@"SOH_DocTaxAmt"];
            [data2 setValue:self.labelServiceTaxTotal.text forKey:@"SOH_DocServiceTaxAmt"];
            [data2 setValue:serviceTaxGstTotal forKey:@"SOH_DocServiceTaxGstAmt"];
            [data2 setValue:_csDocNo forKey:@"SOH_DocNo"];
            [orderFinalArray replaceObjectAtIndex:0 withObject:data2];
            data2 = nil;
        }
       
        
    }
    
    [self.orderFinalTableView reloadData];
    [self reIndexOrderFinalArray];
    totalDict = nil;
    
    if (orderFinalArray.count > 0) {
        long lastRowNumber = [self.orderFinalTableView numberOfRowsInSection:0] - 1;
        NSIndexPath *ip = [NSIndexPath indexPathForRow:lastRowNumber inSection:0];
        [self.orderFinalTableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

-(double)doAdjustmentForTaxIncWith:(NSString *)labelTotalItemTax TaxTotal:(NSString *)labelTaxTotal duuu:(NSString *)duuu dccc:(NSString *)dccc
{
    if (![taxType isEqualToString:@"IEx"]) {
        NSString *finalTotalSellingFigure2;
        NSString *finalTotalTax2;
        double adjTax = 0.00;
        
        labelTotalItemTax = [NSString stringWithFormat:@"%.02f",[labelTotalItemTax doubleValue]  + [serviceTaxGstTotal doubleValue]];
        NSLog(@"%@   %@",duuu, dccc);
        adjTax = [[NSString stringWithFormat:@"%0.2f",[dccc doubleValue] - [duuu doubleValue]] doubleValue];
        if (adjTax != 0.00) {
            
            NSMutableDictionary *data2 = [NSMutableDictionary dictionary];
            if (compEnableSVG == 0) {
                int rowCount = 1;
                if ([[[orderFinalArray objectAtIndex:orderFinalArray.count - 1] objectForKey:@"IM_GSTCode"] isEqualToString:@"SR"]) {
                    rowCount = 1;
                }
                else
                {
                    rowCount = 2;
                }
                finalTotalSellingFigure2 = [NSString stringWithFormat:@"%.02f",[[[orderFinalArray objectAtIndex:orderFinalArray.count - rowCount] objectForKey:@"IM_totalItemSellingAmt"] doubleValue] - adjTax];
                
                finalTotalTax2 = [NSString stringWithFormat:@"%.02f",[[[orderFinalArray objectAtIndex:orderFinalArray.count - rowCount] objectForKey:@"IM_TotalTax"] doubleValue] + adjTax];
                data2 = [orderFinalArray objectAtIndex:orderFinalArray.count - rowCount];
                [data2 setValue:[NSString stringWithFormat:@"%@",finalTotalSellingFigure2] forKey:@"IM_totalItemSellingAmt"];
                [data2 setValue:[NSString stringWithFormat:@"%@",finalTotalTax2] forKey:@"IM_TotalTax"];
                NSLog(@"Total Ex:%@",self.labelExSubtotal.text);
                [orderFinalArray replaceObjectAtIndex:orderFinalArray.count - rowCount withObject:data2];
                return 0.00;
            }
            else
            {
                return adjTax;
            }
            //self.labelExSubtotal.text = [NSString stringWithFormat:@"%0.2f",[self.labelExSubtotal.text doubleValue] - adjTax];
            
        }
        else
        {
            return 0.00;
        }
    }
    else
    {
        return 0.00;
    }
}

/*
-(void)getCalcItemPrice:(long) im_ItemNo
{
    NSString *textTotalTax;
    NSString *textSubTotal;
    NSString *textTotal;
    NSMutableArray *salesArray;
    NSString *textServiceTax;
    double serviceTaxRate;
    salesArray = [[NSMutableArray alloc]init];
    dbTable = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTable open]) {
        NSLog(@"Fail To Open Database");
        return;
    }
    
    FMResultSet *rs = [dbTable executeQuery:@"Select ItemMast.*, IFNULL(t1.T_Percent,'0') as T_Percent, IFNULL(t1.T_Name,'-') as T_Name, IFNULL(t2.T_Percent,'0') as Svc_Percent, IFNULL(t2.T_Name,'-') as Svc_Name from ItemMast "
                       "left join Tax t1 on ItemMast.IM_Tax = t1.T_Name "
                       " left join Tax t2 on ItemMast.IM_ServiceTax = t2.T_Name "
                       "where IM_ItemNo = ?",[NSNumber numberWithLong:im_ItemNo]];
    
    if ([rs next]) {
        if (compEnableGst == 1) {
            gst = [rs doubleForColumn:@"T_Percent"];
        }
        else
        {
            gst = 0.00;
        }
        
        
        if ([taxType isEqualToString:@"Inc"]) {
            //gst inc
            itemSellingPrice = [rs doubleForColumn:@"IM_SalesPrice"] / ((gst / 100)+1);
            
            //self.textItemPrice.text = [NSString stringWithFormat:@"%.02f",[rs doubleForColumn:@"IM_SalesPrice"]];
            
            textSubTotal = [NSString stringWithFormat:@"%.02f",[rs doubleForColumn:@"IM_SalesPrice"]];
            
            textTotalTax = [NSString stringWithFormat:@"%.02f",[rs doubleForColumn:@"IM_SalesPrice"] - itemSellingPrice];
            
            itemTaxAmt = [rs doubleForColumn:@"IM_SalesPrice"] - itemSellingPrice;
            textTotal = [NSString stringWithFormat:@"%.02f",[rs doubleForColumn:@"IM_SalesPrice"]];
            
            totalItemSellingAmt = itemSellingPrice;
            totalItemTaxAmt = itemTaxAmt;
        }
        else
        {
            // gst ex
            itemSellingPrice = [rs doubleForColumn:@"IM_SalesPrice"];
            //self.textItemPrice.text = [NSString stringWithFormat:@"%.02f",[rs doubleForColumn:@"IM_SalesPrice"]];
            textSubTotal = [NSString stringWithFormat:@"%.02f",[rs doubleForColumn:@"IM_SalesPrice"]];
            textTotalTax = [NSString stringWithFormat:@"%.02f",[textSubTotal doubleValue] * (gst / 100)];
            itemTaxAmt = [textTotalTax doubleValue];
            textTotal = [NSString stringWithFormat:@"%.02f",[rs doubleForColumn:@"IM_SalesPrice"] + [textTotalTax doubleValue]];
            totalItemSellingAmt = [textSubTotal doubleValue];
            //totalItemTaxAmt = itemTaxAmt;
            totalItemTaxAmt = [[NSString stringWithFormat:@"%.06f",[textSubTotal doubleValue] * (gst / 100)]doubleValue];
        }
        
        if (compEnableSVG == 1) {
            if ([tpServiceTax2 isEqualToString:@"-"]) {
                // non override svc
                serviceTaxRate = [rs doubleForColumn:@"Svc_Percent"];
                textServiceTax = [NSString stringWithFormat:@"%.06f",itemSellingPrice * ([rs doubleForColumn:@"Svc_Percent"] / 100.0)];
                
            }
            else
            {
                
                serviceTaxRate = [tpServiceTax2 doubleValue];
                textServiceTax = [NSString stringWithFormat:@"%.06f",itemSellingPrice * ([tpServiceTax2 doubleValue] / 100.0)];
            }
 
        }
        else
        {
            serviceTaxRate = 0.00;
            textServiceTax = @"0.00";
        }
        
        
        //textServiceTaxGst = [NSString stringWithFormat:@"%.06f",[textServiceTax doubleValue] * (serviceTaxGst / 100.0)];
        //NSLog(@"%@",textServiceTaxGst);
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        
        [data setObject:orderDataStatus forKey:@"Status"];
        [data setObject:@"NonSONo" forKey:@"SOH_DocNo"];
        [data setObject:[rs stringForColumn:@"IM_ItemCode"] forKey:@"IM_ItemCode"];
        [data setObject:[rs stringForColumn:@"IM_Description"] forKey:@"IM_Description"];
        [data setObject:[NSString stringWithFormat:@"%.02f",[rs doubleForColumn:@"IM_SalesPrice"]] forKey:@"IM_Price"];
        //one item selling price not included tax
        [data setObject:[NSString stringWithFormat:@"%0.6f",itemSellingPrice] forKey:@"IM_SellingPrice"];
        [data setObject:[NSString stringWithFormat:@"%0.6f",itemTaxAmt] forKey:@"IM_Tax"];
        [data setObject:@"1" forKey:@"IM_Qty"];
        [data setObject:[NSString stringWithFormat:@"%f",0.00] forKey:@"IM_DiscountInPercent"];
        
        [data setObject:[NSString stringWithFormat:@"%ld",(long)gst] forKey:@"IM_Gst"];
        
        [data setObject:textTotalTax forKey:@"IM_TotalTax"]; //sum tax amt
        [data setObject:[NSString stringWithFormat:@"%d",0] forKey:@"IM_DiscountType"];
        [data setObject:@"0" forKey:@"IM_Discount"]; // discount given
        [data setObject:@"0.00" forKey:@"IM_DiscountAmt"];  // sum discount
        [data setObject:textSubTotal forKey:@"IM_SubTotal"];
        [data setObject:textTotal forKey:@"IM_Total"];
        
        //------------tax code-----------------
        [data setObject:[rs stringForColumn:@"T_Name"] forKey:@"IM_GSTCode"];
        
        //-------------service tax-------------
        [data setObject:[rs stringForColumn:@"Svc_Name"] forKey:@"IM_ServiceTaxCode"];  //svc tax code
        [data setObject:textServiceTax forKey:@"IM_ServiceTaxAmt"]; // service tax amount
        [data setObject:[NSString stringWithFormat:@"%ld",(long)serviceTaxRate] forKey:@"IM_ServiceTaxRate"];
        //[data setObject:textServiceTaxGst forKey:@"IM_ServiceTaxGstAmt"];
        
        //------------------------------------------------------------------------------------------
        [data setObject:[NSString stringWithFormat:@"%0.2f", totalItemSellingAmt] forKey:@"IM_totalItemSellingAmt"];  // subtotal not include tax n will replace this
        [data setObject:[NSString stringWithFormat:@"%0.6f", totalItemSellingAmt] forKey:@"IM_totalItemSellingAmtLong"];  // subtotal not include tax
        [data setObject:[NSString stringWithFormat:@"%0.6f", totalItemTaxAmt] forKey:@"IM_totalItemTaxAmtLong"];  // total tax amt
        
        [data setObject:[NSString stringWithFormat:@"%0.3f", [textServiceTax doubleValue]] forKey:@"IM_totalServiceTaxAmt"];  // total service tax amt
        
        [data setObject:@"" forKey:@"IM_Remark"];
        [data setObject:_tableName forKey:@"IM_TableName"];
        //---------for print kitchen receipt----------------
        
        [data setObject:@"Print" forKey:@"IM_Print"];
        [data setObject:@"1" forKey:@"IM_OrgQty"];
        
        //---------for item dine in or take away ------------
        [data setObject:_tbStatus forKey:@"IM_TakeAwayYN"];
        
        //---------for main to decide this array-------------
        if ([terminalType isEqualToString:@"Terminal"]) {
            [data setObject:@"Order" forKey:@"IM_Flag"];
            [data setObject:@"0.00" forKey:@"IM_labelTotal"];
            [data setObject:@"0.00" forKey:@"IM_labelTotalDiscount"];
            [data setObject:@"0.00" forKey:@"IM_labelRound"];
            [data setObject:@"0.00" forKey:@"IM_labelSubTotal"];
            [data setObject:@"0.00" forKey:@"IM_labelTaxTotal"];
            [data setObject:@"0.00" forKey:@"IM_labelServiceTaxTotal"];
            [data setObject:@"0.00" forKey:@"IM_serviceTaxGstTotal"];
            [data setObject:_tableName forKey:@"IM_Table"];
            
        }
        
        [salesArray addObject:data];
        
    }
    [self passSales//DataBack:salesArray dataStatus:@"New" tablePosition:0 ArrayIndex:0];
    //NSLog(@"%@",salesArray);
    [rs close];
    [dbTable close];
    salesArray = nil;
}
*/
#pragma mark - order detail delegate

-(void)editAddConfimentViewWithPosition:(NSUInteger)position ShowAll:(NSString *)showAll
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    updateCondimentDtlQtyFrom = @"OrderAddCondimentView";
    
    NSPredicate *predicate;
    if (orderFinalArray.count == position+1) {
        predicate = [NSPredicate predicateWithFormat:@"ParentIndex MATCHES[cd] %@",
                                  [[orderFinalArray objectAtIndex:position]objectForKey:@"ParentIndex"]];
    }
    else
    {
        predicate = [NSPredicate predicateWithFormat:@"ParentIndex MATCHES[cd] %@",
                     [[orderFinalArray objectAtIndex:position + 1]objectForKey:@"ParentIndex"]];
    }
    
    
    OrderAddCondimentViewController *orderAddCondimentViewController = [[OrderAddCondimentViewController alloc]initWithNibName:@"OrderAddCondimentViewController" bundle:nil];
    orderAddCondimentViewController.delegate = self;
    
    orderAddCondimentViewController.icItemCode = [[orderFinalArray objectAtIndex:position] objectForKey:@"IM_ItemCode"];
    orderAddCondimentViewController.selectedCHCode = nil;
    orderAddCondimentViewController.icStatus = @"Edit";
    orderAddCondimentViewController.addCondimentFrom = @"OrderingView";
    //orderAddCondimentViewController.showAll = showAll;
    if ([orderFinalArray filteredArrayUsingPredicate:predicate].count == 0) {
        orderAddCondimentViewController.parentIndex = [NSString stringWithFormat:@"%ld",position+1];
    }
    else
    {
        orderAddCondimentViewController.icAddedArray = [orderFinalArray filteredArrayUsingPredicate:predicate];
    }
    
    
    
    UINavigationController *navbar = [[UINavigationController alloc]  initWithRootViewController:orderAddCondimentViewController];
    
    navbar.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    navbar.modalPresentationStyle = UIModalPresentationFormSheet;
    navbar.popoverPresentationController.sourceView = self.view;
    navbar.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2, 1, 1);
    
    [orderAddCondimentViewController setModalPresentationStyle:UIModalPresentationFormSheet];
    [orderAddCondimentViewController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    
    [self presentViewController:navbar animated:NO completion:nil];
    
}

-(void)editPackageItemWithPosition:(NSUInteger)position
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    [self editPackageItemSelectionViewWithPackageItemIndex:[NSString stringWithFormat:@"%lu",position+1]];
}

-(void)passSalesDataBack:(NSMutableArray *)dataBack dataStatus:(NSString *)flag tablePosition:(int)position ArrayIndex:(int)arrayIndex
{
    
    __block int imNo;
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs;
        rs = [db executeQuery:@"Select IM_ItemNo from ItemMast where IM_ItemCode = ?",[[dataBack objectAtIndex:arrayIndex] objectForKey:@"IM_ItemCode"]];
        
        if ([rs next]) {
            imNo = [rs intForColumn:@"IM_ItemNo"];
        }
        [rs close];
        
    }];
    [queue close];
    
    NSMutableArray *transferSalesArray = [[NSMutableArray alloc] init];
    NSMutableArray *recalcTransferSalesArray = [[NSMutableArray alloc] init];
    NSArray *recalcTransferArray;
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    
    [data setObject:[[dataBack objectAtIndex:arrayIndex] objectForKey:@"IM_DiscountInPercent"] forKey:@"DiscInPercent"];
    [data setObject:[[dataBack objectAtIndex:arrayIndex] objectForKey:@"IM_Qty"] forKey:@"ItemQty"];
    [data setObject:[[dataBack objectAtIndex:arrayIndex] objectForKey:@"IM_Discount"] forKey:@"DiscValue"];
    [data setObject:[[dataBack objectAtIndex:arrayIndex] objectForKey:@"IM_DiscountType"] forKey:@"DiscType"];
    [data setObject:[[dataBack objectAtIndex:arrayIndex] objectForKey:@"IM_DiscountAmt"] forKey:@"TotalDisc"];
    [data setObject:[[dataBack objectAtIndex:arrayIndex] objectForKey:@"IM_Remark"] forKey:@"Remark"];
    [data setObject:[[dataBack objectAtIndex:arrayIndex] objectForKey:@"IM_TotalCondimentSurCharge"] forKey:@"IM_TotalCondimentSurCharge"];
    [data setObject:[[dataBack objectAtIndex:arrayIndex] objectForKey:@"IM_OrgQty"] forKey:@"OrgQty"];
    //settingDict = [PublicSqliteMethod getGeneralnTableSettingWithTableName:tableDesc dbPath:dbPath];
    
    transferSalesArray = [PublicSqliteMethod calcGSTByItemNo:imNo DBPath:dbPath ItemPrice:[[dataBack objectAtIndex:arrayIndex] objectForKey:@"IM_Price"] CompEnableGst:compEnableGst CompEnableSVG:compEnableSVG TableSVC:tpServiceTax2 OverrideSVG:_overrideTableSVC SalesOrderStatus:@"Edit" TaxType:[[LibraryAPI sharedInstance] getTaxType] TableName:tableDesc ItemDineStatus:[NSString stringWithFormat:@"%@",[NSNumber numberWithInt:[[[dataBack objectAtIndex:arrayIndex] objectForKey:@"IM_TakeAwayYN"]integerValue]]] TerminalType:terminalType SalesDict:data IMQty:@"0" KitchenStatus:[[dataBack objectAtIndex:arrayIndex] objectForKey:@"IM_Print"] PaxNo:_paxData DocType:_docType CondimentSubTotal:[[[dataBack objectAtIndex:arrayIndex] objectForKey:@"IM_NewTotalCondimentSurCharge"] doubleValue] ServiceChargeGstPercent:[[LibraryAPI sharedInstance] getServiceTaxGstPercent] TableDineStatus:_tbStatus];
    
    NSDictionary *data2 = [NSDictionary dictionary];
    data2 = [transferSalesArray objectAtIndex:0];
    [data2 setValue:[NSString stringWithFormat:@"%d",position + 1] forKey:@"Index"];
    [transferSalesArray replaceObjectAtIndex:0 withObject:data2];
    data2 = nil;
    
    recalcTransferArray = [PublicSqliteMethod recalculateGSTSalesOrderWithSalesOrderArray:transferSalesArray TaxType:[[LibraryAPI sharedInstance] getTaxType]];
    
    
    [orderFinalArray replaceObjectAtIndex:position withObject:[recalcTransferArray objectAtIndex:0]];
    [self recalculateAllGSTSalesOrder];
    [self updateCondimentDtlOrderQtyWithAddedView:updateCondimentDtlQtyFrom IMQty:[[[dataBack objectAtIndex:arrayIndex] objectForKey:@"IM_Qty"] integerValue]];
    
    //settingDict = nil;
    transferSalesArray = nil;
    recalcTransferArray = nil;
    recalcTransferSalesArray = nil;
    
    [self groupCalcTotalForSalesOrder];
    
}

-(void)passBackToOrderScreenWithCondimentDtl:(NSMutableArray *)array DisplayFormat:(NSString *)displayFormat TotalCondimentPrice:(double)totalCondimentPrice Status:(NSString *)status CondimentUnitPrice:(double)condimentUnitPrice PredicatePrice:(double)predicatePrice
{
    NSString *printStatus;
    NSArray *checkingArray;
    NSArray *checkingCondimentArray;
    
    if ([_docType isEqualToString:@"CashSales"]) {
        printStatus = @"Printed";
    }
    else
    {
        printStatus = @"Print";
    }
    
    if (array.count > 0) {
        predicateItemCode = [[array objectAtIndex:0] objectForKey:@"ItemCode"];
    }
    
    if (orderFinalArray.count > 0) {
        NSPredicate *predicate1;
        predicate1 = [NSPredicate predicateWithFormat:@"IM_ItemCode MATCHES[cd] %@",
                      predicateItemCode];
        
        //NSLog(@"%0.2f",predicatePrice);
        
        NSPredicate *predicate2;
        predicate2 = [NSPredicate predicateWithFormat:@"IM_Price MATCHES[cd] %@",
                      [NSString stringWithFormat:@"%0.2f",predicatePrice]];
        
        NSPredicate *predicate3;
        predicate3 = [NSPredicate predicateWithFormat:@"IM_Print MATCHES[cd] %@",
                      @"Print"];
        
        NSPredicate *predicateAnd = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate1, predicate2, predicate3]];
        
        checkingArray = [orderFinalArray filteredArrayUsingPredicate:predicateAnd];
    }
    
    NSUInteger indexOfArray = 0;
    NSString *checkingAction;
    
    if (checkingArray.count > 0) {
        for (int i = 0; i < checkingArray.count; i++) {
            indexOfArray = [orderFinalArray indexOfObject:checkingArray[i]];
            
            NSPredicate *predicate4;
            predicate4 = [NSPredicate predicateWithFormat:@"ParentIndex MATCHES[cd] %@",
                          [[orderFinalArray objectAtIndex:indexOfArray] objectForKey:@"Index"]];
            
            checkingCondimentArray = [orderFinalArray filteredArrayUsingPredicate:predicate4];
            
            for (int j = 0; j < array.count; j++) {
                NSMutableDictionary *data = [NSMutableDictionary dictionary];
                data = [array objectAtIndex:j];
                [data setValue:[[checkingArray objectAtIndex:i] objectForKey:@"Index"] forKey:@"ParentIndex"];
                [array replaceObjectAtIndex:j withObject:data];
                data = nil;
            }
            predicate4 = nil;
            NSSet *set1 = [NSSet setWithArray:array];
            NSSet *set2 = [NSSet setWithArray:checkingCondimentArray];
            
            if ([set1 isEqualToSet:set2]) {
                checkingAction = @"Replace";
                break;
            }
            else
            {
                checkingAction = @"Add";
            }
        }
    }
    else
    {
        checkingAction = @"Add";
    }
    
    
    
    if ([checkingAction isEqualToString:@"Replace"]) {
        //NSUInteger indexOfArray = 0;
        //indexOfArray = [orderFinalArray indexOfObject:checkingArray[0]];
        
        [self groupCalcItemPrice:itemSelectedIndex ItemQty:[NSString stringWithFormat:@"%0.2f",[[[checkingArray objectAtIndex:0] objectForKey:@"IM_Qty"] doubleValue] + 1] KitchReceiptStatus:printStatus TotalCondimentPrice:totalCondimentPrice TotalCondimentUnitPrice:condimentUnitPrice ReplacedIndex:[NSString stringWithFormat:@"%ld",indexOfArray]];
    }
    else
    {
        [self groupCalcItemPrice:itemSelectedIndex ItemQty:@"1" KitchReceiptStatus:printStatus TotalCondimentPrice:totalCondimentPrice TotalCondimentUnitPrice:condimentUnitPrice ReplacedIndex:@"-"];
    }
    
    checkingArray = nil;
    
    if ([checkingAction isEqualToString:@"Add"]) {
        if (array.count > 0) {
            
            for (int i = 0; i < array.count; i++) {
                NSMutableDictionary *data = [NSMutableDictionary dictionary];
                data = [array objectAtIndex:i];
                [data setValue:[NSString stringWithFormat:@"%lu",orderFinalArray.count] forKey:@"ParentIndex"];
                [array replaceObjectAtIndex:i withObject:data];
                data = nil;
            }
            
            [orderFinalArray addObjectsFromArray:array];
            
            [self.orderFinalTableView reloadData];
        }
    }
    
}

-(void)passBackToOrderScreenWithEditedCondimentDtl:(NSMutableArray *)array DisplayFormat:(NSString *)displayFormat TotalCondimentPrice:(double)totalCondimentPrice ParentIndex:(NSString *)parentIndex CondimentUnitPrice:(double)condimentUnitPrice
{
    
    orderFinalArray = [PublicMethod softingOrderCondimentWithEditedCondimentDtl:array DisplayFormat:@"-" TotalCondimentPrice:totalCondimentPrice ParentIndex:parentIndex CondimentUnitPrice:condimentUnitPrice OriginalArray:orderFinalArray FromView:@"Ordering" KeyName:@"Index"];
    
    NSUInteger insertIndex = 0;
    insertIndex = [[[orderFinalArray objectAtIndex:orderFinalArray.count - 1] objectForKey:@"InsertIndex"] integerValue];
    NSString *flag = [[orderFinalArray objectAtIndex:orderFinalArray.count - 1] objectForKey:@"Flag"];
    
    [orderFinalArray removeObjectAtIndex:orderFinalArray.count - 1];
    
    if ([flag isEqualToString:@"FirstItem"]) {
        
        [self passSalesDataBack:orderFinalArray dataStatus:@"Edit" tablePosition:insertIndex-1 ArrayIndex:insertIndex-1];
    }
    else
    {
        [self passSalesDataBack:orderFinalArray dataStatus:@"Edit" tablePosition:insertIndex ArrayIndex:insertIndex];
    }
    
    
   
}

-(void)updateCondimentDtlOrderQtyWithAddedView:(NSString *)view IMQty:(int)imQty
{
    if ([view isEqualToString:@"OrderDetailModalView"]) {
        for (int i = 0; i < orderFinalArray.count; i++) {
            NSDictionary *data2 = [NSDictionary dictionary];
            data2 = [orderFinalArray objectAtIndex:i];
            if ([[[orderFinalArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"CondimentOrder"])
            {
                
                [data2 setValue:[NSString stringWithFormat:@"%ld",[[[orderFinalArray objectAtIndex:i] objectForKey:@"UnitQty"] integerValue] * 1] forKey:@"UnitQty"];
                
            }
            
            [orderFinalArray replaceObjectAtIndex:i withObject:data2];
            data2 = nil;
        }
    }
    
    
}

#pragma mark - searchbar delegate
-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    
    [searchBar setShowsCancelButton:YES animated:NO];
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    /*
    [itemMastArray removeAllObjects];

    [self filterItemMast: [NSString stringWithFormat:@"%@%@%@",@"%", searchBar.text,@"%"]];
    [searchBar setShowsCancelButton:NO animated:NO];
    [searchBar resignFirstResponder];
     */
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchBar.text = @"";
    isFiltered = @"False";
    [[self view] endEditing:YES];
    [self filterItemMast: [NSString stringWithFormat:@"'%@'",@"%"]];
    
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{

    if (searchText.length == 0) {
        isFiltered = @"False";
    }
    else
    {
        isFiltered = @"True";
        
        NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"IM_Desc CONTAINS[cd] %@",
                                   searchText];
        
        NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"IM_Code CONTAINS[cd] %@",
                                   searchText];
        
        NSPredicate *predicateOr = [NSCompoundPredicate orPredicateWithSubpredicates:@[predicate1, predicate2]];
        
        itemMastArrayFilter = [keepAllItemArray filteredArrayUsingPredicate:predicateOr];
        
        //itemMastArrayFilter = [keepAllItemArray filter]
        
        //NSLog(@"%@", itemMastArrayFilter);
        
        predicate1 = nil;
        predicate2 = nil;
        predicateOr = nil;
        
    }
    
    [self.collectionViewMenu reloadData];
    //NSLog(@"%@",itemMastArray);
}


#pragma mark - custom function
-(void)calcSalesTotal
{
    self.labelSubTotal.text = @"0.00";
    self.labelTaxTotal.text = @"0.00";
    self.labelTotal.text = @"0.00";
    self.labelTotalDiscount.text = @"0.00";
    self.labelServiceTaxTotal.text = @"0.00";
    self.labelTotalQty.text = @"0";
    self.labelExSubtotal.text = @"0.00";
    NSString *labelTotalItemTax = @"0.00";
    NSString *labelServiceTaxTotal = @"0.00";
    double adjTax = 0.00;
    
    for (int i = 0; i < orderFinalArray.count; i++) {
        self.labelExSubtotal.text = [NSString stringWithFormat:@"%.02f",[self.labelExSubtotal.text doubleValue] + [[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_totalItemSellingAmt"]doubleValue]];
        
        self.labelSubTotal.text = [NSString stringWithFormat:@"%.02f",[self.labelSubTotal.text doubleValue] + [[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_SubTotal"]doubleValue]];
        
        self.labelTotalQty.text = [NSString stringWithFormat:@"%.02f",[self.labelTotalQty.text doubleValue] + [[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Qty"] doubleValue]];
        
        self.labelServiceTaxTotal.text = [NSString stringWithFormat:@"%.06f",[self.labelServiceTaxTotal.text doubleValue] + [[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_ServiceTaxAmt"]doubleValue]];
        
        self.labelTaxTotal.text = [NSString stringWithFormat:@"%.06f",[self.labelTaxTotal.text doubleValue] + [[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_totalItemTaxAmtLong"]doubleValue]];
        
        self.labelTotalDiscount.text = [NSString stringWithFormat:@"%.02f",[self.labelTotalDiscount.text doubleValue] + [[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_DiscountAmt"]doubleValue]];
        
        if ([taxType isEqualToString:@"IEx"]) {
            self.labelTotal.text = [NSString stringWithFormat:@"%.02f",[self.labelSubTotal.text doubleValue] + 0 - [self.labelTotalDiscount.text doubleValue] + round([self.labelServiceTaxTotal.text doubleValue]*100)/100];
            
            NSLog(@"first %@ %@  %f  %f",self.labelTotal.text,self.labelSubTotal.text,round([self.labelTaxTotal.text doubleValue]*100)/100,round([self.labelServiceTaxTotal.text doubleValue]*100)/100);
        }
        else
        {
            
            self.labelTotal.text = [NSString stringWithFormat:@"%.02f",[self.labelSubTotal.text doubleValue] - [self.labelTotalDiscount.text doubleValue] + [self.labelServiceTaxTotal.text doubleValue]];
            
        }
        labelTotalItemTax = [NSString stringWithFormat:@"%.06f",[labelTotalItemTax doubleValue] + [[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_TotalTax"] doubleValue]];
        
    }
    
    // special rounding from 2.435 to 2.44
    labelServiceTaxTotal = self.labelServiceTaxTotal.text;
    
    self.labelServiceTaxTotal.text = [NSString stringWithFormat:@"%.2f",round([labelServiceTaxTotal doubleValue] * 100) / 100];
    //NSLog(@"service charge %@  %f",self.labelServiceTaxTotal.text, round([labelServiceTaxTotal doubleValue] * 100) / 100);
    serviceTaxGstTotal = [NSString stringWithFormat:@"%.06f",[labelServiceTaxTotal doubleValue] * (serviceTaxGst / 100.0)];
    
    //NSLog(@"b4 round %@  %@  %@",self.labelTaxTotal.text,serviceTaxGstTotal,self.labelTotal.text);
    
    self.labelTaxTotal.text = [NSString stringWithFormat:@"%.6f",[self.labelTaxTotal.text doubleValue] + [serviceTaxGstTotal doubleValue]];
    self.labelTaxTotal.text = [NSString stringWithFormat:@"%.2f",round([self.labelTaxTotal.text doubleValue]*100)/100];
    
    //NSLog(@"after round %@",self.labelTaxTotal.text);
    if (![taxType isEqualToString:@"IEx"]) {
        NSString *finalTotalSellingFigure2;
        NSString *finalTotalTax2;
        
        labelTotalItemTax = [NSString stringWithFormat:@"%.02f",[labelTotalItemTax doubleValue]  + [serviceTaxGstTotal doubleValue]];
        
        adjTax = [self.labelTaxTotal.text doubleValue] - [labelTotalItemTax doubleValue];
        if (adjTax != 0.00) {
           
            NSMutableDictionary *data2 = [NSMutableDictionary dictionary];
            
            finalTotalSellingFigure2 = [NSString stringWithFormat:@"%.02f",[[[orderFinalArray objectAtIndex:orderFinalArray.count - 1] objectForKey:@"IM_totalItemSellingAmt"] doubleValue] - adjTax];
            
            finalTotalTax2 = [NSString stringWithFormat:@"%.02f",[[[orderFinalArray objectAtIndex:orderFinalArray.count - 1] objectForKey:@"IM_TotalTax"] doubleValue] + adjTax];
            data2 = [orderFinalArray objectAtIndex:orderFinalArray.count - 1];
            [data2 setValue:[NSString stringWithFormat:@"%@",finalTotalSellingFigure2] forKey:@"IM_totalItemSellingAmt"];
            [data2 setValue:[NSString stringWithFormat:@"%@",finalTotalTax2] forKey:@"IM_TotalTax"];
            self.labelExSubtotal.text = [NSString stringWithFormat:@"%0.2f",[self.labelExSubtotal.text doubleValue] - adjTax];
            [orderFinalArray replaceObjectAtIndex:orderFinalArray.count - 1 withObject:data2];
        }
    }
    
    /*
    NSLog(@"total %@",self.labelTotal.text);
    NSLog(@"sevice charge tax gst %@",serviceTaxGstTotal);
    NSLog(@"%@",[NSString stringWithFormat:@"%.02f",[self.labelTotal.text doubleValue] + [[NSString stringWithFormat:@"%0.2f",[serviceTaxGstTotal doubleValue]] doubleValue]]);
    NSLog(@"%@",[NSString stringWithFormat:@"%.02f",[self.labelTotal.text doubleValue] + [serviceTaxGstTotal doubleValue]]);
    */
    if ([taxType isEqualToString:@"IEx"]) {
        /*
        NSString *exGst;
        self.labelTotal.text = [NSString stringWithFormat:@"%.02f",[self.labelSubTotal.text doubleValue] + [self.labelServiceTaxTotal.text doubleValue]];
        if ([self.labelServiceTaxTotal.text doubleValue] == 0.00) {
            exGst = @"0.00";
        }
        else
        {
            exGst = [NSString stringWithFormat:@"%.06f",[self.labelTotal.text doubleValue] * (serviceTaxGst / 100.0) ];
        }
        
        NSLog(@"final total %@, %@",self.labelTotal.text, exGst);
        self.labelTaxTotal.text = [NSString stringWithFormat:@"%.2f",round([exGst doubleValue] * 100) / 100];
        self.self.labelTotal.text = [NSString stringWithFormat:@"%.2f",round(([self.labelTotal.text doubleValue]+[exGst doubleValue]) * 100) / 100];
         */
        NSLog(@"final total %@   %@",self.labelTotal.text, [NSString stringWithFormat:@"%0.2f",round([serviceTaxGstTotal doubleValue] * 100) / 100]);
        self.labelTotal.text = [NSString stringWithFormat:@"%.02f",[self.labelTotal.text doubleValue] + round([self.labelTaxTotal.text doubleValue] * 100) / 100];
        //NSLog(@"final total %@   %@",self.labelTotal.text, serviceTaxGstTotal);
    }
    else
    {
        NSLog(@"final total %@   %@",self.labelTotal.text, [NSString stringWithFormat:@"%0.2f",round([serviceTaxGstTotal doubleValue] * 100) / 100]);
        self.labelTotal.text = [NSString stringWithFormat:@"%.02f",[self.labelTotal.text doubleValue] + [[NSString stringWithFormat:@"%0.2f",[serviceTaxGstTotal doubleValue]] doubleValue]];
    }
    
    
    //self.self.labelTotal.text = [NSString stringWithFormat:@"%.2f",round(([self.labelTotal.text doubleValue]+[serviceTaxGstTotal doubleValue]) * 100) / 100];
    
    
    // rounding
    NSString *strDollar;
    NSString *strCent;
    NSString *lastDigit;
    NSString *secondLastDigit;
    NSString *finalCent;
    
    NSString *final;
    //NSString *sqlCommand;
    lastDigit = [self.labelTotal.text substringFromIndex:[self.labelTotal.text length] - 1];
    NSLog(@"last digit %@, %@",self.labelTotal.text,lastDigit);
    strCent = [NSString stringWithFormat:@"0.%@",[self.labelTotal.text substringFromIndex:[self.labelTotal.text length] - 2]];
    secondLastDigit = [self.labelTotal.text substringWithRange:NSMakeRange([self.labelTotal.text length] - 2, 1)];
    finalCent = [[LibraryAPI sharedInstance]getCalcRounding:self.labelTotal.text DatabasePath:dbPath];
    strDollar = [self.labelTotal.text substringWithRange:NSMakeRange(0, [self.labelTotal.text length] - 3)];
    
    if ([strDollar doubleValue] < 0) {
        final = [NSString stringWithFormat:@"%0.2f",[strDollar doubleValue] - [finalCent doubleValue]];
    }
    else
    {
        final = [NSString stringWithFormat:@"%0.2f",[strDollar doubleValue] + [finalCent doubleValue]];
    }
    
    self.labelRound.text = [NSString stringWithFormat:@"%0.2f",[finalCent doubleValue] - [strCent doubleValue]];
    self.labelTotal.text = final;
    
    if ([terminalType isEqualToString:@"Terminal"]) {
        if (orderFinalArray.count > 0) {
            NSMutableDictionary *data2 = [NSMutableDictionary dictionary];
            
            data2 = [orderFinalArray objectAtIndex:0];
            [data2 setValue:self.labelTotal.text forKey:@"IM_labelTotal"];
            [data2 setValue:self.labelTotalDiscount.text forKey:@"IM_labelTotalDiscount"];
            [data2 setValue:self.labelRound.text forKey:@"IM_labelRound"];
            [data2 setValue:self.labelSubTotal.text forKey:@"IM_labelSubTotal"];
            [data2 setValue:self.labelTaxTotal.text forKey:@"IM_labelTaxTotal"];
            [data2 setValue:self.labelServiceTaxTotal.text forKey:@"IM_labelServiceTaxTotal"];
            [data2 setValue:serviceTaxGstTotal forKey:@"IM_serviceTaxGstTotal"];
            
            [orderFinalArray replaceObjectAtIndex:0 withObject:data2];
            data2 = nil;
        }
    }
    
    if ([_docType isEqualToString:@"CashSales"]) {
        
        NSMutableDictionary *data2 = [NSMutableDictionary dictionary];
        
        data2 = [orderFinalArray objectAtIndex:0];
        [data2 setValue:self.labelTotal.text forKey:@"SOH_DocAmt"];
        [data2 setValue:self.labelTotalDiscount.text forKey:@"SOH_DiscAmt"];
        [data2 setValue:self.labelRound.text forKey:@"SOH_Rounding"];
        [data2 setValue:self.labelSubTotal.text forKey:@"SOH_DocSubTotal"];
        [data2 setValue:self.labelTaxTotal.text forKey:@"SOH_DocTaxAmt"];
        [data2 setValue:self.labelServiceTaxTotal.text forKey:@"SOH_DocServiceTaxAmt"];
        [data2 setValue:serviceTaxGstTotal forKey:@"SOH_DocServiceTaxGstAmt"];
        [data2 setValue:_csDocNo forKey:@"SOH_DocNo"];
        [orderFinalArray replaceObjectAtIndex:0 withObject:data2];
        data2 = nil;
        
    }
    
    [self.orderFinalTableView reloadData];
    
    if (orderFinalArray.count > 0) {
        long lastRowNumber = [self.orderFinalTableView numberOfRowsInSection:0] - 1;
        NSIndexPath *ip = [NSIndexPath indexPathForRow:lastRowNumber inSection:0];
        [self.orderFinalTableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
    
    strDollar = nil;;
    strCent = nil;
    lastDigit = nil;
    secondLastDigit = nil;
    finalCent = nil;
    final = nil;
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)btnVoidOrder:(id)sender {
    if ([_docType isEqualToString:@"SalesOrder"]) {
        if ([terminalType isEqualToString:@"Main"]) {
            if ([orderDataStatus isEqualToString:@"New"]) {
                [self clearSalesScreen];
            }
            else
            {
                VoidOrderReasonViewController *voidOrderViewController = [[VoidOrderReasonViewController alloc] init];
                
                voidOrderViewController.delegate  = self;
                voidOrderViewController.voidTableName = _tableName;
                [voidOrderViewController setModalPresentationStyle:UIModalPresentationFormSheet];
                [voidOrderViewController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
                [self.navigationController presentViewController:voidOrderViewController animated:YES completion:nil];
            }
            
        }
        else
        {
            alertType = @"Alert";
            if ([orderDataStatus isEqualToString:@"New"]) {
                [self clearSalesScreen];
            }
            else
            {
                [self showAlertView:@"Terminal cannot void order" title:@"Warning"];
            }
            
        }

    }
    
}

- (IBAction)btnPayOrder:(id)sender {
    
    NSDate *today = [NSDate date];
    //NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    //[dateFormat setDateFormat:@"yyyy-MM-dd hh:mm"];
    NSDateFormatter *dateFormat = [[LibraryAPI sharedInstance] getDateFormaterhhmmss];
    NSString *dateString = [dateFormat stringFromDate:today];
    BOOL addSalesOrderResult;
    
    if (orderFinalArray.count == 0) {
        [self showAlertView:@"Order list is empty" title:@"Warning"];
        return;
    }
    
    if ([terminalType isEqualToString:@"Main"]) {
        if ([_docType isEqualToString:@"CashSales"]) {
            [[LibraryAPI sharedInstance] setEditCashSalesDetail:orderFinalArray];
            addSalesOrderResult = true;
        }
        else
        {
            if ([orderDataStatus isEqualToString:@"New"]) {
                directExit = @"Yes";
                addSalesOrderResult = [self insertIntoSalesOrder:dateString payType:@"direct"];
            }
            else
            {
                addSalesOrderResult = [self updateSetSalesOrder:dateString PayType:@"direct"];
            }
        }
        
    }
    else
    {
        
        if ([[LibraryAPI sharedInstance] getKioskMode] == 1) {
            addSalesOrderResult = false;
            terminalPayType = @"direct";
            _paxData = @"1";
            if ([_docType isEqualToString:@"CashSales"]) {
                [[LibraryAPI sharedInstance] setEditCashSalesDetail:orderFinalArray];
                [self goToPaymentView];
            }
            else
            {
                [self kioskSendOrderToServerWithOrderStatus:orderDataStatus];
            }
            
        }
        else
        {
            directExit = @"Yes";
            addSalesOrderResult = false;
            terminalPayType = @"direct";
            if ([_docType isEqualToString:@"CashSales"]) {
                [[LibraryAPI sharedInstance] setEditCashSalesDetail:orderFinalArray];
                [self goToPaymentView];
            }
            else
            {
                [self kioskSendOrderToServerWithOrderStatus:orderDataStatus];
            }
            
        }
        
    }
    
    
    //[self showAlertView:[NSString stringWithFormat:@"%@",[NSNumber numberWithBool:addSalesOrderResult]] title:@"Warning"];
    if (addSalesOrderResult) {
        orderDataStatus = @"Edit";
        [self goToPaymentView];
    }
    
    // docNo;
    
}

-(void)goToPaymentView
{
    //NSLog(@"Pay %@",@"2");
    PaymentViewController *paymentViewController = [[PaymentViewController alloc]init];
    [[LibraryAPI sharedInstance] setDocNo:docNo];
    [[LibraryAPI sharedInstance] setTableNo:selectedTableNo];
    paymentViewController.delegate = self;
    paymentViewController.splitBill_YN = @"No";
    paymentViewController.tbName = _tableName;
    paymentViewController.terminalType = terminalType;
    paymentViewController.finalPaxNo = _paxData;
    paymentViewController.payDocType = _docType;
    paymentViewController.dictPayCust = orderCustomerInfo;
    [[LibraryAPI sharedInstance]setPayOrderDetail:orderFinalArray];
    
    
    UINavigationController *navbar = [[UINavigationController alloc]  initWithRootViewController:paymentViewController];
    //NSLog(@"Checking msg");
    
    navbar.modalPresentationStyle = UIModalPresentationPopover;
    
    _popOverPay = [navbar popoverPresentationController];
    _popOverPay.delegate = self;
    _popOverPay.permittedArrowDirections = 0;
    _popOverPay.sourceView = self.view;
    _popOverPay.sourceRect = CGRectMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2, 1, 1);
    [self presentViewController:navbar animated:YES completion:nil];
    
    /*
    self.popOverPay = [[UIPopoverController alloc]initWithContentViewController:navbar];
    self.popOverPay.delegate = self;
    [self.popOverPay presentPopoverFromRect:CGRectMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2, 1, 1) inView:self.view permittedArrowDirections:0 animated:NO];
     */
}

- (void)clickSplitBill:(id)sender {
    SplitBillViewController *splitBillViewController = [[SplitBillViewController alloc]init];
    [[LibraryAPI sharedInstance]setDocNo:docNo];
    splitBillViewController.delegate = self;
    splitBillViewController.splitTableName = tableDesc;
    splitBillViewController.splitPaxNo = _paxData;
    splitBillViewController.splitTableDineType = _tbStatus;
    splitBillViewController.splitCustomerInfoDict = orderCustomerInfo;
    //[splitBillViewController setModalPresentationStyle:UIModalPresentationFormSheet];
    [splitBillViewController setModalPresentationStyle:UIModalPresentationPopover];
    
    /*
    
     */
    
    [self presentViewController:splitBillViewController animated:NO completion:nil];
    
    
    // configure the Popover presentation controller
    UIPopoverPresentationController *popController = [splitBillViewController popoverPresentationController];
    popController.permittedArrowDirections = 0;
    popController.delegate = self;
    
    // in case we don't have a bar button as reference
    popController.sourceView = self.btnSplitBill;
    popController.sourceRect = CGRectMake(self.btnSplitBill.frame.size.width /
                                                                                  2, self.btnSplitBill.frame.size.height / 2, 1, 1);
    
    //[self.navigationController pushViewController:splitBillViewController animated:YES];
    
    
}

-(void)clickPrintSO:(id)sender
{
    if (printerBrand.length == 0) {
        [self showAlertView:@"Receipt printer not found" title:@"Information"];
        return;
    }
    
    if ([orderDataStatus isEqualToString:@"Edit"]) {
        
        if ([printerBrand isEqualToString:@"Asterix"])
        {
            if ([[[LibraryAPI sharedInstance] getWorkMode] isEqualToString:@"Main"])
            {
                
                NSMutableArray *compData = [[NSMutableArray alloc] init];
                NSMutableArray *receiptData = [[NSMutableArray alloc] init];
                
                receiptData = [PublicSqliteMethod getAsterixSalesOrderDetailWithDBPath:dbPath SalesOrderNo:docNo];
                
                [compData addObject:[receiptData objectAtIndex:0]];
                [receiptData removeObjectAtIndex:0];
                
                
                
                [PublicMethod printAsterixSalesOrderWithIpAdd:[[printSOArray objectAtIndex:0] objectForKey:@"P_PortName"] CompanyArray:compData SalesOrderArray:receiptData];
                
                compData = nil;
                receiptData = nil;
            }
            else
            {
                [self requestAsterixPrintSalesOrderFromServer];
            }
            //[self makeEposSalesOrderReceipt];
        }
        else
        {
            NSMutableDictionary *data = [NSMutableDictionary dictionary];
            [data setObject:@"Doc" forKey:@"KR_ItemCode"];
            [data setObject:@"Print" forKey:@"KR_Status"];
            [data setObject:@"0" forKey:@"KR_Qty"];
            [data setObject:@"Doc" forKey:@"KR_Desc"];
            [data setObject:@"RequestPrintKitchenReceipt" forKey:@"IM_Flag"];
            [data setObject:printerBrand forKey:@"KR_Brand"];
            [data setObject:[[printSOArray objectAtIndex:0] objectForKey:@"P_PortName"] forKey:@"KR_IpAddress"];
            [data setObject:printerMode forKey:@"KR_PrintMode"];
            [data setObject:_tableName forKey:@"KR_TableName"];
            [data setObject:@"SalesOrder" forKey:@"KR_DocType"];
            [data setObject:printerName forKey:@"KR_PrinterName"];
            [data setObject:docNo forKey:@"KR_DocNo"];
            
            [kitchenGroup addObject:data];
            
            [self makeXinYeSalesOrderReceipt];
        }
        
    }
    else
    {
        [self showAlertView:@"Only saved sales order can print out" title:@"Warning"];
    }
    
    
    
}

#pragma mark - print receipt
-(void)PrintSOReceiptInRasterMode {
    //InvNo = @"IV000000063";
    p_selectedWidthInch = SMPaperWidth3inchSO;
    p_selectedLanguage = SMLanguageEnglish;
    
    printerPortSetting = @"Standard";
    
    if ([terminalType isEqualToString:@"Main"]) {
        [PrinterFunctions PrintRasterSampleReceiptWithPortname:[[printSOArray objectAtIndex:0] objectForKey:@"P_PortName"] portSettings:printerPortSetting paperWidth:p_selectedWidthInch Language:p_selectedLanguage invDocno:docNo EnableGst:compEnableGst KickOutDrawer:NO];
    }
    else
    {
        //[self requestStarRasterPrintSalesOrderFromServer];
        NSString *printResult;
        printResult = [TerminalData startRasterRequestServerToPrintTerminalReqWithSONo:docNo PortName:[[printSOArray objectAtIndex:0] objectForKey:@"P_PortName"] PrinterSetting:printerPortSetting EnableGst:compEnableGst];
        
        if (![printResult isEqualToString:@"Success"]) {
            //[self showAlertMsgWithMessage:printResult Title:@"Warning"];
            [self showAlertView:printResult title:@"Warning"];
        }
        printResult = nil;
    }
    
    
    
}

- (void)printSOReceiptInLineMode {
    
    
    p_selectedWidthInch = SMPaperWidth3inchSO;
    p_selectedLanguage = SMLanguageEnglish;
    printerPortSetting = @"Standard";
    
    if ([terminalType isEqualToString:@"Main"]) {
        NSData *commands = [PrinterFunctions sampleReceiptWithPaperWidth:p_selectedWidthInch
                                                                language:p_selectedLanguage
                                                              kickDrawer:NO invDocNo:docNo docType:@"SO" EnableGST:compEnableGst];
        if (commands == nil) {
            return;
        }
        
        
        [PrinterFunctions sendCommand:commands
                             portName:[[printSOArray objectAtIndex:0] objectForKey:@"P_PortName"]
                         portSettings:printerPortSetting
                        timeoutMillis:10000];
    }
    else
    {
        //[self requestStarLinePrintSalesOrderFromServer];
        NSString *printResult;
        printResult = [TerminalData startLineRequestServerToPrintTerminalReqWithSONo:docNo PortName:[[printSOArray objectAtIndex:0] objectForKey:@"P_PortName"] PrinterSetting:printerPortSetting EnableGst:compEnableGst];
        
        if (![printResult isEqualToString:@"Success"]) {
            [self showAlertView:printResult title:@"Warning"];
        }
        printResult = nil;
    }
    
}



-(void)makeEposSalesOrderReceipt
{
    NSString *printErrorMsg;
    if ([terminalType isEqualToString:@"Main"]) {
        Result *result = nil;
        EposBuilder *builder = nil;
        
        result = [[Result alloc] init];
        
        //builder = [EposPrintFunction createSalesOrderRceiptData:result DBPath:dbPath GetInvNo:docNo EnableGst:compEnableGst];
        //builder = [EposPrintFunction createReceiptData:result DBPath:dbPath GetInvNo:docNo EnableGst:compEnableGst];
        
        if(result.errType == RESULT_ERR_NONE) {
            [EposPrintFunction print:builder Result:result PortName:[[printSOArray objectAtIndex:0] objectForKey:@"P_PortName"]];
        }
        else
        {
            NSLog(@"Testing Data %@",@"Print Fail");
        }
        
        if (builder != nil) {
            [builder clearCommandBuffer];
        }
        
        printErrorMsg = [EposPrintFunction displayMsg:result];
        
        if ([printErrorMsg length] > 0) {
            [self showAlertView:printErrorMsg title:@"Warning"];
        }
        
        if(result != nil) {
            result = nil;
        }
        printSOArray = nil;
    }
    else
    {
        [self requestAsterixPrintSalesOrderFromServer];
    }
    
    //return;
}

#pragma mark - delegate from order customer
-(void)passBackCustomerInfoWithCustName:(NSString *)custName CustAdd1:(NSString *)custAdd1 CustAdd2:(NSString *)custAdd2 CustAdd3:(NSString *)custAdd3 TelNo:(NSString *)custTelNo CustGstNo:(NSString *)custGstNo
{
    //customerInfo = custInfo;
    [orderCustomerInfo setValue:custName forKey:@"Name"];
    [orderCustomerInfo setValue:custAdd1 forKey:@"Add1"];
    [orderCustomerInfo setValue:custAdd2 forKey:@"Add2"];
    [orderCustomerInfo setValue:custAdd3 forKey:@"Add3"];
    [orderCustomerInfo setValue:custTelNo forKey:@"TelNo"];
    [orderCustomerInfo setValue:custGstNo forKey:@"GstNo"];
    
    if([[orderCustomerInfo objectForKey:@"Name"] length] == 0)
    {
        self.title = [NSString stringWithFormat:@"%@ %@",_tableName,_connectedStatus];
    }
    else
    {
        self.title = [NSString stringWithFormat:@"%@ %@ (%@)",_tableName,_connectedStatus,[orderCustomerInfo objectForKey:@"Name"]];
    }
    
    [self dismissViewControllerAnimated:true completion:nil];
}


#pragma mark - delegate from print bill selection
-(void)printSelectedSalesOrderWithSalesOrderNo:(NSString *)salesDocNo BillStatus:(NSString *)billStatus
{
    
    if (![billStatus isEqualToString:@"Current"]) {
        docNo = salesDocNo;
    }
    
    if ([docNo length] == 0) {
        [self showAlertView:@"Empty sales order" title:@"Warning"];
        return;
    }
    
    if ([printerBrand isEqualToString:@"Star"]) {
        if ([printerMode isEqualToString:@"Line"]) {
            [self printSOReceiptInLineMode];
        }
        else if ([printerMode isEqualToString:@"Raster"])
        {
            [self PrintSOReceiptInRasterMode];
        }
    }
    else if ([printerBrand isEqualToString:@"Asterix"])
    {
        //[self makeEposSale/sOrderReceipt];
    }
}

#pragma mark - delegate from void sales order

-(void)dismissVoidOrderViewWithResult:(NSString *)result{
    
    if ([result isEqualToString:@"True"]) {
        [self makeOrderViewKitchenReceiptWithOrderListArray:orderFinalArray KitchenAction:-1];
        
        [self printOutKitchenReceipt];
    }
    
    if ([[LibraryAPI sharedInstance] getKioskMode] == 0) {
        [self.navigationController popViewControllerAnimated:NO];
    }
    else
    {
        [self clearSalesScreen];
    }
}

#pragma mark - delegate from splitbill
-(void)cancelSplitBill:(NSString *)cancelMethod
{
    //[self.navigationController popViewControllerAnimated:YES];
    if ([cancelMethod isEqualToString:@"NoPay"]) {
        /*
        soNo = [[LibraryAPI sharedInstance]getDocNo];
        if ([terminalType isEqualToString:@"Main"]) {
            [self checkTableStatus];
        }
        else
        {
            [self requestSODtlFromServer];
        }
         */
        
    }
    else
    {
        [self.navigationController popViewControllerAnimated:NO];
    }
    
}

#pragma mark - delegate from payment
-(void)successMakePayment:(NSString *)payLeftOrRight
{
    
    if ([[LibraryAPI sharedInstance] getKioskMode] == 0) {
        [self clearExistingArrayMemory];
        [self.navigationController popViewControllerAnimated:NO];
    }
    else
    {
        orderDataStatus = @"New";
        _docType = @"SalesOrder";
        [self clearSalesScreen];
    }
    
}

-(void)cancelPayment:(NSString *)soOldNo
{
    
}

#pragma mark - delegate from option view
-(void)kioskFindBillView
{
    //[self.popOverOption dismissPopoverAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    BillListingViewController *billListingViewController = [[BillListingViewController alloc] init];
    
    [billListingViewController setModalPresentationStyle:UIModalPresentationFormSheet];
    [billListingViewController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    [self.navigationController presentViewController:billListingViewController animated:YES completion:nil];
    
}

-(void)kioskEditBillView
{
    if (orderFinalArray.count > 0) {
        [self showAlertView:@"Order in progress. Cannot edit bill" title:@"Warning"];
        return;
    }
    
    //[self.popOverOption dismissPopoverAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    EditBillViewController *editBillViewController = [[EditBillViewController alloc] init];
    editBillViewController.delegate = self;
    [editBillViewController setModalPresentationStyle:UIModalPresentationFormSheet];
    [editBillViewController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    [self.navigationController presentViewController:editBillViewController animated:YES completion:nil];
}

#pragma mark - delegate from Edited Bill

-(void)orderingEditBillOnOrderScreenWithTableName:(NSString *)tableName TableNo:(NSInteger)tableNo DineType:(NSString *)dineType OverrideTableSVC:(NSString *)overrideTableSVC PaxNo:(NSString *)paxNo CSDocNo:(NSString *)csDocNo TpServicePercent:(NSString *)tpServicePercent
{
    [self dismissViewControllerAnimated:NO completion:nil];
    
    [[LibraryAPI sharedInstance]setTableNo:tableNo];
    _tableName = tableName;
    _tbStatus = dineType;
    _overrideTableSVC = overrideTableSVC;
    _connectedStatus = @"";
    _docType = @"CashSales";
    _paxData = paxNo;
    _csDocNo = csDocNo;
    [PublicMethod settingServiceTaxPercentWithOverRide:overrideTableSVC Percent:tpServicePercent];
     
    [[LibraryAPI sharedInstance]setDocNo:@"-"];
    
    [self diffSalesOrderNCashSales];
}

#pragma mark - Star Printer kitchen receipt

-(void)PrintStarKitchenReceiptInRasterModeWithItemName:(NSString *)itemName OrderQty:(NSString *)orderQty PortName:(NSString *)portName {
    //InvNo = @"IV000000063";
    p_selectedWidthInch = SMKitchenSingleReceipt;
    p_selectedLanguage = SMLanguageEnglish;
    
    printerPortSetting = @"Standard";
    
    [PrinterFunctions PrintRasterSingleKitchenWithPortname:portName portSettings:printerPortSetting ItemName:itemName TableName:_tableName OrderQty:orderQty];
    
}

- (void)PrintStarKitchenReceiptInLineModeWithItemName:(NSString *)itemName OrderQty:(NSString *)orderQty PortName:(NSString *)portName {
    
    
    p_selectedWidthInch = SMPaperWidth3inchSO;
    p_selectedLanguage = SMLanguageEnglish;
    
    //NSData *[commands = [PrinterFunctions printL]]
    NSData *commands = [PrinterFunctions printKitchenReceiptWithPaperWidth:p_selectedWidthInch language:p_selectedLanguage Item:itemName TableName:_tableName Qty:orderQty];
    
    if (commands == nil) {
        return;
    }
    
    printerPortSetting = @"Standard";
    [PrinterFunctions sendCommand:commands
                         portName:portName
                     portSettings:printerPortSetting
                    timeoutMillis:10000];
    
    
}

- (void)PrintStarGroupKitchenReceiptInLineModeWithOrderArray:(NSMutableArray *)orderArray PortName:(NSString *)portName {
    
    p_selectedWidthInch = SMPaperWidth3inchSO;
    p_selectedLanguage = SMLanguageEnglish;
    
    //NSData *[commands = [PrinterFunctions printL]]
    
    NSData *commands = [PrinterFunctions printGroupKitchenReceiptWithPaperWidth:p_selectedWidthInch language:p_selectedLanguage OrderArray:orderArray TableName:_tableName];
    
    if (commands == nil) {
        return;
    }
    
    printerPortSetting = @"Standard";
    [PrinterFunctions sendCommand:commands
                         portName:portName
                     portSettings:printerPortSetting
                    timeoutMillis:10000];
    
    
}

-(void)PrintStarGroupKitchenReceiptInRasterModeWithItemName:(NSString *)itemName OrderArray:(NSMutableArray *)orderArray PortName:(NSString *)portName {
    //InvNo = @"IV000000063";
    p_selectedWidthInch = SMKitchenSingleReceipt;
    p_selectedLanguage = SMLanguageEnglish;
    
    printerPortSetting = @"Standard";
    
    [PrinterFunctions PrintRasterGroupKitchenWithPortname:portName portSettings:printerPortSetting OrderDetail:orderArray TableName:_tableName];
    
}


#pragma  mark group kitchen data

-(void)makeOrderViewKitchenReceiptWithOrderListArray:(NSMutableArray *)orderListArray KitchenAction:(int)kitchenAction
{
    int kitchenReceiptType = 0;
    NSString *uniID;
    NSString *printStatus;
    NSString *serverType;
    NSString *packageName;
    NSString *showPackageDetail;
    
    if ([terminalType isEqualToString:@"Main"])
    {
        uniID = @"Server";
    }
    else
    {
        uniID = [[LibraryAPI sharedInstance] getTerminalDeviceName];
    }
    
    if (kitchenAction == -1) {
        kitchenReceiptType = 0;
    }
    else
    {
        kitchenReceiptType = [[LibraryAPI sharedInstance] getKitchenReceiptGrouping];
    }
    
    //if (kitchenReceiptType == 0) {
        //[kReceiptArray removeAllObjects];
        for (int i = 0; i < orderListArray.count; i++) {
            
            if (kitchenAction == -1) {
                printStatus = @"Print";
            }
            else
            {
                printStatus = [[orderListArray objectAtIndex:i] objectForKey:@"IM_Print"];
            }
            
            if ([[[orderListArray objectAtIndex:i] objectForKey:@"IM_TakeAwayYN"] isEqualToString:@"0"]) {
                serverType = @"";
            }
            else
            {
                serverType = @"(T)";
            }
            
            NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"Index MATCHES[cd] %@",
                                       [[orderListArray objectAtIndex:i] objectForKey:@"PackageItemIndex"]];
            
            NSArray *parentObject = [orderListArray filteredArrayUsingPredicate:predicate1];
            
            if (parentObject.count > 0) {
                packageName = [[parentObject objectAtIndex:0] objectForKey:@"IM_Description"];
            }
            else
            {
                packageName = @"";
            }
            
            if (![packageName isEqualToString:@""]) {
                if ([[LibraryAPI sharedInstance] getShowPackageDetail] == 0) {
                    showPackageDetail = @"NonShow";
                }
                else
                {
                    showPackageDetail = @"Show";
                }
            }
            else
            {
                showPackageDetail = @"Show";
            }
            
            if ([showPackageDetail isEqualToString:@"Show"]) {
                if ([[[orderListArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"] ||
                    [[[orderListArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"PackageItemOrder"])
                {
                    
                    [self sendDataToKitchenPrinterWithItemNo:[[orderListArray objectAtIndex:i] objectForKey:@"IM_ItemCode"] IM_PrintStatus:printStatus ItemQty:[NSString stringWithFormat:@"%ld",[[[orderListArray objectAtIndex:i] objectForKey:@"IM_OrgQty"] integerValue] * kitchenAction] IMDesc:[NSString stringWithFormat:@"%@ %@",[[orderListArray objectAtIndex:i] objectForKey:@"IM_Description"],serverType] OrderType:[[orderListArray objectAtIndex:i] objectForKey:@"OrderType"] ManualID:[NSString stringWithFormat:@"%@-%@",uniID,[[orderListArray objectAtIndex:i] objectForKey:@"Index"]] PackageName:packageName PackageItemQty:[NSString stringWithFormat:@"%d",1 * kitchenAction]];
                }
                else
                {
                    
                    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"Index MATCHES[cd] %@",
                                               [[orderListArray objectAtIndex:i] objectForKey:@"ParentIndex"]];
                    
                    NSArray *parentObject = [orderListArray filteredArrayUsingPredicate:predicate1];
                    
                    printStatus = [[parentObject objectAtIndex:0] objectForKey:@"IM_Print"];
                    parentObject = nil;
                    [self sendDataToKitchenPrinterWithItemNo:[[orderListArray objectAtIndex:i] objectForKey:@"ItemCode"] IM_PrintStatus:printStatus ItemQty:[[orderListArray objectAtIndex:i] objectForKey:@"UnitQty"] IMDesc:[[orderListArray objectAtIndex:i] objectForKey:@"CDDescription"] OrderType:[[orderListArray objectAtIndex:i] objectForKey:@"OrderType"] ManualID:[NSString stringWithFormat:@"%@-%@",uniID,[[orderListArray objectAtIndex:i] objectForKey:@"ParentIndex"]]PackageName:@"" PackageItemQty:@"0"];
                }

            }
            
        }

    //}
    /*
    else
    {
        [self makeGroupKitchenReceipt];
        
    }
    */
    
}

#pragma mark - make asterix kitchen data
/*
-(void)printAsterixKitchenReceiptWithKitchenData:(NSMutableArray *)kitchenData
{
    
    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"KR_Brand MATCHES[cd] %@",
                               @"Asterix"];
    
    NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"KR_OrderType MATCHES[cd] %@",
                               @"ItemOrder"];
    
    NSPredicate *finalPredicate1 = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate1, predicate2]];
    
    NSArray * itemOrderObject = [kitchenData filteredArrayUsingPredicate:finalPredicate1];
    
    for (int i = 0; i < itemOrderObject.count; i++) {
        NSPredicate *predicate3 = [NSPredicate predicateWithFormat:@"KR_ManualID MATCHES[cd] %@", [[itemOrderObject objectAtIndex:i] objectForKey:@"KR_ManualID"]];
        NSPredicate *predicate4 = [NSPredicate predicateWithFormat:@"KR_OrderType MATCHES[cd] %@",
                                   @"CondimentOrder"];
        
        NSPredicate *finalPredicate2 = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate3, predicate4]];
        
        NSArray * condimentOrderObject = [kitchenData filteredArrayUsingPredicate:finalPredicate2];
        
        if (condimentOrderObject.count > 0)
        {
            [PublicMethod printAsterixKitchenReceiptWithItemDesc:[[itemOrderObject objectAtIndex:i] objectForKey:@"KR_Desc"] IPAdd:[[itemOrderObject objectAtIndex:i] objectForKey:@"KR_IpAddress"] imQty:[[itemOrderObject objectAtIndex:i] objectForKey:@"KR_Qty"] TableName:[[itemOrderObject objectAtIndex:i] objectForKey:@"KR_TableName"] DataArray:condimentOrderObject];
        }
        else
        {
            [PublicMethod printAsterixKitchenReceiptWithItemDesc:[[itemOrderObject objectAtIndex:i] objectForKey:@"KR_Desc"] IPAdd:[[itemOrderObject objectAtIndex:i] objectForKey:@"KR_IpAddress"] imQty:[[itemOrderObject objectAtIndex:i] objectForKey:@"KR_Qty"] TableName:[[itemOrderObject objectAtIndex:i] objectForKey:@"KR_TableName"] DataArray:nil];
        }
        
        
    }
    
    
    //[PublicMethod printAsterixKitchenReceiptWithItemDesc:@"" IPAdd:@"192.168.0.13" imQty:@"" TableName:@"" DataArray:kitchenGroup];
    
}
 */

/*
-(void)printAsterixKitchenReceiptGroupFormatKitchenData:(NSMutableArray *)kitchenData
{
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rsPrinter = [db executeQuery:@"Select * from Printer where P_Type = ? and P_Brand = ?",@"Kitchen", @"Asterix"];
        while ([rsPrinter next]) {
            NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"KR_Brand MATCHES[cd] %@",
                                       @"Asterix"];
            
            NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"KR_IpAddress MATCHES[cd] %@",
                                       [rsPrinter stringForColumn:@"P_PortName"]];
            
            NSPredicate *finalPredicate1 = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate1, predicate2]];
            
            NSArray * itemOrderObject = [kitchenData filteredArrayUsingPredicate:finalPredicate1];
            NSMutableString *mString = [[NSMutableString alloc]init];
            NSString *tableName;
            for (int i = 0; i < itemOrderObject.count; i++) {
                if ([[[itemOrderObject objectAtIndex:i] objectForKey:@"KR_OrderType"]isEqualToString:@"ItemOrder"]) {
                    tableName = [[itemOrderObject objectAtIndex:i] objectForKey:@"KR_TableName"];
                    
                    NSPredicate *predicate3 = [NSPredicate predicateWithFormat:@"KR_ManualID MATCHES[cd] %@", [[itemOrderObject objectAtIndex:i] objectForKey:@"KR_ManualID"]];
                    NSPredicate *predicate4 = [NSPredicate predicateWithFormat:@"KR_OrderType MATCHES[cd] %@",
                                               @"CondimentOrder"];
                    
                    NSPredicate *finalPredicate2 = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate3, predicate4]];
                    
                    NSArray * condimentOrderObject = [kitchenData filteredArrayUsingPredicate:finalPredicate2];
                    
                    [mString appendString:[PublicMethod makeKitchen//GroupReceiptFormatWithItemDesc:[[itemOrderObject objectAtIndex:i] objectForKey:@"KR_Desc"] ItemQty:[[itemOrderObject objectAtIndex:i] objectForKey:@"KR_Qty"]]];
                    
                    for (int j = 0; j < condimentOrderObject.count; j++) {
                        [mString appendString:[NSString stringWithFormat:@" - %@ %@\r\n",[[condimentOrderObject objectAtIndex:j]objectForKey:@"KR_Desc"],[[condimentOrderObject objectAtIndex:j] objectForKey:@"KR_Qty"]]];
                        [mString appendString:@"\r\n"];
                    }
                    
                    condimentOrderObject = nil;

                }
            }
            itemOrderObject = nil;
            
            [PublicMethod printAsterixKRGroupWithIpAdd:[rsPrinter stringForColumn:@"P_PortName"] TableName:tableDesc Data:mString];
            
        }
    }];
    
}
*/
-(void)printOutKitchenReceipt
{
    
    operationQue = [NSOperationQueue new];
    
    NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(insertKitchenDataToPrintQueue) object:nil];
    
    [operationQue addOperation:operation];
    operation = nil;
}

-(void)insertKitchenDataToPrintQueue
{
    
    int kitchenReceiptType = 0;
    
    kitchenReceiptType = [[LibraryAPI sharedInstance] getKitchenReceiptGrouping];
    
    if ([terminalType isEqualToString:@"Terminal"] && kitchenReceiptType == 0) {
        if (kitchenGroup.count > 0) {
            [self insertKitchenReceiptToServerWithArray:kitchenGroup];
        }
        
    }
    else if ([terminalType isEqualToString:@"Terminal"] && kitchenReceiptType == 1) {
        if (kitchenGroup.count > 0) {
            [self insertKitchenReceiptToServerWithArray:kitchenGroup];
        }
        
    }
    else if ([terminalType isEqualToString:@"Main"] && kitchenReceiptType == 0) {
        if (kitchenGroup.count > 0) {
            [[NSNotificationCenter defaultCenter]postNotificationName:@"ServerCallConnectionArrayWithNotification" object:kitchenGroup userInfo:nil];
        }
        
    }
    else if ([terminalType isEqualToString:@"Main"] && kitchenReceiptType == 1)
    {
        if (kitchenGroup.count > 0) {
            [[NSNotificationCenter defaultCenter]postNotificationName:@"ServerCallConnectionArrayWithNotification" object:kitchenGroup userInfo:nil];
        }
    }
    /*
    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"KR_Brand MATCHES[cd] %@",
                               @"Asterix"];
    
    NSArray *itemOrderObject = [kitchenGroup filteredArrayUsingPredicate:predicate1];
    
    if (itemOrderObject.count > 0) {
        if (kitchenReceiptType == 0) {
            [PublicMethod printAsterixKitchenReceiptWithKitchenData:kitchenGroup];
            //[self testWithKitchenData:kitchenGroup];
            
        }
        else
        {
            [PublicMethod printAsterixKitchenReceiptGroupFormatKitchenData:kitchenGroup];
        }
    }
    */
    //predicate1 = nil;
    //itemOrderObject = nil;
    
    [kitchenGroup removeAllObjects];
    //[kReceiptArray removeAllObjects];
    kitchenGroup = nil;
    //[operationQue cancelAllOperations];
}

-(void)testWithKitchenData:(NSMutableArray *)kitchenData
{

    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"KR_Brand MATCHES[cd] %@",
                               @"Asterix"];
    
    NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"KR_OrderType MATCHES[cd] %@",
                               @"ItemOrder"];
    
    NSPredicate *finalPredicate1 = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate1, predicate2]];
    
    NSArray * itemOrderObject = [kitchenData filteredArrayUsingPredicate:finalPredicate1];
    
    for (int i = 0; i < itemOrderObject.count; i++) {
        NSPredicate *predicate3 = [NSPredicate predicateWithFormat:@"KR_ManualID MATCHES[cd] %@", [[itemOrderObject objectAtIndex:i] objectForKey:@"KR_ManualID"]];
        NSPredicate *predicate4 = [NSPredicate predicateWithFormat:@"KR_OrderType MATCHES[cd] %@",
                                   @"CondimentOrder"];
        
        NSPredicate *finalPredicate2 = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate3, predicate4]];
        
        NSArray * condimentOrderObject = [kitchenData filteredArrayUsingPredicate:finalPredicate2];
        
        if (condimentOrderObject.count > 0)
        {
            [PublicMethod printAsterixKitchenReceiptWithItemDesc:[[itemOrderObject objectAtIndex:i] objectForKey:@"KR_Desc"] IPAdd:[[itemOrderObject objectAtIndex:i] objectForKey:@"KR_IpAddress"] imQty:[[itemOrderObject objectAtIndex:i] objectForKey:@"KR_Qty"] TableName:[[itemOrderObject objectAtIndex:i] objectForKey:@"KR_TableName"] DataArray:condimentOrderObject];
            
            
        }
        else
        {
            
            [PublicMethod printAsterixKitchenReceiptWithItemDesc:[[itemOrderObject objectAtIndex:i] objectForKey:@"KR_Desc"] IPAdd:[[itemOrderObject objectAtIndex:i] objectForKey:@"KR_IpAddress"] imQty:[[itemOrderObject objectAtIndex:i] objectForKey:@"KR_Qty"] TableName:[[itemOrderObject objectAtIndex:i] objectForKey:@"KR_TableName"] DataArray:nil];
            
        }
        predicate3 = nil;
        predicate4 = nil;
        
    }
    predicate1 = nil;
    predicate2 = nil;
    
}

-(void)disconnectXYWifiSocket
{
    
}

-(void)sendDataToKitchenPrinterWithItemNo:(NSString *)itemCode IM_PrintStatus:(NSString *)status ItemQty:(NSString *)itemQty IMDesc:(NSString *)imDesc OrderType:(NSString *)orderType ManualID:(NSString *)manualID PackageName:(NSString *)packageName PackageItemQty:(NSString *)packageItemQty
{
    if ([status isEqualToString:@"Print"]) {
        
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
        
        [queue inDatabase:^(FMDatabase *db) {
            FMResultSet *rsPrinter = [db executeQuery:@"Select * from Printer where P_Type = ?",@"Kitchen"];
            
            if (![rsPrinter next]) {
                [rsPrinter close];
                return;
            }
            else
            {
                [rsPrinter close];
            }
            
            FMResultSet *rsItemPrinter = [db executeQuery:@"Select IP_PrinterName, P_Mode, P_Brand, P_PortName from ItemPrinter IP inner join Printer p on IP.IP_PrinterName = P.P_PrinterName where IP.IP_ItemNo = ?",itemCode];
            makeXinYeDiscon++;
            
            while ([rsItemPrinter next]) {
                NSMutableDictionary *data = [NSMutableDictionary dictionary];
                [data setObject:itemCode forKey:@"KR_ItemCode"];
                [data setObject:status forKey:@"KR_Status"];
                if ([orderType isEqualToString:@"PackageItemOrder"]) {
                    [data setObject:packageItemQty forKey:@"KR_Qty"];
                }
                else
                {
                    [data setObject:itemQty forKey:@"KR_Qty"];
                }
                
                [data setObject:imDesc forKey:@"KR_Desc"];
                [data setObject:@"RequestPrintKitchenReceipt" forKey:@"IM_Flag"];
                [data setObject:[rsItemPrinter stringForColumn:@"P_Brand"] forKey:@"KR_Brand"];
                [data setObject:[rsItemPrinter stringForColumn:@"P_PortName"] forKey:@"KR_IpAddress"];
                [data setObject:[rsItemPrinter stringForColumn:@"P_Mode"] forKey:@"KR_PrintMode"];
                [data setObject:_tableName forKey:@"KR_TableName"];
                [data setObject:@"Kitchen" forKey:@"KR_DocType"];
                [data setObject:@"Non" forKey:@"KR_DocNo"];
                [data setObject:orderType forKey:@"KR_OrderType"];
                [data setObject:manualID forKey:@"KR_ManualID"];
                [data setObject:[rsItemPrinter stringForColumn:@"IP_PrinterName"] forKey:@"KR_PrinterName"];
                [data setObject:packageName forKey:@"KR_PackageName"];
                [kitchenGroup addObject:data];
                
                data = nil;
                /*
                if ([terminalType isEqualToString:@"Terminal"]) {
                    NSMutableDictionary *data = [NSMutableDictionary dictionary];
                    [data setObject:itemCode forKey:@"KR_ItemCode"];
                    [data setObject:status forKey:@"KR_Status"];
                    [data setObject:itemQty forKey:@"KR_Qty"];
                    [data setObject:imDesc forKey:@"KR_Desc"];
                    [data setObject:@"RequestPrintKitchenReceipt" forKey:@"IM_Flag"];
                    [data setObject:[rsItemPrinter stringForColumn:@"P_Brand"] forKey:@"KR_Brand"];
                    [data setObject:[rsItemPrinter stringForColumn:@"P_PortName"] forKey:@"KR_IpAddress"];
                    [data setObject:[rsItemPrinter stringForColumn:@"P_Mode"] forKey:@"KR_PrintMode"];
                    [data setObject:_tableName forKey:@"KR_TableName"];
                    [data setObject:@"Kitchen" forKey:@"KR_DocType"];
                    [data setObject:@"Non" forKey:@"KR_DocNo"];
                    [data setObject:orderType forKey:@"KR_OrderType"];
                    [data setObject:manualID forKey:@"KR_ManualID"];
                    [data setObject:[rsItemPrinter stringForColumn:@"IP_PrinterName"] forKey:@"KR_PrinterName"];
                    [data setObject:packageName forKey:@"KR_PackageName"];
                    
                    [kitchenGroup addObject:data];
                    data = nil;
                }
                else
                {
                }
                 */
                
            }
            
            [rsItemPrinter close];
        }];
        [queue close];
    }
}

-(void)makeGroupKitchenReceipt
{
    __block NSString *serverType;
    __block NSString *packageName;
    __block NSString *showPackageDetail;
    //NSLog(@"%@",[[orderFinalArray objectAtIndex:0] objectForKey:@"IM_ItemCode"]);
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        NSString *uniID;
        NSString *printStatus;
        
        if ([terminalType isEqualToString:@"Main"]) {
            uniID = @"Server";
        }
        else
        {
            uniID = [[LibraryAPI sharedInstance] getTerminalDeviceName];
        }
        
        FMResultSet *rsPrinter = [db executeQuery:@"Select * from Printer where P_Type = ?",@"Kitchen"];
        //[kitchenGroup removeAllObjects];
        while ([rsPrinter next]) {
            
            for (int i = 0; i < orderFinalArray.count; i++) {
                
                NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"Index MATCHES[cd] %@",
                                           [[orderFinalArray objectAtIndex:i] objectForKey:@"PackageItemIndex"]];
                
                NSArray *parentObject = [orderFinalArray filteredArrayUsingPredicate:predicate1];
                
                if (parentObject.count > 0) {
                    packageName = [[parentObject objectAtIndex:0] objectForKey:@"IM_Description"];
                }
                else
                {
                    packageName = @"";
                }
                
                if ([[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_TakeAwayYN"] isEqualToString:@"0"]) {
                    serverType = @"";
                }
                else
                {
                    serverType = @"(T)";
                }
                
                if (![packageName isEqualToString:@""]) {
                    if ([[LibraryAPI sharedInstance] getShowPackageDetail] == 0) {
                        showPackageDetail = @"NonShow";
                    }
                    else
                    {
                        showPackageDetail = @"Show";
                    }
                }
                else
                {
                    showPackageDetail = @"Show";
                }
                
                if ([showPackageDetail isEqualToString:@"Show"]) {
                    if ([[[orderFinalArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"] || [[[orderFinalArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"PackageItemOrder"])
                    {
                        
                        if ([[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Print"] isEqualToString:@"Print"])
                        {
                            FMResultSet *rsItemPrinter = [db executeQuery:@"Select IM_Description, IM_Description2, IM_ItemCode from ItemPrinter IP"
                                                          " inner join ItemMast IM on IP.IP_ItemNo = IM.IM_ItemCode where IP.IP_ItemNo = ?"
                                                          " and IP.IP_PrinterName = ?",[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_ItemCode"],[rsPrinter stringForColumn:@"P_PrinterName"]];
                            
                            if ([rsItemPrinter next]) {
                                NSMutableDictionary *data = [NSMutableDictionary dictionary];
                                [data setObject:[rsItemPrinter stringForColumn:@"IM_ItemCode"] forKey:@"KR_ItemCode"];
                                [data setObject:[NSString stringWithFormat:@"%@ %@",[rsItemPrinter stringForColumn:@"IM_Description"],serverType] forKey:@"KR_Desc"];
                                [data setObject:[rsItemPrinter stringForColumn:@"IM_Description2"] forKey:@"KR_Desc2"];
                                
                                [data setObject:[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_OrgQty"] forKey:@"KR_Qty"];
                                
                                [data setObject:@"RequestPrintKitchenReceipt" forKey:@"IM_Flag"];
                                [data setObject:[rsPrinter stringForColumn:@"P_Brand"] forKey:@"KR_Brand"];
                                [data setObject:[rsPrinter stringForColumn:@"P_PortName"] forKey:@"KR_IpAddress"];
                                [data setObject:[rsPrinter stringForColumn:@"P_Mode"] forKey:@"KR_PrintMode"];
                                [data setObject:_tableName forKey:@"KR_TableName"];
                                [data setObject:@"Kitchen" forKey:@"KR_DocType"];
                                [data setObject:@"Non" forKey:@"KR_DocNo"];
                                [data setObject:@"ItemOrder" forKey:@"KR_OrderType"];
                                [data setObject:[NSString stringWithFormat:@"%@-%@",uniID,[[orderFinalArray objectAtIndex:i] objectForKey:@"Index"]] forKey:@"KR_ManualID"];
                                [data setObject:[rsPrinter stringForColumn:@"P_PrinterName"] forKey:@"KR_PrinterName"];
                                [data setObject:packageName forKey:@"KR_PackageName"];
                                [kitchenGroup addObject:data];
                            }
                            [rsItemPrinter close];
                        }
                    }
                    else
                    {
                        
                        NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"Index MATCHES[cd] %@",
                                                   [[orderFinalArray objectAtIndex:i] objectForKey:@"ParentIndex"]];
                        
                        NSArray *parentObject = [orderFinalArray filteredArrayUsingPredicate:predicate1];
                        
                        printStatus = [[parentObject objectAtIndex:0] objectForKey:@"IM_Print"];
                        parentObject = nil;
                        
                        if ([printStatus isEqualToString:@"Print"])
                        {
                            FMResultSet *rsItemPrinter = [db executeQuery:@"Select IM_Description, IM_Description2, IM_ItemCode from ItemPrinter IP"
                                                          " inner join ItemMast IM on IP.IP_ItemNo = IM.IM_ItemCode where IP.IP_ItemNo = ?"
                                                          " and IP.IP_PrinterName = ?",[[orderFinalArray objectAtIndex:i] objectForKey:@"ItemCode"],[rsPrinter stringForColumn:@"P_PrinterName"]];
                            
                            if ([rsItemPrinter next]) {
                                NSMutableDictionary *data = [NSMutableDictionary dictionary];
                                [data setObject:[[orderFinalArray objectAtIndex:i] objectForKey:@"ItemCode"] forKey:@"KR_ItemCode"];
                                [data setObject:[[orderFinalArray objectAtIndex:i] objectForKey:@"CDDescription"] forKey:@"KR_Desc"];
                                [data setObject:[[orderFinalArray objectAtIndex:i] objectForKey:@"CDDescription"] forKey:@"KR_Desc2"];
                                [data setObject:[[orderFinalArray objectAtIndex:i] objectForKey:@"UnitQty"] forKey:@"KR_Qty"];
                                
                                [data setObject:@"RequestPrintKitchenReceipt" forKey:@"IM_Flag"];
                                [data setObject:[rsPrinter stringForColumn:@"P_Brand"] forKey:@"KR_Brand"];
                                [data setObject:[rsPrinter stringForColumn:@"P_PortName"] forKey:@"KR_IpAddress"];
                                [data setObject:[rsPrinter stringForColumn:@"P_Mode"] forKey:@"KR_PrintMode"];
                                [data setObject:_tableName forKey:@"KR_TableName"];
                                [data setObject:@"Kitchen" forKey:@"KR_DocType"];
                                [data setObject:@"Non" forKey:@"KR_DocNo"];
                                [data setObject:@"CondimentOrder" forKey:@"KR_OrderType"];
                                [data setObject:[NSString stringWithFormat:@"%@-%@",uniID,[[orderFinalArray objectAtIndex:i] objectForKey:@"ParentIndex"]] forKey:@"KR_ManualID"];
                                [data setObject:[rsPrinter stringForColumn:@"P_PrinterName"] forKey:@"KR_PrinterName"];
                                [data setObject:packageName forKey:@"KR_PackageName"];
                                
                                [kitchenGroup addObject:data];
                            }
                            [rsItemPrinter close];
                        }
                        
                    }

                }
                
                //NSLog(@"%@",[rsPrinter stringForColumn:@"P_PortName"]);
                
            }
            
        }
        [rsPrinter close];
        
    }];
    
    //kitchenGroup = nil;
    [queue close];
    
}

/*
-(void)runPrintLitchenGroup:(NSString *)portName
{
    Result *result = nil;
    EposBuilder *builder = nil;
    
    result = [[Result alloc] init];
    
    builder = [EposPrintFunction createKitchenReceiptGroupFormat:result OrderDetail:kitchenGroup TableName:_tableName];
    
    if(result.errType == RESULT_ERR_NONE) {
        [EposPrintFunction print:builder Result:result PortName:portName];
    }
    
    if (builder != nil) {
        [builder clearCommandBuffer];
    }
    
    [EposPrintFunction displayMsg:result];
    
    if(result != nil) {
        result = nil;
    }
    
    return;
}
 */
/*
- (void)runPrintKicthenSequenceWithItemDesc:(NSString *)imDesc IPAdd:(NSString *)ipAdd imQty:(NSString *)imQty
{
    Result *result = nil;
    EposBuilder *builder = nil;
    
    result = [[Result alloc] init];
    
    builder = [EposPrintFunction createKitchenReceiptFormat:result TableNo:tableDesc ItemNo:imDesc Qty:imQty];
    
    if(result.errType == RESULT_ERR_NONE) {
        [EposPrintFunction print:builder Result:result PortName:ipAdd];
    }
    
    if (builder != nil) {
        [builder clearCommandBuffer];
    }
    
    [EposPrintFunction displayMsg:result];
    
    if(result != nil) {
        result = nil;
    }
    
    return;
}
*/
/*
-(BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
    return NO;
}
 */

-(BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
    return NO;
}

#pragma mark - FlyTech
-(void)makeFlyTechSalesOrderReceipt
{
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:[[LibraryAPI sharedInstance] getPrinterPortName]];
    if ([PosApi getBleConnectionStatus:uuid] == 0) {
        [self showAlertView:@"Bluetooth printer is connecting" title:@"Information"];
    }
    else if ([PosApi getBleConnectionStatus:uuid] == 2)
    {
        [self showAlertView:@"Bluetooth printer is disconnect" title:@"Information"];
    }
    else
    {
        
        //[EposPrintFunction createFlyTechSalesOrderRceiptWithDBPath:dbPath GetInvNo:docNo EnableGst:compEnableGst];
    }
    
}

-(void)runPrintFlyTechKitchenReceiptWithIMDesc:(NSString *)imDesc Qty:(NSString *)imQty
{
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:[[LibraryAPI sharedInstance] getPrinterPortName]];
    if ([PosApi getBleConnectionStatus:uuid] == 0) {
        [self showAlertView:@"Bluetooth printer is connecting" title:@"Information"];
    }
    else if ([PosApi getBleConnectionStatus:uuid] == 2)
    {
        [self showAlertView:@"Bluetooth printer is disconnect" title:@"Information"];
    }
    else
    {
        [PosApi initPrinter];
        //[EposPrintFunction createFlyTechKitchenReceiptWithDBPath:dbPath TableNo:_tableName ItemNo:imDesc Qty:imQty];
    }
}

/*
-(void)runPrintFlyTechGroupKitchenReceipt
{
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:[[LibraryAPI sharedInstance] getPrinterPortName]];
    if ([PosApi getBleConnectionStatus:uuid] == 0) {
        [self showAlertView:@"Bluetooth printer is connecting" title:@"Information"];
    }
    else if ([PosApi getBleConnectionStatus:uuid] == 2)
    {
        [self showAlertView:@"Bluetooth printer is disconnect" title:@"Information"];
    }
    else
    {
        [PosApi initPrinter];
        [EposPrintFunction createFlyTechKitReceiptGroupWithOrderDetail:kitchenGroup TableName:_tableName];
    }
}
*/

#pragma mark - XinYe printer
-(void)makeXinYeSalesOrderReceipt
{
    if ([terminalType isEqualToString:@"Main"]) {
        /*
        [self.wifiManager XYDisConnect];
        [_wifiManager XYConnectWithHost:[[printSOArray objectAtIndex:0] objectForKey:@"P_PortName"] port:9100 completion:^(BOOL isConnect) {
            if (isConnect) {
                [self sendCommandToXinYePrinter];
            }
        }];
         */
        [[NSNotificationCenter defaultCenter]postNotificationName:@"ServerCallConnectionArrayWithNotification" object:kitchenGroup userInfo:nil];
        [kitchenGroup removeAllObjects];
        
    }
    else
    {
        //[self requestXinYePrintSalesOrderFromServer];
        [self insertKitchenReceiptToServerWithArray:kitchenGroup];
        [kitchenGroup removeAllObjects];
    }
    
}

-(void)sendCommandToXinYePrinter
{
    NSMutableData *commands = [NSMutableData data];
    if ([terminalType isEqualToString:@"Main"]) {
        //commands = [EposPrintFunction generateSalesOrderReceiptFormatWithDBPath:dbPath GetInvNo:docNo EnableGst:compEnableGst PrinterBrand:@"XinYe" ReceiptLength:48];
        
        NSMutableData* dataM=[NSMutableData dataWithData:[PosCommand initializePrinter]];
        [dataM appendData:commands];
        [self.wifiManager XYWriteCommandWithData:dataM];
        
    }
    else
    {
        //[TerminalData flyTechRequestCSDataWithCSNo:docNo];
    }
}

-(void)sendCommandToXinYePrinterKitchenWithIMDesc:(NSString *)imDesc Qty:(NSString *)imQty IPAdd:(NSString *)ipAdd
{
    NSMutableData *commands = [NSMutableData data];
    
    //commands = [EposPrintFunction createXinYeKitchenReceiptWithDBPath:dbPath TableNo:_tableName ItemNo:imDesc Qty:imQty DataArray:nil];
    
    NSMutableData* dataM=[NSMutableData dataWithData:[PosCommand initializePrinter]];
    [dataM appendData:commands];
    [xinYeOrderingWfMng XYWriteCommandWithData:dataM];
    /*
    XYWIFIManager *xinYeWifi = [[XYWIFIManager alloc] init];
    
    [xinYeWifi XYConnectWithHost:ipAdd port:9100 completion:^(BOOL isConnect) {
        if (isConnect) {
            [xinYeWifi XYDisConnect];
        }
        
    }];
    
    [xinYeWifi XYWriteCommandWithData:dataM];
     */
    
}

-(void)runXinYePrinterGroupReceiptWithPort:(NSString *)ipAdd
{
    [self.wifiManager XYDisConnect];
    
    [_wifiManager XYConnectWithHost:ipAdd port:9100 completion:^(BOOL isConnect) {
        if (isConnect) {
            [self sendCommandToXinYePrinterGroupKitchenReceipt];
        }
    }];
}

-(void)sendCommandToXinYePrinterGroupKitchenReceipt
{
    NSMutableData *commands = [NSMutableData data];
    commands = [EposPrintFunction createXinYeKitReceiptGroupWithOrderDetail:kitchenGroup TableName:_tableName];
    
    NSMutableData* dataM=[NSMutableData dataWithData:[PosCommand initializePrinter]];
    [dataM appendData:commands];
    [self.wifiManager XYWriteCommandWithData:dataM];
    //[self.wifiManager XYDisConnect];
}

#pragma mark - uicollection and scroll view part

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if ([isFiltered isEqualToString:@"True"]) {
        return itemMastArrayFilter.count;
    }
    else
    {
        return itemMastArray.count;
    }
    
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"OrderItemCollectionViewCell";
    
    OrderItemCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    
    if ([isFiltered isEqualToString:@"True"]) {
        
        imgPath = [imgDir stringByAppendingPathComponent:[[itemMastArrayFilter objectAtIndex:indexPath.row]objectForKey:@"IM_File"]];
        
        imgBtn = [UIImage imageWithContentsOfFile:imgPath];
        
        [cell.imgCollectionCell hnk_setImage:imgBtn withKey:[[itemMastArrayFilter objectAtIndex:indexPath.row]objectForKey:@"IM_Code"] placeholder:[UIImage imageNamed:@"no_image.jpg"]];
        
        [[cell labelItemName]setText:[[itemMastArrayFilter objectAtIndex:indexPath.row]objectForKey:@"IM_Desc"]];
        
    }
    else
    {
        
        imgPath = [imgDir stringByAppendingPathComponent:[[itemMastArray objectAtIndex:indexPath.row]objectForKey:@"IM_File"]];
        
        imgBtn = [UIImage imageWithContentsOfFile:imgPath];
        
        [cell.imgCollectionCell hnk_setImage:imgBtn withKey:[[itemMastArray objectAtIndex:indexPath.row]objectForKey:@"IM_Code"] placeholder:[UIImage imageNamed:@"no_image.jpg"]];
        
        [[cell labelItemName]setText:[[itemMastArray objectAtIndex:indexPath.row]objectForKey:@"IM_Desc"]];
    }
    
    cell.contentView.backgroundColor = [UIColor clearColor];
    cell.imgCollectionCell.layer.cornerRadius = 10.0;
    cell.imgCollectionCell.layer.masksToBounds = YES;
    
    
    
    return cell;
}


- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)view forElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
    
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    __block BOOL inclucdeCondiment;
    __block BOOL packageItem;
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs;
        //FMResultSet *rsPackage;
        
        if ([isFiltered isEqualToString:@"True"]) {
            if ([[[itemMastArray objectAtIndex:indexPath.row] objectForKey:@"IM_ServiceType"] isEqualToString:@"0"]) {
                rs = [db executeQuery:@"Select * from ItemCondiment where IC_ItemCode = ?",[[itemMastArrayFilter objectAtIndex:indexPath.row] objectForKey:@"IM_Code"]];
            }
            else{
                packageItem = true;
                itemSelectedIndex = [[[itemMastArrayFilter objectAtIndex:indexPath.row] objectForKey:@"IM_No"] integerValue];
                [self openPackageItemSelectionViewWithItemCode:[[itemMastArray objectAtIndex:indexPath.row] objectForKey:@"IM_Code"] ItemCondiment:inclucdeCondiment ItemName:[[itemMastArray objectAtIndex:indexPath.row] objectForKey:@"IM_Desc"]];
            }
            
        }
        else
        {
            if ([[[itemMastArray objectAtIndex:indexPath.row] objectForKey:@"IM_ServiceType"] isEqualToString:@"0"]) {
                packageItem = false;
                rs = [db executeQuery:@"Select * from ItemCondiment where IC_ItemCode = ?",[[itemMastArray objectAtIndex:indexPath.row] objectForKey:@"IM_Code"]];
            }
            else
            {
                packageItem = true;
                itemSelectedIndex = [[[itemMastArray objectAtIndex:indexPath.row] objectForKey:@"IM_No"] integerValue];
                [self openPackageItemSelectionViewWithItemCode:[[itemMastArray objectAtIndex:indexPath.row] objectForKey:@"IM_Code"] ItemCondiment:inclucdeCondiment ItemName:[[itemMastArray objectAtIndex:indexPath.row] objectForKey:@"IM_Desc"]];
            }
            
        }
        
        if ([rs next]) {
            inclucdeCondiment = true;
        }
        else
        {
            inclucdeCondiment = false;
        }
        [rs close];
    }];
    
    if (!packageItem) {
        if (inclucdeCondiment) {
            OrderAddCondimentViewController *orderAddCondimentViewController = [[OrderAddCondimentViewController alloc]init];
            orderAddCondimentViewController.delegate = self;
            if ([isFiltered isEqualToString:@"True"]) {
                orderAddCondimentViewController.icItemCode = [[itemMastArrayFilter objectAtIndex:indexPath.row] objectForKey:@"IM_Code"];
                orderAddCondimentViewController.icItemPrice = [[itemMastArrayFilter objectAtIndex:indexPath.row] objectForKey:@"IM_Price"];
            }
            else
            {
                orderAddCondimentViewController.icItemCode = [[itemMastArray objectAtIndex:indexPath.row] objectForKey:@"IM_Code"];
                orderAddCondimentViewController.icItemPrice = [[itemMastArray objectAtIndex:indexPath.row] objectForKey:@"IM_Price"];
            }
            orderAddCondimentViewController.icStatus = @"New";
            orderAddCondimentViewController.addCondimentFrom = @"OrderingView";
            UINavigationController *navbar = [[UINavigationController alloc]  initWithRootViewController:orderAddCondimentViewController];
            
            navbar.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            navbar.modalPresentationStyle = UIModalPresentationFormSheet;
            orderAddCondimentViewController.delegate  = self;
            [orderAddCondimentViewController setModalPresentationStyle:UIModalPresentationFormSheet];
            [orderAddCondimentViewController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
            
            [self.navigationController presentViewController:navbar animated:NO completion:nil];
            
            
            if ([isFiltered isEqualToString:@"True"]) {
                itemSelectedIndex = [[[itemMastArrayFilter objectAtIndex:indexPath.row] objectForKey:@"IM_No"] integerValue];
            }
            else
            {
                itemSelectedIndex = [[[itemMastArray objectAtIndex:indexPath.row] objectForKey:@"IM_No"] integerValue];
            }
            
            UICollectionViewCell *datasetCell =[collectionView cellForItemAtIndexPath:indexPath];
            datasetCell.contentView.backgroundColor = [UIColor colorWithRed:189/255.0 green:189/255.0 blue:189/255.0 alpha:1.0];
            directExit = @"No";
        }
        else
        {
            //NSString *itemPrice;
            
            if ([isFiltered isEqualToString:@"True"]) {
                itemSelectedIndex = [[[itemMastArrayFilter objectAtIndex:indexPath.row] objectForKey:@"IM_No"] integerValue];
                predicateItemPrice = [[[itemMastArrayFilter objectAtIndex:indexPath.row] objectForKey:@"IM_Price"] doubleValue];
                predicateItemCode = [[itemMastArrayFilter objectAtIndex:indexPath.row] objectForKey:@"IM_Code"];
            }
            else
            {
                itemSelectedIndex = [[[itemMastArray objectAtIndex:indexPath.row] objectForKey:@"IM_No"] integerValue];
                predicateItemPrice = [[[itemMastArray objectAtIndex:indexPath.row] objectForKey:@"IM_Price"]doubleValue];
                predicateItemCode = [[itemMastArray objectAtIndex:indexPath.row] objectForKey:@"IM_Code"];
            }
            
            UICollectionViewCell *datasetCell =[collectionView cellForItemAtIndexPath:indexPath];
            datasetCell.contentView.backgroundColor = [UIColor colorWithRed:189/255.0 green:189/255.0 blue:189/255.0 alpha:1.0];
            
            [self passBackToOrderScreenWithCondimentDtl:nil DisplayFormat:@"-" TotalCondimentPrice:0 Status:@"New" CondimentUnitPrice:0 PredicatePrice:predicateItemPrice];
            directExit = @"No";
//itemPrice = nil;
        }
        
    }
    
    [queue close];
}

-(void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell *datasetCell =[collectionView cellForItemAtIndexPath:indexPath];
    datasetCell.contentView.backgroundColor = [UIColor clearColor];
}

/*
-(UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    
}
 */


-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.scrollViewSecret) {
        CGPoint contentOffset = scrollView.contentOffset;
        contentOffset.x = contentOffset.x - self.collectionViewMenu.contentInset.left;
        self.collectionViewMenu.contentOffset = contentOffset;
    }
}


#pragma mark - multipeer transfer

-(void)sendOrderToServer
{
    
    if ([orderDataStatus isEqualToString:@"Edit"]) {
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        for (int i = 0; i < orderFinalArray.count; i++) {
            
            data = [orderFinalArray objectAtIndex:i];
            [data setValue:orderDataStatus forKey:@"Status"];
            [data setValue:docNo forKey:@"SOH_DocNo"];
            
            [orderFinalArray replaceObjectAtIndex:i withObject:data];
        }
        
    }
    // error
    if (orderCustomerInfo.count > 0) {
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        data = [orderFinalArray objectAtIndex:0];
        [data setValue:[orderCustomerInfo objectForKey:@"Name"] forKey:@"CName"];
        [data setValue:[orderCustomerInfo objectForKey:@"Add1"] forKey:@"CAdd1"];
        [data setValue:[orderCustomerInfo objectForKey:@"Add2"] forKey:@"CAdd2"];
        [data setValue:[orderCustomerInfo objectForKey:@"Add3"] forKey:@"CAdd3"];
        [data setValue:[orderCustomerInfo objectForKey:@"TelNo"] forKey:@"CTelNo"];
        [data setValue:[orderCustomerInfo objectForKey:@"GstNo"] forKey:@"CGstNo"];
        
        [orderFinalArray replaceObjectAtIndex:0 withObject:data];
        data = nil;
    }
    
    terminalPayType = @"undirect";
    NSData *dataToBeSent = [NSKeyedArchiver archivedDataWithRootObject:orderFinalArray];
    
    NSArray *allPeers = [_appDelegate.mcManager.session connectedPeers];
    
    NSError *error;
    //NSLog(@"Peer count %@",allPeers);
    
    if (allPeers.count <= 0) {
        allPeers = nil;
        [self showAlertView:@"Unable to connect server." title:@"Warning"];
        return;
    }
    
    for (int i = 0; i < allPeers.count; i++) {
        specificPeer = [allPeers objectAtIndex:i];
        
        if ([specificPeer.displayName isEqualToString:@"Server"]) {
            NSArray *oneArray = @[[_appDelegate.mcManager.session.connectedPeers objectAtIndex:i]];
            [_appDelegate.mcManager.session sendData:dataToBeSent
                                             toPeers:oneArray
                                            withMode:MCSessionSendDataReliable
                                               error:&error];
            break;
        }
        
    }
    dataToBeSent = nil;
    allPeers = nil;
    if (error) {
        NSLog(@"Erro : %@", [error localizedDescription]);
        [self showAlertView:[error localizedDescription] title:@"Warning"];
        return;
    }
    else
    {
        [self clearExistingArrayMemory];
        [self.navigationController popViewControllerAnimated:NO];
    }

}

-(BOOL)kioskSendOrderToServerWithOrderStatus:(NSString *)status
{
    NSArray *allPeers = [_appDelegate.mcManager.session connectedPeers];
    int connectionFlag = 0;
    
    for (int i = 0; i < allPeers.count; i++) {
        specificPeer = [allPeers objectAtIndex:i];
        
        if ([specificPeer.displayName isEqualToString:@"Server"]) {
            connectionFlag = 1;
            break;
        }
        
    }
    
    if (connectionFlag == 0) {
        [self showAlertView:@"Server disconnect" title:@"Warning"];
        return false;
    }
    
    if ([status isEqualToString:@"Edit"]) {
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        for (int i = 0; i < orderFinalArray.count; i++) {
            
            data = [orderFinalArray objectAtIndex:i];
            
            [data setValue:status forKey:@"Status"];
            [data setValue:docNo forKey:@"SOH_DocNo"];
            
            [orderFinalArray replaceObjectAtIndex:i withObject:data];
        }
        data = nil;
        
    }
    
    if (orderCustomerInfo.count > 0) {
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        data = [orderFinalArray objectAtIndex:0];
        [data setValue:[orderCustomerInfo objectForKey:@"Name"] forKey:@"CName"];
        [data setValue:[orderCustomerInfo objectForKey:@"Add1"] forKey:@"CAdd1"];
        [data setValue:[orderCustomerInfo objectForKey:@"Add2"] forKey:@"CAdd2"];
        [data setValue:[orderCustomerInfo objectForKey:@"Add3"] forKey:@"CAdd3"];
        [data setValue:[orderCustomerInfo objectForKey:@"TelNo"] forKey:@"CTelNo"];
        [data setValue:[orderCustomerInfo objectForKey:@"GstNo"] forKey:@"CGstNo"];
        
        [orderFinalArray replaceObjectAtIndex:0 withObject:data];
        data = nil;
    }

    
    NSData *dataToBeSent = [NSKeyedArchiver archivedDataWithRootObject:orderFinalArray];
    
    NSError *error;
    //NSLog(@"Peer count %@",allPeers);
    
    /*
    if (allPeers.count <= 0) {
        [self showAlertView:@"Unable to connect server." title:@"Warning"];
        return false;
    }
    */
    for (int i = 0; i < allPeers.count; i++) {
        specificPeer = [allPeers objectAtIndex:i];
        
        if ([specificPeer.displayName isEqualToString:@"Server"]) {
            
            //connectionFlag = 1;
            
            NSArray *oneArray = @[[_appDelegate.mcManager.session.connectedPeers objectAtIndex:i]];
            [_appDelegate.mcManager.session sendData:dataToBeSent
                                             toPeers:oneArray
                                            withMode:MCSessionSendDataReliable
                                               error:&error];
        }
        
    }
    
    if (error) {
        NSLog(@"Erro : %@", [error localizedDescription]);
        [self showAlertView:[error localizedDescription] title:@"Warning"];
        return false;
    }
    else
    {
        //[self.navigationController popViewControllerAnimated:YES];
        return true;
    }
    
}

-(void)requestSODtlFromServer
{
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [requestServerData removeAllObjects];
    [data setObject:@"Request" forKey:@"Result"];
    [data setObject:@"-" forKey:@"Message"];
    [data setObject:@"RequestSODtl" forKey:@"IM_Flag"];
    [data setObject:soNo forKey:@"SOH_DocNo"];
    [data setObject:[NSString stringWithFormat:@"%ld",(long)selectedTableNo] forKey:@"TP_ID"];
    [data setObject:[NSString stringWithFormat:@"%d",compEnableGst] forKey:@"CompEnableGst"];
    [data setObject:_docType forKey:@"DocType"];
    
    [requestServerData addObject:data];
    NSData *dataToBeSend = [NSKeyedArchiver archivedDataWithRootObject:requestServerData];
    NSArray *allPeers = [[_appDelegate.mcManager session] connectedPeers];
    NSError *error;
    
    for (int i = 0; i < allPeers.count; i++) {
        specificPeer = [allPeers objectAtIndex:i];
        
        if ([specificPeer.displayName isEqualToString:@"Server"]) {
            NSArray *oneArray = @[[_appDelegate.mcManager.session.connectedPeers objectAtIndex:i]];
            [_appDelegate.mcManager.session sendData:dataToBeSend
                                            toPeers:oneArray
                                           withMode:MCSessionSendDataReliable
                                              error:&error];
        }
        
    }
    
    if (error) {
        NSLog(@"Erro : %@", [error localizedDescription]);
    }

}

-(void)requestXinYePrintSalesOrderFromServer
{
    
    NSData *dataToBeSend = [NSKeyedArchiver archivedDataWithRootObject:kitchenGroup];
    NSArray *allPeers = [[_appDelegate.mcManager session] connectedPeers];
    NSError *error;
    
    for (int i = 0; i < allPeers.count; i++) {
        specificPeer = [allPeers objectAtIndex:i];
        
        if ([specificPeer.displayName isEqualToString:@"Server"]) {
            NSArray *oneArray = @[[_appDelegate.mcManager.session.connectedPeers objectAtIndex:i]];
            [_appDelegate.mcManager.session sendData:dataToBeSend
                                             toPeers:oneArray
                                            withMode:MCSessionSendDataReliable
                                               error:&error];
        }
        
    }
    //data = nil;
    allPeers = nil;
    if (error) {
        NSLog(@"Erro : %@", [error localizedDescription]);
    }
}

-(void)requestAsterixPrintSalesOrderFromServer
{
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [requestServerData removeAllObjects];
    [data setObject:@"Request" forKey:@"Result"];
    [data setObject:@"-" forKey:@"Message"];
    [data setObject:@"RequestPrintAsterixSalesOrder" forKey:@"IM_Flag"];
    [data setObject:soNo forKey:@"SOH_DocNo"];
    [data setObject:[[printSOArray objectAtIndex:0] objectForKey:@"P_PortName"] forKey:@"P_PortName"];
    
    [requestServerData addObject:data];
    NSData *dataToBeSend = [NSKeyedArchiver archivedDataWithRootObject:requestServerData];
    NSArray *allPeers = [[_appDelegate.mcManager session] connectedPeers];
    NSError *error;
    
    for (int i = 0; i < allPeers.count; i++) {
        specificPeer = [allPeers objectAtIndex:i];
        
        if ([specificPeer.displayName isEqualToString:@"Server"]) {
            NSArray *oneArray = @[[_appDelegate.mcManager.session.connectedPeers objectAtIndex:i]];
            [_appDelegate.mcManager.session sendData:dataToBeSend
                                             toPeers:oneArray
                                            withMode:MCSessionSendDataReliable
                                               error:&error];
        }
        
    }
    data = nil;
    allPeers = nil;
    if (error) {
        NSLog(@"Erro : %@", [error localizedDescription]);
    }
}


-(void)requestStarRasterPrintSalesOrderFromServer
{
    //[PrinterFunctions PrintRasterSampleReceiptWithPortname:[[printSOArray objectAtIndex:0] objectForKey:@"P_PortName"] portSettings:printerPortSetting paperWidth:p_selectedWidthInch Language:p_selectedLanguage invDocno:docNo EnableGst:0];
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [requestServerData removeAllObjects];
    [data setObject:@"Request" forKey:@"Result"];
    [data setObject:@"-" forKey:@"Message"];
    [data setObject:@"RequestStarRasterPrintSalesOrder" forKey:@"IM_Flag"];
    [data setObject:docNo forKey:@"SOH_DocNo"];
    [data setObject:printerPortSetting forKey:@"PortSetting"];
    [data setObject:[[printSOArray objectAtIndex:0] objectForKey:@"PortName"] forKey:@"P_PortName"];
    [data setObject:@"0" forKey:@"EnableGst"];
    [data setObject:@"English" forKey:@"Language"];
    
    [requestServerData addObject:data];
    NSData *dataToBeSend = [NSKeyedArchiver archivedDataWithRootObject:requestServerData];
    NSArray *allPeers = [[_appDelegate.mcManager session] connectedPeers];
    NSError *error;
    
    for (int i = 0; i < allPeers.count; i++) {
        specificPeer = [allPeers objectAtIndex:i];
        
        if ([specificPeer.displayName isEqualToString:@"Server"]) {
            NSArray *oneArray = @[[_appDelegate.mcManager.session.connectedPeers objectAtIndex:i]];
            [_appDelegate.mcManager.session sendData:dataToBeSend
                                             toPeers:oneArray
                                            withMode:MCSessionSendDataReliable
                                               error:&error];
        }
        
    }
    
    if (error) {
        NSLog(@"Erro : %@", [error localizedDescription]);
    }
    
}

-(void)requestStarLinePrintSalesOrderFromServer
{
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [requestServerData removeAllObjects];
    [data setObject:@"Request" forKey:@"Result"];
    [data setObject:@"-" forKey:@"Message"];
    [data setObject:@"RequestStarLinePrintSalesOrder" forKey:@"IM_Flag"];
    [data setObject:docNo forKey:@"SOH_DocNo"];
    [data setObject:printerPortSetting forKey:@"PortSetting"];
    [data setObject:[[printSOArray objectAtIndex:0] objectForKey:@"PortName"] forKey:@"P_PortName"];
    [data setObject:@"0" forKey:@"EnableGst"];
    [data setObject:@"English" forKey:@"Language"];
    
    [requestServerData addObject:data];
    NSData *dataToBeSend = [NSKeyedArchiver archivedDataWithRootObject:requestServerData];
    NSArray *allPeers = [[_appDelegate.mcManager session] connectedPeers];
    NSError *error;
    
    for (int i = 0; i < allPeers.count; i++) {
        specificPeer = [allPeers objectAtIndex:i];
        
        if ([specificPeer.displayName isEqualToString:@"Server"]) {
            NSArray *oneArray = @[[_appDelegate.mcManager.session.connectedPeers objectAtIndex:i]];
            [_appDelegate.mcManager.session sendData:dataToBeSend
                                             toPeers:oneArray
                                            withMode:MCSessionSendDataReliable
                                               error:&error];
        }
        
    }
    
    if (error) {
        NSLog(@"Erro : %@", [error localizedDescription]);
    }
    
}


-(void)getSalesOrderDtlWithNotification:(NSNotification *)notification
{
    NSArray *soDTL;
    soDTL = [notification object];
    
    [orderFinalArray removeAllObjects];
    
    dispatch_async(dispatch_get_main_queue(), ^{
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        
        [printSOArray removeAllObjects];
        FMResultSet *rs = [db executeQuery:@"Select * from Printer where P_Type = ?",@"Receipt"];
        
        while ([rs next]) {
            printerMode = [rs stringForColumn:@"P_Mode"];
            printerBrand = [rs stringForColumn:@"P_Brand"];
            printerName = [rs stringForColumn:@"P_PrinterName"];
            [printSOArray addObject:[rs resultDictionary]];
        }
        
        [rs close];
        
        FMResultSet *rs2 = [db executeQuery:@"Select TP_Name from TablePlan where TP_ID = ?",[NSNumber numberWithInt:selectedTableNo]];
        
        if ([rs2 next]) {
            tableDesc = [rs2 stringForColumn:@"TP_Name"];
        }
        
        [rs2 close];
        NSMutableArray *recalcSalesItemArray = [[NSMutableArray alloc] init];
        NSMutableArray *recalcFinalSalesItemArray = [[NSMutableArray alloc] init];
        NSArray *recalcSalesItemIncArray;
        
        for (int i=0; i < soDTL.count; i++) {
            
            [orderCustomerInfo setValue:[[soDTL objectAtIndex:0] objectForKey:@"CName"] forKey:@"Name"];
            [orderCustomerInfo setValue:[[soDTL objectAtIndex:0] objectForKey:@"CAdd1"] forKey:@"Add1"];
            [orderCustomerInfo setValue:[[soDTL objectAtIndex:0] objectForKey:@"CAdd2"] forKey:@"Add2"];
            [orderCustomerInfo setValue:[[soDTL objectAtIndex:0] objectForKey:@"CAdd3"] forKey:@"Add3"];
            [orderCustomerInfo setValue:[[soDTL objectAtIndex:0] objectForKey:@"CTelNo"] forKey:@"TelNo"];
            [orderCustomerInfo setValue:[[soDTL objectAtIndex:0] objectForKey:@"CGstNo"] forKey:@"GstNo"];
            
            _paxData = [[soDTL objectAtIndex:0] objectForKey:@"SOH_PaxNo"];
            //self.labelOrderingPaxNo.text = _paxData;
            [self changeNaviBarTitle];
            self.btnSplitBill.enabled = YES;
            self.btnPrintSO.enabled = YES;
            self.btnVoidOrderBtn.enabled = YES;
            
            orderDataStatus = @"Edit";
            if ([[[soDTL objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"]) {
                docNo = [[soDTL objectAtIndex:0] objectForKey:@"SOH_DocNo"];
                
                //special for update server
                
                NSMutableDictionary *data = [NSMutableDictionary dictionary];
                [data setObject:orderDataStatus forKey:@"Status"];
                [data setObject:docNo forKey:@"SOH_DocNo"];
                
                [data setObject:[[soDTL objectAtIndex:i] objectForKey:@"IM_DiscountInPercent"] forKey:@"DiscInPercent"];
                [data setObject:[[soDTL objectAtIndex:i] objectForKey:@"IM_Qty"] forKey:@"ItemQty"];
                [data setObject:[[soDTL objectAtIndex:i] objectForKey:@"IM_Discount"] forKey:@"DiscValue"];
                [data setObject:[[soDTL objectAtIndex:i] objectForKey:@"IM_DiscountType"] forKey:@"DiscType"];
                [data setObject:[[soDTL objectAtIndex:i] objectForKey:@"IM_DiscountAmt"] forKey:@"TotalDisc"];
                [data setObject:[[soDTL objectAtIndex:i] objectForKey:@"IM_Remark"] forKey:@"Remark"];
                [data setObject:[[soDTL objectAtIndex:i] objectForKey:@"IM_OrgQty"] forKey:@"OrgQty"];
                
                
                recalcSalesItemArray = [PublicSqliteMethod calcGSTByItemNo:[[[soDTL objectAtIndex:i] objectForKey:@"IM_ItemNo"] integerValue] DBPath:dbPath ItemPrice:[[soDTL objectAtIndex:i] objectForKey:@"IM_Price"] CompEnableGst:compEnableGst CompEnableSVG:compEnableSVG TableSVC:tpServiceTax2 OverrideSVG:_overrideTableSVC SalesOrderStatus:@"Edit" TaxType:[[LibraryAPI sharedInstance] getTaxType] TableName:tableDesc ItemDineStatus:[NSString stringWithFormat:@"%@",[NSNumber numberWithInt:[[[soDTL objectAtIndex:i] objectForKey:@"IM_TakeAwayYN"]integerValue]]] TerminalType:terminalType SalesDict:data IMQty:@"0" KitchenStatus:@"Printed" PaxNo:_paxData DocType:_docType CondimentSubTotal:0 ServiceChargeGstPercent:[[LibraryAPI sharedInstance] getServiceTaxGstPercent] TableDineStatus:_tbStatus];
                
                NSDictionary *data2 = [NSDictionary dictionary];
                data2 = [recalcSalesItemArray objectAtIndex:0];
                [data2 setValue:[NSString stringWithFormat:@"%ld",orderFinalArray.count + 1] forKey:@"Index"];
                
                if ([[[soDTL objectAtIndex:i] objectForKey:@"SOD_ModifierID"] length] > 0) {
                    if ([[[soDTL objectAtIndex:i] objectForKey:@"IM_ServiceType"] isEqualToString:@"0"]) {
                        [data2 setValue:@"Yes" forKey:@"UnderPackageItemYN"];
                        [data2 setValue:@"00" forKey:@"PackageItemIndex"];
                        [data2 setValue:@"PackageItemOrder" forKey:@"OrderType"];
                        [data2 setValue:@"1" forKey:@"PD_MinChoice"];
                        if ([[[soDTL objectAtIndex:i] objectForKey:@"SOD_ModifierHdrCode"] isEqualToString:[[soDTL objectAtIndex:i] objectForKey:@"IM_ItemCode"]])
                        {
                            [data2 setValue:@"ItemMast" forKey:@"PD_ItemType"];
                        }
                        else{
                            [data2 setValue:@"Modifier" forKey:@"PD_ItemType"];
                        }
                        
                        [data2 setValue:[[soDTL objectAtIndex:i] objectForKey:@"SOD_ModifierHdrCode"] forKey:@"PD_ModifierHdrCode"];
                    }
                    
                }
                
                //[transferSalesArray replaceObjectAtIndex:0 withObject:data2];
                //data2 = nil;
                
                [recalcSalesItemArray replaceObjectAtIndex:0 withObject:data2];
                data2 = nil;
                
                recalcSalesItemIncArray = [PublicSqliteMethod recalculateGSTSalesOrderWithSalesOrderArray:recalcSalesItemArray TaxType:[[LibraryAPI sharedInstance] getTaxType]];
                
                //[recalcFinalSalesItemArray addObjectsFromArray:recalcSalesItemIncArray];
                data = nil;
                [orderFinalArray addObjectsFromArray:recalcSalesItemIncArray];
            }
            else
            {
                [orderFinalArray addObject:[soDTL objectAtIndex:i]];
            }
            
            
            
            
            recalcSalesItemArray = nil;
            recalcSalesItemIncArray = nil;
            recalcFinalSalesItemArray = nil;
            
        }
        
        
    }];
    
    [queue close];
    //[self showAlertView:@"Complete Transfer" title:@"testing"];
    [self.orderFinalTableView reloadData];
    //[dbTable close];
    [self groupCalcTotalForSalesOrder];
    });
    soDTL = nil;
    
    
}

-(void)confirmSalesOrderWithNotification:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSDictionary *dict = [notification userInfo];
        
        NSString *result = [dict objectForKey:@"Result"];
        
        if ([result isEqualToString:@"True"]) {
            //[self printOutKitchenReceipt];
            if ([terminalPayType isEqualToString:@"direct"]) {
                if ([[LibraryAPI sharedInstance] getKioskMode]==1) {
                    orderDataStatus = @"Edit";
                    docNo = [dict objectForKey:@"DocNo"];
                    [self goToPaymentView];
                }
                else
                {
                    orderDataStatus = @"Edit";
                    docNo = [dict objectForKey:@"DocNo"];
                    
                    [self goToPaymentView];
                }
            }
            
            
        }
        else
        {
            [self showAlertView:@"Fail to send to server" title:@"Warning"];
        }
        
    });
    
}

-(void)printSalesOrderDtlWithNotification:(NSNotification *)notification
{
    [PosApi initPrinter];
    [EposPrintFunction terminalCreateFlyTechSalesOrderRceiptWithDBPath:dbPath soArray:[notification object] EnableGst:compEnableGst];
}

-(void)printAsterixSalesOrderDtlWithNotification:(NSNotification *)notification
{
    NSMutableArray *compData = [[NSMutableArray alloc] init];
    
    NSMutableArray *receiptData = [[NSMutableArray alloc] init];
    receiptData = [notification object];
    [compData addObject:[receiptData objectAtIndex:0]];
    [receiptData removeObjectAtIndex:0];
    
    
    [PublicMethod printAsterixSalesOrderWithIpAdd:[[printSOArray objectAtIndex:0] objectForKey:@"P_PortName"] CompanyArray:compData SalesOrderArray:receiptData];
    
    compData = nil;
    receiptData = nil;
}

#pragma mark - flytech event
- (void)onBleConnectionStatusUpdate:(NSString *)addr status:(int)status
{
    if (status == BLE_DISCONNECTED) {
        
        [self showAlertView:@"Information" title:@"Bluetooth printer has disconnect. Please log out and login to reconnect."];
        
    }
}

#pragma mark - WIFIManagerDelegate
/**
 连接上主机
 */
- (void)XYWIFIManager:(XYWIFIManager *)manager didConnectedToHost:(NSString *)host port:(UInt16)port {
    if (!manager.isAutoDisconnect) {
        //        self.myTab.hidden = NO;
    }
    //[MBProgressHUD showSuccess:@"连接成功" toView:self.view];
    NSLog(@"Success connect printer");
}
/**
 读取到服务器的数据
 */
- (void)XYWIFIManager:(XYWIFIManager *)manager didReadData:(NSData *)data tag:(long)tag {
    
}
/**
 写数据成功
 */
- (void)XYWIFIManager:(XYWIFIManager *)manager didWriteDataWithTag:(long)tag {
    NSLog(@"写入数据成功");
}

/**
 断开连接
 */
- (void)XYWIFIManager:(XYWIFIManager *)manager willDisconnectWithError:(NSError *)error {}

- (void)XYWIFIManagerDidDisconnected:(XYWIFIManager *)manager {
    
    if (!manager.isAutoDisconnect) {
        //        self.myTab.hidden = YES;
    }
    
    //[self showAlertView:@"XP900 has been disconnect." title:@"Warning"];
    NSLog(@"XYWIFIManagerDidDisconnected");
    
}

#pragma mark - clear screen

-(void)clearSalesScreen
{
    self.labelTotalQty.text = @"0";
    self.labelSubTotal.text = @"0.00";
    self.labelTaxTotal.text = @"0.00";
    self.labelTotal.text = @"0.00";
    self.labelTotalDiscount.text = @"0.00";
    self.labelServiceTaxTotal.text = @"0.00";
    self.labelRound.text = @"0.00";
    self.labelExSubtotal.text = @"0.00";
    orderDataStatus = @"New";
    [orderFinalArray removeAllObjects];
    [self.orderFinalTableView reloadData];
    
}


#pragma mark - request server print kitchen receipt
-(void)insertKitchenReceiptToServerWithArray:(NSMutableArray *)krArray
{
    NSData *dataToBeSend = [NSKeyedArchiver archivedDataWithRootObject:krArray];
    NSArray *allPeers = [[_appDelegate.mcManager session] connectedPeers];
    NSError *error;
    
    for (int i = 0; i < allPeers.count; i++) {
        specificPeer = [allPeers objectAtIndex:i];
        
        if ([specificPeer.displayName isEqualToString:@"Server"]) {
            NSArray *oneArray = @[[_appDelegate.mcManager.session.connectedPeers objectAtIndex:i]];
            [_appDelegate.mcManager.session sendData:dataToBeSend
                                             toPeers:oneArray
                                            withMode:MCSessionSendDataReliable
                                               error:&error];
        }
        
    }
    //data = nil;
    allPeers = nil;
    if (error) {
        NSLog(@"Erro : %@", [error localizedDescription]);
    }
}

-(void)requestKitchenGroupReceiptPrintFromServerWithData:(NSMutableArray *)data
{
    NSData *dataToBeSend = [NSKeyedArchiver archivedDataWithRootObject:data];
    NSArray *allPeers = [[_appDelegate.mcManager session] connectedPeers];
    NSError *error;
    
    for (int i = 0; i < allPeers.count; i++) {
        specificPeer = [allPeers objectAtIndex:i];
        
        if ([specificPeer.displayName isEqualToString:@"Server"]) {
            NSArray *oneArray = @[[_appDelegate.mcManager.session.connectedPeers objectAtIndex:i]];
            [_appDelegate.mcManager.session sendData:dataToBeSend
                                             toPeers:oneArray
                                            withMode:MCSessionSendDataReliable
                                               error:&error];
        }
        
    }
    //data = nil;
    allPeers = nil;
    if (error) {
        NSLog(@"Erro : %@", [error localizedDescription]);
    }
}

-(void)clearExistingArrayMemory
{
    orderFinalArray = nil;
    catergoryArray = nil;
    itemMastArray = nil;
    _tableName = nil;
    keepAllItemArray = nil;
    orderCustomerInfo = nil;
}

-(void)openPackageItemSelectionViewWithItemCode:(NSString *)imCode ItemCondiment:(BOOL)itemWithCondiment ItemName:(NSString *)imName
{
    
    directExit = @"No";
    OrderPackageItemViewController *orderPackageItemViewController = [[OrderPackageItemViewController alloc]init];
    orderPackageItemViewController.delegate = self;
    orderPackageItemViewController.imCode = imCode;
    orderPackageItemViewController.imName = imName;
    orderPackageItemViewController.orderingViewParentIndex = @"-";
    UINavigationController *navbar = [[UINavigationController alloc]  initWithRootViewController:orderPackageItemViewController];
    
    navbar.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    navbar.modalPresentationStyle = UIModalPresentationFormSheet;
    [orderPackageItemViewController setModalPresentationStyle:UIModalPresentationFormSheet];
    [orderPackageItemViewController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    
    [self.navigationController presentViewController:navbar animated:YES completion:nil];
    
}

-(void)editPackageItemSelectionViewWithPackageItemIndex:(NSString *)packageItemIndex
{
    
    NSPredicate *predicate1;
    predicate1 = [NSPredicate predicateWithFormat:@"PackageItemIndex MATCHES[cd] %@",
                  packageItemIndex];
    
    NSPredicate *predicate3;
    predicate3 = [NSPredicate predicateWithFormat:@"Index MATCHES[cd] %@",
                  packageItemIndex];
    
    NSLog(@"%@",[[[orderFinalArray filteredArrayUsingPredicate:predicate3] objectAtIndex:0] objectForKey:@"IM_Description"]);
    
    OrderPackageItemViewController *orderPackageItemViewController = [[OrderPackageItemViewController alloc]init];
    orderPackageItemViewController.delegate = self;
    orderPackageItemViewController.imCode = [[[orderFinalArray filteredArrayUsingPredicate:predicate3] objectAtIndex:0] objectForKey:@"IM_ItemCode"];
    orderPackageItemViewController.imName = [[[orderFinalArray filteredArrayUsingPredicate:predicate3] objectAtIndex:0] objectForKey:@"IM_Description"];
    orderPackageItemViewController.orderingViewParentIndex = packageItemIndex;
    orderPackageItemViewController.completedOrderPackageArray = [orderFinalArray filteredArrayUsingPredicate:predicate1];
    predicate1 = nil;
    
    UINavigationController *navbar = [[UINavigationController alloc]  initWithRootViewController:orderPackageItemViewController];
    
    navbar.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    navbar.modalPresentationStyle = UIModalPresentationFormSheet;
    [orderPackageItemViewController setModalPresentationStyle:UIModalPresentationFormSheet];
    [orderPackageItemViewController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    
    [self.navigationController presentViewController:navbar animated:YES completion:nil];
    
}

#pragma mark - delegate from orderpackageitem
-(void)passBackPackageItemDetailToOrderScreenWithPackageDetail:(NSMutableArray *)array DisplayFormat:(NSString *)displayFormat TotalSurcharge:(double)totalSurcharge Status:(NSString *)status PackageItemCode:(NSString *)pItemCode PackageItemDesc:(NSString *)pItemDesc
{
    NSString *printStatus;
    
    if ([_docType isEqualToString:@"CashSales"]) {
        printStatus = @"Printed";
    }
    else
    {
        printStatus = @"Print";
    }
    
    [self groupCalcItemPrice:itemSelectedIndex ItemQty:@"1.0" KitchReceiptStatus:printStatus TotalCondimentPrice:totalSurcharge TotalCondimentUnitPrice:0 ReplacedIndex:@"-"];
    
    NSPredicate *predicate1;
    predicate1 = [NSPredicate predicateWithFormat:@"OrderType MATCHES[cd] %@",
                  @"PackageItemOrder"];
    
    NSPredicate *predicate2;
    predicate2 = [NSPredicate predicateWithFormat:@"OrderType MATCHES[cd] %@",
                  @"CondimentOrder"];
    
    NSArray *packageItemOrderArray = [array filteredArrayUsingPredicate:predicate1];
    NSArray *condimentItemOrderArray = [array filteredArrayUsingPredicate:predicate2];
    
    NSUInteger parentIndex = 0;
    NSUInteger groupHdrIndex = 0;
    
    groupHdrIndex = orderFinalArray.count;
    
    for (int i = 0; i < packageItemOrderArray.count; i++) {
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        data = [packageItemOrderArray objectAtIndex:i];
        [data setValue:status forKey:@"Status"];
        [data setObject:_docType forKey:@"PayDocType"];
        [data setObject:_tbStatus forKey:@"IM_TakeAwayYN"];
        [data setValue:[NSString stringWithFormat:@"%lu",groupHdrIndex] forKey:@"PackageItemIndex"];
        [data setValue:[NSString stringWithFormat:@"%lu",orderFinalArray.count + 1] forKey:@"Index"];
        parentIndex = orderFinalArray.count + 1;
        [orderFinalArray addObject:data];
        data = nil;
        
        for (int j = 0; j < condimentItemOrderArray.count; j++)
        {
            if ([[[condimentItemOrderArray objectAtIndex:j] objectForKey:@"ParentIndex2"] isEqualToString:[[packageItemOrderArray objectAtIndex:i] objectForKey:@"PackageIndex"]])
            {
                //NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                dict = [condimentItemOrderArray objectAtIndex:j];
                [dict setObject:[NSString stringWithFormat:@"%lu",parentIndex] forKey:@"ParentIndex"];
                [dict setObject:[NSString stringWithFormat:@"%lu",groupHdrIndex] forKey:@"PackageItemIndex"];
                [orderFinalArray addObject:dict];
                dict = nil;
            }
            
        }
        
    }
    
    predicate1 = nil;
    predicate2 = nil;
    packageItemOrderArray = nil;
    condimentItemOrderArray = nil;
    
    [self reIndexOrderFinalArray];
    [self.orderFinalTableView reloadData];
    
    /*
    if (array.count > 0) {
        
        for (int i = 0; i < array.count; i++) {
            NSMutableDictionary *data = [NSMutableDictionary dictionary];
            data = [array objectAtIndex:i];
            if ([[[array objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"PackageItemOrder"]) {
                
                [data setValue:status forKey:@"Status"];
                [data setObject:_docType forKey:@"PayDocType"];
                [data setObject:_tbStatus forKey:@"IM_TakeAwayYN"];
                [data setValue:[NSString stringWithFormat:@"%lu",orderFinalArray.count + 1] forKey:@"Index"];
            }
            else{
                [data setValue:[NSString stringWithFormat:@"%lu",orderFinalArray.count] forKey:@"ParentIndex"];
            }
            
            //[array replaceObjectAtIndex:i withObject:data];
            [orderFinalArray addObject:data];
            data = nil;
            
        }
        
        [orderFinalArray addObjectsFromArray:array];
        NSLog(@"Checking : %@",orderFinalArray);
        [self.orderFinalTableView reloadData];
    }
     */
}

-(void)passBackEditedPackageItemDetailToOrderScreenWithPackageDetail:(NSMutableArray *)array DisplayFormat:(NSString *)displayFormat TotalSurcharge:(double)totalSurcharge Status:(NSString *)status PackageItemCode:(NSString *)pItemCode PackageItemDesc:(NSString *)pItemDesc OrderingViewParentIndex:(NSString *)parentIndex
{
    updateCondimentDtlQtyFrom = @"OrderAddPackageItemView";
    
    NSMutableArray *discardedItems = [NSMutableArray array];
    
    for (int i = 0; i < orderFinalArray.count; i++) {
        if ([[[orderFinalArray objectAtIndex:i] objectForKey:@"PackageItemIndex"] isEqualToString:parentIndex])
        {
            [discardedItems addObject:[orderFinalArray objectAtIndex:i]];
        }
    }
    [orderFinalArray removeObjectsInArray:discardedItems];
    
    NSUInteger insertIndex = 0;
    for (int i = 0; i < orderFinalArray.count; i++) {
        if ([[[orderFinalArray objectAtIndex:i] objectForKey:@"Index"] isEqualToString:parentIndex]) {
            if (orderFinalArray.count == i+1) {
                insertIndex = i + 1;
                
            }
            else
            {
                insertIndex = i;
                
                
            }
            
        }
    }
    
    NSUInteger tablePosition = 0;
    tablePosition = insertIndex;
    
    if (insertIndex == orderFinalArray.count) {
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        data = [orderFinalArray objectAtIndex:insertIndex-1];
        [data setValue:[NSString stringWithFormat:@"%0.2f",totalSurcharge] forKey:@"IM_NewTotalCondimentSurCharge"];
        [orderFinalArray replaceObjectAtIndex:insertIndex-1 withObject:data];
        
        [orderFinalArray addObjectsFromArray:array];
        data = nil;
        
        [self passSalesDataBack:orderFinalArray dataStatus:@"Edit" tablePosition:tablePosition-1 ArrayIndex:tablePosition-1];
    }
    else
    {
        
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        data = [orderFinalArray objectAtIndex:insertIndex];
        
        [data setValue:[NSString stringWithFormat:@"%0.2f",totalSurcharge] forKey:@"IM_NewTotalCondimentSurCharge"];
        
        [orderFinalArray replaceObjectAtIndex:insertIndex withObject:data];
        data = nil;
        
        for (int j = 0; j < array.count; j++) {
            [orderFinalArray insertObject:[array objectAtIndex:j] atIndex:insertIndex + 1];
            insertIndex++;
        }
        
        [self passSalesDataBack:orderFinalArray dataStatus:@"Edit" tablePosition:tablePosition ArrayIndex:tablePosition];
        
    }
    
    [self reIndexOrderFinalArray];
    
    [self.orderFinalTableView reloadData];
    //[self sortingOrderPackageItemWithPackageDetail:array TotalPackageSurcharge:totalSurcharge ParentIndex:parentIndex];
    
}

-(void)sortingOrderPackageItemWithPackageDetail:(NSMutableArray *)array TotalPackageSurcharge:(double)totalPackageSurcharge ParentIndex:(NSString *)parentIndex
{
    
}

/*
-(void)createLogArrayWithLogAction:(NSString *)logAction LogView:(NSString *)logView LogRemark:(NSString *)logRemark
{
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    
    [data setObject:@"DateTime" forKey:@"LogDateTime"];
    [data setObject:logAction forKey:@"LogAction"];
    [data setObject:logView forKey:@"LogView"];
    [data setObject:logRemark forKey:@"LogRemark"];
    //[data setObject:[NSString stringWithFormat:@"%@ %@%@ %@",@"New SalesOrder", @"Add Item", [[calculatedSalesArray objectAtIndex:0] objectForKey:@""], @"Qty : 1"] forKey:@"LogRemark"];
    
    //[logArray addObject:data];
    data = nil;
}
 */
@end
