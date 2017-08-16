//
//  BillListingViewController.m
//  IpadOrder
//
//  Created by IRS on 04/05/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import "BillListingViewController.h"
#import "LibraryAPI.h"
#import <FMDB.h>
#import "BillListingTableViewCell.h"
#import "ePOS-Print.h"
#import "Result.h"
#import "MsgMaker.h"
#import "EposPrintFunction.h"
#import "PrinterFunctions.h"
#import <StarIO/SMPort.h>
#import <StarIO/SMBluetoothManager.h>
#import "TerminalData.h"
#import "PublicMethod.h"
#import "PublicSqliteMethod.h"

@interface BillListingViewController ()
{
    NSString *dbPath;
    FMDatabase *dbTable;
    NSMutableArray *billListArray;
    NSString *docNo;
    NSString *printerBrand;
    NSString *printerName;
    SMLanguage p_selectedLanguage;
    SMPaperWidth p_selectedWidthInch;
    NSString *printerMode;
    NSString *printerPortSetting;
    NSString *terminalType;
    NSMutableArray *printSOArray;
    NSMutableArray *requestServerData;
    MCPeerID *specificPeer;
    int enableGST;
    NSMutableArray *receiptDataArray;
    NSUInteger userReprintBillPermission;
}
@property (nonatomic, strong) AppDelegate *appDelegate;
-(void)getSOListingResultWithNotification:(NSNotification *)notification;
-(void)getXinYeReprintCSDetailResultWithNotification:(NSNotification *)notification;
-(void)printAsterixReprintPayBillDtlWithNotification:(NSNotification *)notification;
@end

@implementation BillListingViewController

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
    self.navigationController.navigationBar.hidden = NO;
    self.preferredContentSize = CGSizeMake(307, 459);
    
    dbPath = [[LibraryAPI sharedInstance] getDbPath];
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    billListArray = [[NSMutableArray alloc] init];
    requestServerData = [[NSMutableArray alloc]init];
    receiptDataArray = [[NSMutableArray alloc] init];
    
    enableGST = [[LibraryAPI sharedInstance] getEnableGst];
    
    self.searchBarForBillListing.delegate = self;
    self.searchBarForBillListing.placeholder = @"Document No / Table No";
    self.tableViewBillListing.delegate = self;
    self.tableViewBillListing.dataSource = self;
    [self.searchBarForBillListing becomeFirstResponder];
    terminalType = [[LibraryAPI sharedInstance]
                    getWorkMode];
    printSOArray = [[NSMutableArray alloc] init];
    
    [self.btnPrint addTarget:self action:@selector(btnClickPrintSelectedDoc:) forControlEvents:UIControlEventTouchUpInside];
    [self.btnClose addTarget:self action:@selector(closeBillListingView) forControlEvents:UIControlEventTouchUpInside];
    
    UINib *nib = [UINib nibWithNibName:@"BillListingTableViewCell" bundle:nil];
    [self.tableViewBillListing registerNib:nib forCellReuseIdentifier:@"BillListingTableViewCell"];
    
    self.tableViewBillListing.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(getSOListingResultWithNotification:)
                                                 name:@"GetSOListingResultWithNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(getXinYeReprintCSDetailResultWithNotification:)
                                                 name:@"GetXinYeReprintCSDetailResultWithNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(printAsterixReprintPayBillDtlWithNotification:)
                                                 name:@"PrintAsterixReprintPayBillDtlWithNotification"
                                               object:nil];
    
    
    if ([terminalType isEqualToString:@"Main"]) {
        [self getLimitedData];
    }
    else
    {
        [self requestServerSendBackFindBillResultWithKeyWord:@"%"];
    }
    
}

-(void)viewWillAppear:(BOOL)animated
{
    //[PosApi setDelegate:self];
    if ([[[LibraryAPI sharedInstance] getPrinterBrand] isEqualToString:@"FlyTech"] && [[[LibraryAPI sharedInstance] getWorkMode] isEqualToString:@"Main"])
    {
        [PosApi setDelegate: self];
        
    }
    [self wifiManager];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - sqlite

-(void)getLimitedData
{
    dbTable = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTable open]) {
        NSLog(@"Fail To Open");
        return;
    }
    [billListArray removeAllObjects];
    FMResultSet *rs = [dbTable executeQuery:@"select * from (Select IvH_DocNo,IvH_DocAmt, IvH_Date, IvH_Status, (IvH_DocNo || IvH_Table) as FilterColumn from InvoiceHdr order by IvH_DocNo desc limit 100) Tb1 where FilterColumn like ?", [NSString stringWithFormat:@"%@%@%@",@"%",self.searchBarForBillListing.text,@"%"]];
    
    while ([rs next]) {
        [billListArray addObject:[rs resultDictionary]];
    }
    
    [rs close];
    [dbTable close];
    
    [self.tableViewBillListing reloadData];
}


