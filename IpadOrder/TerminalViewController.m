//
//  TerminalViewController.m
//  IpadOrder
//
//  Created by IRS on 1/6/16.
//  Copyright (c) 2016 IrsSoftware. All rights reserved.
//

#import "TerminalViewController.h"
#import "AppDelegate.h"
#import <ifaddrs.h>
#import <arpa/inet.h>
#import "LibraryAPI.h"
#import <FMDB.h>
#import "TerminalListTableViewCell.h"
#import <KVNProgress/KVNProgress.h>
#import <AFNetworking/AFNetworking.h>
#import "PublicSqliteMethod.h"

extern NSString *baseUrl;
@interface TerminalViewController ()
{
    MCPeerID *pID;
    NSString *documentDirectory;
    
    FMDatabase *dbT;
    NSString *dbPath;
    NSMutableArray *terminalArray;
    NSString *deviceName;
    int sendFiles;
    int receiveFiles;
    
    MCPeerID *specificPeer;
    NSMutableArray *clientPrinterArray;
    NSString *alertType;
    NSString *terminalQty;
    NSMutableArray *appRegInfoArray;
    int appSyncStatus;
    NSString *addOnQty;
    NSMutableArray *arrConnectedDevices;

}
@property (nonatomic, strong) AppDelegate *appDelegate;

//@property (nonatomic) KVNProgressConfiguration *basicConfiguration;

//-(void)peerDidChangeStateWithNotification:(NSNotification *)notification;

-(void)syncStartReceivingResourceWithNotification:(NSNotification *)notification;
-(void)syncUpdateReceivingProgressWithNotification:(NSNotification *)notification;
-(void)syncDidFinishReceivingResourceWithNotification:(NSNotification *)notification;

//refresh tableview
-(void)refreshTableViewWithNotification:(NSNotification *)notification;
@end

@implementation TerminalViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Terminal";
    // Do any additional setup after loading the view from its nib.
    
    terminalArray = [[NSMutableArray alloc]init];
    appRegInfoArray = [[NSMutableArray alloc] init];
    clientPrinterArray = [[NSMutableArray alloc]init];
    dbPath = [[LibraryAPI sharedInstance]getDbPath];
    self.textTerminalQty.delegate = self;
    //[self copySampleFilesToDocDir];
    self.tableDeviceList.delegate = self;
    self.tableDeviceList.dataSource = self;
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    //self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:34/255.0 green:171/255.0 blue:241/255.0 alpha:1.0];
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.translucent = NO;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    documentDirectory = [[NSString alloc] initWithString:[paths objectAtIndex:0]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(syncStartReceivingResourceWithNotification:)
                                                 name:@"SyncMCDidStartReceivingResourceNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(syncUpdateReceivingProgressWithNotification:)
                                                 name:@"SyncMCReceivingProgressNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(syncDidFinishReceivingResourceWithNotification:)
                                                 name:@"syncdidFinishReceivingResourceNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshTableViewWithNotification:)
                                                 name:@"RefreshTableDeviceNotification"
                                               object:nil];
    
    UINib *terminalNib = [UINib nibWithNibName:@"TerminalListTableViewCell" bundle:nil];
    [[self tableDeviceList]registerNib:terminalNib forCellReuseIdentifier:@"TerminalListTableViewCell"];
    
    self.viewTerminalSndBg.layer.cornerRadius = 20.0;
    self.viewTerminalSndBg.layer.masksToBounds = YES;
    
    /*
    UIGraphicsBeginImageContext(self.view.frame.size);
    [[UIImage imageNamed:@"IO_Background1024"] drawInRect:self.view.bounds];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:image];
     */
    //self.viewTerminal.hidden = true;
    [self checkTerminalData];
    [self checkWorkMode];
    self.labelIPAddress.text = [[LibraryAPI sharedInstance] getIpAddress];
    
}

