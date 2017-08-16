//
//  LinkToAccSettingViewController.m
//  IpadOrder
//
//  Created by IRS on 17/10/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import "LinkToAccSettingViewController.h"
#import "LibraryAPI.h"
#import <FMDB.h>
#import "AccPaymentTypeCodeTableViewCell.h"

@interface LinkToAccSettingViewController ()
{
    FMDatabase *dbLinkAcc;
    NSString *dbPath;
    NSMutableArray *paymentTypeArray;
    NSString *flag;
}
@end

@implementation LinkToAccSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    dbPath = [[LibraryAPI sharedInstance]getDbPath];
    paymentTypeArray = [[NSMutableArray alloc] init];
    
    self.tablePaymentType.delegate = self;
    self.tablePaymentType.dataSource = self;
    
    [self setTitle:@"Link IRS BizSuite Setting"];
    
    //dbPath = [[LibraryAPI sharedInstance]getDbPath];
    
    UIBarButtonItem *addBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(linkAccountSetting:)];
    self.navigationItem.rightBarButtonItem = addBtn;
    
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.translucent = NO;
    
    UINib *finalNib = [UINib nibWithNibName:@"AccPaymentTypeCodeTableViewCell" bundle:nil];
    [[self tablePaymentType]registerNib:finalNib forCellReuseIdentifier:@"AccPaymentTypeCodeTableViewCell"];
    
    [self getLinkToAccountSetting];
    [self getPaymentType];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - get Payment Type

-(void)getPaymentType
{
    [paymentTypeArray removeAllObjects];
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"Select PT_ID, PT_Code, PT_Description, PT_Type, PT_Checked, ifnull(PT_AccCode,'') as PT_AccCode from PaymentType"];
        
        while ([rs next]) {
            
            [paymentTypeArray addObject:[rs resultDictionary]];
            
        }
        [rs close];
        
    }];
    
    [queue close];
    
    [self.tablePaymentType reloadData];
}

-(void)linkAccountSetting:(id)sender
{
    
    if (![[[LibraryAPI sharedInstance] getWorkMode] isEqualToString:@"Main"]) {
        [self showAlertView:@"Terminal cannot edit data" title:@"Warning"];
        return;
    }
    
    if ([[LibraryAPI sharedInstance]getUserRole] == 0) {
        [self showAlertView:@"You have no permission to edit data" title:@"Warning"];
        return;
    }
    
    if ([self.textAccClientID.text length] == 0 || [self.textAccClientID.text isEqualToString:@""])
    {
        [self showAlertView:@"Client id cannot empty" title:@"Warning"];
        return;
    }
    else if ([self.textAccUserID.text length] == 0 || [self.textAccUserID.text isEqualToString:@""])
    {
        [self showAlertView:@"Account user id cannot empty" title:@"Warning"];
        return;
    }
    else if ([self.textAccUserPassword.text length] == 0 || [self.textAccUserPassword.text isEqualToString:@""])
    {
        [self showAlertView:@"Account user password cannot empty" title:@"Warning"];
        return;
    }
    else if ([self.textAccCompanyName.text length] == 0 || [self.textAccCompanyName.text isEqualToString:@""])
    {
        [self showAlertView:@"Account company name cannot empty" title:@"Warning"];
        return;
    }
    else if ([self.textAccURL.text length] == 0 || [self.textAccURL.text isEqualToString:@""])
    {
        [self showAlertView:@"Account url cannot empty" title:@"Warning"];
        return;
    }
    else if ([self.textCSAcc.text length] == 0 || [self.textCSAcc.text isEqualToString:@""])
    {
        [self showAlertView:@"Cash sales account cannot empty" title:@"Warning"];
        return;
    }
    else if ([self.textCSRAcc.text length] == 0 || [self.textCSRAcc.text isEqualToString:@""])
    {
        [self showAlertView:@"Cash sales rounding cannot empty" title:@"Warning"];
        return;
    }
    else if ([self.textCSDesc.text length] == 0 || [self.textCSDesc.text isEqualToString:@""])
    {
        [self showAlertView:@"Cash sales description cannot empty" title:@"Warning"];
        return;
    }
    
    if ([flag isEqualToString:@"New"]) {
        [self addSaveAccountSetting];
    }
    else if ([flag isEqualToString:@"Edit"])
    {
        [self editLinkToAccountSetting];
    }

}

