//
//  DetailViewController.m
//  IpadOrder
//
//  Created by IRS on 7/1/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "DetailViewController.h"
#import "UISplitViewController+DetailViewSwapper.h"
#import <QuartzCore/QuartzCore.h>
#import <FMDB.h>
#import "LibraryAPI.h"
#import <MBProgressHUD.h>
#import "PublicSqliteMethod.h"

@interface DetailViewController ()
{
    FMDatabase *dbComp;
    NSString *dbPath;
    NSString *userAction;
    BOOL dbHadError;
    NSString *terminalType;
    NSMutableArray *compArray;
    NSString *appStatus;
}
@property (nonatomic, strong) UIPopoverController *popover;
@end

@implementation DetailViewController
@synthesize popoverController, detailStruct;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self setTitle:@"Company Detail"];
    dbPath = [[LibraryAPI sharedInstance]getDbPath];
    terminalType = [[LibraryAPI sharedInstance]getWorkMode];
    compArray = [[NSMutableArray alloc] init];
    
    UIBarButtonItem *addBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(saveCompany:)];
    self.navigationItem.rightBarButtonItem = addBtn;
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:59/255.0 green:89/255.0 blue:153/255.0 alpha:1.0];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    [self.btnChooseImg addTarget:self action:@selector(btnTakeImg:) forControlEvents:UIControlEventTouchUpInside];
    
    UIGraphicsBeginImageContext(self.view.frame.size);
    [[UIImage imageNamed:@"IO_Background1024"] drawInRect:self.view.bounds];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:image];
    
    [self checkCompDb];
}