-(void)viewDidLayoutSubviews
{
    if ([self.tableDeviceList respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableDeviceList setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([self.tableDeviceList respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.tableDeviceList setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)swChangeValue:(id)sender {
    if (appSyncStatus == 0) {
        if (self.swEnable.isOn) {
            [[_appDelegate mcManager] setupPeerAndSessionWithDisplayName:@"Server"];
            [[_appDelegate mcManager] advertiseSelf:true];
            self.viewTerminal.hidden = true;
            [[LibraryAPI sharedInstance] setMultipleTerminalMode:@"True"];
        }
        else
        {
            [[LibraryAPI sharedInstance] setMultipleTerminalMode:@"False"];
            [[_appDelegate mcManager] advertiseSelf:false];
            self.viewTerminal.hidden = false;
        }
        [self updateGeneralSetting];
    }
    else
    {
        if (self.swEnable.isOn) {
            
        }
        else
        {
            [self showAlertView:@"After synchronize data, device cannot change workMode" title:@"Warning"];
            self.swEnable.on = 1;
            self.viewTerminal.hidden = true;
            [[LibraryAPI sharedInstance] setMultipleTerminalMode:@"True"];
            //[self checkWorkMode];
            return;
        }
        
    }
    
    
}

#pragma mark - textfield delegate

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (textField == self.textTerminalQty) {
        if (appRegInfoArray.count == 0) {
            [self showAlertView:@"Company profile cannot empty" title:@"Information"];
            return NO;
        }
        if ([[[appRegInfoArray objectAtIndex:1] objectForKey:@"App_Status"] isEqualToString:@"PENDING"]) {
            if ([[[appRegInfoArray objectAtIndex:1] objectForKey:@"App_Action"]isEqualToString:@"UpdCompany"]) {
                [self showAlertView:@"Waiting approved. Cannot update terminal qty" title:@"Information"];
            }
            else
            {
                if ([self.textTerminalQty.text isEqualToString:@"5"]) {
                    [self showAlertView:@"Maximum terminal qty is 5. Cannot add on" title:@"Information"];
                }
                else
                {
                    [self showTerminalQtySelectionView];
                }
                
            }
        }
        else if([[[appRegInfoArray objectAtIndex:1] objectForKey:@"App_Status"] isEqualToString:@"REG"])
        {
            if ([self.textTerminalQty.text isEqualToString:@"5"]) {
                [self showAlertView:@"Maximum terminal qty is 5. Cannot add on" title:@"Information"];
            }
            else
            {
                [self showTerminalQtySelectionView];
            }
        }
        else if([[[appRegInfoArray objectAtIndex:1] objectForKey:@"App_Status"] isEqualToString:@"RE-REG"])
        {
            [self showAlertView:@"Waiting approved. Cannot update terminal qty" title:@"Information"];
        }
        else
        {
            [self showTerminalQtySelectionView];
        }
        
        
        return NO;
    }
    else
    {
        return YES;
    }
}

-(void)showTerminalQtySelectionView
{
    
    SelectCatTableViewController *selectCatTableViewController = [[SelectCatTableViewController alloc]init];
    selectCatTableViewController.delegate = self;
    selectCatTableViewController.filterType = @"TerminalNo";
    
    selectCatTableViewController.modalPresentationStyle = UIModalPresentationPopover;
    selectCatTableViewController.popoverPresentationController.sourceView = self.textTerminalQty;
    selectCatTableViewController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionLeft;
    selectCatTableViewController.popoverPresentationController.sourceRect = CGRectMake(self.textTerminalQty.frame.size.width /
                                                                                       2, self.textTerminalQty.frame.size.height / 2, 1, 1);
    [self presentViewController:selectCatTableViewController animated:YES completion:nil];
    
    /*
    self.popOver = [[UIPopoverController alloc]initWithContentViewController:selectCatTableViewController];
    
    [self.view endEditing:YES];
    
    [self.popOver presentPopoverFromRect:CGRectMake(self.textTerminalQty.frame.size.width /
                                                    2, self.textTerminalQty.frame.size.height / 2, 1, 1) inView:self.textTerminalQty permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
     */
}

#pragma mark - selcted cat delegate
-(void)getSelectedCategory:(NSString *)field1 field2:(NSString *)field2 field3:(NSString *)field3 filterType:(NSString *)filterType
{
    
    if ([field1 integerValue] < [[[appRegInfoArray objectAtIndex:1] objectForKey:@"App_TerminalQty"] integerValue])
    {
        if ([[[appRegInfoArray objectAtIndex:1] objectForKey:@"App_Status"]isEqualToString:@"REG"]) {
            [self showAlertView:[NSString stringWithFormat:@"Qty %@ is Less Than Current Terminal Qty",field1] title:@"Warning"];
            //[self.popOver dismissPopoverAnimated:YES];
            [self dismissViewControllerAnimated:YES completion:nil];
            return;
        }
        else
        {
            addOnQty = field1;
            [self showConfirmAddDeductTerminalQtyWithQty:field1];
        }
        
    }
    else if ([field1 integerValue] == [[[appRegInfoArray objectAtIndex:1] objectForKey:@"App_TerminalQty"] integerValue])
    {
        
        //[self.popOver dismissPopoverAnimated:YES];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else
    {
        
        [self showConfirmAddDeductTerminalQtyWithQty:field1];
    }
    
}

-(void)showConfirmAddDeductTerminalQtyWithQty:(NSString *)qty
{
    self.textTerminalQty.text = qty;
    //[self.popOver dismissPopoverAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
    alertType = @"TextAlert";
    NSString *customMsg;
    
    if ([self.textTerminalQty.text integerValue] - [[[appRegInfoArray objectAtIndex:1] objectForKey:@"App_TerminalQty"] integerValue] < 0) {
        customMsg = [NSString stringWithFormat:@"Now %ld",([[[appRegInfoArray objectAtIndex:1] objectForKey:@"App_TerminalQty"] integerValue] - [qty integerValue]) * -1];
    }
    else
    {
        customMsg = [NSString stringWithFormat:@"Now Add On %ld",[self.textTerminalQty.text integerValue] - [[[appRegInfoArray objectAtIndex:1] objectForKey:@"App_TerminalQty"] integerValue]];
    }
    
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:[NSString stringWithFormat:@"Your Current Terminal Qty is %@. %@ \n Are You Sure To Continue ?",[[appRegInfoArray objectAtIndex:1] objectForKey:@"App_TerminalQty"],customMsg]
                                 message:@"Your Qty"
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* yesButton = [UIAlertAction
                                actionWithTitle:@"OK"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
                                    //[self alertActionSelection];
                                    [self terminalViewAlertControlSelectionWithIndex:0];
                                }];
    
    UIAlertAction* noButton = [UIAlertAction
                               actionWithTitle:@"Cancel"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   //Handle no, thanks button
                                   [self terminalViewAlertControlSelectionWithIndex:1];
                               }];
    
    [alert addAction:yesButton];
    [alert addAction:noButton];
    
    [self presentViewController:alert animated:YES completion:nil];

    
    /*
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Your Current Terminal Qty is %@. %@ \n Are You Sure To Continue ?",[[appRegInfoArray objectAtIndex:1] objectForKey:@"App_TerminalQty"],customMsg] message:@"Your Qty" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:@"Cancel", nil];
    [alertView show];
     */
}

#pragma mark - Private method implementation
/*
-(void)peerDidChangeStateWithNotification:(NSNotification *)notification{
    MCPeerID *peerID = [[notification userInfo] objectForKey:@"peerID"];
    //NSString *peerDisplayName = peerID.displayName;
    MCSessionState state = [[[notification userInfo] objectForKey:@"state"] intValue];
    //NSDictionary *dict = [notification userInfo];
    
    if (state != MCSessionStateConnecting) {
        if (state == MCSessionStateConnected) {
            //[peerCollection addObject:dict];
            //NSLog(@"%@",[[peerCollection objectAtIndex:0] objectForKey:@"peerID"]);
            pID = peerID;
            NSLog(@"%@",@"1");
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateDeviceCode];
            });
            
 
            //
            
        }
        else if (state == MCSessionStateNotConnected){
            if ([_arrConnectedDevices count] > 0) {
                //long indexOfPeer = [_arrConnectedDevices indexOfObject:peerDisplayName];
                //[_arrConnectedDevices removeObjectAtIndex:indexOfPeer];
            }
        }
        //[_tblConnectedDevices reloadData];
        
        //BOOL peersExist = ([[_appDelegate.mcManager.session connectedPeers] count] == 0);
        //[_btnDisconnect setEnabled:!peersExist];
        //[_txtName setEnabled:peersExist];
    }
}
 */

#pragma mark - multipeer receive resource event

-(void)syncStartReceivingResourceWithNotification:(NSNotification *)notification{
    sendFiles++;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (sendFiles == 1) {
            [KVNProgress showWithStatus:@"Downloading..."];
        }
        
    });
    
    /*
    sendFiles++;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (sendFiles == 1) {
            [KVNProgress showWithStatus:@"Downloading..."];
        }
    });
     */
    
    /*
    [countProgress removeAllObjects];
    //NSLog(@"%@",notification);
    
     [countProgress addObject:[notification userInfo]];
     
     [self performSelectorOnMainThread:@selector(startCountProgressBar) withObject:nil waitUntilDone:NO];
     //[_tblFiles performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
     */
    
}


