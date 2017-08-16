//
//  DragTablePlanViewController.m
//  IpadOrder
//
//  Created by IRS on 7/20/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "DragTablePlanViewController.h"
#import "ImageToDrag.h"
#import <FMDB.h>
#import "LibraryAPI.h"
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

//static NSUInteger kNumberOfPages = 1;
static NSUInteger kTbSectionPlanWidth = 1008;
@interface DragTablePlanViewController ()
{

    UIImageView *img;
    UILabel  *tbLabel;
    int labelTag;
    int imgTag;
    long imgSelectedIndex;
    NSString *tbName;
    
    FMDatabase *dbTableDesign;
    NSString *dbPath;
    NSString *flag;
    //NSString *userAction;
    
    float tableX, tableY, tableScale, tableRotate;
    
    NSMutableArray *tbImgNameArray;
    NSArray *tbFilterResultForImgArray;
    NSMutableDictionary *tbImgNameDic;
    int sectionIndex;
    NSString *sectionName;
    
    NSString *tbName2;
    
    BOOL pageControlUsed;
    NSString *imgFileName;
    NSString *alertType;
    
    NSMutableArray *designSectionArray;
    //NSMutableArray *newButtons;
    NSMutableDictionary *designSectionDic;
    UIView *viewDragTb;
    
}
//@property (nonatomic, strong)UIPopoverController *popOverTable;
@end

@implementation DragTablePlanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self.navigationController.navigationBar.hidden = NO;
    dbPath = [[LibraryAPI sharedInstance]getDbPath];
    UINavigationItem *n = [self navigationItem];
    [n setTitle:@"Edit Table Plan"];
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    
    UIBarButtonItem *btnBackTableDesign = [[UIBarButtonItem alloc]initWithTitle:@"< Back" style:UIBarButtonItemStylePlain target:self action:@selector(btnClickBackTableDesign)];
    self.navigationItem.leftBarButtonItem = btnBackTableDesign;
    
    UIBarButtonItem *btnSaveTableDesign = [[UIBarButtonItem alloc]initWithTitle:@" Save" style:UIBarButtonItemStylePlain target:self action:@selector(btnSaveTablePlan:)];
    
    UIBarButtonItem *btnAddTableDesign = [[UIBarButtonItem alloc]initWithTitle:@"Add Table " style:UIBarButtonItemStylePlain target:self action:@selector(addTable:)];
    
    [btnAddTableDesign setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"Helvetica-Bold" size:18.0],NSFontAttributeName,[UIColor whiteColor],NSForegroundColorAttributeName, nil] forState:UIControlStateNormal];
    
    [btnSaveTableDesign setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"Helvetica-Bold" size:18.0],NSFontAttributeName,[UIColor whiteColor],NSForegroundColorAttributeName, nil] forState:UIControlStateNormal];
    //UIBarButtonItem *btnSpaceTableDesign = [[UIBarButtonItem alloc]initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:nil];
    
    NSArray *tempArray2= [[NSArray alloc] initWithObjects:btnSaveTableDesign,btnAddTableDesign,nil];
    self.navigationItem.rightBarButtonItems=tempArray2;
    
    /*
    UIGraphicsBeginImageContext(self.view.frame.size);
    [[UIImage imageNamed:@"IO_Background1024"] drawInRect:self.view.bounds];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    */
    self.view.backgroundColor = [UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0];
    
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    //self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0];
    
    flag = @"New";
    //[self.btnAddTable addTarget:self action:@selector(addTable:) forControlEvents:UIControlEventTouchUpInside];
    
    /*
    NSMutableArray *controllers = [[NSMutableArray alloc] init];
    viewControllers = [[NSMutableArray alloc]init];
    for (unsigned i = 0; i < kNumberOfPages; i++) {
        [controllers addObject:[NSNull null]];
    }
    viewControllers = controllers;
    
    self.scrollDesignTablePlan.pagingEnabled = YES;
    self.scrollDesignTablePlan.contentSize = CGSizeMake(self.scrollDesignTablePlan.frame.size.width * kNumberOfPages, self.scrollDesignTablePlan.frame.size.height);
    self.scrollDesignTablePlan.showsHorizontalScrollIndicator = NO;
    self.scrollDesignTablePlan.showsVerticalScrollIndicator = NO;
    self.scrollDesignTablePlan.scrollsToTop = NO;
    self.scrollDesignTablePlan.delegate = self;
     */
    
    //self.scrollSegmentView.buttons = @[@"Section 1"];
    tbImgNameArray = [[NSMutableArray alloc]init];
    designSectionArray = [[NSMutableArray alloc]init];
    self.scrollDesignViewDragTbPlan.delegate = self;
    self.scrollDesignBtnTbSection.delegate  =self;
    
    [self createUiView];
    
    [self displayTablePlan];
    
    //[self loadScrollViewWithPage:0];
    //[self loadScrollViewWithPage:1];
    
    // Do any additional setup after loading the view from its nib.
}


#pragma mark - create uiview

