//
//  TransferTableToViewController.m
//  IpadOrder
//
//  Created by IRS on 09/05/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import "TransferTableToViewController.h"
#import "LibraryAPI.h"
#import <FMDB.h>
#import "PublicSqliteMethod.h"
#import "AppDelegate.h"
#import "ePOS-Print.h"
#import "Result.h"
#import "MsgMaker.h"
#import "EposPrintFunction.h"
#import "PrinterFunctions.h"
#import <StarIO/SMPort.h>
#import <StarIO/SMBluetoothManager.h>
#import "TerminalData.h"
#import "PublicMethod.h"
#import "TransferTableToTableViewCell.h"

@interface TransferTableToViewController ()
{
    NSMutableArray *tableArray;
    NSString *dbPath;
    FMDatabase *dbTable;
    NSString *selectedTableName;
    NSString *alertType;
    int dineType;
    /*
    NSString *labelSubTotal;
    NSString *labelTaxTotal;
    NSString *labelTotal;
    NSString *labelTotalDiscount;
    NSString *labelServiceTaxTotal;
    NSString *labelTotalQty;
    NSString *serviceTaxGstTotal;
    NSString *labelRound;
     */
    NSMutableArray *partialSalesOrderArray;
    
    MCPeerID *specificPeer;
    NSMutableArray *requestServerData;
    NSString *terminalType;
    NSString *kitchenPrinterYN;
    
    SMLanguage p_selectedLanguage;
    SMPaperWidth p_selectedWidthInch;
    NSString *printerPortSetting;
    int makeXinYeDiscon;
    
    //NSMutableArray *printerIpArray;
    //NSMutableArray *xinYeConnectionArray;
    //NSMutableArray *kitchenReceiptArray;
    //NSMutableArray *orderFinalArray;
    
    NSString *toSalesOrderNo;
}
@property (nonatomic, strong) AppDelegate *appDelegate;
-(void)getAllTableListWithNotification:(NSNotification *)notification;
-(void)getRecalculateTransferTableResultWithNotification:(NSNotification *)notification;
//-(void)getTransferSalesOrderDetailResultWithNotification:(NSNotification *)notification;

@end

@implementation TransferTableToViewController

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
    // Do any additional setup after loading the view from its nib.
    
    UINib *nib = [UINib nibWithNibName:@"TransferTableToTableViewCell" bundle:nil];
    [[self tableViewTransferToTableList]registerNib:nib forCellReuseIdentifier:@"TransferTableToTableViewCell"];
    
    self.preferredContentSize = CGSizeMake(500, 500);
    [self wifiManager];
    dbPath = [[LibraryAPI sharedInstance] getDbPath];
    tableArray = [[NSMutableArray alloc] init];
    partialSalesOrderArray = [[NSMutableArray alloc] init];
    requestServerData = [[NSMutableArray alloc] init];
    //printerIpArray = [[NSMutableArray alloc] init];
    //xinYeConnectionArray = [[NSMutableArray alloc] init];
    //kitchenReceiptArray = [[NSMutableArray alloc] init];
    //orderFinalArray = [[NSMutableArray alloc] init];
    
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    terminalType = [[LibraryAPI sharedInstance] getWorkMode];
    self.tableViewTransferToTableList.delegate = self;
    self.tableViewTransferToTableList.dataSource = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(getAllTableListWithNotification:)
                                                 name:@"GetAllTableListWithNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(getRecalculateTransferTableResultWithNotification:)
                                                 name:@"GetRecalculateTransferTableResultWithNotification"
                                               object:nil];
    
    
    
    
    UIBarButtonItem *backButton =
    [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(exitTransferTableToView)];
    self.navigationItem.leftBarButtonItem = backButton;
    
    UIBarButtonItem *confirmButton =
    [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(updateSalesOrderTableName)];

    self.navigationItem.rightBarButtonItem = confirmButton;
    
    self.tableViewTransferToTableList.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self getLocalKitchenPrinter];
    
    if ([[[LibraryAPI sharedInstance]getWorkMode] isEqualToString:@"Terminal"]) {
        //[self requestFreeTableList];
        if([_selectedOption isEqualToString:@"TransferTable"])
        {
            self.title = @"Transfer Table";
            [self requestAllTableListWithOptionName:_selectedOption];
        }
        else if ([_selectedOption isEqualToString:@"CombineTable"])
        {
            self.title = @"Combine Table";
            [self requestAllTableListWithOptionName:_selectedOption];
            
        }
    }
    else
    {
        if([_selectedOption isEqualToString:@"TransferTable"])
        {
            self.title = @"Transfer Table";
            [self getAllTableList];
        }
        
        else if ([_selectedOption isEqualToString:@"CombineTable"])
        {
            self.title = @"Combine Table";
            [self getSplitedTableList];
            
        }
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - sqlite

-(void)getLocalKitchenPrinter
{
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rsPrinter = [db executeQuery:@"Select * from Printer where P_Type = ?",@"Kitchen"];
        
        if ([rsPrinter next]) {
            kitchenPrinterYN = @"Y";
        }
        else
        {
            kitchenPrinterYN = @"N";
        }
        
        [rsPrinter close];
    }];
    
    [queue close];
}

-(void)getAllTableList
{
    [tableArray addObjectsFromArray:[PublicSqliteMethod getAllTableListWithDbPath:dbPath FromTableName:_fromTableName]];
    
    [self.tableViewTransferToTableList reloadData];
    
}



-(void)getSplitedTableList
{
    
    tableArray = [PublicSqliteMethod getParticularCombineTableListWithDbPath:dbPath TableName:_toTableName];
    
    [self.tableViewTransferToTableList reloadData];
    
}


