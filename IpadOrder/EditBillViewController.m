//
//  EditBillViewController.m
//  IpadOrder
//
//  Created by IRS on 30/08/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import "EditBillViewController.h"
#import "LibraryAPI.h"
#import <FMDB.h>
#import "BillListingTableViewCell.h"
#import "OrderingViewController.h"
#import "AppDelegate.h"

@interface EditBillViewController ()
{
    NSString *dbPath;
    FMDatabase *dbTable;
    NSMutableArray *billListArray;
    NSString *terminalType;
    MCPeerID *specificPeer;
    AppDelegate *appDelegate;
}

-(void)getCashSalesListingResultWithNotification:(NSNotification *)notification;
@end

@implementation EditBillViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(getCashSalesListingResultWithNotification:)
                                                 name:@"GetCashSalesListingResultWithNotification"
                                               object:nil];
    
    // Do any additional setup after loading the view from its nib.
     self.preferredContentSize = CGSizeMake(307, 494);
    
    dbPath = [[LibraryAPI sharedInstance] getDbPath];
    billListArray = [[NSMutableArray alloc] init];
    self.tableEditBillListing.delegate = self;
    self.tableEditBillListing.dataSource = self;
    self.searchBarEditBill.delegate = self;
    self.searchBarEditBill.placeholder = @"Document No";
    terminalType = [[LibraryAPI sharedInstance] getWorkMode];
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    UINib *nib = [UINib nibWithNibName:@"BillListingTableViewCell" bundle:nil];
    [self.tableEditBillListing registerNib:nib forCellReuseIdentifier:@"BillListingTableViewCell"];
    
    self.tableEditBillListing.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    
    if ([terminalType isEqualToString:@"Main"]) {
        [self getLimitedData];
    }
    else
    {
        [self requestServerSendInvoiceWithKeyWord:@"%"];
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - sqlite

-(void)getLimitedData
{
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        if ([[LibraryAPI sharedInstance] getEnableGst] == 1) {
            FMResultSet *rsServiceTaxGst = [db executeQuery:@"Select T_Percent from GeneralSetting gs inner join Tax t on gs.GS_ServiceGstCode = t.T_Name"
                                            " where gs.GS_ServiceTaxGst  = 1"];
            
            if ([rsServiceTaxGst next]) {
                [[LibraryAPI sharedInstance] setServiceTaxGstPercent:[rsServiceTaxGst doubleForColumn:@"T_Percent"]];
            }
            else
            {
                [[LibraryAPI sharedInstance] setServiceTaxGstPercent:0.00];
            }
            
            [rsServiceTaxGst close];
        }
        else
        {
            [[LibraryAPI sharedInstance] setServiceTaxGstPercent:0.00];
        }
        
        
        [billListArray removeAllObjects];
        FMResultSet *rs = [db executeQuery:@"select * from (Select IvH_DocNo,IvH_DocAmt, IvH_Date, IvH_Table, IvH_PaxNo, IvH_Status, (IvH_DocNo || IvH_Table) as FilterColumn from InvoiceHdr order by IvH_DocNo desc limit 100) Tb1 left join TablePlan TP on Tb1.IvH_Table = TP.TP_Name where Tb1.FilterColumn like ?", [NSString stringWithFormat:@"%@%@%@",@"%",self.searchBarEditBill.text,@"%"]];
        
        while ([rs next]) {
            [billListArray addObject:[rs resultDictionary]];
        }
        
        [rs close];
    }];
    
    //[dbTable close];
    
    [self.tableEditBillListing reloadData];
}

#pragma mark - multipeer connection
-(void)requestServerSendInvoiceWithKeyWord:(NSString *)keyWord
{
    NSMutableArray *requestServerData = [[NSMutableArray alloc] init];
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data setObject:@"Request" forKey:@"Result"];
    [data setObject:@"-" forKey:@"Message"];
    [data setObject:@"RequestEditBillWithKeyWord" forKey:@"IM_Flag"];
    [data setObject:keyWord forKey:@"KeyWord"];
    
    [requestServerData addObject:data];
    NSData *dataToBeSend = [NSKeyedArchiver archivedDataWithRootObject:requestServerData];
    NSArray *allPeers = [[appDelegate.mcManager session] connectedPeers];
    NSError *error;
    
    for (int i = 0; i < allPeers.count; i++) {
        specificPeer = [allPeers objectAtIndex:i];
        
        if ([specificPeer.displayName isEqualToString:@"Server"]) {
            NSArray *oneArray = @[[appDelegate.mcManager.session.connectedPeers objectAtIndex:i]];
            [appDelegate.mcManager.session sendData:dataToBeSend
                                             toPeers:oneArray
                                            withMode:MCSessionSendDataReliable
                                               error:&error];
        }
        
    }
    
    if (error) {
        NSLog(@"Erro : %@", [error localizedDescription]);
    }

}

-(void)getCashSalesListingResultWithNotification:(NSNotification *)notification
{
    [billListArray removeAllObjects];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSArray *serverFilterResult;
        serverFilterResult = [notification object];
        
        [billListArray addObjectsFromArray:serverFilterResult];
        serverFilterResult = nil;
        [self.tableEditBillListing reloadData];
    });
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
    
    return  cell;
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (_delegate != nil) {
        if ([[[LibraryAPI sharedInstance] getOpenOptionViewName] isEqualToString:@"SelectTableView"]) {
            [_delegate editBillOnOrderScreenWithTableName:[[billListArray objectAtIndex:0] objectForKey:@"IvH_Table"] TableNo:[[[billListArray objectAtIndex:indexPath.row] objectForKey:@"TP_ID"] integerValue] DineType:[[[billListArray objectAtIndex:0] objectForKey:@"TP_DineType"] stringValue] OverrideTableSVC:[[[billListArray objectAtIndex:0] objectForKey:@"TP_Overide"] stringValue] PaxNo:[[billListArray objectAtIndex:0] objectForKey:@"IvH_PaxNo"] CSDocNo:[[billListArray objectAtIndex:indexPath.row] objectForKey:@"IvH_DocNo"] TpServicePercent:[[billListArray objectAtIndex:indexPath.row] objectForKey:@"TP_Percent"]];
        }
        else if([[[LibraryAPI sharedInstance] getOpenOptionViewName] isEqualToString:@"OrderingView"])
        {
            [_delegate orderingEditBillOnOrderScreenWithTableName:[[billListArray objectAtIndex:0] objectForKey:@"IvH_Table"] TableNo:[[[billListArray objectAtIndex:indexPath.row] objectForKey:@"TP_ID"] integerValue] DineType:[[[billListArray objectAtIndex:0] objectForKey:@"TP_DineType"] stringValue] OverrideTableSVC:[[[billListArray objectAtIndex:0] objectForKey:@"TP_Overide"] stringValue] PaxNo:[[billListArray objectAtIndex:0] objectForKey:@"IvH_PaxNo"] CSDocNo:[[billListArray objectAtIndex:indexPath.row] objectForKey:@"IvH_DocNo"] TpServicePercent:[[billListArray objectAtIndex:indexPath.row] objectForKey:@"TP_Percent"]];
            
            
        }
        
        billListArray = nil;
    }
    
    //docNo = [[billListArray objectAtIndex:indexPath.row] objectForKey:@"IvH_DocNo"];
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
    self.searchBarEditBill.text = @"";
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
        [self requestServerSendInvoiceWithKeyWord:searchText];
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

- (IBAction)btnCancelEditBillSelected:(id)sender {
    billListArray = nil;
    [self dismissViewControllerAnimated:NO completion:nil];
}

@end