- (void)createUiView {
    
    __block int i = 0;
    __block int x = 0;
    __block int y = 0;
    [designSectionArray removeAllObjects];
    [designSectionDic removeAllObjects];
    
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
            
            frameSectionBtn.origin.x = self.scrollDesignBtnTbSection.frame.size.width * j;
            frameSectionBtn.origin.y = 0;
            frameSectionBtn.size = self.scrollDesignBtnTbSection.frame.size;
            viewBtnSection = [[UIView alloc] initWithFrame:frameSectionBtn];
        }
        
        [rsTbSectionCount close];
        
        FMResultSet *rsTbSectionPlan = [db executeQuery:@"Select * from TableSection order by TS_No"];
        
        while ([rsTbSectionPlan next]) {
            
            designSectionDic = [NSMutableDictionary dictionary];
            
            [designSectionDic setObject:[rsTbSectionPlan stringForColumn:@"TS_No"] forKey:@"TsNo"];
            [designSectionDic setObject:[rsTbSectionPlan stringForColumn:@"TS_ID"] forKey:@"TsID"];
            [designSectionDic setObject:[rsTbSectionPlan stringForColumn:@"TS_Name"] forKey:@"TsName"];
            //[newButtons addObject:[rsSection stringForColumn:@"TS_Name"]];
            
            [designSectionArray addObject:designSectionDic];
            
            CGRect frame;
            
            if (i == 0) {
                NSLog(@"xxx : %f",self.scrollDesignViewDragTbPlan.frame.origin.x);
                frame.origin.x = 0 ;
            }
            else
            {
                //NSLog(@"width : %f",self.scrollViewTb.frame.size.width * i);
                frame.origin.x = ((self.scrollDesignViewDragTbPlan.frame.size.width) * i);
            }
            
            frame.origin.y = 0;
            frame.size = self.scrollDesignViewDragTbPlan.frame.size;
            
            self.scrollDesignViewDragTbPlan.pagingEnabled = YES;
            //NSLog(@"view.frame:%@", NSStringFromCGRect(frame));
            
            viewDragTb = [[UIView alloc]initWithFrame:frame];
            viewDragTb.tag = [rsTbSectionPlan intForColumn:@"TS_No"];
            viewDragTb.backgroundColor = [UIColor whiteColor];
            /*
            UIImageView *imgBackGround = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tbPlanBase"]];
            [viewDragTb addSubview:imgBackGround];
            
            imgBackGround = nil;
            */
            //viewDragTb.backgroundColor = [UIColor grayColor];
            [self.scrollDesignViewDragTbPlan addSubview:viewDragTb];
            
            
            //section button part
            self.scrollDesignBtnTbSection.pagingEnabled = true;
            
            UIButton *btnSection = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            btnSection.frame = CGRectMake(x, y, 237.0, 56.0);
            [btnSection setTitle:[rsTbSectionPlan stringForColumn:@"TS_Name"] forState:UIControlStateNormal];
            [btnSection setTag:[rsTbSectionPlan intForColumn:@"TS_ID"] + 20000];
            //[btnSection setTitleColor:[UIColor blueColor] forState:UIControlStateSelected];
            [btnSection setTitleColor:[UIColor colorWithRed:182/255.0 green:203/255.0 blue:226/255.0 alpha:1.0] forState:UIControlStateNormal];
            [[btnSection titleLabel] setFont:[UIFont boldSystemFontOfSize:18]];
            [btnSection addTarget:self action:@selector(btnDesignTbSectionClickWithNo:) forControlEvents:UIControlEventTouchDown];
            
            [btnSection setBackgroundColor:[UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0]];
            [btnSection setUserInteractionEnabled:YES];
            [viewBtnSection addSubview:btnSection];
            if (i == 0) {
                sectionName = [rsTbSectionPlan stringForColumn:@"TS_Name"];
                sectionIndex = [[rsTbSectionPlan stringForColumn:@"TS_No"] integerValue];
                [btnSection setBackgroundColor:[UIColor whiteColor]];
                [btnSection setTitleColor:[UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0] forState:UIControlStateNormal];
            }
            
            btnSection = nil;
            //calc next button x (8 is space between button, 105 is button width)
            x = x + 237 + 0;
            
            
            [self.scrollDesignBtnTbSection addSubview:viewBtnSection];
            
            i++;
            
        }
        
        [rsTbSectionPlan close];
        
        
        //tbsection btn part
        
    }];
    
    [queue close];
    
    self.scrollDesignViewDragTbPlan.contentSize = CGSizeMake(self.scrollDesignViewDragTbPlan.frame.size.width * i, self.scrollDesignViewDragTbPlan.frame.size.height);
    //self.scrollTbSection.contentSize = CGSizeMake(self.scrollTbSection.frame.size.width * i, self.scrollTbSection.frame.size.height);
    designSectionDic = nil;
}

-(void)btnClickBackTableDesign
{
    if ([flag isEqualToString:@"Edit"]) {
        alertType = @"BackAlert";
        
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Warning"
                                     message:@"Do you want to Save Current Design ?"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* cancelButton = [UIAlertAction
                                    actionWithTitle:@"Cancel"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
                                        //[self alertActionSelection];
                                    }];
        
        UIAlertAction* yesButton = [UIAlertAction
                                    actionWithTitle:@"Yes"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
                                        //[self alertActionSelection];
                                        [self btnSaveTablePlan:alertType];
                                    }];
        
        UIAlertAction* noButton = [UIAlertAction
                                   actionWithTitle:@"No"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {
                                       //Handle no, thanks button
                                       [self deleteUnSavedTable];
                                   }];
        
        [alert addAction:cancelButton];
        [alert addAction:yesButton];
        [alert addAction:noButton];
        
        [self presentViewController:alert animated:YES completion:nil];
        alert = nil;
        /*
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Alert"
                              message:@"Are you want to Save Current Design ?"
                              delegate:self
                              cancelButtonTitle:@"Cancel"
                              otherButtonTitles:@"Yes",@"No", nil];
        [alert show];
         */
    }
    else
    {
        [self.navigationController popViewControllerAnimated:NO];
    }

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)clickImage:(id)sender
{
 
    NSString *tableName;
    NSString * tablePercent;
    NSString *tableImgName;
    NSArray *selectedImgName;
    int tableDineType;
    float tableAngle;
    int tableOveride;
    dbTableDesign = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTableDesign open]) {
        NSLog(@"Failt To Open DB");
        return;
    }
    
    
    
    UITapGestureRecognizer *gesture = (UITapGestureRecognizer *)sender;
    
    FMResultSet *rsTable = [dbTableDesign executeQuery:@"Select * from TablePlan where TP_ID = ?", [NSNumber numberWithInt:gesture.view.tag]];
    
    if ([rsTable next]) {
        tableName = [rsTable stringForColumn:@"TP_Name"];
        tablePercent = [rsTable stringForColumn:@"TP_Percent"];
        tableOveride = [rsTable intForColumn:@"TP_Overide"];
        tableDineType = [rsTable intForColumn:@"TP_DineType"];
        imgTag = [rsTable intForColumn:@"TP_ID"];
        //tableAngle = [rsTable doubleForColumn:@"TP_RotateAngle"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ImgID MATCHES[cd] %@",
                                  [NSString stringWithFormat:@"%d",imgTag]];
        
        selectedImgName = [tbImgNameArray filteredArrayUsingPredicate:predicate];
    }
    
    tableImgName = [[selectedImgName objectAtIndex:0] objectForKey:@"ImgName"];
    selectedImgName = nil;
    [rsTable close];
    [dbTableDesign close];
    //gesture.
    //CGPoint tapPoint = [sender locationInView:self.view];
    
    UIImageView *imgView = (UIImageView*) [self.view viewWithTag:gesture.view.tag];
    imgSelectedIndex = gesture.view.tag;
    DelTablePopUpViewController *delTablePopUpViewController = [[DelTablePopUpViewController alloc]init];
    delTablePopUpViewController.delegate = self;
    delTablePopUpViewController.tbName = tableName;
    delTablePopUpViewController.tbSelectedImgName = tableImgName;
    delTablePopUpViewController.tbOveride = tableOveride;
    delTablePopUpViewController.tbAngle = tableAngle;
    delTablePopUpViewController.tbDineType = tableDineType;
    if ([tablePercent length] == 0) {
        delTablePopUpViewController.tbPercent = @"";
    }
    else
    {
        delTablePopUpViewController.tbPercent = tablePercent;
    }
    
    //self.popOverTable = [[UIPopoverController alloc]initWithContentViewController:delTablePopUpViewController];
    delTablePopUpViewController.modalPresentationStyle = UIModalPresentationPopover;
    delTablePopUpViewController.popoverPresentationController.sourceView = imgView;
    delTablePopUpViewController.popoverPresentationController.sourceRect = CGRectMake(128/2, 128/2, 1, 1);
    
    [self presentViewController:delTablePopUpViewController animated:YES completion:nil];
    
    
    //[self.popOverTable presentPopoverFromRect:CGRectMake(128/2, 128/2, 1, 1) inView:imgView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    
    imgView = nil;
    
}




