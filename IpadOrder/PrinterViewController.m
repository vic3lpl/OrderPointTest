//
//  PrinterViewController.m
//  IpadOrder
//
//  Created by IRS on 7/7/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "PrinterViewController.h"
#import "PrinterFunctions.h"
#import <StarIO/SMPort.h>
#import <StarIO/SMBluetoothManager.h>
#import <FMDB.h>
#import "LibraryAPI.h"
#import <MBProgressHUD.h>
#import "SelectCatTableViewController.h"
#import "ePOS-Print.h"
#import "Result.h"
#import "MsgMaker.h"
#import <KVNProgress.h>



#define DISCOVERY_INTERVAL  0.5
@interface PrinterViewController ()
{
    NSMutableArray *printers;
    NSArray *foundPrinter;
    NSArray *foundAsterixPrinter;
    NSString *printerPortSetting;
    long rowCount;
    NSString *macAddress;
    
    NSString *dbPath;
    FMDatabase *dbPrinter;
    NSMutableArray *printerArray;
    SMLanguage p_selectedLanguage;
    SMPaperWidth p_selectedWidthInch;
    NSOperationQueue *operationQue;
    NSString *printerMode;
    NSString *dbFlag;
    
    
    NSString *selectedPrinterMode;
    NSString *selectedPrinterBrand;
    NSString *alertFlag;
    NSTimer *timer_;
    //flytech
    NSMutableArray *bleDevicePrinter;
    
}
//@property(nonatomic,strong)UIPopoverController *popOver;
@property (nonatomic, strong) XYWIFIManager *wifiManager;

@end

@implementation PrinterViewController

- (XYWIFIManager *)wifiManager
{
    if (!_wifiManager)
    {
        _wifiManager = [XYWIFIManager shareWifiManager];
        _wifiManager.delegate = self;
    }
    return _wifiManager;
}

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        printers = [[NSMutableArray alloc]init];
        printerArray = [[ NSMutableArray alloc]init];
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self wifiManager];
    
    [self setTitle:@"Printer"];
    macAddress = @"-";
    dbPath = [[LibraryAPI sharedInstance]getDbPath];
    
    bleDevicePrinter = [[NSMutableArray alloc] init];
    //printerMode = [[LibraryAPI sharedInstance]getPrinterMode];
    // Do any additional setup after loading the view from its nib.
    self.printerListView.delegate = self;
    self.printerListView.dataSource = self;
    
    self.savedPrinterTableView.delegate = self;
    self.savedPrinterTableView.dataSource = self;
    
    self.textPrinterType.delegate = self;
    self.textIPAdd.enabled = NO;
    
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    //self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:34/255.0 green:171/255.0 blue:241/255.0 alpha:1.0];
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.translucent = NO;
    
    self.viewPrinterBg.layer.cornerRadius = 20.0;
    self.viewPrinterBg.layer.masksToBounds = YES;
    
    /*
    UIGraphicsBeginImageContext(self.view.frame.size);
    [[UIImage imageNamed:@"IO_Background1024"] drawInRect:self.view.bounds];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:image];
    */
    
    self.printerListView.separatorColor = [UIColor blackColor];
    
    [self checkPrinter];
    dbFlag = @"Add";
    
    if ([[[LibraryAPI sharedInstance] getWorkMode] isEqualToString:@"Terminal"]) {
        self.btnAddKitchenPrinter.enabled = false;
    }
    /*
    CBCentralManager *centralManager = [[CBCentralManager alloc]
                                        initWithDelegate:self
                                        queue:dispatch_get_main_queue()
                                        options:@{CBCentralManagerOptionShowPowerAlertKey: @(NO)}];
     */
    
}

-(void)viewWillAppear:(BOOL)animated
{
    //[PosApi setDelegate: self];
    
    //[PosApi setDelegate:self];
}