-(void)exitTransferTableToView
{
    if ([_transferType isEqualToString:@"Direct"]) {
        if(_delegate != nil)
        {
            tableArray = nil;
            requestServerData = nil;
            [_delegate backOrCloseTransferToView];
            [self.navigationController dismissViewControllerAnimated:NO completion:nil];
        }
        //[self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
    else
    {
        [self.navigationController popViewControllerAnimated:NO];
    }
    
}

-(void)updateSalesOrderTableName
{
    
    NSString *message;
    
    if (tableArray.count == 0) {
        [self showAlertView:@"All table are used" title:@"Warning"];
        return;
    }
    
    if ([selectedTableName length] == 0) {
        [self showAlertView:@"Please select table to transfer" title:@"Warning"];
        return;
    }
    
    alertType = @"Confirm";
    
    if ([_selectedOption isEqualToString:@"TransferTable"]) {
        message = [NSString stringWithFormat:@"Table %@ Transfer to Table %@ ?", _fromTableName, selectedTableName];
    }
    else if ([_selectedOption isEqualToString:@"ShareTable"])
    {
        message = [NSString stringWithFormat:@"Table %@ Merge to Table %@ ?", _fromTableName, selectedTableName];
    }
    else
    {
        message = [NSString stringWithFormat:@"Table %@ Combine to Table %@ ?",selectedTableName , _fromTableName];
    }
    
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Table"
                                 message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* yesButton = [UIAlertAction
                                actionWithTitle:@"OK"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
                                    //[self alertActionSelection];
                                    if ([_selectedOption isEqualToString:@"TransferTable"]) {
                                        if ([terminalType isEqualToString:@"Main"]) {
                                            //[self getAllSalesOrderData];
                                        }
                                        else
                                        {
                                            //[self requestTransferSalesOrderDetail];
                                        }
                                    }
                                    else if ([_selectedOption isEqualToString:@"ShareTable"])
                                    {
                                        //[self shareTableBetweenTablesWithFromSalesOrder:_fromDocNo];
                                    }
                                    else if([_selectedOption isEqualToString:@"CombineTable"])
                                    {
                                        if ([terminalType isEqualToString:@"Main"]) {
                                            //[self updateItemServeType];
                                            
                                            [self combineTwoTableWithFromSalesOrder:_fromDocNo ToSalesOrder:toSalesOrderNo];
                                        }
                                        else
                                        {
                                            //[self requestCombineSalesOrderDetail];
                                            [self combineTwoTableWithFromSalesOrder:_fromDocNo ToSalesOrder:toSalesOrderNo];
                                        }
                                        
                                    }
                                    
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
    
}

#pragma mark tableview
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return tableArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    TransferTableToTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TransferTableToTableViewCell"];
    cell.accessoryType = UITableViewCellAccessoryNone;
    //if (cell == nil) {
        //cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TransferTableToTableViewCell"];
    //}
    
    cell.labelTransfer1.text = [NSString stringWithFormat:@"%@",[[tableArray objectAtIndex:indexPath.row] objectForKey:@"TP_Name"]];
    cell.labelTransfer2.text = [NSString stringWithFormat:@"%@",[[tableArray objectAtIndex:indexPath.row] objectForKey:@"TP_SODocAmt"]];
    cell.labelTransferSection.text = [[tableArray objectAtIndex:indexPath.row]objectForKey:@"TP_Section"];
    [[cell textLabel] setFont:[UIFont boldSystemFontOfSize:18]];
    return cell;
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    selectedTableName = [[tableArray objectAtIndex:indexPath.row] objectForKey:@"TP_Name"];
    dineType = [[[tableArray objectAtIndex:indexPath.row] objectForKey:@"TP_DineType"] integerValue];
     toSalesOrderNo = [[tableArray objectAtIndex:indexPath.row] objectForKey:@"TP_SONo"];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
    //return 360;
}

#pragma mark - alert view

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
     */
    //[alert show];
}



/*
-(void)calcSalesTotalWithSalesOrderArray:(NSMutableArray *)orderFinalArray TaxType:(NSString *)taxType ServiceTaxGst:(double)serviceTaxGst
{
    labelSubTotal = @"0.00";
    labelTaxTotal = @"0.00";
    labelTotal = @"0.00";
    labelTotalDiscount = @"0.00";
    labelServiceTaxTotal = @"0.00";
    labelTotalQty = @"0";
    serviceTaxGstTotal = @"0.00";
    labelRound = @"0.00";
    NSString *labelTotalItemTax = @"0.00";
    NSString *labelTotalServiceTax = @"0.00";
    double adjTax = 0.00;
    
    for (int i = 0; i < orderFinalArray.count; i++) {
        labelTotalQty = [NSString stringWithFormat:@"%ld",[labelTotalQty integerValue] + [[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Qty"] integerValue]];
        labelSubTotal = [NSString stringWithFormat:@"%.02f",[labelSubTotal doubleValue] + [[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_SubTotal"]doubleValue]];
        
        labelServiceTaxTotal = [NSString stringWithFormat:@"%.06f",[labelServiceTaxTotal doubleValue] + [[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_ServiceTaxAmt"]doubleValue]];
        
        labelTaxTotal = [NSString stringWithFormat:@"%.06f",[labelTaxTotal doubleValue] + [[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_totalItemTaxAmtLong"]doubleValue]];
        
        labelTotalDiscount = [NSString stringWithFormat:@"%.02f",[labelTotalDiscount doubleValue] + [[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_DiscountAmt"]doubleValue]];
        
        if ([taxType isEqualToString:@"IEx"]) {
            //labelTotal = [NSString stringWithFormat:@"%.02f",[labelSubTotal doubleValue] + [labelTaxTotal doubleValue] - [labelTotalDiscount doubleValue] + [labelServiceTaxTotal doubleValue]];
            //NSLog(@"1. %@",labelTotal);
            labelTotal = [NSString stringWithFormat:@"%.02f",[labelSubTotal doubleValue] + 0 - [labelTotalDiscount doubleValue] + round([labelServiceTaxTotal doubleValue]*100)/100];
        }
        else
        {
            
            labelTotal = [NSString stringWithFormat:@"%.02f",[labelSubTotal doubleValue] - [labelTotalDiscount doubleValue] + [labelServiceTaxTotal doubleValue]];
        }
        labelTotalItemTax = [NSString stringWithFormat:@"%.06f",[labelTotalItemTax doubleValue] + [[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_TotalTax"] doubleValue]];
        
        
    }
    
    labelTotalServiceTax = labelServiceTaxTotal;
    
    //labelServiceTaxTotal = [NSString stringWithFormat:@"%0.2f",[labelServiceTaxTotal doubleValue]];
    labelServiceTaxTotal = [NSString stringWithFormat:@"%.2f",round([labelServiceTaxTotal doubleValue] * 100) / 100];
    
    serviceTaxGstTotal = [NSString stringWithFormat:@"%.06f",[labelServiceTaxTotal doubleValue] * (serviceTaxGst / 100.0)];
    
    //labelTaxTotal = [NSString stringWithFormat:@"%.2f",round(([labelTaxTotal doubleValue]+[serviceTaxGstTotal doubleValue]) * 100) / 100];
    labelTaxTotal = [NSString stringWithFormat:@"%.6f",[labelTaxTotal doubleValue] + [serviceTaxGstTotal doubleValue]];
    labelTaxTotal = [NSString stringWithFormat:@"%.2f",round([labelTaxTotal doubleValue]*100)/100];
    
    if (![taxType isEqualToString:@"IEx"]) {
        NSString *finalTotalSellingFigure2;
        NSString *finalTotalTax2;
        
        labelTotalItemTax = [NSString stringWithFormat:@"%.02f",[labelTotalItemTax doubleValue]  + [serviceTaxGstTotal doubleValue]];
        
        adjTax = [labelTaxTotal doubleValue] - [labelTotalItemTax doubleValue];
        if (adjTax != 0.00) {
            
            NSMutableDictionary *data2 = [NSMutableDictionary dictionary];
            
            finalTotalSellingFigure2 = [NSString stringWithFormat:@"%.02f",[[[orderFinalArray objectAtIndex:orderFinalArray.count - 1] objectForKey:@"IM_totalItemSellingAmt"] doubleValue] - adjTax];
            
            finalTotalTax2 = [NSString stringWithFormat:@"%.02f",[[[orderFinalArray objectAtIndex:orderFinalArray.count - 1] objectForKey:@"IM_TotalTax"] doubleValue] + adjTax];
            data2 = [orderFinalArray objectAtIndex:orderFinalArray.count - 1];
            [data2 setValue:[NSString stringWithFormat:@"%@",finalTotalSellingFigure2] forKey:@"IM_totalItemSellingAmt"];
            [data2 setValue:[NSString stringWithFormat:@"%@",finalTotalTax2] forKey:@"IM_TotalTax"];
            
            [orderFinalArray replaceObjectAtIndex:orderFinalArray.count - 1 withObject:data2];
        }
    }
    
    //labelTotal = [NSString stringWithFormat:@"%.02f",[labelTotal doubleValue] + [serviceTaxGstTotal doubleValue]];
    
    if ([taxType isEqualToString:@"IEx"]) {
        
        labelTotal = [NSString stringWithFormat:@"%.02f",[labelTotal doubleValue] + round([labelTaxTotal doubleValue] * 100) / 100];
        
    }
    else
    {
        labelTotal = [NSString stringWithFormat:@"%.02f",[labelTotal doubleValue] + [[NSString stringWithFormat:@"%0.2f",[serviceTaxGstTotal doubleValue]] doubleValue]];
    }
    
    // rounding
    NSString *strDollar;
    NSString *strCent;
    NSString *lastDigit;
    NSString *secondLastDigit;
    NSString *finalCent;
    
    NSString *final;
    //NSString *sqlCommand;
    lastDigit = [labelTotal substringFromIndex:[labelTotal length] - 1];
    strCent = [NSString stringWithFormat:@"0.%@",[labelTotal substringFromIndex:[labelTotal length] - 2]];
    secondLastDigit = [labelTotal substringWithRange:NSMakeRange([labelTotal length] - 2, 1)];
    finalCent = [[LibraryAPI sharedInstance]getCalcRounding:labelTotal DatabasePath:dbPath];
    strDollar = [labelTotal substringWithRange:NSMakeRange(0, [labelTotal length] - 3)];
    
    if ([strDollar doubleValue] < 0) {
        //for negative value
        final = [NSString stringWithFormat:@"%0.2f",[strDollar doubleValue] - [finalCent doubleValue]];
    }
    else
    {
        final = [NSString stringWithFormat:@"%0.2f",[strDollar doubleValue] + [finalCent doubleValue]];
    }
    
    
    labelRound = [NSString stringWithFormat:@"%0.2f",[finalCent doubleValue] - [strCent doubleValue]];
    labelTotal = final;
    
    strDollar = nil;;
    strCent = nil;
    lastDigit = nil;
    secondLastDigit = nil;
    finalCent = nil;
    final = nil;
    
}
*/