- (void)displayTablePlan {
    
    dbTableDesign = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTableDesign open]) {
        NSLog(@"Failt To Open DB");
        return;
    }
    
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        int j = 0;
        FMResultSet *rsSection = [dbTableDesign executeQuery:@"Select * from TableSection order by TS_No"];
        while ([rsSection next]) {
            
            //[newButtons addObject:[rsSection stringForColumn:@"TS_Name"]];
            /*
            UIView *sectionView = [[UIView alloc]initWithFrame:CGRectMake(8, 122, 1008, 628)];
            sectionView.tag = [rsSection intForColumn:@"TS_No"];
            //sectionView.backgroundColor = [UIColor grayColor];
            
            sectionView.backgroundColor = [UIColor clearColor];
            
            [self.view addSubview:sectionView];
             */
            
            FMResultSet *rs = [dbTableDesign executeQuery:@"Select * from tableplan where TP_Section = ?",[rsSection stringForColumn:@"TS_Name"]];
            
            while ([rs next]) {
                
                tbImgNameDic = [NSMutableDictionary dictionary];
                
                [tbImgNameDic setObject:[rs stringForColumn:@"TP_ID"] forKey:@"ImgID"];
                [tbImgNameDic setObject:[rs stringForColumn:@"TP_ImgName"] forKey:@"ImgName"];
                [tbImgNameDic setObject:[rs stringForColumn:@"TP_Name"] forKey:@"TableName"];
                [tbImgNameDic setObject:@"Saved" forKey:@"TableStatus"];
                [tbImgNameDic setObject:[rs stringForColumn:@"TP_DineType"] forKey:@"TableDineType"];
                
                [tbImgNameArray addObject:tbImgNameDic];
                
                tableRotate = [rs doubleForColumn:@"TP_Rotate"];
                tableScale = [rs doubleForColumn:@"TP_Scale"];
                tableX = [rs doubleForColumn:@"TP_Xis"];
                tableY = [rs doubleForColumn:@"TP_Yis"];
                tbName = [rs stringForColumn:@"TP_Name"];
                
                UIImageView *newImg = [[UIImageView alloc]initWithImage:[UIImage imageNamed:[rs stringForColumn:@"TP_ImgName"]]];
                newImg.tag = [rs intForColumn:@"TP_ID"];
                newImg.contentMode = UIViewContentModeScaleAspectFit;
                newImg.userInteractionEnabled = YES;
                
                if ([[rs stringForColumn:@"TP_ImgName"] isEqualToString:@"Table1"]) {
                    CGRect imgFrame = newImg.frame;
                    
                    imgFrame.size.width = 150;
                    imgFrame.size.height = 178;
                    newImg.frame = imgFrame;
                    tbLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 65, 145, 40)];
                }
                else if ([[rs stringForColumn:@"TP_ImgName"] isEqualToString:@"Table2"]) {
                    CGRect imgFrame = newImg.frame;
                    
                    imgFrame.size.width = 200;
                    imgFrame.size.height = 176;
                    newImg.frame = imgFrame;
                    tbLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 65, 190, 40)];
                }
                else if ([[rs stringForColumn:@"TP_ImgName"] isEqualToString:@"Table3"]) {
                    CGRect imgFrame = newImg.frame;
                    
                    imgFrame.size.width = 200;
                    imgFrame.size.height = 181;
                    newImg.frame = imgFrame;
                    tbLabel = [[UILabel alloc]initWithFrame:CGRectMake(8, 65, 180, 40)];
                }
                
                CGAffineTransform transform = newImg.transform;
                transform = CGAffineTransformScale(transform, tableScale, tableScale);
                
                [newImg setTransform:transform];
                
                UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(clickImage:)];
                //tapGes.delegate = self;
                tapGes.numberOfTapsRequired = 1;
                [newImg addGestureRecognizer:tapGes];
                
                UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handlePan:)];
                //panGestureRecognizer.delegate = self;
                [newImg addGestureRecognizer:panGestureRecognizer];
                
                
                UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc]
                                                                    initWithTarget:self
                                                                    action:@selector(handlePinch:)];
                [newImg addGestureRecognizer:pinchGestureRecognizer];
                
                newImg.center = CGPointMake(tableX, tableY);
                
                tbLabel.tag = [rs intForColumn:@"TP_ID"] + 500;
                [tbLabel setFont:[UIFont boldSystemFontOfSize:20]];
                tbLabel.textAlignment = NSTextAlignmentCenter;
                tbLabel.text = tbName;
                tbLabel.textColor = [UIColor whiteColor];
                //[tbLabel setFont:[UIFont boldSystemFontOfSize:25]];
                [newImg addSubview:tbLabel];
                
                UIView *insertView = [[UIView alloc]init];
                insertView = (UIView *)[self.view viewWithTag:[rsSection intForColumn:@"TS_No"]];
                //NSLog(@"img:%@", NSStringFromCGRect(newImg.frame));
                //NSLog(@"insert view.frame:%@", NSStringFromCGRect(insertView.frame));
                [insertView addSubview:newImg];
                insertView = nil;
                j++;
                //[self.tablePlanFloor addSubview:newImg];
            }
            
            [rs close];
            
            
        }
        [rsSection close];
    }];
    
    
    
    //self.scrollSegmentView.buttons = newButtons;
    // 20000 because yascrollsegment component tag duplicate with image tag so change its tag no
    //self.scrollSegmentView.selectedIndex = 20000;
    
    tbImgNameDic = nil;
    [dbTableDesign close];
    
    //flag = @"Edit";
    
    
}

