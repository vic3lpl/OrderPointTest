//
//  ViewController.m
//  IpadOrder
//
//  Created by IRS on 6/29/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "ViewController.h"
#import "NumPadTextField/NumericKeypadTextField.h"
#import <QuartzCore/QuartzCore.h>
#import "NumericKeypadViewController.h"
#import "ModalViewController.h"
#import "ContainerViewController.h"
#import "SelectTablePlanViewController.h"
#import <FMDB.h>
#import "DBManager.h"
#import "LibraryAPI.h"
#import "AppDelegate.h"
#import <ifaddrs.h>
#import <arpa/inet.h>
#import "TerminalData.h"

#import "ePOS-Print.h"
#import "EposPrintFunction.h"
#import "PrinterFunctions.h"
#import "Result.h"
#import <StarIO/SMPort.h>
#import <StarIO/SMBluetoothManager.h>
#import "OrderingViewController.h"
#import <KVNProgress.h>
#import <AFNetworking/AFNetworking.h>
#import "PublicSqliteMethod.h"
#import "PublicMethod.h"

#import "OrderPackageItemViewController.h"

#define FMDBQuickCheck(SomeBool) { if (!(SomeBool)) { NSLog(@"Failure on line %d", __LINE__); abort(); } }
//typedef void (^BlockName1) (int someValue);
extern NSString *baseUrl;
extern NSString *appApiVersion;
@class EposPrint;
@interface ViewController ()
{
    NSString *dbPath;
    MCPeerID *pID;
    NSString *deviceName;
    BOOL queryResult;
    MCPeerID *peerID;
    NSMutableArray *returnData;
    NSString *defaultKioskName;
    int remainDayCount;
    
    SMLanguage p_selectedLanguage;
    SMPaperWidth p_selectedWidthInch;
    NSMutableArray *xinYeConnectionArray;
    //NSMutableArray *appRegArray;
    XYWIFIManager *xinYeGeneralWfMng;
    FMDatabase *dbTable;
    
    NSMutableArray *receiptData;
    NSMutableArray *compData;
    NSMutableArray *gstData;
    
    NSTimer *timerPrintQueue;
    NSOperationQueue *operationQue;
    int fireBackFlag;
    //NSThread *thread;
    NSMutableArray *asterixConenctionArray;
    GCDAsyncSocket *gcdSocket;
    
    NSMutableArray *printQueueArray;
    NSUInteger testPrinterIndex;
    
    NSMutableArray *printerConnectStatusArray;
    
    NSString *xYPrinterIP;
    NSString *xYPrinterName;
    
}
@property (nonatomic, strong) DBManager *dbManager;
@property (nonatomic, strong) AppDelegate *appDelegate;

//@property(nonatomic,strong)UIPopoverController *popOverRegister;

-(void)peerDidChangeStateWithNotification:(NSNotification *)notification;
-(void)didReceiveDataWithNotification:(NSNotification *)notification;
-(void)generalCSArrayWithNotification:(NSNotification *)notification;
-(void)serverCallConnectionArrayWithNotification:(NSNotification *)notification;
-(void)autoPrintFromServerWithNotification:(NSNotification *)notification;
-(void)fireBackAutoPrintDocumentWithNotification:(NSNotification *)notification;

//block testing
/*
-(void)addNumber:(int)number1 withNumber:(int)number2 andCompletionHandler:(void (^)(int result))completionHandler;

-(void)minusNumber:(int)number1 withNumber:(int)number2 addCompletion:(void (^)(int resukt))comple;
 */
@end
//NSString *bigBtn;
@implementation ViewController

- (XYWIFIManager *)wifiManager
{
    if (!_wifiManager)
    {
        _wifiManager = [XYWIFIManager shareWifiManager];
        _wifiManager.delegate = self;
    }
    return _wifiManager;
}

-(void)viewWillAppear:(BOOL)animated
{
    
    
    //self.testmmm.attributedText = string;
    [self wifiManager];
    
    NSDateFormatter *dateFormater = [[NSDateFormatter alloc] init];
    [dateFormater setDateFormat:@"yyyy-MMM-dd"];
    [dateFormater setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    
    self.textPassword.text = @"";
    self.textUserId.text = @"";
    self.navigationController.navigationBar.hidden = YES;
    
    [self mixTwoDiffFont];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rsTerminalDtl = [db executeQuery:@"Select * from TerminalDtl"];
        
        if ([rsTerminalDtl next]) {
            deviceName = [NSString stringWithFormat:@"%@,%@,%@,%@",[UIDevice currentDevice].name,[rsTerminalDtl stringForColumn:@"TD_ServerIP"],[rsTerminalDtl stringForColumn:@"TD_Code"],@"Data"];
            [[LibraryAPI sharedInstance] setTerminalDeviceName:deviceName];
        }
        
        FMResultSet *rs = [db executeQuery:@"select * from GeneralSetting"];
        
        if ([rs next]) {
            
            if ([rs intForColumn:@"GS_EnableGST"] == 1) {
                [[LibraryAPI sharedInstance] setServiceTaxGstCode:[rs stringForColumn:@"GS_ServiceGstCode"]];
            }
            else
            {
                [[LibraryAPI sharedInstance] setServiceTaxGstCode:nil];
                
            }
            
            if ([rs doubleForColumn:@"GS_TaxInclude"] == 0) {
                [[LibraryAPI sharedInstance]setTaxType:@"IEx"];
            }
            else
            {
                [[LibraryAPI sharedInstance]setTaxType:@"Inc"];
            }
            
            [[LibraryAPI sharedInstance] setRefreshTB:@"Refresh,1"];
            if ([rs doubleForColumn:@"GS_EnableMTO"] == 1) {
                [[LibraryAPI sharedInstance]setMultipleTerminalMode:@"True"];
                NSArray *allPeers = [[_appDelegate.mcManager session] connectedPeers];
                MCPeerID *serverPeer;
                
                if ([rs doubleForColumn:@"GS_WorkMode"] == 0) {
                    [[LibraryAPI sharedInstance] setWorkMode:@"Main"];
                    if (allPeers.count <= 0) {
                        [[_appDelegate mcManager] setupPeerAndSessionWithDisplayName:@"Server"];
                        [[_appDelegate mcManager] advertiseSelf:true];
                    }
                    
                }
                else
                {
                    [[LibraryAPI sharedInstance] setWorkMode:@"Terminal"];
                    
                    if (deviceName != nil) {
                        
                        
                        if (allPeers.count == 0) {
                            [[_appDelegate mcManager] setupPeerAndSessionWithDisplayName:deviceName];
                            [[_appDelegate mcManager] setupMCBrowser];
                        }
                        else
                        {
                            for (int i = 0; i < allPeers.count; i++)
                            {
                                serverPeer = [allPeers objectAtIndex:i];
                                
                                if (![serverPeer.displayName isEqualToString:@"Server"])
                                {
                                    [[_appDelegate mcManager] setupPeerAndSessionWithDisplayName:deviceName];
                                    [[_appDelegate mcManager] setupMCBrowser];
                                }
                            }
                        }
                        
                        serverPeer = nil;
                        allPeers = nil;
                        
                        //[KVNProgress showWithStatus:@"Connecting..."];
                        
                    }
                    
                    
                }
                
            }
            else
            {
                [[LibraryAPI sharedInstance] setWorkMode:@"Main"];
                [[LibraryAPI sharedInstance] setMultipleTerminalMode:@"False"];
            }
            
            
            [[LibraryAPI sharedInstance]setCurrencySymbol:[rs stringForColumn:@"GS_Currency"]];
            [[LibraryAPI sharedInstance]setKioskMode:[rs intForColumn:@"GS_EnableKioskMode"]];
            [[LibraryAPI sharedInstance] setEnableGst:[rs intForColumn:@"GS_EnableGST"]];
            
            if ([rs intForColumn:@"GS_EnableKioskMode"] == 1) {
                defaultKioskName = [rs stringForColumn:@"GS_DefaultKioskName"];
            }
            
            [rs close];
            
            FMResultSet *rsExpire = [db executeQuery:@"Select App_StartDate, App_ReqExpDate, App_EndDate, App_DemoDay, App_Status, Comp_Company,  substr(app_enddate,10,2)  || ' ' || substr(app_enddate,6,3) || ' ' || substr(app_enddate,1,4) as expDemoDate, substr(App_ReqExpDate,10,2)  || ' ' || substr(App_ReqExpDate,6,3) || ' ' || substr(App_ReqExpDate,1,4) as expReqDate from Company comp  left join AppRegistration app on comp.Comp_Company = App_CompanyName"];
            
            if ([rsExpire next]) {
                [[LibraryAPI sharedInstance] setAppStatus:[rsExpire stringForColumn:@"App_Status"]];
                
                //NSLog(@"%@",[[LibraryAPI sharedInstance] getWorkMode]);
                if ([[[LibraryAPI sharedInstance] getWorkMode] isEqualToString:@"Main"]){
                    if ([[rsExpire stringForColumn:@"App_Status"] length] == 0) {
                        self.labelExpdate.text = [NSString stringWithFormat:@"Registration Info Unmatch"];
                    }
                    else if ([[rsExpire stringForColumn:@"App_Status"] isEqualToString:@"DEMO"])
                    {
                        NSDate *today = [NSDate date];
                        NSDate *date2 = [dateFormater dateFromString:[rsExpire stringForColumn:@"APP_EndDate"]];
                        //NSLog(@"%@",[rsExpire stringForColumn:@"APP_EndDate"]);
                        
                        NSTimeInterval secondsBetween = [date2 timeIntervalSinceDate:today];
                        //NSString *expdate = [dateFormater stringFromDate:date2];
                        
                        remainDayCount = (secondsBetween / 86400)+1;
                        
                        self.labelExpdate.text = [NSString stringWithFormat:@"Expired on %@", [rsExpire stringForColumn:@"expDemoDate"]];
                        //[self addInUnderlineWithTitle:self.labelExpdate.text];
                        
                        if ([[rsExpire stringForColumn:@"expDemoDate"] length] == 11)
                        {
                            [self addInUnderlineWithTitle:self.labelExpdate.text];
                        }
                        else
                        {
                            self.labelExpdate.text = [NSString stringWithFormat:@"Expired on %@", [rsExpire stringForColumn:@"app_enddate"]];
                        }
                        
                        self.btnRegistration.hidden = false;
                        self.labelExpdate.hidden = false;
                        self.labelExpDate2.hidden = false;
                        
                        
                    }
                    else if ([[rsExpire stringForColumn:@"App_Status"] isEqualToString:@"REQ"] || [[rsExpire stringForColumn:@"App_Status"] isEqualToString:@"PENDING"] || [[rsExpire stringForColumn:@"App_Status"] isEqualToString:@"RE-REG"])
                    {
                        self.btnRegistration.hidden = true;
                        [dateFormater setDateFormat:@"yyyy-MMM-dd"];
                        NSDate *today = [NSDate date];
                        NSDate *date2 = [dateFormater dateFromString:[rsExpire stringForColumn:@"App_ReqExpDate"]];
                        //NSString *expdate = [dateFormater stringFromDate:date2];
                        
                        NSTimeInterval secondsBetween = [date2 timeIntervalSinceDate:today];
                        
                        remainDayCount = (secondsBetween / 86400)+1;
                        
                        self.labelExpdate.text = [NSString stringWithFormat:@"Expired on %@", [rsExpire stringForColumn:@"expReqDate"]];
                        
                        
                        self.labelExpdate.hidden = false;
                        self.labelExpDate2.hidden = false;
                        
                        if ([[rsExpire stringForColumn:@"expDemoDate"] length] == 11)
                        {
                            [self addInUnderlineWithTitle:self.labelExpdate.text];
                        }
                        else
                        {
                            self.labelExpdate.text = [NSString stringWithFormat:@"Expired on %@", [rsExpire stringForColumn:@"app_enddate"]];
                        }
                        
                        //[self addInUnderlineWithTitle:self.labelExpdate.text];
                        
                    }
                    else
                    {
                        self.btnRegistration.hidden = true;
                        self.labelExpdate.hidden = true;
                        self.labelExpDate2.hidden = true;
                        
                    }
                }
                else
                {
                    self.btnRegistration.hidden = true;
                    self.labelExpdate.hidden = true;
                    self.labelExpDate2.hidden = true;
                }
                
                
            }
            else
            {
                self.btnRegistration.hidden = true;
                self.labelExpdate.hidden = true;
                self.labelExpDate2.hidden = true;
                
                remainDayCount = 30;
                [[NSUserDefaults standardUserDefaults] setInteger:30 forKey:@"defaultDayCount"];
            }
            [rsExpire close];
            
        }
        
        
    }];
    
    [queue close];
    
    
    
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.textPassword.text = @"1234";
    self.textUserId.text = @"admin";
    
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    xinYeConnectionArray = [[NSMutableArray alloc] init];
    returnData = [[NSMutableArray alloc] init];
    xinYeGeneralWfMng = [[XYWIFIManager alloc] init];
    receiptData = [[NSMutableArray alloc]init];
    compData = [[NSMutableArray alloc]init];
    gstData = [[NSMutableArray alloc] init];
    asterixConenctionArray = [[NSMutableArray alloc] init];
    printQueueArray = [[NSMutableArray alloc]init];
    printerConnectStatusArray = [[NSMutableArray alloc] init];
    
    fireBackFlag = 0;
    //appRegArray = [[NSMutableArray alloc]init];

    UIGraphicsBeginImageContext(self.view.frame.size);
    [[UIImage imageNamed:@"Wallpaper"] drawInRect:self.view.bounds];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    
    UIImageView *userIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Username"]];
    userIcon.frame = CGRectMake(0.0, 0.0, userIcon.image.size.width+10.0, userIcon.image.size.height);
    userIcon.contentMode = UIViewContentModeCenter;
    self.textUserId.leftView = userIcon;
    self.textUserId.leftViewMode = UITextFieldViewModeAlways;
    userIcon = nil;
    
    UIImageView *passwordIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Password"]];
    passwordIcon.frame = CGRectMake(0.0, 0.0, passwordIcon.image.size.width+10.0, passwordIcon.image.size.height);
    passwordIcon.contentMode = UIViewContentModeCenter;
    self.textPassword.leftView = passwordIcon;
    self.textPassword.leftViewMode = UITextFieldViewModeAlways;
    passwordIcon = nil;
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:image];
    image = nil;
    
    //NumericKeypadViewController *nKeyView;
    //nKeyView = [[NumericKeypadViewController alloc]init];
    //bigBtn = @"Login";
    
    
    dbPath = [[LibraryAPI sharedInstance] getDbPath];
    [[_appDelegate mcManager] setDbPath:[[LibraryAPI sharedInstance] getDbPath]];
    
    [self getIpAddress];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveDataWithNotification:)
                                                 name:@"MCDidReceiveDataNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(peerDidChangeStateWithNotification:)
                                                 name:@"MCDidChangeStateNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(generalCSArrayWithNotification:)
                                                 name:@"GeneralCSArrayWithNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(serverCallConnectionArrayWithNotification:)
                                                 name:@"ServerCallConnectionArrayWithNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(autoPrintFromServerWithNotification:)
                                                 name:@"AutoPrintFromServerWithNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fireBackAutoPrintDocumentWithNotification:)
                                                 name:@"FireBackAutoPrintDocumentWithNotification"
                                               object:nil];
    
    //tblWorkMode = [[LibraryAPI sharedInstance] getWorkMode];
    
    if (![[[LibraryAPI sharedInstance] getPrinterUUID] isEqualToString:@"Non"]&& [[[LibraryAPI sharedInstance] getWorkMode] isEqualToString:@"Main"]) {
        [PosApi setDelegate: self];
    }
    
    if ([[[LibraryAPI sharedInstance] getWorkMode] isEqualToString:@"Main"])
    {
        
        
        timerPrintQueue = [NSTimer scheduledTimerWithTimeInterval:2
                                                           target:self
                                                         selector:@selector(serverPrintDocument)
                                                         userInfo:nil
                                                          repeats:YES];
         
        
        
    }

}

/*
- (NSThread *) thread
{
    if (!_thread) {
        _thread = [[NSThread alloc]
                   initWithTarget:self
                   selector:@selector(callBackgroundOperation)
                   object:nil];
    }
    return _thread;
}
*/

#pragma mark - enable timer

-(void)serverPrintDocument
{
    
    [timerPrintQueue invalidate];
    
    //[self.thread start];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"AutoPrintFromServerWithNotification" object:nil userInfo:nil];
    
    
}

-(void)callBackgroundOperation
{
    
     [[NSNotificationCenter defaultCenter]postNotificationName:@"AutoPrintFromServerWithNotification" object:nil userInfo:nil];
    
}


-(void)fireBackAutoPrintDocumentWithNotification:(NSNotification *)notification
{
    //fireBackFlag = 0;
    //[_thread cancel];
    //self.thread = nil;
    timerPrintQueue = [NSTimer scheduledTimerWithTimeInterval:2
                                                       target:self
                                                     selector:@selector(serverPrintDocument)
                                                     userInfo:nil
                                                      repeats:YES];
    
}

#pragma mark - edit label attributed
-(void)addInUnderlineWithTitle:(NSString *)title
{
    
    NSMutableAttributedString * attString = [[NSMutableAttributedString alloc] initWithString:title];
    //[string addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(0,27)];
    [attString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(10,12)];
    [attString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:20 ] range:NSMakeRange(10,12)];
    [attString addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:1] range:(NSRange){10,12}];
    
    self.labelExpdate.attributedText = attString;
}

-(void)mixTwoDiffFont
{
    
    NSMutableAttributedString * attString = [[NSMutableAttributedString alloc] initWithString:@"OrderPoint"];
    //[string addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(0,27)];
    [attString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0,10)];
    [attString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:40 ] range:NSMakeRange(0,5)];
    //[attString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:40 ] range:NSMakeRange(5,10)];
    
    self.labelTitle.attributedText = attString;
}

#pragma mark - Activate Delegate
-(void)afterRequestTerminalDevice
{
    self.btnRegistration.hidden = true;
}

#pragma mark - NumberPadDelegate
-(void)saveActionFormTextField:(UITextField *)textField
{
    [textField resignFirstResponder];
    NSLog(@"Password is %@",textField.text);
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

- (IBAction)userBtn:(id)sender {
    UIButton *btn = (UIButton *)sender;
    btn.backgroundColor = [UIColor redColor];
    [btn setTitleColor:[UIColor yellowColor] forState:UIControlStateNormal];
    NSLog(@"%@",btn.titleLabel.text);
}
/*
- (IBAction)TestModal:(id)sender {
    ModalViewController *modalViewController = [[ModalViewController alloc]init];
    [modalViewController setModalPresentationStyle:UIModalPresentationFormSheet];
    [self presentViewController:modalViewController animated:YES completion:nil];
}
 */

- (IBAction)testSplitView:(id)sender {
    ContainerViewController *containerViewController = [[ContainerViewController alloc]init];
    [self presentViewController:containerViewController animated:YES completion:nil];
}

-(void)testBlockStorageType{
    __block int someValue = 10;
    
    int (^myOperation)(void) = ^(void){
        someValue += 5;
        
        return someValue + 10;
    };
    
    NSLog(@"fgfgfgf %d", myOperation());
}

- (IBAction)loginBtn:(id)sender {
    [self testBlockStorageType];
    
    //[_thread start];
    
    if ([[[LibraryAPI sharedInstance] getWorkMode] isEqualToString:@"Main"])
    {
        [self startDiscoverFlyTechPrinter];
    }
    
    if ([self.labelExpdate.text isEqualToString:@"Registration Info Unmatch"]) {
        [self showAlertView:@"Registration info unmatch." title:@"Warning"];
        return;
    }
    //NSLog(@"Version %@",[[LibraryAPI sharedInstance] getAppApiVersion]);
    
    if ([[[LibraryAPI sharedInstance] getAppApiVersion]length] > 0) {
        if (![[[LibraryAPI sharedInstance] getAppApiVersion] isEqualToString:appApiVersion]) {
            //[self showAlertView:@"Please update your app to latest version" title:@"Warning"];
            //return;
            
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"Information"
                                         message:@"Update to latest version ?"
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* yesButton = [UIAlertAction
                                        actionWithTitle:@"OK"
                                        style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * action) {
                                            [self redirectToAppStore];
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
            return;
            
        }
    }
    
    if ([[[LibraryAPI sharedInstance] getWorkMode] isEqualToString:@"Main"]) {
        if ([[[LibraryAPI sharedInstance]getAppStatus]isEqualToString:@"TERMINATED"]) {
            [self showAlertView:@"Your app has been terminated. Please contact person incharge" title:@"Warning"];
            return;
        }
        else if ([[[LibraryAPI sharedInstance]getAppStatus]isEqualToString:@"REG"])
        {
            NSLog(@"%@",@"Device Register");
        }
        else if ([[[LibraryAPI sharedInstance]getAppStatus]isEqualToString:@"PENDING"])
        {
            if (remainDayCount > 15) {
                [self showAlertView:@"Your pending trail period has end" title:@"Warning"];
                return;
            }
            else if (remainDayCount <= 0)
            {
                [self showAlertView:@"Your pending trail period has end" title:@"Warning"];
                return;
            }
        }
        else if ([[[LibraryAPI sharedInstance]getAppStatus]isEqualToString:@"REQ"])
        {
            if (remainDayCount <= 0)
            {
                [self showAlertView:@"Your pending trail period has end" title:@"Warning"];
                return;
            }
        }
        else
        {
            
            long defaultDayCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"defaultDayCount"];
            
            if ([[[LibraryAPI sharedInstance] getWorkMode] isEqualToString:@"Main"]) {
                if (remainDayCount > 30) {
                    [self showAlertView:@"Your trail period has end" title:@"Warning"];
                    return;
                }
                else if (remainDayCount <= 0)
                {
                    [self showAlertView:@"Your trail period has end" title:@"Warning"];
                    return;
                }
                
                if (remainDayCount < defaultDayCount)
                {
                    [[NSUserDefaults standardUserDefaults]setInteger:remainDayCount forKey:@"defaultDayCount"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
                else if (remainDayCount > defaultDayCount)
                {
                    [self showAlertView:@"Your trail period has end" title:@"Warning"];
                    return;
                }
            }
            
        }
    }
    
    NSString *connectedStatus;
    
    if ([self.textUserId.text length] == 0) {
        [self showAlertView:@"Username cannot empty" title:@"Warning"];
        return;
    }
    else if ([self.textPassword.text length] == 0)
    {
        [self showAlertView:@"Password cannot empty" title:@"Warning"];
        return;
    }
    
    if ([[LibraryAPI sharedInstance]getKioskMode] == 1) {
        if ([[[LibraryAPI sharedInstance] getWorkMode] isEqualToString:@"Terminal"]) {
            NSArray *allPeers = [[_appDelegate.mcManager session] connectedPeers];
            
            if (allPeers.count <= 0) {
                connectedStatus = @"Disconnect";
                [self showAlertView:@"Cannot connect to server" title:@"Warning"];
            }
            else
            {
                connectedStatus = @"Connected";
            }
            allPeers = nil;
        }
        else
        {
            connectedStatus = @"";
        }
        
    }
    
    //[self showAlertView:[[LibraryAPI sharedInstance] getPrinterPortName] title:@"TTT"];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"select * from UserLogin where UL_ID = ? and UL_Password = ?",self.textUserId.text,self.textPassword.text];
        
        if ([db hadError]) {
            NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
            return;
        }
        
        if ([rs next]) {
            [self.textPassword resignFirstResponder];
            [self.textUserId resignFirstResponder];
            
            [[LibraryAPI sharedInstance]setUserRole:[rs intForColumn:@"UL_Role"]];
            [[LibraryAPI sharedInstance] setUserName:[rs stringForColumn:@"UL_ID"]];
            if ([[LibraryAPI sharedInstance]getKioskMode] == 0) {
                SelectTablePlanViewController *selectedTablePlanViewController = [[SelectTablePlanViewController alloc]init];
                [self.navigationController pushViewController:selectedTablePlanViewController animated:NO];
                selectedTablePlanViewController = nil;
            }
            else
            {
                
                [self getKioskSalesSetting];
                OrderingViewController *orderViewController = [[OrderingViewController alloc]init];
                
                FMResultSet *rs1 = [db executeQuery:@"Select * from TablePlan where TP_Name = ?",defaultKioskName];
                
                if ([rs1 next]) {
                    
                    orderViewController.tableName = [rs1 stringForColumn:@"TP_Name"];
                    orderViewController.tbStatus = [rs1 stringForColumn:@"TP_DineType"];
                    orderViewController.overrideTableSVC = [rs1 stringForColumn:@"TP_Overide"];
                    orderViewController.connectedStatus = connectedStatus;
                    [[LibraryAPI sharedInstance]setTableNo:[rs1 intForColumn:@"TP_ID"]];
                    orderViewController.paxData = @"1";
                    orderViewController.docType = @"SalesOrder";
                    
                    [[LibraryAPI sharedInstance]setDocNo:@"-"];
                    [self.navigationController pushViewController:orderViewController animated:NO];
                    
                }
                
                [rs1 close];
                
                orderViewController = nil;
            }
            
        }
        else
        {
            [self showAlertView:@"Invalid username or password" title:@"Warning"];
            return;
        }
        
        [rs close];
    }];
    
    
    //[db close];
    
    //[rs close];
    
    
}

-(void)getKioskSalesSetting
{
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        NSString *enableGst;
        NSString *enableServiceTaxGst;
        
        FMResultSet *rsTax = [db executeQuery:@"Select * from GeneralSetting"];
        
        if ([rsTax next]) {
            if ([rsTax intForColumn:@"GS_EnableGST"] == 1) {
                enableGst = @"Yes";
                [[LibraryAPI sharedInstance] setServiceTaxGstCode:[rsTax stringForColumn:@"GS_ServiceGstCode"]];
            }
            else
            {
                [[LibraryAPI sharedInstance] setServiceTaxGstCode:nil];
                enableGst = @"No";
            }
            [[LibraryAPI sharedInstance]setEnableGst:[rsTax intForColumn:@"GS_EnableGST"]];
            [[LibraryAPI sharedInstance] setEnableSVG:[rsTax intForColumn:@"GS_EnableSVG"]];
        }
        [rsTax close];
        
        if ([enableGst isEqualToString:@"Yes"]) {
            FMResultSet *rsServiceTaxGst = [db executeQuery:@"Select T_Percent from GeneralSetting gs inner join Tax t on gs.GS_ServiceGstCode = t.T_Name"
                                            " where gs.GS_ServiceTaxGst  = 1"];
            
            if ([rsServiceTaxGst next]) {
                enableServiceTaxGst = @"Yes";
                [[LibraryAPI sharedInstance] setServiceTaxGstPercent:[rsServiceTaxGst doubleForColumn:@"T_Percent"]];
            }
            else
            {
                enableServiceTaxGst = @"No";
                [[LibraryAPI sharedInstance] setServiceTaxGstPercent:0.00];
            }
            
            [rsServiceTaxGst close];
        }
        else
        {
            enableServiceTaxGst = @"No";
            [[LibraryAPI sharedInstance] setServiceTaxGstPercent:0.00];
            
        }
        
        FMResultSet *rsTable = [db executeQuery:@"Select TP_Name,TP_Percent, TP_Overide,TP_DineType from TablePlan where TP_Name = ?",defaultKioskName];
        
        if ([rsTable next]) {
            
            if ([rsTable intForColumn:@"TP_Overide"] == 1) {
                if ( [rsTable doubleForColumn:@"TP_Percent"] > 0.0) {
                    //get service tax percent follow table
                    
                    [[LibraryAPI sharedInstance] setServiceTaxPercent:[rsTable stringForColumn:@"TP_Percent"]];
                }
                else if ([rsTable doubleForColumn:@"TP_Percent"] == 0.0) {
                    // get default service tax percent follow tax
                    [[LibraryAPI sharedInstance] setServiceTaxPercent:@"0.00"];
                }
                else
                {
                    [[LibraryAPI sharedInstance] setServiceTaxPercent:@"0.00"];
                }
                
            }
            else
            {
                
                [[LibraryAPI sharedInstance] setServiceTaxPercent:@"-"];
                
            }
            [rsTable close];
            
            
        }

        
    }];

}

