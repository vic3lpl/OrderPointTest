//
//  SelectTablePlanViewController.m
//  IpadOrder
//
//  Created by IRS on 7/15/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "SelectTablePlanViewController.h"
#import "SelectTablePlanTableViewCell.h"
#import <FMDB.h>
#import "LibraryAPI.h"
#import "ContainerViewController.h"
#import "DragTablePlanViewController.h"
//#import "TestScaleViewController.h"
#import "OrderingViewController.h"
#import "BackupSqliteViewController.h"
#import "ReportViewController.h"
#import "AdminViewController.h"
#import "AppDelegate.h"
#import <KVNProgress.h>
#import "BillListingViewController.h"
#import "EditBillViewController.h"
#import "PublicMethod.h"
#import "TerminalData.h"

@interface SelectTablePlanViewController ()
{
    FMDatabase *dbTable;
    NSString *dbPath;
    NSMutableArray *tableArray;
    NSMutableArray *tableArray2;
    UILabel *tbLabel;
    UILabel *amtLabel;
    float tableX, tableY, tableScale, tableRotate;
    NSString *activateTbName;
    
    NSMutableArray *sectionArray;
    NSMutableDictionary *sectionDic;
    long sectionIndex;
    NSString *sectionName;
    
    UIView *sectionView;
    
    NSString *test;
    NSString *selectedTableName;
    NSString *enableServiceTaxGst;
    NSString *enableGst;
    
    //--------
    NSString *tblWorkMode;
    NSString *mtMode;
    AppDelegate *appDelegate;
    MCPeerID *serverPeer;
    NSMutableArray *requestServerData;
    NSTimer *timerRefreshTPAmt;
    NSArray *tableInfo;
    UIButton *btnSection;
    
    NSString *tbDineStatus;
    NSString *tbOverrideSVC;
    BOOL pageControlUsed;
    
    UILabel *existAmtLabel;
    
    UILabel *existTbName;
    MCPeerID *specificPeer;
    
    // for flytech printer
    NSUUID *flyTechUUID;
    NSString *connectStatus;
    NSString *alertType;
    
    NSArray *serverReturnSoNoResult;
    
    // transfer table
    NSMutableDictionary *transferTableDict;
    NSString *selectTablePlanStatus;
    NSMutableArray *partialSalesOrderArray;
    int transferTableDineStatus;
    NSString *transferTableName;
    NSUInteger transferTableID;
    
}

-(void)refreshTablePlanAmtWithNotification:(NSNotification *)notification;
-(void)getSalesOrderDocNoWithNotification:(NSNotification *)notification;

-(void)getTransferSalesOrderDetailResultWithNotification:(NSNotification *)notification;
-(void)getRecalculateTableplanTransferTableResultWithNotification:(NSNotification *)notification;

-(void)getCombineSalesOrderDetailResultWithNotification:(NSNotification *)notification;

@end

@implementation SelectTablePlanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    requestServerData = [[NSMutableArray alloc] init];
    transferTableDict = [NSMutableDictionary dictionary];
    selectTablePlanStatus = @"Order";
    UINavigationItem *n = [self navigationItem];
    [n setTitle:@"Table Layout"];
    
    UIBarButtonItem *btnGoToAdmin = [[UIBarButtonItem alloc]initWithTitle:@"More" style:UIBarButtonItemStylePlain target:self action:@selector(goToMore:)];
    self.navigationItem.rightBarButtonItem = btnGoToAdmin;
    
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    
    [self.navigationController.navigationBar
     setBackgroundImage:[UIImage imageNamed:@"bluedeep_bar"]
     forBarMetrics:UIBarMetricsDefault];
    
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    UIBarButtonItem *newBackButton =
    [[UIBarButtonItem alloc] initWithTitle:@"Logout"
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(backToLogInView)];
    self.navigationItem.leftBarButtonItem = newBackButton;
    
    
    dbPath = [[LibraryAPI sharedInstance]getDbPath];
    tableArray = [[NSMutableArray alloc]init];
    //tableArray2 = [[NSMutableArray alloc]init];
    
    sectionArray = [[NSMutableArray alloc]init];
    //newButtons = [[NSMutableArray alloc]init];
    //self.segmentSection.delegate = self;
    self.scrollViewTb.delegate = self;
    
    [self.btnOption addTarget:self action:@selector(openOptionPopUpMenu) forControlEvents:UIControlEventTouchUpInside];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshTablePlanAmtWithNotification:)
                                                 name:@"RefreshTablePlanAmtWithNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(getSalesOrderDocNoWithNotification:)
                                                 name:@"GetSalesOrderDocNoWithNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(getTransferSalesOrderDetailResultWithNotification:)
                                                 name:@"GetTransferSalesOrderDetailResultWithNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(getRecalculateTableplanTransferTableResultWithNotification:)
                                                 name:@"GetRecalculateTableplanTransferTableResultWithNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(getCombineSalesOrderDetailResultWithNotification:)
                                                 name:@"GetCombineSalesOrderDetailResultWithNotification"
                                               object:nil];
    
    
    [self createUiView];
    
    
    
}

-(void)viewWillAppear:(BOOL)animated
{

    if (![[[LibraryAPI sharedInstance] getPrinterUUID] isEqualToString:@"Non"] && [[[LibraryAPI sharedInstance] getWorkMode] isEqualToString:@"Main"])
    {
        [PosApi setDelegate: self];
        
    }
    
    self.navigationController.navigationBar.hidden = NO;
    
    [self getGstSvgSetting];
    
    mtMode = [[LibraryAPI sharedInstance]getMultipleTerminalMode];
    tblWorkMode = [[LibraryAPI sharedInstance] getWorkMode];
    
    if ([mtMode isEqualToString:@"True"]) {
        
        if ([tblWorkMode isEqualToString:@"Main"]) {
            [self displayTablePlan];
        }
        else if([tblWorkMode isEqualToString:@"Terminal"])
        {
            [KVNProgress showWithStatus:@"Loading..."];
            [self displayTablePlan];
            
        }
        else
        {
            [self displayTablePlan];
        }
        
        
        timerRefreshTPAmt = [NSTimer scheduledTimerWithTimeInterval:2
                                                             target:self
                                                           selector:@selector(refreshTablePlanAmt)
                                                           userInfo:nil
                                                            repeats:YES];
        
        
        
    }
    else
    {
        [self displayTablePlan];
    }

    
}

-(void)backToLogInView
{
    alertType = @"Logout";
    
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Warning"
                                 message:@"Do you want to logout ?"
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* yesButton = [UIAlertAction
                                actionWithTitle:@"OK"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
                                    [self selectTableAlertControlSelection];
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
    
    /*
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Alert"
                          message:@"Are you sure to logout ?"
                          delegate:self
                          cancelButtonTitle:@"Yes"
                          otherButtonTitles:@"No", nil];
    [alert show];
     */
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)createUiView {
    
    __block int i = 0;
    __block int x = 0;
    __block int y = 0;
    [sectionArray removeAllObjects];
    [sectionDic removeAllObjects];
    
    FMDatabaseQueue *queue = [[FMDatabaseQueue alloc] initWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        
        int countTbSection = 0;
        
        FMResultSet *rsTbSectionCount = [db executeQuery:@"Select Count(*) as TotalSection from TableSection"];
        
        if ([rsTbSectionCount next]) {
            countTbSection = [rsTbSectionCount intForColumn:@"TotalSection"] % 4;
        }
        else
        {
            countTbSection = 0;
        }
        CGRect frameSectionBtn;
        UIView *viewBtnSection;
        for (int j=0; j <= countTbSection; j++) {
            
            frameSectionBtn.origin.x = self.scrollTbSection.frame.size.width * j;
            frameSectionBtn.origin.y = 0;
            frameSectionBtn.size = self.scrollTbSection.frame.size;
            viewBtnSection = [[UIView alloc] initWithFrame:frameSectionBtn];
        }
        
        [rsTbSectionCount close];
        
        FMResultSet *rsTbSectionPlan = [db executeQuery:@"Select * from TableSection order by TS_No limit 4"];
        
        while ([rsTbSectionPlan next]) {
            
            sectionDic = [NSMutableDictionary dictionary];
            
            [sectionDic setObject:[rsTbSectionPlan stringForColumn:@"TS_No"] forKey:@"TsNo"];
            [sectionDic setObject:[rsTbSectionPlan stringForColumn:@"TS_ID"] forKey:@"TsID"];
            [sectionDic setObject:[rsTbSectionPlan stringForColumn:@"TS_Name"] forKey:@"TsName"];
            //[newButtons addObject:[rsSection stringForColumn:@"TS_Name"]];
            
            [sectionArray addObject:sectionDic];
            
            CGRect frame;
            if (i == 0) {
                //NSLog(@"xxx : %f",self.scrollViewTb.frame.origin.x);
                frame.origin.x = 0 ;
            }
            else
            {
                //NSLog(@"width : %f",(self.scrollViewTb.frame.size.width+16) * i);
                frame.origin.x = ((self.scrollViewTb.frame.size.width) * i);
            }

            frame.origin.y = 0;
            frame.size = self.scrollViewTb.frame.size;
            //NSLog(@"view %d %@",i,NSStringFromCGRect(frame));
            self.scrollViewTb.pagingEnabled = YES;
            
            sectionView = [[UIView alloc]initWithFrame:frame];
            
            sectionView.tag = [rsTbSectionPlan intForColumn:@"TS_No"];
            
            //sectionView.layer.borderColor = [UIColor blueColor].CGColor;
            //sectionView.layer.borderWidth = 3.0f;
            //sectionView.backgroundColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:0.5];
            sectionView.backgroundColor = [UIColor whiteColor];
            
            [self.scrollViewTb addSubview:sectionView];
            
            //section button part
            self.scrollTbSection.pagingEnabled = true;
            
            btnSection = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            btnSection.frame = CGRectMake(x, y, 210, 65.0);
            [btnSection setTitle:[rsTbSectionPlan stringForColumn:@"TS_Name"] forState:UIControlStateNormal];
            [btnSection setTag:[rsTbSectionPlan intForColumn:@"TS_ID"] + 20000];
            [btnSection setTitleColor:[UIColor colorWithRed:182/255.0 green:203/255.0 blue:226/255.0 alpha:1.0] forState:UIControlStateNormal];
            [[btnSection titleLabel] setFont:[UIFont boldSystemFontOfSize:18]];
            //btnSection.titleLabel.font = [UIFont fontWithName:@"System-Bold" size:18];
            [btnSection addTarget:self action:@selector(btnTbSectionClickWithNo:) forControlEvents:UIControlEventTouchDown];
            
            [btnSection setBackgroundColor:[UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0]];
            [btnSection setUserInteractionEnabled:YES];
            [viewBtnSection addSubview:btnSection];
            if (i == 0) {
                //[btnSection setBackgroundImage:[UIImage imageNamed:@"btnSectionBlue"] forState:UIControlStateNormal];
                [btnSection setBackgroundColor:[UIColor whiteColor]];
                [btnSection setTitleColor:[UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0] forState:UIControlStateNormal];
            }
            
            btnSection = nil;
            //calc next button x (8 is space between button, 105 is button width)
            x = x + 210 + 0;
            
            
            [self.scrollTbSection addSubview:viewBtnSection];
            //viewBtnSection = nil;
            i++;
            
        }
        
        [rsTbSectionPlan close];
        
        //tbsection btn part
        
    }];
    
    
    [queue close];
    
    self.scrollViewTb.contentSize = CGSizeMake(self.scrollViewTb.frame.size.width * i, self.scrollViewTb.frame.size.height);
    //self.scrollTbSection.contentSize = CGSizeMake(self.scrollTbSection.frame.size.width * i, self.scrollTbSection.frame.size.height);
    sectionDic = nil;
}