#pragma mark - scrollview
/*
- (void)loadScrollViewWithPage:(int)page{
    if (page < 0) return;
    if (page >= kNumberOfPages) return;
    
    // replace the placeholder if necessary
    
    TbSectionViewController *controller = [viewControllers objectAtIndex:page];
    
    if ((NSNull *)controller == [NSNull null]) {
        
        controller = [[TbSectionViewController alloc] initWithPageNumber:page];
        controller.delegate = self;
        [viewControllers replaceObjectAtIndex:page withObject:controller];
        //[controller release];
        //controller = nil;
    }
    
    // add the controller's view to the scroll view
    
    if (nil == controller.view.superview) {
        [controller.view removeFromSuperview];
        CGRect frame = self.scrollDesignTablePlan.frame;
        frame.origin.x = frame.size.width * page;
        frame.origin.y = 0;
        controller.view.frame = frame;
        [self.scrollDesignTablePlan addSubview:controller.view];
    }
}
 */

- (void)scrollViewDidScroll:(UIScrollView *)sender {
    
}

// At the begin of scroll dragging, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    pageControlUsed = NO;
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    
    if (scrollView == self.scrollDesignViewDragTbPlan) {
        int page = scrollView.contentOffset.x / scrollView.frame.size.width;
        //NSLog(@"%d",page);
        UIButton *btnTbSectionClicked = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        btnTbSectionClicked = (UIButton *)[self.view viewWithTag:[[[designSectionArray objectAtIndex:page] objectForKey:@"TsID"] integerValue] + 20000];
        [btnTbSectionClicked sendActionsForControlEvents:UIControlEventTouchDown];
        btnTbSectionClicked = nil;
        
    }
    
}

//-----------------------------------------

//#pragma mark - delegate from tbsection scroll view
/*
-(void)passTbSectionBackToSelectTableViewWithNo:(int)tbSectionNo SectionName:(NSString *)tbSectionName
{
    // NSLog(@"%d",tbSectionNo);
    
    dbTableDesign = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTableDesign open]) {
        NSLog(@"Failt To Open DB");
        return;
    }
    
    FMResultSet *rs = [dbTableDesign executeQuery:@"Select * from TableSection"];
    
    while ([rs next]) {
        UIView *delImgView = (UIView*) [self.view viewWithTag:[rs intForColumn:@"TS_No"]];
        if ([[rs stringForColumn:@"TS_Name"] isEqualToString:tbSectionName]) {
            sectionIndex = [rs intForColumn:@"Ts_No"];
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
 */
//---------------------------------------------------------------

#pragma mark - uipopover delegate
/*
-(BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
    return NO;
}
*/
-(BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
    return NO;
}

#pragma mark - sqlite method
- (IBAction)delete:(id)sender {
   
        dbTableDesign = [FMDatabase databaseWithPath:dbPath];
        
        if (![dbTableDesign open]) {
            NSLog(@"Failt To Open DB");
            return;
        }
        
        [dbTableDesign executeUpdate:@"delete from TablePlan"];
        [dbTableDesign executeUpdate:@"delete from TempTablePlan"];
    
    
        [dbTableDesign close];
    
}


- (void)addTable:(id)sender {
    InsertTablePopUpViewController *insertTablePopUpViewController = [[InsertTablePopUpViewController alloc]init];
    insertTablePopUpViewController.delegate = self;
    insertTablePopUpViewController.modalPresentationStyle = UIModalPresentationPopover;
    
    UIPopoverPresentationController *popOverPresentationController = [insertTablePopUpViewController popoverPresentationController];
    popOverPresentationController.delegate = self;
    popOverPresentationController.permittedArrowDirections = 0;
    
    popOverPresentationController.sourceView = self.view;
    popOverPresentationController.sourceRect = CGRectMake(self.view.frame.size.width/2, self.view.frame.size.height/2, 1, 1);
    
    [self presentViewController:insertTablePopUpViewController animated:YES completion:nil];
    
    //[self.popOverTable presentPopoverFromRect:CGRectMake(self.view.frame.size.width/2, self.view.frame.size.height/2, 1, 1) inView:self.view permittedArrowDirections:0 animated:YES];
    
}