#pragma mark - start discover flytech order
-(void)startDiscoverFlyTechPrinter
{
    if (![[[LibraryAPI sharedInstance] getPrinterUUID] isEqualToString:@"Non"]) {
        if (AppUtility.isConnect == NO) {
            [PosApi startDiscoverBleDevice];
            // 設置延遲秒數
            
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
            
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [PosApi stopDiscoverBleDevice];
                
                NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:[[LibraryAPI sharedInstance] getPrinterUUID]];
                
                [PosApi connectBle:uuid];
                uuid = nil;
                
            });
        }
    }
    
}

- (void)onBleConnectionStatusUpdate:(NSString *)addr status:(int)status
{
    if (status == BLE_DISCONNECTED) {
        //[KVNProgress dismiss];
        AppUtility.isConnect = NO;
        
        [AppUtility showAlertView:@"Information" message:@"Cannot connect to bluetooth printer"];
        
        //[self.navigationController popToRootViewControllerAnimated:YES];
    }
    else if (status == BLE_CONNECTED)
    {
        AppUtility.isConnect = YES;
        //[AppUtility showAlertView:@"Information" message:@"Connect to bluetooth printer"];
        //[KVNProgress dismiss];
    }
}

#pragma mark - confirm connect

-(void)peerDidChangeStateWithNotification:(NSNotification *)notification{
    MCPeerID *peerID1 = [[notification userInfo] objectForKey:@"peerID"];
    //NSString *peerDisplayName = peerID.displayName;
    MCSessionState state = [[[notification userInfo] objectForKey:@"state"] intValue];
    NSString *refreshTB = [[LibraryAPI sharedInstance] getRefreshTB];
    
    if (state != MCSessionStateConnecting) {
        if (state == MCSessionStateConnected) {
            
            //NSLog(@"%@",[[peerCollection objectAtIndex:0] objectForKey:@"peerID"]);
            NSLog(@"%@",@"Server success step 2");
            pID = peerID1;
            
            NSArray *arrayWithTwoStrings = [peerID1.displayName componentsSeparatedByString:@","];
            
            if (![[arrayWithTwoStrings objectAtIndex:0] isEqualToString:@"Server"]) {
                if ([[arrayWithTwoStrings objectAtIndex:3] isEqualToString:@"Sync"]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        [self updateDeviceCode];
                        if ([refreshTB isEqualToString:@"Refresh,0"]) {
                            //success
                            
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshTableDeviceNotification"
                                                                                object:nil];
                        }
                        
                    });
                }
            }
            
            
            
        }
        else if (state == MCSessionStateNotConnected){
            
        }
        
    }
}


#pragma mark - multipeer receive data event

-(void)didReceiveDataWithNotification:(NSNotification *)notification{
    
    peerID = [[notification userInfo] objectForKey:@"peerID"];
    
    NSData *receivedData = [[notification userInfo] objectForKey:@"data"];
    NSArray *dataReceive = [NSKeyedUnarchiver unarchiveObjectWithData:receivedData];
    
    NSDate *today = [NSDate date];
    
     NSDateFormatter *dateFormat = [[LibraryAPI sharedInstance] getDateFormaterhhmmss];
    NSString *dateString = [dateFormat stringFromDate:today];
    
    NSString *dataFromTerminal = [[dataReceive objectAtIndex:0] objectForKey:@"IM_Flag"];
    NSLog(@"Flag %@",dataFromTerminal);
    if ([dataFromTerminal isEqualToString:@"Order"]) {
        NSMutableArray *specificOrderPeer = [[NSMutableArray alloc] init];
        [specificOrderPeer addObject:[[notification userInfo] objectForKey:@"peerID"]];
        if ([[[dataReceive objectAtIndex:0] objectForKey:@"Status"] isEqualToString:@"New"])
        {
            //NSLog(@"Log Check 1: %@",@"Start Sales Order");
            queryResult = [TerminalData insertSalesOrderIntoMainWithOrderType:@"sales" sqlitePath:dbPath OrderData:dataReceive OrderDate:dateString terminalArray:specificOrderPeer terminalName:peerID.displayName PayType:@"Other"];
        }
        else
        {
            queryResult = [TerminalData updateSalesOrderIntoMainWithOrderType:@"sales" sqlitePath:dbPath OrderData:dataReceive OrderDate:dateString DocNo:[[dataReceive objectAtIndex:0] objectForKey:@"SOH_DocNo"] terminalArray:specificOrderPeer terminalName:peerID.displayName ToWhichView:@"Ordering" PayType:@"Other" OptionSelected:nil FromSalesOrderNo:nil];
        }
        
        specificOrderPeer = nil;
    }
    else if ([dataFromTerminal isEqualToString:@"Server"]) {
        
        NSDictionary *dict = @{@"Result"  :   [[dataReceive objectAtIndex:0]objectForKey:@"Result"],@"DocNo":[[dataReceive objectAtIndex:0]objectForKey:@"DocNo"]
                               };
        
        [[NSNotificationCenter defaultCenter]postNotificationName:@"ConfirmSalesOrderWithNotification" object:nil userInfo:dict];
        
        NSLog(@"Result From Server : %@",[[dataReceive objectAtIndex:0]objectForKey:@"Result"]);
    }
    
    // terminal refresh table plan amt
    else if ([dataFromTerminal isEqualToString:@"RefreshTablePlanAmt"]) {
        //update tableplan amt
        //2
        //NSLog(@"%@",peerID.displayName);
        NSMutableArray *specificRefreshTablePlanPeer = [[NSMutableArray alloc] init];
        [specificRefreshTablePlanPeer addObject:[[notification userInfo] objectForKey:@"peerID"]];
        [self sendBackToTerminalRefreshTablePlanAmtResult:peerID.displayName SelectedPeer:specificRefreshTablePlanPeer ReferToWhichNotification:@"RefreshTablePlan"];
        specificRefreshTablePlanPeer = nil;
    }
    else if ([dataFromTerminal isEqualToString:@"RefreshTablePlanAmtResult"]) {
        
        [[NSNotificationCenter defaultCenter]postNotificationName:@"RefreshTablePlanAmtWithNotification" object:dataReceive userInfo:nil];
    }
    //for terminal request SO detail from Server
    else if ([dataFromTerminal isEqualToString:@"RequestSODtl"])
    {
        NSMutableArray *specificSODtlPeer = [[NSMutableArray alloc] init];
        [specificSODtlPeer addObject:[[notification userInfo] objectForKey:@"peerID"]];
        [self sendBackToTerminalWithSalesOrderResultTableNo:[[[dataReceive objectAtIndex:0]objectForKey:@"TP_ID"] integerValue] SalesOrderDocNo:[[dataReceive objectAtIndex:0]objectForKey:@"SOH_DocNo"] CompanyEnableGst:[[dataReceive objectAtIndex:0]objectForKey:@"CompEnableGst"] SelectedTerminal:specificSODtlPeer DocType:[[dataReceive objectAtIndex:0]objectForKey:@"DocType"]];
        specificSODtlPeer = nil;
        
    }
    else if ([dataFromTerminal isEqualToString:@"SalesOrderResult"])
    {
        [[NSNotificationCenter defaultCenter]postNotificationName:@"GetSalesOrderDtlWithNotification" object:dataReceive userInfo:nil];
    }
    
    // for terminal request payment so from server
    else if ([dataFromTerminal isEqualToString:@"RequestPaymentSO"])
    {
        NSMutableArray *specificPaymentSOPeer = [[NSMutableArray alloc] init];
        [specificPaymentSOPeer addObject:[[notification userInfo] objectForKey:@"peerID"]];
        //NSLog(@"Display Peer ID request SO %@",specificPaymentSOPeer);
        [self sendBackToTerminalWithPaymentSOResultSalesOrderDocNo:[[dataReceive objectAtIndex:0] objectForKey:@"SOH_DocNo"] TerminalDisplayName:peerID.displayName SelectedPeer:specificPaymentSOPeer PayDocType:[[dataReceive objectAtIndex:0] objectForKey:@"PayDocType"]];
        specificPaymentSOPeer = nil;
        
    }
    else if ([dataFromTerminal isEqualToString:@"PaymentSOResult"])
    {
        [[NSNotificationCenter defaultCenter]postNotificationName:@"GetPaymentSOWithNotification" object:dataReceive userInfo:nil];
    }
    
    // for terminal send data to insert invoice
    else if ([dataFromTerminal isEqualToString:@"Invoice"])
    {
        NSMutableArray *specificInsertInvoicePeer = [[NSMutableArray alloc] init];
        [specificInsertInvoicePeer addObject:[[notification userInfo] objectForKey:@"peerID"]];
        
        queryResult = [TerminalData insertInvoiceIntoMainWithSqlitePath:dbPath InvData:dataReceive InvDate:dateString terminalArray:specificInsertInvoicePeer TerminalName:peerID.displayName];
        specificInsertInvoicePeer = nil;
        
        
    }
    else if ([dataFromTerminal isEqualToString:@"InsertInvoiceResult"])
    {
        [[NSNotificationCenter defaultCenter]postNotificationName:@"GetInsertInvoiceResultWithNotification" object:dataReceive userInfo:nil];
    }
    //for terminal request SO detail that want to split from Server
    else if ([dataFromTerminal isEqualToString:@"RequestSODtlWantSplit"])
    {
        NSMutableArray *specificRequestSalesOrderSplitBillPeer = [[NSMutableArray alloc] init];
        [specificRequestSalesOrderSplitBillPeer addObject:[[notification userInfo] objectForKey:@"peerID"]];
        [self sendBacktoTerminalSalesOrderSplitBillWithTableName:[[dataReceive objectAtIndex:0] objectForKey:@"TP_Name"] SalesOrderNo:[[dataReceive objectAtIndex:0] objectForKey:@"SO_DocNo"] TerminalDisplayName:peerID.displayName SelectedPeer:specificRequestSalesOrderSplitBillPeer ServiceTaxGstPercent:[[[dataReceive objectAtIndex:0] objectForKey:@"ServiceTaxGstPercent"]doubleValue]];
        specificRequestSalesOrderSplitBillPeer = nil;
        
    }
    else if([dataFromTerminal isEqualToString:@"SaleOrderRequestSplit"])
    {
        [[NSNotificationCenter defaultCenter]postNotificationName:@"GetSplitBillSalesOrderDtlWithNotification" object:dataReceive userInfo:nil];
    }
    // for terminal send data to split SO
    else if ([dataFromTerminal isEqualToString:@"SplitSaleOrder"])
    {
        NSMutableArray *specificSplitSaleOrderPeer = [[NSMutableArray alloc] init];
        [specificSplitSaleOrderPeer addObject:[[notification userInfo] objectForKey:@"peerID"]];
        queryResult = [TerminalData insertSplitSalesOrderIntoMainWithSqlitePath:dbPath SplitData:dataReceive SplitDate:dateString terminalArray:specificSplitSaleOrderPeer TerminalName:peerID.displayName];
        specificSplitSaleOrderPeer = nil;
    
    }
    else if ([dataFromTerminal isEqualToString:@"SplitBillSOResult"])
    {
        [[NSNotificationCenter defaultCenter]postNotificationName:@"GetSplitBillSalesOrderNoWithNotification" object:dataReceive userInfo:nil];
    }
    // for terminal request multiple SO after split but not pay
    else if ([dataFromTerminal isEqualToString:@"RequestMultipleSO"])
    {
        NSMutableArray *specificRequestMultipleSOPeer = [[NSMutableArray alloc] init];
        [specificRequestMultipleSOPeer addObject:[[notification userInfo] objectForKey:@"peerID"]];
         
        [self sendBacktoTerminalMultipleSalesOrderWithTableName:[[dataReceive objectAtIndex:0] objectForKey:@"TP_Name"] TerminalDisplayName:peerID.displayName SelectedPeer:specificRequestMultipleSOPeer];
        specificRequestMultipleSOPeer = nil;
    }
    else if ([dataFromTerminal isEqualToString:@"MultipleSaleOrderRequestResult"])
    {
        [[NSNotificationCenter defaultCenter]postNotificationName:@"GetMultipleSalesOrderWithNotification" object:dataReceive userInfo:nil];
    }
    // asterix part
    else if ([dataFromTerminal isEqualToString:@"RequestPrintAsterixSalesOrder"])
    {
        NSMutableArray *specificRequestPrintSOPeer = [[NSMutableArray alloc] init];
        [specificRequestPrintSOPeer addObject:[[notification userInfo] objectForKey:@"peerID"]];
        [self printAsterixSalesOrderWithSONo:[[dataReceive objectAtIndex:0] objectForKey:@"SOH_DocNo"] PrinterPortName:[[dataReceive objectAtIndex:0] objectForKey:@"P_PortName"] SelectedPeer:specificRequestPrintSOPeer];
        specificRequestPrintSOPeer = nil;
    }
    else if ([dataFromTerminal isEqualToString:@"TerminalRequestSODtlResult"])
    {
        [[NSNotificationCenter defaultCenter]postNotificationName:@"PrintAsterixSalesOrderDtlWithNotification" object:dataReceive userInfo:nil];
    }
    
    //--------------------------------------------------
    else if ([dataFromTerminal isEqualToString:@"RequestPrintAsterixInvoice"])
    {
        NSMutableArray *specificRequestPrintSOPeer = [[NSMutableArray alloc] init];
        [specificRequestPrintSOPeer addObject:[[notification userInfo] objectForKey:@"peerID"]];
        [self printAsterixInvoiceWithInvNo:[[dataReceive objectAtIndex:0] objectForKey:@"Inv_DocNo"] PrinterPortName:[[dataReceive objectAtIndex:0] objectForKey:@"P_PortName"] EnableGst:[[[dataReceive objectAtIndex:0] objectForKey:@"EnableGst"] integerValue] SelectedPeer:specificRequestPrintSOPeer KickOutDrawer:[[dataReceive objectAtIndex:0] objectForKey:@"P_KickDrawer"] ViewName:[[dataReceive objectAtIndex:0] objectForKey:@"ViewName"]];
        
        specificRequestPrintSOPeer = nil;
    }
    else if ([dataFromTerminal isEqualToString:@"TerminalRequestCashSalesResult"])
    {
        if ([[[dataReceive objectAtIndex:0] objectForKey:@"ViewName"] isEqualToString:@"PaymentView"]) {
            [[NSNotificationCenter defaultCenter]postNotificationName:@"PrintAsterixPayBillDtlWithNotification" object:dataReceive userInfo:nil];
        }
        else if ([[[dataReceive objectAtIndex:0] objectForKey:@"ViewName"] isEqualToString:@"ReprintBillView"])
        {
            [[NSNotificationCenter defaultCenter]postNotificationName:@"PrintAsterixReprintPayBillDtlWithNotification" object:dataReceive userInfo:nil];
        }
        
    }
    
    // part below for fill bill used
    else if ([dataFromTerminal isEqualToString:@"RequestFindBillWithKeyWord"])
    {
        NSMutableArray *RequestFindBillWithKeyWordPeer = [[NSMutableArray alloc] init];
        [RequestFindBillWithKeyWordPeer addObject:[[notification userInfo] objectForKey:@"peerID"]];
        
        [self sendBackToTerminalSalesOrderFilteringResultWithSelectedPeer:RequestFindBillWithKeyWordPeer KeyWord:[[dataReceive objectAtIndex:0] objectForKey:@"KeyWord"]];
        RequestFindBillWithKeyWordPeer = nil;
    }
    else if ([dataFromTerminal isEqualToString:@"FilteringSalesOrderResult"])
    {
        [[NSNotificationCenter defaultCenter]postNotificationName:@"GetSOListingResultWithNotification" object:dataReceive userInfo:nil];
    }
    
    // part below for edit bill used
    else if ([dataFromTerminal isEqualToString:@"RequestEditBillWithKeyWord"])
    {
        NSMutableArray *RequestFindBillWithKeyWordPeer = [[NSMutableArray alloc] init];
        [RequestFindBillWithKeyWordPeer addObject:[[notification userInfo] objectForKey:@"peerID"]];
        
        [self sendBackToTerminalEditBillFilteringResultWithSelectedPeer:RequestFindBillWithKeyWordPeer KeyWord:[[dataReceive objectAtIndex:0] objectForKey:@"KeyWord"]];
        RequestFindBillWithKeyWordPeer = nil;
    }
    else if ([dataFromTerminal isEqualToString:@"FilteringEditBillResult"])
    {
        [[NSNotificationCenter defaultCenter]postNotificationName:@"GetCashSalesListingResultWithNotification" object:dataReceive userInfo:nil];
    }
    // part below for transfer table use
    else if ([dataFromTerminal isEqualToString:@"RequestSalesNo"])
    {
        //1
        NSMutableArray *RequestSalesNoPeer = [[NSMutableArray alloc] init];
        [RequestSalesNoPeer addObject:[[notification userInfo] objectForKey:@"peerID"]];
        
        [self sendBackToTerminalSalesOrderNoResultWithSelectedPeer:RequestSalesNoPeer TableName:[[dataReceive objectAtIndex:0] objectForKey:@"TableName"]];
        RequestSalesNoPeer = nil;
    }
    else if ([dataFromTerminal isEqualToString:@"SalesOrderNoResult"])
    {
        [[NSNotificationCenter defaultCenter]postNotificationName:@"GetSalesOrderDocNoWithNotification" object:dataReceive userInfo:nil];
    }
    else if ([dataFromTerminal isEqualToString:@"RequestAllTable"])
    {
        NSMutableArray *specificRequestAllTablePeer = [[NSMutableArray alloc] init];
        [specificRequestAllTablePeer addObject:[[notification userInfo] objectForKey:@"peerID"]];
        
        [self sendBackToTerminalAllTableResultWithSelectedPeer:specificRequestAllTablePeer OptionSelected:[[dataReceive objectAtIndex:0] objectForKey:@"OptionSelected"] FromTableName:[[dataReceive objectAtIndex:0] objectForKey:@"FromTableName"] ToTableName:[[dataReceive objectAtIndex:0] objectForKey:@"ToTableName"]];
        specificRequestAllTablePeer = nil;
    }
    else if ([dataFromTerminal isEqualToString:@"AllTableResult"])
    {
        [[NSNotificationCenter defaultCenter]postNotificationName:@"GetAllTableListWithNotification" object:dataReceive userInfo:nil];
    }
    else if ([dataFromTerminal isEqualToString:@"RequestRecalcSaleSOrder"])
    {
        NSMutableArray *specificRequestRecalcSaleSOrderPeer = [[NSMutableArray alloc] init];
        [specificRequestRecalcSaleSOrderPeer addObject:[[notification userInfo] objectForKey:@"peerID"]];
        
        [self sendBackToTerminalWithRecalculateSalesOrderResult:specificRequestRecalcSaleSOrderPeer FromSalesOrderNo:[[dataReceive objectAtIndex:0] objectForKey:@"SoNo"] SelectedTbName:[[dataReceive objectAtIndex:0] objectForKey:@"TbName"] SelectedDineType:[[[dataReceive objectAtIndex:0] objectForKey:@"DineType"] integerValue] Date:dateString ItemServeTypeFlag:[[dataReceive objectAtIndex:0] objectForKey:@"ServeType"] OptionSelected:[[dataReceive objectAtIndex:0] objectForKey:@"OptionSelected"] ToSalesOrderNo:[[dataReceive objectAtIndex:0] objectForKey:@"ToSalesOrderNo"]];
        
        specificRequestRecalcSaleSOrderPeer = nil;
    }
    
    else if ([dataFromTerminal isEqualToString:@"RecalculateTransferSalesOrderResult"])
    {
        [[NSNotificationCenter defaultCenter]postNotificationName:@"GetRecalculateTransferTableResultWithNotification" object:dataReceive userInfo:nil];
    }
    else if ([dataFromTerminal isEqualToString:@"RecalculateTablePlanTransferSalesOrderResult"])
    {
        [[NSNotificationCenter defaultCenter]postNotificationName:@"GetRecalculateTableplanTransferTableResultWithNotification" object:dataReceive userInfo:nil];
    }
    else if ([dataFromTerminal isEqualToString:@"RequestTransferMultipleSO"])
    {
        NSMutableArray *specificRequestTransferMultipleSOPeer = [[NSMutableArray alloc] init];
        [specificRequestTransferMultipleSOPeer addObject:[[notification userInfo] objectForKey:@"peerID"]];
        
        [self sendBackToTerminalWithMultiTransferSOResultWithSelectedPeer:specificRequestTransferMultipleSOPeer TableName:[[dataReceive objectAtIndex:0] objectForKey:@"TP_Name"]];
        
        specificRequestTransferMultipleSOPeer = nil;
    }
    else if ([dataFromTerminal isEqualToString:@"TransferMultiSOResult"])
    {
        [[NSNotificationCenter defaultCenter]postNotificationName:@"GetTransferMultipleSalesOrderWithNotification" object:dataReceive userInfo:nil];
    }
    else if ([dataFromTerminal isEqualToString:@"RequestTransferSalesOrderDetail"])
    {
        NSMutableArray *specificRequestSaleSOrderDetailPeer = [[NSMutableArray alloc] init];
        [specificRequestSaleSOrderDetailPeer addObject:[[notification userInfo] objectForKey:@"peerID"]];
        
        [self sendBackToTerminalWithTransferSalesOrderResult:specificRequestSaleSOrderDetailPeer SalesOrderNo:[[dataReceive objectAtIndex:0] objectForKey:@"SoNo"] SelectedTbName:[[dataReceive objectAtIndex:0] objectForKey:@"TbName"] SelectedDineType:[[[dataReceive objectAtIndex:0] objectForKey:@"DineType"] integerValue] Date:dateString];
        specificRequestSaleSOrderDetailPeer = nil;
    }
    else if ([dataFromTerminal isEqualToString:@"TransferSalesOrderDetailResult"])
    {
        
        [[NSNotificationCenter defaultCenter]postNotificationName:@"GetTransferSalesOrderDetailResultWithNotification" object:dataReceive userInfo:nil];
         
    }
    else if ([dataFromTerminal isEqualToString:@"RequestCombineSalesOrderDetail"])
    {
        NSMutableArray *specificRequestCombineSaleSOrderDetailPeer = [[NSMutableArray alloc] init];
        [specificRequestCombineSaleSOrderDetailPeer addObject:[[notification userInfo] objectForKey:@"peerID"]];
        
        [self sendBackToTerminalCombineTableResultWithSelectedPeer:specificRequestCombineSaleSOrderDetailPeer OptionSelected:[[dataReceive objectAtIndex:0] objectForKey:@"OptionSelected"] FromSalesOrderNo: [[dataReceive objectAtIndex:0] objectForKey:@"FromSalesOrderNo"]ToSalesOrderNo:[[dataReceive objectAtIndex:0] objectForKey:@"FromSalesOrderNo"]];
        specificRequestCombineSaleSOrderDetailPeer = nil;
    }
    else if ([dataFromTerminal isEqualToString:@"CombineTableResult"])
    {
        [[NSNotificationCenter defaultCenter]postNotificationName:@"GetCombineSalesOrderDetailResultWithNotification" object:dataReceive userInfo:nil];
    }
    
    //-------------------------------------
    else if ([dataFromTerminal isEqualToString:@"GeneralRequestInvoiceArray"])
    {
        NSMutableArray *specificGeneralInvDetailPeer = [[NSMutableArray alloc] init];
        [specificGeneralInvDetailPeer addObject:[[notification userInfo] objectForKey:@"peerID"]];
        
        [self sendBackToTerminalForFlyTechPrinterWithCSNo:[[dataReceive objectAtIndex:0] objectForKey:@"DocNo"] SelectedPeer:specificGeneralInvDetailPeer];
        specificGeneralInvDetailPeer = nil;
    }
    else if ([dataFromTerminal isEqualToString:@"TerminalPrintFlyTechReceiptResult"])
    {
        [[NSNotificationCenter defaultCenter]postNotificationName:@"GeneralCSArrayWithNotification" object:dataReceive userInfo:nil];
        
    }
    else if ([dataFromTerminal isEqualToString:@"GeneralRequestSalesOrderArray"])
    {
        NSMutableArray *specificGeneralSODetailPeer = [[NSMutableArray alloc] init];
        [specificGeneralSODetailPeer addObject:[[notification userInfo] objectForKey:@"peerID"]];
        
        [self sendBackToTerminalForFlyTechPrinterWithSONo:[[dataReceive objectAtIndex:0] objectForKey:@"DocNo"] SelectedPeer:specificGeneralSODetailPeer];
        specificGeneralSODetailPeer = nil;
    }
    else if ([dataFromTerminal isEqualToString:@"TerminalPrintFlyTechSOReceiptResult"])
    {
        [[NSNotificationCenter defaultCenter]postNotificationName:@"PrintSalesOrderDtlWithNotification" object:dataReceive userInfo:nil];
        
    }
    
    else if ([dataFromTerminal isEqualToString:@"XinYePrintKitchen"])
    {
        [[NSNotificationCenter defaultCenter]postNotificationName:@"GetXinYePrinterResultWithNotification" object:nil userInfo:nil];
    }
    else if ([dataFromTerminal isEqualToString:@"XinYeTerminalPrinterCsDetail"])
    {
        NSMutableArray *specificGeneralInvDetailPeer = [[NSMutableArray alloc] init];
        [specificGeneralInvDetailPeer addObject:[[notification userInfo] objectForKey:@"peerID"]];
        
        [self sendBackToTerminalForCSDetailWithCSNo:[[dataReceive objectAtIndex:0] objectForKey:@"DocNo"] SelectedPeer:specificGeneralInvDetailPeer ToView:[[dataReceive objectAtIndex:0] objectForKey:@"From"]];
    
        specificGeneralInvDetailPeer = nil;
        
    }
    else if ([dataFromTerminal isEqualToString:@"XinYeTerminalCSDetail"])
    {
        [[NSNotificationCenter defaultCenter]postNotificationName:@"GetXinYeCSDetailResultWithNotification" object:dataReceive userInfo:nil];
    }
    else if ([dataFromTerminal isEqualToString:@"XinYeTerminalReprintCSDetail"])
    {
        [[NSNotificationCenter defaultCenter]postNotificationName:@"GetXinYeReprintCSDetailResultWithNotification" object:dataReceive userInfo:nil];
    }
    else if ([dataFromTerminal isEqualToString:@"RequestPrintKitchenReceipt"])
    {
        [self serverPrintingDataWithArray:dataReceive];
    }
    /*
    else if ([dataFromTerminal isEqualToString:@"RequestPrintKitchenGroupReceipt"])
    {
        
        [self serverPrintKitchenGroupReceiptWithArray:dataReceive];
    }
    */
    //
    
}