-(void)viewDidLayoutSubviews
{
    if ([self.printerListView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.printerListView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([self.printerListView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.printerListView setLayoutMargins:UIEdgeInsetsZero];
    }
    
    if ([self.savedPrinterTableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.savedPrinterTableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([self.savedPrinterTableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.savedPrinterTableView setLayoutMargins:UIEdgeInsetsZero];
    }
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - text editing
-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    SelectPrinterTableViewController *selectPrinterTableViewController = [[SelectPrinterTableViewController alloc]init];
    selectPrinterTableViewController.delegate = self;
    //self.popOver = [[UIPopoverController alloc]initWithContentViewController:selectPrinterTableViewController];
    
        
    //.filterType = @"PrinterBrand";
    [self.view endEditing:YES];
    
    selectPrinterTableViewController.modalPresentationStyle = UIModalPresentationPopover;
    selectPrinterTableViewController.popoverPresentationController.sourceView = self.textPrinterType;
    selectPrinterTableViewController.popoverPresentationController.sourceRect = CGRectMake(self.textPrinterType.frame.size.width /
                                                                                           2, self.textPrinterType.frame.size.height / 2, 1, 1);
    [self presentViewController:selectPrinterTableViewController animated:YES completion:nil];
    
    
        /*
    [self.popOver presentPopoverFromRect:CGRectMake(self.textPrinterType.frame.size.width /
                                                        2, self.textPrinterType.frame.size.height / 2, 1, 1) inView:self.textPrinterType permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
         */
    return NO;
}

#pragma mark - delegate method
-(void)getSelectedPrinter:(NSString *)model field2:(NSString *)mode field3:(NSString *)brand
{
    
    self.textPrinterType.text = model;
    selectedPrinterBrand = brand;
    selectedPrinterMode = mode;
    if (![brand isEqualToString:@"XinYe"]) {
        self.textIPAdd.text = @"Finding...";
    }
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    if ([self.textPrinterType.text isEqualToString:@"FlyTech 9C"]) {
        [PosApi setDelegate: self];
    }
    
    //[self findPrinter];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self findPrinter];
    });
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - sqlite

-(void)checkPrinter
{
    dbPrinter = [FMDatabase databaseWithPath:dbPath];
    
    //BOOL dbHadError;
    
    if (![dbPrinter open]) {
        NSLog(@"Fail To Open");
        return;
    }
    
    [printerArray removeAllObjects];
    FMResultSet *rs = [dbPrinter executeQuery:@"Select * from Printer"];
    
    while ([rs next]) {
        [printerArray addObject:[rs resultDictionary]];
    }
    
    [rs close];
    //[dbPrinter executeUpdate:@"delete from printer"];
    [dbPrinter close];
    [self.savedPrinterTableView reloadData];
    [self.view endEditing:NO];
    
}


#pragma mark - printer part

-(void)findPrinter
{
    NSArray *array = nil;
    
    self.textIPAdd.enabled = false;
    if ([selectedPrinterBrand isEqualToString:@"Star"]) {
        array = [SMPort searchPrinter:@"TCP:"];
        if (array.count > 0) {
            foundPrinter = array;
            [self.printerListView reloadData];
            
        }
        else
        {
            self.textIPAdd .text = @"Printer Not Found";
        }
    }
    else if ([selectedPrinterBrand isEqualToString:@"Asterix"])
    {
        //[PosApi stopDiscoverBleDevice];
        //[self.printerListView reloadData];
        [EpsonIoFinder stop];
        int connectionType;
        NSString *option = nil;
        
        connectionType = EPSONIO_OC_DEVTYPE_TCP;
        option = @"255.255.255.255";
        
        // find start
        int result = [EpsonIoFinder start:connectionType
                               FindOption:option];
        
        if(result != EPSONIO_OC_SUCCESS) {
            return ;
        }
        //NSLog(@"1111");
        timer_ = [NSTimer scheduledTimerWithTimeInterval:DISCOVERY_INTERVAL
                                                  target:self
                                                selector:@selector(timerFindPrinter:)
                                                userInfo:nil
                                                 repeats:YES];
         
        
    }
    else if ([selectedPrinterBrand isEqualToString:@"FlyTech"])
    {
        if ([AppUtility isConnect]) {
            [self showAlertView:@"Bluetooth printer connected" title:@"Information"];
        }
        else
        {
            //[foundPrinter]
            [PosApi startDiscoverBleDevice];
            // 設置延遲秒數
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC);
            
            // 以執行緒方式執行，避免主行程被鎖住。
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [PosApi stopDiscoverBleDevice];
                
            });
        }
        
        //[self.printerListView reloadData];
        
    }
    else if ([selectedPrinterBrand isEqualToString:@"XinYe"])
    {
        self.textIPAdd.enabled = true;
        macAddress = @"Non";
        self.textModel.text = @"";
        [self.printerListView reloadData];
        
    }
    
    self.textIPAdd.text = @"";
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    if (central.state == CBCentralManagerStatePoweredOff) {
        /*
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Error" message: @"Please turn on Bluetooth in Settings" delegate: nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
         */
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Warning"
                                     message:@"Please turn on Bluetooth in Settings"
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
    }
    
}