#pragma mark - delegate
-(void)saveTableName:(NSString *)insName Percent:(NSString *)percent Overide:(int)overide ImgName:(NSString *)imgName DineType:(int)dineType
{
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    dbTableDesign = [FMDatabase databaseWithPath:dbPath];
    BOOL duplicateTable;
    if (![dbTableDesign open]) {
        NSLog(@"Failt To Open DB");
        return;
    }
    
    FMResultSet *checkRs = [dbTableDesign executeQuery:@"Select * from Tableplan where TP_Name = ?", insName];
    
    if ([checkRs next]) {
        duplicateTable = YES;
        [self showAlertView:@"Table name duplicate" title:@"Warning"];
        //return;
    }
    else
    {
        duplicateTable = NO;
        
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
        
        [queue inDatabase:^(FMDatabase *db) {
            
            BOOL dbNoError = [db executeUpdate:@"Insert into TablePlan ("
                              "TP_Name, TP_Description,TP_Scale, TP_Rotate, TP_Xis, TP_Yis,TP_Section,TP_Percent,TP_Overide, TP_ImgName, TP_DineType) values ("
                              "?,?,?,?,?,?,?,?,?,?,?)",insName, @"-",[NSNumber numberWithFloat:1.00],[NSNumber numberWithFloat:0.00],[NSNumber numberWithFloat:0.00],[NSNumber numberWithFloat:0.00],sectionName,percent,[NSNumber numberWithInt:overide],imgName, [NSNumber numberWithInt:dineType]];
            
            
            
            if (dbNoError) {
                
                FMResultSet *rs = [db executeQuery:@"Select * from TablePlan where TP_Name = ?",insName];
                if ([rs next]) {
                    
                    tbImgNameDic = [NSMutableDictionary dictionary];
                    
                    [tbImgNameDic setObject:[rs stringForColumn:@"TP_ID"] forKey:@"ImgID"];
                    [tbImgNameDic setObject:[rs stringForColumn:@"TP_ImgName"] forKey:@"ImgName"];
                    [tbImgNameDic setObject:[rs stringForColumn:@"TP_Name"] forKey:@"TableName"];
                    [tbImgNameDic setObject:@"New" forKey:@"TableStatus"];
                    [tbImgNameDic setObject:[rs stringForColumn:@"TP_DineType"] forKey:@"TableDineType"];
                    
                    [tbImgNameArray addObject:tbImgNameDic];
                    tbImgNameDic = nil;
                    
                    imgTag = [rs intForColumn:@"TP_ID"];
                    tbName = [rs stringForColumn:@"TP_Name"];
                    //imgChangeStatus = @"Edit";
                }
                [rs close];
            }
            else
            {
                [self showAlertView:[db lastErrorMessage] title:@"Error"];
            }
            
            
            
        }];
    }
    [checkRs close];
    
    [dbTableDesign close];
    
    if (!duplicateTable) {
        flag = @"Edit";
        img = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imgName]];
        //img.dbPath = dbPath;
        CGRect imgFrame = img.frame;
        
        if ([imgName isEqualToString:@"Table1"]) {
            imgFrame.size.width = 150;
            imgFrame.size.height = 178;
            tbLabel = [[UILabel alloc]initWithFrame:CGRectMake(5, 60, 145, 40)];
        }
        else if ([imgName isEqualToString:@"Table2"])
        {
            imgFrame.size.width = 200;
            imgFrame.size.height = 176;
            tbLabel = [[UILabel alloc]initWithFrame:CGRectMake(5, 60, 180, 40)];
        }
        else if ([imgName isEqualToString:@"Table3"])
        {
            imgFrame.size.width = 200;
            imgFrame.size.height = 181;
            tbLabel = [[UILabel alloc]initWithFrame:CGRectMake(5, 60, 180, 40)];
        }
        
        img.frame = imgFrame;
        img.center = CGPointMake(300, 300);
        
        img.contentMode = UIViewContentModeScaleAspectFit;
        img.userInteractionEnabled = YES;
        img.tag = imgTag;
        //img.tpName = tbName;
        UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(clickImage:)];
        //tapGes.numberOfTouchesRequired = 1;
        tapGes.numberOfTapsRequired = 1;
        [img addGestureRecognizer:tapGes];
        //NSLog(@"%f",img.frame.size.height);
        
        [tbLabel setFont:[UIFont boldSystemFontOfSize:20]];
        tbLabel.tag = imgTag + 500;
        tbLabel.textAlignment = NSTextAlignmentCenter;
        tbLabel.text = tbName;
        tbLabel.textColor = [UIColor whiteColor];
        [img addSubview:tbLabel];
        
        UIView *selectedView = [[UIView alloc]init];
        selectedView = (UIView *)[self.view viewWithTag:sectionIndex];
        
        [selectedView addSubview:img];
        
        //[self.tablePlanFloor addSubview:img];
        
        UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc]
                                                            initWithTarget:self
                                                            action:@selector(handlePinch:)];
        
        
        //UIRotationGestureRecognizer *rotateRecognizer = [[UIRotationGestureRecognizer alloc]
          //                                               initWithTarget:self
            //                                             action:@selector(handleRotate:)];
        
        UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handlePan:)];
        
        [img addGestureRecognizer:pinchGestureRecognizer];
        [img addGestureRecognizer:panGestureRecognizer];
        
        panGestureRecognizer.delegate = self;
        pinchGestureRecognizer.delegate = self;
        //rotateRecognizer.delegate = self;
        
        //[self.popOverTable dismissPopoverAnimated:YES];
        selectedView = nil;
    }
    
    imgFileName = @"Table1";
    
}

-(void)delTableName:(NSString *)delName UpdatePercent:(NSString *)updatePercent Overide:(int)overide ImageName:(NSString *)imgName DineType:(int)dineType
{
    NSString *selectedImgName;
    
    if ([delName isEqualToString:@"Delete"]) {
        [self deleteTable];
    }
    else
    {
        if ([imgName isEqualToString:@"Table1"]) {
            selectedImgName = @"Table1";
        }
        else if([imgName isEqualToString:@"Table2"])
        {
            selectedImgName = @"Table2";
        }
        else if([imgName isEqualToString:@"Table3"])
        {
            selectedImgName = @"Table3";
        }
        
        [self updateTableName:delName UpdatePercent:updatePercent UpdateOveride:overide SelectedImgName:selectedImgName UpdateDineType:dineType];
    }
}