-(void)updateDeviceCode
{
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        [db executeUpdate:@"Update Terminal set T_DeviceName = ? where T_Code = ?", _appDelegate.mcManager.tName, _appDelegate.mcManager.tCode];
        
        if ([db hadError]) {
            //[self showAlert:(NSString *)];
        }
        
        
    }];
    
    [queue close];
    
    if ([_appDelegate.mcManager.tStatus isEqualToString:@"Sync"]) {
        [self fileTransferToTerminal];
    }
    
    
}

-(void)fileTransferToTerminal
{
    //int totalFileUpload = 0;
    //[self showAlertView:@"1" title:@"1"];
    NSString * resourcePath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    
    NSError * error;
    NSArray * directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:resourcePath error:&error];
    NSString *localPath;
    
    localPath = [resourcePath stringByAppendingPathComponent:@"iorder.db"];
    //[self.restClient uploadFile:[directoryContents objectAtIndex:i] toPath:destDir withParentRev:nil fromPath:localPath];
    NSURL *resourceURL = [NSURL fileURLWithPath:localPath];
    [_appDelegate.mcManager.session sendResourceAtURL:resourceURL withName:@"iorder.db" toPeer:pID withCompletionHandler:^(NSError *error) {
        if (error) {
            //[self showAlertView:[error localizedDescription] title:@"2"];
            NSLog(@"iOrder Transfer Fail : %@", [error localizedDescription]);
        }
    }];
    
    for (int i = 0; i < directoryContents.count; i++) {
        if ([[directoryContents objectAtIndex:i] isEqualToString:@"EposLog"])
        {
            
        }
        else if ([[directoryContents objectAtIndex:i] isEqualToString:@".DS_Store"])
        {
            
        }
        else if ([[directoryContents objectAtIndex:i] isEqualToString:@"iorder.db"])
        {
            
        }
        else if ([[directoryContents objectAtIndex:i] isEqualToString:@"iorder.db-shm"])
        {
            
        }
        else if ([[directoryContents objectAtIndex:i] isEqualToString:@"iorder.db-wal"])
        {
            
        }
        else
        {
            
            localPath = [resourcePath stringByAppendingPathComponent:[directoryContents objectAtIndex:i]];
            //[self.restClient uploadFile:[directoryContents objectAtIndex:i] toPath:destDir withParentRev:nil fromPath:localPath];
            NSURL *resourceURL = [NSURL fileURLWithPath:localPath];
            [_appDelegate.mcManager.session sendResourceAtURL:resourceURL withName:[directoryContents objectAtIndex:i] toPeer:pID withCompletionHandler:^(NSError *error) {
                if (error) {
                    //[self showAlertView:[error localizedDescription] title:@"2"];
                    NSLog(@"%@", [error localizedDescription]);
                }
            }];
        }
        
    }
    
    //[self showAlertView:@"3" title:@"3"];
    
}
#pragma mark - server to terminal
-(void)sendBackToTerminalWithResult:(NSString *)result Message:(NSString *)message
{
    [returnData removeAllObjects];
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    
    //[data setObject:[NSString stringWithFormat:@"%ld",(long)_im_ItemNo] forKey:@"IM_ItemNo"];
    [data setObject:result forKey:@"Result"];
    [data setObject:message forKey:@"Message"];
    [data setObject:@"Server" forKey:@"IM_Flag"];
    [data setObject:@"-" forKey:@"DocNo"];
    
    [returnData addObject:data];
    NSData *dataToBeReturn = [NSKeyedArchiver archivedDataWithRootObject:returnData];
    NSError *error;
    for (int i = 0; i < [[_appDelegate.mcManager connectedPeerArray]count]; i++) {
        NSArray *allPeers = [[_appDelegate.mcManager session] connectedPeers];
        NSString *connectedPeerName;
        MCPeerID *onePeer = [allPeers objectAtIndex:i];
        
        connectedPeerName = onePeer.displayName;
        
        if ([connectedPeerName isEqualToString:peerID.displayName]) {
            NSArray *oneArray = @[[_appDelegate.mcManager.session.connectedPeers objectAtIndex:i]];
            [_appDelegate.mcManager.session sendData:dataToBeReturn
                                             toPeers:oneArray
                                            withMode:MCSessionSendDataReliable
                                               error:&error];
            
        }
        
        if (error) {
            NSLog(@"Erro : %@", [error localizedDescription]);
        }
        
        
    }
}

-(void)sendBackToTerminalRefreshTablePlanAmtResult:(NSString *)displayName SelectedPeer:(NSArray *)selectedArray ReferToWhichNotification:(NSString *)returnTo
{
    NSMutableArray *resultArray;
    
    resultArray = [[NSMutableArray alloc]init];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rsSection = [db executeQuery:@"Select * from TableSection"];
        while ([rsSection next]) {
            
            FMResultSet *rs = [db executeQuery:@"Select *,ifnull(SOH_DocNo,'-') as DocNo ,ifnull(SOH_Index,'null') as 'Index' from tableplan t1 left join"
                               " (select * from SalesOrderHdr where SOH_Status = 'New' group by SOH_Table) as tb1 "
                               " on t1.tp_name = tb1.soh_table where t1.TP_Section = ?",[rsSection stringForColumn:@"TS_Name"]];
            
            while ([rs next]) {
                NSMutableDictionary *data = [NSMutableDictionary dictionary];
                //NSLog(@"tp id %@",[rs stringForColumn:@"TP_ID"]);
                if ([returnTo isEqualToString:@"RefreshTablePlan"]) {
                    [data setObject:@"RefreshTablePlanAmtResult" forKey:@"IM_Flag"];
                }
                else
                {
                    [data setObject:@"TransferMultiSOResult" forKey:@"IM_Flag"];
                    [data setObject:[rs stringForColumn:@"SOH_DocAmt"] forKey:@"SOH_DocAmt"];
                    
                }
                
                [data setObject:[rs stringForColumn:@"TP_ID"] forKey:@"TP_ID"];
                [data setObject:[rs stringForColumn:@"TP_Name"] forKey:@"TP_Name"];
                [data setObject:[rs stringForColumn:@"DocNo"] forKey:@"SOH_DocNo"];
                [data setObject:[rs stringForColumn:@"Index"] forKey:@"SOH_Index"];
                
                
                FMResultSet *rsSOCount = [db executeQuery:@"Select count(*) as soCount from SalesOrderHdr where SOH_Table = ? and SOH_Status = ?",[rs stringForColumn:@"TP_Name"],@"New"];
                
                if ([rsSOCount next]) {
                    if ([rsSOCount intForColumn:@"soCount"] > 1) {
                        [data setObject:[rsSOCount stringForColumn:@"soCount"] forKey:@"TP_Count"];
                        [data setObject:@"0.00" forKey:@"TP_Amt"];
                        
                    }
                    else
                    {
                        
                        if ([rs doubleForColumn:@"SOH_DocAmt"] > 0.00) {
                            [data setObject:@"1" forKey:@"TP_Count"];
                            [data setObject:[rs stringForColumn:@"SOH_DocAmt"] forKey:@"TP_Amt"];
                        }
                        else
                        {
                            [data setObject:@"0" forKey:@"TP_Count"];
                            [data setObject:@"0.00" forKey:@"TP_Amt"];
                        }
                        
                        
                    }
                }
                else
                {
                    [data setObject:@"0" forKey:@"TP_Count"];
                    [data setObject:@"0.00" forKey:@"TP_Amt"];
                }
                [rsSOCount close];
                [resultArray addObject:data];
                data = nil;
                
            }
            [rs close];
            
        }
        
        [rsSection close];
    }];
    
    NSData *dataToBeReturn = [NSKeyedArchiver archivedDataWithRootObject:resultArray];
    NSError *error;
    
    
    //NSArray *allPeers = [[_appDelegate.mcManager session] connectedPeers];
    
    [_appDelegate.mcManager.session sendData:dataToBeReturn
                                     toPeers:selectedArray
                                    withMode:MCSessionSendDataReliable
                                       error:&error];
    
    resultArray = nil;
}

-(void)sendBackToTerminalWithSalesOrderResultTableNo:(int)tblNo SalesOrderDocNo:(NSString *)soDocNo CompanyEnableGst:(NSString *)compEnableGst SelectedTerminal:(NSArray *)selectedTerminal DocType:(NSString *)docType
{
    NSMutableArray *resultArray;
    resultArray = [[NSMutableArray alloc]init];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        NSString *tableDesc = @"";
        
        FMResultSet *rs2 = [db executeQuery:@"Select TP_Name from TablePlan where TP_ID = ?",[NSNumber numberWithInt:tblNo]];
        
        if ([rs2 next]) {
            tableDesc = [rs2 stringForColumn:@"TP_Name"];
        }
        
        [rs2 close];
        
        
        NSString *sqlCommand;
        FMResultSet *rs1;
        if ([docType isEqualToString:@"CashSales"]) {
            sqlCommand = [PublicSqliteMethod generateCSOrderDataArray];
            rs1 = [db executeQuery:sqlCommand,soDocNo];
        }
        else
        {
            sqlCommand = [PublicSqliteMethod generateSalesOrderDataArray];
            sqlCommand = [NSString stringWithFormat:@"%@ %@",sqlCommand,@"where s1.SOH_Table = ? and s1.SOH_DocNo = ? and s1.SOH_Status = 'New' order by SOD_AutoNo"];
            rs1 = [db executeQuery:sqlCommand, tableDesc,soDocNo];
        }
        
        while ([rs1 next]) {
            
            NSMutableDictionary *data = [NSMutableDictionary dictionary];
        
            [data setObject:@"SalesOrderResult" forKey:@"IM_Flag"];
            
            //NSLog(@"%@",[rs1 stringForColumn:@"T_Percent"]);
            [data setObject:soDocNo forKey:@"SOH_DocNo"];
            [data setObject:[rs1 stringForColumn:@"IM_ItemNo"] forKey:@"IM_ItemNo"];
            [data setObject:[rs1 stringForColumn:@"IM_ItemCode"] forKey:@"IM_ItemCode"];
            [data setObject:[rs1 stringForColumn:@"IM_Description"] forKey:@"IM_Description"];
            [data setObject:[NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"IM_Price"]] forKey:@"IM_Price"];
            //one item selling price not included tax
            [data setObject:[rs1 stringForColumn:@"IM_SellingPrice"] forKey:@"IM_SellingPrice"];
            [data setObject:[rs1 stringForColumn:@"IM_DiscountInPercent"] forKey:@"IM_DiscountInPercent"];
            [data setObject:[rs1 stringForColumn:@"IM_Tax"] forKey:@"IM_Tax"];
            [data setObject:[NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"IM_Qty"]] forKey:@"IM_Qty"];
            
            // control enable gst
            if ([compEnableGst isEqualToString:@"0"]) {
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
            [data setObject:[rs1 stringForColumn:@"IM_TableName"] forKey:@"IM_TableName"];
            //-------for kitchen receipt ---------
            [data setObject:@"Printed" forKey:@"IM_Print"];
            [data setObject:[NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"IM_Qty"]] forKey:@"IM_OrgQty"];
            
            //------------tax code-----------------
            [data setObject:[rs1 stringForColumn:@"IM_TaxCode"] forKey:@"IM_GSTCode"];
            
            //-------------service tax-------------
            [data setObject:[rs1 stringForColumn:@"IM_ServiceTaxCode"] forKey:@"IM_ServiceTaxCode"];  //svc tax code
            [data setObject:[rs1 stringForColumn:@"IM_ServiceTaxAmt"] forKey:@"IM_ServiceTaxAmt"]; // service tax amount
            [data setObject:[rs1 stringForColumn:@"IM_ServiceTaxRate"] forKey:@"IM_ServiceTaxRate"];
            
            [data setObject:[rs1 stringForColumn:@"SOH_DocServiceTaxGstAmt"] forKey:@"SOH_DocServiceTaxGstAmt"];
            
            //serviceTaxGstTotal = [NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"SOH_DocServiceTaxGstAmt"]];
            
            //------for take away----------------
            [data setObject:[rs1 stringForColumn:@"IM_TakeAwayYN"] forKey:@"IM_TakeAwayYN"];
            
            //tableDesc = [rs1 stringForColumn:@"IM_TableName"];
            
            //------------------------------------
            [data setObject:[rs1 stringForColumn:@"SOH_PaxNo"] forKey:@"SOH_PaxNo"];
            [data setObject:docType forKey:@"PayDocType"];
            
            //for condiment
            [data setObject:@"ItemOrder" forKey:@"OrderType"];
            [data setObject:[NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"IM_TotalCondimentSurCharge"]] forKey:@"IM_TotalCondimentSurCharge"];
            [data setObject:@"0.00" forKey:@"IM_NewTotalCondimentSurCharge"];
            [data setObject:[rs1 stringForColumn:@"SOD_ManualID"] forKey:@"SOD_ManualID"];
            [data setObject:[rs1 stringForColumn:@"IM_ServiceType"] forKey:@"IM_ServiceType"];
            
            
            [data setObject:[rs1 stringForColumn:@"SOD_ModifierID"] forKey:@"SOD_ModifierID"];
            [data setObject:[rs1 stringForColumn:@"SOD_ModifierHdrCode"] forKey:@"SOD_ModifierHdrCode"];
            
            [data setObject:[rs1 stringForColumn:@"SOH_Rounding"] forKey:@"SOH_Rounding"];
            [data setObject:[rs1 stringForColumn:@"SOH_DocSubTotal"] forKey:@"SOH_DocSubTotal"];
            [data setObject:[rs1 stringForColumn:@"SOH_DiscAmt"] forKey:@"SOH_DiscAmt"];
            [data setObject:[rs1 stringForColumn:@"SOH_DocAmt"] forKey:@"SOH_DocAmt"];
            [data setObject:[rs1 stringForColumn:@"SOH_DocTaxAmt"] forKey:@"SOH_DocTaxAmt"];
            [data setObject:[rs1 stringForColumn:@"SOH_DocServiceTaxAmt"] forKey:@"SOH_DocServiceTaxAmt"];
            
            [data setValue:[rs1 stringForColumn:@"SOH_CustName"] forKey:@"CName"];
            [data setValue:[rs1 stringForColumn:@"SOH_CustAdd1"] forKey:@"CAdd1"];
            [data setValue:[rs1 stringForColumn:@"SOH_CustAdd2"] forKey:@"CAdd2"];
            [data setValue:[rs1 stringForColumn:@"SOH_CustAdd3"] forKey:@"CAdd3"];
            [data setValue:[rs1 stringForColumn:@"SOH_CustTelNo"] forKey:@"CTelNo"];
            [data setValue:[rs1 stringForColumn:@"SOH_CustGstNo"] forKey:@"CGstNo"];
            
            [resultArray addObject:data];
            
            if ([docType isEqualToString:@"CashSales"]) {
                [resultArray addObjectsFromArray:[PublicSqliteMethod getInvoiceCondimentWithDBPath:dbPath InvoiceNo:[data objectForKey:@"SOH_DocNo"] ItemCode:[data objectForKey:@"IM_ItemCode"] ManualID:[data objectForKey:@"SOD_ManualID"] ParentIndex:resultArray.count]];
            }
            else
            {
                [resultArray addObjectsFromArray:[PublicSqliteMethod getSalesOrderCondimentWithDBPath:dbPath SalesOrderNo:[data objectForKey:@"SOH_DocNo"] ItemCode:[data objectForKey:@"IM_ItemCode"] ManualID:[data objectForKey:@"SOD_ManualID"] ParentIndex:resultArray.count]];
            }
            
        }
        
    }];
    
    [queue close];
    
    NSData *dataToBeReturn = [NSKeyedArchiver archivedDataWithRootObject:resultArray];
    NSError *error;
    
    [_appDelegate.mcManager.session sendData:dataToBeReturn
                                     toPeers:selectedTerminal
                                    withMode:MCSessionSendDataReliable
                                       error:&error];
    
    
    resultArray = nil;
}

-(void)sendBackToTerminalWithPaymentSOResultSalesOrderDocNo:(NSString *)soDocNo TerminalDisplayName:(NSString *)displayName SelectedPeer:(NSArray *)selectedPeer PayDocType:(NSString *)payDocType
{
    
    NSMutableArray *resultArray;
    resultArray = [[NSMutableArray alloc]init];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rs1 = [db executeQuery:@"Select SOD_ItemCode as IM_ItemCode, SOD_ItemDescription as IM_Description,"
                            "SOD_Price as IM_Price2,SOD_Quantity as IM_Qty,SOD_DiscValue as IM_Discount,SOD_SellingPrice as IM_SellingPrice,"
                            "SOD_UnitPrice as IM_Price, SOD_Remark as IM_Remark, SOD_TakeAway_YN as IM_TakeAway_YN,"
                            "SOD_DiscType as IM_DiscountType, SOD_SellTax as IM_Tax, SOD_TotalSalesTax as IM_TotalTax,"
                            "SOD_TotalSalesTaxLong as IM_totalItemTaxAmtLong, SOD_TotalEx as IM_totalItemSellingAmt,"
                            "SOD_TotalExLong as IM_totalItemSellingAmtLong, SOD_TotalInc as IM_Total, SOD_TotalDisc as IM_DiscountAmt,SOD_SubTotal as IM_SubTotal,SOD_DiscInPercent as IM_DiscountInPercent,SOH_DocNo,SOD_DocNo,SOH_Status, SOH_DocAmt, SOH_DocSubTotal, SOH_DiscAmt, SOH_DocTaxAmt,SOH_DocServiceTaxAmt,SOH_DocServiceTaxGstAmt,IFNULL(T_Percent,'0') as T_Percent,SOH_Rounding, TP_Name as IM_TableName,IFNULL(T_Name,'-') as IM_TaxCode,"
                            " IFNULL(SOD_ServiceTaxCode,'-') as IM_ServiceTaxCode, SOD_ServiceTaxAmt as IM_ServiceTaxAmt, SOD_ServiceTaxRate as IM_ServiceTaxRate "
                            " ,SOD_TakeAwayYN as IM_TakeAwayYN, SOH_PaxNo,IFNULL(SOD_TotalCondimentSurCharge,'0.00') as IM_TotalCondimentSurCharge, SOD_ManualID, SOH_CustName,SOH_CustAdd1,SOH_CustAdd2,SOH_CustAdd3,SOH_CustTelNo,SOH_CustGstNo"
                            //" ,ifnull(IP_PrinterPort,'-') as IM_PrinterPort"
                            " from SalesOrderHdr s1"
                            " left join SalesOrderDtl s2"
                            " on s1.SOH_DocNo = s2.SOD_DocNo"
                            //" left join ItemMast I1 on s2.SOD_ItemNo = I1.IM_ItemCode"
                            " left join Tax T1 on s2.SOD_TaxCode = T1.T_Name"
                            //" left join ItemPrinter IP on s2.SOD_ItemNo = IP.IP_ItemNo"
                            //" left join Printer P on IP.IP_PrinterPort = P.P_PortName"
                            " left join TablePlan TP on s1.SOH_Table = TP.TP_Name"
                            " where s1.SOH_Status = 'New' and SOH_DocNo = ? order by SOD_AutoNo",soDocNo];
        
        
        if ([db hadError]) {
            //[self showAlertView:[dbTable lastErrorMessage] title:@"Fail"];
        }
        
        while ([rs1 next]) {
            
            NSMutableDictionary *data = [NSMutableDictionary dictionary];
            
            [data setObject:@"PaymentSOResult" forKey:@"IM_Flag"];
            [data setObject:soDocNo forKey:@"SOH_DocNo"];
            [data setObject:[rs1 stringForColumn:@"IM_ItemCode"] forKey:@"IM_ItemCode"];
            [data setObject:[rs1 stringForColumn:@"IM_Description"] forKey:@"IM_Description"];
            
            [data setObject:[NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"IM_Price"]] forKey:@"IM_Price"];
            //one item selling price not included tax
            [data setObject:[rs1 stringForColumn:@"IM_SellingPrice"] forKey:@"IM_SellingPrice"];
            [data setObject:[rs1 stringForColumn:@"IM_DiscountInPercent"] forKey:@"IM_DiscountInPercent"];
            [data setObject:[NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"IM_Price2"]] forKey:@"IM_SalesPrice"];
            NSLog(@"%@",[rs1 stringForColumn:@"IM_Price2"]);
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
            [data setObject:@"ItemOrder" forKey:@"OrderType"];
            [data setObject:[NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"IM_TotalCondimentSurCharge"]] forKey:@"IM_TotalCondimentSurCharge"];
            [data setObject:@"0.00" forKey:@"IM_NewTotalCondimentSurCharge"];
            [data setObject:[rs1 stringForColumn:@"SOD_ManualID"] forKey:@"SOD_ManualID"];
            [data setObject:[NSString stringWithFormat:@"%ld",resultArray.count + 1] forKey:@"Index"];
            
            //-------------service tax-------------
            [data setObject:[rs1 stringForColumn:@"IM_ServiceTaxCode"] forKey:@"IM_ServiceTaxCode"];  //svc tax code
            [data setObject:[rs1 stringForColumn:@"IM_ServiceTaxAmt"] forKey:@"IM_ServiceTaxAmt"]; // service tax amount
            [data setObject:[rs1 stringForColumn:@"IM_ServiceTaxRate"] forKey:@"IM_ServiceTaxRate"];
            
            //------ for take away -------------
            [data setObject:[NSString stringWithFormat:@"%d",[rs1 intForColumn:@"IM_TakeAwayYN"]] forKey:@"IM_TakeAwayYN"];
            
            //---------- table pax no --------------
            [data setObject:[rs1 stringForColumn:@"SOH_PaxNo"] forKey:@"SOH_PaxNo"];
            
            //---------- doc type -------------------
            [data setObject:payDocType forKey:@"PayDocType"];
            
            //-------------total amount
            [data setObject:[NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"SOH_Rounding"]] forKey:@"SOH_Rounding"];
            [data setObject:[NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"SOH_DocSubTotal"]] forKey:@"SOH_DocSubTotal"];
            [data setObject:[NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"SOH_DiscAmt"]] forKey:@"SOH_DiscAmt"];
            [data setObject:[NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"SOH_DocTaxAmt"]]forKey:@"SOH_DocTaxAmt"];
            
            [data setObject:[NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"SOH_DocAmt"]] forKey:@"SOH_DocAmt"];
            
            [data setObject:[NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"SOH_DocServiceTaxGstAmt"]] forKey:@"SOH_DocServiceTaxGstAmt"];
            [data setObject:[NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"SOH_DocServiceTaxAmt"]] forKey:@"SOH_DocServiceTaxAmt"];
            
            // for customer info
            /*
            [data setValue:[rs1 stringForColumn:@"SOH_CustName"] forKey:@"CName"];
            [data setValue:[rs1 stringForColumn:@"SOH_CustAdd1"] forKey:@"CAdd1"];
            [data setValue:[rs1 stringForColumn:@"SOH_CustAdd2"] forKey:@"CAdd2"];
            [data setValue:[rs1 stringForColumn:@"SOH_CustAdd3"] forKey:@"CAdd3"];
            [data setValue:[rs1 stringForColumn:@"SOH_CustTelNo"] forKey:@"CTelNo"];
            [data setValue:[rs1 stringForColumn:@"SOH_CustGstNo"] forKey:@"CGstNo"];
            */
            // special use for some feature
            [data setObject:@"1" forKey:@"IvH_PaymentTypeQty"];
            [data setObject:@"0.00" forKey:@"SOH_ChangeAmt"];
            [data setObject:@"0.00" forKey:@"SOH_PayAmt"];
            
            //------------------------------------------------
            [data setObject:@"-" forKey:@"IvH_PaymentType1"];
            [data setObject:@"0.00" forKey:@"IvH_PaymentAmt1"];
            [data setObject:@"-" forKey:@"IvH_PaymentRef1"];
            
            [data setObject:@"-" forKey:@"IvH_PaymentType2"];
            [data setObject:@"0.00" forKey:@"IvH_PaymentAmt2"];
            [data setObject:@"-" forKey:@"IvH_PaymentRef2"];
            
            [data setObject:@"-" forKey:@"IvH_PaymentType3"];
            [data setObject:@"0.00" forKey:@"IvH_PaymentAmt3"];
            [data setObject:@"-" forKey:@"IvH_PaymentRef3"];
            
            [data setObject:@"-" forKey:@"IvH_PaymentType4"];
            [data setObject:@"0.00" forKey:@"IvH_PaymentAmt4"];
            [data setObject:@"-" forKey:@"IvH_PaymentRef4"];
            
            [data setObject:@"-" forKey:@"IvH_PaymentType5"];
            [data setObject:@"0.00" forKey:@"IvH_PaymentAmt5"];
            [data setObject:@"-" forKey:@"IvH_PaymentRef5"];
            
            [data setObject:@"-" forKey:@"IvH_PaymentType6"];
            [data setObject:@"0.00" forKey:@"IvH_PaymentAmt6"];
            [data setObject:@"-" forKey:@"IvH_PaymentRef6"];
            
            [data setObject:@"-" forKey:@"IvH_PaymentType7"];
            [data setObject:@"0.00" forKey:@"IvH_PaymentAmt7"];
            [data setObject:@"-" forKey:@"IvH_PaymentRef7"];
            
            [data setObject:@"-" forKey:@"IvH_PaymentType8"];
            [data setObject:@"0.00" forKey:@"IvH_PaymentAmt8"];
            [data setObject:@"-" forKey:@"IvH_PaymentRef8"];
            
            // for data ref
            [data setObject:@"" forKey:@"IvH_DocRef"];
            
            // for client user
            [data setObject:@"Client" forKey:@"IvH_UserName"];
            
            
            [resultArray addObject:data];
            
            [resultArray addObjectsFromArray:[PublicSqliteMethod getSalesOrderCondimentWithDBPath:dbPath SalesOrderNo:[data objectForKey:@"SOH_DocNo"] ItemCode:[data objectForKey:@"IM_ItemCode"] ManualID:[data objectForKey:@"SOD_ManualID"] ParentIndex:resultArray.count]];
            
        }
        [rs1 close];
        
    }];
    [queue close];
    
    //NSLog(@"%@",[[resultArray objectAtIndex:0] objectForKey:@"IM_Flag"]);
    
    NSData *dataToBeReturn = [NSKeyedArchiver archivedDataWithRootObject:resultArray];
    NSError *error;
    
    [_appDelegate.mcManager.session sendData:dataToBeReturn
                                     toPeers:selectedPeer
                                    withMode:MCSessionSendDataReliable
                                       error:&error];
    
    /*
    for (int i = 0; i < [[_appDelegate.mcManager connectedPeerArray]count]; i++) {
        NSArray *allPeers = [[_appDelegate.mcManager session] connectedPeers];
        NSString *connectedPeerName;
        MCPeerID *onePeer = [allPeers objectAtIndex:i];
        
        connectedPeerName = onePeer.displayName;
        
        if ([connectedPeerName isEqualToString:displayName]) {
            NSArray *oneArray = @[[_appDelegate.mcManager.session.connectedPeers objectAtIndex:i]];
            [_appDelegate.mcManager.session sendData:dataToBeReturn
                                             toPeers:oneArray
                                            withMode:MCSessionSendDataReliable
                                               error:&error];
            
        }
        
        if (error) {
            NSLog(@"Erro : %@", [error localizedDescription]);
        }
    }
     */
    
    
    //[dbTable close];
    resultArray = nil;

}