-(void)addSaveAccountSetting
{
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        if ([[[LibraryAPI sharedInstance] getWorkMode] isEqualToString:@"Main"]) {
            
            if (![db open]) {
                NSLog(@"Fail To Open");
                return;
            }
            
            [db executeUpdate:@"Insert into LinkAccount (LA_ClientID"
             @", LA_AccUserID, LA_AccPassword, LA_Company"
             @", LA_CashSalesAC, LA_CashSalesRoundingAC"
             @", LA_ServiceChargeAC, LA_CashSalesDesc"
             @", LA_AccUrl, LA_CustomerAC) values (?,?,?,?,?,?,?,?,?,?)"
             ,self.textAccClientID.text
             ,self.textAccUserID.text
             ,self.textAccUserPassword.text
             ,self.textAccCompanyName.text
             ,self.textCSAcc.text
             ,self.textCSRAcc.text
             ,self.textSCAcc.text
             ,self.textCSDesc.text
             ,self.textAccURL.text
             ,self.textCustomerAcc.text
             ];
            
            if (![db hadError])
            {
                for (int i = 0; i < paymentTypeArray.count; i++) {
                    UITextField *textAccCode = (UITextField *)[self.tablePaymentType viewWithTag:i + 21];
                    
                    UILabel *label = (UILabel *)[self.tablePaymentType viewWithTag:i+61];
                    
                    
                    [db executeUpdate:@"Update PaymentType set PT_AccCode = ? where PT_Code = ?",
                     textAccCode.text,label.text];
                    
                    if ([db hadError]) {
                        //[self showAlertView:[db lastErrorMessage] title:@"Fail"];
                        *rollback = YES;
                        break;
                    }
                    else
                    {
                        //[self showAlertView:@"Data added" title:@"Information"];
                        flag = @"Edit";
                    }
                    
                    
                    
                    textAccCode = nil;
                    label = nil;
                    
                }
                
            }
            else
            {
                [self showAlertView:[db lastErrorMessage] title:@"Fail"];
                *rollback = YES;
            }
            
            if ([db hadError]) {
                [self showAlertView:[db lastErrorMessage] title:@"Fail"];
            }
            else
            {
                [self showAlertView:@"Data saved" title:@"Information"];
            }
            
            
            
        }
        else
        {
            [self showAlertView:@"Terminal cannot edit data" title:@"Warning"];
            
        }
        
    }];
    [queue close];
    //[self getPaymentType];
    
}

-(void)editLinkToAccountSetting
{
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        if ([[[LibraryAPI sharedInstance] getWorkMode] isEqualToString:@"Main"]) {
            
            if (![db open]) {
                NSLog(@"Fail To Open");
                return;
            }
            
            [db executeUpdate:@"Update LinkAccount set LA_ClientID = ?"
             @", LA_AccUserID = ?, LA_AccPassword = ?, LA_Company = ?"
             @", LA_CashSalesAC = ?, LA_CashSalesRoundingAC = ?"
             @", LA_ServiceChargeAC = ?, LA_CashSalesDesc = ?"
             @", LA_AccUrl = ?, LA_CustomerAC = ?"
             ,self.textAccClientID.text
             ,self.textAccUserID.text
             ,self.textAccUserPassword.text
             ,self.textAccCompanyName.text
             ,self.textCSAcc.text
             ,self.textCSRAcc.text
             ,self.textSCAcc.text
             ,self.textCSDesc.text
             ,self.textAccURL.text
             ,self.textCustomerAcc.text
             ];
            
            if (![db hadError])
            {
                for (int i = 0; i < paymentTypeArray.count; i++) {
                    UITextField *textAccCode = (UITextField *)[self.tablePaymentType viewWithTag:i + 21];
                    
                    UILabel *label = (UILabel *)[self.tablePaymentType viewWithTag:i+61];
                    
                    [db executeUpdate:@"Update PaymentType set PT_AccCode = ? where PT_Code = ?",
                     textAccCode.text,label.text];
                    
                    if ([db hadError]) {
                        //[self showAlertView:[db lastErrorMessage] title:@"Fail"];
                        //NSLog(@"%@",[db lastErrorMessage]);
                        *rollback = YES;
                        break;
                    }
                    else
                    {
                        //[self showAlertView:@"Data updated" title:@"Information"];
                        //flag = @"Edit";
                    }
                    
                    
                    textAccCode = nil;
                    label = nil;
                    
                    
                }
                
                if ([db hadError]) {
                    [self showAlertView:[db lastErrorMessage] title:@"Fail"];
                }
                else
                {
                    [self showAlertView:@"Data updated" title:@"Information"];
                }
                
                //[self showAlertView:@"Data updated" title:@"Information"];
                
            }
            else
            {
                [self showAlertView:[db lastErrorMessage] title:@"Fail"];
                *rollback = YES;
            }
            
            
        }
        else
        {
            [self showAlertView:@"Terminal cannot edit data" title:@"Warning"];
            
        }
        
    }];
    [queue close];
    //[self getPaymentType];
    
}


