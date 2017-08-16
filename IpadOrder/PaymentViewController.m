//
//  PaymentViewController.m
//  IpadOrder
//
//  Created by IRS on 8/20/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "PaymentViewController.h"
#import "LibraryAPI.h"
#import <FMDB.h>
#import "PaymentAmtViewController.h"
#import "PaymentMethodTableViewCell.h"
#import "NumPadTextField/NumericKeypadTextField.h"
#import "NumericKeypadViewController.h"
#import "PrinterFunctions.h"
#import <StarIO/SMPort.h>
#import <StarIO/SMBluetoothManager.h>
#import <MBProgressHUD.h>
#import "ePOS-Print.h"
#import "Result.h"
#import "MsgMaker.h"
#import "EposPrintFunction.h"
#import "AppDelegate.h"
#import "PaymentMethodCollectionViewCell.h"
#import "PaymentModeTableViewCell.h"
#import <KVNProgress.h>
#import "TerminalData.h"
#import "PublicMethod.h"

#define DISCOVERY_INTERVAL  0.5
static NSString * const itemCellIdentifier = @"PaymentMethodCollectionViewCell";
@interface PaymentViewController ()
{
    FMDatabase *dbTable;
    NSString *dbPath;
    NSMutableArray *paymentArray;
    NSString *SONo;
    NSString *InvNo;
    NSMutableArray *finalSplitBillArray;
    int selectedTbNo;
    NSString *paymentType;
    NSString *multiPayAmt;
    NSMutableArray *payOrderDetailArray;
    
    // printer varable
    NSString *printerPortSetting;
    NSMutableArray *printerArray;
    SMLanguage p_selectedLanguage;
    SMPaperWidth p_selectedWidthInch;
    NSOperationQueue *operationQue;
    NSMutableArray *invArray;
    
    NSString *printerMode;
    NSString *printerBrand;
    NSString *printerName;
    
    //epos printer
    NSArray *printList;
    NSTimer *timer_;
    NSString *eposDeviceIP;
    NSString *eposDeviceModel;
    
    NSString *eposSection1;
    NSString *eposSection2;
    NSString *eposSection3;
    NSString *eposSection4;
    NSString *eposSection5;
    
    // service tax
    NSString *serviceTaxGstAmt;
    
    //payment type
    NSMutableArray *paymentTypeArray;
    NSString *paymentGroup;
    
    NSMutableArray *kitchenGroup;
    int enableGst;
    
    //main terminal used
    
    MCPeerID *specificPeer;
    NSMutableArray *requestServerData;
    NSString *flag;
    NSString *number;
    BOOL multiplePayment;
    NSString *creditCardKeyPadCtrl;
    //NSString *userName;
    int paymentArraySelectedIndex;
    
    NSMutableArray *bleDevicePrinter;
    long paymentIndexSelected;
    int makeXinYeDiscon;
    NSMutableArray *receiptDataArray;
    MBProgressHUD *loading;
    NSString *receiptPrinterIP;
    
}
@property (nonatomic, strong) AppDelegate *appDelegate;
@property (nonatomic, strong)UIPopoverController *popOverChange;

-(void)getPaymentSOResultWithNotification:(NSNotification *)notification;
-(void)getInsertInvoiceResultWithNotification:(NSNotification *)notification;
-(void)printAsterixPayBillDtlWithNotification:(NSNotification *)notification;

@end

@implementation PaymentViewController

- (XYWIFIManager *)wifiManager
{
    if (!_wifiManager)
    {
        _wifiManager = [XYWIFIManager shareWifiManager];
        _wifiManager.delegate = self;
    }
    return _wifiManager;
}

- (IBAction)btnTestPrinter:(id)sender {
    //[self printReceiptOnXinYePrinter];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    multiplePayment = false;
    flag = @"New";
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    requestServerData = [[NSMutableArray alloc]init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(getPaymentSOResultWithNotification:)
                                                 name:@"GetPaymentSOWithNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(getInsertInvoiceResultWithNotification:)
                                                 name:@"GetInsertInvoiceResultWithNotification"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(printAsterixPayBillDtlWithNotification:)
                                                 name:@"PrintAsterixPayBillDtlWithNotification"
                                               object:nil];
    
    self.preferredContentSize = CGSizeMake(1000, 700);
    self.navigationController.navigationBar.hidden = YES;
    paymentArray = [[NSMutableArray alloc]init];
    finalSplitBillArray = [[NSMutableArray alloc]init];
    printerArray = [[NSMutableArray alloc]init];
    payOrderDetailArray = [[NSMutableArray alloc]init];
    paymentTypeArray = [[NSMutableArray alloc]init];
    bleDevicePrinter = [[NSMutableArray alloc] init];
    receiptDataArray  = [[NSMutableArray alloc] init];
    receiptPrinterIP = @"";
    
    dbPath = [[LibraryAPI sharedInstance]getDbPath];
    SONo = [[LibraryAPI sharedInstance]getDocNo];
    enableGst = [[LibraryAPI sharedInstance]getEnableGst];
    //userName = [[LibraryAPI sharedInstance] getUserName];
    //printerMode = [[LibraryAPI sharedInstance]getPrinterMode];
    // Do any additional setup after loading the view from its nib.
    self.textTotalAmtNeedToPay.delegate = self;
    self.textPayAmt.numericKeypadDelegate = self;
    self.textPayAmt.delegate = self;
    [self.textPayAmt addTarget:self action:@selector(editTextField:) forControlEvents:UIControlEventEditingChanged];
    [self.btnMakePayment addTarget:self action:@selector(btnMakePayment:) forControlEvents:UIControlEventTouchUpInside];
    self.textPayAmt.enabled = false;
    self.labelChangeAmt.enabled = false;
    self.labelLeftChange.delegate = self;
    bigBtn = @"Confirm";
    paymentType = @"Cash";
    
    /*
    UIGraphicsBeginImageContext(self.view.frame.size);
    [[UIImage imageNamed:@"promtBlue.jpg"] drawInRect:self.view.bounds];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:image];
    */
    self.view.backgroundColor = [UIColor whiteColor];
    UINib *itemCollectionNib = [UINib nibWithNibName:itemCellIdentifier bundle:nil];
    
    [_collectionViewPayMethod registerNib:itemCollectionNib forCellWithReuseIdentifier:itemCellIdentifier];
    
    UINib *paymentModeNib = [UINib nibWithNibName:@"PaymentModeTableViewCell" bundle:nil];
    [_paymentModeTableView registerNib:paymentModeNib forCellReuseIdentifier:@"PaymentModeTableViewCell"];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setItemSize:CGSizeMake(130, 117)];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    flowLayout.minimumInteritemSpacing = 5.0;
    [self.collectionViewPayMethod setCollectionViewLayout:flowLayout];
    
    _collectionViewPayMethod.delegate = self;
    _collectionViewPayMethod.dataSource = self;
    
    
    //[self.btnPayCash addTarget:self action:@selector(payCash:) forControlEvents:UIControlEventTouchUpInside];
    //[self.btnPayCash setBackgroundImage:[UIImage imageNamed:@"normal"] forState: UIControlStateNormal];
    
    [self.btnPayCard addTarget:self action:@selector(payCard:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.btnTen addTarget:self action:@selector(btnTen:) forControlEvents:UIControlEventTouchUpInside];
    [self.btnTwenty addTarget:self action:@selector(btnTwenty:) forControlEvents:UIControlEventTouchUpInside];
    [self.btnFity addTarget:self action:@selector(btnFity:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.btnExact addTarget:self action:@selector(btnExactAmt:) forControlEvents:UIControlEventTouchUpInside];
    
    self.paymentModeTableView.delegate = self;
    self.paymentModeTableView.dataSource = self;
    
    self.textTotalAmtNeedToPay.layer.borderWidth = 1.0;
    self.textTotalAmtNeedToPay.layer.borderColor = [[UIColor colorWithRed:128/255.0 green:128/255.0 blue:128/255.0 alpha:1.0] CGColor];
    self.textTotalAmtNeedToPay.layer.cornerRadius = 10.0;
    
    self.textRef.layer.borderWidth = 1.0;
    self.textRef.layer.borderColor = [[UIColor colorWithRed:128/255.0 green:128/255.0 blue:128/255.0 alpha:1.0] CGColor];
    self.textRef.layer.cornerRadius = 10.0;
    
    self.labelLeftChange.layer.borderWidth = 1.0;
    self.labelLeftChange.layer.borderColor = [[UIColor colorWithRed:128/255.0 green:128/255.0 blue:128/255.0 alpha:1.0] CGColor];
    self.labelLeftChange.layer.cornerRadius = 10.0;
    
    self.paymentModeTableView.layer.borderWidth = 1.0;
    self.paymentModeTableView.layer.borderColor = [[UIColor colorWithRed:128/255.0 green:128/255.0 blue:128/255.0 alpha:1.0] CGColor];
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data setObject:paymentType forKey:@"PayType"];
    [data setObject:[NSString stringWithFormat:@"%0.2f",[self.textPayAmt.text doubleValue]] forKey:@"PayAmt"];
    [data setObject:self.textRef.text forKey:@"PayRef"];
    [paymentArray addObject:data];
    data = nil;
    
    self.paymentModeTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self recalMultiPayChangeAmt2];
    
    kitchenGroup = [[NSMutableArray alloc]init];
    
    if ([_terminalType isEqualToString:@"Main"]) {
        if ([SONo isEqualToString:@"-"])
        {
            //selectedTbNo = [[LibraryAPI sharedInstance]getTableNo];
            [self getSplitBillData];
        }
        else
        {
            //selectedTbNo = [[LibraryAPI sharedInstance]getTableNo];
            [self getPrinterNPaymentTypeSetting];
            [self getSalesOrderAmount];
        }
    }
    else
    {
        [self getPrinterNPaymentTypeSetting];
        [payOrderDetailArray addObjectsFromArray:[[LibraryAPI sharedInstance]getPayOrderDetailArray]];
        if ([_payDocType isEqualToString:@"CashSales"]) {
            finalSplitBillArray = [[LibraryAPI sharedInstance] getEditCashSalesDetailArray];
            
            
            self.labelRounding.text = [NSString stringWithFormat:@"%0.2f",[[[finalSplitBillArray objectAtIndex:0] objectForKey:@"SOH_Rounding"] doubleValue]];
            self.labelSubtotal.text = [NSString stringWithFormat:@"%0.2f",[[[finalSplitBillArray objectAtIndex:0] objectForKey:@"SOH_DocSubTotal"] doubleValue]];
            
            self.labelTotalDiscount.text = [NSString stringWithFormat:@"%0.2f",[[[finalSplitBillArray objectAtIndex:0] objectForKey:@"SOH_DiscAmt"] doubleValue]];
            self.labelTotalTax.text = [NSString stringWithFormat:@"%0.2f",[[[finalSplitBillArray objectAtIndex:0] objectForKey:@"SOH_DocTaxAmt"] doubleValue]];
            self.labelTotalAmt.text = [NSString stringWithFormat:@"%0.2f",[[[finalSplitBillArray objectAtIndex:0] objectForKey:@"SOH_DocAmt"] doubleValue]];
            serviceTaxGstAmt = [NSString stringWithFormat:@"%0.2f",[[[finalSplitBillArray objectAtIndex:0] objectForKey:@"SOH_DocServiceTaxGstAmt"] doubleValue]];
            self.labelServiceCharge.text = [NSString stringWithFormat:@"%0.2f",[[[finalSplitBillArray objectAtIndex:0] objectForKey:@"SOH_DocServiceTaxAmt"] doubleValue]];
            //self.labelTotalAmtBlue.text = self.labelTotalAmt.text;
            self.textTotalAmtNeedToPay.text = self.labelTotalAmt.text;
            
            [self addInPaymentTypeDefaultValueOnCashSales];
        }
        else
        {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                loading = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
                loading.mode = MBProgressHUDModeText;
                loading.margin = 50.0f;
                loading.yOffset = 40.0f;
                
                loading.labelText = @"Loading...";
                loading.labelFont = [UIFont fontWithName:@"System" size:15];
                loading.removeFromSuperViewOnHide = YES;
                
            });
            
            [self requestPaymentSODetail];
        }
        
    }
    
}