-(void)syncUpdateReceivingProgressWithNotification:(NSNotification *)notification{
    
    
     //NSProgress *progress = [[notification userInfo]objectForKey:@"progress"];
    
    /*
     NSDictionary *dict = [countProgress objectAtIndex:(countProgress.count - 1)];
     NSDictionary *updatedDict = @{@"resourceName"  :   [dict objectForKey:@"resourceName"],
     @"peerID"        :   [dict objectForKey:@"peerID"],
     @"progress"      :   progress
     };
     
     
     [countProgress replaceObjectAtIndex:countProgress.count - 1
     withObject:updatedDict];
     
    [self performSelectorOnMainThread:@selector(startCountProgressBar) withObject:nil waitUntilDone:NO];
     */
    /*
    if (progress.fractionCompleted == 1.00) {
        //receiveFiles++;
        _progress.progress = 0.0;
        
    }
     */
     
}

-(void)refreshTableViewWithNotification:(NSNotification *)notification
{
    [self checkTerminalData];
}

-(void)syncDidFinishReceivingResourceWithNotification:(NSNotification *)notification{
    //[self showAlertView:@"1" title:@"1"];
    
    NSDictionary *dict = [notification userInfo];
    
    //NSLog(@"%@ %lu",@"End Receive",(unsigned long)dict.count);
    
    NSURL *localURL = [dict objectForKey:@"localURL"];
    NSString *resourceName = [dict objectForKey:@"resourceName"];
    //_dataStatus = [dict objectForKey:@"peerConnect"];
    
    NSString *destinationPath = [documentDirectory stringByAppendingPathComponent:resourceName];
    NSLog(@"File Detail : %@",destinationPath);
    NSURL *destinationURL = [NSURL fileURLWithPath:destinationPath];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    
    if ([fileManager fileExistsAtPath:destinationPath] == YES) {
        [fileManager removeItemAtPath:destinationPath error:&error];
    }
    
    [fileManager copyItemAtURL:localURL toURL:destinationURL error:&error];
    
    if (error) {
        receiveFiles++;
        [self showAlertView:[error localizedDescription] title:@"Error"];
        //NSLog(@"finsh receive %@", [error localizedDescription]);
    }
    else
    {
        receiveFiles++;
        NSLog(@"%@",@"Success Copy File");
    }
    
    NSLog(@"Checking %d   %d",sendFiles, receiveFiles);
    
    if (sendFiles == receiveFiles) {
        
        NSLog(@"%@",@"Success Copy All File");
        
        [self updateMOTStatus];
        [self showSuccess];
        
    }
    
    dict = nil;
    
}