-(void)viewDidAppear:(BOOL)animated
{
    self.viewCompanyBg.layer.cornerRadius = 20.0;
    //self.viewCompanyBg.layer.borderWidth = 1.0;
    self.viewCompanyBg.layer.masksToBounds = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - sqlite action

-(void)saveCompany:(id)sender
{
    BOOL apiResult;
    
    if([appStatus isEqualToString:@"DEMO"])
    {
        [self userActionUpdateOrInsert];
    }
    else
    {
        apiResult = [PublicSqliteMethod updateWebApiRegitration];
        
        if (apiResult == true) {
            [self userActionUpdateOrInsert];
        }
        else
        {
            [self showAlertView:@"Please connect your device to internet" title:@"Warning"];
        }
        
    }
    
}

-(void)userActionUpdateOrInsert
{
    if ([terminalType isEqualToString:@"Main"]) {
        
        if([PublicSqliteMethod updateWebApiRegitration])
        {
            if ([userAction isEqualToString:@"New"]) {
                [self addCompany];
            }
            else
            {
                [self updateCompany];
            }
            
        }
    }
    else
    {
        //[self showMyHudMessageBoxWithMessage:@"Terminal Cannot Edit"];
        [self showAlertView:@"Terminal cannot edit" title:@"Warning"];
    }
}

-(void)addCompany
{
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    [dict setObject:self.companyName.text forKey:@"CompName"];
    [dict setObject:self.companyAddr1.text forKey:@"CompAdd1"];
    [dict setObject:self.companyAddr2.text forKey:@"CompAdd2"];
    [dict setObject:self.companyAddr3.text forKey:@"CompAdd3"];
    [dict setObject:self.companyCity.text forKey:@"CompCity"];
    [dict setObject:self.companyState.text forKey:@"CompState"];
    [dict setObject:self.companyTel.text forKey:@"CompTel"];
    [dict setObject:self.companyWebSite.text forKey:@"CompWebsite"];
    [dict setObject:self.companyGst.text forKey:@"CompGst"];
    [dict setObject:self.companyRegistrationNo.text forKey:@"CompReg"];
    [dict setObject:self.companyPostCode.text forKey:@"CompPost"];
    [dict setObject:self.companyCountry.text forKey:@"CompCountry"];
    [dict setObject:self.companyEmail.text forKey:@"CompEmail"];
    //[dict setObject:[NSString stringWithFormat:@"%d",self.switchEnableGst.on] forKey:@"CompEnable"];
    [dict setObject:dbPath forKey:@"SqlPath"];
    
    [compArray addObject:dict];
    dict = nil;
    
    NSString *result = [PublicSqliteMethod insertIntoCompanyTableWithDataArray:compArray];
    
    if ([result isEqualToString:@"Success"]) {
        userAction = @"Edit";
        [self showAlertView:@"Data save" title:@"Success"];
    }
    else
    {
        [self showAlertView:result title:@"Error"];
    }

    
}

-(void)updateCompany
{
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    [dict setObject:self.companyName.text forKey:@"CompName"];
    [dict setObject:self.companyAddr1.text forKey:@"CompAdd1"];
    [dict setObject:self.companyAddr2.text forKey:@"CompAdd2"];
    [dict setObject:self.companyAddr3.text forKey:@"CompAdd3"];
    [dict setObject:self.companyCity.text forKey:@"CompCity"];
    [dict setObject:self.companyState.text forKey:@"CompState"];
    [dict setObject:self.companyTel.text forKey:@"CompTel"];
    [dict setObject:self.companyWebSite.text forKey:@"CompWebsite"];
    [dict setObject:self.companyGst.text forKey:@"CompGst"];
    [dict setObject:self.companyRegistrationNo.text forKey:@"CompReg"];
    [dict setObject:self.companyPostCode.text forKey:@"CompPost"];
    [dict setObject:self.companyCountry.text forKey:@"CompCountry"];
    [dict setObject:self.companyEmail.text forKey:@"CompEmail"];
    //[dict setObject:[NSString stringWithFormat:@"%d",self.switchEnableGst.on] forKey:@"CompEnable"];
    [dict setObject:dbPath forKey:@"SqlPath"];
    
    [compArray addObject:dict];
    dict = nil;
    
    NSString *result = [PublicSqliteMethod updateIntoCompanyTableWithDataArray:compArray];
    
    if ([result isEqualToString:@"Success"]) {
        [self showAlertView:@"Data save" title:@"Success"];
    }
    else
    {
        [self showAlertView:result title:@"Error"];
    }

}

-(void)checkCompDb
{
    NSMutableArray *companyData = [[NSMutableArray alloc] initWithCapacity:1];
    
    companyData = [PublicSqliteMethod checkCompanyProfileWithDbPath:dbPath];
    
    if ([[[companyData objectAtIndex:0] objectForKey:@"User_Action"] isEqualToString:@"New"]) {
        userAction = @"New";
        appStatus = [[companyData objectAtIndex:0] objectForKey:@"App_Status"];
    }
    else
    {
        userAction = @"Edit";
        
        self.companyName.text = [[companyData objectAtIndex:0]objectForKey:@"Comp_Company"];
        self.companyAddr1.text = [[companyData objectAtIndex:0]objectForKey:@"Comp_Address1"];
        NSLog(@"%@",self.companyAddr1.text);
        self.companyAddr2.text = [[companyData objectAtIndex:0]objectForKey:@"Comp_Address2"];
        self.companyAddr3.text = [[companyData objectAtIndex:0]objectForKey:@"Comp_Address3"];
        self.companyCity.text = [[companyData objectAtIndex:0]objectForKey:@"Comp_City"];
        self.companyPostCode.text = [[companyData objectAtIndex:0]objectForKey:@"Comp_PostCode"];
        self.companyState.text = [[companyData objectAtIndex:0]objectForKey:@"Comp_State"];
        self.companyCountry.text = [[companyData objectAtIndex:0]objectForKey:@"Comp_Country"];
        self.companyTel.text = [[companyData objectAtIndex:0]objectForKey:@"Comp_Telephone"];
        self.companyEmail.text = [[companyData objectAtIndex:0]objectForKey:@"Comp_Email"];
        self.companyWebSite.text = [[companyData objectAtIndex:0]objectForKey:@"Comp_WebSite"];
        self.companyGst.text = [[companyData objectAtIndex:0]objectForKey:@"Comp_GstNo"];
        self.companyRegistrationNo.text = [[companyData objectAtIndex:0]objectForKey:@"Comp_RegistrationNo"];
        appStatus = [[companyData objectAtIndex:0] objectForKey:@"App_Status"];
        
    }
    companyData = nil;
}


-(void)closeDatabase
{
    [dbComp close];
}

#pragma mark - alertView

-(void)showAlertView:(NSString *)msg title:(NSString *)title
{
    /*
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:msg
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
     */
}


#pragma mark - ipad rotate

- (void)splitViewController:(UISplitViewController*)svc

     willHideViewController:(UIViewController *)aViewController

          withBarButtonItem:(UIBarButtonItem*)barButtonItem

       forPopoverController:(UIPopoverController*)pc

{
    
    [barButtonItem setTitle:@"Structures"];
    
    [[self navigationItem] setLeftBarButtonItem:barButtonItem];
    
    [self setPopoverController:pc];
    
}

- (void)splitViewController:(UISplitViewController*)svc

     willShowViewController:(UIViewController *)aViewController

  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem

{
    
    [[self navigationItem] setLeftBarButtonItem:nil];
    
    [self setPopoverController:nil];
    
}


#pragma mark - check field
/*
-(BOOL)checkTextField
{
    if ([self.companyName.text isEqualToString:@""]) {
        [self showAlertView:@"Company name cannot empty" title:@"Warning"];
        return NO;
    }
    else if ([self.companyAddr1.text isEqualToString:@""])
    {
        [self showAlertView:@"Address 1 cannot empty" title:@"Warning"];
        return NO;
    }
    else if ([self.companyAddr2.text isEqualToString:@""])
    {
        [self showAlertView:@"company 2 cannot empty" title:@"Warning"];
        return NO;
    }
    else if ([self.companyCity.text isEqualToString:@""])
    {
        [self showAlertView:@"City cannot empty" title:@"Warning"];
        return NO;
    }
    else if ([self.companyPostCode.text isEqualToString:@""])
    {
        [self showAlertView:@" PostCode cannot empty" title:@"Warning"];
        return NO;
    }
    else if ([self.companyCountry.text isEqualToString:@""])
    {
        [self showAlertView:@" Country cannot empty" title:@"Warning"];
        return NO;
    }
    else if ([self.companyTel.text isEqualToString:@""])
    {
        [self showAlertView:@"Telephone cannot empty" title:@"Warning"];
        return NO;
    }
    else if ([self.companyRegistrationNo.text isEqualToString:@""])
    {
        [self showAlertView:@"Registration no cannot empty" title:@"Warning"];
        return NO;
    }
    else if ([self.companyGst.text isEqualToString:@""])
    {
        //[self showAlertView:@"Gst No Cannot Empty" title:@"Warning"];
        //return NO;
    }
    
    return  YES;
}
*/

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