-(void)showNewImageWithImgName:(NSString *)imgName Rotate:(float)rotate TableName:(NSString *)tableName
{

    if ([imgName isEqualToString:@"Table1"]) {
        imgFileName = @"Table1";
        
        img = (UIImageView *)[self.view viewWithTag:imgTag];
        img.transform = CGAffineTransformIdentity;
        CGRect imgFrame = img.frame;
        
        imgFrame.size.width = 150;
        imgFrame.size.height = 178;
        img.frame = imgFrame;
        
        
        tbLabel = (UILabel *)[self.view viewWithTag:imgTag + 500];
        CGRect lblFrame = tbLabel.frame;
        lblFrame.origin.x = 5;
        lblFrame.origin.y = 60;
        lblFrame.size.height = 40;
        lblFrame.size.width = 150;
        tbLabel.frame = lblFrame;
        tbLabel.textAlignment = NSTextAlignmentCenter;
        tbLabel.text = tableName;
        
    }
    else if([imgName isEqualToString:@"Table2"])
    {
        
        imgFileName = @"Table2";
        img = (UIImageView *)[self.view viewWithTag:imgTag];
        img.transform = CGAffineTransformIdentity;
        img.image = [UIImage imageNamed:imgFileName];
        CGRect imgFrame = img.frame;
        
        imgFrame.size.width = 200;
        imgFrame.size.height = 176;
        img.frame = imgFrame;
        
        tbLabel = (UILabel *)[self.view viewWithTag:imgTag + 500];
        CGRect lblFrame = tbLabel.frame;
        lblFrame.origin.x = 5;
        lblFrame.origin.y = 60;
        lblFrame.size.height = 40;
        lblFrame.size.width = 180;
        tbLabel.frame = lblFrame;
        tbLabel.textAlignment = NSTextAlignmentCenter;
        tbLabel.text = tableName;
        
        
    }
    else if ([imgName isEqualToString:@"Table3"])
    {
        imgFileName = @"Table3";
        
        img = (UIImageView *)[self.view viewWithTag:imgTag];
        img.transform = CGAffineTransformIdentity;
        CGRect imgFrame = img.frame;
        
        imgFrame.size.width = 200;
        imgFrame.size.height = 181;
        img.frame = imgFrame;
        
        tbLabel = (UILabel *)[self.view viewWithTag:imgTag + 500];
        CGRect lblFrame = tbLabel.frame;
        lblFrame.origin.x = 5;
        lblFrame.origin.y = 60;
        lblFrame.size.height = 40;
        lblFrame.size.width = 180;
        tbLabel.frame = lblFrame;
        tbLabel.textAlignment = NSTextAlignmentCenter;
        tbLabel.text = tableName;
        
    }
    
    flag = @"Edit";
    
    NSMutableDictionary *fileNameDict2 = [NSMutableDictionary dictionary];
    
    for (int i = 0; i < tbImgNameArray.count; i++) {
        if ([[[tbImgNameArray objectAtIndex:i] objectForKey:@"ImgID"] integerValue] == imgSelectedIndex) {
            fileNameDict2 = [tbImgNameArray objectAtIndex:i];
            [fileNameDict2 setValue:imgFileName forKey:@"ImgName"];
            
            [tbImgNameArray replaceObjectAtIndex:i withObject:fileNameDict2];
        }
    }
    
    fileNameDict2 = nil;
    
    img = (UIImageView *) [self.view viewWithTag:imgSelectedIndex];
    img.image = [UIImage imageNamed:imgFileName];
    //imgView.transform = CGAffineTransformMakeRotation(M_PI_2 * rotate);
    
    img = nil;
    
}

-(void)deleteTable
{
    
     [self dismissViewControllerAnimated:YES completion:nil];
    
    dbTableDesign = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTableDesign open]) {
        NSLog(@"Fail To Open DB");
        return;
    }
    
    ImageToDrag *delImgView = (ImageToDrag*) [self.view viewWithTag:imgSelectedIndex];
    
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        
        
        FMResultSet *rsTb = [db executeQuery:@"Select * from TablePlan where TP_ID = ?",[NSNumber numberWithInt:imgSelectedIndex]];
        
        if ([rsTb next]) {
            tbName2 = [rsTb stringForColumn:@"TP_Name"];
            //return;
        }
        [rsTb close];
        
        FMResultSet *rsSO = [db executeQuery:@"Select * from SalesOrderHdr where SOH_Table = ? and SOH_Status = ?",tbName2 ,@"New"];
        
        if ([rsSO next]) {
            [rsSO close];
            [self showAlertView:@"Sales order exist. Cannot delete" title:@"Warning"];
            return;
        }
        
        [rsSO close];
        
        FMResultSet *rsTb2 = [db executeQuery:@"Select * from GeneralSetting where GS_DefaultKioskName = ?",tbName2];
        
        if ([rsTb2 next]) {
            [rsTb2 close];
            [self showAlertView:@"This table set as kiosk. Cannot delete" title:@"Warning"];
            return;
        }
        [rsTb2 close];
        
        BOOL dbNoError = [dbTableDesign executeUpdate:@"delete from TablePlan where TP_ID = ?",[NSNumber numberWithInt:imgSelectedIndex]];
        
        if (dbNoError) {
            
            [delImgView removeFromSuperview];
            [dbTableDesign executeUpdate:@"delete from TempTablePlan where TP_ID = ?", [NSNumber numberWithInt:imgSelectedIndex]];
            flag = @"New";
            
            for (int i = 0; i < tbImgNameArray.count; i++) {
                if ([[[tbImgNameArray objectAtIndex:i] objectForKey:@"ImgID"] integerValue] == imgSelectedIndex) {
                    [tbImgNameArray removeObjectAtIndex:i];
                    break;
                }
            }
            
        }
        else
        {
            [self showAlertView:[dbTableDesign lastErrorMessage] title:@"Warning"];
        }
        
        
    }];
    
    delImgView = nil;
    [queue close];
    
    [dbTableDesign close];
    //[self.popOverTable dismissPopoverAnimated:YES];
   
    
}

-(void)updateTableName:(NSString *)tableName UpdatePercent:(NSString *)updatePercent UpdateOveride:(int)updateOveride SelectedImgName:(NSString *)selectedImgName UpdateDineType:(int)updateDineType
{
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    ImageToDrag *delImgView = (ImageToDrag*) [self.view viewWithTag:imgSelectedIndex];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        
        NSString *existingPercent;
        FMResultSet *rsTb = [db executeQuery:@"Select * from TablePlan where TP_ID = ?",[NSNumber numberWithInt:imgSelectedIndex]];
        
        if ([rsTb next]) {
            tbName2 = [rsTb stringForColumn:@"TP_Name"];
            existingPercent = [rsTb stringForColumn:@"TP_Percent"];
            //return;
        }
        [rsTb close];
        
        FMResultSet *rsSO = [db executeQuery:@"Select * from SalesOrderHdr where SOH_Table = ? and SOH_Status = ?",tbName2 ,@"New"];
        
        if ([rsSO next]) {
            
            if (![tableName isEqualToString:tbName2]) {
                [rsSO close];
                [self showAlertView:@"Sales order exist. Cannot update" title:@"Warning"];
                return;
            }else if (![existingPercent isEqualToString:updatePercent])
            {
                [rsSO close];
                [self showAlertView:@"Sales order exist. Cannot update" title:@"Warning"];
                return;
            }
            
        }
        [rsSO close];
        
        
        FMResultSet *rsTb2 = [db executeQuery:@"Select * from GeneralSetting where GS_DefaultKioskName = ?",tbName2];
        
        if ([rsTb2 next]) {
            [rsTb2 close];
            [self showAlertView:@"Used as non table service. Cannot update" title:@"Warning"];
            return;
        }
        [rsTb2 close];
    
        BOOL dbNoError = [db executeUpdate:@"update TablePlan set TP_Name = ?, TP_Percent = ?, TP_Overide = ?, TP_ImgName = ?, Tp_DineType = ? where TP_ID = ?",tableName,updatePercent,[NSNumber numberWithInt:updateOveride],selectedImgName,[NSNumber numberWithInt:updateDineType],[NSNumber numberWithInt:imgSelectedIndex]];
        
        if (dbNoError) {
            flag = @"Edit";
            UILabel *labelTb = (UILabel*) [self.view viewWithTag:imgSelectedIndex + 500];
            labelTb.text = tableName;
            
        }
        else
        {
            [self showAlertView:[dbTableDesign lastErrorMessage] title:@"Warning"];
        }
        
    }];
    
    delImgView = nil;
    
    [queue close];
    //[self.popOverTable dismissPopoverAnimated:YES];
    
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}