- (void)displayTablePlan {
    __block NSString *tableFlagName;
    __block NSString *tbName;
    dbTable = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTable open]) {
        NSLog(@"Failt To Open DB");
        return;
    }
    
    //[newButtons removeAllObjects];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        //int j = 0;
        NSString *tbImgName;
        
        FMResultSet *rsTbSectionPlan = [db executeQuery:@"Select * from TableSection order by TS_No"];
        
        while ([rsTbSectionPlan next]) {
            UIButton *btnSectionTmp = (UIButton *)[self.view viewWithTag:[rsTbSectionPlan intForColumn:@"TS_ID"] + 20000];
            [btnSectionTmp setTitle:[rsTbSectionPlan stringForColumn:@"TS_Name"]  forState:UIControlStateNormal];
            //[btnSection setTag:[rsTbSectionPlan intForColumn:@"TS_ID"] + 20000];
            btnSectionTmp = nil;
        }
        
        [rsTbSectionPlan close];
        
        FMResultSet *rs_Tax = [db executeQuery:@"select * from GeneralSetting"];
        
        if ([rs_Tax next]) {
            if ([rs_Tax doubleForColumn:@"GS_TaxInclude"] == 0) {
                [[LibraryAPI sharedInstance]setTaxType:@"IEx"];
            }
            else
            {
                [[LibraryAPI sharedInstance]setTaxType:@"Inc"];
            }
            
            [[LibraryAPI sharedInstance]setKitchenReceiptGroup:[rs_Tax intForColumn:@"GS_KitchenReceiptGrouping"]];
            
        }
        [rs_Tax close];
        
        FMResultSet *rs1 = [db executeQuery:@"Select * from TablePlan order by TP_ID"];
        
        //NSMutableDictionary *item1 = [NSMutableDictionary dictionary];
        while ([rs1 next]) {
            UIImageView *removeImgView = (UIImageView*) [self.view viewWithTag:[rs1 intForColumn:@"TP_ID"]];
            
            [removeImgView removeFromSuperview];
            
        }
        [rs1 close];
        
        FMResultSet *rsSection = [dbTable executeQuery:@"Select * from TableSection"];
        while ([rsSection next]) {
        
            FMResultSet *rs = [dbTable executeQuery:@"Select *, IFNULL(SOH_DocAmt,'0') as TotalDocAmt from tableplan t1 left join"
                               " (select * from SalesOrderHdr where SOH_Status = 'New') as tb1 "
                               " on t1.tp_name = tb1.soh_table where t1.TP_Section = ? group by TP_Name",[rsSection stringForColumn:@"TS_Name"]];
                
            while ([rs next]) {
                
                tableRotate = [rs doubleForColumn:@"TP_Rotate"];
                tableScale = [rs doubleForColumn:@"TP_Scale"];
                tableX = [rs doubleForColumn:@"TP_Xis"];
                tableY = [rs doubleForColumn:@"TP_Yis"];
                tbName = [rs stringForColumn:@"TP_Name"];
                tbImgName = [rs stringForColumn:@"TP_ImgName"];
                
                UIImageView *newImg;
                //NSLog(@"%f",[rs doubleForColumn:@"SOH_Index"]);
                if ([rs doubleForColumn:@"SOH_Index"] == 0) {
                    newImg = [[UIImageView alloc]initWithImage:[UIImage imageNamed:[rs stringForColumn:@"TP_ImgName"]]];
                    newImg.tag = [rs intForColumn:@"TP_ID"];
                    newImg.userInteractionEnabled = YES;
                    newImg.contentMode = UIViewContentModeScaleAspectFit;
                    tableFlagName = [rs stringForColumn:@"TP_ImgName"];
                }
                else
                {
                    
                    tableFlagName = [self getBusyTableImgNameWithTableName:[rs stringForColumn:@"TP_ImgName"]];
                    
                    newImg = [[UIImageView alloc]initWithImage:[UIImage imageNamed:tableFlagName]];
                    newImg.tag = [rs intForColumn:@"TP_ID"];
                    newImg.userInteractionEnabled = YES;
                    newImg.contentMode = UIViewContentModeScaleAspectFit;
                    tableFlagName = [rs stringForColumn:@"TP_ImgName"];
                    
                }
                
                
                if ([tableFlagName isEqualToString:@"Table1"]) {
                    CGRect imgFrame = newImg.frame;
                    
                    imgFrame.size.width = 150;
                    imgFrame.size.height = 178;
                    newImg.frame = imgFrame;
                }
                else if ([tableFlagName isEqualToString:@"Table2"]) {
                    CGRect imgFrame = newImg.frame;
                    
                    imgFrame.size.width = 200;
                    imgFrame.size.height = 176;
                    newImg.frame = imgFrame;
                }
                else if ([tableFlagName isEqualToString:@"Table3"]) {
                    CGRect imgFrame = newImg.frame;
                    
                    imgFrame.size.width = 200;
                    imgFrame.size.height = 181;
                    newImg.frame = imgFrame;
                }
                
                
                CGAffineTransform transform = newImg.transform;
                transform = CGAffineTransformScale(transform, tableScale, tableScale);
                
                [newImg setTransform:transform];
                     
                UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(clickTable:)];
                     //tapGes.delegate = self;
                tapGes.numberOfTapsRequired = 1;
                [newImg addGestureRecognizer:tapGes];
                
                UILongPressGestureRecognizer *gestureRecognizer = [[UILongPressGestureRecognizer alloc] init];
                [gestureRecognizer addTarget:self action:@selector(imgLongPressed:)];
               
                [newImg addGestureRecognizer: gestureRecognizer];
                
                newImg.center = CGPointMake(tableX, tableY);
                
                if ([tbImgName isEqualToString:@"Table1"]) {
                    tbLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 45, 145, 40)];
                    tbLabel.textAlignment = NSTextAlignmentCenter;
                }
                else if ([tbImgName isEqualToString:@"Table2"]) {
                    tbLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 45, 200, 40)];
                    tbLabel.textAlignment = NSTextAlignmentCenter;
                }
                else if ([tbImgName isEqualToString:@"Table3"]) {
                    tbLabel = [[UILabel alloc]initWithFrame:CGRectMake(8, 38, 180, 40)];
                    tbLabel.textAlignment = NSTextAlignmentCenter;
                }
                
                [tbLabel setFont:[UIFont boldSystemFontOfSize:23]];
                tbLabel.tag = [rs intForColumn:@"TP_ID"] + 30000;
                
                tbLabel.text = tbName;
                [newImg addSubview:tbLabel];
                
                //--------------------------------------------------------------------
                if ([tbImgName isEqualToString:@"Table1"]) {
                    amtLabel = [[UILabel alloc]initWithFrame:CGRectMake(2, 90, 145, 40)];
                    amtLabel.textAlignment = NSTextAlignmentCenter;
                }
                else if ([tbImgName isEqualToString:@"Table2"]) {
                    amtLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 90, 200, 40)];
                    amtLabel.textAlignment = NSTextAlignmentCenter;
                }
                else if ([tbImgName isEqualToString:@"Table3"]) {
                    amtLabel = [[UILabel alloc]initWithFrame:CGRectMake(8, 90, 180, 40)];
                    amtLabel.textAlignment = NSTextAlignmentCenter;
                }
                
                amtLabel.tag = [rs intForColumn:@"TP_ID"] + 40000;
                [amtLabel setFont:[UIFont boldSystemFontOfSize:25]];
                
                FMResultSet *rsSOCount = [db executeQuery:@"Select count(*) as soCount from SalesOrderHdr where SOH_Table = ? and SOH_Status = ?",[rs stringForColumn:@"TP_Name"],@"New"];
                
                if ([rsSOCount next]) {
                    if ([rsSOCount intForColumn:@"soCount"] > 1) {
                        
                        if([tblWorkMode isEqualToString:@"Terminal"])
                        {
                            amtLabel.text = @"0.00";
                            amtLabel.textColor = [UIColor whiteColor];
                            tbLabel.textColor = [UIColor whiteColor];
                        }
                        else
                        {
                            amtLabel.text = [NSString stringWithFormat:@"# %d",[rsSOCount intForColumn:@"soCount"]];
                            amtLabel.textColor = [UIColor whiteColor];
                            tbLabel.textColor = [UIColor whiteColor];
                        }
                        
                    }
                    else
                    {
                        
                        if([tblWorkMode isEqualToString:@"Terminal"])
                        {
                            amtLabel.text = @"0.00";
                        }
                        else
                        {
                            amtLabel.text = [NSString stringWithFormat:@"%0.2f",[rs doubleForColumn:@"SOH_DocAmt"]];
                            
                            amtLabel.textColor = [UIColor whiteColor];
                            tbLabel.textColor = [UIColor whiteColor];
                            /*
                            if ([rs doubleForColumn:@"TotalDocAmt"] > 0.00) {
                                
                            }
                            else
                            {
                                tbLabel.textColor = [UIColor blackColor];
                                amtLabel.textColor = [UIColor blackColor];
                            }
                             */
                            
                        }
                        
                    }
                }
                [rsSOCount close];
                
                [newImg addSubview:amtLabel];
                
                UIView *editView = [[UIView alloc]init];
                editView = (UIView *)[self.view viewWithTag:[rsSection intForColumn:@"TS_No"]];
                     
                [editView addSubview:newImg];
                editView = nil;
                    
                tbLabel = nil;
                amtLabel = nil;

            }
            [rs close];
            
        }
        
        [rsSection close];
    }];
    
    sectionDic = nil;
    [dbTable close];
    
    
}

- (void) imgLongPressed:(UILongPressGestureRecognizer*)sender
{
    
    NSString *tb_Name;
    UITapGestureRecognizer *gesture = (UITapGestureRecognizer *)sender;
    
    int imgSelectedIndex = (int)gesture.view.tag;
    
    if (sender.state == UIGestureRecognizerStateBegan)
    {
        
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
        
        [queue inDatabase:^(FMDatabase *db) {
            
            if ([enableGst isEqualToString:@"Yes"]) {
                FMResultSet *rsServiceTaxGst = [db executeQuery:@"Select T_Percent from GeneralSetting gs inner join Tax t on gs.GS_ServiceGstCode = t.T_Name"
                                                " where gs.GS_ServiceTaxGst = 1"];
                
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
            
            
        }];
        
        [queue close];
        
        if ([selectTablePlanStatus isEqualToString:@"Order"]) {
            if ([tblWorkMode isEqualToString:@"Main"])
            {
                tb_Name = [self getTableID:imgSelectedIndex];
                //[self getTableSalesOrderNoWithTableName:tb_Name];
                if ([self checkTableOccupieStatusWithTableName:tb_Name] > 0) {
                    [self showMoreTableFunctionWithTableName:tb_Name];
                }
                
            }
            else
            {
                tb_Name = [self getTableID:imgSelectedIndex];
                [self requestSalesNoFromServerWithTableName:tb_Name];
            }
        }
        
        
    }
    else if (sender.state == UIGestureRecognizerStateChanged)
    {
        NSLog(@"%@",@"Change Long Press");
    }
    else if (sender.state == UIGestureRecognizerStateEnded)
    {
        
    }
    [dbTable close];
    
}

-(NSString *)getTableID:(int)imgSelectedIndex
{
    __block NSString *tableName;
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rsTable = [db executeQuery:@"Select * from TablePlan where TP_ID = ?",[NSNumber numberWithInt:imgSelectedIndex]];
        
        if ([rsTable next]) {
            [[LibraryAPI sharedInstance] setTableNo:imgSelectedIndex];
            tbDineStatus = [rsTable stringForColumn:@"TP_DineType"];
            tableName = [rsTable stringForColumn:@"TP_Name"];
        }
        else
        {
            [self showAlertView:@"Empty table cannot select" title:@"Warning"];
            return;
        }
        [rsTable close];
    }];
    
    [queue close];
    
    return tableName;
}