- (void)showSuccess
{
    deviceName = [NSString stringWithFormat:@"%@,%@,%@,%@",[UIDevice currentDevice].name,self.textServerIP.text,self.textTerminalCode.text,@"Data"];
    
    [[LibraryAPI sharedInstance] setTerminalDeviceName:deviceName];
    
    [KVNProgress showSuccessWithStatus:@"Success"];
    /*
    NSLog(@"%@",@"All Finish");
    [_appDelegate.mcManager.session disconnect];
    deviceName = [NSString stringWithFormat:@"%@,%@,%@,%@",[UIDevice currentDevice].name,self.textServerIP.text,self.textTerminalCode.text,@"Data"];
    [[_appDelegate mcManager] setupPeerAndSessionWithDisplayName:deviceName];
    [[_appDelegate mcManager] setupMCBrowser];
     */

    
}

-(void)startCountProgressBar
{
    //NSProgress *progress = [[countProgress objectAtIndex:0] objectForKey:@"progress"];
    //[_progress setProgress:progress.fractionCompleted];
}

-(void)sendMoreThanOneImg
{
    NSString *documentsDirectory;
    NSString *imgName;
    imgName = @"iorder.db";
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    documentsDirectory = [[NSString alloc] initWithString:[paths objectAtIndex:0]];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:imgName];
    NSString *modifiedName = [NSString stringWithFormat:@"%@_%@", _appDelegate.mcManager.peerID.displayName, imgName];
    NSURL *resourceURL = [NSURL fileURLWithPath:filePath];
    NSLog(@"%@",pID.displayName);
    [_appDelegate.mcManager.session sendResourceAtURL:resourceURL withName:modifiedName toPeer:pID withCompletionHandler:^(NSError *error) {
        if (error) {
            NSLog(@"%@", [error localizedDescription]);
        }
    }];
}

/*
-(void)fileTransferToTerminal
{
    //int totalFileUpload = 0;
    NSString * resourcePath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    
    NSError * error;
    NSArray * directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:resourcePath error:&error];
    NSString *localPath;
    
    for (int i = 0; i < directoryContents.count; i++) {
        if ([[directoryContents objectAtIndex:i] isEqualToString:@"EposLog"])
        {
            
        }
        else if ([[directoryContents objectAtIndex:i] isEqualToString:@".DS_Store"])
        {
            
        }
        else
        {
            
            localPath = [resourcePath stringByAppendingPathComponent:[directoryContents objectAtIndex:i]];
            //[self.restClient uploadFile:[directoryContents objectAtIndex:i] toPath:destDir withParentRev:nil fromPath:localPath];
            NSURL *resourceURL = [NSURL fileURLWithPath:localPath];
            [_appDelegate.mcManager.session sendResourceAtURL:resourceURL withName:[directoryContents objectAtIndex:i] toPeer:pID withCompletionHandler:^(NSError *error) {
                if (error) {
                    NSLog(@"%@", [error localizedDescription]);
                }
            }];
        }
        
    }
    
}
 */



