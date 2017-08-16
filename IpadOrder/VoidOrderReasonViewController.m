//
//  VoidOrderReasonViewController.m
//  IpadOrder
//
//  Created by IRS on 03/05/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import "VoidOrderReasonViewController.h"
#import "LibraryAPI.h"
#import <FMDB.h>

@interface VoidOrderReasonViewController ()
{
    NSString *dbPath;
    FMDatabase *dbTable;
    NSString *voidSONo;
    NSString *dateString;
    NSMutableArray *kitchenReceiptArray;
}
@end

@implementation VoidOrderReasonViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.preferredContentSize = CGSizeMake(411, 261);
    
    dbPath = [[LibraryAPI sharedInstance] getDbPath];
    voidSONo = [[LibraryAPI sharedInstance] getDocNo];
    kitchenReceiptArray = [[NSMutableArray alloc] init];
    
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormat = [[LibraryAPI sharedInstance] getDateFormaterhhmmss];
    dateString = [dateFormat stringFromDate:today];
    
    [self.textUsername becomeFirstResponder];
    
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

#pragma mark - show alert
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

- (IBAction)btnCancelVoidOrder:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}

- (IBAction)btnVoidOrder:(id)sender {
    if ([self.textAdminPassword.text length] == 0) {
        [self showAlertView:@"Admin password cannot empty" title:@"Warning"];
        return;
    }
    else if ([self.textVoidReason.text length] == 0)
    {
        [self showAlertView:@"Enter void reason" title:@"Warning"];
        return;
    }
    
    __block BOOL flag;
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rsPassword = [db executeQuery:@"Select * from UserLogin where UL_Password = ? and UL_ID = ?",self.textAdminPassword.text,self.textUsername.text];
        
        if (![rsPassword next]) {
            flag = false;
            [self showAlertView:@"Invalid username / password" title:@"Warning"];
            [rsPassword close];
            return;
        }
        else
        {
            if ([rsPassword intForColumn:@"UL_Role"] == 0) {
                flag = false;
                [self showAlertView:@"You have no permission" title:@"Warning"];
                [rsPassword close];
                return;
            }
            else
            {
                [rsPassword close];
            }
            
        }
        
        [db executeUpdate:@"Update SalesOrderHdr set SOH_Reason = ?,SOH_Status = ?, SOH_VoidDate = ? where SOH_DocNo = ?",self.textVoidReason.text,@"Void",dateString,voidSONo];
        
        if ([db hadError]) {
            flag = false;
            [self showAlertView:[db lastErrorMessage] title:@"Warning"];
            [rsPassword close];
            return;
        }
        else
        {
            flag = true;
            
        }
        
    }];
    
    [queue close];
    
    if (flag) {
        [self askKitchenVoidOrder];
    }
    else
    {
        [self closeVoidOrderView];
    }
    
    
    
}

-(void)askKitchenVoidOrder
{
    
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"To Kitchen"
                                 message:@"Done. Send to kitchen ?"
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* yesButton = [UIAlertAction
                                actionWithTitle:@"OK"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
                                    
                                    [self makeKitchenReceiptDictionary];
                                    
                                }];
    
    UIAlertAction* noButton = [UIAlertAction
                               actionWithTitle:@"Cancel"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   [self closeVoidOrderView];
                               }];
    
    [alert addAction:yesButton];
    [alert addAction:noButton];
    
    [self presentViewController:alert animated:NO completion:nil];
    alert = nil;
    
    /*
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
     
        NSString *printerName;
        NSString *printerBrand;
        NSString *printerPort;
        NSString *printerMode;
        
        FMResultSet *rsPrinter = [db executeQuery:@"Select * from Printer where P_Type = ?",@"Kitchen"];
        
        if ([rsPrinter next]) {
            
            printerName = [rsPrinter stringForColumn:@"P_PrinterName"];
            printerMode = [rsPrinter stringForColumn:@"P_Mode"];
            printerPort = [rsPrinter stringForColumn:@"P_PortName"];
            printerBrand = [rsPrinter stringForColumn:@"P_Brand"];
            
            
            
        }
        else
        {
            [self closeVoidOrderView];
        }
        
        [rsPrinter close];
    }];
    
    [queue close];
     */
}