-(void)requestSalesNoFromServerWithTableName:(NSString *)table
{
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [requestServerData removeAllObjects];
    [data setObject:@"Request" forKey:@"Result"];
    [data setObject:@"-" forKey:@"Message"];
    [data setObject:@"RequestSalesNo" forKey:@"IM_Flag"];
    [data setObject:table forKey:@"TableName"];
    
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

-(void)getSalesOrderDocNoWithNotification:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        
        serverReturnSoNoResult = [notification object];
        
        if ([[[serverReturnSoNoResult objectAtIndex:0] objectForKey:@"Result"] isEqualToString:@"True"]) {
            if ([[[serverReturnSoNoResult objectAtIndex:0] objectForKey:@"DataCount"] isEqualToString:@"0"]) {
                return;
            }
            else
            {
                
                [self showMoreTableFunctionWithTableName:[[serverReturnSoNoResult objectAtIndex:0] objectForKey:@"SOH_Table"]];
            }
            
        }
        else
        {
            [self showAlertView:@"Cannot get trasfer data" title:@"Warning"];
        }
        
        
    });
}

-(void)showMoreTableFunctionWithTableName:(NSString *)tableName
{
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Option"
                                 message:@"Select function"
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* transferButton = [UIAlertAction
                                     actionWithTitle:@"Transfer Table"
                                     style:UIAlertActionStyleDefault
                                     handler:^(UIAlertAction * action) {
                                         [self getTableSalesOrderNoWithTableName:tableName OptionSelected:@"TransferTable"];
                                     }];
    
    UIAlertAction* combineButton = [UIAlertAction
                                    actionWithTitle:@"Combine Table"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
                                        [self getTableSalesOrderNoWithTableName:tableName OptionSelected:@"CombineTable"];
                                        
                                    }];
    
    UIAlertAction* shareButton = [UIAlertAction
                                  actionWithTitle:@"Share Table"
                                  style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction * action) {
                                      //[self callOutPaxEntryView];
                                      [self getTableSalesOrderNoWithTableName:tableName OptionSelected:@"ShareTable"];
                                      
                                  }];
    
    UIAlertAction* cancelButton = [UIAlertAction
                                   actionWithTitle:@"Cancel"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {
                                       
                                   }];
    
    [alert addAction:transferButton];
    [alert addAction:combineButton];
    [alert addAction:shareButton];
    [alert addAction:cancelButton];
    
    [self presentViewController:alert animated:NO completion:nil];
    alert = nil;
}

-(int)checkTableOccupieStatusWithTableName:(NSString *)table_Name
{
    __block int soQty = 0;
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rsSO = [db executeQuery:@"Select SOH_Table, SOH_DocAmt,SOH_DocNo from SalesOrderHdr where SOH_Status = ? and SOH_Table = ?",@"New",table_Name];
        
        while ([rsSO next]) {
            soQty++;
            
        }
        
        [rsSO close];
    }];
    
    [queue close];
    
    return soQty;
}

-(void)getTableSalesOrderNoWithTableName:(NSString *)table_Name OptionSelected:(NSString *)optionSelected
{
    
    __block NSString *soDocNo;
    __block NSUInteger soQty = 0;
    __block NSString *openOrderView;
    [timerRefreshTPAmt invalidate];
    if ([[[LibraryAPI sharedInstance] getWorkMode] isEqualToString:@"Main"]) {
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
        
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            
            FMResultSet *rsSO = [db executeQuery:@"Select SOH_Table, SOH_DocAmt,SOH_DocNo from SalesOrderHdr where SOH_Status = ? and SOH_Table = ?",@"New",table_Name];
            
            while ([rsSO next]) {
                soQty++;
                soDocNo = [rsSO stringForColumn:@"SOH_DocNo"];
            }
            
            [rsSO close];
            
            if ([optionSelected isEqualToString:@"ShareTable"]) {
                FMResultSet *rsTable = [db executeQuery:@"Select TP_Name,TP_Percent, TP_Overide,TP_DineType, TP_ID from TablePlan where TP_Name = ?",table_Name];
                
                if ([rsTable next]) {
                    
                    selectedTableName = [rsTable stringForColumn:@"TP_Name"];
                    [[LibraryAPI sharedInstance] setTableName:selectedTableName];
                    tbDineStatus = [rsTable stringForColumn:@"TP_DineType"];
                    tbOverrideSVC = [rsTable stringForColumn:@"TP_Overide"];
                    activateTbName = [rsTable stringForColumn:@"TP_Name"];
                    [PublicMethod settingServiceTaxPercentWithOverRide:[rsTable stringForColumn:@"TP_Overide"] Percent:[rsTable stringForColumn:@"TP_Percent"]];
                    openOrderView = @"Go";
                    [rsTable close];
                    
                }
                else
                {
                    openOrderView = @"Deny";
                }
            }
            
            
        }];
        
        [queue close];
    }
    else
    {
        if([[[serverReturnSoNoResult objectAtIndex:0] objectForKey:@"DataCount"] integerValue] > 0)
        {
            soQty = serverReturnSoNoResult.count - 1;
            soDocNo = [[serverReturnSoNoResult objectAtIndex:0] objectForKey:@"SOH_DocNo"];
            
            if ([optionSelected isEqualToString:@"ShareTable"]) {
                
                selectedTableName = [[serverReturnSoNoResult objectAtIndex:serverReturnSoNoResult.count-1] objectForKey:@"SOH_DocNo"];
                [[LibraryAPI sharedInstance] setTableName:selectedTableName];
                tbDineStatus = [[serverReturnSoNoResult objectAtIndex:serverReturnSoNoResult.count-1] objectForKey:@"TP_DineType"];
                tbOverrideSVC = [[serverReturnSoNoResult objectAtIndex:serverReturnSoNoResult.count-1] objectForKey:@"TP_Overide"];
                activateTbName = [[serverReturnSoNoResult objectAtIndex:serverReturnSoNoResult.count-1] objectForKey:@"TP_Name"];
                [PublicMethod settingServiceTaxPercentWithOverRide:tbOverrideSVC Percent:[[serverReturnSoNoResult objectAtIndex:serverReturnSoNoResult.count-1] objectForKey:@"TP_Percent"]];
                openOrderView = @"Go";
                
            }
            else
            {
                openOrderView = @"Deny";
            }
        }
        else
        {
            return;
        }
    }
    
    
    if ([openOrderView isEqualToString:@"Go"]) {
        [self callOutPaxEntryView];
    }
    else
    {
        [self showTransferTableViewWithSOQty:soQty TableName:table_Name SoDocNo:soDocNo OptionSelected:optionSelected];
    }
    
}