#pragma mark - tableview

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    // Return the number of rows in the section.
    return [terminalArray count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TerminalListTableViewCell *terminalListCell = [tableView dequeueReusableCellWithIdentifier:@"TerminalListTableViewCell"];
    
    //terminalListCell.labelDeviceName.text = [[terminalArray objectAtIndex:indexPath.row] objectForKey:@"T_Name"];
    [[terminalListCell textTermialID]setTag:indexPath.row + 21];
    [[terminalListCell btnUnPair]setTag:indexPath.row];
    [terminalListCell.btnUnPair.layer setBorderWidth:1.0];
    [terminalListCell.btnUnPair.layer setBorderColor:[UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0].CGColor];
    [terminalListCell.btnUnPair.layer setCornerRadius:5.0];
    
    [[terminalListCell btnAddTerminal] setTag:indexPath.row + 41];
    [terminalListCell.btnAddTerminal.layer setBorderWidth:1.0];
    [terminalListCell.btnAddTerminal.layer setBorderColor:[UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0].CGColor];
    [terminalListCell.btnAddTerminal.layer setCornerRadius:5.0];
    
    
    [[terminalListCell btnAddTerminal] addTarget:self action:@selector(updateTerminal:) forControlEvents:UIControlEventTouchUpInside];
    [[terminalListCell btnUnPair] addTarget:self action:@selector(clickUnPair:) forControlEvents:UIControlEventTouchUpInside];
    terminalListCell.labelNo.text = [[[terminalArray objectAtIndex:indexPath.row]objectForKey:@"T_ID"]stringValue];
    terminalListCell.labelDeviceName.text = [[terminalArray objectAtIndex:indexPath.row]objectForKey:@"T_DeviceName"];
    if (![[[terminalArray objectAtIndex:indexPath.row]objectForKey:@"DeviceCode"] isEqualToString:@"null"]) {
        terminalListCell.textTermialID.text = [[terminalArray objectAtIndex:indexPath.row]objectForKey:@"DeviceCode"];
        [[terminalListCell btnAddTerminal] setTitle:@"Update" forState:UIControlStateNormal];
        
    }
    else
    {
        terminalListCell.textTermialID.text = @"";
        [[terminalListCell btnAddTerminal] setTitle:@"Add" forState:UIControlStateNormal];
    }
    
    if ([[[terminalArray objectAtIndex:indexPath.row]objectForKey:@"T_DeviceName"] isEqualToString:@"None"]) {
        [[terminalListCell btnUnPair]setEnabled:false];
    }
    else
    {
        [[terminalListCell btnUnPair]setEnabled:true];
    }
    
    
    return terminalListCell;
    
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 45;
}

-(void)changeTableViewButtonTitleWithTag:(int)tagNo
{
    
}

#pragma mark - alertView

-(void)showAlertView:(NSString *)msg title:(NSString *)title
{
    alertType = @"NormalAlert";
    UIAlertController *alert = [[LibraryAPI sharedInstance] showAlertViewWithMsg:msg Title:title];
    
    [self presentViewController:alert animated:NO completion:nil];
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

#pragma mark - sqlite
// this is for client to update WorkMode after database is replace by server
- (void)updateMOTStatus {
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        if (clientPrinterArray.count > 0) {
            [db executeUpdate:@"Delete from Printer where P_Type = ?",@"Receipt"];
        }
        
        for (int i = 0; i < clientPrinterArray.count; i++) {
            [db executeUpdate:@"Insert into Printer (P_PortName, P_PrinterName, P_Type,"
             "P_MacAddress,P_PrintType,P_Mode,P_Brand) values ("
             "?,?,?,?,?,?,?)",[[clientPrinterArray objectAtIndex:i] objectForKey:@"P_PortName"], [[clientPrinterArray objectAtIndex:i] objectForKey:@"P_PrinterName"],[[clientPrinterArray objectAtIndex:i] objectForKey:@"P_Type"],[[clientPrinterArray objectAtIndex:i] objectForKey:@"P_MacAddress"],[[clientPrinterArray objectAtIndex:i] objectForKey:@"P_PrintType"],[[clientPrinterArray objectAtIndex:i] objectForKey:@"P_Mode"],[[clientPrinterArray objectAtIndex:i] objectForKey:@"P_Brand"]];
            //[[clientPrinterArray objectAtIndex:i] objectForKey:@"P_PortName"]
            if ([db hadError]) {
                [self showAlertView:[db lastErrorMessage] title:@"Error"];
            }
        }
        
        [db executeUpdate:@"Update GeneralSetting set GS_WorkMode = ?",[NSNumber numberWithBool:self.segmentWorkMode.selectedSegmentIndex]];
        
        if ([db hadError])
        {
            [self showAlertView:[db lastErrorMessage] title:@"Fail"];
        }
        
        [db executeUpdate:@"Delete from TerminalDtl"];
        
        if ([db hadError]) {
            [self showAlertView:[db lastErrorMessage] title:@"Error"];
        }
        
        [db executeUpdate:@"Insert into TerminalDtl (TD_Name, TD_Code, TD_ServerIP) values ("
         " ?,?,?)",[UIDevice currentDevice].name, self.textTerminalCode.text,self.textServerIP.text];
        
        if ([db hadError]) {
            [self showAlertView:[db lastErrorMessage] title:@"Error"];
        }
        else
        {
            appSyncStatus = 1;
        }
        
        FMResultSet *rsKioskSetting = [db executeQuery:@"Select * from GeneralSetting"];
        
        if ([rsKioskSetting next]) {
            [[LibraryAPI sharedInstance] setKioskMode:[rsKioskSetting intForColumn:@"GS_EnableKioskMode"]];
        }
        [rsKioskSetting close];
        
        [db executeUpdate:@"Delete from AppRegistration"];
        
        
    }];
    
    [queue close];
    
}