#pragma mark - alertView

-(void)showAlertView:(NSString *)msg title:(NSString *)title
{
    alertType = @"OtherAlert";
    
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

#pragma mark - alertview response
/*
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if ([alertType isEqualToString:@"BackAlert"]) {
        if (buttonIndex == 0) {
            NSLog(@"Cancel Click");
        }
        else if (buttonIndex == 1)
        {
            [self btnSaveTablePlan:alertType];
        }
        else if (buttonIndex == 2)
        {
            [self deleteUnSavedTable];
        }
    }
}
*/

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return ![gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] && ![gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return NO;
}

- (IBAction)backTablePlan:(id)sender {
    if ([flag isEqualToString:@"New"]) {
        [self showAlertView:@"Please save tableplan" title:@"Warning"];
        return;
    }
    [self.navigationController popViewControllerAnimated:NO];
}

-(void)deleteUnSavedTable
{
    __block NSString *status;

    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        
        for (int i = 0; i < tbImgNameArray.count; i++) {
            if ([[[tbImgNameArray objectAtIndex:i] objectForKey:@"TableStatus"] isEqualToString:@"New"]) {
                status = @"NoExit";
                [db executeUpdate:@"Delete from TablePlan where TP_Name = ?",[[tbImgNameArray objectAtIndex:i] objectForKey:@"TableName"]];
                
                if ([db hadError]) {
                    [self showAlertView:[db lastErrorMessage] title:@"Warning"];
                }
                else
                {
                    [self.navigationController popViewControllerAnimated:NO];
                }
                
            }
            else
            {
                status = @"Exit";
            }
        }
        
    }];
    
    [queue close];
    
    if ([status isEqualToString:@"Exit"]) {
        [self.navigationController popViewControllerAnimated:NO];
    }
}

- (IBAction)btnSaveTablePlan:(id)sender {
    dbTableDesign = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTableDesign open]) {
        NSLog(@"Failt To Open DB");
        return;
    }
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rsTB = [db executeQuery:@"Select * from TablePlan"];
        
        while ([rsTB next]) {
            NSArray *keepImgName;
            UIImageView *imgView = (UIImageView*) [self.view viewWithTag:[rsTB intForColumn:@"TP_ID"]];
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ImgID MATCHES[cd] %@",
                                      [rsTB stringForColumn:@"TP_ID"]];
            
            keepImgName = [tbImgNameArray filteredArrayUsingPredicate:predicate];
            
            //NSLog(@"%f",imgView.transform.a);
            //[NSNumber numberWithFloat:imgView.transform.a]
            
            BOOL dbHadError = [db executeUpdate:@"Update TablePlan set "
                               "TP_Rotate = ?, TP_Scale = ?"
                               ", TP_Xis = ?, TP_Yis = ?, TP_ImgName = ? where TP_ID = ?",[NSNumber numberWithFloat:[[imgView.layer valueForKeyPath:@"transform.rotation"]floatValue]],[NSNumber numberWithFloat:imgView.transform.a],[NSNumber numberWithFloat:imgView.center.x],[NSNumber numberWithFloat:imgView.center.y],[[keepImgName objectAtIndex:0] objectForKey:@"ImgName"],[NSNumber numberWithInt:[rsTB intForColumn:@"TP_ID"]]];
            
            //NSLog(@"tp id %d %f",[rsTB intForColumn:@"TP_ID"],imgView.center.y);
            keepImgName = nil;
            if (dbHadError) {
                flag = @"Edit";
            }
            else
            {
                NSLog(@"Fail Save Img Data");
                return;
            }
            imgView = nil;
            
            
        }
        [rsTB close];
        
    }];
    
    [queue close];
    [dbTableDesign close];
    if ([flag isEqualToString:@"Edit"]) {
        [self.navigationController popViewControllerAnimated:NO];
    }
    
    
}


#pragma mark gesture part

- (void) handlePinch:(UIPinchGestureRecognizer*) recognizer
{
    recognizer.view.transform = CGAffineTransformScale(recognizer.view.transform, recognizer.scale, recognizer.scale);
    
    recognizer.scale = 1;
}

- (void) handleRotate:(UIRotationGestureRecognizer*) recognizer
{
    recognizer.view.transform = CGAffineTransformRotate(recognizer.view.transform, recognizer.rotation);
    recognizer.rotation = 0;
}

- (void) handlePan:(UIPanGestureRecognizer*) recognizer
{
    
    CGPoint movement;
    
    if(recognizer.state == UIGestureRecognizerStateBegan || recognizer.state == UIGestureRecognizerStateChanged || recognizer.state == UIGestureRecognizerStateEnded)
    {
        flag = @"Edit";
        CGRect rec = recognizer.view.frame;
        //NSLog(@"view.frame:%@", NSStringFromCGRect(rec));
        UIView *dragView = [[UIView alloc]initWithFrame:CGRectMake(8, 122, 1008, 632)];
        //dragView = (UIView *)[self.view viewWithTag:sectionIndex];
        CGRect imgvw = dragView.frame;
        //NSLog(@"img view.frame:%@", NSStringFromCGRect(imgvw));
        NSLog(@"img x %f view x %f",rec.origin.x, imgvw.origin.x );
        
        if( (rec.origin.x + rec.size.width <= imgvw.origin.x + imgvw.size.width))
        {
            CGPoint translation = [recognizer translationInView:recognizer.view.superview];
            movement = translation;
            recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x, recognizer.view.center.y + translation.y);
            rec = recognizer.view.frame;
            
            if( rec.origin.x < imgvw.origin.x )
                //NSLog(@"%f",imgvw.origin.x);
                rec.origin.x = 0;
            
            if( rec.origin.x + rec.size.width > imgvw.origin.x + imgvw.size.width )
                rec.origin.x = imgvw.origin.x + imgvw.size.width - rec.size.width;
            
            if( rec.origin.y < 0)
                rec.origin.y = 0;
            
            if( rec.origin.y + rec.size.height >  imgvw.size.height )
            {
                rec.origin.y =  imgvw.size.height - rec.size.height;
                
            }
            //NSLog(@"rec y %f", rec.origin.y);
            
            //
            recognizer.view.frame = rec;
            
            [recognizer setTranslation:CGPointZero inView:recognizer.view.superview];
            
            //[self handleMovementForHandlers:movement];
        }
        else
        {
            
        }
    }
    
    
}