-(void)showTransferTableViewWithSOQty:(NSUInteger)soQty TableName:(NSString *)tb_Name SoDocNo:(NSString *)soDocNo OptionSelected:(NSString *)optionSelected
{
    if (soQty == 1) {
        
        [self enableTransferTableModeWithSOQty:soQty TableName:tb_Name SoDocNo:soDocNo OptionSelected:optionSelected TableDineStatus:tbDineStatus TransferType:@"Direct"];
        
        /*
        if ([optionSelected isEqualToString:@"TransferTable"]) {
            [self enableTransferTableModeWithSOQty:soQty TableName:tb_Name SoDocNo:soDocNo OptionSelected:optionSelected TableDineStatus:tbDineStatus TransferType:@"Direct"];
        }
        else
        {
            TransferTableToViewController *transferTableToViewController = [[TransferTableToViewController alloc] init];
            transferTableToViewController.delegate = self;
            UINavigationController *navi = [[UINavigationController alloc]  initWithRootViewController:transferTableToViewController];
            transferTableToViewController.fromDocNo = soDocNo;
            transferTableToViewController.fromTableName = tb_Name;
            transferTableToViewController.transferType = @"Direct";
            transferTableToViewController.selectedOption = optionSelected;
            transferTableToViewController.fromTableDineType = tbDineStatus;
            [navi setModalPresentationStyle:UIModalPresentationFormSheet];
            [navi setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
            [self.navigationController presentViewController:navi animated:YES completion:nil];
        }
        */
        
        
    }
    else if(soQty > 1)
    {
        TransferTableFromViewController *transferTableFromViewController = [[TransferTableFromViewController alloc] init];
        transferTableFromViewController.selectedMultiTbName = tb_Name;
        transferTableFromViewController.delegate = self;
        transferTableFromViewController.transferFromSelectOption = optionSelected;
        UINavigationController *navi = [[UINavigationController alloc]  initWithRootViewController:transferTableFromViewController];
        [navi setModalPresentationStyle:UIModalPresentationFormSheet];
        [navi setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
        [self.navigationController presentViewController:navi animated:YES completion:nil];
    }
}



-(void)refreshTablePlanAmt {
    
    __block NSString *tableFlagName;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if ([mtMode isEqualToString:@"True"]) {
            if ([tblWorkMode isEqualToString:@"Main"]) {
                FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
                
                [queue inDatabase:^(FMDatabase *db) {
                    
                    FMResultSet *rsSection = [db executeQuery:@"Select * from TableSection"];
                    while ([rsSection next]) {
                        
                        FMResultSet *rs = [db executeQuery:@"Select * from tableplan t1 left join"
                                           " (select * from SalesOrderHdr where SOH_Status = 'New') as tb1 "
                                           " on t1.tp_name = tb1.soh_table where t1.TP_Section = ? group by t1.TP_Name",[rsSection stringForColumn:@"TS_Name"]];
                        
                        while ([rs next]) {
                             UIImageView *imageView=(UIImageView *)[self.view viewWithTag:[rs intForColumn:@"TP_ID"]];
                            FMResultSet *rsSOCount = [db executeQuery:@"Select count(*) as soCount from SalesOrderHdr where SOH_Table = ? and SOH_Status = ?",[rs stringForColumn:@"TP_Name"],@"New"];
                            
                            if ([rsSOCount next]) {
                                
                                if ([rsSOCount intForColumn:@"soCount"] > 1) {
                                    
                                    tableFlagName = [self getBusyTableImgNameWithTableName:[rs stringForColumn:@"TP_ImgName"]];
                                    
                                    [imageView setImage:[UIImage imageNamed:tableFlagName]];
                                    imageView.userInteractionEnabled = YES;
                                    imageView.contentMode = UIViewContentModeScaleAspectFit;
                                    
                                    existAmtLabel = (UILabel *) [self.view viewWithTag:40000 + [rs intForColumn:@"TP_ID"]];
                                    
                                    existTbName = (UILabel *) [self.view viewWithTag:30000 + [rs intForColumn:@"TP_ID"]];
                                    existTbName.textColor = [UIColor whiteColor];
                                    
                                    existAmtLabel.text = [NSString stringWithFormat:@"# %d",[rsSOCount intForColumn:@"soCount"]];
                                    
                                    existAmtLabel.textColor = [UIColor whiteColor];
                                    existTbName.textColor = [UIColor whiteColor];
                                    
                                }
                                else
                                {
                                    
                                    existAmtLabel = (UILabel *) [self.view viewWithTag:40000 + [rs intForColumn:@"TP_ID"]];
                                    
                                    existTbName = (UILabel *) [self.view viewWithTag:30000 + [rs intForColumn:@"TP_ID"]];
                                    
                                    existAmtLabel.text = [NSString stringWithFormat:@"%0.2f",[rs doubleForColumn:@"SOH_DocAmt"]];
                                    
                                    if ([rsSOCount intForColumn:@"soCount"] == 1) {
                                        tableFlagName = [self getBusyTableImgNameWithTableName:[rs stringForColumn:@"TP_ImgName"]];
                                    }
                                    else
                                    {
                                        tableFlagName = [rs stringForColumn:@"TP_ImgName"];
                                    }
                                    
                                    [imageView setImage:[UIImage imageNamed:tableFlagName]];
                                    imageView.userInteractionEnabled = YES;
                                    imageView.contentMode = UIViewContentModeScaleAspectFit;
                                    
                                    existAmtLabel.textColor = [UIColor whiteColor];
                                    existTbName.textColor = [UIColor whiteColor];
                                    
                                    
                                }
                            }
                            [rsSOCount close];
                            imageView = nil;
                            
                        }
                        [rs close];
                        
                    }
                    
                    [rsSection close];
                }];
                [queue close];
                
            }
            else
            {
                //terminal send to main to request table amt
                //1
                
                if([[appDelegate.mcManager connectedPeerArray]count] <= 0) {
                    //[self showAlertView:@"Unable Connect Device" title:@"Warning"];
                    //return;
                }
                
                NSMutableDictionary *data = [NSMutableDictionary dictionary];
                [requestServerData removeAllObjects];
                [data setObject:@"Request" forKey:@"Result"];
                [data setObject:@"-" forKey:@"Message"];
                [data setObject:@"RefreshTablePlanAmt" forKey:@"IM_Flag"];
                [requestServerData addObject:data];
                NSData *dataToBeSend = [NSKeyedArchiver archivedDataWithRootObject:requestServerData];
                NSArray *allPeers = [[appDelegate.mcManager session] connectedPeers];
                NSError *error;
                
                if (allPeers.count <= 0) {
                    UINavigationItem *n = [self navigationItem];
                    [n setTitle:@"Table Layout [Disconnected]"];
                    [KVNProgress dismiss];
                    n = nil;
                    return;
                }
                else
                {
                    //UINavigationItem *n = [self navigationItem];
                    //[n setTitle:@"Table Layout [Connected]"];
                    for (int i = 0; i < allPeers.count; i++) {
                        serverPeer = [allPeers objectAtIndex:i];
                        
                        if ([serverPeer.displayName isEqualToString:@"Server"])
                        {
                            UINavigationItem *n = [self navigationItem];
                            [n setTitle:@"Table Layout [Connected]"];
                            connectStatus = @"Connected";
                            //[[LibraryAPI sharedInstance] setServerConnectedStatusWithStatus:@"Connected"];
                            [KVNProgress dismiss];
                            n = nil;
                            NSArray *oneArray = @[[appDelegate.mcManager.session.connectedPeers objectAtIndex:i]];
                            [appDelegate.mcManager.session sendData:dataToBeSend
                                                            toPeers:oneArray
                                                           withMode:MCSessionSendDataReliable
                                                              error:&error];
                            break;
                        }
                        else
                        {
                            //[[LibraryAPI sharedInstance] setServerConnectedStatusWithStatus:@"Disconnected"];
                            connectStatus = @"Disconnected";
                            UINavigationItem *n = [self navigationItem];
                            [n setTitle:@"Table Layout [Disconnected]"];
                            [KVNProgress dismiss];
                            n = nil;
                            //NSLog(@"%@",@"Testing ABCDEFG");
                        }
                        
                    }
                }
                
                //NSLog(@"%@",[[LibraryAPI sharedInstance] getServerConnectedStatus]);
                /*
                if ([[[LibraryAPI sharedInstance] getServerConnectedStatus] isEqualToString:@"Connected"]) {
                    UINavigationItem *n = [self navigationItem];
                    [n setTitle:@"Table Layout [Connected]"];
                    n = nil;
                }
                else
                {
                    UINavigationItem *n = [self navigationItem];
                    [n setTitle:@"Table Layout [Disconnected]"];
                    [KVNProgress dismiss];
                    n = nil;
                    return;
                }
                 */
                
                
                allPeers = nil;
                if (error) {
                    NSLog(@"Erro : %@", [error localizedDescription]);
                    [KVNProgress dismiss];
                }
            }
            
        }
        else
        {
            //[self showAlertView:@"StandaLone" title:@"Warning"];
            //NSLog(@"%@",@"StandAlone");
            [KVNProgress dismiss];
        }
        
    });
    
    
}


-(void)clickTable:(id)sender
{
    
    if ([[LibraryAPI sharedInstance] getKioskMode] == 1) {
        [self showAlertView:@"Please logout to enable kiosk mode" title:@"Warning"];
        return;
    }
    
    UITapGestureRecognizer *gesture = (UITapGestureRecognizer *)sender;
    
    UIImageView *imgView = (UIImageView*) [self.view viewWithTag:gesture.view.tag];
    int imgSelectedIndex = (int)gesture.view.tag;
    
    if ([selectTablePlanStatus isEqualToString:@"Order"]) {
        
        
        MultiSOViewController *multiSOViewController = [[MultiSOViewController alloc]init];
        multiSOViewController.delegate = self;
        //self.popOver = [[UIPopoverController alloc]initWithContentViewController:multiSOViewController];
        multiSOViewController.modalPresentationStyle = UIModalPresentationPopover;
        
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
        
        [queue inDatabase:^(FMDatabase *db) {
            
            FMResultSet *rsComp = [db executeQuery:@"Select * from Company"];
            
            if (![rsComp next ]) {
                [self showAlertView:@"Company is empty, Go to Admin -> General Setting -> Company to add" title:@"Warning"];
                return;
            }
            
            [rsComp close];
            
            FMResultSet *rsCat = [db executeQuery:@"Select IC_Category from ItemCatg limit 1"];
            
            if (![rsCat next]) {
                [self showAlertView:@"Item category is empty, Go To Admin -> General Setting -> Item Category to add it" title:@"Warning"];
                return;
            }
            [rsCat close];
            
            FMResultSet *rsItem = [db executeQuery:@"Select IM_ItemNo from ItemMast limit 1"];
            
            if (![rsItem next]) {
                [self showAlertView:@"Item is empty, Go to Admin -> General Setting -> Item to add it" title:@"Warning"];
                return;
            }
            [rsItem close];
            
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
            
            
            
            FMResultSet *rsTable = [db executeQuery:@"Select TP_Name,TP_Percent, TP_Overide,TP_DineType from TablePlan where TP_ID = ?",[NSNumber numberWithInteger:imgSelectedIndex]];
            
            if ([rsTable next]) {
                selectedTableName = [rsTable stringForColumn:@"TP_Name"];
                [[LibraryAPI sharedInstance] setTableName:selectedTableName];
                tbDineStatus = [rsTable stringForColumn:@"TP_DineType"];
                tbOverrideSVC = [rsTable stringForColumn:@"TP_Overide"];
                [PublicMethod settingServiceTaxPercentWithOverRide:[rsTable stringForColumn:@"TP_Overide"] Percent:[rsTable stringForColumn:@"TP_Percent"]];
                
                [rsTable close];
                
            }
            
            if ([tblWorkMode isEqualToString:@"Main"]) {
                
                FMResultSet *rs = [db executeQuery:@"Select count(*) as dataCount from SalesOrderHdr s1 left join TablePlan tp on"
                                   " s1.SOH_Table = tp.TP_Name where s1.SOH_Table = ? and s1.SOH_Status = ?",selectedTableName,@"New"];
                
                //NSLog(@"%d",[rs intForColumn:@"dataCount"]);
                if ([rs next]) {
                    if ([rs intForColumn:@"dataCount"] > 1)
                    {
                        [timerRefreshTPAmt invalidate];
                        multiSOViewController.tbSelecName = selectedTableName;
                        multiSOViewController.tbSelectNo = imgSelectedIndex;
                        
                        multiSOViewController.popoverPresentationController.sourceView = imgView;
                        multiSOViewController.popoverPresentationController.sourceRect = CGRectMake(imgView.frame.size.width /
                                                                                                    2, imgView.frame.size.height / 2, 1, 1);
                        [self presentViewController:multiSOViewController animated:YES completion:nil];
                        
                        /*
                         [self.popOver presentPopoverFromRect:CGRectMake(imgView.frame.size.width /
                         2, imgView.frame.size.height / 2, 1, 1) inView:imgView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
                         */
                    }
                    else if ([rs intForColumn:@"dataCount"] == 1)
                    {
                        FMResultSet *rs2 = [db executeQuery:@"Select * from SalesOrderHdr s1 left join TablePlan tp on"
                                            " s1.SOH_Table = tp.TP_Name where s1.SOH_Table = ? and s1.SOH_Status = ?",selectedTableName,@"New"];
                        
                        if ([rs2 next]) {
                            
                            [timerRefreshTPAmt invalidate];
                            [[LibraryAPI sharedInstance]setTableNo:imgSelectedIndex];
                            
                            OrderingViewController *orderingViewController = [[OrderingViewController alloc]init];
                            orderingViewController.tbStatus = tbDineStatus;
                            orderingViewController.tableName = [rs2 stringForColumn:@"TP_Name"];
                            orderingViewController.paxData = [rs2 stringForColumn:@"SOH_PaxNo"];
                            orderingViewController.overrideTableSVC = tbOverrideSVC;                        orderingViewController.connectedStatus = @"";
                            //orderingViewController.soNo = soNo;
                            orderingViewController.docType = @"SalesOrder";
                            [[LibraryAPI sharedInstance]setDocNo:[rs2 stringForColumn:@"SOH_DocNo"]];
                            [self.navigationController pushViewController:orderingViewController animated:NO];
                            orderingViewController = nil;
                        }
                        
                        [rs2 close];
                        
                    }
                    else
                    {
                        FMResultSet *rs1 = [db executeQuery:@"Select * from TablePlan where TP_ID = ?",[NSNumber numberWithInt:imgSelectedIndex]];
                        [[LibraryAPI sharedInstance]setTableNo:imgSelectedIndex];
                        //[self removeTableImage];
                        
                        if ([rs1 next]) {
                            activateTbName = [rs1 stringForColumn:@"TP_Name"];
                            [self callOutPaxEntryView];
                            
                            
                        }
                        
                        [rs1 close];
                        
                    }
                    
                }
                [rs close];
                
                
            }
            else
            {
                
                NSArray *allPeers = [[appDelegate.mcManager session] connectedPeers];
                if (allPeers.count <= 0) {
                    [self showAlertView:@"Unable to connect server" title:@"Warning"];
                    return;
                }
                else
                {
                    for (int i = 0; i < allPeers.count; i++)
                    {
                        serverPeer = [allPeers objectAtIndex:i];
                        
                        if ([serverPeer.displayName isEqualToString:@"Server"])
                        {
                            UINavigationItem *n = [self navigationItem];
                            [n setTitle:@"Table Layout [Connected]"];
                            connectStatus = @"Connected";
                            n = nil;
                            break;
                        }
                    }
                }
                
                allPeers = nil;
                
                for (int i = 0; i < tableInfo.count; i++) {
                    if ([[[tableInfo objectAtIndex:i] objectForKey:@"TP_ID"] integerValue] == imgSelectedIndex) {
                        if ([[[tableInfo objectAtIndex:i] objectForKey:@"TP_Count"] integerValue] > 1) {
                            NSLog(@"This is Multiple SO in 1 Table %@",[[tableInfo objectAtIndex:i] objectForKey:@"TP_Count"]);
                            [timerRefreshTPAmt invalidate];
                            multiSOViewController.tbSelecName = selectedTableName;
                            multiSOViewController.tbSelectNo = imgSelectedIndex;
                            
                            //multiSOViewController.modalPresentationStyle = UIModalPresentationPopover;
                            multiSOViewController.popoverPresentationController.sourceView = imgView;
                            multiSOViewController.popoverPresentationController.sourceRect = CGRectMake(imgView.frame.size.width /
                                                                                                        2, imgView.frame.size.height / 2, 1, 1);
                            [self presentViewController:multiSOViewController animated:YES completion:nil];
                            
                            
                            /*
                             [self.popOver presentPopoverFromRect:CGRectMake(imgView.frame.size.width /
                             2, imgView.frame.size.height / 2, 1, 1) inView:imgView permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
                             */
                        }
                        else if ([[[tableInfo objectAtIndex:i] objectForKey:@"TP_Count"] integerValue] == 1)
                        {
                            
                            FMResultSet *rs1 = [db executeQuery:@"Select * from TablePlan where TP_ID = ?",[NSNumber numberWithInt:imgSelectedIndex]];
                            [[LibraryAPI sharedInstance]setTableNo:imgSelectedIndex];
                            
                            if ([rs1 next]) {
                                [timerRefreshTPAmt invalidate];
                                OrderingViewController *orderingViewController = [[OrderingViewController alloc]init];
                                orderingViewController.tableName = [rs1 stringForColumn:@"TP_Name"];
                                orderingViewController.connectedStatus = @"";
                                orderingViewController.tbStatus = tbDineStatus;
                                orderingViewController.overrideTableSVC = tbOverrideSVC;
                                [[LibraryAPI sharedInstance]setDocNo:[[tableInfo objectAtIndex:i] objectForKey:@"SOH_DocNo"]];
                                orderingViewController.docType = @"SalesOrder";
                                [self.navigationController pushViewController:orderingViewController animated:NO];
                                orderingViewController = nil;
                            }
                            
                            [rs1 close];
                            
                        }
                        else
                        {
                            FMResultSet *rs1 = [db executeQuery:@"Select * from TablePlan where TP_ID = ?",[NSNumber numberWithInt:imgSelectedIndex]];
                            [[LibraryAPI sharedInstance]setTableNo:imgSelectedIndex];
                            
                            if ([rs1 next]) {
                                activateTbName = [rs1 stringForColumn:@"TP_Name"];
                                [self callOutPaxEntryView];
                                
                                
                            }
                            
                            [rs1 close];
                        }
                        
                    }
                    
                }
                
            }
        }];
        
        [queue close];
        //[dbTable close];
        
        imgView = nil;
    }
    else
    {
        [self startTransferTableToSelectedTableWithTableIndex:imgSelectedIndex];

    }
    
    
    
}