-(void)sendBackToTerminalWithInsertInvoiceResult:(NSString *)result Message:(NSString *)message
{
    [returnData removeAllObjects];
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    
    //[data setObject:[NSString stringWithFormat:@"%ld",(long)_im_ItemNo] forKey:@"IM_ItemNo"];
    [data setObject:result forKey:@"Result"];
    [data setObject:message forKey:@"Message"];
    [data setObject:@"InsertInvoiceResult" forKey:@"IM_Flag"];
    
    [returnData addObject:data];
    NSData *dataToBeReturn = [NSKeyedArchiver archivedDataWithRootObject:returnData];
    NSError *error;
    for (int i = 0; i < [[_appDelegate.mcManager connectedPeerArray]count]; i++) {
        NSArray *allPeers = [[_appDelegate.mcManager session] connectedPeers];
        NSString *connectedPeerName;
        MCPeerID *onePeer = [allPeers objectAtIndex:i];
        
        connectedPeerName = onePeer.displayName;
        
        if ([connectedPeerName isEqualToString:peerID.displayName]) {
            NSArray *oneArray = @[[_appDelegate.mcManager.session.connectedPeers objectAtIndex:i]];
            [_appDelegate.mcManager.session sendData:dataToBeReturn
                                             toPeers:oneArray
                                            withMode:MCSessionSendDataReliable
                                               error:&error];
            
        }
        
        if (error) {
            NSLog(@"Erro : %@", [error localizedDescription]);
        }
    }
}

-(void)sendBackToTerminalWithSplitBillResult:(NSString *)result SONo:(NSArray *)soNoArray
{
    [returnData removeAllObjects];
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    
    //[data setObject:[NSString stringWithFormat:@"%ld",(long)_im_ItemNo] forKey:@"IM_ItemNo"];
    [data setObject:result forKey:@"Result"];
    [data setObject:@"-" forKey:@"Message"];
    [data setObject:soNoArray[1] forKey:@"NewSODocNo"];
    [data setObject:soNoArray[0] forKey:@"OrgSODocNo"];
    [data setObject:soNoArray[2] forKey:@"PayForWhichSO"];
    [data setObject:@"SplitBillSOResult" forKey:@"IM_Flag"];
    
    [returnData addObject:data];
    NSData *dataToBeReturn = [NSKeyedArchiver archivedDataWithRootObject:returnData];
    NSError *error;
    for (int i = 0; i < [[_appDelegate.mcManager connectedPeerArray]count]; i++) {
        NSArray *allPeers = [[_appDelegate.mcManager session] connectedPeers];
        NSString *connectedPeerName;
        MCPeerID *onePeer = [allPeers objectAtIndex:i];
        
        connectedPeerName = onePeer.displayName;
        
        if ([connectedPeerName isEqualToString:peerID.displayName]) {
            NSArray *oneArray = @[[_appDelegate.mcManager.session.connectedPeers objectAtIndex:i]];
            [_appDelegate.mcManager.session sendData:dataToBeReturn
                                             toPeers:oneArray
                                            withMode:MCSessionSendDataReliable
                                               error:&error];
            
        }
        
        if (error) {
            NSLog(@"Erro : %@", [error localizedDescription]);
        }
    }
}

-(void)sendBacktoTerminalSalesOrderSplitBillWithTableName:(NSString *)tbName SalesOrderNo:(NSString *)soNo TerminalDisplayName:(NSString *)displayName SelectedPeer:(NSArray *)selectedPeer ServiceTaxGstPercent:(double)svcGstPercent
{
    NSMutableArray *resultArray;
    resultArray = [[NSMutableArray alloc]init];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        
        NSString *itemServiceTaxGst;
        NSString *itemServiceTaxGstLong;
        
        FMResultSet *rs1 = [db executeQuery:@"Select SOD_ItemCode as IM_ItemCode, SOD_ItemDescription as IM_Description,"
                            "SOD_Price as IM_Price2,SOD_Quantity as IM_Qty,SOD_DiscValue as IM_Discount,SOD_SellingPrice as IM_SellingPrice,"
                            "SOD_UnitPrice as IM_Price, SOD_Remark as IM_Remark, SOD_TakeAway_YN as IM_TakeAway_YN,"
                            "SOD_DiscType as IM_DiscountType, SOD_SellTax as IM_Tax, SOD_TotalSalesTax as IM_TotalTax,"
                            "SOD_TotalSalesTaxLong as IM_totalItemTaxAmtLong, SOD_TotalEx as IM_totalItemSellingAmt,"
                            "SOD_TotalExLong as IM_totalItemSellingAmtLong, SOD_TotalInc as IM_Total, SOD_TotalDisc as IM_DiscountAmt,SOD_SubTotal as IM_SubTotal,SOD_DiscInPercent as IM_DiscountInPercent,SOH_DocNo,SOD_DocNo,SOH_Status, SOH_DocAmt, SOH_DocSubTotal, SOH_DiscAmt, SOH_DocTaxAmt,SOH_DocServiceTaxAmt, SOH_DocServiceTaxGstAmt,SOH_Rounding,IFNULL(T_Percent,'0') as T_Percent,IFNULL(T_Name,'-') as IM_TaxCode"
                            " , IFNULL(SOD_ServiceTaxCode,'-') as IM_ServiceTaxCode, SOD_ServiceTaxAmt as IM_ServiceTaxAmt, SOD_ServiceTaxRate as IM_ServiceTaxRate "
                            " ,SOD_TakeAwayYN as IM_TakeAwayYN, SOH_PaxNo,IFNULL(SOD_TotalCondimentSurCharge,'0.00') as IM_TotalCondimentSurCharge, SOD_ManualID, SOD_ModifierID, SOD_ModifierHdrCode"
                            " from SalesOrderHdr s1"
                            " left join SalesOrderDtl s2"
                            " on s1.SOH_DocNo = s2.SOD_DocNo"
                            //" left join ItemMast I1 on s2.SOD_ItemNo = I1.IM_ItemCode"
                            " left join Tax T1 on s2.SOD_TaxCode = T1.T_Name"
                            " where s1.SOH_Table = ? and s1.SOH_Status = 'New' and SOH_DocNo = ? order by SOD_AutoNo", tbName,soNo];
        
        
        if ([db hadError]) {
            //[self showAlertView:[dbTable lastErrorMessage] title:@"Fail"];
        }
        
        while ([rs1 next]) {
            
            //docNo = [rs1 stringForColumn:@"SOH_DocNo"];
            NSMutableDictionary *data = [NSMutableDictionary dictionary];
            //[orderFinalArray addObject:[rs1 resultDictionary]];
            
            //self.soO.text = [rs1 stringForColumn:@"SOH_DocNo"];
            [data setObject:@"OldSO" forKey:@"SplitType"];
            
            [data setObject:[rs1 stringForColumn:@"IM_ItemCode"] forKey:@"IM_ItemCode"];
            [data setObject:[rs1 stringForColumn:@"IM_Description"] forKey:@"IM_Description"];
            [data setObject:[NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"IM_Price"]] forKey:@"IM_Price"];
            [data setObject:[NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"IM_Price2"]] forKey:@"IM_SalesPrice"];
            //one item selling price not included tax
            [data setObject:[rs1 stringForColumn:@"IM_SellingPrice"] forKey:@"IM_SellingPrice"];
            [data setObject:[rs1 stringForColumn:@"IM_DiscountInPercent"] forKey:@"IM_DiscountInPercent"];
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
            
            //---------tax code-------------
            [data setObject:[rs1 stringForColumn:@"IM_TaxCode"] forKey:@"IM_GSTCode"];
            
            //-------------for table pax ---------------------------
            [data setObject:[rs1 stringForColumn:@"SOH_PaxNo"] forKey:@"SOH_PaxNo"];
            
            [data setObject:@"ItemOrder" forKey:@"OrderType"];
            [data setObject:[NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"IM_TotalCondimentSurCharge"]] forKey:@"IM_TotalCondimentSurCharge"];
            [data setObject:@"0.00" forKey:@"IM_NewTotalCondimentSurCharge"];
            [data setObject:[rs1 stringForColumn:@"SOD_ManualID"] forKey:@"SOD_ManualID"];
            [data setObject:[NSString stringWithFormat:@"%ld",resultArray.count + 1] forKey:@"Index"];
            
            //-------------service tax-------------
            
            if ([[[LibraryAPI sharedInstance] getTaxType] isEqualToString:@"Inc"]) {
                itemServiceTaxGst = [NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"IM_ServiceTaxAmt"] * (svcGstPercent / 100)];
                itemServiceTaxGstLong = [NSString stringWithFormat:@"%0.6f",[rs1 doubleForColumn:@"IM_ServiceTaxAmt"] * (svcGstPercent/100)];
            }
            else
            {
                itemServiceTaxGst = @"0.00";
                itemServiceTaxGstLong = [rs1 stringForColumn:@"IM_ServiceTaxAmt"];
            }
            
            
            [data setObject:[rs1 stringForColumn:@"IM_ServiceTaxCode"] forKey:@"IM_ServiceTaxCode"];  //svc tax code
            [data setObject:[rs1 stringForColumn:@"IM_ServiceTaxAmt"] forKey:@"IM_ServiceTaxAmt"]; // service tax amount
            [data setObject:[rs1 stringForColumn:@"IM_ServiceTaxRate"] forKey:@"IM_ServiceTaxRate"];
            
            [data setObject:itemServiceTaxGst forKey:@"IM_ServiceTaxGstAmt"];
            [data setObject:itemServiceTaxGstLong forKey:@"IM_ServiceTaxGstAmtLong"];
            //serviceTaxGstTotal123 = [NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"SOH_DocServiceTaxGstAmt"]];
            
            //-----------for take away----------------------
            [data setObject:[NSString stringWithFormat:@"%d",[rs1 intForColumn:@"IM_TakeAwayYN"]] forKey:@"IM_TakeAwayYN"];
            
            [data setObject:[rs1 stringForColumn:@"IM_Remark"] forKey:@"IM_Remark"];
            
            //------------ for transfer data use ----------------
            [data setObject:@"SaleOrderRequestSplit" forKey:@"IM_Flag"];
            [data setObject:[rs1 stringForColumn:@"SOH_DocNo"] forKey:@"IM_DocNo"];
            [data setObject:tbName forKey:@"SOH_TableName"];
            [data setObject:@"1" forKey:@"IM_InsertSplitFlag"];
            
            [data setObject:[rs1 stringForColumn:@"SOH_DocSubTotal"] forKey:@"SOH_DocSubTotal"];
            [data setObject:[rs1 stringForColumn:@"SOH_DiscAmt"] forKey:@"SOH_DiscAmt"];
            [data setObject:[rs1 stringForColumn:@"SOH_DocTaxAmt"] forKey:@"SOH_DocTaxAmt"];
            [data setObject:[rs1 stringForColumn:@"SOH_DocAmt"] forKey:@"SOH_DocAmt"];
            [data setObject:[rs1 stringForColumn:@"SOH_Rounding"] forKey:@"SOH_Rounding"];
            [data setObject:[NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"SOH_DocServiceTaxAmt"]] forKey:@"SOH_DocServiceTaxAmt"];
            [data setObject:@"0.00" forKey:@"SOH_DocServiceTaxGstAmt"];
            [data setObject:@"OrgSplitSO" forKey:@"PayForWhich"];
            
            [data setObject:[rs1 stringForColumn:@"SOD_ModifierID"] forKey:@"SOD_ModifierID"];
            [data setObject:[rs1 stringForColumn:@"SOD_ModifierHdrCode"] forKey:@"SOD_ModifierHdrCode"];
            
            if ([[rs1 stringForColumn:@"SOD_ModifierHdrCode"]length] > 0) {
                [data setObject:@"PackageItemOrder" forKey:@"OrderType"];
                [data setObject:@"Yes" forKey:@"UnderPackageItemYN"];
                [data setObject:@"1" forKey:@"PD_MinChoice"];
                [data setObject:@"00" forKey:@"PackageItemIndex"];
                [data setObject:[rs1 stringForColumn:@"SOD_ModifierHdrCode"] forKey:@"PD_ModifierHdrCode"];
            }
            else
            {
                [data setObject:@"No" forKey:@"UnderPackageItemYN"];
                [data setObject:@"ItemOrder" forKey:@"OrderType"];
                [data setObject:@"1" forKey:@"PD_MinChoice"];
            }
            
            if ([[rs1 stringForColumn:@"SOD_ModifierHdrCode"] isEqualToString:[rs1 stringForColumn:@"IM_ItemCode"]])
            {
                [data setObject:@"ItemMast" forKey:@"PD_ItemType"];
            }
            else{
                [data setObject:@"Modifier" forKey:@"PD_ItemType"];
            }
            
            if ([[rs1 stringForColumn:@"SOD_ModifierHdrCode"]length] == 0 && [[rs1 stringForColumn:@"SOD_ModifierID"] length] > 0) {
                [data setObject:@"1" forKey:@"IM_ServiceType"];
            }
            
            
            [resultArray addObject:data];
            //NSLog(@"test get doc no %@",[data objectForKey:@"IM_DocNo"]);
            [resultArray addObjectsFromArray:[PublicSqliteMethod getSalesOrderCondimentWithDBPath:dbPath SalesOrderNo:[data objectForKey:@"IM_DocNo"] ItemCode:[data objectForKey:@"IM_ItemCode"] ManualID:[data objectForKey:@"SOD_ManualID"] ParentIndex:resultArray.count]];
            
        }
        [rs1 close];
        
    }];
    
    [queue close];
    
    NSData *dataToBeReturn = [NSKeyedArchiver archivedDataWithRootObject:resultArray];
    NSError *error;
    
    [_appDelegate.mcManager.session sendData:dataToBeReturn
                                     toPeers:selectedPeer
                                    withMode:MCSessionSendDataReliable
                                       error:&error];

    resultArray = nil;
    
}

-(void)sendBacktoTerminalMultipleSalesOrderWithTableName:(NSString *)tbName TerminalDisplayName:(NSString *)displayName SelectedPeer:(NSArray *)selectedPeer
{
    
    NSMutableArray *resultArray;
    resultArray = [[NSMutableArray alloc]init];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
    
        FMResultSet *rs = [db executeQuery:@"Select *, 'MultipleSaleOrderRequestResult' as 'IM_Flag' from SalesOrderHdr s1 left join TablePlan tp on"
                           " s1.SOH_Table = tp.TP_Name where s1.SOH_Table = ? and s1.SOH_Status = ?",tbName,@"New"];
        while ([rs next]) {
            //tbName = [rs stringForColumn:@"TP_Name"];
            [resultArray addObject:[rs resultDictionary]];
        }
        [rs close];
    
    }];
    
    
    [queue close];
    
    NSData *dataToBeReturn = [NSKeyedArchiver archivedDataWithRootObject:resultArray];
    NSError *error;
    resultArray = nil;
    [_appDelegate.mcManager.session sendData:dataToBeReturn
                                     toPeers:selectedPeer
                                    withMode:MCSessionSendDataReliable
                                       error:&error];
    /*
    for (int i = 0; i < [[_appDelegate.mcManager connectedPeerArray]count]; i++) {
        NSArray *allPeers = [[_appDelegate.mcManager session] connectedPeers];
        NSString *connectedPeerName;
        MCPeerID *onePeer = [allPeers objectAtIndex:i];
        
        connectedPeerName = onePeer.displayName;
        
        if ([connectedPeerName isEqualToString:displayName]) {
            NSArray *oneArray = @[[_appDelegate.mcManager.session.connectedPeers objectAtIndex:i]];
            [_appDelegate.mcManager.session sendData:dataToBeReturn
                                             toPeers:oneArray
                                            withMode:MCSessionSendDataReliable
                                               error:&error];
            
        }
        
        if (error) {
            NSLog(@"Erro : %@", [error localizedDescription]);
        }
    }
     */
    
    resultArray = nil;
}

-(void)sendBackToTerminalSalesOrderFilteringResultWithSelectedPeer:(NSArray *)selectedPeer KeyWord:(NSString *)keyWord
{
    NSMutableArray *resultArray;
    resultArray = [[NSMutableArray alloc]init];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"select * from (Select IvH_DocNo,IvH_DocAmt, IvH_Status,IvH_Date, (IvH_DocNo || IvH_Table) as FilterColumn, 'FilteringSalesOrderResult' as 'IM_Flag', '1' as DataCount from InvoiceHdr order by IvH_DocNo desc limit 100) Tb1 where FilterColumn like ?", [NSString stringWithFormat:@"%@%@%@",@"%",keyWord,@"%"]];;
        while ([rs next]) {
            //tbName = [rs stringForColumn:@"TP_Name"];
            [resultArray addObject:[rs resultDictionary]];
        }
        [rs close];
        
    }];
    
    [queue close];
    
    NSData *dataToBeReturn = [NSKeyedArchiver archivedDataWithRootObject:resultArray];
    NSError *error;
    resultArray = nil;
    [_appDelegate.mcManager.session sendData:dataToBeReturn
                                     toPeers:selectedPeer
                                    withMode:MCSessionSendDataReliable
                                       error:&error];
    
}

-(void)sendBackToTerminalEditBillFilteringResultWithSelectedPeer:(NSArray *)selectedPeer KeyWord:(NSString *)keyWord
{
    NSMutableArray *resultArray;
    resultArray = [[NSMutableArray alloc]init];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"select * from (Select IvH_DocNo,IvH_DocAmt, IvH_Date, IvH_Table, IvH_PaxNo, IvH_Status, (IvH_DocNo || IvH_Table) as FilterColumn, 'FilteringEditBillResult' as 'IM_Flag' from InvoiceHdr order by IvH_DocNo desc limit 100) Tb1 left join TablePlan TP on Tb1.IvH_Table = TP.TP_Name where FilterColumn like ?", [NSString stringWithFormat:@"%@%@%@",@"%",keyWord,@"%"]];
        
        while ([rs next]) {
            //tbName = [rs stringForColumn:@"TP_Name"];
            [resultArray addObject:[rs resultDictionary]];
        }
        [rs close];
        
    }];
    
    [queue close];
    
    NSData *dataToBeReturn = [NSKeyedArchiver archivedDataWithRootObject:resultArray];
    NSError *error;
    resultArray = nil;
    [_appDelegate.mcManager.session sendData:dataToBeReturn
                                     toPeers:selectedPeer
                                    withMode:MCSessionSendDataReliable
                                       error:&error];
    
}

-(void)sendBackToTerminalSalesOrderNoResultWithSelectedPeer:(NSArray *)selectedPeer TableName:(NSString *)tableName
{

    NSMutableArray *resultArray;
    resultArray = [[NSMutableArray alloc]init];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rsSO = [db executeQuery:@"Select SOH_Table, SOH_DocAmt,SOH_DocNo, 'SalesOrderNoResult' as IM_Flag, 'True' as Result, '2' as DataCount from SalesOrderHdr where SOH_Status = ? and SOH_Table = ?",@"New",tableName];
        
        while ([rsSO next]) {
            [resultArray addObject:[rsSO resultDictionary]];
        }
        
        [rsSO close];
        
        if (resultArray.count > 0) {
            FMResultSet *rsTable = [db executeQuery:@"Select TP_Name,TP_Percent, TP_Overide,TP_DineType from TablePlan where TP_Name = ?",tableName];
            
            if ([rsTable next]) {
                NSMutableDictionary *data = [NSMutableDictionary dictionary];
                
                [data setObject:[rsTable stringForColumn:@"TP_Name"] forKey:@"TP_Name"];
                [data setObject:[rsTable stringForColumn:@"TP_Percent"] forKey:@"TP_Percent"];
                [data setObject:[rsTable stringForColumn:@"TP_Overide"] forKey:@"TP_Overide"];
                [data setObject:[rsTable stringForColumn:@"TP_DineType"] forKey:@"TP_DineType"];
                [resultArray addObject:data];
                
                data = nil;
            }
            
        }
        
    }];
    
    [queue close];
    
    if (resultArray.count == 0) {
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        
        [data setObject:@"Request" forKey:@"Result"];
        [data setObject:@"-" forKey:@"Message"];
        [data setObject:@"SalesOrderNoResult" forKey:@"IM_Flag"];
        [data setObject:@"0" forKey:@"DataCount"];
        
        [resultArray addObject:data];
        data = nil;
    }
    
    NSData *dataToBeReturn = [NSKeyedArchiver archivedDataWithRootObject:resultArray];
    NSError *error;
    resultArray = nil;
    [_appDelegate.mcManager.session sendData:dataToBeReturn
                                     toPeers:selectedPeer
                                    withMode:MCSessionSendDataReliable
                                       error:&error];
    
}

-(void)sendBackToTerminalWithRecalculateSalesOrderResult:(NSArray *)selectedPeer FromSalesOrderNo:(NSString *)fromSalesOrderNo SelectedTbName:(NSString *)selectedTbName SelectedDineType:(int)dineType Date:(NSString *)todayDate ItemServeTypeFlag:(NSString *)itemServeTypeFlag OptionSelected:(NSString *)optionSelected ToSalesOrderNo:(NSString *)toSalesOrderNo
{
    NSMutableArray *recalcTransferSalesArray = [[NSMutableArray alloc] init];
    NSDictionary *totalDict = [NSDictionary dictionary];
    NSMutableDictionary *settingDict = [NSMutableDictionary dictionary];
    
    settingDict = [PublicSqliteMethod getGeneralnTableSettingWithTableName:selectedTbName dbPath:dbPath];
    
    [recalcTransferSalesArray addObjectsFromArray:[PublicSqliteMethod recalculateSalesOrderResultWithFromSalesOrderNo:fromSalesOrderNo SelectedTbName:selectedTbName SelectedDineType:dineType Date:todayDate ItemServeTypeFlag:itemServeTypeFlag OptionSelected:optionSelected ToSalesOrderNo:toSalesOrderNo DBPath:dbPath]];
    /*
    
    NSMutableArray *transferSalesArray = [[NSMutableArray alloc] init];
    NSArray *recalcTransferArray;
    
    
    NSMutableArray *salesOrderDetailArray = [[NSMutableArray alloc] init];
    
    if ([optionSelected isEqualToString:@"TransferTable"]) {
        salesOrderDetailArray = [PublicSqliteMethod getTransferSa//lesOrderDetailWithDbPath:dbPath SalesOrderNo:fromSalesOrderNo];
    }
    else
    {
        salesOrderDetailArray = [PublicSqliteMethod publicCombineTwoTableWithFromSalesOrder:fromSalesOrderNo ToSalesOrder:toSalesOrderNo DBPath:dbPath];
    }
    
    
    if (![itemServeTypeFlag isEqualToString:@"-"]) {
        for (int i = 0; i < salesOrderDetailArray.count; i++) {
            NSMutableDictionary *data = [NSMutableDictionary dictionary];
            data = [salesOrderDetailArray objectAtIndex:i];
            [data setValue:itemServeTypeFlag forKey:@"SOD_TakeAwayYN"];
            [salesOrderDetailArray replaceObjectAtIndex:i withObject:data];
            data = nil;
        }
    }
    
    
    for (int i = 0; i < salesOrderDetailArray.count; i++) {
        
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        
        [data setObject:[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"SOD_DiscInPercent"] forKey:@"DiscInPercent"];
        [data setObject:[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"SOD_Quantity"] forKey:@"ItemQty"];
        [data setObject:[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"SOD_DiscValue"] forKey:@"DiscValue"];
        [data setObject:[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"SOD_DiscType"] forKey:@"DiscType"];
        [data setObject:[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"SOD_TotalDisc"] forKey:@"TotalDisc"];
        [data setObject:[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"SOD_Remark"] forKey:@"Remark"];
        [data setObject:[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"IM_TotalCondimentSurCharge"] forKey:@"IM_TotalCondimentSurCharge"];
        [data setObject:[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"SOD_Quantity"] forKey:@"OrgQty"];
    
        settingDict = [PublicSqliteMethod getGeneralnTableSettingWithTableName:selectedTbName dbPath:dbPath];
        
        
        transferSalesArray = [PublicSqliteMethod calcGSTByItemNo:[[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"IM_ItemNo"] integerValue] DBPath:dbPath ItemPrice:[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"SOD_UnitPrice"] CompEnableGst:[[settingDict objectForKey:@"EnableGst"] integerValue] CompEnableSVG:[[settingDict objectForKey:@"EnableSVG"] integerValue] TableSVC:[settingDict objectForKey:@"TableSVGPercent"] OverrideSVG:[settingDict objectForKey:@"TableSVGOverRide"] SalesOrderStatus:@"Edit" TaxType:[[LibraryAPI sharedInstance] getTaxType] TableName:selectedTbName ItemDineStatus:[NSString stringWithFormat:@"%@",[NSNumber numberWithInt:[[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"SOD_TakeAwayYN"]integerValue]]] TerminalType:[[LibraryAPI sharedInstance] getWorkMode] SalesDict:data IMQty:@"0" KitchenStatus:@"Printed" PaxNo:[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"SOH_PaxNo"] DocType:@"SalesOrder" CondimentSubTotal:[[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"IM_TotalCondimentSurCharge"] doubleValue] ServiceChargeGstPercent:[[LibraryAPI sharedInstance] getServiceTaxGstPercent] TableDineStatus:[NSString stringWithFormat:@"%d",dineType]];
        
        NSDictionary *data2 = [NSDictionary dictionary];
        data2 = [transferSalesArray objectAtIndex:0];
        //[data2 setValue:[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"CondimentKey"] forKey:@"Index"];
        [data2 setValue:[NSString stringWithFormat:@"%ld",recalcTransferSalesArray.count + 1] forKey:@"Index"];
        
        [data2 setValue:[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"SOD_ManualID"]  forKey:@"SOD_ManualID"];
        [data2 setValue:[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"SOD_ModifierID"] forKey:@"SOD_ModifierID"];
        [data2 setValue:[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"SOD_ModifierHdrCode"] forKey:@"SOD_ModifierHdrCode"];
        [data2 setValue:[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"OrderType"] forKey:@"OrderType"];
        
        [transferSalesArray replaceObjectAtIndex:0 withObject:data2];
        data2 = nil;
        
        recalcTransferArray = [PublicSqliteMethod recalculateGSTSalesOrderWithSalesOrderArray:transferSalesArray TaxType:[[LibraryAPI sharedInstance] getTaxType]];
        
        [recalcTransferSalesArray addObjectsFromArray:recalcTransferArray];
        
        [recalcTransferSalesArray addObjectsFromArray:[PublicSqliteMethod getSalesOrderCondimentWithDBPath:dbPath SalesOrderNo:[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"OldSOD_DocNo"] ItemCode:[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"SOD_ItemCode"] ManualID:[[salesOrderDetailArray objectAtIndex:i] objectForKey:@"OldSOD_ManualID"] ParentIndex:[[[transferSalesArray objectAtIndex:0] objectForKey:@"Index"] integerValue]]];
    
    }
    */
    totalDict = [PublicSqliteMethod calclateSalesTotalWith:recalcTransferSalesArray TaxType:[[LibraryAPI sharedInstance] getTaxType] ServiceTaxGst:[[settingDict objectForKey:@"ServiceTaxGstPercent"] doubleValue] DBPath:dbPath];
    
    settingDict = nil;
    
    
    NSDictionary *dataTotal = [NSDictionary dictionary];
    dataTotal = [recalcTransferSalesArray objectAtIndex:0];
    
    [dataTotal setValue:[totalDict objectForKey:@"Total"]  forKey:@"IM_labelTotal"];
    [dataTotal setValue:[totalDict objectForKey:@"TotalDiscount"]  forKey:@"IM_labelTotalDiscount"];
    [dataTotal setValue:[totalDict objectForKey:@"Rounding"]  forKey:@"IM_labelRound"];
    [dataTotal setValue:[totalDict objectForKey:@"SubTotal"]  forKey:@"IM_labelSubTotal"];
    [dataTotal setValue:[totalDict objectForKey:@"TotalGst"]  forKey:@"IM_labelTaxTotal"];
    [dataTotal setValue:[totalDict objectForKey:@"ServiceCharge"]  forKey:@"IM_labelServiceTaxTotal"];
    [dataTotal setValue:[totalDict objectForKey:@"TotalServiceChargeGst"]  forKey:@"IM_serviceTaxGstTotal"];
    
    [recalcTransferSalesArray replaceObjectAtIndex:0 withObject:dataTotal];
    dataTotal = nil;
    
    if ([optionSelected isEqualToString:@"TransferTable"]) {
        [TerminalData updateSalesOrderIntoMainWithOrderType:@"sales" sqlitePath:dbPath OrderData:recalcTransferSalesArray OrderDate:todayDate DocNo:fromSalesOrderNo terminalArray:selectedPeer terminalName:peerID.displayName ToWhichView:@"Transfer" PayType:@"Other" OptionSelected:optionSelected FromSalesOrderNo:fromSalesOrderNo];
    }
    else
    {
        [TerminalData updateSalesOrderIntoMainWithOrderType:@"sales" sqlitePath:dbPath OrderData:recalcTransferSalesArray OrderDate:todayDate DocNo:toSalesOrderNo terminalArray:selectedPeer terminalName:peerID.displayName ToWhichView:@"Transfer" PayType:@"Other" OptionSelected:optionSelected FromSalesOrderNo:fromSalesOrderNo];
    }
    
    
    //transferSalesArray = nil;
    //recalcTransferArray = nil;
    recalcTransferSalesArray = nil;
    totalDict = nil;
    
}

