//
//  TransferTableFromViewController.m
//  IpadOrder
//
//  Created by IRS on 09/05/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import "TransferTableFromViewController.h"
#import "LibraryAPI.h"
#import <FMDB.h>
#import "TransferTableToViewController.h"
#import "TransferTableToTableViewCell.h"
#import "AppDelegate.h"

@interface TransferTableFromViewController ()
{
    FMDatabase *dbTable;
    NSString *dbPath;
    NSMutableArray *tableSOArray;
    //int tableID;
    NSString *terminalType;
    MCPeerID *specificPeer;
    NSMutableArray *requestServerData;
}
@property (nonatomic, strong) AppDelegate *appDelegate;
-(void)getTransferMultipleSalesOrderWithNotification:(NSNotification *)notification;
@end

@implementation TransferTableFromViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.preferredContentSize = CGSizeMake(480, 500);
    
    
    if([_transferFromSelectOption isEqualToString:@"TransferTable"])
    {
        self.title = @"Transfer Table";
    }
    else if ([_transferFromSelectOption isEqualToString:@"ShareTable"])
    {
        self.title = @"Share Table";
    }
    else if ([_transferFromSelectOption isEqualToString:@"CombineTable"])
    {
        self.title = @"Combine Table";
    }
    
    terminalType = [[LibraryAPI sharedInstance]getWorkMode];
    UINib *nib = [UINib nibWithNibName:@"TransferTableToTableViewCell" bundle:nil];
    [[self tableViewSOToTransfer]registerNib:nib forCellReuseIdentifier:@"TransferTableToTableViewCell"];
    
    UIBarButtonItem *newBackButton =
    [[UIBarButtonItem alloc] initWithTitle:@"Close"
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(closeTrandferTableFromView:)];
    self.navigationItem.leftBarButtonItem = newBackButton;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(getTransferMultipleSalesOrderWithNotification:)
                                                 name:@"GetTransferMultipleSalesOrderWithNotification"
                                               object:nil];
    
    tableSOArray = [[NSMutableArray alloc] init];
    dbPath = [[LibraryAPI sharedInstance] getDbPath];
    //tableID = [[LibraryAPI sharedInstance] getTableNo];
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.tableViewSOToTransfer.delegate = self;
    self.tableViewSOToTransfer.dataSource = self;
    requestServerData = [[NSMutableArray alloc] init];
    
    self.tableViewSOToTransfer.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    
}

-(void)viewWillAppear:(BOOL)animated
{
    if ([terminalType isEqualToString:@"Main"]) {
        [self getTransferSO];
    }
    else
    {
        [self requestTransferMultipleSalesOrderFromServer];
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - sqlite part
-(void)getTransferSO
{
    [tableSOArray removeAllObjects];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rsSO = [db executeQuery:@"Select SOH_Table, SOH_DocAmt,SOH_DocNo, TP_DineType, TP_Section from SalesOrderHdr SOH left join TablePlan TP on SOH.SOH_Table = TP.TP_Name where SOH_Status = ? and SOH_Table = ?",@"New",_selectedMultiTbName];
        
        while ([rsSO next]) {
            [tableSOArray addObject:[rsSO resultDictionary]];
        }
        
        [rsSO close];
        
    }];
    
    [queue close];
    
    if (tableSOArray.count == 0) {
        [self closeTrandferTableFromView:@"noNeed"];
    }
    
    [self.tableViewSOToTransfer reloadData];
    
}

#pragma mark - tableview 

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return tableSOArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //static NSString *Identifier = @"PaymentTypeTableViewCell";
    
    TransferTableToTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TransferTableToTableViewCell"];
    
    cell.labelTransfer1.text = [[tableSOArray objectAtIndex:indexPath.row] objectForKey:@"SOH_DocNo"];
    cell.labelTransfer2.text = [NSString stringWithFormat:@"%@ %0.2f",[[LibraryAPI sharedInstance] getCurrencySymbol],[[[tableSOArray objectAtIndex:indexPath.row] objectForKey:@"SOH_DocAmt"] doubleValue]];
    cell.labelTransferSection.text = [[tableSOArray objectAtIndex:indexPath.row]objectForKey:@"TP_Section"];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    /*
    TransferTableToViewController *transferTableToViewController = [[TransferTableToViewController alloc] init];
    transferTableToViewController.fromDocNo = [[tableSOArray objectAtIndex:indexPath.row] objectForKey:@"SOH_DocNo"];
    transferTableToViewController.fromTableName = [[tableSOArray objectAtIndex:indexPath.row] objectForKey:@"SOH_Table"];
    transferTableToViewController.selectedOption = _transferFromSelectOption;
    transferTableToViewController.transferType = @"InDirect";
    transferTableToViewController.fromTableDineType = [NSString stringWithFormat:@"%ld",[[[tableSOArray objectAtIndex:indexPath.row] objectForKey:@"TP_DineType"] integerValue]];
    [self.navigationController pushViewController:transferTableToViewController animated:YES];
    */
    if (_delegate != nil) {
        [_delegate selectTableAtSelectTableViewWithFromDocNo:[[tableSOArray objectAtIndex:indexPath.row] objectForKey:@"SOH_DocNo"] FromTableName:[[tableSOArray objectAtIndex:indexPath.row] objectForKey:@"SOH_Table"] SelectedOption:_transferFromSelectOption TransferType:@"InDirect" FromTableDineType:[NSString stringWithFormat:@"%ld",[[[tableSOArray objectAtIndex:indexPath.row] objectForKey:@"TP_DineType"] integerValue]]];
    }
    
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
    //return 360;
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

#pragma mark - button action
- (IBAction)closeTrandferTableFromView:(id)sender {
    if (_delegate != nil) {
        [_delegate askSelectedTableViewRefreshTablePlan];
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
    
}

#pragma mark - multipeer multi SalesOrder
-(void)requestTransferMultipleSalesOrderFromServer
{
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [requestServerData removeAllObjects];
    [data setObject:@"Request" forKey:@"Result"];
    [data setObject:@"-" forKey:@"Message"];
    [data setObject:@"RequestTransferMultipleSO" forKey:@"IM_Flag"];
    [data setObject:_selectedMultiTbName forKey:@"TP_Name"];
    
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

-(void)getTransferMultipleSalesOrderWithNotification:(NSNotification *)notification
{
    
    tableSOArray = [notification object];
    
    if ([[[tableSOArray objectAtIndex:0] objectForKey:@"Result"] isEqualToString:@"True"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableViewSOToTransfer reloadData];
        });
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self closeTrandferTableFromView:@"noNeed"];
        });
       
    }
    
}

@end