-(void)checkTablePlanWithSales
{
    dbTable = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTable open]) {
        NSLog(@"Fail To Open");
        return;
    }
    
    [tableArray removeAllObjects];
    
    NSUInteger count = [dbTable intForQuery:@"SELECT COUNT(TP_ID) FROM TablePlan"];
    
    if (count % 4 == 0) {
        count = count / 4;
    }
    else
    {
        count = (count / 4) + 1;
    }
    
    
    FMResultSet *rs = [dbTable executeQuery:@"Select * from TablePlan order by TP_ID"];
    
    
    for (int i = 0; i < count; i++) {
        NSMutableDictionary *item1 = [NSMutableDictionary dictionary];
        for (int j = 1; j <= 4; j++) {
            if ([rs next]) {
                [item1 setObject:[rs stringForColumn:@"TP_ID"] forKey:[NSString stringWithFormat:@"Tb%dID",j]];
                [item1 setObject:[rs stringForColumn:@"TP_Name"] forKey:[NSString stringWithFormat:@"Tb%dName",j]];
            }
            else
            {
                break;
            }
        }
        [tableArray addObject:item1];
        item1 = nil;
        //[item1 removeAllObjects];
    }
    
    [rs close];
    [dbTable close];
    [self.tablePlanTableView reloadData];

}


- (IBAction)goToMore:(id)sender {
    
    if ([selectTablePlanStatus isEqualToString:@"Order"]) {
        [timerRefreshTPAmt invalidate];
        
        [self removeTableImage];
        AdminViewController *adminViewController = [[AdminViewController alloc]init];
        [self.navigationController pushViewController:adminViewController animated:NO];
    }
    else
    {
        [self showAlertView:@"Please cancel transfer mode." title:@"Information"];
    }
    
    /*
    int userRole;
    userRole = [[LibraryAPI sharedInstance]getUserRole];
    if (userRole == 1) {
        
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Alert"
                              message:@"You Have No Permission To Login."
                              delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil, nil];
        [alert show];
    }
    
    */
}

- (IBAction)gotoTableDesign:(id)sender {
    [self removeTableImage];
    DragTablePlanViewController *dragTablePlanViewController = [[DragTablePlanViewController alloc]init];
    //[self presentViewController:dragTablePlanViewController animated:YES completion:nil];
    [self.navigationController pushViewController:dragTablePlanViewController animated:YES];
}

#pragma mark - get setting
-(void)getGstSvgSetting
{
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rsTax = [db executeQuery:@"Select * from GeneralSetting"];
        
        if ([rsTax next]) {
            if ([rsTax intForColumn:@"GS_EnableGST"] == 1) {
                enableGst = @"Yes";
            }
            else
            {
                enableGst = @"No";
            }
            [[LibraryAPI sharedInstance]setEnableGst:[rsTax intForColumn:@"GS_EnableGST"]];
            [[LibraryAPI sharedInstance] setEnableSVG:[rsTax intForColumn:@"GS_EnableSVG"]];
        }
        
        [rsTax close];
        
        
    }];
    
    [queue close];
}


#pragma mark - remove image
-(void)removeTableImage
{
    dbTable = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTable open]) {
        NSLog(@"Failt To Open DB");
        return;
    }
    
    FMResultSet *rs = [dbTable executeQuery:@"Select * from TablePlan order by TP_ID"];
    
    //NSMutableDictionary *item1 = [NSMutableDictionary dictionary];
    while ([rs next]) {
        UIImageView *removeImgView = (UIImageView*) [self.view viewWithTag:[rs intForColumn:@"TP_ID"]];
        
        [removeImgView removeFromSuperview];
        
    }
    [rs close];
    [dbTable close];
}


#pragma mark - delegate method