-(void)addInPaymentTypeDefaultValueOnCashSales
{
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    
    data = [finalSplitBillArray objectAtIndex:0];
    
    [data setValue:@"-" forKey:@"IvH_PaymentType1"];
    [data setValue:@"0.00" forKey:@"IvH_PaymentAmt1"];
    [data setValue:@"-" forKey:@"IvH_PaymentRef1"];
    
    [data setValue:@"-" forKey:@"IvH_PaymentType2"];
    [data setValue:@"0.00" forKey:@"IvH_PaymentAmt2"];
    [data setValue:@"-" forKey:@"IvH_PaymentRef2"];
    
    [data setValue:@"-" forKey:@"IvH_PaymentType3"];
    [data setValue:@"0.00" forKey:@"IvH_PaymentAmt3"];
    [data setValue:@"-" forKey:@"IvH_PaymentRef3"];
    
    [data setValue:@"-" forKey:@"IvH_PaymentType4"];
    [data setValue:@"0.00" forKey:@"IvH_PaymentAmt4"];
    [data setValue:@"-" forKey:@"IvH_PaymentRef4"];
    
    [data setValue:@"-" forKey:@"IvH_PaymentType5"];
    [data setValue:@"0.00" forKey:@"IvH_PaymentAmt5"];
    [data setValue:@"-" forKey:@"IvH_PaymentRef5"];
    
    [data setValue:@"-" forKey:@"IvH_PaymentType6"];
    [data setValue:@"0.00" forKey:@"IvH_PaymentAmt6"];
    [data setValue:@"-" forKey:@"IvH_PaymentRef6"];
    
    [data setValue:@"-" forKey:@"IvH_PaymentType7"];
    [data setValue:@"0.00" forKey:@"IvH_PaymentAmt7"];
    [data setValue:@"-" forKey:@"IvH_PaymentRef7"];
    
    [data setValue:@"-" forKey:@"IvH_PaymentType8"];
    [data setValue:@"0.00" forKey:@"IvH_PaymentAmt8"];
    [data setValue:@"-" forKey:@"IvH_PaymentRef8"];
    
    [finalSplitBillArray replaceObjectAtIndex:0 withObject:data];
    
    data = nil;
}

-(void)viewWillAppear:(BOOL)animated
{
    
    if (![[[LibraryAPI sharedInstance] getPrinterUUID] isEqualToString:@"Non"] && [[[LibraryAPI sharedInstance] getWorkMode] isEqualToString:@"Main"])
    {
        [PosApi setDelegate: self];
        
    }
    else if ([[[LibraryAPI sharedInstance] getPrinterBrand] isEqualToString:@"XinYe"])
    {
        [self wifiManager];
    }
    
    [self manualDidSelectCollectionViewWithIndexNo:0];
    NSIndexPath *indexPathForFirstRow = [NSIndexPath indexPathForItem:0 inSection:0];
    [self.paymentModeTableView selectRowAtIndexPath:indexPathForFirstRow animated:NO  scrollPosition:UITableViewScrollPositionNone];
}

-(void)viewWillLayoutSubviews
{
    //[super viewWillLayoutSubviews];
    
    //self.view.superview.bounds = CGRectMake(0, 0, 850, 700);
    
    //[self getItemMast];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

-(void)getPrinterNPaymentTypeSetting
{
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        
        [paymentTypeArray removeAllObjects];
        FMResultSet *rsPaymentType = [db executeQuery:@"Select * from PaymentType where PT_Checked = 1"];
        
        while ([rsPaymentType next])
        {
            [paymentTypeArray addObject:[rsPaymentType resultDictionary]];
        }
        [rsPaymentType close];
        
        [printerArray removeAllObjects];
        FMResultSet *rs = [db executeQuery:@"Select * from Printer where P_Type = ?",@"Receipt"];
        
        while ([rs next]) {
            printerMode = [rs stringForColumn:@"P_Mode"];
            printerBrand = [rs stringForColumn:@"P_Brand"];
            receiptPrinterIP = [rs stringForColumn:@"P_PortName"];
            printerName = [rs stringForColumn:@"P_PrinterName"];
            [printerArray addObject:[rs resultDictionary]];
        }
        
        [rs close];
        
    }];
    
    [queue close];
}

#pragma mark - scroll view part

-(void)makeUiCollectionView
{
    
    [_collectionViewPayMethod reloadData];

}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return paymentTypeArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    //static NSString *identifier = @"PaymentMethodCollectionViewCell";
    NSString *imgName;
    PaymentMethodCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:itemCellIdentifier forIndexPath:indexPath];
    imgName = [NSString stringWithFormat:@"%@Black",[[paymentTypeArray objectAtIndex:indexPath.row] objectForKey:@"PT_ImgName"]];
    
    if (paymentIndexSelected == indexPath.row) {
        [[cell imgPayMethod] setImage:[UIImage imageNamed:[[paymentTypeArray objectAtIndex:indexPath.row] objectForKey:@"PT_ImgName"] ]];
        cell.labelPaymentMethod.textColor = [UIColor blackColor];
    }
    else
    {
        [[cell imgPayMethod] setImage:[UIImage imageNamed:imgName ]];
        cell.labelPaymentMethod.textColor = [UIColor whiteColor];
    }
    //cell.layer.borderWidth = 2.0;
    //cell.layer.borderColor = [[UIColor blackColor] CGColor];
    /*
    if (indexPath.row == 0) {
        if ([flag isEqualToString:@"New"]) {
            cell.layer.borderWidth = 3.0;
            cell.layer.borderColor = [[UIColor blackColor] CGColor];
            [[cell imgPayMethod] setImage:[UIImage imageNamed:[[paymentTypeArray objectAtIndex:indexPath.row] objectForKey:@"PT_Code"] ]];
            flag = @"Old";
        }
        else
        {
            cell.layer.borderWidth = 3.0;
            cell.layer.borderColor = [[UIColor blackColor] CGColor];
            [[cell imgPayMethod] setImage:[UIImage imageNamed:imgName ]];
        }
        
    }
    else
    {
        //[[cell imgPayMethod] setImage:[UIImage imageNamed:imgName ]];
    }
    */
    //[[cell imgPayMethod] setImage:[UIImage imageNamed:[[paymentTypeArray objectAtIndex:indexPath.row] objectForKey:@"PT_Code"] ]];
    
    [[cell labelPaymentMethod] setText:[[paymentTypeArray objectAtIndex:indexPath.row] objectForKey:@"PT_Code"]];
    //cell.contentView.backgroundColor = [UIColor whiteColor];
    
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
    int payZeroIndex = 0;
    NSString *payZeroFlag;
    UICollectionViewCell* cell = [collectionView cellForItemAtIndexPath:indexPath];
    //cell.contentView.backgroundColor = [UIColor orangeColor];
    paymentIndexSelected = indexPath.row;
    //cell.layer.borderWidth = 3.0;
    //cell.layer.borderColor = [[UIColor blackColor] CGColor];
    cell.backgroundColor = [UIColor whiteColor];
    creditCardKeyPadCtrl = @"Clear";
    
    if (([[[paymentArray objectAtIndex:paymentArray.count -1] objectForKey:@"PayAmt"] doubleValue] == 0.00 || [[[paymentArray objectAtIndex:paymentArray.count -1] objectForKey:@"PayAmt"] doubleValue] >= [self.textTotalAmtNeedToPay.text doubleValue]) && paymentArray.count == 1 ) {
        [self calculatePayByPayGroup:[[paymentTypeArray objectAtIndex:indexPath.row] objectForKey:@"PT_Type"] PT_Code:[[paymentTypeArray objectAtIndex:indexPath.row]objectForKey:@"PT_Code"]];
        [self changePaymentType];
    }
    else
    {
        
        multiplePayment = true;
        
        [self calculatePayByPayGroup:[[paymentTypeArray objectAtIndex:indexPath.row] objectForKey:@"PT_Type"] PT_Code:[[paymentTypeArray objectAtIndex:indexPath.row]objectForKey:@"PT_Code"]];
        double totalMultiAmt = 0.00;
        for (int j = 0; j < paymentArray.count; j++) {
            if ([[[paymentArray objectAtIndex:j] objectForKey:@"PayType"] isEqualToString:paymentType]) {
                //[self showAlertView:@"Payment Type Duplicate" title:@"Warning"];
                self.textPayAmt.text = @"";
                return;
            }
            
            if ([[[paymentArray objectAtIndex:j] objectForKey:@"PayAmt"] doubleValue] == 0.0) {
                payZeroIndex = j;
                payZeroFlag = @"Zero";
            }
            totalMultiAmt = [[[paymentArray objectAtIndex:j] objectForKey:@"PayAmt"] doubleValue] + totalMultiAmt;
        }
        
        if (totalMultiAmt >= [self.textTotalAmtNeedToPay.text doubleValue]) {
            [self showAlertView:@"Already match total amount" title:@"Warning"];
            return;
        }
        
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        if ([payZeroFlag isEqualToString:@"Zero"]) {
            [data setObject:paymentType forKey:@"PayType"];
            [data setObject:[NSString stringWithFormat:@"%0.2f",[self.textPayAmt.text doubleValue]] forKey:@"PayAmt"];
            [data setObject:self.textRef.text forKey:@"PayRef"];
            [paymentArray replaceObjectAtIndex:payZeroIndex withObject:data];
        }
        else
        {
            [data setObject:paymentType forKey:@"PayType"];
            [data setObject:[NSString stringWithFormat:@"%0.2f",[self.textPayAmt.text doubleValue]] forKey:@"PayAmt"];
            [data setObject:self.textRef.text forKey:@"PayRef"];
            [paymentArray addObject:data];
        }
        
        data = nil;
        [self.paymentModeTableView reloadData];
        [self recalMultiPayChangeAmt2];
        NSIndexPath *indexPathRow = [NSIndexPath indexPathForItem:paymentArray.count - 1 inSection:0];
        
        [self.paymentModeTableView selectRowAtIndexPath:indexPathRow animated:NO  scrollPosition:UITableViewScrollPositionNone];
        paymentArraySelectedIndex = paymentArray.count - 1;
        self.btnExact.enabled = false;
        
    }
    [self.collectionViewPayMethod reloadData];
}

-(void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    //UICollectionViewCell* cell = [collectionView cellForItemAtIndexPath:indexPath];
    //cell.contentView.backgroundColor = [UIColor whiteColor];
    //cell.layer.borderWidth = 3.0;
    //cell.layer.borderColor = [[UIColor blackColor] CGColor];
    //cell.backgroundColor = [UIColor grayColor];
    
}

- (UIEdgeInsets)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 17); // top, left, bottom, right
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    
    return 5.0;
}

#pragma mark - change payment mode

-(void)calculatePayByPayGroup:(NSString *)group PT_Code:(NSString *)ptCode
{
    if ([group isEqualToString:@"Cash"]) {
        paymentGroup = @"Cash";
        if ([ptCode isEqualToString:@"Cash"]) {
            [self payCash:ptCode];
        }
        else
        {
            paymentGroup = @"Card";
            [self payCard:ptCode];
        }
        
    }
    else if ([group isEqualToString:@"Card"])
    {
        //[self payCard:@"Card"];
        paymentGroup = @"Card";
        [self payCard:ptCode];
    }
}

-(void)changePaymentType
{
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    if (paymentArray.count == 1) {
        data = [paymentArray objectAtIndex:paymentArray.count -1];
        if ([[[paymentArray objectAtIndex:paymentArray.count -1] objectForKey:@"PayAmt"] isEqualToString:@"0.00"]) {
            
            [data setValue:paymentType forKey:@"PayType"];
            if ([paymentGroup isEqualToString:@"Card"]) {
                [data setObject:self.textTotalAmtNeedToPay.text forKey:@"PayAmt"];
            }
            else
            {
                [data setObject:@"0.00" forKey:@"PayAmt"];
            }
            [paymentArray replaceObjectAtIndex:paymentArray.count -1 withObject:data];
        }
        else if ([[[paymentArray objectAtIndex:paymentArray.count -1] objectForKey:@"PayAmt"] doubleValue] > 0.00 && [paymentGroup isEqualToString:@"Cash"])
        {
            [data setValue:paymentType forKey:@"PayType"];
            [data setObject:@"0.00" forKey:@"PayAmt"];
            [paymentArray replaceObjectAtIndex:paymentArray.count -1 withObject:data];
        }
        else if ([[[paymentArray objectAtIndex:paymentArray.count -1] objectForKey:@"PayAmt"] doubleValue] > 0.00 && [paymentGroup isEqualToString:@"Card"])
        {
            [data setValue:paymentType forKey:@"PayType"];
            [data setObject:self.textTotalAmtNeedToPay.text forKey:@"PayAmt"];
            [paymentArray replaceObjectAtIndex:paymentArray.count -1 withObject:data];
        }
        /*
        else
        {
            if ([[[paymentArray objectAtIndex:paymentArray.count -1] objectForKey:@"PayAmt"] doubleValue] >= [self.textTotalAmtNeedToPay.text doubleValue]) {
                
            }
            else
            {
                [data setObject:paymentType forKey:@"PayType"];
                [data setObject:@"0.00" forKey:@"PayAmt"];
                [data setObject:self.textRef.text forKey:@"PayRef"];
                [paymentArray addObject:data];
            }
            
        }
         */
    }
    
    data = nil;
    [self.paymentModeTableView reloadData];
}


#pragma mark - NumberPadDelegate
-(void)saveActionFormTextField:(UITextField *)textField
{
    [textField resignFirstResponder];
}

#pragma mark - get spltbill data

-(void)getSplitBillData
{
    
    [finalSplitBillArray addObjectsFromArray:[[LibraryAPI sharedInstance]getDirectOrderDetailArray]];
    self.labelTotalTax.text = _splitBillTotalTaxAmt;
    self.labelTotalAmt.text = _splitBillTotalAmt;
    self.labelTotalDiscount.text = _splitBillTotalDiscAmt;
    self.labelSubtotal.text = _splitBillSubTotalAmt;
    self.textTotalAmtNeedToPay.text = self.labelTotalAmt.text;
    
}

#pragma mark - sqlite3 function

