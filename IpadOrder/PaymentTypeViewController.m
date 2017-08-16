//
//  PaymentTypeViewController.m
//  IpadOrder
//
//  Created by IRS on 11/5/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "PaymentTypeViewController.h"
#import "LibraryAPI.h"
#import <FMDB.h>
#import <MBProgressHUD.h>
#import "PaymentTypeTableViewCell.h"
#import "PaymentTypeEditViewController.h"

@interface PaymentTypeViewController ()
{
    FMDatabase *dbPaymentType;
    NSString *dbPath;
    NSMutableArray *paymentTypeArray;
    int ptChecked;
    NSString *terminalType;
    NSString *alertFlag;
}
@end

@implementation PaymentTypeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setTitle:@"Payment Mode"];
    paymentTypeArray = [[NSMutableArray alloc] init];
    dbPath = [[LibraryAPI sharedInstance]getDbPath];
    terminalType = [[LibraryAPI sharedInstance]getWorkMode];
    
    self.tableViewPaymentType.delegate = self;
    self.tableViewPaymentType.dataSource = self;
    
    UINib *cellNib = [UINib nibWithNibName:@"PaymentTypeTableViewCell" bundle:nil];
    [[self tableViewPaymentType]registerNib:cellNib forCellReuseIdentifier:@"PaymentTypeTableViewCell"];
    
    UIBarButtonItem *addBtn = [[UIBarButtonItem alloc]initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:self action:@selector(addPaymentType)];
    self.navigationItem.rightBarButtonItem = addBtn;
    
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    //self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:34/255.0 green:171/255.0 blue:241/255.0 alpha:1.0];
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.translucent = NO;
    
    self.tableViewPaymentType.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    
    // Do any additional setup after loading the view from its nib.
}

-(void)viewWillAppear:(BOOL)animated
{
    [self checkPaymentType];
}

