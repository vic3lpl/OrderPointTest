//
//  AdminViewController.m
//  IpadOrder
//
//  Created by IRS on 10/15/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "AdminViewController.h"
#import "ReportViewController.h"
#import "ContainerViewController.h"
#import "BackupSqliteViewController.h"
#import "DragTablePlanViewController.h"
#import <MBProgressHUD.h>
#import "LibraryAPI.h"
#import "LinkToAccountViewController.h"
#import <FMDB.h>
#import "PublicMethod.h"
//#import "AppDelegate.h"

@interface AdminViewController ()
{
    NSMutableArray *streamData;
    NSString *terminalType;
    NSString *accUrl;
    NSString *dbPath;
    NSString *accPassword;
    NSUInteger linkAccCount;
}
//@property (nonatomic, strong) AppDelegate *appDelegate;
@end

@implementation AdminViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //_appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    streamData = [[NSMutableArray alloc] init];
    // Do any additional setup after loading the view from its nib.
    terminalType = [[LibraryAPI sharedInstance] getWorkMode];
    dbPath = [[LibraryAPI sharedInstance] getDbPath];
    linkAccCount = 0;
    [self setTitle:@"More"];
    UIBarButtonItem *btnBackTableDesign = [[UIBarButtonItem alloc]initWithTitle:@"< Table" style:UIBarButtonItemStylePlain target:self action:@selector(btnClickBackToTableDesign)];
    self.navigationItem.leftBarButtonItem = btnBackTableDesign;
    
    [btnBackTableDesign setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor],NSForegroundColorAttributeName, nil] forState:UIControlStateNormal];
    
    
    /*
    UIGraphicsBeginImageContext(self.view.frame.size);
    [[UIImage imageNamed:@"IO_Background1024"] drawInRect:self.view.bounds];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.view.backgroundColor = [UIColor colorWithPatternImage:image];
    */
    //[[NSNotificationCenter defaultCenter] addObserver:self
      //                                       selector:@selector(didReceiveDataWithNotification:)
                                               //  name:@"MCDidReceiveDataNotification"
                                               //object:nil];
    
}

-(void)viewDidAppear:(BOOL)animated
{
    [self getLinkAccountSetting];
    //self.navigationController.navigationBar.hidden = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)btnClickBackToTableDesign
{
    [self.navigationController popViewControllerAnimated:NO];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)btnReportView:(id)sender {
    if ([terminalType isEqualToString:@"Main"]) {
        ReportViewController *backupSqliteViewController2 = [[ReportViewController alloc]init];
        [self presentViewController:backupSqliteViewController2 animated:NO completion:nil];
    }
    else
    {
        [self showMyHudMessageBoxWithMessage:@"Terminal Cannot Access Report"];
    }
    
}

- (IBAction)btnSettingView:(id)sender {
    ContainerViewController *containerViewController = [[ContainerViewController alloc]init];
    [self presentViewController:containerViewController animated:NO completion:nil];
}

- (IBAction)btnBackup:(id)sender {
    if ([terminalType isEqualToString:@"Main"]) {
        BackupSqliteViewController *backupSqliteViewController2 = [[BackupSqliteViewController alloc]init];
        [self.navigationController pushViewController:backupSqliteViewController2 animated:NO];
    }
    else
    {
        [self showMyHudMessageBoxWithMessage:@"Terminal Cannot Access Backup"];
    }
    
}

- (IBAction)btnTableDesign:(id)sender {
    
    if ([[LibraryAPI sharedInstance]getUserRole] == 0) {
        [[LibraryAPI sharedInstance] showAlertViewWithTitlw:@"You have no permission entry" Title:@"Warning"];
        //[self showAlertView:@"You have no permission to edit data" title:@"Warning"];
        return;
    }
    
    if ([terminalType isEqualToString:@"Main"]) {
        DragTablePlanViewController *dragTablePlanViewController = [[DragTablePlanViewController alloc]init];
        //[self presentViewController:dragTablePlanViewController animated:YES completion:nil];
        [self.navigationController pushViewController:dragTablePlanViewController animated:NO];
    }
    else
    {
        [self showMyHudMessageBoxWithMessage:@"Terminal cannot access table design"];
    }
    
}

- (IBAction)btnGoToLinkAccount:(id)sender {
    
    if ([terminalType isEqualToString:@"Main"]) {
        [self getEncodeAccPassword];
    }
    else
    {
        [self showMyHudMessageBoxWithMessage:@"Terminal cannot access"];
    }
    
    
    
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

#pragma mark - sqlite3
-(void)getLinkAccountSetting
{
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rsLASetting = [db executeQuery:@"Select LA_ClientID, LA_AccUSerID,LA_AccPassword, LA_Company ,LA_CashSalesAC, LA_CashSalesRoundingAC, LA_ServiceChargeAC, LA_CashSalesDesc, LA_AccUrl, LA_CustomerAC, LA_AccUrl from LinkAccount"];
        
        if ([rsLASetting next])
        {
            linkAccCount = 1;
            accUrl = [rsLASetting stringForColumn:@"LA_AccUrl"];
            accPassword = [rsLASetting stringForColumn:@"LA_AccPassword"];
        }
        else
        {
            linkAccCount = 0;
        }
        [rsLASetting close];
    }];
}