/*
-(BOOL)completeTransferTableWithDate:(NSString *)date SalesOrderArray:(NSMutableArray *)orderFinalArray FinalSalesOrderNo:(NSString *)finalSONo FromSalesOrderNo:(NSString *)fromSalesOrderNo FinalTableName:(NSString *)finalTableName
{
    __block BOOL updateResult;
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
       
        NSUInteger taxIncludedYN = 0;
        
        if ([[[LibraryAPI sharedInstance] getTaxType] isEqualToString:@"IEx"]) {
            taxIncludedYN = 0;
        }
        else
        {
            taxIncludedYN = 1;
        }
        
        if ([_selectedOption isEqualToString:@"CombineTable"]) {
            [db executeUpdate:@"Delete from SalesOrderHdr where SOH_DocNo = ? ", fromSalesOrderNo];
            [db executeUpdate:@"Delete from SalesOrderDtl where SOD_DocNo = ? ", fromSalesOrderNo];
            [db executeUpdate:@"Delete from SalesOrderCondiment where SOC_DocNo = ? ", fromSalesOrderNo];
            [db executeUpdate:@"Delete from SalesOrderCondiment where SOC_DocNo = ?", finalSONo];
        }
        
        [db executeUpdate:@"Update SalesOrderHdr set "
                     " SOH_Date = ?, SOH_DocAmt = ?, SOH_DiscAmt = ?, SOH_Rounding = ?, SOH_Table = ?"
                     ", SOH_User = ?, SOH_AcctCode = ?, SOH_Status = ?, SOH_DocSubTotal = ?,SOH_DocTaxAmt=?, SOH_DocServiceTaxAmt = ?, SOH_DocServiceTaxGstAmt =?,SOH_TaxIncluded_YN = ?, SOH_ServiceTaxGstCode = ? where SOH_DocNo = ?",
                     date,labelTotal,labelTotalDiscount,labelRound ,finalTableName,[[LibraryAPI sharedInstance] getUserName],@"Cash",@"New",labelSubTotal,labelTaxTotal,labelServiceTaxTotal,serviceTaxGstTotal,[NSNumber numberWithInteger:taxIncludedYN],[[LibraryAPI sharedInstance] getServiceTaxGstCode],finalSONo];
        
        
        if (![db hadError]) {
            [db executeUpdate:@"Delete from SalesOrderDtl where SOD_DocNo = ?", finalSONo];
            
            if ([db hadError]) {
                NSLog(@"%@",[dbTable lastErrorMessage]);
                *rollback = YES;
                updateResult = false;
                [self showAlertView:[dbTable lastErrorMessage] title:@"Fail"];
                return;
            }
            else
            {
                for (int i = 0; i < orderFinalArray.count; i++) {
                    if ([[[orderFinalArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"] || [[[orderFinalArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"PackageItemOrder"]) {
                    
                        [db executeUpdate:@"Insert into SalesOrderDtl "
                         "(SOD_AcctCode, SOD_DocNo, SOD_ItemCode, SOD_ItemDescription, SOD_Quantity, SOD_Price, SOD_DiscValue, SOD_SellingPrice, SOD_UnitPrice, SOD_Remark, SOD_TakeAway_YN,SOD_DiscType,SOD_SellTax,SOD_TotalSalesTax,SOD_TotalSalesTaxLong,SOD_TotalEx,SOD_TotalExLong,SOD_TotalInc,SOD_TotalDisc,SOD_SubTotal,SOD_DiscInPercent,SOd_TaxCode,SOD_ServiceTaxCode, SOD_ServiceTaxAmt, SOD_TaxRate,SOD_ServiceTaxRate,SOD_TakeAwayYN,SOD_TotalCondimentSurCharge,SOD_ManualID,SOD_TerminalName, SOD_ModifierID, SOD_ModifierHdrCode) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",@"Cash",finalSONo,[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_ItemCode"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Description"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Qty"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_SalesPrice"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Discount"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_SellingPrice"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Price"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Remark"],[NSNumber numberWithInt:0],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_DiscountType"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Tax"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_TotalTax"],
                         [[orderFinalArray objectAtIndex:i] objectForKey:@"IM_totalItemTaxAmtLong"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_totalItemSellingAmt"],
                         [[orderFinalArray objectAtIndex:i] objectForKey:@"IM_totalItemSellingAmtLong"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Total"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_DiscountAmt"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_SubTotal"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_DiscountInPercent"],([[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_GSTCode"] isEqualToString:@"-"])?nil:[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_GSTCode"],([[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_ServiceTaxCode"] isEqualToString:@"-"])?nil:[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_ServiceTaxCode"],[[orderFinalArray objectAtIndex:i]objectForKey:@"IM_ServiceTaxAmt"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_Gst"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_ServiceTaxRate"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_TakeAwayYN"],[[orderFinalArray objectAtIndex:i] objectForKey:@"IM_TotalCondimentSurCharge"],[NSString stringWithFormat:@"%@",[[orderFinalArray objectAtIndex:i] objectForKey:@"SOD_ManualID"]],@"Server",[[orderFinalArray objectAtIndex:i] objectForKey:@"SOD_ModifierID"],[[orderFinalArray objectAtIndex:i] objectForKey:@"PD_ModifierHdrCode"]];
                    
                    }
                    else if([[[orderFinalArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"CondimentOrder"])
                    {
                        [db executeUpdate:@"Insert into SalesOrderCondiment"
                                     " (SOC_DocNo, SOC_ItemCode, SOC_CHCode, SOC_CDCode, SOC_CDDescription, SOC_CDPrice, SOC_CDDiscount, SOC_DateTime,SOC_CDQty,SOC_CDManualKey) Values (?,?,?,?,?,?,?,?,?,?)",finalSONo,[[orderFinalArray objectAtIndex:i] objectForKey:@"ItemCode"],[[orderFinalArray objectAtIndex:i] objectForKey:@"CHCode"],[[orderFinalArray objectAtIndex:i] objectForKey:@"CDCode"],[[orderFinalArray objectAtIndex:i] objectForKey:@"CDDescription"],[[orderFinalArray objectAtIndex:i] objectForKey:@"CDPrice"],[NSNumber numberWithDouble:0.00],date,[[orderFinalArray objectAtIndex:i] objectForKey:@"UnitQty"],[NSString stringWithFormat:@"%@-%@",finalSONo,[[orderFinalArray objectAtIndex:i] objectForKey:@"ParentIndex"]]];
                    }
                    
                    
                    
                    if ([db hadError]) {
                        //NSLog(@"%@",[dbTable lastErrorMessage]);
                        *rollback = YES;
                        updateResult = false;
                        [self showAlertView:[dbTable lastErrorMessage] title:@"Fail"];
                        return;
                    }
                    
                }
                
                updateResult = true;
                
            }
            
        }
        else
        {
            updateResult = false;
            [self showAlertView:[dbTable lastErrorMessage] title:@"Fail"];
            return;
        }
        
        
    }];
    
    [queue close];
    return updateResult;
}
*/
#pragma mark data transfer
-(void)requestAllTableListWithOptionName:(NSString *)optionSelected
{
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [requestServerData removeAllObjects];
    [data setObject:@"Request" forKey:@"Result"];
    [data setObject:@"-" forKey:@"Message"];
    [data setObject:@"RequestAllTable" forKey:@"IM_Flag"];
    [data setObject:optionSelected forKey:@"OptionSelected"];
    [data setObject:_fromTableName forKey:@"FromTableName"];
    [data setObject:_toTableName forKey:@"ToTableName"];
    
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

-(void)getAllTableListWithNotification:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        //NSArray *serverReturnSoNoResult;
        [tableArray removeAllObjects];
        tableArray = [notification object];
        if ([[[tableArray objectAtIndex:0] objectForKey:@"Result"] isEqualToString:@"True"]) {
            [self.tableViewTransferToTableList reloadData];
        }
        
    });
}

