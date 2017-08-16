//
//  DailyCollectionViewController.m
//  IpadOrder
//
//  Created by IRS on 10/27/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "DailyCollectionViewController.h"
#import "ePOS-Print.h"
#import "Result.h"
#import "MsgMaker.h"
#import "EposPrintFunction.h"
#import "LibraryAPI.h"
#import <FMDB.h>
#import "PrinterFunctions.h"
#import <StarIO/SMPort.h>
#import <StarIO/SMBluetoothManager.h>

@interface DailyCollectionViewController ()
{
    NSString *dbPath;
    NSMutableArray *printerArray;
    NSString *printerMode;
    NSString *printerBrand;
    NSString *printerPortSetting;
    FMDatabase *dbTable;
    NSString *dateString1;
    NSString *dateString2;
}
//@property (nonatomic,strong)UIPopoverController *popOverDate;
@end

@implementation DailyCollectionViewController

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
    self.textDailyDateFrom.delegate = self;
    self.textDailyDateTo.delegate = self;
    [self wifiManager];
    printerArray = [[NSMutableArray alloc]init];
    
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc]init];
    [dateFormat setDateFormat:@"dd/MMM/yyyy"];
    dateString1 = [dateFormat stringFromDate:today];
    self.textDailyDateFrom.text = dateString1;
    
    [dateFormat setDateFormat:@"dd/MMM/yyyy"];
    dateString2 = [dateFormat stringFromDate:today];
    self.textDailyDateTo.text = dateString2;
    
    dbPath = [[LibraryAPI sharedInstance] getDbPath];
    
    [self setTitle:@"Daily Collection"];
    
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    
    
    //self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:34/255.0 green:171/255.0 blue:241/255.0 alpha:1.0];
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.translucent = NO;
    
    self.viewRptDailyCollectionBg.layer.cornerRadius = 10.0;
    self.viewRptDailyCollectionBg.layer.masksToBounds = YES;
    
    [self getReceiptPrinterData];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - text editing
-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    DatePickerViewController *datePickerViewController = [[DatePickerViewController alloc]init];
    datePickerViewController.delegate = self;
    //self.popOverDate = [[UIPopoverController alloc]initWithContentViewController:datePickerViewController];
    
    if (textField.tag == 0) {
        [self.view endEditing:YES];
        datePickerViewController.textType = @"XDate1";
        
        datePickerViewController.modalPresentationStyle = UIModalPresentationPopover;
        datePickerViewController.popoverPresentationController.sourceRect = CGRectMake(self.textDailyDateFrom.frame.size.width /
                                                                                       2, self.textDailyDateFrom.frame.size.height / 2, 1, 1);
        datePickerViewController.popoverPresentationController.sourceView = self.textDailyDateFrom;
        datePickerViewController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionLeft;
        
        [self presentViewController:datePickerViewController animated:YES completion:nil];
        
        /*
        [self.popOverDate presentPopoverFromRect:CGRectMake(self.textDailyDateFrom.frame.size.width /
                                                            2, self.textDailyDateFrom.frame.size.height / 2, 1, 1) inView:self.textDailyDateFrom permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
         */
    }
    else if (textField.tag == 1)
    {
        [self.view endEditing:YES];
        datePickerViewController.textType = @"XDate2";
        
        datePickerViewController.modalPresentationStyle = UIModalPresentationPopover;
        datePickerViewController.popoverPresentationController.sourceRect = CGRectMake(self.textDailyDateTo.frame.size.width /
                                                                                       2, self.textDailyDateTo.frame.size.height / 2, 1, 1);
        datePickerViewController.popoverPresentationController.sourceView = self.textDailyDateTo;
        datePickerViewController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionLeft;
        
        [self presentViewController:datePickerViewController animated:YES completion:nil];
        
        /*
        [self.popOverDate presentPopoverFromRect:CGRectMake(self.textDailyDateTo.frame.size.width /
                                                            2, self.textDailyDateTo.frame.size.height / 2, 1, 1) inView:self.textDailyDateTo permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
         */
    }
    else
    {
        [self.view endEditing:NO];
    }
    
    return NO;
    
}

