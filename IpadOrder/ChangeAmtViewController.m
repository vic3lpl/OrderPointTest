//
//  ChangeAmtViewController.m
//  IpadOrder
//
//  Created by IRS on 11/24/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "ChangeAmtViewController.h"
#import "LibraryAPI.h"
#import <FMDB.h>
#import "AppDelegate.h"
#import "PublicSqliteMethod.h"
#import "PublicMethod.h"

@interface ChangeAmtViewController ()
{
    NSString *currencySymbol;
    NSMutableArray *payOrderDetailArray;
    FMDatabase *dbTable;
    int makeXinYeDiscon;
    NSString *dbPath;
    NSOperationQueue *operationQue;
    NSMutableArray *requestServerData;
    MCPeerID *specificPeer;
    NSString *terminalType;
    NSMutableArray *kitchenReceiptArray;
    
    NSMutableArray *printerIpArray;
    NSMutableArray *xinYeConnectionArray;
}
@property (nonatomic, strong) AppDelegate *appDelegate;
-(void)getXinYeCSDetailResultWithNotification:(NSNotification *)notification;
@end

@implementation ChangeAmtViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self wifiManager];
    makeXinYeDiscon = 0;
    
    terminalType = [[LibraryAPI sharedInstance] getWorkMode];
    dbPath = [[LibraryAPI sharedInstance] getDbPath];
    payOrderDetailArray = [[NSMutableArray alloc]init];
    requestServerData = [[NSMutableArray alloc]init];
    kitchenReceiptArray = [[NSMutableArray alloc]init];
    printerIpArray = [[NSMutableArray alloc] init];
    xinYeConnectionArray = [[NSMutableArray alloc] init];
    
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [payOrderDetailArray addObjectsFromArray:[[LibraryAPI sharedInstance]getPayOrderDetailArray]];
    currencySymbol = [[LibraryAPI sharedInstance] getCurrencySymbol];
    self.labelFinalChangeAmt.text = [NSString stringWithFormat:@"%@ %@",currencySymbol, _changeAmt];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(getXinYeCSDetailResultWithNotification:)
                                                 name:@"GetXinYeCSDetailResultWithNotification"
                                               object:nil];
    
    
    //Do any additional setup after loading the view from its nib.
    printerIpArray = [PublicSqliteMethod getAllItemPrinterIpAddWithDBPath:dbPath];
}

-(void)viewWillAppear:(BOOL)animated
{
    operationQue = [NSOperationQueue new];
    
    NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(makeChangeKitchenReceipt) object:nil];
    
    [operationQue addOperation:operation];
    operation = nil;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)btnDone:(id)sender {
    if (_delegate != nil) {
        //[self dismissViewControllerAnimated:NO completion:nil];
        [_delegate CloseFinalChangeAmt];
        //[self.navigationController popViewControllerAnimated:NO];
        
        
    }
}

#pragma mark - WIFIManagerDelegate
/**
 连接上主机
 */

- (XYWIFIManager *)wifiManager
{
    if (!_wifiManager)
    {
        _wifiManager = [XYWIFIManager shareWifiManager];
        _wifiManager.delegate = self;
    }
    return _wifiManager;
}

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