-(void)selectTableFindBillView
{
    //[self.popOver dismissPopoverAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    BillListingViewController *billListingViewController = [[BillListingViewController alloc] init];
    //billListingViewController.delegate = self;
    //UINavigationController *navi = [[UINavigationController alloc]  initWithRootViewController:transferTableFromViewController];
    
    [billListingViewController setModalPresentationStyle:UIModalPresentationFormSheet];
    [billListingViewController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    [self.navigationController presentViewController:billListingViewController animated:YES completion:nil];
    
}

-(void)selectTableEditedBillView
{
    //[self.popOver dismissPopoverAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    EditBillViewController *editBillViewController = [[EditBillViewController alloc] init];
    editBillViewController.delegate = self;
    [editBillViewController setModalPresentationStyle:UIModalPresentationFormSheet];
    [editBillViewController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    [self.navigationController presentViewController:editBillViewController animated:YES completion:nil];
}

-(void)editBillOnOrderScreenWithTableName:(NSString *)tableName TableNo:(NSInteger)tableNo DineType:(NSString *)dineType OverrideTableSVC:(NSString *)overrideTableSVC PaxNo:(NSString *)paxNo CSDocNo:(NSString *)csDocNo TpServicePercent:(NSString *)tpServicePercent
{
    [self dismissViewControllerAnimated:NO completion:nil];
    
    OrderingViewController *orderingViewController = [[OrderingViewController alloc]init];
    
    [[LibraryAPI sharedInstance]setTableNo:tableNo];
    orderingViewController.tableName = tableName;
    orderingViewController.tbStatus = dineType;
    orderingViewController.overrideTableSVC = overrideTableSVC;
    orderingViewController.connectedStatus = @"";
    orderingViewController.docType = @"CashSales";
    orderingViewController.paxData = paxNo;
    orderingViewController.csDocNo = csDocNo;
    
    [PublicMethod settingServiceTaxPercentWithOverRide:overrideTableSVC Percent:tpServicePercent];
    [[LibraryAPI sharedInstance]setDocNo:@"-"];
    [self.navigationController pushViewController:orderingViewController animated:NO];
    orderingViewController = nil;
}

-(void)askSelectedTableViewRefreshTablePlan
{
    if ([mtMode isEqualToString:@"True"]) {
        timerRefreshTPAmt = [NSTimer scheduledTimerWithTimeInterval:2
                                                             target:self
                                                           selector:@selector(refreshTablePlanAmt)
                                                           userInfo:nil
                                                            repeats:YES];
        [self displayTablePlan];
    }
    else
    {
        [self displayTablePlan];
    }
}

-(void)selectTableAtSelectTableViewWithFromDocNo:(NSString *)fromDocNo FromTableName:(NSString *)fromTableName SelectedOption:(NSString *)selectedOption TransferType:(NSString *)transferType FromTableDineType:(NSString *)fromTableDineType
{
    [self.navigationController dismissViewControllerAnimated:NO completion:nil];
    
    [self enableTransferTableModeWithSOQty:1 TableName:fromTableName SoDocNo:fromDocNo OptionSelected:selectedOption TableDineStatus:fromTableDineType TransferType:transferType];
    
}

-(void)backOrCloseTransferToView
{
    if ([mtMode isEqualToString:@"True"]) {
        
        [self cancelTransferModeWithStatus:@"Cancel"];
        timerRefreshTPAmt = [NSTimer scheduledTimerWithTimeInterval:2
                                                             target:self
                                                           selector:@selector(refreshTablePlanAmt)
                                                           userInfo:nil
                                                            repeats:YES];
        [self displayTablePlan];
    }
    else
    {
        [self displayTablePlan];
    }
    
}

-(void)passBackMultiSelectedSONo:(NSString *)soNo TableName:(NSString *)tableName TableNo:(NSInteger)tableNo PaxNo:(NSString *)paxNo
{
    //[self.popOver dismissPopoverAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    [[LibraryAPI sharedInstance]setTableNo:tableNo];
    
    OrderingViewController *orderingViewController = [[OrderingViewController alloc]init];
    orderingViewController.tableName = tableName;
    orderingViewController.tbStatus = tbDineStatus;
    orderingViewController.overrideTableSVC = tbOverrideSVC;
    orderingViewController.connectedStatus = @"";
    orderingViewController.paxData = paxNo;
    orderingViewController.docType = @"SalesOrder";
    //orderingViewController.soNo = soNo;
    [[LibraryAPI sharedInstance]setDocNo:soNo];
    [self.navigationController pushViewController:orderingViewController animated:NO];
    
    
    
}

-(void)refreshTablePlanAmtWithNotification:(NSNotification *)notification
{
    tableInfo = [notification object];
    __block NSString *tableFlagName;
    dispatch_async(dispatch_get_main_queue(), ^{
        //NSLog(@"%@",@"refresh refresh");
        for (int i = 0; i < tableInfo.count; i++) {
            
            dbTable = [FMDatabase databaseWithPath:dbPath];
            
            if (![dbTable open]) {
                NSLog(@"Failt To Open DB");
                return;
            }
            
            FMResultSet *rs = [dbTable executeQuery:@"Select * from TablePlan where TP_ID = ?",[[tableInfo objectAtIndex:i] objectForKey:@"TP_ID"]];
            
            if ([rs next]) {
                UIImageView *imageView=(UIImageView *)[self.view viewWithTag:[rs intForColumn:@"TP_ID"]];
                
                tableFlagName = [self getBusyTableImgNameWithTableName:[rs stringForColumn:@"TP_ImgName"]];
                
                if (![[[tableInfo objectAtIndex:i] objectForKey:@"TP_Count"] isEqualToString:@"0"]) {
                    if ([[[tableInfo objectAtIndex:i] objectForKey:@"TP_Count"] integerValue] > 1) {
                        existAmtLabel = (UILabel *) [self.view viewWithTag:40000 + [[[tableInfo objectAtIndex:i] objectForKey:@"TP_ID"] integerValue]];
                        
                        existTbName = (UILabel *) [self.view viewWithTag:30000 + [[[tableInfo objectAtIndex:i] objectForKey:@"TP_ID"] integerValue]];
                        
                        existAmtLabel.text = [NSString stringWithFormat:@"# %td",[[[tableInfo objectAtIndex:i] objectForKey:@"TP_Count"] integerValue]];
                        //amtLabel.text = [NSString stringWithFormat:@"# %@",[[array objectAtIndex:i] objectForKey:@"TP_Count"]];
                        //NSLog(@"amt label %@",existAmtLabel.text);
                        existTbName.textColor = [UIColor whiteColor];
                        existAmtLabel.textColor = [UIColor whiteColor];
                        
                        [imageView setImage:[UIImage imageNamed:tableFlagName]];
                        imageView.userInteractionEnabled = YES;
                        imageView.contentMode = UIViewContentModeScaleAspectFit;
                        
                        
                    }
                    else
                    {
                        
                        existAmtLabel = (UILabel *) [self.view viewWithTag:40000 + [[[tableInfo objectAtIndex:i] objectForKey:@"TP_ID"] integerValue]];
                        
                        existTbName = (UILabel *) [self.view viewWithTag:30000 + [[[tableInfo objectAtIndex:i] objectForKey:@"TP_ID"] integerValue]];
                        
                        existAmtLabel.text = [NSString stringWithFormat:@"%0.2f",[[[tableInfo objectAtIndex:i] objectForKey:@"TP_Amt"] doubleValue]];
                        //NSLog(@"terminal %@",[[tableInfo objectAtIndex:i] objectForKey:@"TP_Amt"]);
                        
                        //if ([[[tableInfo objectAtIndex:i] objectForKey:@"TP_Amt"] doubleValue] > 0.00) {
                        if ([[[tableInfo objectAtIndex:i] objectForKey:@"SOH_Index"] isEqualToString:@"null"]) {
                            
                            [imageView setImage:[UIImage imageNamed:[rs stringForColumn:@"TP_ImgName"]]];
                            
                            imageView.userInteractionEnabled = YES;
                            imageView.contentMode = UIViewContentModeScaleAspectFit;
                            existTbName.textColor = [UIColor whiteColor];
                            existAmtLabel.textColor = [UIColor whiteColor];
                        }
                        else
                        {
                            
                            
                            imageView.userInteractionEnabled = YES;
                            imageView.contentMode = UIViewContentModeScaleAspectFit;
                            
                            UIImageView *imageView=(UIImageView *)[self.view viewWithTag:[rs intForColumn:@"TP_ID"]];
                            [imageView setImage:[UIImage imageNamed:tableFlagName]];
                            imageView = nil;
                            existTbName.textColor = [UIColor whiteColor];
                            existAmtLabel.textColor = [UIColor whiteColor];
                        }
                        //existTbName = nil;
                        //existAmtLabel = nil;
                    }
                }
                else
                {
                    existAmtLabel = (UILabel *) [self.view viewWithTag:40000 + [[[tableInfo objectAtIndex:i] objectForKey:@"TP_ID"] integerValue]];
                    
                    existTbName = (UILabel *) [self.view viewWithTag:30000 + [[[tableInfo objectAtIndex:i] objectForKey:@"TP_ID"] integerValue]];
                    
                    existAmtLabel.text = [NSString stringWithFormat:@"%0.2f",[[[tableInfo objectAtIndex:i] objectForKey:@"TP_Amt"] doubleValue]];
                    //NSLog(@"terminal %@",[[tableInfo objectAtIndex:i] objectForKey:@"TP_Amt"]);
                    
                    //if ([[[tableInfo objectAtIndex:i] objectForKey:@"TP_Amt"] doubleValue] > 0.00) {
                    if ([[[tableInfo objectAtIndex:i] objectForKey:@"SOH_Index"] isEqualToString:@"null"]) {
                        
                        [imageView setImage:[UIImage imageNamed:[rs stringForColumn:@"TP_ImgName"]]];
                        
                        
                        imageView.userInteractionEnabled = YES;
                        imageView.contentMode = UIViewContentModeScaleAspectFit;
                        
                        existTbName.textColor = [UIColor whiteColor];
                        existAmtLabel.textColor = [UIColor whiteColor];
                    }
                    else
                    {
                        [imageView setImage:[UIImage imageNamed:tableFlagName]];
                        imageView.userInteractionEnabled = YES;
                        imageView.contentMode = UIViewContentModeScaleAspectFit;
                        
                        existTbName.textColor = [UIColor whiteColor];
                        existAmtLabel.textColor = [UIColor whiteColor];
                    }
                    
                }
                
                if ([[[tableInfo objectAtIndex:i] objectForKey:@"TP_Amt"] doubleValue] > 0.00) {
                }
                imageView = nil;
                
            }
            
            [rs close];
            [dbTable close];
            
        }
        
    });
    
    [KVNProgress dismiss];
}

#pragma mark - scrollview

- (void)scrollViewDidScroll:(UIScrollView *)sender {

}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    
    if (scrollView == self.scrollViewTb) {
        int page = scrollView.contentOffset.x / scrollView.frame.size.width;
        //NSLog(@"%d",page);
        UIButton *btnTbSectionClicked = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        btnTbSectionClicked = (UIButton *)[self.view viewWithTag:[[[sectionArray objectAtIndex:page] objectForKey:@"TsID"] integerValue] + 20000];
        [btnTbSectionClicked sendActionsForControlEvents:UIControlEventTouchDown];
        btnTbSectionClicked = nil;
        
        //NSLog(@"paging no %ld",page);
        
    }
    
}

// At the begin of scroll dragging, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    pageControlUsed = NO;
}

//-----------------------------------------

#pragma mark - delegate from tbsection scroll view
-(void)passTbSectionBackToSelectTableViewWithNo:(int)tbSectionNo SectionName:(NSString *)tbSectionName
{
   // NSLog(@"%d",tbSectionNo);
    
    dbTable = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTable open]) {
        NSLog(@"Failt To Open DB");
        return;
    }
    
    FMResultSet *rs = [dbTable executeQuery:@"Select * from TableSection"];
    
    while ([rs next]) {
        UIView *delImgView = (UIView*) [self.view viewWithTag:[rs intForColumn:@"TS_No"]];
        if ([[rs stringForColumn:@"TS_Name"] isEqualToString:tbSectionName]) {
            
            sectionName = [rs stringForColumn:@"TS_Name"];
            //NSLog(@"%@",sectionName);
            delImgView.hidden = NO;
        }
        else
        {
            delImgView.hidden = YES;
        }
        delImgView = nil;
    }
    
    
}

#pragma mark - alertView