-(void)getSalesOrderAmount
{
    [payOrderDetailArray addObjectsFromArray:[[LibraryAPI sharedInstance]getPayOrderDetailArray]];
    dbTable = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTable open]) {
        NSLog(@"Fail To Open Database");
        return;
    }
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rs1;
        NSString *sqlCommand;
        if ([_payDocType isEqualToString:@"CashSales"]) {
            
            finalSplitBillArray = [[LibraryAPI sharedInstance] getEditCashSalesDetailArray];
            
            self.labelRounding.text = [NSString stringWithFormat:@"%0.2f",[[[finalSplitBillArray objectAtIndex:0] objectForKey:@"SOH_Rounding"] doubleValue]];
            self.labelSubtotal.text = [NSString stringWithFormat:@"%0.2f",[[[finalSplitBillArray objectAtIndex:0] objectForKey:@"SOH_DocSubTotal"] doubleValue]];
            
            self.labelTotalDiscount.text = [NSString stringWithFormat:@"%0.2f",[[[finalSplitBillArray objectAtIndex:0] objectForKey:@"SOH_DiscAmt"] doubleValue]];
            self.labelTotalTax.text = [NSString stringWithFormat:@"%0.2f",[[[finalSplitBillArray objectAtIndex:0] objectForKey:@"SOH_DocTaxAmt"] doubleValue]];
            self.labelTotalAmt.text = [NSString stringWithFormat:@"%0.2f",[[[finalSplitBillArray objectAtIndex:0] objectForKey:@"SOH_DocAmt"] doubleValue]];
            serviceTaxGstAmt = [NSString stringWithFormat:@"%0.2f",[[[finalSplitBillArray objectAtIndex:0] objectForKey:@"SOH_DocServiceTaxGstAmt"] doubleValue]];
            self.labelServiceCharge.text = [NSString stringWithFormat:@"%0.2f",[[[finalSplitBillArray objectAtIndex:0] objectForKey:@"SOH_DocServiceTaxAmt"] doubleValue]];
            //self.labelTotalAmtBlue.text = self.labelTotalAmt.text;
            self.textTotalAmtNeedToPay.text = self.labelTotalAmt.text;
            
        }
        else
        {
            sqlCommand = [PublicSqliteMethod generateSalesOrderDataArray];
            sqlCommand = [NSString stringWithFormat:@"%@ %@",sqlCommand,@"where s1.SOH_DocNo = ? and s1.SOH_Status = 'New' order by SOD_AutoNo"];
            rs1 = [db executeQuery:sqlCommand,SONo];
            
            while ([rs1 next]) {
                
                //docNo = [rs1 stringForColumn:@"SOH_DocNo"];
                NSMutableDictionary *data = [NSMutableDictionary dictionary];
                //[orderFinalArray addObject:[rs1 resultDictionary]];
                SONo = [rs1 stringForColumn:@"SOH_DocNo"];
                
                //[data setObject:[NSString stringWithFormat:@"%ld",(long)[rs1 intForColumn:@"IM_ItemNo"]] forKey:@"IM_ItemNo"];
                [data setObject:[rs1 stringForColumn:@"IM_ItemCode"] forKey:@"IM_ItemCode"];
                [data setObject:[rs1 stringForColumn:@"IM_Description"] forKey:@"IM_Description"];
                
                [data setObject:[NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"IM_Price"]] forKey:@"IM_Price"];
                //one item selling price not included tax
                [data setObject:[rs1 stringForColumn:@"IM_SellingPrice"] forKey:@"IM_SellingPrice"];
                [data setObject:[rs1 stringForColumn:@"IM_DiscountInPercent"] forKey:@"IM_DiscountInPercent"];
                [data setObject:[NSString stringWithFormat:@"%.02f",[rs1 doubleForColumn:@"IM_Price2"]] forKey:@"IM_SalesPrice"];
                
                [data setObject:[rs1 stringForColumn:@"IM_Tax"] forKey:@"IM_Tax"];
                [data setObject:[NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"IM_Qty"]] forKey:@"IM_Qty"];
                
                [data setObject:[rs1 stringForColumn:@"T_Percent"] forKey:@"IM_Gst"];
                
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
                [data setObject:[rs1 stringForColumn:@"IM_TableName"] forKey:@"IM_TableName"];
                //[data setObject:[rs1 stringForColumn:@"IM_PrinterPort"] forKey:@"IM_PrinterPort"];
                
                //--------------tax code --------------
                [data setObject:[rs1 stringForColumn:@"IM_TaxCode"] forKey:@"IM_GSTCode"];
                //[data setObject:[rs1 stringForColumn:@"IM_TaxCode"] forKey:@"IM_GSTCode"];
                
                //-------------service tax-------------
                [data setObject:[rs1 stringForColumn:@"IM_ServiceTaxCode"] forKey:@"IM_ServiceTaxCode"];  //svc tax code
                [data setObject:[rs1 stringForColumn:@"IM_ServiceTaxAmt"] forKey:@"IM_ServiceTaxAmt"]; // service tax amount
                [data setObject:[rs1 stringForColumn:@"IM_ServiceTaxRate"] forKey:@"IM_ServiceTaxRate"];
                
                //-----------for table pax no ---------------------
                [data setObject:[rs1 stringForColumn:@"SOH_PaxNo"] forKey:@"SOH_PaxNo"];
                
                [data setObject:[NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"IM_TotalCondimentSurCharge"]] forKey:@"IM_TotalCondimentSurCharge"];
                [data setObject:@"0.00" forKey:@"IM_NewTotalCondimentSurCharge"];
                [data setObject:[NSString stringWithFormat:@"%ld", finalSplitBillArray.count+1] forKey:@"Index"];
                [data setObject:[rs1 stringForColumn:@"SOD_ManualID"] forKey:@"SOD_ManualID"];
                
                //------ for take away -------------
                [data setObject:[NSString stringWithFormat:@"%d",[rs1 intForColumn:@"IM_TakeAwayYN"]] forKey:@"IM_TakeAwayYN"];
                
                // for modifier
                [data setObject:[rs1 stringForColumn:@"IM_ServiceType"] forKey:@"IM_ServiceType"];
                [data setObject:[rs1 stringForColumn:@"SOD_ModifierID"] forKey:@"SOD_ModifierID"];
                [data setObject:[rs1 stringForColumn:@"SOD_ModifierHdrCode"] forKey:@"SOD_ModifierHdrCode"];
                
                if ([[rs1 stringForColumn:@"SOD_ModifierHdrCode"] length] > 0) {
                    [data setObject:@"PackageItemOrder" forKey:@"OrderType"];
                }
                else
                {
                    [data setObject:@"ItemOrder" forKey:@"OrderType"];
                }
                
                
                self.labelRounding.text = [NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"SOH_Rounding"]];
                self.labelSubtotal.text = [NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"SOH_DocSubTotal"]];
                self.labelTotalDiscount.text = [NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"SOH_DiscAmt"]];
                self.labelTotalTax.text = [NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"SOH_DocTaxAmt"]];
                self.labelTotalAmt.text = [NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"SOH_DocAmt"]];
                serviceTaxGstAmt = [NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"SOH_DocServiceTaxGstAmt"]];
                self.labelServiceCharge.text = [NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"SOH_DocServiceTaxAmt"]];
                //self.labelTotalAmtBlue.text = self.labelTotalAmt.text;
                self.textTotalAmtNeedToPay.text = self.labelTotalAmt.text;
                
                [finalSplitBillArray addObject:data];
                
                [finalSplitBillArray addObjectsFromArray:[PublicSqliteMethod getSalesOrderCondimentWithDBPath:dbPath SalesOrderNo:SONo ItemCode:[data objectForKey:@"IM_ItemCode"] ManualID:[data objectForKey:@"SOD_ManualID"] ParentIndex:finalSplitBillArray.count]];
                
            }
            [rs1 close];
            
        }
        
        /*
        if ([dbTable hadError]) {
            [self showAlertView:[dbTable lastErrorMessage] title:@"Fail"];
        }
        */
        
    }];
    
    [queue close];
    [dbTable close];
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)btnCancelPayment:(id)sender {
    paymentArray = nil;
    finalSplitBillArray = nil;
    payOrderDetailArray = nil;
    printerArray = nil;
    invArray = nil;
    paymentTypeArray = nil;
    kitchenGroup = nil;
    bleDevicePrinter = nil;
    _dictPayCust = nil;
    
    if (_delegate != nil) {
        [_delegate cancelPayment:@"CancelPay"];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    //[self dismissViewControllerAnimated:YES completion:nil];
}

-(void)editTextField:(id)sender
{
    if (multiplePayment == false) {
        [self calcChangeBack];
    }
    
}

#pragma mark - highlight textfield
-(void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == self.textPayAmt) {
        //this is textfield 2, so call your method here
        
        
    }
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return NO;
}

- (void)btnMakePayment:(id)sender {
    
    [self.textRef resignFirstResponder];
    NSDate *today = [NSDate date];
    //NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    //[dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDateFormatter *dateFormat = [[LibraryAPI sharedInstance] getDateFormaterhhmmss];
    NSString *dateString = [dateFormat stringFromDate:today];
    
    if ([self.textTotalAmtNeedToPay.text isEqualToString:@"0.00"]) {
        //[self showAlertView:@"Pay amount cannot 0.00" title:@"Warning"];
        //return;
    }
    
    if (paymentArray.count > 8) {
        [self showAlertView:@"Cannot more than 8 payment mode" title:@"Warning"];
        return;
    }
    
    if (paymentArray.count > 1) {
        multiplePayment = true;
        for (int i = 0; i < paymentArray.count; i++) {
            if ([[[paymentArray objectAtIndex:i] objectForKey:@"PayAmt"] doubleValue] == 0.00) {
                [self showAlertView:@"Multi payment mode cannot contain amount 0.00" title:@"Warning"];
                return;
            }
        }
    }
    else
    {
        multiplePayment = false;
    }
    
    if (multiplePayment == false) {
        if (![paymentGroup isEqualToString:@"Cash"]) {
            
            if ([self.textPayAmt.text doubleValue] > [self.textTotalAmtNeedToPay.text doubleValue]) {
                [self showAlertView:@"Card payment is more than actual amount" title:@"Warning"];
                return;
            }
            else if ([self.textPayAmt.text doubleValue] < [self.textTotalAmtNeedToPay.text doubleValue]) {
                [self showAlertView:@"Card payment is less than actual amount" title:@"Warning"];
                return;
            }
            else if ([self.textPayAmt.text doubleValue] == 0.00) {
                [self showAlertView:@"Card payment cannot 0.00" title:@"Warning"];
                return;
            }
        }
    }
    
    //[self.popOverChange presentPopoverFromRect:CGRectMake(self.btnMakePayment.frame.size.width/2, self.btnMakePayment.frame.size.height/2, 1, 1) inView:self.btnMakePayment permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    
    
    if ([_terminalType isEqualToString:@"Main"]) {
        if ([_splitBill_YN isEqualToString:@"No"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                MBProgressHUD *HUD;
                
                HUD = [[MBProgressHUD alloc] initWithView:self.view];
                HUD.labelText = @"Processing...";
                
                [self.view addSubview:HUD];
                
                [HUD showWhileExecuting:@selector(insertIntoInvoice:) onTarget:self withObject:dateString animated:YES];
            });
            
            //[self insertIntoInvoice:dateString];
        }
        else
        {
            //[self showAlertView:@"Ipad" title:@"Ipad"];
            
            [self insertIntoInvoice:dateString];
        }
    }
    else
    {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
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
                [self showAlertView:@"Server disconnect" title:@"Warning"];
                return;
            }
            
            //[KVNProgress showWithStatus:@"Loading..."];
            [self sendPaymentInv];
        });
        
    }
    
    
    
}

-(void)calcChangeBack
{
    
    if (multiplePayment == false) {
        self.labelChangeAmt.text = [NSString stringWithFormat:@"%0.2f",[self.textPayAmt.text doubleValue] - [self.labelTotalAmt.text doubleValue]];
        
        self.labelLeftChange.text = [NSString stringWithFormat:@"%0.2f",[self.textPayAmt.text doubleValue] - [self.labelTotalAmt.text doubleValue]];
        
        if ([self.labelChangeAmt.text doubleValue] >= 0.00) {
            self.btnMakePayment.enabled = YES;
            self.labelChangeAmt.textColor = [UIColor blueColor];
            self.labelLeftChange.textColor = [UIColor colorWithRed:50/255.0 green:159/255.0 blue:72/255.0 alpha:1.0];
            //self.btnMakePayment.hidden = false;
            
            //self.labelMultiPayVisible.hidden = true;
            
        }
        else
        {
            self.btnMakePayment.enabled = NO;
            self.labelChangeAmt.textColor = [UIColor redColor];
            self.labelLeftChange.textColor = [UIColor redColor];
            //self.btnMakePayment.hidden = true;
           
            //self.labelMultiPayVisible.hidden = false;
            
        }
    }
    
    //[self calcChangeBack];
}