-(void)requestTransferSalesOrderDetail
{
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [requestServerData removeAllObjects];
    [data setObject:@"Request" forKey:@"Result"];
    [data setObject:_fromDocNo forKey:@"SoNo"];
    [data setObject:selectedTableName forKey:@"TbName"];
    [data setObject:[NSString stringWithFormat:@"%d",dineType] forKey:@"DineType"];
    [data setObject:@"-" forKey:@"Message"];
    [data setObject:@"RequestTransferSalesOrderDetail" forKey:@"IM_Flag"];
    
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

/*
-(void)requestCombineSalesOrderDetail
{
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [requestServerData removeAllObjects];
    [data setObject:@"Request" forKey:@"Result"];
    [data setObject:_selectedOption forKey:@"OptionSelected"];
    [data setObject:@"-" forKey:@"Message"];
    [data setObject:_fromTableName forKey:@"FromTableName"];
    [data setObject:@"RequestCombineSalesOrderDetail" forKey:@"IM_Flag"];
    
    [data setObject:_fromDocNo forKey:@"FromSalesOrderNo"];
    [data setObject:toSalesOrderNo forKey:@"ToSalesOrderNo"];
    
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
        NSLog(@"Error : %@", [error localizedDescription]);
    }
    
}
 */
/*
-(void)getTransferSales//OrderDetailResultWithNotification:(NSNotification *)notification
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        partialSalesOrderArray = [notification object];
        //[self showAlertView:[NSString stringWithFormat:@"%ld",partialSalesOrderArray.count] title:@"Warning"];
        if (partialSalesOrderArray.count > 0) {
            [self requestRecalculateSalesOrder];
        }
        else
        {
            [self showAlertView:@"Empty sales order" title:@"Warning"];
        }
        
    });
    
}
*/

-(void)requestRecalculateSalesOrder
{
    
    NSString *itemServeType;
    
    if ([_fromTableDineType isEqualToString:@"0"] && dineType == 1) {
        itemServeType = @"1";
    }
    else if([_fromTableDineType isEqualToString:@"1"] && dineType == 0)
    {
        itemServeType = @"0";
    }
    else
    {
        itemServeType = @"-";
    }
    
    NSString *finalSelectedTable;
    
    if ([_selectedOption isEqualToString:@"TransferTable"]) {
        finalSelectedTable = selectedTableName;
    }
    else if([_selectedOption isEqualToString:@"CombineTable"])
    {
        finalSelectedTable = _fromTableName;
    }
    else
    {
        finalSelectedTable = selectedTableName;
    }

    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [requestServerData removeAllObjects];
    [data setObject:@"Request" forKey:@"Result"];
    [data setObject:_fromDocNo forKey:@"SoNo"];
    [data setObject:finalSelectedTable forKey:@"TbName"];
    [data setObject:[NSString stringWithFormat:@"%d",dineType] forKey:@"DineType"];
    [data setObject:@"-" forKey:@"Message"];
    [data setObject:@"RequestRecalcSaleSOrder" forKey:@"IM_Flag"];
    [data setObject:itemServeType forKey:@"ServeType"];
    [data setObject:_selectedOption forKey:@"OptionSelected"];
    [data setObject:toSalesOrderNo forKey:@"ToSalesOrderNo"];
    
    
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

-(void)getRecalculateTransferTableResultWithNotification:(NSNotification *)notification
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSArray *serverReturnSoNoResult;
        //serverReturnSoNoResult = [notification object];
        
        serverReturnSoNoResult = [notification object];
        
        NSString *result = [[serverReturnSoNoResult objectAtIndex:0] objectForKey:@"Result"];
        //[self showAlertView:result title:@"Warning"];
        if ([result isEqualToString:@"True"]) {
            
        }
        else
        {
            [self showAlertView:@"Fail to send to server" title:@"Warning"];
        }
        
        
        
        [self askForReprint];
        serverReturnSoNoResult = nil;
    });
     
}