-(void)sendBackToTerminalAllTableResultWithSelectedPeer:(NSArray *)selectedPeer OptionSelected:(NSString *)optionSelected FromTableName:(NSString *)fromTableName ToTableName:(NSString *)toTableName
{
    
    NSMutableArray *resultArray;
    resultArray = [[NSMutableArray alloc]init];
    
    if ([optionSelected isEqualToString:@"TransferTable"]) {
        [resultArray addObjectsFromArray:[PublicSqliteMethod getAllTableListWithDbPath:dbPath FromTableName:fromTableName]];
    }
    else
    {
        //[resultArray addObjectsFromArray:[PublicSqliteMethod getCombineTableListWithDbPath:dbPath FromTableName:fromTableName]];
        [resultArray addObjectsFromArray:[PublicSqliteMethod getParticularCombineTableListWithDbPath:dbPath TableName:toTableName]];
    }
    /*
    NSMutableArray *resultArray;
    resultArray = [[NSMutableArray alloc]init];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rsFreeTable = [db executeQuery:@"Select TP_Name, TP_ID, TP_DineType, 'FreeTableResult' as IM_Flag, 'True' as Result from TablePlan where TP_Name Not In (Select SOH_Table from SalesOrderHdr where SOH_Status = ?)",@"New"];
        
        while ([rsFreeTable next]) {
            [resultArray addObject:[rsFreeTable resultDictionary]];
        }
        
        [rsFreeTable close];
        
        if (resultArray.count == 0) {
            NSMutableDictionary *data = [NSMutableDictionary dictionary];
            
            [data setObject:@"False" forKey:@"Result"];
            [data setObject:@"-" forKey:@"Message"];
            [data setObject:@"FreeTableResult" forKey:@"IM_Flag"];
            //[data setObject:@"0" forKey:@"DataCount"];
            
            [resultArray addObject:data];
            data = nil;
        }
        
    }];
    
    [queue close];
    */
    
    if (resultArray.count == 0) {
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        
        [data setObject:@"False" forKey:@"Result"];
        [data setObject:@"-" forKey:@"Message"];
        [data setObject:@"AllTableResult" forKey:@"IM_Flag"];
        
        [resultArray addObject:data];
        data = nil;
    }
    
    NSData *dataToBeReturn = [NSKeyedArchiver archivedDataWithRootObject:resultArray];
    NSError *error;
    resultArray = nil;
    [_appDelegate.mcManager.session sendData:dataToBeReturn
                                     toPeers:selectedPeer
                                    withMode:MCSessionSendDataReliable
                                       error:&error];
    
}

-(void)sendBackToTerminalWithMultiTransferSOResultWithSelectedPeer:(NSArray *)selectedArray TableName:(NSString *)tbName
{
    NSMutableArray *resultArray;
    
    resultArray = [[NSMutableArray alloc]init];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rsSO = [db executeQuery:@"Select SOH_Table, SOH_DocAmt,SOH_DocNo, 'TransferMultiSOResult' as IM_Flag, 'True' as Result, TP_Section from SalesOrderHdr SOH left join TablePlan TP on SOH.SOH_Table = TP.TP_Name where SOH_Status = ? and SOH_Table = ?",@"New",tbName];
        
        while ([rsSO next]) {
            [resultArray addObject:[rsSO resultDictionary]];
        }
        
        [rsSO close];
     
    }];
    
    if (resultArray.count == 0) {
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        
        [data setObject:@"False" forKey:@"Result"];
        [data setObject:@"" forKey:@"Message"];
        [data setObject:@"TransferMultiSOResult" forKey:@"IM_Flag"];
        
        [resultArray addObject:data];
        data = nil;
    }
    
    NSData *dataToBeReturn = [NSKeyedArchiver archivedDataWithRootObject:resultArray];
    NSError *error;
    
    //NSArray *allPeers = [[_appDelegate.mcManager session] connectedPeers];
    
    [_appDelegate.mcManager.session sendData:dataToBeReturn
                                     toPeers:selectedArray
                                    withMode:MCSessionSendDataReliable
                                       error:&error];
    
    resultArray = nil;
}

-(void)sendBackToTerminalWithTransferSalesOrderResult:(NSArray *)selectedPeer SalesOrderNo:(NSString *)soNo SelectedTbName:(NSString *)selectedTbName SelectedDineType:(int)dineType Date:(NSString *)todayDate
{
    NSMutableArray *transferSalesOrderDetailArray = [[NSMutableArray alloc] init];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:[NSString stringWithFormat:@"%@,'%@' as TableName %@",@"Select SOD_ItemCode, SOD_ItemDescription, SOD_Quantity,'TransferSalesOrderDetailResult' as IM_Flag",selectedTbName, @" from SalesOrderDtl where SOD_DocNo = ?"],soNo];
        
        while ([rs next]) {
            [transferSalesOrderDetailArray addObject:[rs resultDictionary]];
        }
        [rs close];
    }];
    [queue close];
    
    NSData *dataToBeReturn = [NSKeyedArchiver archivedDataWithRootObject:transferSalesOrderDetailArray];
    NSError *error;
    transferSalesOrderDetailArray = nil;
    
    //NSArray *allPeers = [[_appDelegate.mcManager session] connectedPeers];
    
    [_appDelegate.mcManager.session sendData:dataToBeReturn
                                     toPeers:selectedPeer
                                    withMode:MCSessionSendDataReliable
                                       error:&error];
    
    
    
}

-(void)sendBackToTerminalCombineTableResultWithSelectedPeer:(NSArray *)selectedPeer OptionSelected:(NSString *)optionSelected FromSalesOrderNo:(NSString *)fromSalesOrderNo ToSalesOrderNo:(NSString *)ToSalesOrderNo
{
    
    NSMutableArray *resultArray;
    resultArray = [[NSMutableArray alloc]init];
    
    //[resultArray addObjectsFromArray:[PublicSqliteMethod getCombineTableListWithDbPath:dbPath FromTableName:fromTableName]];
    
    [resultArray addObjectsFromArray:[PublicSqliteMethod publicCombineTwoTableWithFromSalesOrder:fromSalesOrderNo ToSalesOrder:ToSalesOrderNo DBPath:dbPath]];
    
    if (resultArray.count == 0) {
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        
        [data setObject:@"False" forKey:@"Result"];
        [data setObject:@"-" forKey:@"Message"];
        [data setObject:@"CombineTableResult" forKey:@"IM_Flag"];
        
        [resultArray addObject:data];
        data = nil;
    }
    
    NSData *dataToBeReturn = [NSKeyedArchiver archivedDataWithRootObject:resultArray];
    NSError *error;
    resultArray = nil;
    [_appDelegate.mcManager.session sendData:dataToBeReturn
                                     toPeers:selectedPeer
                                    withMode:MCSessionSendDataReliable
                                       error:&error];
    
}

-(void)sendBackToTerminalForFlyTechPrinterWithCSNo:(NSString *)invNo SelectedPeer:(NSArray *)selectedPeer
{
    NSMutableArray *rptArray = [[NSMutableArray alloc]init];
    
    [rptArray removeAllObjects];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSString *sqlCommand;
        
        sqlCommand = [NSString stringWithFormat:@"%@,'%@' as IM_Flag",@"Select *,IFNULL(IvD_ItemTaxCode,'') || ': ' || IvD_ItemDescription as ItemDesc,IvD_ItemDescription as ItemDesc2, IFNULL(IvD_ItemTaxCode,'-') as Flag",@"TerminalPrintFlyTechReceiptResult"];
        
        FMResultSet *rs = [db executeQuery:[NSString stringWithFormat:@"%@ %@",sqlCommand,@" from InvoiceHdr InvH "
                                            " left join InvoiceDtl InvD on InvH.IvH_DocNo = InvD.IvD_DocNo"
                                            " left join ItemMast IM on IM.IM_ItemCode = InvD.IvD_ItemCode"
                                            " where InvH.IvH_DocNo = ?"],invNo];
        
        
        while ([rs next]) {
            [rptArray addObject:[rs resultDictionary]];
        }
        
        [rs close];
        //[dbTable close];
        
    }];
    [queue close];
    
    NSData *dataToBeReturn = [NSKeyedArchiver archivedDataWithRootObject:rptArray];
    NSError *error;
    rptArray = nil;
    
    //NSArray *allPeers = [[_appDelegate.mcManager session] connectedPeers];
    
    [_appDelegate.mcManager.session sendData:dataToBeReturn
                                     toPeers:selectedPeer
                                    withMode:MCSessionSendDataReliable
                                       error:&error];
}


-(void)sendBackToTerminalForFlyTechPrinterWithSONo:(NSString *)soNo SelectedPeer:(NSArray *)selectedPeer
{
    NSMutableArray *receiptArray = [[NSMutableArray alloc]init];
    
    [receiptArray removeAllObjects];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rs = [db executeQuery:@"Select *, 'TerminalPrintFlyTechSOReceiptResult' as IM_Flag, SOD_ItemDescription as ItemDesc from SalesOrderHdr Hdr "
                           " left join SalesOrderDtl Dtl on Hdr.SOH_DocNo = Dtl.SOD_DocNo"
                           " left join ItemMast IM on IM.IM_ItemCode = Dtl.SOD_ItemCode"
                           " where Hdr.SOH_DocNo = ?",soNo];
        
        while ([rs next]) {
            [receiptArray addObject:[rs resultDictionary]];
        }
        
        [rs close];
        //[dbTable close];
        
    }];
    
    NSData *dataToBeReturn = [NSKeyedArchiver archivedDataWithRootObject:receiptArray];
    NSError *error;
    receiptArray = nil;
    
    //NSArray *allPeers = [[_appDelegate.mcManager session] connectedPeers];
    
    [_appDelegate.mcManager.session sendData:dataToBeReturn
                                     toPeers:selectedPeer
                                    withMode:MCSessionSendDataReliable
                                       error:&error];
}

// multipeer notification
-(void)generalCSArrayWithNotification:(NSNotification *)notification
{
    NSMutableArray *compArray = [[NSMutableArray alloc]init];
    NSArray *csArray;
    csArray = [notification object];
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rsCompany = [db executeQuery:@"Select * from Company"];
        while ([rsCompany next]) {
            [compArray addObject:[rsCompany resultDictionary]];
        }
        
    }];
    [queue close];
    
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    NSString *dateString = [dateFormat stringFromDate:today];
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
    NSString *timeString = [timeFormat stringFromDate:today];
    
    int spaceCount = 0;
    
    NSString *shopName = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Company"]];
    NSString *add1 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address1"]];
    NSString *add2 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address2"]];
    NSString *add3 = [NSString stringWithFormat:@"%@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Address3"]];
    NSString *tel = [NSString stringWithFormat:@"Tel : %@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_Telephone"]];
    NSString *gstNo = [NSString stringWithFormat:@"GST ID : %@\r\n",[[compArray objectAtIndex:0] objectForKey:@"Comp_GstNo"]];
    NSString *invNo = [NSString stringWithFormat:@"Receipt : %@\r\n",[[csArray objectAtIndex:0] objectForKey:@"IvH_DocNo"]];
    spaceCount = (int)(38 - invNo.length)/2;
    NSString *date = [NSString stringWithFormat:@"Date : %@",dateString];
    NSString *time = timeString;
    
    spaceCount = (int)(38 - date.length - time.length);
    NSString *dateTime;
    dateTime = [NSString stringWithFormat:@"%@%@%@\r\n\r\n",
                date,[@" " stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0],
                time];
    
    NSString *title =    @"Item              Qty   Price    Total\r\n";
    NSString *dashline = @"--------------------------------------\r\n";
    
    NSString *item = @"";
    NSString *qty = @"";
    NSString *price = @"";
    NSString *itemTotal = @"";
    NSString *itemDesc2 = @"";
    double subTotalB4Gst = 0.00;
    long spaceAdd = 0;
    
    NSString *detail2;
    NSString *detail3;
    NSString *detail4;
    NSMutableString *mString2 = [[NSMutableString alloc]init];
    
    for (int i = 0; i<csArray.count; i++) {
        if ([[LibraryAPI sharedInstance] getEnableGst] == 0) {
            item = [[csArray objectAtIndex:i] objectForKey:@"ItemDesc2"];
        }
        else
        {
            if ([[[csArray objectAtIndex:i]objectForKey:@"Flag"] isEqualToString:@"-"]) {
                item = [[csArray objectAtIndex:i] objectForKey:@"ItemDesc2"];
            }
            else
            {
                item = [[csArray objectAtIndex:i] objectForKey:@"ItemDesc"];
            }
            
        }
        subTotalB4Gst = subTotalB4Gst + [[[csArray objectAtIndex:i] objectForKey:@"IvD_TotalEx"] doubleValue];
        //NSLog(@"%d",[item length]);
        if ([item length] > 15) item = [item substringToIndex:15];
        qty = [NSString stringWithFormat:@"%0.2f",[[[csArray objectAtIndex:i] objectForKey:@"IvD_Quantity"] doubleValue]];
        if ([qty length] > 6) qty = [qty substringToIndex:6];
        price = [NSString stringWithFormat:@"%0.2f",[[[csArray objectAtIndex:i] objectForKey:@"IvD_Price"] doubleValue]];
        if ([price length] > 8) price = [price substringToIndex:8];
        itemTotal = [NSString stringWithFormat:@"%0.2f",[[[csArray objectAtIndex:i] objectForKey:@"IvD_SubTotal"] doubleValue]];
        if ([itemTotal length] > 9) itemTotal = [itemTotal substringToIndex:9];
        
        spaceAdd = 15 - item.length;
        NSString *detail1 = [NSString stringWithFormat:@"%@%@",
                             item,
                             [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0]];
        
        spaceAdd = 6 - qty.length;
        if (spaceAdd > 0) {
            detail2 = [NSString stringWithFormat:@"%@%@",
                       [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0],
                       qty];
        }
        
        spaceAdd = 8 - price.length;
        if (spaceAdd > 0) {
            detail3 = [NSString stringWithFormat:@"%@%@",
                       [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0],
                       price];
        }
        
        spaceAdd = 9 - itemTotal.length;
        if (spaceAdd > 0) {
            detail4 = [NSString stringWithFormat:@"%@%@",
                       [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0],
                       itemTotal];
        }
        
        itemDesc2 = [[csArray objectAtIndex:i] objectForKey:@"IM_Description2"];
        
        [mString2 appendString:[NSString stringWithFormat:@"%@%@%@%@\n",detail1,detail2,detail3,detail4]];
    }
    
    NSString *footer;
    NSString *footerTitle;
    
    footer = [NSString stringWithFormat:@"%0.2f",subTotalB4Gst];
    footerTitle = @"SubTotal Exlude GST";
    NSString *subTotalEx = [NSString stringWithFormat:@"%@%@%@\r\n",
                            footerTitle,
                            [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[csArray objectAtIndex:0] objectForKey:@"IvH_DocSubTotal"] doubleValue]];
    footerTitle = @"SubTotal";
    NSString *subTotal = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[csArray objectAtIndex:0] objectForKey:@"IvH_DiscAmt"] doubleValue]];
    footerTitle = @"Discount";
    NSString *discount = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[csArray objectAtIndex:0] objectForKey:@"IvH_DocServiceTaxAmt"] doubleValue]];
    footerTitle = @"Service Charge";
    NSString *serviceCharge = [NSString stringWithFormat:@"%@%@%@\r\n",
                               footerTitle,
                               [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[csArray objectAtIndex:0] objectForKey:@"IvH_DocTaxAmt"] doubleValue]];
    footerTitle = @"Total GST";
    NSString *gst = [NSString stringWithFormat:@"%@%@%@\r\n",
                     footerTitle,
                     [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[csArray objectAtIndex:0] objectForKey:@"IvH_Rounding"] doubleValue]];
    footerTitle = @"Rounding";
    NSString *rounding = [NSString stringWithFormat:@"%@%@%@\r\n",
                          footerTitle,
                          [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[csArray objectAtIndex:0] objectForKey:@"IvH_DocAmt"] doubleValue]];
    footerTitle = @"Total";
    NSString *granTotal = [NSString stringWithFormat:@"%@%@%@\r\n",
                           footerTitle,
                           [@" " stringByPaddingToLength:19-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[csArray objectAtIndex:0] objectForKey:@"IvH_TotalPay"] doubleValue]];
    footerTitle = @"Pay";
    NSString *pay = [NSString stringWithFormat:@"%@%@%@\r\n",
                     footerTitle,
                     [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = [NSString stringWithFormat:@"%0.2f",[[[csArray objectAtIndex:0] objectForKey:@"IvH_ChangeAmt"] doubleValue]];
    footerTitle = @"Change";
    NSString *change = [NSString stringWithFormat:@"%@%@%@\r\n\r\n",
                        footerTitle,
                        [@" " stringByPaddingToLength:38-footerTitle.length-footer.length withString:@" " startingAtIndex:0],footer];
    
    footer = @"Goods Sold Are Not Refundable";
    
    NSMutableString *headerPart = [[NSMutableString alloc] init];
    NSMutableString *middlePart = [[NSMutableString alloc] init];
    NSMutableString *footerPart = [[NSMutableString alloc] init];
    
    [headerPart appendString:shopName];
    [headerPart appendString:add1];
    [headerPart appendString:add2];
    [headerPart appendString:add3];
    [headerPart appendString:tel];
    if ([[LibraryAPI sharedInstance]getEnableGst] == 1) {
        [headerPart appendString:gstNo];
    }
    [headerPart appendString:invNo];
    
    
    [middlePart setString:@""];
    [middlePart appendString:dateTime];
    [middlePart appendString:title];
    [middlePart appendString:dashline];
    [middlePart appendString:mString2];
    //[middlePart setString:@""];
    
    [footerPart setString:@""];
    [footerPart appendString:dashline];
    [footerPart appendString:subTotalEx];
    [footerPart appendString:subTotal];
    [footerPart appendString:discount];
    [footerPart appendString:serviceCharge];
    if ([[LibraryAPI sharedInstance]getEnableGst] == 1) {
        [footerPart appendString:gst];
    }
    [footerPart appendString:rounding];
    //[footerPart appendString:granTotal];
    //[footerPart appendString:pay];
    //[footerPart appendString:change];
    [PosApi openCashBox];
    [PosApi initPrinter];
    [PosApi setPrinterSettings:CHARSET_USA leftMargin:0 printAreaWidth:576 printQuality:8];
    [PosApi setPrintFont:PRINT_FONT_12x24];
    
    [PosApi setPrintFormat:ALIGNMENT_CENTERD];
    [PosApi printText:headerPart];
    
    [PosApi setPrintFormat:ALIGNMENT_LEFT];
    [PosApi printText:middlePart];
    [PosApi printText:footerPart];
    [PosApi printText:@"\r\n"];
    [PosApi setPrintCharacterScale:FONT_SCALE_VERTICAL_2 hScale:FONT_SCALE_HORIZONTAL_2];
    [PosApi printText:granTotal];
    [PosApi printText:@"\r\n"];
    [PosApi setPrintCharacterScale:FONT_SCALE_VERTICAL_1 hScale:FONT_SCALE_HORIZONTAL_1];
    [PosApi printText:pay];
    [PosApi printText:change];
    [PosApi cutPaper];
    
    headerPart = nil;
    middlePart = nil;
    footerPart = nil;

    
}

#pragma mark - Print Asterix Part

-(void)printAsterixReceiptWithIpAdd:(NSString *)ipAdd CompanyArray:(NSMutableArray *)compArray CSArray:(NSMutableArray *)csArray
{
    NSString *printErrorMsg;
    
    Result *result = nil;
    EposBuilder *builder = nil;
    
    result = [[Result alloc] init];
    
    //builder = [EposPrintFunction createSalesOrderRceiptData:result DBPath:dbPath GetInvNo:docNo EnableGst:enableGST];
    
    builder = [EposPrintFunction createReceiptData:result ComapnyArray:compArray CSArray:csArray EnableGst:[[LibraryAPI sharedInstance] getEnableGst] KickOutDrawerYN:@"Y"];
    
    if(result.errType == RESULT_ERR_NONE) {
        [EposPrintFunction print:builder Result:result PortName:ipAdd];
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
        [self showAlertView:printErrorMsg title:@"Warning"];
    }
    
    if(result != nil) {
        result = nil;
    }
    
    
}


-(void)printAsterixSalesOrderWithIpAdd:(NSString *)ipAdd CompanyArray:(NSMutableArray *)compArray SalesOrderArray:(NSMutableArray *)soArray
{
    NSString *printErrorMsg;
    Result *result = nil;
    EposBuilder *builder = nil;
    
    result = [[Result alloc] init];
    
    builder = [EposPrintFunction createSalesOrderRceiptData:result ComapnyArray:compArray SalesOrderArray:soArray EnableGst:[[LibraryAPI sharedInstance] getEnableGst]];
    //builder = [EposPrintFunction createReceiptData:result DBPath:dbPath GetInvNo:docNo EnableGst:compEnableGst];
    
    if(result.errType == RESULT_ERR_NONE) {
        [EposPrintFunction print:builder Result:result PortName:ipAdd];
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
    //printSOArray = nil;
    
    
    //return;
}
/*
-(void)printAsterixKRGroupWithIpAdd:(NSString *)ipAdd TableName:(NSString *)tbName Data:(NSMutableString *)data
{
    Result *result = nil;
    EposBuilder *builder = nil;
    
    result = [[Result alloc] init];
    
    builder = [EposPrintFunction createKitchenReceiptGroupFormat:result OrderDetail:data TableName:tbName];
    
    if(result.errType == RESULT_ERR_NONE) {
        [EposPrintFunction print:builder Result:result PortName:ipAdd];
    }
    
    if (builder != nil)
    {
        [builder clearCommandBuffer];
    }
    
    //[EposPrintFunction displayMsg:result];
    
    if(result != nil) {
        result = nil;
    }
    
    return;
}
*/

- (void)printAsterixKRWithItemDesc:(NSString *)imDesc IPAdd:(NSString *)ipAdd imQty:(NSString *)imQty TableName:(NSString *)tableName DataArray:(NSMutableArray *)dataArray
{
    
        Result *result = nil;
        EposBuilder *builder = nil;
        
        result = [[Result alloc] init];
        
        builder = [EposPrintFunction createKitchenReceiptFormat:result TableNo:tableName ItemNo:imDesc Qty:imQty DataArray:dataArray];
        
        if(result.errType == RESULT_ERR_NONE) {
            
            //Do background work
            [EposPrintFunction print:builder Result:result PortName:ipAdd];
            
        }
        
        if (builder != nil) {
            [builder clearCommandBuffer];
        }
        
        [EposPrintFunction displayMsg:result];
        
        if(result != nil) {
            result = nil;
        }
        
    
    
    //return;
}


- (void)printAsterixKR2WithItemDesc
{
    //for (int i = 0; i < 5; i++) {
    dispatch_async(dispatch_get_main_queue(), ^{
        Result *result = nil;
        EposBuilder *builder = nil;
        
        result = [[Result alloc] init];
        
        builder = [EposPrintFunction createKitchenReceiptFormat:result TableNo:@"ttt" ItemNo:@"111" Qty:@"1" DataArray:nil];
        
        if(result.errType == RESULT_ERR_NONE) {
            
            //Do background work
            [EposPrintFunction print:builder Result:result PortName:@"192.168.0.13"];
            //NSLog(@"Testing %d",i);
            
            
        }
        
        if (builder != nil) {
            [builder clearCommandBuffer];
        }
        
        [EposPrintFunction displayMsg:result];
        
        if(result != nil) {
            result = nil;
        }

    });
    
}


-(void)printAsterixSalesOrderWithSONo:(NSString *)soNo PrinterPortName:(NSString *)portName SelectedPeer:(NSArray *)selectedPeer
{
    
    NSMutableArray *resultArray;
    resultArray = [[NSMutableArray alloc]init];
    /*
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"Select *, IFNULL(SOD_TaxCode,'') || ': ' || SOD_ItemDescription as ItemDesc ,SOD_ItemDescription as ItemDesc2, 'ItemOrder' as OrderType, 'TerminalRequestSODtlResult' as IM_Flag from SalesOrderHdr Hdr "
                           " left join SalesOrderDtl Dtl on Hdr.SOH_DocNo = Dtl.SOD_DocNo"
                           " left join ItemMast IM on IM.IM_ItemCode = Dtl.SOD_ItemCode"
                           " where Hdr.SOH_DocNo = ?",soNo];
        
        while ([rs next]) {
            
            [resultArray addObject:[rs resultDictionary]];
            
            FMResultSet *rsCdt = [db executeQuery:@"Select *,'CondimentOrder' as OrderType from SalesOrderCondiment where SOC_CDManualKey = ?",[rs stringForColumn:@"SOD_ManualID"]];
            
            while ([rsCdt next]) {
                [resultArray addObject:[rsCdt resultDictionary]];
            }
            [rsCdt close];
        }
        
        [rs close];
        
    }];
    
    [queue close];
    */
    
    resultArray = [PublicSqliteMethod getAsterixSalesOrderDetailWithDBPath:dbPath SalesOrderNo:soNo];
    
    NSData *dataToBeReturn = [NSKeyedArchiver archivedDataWithRootObject:resultArray];
    NSError *error;
    resultArray = nil;
    [_appDelegate.mcManager.session sendData:dataToBeReturn
                                     toPeers:selectedPeer
                                    withMode:MCSessionSendDataReliable
                                       error:&error];
}

-(void)printAsterixInvoiceWithInvNo:(NSString *)invNo PrinterPortName:(NSString *)portName EnableGst:(int)enableGst SelectedPeer:(NSArray *)selectedPeer KickOutDrawer:(NSString *)kickOutDrawer ViewName:(NSString *)viewName
{
    
    
    NSMutableArray *resultArray;
    resultArray = [[NSMutableArray alloc]init];
    
    resultArray = [PublicSqliteMethod getAsterixCashSalesDetailWithDBPath:dbPath CashSalesNo:invNo ViewName:viewName];
    
    NSData *dataToBeReturn = [NSKeyedArchiver archivedDataWithRootObject:resultArray];
    NSError *error;
    resultArray = nil;
    [_appDelegate.mcManager.session sendData:dataToBeReturn
                                     toPeers:selectedPeer
                                    withMode:MCSessionSendDataReliable
                                       error:&error];
    
    /*
     Result *result = nil;
     EposBuilder *builder = nil;
     
     result = [[Result alloc] init];
     
     //builder = [EposPrintFunction createReceiptData:result DBPath:dbPath GetInvNo:invNo EnableGst:enableGst KickOutDrawerYN:kickOutDrawer];
     
     if(result.errType == RESULT_ERR_NONE) {
     [EposPrintFunction print:builder Result:result PortName:portName];
     }
     else
     {
     NSLog(@"Testing Data %@",@"Print Fail");
     }
     
     if (builder != nil) {
     [builder clearCommandBuffer];
     }
     
     [EposPrintFunction displayMsg:result];
     
     if(result != nil) {
     result = nil;
     }
     */
     
    
}

#pragma mark - Print Star Part
-(void)printStarRasterSalesOrderWithSONo:(NSString *)soNo PortSetting:(NSString *)portSetting PortName:(NSString *)portName EnableGst:(int)enableGst
{
    p_selectedWidthInch = SMPaperWidth3inchSO;
    p_selectedLanguage = SMLanguageEnglish;
    
    [PrinterFunctions PrintRasterSampleReceiptWithPortname:portName portSettings:portSetting paperWidth:p_selectedWidthInch Language:p_selectedLanguage invDocno:soNo EnableGst:enableGst KickOutDrawer:NO];
}

-(void)printStarRasterInvoiceWithInvNo:(NSString *)invNo PortSetting:(NSString *)portSetting PortName:(NSString *)portName EnableGst:(int)enableGst
{
    p_selectedWidthInch = SMPaperWidth3inchSO;
    p_selectedLanguage = SMLanguageEnglish;
    
    [PrinterFunctions PrintRasterSampleReceiptWithPortname:portName portSettings:portSetting paperWidth:p_selectedWidthInch Language:p_selectedLanguage invDocno:invNo EnableGst:enableGst KickOutDrawer:YES];
}

-(void)printStarLineSalesOrderWithSONo:(NSString *)soNo PortSetting:(NSString *)portSetting PortName:(NSString *)portName EnableGst:(int)enableGst
{
    p_selectedWidthInch = SMPaperWidth3inchSO;
    p_selectedLanguage = SMLanguageEnglish;
    
    
    NSData *commands = [PrinterFunctions sampleReceiptWithPaperWidth:p_selectedWidthInch
                                                            language:p_selectedLanguage
                                                          kickDrawer:NO invDocNo:soNo docType:@"SO" EnableGST:enableGst];
    if (commands == nil) {
        return;
    }
    
    //printerPortSetting = @"Standard";
    [PrinterFunctions sendCommand:commands
                         portName:portName
                     portSettings:portSetting
                    timeoutMillis:10000];
    
    
}

-(void)printStarLineInvoiceWithInvNo:(NSString *)invNo PortSetting:(NSString *)portSetting PortName:(NSString *)portName EnableGst:(int)enableGst
{
    p_selectedWidthInch = SMPaperWidth3inchSO;
    p_selectedLanguage = SMLanguageEnglish;
    
    NSData *commands = [PrinterFunctions sampleReceiptWithPaperWidth:p_selectedWidthInch
                                                            language:p_selectedLanguage
                                                          kickDrawer:YES invDocNo:invNo docType:@"Inv" EnableGST:enableGst];
    if (commands == nil) {
        return;
    }
    
    
    [PrinterFunctions sendCommand:commands
                         portName:portName
                     portSettings:portSetting
                    timeoutMillis:10000];
}

-(void)printFlyTechInvoiceWithInvNo:(NSString *)invNo PortSetting:(NSString *)portSetting PortName:(NSString *)portName EnableGst:(int)enableGst
{
    //[EposPrintFunction createFlyTechReceiptWithDBPath:dbPath GetInvNo:invNo EnableGst:enableGst KickOutDrawerYN:@"Y"];
}

#pragma mark - FlyTech part
-(void)printFlyTechKitchenReceiptWithIMDesc:(NSString *)imDesc Qty:(NSString *)imQty TableName:(NSString *)tableName DataArray:(NSMutableArray *)array
{
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:[[LibraryAPI sharedInstance] getPrinterUUID]];
    
    if ([PosApi getBleConnectionStatus:uuid] == 0) {
        [self showAlertView:@"Bluetooth printer is connecting" title:@"Information"];
    }
    else if ([PosApi getBleConnectionStatus:uuid] == 2)
    {
        [self showAlertView:@"Bluetooth printer is disconnect" title:@"Information"];
    }
    else
    {
        //[PosApi initPrinter];
        [EposPrintFunction createFlyTechKitchenReceiptWithDBPath:dbPath TableNo:tableName ItemNo:imDesc Qty:imQty DataArray:array];
    }
}

-(void)printFlyTechKRGroupWithData:(NSMutableString *)data TableName:(NSString *)tbName
{
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:[[LibraryAPI sharedInstance] getPrinterUUID]];
    if ([PosApi getBleConnectionStatus:uuid] == 0) {
        [self showAlertView:@"Bluetooth printer is connecting" title:@"Information"];
    }
    else if ([PosApi getBleConnectionStatus:uuid] == 2)
    {
        [self showAlertView:@"Bluetooth printer is disconnect" title:@"Information"];
    }
    else
    {
        //[PosApi initPrinter];
        [EposPrintFunction createFlyTechKitReceiptGroupWithOrderDetail:data TableName:tbName];
    }
}