#pragma mark - tableview

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return billListArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BillListingTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BillListingTableViewCell"];
    
    cell.labelDocNo.text = [[billListArray objectAtIndex:indexPath.row] objectForKey:@"IvH_DocNo"];
    cell.labelDocAmt.text = [NSString stringWithFormat:@"%@ %0.2f",[[LibraryAPI sharedInstance] getCurrencySymbol],[[[billListArray objectAtIndex:indexPath.row] objectForKey:@"IvH_DocAmt"] doubleValue]];
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *date = [dateFormat dateFromString:[[billListArray objectAtIndex:indexPath.row] objectForKey:@"IvH_Date"]];
    [dateFormat setDateFormat:@"dd-MMM-yyyy"];
    NSString *dateString = [dateFormat stringFromDate:date];
    
    cell.labelStatus.text = dateString;
    /*
    if ([[[billListArray objectAtIndex:indexPath.row] objectForKey:@"IvH_Status"] isEqualToString:@"Pay"]) {
        cell.labelStatus.text = @"PAIDED";
        cell.labelStatus.textColor = [UIColor redColor];
    }
    else if([[[billListArray objectAtIndex:indexPath.row] objectForKey:@"IvH_Status"] isEqualToString:@"New"])
    {
        cell.labelStatus.text = @"OPEN";
        cell.labelStatus.textColor = [UIColor blackColor];
    }
    else if ([[[billListArray objectAtIndex:indexPath.row] objectForKey:@"IvH_Status"] isEqualToString:@"Void"])
    {
        cell.labelStatus.text = @"VOIDED";
        cell.labelStatus.textColor = [UIColor redColor];
    }
     */
    //cell.labelStatus.text = [[billListArray objectAtIndex:indexPath.row] objectForKey:@"SOH_Status"];
    
    return  cell;
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    docNo = [[billListArray objectAtIndex:indexPath.row] objectForKey:@"IvH_DocNo"];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
}

#pragma mark - search bar delegate
-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    
    [searchBar setShowsCancelButton:YES animated:NO];
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.searchBarForBillListing.text = @"";
    //isFiltered = @"False";
    [[self view] endEditing:YES];
    [self getLimitedData];
    //[self filterItemMast: [NSString stringWithFormat:@"'%@'",@"%"]];
    
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if ([terminalType isEqualToString:@"Main"]) {
        [self getLimitedData];
    }
    else
    {
        [self requestServerSendBackFindBillResultWithKeyWord:searchText];
    }
    
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)btnClickPrintSelectedDoc:(id)sender {
    
    if ([docNo length] == 0) {
        [self showAlertMsgWithMessage:@"Please select document" Title:@"Warning"];
        return;
    }
    [printSOArray removeAllObjects];
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rsUser = [db executeQuery:@"Select * from UserLogin where UL_ID = ?",[[LibraryAPI sharedInstance] getUserName]];
        
        if ([rsUser next]) {
            userReprintBillPermission = [rsUser intForColumn:@"UL_ReprintBillPermission"];
        }
        else
        {
            userReprintBillPermission = 1;
        }
        [rsUser close];
        
        FMResultSet *rs = [db executeQuery:@"Select * from Printer where P_Type = ?",@"Receipt"];
        
        if ([rs next]) {
            printerBrand = [rs stringForColumn:@"P_Brand"];
            printerMode = [rs stringForColumn:@"P_Mode"];
            printerName = [rs stringForColumn:@"P_PrinterName"];
            [printSOArray addObject:[rs resultDictionary]];
        }
        else
        {
            [self showAlertMsgWithMessage:@"Receipt printer not found" Title:@"Information"];
            return;
        }
        
        [rs close];
    }];
    [queue close];
    
    
    if (userReprintBillPermission == 1) {
        [self showAlertMsgWithMessage:@"You have no permission to print" Title:@"Warning"];
        return;
    }
    
    if ([printerBrand isEqualToString:@"Asterix"])
    {
        if ([[[LibraryAPI sharedInstance] getWorkMode] isEqualToString:@"Main"])
        {
            
            NSMutableArray *compData = [[NSMutableArray alloc] init];
            NSMutableArray *receiptData = [[NSMutableArray alloc] init];
            
            receiptData = [PublicSqliteMethod getAsterixCashSalesDetailWithDBPath:dbPath CashSalesNo:docNo ViewName:@"ReprintBillView"];
            
            [compData addObject:[receiptData objectAtIndex:0]];
            [receiptData removeObjectAtIndex:0];
            
            [PublicMethod printAsterixReceiptWithIpAdd:[[printSOArray objectAtIndex:0] objectForKey:@"P_PortName"] CompanyArray:compData CSArray:receiptData];
            
            compData = nil;
            receiptData = nil;
        }
        else
        {
            [self requestAsterixPrintInvoiceFromServer];
        }
    }
    else
    {
        if (printSOArray.count > 0) {
            [self makePrinterReceiptWithIpAdd:[[printSOArray objectAtIndex:0] objectForKey:@"P_PortName"]];
        }
    }
    
     
}