/*
-(void)getCombineSalesOrderDetailResultWithNotification:(NSNotification *)notification
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        partialSalesOrderArray = [notification object];
        
        if (partialSalesOrderArray.count > 0) {
            [self requestRecalculateSalesOrder];
        }
        else
        {
            [self showAlertView:@"Empty sales order" title:@"Warning"];
        }
        
    });
    
}
*/
#pragma mark - group recalculate

-(void)combineTwoTableWithFromSalesOrder:(NSString *)fromSalesOrder ToSalesOrder:(NSString *)toSalesOrder
{
    
    if(_delegate != nil)
    {
        tableArray = nil;
        partialSalesOrderArray = nil;
        requestServerData = nil;
        [_delegate combineTwoTableWithFromSalesOrder:fromSalesOrder ToSalesOrder:toSalesOrderNo];
        [self.navigationController dismissViewControllerAnimated:NO completion:nil];
        
        //[self.navigationController dismissViewControllerAnimated:NO completion:nil];
    }
    
    /*
    [partialSalesOrderArray addObjectsFromArray:[PublicSqliteMethod publicCombineTwoTableWithFromSalesOrder:fromSalesOrder ToSalesOrder:toSalesOrder DBPath:dbPath]];
    
    
    if (partialSalesOrderArray.count > 0) {
        [self updateItemServeType];
        
        [self startRecalculateWithFinalSalesOrder:toSalesOrderNo];
    }
     */
}