- (void)timerFindPrinter:(NSTimer *)timer
{
    
    //NSLog(@"2222");
    int result = 0;
    NSArray *items = [EpsonIoFinder getDeviceInfoList:&result
                                         FilterOption:EPSONIO_OC_PARAM_DEFAULT];
    
    if((items != nil) && (result == EPSONIO_OC_SUCCESS)) {
        if([foundAsterixPrinter count] != [items count]) {
            
            foundAsterixPrinter = items;
           
            //eposDeviceModel = [[printList objectAtIndex:0]device]
            
            //eposPrinterName = [[printList objectAtIndex:0]printerName];
        }
        
        if (foundAsterixPrinter.count > 0) {
            [self performSelectorOnMainThread:@selector(autoClickPrinterView)
                                   withObject:nil
                                waitUntilDone:YES];
        }
        
    }
    
    [timer_ invalidate];
}

-(void)autoClickPrinterView
{
    //NSLog(@"3333");
    [self.printerListView reloadData];
    
    NSIndexPath *indexPath=[NSIndexPath indexPathForRow:0 inSection:0];
    [self.printerListView selectRowAtIndexPath:indexPath animated:YES  scrollPosition:UITableViewScrollPositionBottom];
     [self tableView:self.printerListView didSelectRowAtIndexPath:indexPath];
    
    //[self tableView:self.printerListView didSelectRowAtIndexPath:(NSIndexPath *)]
}