-(void)requestAsterixPrintInvoiceFromServer
{
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [requestServerData removeAllObjects];
    [data setObject:@"Request" forKey:@"Result"];
    [data setObject:@"-" forKey:@"Message"];
    [data setObject:@"RequestPrintAsterixInvoice" forKey:@"IM_Flag"];
    [data setObject:docNo forKey:@"Inv_DocNo"];
    [data setObject:[[printSOArray objectAtIndex:0] objectForKey:@"P_PortName"] forKey:@"P_PortName"];
    [data setObject:[NSString stringWithFormat:@"%d", 1] forKey:@"EnableGst"];
    [data setObject:@"Y" forKey:@"P_KickDrawer"];
    [data setObject:@"ReprintBillView" forKey:@"ViewName"];
    
    
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


-(void)closeBillListingView
{
    receiptDataArray = nil;
    [self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark - print receipt

-(void)makeFlyTechPrinterReceipt
{
    if ([terminalType isEqualToString:@"Main"]) {
        //[PosApi initPrinter];
        //[EposPrintFunction createFlyTechReceiptWithDBPath:dbPath GetInvNo:docNo EnableGst:enableGST KickOutDrawerYN:@"N"];
    }
    else
    {
        //[TerminalData flyTechRequestCSDataWithCSNo:docNo];
    }
}

-(void)makeEposSalesOrderReceipt
{
    NSString *printErrorMsg;
    if ([terminalType isEqualToString:@"Main"]) {
        Result *result = nil;
        EposBuilder *builder = nil;
        
        result = [[Result alloc] init];
        
        //builder = [EposPrintFunction createSalesOrderRceiptData:result DBPath:dbPath GetInvNo:docNo EnableGst:enableGST];
        
        //builder = [EposPrintFunction createReceiptData:result DBPath:dbPath GetInvNo:docNo EnableGst:enableGST KickOutDrawerYN:@"N"];
        
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
            //[self showAlertView:printErrorMsg title:@"Warning"];
            [self showAlertMsgWithMessage:printErrorMsg Title:@"Warning"];
        }
        
        if(result != nil) {
            result = nil;
        }
        printSOArray = nil;
    }
    else
    {
        //[self requestAsterixPrintSalesOrderFromServer];
        NSString *printResult;
        printResult = [TerminalData asterixRequestServerToPrintTerminalReqWithCSNo:docNo PortName:[[printSOArray objectAtIndex:0] objectForKey:@"P_PortName"]];
        
        if (![printResult isEqualToString:@"Success"]) {
            [self showAlertMsgWithMessage:printResult Title:@"Warning"];
        }
        printResult = nil;
    }
    
}

-(void)PrintSOReceiptInRasterMode {
    //InvNo = @"IV000000063";
    //p_selectedWidthInch = SMPaperWidth3inchSO;
    p_selectedWidthInch = SMPaperWidth3inch;
    p_selectedLanguage = SMLanguageEnglish;
    
    printerPortSetting = @"Standard";
    
    if ([terminalType isEqualToString:@"Main"]) {
        //[PrinterFunctions PrintRasterSampleReceiptWithPortname:[[printSOArray objectAtIndex:0] objectForKey:@"P_PortName"] portSettings:printerPortSetting paperWidth:p_selectedWidthInch Language:p_selectedLanguage invDocno:docNo EnableGst:enableGST];
        
        [PrinterFunctions PrintRasterSampleReceiptWithPortname:[[printSOArray objectAtIndex:0] objectForKey:@"P_PortName"] portSettings:printerPortSetting paperWidth:p_selectedWidthInch Language:p_selectedLanguage invDocno:docNo EnableGst:enableGST KickOutDrawer:NO];
    }
    else
    {
        //[self requestStarRasterPrintSalesOrderFromServer];
        NSString *printResult;
        printResult = [TerminalData startRasterRequestServerToPrintTerminalReqWithSONo:docNo PortName:[[printSOArray objectAtIndex:0] objectForKey:@"P_PortName"] PrinterSetting:printerPortSetting EnableGst:enableGST];
        
        if (![printResult isEqualToString:@"Success"]) {
            [self showAlertMsgWithMessage:printResult Title:@"Warning"];
        }
        printResult = nil;
    }
    
    
    
}

- (void)printSOReceiptInLineMode {
    
    
    p_selectedWidthInch = SMPaperWidth3inch;
    p_selectedLanguage = SMLanguageEnglish;
    printerPortSetting = @"Standard";
    
    if ([terminalType isEqualToString:@"Main"]) {
        NSData *commands = [PrinterFunctions sampleReceiptWithPaperWidth:p_selectedWidthInch
                                                                language:p_selectedLanguage
                                                              kickDrawer:NO invDocNo:docNo docType:@"CS" EnableGST:enableGST];
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
        //[self requestStarLinePringetSalesOrderFromServer];
        NSString *printResult;
        printResult = [TerminalData startLineRequestServerToPrintTerminalReqWithCSNo:docNo PortName:[[printSOArray objectAtIndex:0] objectForKey:@"P_PortName"] PrinterSetting:printerPortSetting EnableGst:enableGST];
        
        if (![printResult isEqualToString:@"Success"]) {
            [self showAlertMsgWithMessage:printResult
                                    Title:@"Warning"];
        }
        printResult = nil;
    }
    
}

-(void)makePrinterReceiptWithIpAdd:(NSString *)ip
{
    [receiptDataArray removeAllObjects];
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data setObject:@"Doc" forKey:@"KR_ItemCode"];
    [data setObject:@"Print" forKey:@"KR_Status"];
    [data setObject:@"0" forKey:@"KR_Qty"];
    [data setObject:@"Doc" forKey:@"KR_Desc"];
    [data setObject:@"RequestPrintKitchenReceipt" forKey:@"IM_Flag"];
    [data setObject:printerBrand forKey:@"KR_Brand"];
    [data setObject:ip forKey:@"KR_IpAddress"];
    [data setObject:printerMode forKey:@"KR_PrintMode"];
    [data setObject:@"Doc" forKey:@"KR_TableName"];
    [data setObject:@"ReprintReceipt" forKey:@"KR_DocType"];
    [data setObject:docNo forKey:@"KR_DocNo"];
    [data setObject:printerName forKey:@"KR_PrinterName"];
    
    [receiptDataArray addObject:data];
    data = nil;
    if ([terminalType isEqualToString:@"Main"]) {
        [[NSNotificationCenter defaultCenter]postNotificationName:@"ServerCallConnectionArrayWithNotification" object:receiptDataArray userInfo:nil];
        
        
    }
    else
    {
        //[self xinYeRequestCSDetailFromServer];
        
        NSString *printResult;
        printResult = [TerminalData xinYeRequestServerToPrintTerminalReqWithReceiptArray:receiptDataArray];
        
        if (![printResult isEqualToString:@"Success"]) {
            [self showAlertMsgWithMessage:printResult Title:@"Warning"];
        }
        printResult = nil;
        
    }
    
}

-(void)sendCommandToXinYePrinterWithDataArray:(NSMutableArray *)array
{
    
    if ([terminalType isEqualToString:@"Main"]) {
        NSMutableData *commands = [NSMutableData data];
        commands = [EposPrintFunction generateReceiptFormatWithDBPath:dbPath GetInvNo:docNo EnableGst:enableGST KickOutDrawerYN:@"N" PrinterBrand:@"XinYe" ReceiptLength:48 DataArray:nil];
        
        NSMutableData* dataM=[NSMutableData dataWithData:[PosCommand initializePrinter]];
        [dataM appendData:commands];
        [self.wifiManager XYWriteCommandWithData:dataM];
        
        
    }
    else
    {
        [self.wifiManager XYDisConnect];
        
        [_wifiManager XYConnectWithHost:[[printSOArray objectAtIndex:0] objectForKey:@"P_PortName"] port:9100 completion:^(BOOL isConnect) {
            if (isConnect) {
                [self sendCommandToXinYePrinterWithArray:array];
            }
        }];
    }
}

-(void)sendCommandToXinYePrinterWithArray:(NSMutableArray *)array
{
    NSMutableData *commands = [NSMutableData data];
    commands = [EposPrintFunction generateReceiptFormatWithDBPath:dbPath GetInvNo:docNo EnableGst:enableGST KickOutDrawerYN:@"N" PrinterBrand:@"XinYe" ReceiptLength:48 DataArray:array];
        
    NSMutableData* dataM=[NSMutableData dataWithData:[PosCommand initializePrinter]];
    [dataM appendData:commands];
    [self.wifiManager XYWriteCommandWithData:dataM];
    
}

-(void)xinYeRequestCSDetailFromServer
{
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [requestServerData removeAllObjects];
    [data setObject:@"Request" forKey:@"Result"];
    [data setObject:@"-" forKey:@"Message"];
    [data setObject:@"XinYeTerminalPrinterCsDetail" forKey:@"IM_Flag"];
    [data setObject:docNo forKey:@"DocNo"];
    [data setObject:@"XinYeTerminalReprintCSDetail" forKey:@"From"];
    
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

-(void)getXinYeReprintCSDetailResultWithNotification:(NSNotification *)notification
{
    //dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableArray *reprintCS;
        reprintCS = [[NSMutableArray alloc] init];
        [reprintCS addObject:[notification object]];
        
        [self sendCommandToXinYePrinterWithDataArray:[reprintCS objectAtIndex:0]];
    //});
}


#pragma mark - multipeer data transfer
-(void)getSOListingResultWithNotification:(NSNotification *)notification
{
    [billListArray removeAllObjects];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSArray *serverFilterResult;
        serverFilterResult = [notification object];
    
        [billListArray addObjectsFromArray:serverFilterResult];
        serverFilterResult = nil;
        [self.tableViewBillListing reloadData];
    });
}