#pragma mark - delegate methof

-(void)getDatePickerDateValue:(NSString *)dateValue returnTextName:(NSString *)textName
{
    if ([textName isEqualToString:@"XDate1"]) {
        self.textDailyDateFrom.text = dateValue;
    }
    else if ([textName isEqualToString:@"XDate2"])
    {
        self.textDailyDateTo.text = dateValue;
    }
    
    //[self.popOverDate dismissPopoverAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - get receipt printer

-(void)getReceiptPrinterData
{
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    [queue inDatabase:^(FMDatabase *db) {
        [printerArray removeAllObjects];
        FMResultSet *rs = [db executeQuery:@"Select * from Printer where P_Type = ?",@"Receipt"];
        
        while ([rs next]) {
            printerMode = [rs stringForColumn:@"P_Mode"];
            printerBrand = [rs stringForColumn:@"P_Brand"];
            [printerArray addObject:[rs resultDictionary]];
        }
        
        [rs close];
    }];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)btnDailySearch:(id)sender {
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"dd/MMM/yyyy"];
    NSDate *dateFrom = [dateFormat dateFromString:self.textDailyDateFrom.text];
    NSDate *dateTo = [dateFormat dateFromString:self.textDailyDateTo.text];
    
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    dateString1 = [dateFormat stringFromDate:dateFrom];
    dateString2 = [dateFormat stringFromDate:dateTo];
    
    dbTable = [FMDatabase databaseWithPath:dbPath];
    //BOOL dbHadError;
    if (![dbTable open]) {
        NSLog(@"Fail To Open");
        return;
    }
    NSLog(@"%@",self.textDailyDateFrom.text);
    FMResultSet *rs = [dbTable executeQuery:@"select count(*) qty, IvH_PaymentType1 as Type, sum(IvH_PaymentAmt1) Amt from InvoiceHdr where date(IvH_Date) between date(?) and date(?) group by Ivh_PaymentType1 "
                       ,dateString1,dateString2];
    
    if ([rs next]) {
        [rs close];
        if ([printerBrand isEqualToString:@"Star"]) {
            if ([printerMode isEqualToString:@"Line"]) {
                [self printDailyCollectionReceiptInLineMode];
            }
            else if ([printerMode isEqualToString:@"Raster"])
            {
                [self PrintDailyCollectionReceiptInRasterMode];
            }
        }
        else if ([printerBrand isEqualToString:@"Asterix"])
        {
            [self printAsterixDailyCollection];
        }
        else if ([printerBrand isEqualToString:@"FlyTech"])
        {
            [self printFlyTechDailyCollection];
        }
        else if ([printerBrand isEqualToString:@"XinYe"])
        {
            [self connectXinYePrinter];
        }
    }
    else
    {
        [rs close];
        
        UIAlertController * alert = [[LibraryAPI sharedInstance] showAlertViewWithMsg:@"No record found" Title:@"Warning"];
        
        [self presentViewController:alert animated:YES completion:nil];
        
        alert = nil;
        /*
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"No Receord Found." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
         */
    }
    
    [dbTable close];
    
}

#pragma mark - print daily collection

-(void)PrintDailyCollectionReceiptInRasterMode {
    
    printerPortSetting = @"Standard";
    
    [PrinterFunctions PrintRasterDailyCollectionWithPortName:[[printerArray objectAtIndex:0] objectForKey:@"P_PortName"] portSettings:printerPortSetting dateFrom:dateString1 dateTo:dateString2];
}