/*
-(void)getAllSalesOrderData
{
    
    partialSalesOrderArray = [PublicSqliteMethod getTransferSalesOrderDetailWithDbPath:dbPath SalesOrderNo:_fromDocNo];
    [self updateItemServeType];
    [self startRecalculateWithFinalSalesOrder:_fromDocNo];
}
*/
/*
-(void)startRecalculateWithFinalSalesOrder:(NSString *)finalSalesOrderNo
{
    NSMutableDictionary *settingDict = [NSMutableDictionary dictionary];
    NSMutableArray *transferSalesArray = [[NSMutableArray alloc] init];
    NSMutableArray *recalcTransferSalesArray = [[NSMutableArray alloc] init];
    NSArray *recalcTransferArray;
    
    for (int i = 0; i < partialSalesOrderArray.count; i++) {
        
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        
        [data setObject:[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"SOD_DiscInPercent"] forKey:@"DiscInPercent"];
        [data setObject:[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"SOD_Quantity"] forKey:@"ItemQty"];
        [data setObject:[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"SOD_DiscValue"] forKey:@"DiscValue"];
        [data setObject:[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"SOD_DiscType"] forKey:@"DiscType"];
        [data setObject:[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"SOD_TotalDisc"] forKey:@"TotalDisc"];
        [data setObject:[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"SOD_Remark"] forKey:@"Remark"];
        [data setObject:[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"IM_TotalCondimentSurCharge"] forKey:@"IM_TotalCondimentSurCharge"];
        [data setObject:[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"SOD_Quantity"] forKey:@"OrgQty"];
        
        settingDict = [PublicSqliteMethod getGeneralnTableSettingWithTableName:selectedTableName dbPath:dbPath];
        
        transferSalesArray = [PublicSqliteMethod calcGSTByItemNo:[[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"IM_ItemNo"] integerValue] DBPath:dbPath ItemPrice:[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"SOD_UnitPrice"] CompEnableGst:[[settingDict objectForKey:@"EnableGst"] integerValue] CompEnableSVG:[[settingDict objectForKey:@"EnableSVG"] integerValue] TableSVC:[settingDict objectForKey:@"TableSVGPercent"] OverrideSVG:[settingDict objectForKey:@"TableSVGOverRide"] SalesOrderStatus:@"Edit" TaxType:[[LibraryAPI sharedInstance] getTaxType] TableName:selectedTableName ItemDineStatus:[NSString stringWithFormat:@"%@",[NSNumber numberWithInt:[[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"SOD_TakeAwayYN"]integerValue]]] TerminalType:terminalType SalesDict:data IMQty:@"0" KitchenStatus:@"Printed" PaxNo:[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"SOH_PaxNo"] DocType:@"SalesOrder" CondimentSubTotal:[[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"IM_TotalCondimentSurCharge"] doubleValue] ServiceChargeGstPercent:[[LibraryAPI sharedInstance] getServiceTaxGstPercent] TableDineStatus:[NSString stringWithFormat:@"%d",dineType]];
        
        NSDictionary *data2 = [NSDictionary dictionary];
        data2 = [transferSalesArray objectAtIndex:0];
        [data2 setValue:[NSString stringWithFormat:@"%ld",recalcTransferSalesArray.count + 1] forKey:@"Index"];
        [data2 setValue:[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"SOD_ManualID"]  forKey:@"SOD_ManualID"];
        [data2 setValue:[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"SOD_ModifierID"] forKey:@"SOD_ModifierID"];
        [data2 setValue:[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"PD_ModifierHdrCode"] forKey:@"PD_ModifierHdrCode"];
        
        [transferSalesArray replaceObjectAtIndex:0 withObject:data2];
        data2 = nil;
        
        recalcTransferArray = [PublicSqliteMethod recalculateGSTSalesOrderWithSalesOrderArray:transferSalesArray TaxType:[[LibraryAPI sharedInstance] getTaxType]];
        
        //[orderFinalArray addObjectsFromArray:recalcTransferArray];
        
        [recalcTransferSalesArray addObjectsFromArray:recalcTransferArray];
        [self groupCalcTotalForSalesOrderWithRecalculateArray:recalcTransferSalesArray TaxType:[[LibraryAPI sharedInstance] getTaxType] ServiceTaxGst:[[settingDict objectForKey:@"ServiceTaxGstPercent"] doubleValue]];
        
        if ([_selectedOption isEqualToString:@"CombineTable"]) {
            [recalcTransferSalesArray addObjectsFromArray:[PublicSqliteMethod getSalesOrderCondimentWithDBPath:dbPath SalesOrderNo:[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"OldSOD_DocNo"] ItemCode:[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"SOD_ItemCode"] ManualID:[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"OldSOD_ManualID"] ParentIndex:[[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"Index"] integerValue]]];
        }
        
        
    }
    
    NSDate *today = [NSDate date];
    
    NSDateFormatter *dateFormat = [[LibraryAPI sharedInstance] getDateFormateryyyymmdd];
    NSString *dateString = [dateFormat stringFromDate:today];
    
    NSString *finalSelectedTable;
    
    if ([_selectedOption isEqualToString:@"TransferTable"]) {
        finalSelectedTable = selectedTableName;
    }
    else if([_selectedOption isEqualToString:@"CombineTable"])
    {
        finalSelectedTable = _fromTableName;
    }
    else
    {
        finalSelectedTable = selectedTableName;
    }
    
    if([self completeTransferTableWithDate:dateString SalesOrderArray:recalcTransferSalesArray FinalSalesOrderNo:finalSalesOrderNo FromSalesOrderNo:_fromDocNo FinalTableName:finalSelectedTable])
    {
        //[self showAlertView:@"Complete transfer" title:@"Success"];
        //[self.navigationController popViewControllerAnimated:YES];
        //[self.navigationController dismissViewControllerAnimated:NO completion:nil];
        if(_delegate != nil)
        {
            tableArray = nil;
            requestServerData = nil;
            [_delegate backOrCloseTransferToView];
            [self.navigationController dismissViewControllerAnimated:NO completion:nil];
        }
        
    }
    else
    {
        [self showAlertView:@"Fail to transfer" title:@"Warning"];
        return;
    }
    
    dateString = nil;
    today = nil;
    
    settingDict = nil;
    transferSalesArray = nil;
    recalcTransferArray = nil;
    recalcTransferSalesArray = nil;
    
    //NSLog(@"%@",@"Complete Transfer");
    if ([_selectedOption isEqualToString:@"TransferTable"]) {
        [self askForReprint];
    }
    
}
*/
/*
-(void)recalculateTransferAllGSTSalesOrderWithOrderFinalArray:(NSMutableArray *)orderFinalArray
{
    double itemExShort = 0.00;
    double itemExLong = 0.00;
    
    NSString *stringItemExLong;
    NSString *stringItemExShort;
    //NSString *temp;
    //double diffCent = 0.00;
    
    if ([[[LibraryAPI sharedInstance] getTaxType] isEqualToString:@"Inc"]) {
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        for (int i = 0; i < orderFinalArray.count; i++) {
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
    
    
}
*/
/*
-(void)groupCalcTotalForSalesOrderWithRecalculateArray:(NSMutableArray *)orderFinalArray TaxType:(NSString *)taxType ServiceTaxGst:(double)serviceTaxGst
{
    labelSubTotal = @"0.00";
    labelTaxTotal = @"0.00";
    labelTotal = @"0.00";
    labelTotalDiscount = @"0.00";
    labelServiceTaxTotal = @"0.00";
    labelTotalQty = @"0";
    serviceTaxGstTotal = @"0.00";
    labelRound = @"0.00";
    NSDictionary *totalDict = [NSDictionary dictionary];
    NSString *finalTaxAmt = @"0.00";
    NSString *finalServiceCharge = @"0.00";
    NSString *totalTaxableAmt = @"0.00";
    NSString *totalTaxAmt = @"0.00";
    
    [self recalculateTransferAllGSTSalesOrderWithOrderFinalArray:orderFinalArray];
    
    totalDict = [PublicSqliteMethod calclateSalesTotalWith:orderFinalArray TaxType:[[LibraryAPI sharedInstance] getTaxType] ServiceTaxGst:serviceTaxGst DBPath:dbPath];
    
    if (![taxType isEqualToString:@"IEx"]) {
        NSString *finalTotalSellingFigure2;
        NSString *finalTotalTax2;
        double adjTax = 0.00;
        //labelTaxTotal = [NSString stringWithFormat:@"%.02f",[labelTaxTotal doubleValue]  + [serviceTaxGstTotal doubleValue]];
        
        adjTax = [[totalDict objectForKey:@"dccc"] doubleValue] - [[totalDict objectForKey:@"duuu"] doubleValue];
        if (adjTax != 0.00) {
            if ([[LibraryAPI sharedInstance]getEnableSVG] == 0) {
                int rowCount = 1;
                if ([[[orderFinalArray objectAtIndex:orderFinalArray.count - 1] objectForKey:@"IM_GSTCode"] isEqualToString:@"SR"]) {
                    rowCount = 1;
                }
                else
                {
                    rowCount = 2;
                }
                
                NSMutableDictionary *data2 = [NSMutableDictionary dictionary];
                
                finalTotalSellingFigure2 = [NSString stringWithFormat:@"%.02f",[[[orderFinalArray objectAtIndex:orderFinalArray.count - rowCount] objectForKey:@"IM_totalItemSellingAmt"] doubleValue] - adjTax];
                
                finalTotalTax2 = [NSString stringWithFormat:@"%.02f",[[[orderFinalArray objectAtIndex:orderFinalArray.count - rowCount] objectForKey:@"IM_TotalTax"] doubleValue] + adjTax];
                data2 = [orderFinalArray objectAtIndex:orderFinalArray.count - rowCount];
                [data2 setValue:[NSString stringWithFormat:@"%@",finalTotalSellingFigure2] forKey:@"IM_totalItemSellingAmt"];
                [data2 setValue:[NSString stringWithFormat:@"%@",finalTotalTax2] forKey:@"IM_TotalTax"];
                
                [orderFinalArray replaceObjectAtIndex:orderFinalArray.count - rowCount withObject:data2];
            }
            else
            {
                finalTaxAmt = [NSString stringWithFormat:@"%0.2f",[[totalDict objectForKey:@"TotalGst"] doubleValue] + adjTax];
                finalServiceCharge = [NSString stringWithFormat:@"%0.2f",[[totalDict objectForKey:@"ServiceCharge"] doubleValue] - adjTax];
            }
            
        }
    }
    
    if ([[LibraryAPI sharedInstance] getEnableSVG] == 0 && [[totalDict objectForKey:@"TotalServiceChargeGst"]doubleValue] > 0.00) {
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
    
    labelSubTotal = [totalDict objectForKey:@"SubTotal"];
    labelTaxTotal = totalTaxAmt;
    labelTotal = [totalDict objectForKey:@"Total"];
    labelTotalDiscount = [totalDict objectForKey:@"TotalDiscount"];
    labelServiceTaxTotal = [totalDict objectForKey:@"ServiceCharge"];
    labelTotalQty = [totalDict objectForKey:@"TotalQty"];
    labelRound = [totalDict objectForKey:@"Rounding"];
    
    serviceTaxGstTotal = [totalDict objectForKey:@"TotalServiceChargeGst"];
    
    totalDict = nil;
}
*/
#pragma mark - reprint
-(void)askForReprint
{
    if ([kitchenPrinterYN isEqualToString:@"Y"]) {
        alertType = @"Reprint";
        
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"To Kitchen"
                                     message:@"Complete transfer. Send to kitchen ?"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* yesButton = [UIAlertAction
                                    actionWithTitle:@"OK"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
                                        //[self alertActionSelection];
                                       
                                        //[self rePrintKitchenReceipt];
                                        //[PublicSqliteMethod askForReprintKitchenReceiptWithDBPath:dbPath SalesOrderArray:partialSalesOrderArray FromTable:_fromTableName ToTable:selectedTableName SelectedOption:[trans]];
                                        
                                        if ([_transferType isEqualToString:@"Direct"]) {
                                            
                                            if(_delegate != nil)
                                            {
                                                tableArray = nil;
                                                requestServerData = nil;
                                                [_delegate backOrCloseTransferToView];
                                                [self.navigationController dismissViewControllerAnimated:NO completion:nil];
                                            }
                                        }
                                        else
                                        {
                                            [self.navigationController popViewControllerAnimated:NO];
                                        }
                                        
                                    }];
        
        UIAlertAction* noButton = [UIAlertAction
                                   actionWithTitle:@"Cancel"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {
                                       //Handle no, thanks button
                                       if ([_transferType isEqualToString:@"Direct"]) {
                                           
                                           if(_delegate != nil)
                                           {
                                               tableArray = nil;
                                               requestServerData = nil;
                                               [_delegate backOrCloseTransferToView];
                                               [self.navigationController dismissViewControllerAnimated:NO completion:nil];
                                           }
                                       }
                                       else
                                       {
                                           [self.navigationController popViewControllerAnimated:NO];
                                       }
                                   }];
        
        [alert addAction:yesButton];
        [alert addAction:noButton];
        
        [self presentViewController:alert animated:NO completion:nil];
        alert = nil;
        /*
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"To Kitchen"
                                                        message:@"Send To Kitchen Again ?"
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:@"Cancel",nil];
        [alert show];
         */
    }
    else
    {
        //[self.navigationController popViewControllerAnimated:YES];
        [self exitTransferTableToView];
        
    }
    
}