-(void)updateSalesOrder
{
    dbTable = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTable open]) {
        NSLog(@"Fail To Open Database");
        return;
    }
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        [db executeUpdate:@"Update SalesOrderHdr set SOH_Status = ? where SOH_DocNo = ?",@"Pay",SONo];
        
        if ([db hadError]) {
            [self showAlertView:[db lastErrorMessage] title:@"Fail"];
            *rollback = YES;
        }
        else
        {
            [self showAlertView:@"Success make payment" title:@"Success"];
            if (_delegate != nil) {
                //[_delegate successMakePayment];
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        }
        
    }];
    
    [queue close];
    
    [dbTable close];
}

-(void)insertIntoInvoice:(NSString *)date
{
    __block BOOL insertResult = NO;
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        double totalPayAmt = 0.00;
        //NSString *tableName;
        NSUInteger taxIncludedYN = 0;
        NSString *invModifierID = @"";
        NSString *invModifierHdrCode = @"";
        
        if ([[[LibraryAPI sharedInstance] getTaxType] isEqualToString:@"IEx"]) {
            taxIncludedYN = 0;
        }
        else
        {
            taxIncludedYN = 1;
        }
        
        int updateDocNo = 0;
        
        if ([_payDocType isEqualToString:@"CashSales"])
        {
            InvNo = [[finalSplitBillArray objectAtIndex:0] objectForKey:@"SOH_DocNo"];
            [db executeUpdate:@"Delete from InvoiceHdr where IvH_DocNo = ?",InvNo];
            [db executeUpdate:@"Delete from InvoiceDtl where IvD_DocNo = ?",InvNo];
            [db executeUpdate:@"Delete from InvoiceCondiment where IVC_DocNo = ?",InvNo];
            
        }
        else
        {
            FMResultSet *docRs = [db executeQuery:@"Select DOC_Number,DOC_Header from DocNo"
                                  " where DOC_Header = 'CS'"];
            
            if ([docRs next])
            {
                updateDocNo = [docRs intForColumn:@"DOC_Number"] + 1;
                InvNo = [NSString stringWithFormat:@"%@%09.f",[docRs stringForColumn:@"DOC_Header"],[[docRs stringForColumn:@"DOC_Number"]doubleValue] + 1];
            }
            [docRs close];
        }
        
        BOOL dbNoError;
        
        @try {
            if (multiplePayment == false) {
                dbNoError = [db executeUpdate:@"Insert into InvoiceHdr ("
                             "IvH_DocNo,IvH_Date,IvH_DocAmt,IvH_DiscAmt,IvH_Rounding,IvH_Table,IvH_User,IvH_AcctCode,IvH_Status, IvH_DocSubTotal,IvH_DocTaxAmt,IvH_ChangeAmt,IvH_TotalPay,IvH_PaymentType1,IvH_PaymentAmt1,IvH_PaymentRef1,IvH_DocServiceTaxAmt,IvH_DocServiceTaxGstAmt,IvH_DocRef, IvH_PaxNo, IvH_SoNo,IvH_TerminalName,IvH_TaxIncluded_YN,IvH_ServiceTaxGstCode,IvH_CustName,IvH_CustAdd1,IvH_CustAdd2,IvH_CustAdd3,IvH_CustTelNo,IvH_CustGstNo)"
                             "values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",InvNo,date,self.labelTotalAmt.text,self.labelTotalDiscount.text,self.labelRounding.text,_tbName,[[LibraryAPI sharedInstance] getUserName],@"Cash",@"Pay",self.labelSubtotal.text,self.labelTotalTax.text,self.labelChangeAmt.text,self.textPayAmt.text,paymentType,[[paymentArray objectAtIndex:0] objectForKey:@"PayAmt"],self.textRef.text,self.labelServiceCharge.text,serviceTaxGstAmt,self.textRef.text,_finalPaxNo,SONo,@"Server",[NSNumber numberWithInteger:taxIncludedYN],[[LibraryAPI sharedInstance] getServiceTaxGstCode],[_dictPayCust objectForKey:@"Name"],[_dictPayCust objectForKey:@"Add1"],[_dictPayCust objectForKey:@"Add2"],[_dictPayCust objectForKey:@"Add3"],[_dictPayCust objectForKey:@"TelNo"],[_dictPayCust objectForKey:@"GstNo"]];
            }
            else
            {
                for (int i = 0; i < 8; i++)
                {
                    if (i+1 > paymentArray.count) {
                        NSMutableDictionary *dataUpdateTable = [NSMutableDictionary dictionary];
                        [dataUpdateTable setObject:@"-" forKey:@"PayType"];
                        [dataUpdateTable setObject:@"0.00" forKey:@"PayAmt"];
                        [dataUpdateTable setObject:@"-" forKey:@"PayRef"];
                        [paymentArray addObject:dataUpdateTable];
                    }
                    totalPayAmt += [[[paymentArray objectAtIndex:i] objectForKey:@"PayAmt"] doubleValue];
                    
                }
                dbNoError = [db executeUpdate:@"Insert into InvoiceHdr ("
                             "IvH_DocNo,IvH_Date,IvH_DocAmt,IvH_DiscAmt,IvH_Rounding,IvH_Table,IvH_User,IvH_AcctCode,IvH_Status, IvH_DocSubTotal,IvH_DocTaxAmt,IvH_ChangeAmt,IvH_TotalPay,IvH_PaymentType1,IvH_PaymentAmt1,IvH_PaymentRef1"
                             ",IvH_PaymentType2,IvH_PaymentAmt2,IvH_PaymentRef2,IvH_DocServiceTaxAmt,IvH_DocServiceTaxGstAmt"
                             ",IvH_PaymentType3,IvH_PaymentAmt3,IvH_PaymentRef3"
                             ",IvH_PaymentType4,IvH_PaymentAmt4,IvH_PaymentRef4"
                             ",IvH_PaymentType5,IvH_PaymentAmt5,IvH_PaymentRef5"
                             ",IvH_PaymentType6,IvH_PaymentAmt6,IvH_PaymentRef6"
                             ",IvH_PaymentType7,IvH_PaymentAmt7,IvH_PaymentRef7"
                             ",IvH_PaymentType8,IvH_PaymentAmt8,IvH_PaymentRef8"
                             ",IvH_DocRef,IvH_PaxNo,IvH_SoNo,IvH_TerminalName,IvH_TaxIncluded_YN,IvH_ServiceTaxGstCode,IvH_CustName,IvH_CustAdd1,IvH_CustAdd2,IvH_CustAdd3,IvH_CustTelNo,IvH_CustGstNo)"
                             "values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",InvNo,date,self.labelTotalAmt.text,self.labelTotalDiscount.text,[NSNumber numberWithDouble:0.00],_tbName,[[LibraryAPI sharedInstance] getUserName],@"Cash",@"Pay",self.labelSubtotal.text,self.labelTotalTax.text,self.labelChangeAmt.text,[NSNumber numberWithDouble:totalPayAmt],[[paymentArray objectAtIndex:0] objectForKey:@"PayType"],[[paymentArray objectAtIndex:0] objectForKey:@"PayAmt"],[[paymentArray objectAtIndex:0] objectForKey:@"PayRef"],[[paymentArray objectAtIndex:1] objectForKey:@"PayType"],[[paymentArray objectAtIndex:1] objectForKey:@"PayAmt"],[[paymentArray objectAtIndex:1] objectForKey:@"PayRef"],self.labelServiceCharge.text,serviceTaxGstAmt,[[paymentArray objectAtIndex:2] objectForKey:@"PayType"],[[paymentArray objectAtIndex:2] objectForKey:@"PayAmt"],[[paymentArray objectAtIndex:2] objectForKey:@"PayRef"],[[paymentArray objectAtIndex:3] objectForKey:@"PayType"],[[paymentArray objectAtIndex:3] objectForKey:@"PayAmt"],[[paymentArray objectAtIndex:3] objectForKey:@"PayRef"],[[paymentArray objectAtIndex:4] objectForKey:@"PayType"],[[paymentArray objectAtIndex:4] objectForKey:@"PayAmt"],[[paymentArray objectAtIndex:4] objectForKey:@"PayRef"],[[paymentArray objectAtIndex:5] objectForKey:@"PayType"],[[paymentArray objectAtIndex:5] objectForKey:@"PayAmt"],[[paymentArray objectAtIndex:5] objectForKey:@"PayRef"],[[paymentArray objectAtIndex:6] objectForKey:@"PayType"],[[paymentArray objectAtIndex:6] objectForKey:@"PayAmt"],[[paymentArray objectAtIndex:6] objectForKey:@"PayRef"]
                             ,[[paymentArray objectAtIndex:7] objectForKey:@"PayType"],[[paymentArray objectAtIndex:7] objectForKey:@"PayAmt"],[[paymentArray objectAtIndex:7] objectForKey:@"PayRef"]
                             ,self.textRef.text,_finalPaxNo,SONo,@"Server",[NSNumber numberWithInteger:taxIncludedYN],[[LibraryAPI sharedInstance] getServiceTaxGstCode],[_dictPayCust objectForKey:@"Name"],[_dictPayCust objectForKey:@"Add1"],[_dictPayCust objectForKey:@"Add2"],[_dictPayCust objectForKey:@"Add3"],[_dictPayCust objectForKey:@"TelNo"],[_dictPayCust objectForKey:@"GstNo"]];
            }
            
            if (dbNoError) {
                for (int i = 0; i < finalSplitBillArray.count; i++) {
                    if ([[[finalSplitBillArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"] ||
                        [[[finalSplitBillArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"PackageItemOrder"]) {
                        
                        if ([[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_ServiceType"] isEqualToString:@"1"])
                        {
                            invModifierID = [NSString stringWithFormat:@"M%@-%@",InvNo,[[finalSplitBillArray objectAtIndex:i] objectForKey:@"Index"]];
                        }
                        else
                        {
                            if ([[[finalSplitBillArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"]) {
                                invModifierID = @"";
                            }
                        }
                        
                        if ([[[finalSplitBillArray objectAtIndex:i] objectForKey:@"SOD_ModifierHdrCode"] length] > 0) {
                            invModifierHdrCode = [[finalSplitBillArray objectAtIndex:i] objectForKey:@"SOD_ModifierHdrCode"];
                        }
                        else{
                            invModifierHdrCode = @"";
                        }
                        
                        dbNoError = [db executeUpdate:@"Insert into InvoiceDtl "
                                     "(IvD_AcctCode, IvD_DocNo, IvD_ItemCode, IvD_ItemDescription, IvD_Quantity, IvD_Price, IvD_DiscValue, IvD_SellingPrice, IvD_UnitPrice, IvD_Remark, IvD_TakeAway_YN,IvD_DiscType,IvD_SellTax,IvD_TotalSalesTax,IvD_TotalSalesTaxLong,IvD_TotalEx,IvD_TotalExLong,IvD_TotalInc,IvD_TotalDisc,IvD_SubTotal,IvD_DiscInPercent,IvD_ItemTaxCode,IvD_ServiceTaxCode, IvD_TaxRate, IvD_ServiceTaxRate, IvD_ServiceTaxAmt,IvD_TakeAwayYN,IvD_TotalCondimentSurCharge,IvD_ManualID, IvD_ModifierID, IvD_ModifierHdrCode) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",@"Cash",InvNo,[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_ItemCode"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_Description"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_Qty"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_SalesPrice"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_Discount"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_SellingPrice"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_Price"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_Remark"],[NSNumber numberWithInt:0],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_DiscountType"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_Tax"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_TotalTax"],
                                     [[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_totalItemTaxAmtLong"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_totalItemSellingAmt"],
                                     [[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_totalItemSellingAmtLong"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_Total"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_DiscountAmt"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_SubTotal"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_DiscountInPercent"],([[[finalSplitBillArray objectAtIndex:i]objectForKey:@"IM_GSTCode"] isEqualToString:@"-"])?nil:[[finalSplitBillArray objectAtIndex:i]objectForKey:@"IM_GSTCode"],([[[finalSplitBillArray objectAtIndex:i]objectForKey:@"IM_ServiceTaxCode"] isEqualToString:@"-"])?nil:[[finalSplitBillArray objectAtIndex:i]objectForKey:@"IM_ServiceTaxCode"],[[finalSplitBillArray objectAtIndex:i]objectForKey:@"IM_Gst"],[[finalSplitBillArray objectAtIndex:i]objectForKey:@"IM_ServiceTaxRate"],[[finalSplitBillArray objectAtIndex:i]objectForKey:@"IM_ServiceTaxAmt"],[[finalSplitBillArray objectAtIndex:i]objectForKey:@"IM_TakeAwayYN"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_TotalCondimentSurCharge"],[NSString stringWithFormat:@"%@-%@",InvNo,[[finalSplitBillArray objectAtIndex:i] objectForKey:@"Index"]],invModifierID,invModifierHdrCode];
                        
                        
                    }
                    else
                    {
                        
                        dbNoError = [db executeUpdate:@"Insert into InvoiceCondiment"
                                     " (IVC_DocNo, IVC_ItemCode, IVC_CHCode, IVC_CDCode, IVC_CDDescription, IVC_CDPrice, IVC_CDDiscount, IVC_DateTime,IVC_CDQty,IVC_CDManualKey) Values (?,?,?,?,?,?,?,?,?,?)",InvNo,[[finalSplitBillArray objectAtIndex:i] objectForKey:@"ItemCode"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"CHCode"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"CDCode"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"CDDescription"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"CDPrice"],[NSNumber numberWithDouble:0.00],date,[[finalSplitBillArray objectAtIndex:i] objectForKey:@"UnitQty"],[NSString stringWithFormat:@"%@-%@",InvNo,[[finalSplitBillArray objectAtIndex:i] objectForKey:@"ParentIndex"]]];
                        
                    }
                    
                    
                    if (!dbNoError) {
                        
                        [self showAlertView:[dbTable lastErrorMessage] title:@"Fail"];
                        *rollback = YES;
                        return;
                    }
                    else
                    {
                        if (![_payDocType isEqualToString:@"CashSales"])
                        {
                            dbNoError = [db executeUpdate:@"Update DocNo set DOC_Number = ? where DOC_Header = 'CS'",[NSNumber numberWithInt:updateDocNo]];
                            if (!dbNoError) {
                                
                                [self showAlertView:[dbTable lastErrorMessage] title:@"Fail"];
                                *rollback = YES;
                                return;
                            }
                        }
                    }
                }
                
                dbNoError = [db executeUpdate:@"Delete from SalesOrderHdr where SOH_DocNo = ?",SONo];
                dbNoError = [db executeUpdate:@"Delete from SalesOrderDtl where SOD_DocNo = ?",SONo];
                dbNoError = [db executeUpdate:@"Delete from SalesOrderCondiment where SOC_DocNo = ?",SONo];
                
                if (!dbNoError)
                {
                    
                    [self showAlertView:[dbTable lastErrorMessage] title:@"Fail"];
                    *rollback = YES;
                    return;
                }
                else
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        insertResult = YES;
                        ChangeAmtViewController *changeAmtViewController = [[ChangeAmtViewController alloc] init];
                        changeAmtViewController.delegate  = self;
                        changeAmtViewController.changeAmt = self.labelChangeAmt.text;
                        changeAmtViewController.tableName = _tbName;
                        changeAmtViewController.printerBrand = printerBrand;
                        [self.navigationController pushViewController:changeAmtViewController animated:NO];
                    });
                    
                    
                }
                
                
            }
            else
            {
                //NSLog(@"%@",[dbTable lastErrorMessage]);
                [self showAlertView:[dbTable lastErrorMessage] title:@"Fail"];
                return;
            }

        } @catch (NSException *exception) {
            insertResult = NO;
            [self showAlertView:exception.reason title:@"Exception error"];
            *rollback = YES;
            return;
        } @finally {
            
        }
        
    }];
    
    [queue close];
    
    if (insertResult == YES) {
        [self printReceipt];
    }
    
}

-(void)printReceipt
{
    
    if ([printerBrand isEqualToString:@"Asterix"])
    {
        if ([[[LibraryAPI sharedInstance] getWorkMode] isEqualToString:@"Main"])
        {
            
            NSMutableArray *compData = [[NSMutableArray alloc] init];
            NSMutableArray *receiptData = [[NSMutableArray alloc] init];
            
            receiptData = [PublicSqliteMethod getAsterixCashSalesDetailWithDBPath:dbPath CashSalesNo:InvNo ViewName:@"PaymentView"];
            
            [compData addObject:[receiptData objectAtIndex:0]];
            [receiptData removeObjectAtIndex:0];
            
            //[PublicMethod printAsterixSalesOrderWithIpAdd:[[printSOArray objectAtIndex:0] objectForKey:@"P_PortName"] CompanyArray:compData SalesOrderArray:receiptData];
            [PublicMethod printAsterixReceiptWithIpAdd:[[printerArray objectAtIndex:0] objectForKey:@"P_PortName"] CompanyArray:compData CSArray:receiptData];
            
            compData = nil;
            receiptData = nil;
        }
        else
        {
            [self requestAsterixPrintInvoiceFromServer];
        }
        //[self sqlMakeEposReceiptFormat:InvNo];
    }
    else
    {
        if (printerBrand.length > 0) {
            
            [self preparePrintingData];
        }
    }
    
    
    
}

-(void)printKitchen
{
    //[self performSelector:@selector(makeKitchenReceipt) withObject:nil afterDelay:3.0 ];
    //[self makeKitchenReceipt];
    
}

#pragma mark - print receipt

-(void)preparePrintingData
{
    [receiptDataArray removeAllObjects];
    
    [self getPrinterNPaymentTypeSetting];
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data setObject:@"Doc" forKey:@"KR_ItemCode"];
    [data setObject:@"Print" forKey:@"KR_Status"];
    [data setObject:@"0" forKey:@"KR_Qty"];
    [data setObject:@"Doc" forKey:@"KR_Desc"];
    [data setObject:@"RequestPrintKitchenReceipt" forKey:@"IM_Flag"];
    [data setObject:printerBrand forKey:@"KR_Brand"];
    //[data setObject:[[printerArray objectAtIndex:0] objectForKey:@"P_PortName"] forKey:@"KR_IpAddress"];
    [data setObject:receiptPrinterIP forKey:@"KR_IpAddress"];
    
    [data setObject:printerMode forKey:@"KR_PrintMode"];
    [data setObject:_tbName forKey:@"KR_TableName"];
    [data setObject:@"Receipt" forKey:@"KR_DocType"];
    [data setObject:InvNo forKey:@"KR_DocNo"];
    [data setObject:printerName forKey:@"KR_PrinterName"];
    [data setObject:@"Y" forKey:@"KR_KickDrawer"];
    
    [receiptDataArray addObject:data];
    
    if ([_terminalType isEqualToString:@"Main"]) {
        
        
        [[NSNotificationCenter defaultCenter]postNotificationName:@"ServerCallConnectionArrayWithNotification" object:receiptDataArray userInfo:nil];
    }
    else
    {
        [self requestInsertPrintReceiptFromServer];
        
    }
    
}

-(void)printReceiptOnFlyTechPrinter
{
    
    //macAddress = [deviceInfo.mUUID UUIDString];
    
    if ([_terminalType isEqualToString:@"Main"]) {
        [PosApi initPrinter];
        //[EposPrintFunction createFlyTechReceiptWithDBPath:dbPath GetInvNo:InvNo EnableGst:enableGst KickOutDrawerYN:@"Y"];
    }
    else
    {
        //[self requestFlyTechPrintInvoiceFromServer];
        [TerminalData flyTechRequestCSDataWithCSNo:InvNo];
    }
    
    
}

-(void)PrintReceiptInRasterMode {
    //InvNo = @"IV000000063";
    p_selectedWidthInch = SMPaperWidth3inch;
    p_selectedLanguage = SMLanguageEnglish;
    
    printerPortSetting = @"Standard";
    
    if ([_terminalType isEqualToString:@"Main"]) {
        [PrinterFunctions PrintRasterSampleReceiptWithPortname:[[printerArray objectAtIndex:0] objectForKey:@"P_PortName"] portSettings:printerPortSetting paperWidth:p_selectedWidthInch Language:p_selectedLanguage invDocno:InvNo EnableGst:enableGst KickOutDrawer:YES];
    }
    else
    {
        [self requestStarRasterPrintInvoiceFromServer];
    }
    
    
    
}

- (void)printReceiptInLineMode {
    
    
    p_selectedWidthInch = SMPaperWidth3inch;
    p_selectedLanguage = SMLanguageEnglish;
    printerPortSetting = @"Standard";
    
    if ([_terminalType isEqualToString:@"Main"]) {
        NSData *commands = [PrinterFunctions sampleReceiptWithPaperWidth:p_selectedWidthInch
                                                                language:p_selectedLanguage
                                                              kickDrawer:YES invDocNo:InvNo docType:@"Inv" EnableGST:enableGst];
        if (commands == nil) {
            return;
        }
        
        
        [PrinterFunctions sendCommand:commands
                             portName:[[printerArray objectAtIndex:0] objectForKey:@"P_PortName"]
                         portSettings:printerPortSetting
                        timeoutMillis:10000];
    }
    else
    {
        [self requestStarLinePrintInvoiceFromServer];
    }
    
    
    
    
}

#pragma mark - alertView

-(void)showAlertView:(NSString *)msg title:(NSString *)title
{
    /*
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:msg
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
     */
    UIAlertController * alert = [[LibraryAPI sharedInstance] showAlertViewWithMsg:msg Title:title];
    
    [self presentViewController:alert animated:YES completion:nil];
    
    alert = nil;
}

#pragma mark - tableview

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    // Return the number of rows in the section.
    //return paymentArray.count;
    
    int dCount;
    if (tableView == self.paymentModeTableView) {
        dCount = paymentArray.count;
    }
    
    return dCount;
    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id cellReturn;
    static NSString *Identifier = @"PaymentModeTableViewCell";
    
    if (tableView == self.paymentModeTableView) {
        PaymentModeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:Identifier];
       
        cell.labelPaymentMode .text = [[paymentArray objectAtIndex:indexPath.row] objectForKey:@"PayType"];
        
        cell.labelPaymentAmt.text = [NSString stringWithFormat:@"%0.2f",[[[paymentArray objectAtIndex:indexPath.row]objectForKey:@"PayAmt"] doubleValue]];
        cellReturn = cell;
    }
    
    return cellReturn;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    paymentArraySelectedIndex = indexPath.row;
    creditCardKeyPadCtrl = @"Clear";
    /*
    if (tableView == self.paymentTypeTableView) {
        if ([[[paymentTypeArray objectAtIndex:indexPath.row] objectForKey:@"PT_Type"] isEqualToString:@"Cash"]) {
            paymentGroup = @"Cash";
            [self payCash:@"Cash"];
        }
        else if ([[[paymentTypeArray objectAtIndex:indexPath.row] objectForKey:@"PT_Type"] isEqualToString:@"Card"])
        {
            //[self payCard:@"Card"];
            paymentGroup = @"Card";
            [self payCard:[[paymentTypeArray objectAtIndex:indexPath.row]objectForKey:@"PT_Code"]];
        }
    }
     */
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

    if (paymentArray.count == 1) {
        multiplePayment = false;
        
        return;
    }
    
    //deselect remove payment type in collectionview
    for (int j = 0; j <= paymentTypeArray.count - 1; j++) {
        NSIndexPath *deSelectRow = [NSIndexPath indexPathForItem:j inSection:0];
        [self.collectionViewPayMethod deselectItemAtIndexPath:deSelectRow animated:NO];
        [self collectionView:self.collectionViewPayMethod didDeselectItemAtIndexPath:deSelectRow];
    }
    
    if(indexPath.row - 1 <= 0)
    {
        paymentArraySelectedIndex = 0;
    }
    else
    {
        paymentArraySelectedIndex = indexPath.row - 1;
    }
    //NSLog(@"last selected row %d",lastRowAfterDelete);
    [paymentArray removeObjectAtIndex:indexPath.row];
    
    if ([paymentArray count] == 1) {
        multiplePayment = false;
        if ([[[paymentArray objectAtIndex:0] objectForKey:@"PayType"] isEqualToString:@"Cash"]) {
            self.btnExact.enabled = true;
        }
    }
    else
    {
        multiplePayment = true;
    }
    
    [self.paymentModeTableView reloadData];
    
    
    for (int j = 0; j <= paymentTypeArray.count - 1; j++) {
        if ([[[paymentTypeArray objectAtIndex:j] objectForKey:@"PT_Code"] isEqualToString:[[paymentArray objectAtIndex:paymentArraySelectedIndex] objectForKey:@"PayType"]]) {
            
            if (paymentArray.count == 1) {
                [self replacePaymentArraynRefreshTableWithPayAmt:@"0.00" SelectedIndex:0];
                self.textPayAmt.text = @"0.00";
                [self manualDidSelectCollectionViewWithIndexNo:j];
            }
            else
            {
                [self manualDidSelectCollectionViewWithIndexNo:j];
            }
            
        }
    }
    
    [self recalMultiPayChangeAmt2];
    
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

#pragma mark - btn click

- (void)btnTen:(id)sender {
    if ([creditCardKeyPadCtrl isEqualToString:@"UnClear"]) {
        self.textPayAmt.text = @"";
    }
    
    creditCardKeyPadCtrl = @"Clear";
    self.textPayAmt.text = [NSString stringWithFormat:@"%0.f",[self.textPayAmt.text doubleValue] + 10];
    
    [self replacePaymentArraynRefreshTableWithPayAmt:self.textPayAmt.text SelectedIndex:paymentArraySelectedIndex];
    if (multiplePayment == YES) {
        [self recalMultiPayChangeAmt2];
    }
    else
    {
        [self calcChangeBack];
    }
}
- (void)btnTwenty:(id)sender {
    if ([creditCardKeyPadCtrl isEqualToString:@"UnClear"]) {
        self.textPayAmt.text = @"";
    }
    
    creditCardKeyPadCtrl = @"Clear";
    self.textPayAmt.text = [NSString stringWithFormat:@"%0.f",[self.textPayAmt.text doubleValue] + 20];
    
    [self replacePaymentArraynRefreshTableWithPayAmt:self.textPayAmt.text SelectedIndex:paymentArraySelectedIndex];
    if (multiplePayment == YES) {
        [self recalMultiPayChangeAmt2];
    }
    else
    {
        [self calcChangeBack];
    }
}

- (void)btnFity:(id)sender {
    if ([creditCardKeyPadCtrl isEqualToString:@"UnClear"]) {
        self.textPayAmt.text = @"";
    }
    creditCardKeyPadCtrl = @"Clear";
    self.textPayAmt.text = [NSString stringWithFormat:@"%0.f",[self.textPayAmt.text doubleValue] + 50];
    [self replacePaymentArraynRefreshTableWithPayAmt:self.textPayAmt.text SelectedIndex:paymentArraySelectedIndex];
    if (multiplePayment == YES) {
        [self recalMultiPayChangeAmt2];
    }
    else
    {
        [self calcChangeBack];
    }
    //[self calcChangeBack];
}

- (void)btnExactAmt:(id)sender {
    creditCardKeyPadCtrl = @"Clear";
    
    
    
    if (multiplePayment == true) {
        if ([self.labelLeftChange.text doubleValue] <= 0) {
            self.textPayAmt.text = [NSString stringWithFormat:@"%0.2f",[self.labelLeftChange.text doubleValue] * -1];
            
        }
        else
        {
            //self.textPayAmt.text = self.labelTotalAmt.text;
        }
    }
    else
    {
        self.textPayAmt.text = self.labelTotalAmt.text;
        
        [self replacePaymentArraynRefreshTableWithPayAmt:self.textPayAmt.text SelectedIndex:paymentArraySelectedIndex];
    }
    
    [self calcChangeBack];
}

-(void)payCash:(NSString *)payType
{
    paymentType = payType;
    [self.btnPayCash setBackgroundImage:[UIImage imageNamed:@"normal"] forState: UIControlStateNormal];
    [self.btnPayCard setBackgroundImage:[UIImage imageNamed:@"highlight"] forState: UIControlStateNormal];
    self.btnMakePayment.enabled = false;
    self.textPayAmt.enabled = true;
    self.textPayAmt.text = @"";
    
    self.btnTen.enabled = true;
    self.btnTwenty.enabled = true;
    self.btnFity.enabled = true;
    
    if (multiplePayment == false) {
        self.btnExact.enabled = true;
    }
    
    /*
    if ([self.labelChangeAmt.text doubleValue] >= 0.00) {
        
        self.labelMultiPayVisible.hidden = true;
    }
    else
    {
        
        self.labelMultiPayVisible.hidden = false;
    }
     */
    
   
}

-(void)payCard:(NSString *)pType
{
    NSString *payAmt;
    paymentType = pType;
    [self.btnPayCard setBackgroundImage:[UIImage imageNamed:@"normal"] forState: UIControlStateNormal];
    [self.btnPayCash setBackgroundImage:[UIImage imageNamed:@"highlight"] forState: UIControlStateNormal];
    
    self.btnTen.enabled = false;
    self.btnTwenty.enabled = false;
    self.btnFity.enabled = false;
    self.btnExact.enabled = false;
    payAmt = @"0.00";
    if (multiplePayment == true) {
        for (int i = 0; i < paymentArray.count; i++) {
            payAmt = [NSString stringWithFormat:@"%0.2f", [[[paymentArray objectAtIndex:i]objectForKey:@"PayAmt"]doubleValue] + [payAmt doubleValue]];
        }
        self.textPayAmt.text = [NSString stringWithFormat:@"%0.2f",[self.labelTotalAmt.text doubleValue] - [payAmt doubleValue]];
        self.textPayAmt.enabled = true;
        
    }
    else
    {
        
        self.textPayAmt.text = self.textTotalAmtNeedToPay.text;
        self.textPayAmt.enabled = false;
        self.btnMakePayment.enabled = true;
        self.labelChangeAmt.text = @"0.00";
        self.labelLeftChange.text = @"0.00";
        self.labelLeftChange.textColor = [UIColor colorWithRed:50/255.0 green:159/255.0 blue:72/255.0 alpha:1.0];
        //self.labelPayment.text = self.labelTotalAmt.text;
    }
    
    
}

-(void)addPaymentMode:(id)sender
{
    creditCardKeyPadCtrl = @"Clear";
    NSString *remainAmt;
    /*
    if ([self.textPayAmt.text doubleValue] <= 0.00) {
        [self showAlertView:@"Cannot 0.00" title:@"Alert"];
        self.textPayAmt.text = @"";
     
        return;
    }
     */
    
    
    if ([paymentGroup isEqualToString:@"Card"]) {
        NSLog(@"%f",[self.labelTotalAmt.text doubleValue] - [multiPayAmt doubleValue]);
        remainAmt = [NSString stringWithFormat:@"%0.2f", [self.labelTotalAmt.text doubleValue] - [multiPayAmt doubleValue]];
        if ([self.textPayAmt.text doubleValue] > [remainAmt doubleValue]) {
            [self showAlertView:@"Card payment is more than actual amount" title:@"Warning"];
            self.textPayAmt.text = @"";
            return;
        }
    }
    
    if ([multiPayAmt doubleValue] >= [self.labelTotalAmt.text doubleValue]) {
        [self showAlertView:@"Already match total amount" title:@"Warning"];
        self.textPayAmt.text = @"";
        return;
    }
    
    //multiplePayment = true;
    /*
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data setObject:paymentType forKey:@"PayType"];
    [data setObject:[NSString stringWithFormat:@"%0.2f",[self.textPayAmt.text doubleValue]] forKey:@"PayAmt"];
    [data setObject:self.textRef.text forKey:@"PayRef"];
    [paymentArray addObject:data];
    data = nil;
    */
    
    
}

-(void)recalMultiPayChangeAmt2
{
    //creditCardKeyPadCtrl = @"Clear";
    NSString *remainAmt;
    multiPayAmt = @"0.00";
    
    for (int i=0; i<paymentArray.count; i++) {
        multiPayAmt = [NSString stringWithFormat:@"%0.2f", [[[paymentArray objectAtIndex:i]objectForKey:@"PayAmt"]doubleValue] + [multiPayAmt doubleValue]];
    }
    
    if ([paymentGroup isEqualToString:@"Card"]) {
        remainAmt = [NSString stringWithFormat:@"%0.2f", [self.labelTotalAmt.text doubleValue] - [multiPayAmt doubleValue]];
        NSLog(@"multipay %@",multiPayAmt);
        if ([multiPayAmt doubleValue] > [self.textTotalAmtNeedToPay.text doubleValue]) {
            [self showAlertView:@"Card payment is more than actual amount" title:@"Warning"];
            self.textPayAmt.text = @"";
            [self replacePaymentArraynRefreshTableWithPayAmt:@"0.00" SelectedIndex:paymentArraySelectedIndex];
            self.labelLeftChange.text = [NSString stringWithFormat:@"%0.2f", [multiPayAmt doubleValue] - [self.textTotalAmtNeedToPay.text doubleValue]];
            return;
        }
    }
    
    self.labelChangeAmt.text = [NSString stringWithFormat:@"%0.2f", [multiPayAmt doubleValue] - [self.textTotalAmtNeedToPay.text doubleValue]];
    
    self.labelLeftChange.text = [NSString stringWithFormat:@"%0.2f", [multiPayAmt doubleValue] - [self.textTotalAmtNeedToPay.text doubleValue]];
    
    NSLog(@"%@ - %@ = %@",multiPayAmt,self.textTotalAmtNeedToPay.text,self.labelLeftChange.text);
    
    if ([self.labelChangeAmt.text doubleValue] >= 0.00) {
        self.btnMakePayment.enabled = YES;
        
        self.labelChangeAmt.textColor = [UIColor whiteColor];
        self.labelLeftChange.textColor = [UIColor colorWithRed:50/255.0 green:159/255.0 blue:72/255.0 alpha:1.0];
        //self.btnC.enabled = false;
        
    }
    else
    {
        self.btnMakePayment.enabled = NO;
        //self.btnMakePayment.hidden = true;
        self.labelChangeAmt.textColor = [UIColor redColor];
        self.labelLeftChange.textColor = [UIColor redColor];
        //self.btnC.enabled = true;
    }
    
    [self.paymentModeTableView reloadData];
}
/*
-(void)recalMultiPayChangeAmt
{
    creditCardKeyPadCtrl = @"Clear";
    multiPayAmt = @"0.00";
    self.textPayAmt.text = @"0.00";
    
    for (int i=0; i<paymentArray.count; i++) {
        multiPayAmt = [NSString stringWithFormat:@"%0.2f", [[[paymentArray objectAtIndex:i]objectForKey:@"PayAmt"]doubleValue] + [multiPayAmt doubleValue]];
    }
     
    self.labelChangeAmt.text = [NSString stringWithFormat:@"%0.2f", [multiPayAmt doubleValue] - [self.labelTotalAmt.text doubleValue]];
    
    self.labelLeftChange.text = [NSString stringWithFormat:@"%0.2f", [multiPayAmt doubleValue] - [self.labelTotalAmt.text doubleValue]];
    
    if ([self.labelChangeAmt.text doubleValue] >= 0.00) {
        self.btnMakePayment.enabled = YES;
        self.labelChangeAmt.textColor = [UIColor whiteColor];
        self.labelLeftChange.textColor = [UIColor blueColor];
        //self.btnC.enabled = false;
        
    }
    else
    {
        self.btnMakePayment.enabled = NO;
        //self.btnMakePayment.hidden = true;
        self.labelChangeAmt.textColor = [UIColor redColor];
        self.labelLeftChange.textColor = [UIColor redColor];
        //self.btnC.enabled = true;
    }
    
    [self.paymentModeTableView reloadData];
}

*/


#pragma mark - step4 receipt printing code

-(void)sqlMakeEposReceiptFormat:(NSString *)receiptType
{
    if ([_terminalType isEqualToString:@"Main"]) {
        [self runPrintSequence];
    }
    else
    {
        [self requestAsterixPrintInvoiceFromServer];
    }
    
}

- (void)runPrintSequence
{
    NSString *errorMsg;
    Result *result = nil;
    EposBuilder *builder = nil;
    
    result = [[Result alloc] init];
    
    //builder = [EposPrintFunction createReceiptData:result DBPath:dbPath GetInvNo:InvNo EnableGst:enableGst KickOutDrawerYN:@"Y"];
    
    if(result.errType == RESULT_ERR_NONE) {
        [EposPrintFunction print:builder
             Result:result PortName:[[printerArray objectAtIndex:0] objectForKey:@"P_PortName"]];
    }
    
    if(builder != nil) {
        [builder clearCommandBuffer];
        
        //[builder release];
    }
    
    errorMsg = [EposPrintFunction displayMsg:result];
    
    if(result != nil) {
        // [result release];
        if ([errorMsg length] > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showAlertView:errorMsg title:@"Printer Error"];
            });
        }
        
    }
    
    return;
    
    
}

#pragma mark - Star Printer kitchen receipt

-(void)PaymentPrintStarKitchenReceiptInRasterModeWithItemName:(NSString *)itemName OrderQty:(NSString *)orderQty PortName:(NSString *)portName {
    //InvNo = @"IV000000063";
    p_selectedWidthInch = SMKitchenSingleReceipt;
    p_selectedLanguage = SMLanguageEnglish;
    
    printerPortSetting = @"Standard";
    
    [PrinterFunctions PrintRasterSingleKitchenWithPortname:portName portSettings:printerPortSetting ItemName:itemName TableName:_tbName OrderQty:orderQty];
    
}

- (void)PaymentPrintStarKitchenReceiptInLineModeWithItemName:(NSString *)itemName OrderQty:(NSString *)orderQty PortName:(NSString *)portName {
    
    
    p_selectedWidthInch = SMPaperWidth3inchSO;
    p_selectedLanguage = SMLanguageEnglish;
    
    //NSData *[commands = [PrinterFunctions printL]]
    NSData *commands = [PrinterFunctions printKitchenReceiptWithPaperWidth:p_selectedWidthInch language:p_selectedLanguage Item:itemName TableName:_tbName Qty:orderQty];
    
    if (commands == nil) {
        return;
    }
    
    printerPortSetting = @"Standard";
    [PrinterFunctions sendCommand:commands
                         portName:portName
                     portSettings:printerPortSetting
                    timeoutMillis:10000];
    
    
}

- (void)PaymentPrintStarGroupKitchenReceiptInLineModeWithOrderArray:(NSMutableArray *)orderArray PortName:(NSString *)portName {
    
    p_selectedWidthInch = SMPaperWidth3inchSO;
    p_selectedLanguage = SMLanguageEnglish;
    
    //NSData *[commands = [PrinterFunctions printL]]
    
    NSData *commands = [PrinterFunctions printGroupKitchenReceiptWithPaperWidth:p_selectedWidthInch language:p_selectedLanguage OrderArray:orderArray TableName:_tbName];
    
    if (commands == nil) {
        return;
    }
    
    printerPortSetting = @"Standard";
    [PrinterFunctions sendCommand:commands
                         portName:portName
                     portSettings:printerPortSetting
                    timeoutMillis:10000];
    
    
}

-(void)PaymentPrintStarGroupKitchenReceiptInRasterModeWithItemName:(NSString *)itemName OrderArray:(NSMutableArray *)orderArray PortName:(NSString *)portName {
    //InvNo = @"IV000000063";
    p_selectedWidthInch = SMKitchenSingleReceipt;
    p_selectedLanguage = SMLanguageEnglish;
    
    printerPortSetting = @"Standard";
    
    [PrinterFunctions PrintRasterGroupKitchenWithPortname:portName portSettings:printerPortSetting OrderDetail:orderArray TableName:_tbName];
    
}


#pragma  mark asterix kitchen printer

-(void)makeGroupKitchenReceipt
{

    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rsPrinter = [db executeQuery:@"Select * from Printer where P_Type = ?",@"Kitchen"];
        
        while ([rsPrinter next]) {
            [kitchenGroup removeAllObjects];
            for (int i = 0; i < payOrderDetailArray.count; i++) {
                if ([[[payOrderDetailArray objectAtIndex:i] objectForKey:@"IM_Print"] isEqualToString:@"Print"]) {
                    
                    FMResultSet *rsItemPrinter = [db executeQuery:@"Select IM_Description, IM_Description2 from ItemPrinter IP"
                                                  " inner join ItemMast IM on IP.IP_ItemNo = IM.IM_ItemCode where IP.IP_ItemNo = ?"
                                                  " and IP.IP_PrinterName = ?",[[payOrderDetailArray objectAtIndex:i] objectForKey:@"IM_ItemCode"],[rsPrinter stringForColumn:@"P_PrinterName"]];
                    
                    if ([rsItemPrinter next]) {
                        NSMutableDictionary *data = [NSMutableDictionary dictionary];
                        [data setObject:[rsItemPrinter stringForColumn:@"IM_Description"] forKey:@"IM_Description"];
                        [data setObject:[rsItemPrinter stringForColumn:@"IM_Description2"] forKey:@"IM_Description2"];
                        [data setObject:[[payOrderDetailArray objectAtIndex:i] objectForKey:@"IM_Qty"] forKey:@"IM_Qty"];
                        //[data setObject:[rsItemPrinter stringForColumn:@"IM_Description"] forKey:@"IM_Desc"];
                        [kitchenGroup addObject:data];
                    }
                    [rsItemPrinter close];
                    
                }
                
                
            }
            if (kitchenGroup.count > 0) {
                
                if ([[rsPrinter stringForColumn:@"P_Brand"] isEqualToString:@"Star"]) {
                    if ([[rsPrinter stringForColumn:@"P_Mode"] isEqualToString:@"Line"]) {
                        [self PaymentPrintStarGroupKitchenReceiptInLineModeWithOrderArray:kitchenGroup PortName:[rsPrinter stringForColumn:@"P_PortName"]];
                    }
                    else if ([[rsPrinter stringForColumn:@"P_Mode"] isEqualToString:@"Raster"])
                    {
                        [self PaymentPrintStarGroupKitchenReceiptInRasterModeWithItemName:@"ddd" OrderArray:kitchenGroup PortName:[rsPrinter stringForColumn:@"P_PortName"]];
                    }
                }
                else if ([[rsPrinter stringForColumn:@"P_Brand"] isEqualToString:@"Asterix"])
                {
                    //[self runPrintLitchenGroup:[rsPrinter stringForColumn:@"P_PortName"]];
                }
                else if ([[rsPrinter stringForColumn:@"P_Brand"] isEqualToString:@"FlyTech"])
                {
                    //[self runPrintFlyTechKitchenGroup];
                }
                else if ([[rsPrinter stringForColumn:@"P_Brand"] isEqualToString:@"XinYe"])
                {
                    //[self runPrintFlyTechKitchenGroup];
                    //[self connectXinYePrinterToPrintGroupKitchenReceiptWithIPAddress:[rsPrinter stringForColumn:@"P_PortName"]];
                }
                
                
            }
            
            
        }
        [rsPrinter close];
        
    }];
    
    kitchenGroup = nil;
    [queue close];
    
}

-(void)runPrintFlyTechKitchenGroup
{
    [PosApi initPrinter];
    [EposPrintFunction createFlyTechKitReceiptGroupWithOrderDetail:kitchenGroup TableName:_tbName];
}

-(void)runPrintLitchenGroup:(NSString *)portName
{
    Result *result = nil;
    EposBuilder *builder = nil;
    
    result = [[Result alloc] init];
    
    builder = [EposPrintFunction createKitchenReceiptGroupFormat:result OrderDetail:kitchenGroup TableName:_tbName];
    
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

-(void)makeKitchenReceipt
{
    
    int kitchenReceiptType = 0;
    
    kitchenReceiptType = [[LibraryAPI sharedInstance] getKitchenReceiptGrouping];
    
    if (kitchenReceiptType == 0) {
        for (int i = 0; i < payOrderDetailArray.count; i++) {
            if ([[[payOrderDetailArray objectAtIndex:i] objectForKey:@"IM_Print"] isEqualToString:@"Print"]) {
                dbTable = [FMDatabase databaseWithPath:dbPath];
                makeXinYeDiscon++;
                //BOOL dbHadError;
                
                if (![dbTable open]) {
                    NSLog(@"Fail To Open");
                    return;
                }
                
                FMResultSet *rs = [dbTable executeQuery:@"Select IP_PrinterName, P_Mode, P_Brand, P_PortName from ItemPrinter IP inner join Printer p on IP.IP_PrinterName = P.P_PrinterName where IP.IP_ItemNo = ?",[[payOrderDetailArray objectAtIndex:i] objectForKey:@"IM_ItemCode"]];
                
                while ([rs next]) {
                    if ([[rs stringForColumn:@"P_Brand"] isEqualToString:@"Star"]) {
                        if ([[rs stringForColumn:@"P_Mode"] isEqualToString:@"Line"]) {
                            //[self printReceiptInLineMode];
                            [self PaymentPrintStarKitchenReceiptInLineModeWithItemName:[[payOrderDetailArray objectAtIndex:i] objectForKey:@"IM_Description"] OrderQty:[[payOrderDetailArray objectAtIndex:i] objectForKey:@"IM_Qty"] PortName:[rs stringForColumn:@"P_PortName"]];
                        }
                        else if ([[rs stringForColumn:@"P_Mode"] isEqualToString:@"Raster"])
                        {
                            //[self PrintReceiptInRasterMode];
                            [self PaymentPrintStarKitchenReceiptInRasterModeWithItemName:[[payOrderDetailArray objectAtIndex:i] objectForKey:@"IM_Description"] OrderQty:[[payOrderDetailArray objectAtIndex:i] objectForKey:@"IM_Qty"] PortName:[rs stringForColumn:@"P_PortName"]];
                        }
                        
                    }
                    else if ([[rs stringForColumn:@"P_Brand"] isEqualToString:@"Asterix"])
                    {
                        //[self runPrintKicthenSequence:i IPAdd:[rs stringForColumn:@"P_PortName"]];
                    }
                    else if ([[rs stringForColumn:@"P_Brand"] isEqualToString:@"FlyTech"])
                    {
                        //[self runPrintFlyTechKitchenReceiptPaymentWithIndex:i];
                    }
                    /*
                    else if ([[rs stringForColumn:@"P_Brand"] isEqualToString:@"XinYe"])
                    {
                        if (makeXinYeDiscon == 1) {
                            
                            [self.wifiManager XYDisConnect];
                            
                            [_wifiManager XYConnectWithHost:[rs stringForColumn:@"P_PortName"] port:9100 completion:^(BOOL isConnect) {
                                if (isConnect) {
                                    [self sendCommandToXinYePrinterKitchenWhenPayWithIMDesc:[[payOrderDetailArray objectAtIndex:i] objectForKey:@"IM_Description"] Qty:[[payOrderDetailArray objectAtIndex:i] objectForKey:@"IM_Qty"] IPAdd:[rs stringForColumn:@"P_PortName"] DetectLastItem:i];
                                }
                            }];
                            
                        }
                        else
                        {
                            [self sendCommandToXinYePrinterKitchenWhenPayWithIMDesc:[[payOrderDetailArray objectAtIndex:i] objectForKey:@"IM_Description"] Qty:[[payOrderDetailArray objectAtIndex:i] objectForKey:@"IM_Qty"] IPAdd:[rs stringForColumn:@"P_PortName"] DetectLastItem:i];
                        }
                        
                    }
                     */
                    
                }
                
                [rs close];
            }
            
            
        }

    }
    else
    {
        [self makeGroupKitchenReceipt];
    }
    
}

#pragma mark - XinYe Printer
-(void)sendCommandToXinYePrinterKitchenWhenPayWithIMDesc:(NSString *)imDesc Qty:(NSString *)imQty IPAdd:(NSString *)ipAdd DetectLastItem:(long)indexNo
{
    NSMutableData *commands = [NSMutableData data];
    //if ([_terminalType isEqualToString:@"Main"]) {
        //commands = [EposPrintFunction createXinYeKitchenReceiptWithDBPath:dbPath TableNo:_tbName ItemNo:imDesc Qty:imQty DataArray:nil];
        
        NSMutableData* dataM=[NSMutableData dataWithData:[PosCommand initializePrinter]];
        [dataM appendData:commands];
        [self.wifiManager XYWriteCommandWithData:dataM];
    
}

-(void)connectXinYePrinterToPrintGroupKitchenReceiptWithIPAddress:(NSString *)ipAdd
{
    //[self sendCommandToXinYePrinterGroupKitchenReceipt];
    
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
    
        commands = [EposPrintFunction createXinYeKitReceiptGroupWithOrderDetail:kitchenGroup TableName:_tbName];
        
        NSMutableData* dataM=[NSMutableData dataWithData:[PosCommand initializePrinter]];
        [dataM appendData:commands];
        [self.wifiManager XYWriteCommandWithData:dataM];
        
}

#pragma mark - flytech printer
/*
-(void)runPrintFlyTechKitchenReceiptPaymentWithIndex:(int)indexNo
{
    [PosApi initPrinter];
    
    [EposPrintFunction createFlyTechKitchenReceiptWithDBPath:dbPath TableNo:_tbName ItemNo:[[payOrderDetailArray objectAtIndex:indexNo] objectForKey:@"IM_Description"] Qty:[[payOrderDetailArray objectAtIndex:indexNo] objectForKey:@"IM_Qty"]];
}
*/

#pragma mark - request / send multipeer

-(void)requestPaymentSODetail
{
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [requestServerData removeAllObjects];
    [data setObject:@"Request" forKey:@"Result"];
    [data setObject:@"-" forKey:@"Message"];
    [data setObject:@"RequestPaymentSO" forKey:@"IM_Flag"];
    [data setObject:_payDocType forKey:@"PayDocType"];
    [data setObject:SONo forKey:@"SOH_DocNo"];
    
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

-(void)sendPaymentInv
{
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    
    if (multiplePayment == false) {
        data = [finalSplitBillArray objectAtIndex:0];
        [data setValue:@"Invoice" forKey:@"IM_Flag"];
        [data setValue:paymentType forKey:@"IvH_PaymentType1"];
        [data setValue:self.labelTotalAmt.text forKey:@"IvH_PaymentAmt1"];
        [data setValue:self.textRef.text forKey:@"IvH_PaymentRef1"];
        [data setValue:@"1" forKey:@"IvH_PaymentTypeQty"];
        [data setValue:self.labelChangeAmt.text forKey:@"SOH_ChangeAmt"];
        [data setValue:self.labelLeftChange.text forKey:@"SOH_ChangeAmt"];
        [data setValue:self.textPayAmt.text forKey:@"SOH_PayAmt"];
        [data setValue:self.textRef.text forKey:@"IvH_DocRef"];
        [data setValue:[[LibraryAPI sharedInstance] getUserName] forKey:@"IvH_UserName"];
        [finalSplitBillArray replaceObjectAtIndex:0 withObject:data];
        //[data setObject:SONo forKey:@"SOH_DocNo"];
    }
    else
    {
        data = [finalSplitBillArray objectAtIndex:0];
        [data setValue:@"Invoice" forKey:@"IM_Flag"];
        [data setValue:[NSString stringWithFormat:@"%lu",(unsigned long)paymentArray.count] forKey:@"IvH_PaymentTypeQty"];
        for (int i = 0; i < paymentArray.count; i++) {
            [data setValue:[[paymentArray objectAtIndex:i] objectForKey:@"PayType"] forKey:[NSString stringWithFormat:@"%@%d",@"IvH_PaymentType",i+1]];  //@"IvH_PaymentType1"];
            [data setValue:[[paymentArray objectAtIndex:i] objectForKey:@"PayAmt"] forKey:[NSString stringWithFormat:@"%@%d",@"IvH_PaymentAmt",i+1]];
            [data setValue:self.textRef.text forKey:[NSString stringWithFormat:@"%@%d",@"IvH_PaymentRef",i+1]];
        }
        [data setValue:self.labelChangeAmt.text forKey:@"SOH_ChangeAmt"];
        [data setValue:self.labelLeftChange.text forKey:@"SOH_ChangeAmt"];
        [data setValue:self.textPayAmt.text forKey:@"SOH_PayAmt"];
        [data setValue:self.textRef.text forKey:@"IvH_DocRef"];
        [data setValue:[[LibraryAPI sharedInstance] getUserName] forKey:@"IvH_UserName"];
        [finalSplitBillArray replaceObjectAtIndex:0 withObject:data];
    }
    data = nil;
    
    NSMutableDictionary *data2 = [NSMutableDictionary dictionary];
    data2 = [finalSplitBillArray objectAtIndex:0];
    [data2 setValue:[_dictPayCust objectForKey:@"Name"] forKey:@"CName"];
    [data2 setValue:[_dictPayCust objectForKey:@"Add1"] forKey:@"CAdd1"];
    [data2 setValue:[_dictPayCust objectForKey:@"Add2"] forKey:@"CAdd2"];
    [data2 setValue:[_dictPayCust objectForKey:@"Add3"] forKey:@"CAdd3"];
    [data2 setValue:[_dictPayCust objectForKey:@"TelNo"] forKey:@"CTelNo"];
    [data2 setValue:[_dictPayCust objectForKey:@"GstNo"] forKey:@"CGstNo"];
    
    [finalSplitBillArray replaceObjectAtIndex:0 withObject:data2];
    data2 = nil;
    
    //[requestServerData addObject:data];
    NSData *dataToBeSend = [NSKeyedArchiver archivedDataWithRootObject:finalSplitBillArray];
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
    dataToBeSend = nil;
    allPeers = nil;
    
    if (error)
    {
        NSLog(@"Erro : %@", [error localizedDescription]);
    }
}


#pragma mark - multipeer data transfer

-(void)getPaymentSOResultWithNotification:(NSNotification *)notification
{
    NSArray *paySO;
    paySO = [notification object];
    //NSLog(@"%@",[[paySO objectAtIndex:0] objectForKey:@"IM_Remark"]);
    [finalSplitBillArray removeAllObjects];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.labelRounding.text = [NSString stringWithFormat:@"%0.2f",[[[paySO objectAtIndex:0] objectForKey:@"SOH_Rounding"] doubleValue]];
        self.labelSubtotal.text = [NSString stringWithFormat:@"%0.2f",[[[paySO objectAtIndex:0] objectForKey:@"SOH_DocSubTotal"] doubleValue]];
        
        self.labelTotalDiscount.text = [NSString stringWithFormat:@"%0.2f",[[[paySO objectAtIndex:0] objectForKey:@"SOH_DiscAmt"] doubleValue]];
        
        self.labelTotalTax.text = [NSString stringWithFormat:@"%0.2f",[[[paySO objectAtIndex:0] objectForKey:@"SOH_DocTaxAmt"] doubleValue]];
        
        self.labelTotalAmt.text = [NSString stringWithFormat:@"%0.2f",[[[paySO objectAtIndex:0] objectForKey:@"SOH_DocAmt"] doubleValue]];
        
        serviceTaxGstAmt = [NSString stringWithFormat:@"%0.2f",[[[paySO objectAtIndex:0] objectForKey:@"SOH_DocServiceTaxGstAmt"] doubleValue]];
        
        self.labelServiceCharge.text = [NSString stringWithFormat:@"%0.2f",[[[paySO objectAtIndex:0] objectForKey:@"SOH_DocServiceTaxAmt"] doubleValue]];
        
        self.textTotalAmtNeedToPay.text = self.labelTotalAmt.text;
        
        [finalSplitBillArray addObjectsFromArray:paySO];
        //self.btnExact.enabled = true;
        
        [loading hide:YES afterDelay:0.6];
        
    });
    
    paySO = nil;
    
    
}

-(void)getInsertInvoiceResultWithNotification:(NSNotification *)notification
{
    
    __block NSArray *dict = [notification object];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSString *result = [[dict objectAtIndex:0] objectForKey:@"Result"];
        
        if ([result isEqualToString:@"True"])
        {
            
            ChangeAmtViewController *changeAmtViewController = [[ChangeAmtViewController alloc] init];
            InvNo = [[dict objectAtIndex:0] objectForKey:@"InvNo"];
            changeAmtViewController.delegate  = self;
            changeAmtViewController.changeAmt = self.labelChangeAmt.text;
            changeAmtViewController.tableName = _tbName;
            changeAmtViewController.printerBrand = printerBrand;
            changeAmtViewController.csNo = InvNo;
            if (printerArray.count > 0) {
                changeAmtViewController.receiptPrinterIpAdd = [[printerArray objectAtIndex:0] objectForKey:@"P_PortName"];
            }
            else
            {
                changeAmtViewController.receiptPrinterIpAdd = @"0.0.0.0";
            }
            [self.navigationController pushViewController:changeAmtViewController animated:NO];
            
        }
        else
        {
            [self showAlertView:@"Fail to make payment. Please check connection" title:@"Warning"];
        }
        
        dict = nil;
        
        [self printReceipt];
        /*
            if ([_splitBill_YN isEqualToString:@"No"]) {
                operationQue = [NSOperationQueue new];
                
                NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(printKitchen) object:nil];
                
                [operationQue addOperation:operation];
                operation = nil;
            }
         */
        //}
        
    });

}