- (void)printDailyCollectionReceiptInLineMode {
    
    NSData *commands = [PrinterFunctions PrinLineCollectionLineWithDocType:@"Daily" DateFrom:dateString1 DateTo:dateString2];
    
    if (commands == nil) {
        return;
    }
    
    printerPortSetting = @"Standard";
    [PrinterFunctions sendCommand:commands
                         portName:[[printerArray objectAtIndex:0] objectForKey:@"P_PortName"]
                     portSettings:printerPortSetting
                    timeoutMillis:10000];
}


-(void)printAsterixDailyCollection
{
    Result *result = nil;
    EposBuilder *builder = nil;
    
    result = [[Result alloc] init];
    
    builder = [EposPrintFunction createDailyCollectionData:result DBPath:dbPath DateFrom:dateString1 DateTo:dateString2];
    
    if(result.errType == RESULT_ERR_NONE) {
        [EposPrintFunction print:builder
                          Result:result PortName:[[printerArray objectAtIndex:0] objectForKey:@"P_PortName"]];
    }
    
    if(builder != nil) {
        [builder clearCommandBuffer];
        
        //[builder release];
    }
    
    [EposPrintFunction displayMsg:result];
    
    if(result != nil) {
        // [result release];
    }
    
    return;
}

-(void)printFlyTechDailyCollection
{
    [EposPrintFunction createDailyCollectionWithDbPath:dbPath DateFrom:dateString1 DateTo:dateString2 PrinterBrand:@"FlyTech"];
}

#pragma mark - flytech printer event
- (void)onBleConnectionStatusUpdate:(NSString *)addr status:(int)status
{
    if (status == BLE_DISCONNECTED) {
        
        //[self showAlertView:@"Error" title:@"Unable To Connect To Device"];
        [AppUtility showAlertView:@"Information" message:@"Bluetooth printer has disconnect. Please log out and login to reconnect."];
        
    }
}


#pragma mark - XinYe Printer
-(void)connectXinYePrinter
{
    
    NSMutableData *commands = [NSMutableData data];
    commands = [EposPrintFunction createDailyCollectionWithDbPath:dbPath DateFrom:dateString1 DateTo:dateString2 PrinterBrand:@"XinYe"];
    [[LibraryAPI sharedInstance] setDailyCollectionData:commands];
    commands = nil;
    
    NSMutableArray *reportData = [[NSMutableArray alloc] init];
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data setObject:@"Doc" forKey:@"KR_ItemCode"];
    [data setObject:@"Print" forKey:@"KR_Status"];
    [data setObject:dateString1 forKey:@"KR_Qty"];
    [data setObject:dateString2 forKey:@"KR_Desc"];
    [data setObject:@"RequestPrintKitchenReceipt" forKey:@"IM_Flag"];
    [data setObject:printerBrand forKey:@"KR_Brand"];
    [data setObject:[[printerArray objectAtIndex:0] objectForKey:@"P_PortName"] forKey:@"KR_IpAddress"];
    [data setObject:printerMode forKey:@"KR_PrintMode"];
    [data setObject:@"Non" forKey:@"KR_TableName"];
    [data setObject:@"DailyCollection" forKey:@"KR_DocType"];
    [data setObject:@"Non" forKey:@"KR_DocNo"];
    
    [reportData addObject:data];
    
    [[NSNotificationCenter defaultCenter]postNotificationName:@"ServerCallConnectionArrayWithNotification" object:reportData userInfo:nil];
    
    reportData = nil;
    
    /*
    [self.wifiManager XYDisConnect];
    
    [_wifiManager XYConnectWithHost:[[printerArray objectAtIndex:0] objectForKey:@"P_PortName"] port:9100 completion:^(BOOL isConnect) {
        if (isConnect) {
            [self sendCommandToXinYePrinter];
        }
    }];
     */
}

-(void)sendCommandToXinYePrinter
{
    
    //NSMutableData* dataM=[NSMutableData dataWithData:[PosCommand initializePrinter]];
    //[dataM appendData:commands];
    //[self.wifiManager XYWriteCommandWithData:dataM];
    
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
@end