-(void)makeChangeKitchenReceipt
{
    
    int kitchenReceiptType = 0;
    
    kitchenReceiptType = [[LibraryAPI sharedInstance] getKitchenReceiptGrouping];
    NSString *uniID;
    if ([terminalType isEqualToString:@"Main"]) {
        uniID = @"Server";
    }
    else
    {
        uniID = [[LibraryAPI sharedInstance] getTerminalDeviceName];
    }
    
    if (kitchenReceiptType == 0) {
        
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
        
        [queue inDatabase:^(FMDatabase *db) {
            NSString *printStatus;
            for (int i = 0; i < payOrderDetailArray.count; i++) {
                if ([[[payOrderDetailArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"] || [[[payOrderDetailArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"PackageItemOrder"]) {
                    if ([[[payOrderDetailArray objectAtIndex:i] objectForKey:@"IM_Print"] isEqualToString:@"Print"]) {
                        //dbTable = [FMDatabase databaseWithPath:dbPath];
                        makeXinYeDiscon++;
                        
                        FMResultSet *rs = [db executeQuery:@"Select IP_PrinterName, P_Mode, P_Brand, P_PortName from ItemPrinter IP inner join Printer p on IP.IP_PrinterName = P.P_PrinterName where IP.IP_ItemNo = ?",[[payOrderDetailArray objectAtIndex:i] objectForKey:@"IM_ItemCode"]];
                        
                        while ([rs next])
                        {
                            NSMutableDictionary *data = [NSMutableDictionary dictionary];
                            [data setObject:[[payOrderDetailArray objectAtIndex:i] objectForKey:@"IM_ItemCode"] forKey:@"KR_ItemCode"];
                            [data setObject:@"Print" forKey:@"KR_Status"];
                            [data setObject:[[payOrderDetailArray objectAtIndex:i] objectForKey:@"IM_Qty"] forKey:@"KR_Qty"];
                            [data setObject:[[payOrderDetailArray objectAtIndex:i] objectForKey:@"IM_Description"] forKey:@"KR_Desc"];
                            [data setObject:@"RequestPrintKitchenReceipt" forKey:@"IM_Flag"];
                            [data setObject:[rs stringForColumn:@"P_Brand"] forKey:@"KR_Brand"];
                            [data setObject:[rs stringForColumn:@"P_PortName"] forKey:@"KR_IpAddress"];
                            [data setObject:[rs stringForColumn:@"P_Mode"] forKey:@"KR_PrintMode"];
                            [data setObject:_tableName forKey:@"KR_TableName"];
                            [data setObject:@"Kitchen" forKey:@"KR_DocType"];
                            [data setObject:@"Non" forKey:@"KR_DocNo"];
                            
                            [data setObject:[[payOrderDetailArray objectAtIndex:i] objectForKey:@"OrderType"] forKey:@"KR_OrderType"];
                            [data setObject:[NSString stringWithFormat:@"%@-%@",uniID,[[payOrderDetailArray objectAtIndex:i] objectForKey:@"Index"]] forKey:@"KR_ManualID"];
                            [data setObject:[rs stringForColumn:@"IP_PrinterName"] forKey:@"KR_PrinterName"];
                            
                            
                            [kitchenReceiptArray addObject:data];
                            data = nil;
                            
                        }
                        [rs close];
                    }
                    
                }
                else
                {
                    
                    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"Index MATCHES[cd] %@",
                                               [[payOrderDetailArray objectAtIndex:i] objectForKey:@"ParentIndex"]];
                    
                    NSArray *parentObject = [payOrderDetailArray filteredArrayUsingPredicate:predicate1];
                    
                    printStatus = [[parentObject objectAtIndex:0] objectForKey:@"IM_Print"];
                    parentObject = nil;
                    
                    if ([printStatus isEqualToString:@"Print"]) {
                        FMResultSet *rs = [db executeQuery:@"Select IP_PrinterName, P_Mode, P_Brand, P_PortName from ItemPrinter IP inner join Printer p on IP.IP_PrinterName = P.P_PrinterName where IP.IP_ItemNo = ?",[[payOrderDetailArray objectAtIndex:i] objectForKey:@"ItemCode"]];
                        
                        while ([rs next]) {
                            NSMutableDictionary *data = [NSMutableDictionary dictionary];
                            [data setObject:[[payOrderDetailArray objectAtIndex:i] objectForKey:@"ItemCode"] forKey:@"KR_ItemCode"];
                            [data setObject:[[payOrderDetailArray objectAtIndex:i] objectForKey:@"CDDescription"] forKey:@"KR_Desc"];
                            [data setObject:[[payOrderDetailArray objectAtIndex:i] objectForKey:@"CDDescription"] forKey:@"KR_Desc2"];
                            [data setObject:[[payOrderDetailArray objectAtIndex:i] objectForKey:@"UnitQty"] forKey:@"KR_Qty"];
                            
                            [data setObject:@"RequestPrintKitchenReceipt" forKey:@"IM_Flag"];
                            [data setObject:[rs stringForColumn:@"P_Brand"] forKey:@"KR_Brand"];
                            [data setObject:[rs stringForColumn:@"P_PortName"] forKey:@"KR_IpAddress"];
                            [data setObject:[rs stringForColumn:@"P_Mode"] forKey:@"KR_PrintMode"];
                            [data setObject:_tableName forKey:@"KR_TableName"];
                            [data setObject:@"Kitchen" forKey:@"KR_DocType"];
                            [data setObject:@"Non" forKey:@"KR_DocNo"];
                            [data setObject:@"CondimentOrder" forKey:@"KR_OrderType"];
                            [data setObject:[NSString stringWithFormat:@"%@-%@",uniID,[[payOrderDetailArray objectAtIndex:i] objectForKey:@"ParentIndex"]] forKey:@"KR_ManualID"];
                            [data setObject:[rs stringForColumn:@"IP_PrinterName"] forKey:@"KR_PrinterName"];
                            
                            [kitchenReceiptArray addObject:data];
                        }
                        [rs close];
                    }
                    
                }
                
                
            }
            
        }];
        [queue close];
        
        
    }
    else
    {
        [self makeGroupKitchenReceiptWithUUID:uniID];
    }
    
    if ([terminalType isEqualToString:@"Main"]) {
        if (kitchenReceiptArray.count > 0) {
            [[NSNotificationCenter defaultCenter]postNotificationName:@"ServerCallConnectionArrayWithNotification" object:kitchenReceiptArray userInfo:nil];
        }
    }
    else if ([terminalType isEqualToString:@"Terminal"])
    {
        if (kitchenReceiptArray.count > 0) {
            [self sendKitchenDataToServer];
        }
        
    }
    
    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"KR_Brand MATCHES[cd] %@",
                               @"Asterix"];
    
    NSArray *itemOrderObject = [kitchenReceiptArray filteredArrayUsingPredicate:predicate1];
    
    if (itemOrderObject.count > 0) {
        if (kitchenReceiptType == 0) {
            [PublicMethod printAsterixKitchenReceiptWithKitchenData:kitchenReceiptArray];
        }
        else
        {
            [PublicMethod printAsterixKitchenReceiptGroupFormatKitchenData:kitchenReceiptArray];
        }
    }
    itemOrderObject = nil;
    predicate1 = nil;
    
}


#pragma mark - XinYe Printer

-(void)makeGroupKitchenReceiptWithUUID:(NSString *)uuid
{
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        NSString *printStatus;
        FMResultSet *rsPrinter = [db executeQuery:@"Select * from Printer where P_Type = ?",@"Kitchen"];
        [kitchenReceiptArray removeAllObjects];
        while ([rsPrinter next]) {
            
            for (int i = 0; i < payOrderDetailArray.count; i++) {
                if ([[[payOrderDetailArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"] || [[[payOrderDetailArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"PackageItemOrder"])
                {
                    if ([[[payOrderDetailArray objectAtIndex:i] objectForKey:@"IM_Print"] isEqualToString:@"Print"])
                    {
                        FMResultSet *rsItemPrinter = [db executeQuery:@"Select IM_Description, IM_Description2, IM_ItemCode from ItemPrinter IP"
                                                      " inner join ItemMast IM on IP.IP_ItemNo = IM.IM_ItemCode where IP.IP_ItemNo = ?"
                                                      " and IP.IP_PrinterName = ?",[[payOrderDetailArray objectAtIndex:i] objectForKey:@"IM_ItemCode"],[rsPrinter stringForColumn:@"P_PrinterName"]];
                        
                        if ([rsItemPrinter next]) {
                            NSMutableDictionary *data = [NSMutableDictionary dictionary];
                            [data setObject:[rsItemPrinter stringForColumn:@"IM_ItemCode"] forKey:@"KR_ItemCode"];
                            [data setObject:[rsItemPrinter stringForColumn:@"IM_Description"] forKey:@"KR_Desc"];
                            [data setObject:[rsItemPrinter stringForColumn:@"IM_Description2"] forKey:@"KR_Desc2"];
                            [data setObject:[[payOrderDetailArray objectAtIndex:i] objectForKey:@"IM_OrgQty"] forKey:@"KR_Qty"];
                            
                            [data setObject:@"RequestPrintKitchenReceipt" forKey:@"IM_Flag"];
                            [data setObject:[rsPrinter stringForColumn:@"P_Brand"] forKey:@"KR_Brand"];
                            [data setObject:[rsPrinter stringForColumn:@"P_PortName"] forKey:@"KR_IpAddress"];
                            [data setObject:[rsPrinter stringForColumn:@"P_Mode"] forKey:@"KR_PrintMode"];
                            [data setObject:_tableName forKey:@"KR_TableName"];
                            [data setObject:@"Kitchen" forKey:@"KR_DocType"];
                            [data setObject:@"Non" forKey:@"KR_DocNo"];
                            
                            [data setObject:[[payOrderDetailArray objectAtIndex:i] objectForKey:@"OrderType"] forKey:@"KR_OrderType"];
                            [data setObject:[NSString stringWithFormat:@"%@-%@",uuid,[[payOrderDetailArray objectAtIndex:i] objectForKey:@"Index"]] forKey:@"KR_ManualID"];
                            [data setObject:[rsPrinter stringForColumn:@"P_PrinterName"] forKey:@"KR_PrinterName"];
                            
                            [kitchenReceiptArray addObject:data];
                        }
                        [rsItemPrinter close];
                    }

                }
                else
                {
                    
                    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"Index MATCHES[cd] %@",
                                               [[payOrderDetailArray objectAtIndex:i] objectForKey:@"ParentIndex"]];
                    
                    NSArray *parentObject = [payOrderDetailArray filteredArrayUsingPredicate:predicate1];
                    
                    printStatus = [[parentObject objectAtIndex:0] objectForKey:@"IM_Print"];
                    parentObject = nil;
                    
                    if ([printStatus isEqualToString:@"Print"])
                    {
                        FMResultSet *rsItemPrinter = [db executeQuery:@"Select IM_Description, IM_Description2, IM_ItemCode from ItemPrinter IP"
                                                      " inner join ItemMast IM on IP.IP_ItemNo = IM.IM_ItemCode where IP.IP_ItemNo = ?"
                                                      " and IP.IP_PrinterName = ?",[[payOrderDetailArray objectAtIndex:i] objectForKey:@"ItemCode"],[rsPrinter stringForColumn:@"P_PrinterName"]];
                        
                        if ([rsItemPrinter next]) {
                            NSMutableDictionary *data = [NSMutableDictionary dictionary];
                            [data setObject:[[payOrderDetailArray objectAtIndex:i] objectForKey:@"ItemCode"] forKey:@"KR_ItemCode"];
                            [data setObject:[[payOrderDetailArray objectAtIndex:i] objectForKey:@"CDDescription"] forKey:@"KR_Desc"];
                            [data setObject:[[payOrderDetailArray objectAtIndex:i] objectForKey:@"CDDescription"] forKey:@"KR_Desc2"];
                            [data setObject:[[payOrderDetailArray objectAtIndex:i] objectForKey:@"UnitQty"] forKey:@"KR_Qty"];
                            
                            [data setObject:@"RequestPrintKitchenReceipt" forKey:@"IM_Flag"];
                            [data setObject:[rsPrinter stringForColumn:@"P_Brand"] forKey:@"KR_Brand"];
                            [data setObject:[rsPrinter stringForColumn:@"P_PortName"] forKey:@"KR_IpAddress"];
                            [data setObject:[rsPrinter stringForColumn:@"P_Mode"] forKey:@"KR_PrintMode"];
                            [data setObject:_tableName forKey:@"KR_TableName"];
                            [data setObject:@"Kitchen" forKey:@"KR_DocType"];
                            [data setObject:@"Non" forKey:@"KR_DocNo"];
                            [data setObject:@"CondimentOrder" forKey:@"KR_OrderType"];
                            [data setObject:[NSString stringWithFormat:@"%@-%@",uuid,[[payOrderDetailArray objectAtIndex:i] objectForKey:@"ParentIndex"]] forKey:@"KR_ManualID"];
                            [data setObject:[rsPrinter stringForColumn:@"P_PrinterName"] forKey:@"KR_PrinterName"];
                            
                            [kitchenReceiptArray addObject:data];
                        }
                        [rsItemPrinter close];
                    }
                    
                    
                }
                                //NSLog(@"%@",[rsPrinter stringForColumn:@"P_PortName"]);
                
            }
            
        }
        [rsPrinter close];
        
    }];
    
    [queue close];
    
}

/*
-(void)sendCommandToXinYePrinterKitchenWhenPayWithIMDesc:(NSString *)imDesc Qty:(NSString *)imQty IPAdd:(NSString *)ipAdd DetectLastItem:(long)indexNo
{
    NSMutableData *commands = [NSMutableData data];
    //if ([_terminalType isEqualToString:@"Main"]) {
    commands = [EposPrintFunction createXinYeKitchenReceiptWithDBPath:dbPath TableNo:_tableName ItemNo:imDesc Qty:imQty DataArray:nil];
    
    NSMutableData* dataM=[NSMutableData dataWithData:[PosCommand initializePrinter]];
    [dataM appendData:commands];
    [self.wifiManager XYWriteCommandWithData:dataM];
    //[self.wifiManager XYClearBuffer];
}
 */

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
    /*
    NSMutableData *commands = [NSMutableData data];
    
    commands = [EposPrintFunction createXinYeKitReceiptGroupWithOrderDetail:kitchenReceiptArray TableName:_tableName];
    
    NSMutableData* dataM=[NSMutableData dataWithData:[PosCommand initializePrinter]];
    [dataM appendData:commands];
    [self.wifiManager XYWriteCommandWithData:dataM];
     */
    
}

#pragma mark - asterix print kitchen
/*
- (void)runPrintKicthenSequence:(int)indexNo IPAdd:(NSString *)ipAdd
{
    Result *result = nil;
    EposBuilder *builder = nil;
    NSString *errMsg;
    
    result = [[Result alloc] init];
    
    builder = [EposPrintFunction createKitchenReceiptFormat:result TableNo:_tableName ItemNo:[[payOrderDetailArray objectAtIndex:indexNo] objectForKey:@"IM_Description"] Qty:[[payOrderDetailArray objectAtIndex:indexNo] objectForKey:@"IM_Qty"]];
    
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
*/
-(void)getXinYeCSDetailResultWithNotification:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
    NSMutableArray *paySO;
    paySO = [[NSMutableArray alloc] init];
    //paySO = [notification object];
    [paySO addObject:[notification object]];
    
    [self printReceiptOnXinYePrinterWithArray:[paySO objectAtIndex:0]];
    });
}