-(void)checkTerminalData
{
    [terminalArray removeAllObjects];
    [appRegInfoArray removeAllObjects];
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        //NSString *terminalQty;
        
        FMResultSet *rsCompany = [db executeQuery:@"Select * from Company"];
        if ([rsCompany next]) {
            [appRegInfoArray addObject:[rsCompany resultDictionary]];
        }
        [rsCompany close];
        
        FMResultSet *rsAppReg = [db executeQuery:@"Select App_TerminalQty,App_CompanyName,App_PurchaseID,App_LicenseID,App_Status, App_ReqExpDate, App_Action from AppRegistration"];
        
        if ([rsAppReg next]) {
            terminalQty = [rsAppReg stringForColumn:@"App_TerminalQty"];
            self.textTerminalCode.text = [rsAppReg stringForColumn:@"App_TerminalQty"];
            [appRegInfoArray addObject:[rsAppReg resultDictionary]];
        }
        else
        {
            terminalQty = @"5";
        }
        [rsAppReg close];
        
        FMResultSet *rsGS = [db executeQuery:@"Select GS_EnableMTO, GS_WorkMode from GeneralSetting"];
        if ([rsGS next]) {
            if ([rsGS intForColumn:@"GS_EnableMTO"] == 0) {
                self.viewTerminal.hidden = false;
            }
            else
            {
                self.viewTerminal.hidden = true;
            }
            self.swEnable.on = [rsGS boolForColumn:@"GS_EnableMTO"];
            self.segmentWorkMode.selectedSegmentIndex = [rsGS boolForColumn:@"GS_WorkMode"];
            
        }
        [rsGS close];
        
        //FMResultSet *rs = [db executeQuery:@"Select T_ID, T_Code as DeviceCode,T_DeviceName, T_Connect,T_Session from Terminal"];
        FMResultSet *rs = [db executeQuery:[NSString stringWithFormat:@"Select T_ID, T_Code as DeviceCode,T_DeviceName, T_Connect,T_Session from Terminal limit %@",terminalQty]];
        while ([rs next]) {
            [terminalArray addObject:[rs resultDictionary]];
        }
        [self.tableDeviceList reloadData];
        [rs close];
        
        appSyncStatus = 0;
        
        FMResultSet *rsPrinter = [db executeQuery:@"Select * from Printer where P_Type = ?",@"Receipt"];
        
        while ([rsPrinter next]) {
            [clientPrinterArray addObject:[rsPrinter resultDictionary]];
        }
        [rsPrinter close];
                
    }];
    
    [queue close];
    
}

-(void)deleteTerminalData:(NSString *)terminalName SessionSequence:(int)index
{
    dbT = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbT open]) {
        NSLog(@"Fail To Open");
        return;
    }
    
    [dbT executeUpdate:@"Delete from Terminal where T_Name = ?",terminalName];
    
    if ([dbT hadError]) {
        [self showAlertView:[dbT lastErrorMessage] title:@"Fail"];
    }
    else
    {
        [terminalArray removeObjectAtIndex:index];
    }
    [self.tableDeviceList reloadData];
    
    [dbT close];
}

-(void)clickUnPair:(UIButton *)sender
{
    
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableDeviceList];
    NSIndexPath *indexPath = [self.tableDeviceList indexPathForRowAtPoint:buttonPosition];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        [db executeUpdate:@"Update Terminal set T_DeviceName = ?, T_Code = ? where T_ID = ?",
          @"None",@"null", [[terminalArray objectAtIndex:indexPath.row] objectForKey:@"T_ID"]];
        
        if (![db hadError]) {
            [self showAlertView:@"Device unpair" title:@"Success"];
        }
        
    }];
    
    [queue close];
    
    [self checkTerminalData];
    
    
}

-(void)updateTerminal:(UIButton *)sender
{
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableDeviceList];
    NSIndexPath *indexPath = [self.tableDeviceList indexPathForRowAtPoint:buttonPosition];
    
    UITextField *terminalName = (UITextField *)[self.tableDeviceList viewWithTag:indexPath.row + 21];
    
    
    if ([[terminalName text] isEqualToString:@""]) {
        [self showAlertView:@"Device code cannot empty" title:@"Warning"];
        return;
    }
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs1 = [db executeQuery:@"Select * from Terminal where T_Code = ?", [[terminalName text] uppercaseString]];
        
        if ([rs1 next]) {
            [self showAlertView:@"Terminal code exist" title:@"Warning"];
            [rs1 close];
            return;
        }
        
        [db executeUpdate:@"Update Terminal set T_Code = ?, T_DeviceName = ? where T_ID = ?",
         [terminalName text], [[terminalArray objectAtIndex:indexPath.row] objectForKey:@"T_DeviceName"], [[terminalArray objectAtIndex:indexPath.row] objectForKey:@"T_ID"]];
        
        if (![db hadError]) {
            [self showAlertView:@"Success update" title:@"Success"];
        }
        
        
    }];
    
    [queue close];
    [self checkTerminalData];
   
    
}

/*
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
        //[self fileTransferToTerminal];
    }
    
    
}
 */

- (void)updateGeneralSetting
{
    dbT = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbT open]) {
        NSLog(@"Fail To Open");
        return;
    }
    
    [dbT executeUpdate:@"Update GeneralSetting set GS_EnableMTO = ?",[NSNumber numberWithBool:self.swEnable.on]];
    
    if ([dbT hadError])
    {
        [self showAlertView:[dbT lastErrorMessage] title:@"Fail"];
    }
    else
    {
        
        [self checkWorkMode];
        
    }
    
    [dbT close];
}