-(void)getLinkToAccountSetting
{
    [paymentTypeArray removeAllObjects];
    
    FMDatabase *db = [FMDatabase databaseWithPath:dbPath];
    
    if (![db open]) {
        NSLog(@"Fail To Open");
        return;
    }
    
    [[LibraryAPI sharedInstance]setDbPath:dbPath];
    
    FMResultSet *rs = [db executeQuery:@"select * from LinkAccount"];
    
    if ([rs next])
    {
        flag = @"Edit";
        self.textAccClientID.text = [rs stringForColumn:@"LA_ClientID"];
        self.textAccUserID.text = [rs stringForColumn:@"LA_AccUserID"];
        self.textAccUserPassword.text = [rs stringForColumn:@"LA_AccPassword"];
        self.textAccCompanyName.text = [rs stringForColumn:@"LA_Company"];
        self.textAccURL.text = [rs stringForColumn:@"LA_AccUrl"];
        self.textCSAcc.text = [rs stringForColumn:@"LA_CashSalesAC"];
        
        self.textCSDesc.text = [rs stringForColumn:@"LA_CashSalesDesc"];
        self.textCSAcc.text = [rs stringForColumn:@"LA_CashSalesAC"];
        self.textCSRAcc.text = [rs stringForColumn:@"LA_CashSalesRoundingAC"];
        self.textSCAcc.text = [rs stringForColumn:@"LA_ServiceChargeAC"];
        self.textCustomerAcc.text = [rs stringForColumn:@"LA_CustomerAC"];
        
    }
    else
    {
        flag = @"New";
    }
    
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
    }
    
    [rs close];
    [db close];
}

#pragma mark - tableview
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return paymentTypeArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"AccPaymentTypeCodeTableViewCell";
    
    AccPaymentTypeCodeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    cell.textPaymentTypeAccCode.text = [[paymentTypeArray objectAtIndex:indexPath.row] objectForKey:@"PT_AccCode"];
    cell.labelPaymentType.text = [[paymentTypeArray objectAtIndex:indexPath.row] objectForKey:@"PT_Code"];
    
    cell.textPaymentTypeAccCode.tag = indexPath.row + 21;
    //cell.btnUpdateAccCode.tag = indexPath.row;
    //cell.btnDeleteAccCode.tag = indexPath.row + 41;
    cell.labelPaymentType.tag = indexPath.row + 61;
    
    //[cell.btnUpdateAccCode addTarget:self action:@selector(updatePaymentTypeAccCode:) forControlEvents:UIControlEventTouchUpInside];
    
    //[cell.btnDeleteAccCode addTarget:self action:@selector(deletePaymentTypeAccCode:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}


#pragma mark - selector
/*
-(void)updatePaymentTypeAccCode:(id)sender
{
    
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tablePaymentType];
    NSIndexPath *indexPath = [self.tablePaymentType indexPathForRowAtPoint:buttonPosition];
    
    UITextField *textAccCode = (UITextField *)[self.tablePaymentType viewWithTag:indexPath.row + 21];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        [db executeUpdate:@"Update PaymentType set PT_AccCode = ? where PT_Code = ?",
         textAccCode.text,[[paymentTypeArray objectAtIndex:indexPath.row] objectForKey:@"PT_Code"]];
        
        if (![db hadError]) {
            //[self showAlertView:@"Data updated" title:@"Success"];
        }
        
    }];
    textAccCode = nil;
    [queue close];

    [self getPaymentType];
    
}


-(void)deletePaymentTypeAccCode:(id)sender
{
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tablePaymentType];
    NSIndexPath *indexPath = [self.tablePaymentType indexPathForRowAtPoint:buttonPosition];
    
    //UITextField *paymentAccCode = (UITextField *)[self.tablePaymentType viewWithTag:indexPath.row + 21];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        [db executeUpdate:@"Update PaymentType set PT_AccCode = ? where PT_Code = ?",
         @"",[[paymentTypeArray objectAtIndex:indexPath.row] objectForKey:@"PT_Code"]];
        
        if (![db hadError]) {
            [self showAlertView:@"Data updated" title:@"Success"];
        }
        
    }];
    
    [queue close];
    
    [self getPaymentType];
}
*/
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