-(void)printFlyTechSalesOrderReceiptWithCompanyData:(NSMutableArray *)compArray SalesOrderData:(NSMutableArray *)soArray
{
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:[[LibraryAPI sharedInstance] getPrinterUUID]];
    if ([PosApi getBleConnectionStatus:uuid] == 0) {
        [self showAlertView:@"Bluetooth printer is connecting" title:@"Information"];
    }
    else if ([PosApi getBleConnectionStatus:uuid] == 2)
    {
        [self showAlertView:@"Bluetooth printer is disconnect" title:@"Information"];
    }
    else
    {
        [EposPrintFunction createFlyTechSalesOrderReceiptWithComapnyArray:compArray SalesOrderArray:soArray EnableGst:[[LibraryAPI sharedInstance] getEnableGst]];
    }
    
}

-(void)printFlyTechReceiptWithCompanyData:(NSMutableArray *)compArray CSArray:(NSMutableArray *)csArray PrintOption:(NSMutableArray *)pArray PrintType:(NSString *)printType
{
    //[PosApi initPrinter];
    [EposPrintFunction createFlyTechReceiptWithCompanyArray:compArray ReceiptArray:csArray EnableGst:[[LibraryAPI sharedInstance] getEnableGst] KickOutDrawerYN:@"Y" PrintOption:pArray PrintType:printType];
    
}

#pragma mark - XinYe Part

-(void)printXinYeSalesOrderWithSONo:(NSString *)soNo PrinterPortName:(NSString *)ipAdd SelectedPeer:(NSArray *)selectedPeer
{
    [self.wifiManager XYDisConnect];
    
    [_wifiManager XYConnectWithHost:ipAdd port:9100 completion:^(BOOL isConnect) {
        if (isConnect) {
            [self sendCommandToServerXinYePrinterWithSONo:soNo EnableGst:[[LibraryAPI sharedInstance] getEnableGst]];
        }
    }];
    
}

-(void)sendCommandToServerXinYePrinterWithSONo:(NSString *)soNo EnableGst:(int)enableGst
{
    NSMutableData *commands = [NSMutableData data];
    //commands = [EposPrintFunction generateSalesOrderReceiptFormatWithDBPath:dbPath GetInvNo:soNo EnableGst:enableGst PrinterBrand:@"XinYe" ReceiptLength:48];
    
    NSMutableData* dataM=[NSMutableData dataWithData:[PosCommand initializePrinter]];
    [dataM appendData:commands];
    [self.wifiManager XYWriteCommandWithData:dataM];
}


-(void)printXinYeCSWithCsNo:(NSString *)csNo PrinterPortName:(NSString *)ipAdd EnableGst:(int)enableGst SelectedPeer:(NSArray *)selectedPeer KickOutDrawer:(NSString *)kickOutDrawer
{
    
    [self.wifiManager XYDisConnect];
    
    [_wifiManager XYConnectWithHost:ipAdd port:9100 completion:^(BOOL isConnect) {
        if (isConnect) {
            [self sendCommandToServerToPrintCsDocNo:csNo EnableGst:enableGst];
        }
    }];

}

-(void)sendCommandToServerToPrintCsDocNo:(NSString *)csNo EnableGst:(int)enableGst
{
    NSMutableData *commands = [NSMutableData data];
    
    commands = [EposPrintFunction generateReceiptFormatWithDBPath:dbPath GetInvNo:csNo EnableGst:enableGst KickOutDrawerYN:@"N" PrinterBrand:@"XinYe" ReceiptLength:48 DataArray:nil];
        
        NSMutableData* dataM=[NSMutableData dataWithData:[PosCommand initializePrinter]];
        [dataM appendData:commands];
        [self.wifiManager XYWriteCommandWithData:dataM];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self.wifiManager XYDisConnect];
    });
}

-(void)sendBackToTerminalForCSDetailWithCSNo:(NSString *)csNo SelectedPeer:(NSArray *)selectedPeer ToView:(NSString *)toView
{
    NSMutableArray *receiptArray = [[NSMutableArray alloc]init];
    
    [receiptArray removeAllObjects];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSString *sqlCommand;
        
        sqlCommand = [NSString stringWithFormat:@"%@,'%@' as IM_Flag",@"Select *,IFNULL(IvD_ItemTaxCode,'') || ': ' || IvD_ItemDescription as ItemDesc,IvD_ItemDescription as ItemDesc2, IFNULL(IvD_ItemTaxCode,'-') as Flag",toView];
        
        FMResultSet *rs = [db executeQuery:[NSString stringWithFormat:@"%@ %@",sqlCommand,@" from InvoiceHdr InvH "
                                            " left join InvoiceDtl InvD on InvH.IvH_DocNo = InvD.IvD_DocNo"
                                            " left join ItemMast IM on IM.IM_ItemCode = InvD.IvD_ItemCode"
                                            " where InvH.IvH_DocNo = ?"],csNo];
        
        
        while ([rs next]) {
            [receiptArray addObject:[rs resultDictionary]];
        }
        
        [rs close];
        //[dbTable close];
        
    }];
    [queue close];
    
    NSData *dataToBeReturn = [NSKeyedArchiver archivedDataWithRootObject:receiptArray];
    NSError *error;
    receiptArray = nil;
    
    //NSArray *allPeers = [[_appDelegate.mcManager session] connectedPeers];
    
    [_appDelegate.mcManager.session sendData:dataToBeReturn
                                     toPeers:selectedPeer
                                    withMode:MCSessionSendDataReliable
                                       error:&error];
}

#pragma mark - server Print kitchen receipt
-(void)serverPrintingDataWithArray:(NSArray *)data
{
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (int j = 0; j < data.count; j++) {
            
            [db executeUpdate:@"Insert into PrintQueue (PQ_ItemCode, PQ_ItemDesc, PQ_PrinterIP, PQ_PrinterBrand, PQ_PrinterMode, PQ_DocNo,PQ_TableName, PQ_ItemQty,PQ_DocType,PQ_Status,PQ_OrderType,PQ_ManualID, PQ_PrinterName, PQ_PackageName)"
             " values (?,?,?,?,?,?,?,?,?,?,?,?,?,?)",[[data objectAtIndex:j] objectForKey:@"KR_ItemCode"],[[data objectAtIndex:j] objectForKey:@"KR_Desc"],[[data objectAtIndex:j] objectForKey:@"KR_IpAddress"],[[data objectAtIndex:j] objectForKey:@"KR_Brand"],[[data objectAtIndex:j] objectForKey:@"KR_PrintMode"],[[data objectAtIndex:j] objectForKey:@"KR_DocNo"],[[data objectAtIndex:j] objectForKey:@"KR_TableName"],[[data objectAtIndex:j] objectForKey:@"KR_Qty"],[[data objectAtIndex:j] objectForKey:@"KR_DocType"],@"Print",[[data objectAtIndex:j] objectForKey:@"KR_OrderType"],[[data objectAtIndex:j] objectForKey:@"KR_ManualID"],[[data objectAtIndex:j] objectForKey:@"KR_PrinterName"],[[data objectAtIndex:j] objectForKey:@"KR_PackageName"]];
            
        }
        
        if ([db hadError]) {
            [self showAlertView:[db lastErrorMessage] title:@"Fail"];
        }
    }];
    
    
    //[dbTable close];
    /*
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
    }];
    
    [queue close];
    */
    /*
     select PQ_ItemCode,PQ_ItemDesc,PQ_ItemQty,IP_PrinterPort,P_Type,P_Brand,P_Mode from PrintQueue pq
     left join ItemPrinter ip on pq.PQ_ItemCode = ip.IP_ItemNo
     left join Printer p on ip.IP_PrinterName = p.P_PrinterName
     */
    
    /*
         */
    
}

/*
-(void)serverPrintKitchenGroupReceiptWithArray:(NSArray *)krData
{
    //[self arrayConnectToXinYePrinter];
    //for (int i = 0; i < krData.count; i++) {
        if ([[[krData objectAtIndex:0] objectForKey:@"KR_Brand"] isEqualToString:@"Star"]) {
            if ([[[krData objectAtIndex:0] objectForKey:@"KR_Mode"] isEqualToString:@"Line"]) {
                //[self PrintStarKitchenReceiptInLineModeWithItemName:itemCode OrderQty:itemQty PortName:[rs stringForColumn:@"P_PortName"]];
            }
            else if ([[[krData objectAtIndex:0] objectForKey:@"KR_Mode"] isEqualToString:@"Raster"])
            {
                //[self PrintStarKitchenReceiptInRasterModeWithItemName:itemCode OrderQty:itemQty PortName:[rs stringForColumn:@"P_PortName"]];
            }
        }
        else if ([[[krData objectAtIndex:0] objectForKey:@"KR_Mode"] isEqualToString:@"Asterix"])
        {
            //[self runPrintKicthenSequenceWithItemDesc:imDesc IPAdd:[rs stringForColumn:@"P_PortName"] imQty:itemQty];
        }
        else if ([[[krData objectAtIndex:0] objectForKey:@"KR_Mode"] isEqualToString:@"FlyTech"])
        {
            //[self runPrintFlyTechKitchenReceiptWithIMDesc:imDesc Qty:itemQty];
        }
        else if ([[[krData objectAtIndex:0] objectForKey:@"KR_Brand"] isEqualToString:@"XinYe"])
        {
            NSMutableArray *fff = [[NSMutableArray alloc] init];
            [fff addObjectsFromArray:krData];
            
            for (int j =0; j < xinYeConnectionArray.count; j++) {
                if ([[[fff objectAtIndex:0] objectForKey:@"KR_IpAddress"] isEqualToString:[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"IpAdd"]]) {
                    self.wifiManager = [[xinYeConnectionArray objectAtIndex:j] objectForKey:@"XinYe"];
                    NSMutableData *commands = [NSMutableData data];
                    
                    commands = [EposPrintFunction createXinYeKitReceiptGroupWithOrderDetail:fff TableName:[[fff objectAtIndex:0] objectForKey:@"KR_TableName"]];
                    
                    NSMutableData* dataM=[NSMutableData dataWithData:[PosCommand initializePrinter]];
                    [dataM appendData:commands];
                    [self.wifiManager XYWriteCommandWithData:dataM];
                }
            }
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self.wifiManager XYDisConnect];
            });
            
            
        }
    //}
}
*/

-(void)serverCallConnectionArrayWithNotification:(NSNotification *)notification
{
    NSArray *itemDTL;
    itemDTL = [notification object];
    
    if (itemDTL.count > 0) {
        [self serverPrintingDataWithArray:itemDTL];
    }
    
}