-(void)showAlertView:(NSString *)msg title:(NSString *)title
{
    alertType = @"Normal";
    
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

#pragma mark - section button default click

-(IBAction)btnTbSectionClickWithNo:(id)sender
{

    long xPosition = 0;
    for (int i = 0; i < sectionArray.count; i++) {
        if ([[[sectionArray objectAtIndex:i] objectForKey:@"TsID"] integerValue] + 20000 == [sender tag]) {
            UIButton *btn = (UIButton *)[self.view viewWithTag:[sender tag]];
            
            //[btn setBackgroundImage:[UIImage imageNamed:@"btnSectionBlue"] forState:UIControlStateNormal];
            //[btn setBackgroundColor:[UIColor whiteColor]];
            //btn.titleLabel.textColor = [UIColor blueColor];
            [btn setBackgroundColor:[UIColor whiteColor]];
            //btn.titleLabel.textColor = [UIColor blueColor];
            [btn setTitleColor:[UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0] forState:UIControlStateNormal];
            btn = nil;
            
            if (i == 0) {
                xPosition = 0;
            }
            else
            {
                //xPosition = i * kTbSectionPlanWidth;
                xPosition = i * 1008;
            }
            
            [self.scrollViewTb setContentOffset:CGPointMake(xPosition, 0) animated:YES];
            
        }
        else
        {
            UIButton *btn = (UIButton *)[self.view viewWithTag:[[[sectionArray objectAtIndex:i] objectForKey:@"TsID"] integerValue] + 20000];
            
            //[btn setBackgroundImage:[UIImage imageNamed:@"btnSectionGrey"] forState:UIControlStateNormal];
            [btn setBackgroundColor:[UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0]];
            //btn.titleLabel.textColor = [UIColor lightGrayColor];
            [btn setBackgroundColor:[UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0]];
            [btn setTitleColor:[UIColor colorWithRed:182/255.0 green:203/255.0 blue:226/255.0 alpha:1.0] forState:UIControlStateNormal];
            btn = nil;
        }
    }
}
    
-(void)openOptionPopUpMenu
{
    [[LibraryAPI sharedInstance] setOpenOptionViewName:@"SelectTableView"];
    OptionSelectTableViewController *optionSelectedTableViewController = [[OptionSelectTableViewController alloc]init];
    optionSelectedTableViewController.delegate  =self;
    //optionSelectedTableViewController.optionViewFlag = @"SelectTableView";
    //self.popOver = [[UIPopoverController alloc]initWithContentViewController:optionSelectedTableViewController];
    optionSelectedTableViewController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionDown;
    optionSelectedTableViewController.modalPresentationStyle = UIModalPresentationPopover;
    optionSelectedTableViewController.popoverPresentationController.sourceView = self.fakeView;
    optionSelectedTableViewController.popoverPresentationController.sourceRect = CGRectMake(950, 0, 1, 1);
    
    [self presentViewController:optionSelectedTableViewController animated:YES completion:nil];
    
    //[self.popOver presentPopoverFromRect:CGRectMake(950, 0, 1, 1) inView:self.fakeView permittedArrowDirections:UIPopoverArrowDirectionUp animated:NO];
}

#pragma mark - flytech device event
- (void)onBleConnectionStatusUpdate:(NSString *)addr status:(int)status
{
    if (status == BLE_DISCONNECTED)
    {
        AppUtility.isConnect = NO;
        
        [AppUtility showAlertView:@"Information" message:@"Bluetooth printer has disconnect. Please log out and login to reconnect."];
        
    }
    else if (status == BLE_CONNECTED)
    {
        AppUtility.isConnect = YES;
    }
}

-(NSString *)getBusyTableImgNameWithTableName:(NSString *)name
{
    if ([name isEqualToString:@"Table1"])
    {
        return @"Table_1";
    }
    else if ([name isEqualToString:@"Table2"])
    {
        return @"Table_2";
    }
    else ([name isEqualToString:@"Table3"]);
    {
         return @"Table_3";
    }
}

-(void)callOutPaxEntryView
{
    PaxEntryViewController *paxEntryViewController = [[PaxEntryViewController alloc] init];
   
    paxEntryViewController.delegate  = self;
    paxEntryViewController.requirePaxEntryView = @"SelectTableView";
    [paxEntryViewController setModalPresentationStyle:UIModalPresentationFormSheet];
    [paxEntryViewController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    
    [self.navigationController presentViewController:paxEntryViewController animated:NO completion:nil];
}

-(void)afterKeyInPaxNumberWithPaxNo:(NSString *)paxNo
{
    [self dismissViewControllerAnimated:NO completion:nil];
    [timerRefreshTPAmt invalidate];
    [self getGstSvgSetting];
    OrderingViewController *orderingViewController = [[OrderingViewController alloc]init];
    orderingViewController.tableName = activateTbName;
    orderingViewController.tbStatus = tbDineStatus;
    orderingViewController.overrideTableSVC = tbOverrideSVC;
    orderingViewController.connectedStatus = @"";
    orderingViewController.paxData = paxNo;
    orderingViewController.docType = @"SalesOrder";
    //orderingViewController.soNo = @"-";
    [[LibraryAPI sharedInstance]setDocNo:@"-"];
    [self.navigationController pushViewController:orderingViewController animated:NO];
    orderingViewController = nil;
}

#pragma mark - transfer table

-(void)startTransferTableToSelectedTableWithTableIndex:(NSUInteger)tableIndex
{

    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    //__block NSString *transferTableName;
    //__block int transferTableDineStatus;
    __block BOOL result;
    __block NSUInteger combineSOQty;
    __block NSString *toSalesOrderNo;
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rsTable = [db executeQuery:@"Select TP_Name,TP_Percent, TP_Overide,TP_DineType from TablePlan where TP_ID = ?",[NSNumber numberWithInteger:tableIndex]];
        
        if ([rsTable next]) {
            transferTableName = [rsTable stringForColumn:@"TP_Name"];
            transferTableDineStatus = [rsTable intForColumn:@"TP_DineType"];
            
            if ([transferTableName isEqualToString:[transferTableDict objectForKey:@"FromTableName"]]) {
                [rsTable close];
                [self showAlertView:@"Please select other table" title:@"Warning"];
                return;
            }
            
            [transferTableDict setValue:transferTableName forKey:@"ToTableName"];
            if ([[transferTableDict objectForKey:@"SelectedOption"] isEqualToString:@"TransferTable"]) {
                result = true;
                [rsTable close];
            }
            else
            {
                [rsTable close];
                
                if ([[[LibraryAPI sharedInstance] getWorkMode] isEqualToString:@"Main"])
                {
                    FMResultSet *rsCombine = [db executeQuery:@"Select count(*) as TotalSO, SOH_DocNo from SalesOrderHdr where SOH_Table = ? and SOH_Status = ?",transferTableName,@"New"];
                    
                    if ([rsCombine next]) {
                        if ([rsCombine intForColumn:@"TotalSO"] > 1) {
                            [rsCombine close];
                            combineSOQty = 2;
                            [self showMultipleSOSelectionForCombineTableWithSOQty:0 FromTableName:[transferTableDict objectForKey:@"FromTableName"] SoDocNo:[transferTableDict objectForKey:@"FromDocNo"] OptionSelected:@"CombineTable" ToTableName:transferTableName];
                            
                        }
                        else if([rsCombine intForColumn:@"TotalSO"] == 1)
                        {
                            toSalesOrderNo = [rsCombine stringForColumn:@"SOH_DocNo"];
                            [rsCombine close];
                            combineSOQty = 1;
                            
                        }
                        else
                        {
                            combineSOQty = 0;
                            [rsCombine close];
                        }
                    }
                }
                else
                {
                    NSPredicate *predicate1;
                    predicate1 = [NSPredicate predicateWithFormat:@"TP_Name MATCHES[cd] %@",
                                  transferTableName];
                    
                    NSArray *array = [tableInfo filteredArrayUsingPredicate:predicate1];
                    
                    if (array.count > 0) {
                        if ([[[array objectAtIndex:0] objectForKey:@"TP_Count"] integerValue] > 1) {
                            
                            combineSOQty = 2;
                            
                            [self showMultipleSOSelectionForCombineTableWithSOQty:0 FromTableName:[transferTableDict objectForKey:@"FromTableName"] SoDocNo:[transferTableDict objectForKey:@"FromDocNo"] OptionSelected:@"CombineTable" ToTableName:transferTableName];
                            
                        }
                        else if([[[array objectAtIndex:0] objectForKey:@"TP_Count"] integerValue] == 1)
                        {
                            toSalesOrderNo = [[array objectAtIndex:0] objectForKey:@"SOH_DocNo"];
                            combineSOQty = 1;
                        }
                        else
                        {
                            combineSOQty = 0;
                        }
                    }
                    array = nil;
                    predicate1 = nil;
                    
                }
                
                
            }
            
            
        }
        else
        {
            result = false;
            [rsTable close];
            [self showAlertView:[db lastErrorMessage] title:@"Warning"];
            return;
        }
        
    }];
    [queue close];
    
    if ([[transferTableDict objectForKey:@"SelectedOption"] isEqualToString:@"TransferTable"]) {
        if ([transferTableName isEqualToString:[transferTableDict objectForKey:@"FromTableName"]]) {
            [self showAlertView:@"Please select different table" title:@"Warning"];
        }
        else
        {
            if (result) {
                if ([[[LibraryAPI sharedInstance] getWorkMode] isEqualToString:@"Main"]) {
                    partialSalesOrderArray = [PublicSqliteMethod getTransferSalesOrderDetailWithDbPath:dbPath SalesOrderNo:[transferTableDict objectForKey:@"FromDocNo"]];
                    
                    [self startRecalculateTransferSalesOrderWithTableName:transferTableName DineType:transferTableDineStatus ToSalesOrderNo:@""];
                }
                else
                {
                    [self requestTransferSalesOrderDetail];
                }
            }
        }
    }
    else
    {
        if (combineSOQty == 1) {
            
            [transferTableDict setValue:toSalesOrderNo forKey:@"ToDocNo"];
            
            if ([[[LibraryAPI sharedInstance] getWorkMode] isEqualToString:@"Main"]) {
                [partialSalesOrderArray addObjectsFromArray:[PublicSqliteMethod publicCombineTwoTableWithFromSalesOrder:[transferTableDict objectForKey:@"FromDocNo"] ToSalesOrder:toSalesOrderNo DBPath:dbPath]];
                
                [self startRecalculateTransferSalesOrderWithTableName:[transferTableDict objectForKey:@"FromTableName"] DineType:transferTableDineStatus ToSalesOrderNo:toSalesOrderNo];
            }
            else
            {
                [self requestCombineSalesOrderDetail];
            }
            
        }
        else
        {
            [self showAlertView:@"Please select table with order" title:@"Warning"];
        }
    }
    
}

-(void)requestCombineSalesOrderDetail
{
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [requestServerData removeAllObjects];
    [data setObject:@"Request" forKey:@"Result"];
    [data setObject:[transferTableDict objectForKey:@"SelectedOption"] forKey:@"OptionSelected"];
    [data setObject:@"-" forKey:@"Message"];
    [data setObject:[transferTableDict objectForKey:@"FromTableName"] forKey:@"FromTableName"];
    [data setObject:@"RequestCombineSalesOrderDetail" forKey:@"IM_Flag"];
    
    [data setObject:[transferTableDict objectForKey:@"FromDocNo"] forKey:@"FromSalesOrderNo"];
    [data setObject:[transferTableDict objectForKey:@"ToDocNo"] forKey:@"ToSalesOrderNo"];
    
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
        NSLog(@"Error : %@", [error localizedDescription]);
    }
    
}