-(void)rePrintKitchenReceipt
{
    /*
    NSMutableArray *asterixPrinterIPArray = [[NSMutableArray alloc] init];
    int kitchenReceiptType = 0;
    [kitchenReceiptArray removeAllObjects];
    
    kitchenReceiptType = [[LibraryAPI sharedInstance] getKitchenReceiptGrouping];
    
    //if (kitchenReceiptType == 0) {
        for (int i = 0; i < partialSalesOrderArray.count; i++) {
            dbTable = [FMDatabase databaseWithPath:dbPath];
            makeXinYeDiscon++;
            //BOOL dbHadError;
            
            if (![dbTable open]) {
                NSLog(@"Fail To Open");
                return;
            }
            
            FMResultSet *rs = [dbTable executeQuery:@"Select IP_PrinterName, P_Mode, P_Brand, P_PortName from ItemPrinter IP inner join Printer p on IP.IP_PrinterName = P.P_PrinterName where IP.IP_ItemNo = ?",[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"SOD_ItemCode"]];
    
            while ([rs next]) {
                if ([[rs stringForColumn:@"P_Brand"] isEqualToString:@"Asterix"]) {
                    NSMutableDictionary *data = [NSMutableDictionary dictionary];
                    [data setObject:[rs stringForColumn:@"P_PortName"] forKey:@"KR_IpAddress"];
                    [asterixPrinterIPArray addObject:data];
                    data = nil;
                }
                else
                {
                    NSMutableDictionary *data = [NSMutableDictionary dictionary];
                    [data setObject:@"Notice" forKey:@"KR_ItemCode"];
                    [data setObject:@"Print" forKey:@"KR_Status"];
                    [data setObject:@"0" forKey:@"KR_Qty"];
                    [data setObject:@"Transfer" forKey:@"KR_Desc"];
                    [data setObject:@"RequestPrintKitchenReceipt" forKey:@"IM_Flag"];
                    [data setObject:[rs stringForColumn:@"P_Brand"] forKey:@"KR_Brand"];
                    [data setObject:[rs stringForColumn:@"P_PortName"] forKey:@"KR_IpAddress"];
                    [data setObject:[rs stringForColumn:@"P_Mode"] forKey:@"KR_PrintMode"];
                    [data setObject:selectedTableName forKey:@"KR_TableName"];
                    [data setObject:@"KitchenNotice" forKey:@"KR_DocType"];
                    [data setObject:_fromTableName forKey:@"KR_DocNo"];
                    [kitchenReceiptArray addObject:data];
                    data = nil;
                }
                
                
            }
            
            [rs close];
            
            
        }
    
    NSOrderedSet *orderedSet = [NSOrderedSet orderedSetWithArray:kitchenReceiptArray];
    NSArray *arrayWithoutDuplicates = [orderedSet array];
    [kitchenReceiptArray removeAllObjects];
    [kitchenReceiptArray addObjectsFromArray:arrayWithoutDuplicates];
    
    
    if (kitchenReceiptArray.count > 0 && [terminalType isEqualToString:@"Main"]) {
        [[NSNotificationCenter defaultCenter]postNotificationName:@"ServerCallConnectionArrayWithNotification" object:kitchenReceiptArray userInfo:nil];
    }
    else if (kitchenReceiptArray.count > 0 && [terminalType isEqualToString:@"Terminal"])
    {
        [TerminalData xinYeRequestServerToPrintTerminalReqWithReceiptArray:kitchenReceiptArray];
    }
    
    kitchenReceiptArray = nil;
    arrayWithoutDuplicates = nil;
     */
    /*
    if (asterixPrinterIPArray.count > 0) {
        NSArray *groupIPArray = [asterixPrinterIPArray valueForKeyPath:@"@distinctUnionOfObjects.KR_IpAddress"];
        
        for (int j = 0; j < groupIPArray.count; j++) {
            
            [PublicMethod printAsterixKitchenReceiptWithItemDesc:@"Transfer to" IPAdd:[groupIPArray objectAtIndex:j] imQty:_fromTableName TableName:selectedTableName DataArray:nil];
        }
        groupIPArray = nil;
        
    }
    
    asterixPrinterIPArray = nil;
     */
    
}

#pragma mark - update item server type
-(void)updateItemServeType
{
    NSString *itemServeType;
    
    if ([_fromTableDineType isEqualToString:@"0"] && dineType == 1) {
        itemServeType = @"1";
    }
    else if([_fromTableDineType isEqualToString:@"1"] && dineType == 0)
    {
        itemServeType = @"0";
    }
    else
    {
        itemServeType = @"-";
    }
    
    if (![itemServeType isEqualToString:@"-"]) {
        for (int i = 0; i < partialSalesOrderArray.count; i++) {
            NSMutableDictionary *data = [NSMutableDictionary dictionary];
            data = [partialSalesOrderArray objectAtIndex:i];
            [data setValue:itemServeType forKey:@"SOD_TakeAwayYN"];
            [partialSalesOrderArray replaceObjectAtIndex:i withObject:data];
            data = nil;
        }
    }
    
    
}

#pragma mark - star printer kitchen receipt
- (void)PrintStarKitchenReceiptInLineModeWithItemName:(NSString *)itemName OrderQty:(NSString *)orderQty PortName:(NSString *)portName {
    
    p_selectedWidthInch = SMPaperWidth3inchSO;
    p_selectedLanguage = SMLanguageEnglish;
    
    //NSData *[commands = [PrinterFunctions printL]]
    NSData *commands = [PrinterFunctions printKitchenReceiptWithPaperWidth:p_selectedWidthInch language:p_selectedLanguage Item:itemName TableName:selectedTableName Qty:orderQty];
    
    if (commands == nil) {
        return;
    }
    
    printerPortSetting = @"Standard";
    [PrinterFunctions sendCommand:commands
                         portName:portName
                     portSettings:printerPortSetting
                    timeoutMillis:10000];
    
    
}

