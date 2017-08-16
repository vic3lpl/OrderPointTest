//
//  OptionSelectTableViewController.m
//  IpadOrder
//
//  Created by IRS on 04/04/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import "OptionSelectTableViewController.h"
#import "PrinterFunctions.h"
#import "ePOS-Print.h"
#import "Result.h"
#import "MsgMaker.h"
#import "EposPrintFunction.h"
#import <FMDB.h>
#import "LibraryAPI.h"
#import "AdminViewController.h"

@interface OptionSelectTableViewController ()
{
    NSString *portName;
    FMDatabase *dbTable;
    NSString *dbPath;
}
@end

@implementation OptionSelectTableViewController


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
    dbPath = [[LibraryAPI sharedInstance] getDbPath];
    [self wifiManager];
    if ([[[LibraryAPI sharedInstance] getOpenOptionViewName] isEqualToString:@"OrderingView"]) {
        self.preferredContentSize = CGSizeMake(200, 280);
        
    }
    else
    {
        self.preferredContentSize = CGSizeMake(200, 240);
    }
    
    [self.btnOpenDrawer.layer setCornerRadius:5.0];
    [self.btnOpenDrawer addTarget:self action:@selector(checkDefaultPrinter) forControlEvents:UIControlEventTouchUpInside];
    [self.btnFindBill addTarget:self action:@selector(openFindBillViewAtSelectTableView) forControlEvents:UIControlEventTouchUpInside];
    [self.btnUnlockDock addTarget:self action:@selector(releaseTheDock) forControlEvents:UIControlEventTouchUpInside];
    [self.btnEditBill addTarget:self action:@selector(callOutEditBillListView) forControlEvents:UIControlEventTouchUpInside];
    [self.btnOptionMore addTarget:self action:@selector(orderingGoToMore) forControlEvents:UIControlEventTouchUpInside];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)openDrawerThroughStarPrinter
{
    [PrinterFunctions OpenCashDrawerWithPortname:portName portSettings:@"Standard" drawerNumber:1];
}

-(void)openDrawerThroughStepPrinter
{
    Result *result = nil;
    EposBuilder *builder = nil;
    
    result = [[Result alloc] init];
    
    builder = [EposPrintFunction stepOpenCashDrawer];
    
    if(result.errType == RESULT_ERR_NONE) {
       [EposPrintFunction print:builder
                          Result:result PortName:portName];
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

#pragma mark - check Printer

-(void)checkDefaultPrinter
{
    
    dbTable = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTable open]) {
        NSLog(@"Failt To Open DB");
        return;
    }
    
    FMResultSet *rs = [dbTable executeQuery:@"Select * from Printer where P_Type = ?",@"Receipt"];
    
    if ([rs next]) {
        portName = [rs stringForColumn:@"P_PortName"];
        if ([[rs stringForColumn:@"P_Brand"] isEqualToString:@"Star"]) {
            [self openDrawerThroughStarPrinter];
        }
        else if([[rs stringForColumn:@"P_Brand"] isEqualToString:@"Asterix"])
        {
            [self openDrawerThroughStepPrinter];
        }
        else if ([[rs stringForColumn:@"P_Brand"] isEqualToString:@"FlyTech"])
        {
            [PosApi openCashBox];
        }
        else if ([[rs stringForColumn:@"P_Brand"] isEqualToString:@"XinYe"])
        {
            [self openXinYePrinterCashDrawerWithIpAdd:[rs stringForColumn:@"P_PortName"]];
        }
    }
    else
    {
        [self showAlertView:@"Cannot find printer" title:@"Warning"];
    }
    
    [rs close];
    [dbTable close];
    
    
}

-(void)openXinYePrinterCashDrawerWithIpAdd:(NSString *)ipAdd
{
    [self.wifiManager XYDisConnect];
    [_wifiManager XYConnectWithHost:ipAdd port:9100 completion:^(BOOL isConnect) {
        if (isConnect) {
            NSMutableData* dataM=[NSMutableData dataWithData:[PosCommand initializePrinter]];
            [dataM appendData:[PosCommand  openCashBoxRealTimeWithM:0 andT:1]];
            [self.wifiManager XYWriteCommandWithData:dataM];
        }
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self.wifiManager XYDisConnect];
    });
}

-(void)openFindBillViewAtSelectTableView
{
    if (_delegate != nil) {
        if ([[[LibraryAPI sharedInstance] getOpenOptionViewName] isEqualToString:@"SelectTableView"]) {
            [_delegate selectTableFindBillView];
        }
        else if ([[[LibraryAPI sharedInstance] getOpenOptionViewName] isEqualToString:@"OrderingView"])
        {
            [_delegate kioskFindBillView];
        }
        
    }
}

-(void)releaseTheDock
{
    if (AppUtility.isConnect == YES) {
        if ([PosApi undock:10]) {
            [self showAlertView:@"iPad unlock now" title:@"Information"];
        }else
        {
            [self showAlertView:@"Please try again" title:@"Information"];
        }
    }
    
}

-(void)callOutEditBillListView
{
    if ([[LibraryAPI sharedInstance]getUserRole] == 0) {
        [self showAlertView:@"You have no permission to edit bill" title:@"Warning"];
        return;
    }
    
    if (_delegate != nil) {
        if ([[[LibraryAPI sharedInstance] getOpenOptionViewName] isEqualToString:@"SelectTableView"]) {
            [_delegate selectTableEditedBillView];
        }
        else if ([[[LibraryAPI sharedInstance] getOpenOptionViewName] isEqualToString:@"OrderingView"])
        {
            
            [_delegate kioskEditBillView];
        }
        
    }
}

-(void)orderingGoToMore
{
    if (_delegate != nil) {
        [_delegate kiosOpenMoreView];
        
    }
}

#pragma mark alert view
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


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