#pragma mark - Get Account Encode password

-(void)getEncodeAccPassword
{
    
    if (linkAccCount == 0) {
        UIAlertController * alert = [[LibraryAPI sharedInstance] showAlertViewWithMsg:@"Link to account setting cannot empty" Title:@"Information"];
        
        [self presentViewController:alert animated:YES completion:nil];
        alert = nil;
        return;
    }
    
    if ([accPassword isEqualToString:@""] && [accUrl isEqualToString:@""]) {
        
        UIAlertController * alert = [[LibraryAPI sharedInstance] showAlertViewWithMsg:@"Incorrect IRS BizSuite setting." Title:@"Information"];
        
        [self presentViewController:alert animated:YES completion:nil];
        alert = nil;
        
        return;
    }
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/%@",accUrl,@"/api/rest/Common/GetEncyptPassword",accPassword]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"Get"];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    //[request setHTTPBody:[userJson dataUsingEncoding:NSUTF8StringEncoding]];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response,
                                               NSData *data, NSError *connectionError)
     {
         if (data.length > 0 && connectionError == nil)
         {
             
             NSArray *responceData = [PublicMethod manuallyConvertAccReturnJsonWithData:data];
             
             //NSString* responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
             
             if ([[[responceData objectAtIndex:0] objectForKey:@"Result"] isEqualToString:@"True"]){
                 LinkToAccountViewController *linkToAccountViewController = [[LinkToAccountViewController alloc] init];
                 linkToAccountViewController.accPassword = [[responceData objectAtIndex:0] objectForKey:@"Message"];
                 [linkToAccountViewController setModalPresentationStyle:UIModalPresentationFormSheet];
                 [linkToAccountViewController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
                 [self.navigationController presentViewController:linkToAccountViewController animated:NO completion:nil];
             }
             else
             {
                 
                 UIAlertController * alert = [[LibraryAPI sharedInstance] showAlertViewWithMsg:[[responceData objectAtIndex:0] objectForKey:@"Message"] Title:@"Information"];
                 
                 [self presentViewController:alert animated:YES completion:nil];
                 alert = nil;
                 
             }
             
             //NSLog(@"Response username : %@",responseString);
             
         }
         else
         {
             UIAlertController *alert = [[LibraryAPI sharedInstance] showAlertViewWithMsg:@"Please check URL setting" Title:@"Information"];
             
             [self presentViewController:alert animated:NO completion:nil];
             alert = nil;
         }
     }];
    

}

/*
-(void)didReceiveDataWithNotification:(NSNotification *)notification{
    //NSDictionary *dict = [notification userInfo];
    //NSString *terminal = _appDelegate.mcManager.terminalName;
    MCPeerID *peerID = [[notification userInfo] objectForKey:@"peerID"];
    
    NSString *peerDisplayName = peerID.displayName;
    
    NSData *receivedData = [[notification userInfo] objectForKey:@"data"];
    NSArray *dataReceive = [NSKeyedUnarchiver unarchiveObjectWithData:receivedData];
    
    //NSString *user = [[dataReceive objectAtIndex:0] objectForKey:@"User"];
    
    NSString *dataFromOther = [NSString stringWithFormat:@"%@ %@ %lu",peerDisplayName,[[dataReceive objectAtIndex:1] objectForKey:@"IM_ItemCode"],(unsigned long)dataReceive.count];
    
    // if ([@"Server" isEqualToString:user]) {
    [_textDataDisplay performSelectorOnMainThread:@selector(setText:) withObject:[_textDataDisplay.text stringByAppendingString:[NSString stringWithFormat:@"%@ wrote:\n%@\n\n", peerDisplayName, dataFromOther]] waitUntilDone:NO];
    [self sendBackMessage];
    
}

-(void)sendBackMessage{
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    
    //[data setObject:[NSString stringWithFormat:@"%ld",(long)_im_ItemNo] forKey:@"IM_ItemNo"];
    [data setObject:@"FromServer" forKey:@"IM_ItemCode"];
    [data setObject:@"Server" forKey:@"User"];
    
    [streamData addObject:data];
    
    NSMutableDictionary *data2 = [NSMutableDictionary dictionary];
    [data2 setObject:@"FromServer2" forKey:@"IM_ItemCode"];
    [data2 setObject:@"Server" forKey:@"User"];
    
    [streamData addObject:data2];
    
    NSData *dataToBeSent = [NSKeyedArchiver archivedDataWithRootObject:streamData];
    
    //NSArray *allPeers = [_appDelegate.mcManager.session connectedPeers];
    NSArray *oneArray = @[[[_appDelegate.mcManager.testArray objectAtIndex:0] objectForKey:@"peerID"]];
    //NSArray *oneArray = @[[_appDelegate.mcManager.session.connectedPeers objectAtIndex:0]];
    NSLog(@"lim : %@",oneArray);
    
    NSError *error;
    
    [_appDelegate.mcManager.session sendData:dataToBeSent
                                     toPeers:oneArray
                                    withMode:MCSessionSendDataReliable
                                       error:&error];
    
    if (error) {
        NSLog(@"Erro : %@", [error localizedDescription]);
    }
    
}
*/

@end