-(void)autoPrintFromServerWithNotificationBackup:(NSNotification *)notification
{
    /*
    [testPrinterArray removeAllObjects];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback){
        dispatch_queue_t mainQueue = dispatch_get_main_queue();
        FMResultSet *rsPrinterIP = [db executeQuery:@"Select PQ_PrinterIP, PQ_PrinterBrand, 'Disconnected' as 'PQ_Status' from PrintQueue group by PQ_PrinterIP,PQ_PrinterBrand limit 1"];
        
        while ([rsPrinterIP next]) {
            
            GCDAsyncSocket *gcdArraySocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:mainQueue];
            NSMutableDictionary *data = [NSMutableDictionary dictionary];
            [data setObject:[rsPrinterIP stringForColumn:@"PQ_PrinterIP"] forKey:@"PQ_PrinterIP"];
            [data setObject:[rsPrinterIP stringForColumn:@"PQ_PrinterBrand"] forKey:@"PQ_PrinterBrand"];
            [data setObject:gcdArraySocket forKey:@"XinYe"];
            [testPrinterArray addObject:data];
            data = nil;
            
        }
        [rsPrinterIP close];
    }];
    [queue close];
    
    testPrinterIndex = 0;
    NSError *err = nil;
    
    if (testPrinterArray.count > 0) {
        [[[testPrinterArray objectAtIndex:testPrinterIndex] objectForKey:@"XinYe"] connectToHost:[[testPrinterArray objectAtIndex:testPrinterIndex] objectForKey:@"PQ_PrinterIP"] onPort:9100 withTimeout:1 error:&err];
    }
    */
    /*
    NSMutableArray *printQueueData = [[NSMutableArray alloc] init];
    NSMutableArray *kitchenQueueData = [[NSMutableArray alloc] init];
    NSMutableArray *printOptionData = [[NSMutableArray alloc] init];
    
    if (![[[LibraryAPI sharedInstance] getPrinterUUID] isEqualToString:@"Non"]) {
        [PosApi initPrinter];
    }
    
    [self arrayConnectToXinYePrinter];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        int kitchenReceiptGroup = 0;
        
        FMResultSet *rsGs = [db executeQuery:@"Select GS_KitchenReceiptGrouping from GeneralSetting"];
        
        if ([rsGs next]) {
            kitchenReceiptGroup = [rsGs intForColumn:@"GS_KitchenReceiptGrouping"];
        }
        [rsGs close];
        
        for (int j =0; j < xinYeConnectionArray.count; j++)
        {
            if ([[[xinYeConnectionArray objectAtIndex:j]objectForKey:@"XinYe"] connectOK]) {
                NSLog(@"Connected printer");
            }
        }
        
        FMResultSet *rsDocType = [db executeQuery:@"Select PQ_DocType from PrintQueue Group by PQ_DocType Order by PQ_DocType desc"];
        
        while ([rsDocType next]) {
            if ([[rsDocType stringForColumn:@"PQ_DocType"] isEqualToString:@"Kitchen"])
            {
                
                for (int j =0; j < xinYeConnectionArray.count; j++)
                {
                    if (kitchenReceiptGroup == 0) {
                        FMResultSet *rsPQ = [db executeQuery:@"Select * from PrintQueue where PQ_Status = ? and PQ_PrinterIP = ? and PQ_DocType = ? and PQ_OrderType in (?,?)",@"Print",[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"IpAdd"],@"Kitchen",@"ItemOrder",@"PackageItemOrder"];
                        
                        while ([rsPQ next]) {
                            [kitchenQueueData removeAllObjects];
                            
                            FMResultSet *rsKQueue = [db executeQuery:@"Select * from PrintQueue where PQ_ManualID = ?",[rsPQ stringForColumn:@"PQ_ManualID"]];
                            
                            while([rsKQueue next]) {
                                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                                [dict setObject:[rsKQueue stringForColumn:@"PQ_OrderType"] forKey:@"PQ_OrderType"];
                                [dict setObject:[rsKQueue stringForColumn:@"PQ_ItemDesc"] forKey:@"PQ_ItemDesc"];
                                [dict setObject:[rsKQueue stringForColumn:@"PQ_ItemQty"] forKey:@"PQ_ItemQty"];
                                
                                [printQueueData addObject:[rsKQueue resultDictionary]];
                                [kitchenQueueData addObject:dict];
                                dict = nil;
                            }
                            [rsKQueue close];
                            
                            if ([[rsPQ stringForColumn:@"PQ_PrinterBrand"] isEqualToString:@"XinYe"]) {
                                [printQueueData addObject:[rsPQ resultDictionary]];
                                NSMutableData *commands = [NSMutableData data];
                                //[printQueueData addObject:[rsPQ resultDictionary]];
                                commands = [EposPrintFunction createXinYeKitchenReceiptWithDBPath:dbPath TableNo:[rsPQ stringForColumn:@"PQ_TableName"] ItemNo:[rsPQ stringForColumn:@"PQ_ItemDesc"] Qty:[NSString stringWithFormat:@"Qty: %@",[rsPQ stringForColumn:@"PQ_ItemQty"]] DataArray:kitchenQueueData PackageName:[rsPQ stringForColumn:@"PQ_PackageName"]];
                                
                                NSMutableData* dataM=[NSMutableData dataWithData:[PosCommand initializePrinter]];
                                [dataM appendData:commands];
                                [[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"XinYe"] XYWriteCommandWithData:dataM];
                            }
                            else if ([[rsPQ stringForColumn:@"PQ_PrinterBrand"] isEqualToString:@"Asterix"])
                            {
                                
                                [printQueueData addObject:[rsPQ resultDictionary]];
                                
                                //[self printAsterixKRWithItemDesc:[rsPQ stringForColumn:@"PQ_ItemDesc"] IPAdd:[rsPQ stringForColumn:@"PQ_PrinterIP"] imQty:[NSString stringWithFormat:@"Qty: %@",[rsPQ stringForColumn:@"PQ_ItemQty"]] TableName:[rsPQ stringForColumn:@"PQ_TableName"] DataArray:kitchenQueueData];
                                
                            }
                            else if ([[rsPQ stringForColumn:@"PQ_PrinterBrand"] isEqualToString:@"FlyTech"])
                            {
                                
                                [printQueueData addObject:[rsPQ resultDictionary]];
                                [self printFlyTechKitchenReceiptWithIMDesc:[rsPQ stringForColumn:@"PQ_ItemDesc"] Qty:[NSString stringWithFormat:@"Qty: %@",[rsPQ stringForColumn:@"PQ_ItemQty"]] TableName:[rsPQ stringForColumn:@"PQ_TableName"] DataArray:kitchenQueueData];
                            }
                            
                        }
                        [rsPQ close];
                        
                    }
                    else
                    {
                        FMResultSet *rsPQTable = [db executeQuery:@"Select PQ_TableName,PQ_PrinterName from PrintQueue Group by PQ_PrinterName"];
                        
                        while ([rsPQTable next]) {
                            
                            FMResultSet *rsPQ = [db executeQuery:@"Select * from PrintQueue where PQ_Status = ? and PQ_PrinterIP = ? and PQ_TableName = ? and PQ_DocType = ? and PQ_OrderType = ? and PQ_PrinterName = ?",@"Print",[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"IpAdd"],[rsPQTable stringForColumn:@"PQ_TableName"],@"Kitchen",@"ItemOrder",[rsPQTable stringForColumn:@"PQ_PrinterName"]];
                            
                            NSMutableString *mString = [[NSMutableString alloc]init];
                            NSMutableData *commands = [NSMutableData data];
                            
                            while ([rsPQ next]) {
                                
                                [printQueueData addObject:[rsPQ resultDictionary]];
                                [mString appendString:[PublicMethod makeKitchen//GroupReceiptFormatWithItemDesc:[rsPQ stringForColumn:@"PQ_ItemDesc"] ItemQty:[rsPQ stringForColumn:@"PQ_ItemQty"] PackageName:[rsPQ stringForColumn:@"PQ_PackageName"]]];
                                
                                FMResultSet *rsKQueue = [db executeQuery:@"Select * from PrintQueue where PQ_ManualID = ? and PQ_OrderType = ? and PQ_PrinterName = ?",[rsPQ stringForColumn:@"PQ_ManualID"],@"CondimentOrder", [rsPQTable stringForColumn:@"PQ_PrinterName"]];
                                
                                while([rsKQueue next])
                                {
                                    [printQueueData addObject:[rsKQueue resultDictionary]];
                                    
                                    [mString appendString:[NSString stringWithFormat:@" - %@ %@\r\n",[rsKQueue stringForColumn:@"PQ_ItemDesc"],[rsKQueue stringForColumn:@"PQ_ItemQty"]]];
                                    [mString appendString:@"\r\n"];
                                }
                                [mString appendString:@"------------------------------\r\n"];
                                [rsKQueue close];
                            }
                            
                            if ([[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"Brand"] isEqualToString:@"XinYe"]) {
                                [commands appendData:[PosCommand selectAlignment:0]]; //align left
                                [commands appendData:[PosCommand selectFont:1]];
                                [commands appendData:[PosCommand selectCharacterSize:25]];
                                [commands appendData:[[NSString stringWithFormat:@"Table : %@\n\n",[rsPQTable stringForColumn:@"PQ_TableName"]] dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
                                
                                [commands appendData:[mString dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
                                [commands appendData:[PosCommand printAndFeedLine]];
                                [commands appendData:[PosCommand selectCharacterSize:0]];
                                [commands appendData:[PosCommand printAndFeedLine]];
                                [commands appendData:[PosCommand printAndFeedLine]];
                                [commands appendData:[PosCommand printAndFeedLine]];
                                [commands appendData:[PosCommand printAndFeedLine]];
                                [commands appendData:[PosCommand selectCutPageModelAndCutpage:0]];
                                
                                NSMutableData* dataM=[NSMutableData dataWithData:[PosCommand initializePrinter]];
                                [dataM appendData:commands];
                                
                                if ([mString length] > 0) {
                                    [[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"XinYe"] XYWriteCommandWithData:dataM];
                                    //NSLog(@"%@",[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"IpAdd"]);
                                }
                                else
                                {
                                    [self showAlertView:@"Data missing" title:@"Warning"];
                                }
                            }
                            else if ([[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"Brand"] isEqualToString:@"Asterix"]) {
                                //[self printAsterixKRGroupWithIpAdd:[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"IpAdd"] TableName:[rsPQTable stringForColumn:@"PQ_TableName"] Data:mString];
                            }
                            else if ([[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"Brand"] isEqualToString:@"FlyTech"]) {
                                [self printFlyTechKRGroupWithData:mString TableName:[rsPQTable stringForColumn:@"PQ_TableName"]];
                            }
                            
                            mString = nil;
                            [rsPQ close];
                        }
                        [rsPQTable close];
                    }
                }
            }
            else if ([[rsDocType stringForColumn:@"PQ_DocType"] isEqualToString:@"KitchenNotice"])
            {
                for (int j =0; j < xinYeConnectionArray.count; j++)
                {
                    FMResultSet *rsPQ = [db executeQuery:@"select PQ_No,PQ_PrinterIP, PQ_PrinterBrand, PQ_DocNo, PQ_TableName,PQ_DocType from PrintQueue where PQ_PrinterIP = ? and PQ_DocType = ? group by PQ_PrinterIP, PQ_PrinterBrand",[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"IpAdd"],@"KitchenNotice"];
                    
                    while ([rsPQ next]) {
                        [printQueueData addObject:[rsPQ resultDictionary]];
                        if ([[rsPQ stringForColumn:@"PQ_PrinterBrand"] isEqualToString:@"XinYe"]) {
                            [printQueueData addObject:[rsPQ resultDictionary]];
                            NSMutableData *commands = [NSMutableData data];
                            
                            commands = [EposPrintFunction createXinYeKitchenReceiptWithDBPath:dbPath TableNo:[rsPQ stringForColumn:@"PQ_DocNo"] ItemNo:@"Transfer to" Qty:[NSString stringWithFormat:@"Table No: %@",[rsPQ stringForColumn:@"PQ_TableName"]] DataArray:nil PackageName:@""];
                            
                            NSMutableData* dataM=[NSMutableData dataWithData:[PosCommand initializePrinter]];
                            [dataM appendData:commands];
                            [[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"XinYe"] XYWriteCommandWithData:dataM];
                        }
                        else if ([[rsPQ stringForColumn:@"PQ_PrinterBrand"] isEqualToString:@"Asterix"])
                        {
                            [printQueueData addObject:[rsPQ resultDictionary]];
                            //[self printAsterixKRWithItemDesc:@"Transfer to" IPAdd:[rsPQ stringForColumn:@"PQ_PrinterIP"] imQty:[NSString stringWithFormat:@"Table No: %@",[rsPQ stringForColumn:@"PQ_DocNo"]] TableName:[rsPQ stringForColumn:@"PQ_TableName"] DataArray:nil];
                        }
                        else if ([[rsPQ stringForColumn:@"PQ_PrinterBrand"] isEqualToString:@"FlyTech"])
                        {
                            [printQueueData addObject:[rsPQ resultDictionary]];
                            [self printFlyTechKitchenReceiptWithIMDesc:[rsPQ stringForColumn:@"PQ_ItemDesc"] Qty:[NSString stringWithFormat:@"Table No: %@",[rsPQ stringForColumn:@"PQ_DocNo"]] TableName:[rsPQ stringForColumn:@"PQ_TableName"] DataArray:nil];
                        }
                        
                    }
                    [rsPQ close];
                    
                }
            }
            else if ([[rsDocType stringForColumn:@"PQ_DocType"] isEqualToString:@"SalesOrder"])
            {
                for (int j =0; j < xinYeConnectionArray.count; j++)
                {
                    FMResultSet *rsPQ = [db executeQuery:@"Select * from PrintQueue where PQ_Status = ? and PQ_PrinterIP = ? and PQ_DocType = ?",@"Print",[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"IpAdd"],@"SalesOrder"];
                    
                    while ([rsPQ next]) {
                        [printQueueData addObject:[rsPQ resultDictionary]];
                        [compData removeAllObjects];
                        [receiptData removeAllObjects];
                        
                        FMResultSet *rsCompany = [db executeQuery:@"Select * from Company"];
                        while ([rsCompany next]) {
                            [compData addObject:[rsCompany resultDictionary]];
                        }
                        [rsCompany close];
                        //int i =0;
                        FMResultSet *rs = [db executeQuery:@"Select *, IFNULL(SOD_TaxCode,'') || ': ' || SOD_ItemDescription as ItemDesc ,SOD_ItemDescription as ItemDesc2,"
                            " Case when length(SOD_ModifierHdrCode) > 0 then 'PackageItemOrder' else 'ItemOrder'  end as 'OrderType' "
                                           " from SalesOrderHdr Hdr "
                                           " left join SalesOrderDtl Dtl on Hdr.SOH_DocNo = Dtl.SOD_DocNo"
                                           " left join ItemMast IM on IM.IM_ItemCode = Dtl.SOD_ItemCode"
                                           " where Hdr.SOH_DocNo = ? order by SOD_AutoNo",[rsPQ stringForColumn:@"PQ_DocNo"]];
                        
                        while ([rs next]) {
                            
                            [receiptData addObject:[rs resultDictionary]];
                            
                            FMResultSet *rsCdt = [db executeQuery:@"Select *,'CondimentOrder' as OrderType from SalesOrderCondiment where SOC_CDManualKey = ?",[rs stringForColumn:@"SOD_ManualID"]];
                            
                            while ([rsCdt next]) {
                                [receiptData addObject:[rsCdt resultDictionary]];
                            }
                            [rsCdt close];
                        }
                        
                        [rs close];
                        
                        if ([[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"Brand"] isEqualToString:@"XinYe"])
                        {
                            NSMutableData *commands = [NSMutableData data];
                            commands = [EposPrintFunction generateSalesOrderReceiptFormatWithComapnyArray:compData SalesOrderArray:receiptData EnableGst:[[LibraryAPI sharedInstance] getEnableGst] PrinterBrand:[rsPQ stringForColumn:@"PQ_PrinterBrand"] ReceiptLength:48];
                            
                            NSMutableData* dataM=[NSMutableData dataWithData:[PosCommand initializePrinter]];
                            [dataM appendData:commands];
                            
                            [[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"XinYe"] XYWriteCommandWithData:dataM];
                        }
                        else if ([[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"Brand"] isEqualToString:@"Asterix"])
                        {
                            
                            //[self printAsterixSalesOrderWithIpAdd:[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"IpAdd"] CompanyArray:compData SalesOrderArray:receiptData];
                            
                            
                        }
                        else if ([[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"Brand"] isEqualToString:@"FlyTech"])
                        {
                            [self printFlyTechSalesOrderReceiptWithCompanyData:compData SalesOrderData:receiptData];
                        }
                        
                    }
                    
                }
                
            }
            else if ([[rsDocType stringForColumn:@"PQ_DocType"] isEqualToString:@"Receipt"] || [[rsDocType stringForColumn:@"PQ_DocType"] isEqualToString:@"ReprintReceipt"])
            {
                for (int j =0; j < xinYeConnectionArray.count; j++)
                {
                    FMResultSet *rsPQ = [db executeQuery:@"Select * from PrintQueue where PQ_Status = ? and PQ_PrinterIP = ? and PQ_DocType = ?",@"Print",[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"IpAdd"],[rsDocType stringForColumn:@"PQ_DocType"]];
                    
                    while ([rsPQ next]) {
                        [printQueueData addObject:[rsPQ resultDictionary]];
                        [compData removeAllObjects];
                        [receiptData removeAllObjects];
                        [gstData removeAllObjects];
                        [printOptionData removeAllObjects];
                        
                        FMResultSet *rsCompany = [db executeQuery:@"Select * from Company"];
                        while ([rsCompany next]) {
                            [compData addObject:[rsCompany resultDictionary]];
                        }
                        [rsCompany close];
                        
                        FMResultSet *rsGst = [db executeQuery:@"Select * from GeneralSetting"];
                        if ([rsGst next]) {
                            [gstData addObject:[rsGst resultDictionary]];
                            
                        }
                        [rsCompany close];
                        
                        FMResultSet *rs = [db executeQuery:@"Select *,IFNULL(IvD_ItemTaxCode,'') || ': ' || IvD_ItemDescription as ItemDesc,IvD_ItemDescription as ItemDesc2, IFNULL(IvD_ItemTaxCode,'-') as Flag,"
                            " Case when length(IvD_ModifierHdrCode) > 0 then 'PackageItemOrder' else 'ItemOrder'  end as 'OrderType'"
                                           " from InvoiceHdr InvH "
                                           " left join InvoiceDtl InvD on InvH.IvH_DocNo = InvD.IvD_DocNo"
                                           " left join ItemMast IM on IM.IM_ItemCode = InvD.IvD_ItemCode"
                                           " where InvH.IvH_DocNo = ? order by IvD_AutoNo",[rsPQ stringForColumn:@"PQ_DocNo"]];
                        
                        while ([rs next]) {
                            [receiptData addObject:[rs resultDictionary]];
                            
                            FMResultSet *rsCdt = [db executeQuery:@"Select *,'CondimentOrder' as OrderType from InvoiceCondiment where IVC_CDManualKey = ?",[rs stringForColumn:@"IvD_ManualID"]];
                            
                            while ([rsCdt next])
                            {
                                [receiptData addObject:[rsCdt resultDictionary]];
                            }
                            [rsCdt close];
                            
                        }
                        
                        [rs close];
                        
                        FMResultSet *rsPrintOption = [db executeQuery:@"Select * from PrintOption"];
                        
                        if ([rsPrintOption next]) {
                            [printOptionData addObject:[rsPrintOption resultDictionary]];
                        }
                        
                        if ([[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"Brand"] isEqualToString:@"XinYe"])
                        {
                            NSMutableData *commands = [NSMutableData data];
                            
                            commands = [EposPrintFunction generateReceiptFormatWithComapnyArray:compData ReceiptArray:receiptData EnableGst:[[LibraryAPI sharedInstance]getEnableGst] KickOutDrawerYN:@"Y" PrinterBrand:[rsPQ stringForColumn:@"PQ_PrinterBrand"] ReceiptLength:48 GstArray:gstData PrintOptionArray:printOptionData PrintType:[rsPQ stringForColumn:@"PQ_DocType"]];
                            
                            NSMutableData* dataM=[NSMutableData dataWithData:[PosCommand initializePrinter]];
                            [dataM appendData:commands];
                            
                            [[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"XinYe"] XYWriteCommandWithData:dataM];
                        }
                        else if ([[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"Brand"] isEqualToString:@"Asterix"])
                        {
                            //[self printAsterixReceiptWithIpAdd:[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"IpAdd"] CompanyArray:compData CSArray:receiptData];
                        }
                        else if ([[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"Brand"] isEqualToString:@"FlyTech"])
                        {
                            [self printFlyTechReceiptWithCompanyData:compData CSArray:receiptData PrintOption:printOptionData PrintType:[rsPQ stringForColumn:@"PQ_DocType"]];
                        }
                        
                    }
                    
                }
            }
            else if ([[rsDocType stringForColumn:@"PQ_DocType"] isEqualToString:@"DailyCollection"])
            {
                for (int j =0; j < xinYeConnectionArray.count; j++)
                {
                    FMResultSet *rsPQ = [db executeQuery:@"Select * from PrintQueue where PQ_Status = ? and PQ_PrinterIP = ? and PQ_DocType = ?",@"Print",[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"IpAdd"],@"DailyCollection"];
                    
                    while ([rsPQ next]) {
                        [printQueueData addObject:[rsPQ resultDictionary]];
                        
                        NSMutableData* dataM=[NSMutableData dataWithData:[PosCommand initializePrinter]];
                        [dataM appendData:[[LibraryAPI sharedInstance] getDailyCollectionData]];
                        [[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"XinYe"] XYWriteCommandWithData:dataM];
                    }
                    
                }
            }
        }
        
        [rsDocType close];
        
        
        for (int i = 0; i < printQueueData.count; i++) {
            //[db executeUpdate:@"Delete from PrintQueue where PQ_No = ?",[NSNumber numberWithInt:[[[printQueueData objectAtIndex:i] objectForKey:@"PQ_No"] integerValue]]];
            //NSLog(@"PrintQueue %@",[[printQueueData objectAtIndex:i] objectForKey:@"PQ_No"]);
        }
        
        [printQueueData removeAllObjects];
        
        
    }];
    [queue close];
    
    printQueueData = nil;
    kitchenQueueData = nil;
    printOptionData = nil;
    */
    //[_thread cancel];
    //[[NSNotificationCenter defaultCenter]postNotificationName:@"FireBackAutoPrintDocumentWithNotification" object:nil userInfo:nil];
}

-(void)arrayConnectToXinYePrinter
{
    NSMutableArray *printerIpArray = [[NSMutableArray alloc] init];
    printerIpArray = [PublicSqliteMethod getAllItemPrinterIpAddWithDBPath:dbPath];
    //[xinYeConnectionArray removeAllObjects];
    for (int k = 0; k < xinYeConnectionArray.count; k++) {
        if ([[[xinYeConnectionArray objectAtIndex:k] objectForKey:@"Brand"] isEqualToString:@"XinYe"]) {
            [[[xinYeConnectionArray objectAtIndex:k] objectForKey:@"XinYe"] XYDisConnect];

        }
    }
    
    [xinYeConnectionArray removeAllObjects];
    
    for (int i = 0; i < printerIpArray.count; i++) {
        __block NSMutableDictionary *data = [NSMutableDictionary dictionary];
        if ([[[printerIpArray objectAtIndex:i] objectForKey:@"PQ_PrinterBrand"] isEqualToString:@"XinYe"]) {
            XYWIFIManager *xinYeWifi = [[XYWIFIManager alloc] init];
            //xinYeWifi.delegate = self;
            [xinYeWifi XYDisConnect];
            
            [xinYeWifi XYConnectWithHost:[[printerIpArray objectAtIndex:i] objectForKey:@"PQ_PrinterIP"] port:9100 completion:^(BOOL isConnect) {
                if (isConnect) {
                    [data setObject:[[printerIpArray objectAtIndex:i] objectForKey:@"PQ_PrinterIP"] forKey:@"IpAdd"];
                    [data setObject:[[printerIpArray objectAtIndex:i] objectForKey:@"PQ_PrinterBrand"] forKey:@"Brand"];
                    [data setObject:xinYeWifi forKey:@"XinYe"];
                    
                }
                [xinYeConnectionArray addObject:data];
                data = nil;
            }];
            xinYeWifi = nil;
        }
        else
        {
            [data setObject:[[printerIpArray objectAtIndex:i] objectForKey:@"PQ_PrinterIP"] forKey:@"IpAdd"];
            [data setObject:[[printerIpArray objectAtIndex:i] objectForKey:@"PQ_PrinterBrand"] forKey:@"Brand"];
            [data setObject:@"Nil" forKey:@"XinYe"];
            [xinYeConnectionArray addObject:data];
        }
        
    }
    
}

/*
-(void)sendCommandToXinYePrinterKitchenWithIMDesc:(NSString *)imDesc Qty:(NSString *)imQty IPAdd:(NSString *)ipAdd TableName:(NSString *)tableName
{
    NSMutableData *commands = [NSMutableData data];
    
    commands = [EposPrintFunction createXinYeKitchenReceiptWithDBPath:dbPath TableNo:tableName ItemNo:imDesc Qty:imQty DataArray:nil PackageName:@""];
    
    NSMutableData* dataM=[NSMutableData dataWithData:[PosCommand initializePrinter]];
    [dataM appendData:commands];
    [xinYeGeneralWfMng XYWriteCommandWithData:dataM];
    
}
*/

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

}

- (void)XYWIFIManagerDidDisconnected:(XYWIFIManager *)manager {
    
    if (!manager.isAutoDisconnect) {
        //        self.myTab.hidden = YES;
    }
    
    
    //[self showAlertMsgWithMessage:@"XP900 has been disconnect." Title:@"Warning"];
    NSLog(@"XYWIFIManagerDidDisconnected");
    
}


#pragma mark - get ip address
-(NSString *)getIpAddress
{
    
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en1"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
                else if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"])
                {
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    
    if ([address isEqualToString:@"error"]) {
        //[[LibraryAPI sharedInstance]setIpAddress:@"192.168.0.5"];
        UIAlertController * alert = [[LibraryAPI sharedInstance] showAlertViewWithMsg:@"Cannot get ip address" Title:@"Warning"];
        
        [self presentViewController:alert animated:YES completion:nil];
        
        alert = nil;
        
    }
    else
    {
        [[LibraryAPI sharedInstance]setIpAddress:address];
    }
    return address;
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


- (IBAction)popOverRegisterView:(id)sender {
    ActivateDeviceViewController *activateDeviceViewController = [[ActivateDeviceViewController alloc] init];
    activateDeviceViewController.delegate = self;
    
    UINavigationController *navbar = [[UINavigationController alloc]  initWithRootViewController:activateDeviceViewController];
    navbar.view.backgroundColor = [UIColor clearColor];
    [navbar setModalPresentationStyle:UIModalPresentationOverCurrentContext];
    [navbar setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    //[self presentViewController:registrationViewController animated:YES completion:nil];
    [self.navigationController presentViewController:navbar animated:YES completion:nil];
    
}

- (void)onBleDiscoveredDevice:(BleDeviceInfo*)deviceInfo
{
    //[self showAlertView:deviceInfo.mName title:@"Testing"];
}
             

-(void)redirectToAppStore
{
    NSString *simple = @"itms-apps://itunes.apple.com/app/id1151675338";
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:simple]];
}

/*
-(void)addNumber:(int)number1 withNumber:(int)number2 andCompletionHandler:(void (^)(int))completionHandler
{
    int result = number1 + number2;
    completionHandler(result);
}

-(void)minusNumber:(int)number1 withNumber:(int)number2 addCompletion:(void (^)(int))comple
{
    int dd = number2 - number1;
    comple(dd);
}
 */

-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    /*
    NSLog(@"Found open port %d on %@", port, host);
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data setObject:host forKey:@"PQ_PrinterIP"];
    [data setObject:@"XinYe" forKey:@"PQ_PrinterBrand"];
    [data setObject:@"Connected" forKey:@"PQ_Status"];
    [printerConnectStatusArray addObject:data];
    data = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        @autoreleasepool {
            //一樣打notify 在main queue
            [[NSNotificationCenter defaultCenter] postNotificationName:@"TestPrinterSocket" object:nil];
            [sock disconnect];
        }
    });
    */
    [sock disconnect];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    NSLog(@"Disconnected: %@", err ? err : @"");
    
    if (err) {
        
        //[self showAlertView:@"Cannot connect to printer" title:@"Warning"];
        //[[LibraryAPI sharedInstance] showAlertMessageBox];
        
        UIViewController *topView = [PublicMethod getTopViewController];
        
        UIAlertController * alertView = [UIAlertController
                                     alertControllerWithTitle:@"Warning"
                                         message:[NSString stringWithFormat:@"Cannot connect printer: %@. Try again ?",xYPrinterName]
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* yesButton = [UIAlertAction
                                    actionWithTitle:@"OK"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
                                        [[NSNotificationCenter defaultCenter]postNotificationName:@"FireBackAutoPrintDocumentWithNotification" object:nil userInfo:nil];
                                    }];
        
        UIAlertAction* noButton = [UIAlertAction
                                   actionWithTitle:@"Cancel"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {
                                       //Handle no, thanks button
                                       [self arrayConnectToXinYePrinter2WithIpAddress:xYPrinterIP Brand:@"XinYe"];
                                       //[[NSNotificationCenter defaultCenter]postNotificationName:@"FireBackAutoPrintDocumentWithNotification" object:nil userInfo:nil];
                                       [self startPrintingProcess];
                                   }];
        
        [alertView addAction:yesButton];
        [alertView addAction:noButton];
        
        [topView presentViewController:alertView animated:NO completion:nil];
        
        topView = nil;
    }
    else
    {
        [self arrayConnectToXinYePrinter2WithIpAddress:xYPrinterIP Brand:@"XinYe"];
        [self startPrintingProcess];
        // try to disable this area see how - azlim
        // try to move to autoPrintFromServerWithNotification
        /*
        for (int k = 0; k < xinYeConnectionArray.count; k++) {
            if ([[[xinYeConnectionArray objectAtIndex:k] objectForKey:@"Brand"] isEqualToString:@"XinYe"]) {
                [[[xinYeConnectionArray objectAtIndex:k] objectForKey:@"XinYe"] XYDisConnect];
                
            }
        }
         */
        
    }
    //[gcdSocket connectToHost:@"192.168.20.14" onPort:9100 withTimeout:0.01 error:nil];
}