#pragma mark - Table View

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.printerListView) {
        if ([selectedPrinterBrand isEqualToString:@"Asterix"])
        {
            rowCount = foundAsterixPrinter.count;
        }
        else
        {
            rowCount = foundPrinter.count;
        }
        
    }
    else if (tableView == self.savedPrinterTableView)
    {
        rowCount = printerArray.count;
    }
    return rowCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    if (tableView == self.printerListView) {
        if ([selectedPrinterBrand isEqualToString:@"Star"]) {
            if (indexPath.row < foundPrinter.count) {
                PortInfo *port = foundPrinter[indexPath.row];
                cell.textLabel.text = port.modelName;
                
                if (([port.macAddress isEqualToString:@""]) ||
                    ([port.portName isEqualToString:@"BLE:"])) {
                    cell.detailTextLabel.text = port.portName;
                } else {
                    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", port.portName];
                }
            }
        }
        else if ([selectedPrinterBrand isEqualToString:@"Asterix"])
        {
            
            if (indexPath.row < foundAsterixPrinter.count) {
                //[self showAlertView:@"fff" title:@"fff"];
                cell.textLabel.text = [[foundAsterixPrinter objectAtIndex:indexPath.row] printerName];
                
                cell.detailTextLabel.text = [[foundAsterixPrinter objectAtIndex:indexPath.row] deviceName];
                
            }
        }
        else if ([selectedPrinterBrand isEqualToString:@"FlyTech"])
        {
            
            if (indexPath.row < foundPrinter.count) {
                //BleDeviceInfo *deviceInfo;
                //NSValue *value = [bleDevicePrinter objectAtIndex:indexPath.row];
                
                BleDeviceInfo *deviceInfo = [bleDevicePrinter objectAtIndex:indexPath.row];
                //[value getValue:&deviceInfo];
                
                cell.textLabel.text = deviceInfo.mName;
                cell.detailTextLabel.text = [deviceInfo.mUUID UUIDString];
                 
                
            }
            
        }
        else if ([selectedPrinterBrand isEqualToString:@"XinYe"])
        {
            cell.textLabel.text = @"";
            cell.detailTextLabel.text = @"";
        }
        
        //cell.textLabel.text = [printers objectAtIndex:indexPath.row];
    }
    else if (tableView == self.savedPrinterTableView)
    {
        cell.textLabel.text = [[printerArray objectAtIndex:indexPath.row] objectForKey:@"P_PrinterName"];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@  (%@)",[[printerArray objectAtIndex:indexPath.row]objectForKey:@"P_PortName"],[[printerArray objectAtIndex:indexPath.row]objectForKey:@"P_Type"]];
    }
    
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.printerListView) {
        dbFlag = @"Add";
        
        
        if ([selectedPrinterBrand isEqualToString:@"Star"]) {
            PortInfo *port = foundPrinter[indexPath.row];
            self.textModel.text = port.modelName;
            self.textIPAdd.text = port.portName;
            macAddress = port.macAddress;
        }
        else if ([selectedPrinterBrand isEqualToString:@"Asterix"])
        {
            self.textModel.text = [[foundAsterixPrinter objectAtIndex:indexPath.row] printerName];
            self.textIPAdd.text = [[foundAsterixPrinter objectAtIndex:indexPath.row] deviceName];
            macAddress = [[foundAsterixPrinter objectAtIndex:indexPath.row]macAddress];
        }
        else if ([selectedPrinterBrand isEqualToString:@"FlyTech"])
        {
            BleDeviceInfo *deviceInfo = [bleDevicePrinter objectAtIndex:indexPath.row];
            //NSValue *value = [bleDevicePrinter objectAtIndex:indexPath.row];
            //[value getValue:&deviceInfo];
            
            self.textModel.text = deviceInfo.mName;
            self.textIPAdd.text = [deviceInfo.mUUID UUIDString];
            macAddress = [deviceInfo.mUUID UUIDString];
            /*
            if (AppUtility.isConnect == NO) {
                [KVNProgress showWithStatus:@"Connecting..."];
                
                [PosApi connectBle:deviceInfo.mUUID];
            }
             */
            
        }
        
        //self.textModel.enabled = NO;
    }
    else if (tableView == self.savedPrinterTableView)
    {
        if ([[[LibraryAPI sharedInstance] getWorkMode] isEqualToString:@"Terminal"] && [[[printerArray objectAtIndex:indexPath.row]objectForKey:@"P_Type"] isEqualToString:@"Kitchen"]) {
            self.btnRemovePrinter.enabled = false;
            
        }
        else
        {
            self.btnRemovePrinter.enabled = true;
        }
        //dbFlag = @"Edit";
        self.textIPAdd.text = [[printerArray objectAtIndex:indexPath.row] objectForKey:@"P_PortName"];
        self.textModel.text = [[printerArray objectAtIndex:indexPath.row]objectForKey:@"P_PrinterName"];
        
        self.textModel.text = [[printerArray objectAtIndex:indexPath.row]objectForKey:@"P_PrinterName"];
        self.textPrinterType.text = [[printerArray objectAtIndex:indexPath.row]objectForKey:@"P_PrinterType"];
        selectedPrinterBrand = [[printerArray objectAtIndex:indexPath.row]objectForKey:@"P_Brand"];
        selectedPrinterMode = [[printerArray objectAtIndex:indexPath.row]objectForKey:@"P_Mode"];
        macAddress = [[printerArray objectAtIndex:indexPath.row]objectForKey:@"P_MacAddress"];
        
        //self.textModel.enabled = YES;
    }
}

/*
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
    //return 360;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)btnPrintSample:(id)sender {
    if ([printerMode isEqualToString:@"Line"]) {
        [self printReceiptInLineMode];
    }
    else if ([printerMode isEqualToString:@"Raster"])
    {
        [self PrintReceiptInRasterMode];
    }

}

- (IBAction)btnRemovePrinter:(id)sender {
    
    alertFlag = @"Remove";
    
    
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Warning"
                                 message:@"Are You Sure To Delete ?"
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* yesButton = [UIAlertAction
                                actionWithTitle:@"OK"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
                                    [self printerAlertControlSelection];
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
    
    /*
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning"
                                                    message:@"Are You Sure To Delete ?"
                                                   delegate:self
                                          cancelButtonTitle:@"Yes"
                                          otherButtonTitles:@"No", nil];
    [alert show];
     */
    
    
}