- (IBAction)testDis:(id)sender {
    [self displayTablePlan];
}

#pragma mark select segment
/*
-(void)didSelectItemAtIndex:(NSInteger)index
{
     NSLog(@"Button selected at index: %lu", (long)index);
    
    int viewTag;
    int selectedViewTag;
    // index - 20000 because yascrollsegment component tag duplicate with image tag
    int calcArrayIndex = index - 20000;
    selectedViewTag = [[[sectionArray objectAtIndex:calcArrayIndex]objectForKey:@"TsID"] integerValue];
    for (int j = 0; j < sectionArray.count; j ++) {
        viewTag = [[[sectionArray objectAtIndex:j]objectForKey:@"TsID"] integerValue];
        UIView *delImgView = (UIView*) [self.view viewWithTag:viewTag];
        if (selectedViewTag == viewTag) {
            sectionIndex = selectedViewTag;
            sectionName = [[sectionArray objectAtIndex:calcArrayIndex]objectForKey:@"TsName"];
            //NSLog(@"%@",sectionName);
            delImgView.hidden = NO;
            //[self drawTable:sectionIndex];
        }
        else
        {
            delImgView.hidden = YES;
        }
        delImgView = nil;
    }
    
}
 */

-(void)drawTable:(int)tagNo myViewName:(NSString *)viewName
{
    dbTableDesign = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTableDesign open]) {
        NSLog(@"Failt To Open DB");
        return;
    }
    
     FMResultSet *rs = [dbTableDesign executeQuery:@"Select * from tableplan where TP_Section = ?",sectionName];
     
     while ([rs next]) {
         tableRotate = [rs doubleForColumn:@"TP_Rotate"];
         tableScale = [rs doubleForColumn:@"TP_Scale"];
         tableX = [rs doubleForColumn:@"TP_Xis"];
         tableY = [rs doubleForColumn:@"TP_Yis"];
         tbName = [rs stringForColumn:@"TP_Name"];
     
         UIImageView *newImg = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"table2"]];
         newImg.userInteractionEnabled = YES;
         //CGAffineTransform transform = CGAffineTransformIdentity;
         CGAffineTransform transform = newImg.transform;
         transform = CGAffineTransformScale(transform, tableScale, tableScale);
     
         newImg.tag = [rs intForColumn:@"TP_ID"];
         [newImg setTransform:transform];
     
         UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(clickImage:)];
         //tapGes.delegate = self;
         tapGes.numberOfTapsRequired = 1;
         [newImg addGestureRecognizer:tapGes];
     
         UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handlePan:)];
         //panGestureRecognizer.delegate = self;
         [newImg addGestureRecognizer:panGestureRecognizer];
     
     
         UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc]
                                                             initWithTarget:self
                                                             action:@selector(handlePinch:)];
         [newImg addGestureRecognizer:pinchGestureRecognizer];
     
         newImg.center = CGPointMake(tableX, tableY);
     
         tbLabel = [[UILabel alloc]initWithFrame:CGRectMake(5, 38, 120, 40)];
         [tbLabel setFont:[UIFont boldSystemFontOfSize:20]];
         tbLabel.textAlignment = NSTextAlignmentCenter;
         tbLabel.text = tbName;
         tbLabel.textColor = [UIColor whiteColor];
         [newImg addSubview:tbLabel];
     
         UIView *insertView = [[UIView alloc]init];
         insertView = (UIView *)[self.view viewWithTag:tagNo];
         
         [insertView addSubview:newImg];
         insertView = nil;
         //[self.tablePlanFloor addSubview:newImg];
     }
     
     [rs close];
     
     
    [dbTableDesign close];

}

#pragma mark - section button default click

-(IBAction)btnDesignTbSectionClickWithNo:(id)sender
{
    
    long xPosition = 0;
    for (int i = 0; i < designSectionArray.count; i++) {
        if ([[[designSectionArray objectAtIndex:i] objectForKey:@"TsID"] integerValue] + 20000 == [sender tag]) {
            
            sectionIndex = [[[designSectionArray objectAtIndex:i] objectForKey:@"TsNo"] integerValue];
            
            sectionName = [[designSectionArray objectAtIndex:i] objectForKey:@"TsName"];
            
            UIButton *btn = (UIButton *)[self.view viewWithTag:[sender tag]];
            
            //[btn setBackgroundImage:[UIImage imageNamed:@"btnSectionBlue"] forState:UIControlStateNormal];
            [btn setBackgroundColor:[UIColor whiteColor]];
            //btn.titleLabel.textColor = [UIColor blueColor];
            [btn setTitleColor:[UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0] forState:UIControlStateNormal];
            btn = nil;
            
            if (i == 0) {
                xPosition = 0;
            }
            else
            {
                xPosition = i * kTbSectionPlanWidth;
            }
            
            [self.scrollDesignViewDragTbPlan setContentOffset:CGPointMake(xPosition, 0) animated:YES];
            
        }
        else
        {
            UIButton *btn = (UIButton *)[self.view viewWithTag:[[[designSectionArray objectAtIndex:i] objectForKey:@"TsID"] integerValue] + 20000];
            
            //[btn setBackgroundImage:[UIImage imageNamed:@"btnSectionGrey"] forState:UIControlStateNormal];
            [btn setBackgroundColor:[UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0]];
            [btn setTitleColor:[UIColor colorWithRed:182/255.0 green:203/255.0 blue:226/255.0 alpha:1.0] forState:UIControlStateNormal];
            btn = nil;
        }
    }
}


@end