- (IBAction)changeWorkMode:(id)sender {
    if (appSyncStatus == 0) {
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
        
        [queue inDatabase:^(FMDatabase *db) {
            [db executeUpdate:@"Update GeneralSetting set GS_WorkMode = ?",[NSNumber numberWithBool:self.segmentWorkMode.selectedSegmentIndex]];
            
            if ([db hadError])
            {
                [self showAlertView:[db lastErrorMessage] title:@"Fail"];
            }
            
        }];
        [queue close];
        
        switch (self.segmentWorkMode.selectedSegmentIndex) {
            case 0:
                
                [[_appDelegate mcManager] setupPeerAndSessionWithDisplayName:@"Server"];
                [[_appDelegate mcManager] advertiseSelf:true];
                break;
            case 1:
                
                break;
                
        }
    }
    
    
    
    [self checkWorkMode];
}

-(void)checkWorkMode
{
    //NSArray *existingPeers = [_appDelegate.mcManager.session connectedPeers];
    if (appSyncStatus == 1) {
        [self showAlertView:@"After synchronize data, device cannot change work mode" title:@"Warning"];
        self.segmentWorkMode.selectedSegmentIndex = 1;
        return;
    }
    if (self.swEnable.isOn) {
        switch (self.segmentWorkMode.selectedSegmentIndex) {
            case 0:
                self.labelServerDeviceIP.text = @"Device IP Address";
                self.textServerIP.hidden = true;
                //self.textTerminalCode.hidden = true;
                self.tableDeviceList.hidden = false;
                self.labelIPAddress.hidden = false;
                self.btnSyncServer.hidden = true;
                [[LibraryAPI sharedInstance]setRefreshTB:@"Refresh,0"];
                [[LibraryAPI sharedInstance] setWorkMode:@"Main"];
                self.labelTerminalQtyCode.text = @"Current Terminal Qty";
                self.textTerminalQty.text = terminalQty;
                self.textTerminalCode.hidden = true;
                self.textTerminalQty.hidden = false;
                //[self calcAmount];
                break;
            case 1:
                [[_appDelegate mcManager] advertiseSelf:false];
                self.labelServerDeviceIP.text = @"Server IP Address";
                self.tableDeviceList.hidden = true;
                self.labelIPAddress.hidden = true;
                self.textServerIP.hidden = false;
                self.textTerminalCode.hidden = false;
                self.btnSyncServer.hidden = false;
                [[LibraryAPI sharedInstance]setRefreshTB:@"Refresh,1"];
                [[LibraryAPI sharedInstance] setWorkMode:@"Terminal"];
                self.labelTerminalQtyCode.text = @"Terminal Code";
                self.textTerminalCode.text = @"";
                [self.btnSyncServer setTitle:@"SYNC WITH SERVER" forState:UIControlStateNormal];
                [self getTerminalDetail];
                self.textTerminalCode.hidden = false;
                self.textTerminalQty.hidden = true;
                //self.textServerIP
                break;
            default:
                break;
        }

    }
    else
    {
        [[_appDelegate mcManager] advertiseSelf:false];
        [[[_appDelegate mcManager] myBrowser ]stopBrowsingForPeers];
    }
    
}

-(void)getTerminalDetail
{
    dbT = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbT open]) {
        NSLog(@"Fail To Open");
        return;
    }
    
    FMResultSet *rs = [dbT executeQuery:@"Select * from TerminalDtl"];
    
    if ([rs next])
    {
        appSyncStatus = 1;
        self.textServerIP.text = [rs stringForColumn:@"TD_ServerIP"];
        self.textTerminalCode.text = [rs stringForColumn:@"TD_Code"];
    }
    else
    {
        appSyncStatus = 0;
    }
    
    [dbT close];
    
}

#pragma mark - alertview response
- (void)terminalViewAlertControlSelectionWithIndex:(NSUInteger)index
{
    if ([alertType isEqualToString:@"TextAlert"]) {
        if (index == 0)
        {
            if ([[[appRegInfoArray objectAtIndex:1] objectForKey:@"App_Status"]isEqualToString:@"REG"]) {
                [self callAddOnTerminalWebApiWithTerminalQty:self.textTerminalQty.text];
            }
            else
            {
                BOOL result = [PublicSqliteMethod updateAppRegistrationTableWhenDemoWithTerminalQty:self.textTerminalQty.text DBPath:dbPath];
                if (result == true) {
                    [self callAddOnTerminalWebApiWithTerminalQty:self.textTerminalQty.text];
                    [self checkTerminalData];
                }
                else
                {
                    [self showAlertView:@"Fail to update local database. Please try again." title:@"Warning"];
                }
                [KVNProgress dismiss];
            }
            
        }
        else
        {
            
            self.textTerminalQty.text = [[NSNumber numberWithInt:[[[appRegInfoArray objectAtIndex:1] objectForKey:@"App_TerminalQty"] integerValue]]stringValue];
        }
    }
}