#pragma mark - alertview response
- (void)printerAlertControlSelection
{
    [KVNProgress showWithStatus:@"Loading"];
    
    if ([alertFlag isEqualToString:@"Add"]) {
        [KVNProgress dismiss];
        return;
    }
    else if ([alertFlag isEqualToString:@"Alert"])
    {
        [KVNProgress dismiss];
        return;
    }
    
    
        dbPrinter = [FMDatabase databaseWithPath:dbPath];
        
        if ([self.textIPAdd.text isEqualToString:@""]) {
            [KVNProgress dismiss];
            [self showAlertView:@"Please select installed printer" title:@"Warning"];
            return;
        }
        
        if (![dbPrinter open]) {
            [KVNProgress dismiss];
            NSLog(@"Fail To Open");
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
            
            [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                [db executeUpdate:@"delete from Printer where P_PrinterName = ?",self.textModel.text];
                
                if ([db hadError]) {
                    [self showAlertView:[dbPrinter lastErrorMessage] title:@"Error"];
                    *rollback = YES;
                    return;
                }
                
                [db executeUpdate:@"delete from ItemPrinter where IP_PrinterName = ?",self.textModel.text];
                
                if ([db hadError]) {
                    [self showAlertView:[dbPrinter lastErrorMessage] title:@"Error"];
                    *rollback = YES;
                    return;
                }
                else
                {
                    if ([selectedPrinterBrand isEqualToString:@"FlyTech"]) {
                        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:self.textIPAdd.text];
                        [PosApi disconnect:uuid];
                        uuid = nil;
                    }
                    
                    self.textIPAdd.text = @"";
                    self.textModel.text = @"";
                    //[self checkPrinter];
                    [printerArray removeAllObjects];
                    FMResultSet *rs = [db executeQuery:@"Select * from Printer"];
                    
                    while ([rs next]) {
                        [printerArray addObject:[rs resultDictionary]];
                    }
                    
                    [rs close];
                
                    [self.savedPrinterTableView reloadData];
                }
                
            }];
            
            [queue close];
        });
        
    [KVNProgress dismiss];
    
}


#pragma mark - print receipt
-(void)PrintReceiptInRasterMode {
    //InvNo = @"IV000000063";
    p_selectedWidthInch = SMPaperTestPrint;
    p_selectedLanguage = SMLanguageEnglish;
    
    printerPortSetting = @"Standard";
    
    //[PrinterFunctions PrintRasterSampleReceiptWithPortname:[[printerArray objectAtIndex:0] objectForKey:@"P_PortName"] portSettings:printerPortSetting paperWidth:p_selectedWidthInch Language:p_selectedLanguage invDocno:@"-"];
    
}

- (void)printReceiptInLineMode {
    
    /*
    p_selectedWidthInch = SMPaperWidth3inch;
    p_selectedLanguage = SMLanguageEnglish;
    
    
    NSData *commands = [PrinterFunctions sampleReceiptWithPaperWidth:p_selectedWidthInch
                                                            language:p_selectedLanguage
                                                          kickDrawer:YES invDocNo:@"-" docType:@"NONO"];
    if (commands == nil) {
        return;
    }
    
    printerPortSetting = @"Standard";
    [PrinterFunctions sendCommand:commands
                         portName:[[printerArray objectAtIndex:0] objectForKey:@"P_PortName"]
                     portSettings:printerPortSetting
                    timeoutMillis:10000];
    */
    
}

/*
- (IBAction)btnFindPrinter:(id)sender {
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    operationQue = [NSOperationQueue new];
    
    NSInvocationOperation *operation = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(findPrinter) object:nil];
    [operationQue addOperation:operation];
    
    //[self findPrinter];

}
 */

#pragma mark - find flextech bluetooth printer