-(void)printAsterixReprintPayBillDtlWithNotification:(NSNotification *)notification
{
    NSMutableArray *compData = [[NSMutableArray alloc] init];
    
    NSMutableArray *receiptData = [[NSMutableArray alloc] init];
    receiptData = [notification object];
    [compData addObject:[receiptData objectAtIndex:0]];
    [receiptData removeObjectAtIndex:0];
    
    [PublicMethod printAsterixReceiptWithIpAdd:[[printSOArray objectAtIndex:0] objectForKey:@"P_PortName"] CompanyArray:compData CSArray:receiptData];
    
    compData = nil;
    receiptData = nil;
}

-(void)requestServerSendBackFindBillResultWithKeyWord:(NSString *)keyWord
{
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [requestServerData removeAllObjects];
    [data setObject:@"Request" forKey:@"Result"];
    [data setObject:@"-" forKey:@"Message"];
    [data setObject:@"RequestFindBillWithKeyWord" forKey:@"IM_Flag"];
    [data setObject:keyWord forKey:@"KeyWord"];
    
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
    
    
    //[self showAlertMsgWithMessage:@"XP900 has been disconnect." Title:@"Warning"];
    NSLog(@"XYWIFIManagerDidDisconnected");
    
}


#pragma mark - show alertbox
-(void)showAlertMsgWithMessage:(NSString *)message Title:(NSString *)title
{
    UIAlertController * alert = [[LibraryAPI sharedInstance] showAlertViewWithMsg:message Title:title];
    
    [self presentViewController:alert animated:YES completion:nil];
    
    alert = nil;
    
    /*
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
     */
    
}
@end