-(void)closeVoidOrderView
{
    kitchenReceiptArray = nil;
    [self dismissViewControllerAnimated:true completion:nil];
    if (_delegate != nil) {
        [_delegate dismissVoidOrderViewWithResult:@"False"];
    }
}

-(void)makeKitchenReceiptDictionary
{
    
    [self dismissViewControllerAnimated:true completion:nil];
    if (_delegate != nil) {
        [_delegate dismissVoidOrderViewWithResult:@"True"];
    }
    
    /*
    [kitchenReceiptArray removeAllObjects];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        
        NSString *uniID;
        
        if ([[[LibraryAPI sharedInstance] getWorkMode] isEqualToString:@"Main"])
        {
            uniID = @"Server";
        }
        else
        {
            uniID = [[LibraryAPI sharedInstance] getTerminalDeviceName];
        }
        
        FMResultSet *rsPrinter = [db executeQuery:@"select s1.SOD_ItemCode,s1.SOD_Quantity,s1.SOD_ItemDescription,IP_PrinterName, IP_PrinterPort, P_Brand, P_Mode"
                                  @" from SalesOrderDtl s1"
                                  @" inner join ItemPrinter i1 on s1.SOD_ItemCode = i1.IP_ItemNo"
                                  @" inner join Printer p1 on i1.IP_PrinterName = p1.P_PrinterName"
                                  @" where SOD_DocNo = ?  group by IP_PrinterPort, IP_PrinterName", voidSONo];
        
        while ([rsPrinter next]) {
            
            NSMutableDictionary *data = [NSMutableDictionary dictionary];
            [data setObject:[rsPrinter stringForColumn:@"SOD_ItemCode"] forKey:@"KR_ItemCode"];
            [data setObject:@"Print" forKey:@"KR_Status"];
            [data setObject:[NSString stringWithFormat:@"-%@",[rsPrinter stringForColumn:@"SOD_Quantity"]] forKey:@"KR_Qty"];
            [data setObject:[rsPrinter stringForColumn:@"SOD_ItemDescription"] forKey:@"KR_Desc"];
            [data setObject:@"RequestPrintKitchenReceipt" forKey:@"IM_Flag"];
            [data setObject:[rsPrinter stringForColumn:@"P_Brand"] forKey:@"KR_Brand"];
            [data setObject:[rsPrinter stringForColumn:@"IP_PrinterPort"] forKey:@"KR_IpAddress"];
            [data setObject:[rsPrinter stringForColumn:@"P_Mode"] forKey:@"KR_PrintMode"];
            [data setObject:_voidTableName forKey:@"KR_TableName"];
            [data setObject:@"Kitchen" forKey:@"KR_DocType"];
            [data setObject:@"Non" forKey:@"KR_DocNo"];
            [data setObject:[rsPrinter stringForColumn:@"IP_PrinterName"] forKey:@"KR_PrinterName"];
            
            [kitchenReceiptArray addObject:data];
     
            printerName = [rsPrinter stringForColumn:@"P_PrinterName"];
            printerMode = [rsPrinter stringForColumn:@"P_Mode"];
            printerPort = [rsPrinter stringForColumn:@"P_PortName"];
            printerBrand = [rsPrinter stringForColumn:@"P_Brand"];
     
            
        }
        
        [rsPrinter close];
    }];
    
    [queue close];
    
    
    [[NSNotificationCenter defaultCenter]postNotificationName:@"ServerCallConnectionArrayWithNotification" object:kitchenReceiptArray userInfo:nil];
    */
    
}




@end
