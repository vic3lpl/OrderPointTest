//
//  MultiSOViewController.m
//  IpadOrder
//
//  Created by IRS on 8/28/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "MultiSOViewController.h"
#import <FMDB.h>
#import "LibraryAPI.h"
#import "AppDelegate.h"
@interface MultiSOViewController ()
{
    FMDatabase *dbTable;
    NSString *dbPath;
    NSMutableArray *SOArray;
    NSString *tbName;
    NSString *terminalType;
    AppDelegate *appDelegate;
    MCPeerID *specificPeer;
    NSMutableArray *requestServerData;
}
-(void)getMultipleSalesOrderWithNotification:(NSNotification *)notification;
@end

@implementation MultiSOViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(getMultipleSalesOrderWithNotification:)
                                                 name:@"GetMultipleSalesOrderWithNotification"
                                               object:nil];
    
    self.preferredContentSize = CGSizeMake(270, 331);
    dbPath = [[LibraryAPI sharedInstance]getDbPath];
    terminalType = [[LibraryAPI sharedInstance]getWorkMode];
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    requestServerData = [[NSMutableArray alloc] init];
    SOArray = [[NSMutableArray alloc]init];
    self.soTableView.delegate = self;
    self.soTableView.dataSource = self;
    
    
    if ([terminalType isEqualToString:@"Main"]) {
        [self getAllSO];
    }
    else
    {
        [self requestMultipleSalesOrder];
    }
    
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - sqlite
-(void)getAllSO
{
    dbTable = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTable open]) {
        NSLog(@"Failt To Open DB");
        return;
    }
    
    FMResultSet *rs = [dbTable executeQuery:@"Select * from SalesOrderHdr s1 left join TablePlan tp on"
                       " s1.SOH_Table = tp.TP_Name where s1.SOH_Table = ? and s1.SOH_Status = ?",_tbSelecName,@"New"];
    while ([rs next]) {
        tbName = [rs stringForColumn:@"TP_Name"];
        [SOArray addObject:[rs resultDictionary]];
    }
    [rs close];
    [dbTable close];
    
    [self.soTableView reloadData];
}


#pragma mark - tableview

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    // Return the number of rows in the section.
    return SOArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *Identifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:Identifier];
    if (cell == nil) {
        //        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:Identifier] autorelease];
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:Identifier];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"Amount : %0.2f",[[[SOArray objectAtIndex:indexPath.row]objectForKey:@"SOH_DocAmt"]doubleValue]];
    
    cell.textLabel.text = [[SOArray objectAtIndex:indexPath.row]objectForKey:@"SOH_DocNo"];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Amount : %0.2f",[[[SOArray objectAtIndex:indexPath.row]objectForKey:@"SOH_DocAmt"]doubleValue]];
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_delegate != nil) {
        
        [_delegate passBackMultiSelectedSONo:[[SOArray objectAtIndex:indexPath.row] objectForKey:@"SOH_DocNo"] TableName:[[SOArray objectAtIndex:indexPath.row] objectForKey:@"TP_Name"] TableNo:[[[SOArray objectAtIndex:indexPath.row] objectForKey:@"TP_ID"] integerValue] PaxNo:[[SOArray objectAtIndex:indexPath.row] objectForKey:@"SOH_PaxNo"]];
        //[self dismissViewControllerAnimated:YES completion:nil];
        //[self dismissViewControllerAnimated:YES completion:nil];
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 54;
    //return 360;
}

#pragma mark - notification from server

-(void)getMultipleSalesOrderWithNotification:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray *soDTL;
        soDTL = [notification object];
        
        [SOArray addObjectsFromArray:soDTL];
        tbName = _tbSelecName;
        [self.soTableView reloadData];
    });

}

#pragma mark - multipeer data transfer
-(void)requestMultipleSalesOrder
{
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [requestServerData removeAllObjects];
    [data setObject:@"Request" forKey:@"Result"];
    [data setObject:@"-" forKey:@"Message"];
    [data setObject:@"RequestMultipleSO" forKey:@"IM_Flag"];
    //[data setObject:self.soO.text forKey:@"SO_DocNo"];
    [data setObject:_tbSelecName forKey:@"TP_Name"];
    //[data setObject:[NSString stringWithFormat:@"%d",compEnableGst] forKey:@"CompEnableGst"];
    
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)btnNewOrder:(id)sender {
    if (_delegate != nil) {
        
        //[_delegate passBackMultiSelectedSONo:@"-" TableName:tbName TableNo:_tbSelectNo];
        //[self dismissViewControllerAnimated:YES completion:nil];
        //[self dismissViewControllerAnimated:YES completion:nil];
    }
}
@end