- (IBAction)btnClickSyncServer:(id)sender {
    if (self.segmentWorkMode.selectedSegmentIndex == 1)
    {
        [[[_appDelegate mcManager] myBrowser]stopBrowsingForPeers];
        sendFiles = 0;
        receiveFiles = 0;
        deviceName = [NSString stringWithFormat:@"%@,%@,%@,%@",[UIDevice currentDevice].name,self.textServerIP.text,self.textTerminalCode.text,@"Sync"];
        _appDelegate.mcManager.tName = [UIDevice currentDevice].name;
        _appDelegate.mcManager.tIp = self.textServerIP.text;
        _appDelegate.mcManager.tCode = self.textTerminalCode.text;
        [[_appDelegate mcManager] setupPeerAndSessionWithDisplayName:deviceName];
        [[_appDelegate mcManager] setupMCBrowser];
    }
    
}

#pragma mark - add on terminal qty

-(void)callAddOnTerminalWebApiWithTerminalQty:(NSString *)qty
{
    [KVNProgress showWithStatus:@"Data Sending..."];
    NSString *toDay;
    NSDate *toDayDate = [NSDate date];
    //NSDateFormatter *dateFormater = [[NSDateFormatter alloc] init];
    //[dateFormater setDateFormat:@"yyyy-MM-dd"];
    NSDateFormatter *dateFormater = [[LibraryAPI sharedInstance] getDateFormateryyyymmdd];
    toDay = [dateFormater stringFromDate:toDayDate];
    //int dayCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"defaultDayCount"];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc]initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    NSDictionary *parameters = @{@"DeviceID":[[appRegInfoArray objectAtIndex:1] objectForKey:@"App_LicenseID"],@"DateTime":toDay,@"AddDay":@"0",@"CompanyName1":[[appRegInfoArray objectAtIndex:1] objectForKey:@"App_CompanyName"],@"CompanyName2":@"",@"Address1":[[appRegInfoArray objectAtIndex:0] objectForKey:@"Comp_Address1"],@"Address2":[[appRegInfoArray objectAtIndex:0] objectForKey:@"Comp_Address2"],@"PostCode":[[appRegInfoArray objectAtIndex:0] objectForKey:@"Comp_PostCode"],@"Country":[[appRegInfoArray objectAtIndex:0] objectForKey:@"Comp_Country"],@"Email":[[appRegInfoArray objectAtIndex:0] objectForKey:@"Comp_Email"],@"Terminal":qty,@"intVersion":@"34",@"PurchaseID":[[appRegInfoArray objectAtIndex:1] objectForKey:@"App_PurchaseID"],@"LCode":@"1714",@"Status":[[appRegInfoArray objectAtIndex:1] objectForKey:@"App_Status"],@"UpdCompany_YN":@"0",@"UpdTerminal_YN":@"1"};
    
    //NSLog(@"Add Terminal Parameter %@",parameters);
    
    NSMutableURLRequest *req = [[AFJSONRequestSerializer serializer]requestWithMethod:@"POST" URLString:[NSString stringWithFormat:@"%@%@",baseUrl, @"/RegisterDevice.aspx"] parameters:parameters error:nil];
    
    req.timeoutInterval= [[[NSUserDefaults standardUserDefaults] valueForKey:@"timeoutInterval"] longValue];
    
    [[manager dataTaskWithRequest:req completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        BOOL result;
        if (!error) {
            NSDictionary* json = [NSJSONSerialization JSONObjectWithData:responseObject
                                                                 options:kNilOptions
                                                                   error:&error];
            
            //NSLog(@"add terminal json result : %@",json);
            if (json.count > 0) {
                if ([[json objectForKey:@"Result"] isEqualToString:@"True"]) {
                    
                    result = [PublicSqliteMethod updateAppRegistrationTableWhenAddTerminalWithLicenseID:[json objectForKey:@"DeviceID"] ProductKey:[json objectForKey:@"ProductKey"] DeviceStatus:[json objectForKey:@"Status"] TerminalQty:[json objectForKey:@"TerminalNo"] DBPath:dbPath RequestAction:[json objectForKey:@"Action"]];
                    if (result == true) {
                        
                        [self checkTerminalData];
                    }
                    else
                    {
                        [self showAlertView:@"Fail to update local database. Please try again." title:@"Warning"];
                    }
                    [KVNProgress dismiss];
                    
                }
                else
                {
                    [KVNProgress dismiss];
                    [self showAlertView:[json objectForKey:@"Message"] title:@"Warning"];
                }
            }
            else
            {
                [KVNProgress dismiss];
                [self showAlertView:@"Fail to get data from server" title:@"Warning"];
            }
            
            
        } else {
            [KVNProgress dismiss];
            [self showAlertView:[NSString stringWithFormat:@"%@",error] title:@"Cannot Connect Server"];
            //NSLog(@"Error: %@, %@, %@", error, response, responseObject);
        }
    }] resume];
}

@end