-(void)startPrintingProcess
{
    NSMutableArray *printQueueData = [[NSMutableArray alloc] init];
    NSMutableArray *kitchenQueueData = [[NSMutableArray alloc] init];
    NSMutableArray *printOptionData = [[NSMutableArray alloc] init];
    
    if (![[[LibraryAPI sharedInstance] getPrinterUUID] isEqualToString:@"Non"]) {
        [PosApi initPrinter];
    }
    
    //[self arrayConnectToXinYePrinter];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        int kitchenReceiptGroup = 0;
        int printPackageItemDetail = 0;
        
        FMResultSet *rsGs = [db executeQuery:@"Select GS_KitchenReceiptGrouping from GeneralSetting"];
        
        if ([rsGs next]) {
            kitchenReceiptGroup = [rsGs intForColumn:@"GS_KitchenReceiptGrouping"];
        }
        [rsGs close];
        
        FMResultSet *rsPrintOption = [db executeQuery:@"Select PO_ShowPackageItemDetail from PrintOption"];
        
        if ([rsPrintOption next]) {
            printPackageItemDetail = [rsPrintOption intForColumn:@"PO_ShowPackageItemDetail"];
        }
        [rsPrintOption close];
        
        FMResultSet *rsDocType = [db executeQuery:@"Select PQ_DocType from PrintQueue Group by PQ_DocType Order by PQ_DocType desc"];
        
        while ([rsDocType next]) {
            if ([[rsDocType stringForColumn:@"PQ_DocType"] isEqualToString:@"Kitchen"])
            {
                
                for (int j =0; j < xinYeConnectionArray.count; j++)
                {
                    if (kitchenReceiptGroup == 0) {
                        FMResultSet *rsPQ = [db executeQuery:@"Select * from PrintQueue where PQ_Status = ? and PQ_PrinterIP = ? and PQ_DocType = ? and PQ_OrderType in (?,?)",@"Print",[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"IpAdd"],@"Kitchen",@"ItemOrder",@"PackageItemOrder"];
                        
                        while ([rsPQ next]) {
                            [kitchenQueueData removeAllObjects];
                            
                            FMResultSet *rsKQueue = [db executeQuery:@"Select * from PrintQueue where PQ_ManualID = ?",[rsPQ stringForColumn:@"PQ_ManualID"]];
                            
                            while([rsKQueue next]) {
                                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                                [dict setObject:[rsKQueue stringForColumn:@"PQ_OrderType"] forKey:@"PQ_OrderType"];
                                [dict setObject:[rsKQueue stringForColumn:@"PQ_ItemDesc"] forKey:@"PQ_ItemDesc"];
                                [dict setObject:[rsKQueue stringForColumn:@"PQ_ItemQty"] forKey:@"PQ_ItemQty"];
                                
                                [printQueueData addObject:[rsKQueue resultDictionary]];
                                [kitchenQueueData addObject:dict];
                                dict = nil;
                            }
                            [rsKQueue close];
                            
                            if ([[rsPQ stringForColumn:@"PQ_PrinterBrand"] isEqualToString:@"XinYe"]) {
                                [printQueueData addObject:[rsPQ resultDictionary]];
                                NSMutableData *commands = [NSMutableData data];
                                //[printQueueData addObject:[rsPQ resultDictionary]];
                                commands = [EposPrintFunction createXinYeKitchenReceiptWithDBPath:dbPath TableNo:[rsPQ stringForColumn:@"PQ_TableName"] ItemNo:[rsPQ stringForColumn:@"PQ_ItemDesc"] Qty:[NSString stringWithFormat:@"Qty: %@",[rsPQ stringForColumn:@"PQ_ItemQty"]] DataArray:kitchenQueueData PackageName:[rsPQ stringForColumn:@"PQ_PackageName"] ShowPackageDetail:printPackageItemDetail];
                                
                                NSMutableData* dataM=[NSMutableData dataWithData:[PosCommand initializePrinter]];
                                [dataM appendData:commands];
                                
                                [[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"XinYe"] XYWriteCommandWithData:dataM];
                                commands = nil;
                            }
                            else if ([[rsPQ stringForColumn:@"PQ_PrinterBrand"] isEqualToString:@"Asterix"])
                            {
                                
                                [printQueueData addObject:[rsPQ resultDictionary]];
                                
                                //[self printAsterixKRWithItemDesc:[rsPQ stringForColumn:@"PQ_ItemDesc"] IPAdd:[rsPQ stringForColumn:@"PQ_PrinterIP"] imQty:[NSString stringWithFormat:@"Qty: %@",[rsPQ stringForColumn:@"PQ_ItemQty"]] TableName:[rsPQ stringForColumn:@"PQ_TableName"] DataArray:kitchenQueueData];
                                
                            }
                            else if ([[rsPQ stringForColumn:@"PQ_PrinterBrand"] isEqualToString:@"FlyTech"])
                            {
                                
                                [printQueueData addObject:[rsPQ resultDictionary]];
                                [self printFlyTechKitchenReceiptWithIMDesc:[rsPQ stringForColumn:@"PQ_ItemDesc"] Qty:[NSString stringWithFormat:@"Qty: %@",[rsPQ stringForColumn:@"PQ_ItemQty"]] TableName:[rsPQ stringForColumn:@"PQ_TableName"] DataArray:kitchenQueueData];
                            }
                            
                        }
                        [rsPQ close];
                        
                    }
                    else
                    {
                        FMResultSet *rsPQTable = [db executeQuery:@"Select PQ_TableName,PQ_PrinterName from PrintQueue Group by PQ_PrinterName"];
                        
                        while ([rsPQTable next]) {
                            
                            FMResultSet *rsPQ = [db executeQuery:@"Select * from PrintQueue where PQ_Status = ? and PQ_PrinterIP = ? and PQ_TableName = ? and PQ_DocType = ? and PQ_OrderType in (?,?) and PQ_PrinterName = ?",@"Print",[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"IpAdd"],[rsPQTable stringForColumn:@"PQ_TableName"],@"Kitchen",@"ItemOrder",@"PackageItemOrder",[rsPQTable stringForColumn:@"PQ_PrinterName"]];
                            
                            NSMutableString *mString = [[NSMutableString alloc]init];
                            NSMutableString *mString2 = [[NSMutableString alloc]init];
                            //NSMutableString *mStringFlyTech = [[NSMutableString alloc]init];
                            NSMutableString *mStringCondiment = [[NSMutableString alloc]init];
                            NSMutableData *commands = [NSMutableData data];
                            NSMutableData *content = [NSMutableData data];
                            NSString *packageName;
                            
                            while ([rsPQ next]) {
                                if ([rsPQ stringForColumn:@"PQ_PackageName"].length  > 0 && [[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"Brand"]isEqualToString:@"XinYe"]) {
                                    NSUInteger spaceAdd = 25 - [rsPQ stringForColumn:@"PQ_PackageName"].length;
                                    NSString *detail1 = [NSString stringWithFormat:@"%@%@",
                                                         [rsPQ stringForColumn:@"PQ_PackageName"],
                                                         [@" " stringByPaddingToLength:spaceAdd withString:@" " startingAtIndex:0]];
                                    packageName = [PublicMethod processChineseOrEnglishCharWithDetail1:detail1 ItemDesc:[rsPQ stringForColumn:@"PQ_PackageName"] FixLength:25];
                                    [content appendData:[PosCommand selectFont:1]];
                                    [content appendData:[PosCommand selectCharacterSize:33]];
                                    [content appendData:[[NSString stringWithFormat:@"%@\n\n",packageName] dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
                                }
                                
                                [printQueueData addObject:[rsPQ resultDictionary]];
                                mStringCondiment.string = @"";
                                [mString appendString:[PublicMethod makeKitchenGroupReceiptFormatWithItemDesc:[rsPQ stringForColumn:@"PQ_ItemDesc"] ItemQty:[rsPQ stringForColumn:@"PQ_ItemQty"] PackageName:[rsPQ stringForColumn:@"PQ_PackageName"] ShowPackageDetail:printPackageItemDetail PrinterBrand:[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"Brand"]]];
                                
                                FMResultSet *rsKQueue = [db executeQuery:@"Select * from PrintQueue where PQ_ManualID = ? and PQ_OrderType = ? and PQ_PrinterName = ?",[rsPQ stringForColumn:@"PQ_ManualID"],@"CondimentOrder", [rsPQTable stringForColumn:@"PQ_PrinterName"]];
                                
                                while([rsKQueue next])
                                {
                                    [printQueueData addObject:[rsKQueue resultDictionary]];
                                    
                                    [mStringCondiment appendString:[NSString stringWithFormat:@" - %@ %@\r\n",[rsKQueue stringForColumn:@"PQ_ItemDesc"],[rsKQueue stringForColumn:@"PQ_ItemQty"]]];
                                    [mStringCondiment appendString:@"\r\n"];
                                }
                                [mStringCondiment appendString:@"------------------------------\r\n"];
                                [mString2 appendString:mString];
                                [mString2 appendString:mStringCondiment];
                                
                                if ([[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"Brand"] isEqualToString:@"XinYe"]) {
                                    [content appendData:[PosCommand selectFont:1]];
                                    [content appendData:[PosCommand selectCharacterSize:25]];
                                    [content appendData:[[NSString stringWithFormat:@"%@\n\n",mString2] dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
                                    mString.string = @"";
                                    mString2.string = @"";
                                }
                                else
                                {
                                    [mString appendString:mStringCondiment];
                                }
                                
                                [rsKQueue close];
                            }
                            
                            if ([[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"Brand"] isEqualToString:@"XinYe"]) {
                                [commands appendData:[PosCommand selectAlignment:0]]; //align left
                                [commands appendData:[PosCommand selectFont:1]];
                                [commands appendData:[PosCommand selectCharacterSize:25]];
                                [commands appendData:[[NSString stringWithFormat:@"Table : %@\n\n",[rsPQTable stringForColumn:@"PQ_TableName"]] dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
                                
                                //[commands appendData:[mString dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]];
                                [commands appendData:content];
                                [commands appendData:[PosCommand printAndFeedLine]];
                                [commands appendData:[PosCommand selectCharacterSize:0]];
                                [commands appendData:[PosCommand printAndFeedLine]];
                                [commands appendData:[PosCommand printAndFeedLine]];
                                [commands appendData:[PosCommand printAndFeedLine]];
                                [commands appendData:[PosCommand printAndFeedLine]];
                                [commands appendData:[PosCommand selectCutPageModelAndCutpage:0]];
                                
                                NSMutableData* dataM=[NSMutableData dataWithData:[PosCommand initializePrinter]];
                                [dataM appendData:commands];
                                NSLog(@"Test data length - %lu",(unsigned long)commands.length);
                                if (commands.length > 40) {
                                    
                                    [[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"XinYe"] XYWriteCommandWithData:dataM];
                                    //[[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"XinYe"] XYPrinterSound:3 t:5];
                                    //NSLog(@"%@",[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"IpAdd"]);
                                }
                                else
                                {
                                    
                                    //[[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"XinYe"] XYWriteCommandWithData:dataM];
                                    NSLog(@"%@",@"Empty Commands");
                                    //[self showAlertView:@"Data missing" title:@"Warning"];
                                }
                                content = nil;
                            }
                            else if ([[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"Brand"] isEqualToString:@"Asterix"]) {
                                //[self printAsterixKRGroupWithIpAdd:[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"IpAdd"] TableName:[rsPQTable stringForColumn:@"PQ_TableName"] Data:mString];
                            }
                            else if ([[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"Brand"] isEqualToString:@"FlyTech"]) {
                                [self printFlyTechKRGroupWithData:mString2 TableName:[rsPQTable stringForColumn:@"PQ_TableName"]];
                            }
                            
                            mString = nil;
                            [rsPQ close];
                        }
                        [rsPQTable close];
                    }
                    [[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"XinYe"] XYPrinterSound:3 t:5];
                }
            }
            else if ([[rsDocType stringForColumn:@"PQ_DocType"] isEqualToString:@"KitchenNotice"])
            {
                for (int j =0; j < xinYeConnectionArray.count; j++)
                {
                    FMResultSet *rsPQ = [db executeQuery:@"select PQ_No,PQ_PrinterIP, PQ_PrinterBrand, PQ_DocNo, PQ_TableName,PQ_DocType,PQ_ItemDesc from PrintQueue where PQ_PrinterIP = ? and PQ_DocType = ? group by PQ_PrinterIP, PQ_PrinterBrand",[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"IpAdd"],@"KitchenNotice"];
                    
                    while ([rsPQ next]) {
                        [printQueueData addObject:[rsPQ resultDictionary]];
                        if ([[rsPQ stringForColumn:@"PQ_PrinterBrand"] isEqualToString:@"XinYe"]) {
                            [printQueueData addObject:[rsPQ resultDictionary]];
                            NSMutableData *commands = [NSMutableData data];
                            
                            if ([[rsPQ stringForColumn:@"PQ_ItemDesc"] isEqualToString:@"Combine To"]) {
                                commands = [EposPrintFunction createXinYeKitchenReceiptWithDBPath:dbPath TableNo:[rsPQ stringForColumn:@"PQ_TableName"] ItemNo:[rsPQ stringForColumn:@"PQ_ItemDesc"] Qty:[NSString stringWithFormat:@"Table No: %@",[rsPQ stringForColumn:@"PQ_DocNo"]] DataArray:nil PackageName:@"" ShowPackageDetail:0];
                            }
                            else if([[rsPQ stringForColumn:@"PQ_ItemDesc"] isEqualToString:@"Transfer To"])
                            {
                                commands = [EposPrintFunction createXinYeKitchenReceiptWithDBPath:dbPath TableNo:[rsPQ stringForColumn:@"PQ_DocNo"] ItemNo:[rsPQ stringForColumn:@"PQ_ItemDesc"] Qty:[NSString stringWithFormat:@"Table No: %@",[rsPQ stringForColumn:@"PQ_TableName"]] DataArray:nil PackageName:@"" ShowPackageDetail:0];
                            }
                            else
                            {
                                commands = [EposPrintFunction createXinYeKitchenReceiptWithDBPath:dbPath TableNo:[rsPQ stringForColumn:@"PQ_TableName"] ItemNo:@"Cancel Order" Qty:[rsPQ stringForColumn:@"PQ_DocNo"] DataArray:nil PackageName:@"" ShowPackageDetail:0];
                            }
                            
                            
                            NSMutableData* dataM=[NSMutableData dataWithData:[PosCommand initializePrinter]];
                            [dataM appendData:commands];
                            [[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"XinYe"] XYWriteCommandWithData:dataM];
                            //[[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"XinYe"] XYPrinterSound:3 t:5];
                        }
                        else if ([[rsPQ stringForColumn:@"PQ_PrinterBrand"] isEqualToString:@"Asterix"])
                        {
                            [printQueueData addObject:[rsPQ resultDictionary]];
                            
                        }
                        else if ([[rsPQ stringForColumn:@"PQ_PrinterBrand"] isEqualToString:@"FlyTech"])
                        {
                            [printQueueData addObject:[rsPQ resultDictionary]];
                            [self printFlyTechKitchenReceiptWithIMDesc:[rsPQ stringForColumn:@"PQ_ItemDesc"] Qty:[NSString stringWithFormat:@"Table No: %@",[rsPQ stringForColumn:@"PQ_DocNo"]] TableName:[rsPQ stringForColumn:@"PQ_TableName"] DataArray:nil];
                        }
                        
                    }
                    [rsPQ close];
                    [[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"XinYe"] XYPrinterSound:3 t:5];
                }
            }
            else if ([[rsDocType stringForColumn:@"PQ_DocType"] isEqualToString:@"SalesOrder"])
            {
                for (int j =0; j < xinYeConnectionArray.count; j++)
                {
                    FMResultSet *rsPQ = [db executeQuery:@"Select * from PrintQueue where PQ_Status = ? and PQ_PrinterIP = ? and PQ_DocType = ?",@"Print",[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"IpAdd"],@"SalesOrder"];
                    
                    while ([rsPQ next]) {
                        [printQueueData addObject:[rsPQ resultDictionary]];
                        [compData removeAllObjects];
                        [receiptData removeAllObjects];
                        
                        FMResultSet *rsCompany = [db executeQuery:@"Select * from Company"];
                        while ([rsCompany next]) {
                            [compData addObject:[rsCompany resultDictionary]];
                        }
                        [rsCompany close];
                        //int i =0;
                        FMResultSet *rs = [db executeQuery:@"Select *, IFNULL(SOD_TaxCode,'') || ': ' || SOD_ItemDescription as ItemDesc ,SOD_ItemDescription as ItemDesc2,"
                                           " Case when length(SOD_ModifierHdrCode) > 0 then 'PackageItemOrder' else 'ItemOrder'  end as 'OrderType' "
                                           " from SalesOrderHdr Hdr "
                                           " left join SalesOrderDtl Dtl on Hdr.SOH_DocNo = Dtl.SOD_DocNo"
                                           " left join ItemMast IM on IM.IM_ItemCode = Dtl.SOD_ItemCode"
                                           " where Hdr.SOH_DocNo = ? order by SOD_AutoNo",[rsPQ stringForColumn:@"PQ_DocNo"]];
                        
                        while ([rs next]) {
                            
                            [receiptData addObject:[rs resultDictionary]];
                            
                            FMResultSet *rsCdt = [db executeQuery:@"Select *,'CondimentOrder' as OrderType from SalesOrderCondiment where SOC_CDManualKey = ?",[rs stringForColumn:@"SOD_ManualID"]];
                            
                            while ([rsCdt next]) {
                                [receiptData addObject:[rsCdt resultDictionary]];
                            }
                            [rsCdt close];
                        }
                        
                        [rs close];
                        
                        if ([[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"Brand"] isEqualToString:@"XinYe"])
                        {
                            NSMutableData *commands = [NSMutableData data];
                            commands = [EposPrintFunction generateSalesOrderReceiptFormatWithComapnyArray:compData SalesOrderArray:receiptData EnableGst:[[LibraryAPI sharedInstance] getEnableGst] PrinterBrand:[rsPQ stringForColumn:@"PQ_PrinterBrand"] ReceiptLength:48];
                            
                            NSMutableData* dataM=[NSMutableData dataWithData:[PosCommand initializePrinter]];
                            [dataM appendData:commands];
                            
                            [[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"XinYe"] XYWriteCommandWithData:dataM];
                        }
                        else if ([[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"Brand"] isEqualToString:@"Asterix"])
                        {
                            
                            //[self printAsterixSalesOrderWithIpAdd:[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"IpAdd"] CompanyArray:compData SalesOrderArray:receiptData];
                            
                            
                        }
                        else if ([[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"Brand"] isEqualToString:@"FlyTech"])
                        {
                            [self printFlyTechSalesOrderReceiptWithCompanyData:compData SalesOrderData:receiptData];
                        }
                        
                    }
                    
                }
                
            }
            else if ([[rsDocType stringForColumn:@"PQ_DocType"] isEqualToString:@"Receipt"] || [[rsDocType stringForColumn:@"PQ_DocType"] isEqualToString:@"ReprintReceipt"])
            {
                for (int j =0; j < xinYeConnectionArray.count; j++)
                {
                    FMResultSet *rsPQ = [db executeQuery:@"Select * from PrintQueue where PQ_Status = ? and PQ_PrinterIP = ? and PQ_DocType = ?",@"Print",[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"IpAdd"],[rsDocType stringForColumn:@"PQ_DocType"]];
                    
                    while ([rsPQ next]) {
                        [printQueueData addObject:[rsPQ resultDictionary]];
                        [compData removeAllObjects];
                        [receiptData removeAllObjects];
                        [gstData removeAllObjects];
                        [printOptionData removeAllObjects];
                        
                        FMResultSet *rsCompany = [db executeQuery:@"Select * from Company"];
                        while ([rsCompany next]) {
                            [compData addObject:[rsCompany resultDictionary]];
                        }
                        [rsCompany close];
                        
                        FMResultSet *rsGst = [db executeQuery:@"Select * from GeneralSetting"];
                        if ([rsGst next]) {
                            [gstData addObject:[rsGst resultDictionary]];
                            
                        }
                        [rsCompany close];
                        
                        FMResultSet *rs = [db executeQuery:@"Select *,IFNULL(IvD_ItemTaxCode,'') || ': ' || IvD_ItemDescription as ItemDesc,IvD_ItemDescription as ItemDesc2, IFNULL(IvD_ItemTaxCode,'-') as Flag,"
                                           " Case when length(IvD_ModifierHdrCode) > 0 then 'PackageItemOrder' else 'ItemOrder'  end as 'OrderType'"
                                           " from InvoiceHdr InvH "
                                           " left join InvoiceDtl InvD on InvH.IvH_DocNo = InvD.IvD_DocNo"
                                           " left join ItemMast IM on IM.IM_ItemCode = InvD.IvD_ItemCode"
                                           " where InvH.IvH_DocNo = ? order by IvD_AutoNo",[rsPQ stringForColumn:@"PQ_DocNo"]];
                        
                        while ([rs next]) {
                            [receiptData addObject:[rs resultDictionary]];
                            
                            FMResultSet *rsCdt = [db executeQuery:@"Select *,'CondimentOrder' as OrderType from InvoiceCondiment where IVC_CDManualKey = ?",[rs stringForColumn:@"IvD_ManualID"]];
                            
                            while ([rsCdt next])
                            {
                                [receiptData addObject:[rsCdt resultDictionary]];
                            }
                            [rsCdt close];
                            
                        }
                        
                        [rs close];
                        
                        FMResultSet *rsPrintOption = [db executeQuery:@"Select * from PrintOption"];
                        
                        if ([rsPrintOption next]) {
                            [printOptionData addObject:[rsPrintOption resultDictionary]];
                        }
                        
                        if ([[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"Brand"] isEqualToString:@"XinYe"])
                        {
                            NSMutableData *commands = [NSMutableData data];
                            
                            commands = [EposPrintFunction generateReceiptFormatWithComapnyArray:compData ReceiptArray:receiptData EnableGst:[[LibraryAPI sharedInstance]getEnableGst] KickOutDrawerYN:@"Y" PrinterBrand:[rsPQ stringForColumn:@"PQ_PrinterBrand"] ReceiptLength:48 GstArray:gstData PrintOptionArray:printOptionData PrintType:[rsPQ stringForColumn:@"PQ_DocType"]];
                            
                            NSMutableData* dataM=[NSMutableData dataWithData:[PosCommand initializePrinter]];
                            [dataM appendData:commands];
                            
                            [[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"XinYe"] XYWriteCommandWithData:dataM];
                        }
                        else if ([[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"Brand"] isEqualToString:@"Asterix"])
                        {
                            //[self printAsterixReceiptWithIpAdd:[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"IpAdd"] CompanyArray:compData CSArray:receiptData];
                        }
                        else if ([[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"Brand"] isEqualToString:@"FlyTech"])
                        {
                            [self printFlyTechReceiptWithCompanyData:compData CSArray:receiptData PrintOption:printOptionData PrintType:[rsPQ stringForColumn:@"PQ_DocType"]];
                        }
                        
                    }
                    
                }
            }
            else if ([[rsDocType stringForColumn:@"PQ_DocType"] isEqualToString:@"DailyCollection"])
            {
                for (int j =0; j < xinYeConnectionArray.count; j++)
                {
                    FMResultSet *rsPQ = [db executeQuery:@"Select * from PrintQueue where PQ_Status = ? and PQ_PrinterIP = ? and PQ_DocType = ?",@"Print",[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"IpAdd"],@"DailyCollection"];
                    
                    while ([rsPQ next]) {
                        [printQueueData addObject:[rsPQ resultDictionary]];
                        
                        NSMutableData* dataM=[NSMutableData dataWithData:[PosCommand initializePrinter]];
                        [dataM appendData:[[LibraryAPI sharedInstance] getDailyCollectionData]];
                        [[[xinYeConnectionArray objectAtIndex:j] objectForKey:@"XinYe"] XYWriteCommandWithData:dataM];
                    }
                    
                }
            }
        }
        
        [rsDocType close];
        
        
        for (int i = 0; i < printQueueData.count; i++) {
            [db executeUpdate:@"Delete from PrintQueue where PQ_No = ?",[NSNumber numberWithInt:[[[printQueueData objectAtIndex:i] objectForKey:@"PQ_No"] integerValue]]];
            //NSLog(@"Delete PrintQueue %@",[[printQueueData objectAtIndex:i] objectForKey:@"PQ_ItemDesc"]);
        }
        
        [printQueueData removeAllObjects];
        
        
    }];
    [queue close];
    //[dbTable close];
    printQueueData = nil;
    kitchenQueueData = nil;
    printOptionData = nil;
    [_thread cancel];
    
    [[NSNotificationCenter defaultCenter]postNotificationName:@"FireBackAutoPrintDocumentWithNotification" object:nil userInfo:nil];
    
}

-(void)autoPrintFromServerWithNotification:(NSNotification *)notification
{
    
    [printQueueArray removeAllObjects];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback){
        dispatch_queue_t mainQueue = dispatch_get_main_queue();
        FMResultSet *rsPrinterIP = [db executeQuery:@"Select PQ_PrinterIP, PQ_PrinterBrand, 'Disconnected' as 'PQ_Status', PQ_PrinterName from PrintQueue group by PQ_PrinterIP,PQ_PrinterBrand limit 1"];
        
        while ([rsPrinterIP next]) {
            
            if ([[rsPrinterIP stringForColumn:@"PQ_PrinterBrand"] isEqualToString:@"XinYe"]) {
                GCDAsyncSocket *gcdArraySocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:mainQueue];
                NSMutableDictionary *data = [NSMutableDictionary dictionary];
                [data setObject:[rsPrinterIP stringForColumn:@"PQ_PrinterIP"] forKey:@"PQ_PrinterIP"];
                [data setObject:[rsPrinterIP stringForColumn:@"PQ_PrinterBrand"] forKey:@"PQ_PrinterBrand"];
                [data setObject:[rsPrinterIP stringForColumn:@"PQ_PrinterName"] forKey:@"PQ_PrinterName"];
                [data setObject:gcdArraySocket forKey:@"XinYe"];
                [printQueueArray addObject:data];
                data = nil;
            }
            else
            {
                NSMutableDictionary *data = [NSMutableDictionary dictionary];
                [data setObject:[rsPrinterIP stringForColumn:@"PQ_PrinterIP"] forKey:@"PQ_PrinterIP"];
                [data setObject:[rsPrinterIP stringForColumn:@"PQ_PrinterBrand"] forKey:@"PQ_PrinterBrand"];
                [data setObject:[rsPrinterIP stringForColumn:@"PQ_PrinterName"] forKey:@"PQ_PrinterName"];
                [data setObject:@"Nil" forKey:@"XinYe"];
                [printQueueArray addObject:data];
                data = nil;
            }
            
            
        }
        [rsPrinterIP close];
    }];
    [queue close];
    
    testPrinterIndex = 0;
    NSError *err = nil;
    
    for (int k = 0; k < xinYeConnectionArray.count; k++) {
        if ([[[xinYeConnectionArray objectAtIndex:k] objectForKey:@"Brand"] isEqualToString:@"XinYe"]) {
            [[[xinYeConnectionArray objectAtIndex:k] objectForKey:@"XinYe"] XYDisConnect];
            
        }
    }
    
    if (printQueueArray.count > 0) {
        if ([[[printQueueArray objectAtIndex:0] objectForKey:@"PQ_PrinterBrand"] isEqualToString:@"XinYe"])
        {
            xYPrinterIP = [[printQueueArray objectAtIndex:testPrinterIndex] objectForKey:@"PQ_PrinterIP"];
            xYPrinterName = [[printQueueArray objectAtIndex:testPrinterIndex] objectForKey:@"PQ_PrinterName"];
            [[[printQueueArray objectAtIndex:testPrinterIndex] objectForKey:@"XinYe"] connectToHost:[[printQueueArray objectAtIndex:testPrinterIndex] objectForKey:@"PQ_PrinterIP"] onPort:9100 withTimeout:1 error:&err];
        }
        else
        {
            [self arrayConnectToXinYePrinter2WithIpAddress:[[printQueueArray objectAtIndex:0] objectForKey:@"PQ_PrinterIP"] Brand:[[printQueueArray objectAtIndex:0] objectForKey:@"PQ_PrinterBrand"]];
        }
    }
    else
    {
        [[NSNotificationCenter defaultCenter]postNotificationName:@"FireBackAutoPrintDocumentWithNotification" object:nil userInfo:nil];
    }
    
}
    


-(void)arrayConnectToXinYePrinter2WithIpAddress:(NSString *)ip Brand:(NSString *)brand
{
    //NSMutableArray *printerIpArray = [[NSMutableArray alloc] init];
    //printerIpArray = [PublicSqliteMethod getAllItemPrinterIpAddWithDBPath:dbPath];
    
    for (int k = 0; k < xinYeConnectionArray.count; k++) {
        if ([[[xinYeConnectionArray objectAtIndex:k] objectForKey:@"Brand"] isEqualToString:@"XinYe"]) {
            [[[xinYeConnectionArray objectAtIndex:k] objectForKey:@"XinYe"] XYDisConnect];
            
        }
    }
    
    [xinYeConnectionArray removeAllObjects];
    
    for (int i = 0; i < printQueueArray.count; i++) {
        __block NSMutableDictionary *data = [NSMutableDictionary dictionary];
        if ([[[printQueueArray objectAtIndex:i] objectForKey:@"PQ_PrinterBrand"] isEqualToString:@"XinYe"]) {
            XYWIFIManager *xinYeWifi = [[XYWIFIManager alloc] init];
            //xinYeWifi.delegate = self;
            [xinYeWifi XYDisConnect];
            
            [xinYeWifi XYConnectWithHost:[[printQueueArray objectAtIndex:i] objectForKey:@"PQ_PrinterIP"] port:9100 completion:^(BOOL isConnect) {
                if (isConnect) {
                    [data setObject:[[printQueueArray objectAtIndex:i] objectForKey:@"PQ_PrinterIP"] forKey:@"IpAdd"];
                    [data setObject:[[printQueueArray objectAtIndex:i] objectForKey:@"PQ_PrinterBrand"] forKey:@"Brand"];
                    [data setObject:xinYeWifi forKey:@"XinYe"];
                    
                }
                [xinYeConnectionArray addObject:data];
                data = nil;
            }];
            xinYeWifi = nil;
        }
        else
        {
            [data setObject:[[printQueueArray objectAtIndex:i] objectForKey:@"PQ_PrinterIP"] forKey:@"IpAdd"];
            [data setObject:[[printQueueArray objectAtIndex:i] objectForKey:@"PQ_PrinterBrand"] forKey:@"Brand"];
            [data setObject:@"Nil" forKey:@"XinYe"];
            [xinYeConnectionArray addObject:data];
        }
        
    }
    
}


@end