-(void)PrintStarKitchenReceiptInRasterModeWithItemName:(NSString *)itemName OrderQty:(NSString *)orderQty PortName:(NSString *)portName {
    //InvNo = @"IV000000063";
    p_selectedWidthInch = SMKitchenSingleReceipt;
    p_selectedLanguage = SMLanguageEnglish;
    
    printerPortSetting = @"Standard";
    
    [PrinterFunctions PrintRasterSingleKitchenWithPortname:portName portSettings:printerPortSetting ItemName:itemName TableName:selectedTableName OrderQty:orderQty];
    
}

- (void)PrintStarGroupKitchenReceiptInLineModeWithOrderArray:(NSMutableArray *)orderArray PortName:(NSString *)portName {
    
    p_selectedWidthInch = SMPaperWidth3inchSO;
    p_selectedLanguage = SMLanguageEnglish;
    
    //NSData *[commands = [PrinterFunctions printL]]
    
    NSData *commands = [PrinterFunctions printGroupKitchenReceiptWithPaperWidth:p_selectedWidthInch language:p_selectedLanguage OrderArray:orderArray TableName:selectedTableName];
    
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
    
    [PrinterFunctions PrintRasterGroupKitchenWithPortname:portName portSettings:printerPortSetting OrderDetail:orderArray TableName:selectedTableName];
    
}

#pragma mark - print kitchen receipt
/*
-(void)runTransferPrintFlyTechKitchenReceiptWithIMDesc:(NSString *)imDesc Qty:(NSString *)imQty
{
    [PosApi initPrinter];
    [EposPrintFunction createFlyTechKitchenReceiptWithDBPath:dbPath TableNo:selectedTableName ItemNo:imDesc Qty:imQty];
}
 */

#pragma mark - asterix print kicthen receipt

- (void)runPrintKicthenSequence:(int)indexNo IPAdd:(NSString *)ipAdd
{
    Result *result = nil;
    EposBuilder *builder = nil;
    NSString *errMsg;
    
    result = [[Result alloc] init];
    
    builder = [EposPrintFunction createKitchenReceiptFormat:result TableNo:selectedTableName ItemNo:[[partialSalesOrderArray objectAtIndex:indexNo] objectForKey:@"SOD_ItemDescription"] Qty:[[partialSalesOrderArray objectAtIndex:indexNo] objectForKey:@"SOD_Quantity"] DataArray:nil];
    
    if(result.errType == RESULT_ERR_NONE) {
        [EposPrintFunction print:builder Result:result PortName:ipAdd];
    }
    
    if (builder != nil) {
        [builder clearCommandBuffer];
    }
    
    errMsg = [EposPrintFunction displayMsg:result];
    
    if (errMsg.length > 0) {
        [self showAlertView:errMsg title:@"Warning"];
    }
    
    if(result != nil) {
        result = nil;
    }
    
    return;
}

-(void)makeGroupKitchenReceipt
{
    //NSMutableArray *kitchenGroup = [[NSMutableArray alloc] init];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rsPrinter = [db executeQuery:@"Select * from Printer where P_Type = ?",@"Kitchen"];
        
        while ([rsPrinter next]) {
            //[kitchenGroup removeAllObjects];
            for (int i = 0; i < partialSalesOrderArray.count; i++) {
                FMResultSet *rsItemPrinter = [db executeQuery:@"Select IM_Description, IM_Description2, IM_ItemCode from ItemPrinter IP"
                                              " inner join ItemMast IM on IP.IP_ItemNo = IM.IM_ItemCode where IP.IP_ItemNo = ?"
                                              " and IP.IP_PrinterName = ?",[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"SOD_ItemCode"],[rsPrinter stringForColumn:@"P_PrinterName"]];
                
                if ([rsItemPrinter next]) {
                    NSMutableDictionary *data = [NSMutableDictionary dictionary];
                    [data setObject:[rsItemPrinter stringForColumn:@"IM_ItemCode"] forKey:@"KR_ItemCode"];
                    [data setObject:[rsItemPrinter stringForColumn:@"IM_Description"] forKey:@"KR_Desc"];
                    [data setObject:[rsItemPrinter stringForColumn:@"IM_Description2"] forKey:@"KR_Desc2"];
                    [data setObject:[[partialSalesOrderArray objectAtIndex:i] objectForKey:@"SOD_Quantity"] forKey:@"KR_Qty"];
                    
                    [data setObject:@"RequestPrintKitchenReceipt" forKey:@"IM_Flag"];
                    [data setObject:[rsPrinter stringForColumn:@"P_Brand"] forKey:@"KR_Brand"];
                    [data setObject:[rsPrinter stringForColumn:@"P_PortName"] forKey:@"KR_IpAddress"];
                    [data setObject:[rsPrinter stringForColumn:@"P_Mode"] forKey:@"KR_PrintMode"];
                    [data setObject:selectedTableName forKey:@"KR_TableName"];
                    [data setObject:@"Kitchen" forKey:@"KR_DocType"];
                    [data setObject:@"Non" forKey:@"KR_DocNo"];
                    //[kitchenReceiptArray addObject:data];
                    
                }
                [rsItemPrinter close];
                
                
            }
        
            
        }
        [rsPrinter close];
        
    }];
    
    //kitchenGroup = nil;
    [queue close];
    
}

-(void)runXinYePrinterGroupReceiptWithPort:(NSString *)ipAdd GroupData:(NSMutableArray *)groupData
{
    [self.wifiManager XYDisConnect];
    
    [_wifiManager XYConnectWithHost:ipAdd port:9100 completion:^(BOOL isConnect) {
        if (isConnect) {
            [self sendCommandToXinYePrinterGroupKitchenReceipt:groupData];
        }
    }];
}

-(void)sendCommandToXinYePrinterGroupKitchenReceipt:(NSMutableArray *)groupData
{
    NSMutableData *commands = [NSMutableData data];
    commands = [EposPrintFunction createXinYeKitReceiptGroupWithOrderDetail:groupData TableName:selectedTableName];
    
    NSMutableData* dataM=[NSMutableData dataWithData:[PosCommand initializePrinter]];
    [dataM appendData:commands];
    [self.wifiManager XYWriteCommandWithData:dataM];
    [self.wifiManager XYDisConnect];
}

-(void)runTransferFlyTechKitchenGroupReceiptWithKitchenGroupData:(NSMutableArray *)groupData
{
    [EposPrintFunction createFlyTechKitReceiptGroupWithOrderDetail:groupData TableName:selectedTableName];
}

-(void)runPrintLitchenGroup:(NSString *)portName KitchenGroupData:(NSMutableArray *)groupData
{
    Result *result = nil;
    EposBuilder *builder = nil;
    
    result = [[Result alloc] init];
    
    builder = [EposPrintFunction createKitchenReceiptGroupFormat:result OrderDetail:groupData TableName:selectedTableName];
    
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
    
    
    NSLog(@"XYWIFIManagerDidDisconnected");
    
}

@end