-(void)printReceiptOnXinYePrinterWithArray:(NSMutableArray *)array
{
    if (![terminalType isEqualToString:@"Main"]) {
        //[self.wifiManager XYDisConnect];
        
        [_wifiManager XYConnectWithHost:_receiptPrinterIpAdd port:9100 completion:^(BOOL isConnect) {
            if (isConnect) {
                [self sendCommandToXinYePrinterWithArray:array];
            }
        }];
    }
    
    
}

-(void)sendCommandToXinYePrinterWithArray:(NSMutableArray *)array
{
    NSMutableData *commands = [NSMutableData data];
    if (![terminalType isEqualToString:@"Main"]) {
        commands = [EposPrintFunction generateReceiptFormatWithDBPath:dbPath GetInvNo:_csNo EnableGst:[[LibraryAPI sharedInstance] getEnableGst] KickOutDrawerYN:@"Y" PrinterBrand:@"XinYe" ReceiptLength:48 DataArray:array];
        
        NSMutableData* dataM=[NSMutableData dataWithData:[PosCommand initializePrinter]];
        [dataM appendData:commands];
        [self.wifiManager XYWriteCommandWithData:dataM];
        
    }
    
}


-(void)sendKitchenDataToServer
{
    //if ([_printerBrand isEqualToString:@"XinYe"]) {
    
        NSData *dataToBeSend = [NSKeyedArchiver archivedDataWithRootObject:kitchenReceiptArray];
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
    //}
    
}

#pragma mark - alertView

-(void)showAlertView:(NSString *)msg title:(NSString *)title
{
    
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
@end