-(void)viewDidLayoutSubviews
{
    if ([self.tableViewPaymentType respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableViewPaymentType setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([self.tableViewPaymentType respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.tableViewPaymentType setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)checkPaymentType
{
    dbPaymentType = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbPaymentType open]) {
        NSLog(@"Fail To Open");
        return;
    }
    
    [paymentTypeArray removeAllObjects];
    
    FMResultSet *rs = [dbPaymentType executeQuery:@"Select * from PaymentType order by PT_Code"];
    
    while ([rs next]) {
        //[paymentTypeArray addObject:[rs resultDictionary]];
        NSMutableDictionary *paymentDict = [NSMutableDictionary dictionary];
        
        [paymentDict setObject:[rs stringForColumn:@"PT_Code"] forKey:@"PT_Code"];
        [paymentDict setObject:[rs stringForColumn:@"PT_Description"] forKey:@"PT_Description"];
        //[paymentDict setObject:[rs stringForColumn:@"P_PrinterName"] forKey:@"P_Name"];
        [paymentDict setObject:[rs stringForColumn:@"PT_Checked"] forKey:@"PT_Checked"];
        
        [paymentTypeArray addObject:paymentDict];
        paymentDict = nil;
    }
    
    [rs close];
    [dbPaymentType close];
    [self.tableViewPaymentType reloadData];
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if ([[[paymentTypeArray objectAtIndex:indexPath.row] objectForKey:@"PT_Checked" ] integerValue] == 1) {
        //cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tick"]];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        //cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"untick"]];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    // Return the number of rows in the section.
    return [paymentTypeArray count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *Identifier = @"PaymentTypeTableViewCell";
    
    PaymentTypeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:Identifier];
    //if (cell == nil) {
        //        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:Identifier] autorelease];
      //  cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:Identifier];
    //}
    cell.labelPaymentTypeName.text = [[paymentTypeArray objectAtIndex:indexPath.row] objectForKey:@"PT_Code"];
    cell.labelPaymentTypeName.textColor = [UIColor colorWithRed:36/255.0 green:36/255.0 blue:36/255.0 alpha:1.0];
    
    if ([[[paymentTypeArray objectAtIndex:indexPath.row] objectForKey:@"PT_Checked" ] integerValue] == 1) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        //cell.imageTick.image = [UIImage imageNamed:@"tick"];
    }
    else
    {
        //cell.imageTick.image = [UIImage imageNamed:@"untick"];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PaymentTypeTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    /*
    if (cell.accessoryType == UITableViewCellAccessoryNone) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        
     
        NSMutableDictionary *paymentDict3 = [NSMutableDictionary dictionary];
        paymentDict3 = [paymentTypeArray objectAtIndex:indexPath.row];
        [paymentDict3 setValue:@"1" forKey:@"PT_Checked"];
        [paymentTypeArray replaceObjectAtIndex:indexPath.row withObject:paymentDict3];
        paymentDict3 = nil;
     
        
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
     
        NSMutableDictionary *paymentDict3 = [NSMutableDictionary dictionary];
        paymentDict3 = [paymentTypeArray objectAtIndex:indexPath.row];
        [paymentDict3 setValue:@"0" forKey:@"PT_Checked"];
        [paymentTypeArray replaceObjectAtIndex:indexPath.row withObject:paymentDict3];
        paymentDict3 = nil;
     
    }
    */
    
    if ([terminalType isEqualToString:@"Main"]) {
        PaymentTypeEditViewController *paymentTypeEditViewController = [[PaymentTypeEditViewController alloc] init];
        paymentTypeEditViewController.editPaymentTypeCode = [[paymentTypeArray objectAtIndex:indexPath.row] objectForKey:@"PT_Code"];
        paymentTypeEditViewController.editPaymentTypeAction = @"Edit";
        [self.navigationController pushViewController:paymentTypeEditViewController animated:NO];
        
        
    }
    else
    {
        [self showAlertView:@"Terminal cannot access" title:@"Warning"];
        
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [tableView reloadData];
    
}

/*
-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PaymentTypeTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    
    //cell.accessoryType = UITableViewCellAccessoryNone;
    cell.imageTick.image = [UIImage imageNamed:@"untick"];
    //[selectPrinterArray removeObject:indexPath];
    NSMutableDictionary *paymentDict3 = [NSMutableDictionary dictionary];
        
    paymentDict3 = [paymentTypeArray objectAtIndex:indexPath.row];
    [paymentDict3 setValue:@"0" forKey:@"PT_Checked"];
    [paymentTypeArray replaceObjectAtIndex:indexPath.row withObject:paymentDict3];
    paymentDict3 = nil;
    
}
*/

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        if ([terminalType isEqualToString:@"Main"]) {
            //alertFlag = @"Delete";
            
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"Warning"
                                         message:@"Sure To Delete ?"
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* yesButton = [UIAlertAction
                                        actionWithTitle:@"OK"
                                        style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * action) {
                                            [self checkPaymentTypeUsedWithPaymentCode:[[paymentTypeArray objectAtIndex:indexPath.row] objectForKey:@"PT_Code"]];
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
            
        }
        else
        {
            [self showAlertView:@"Terminal cannot delete item" title:@"Warning"];
        }
        
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 54;
}

-(void)checkPaymentTypeUsedWithPaymentCode:(NSString *)ptCode
{
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        if ([ptCode isEqualToString:@"Cash"]) {
            [self showAlertView:@"Cash cannot delete" title:@"Information"];
            return;
        }
    
        FMResultSet *rs = [db executeQuery:@"Select * from InvoiceHdr where IvH_PaymentType1 = ? or IvH_PaymentType2 = ? or IvH_PaymentType3 = ? or IvH_PaymentType4 = ? or IvH_PaymentType5 = ? or IvH_PaymentType6 = ? or IvH_PaymentType7 = ? or IvH_PaymentType8 = ?",ptCode,ptCode,ptCode,ptCode,ptCode,ptCode,ptCode,ptCode];
        
        if ([rs next]) {
            [self showAlertView:@"Data used cannot delete" title:@"Information"];
        }
        else
        {
            [db executeUpdate:@"Delete from PaymentType where PT_Code = ?",ptCode];
        }
        [rs close];
        
    }];
    
    [queue close];
    
    [self checkPaymentType];
}

#pragma mark - sqlite3
-(void)addPaymentType
{
    if ([terminalType isEqualToString:@"Main"]) {
        PaymentTypeEditViewController *paymentTypeEditViewController = [[PaymentTypeEditViewController alloc] init];
        
        paymentTypeEditViewController.editPaymentTypeAction = @"New";
        [self.navigationController pushViewController:paymentTypeEditViewController animated:NO];
    }
    else
    {
        [self showAlertView:@"Terminal cannot add payment type" title:@"Warning"];
    }
    
}
/*
-(void)updatePaymentType
{
    if ([terminalType isEqualToString:@"Main"]) {
        
        if ([[LibraryAPI sharedInstance]getUserRole] == 0) {
            [self showAlertView:@"You have no permission to edit data" title:@"Warning"];
            return;
        }
        
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
        
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            for (int i = 0; i < paymentTypeArray.count; i++) {
                if ([[[paymentTypeArray objectAtIndex:i] objectForKey:@"PT_Checked"] isEqualToString:@"1"]) {
                    ptChecked = 1;
                }
                else
                {
                    ptChecked = 0;
                }
                
                [db executeUpdate:@"Update PaymentType set PT_Checked = ? where PT_Code = ?",[NSNumber numberWithInt:ptChecked],[[paymentTypeArray objectAtIndex:i] objectForKey:@"PT_Code"]];
                
                if ([db hadError]) {
                    [self showAlertView:[db lastErrorMessage] title:@"Error"];
                    *rollback = YES;
                    return;
                }
                else
                {
                    
                }
                
            }
        }];
        
        [queue close];
        [self showAlertView:@"Data updated" title:@"Success"];
    }
    else
    {
        //[self showMyHudMessageBoxWithMessage:@"Terminal Cannot Edit Payment Type"];
        [self showAlertView:@"Terminal cannot edit payment type" title:@"Warning"];
    }
    

}
 */

#pragma mark - alertView

-(void)showAlertView:(NSString *)msg title:(NSString *)title
{
    alertFlag = @"Alert";
    
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

#pragma mark - show hub message box

-(void)showMyHudMessageBoxWithMessage:(NSString *)message
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.margin = 30.0f;
    hud.yOffset = 200.0f;
    
    hud.labelText = message;
    
    hud.removeFromSuperViewOnHide = YES;
    
    [hud hide:YES afterDelay:0.6];
    
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