-(void)onBleDiscoveredDevice:(BleDeviceInfo*)deviceInfo
{
    
    //NSValue *value = [NSValue value:&deviceInfo withObjCType:@encode(BleDeviceInfo)];
    
    NSMutableArray *tmpDevInfoArray = [NSMutableArray arrayWithArray:bleDevicePrinter];
    
    /*
    for (NSValue *existValue in tmpDevInfoArray) {
        BleDeviceInfo *tmp;
        [existValue getValue:&tmp];
        
        if ([deviceInfo.mUUID isEqual:tmp.mUUID]) {
            [tmpDevInfoArray removeObject:existValue];
            break;
        }
    }
     
     [tmpDevInfoArray addObject:value];
     */
    
    for (BleDeviceInfo *existValue in tmpDevInfoArray) {
        if ([deviceInfo.mUUID isEqual:existValue.mUUID]) {
            [tmpDevInfoArray removeObject:existValue];
            break;
        }
    }
    
    
    [tmpDevInfoArray addObject:deviceInfo];
    
    if (tmpDevInfoArray.count > 1) {
        
        NSArray *sortedArray;
        sortedArray = [tmpDevInfoArray sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            BleDeviceInfo *devA = a;
            BleDeviceInfo *devB = b;
            
            //[(NSValue*)a getValue:&devA];
            //[(NSValue*)b getValue:&devB];
            
            
            return [devA.mUUID.UUIDString compare:devB.mUUID.UUIDString];
        }];
        bleDevicePrinter = [NSMutableArray arrayWithArray:sortedArray];
    }
    else {
        
        bleDevicePrinter = [NSMutableArray arrayWithArray:tmpDevInfoArray];
    }
    
    foundPrinter = [NSArray arrayWithArray:bleDevicePrinter];
    
    if (foundPrinter.count > 0) {
        [PosApi stopDiscoverBleDevice];
    }
    
    //[self showAlertView:[NSString stringWithFormat:@"%ld",foundPrinter.count] title:@"Checking"];
    //[self.printerListView reloadData];
    [self autoClickPrinterView];
    
    
}

- (void)onBleConnectionStatusUpdate:(NSString *)addr status:(int)status
{
    if (NO) {
    } else if (status == BLE_CONNECTING) {
        // Nothing
    } else if (status == BLE_CONNECTED) {
        [KVNProgress dismiss];
        AppUtility.isConnect = YES;
        [AppUtility showAlertView:@"Information" message:@"Bluetooth printer connected"];
        
        
    } else if (status == BLE_DISCONNECTED) {
        AppUtility.isConnect = NO;
        [KVNProgress dismiss];
        [AppUtility showAlertView:@"Information" message:@"Disconnect with device!"];
    }
}

-(void) onBleError:(int)err
{
    NSLog(@"onBleError:%d", err);
    [self showAlertView:@"Printer Error : " title:[NSString stringWithFormat:@"%d",err]];
}

#pragma mark - alertView

-(void)showAlertView:(NSString *)msg title:(NSString *)title
{
    alertFlag = @"Alert";
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
}
- (IBAction)btnAddReceiptPrinter:(id)sender {
    
    alertFlag = @"Add";
    
    if ([macAddress isEqualToString:@"-"]) {
        [self showAlertView:@"Please select a printer" title:@"Warning"];
        return;
    }
    
    if (self.textModel.text.length == 0) {
        [self showAlertView:@"Printer name cannot empty" title:@"Warning"];
        return;
    }
    
    if (self.textIPAdd.text.length == 0) {
        [self showAlertView:@"Printer ip cannot empty" title:@"Warning"];
        return;
    }
    
    if ([selectedPrinterBrand isEqualToString:@"FlyTech"])
    {
        if (AppUtility.isConnect == NO) {
            [KVNProgress showWithStatus:@"Connecting..."];
            NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:macAddress];
            [[LibraryAPI sharedInstance] setPrinterUUID:macAddress];
            [PosApi connectBle:uuid];
            uuid = nil;
        }
    }
    else if ([selectedPrinterBrand isEqualToString:@"XinYe"])
    {
        
        macAddress = @"Non";
    }
    
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"Select * from Printer where P_Type = ?",@"Receipt"];
        
        
        if ([rs next]) {
            
            [rs close];
            
            [self showAlertView:@"You has already configured receipt printer. You must delete existing receipt printer and add new one." title:@"Printer Already Configured"];
            
        }
        else
        {
            [rs close];
            BOOL dbHadError = [db executeUpdate:@"insert into Printer (P_PortName, P_PrinterName, P_Type,P_MacAddress,P_PrintType,P_Mode,P_Brand) values (?,?,?,?,?,?,?)",self.textIPAdd.text,self.textModel.text,@"Receipt",macAddress,self.textPrinterType.text,selectedPrinterMode,selectedPrinterBrand];
            
            if (dbHadError) {
                //[self showAlertView:@"Data Save" title:@"Success"];
                [self.navigationController popViewControllerAnimated:YES];
            }
            else
            {
                [self showAlertView:[dbPrinter lastErrorMessage] title:@"Error"];
            }
        }
        
    }];
    [queue close];
    [self checkPrinter];
}