-(void)showMultipleSOSelectionForCombineTableWithSOQty:(NSUInteger)soQty FromTableName:(NSString *)fromTableName SoDocNo:(NSString *)soDocNo OptionSelected:(NSString *)optionSelected ToTableName:(NSString *)toTableName
{
    TransferTableToViewController *transferTableToViewController = [[TransferTableToViewController alloc] init];
    transferTableToViewController.delegate = self;
    UINavigationController *navi = [[UINavigationController alloc]  initWithRootViewController:transferTableToViewController];
    transferTableToViewController.fromDocNo = soDocNo;
    transferTableToViewController.fromTableName = fromTableName;
    transferTableToViewController.transferType = @"Direct";
    transferTableToViewController.selectedOption = optionSelected;
    transferTableToViewController.fromTableDineType = tbDineStatus;
    transferTableToViewController.toTableName = toTableName;
    [navi setModalPresentationStyle:UIModalPresentationFormSheet];
    [navi setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    [self.navigationController presentViewController:navi animated:YES completion:nil];
}


-(void)startRecalculateTransferSalesOrderWithTableName:(NSString *)tbName DineType:(NSUInteger)dineType ToSalesOrderNo:(NSString *)toSalesOrderNo
{
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormat = [[LibraryAPI sharedInstance] getDateFormaterhhmmss];
    NSString *dateString = [dateFormat stringFromDate:today];
    
    NSMutableDictionary *settingDict = [NSMutableDictionary dictionary];
    NSMutableArray *recalcTransferSalesArray = [[NSMutableArray alloc] init];
    NSDictionary *totalDict = [NSDictionary dictionary];
    
    settingDict = [PublicSqliteMethod getGeneralnTableSettingWithTableName:tbName dbPath:dbPath];
    
    NSString *itemServeType;
    
    if ([[transferTableDict objectForKey:@"FromTableDineType"] isEqualToString:@"0"] && dineType == 1) {
        itemServeType = @"1";
    }
    else if([[transferTableDict objectForKey:@"FromTableDineType"] isEqualToString:@"1"] && dineType == 0)
    {
        itemServeType = @"0";
    }
    else
    {
        itemServeType = @"-";
    }
    
    [recalcTransferSalesArray addObjectsFromArray:[PublicSqliteMethod recalculateSalesOrderResultWithFromSalesOrderNo:[transferTableDict objectForKey:@"FromDocNo"] SelectedTbName:tbName SelectedDineType:dineType Date:dateString ItemServeTypeFlag:itemServeType OptionSelected:[transferTableDict objectForKey:@"SelectedOption"] ToSalesOrderNo:toSalesOrderNo DBPath:dbPath]];
    
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
    
    if ([TerminalData updateSalesOrderIntoMainWithOrderType:@"sales" sqlitePath:dbPath OrderData:recalcTransferSalesArray OrderDate:dateString DocNo:[transferTableDict objectForKey:@"ToDocNo"]  terminalArray:nil terminalName:@"Main" ToWhichView:@"Transfer" PayType:@"Other" OptionSelected:[transferTableDict objectForKey:@"SelectedOption"] FromSalesOrderNo:[transferTableDict objectForKey:@"FromDocNo"] ])
    {
        
        [self askToReprintKitchenReceipt];
        if ([mtMode isEqualToString:@"True"]) {
            timerRefreshTPAmt = [NSTimer scheduledTimerWithTimeInterval:2
                                                                 target:self
                                                               selector:@selector(refreshTablePlanAmt)
                                                               userInfo:nil
                                                                repeats:YES];
            [self displayTablePlan];
        }
        else
        {
            [self displayTablePlan];
        }
        
        [self cancelTransferModeWithStatus:@"Complete"];
    }
    else
    {
        [self showAlertView:@"Fail to transfer" title:@"Warning"];
        selectTablePlanStatus = @"Order";
        
    }

    recalcTransferSalesArray = nil;
    totalDict = nil;
    
}

-(void)cancelTransferTableMode
{
    
    if ([mtMode isEqualToString:@"True"]) {
        timerRefreshTPAmt = [NSTimer scheduledTimerWithTimeInterval:2
                                                             target:self
                                                           selector:@selector(refreshTablePlanAmt)
                                                           userInfo:nil
                                                            repeats:YES];
        [self displayTablePlan];
    }
    else
    {
        [self displayTablePlan];
    }
    
    [self cancelTransferModeWithStatus:@"Cancel"];
}

-(void)cancelTransferModeWithStatus:(NSString *)status
{
    UINavigationItem *n = [self navigationItem];
    [n setTitle:@"Table Layout"];
    
    selectTablePlanStatus = @"Order";
    
    if ([status isEqualToString:@"Cancel"]) {
        partialSalesOrderArray = nil;
    }
    
    UIBarButtonItem *newBackButton =
    [[UIBarButtonItem alloc] initWithTitle:@"Logout"
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(backToLogInView)];
    self.navigationItem.leftBarButtonItem = newBackButton;
}

-(void)enableTransferTableModeWithSOQty:(NSUInteger)soQty TableName:(NSString *)tb_Name SoDocNo:(NSString *)soDocNo OptionSelected:(NSString *)optionSelected TableDineStatus:(NSString *)dineStatus TransferType:(NSString *)transferType
{
    tbLabel=(UILabel *)[self.view viewWithTag:[[LibraryAPI sharedInstance] getTableNo]+30000];
    tbLabel.textColor = [UIColor redColor];
    
    amtLabel=(UILabel *)[self.view viewWithTag:[[LibraryAPI sharedInstance] getTableNo]+40000];
    amtLabel.textColor = [UIColor redColor];

    
    UINavigationItem *n = [self navigationItem];
    if ([optionSelected isEqualToString:@"TransferTable"]) {
        [n setTitle:@"Click table to transfer"];
    }
    else
    {
        [n setTitle:@"Select table to combine"];
    }
    
    UIBarButtonItem *cancelButton =
    [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(cancelTransferTableMode)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    partialSalesOrderArray = [[NSMutableArray alloc] init];
    selectTablePlanStatus = @"Transfer";
    [transferTableDict setObject:soDocNo forKey:@"FromDocNo"];
    [transferTableDict setObject:tb_Name forKey:@"FromTableName"];
    [transferTableDict setObject:transferType forKey:@"TransferType"];
    [transferTableDict setObject:optionSelected forKey:@"SelectedOption"];
    [transferTableDict setObject:dineStatus forKey:@"FromTableDineType"];
    [transferTableDict setObject:soDocNo forKey:@"ToDocNo"];
    [transferTableDict setObject:tb_Name forKey:@"ToTableName"];
}

#pragma mark data transfer

-(void)requestTransferSalesOrderDetail
{
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [requestServerData removeAllObjects];
    [data setObject:@"Request" forKey:@"Result"];
    [data setObject:[transferTableDict objectForKey:@"FromDocNo"] forKey:@"SoNo"];
    [data setObject:[transferTableDict objectForKey:@"FromTableName"] forKey:@"TbName"];
    [data setObject:[transferTableDict objectForKey:@"FromTableDineType"] forKey:@"DineType"];
    [data setObject:@"-" forKey:@"Message"];
    [data setObject:@"RequestTransferSalesOrderDetail" forKey:@"IM_Flag"];
    
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


-(void)getTransferSalesOrderDetailResultWithNotification:(NSNotification *)notification
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        partialSalesOrderArray = [notification object];
        
        if (partialSalesOrderArray.count > 0) {
            [self requestRecalculateTransferSalesOrderWithDineType:transferTableDineStatus TableName:[transferTableDict objectForKey:@"ToTableName"]];
        }
        else
        {
            [self showAlertView:@"Empty sales order" title:@"Warning"];
        }
        
    });
    
}

-(void)getCombineSalesOrderDetailResultWithNotification:(NSNotification *)notification
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        partialSalesOrderArray = [notification object];
        
        if (partialSalesOrderArray.count > 0) {
            //[self requestRecalculateSalesOrder];
            [self requestRecalculateTransferSalesOrderWithDineType:[[transferTableDict objectForKey:@"FromTableDineType"] integerValue] TableName:[transferTableDict objectForKey:@"FromTableName"]];
        }
        else
        {
            [self showAlertView:@"Empty sales order" title:@"Warning"];
        }
        
    });
    
}


-(void)requestRecalculateTransferSalesOrderWithDineType:(int)dineType TableName:(NSString *)tbName
{
    
    NSString *itemServeType;
    
    if ([[transferTableDict objectForKey:@"FromTableDineType"] isEqualToString:@"0"] && dineType == 1) {
        itemServeType = @"1";
    }
    else if([[transferTableDict objectForKey:@"FromTableDineType"] isEqualToString:@"1"] && dineType == 0)
    {
        itemServeType = @"0";
    }
    else
    {
        itemServeType = @"-";
    }
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [requestServerData removeAllObjects];
    [data setObject:@"Request" forKey:@"Result"];
    [data setObject:[transferTableDict objectForKey:@"FromDocNo"] forKey:@"SoNo"];
    [data setObject:tbName forKey:@"TbName"];
    [data setObject:[NSString stringWithFormat:@"%d",dineType] forKey:@"DineType"];
    [data setObject:@"-" forKey:@"Message"];
    [data setObject:@"RequestRecalcSaleSOrder" forKey:@"IM_Flag"];
    [data setObject:itemServeType forKey:@"ServeType"];
    [data setObject:[transferTableDict objectForKey:@"SelectedOption"] forKey:@"OptionSelected"];
    [data setObject:[transferTableDict objectForKey:@"ToDocNo"] forKey:@"ToSalesOrderNo"];
    
    
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

-(void)getRecalculateTableplanTransferTableResultWithNotification:(NSNotification *)notification
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSArray *serverReturnRecalcSoNoResult;
        
        serverReturnRecalcSoNoResult = [notification object];
        
        NSString *result = [[serverReturnRecalcSoNoResult objectAtIndex:0] objectForKey:@"Result"];
        //[self showAlertView:result title:@"Warning"];
        if ([result isEqualToString:@"True"])
        {
            [self askToReprintKitchenReceipt];
            [self cancelTransferModeWithStatus:@"Complete"];
            timerRefreshTPAmt = [NSTimer scheduledTimerWithTimeInterval:2
                                                                 target:self
                                                               selector:@selector(refreshTablePlanAmt)
                                                               userInfo:nil
                                                                repeats:YES];
            [self displayTablePlan];
        }
        else
        {
            [self showAlertView:@"Fail to send to server" title:@"Warning"];
        }
        
        
        
        //[self askForReprint];
        serverReturnRecalcSoNoResult = nil;
    });
    
}

-(void)askToReprintKitchenReceipt
{
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rsPrinter = [db executeQuery:@"Select * from Printer where P_Type = ?",@"Kitchen"];
        
        if ([rsPrinter next]) {
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"To Kitchen"
                                         message:@"Done. Send to kitchen ?"
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* yesButton = [UIAlertAction
                                        actionWithTitle:@"OK"
                                        style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * action) {
                                            
                                            [PublicSqliteMethod askForReprintKitchenReceiptWithDBPath:dbPath SalesOrderArray:partialSalesOrderArray FromTable:[transferTableDict objectForKey:@"FromTableName"] ToTable:transferTableName SelectedOption:[transferTableDict objectForKey:@"SelectedOption"]];
                                            
                                            partialSalesOrderArray = nil;
                                            
                                        }];
            
            UIAlertAction* noButton = [UIAlertAction
                                       actionWithTitle:@"Cancel"
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction * action) {
                                           //[self showAlertView:@"Complete transfer" title:@"Warning"];
                                           
                                           partialSalesOrderArray = nil;
                                       }];
            
            [alert addAction:yesButton];
            [alert addAction:noButton];
            
            [self presentViewController:alert animated:NO completion:nil];
            alert = nil;

        }
        else
        {
            
        }
        
        [rsPrinter close];
    }];
    
    [queue close];
    
}

#pragma mark - transfer table to delegate
-(void)combineTwoTableWithFromSalesOrder:(NSString *)fromSalesOrder ToSalesOrder:(NSString *)toSalesOrder
{
    [transferTableDict setValue:toSalesOrder forKey:@"ToDocNo"];
    
    if ([[[LibraryAPI sharedInstance]getWorkMode] isEqualToString:@"Main"]) {
        [partialSalesOrderArray addObjectsFromArray:[PublicSqliteMethod publicCombineTwoTableWithFromSalesOrder:fromSalesOrder ToSalesOrder:toSalesOrder DBPath:dbPath]];
        
        [self startRecalculateTransferSalesOrderWithTableName:[transferTableDict objectForKey:@"FromTableName"] DineType:[[transferTableDict objectForKey:@"FromTableDineType"] integerValue] ToSalesOrderNo:toSalesOrder];
    }
    else
    {
        
        [self requestCombineSalesOrderDetail];
    }
    
    
}


#pragma mark - alertview response
- (void)selectTableAlertControlSelection
{
    if ([alertType isEqualToString:@"Logout"]) {
        //if (buttonIndex == 0) {
            [self.navigationController popViewControllerAnimated:NO];
        //}
    }
}
@end