-(void)printAsterixPayBillDtlWithNotification:(NSNotification *)notification
{
    NSMutableArray *compData = [[NSMutableArray alloc] init];
    
    NSMutableArray *receiptData = [[NSMutableArray alloc] init];
    receiptData = [notification object];
    [compData addObject:[receiptData objectAtIndex:0]];
    [receiptData removeObjectAtIndex:0];
    
    [PublicMethod printAsterixReceiptWithIpAdd:[[printerArray objectAtIndex:0] objectForKey:@"P_PortName"] CompanyArray:compData CSArray:receiptData];
    
    compData = nil;
    receiptData = nil;
}

-(void)CloseFinalChangeAmt
{
    //dispatch_async(dispatch_get_main_queue(), ^{
        if (_delegate != nil) {
            finalSplitBillArray = nil;
            paymentArray = nil;
            
            [self dismissViewControllerAnimated:NO completion:nil];
            [_delegate successMakePayment:_splitBill_YN];
            
        }
    //});
    
}

-(void)requestFlyTechPrintInvoiceFromServer
{
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [requestServerData removeAllObjects];
    [data setObject:@"Request" forKey:@"Result"];
    [data setObject:@"-" forKey:@"Message"];
    [data setObject:@"RequestPrintFlyTechInvoice" forKey:@"IM_Flag"];
    [data setObject:InvNo forKey:@"Inv_DocNo"];
    [data setObject:[[printerArray objectAtIndex:0] objectForKey:@"P_PortName"] forKey:@"P_PortName"];
    [data setObject:[NSString stringWithFormat:@"%d", enableGst] forKey:@"EnableGst"];
    [data setObject:@"Y" forKey:@"P_KickDrawer"];
    
    
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

-(void)requestInsertPrintReceiptFromServer
{
    /*
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [requestServerData removeAllObjects];
    [data setObject:@"Request" forKey:@"Result"];
    [data setObject:@"-" forKey:@"Message"];
    [data setObject:@"RequestPrintXinYeCS" forKey:@"IM_Flag"];
    [data setObject:InvNo forKey:@"Inv_DocNo"];
    [data setObject:[[printerArray objectAtIndex:0] objectForKey:@"P_PortName"] forKey:@"P_PortName"];
    [data setObject:[NSString stringWithFormat:@"%d", enableGst] forKey:@"EnableGst"];
    [data setObject:@"Y" forKey:@"P_KickDrawer"];
    */
    
    //[requestServerData addObject:data];
    
    NSData *dataToBeSend = [NSKeyedArchiver archivedDataWithRootObject:receiptDataArray];
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

-(void)requestAsterixPrintInvoiceFromServer
{
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [requestServerData removeAllObjects];
    [data setObject:@"Request" forKey:@"Result"];
    [data setObject:@"-" forKey:@"Message"];
    [data setObject:@"RequestPrintAsterixInvoice" forKey:@"IM_Flag"];
    [data setObject:InvNo forKey:@"Inv_DocNo"];
    [data setObject:[[printerArray objectAtIndex:0] objectForKey:@"P_PortName"] forKey:@"P_PortName"];
    [data setObject:[NSString stringWithFormat:@"%d", enableGst] forKey:@"EnableGst"];
    [data setObject:@"Y" forKey:@"P_KickDrawer"];
    [data setObject:@"PaymentView" forKey:@"ViewName"];
    
    
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

-(void)requestStarRasterPrintInvoiceFromServer
{
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [requestServerData removeAllObjects];
    [data setObject:@"Request" forKey:@"Result"];
    [data setObject:@"-" forKey:@"Message"];
    [data setObject:@"RequestStarRasterPrintInvoice" forKey:@"IM_Flag"];
    [data setObject:InvNo forKey:@"Inv_DocNo"];
    [data setObject:printerPortSetting forKey:@"PortSetting"];
    [data setObject:[[printerArray objectAtIndex:0] objectForKey:@"P_PortName"] forKey:@"P_PortName"];
    [data setObject:[NSString stringWithFormat:@"%d",enableGst] forKey:@"EnableGst"];
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

-(void)requestStarLinePrintInvoiceFromServer
{
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [requestServerData removeAllObjects];
    [data setObject:@"Request" forKey:@"Result"];
    [data setObject:@"-" forKey:@"Message"];
    [data setObject:@"RequestStarLinePrintInvoice" forKey:@"IM_Flag"];
    [data setObject:InvNo forKey:@"Inv_DocNo"];
    [data setObject:printerPortSetting forKey:@"PortSetting"];
    [data setObject:[[printerArray objectAtIndex:0] objectForKey:@"P_PortName"] forKey:@"P_PortName"];
    [data setObject:[NSString stringWithFormat:@"%d",enableGst] forKey:@"EnableGst"];
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


- (IBAction)btnKeyPad:(id)sender {
    UIButton *button = (UIButton *) sender;
    
    if ([creditCardKeyPadCtrl isEqualToString:@"Clear"]) {
        self.textPayAmt.text = @"";
        creditCardKeyPadCtrl = @"UnClear";
        
    }
    
    if ([button.titleLabel.text isEqualToString:@"."]) {
        if ([self.textPayAmt.text length] == 0) {
            self.textPayAmt.text = @"0.";
        }
        else
        {
            if (![self.textPayAmt.text containsString:@"."]) {
                self.textPayAmt.text = [self.textPayAmt.text
                                      stringByAppendingString:button.titleLabel.text];
            }
        }
        
    }
    else if ([button.titleLabel.text isEqualToString:@"Clear"])
    {
        self.textPayAmt.text = @"";
        
        self.btnMakePayment.enabled = false;
        //self.btnMakePayment.hidden = true;
        
        [self replacePaymentArraynRefreshTableWithPayAmt:@"0.00" SelectedIndex:paymentArraySelectedIndex];
        [self recalMultiPayChangeAmt2];
        
    }
    else
    {
        self.textPayAmt.text = [self.textPayAmt.text
                              stringByAppendingString:button.titleLabel.text];
    
        [self replacePaymentArraynRefreshTableWithPayAmt:self.textPayAmt.text SelectedIndex:paymentArraySelectedIndex];
        if (multiplePayment == YES) {
            [self recalMultiPayChangeAmt2];
        }
        else
        {
            [self calcChangeBack];
        }
        
    }
    
}

-(void)replacePaymentArraynRefreshTableWithPayAmt:(NSString *)payAmt SelectedIndex:(int)index;
{
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    data = [paymentArray objectAtIndex:index];
    [data setObject:payAmt forKey:@"PayAmt"];
    [paymentArray replaceObjectAtIndex:index withObject:data];
    data = nil;
    [self.paymentModeTableView reloadData];
}

#pragma mark - programatic didselect collectionview
-(void)manualDidSelectCollectionViewWithIndexNo:(int)rowNo
{
    paymentIndexSelected = rowNo;
    NSIndexPath *indexPathForFirstRow = [NSIndexPath indexPathForItem:rowNo inSection:0];
    [self.collectionViewPayMethod selectItemAtIndexPath:indexPathForFirstRow animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    [self collectionView:self.collectionViewPayMethod didSelectItemAtIndexPath:indexPathForFirstRow];
}

#pragma mark - flytech printer event
- (void)onBleConnectionStatusUpdate:(NSString *)addr status:(int)status
{
    if (status == BLE_DISCONNECTED) {
        
        [self showAlertView:@"Information" title:@"Bluetooth printer has disconnect. Please log out and login to reconnect."];
        
    }
}

- (void)onPrinterOutOfPaperSensor:(NSNumber*)status
{
    int stat = [status intValue];
    NSLog(@"onPrinterOutOfPaperSensor = %d",stat);
    if(stat>0)
    {
        [AppUtility showAlertView:@"Printer out of paper" message:@"Error"];
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
- (void)XYWIFIManager:(XYWIFIManager *)manager willDisconnectWithError:(NSError *)error {
    NSLog(@"Error %@",error.description);
}

- (void)XYWIFIManagerDidDisconnected:(XYWIFIManager *)manager {
    
    if (!manager.isAutoDisconnect) {
        //        self.myTab.hidden = YES;
    }
    
    
    NSLog(@"XYWIFIManagerDidDisconnected");
    
}

/*
- (IBAction)btnBLE:(id)sender {
    [PosApi startDiscoverBleDevice];
    // 設置延遲秒數
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC);
    
    // 以執行緒方式執行，避免主行程被鎖住。
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        //[self showAlertView:@"ffff" title:@"fffff"];
        [PosApi stopDiscoverBleDevice];
    });
    
    
}
 */
@end