- (IBAction)btnAddKitchenPrinter:(id)sender {
    
    alertFlag = @"Add";
    
    if ([macAddress isEqualToString:@"-"]) {
        [self showAlertView:@"Please select a printer" title:@"Warning"];
        return;
    }
    
    if (self.textModel.text.length == 0) {
        [self showAlertView:@"Printer name cannot empty" title:@"Warning"];
        return;
    }
    
    if (self.textIPAdd.text.length == 0) {
        [self showAlertView:@"Printer ip cannot empty" title:@"Warning"];
        return;
    }
    
    if ([selectedPrinterBrand isEqualToString:@"FlyTech"])
    {
        if (AppUtility.isConnect == NO) {
            [KVNProgress showWithStatus:@"Connecting..."];
            NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:macAddress];
            [[LibraryAPI sharedInstance] setPrinterUUID:macAddress];
            [PosApi connectBle:uuid];
            uuid = nil;
        }
    }
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"Select * from Printer where P_PrinterName = ?",[self.textModel.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
        
        if ([rs next]) {
            
            [rs close];
            
            [self showAlertView:@"Please change your printer name." title:@"Printer Name Conflict"];
            
        }
        else
        {
            [rs close];
            BOOL dbHadError = [db executeUpdate:@"insert into Printer (P_PortName, P_PrinterName, P_Type,P_MacAddress,P_PrintType,P_Mode,P_Brand) values (?,?,?,?,?,?,?)",self.textIPAdd .text,self.textModel.text,@"Kitchen",macAddress,self.textPrinterType.text,selectedPrinterMode,selectedPrinterBrand];
            
            if (dbHadError) {
                //[self showAlertView:@"Data Save" title:@"Success"];
                [[LibraryAPI sharedInstance] setPrinterBand:selectedPrinterBrand];
                [[LibraryAPI sharedInstance] setPrinterPortName:self.textIPAdd .text];
                [self.navigationController popViewControllerAnimated:YES];
            }
            else
            {
                [self showAlertView:[dbPrinter lastErrorMessage] title:@"Error"];
            }
        }
        
    }];
    [queue close];
    [self checkPrinter];
    
}

#pragma mark - touch background
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
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




- (IBAction)textFlyTech:(id)sender {
    [PosApi initPrinter];
    [PosApi setPrinterSettings:CHARSET_GBK leftMargin:0 printAreaWidth:576 printQuality:8];
    [PosApi setPrintFont:PRINT_FONT_12x24];
    [PosApi setPrintCharacterScale:FONT_SCALE_VERTICAL_2 hScale:FONT_SCALE_HORIZONTAL_2];
    [PosApi setPrintFormat:ALIGNMENT_LEFT];
    [PosApi printText:@"Shi Jack........"];
    [PosApi setPrintCharacterScale:FONT_SCALE_VERTICAL_2 hScale:FONT_SCALE_HORIZONTAL_2];
    //[PosApi setPrintFont:2];
    [PosApi printText:@"Testing 1234567890"];
    [PosApi cutPaper];
}
@end
