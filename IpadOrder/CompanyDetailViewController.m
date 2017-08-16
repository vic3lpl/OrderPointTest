//
//  CompanyDetailViewController.m
//  IpadOrder
//
//  Created by IRS on 31/03/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import "CompanyDetailViewController.h"
#import "UISplitViewController+DetailViewSwapper.h"
#import <QuartzCore/QuartzCore.h>
#import <FMDB.h>
#import "LibraryAPI.h"
#import <MBProgressHUD.h>
#import "PublicSqliteMethod.h"
#import <AFNetworking/AFNetworking.h>
#import <KVNProgress.h>


extern NSString *baseUrl;
@interface CompanyDetailViewController ()
{
    FMDatabase *dbComp;
    NSString *dbPath;
    NSString *userAction;
    BOOL dbHadError;
    NSString *terminalType;
    NSMutableArray *companyArray;
    NSString *appStatus;
    NSMutableArray *companyData;
    //NSString *alertType;
    NSString *apiDeviceID;
    NSString *apiProductKey;
    NSString *apiStatus;
    NSString *apiExpDate;
    NSDictionary* json;
    BOOL compEdited;
}
//@property(nonatomic,strong)UIPopoverController *popOverCountry;
@end

@implementation CompanyDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self setTitle:@"Company Detail"];
    
    
    dbPath = [[LibraryAPI sharedInstance]getDbPath];
    terminalType = [[LibraryAPI sharedInstance]getWorkMode];
    companyArray = [[NSMutableArray alloc] init];
    companyData = [[NSMutableArray alloc] initWithCapacity:1];
    self.companyCountry2.delegate = self;
    UIBarButtonItem *addBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(saveCompany:)];
    self.navigationItem.rightBarButtonItem = addBtn;
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0];
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    /*
    UIGraphicsBeginImageContext(self.view.frame.size);
    [[UIImage imageNamed:@"IO_Background1024"] drawInRect:self.view.bounds];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:image];
    */
    [self checkCompDb];
}



-(void)viewDidAppear:(BOOL)animated
{
    //self.viewCompanyBg2.layer.cornerRadius = 20.0;
    //self.viewCompanyBg.layer.borderWidth = 1.0;
    //self.viewCompanyBg2.layer.masksToBounds = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - textview delegate
-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    SelectCatTableViewController *selectCatTableViewController = [[SelectCatTableViewController alloc]init];
    selectCatTableViewController.delegate = self;
    //self.popOverCountry = [[UIPopoverController alloc]initWithContentViewController:selectCatTableViewController];
    
    if (textField == self.companyCountry2) {
        selectCatTableViewController.filterType = @"Country";
        [self.view endEditing:YES];
        
        selectCatTableViewController.modalPresentationStyle = UIModalPresentationPopover;
        selectCatTableViewController.popoverPresentationController.sourceView = self.companyCountry2;
        selectCatTableViewController.popoverPresentationController.sourceRect = CGRectMake(self.companyCountry2.frame.size.width /
                                                                                           2, self.companyCountry2.frame.size.height / 2, 1, 1);
        selectCatTableViewController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionLeft;
        
        [self presentViewController:selectCatTableViewController animated:YES completion:nil];
        /*
        [self.popOverCountry presentPopoverFromRect:CGRectMake(self.companyCountry2.frame.size.width /
                                                               2, self.companyCountry2.frame.size.height / 2, 1, 1) inView:self.companyCountry2 permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
         */
        return NO;
    }
    else
    {
        return YES;
    }
}

#pragma mark - delegate method
-(void)getSelectedCategory:(NSString *)field1 field2:(NSString *)field2 field3:(NSString *)field3 filterType:(NSString *)filterType
{
    if ([filterType isEqualToString:@"Country"]) {
        self.companyCountry2.text = field1;
    }
    //[self.popOverCountry dismissPopoverAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark - sqlite action
-(void)saveCompany:(id)sender
{
    
    //BOOL apiResult;
    if ([self checkTextField]) {
        if([appStatus isEqualToString:@"DEMO"])
        {
            [self userActionUpdateOrInsert];
        }
        else
        {
            
            [self userActionUpdateOrInsert];
            
        }
    }
    
    
}

-(void)userActionUpdateOrInsert
{
    if ([terminalType isEqualToString:@"Main"]) {
        
        if ([[LibraryAPI sharedInstance]getUserRole] == 0) {
            [self showAlertView:@"You have no permission to edit data" title:@"Warning"];
            return;
        }
        
        if ([userAction isEqualToString:@"New"]) {
            [self addCompany];
        }
        else
        {
            apiDeviceID = @"";
            apiProductKey = @"";
            apiStatus = @"";
            apiExpDate = @"";
            if ([appStatus isEqualToString:@"DEMO"]) {
                [self updateCompany];
            }
            else if ([appStatus isEqualToString:@"REG"])
            {
                if (![self checkCompanyDataEditOrNot]) {
                    //alertType = @"Alert";
                    
                    UIAlertController * alert = [UIAlertController
                                                 alertControllerWithTitle:[NSString stringWithFormat:@"%@ \r %@ \r %@", @"Update company profile will need Re-Activate again.", @"Please get approved from your Software Vendor within Re-Activation period.",@"Are you sure to continue ?"]
                                                 message:@"Warning"
                                                 preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction* yesButton = [UIAlertAction
                                                actionWithTitle:@"Yes"
                                                style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action) {
                                                    [self updateWebApiRegitration];
                                                    //Handle your yes please button action here
                                                }];
                    
                    UIAlertAction* noButton = [UIAlertAction
                                               actionWithTitle:@"No"
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
                    [self updateCompany];
                    
                }
                
            }
            else if ([appStatus isEqualToString:@"PENDING"])
            {
                if ([[[companyData objectAtIndex:0] objectForKey:@"App_Action"] isEqualToString:@"UpdCompany"]) {
                    [self updateWebApiRegitration];
                }
                else if ([[[companyData objectAtIndex:0] objectForKey:@"App_Action"] isEqualToString:@"UpdTerminal"])
                {
                    [self showAlertView:@"Waiting approved. Cannot update company profile" title:@"Warning"];
                    return;
                }
            }
            else
            {
                [self updateWebApiRegitration];
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
    [companyArray removeAllObjects];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    [dict setObject:self.companyName2.text forKey:@"CompName"];
    [dict setObject:self.companyAddr12.text forKey:@"CompAdd1"];
    [dict setObject:self.companyAddr22.text forKey:@"CompAdd2"];
    [dict setObject:self.companyAddr32.text forKey:@"CompAdd3"];
    [dict setObject:self.companyCity2.text forKey:@"CompCity"];
    [dict setObject:self.companyState2.text forKey:@"CompState"];
    [dict setObject:self.companyTel2.text forKey:@"CompTel"];
    [dict setObject:self.companyWebSite2.text forKey:@"CompWebsite"];
    [dict setObject:self.companyGst2.text forKey:@"CompGst"];
    [dict setObject:self.companyRegistrationNo2.text forKey:@"CompReg"];
    [dict setObject:self.companyPostCode2.text forKey:@"CompPost"];
    [dict setObject:self.companyCountry2.text forKey:@"CompCountry"];
    [dict setObject:self.companyEmail2.text forKey:@"CompEmail"];
    //[dict setObject:[NSString stringWithFormat:@"%d",self.switchEnableGst2.on] forKey:@"CompEnable"];
    [dict setObject:dbPath forKey:@"SqlPath"];
    
    [companyArray addObject:dict];
    dict = nil;
    
    NSString *result = [PublicSqliteMethod insertIntoCompanyTableWithDataArray:companyArray];
    
    if ([result isEqualToString:@"Success"]) {
        userAction = @"Edit";
        [[NSUserDefaults standardUserDefaults] setInteger:30 forKey:@"defaultDayCount"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [[LibraryAPI sharedInstance] setAppStatus:@"DEMO"];
        [self writeCompanyName];
        [self showAlertView:@"Data save" title:@"Success"];
    }
    else
    {
        [self showAlertView:result title:@"Error"];
    }
    
}

-(void)updateCompany
{
    [companyArray removeAllObjects];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    [dict setObject:self.companyName2.text forKey:@"CompName"];
    [dict setObject:self.companyAddr12.text forKey:@"CompAdd1"];
    [dict setObject:self.companyAddr22.text forKey:@"CompAdd2"];
    [dict setObject:self.companyAddr32.text forKey:@"CompAdd3"];
    [dict setObject:self.companyCity2.text forKey:@"CompCity"];
    [dict setObject:self.companyState2.text forKey:@"CompState"];
    [dict setObject:self.companyTel2.text forKey:@"CompTel"];
    [dict setObject:self.companyWebSite2.text forKey:@"CompWebsite"];
    [dict setObject:self.companyGst2.text forKey:@"CompGst"];
    [dict setObject:self.companyRegistrationNo2.text forKey:@"CompReg"];
    [dict setObject:self.companyPostCode2.text forKey:@"CompPost"];
    [dict setObject:self.companyCountry2.text forKey:@"CompCountry"];
    [dict setObject:self.companyEmail2.text forKey:@"CompEmail"];
    
    if ([appStatus isEqualToString:@"REQ"]) {
        [dict setObject:[json objectForKey:@"Status"] forKey:@"AppStatus"];
        [dict setObject:[json objectForKey:@"DeviceID"] forKey:@"AppDeviceID"];
        [dict setObject:[json objectForKey:@"ProductKey"] forKey:@"AppProductKey"];
        [dict setObject:[[companyData objectAtIndex:0] objectForKey:@"App_ReqExpDate"] forKey:@"AppExpDate"];
        [dict setObject:[json objectForKey:@"Action"] forKey:@"AppAction"];
    }
    else if ([appStatus isEqualToString:@"PENDING"] || [appStatus isEqualToString:@"RE-REG"] || [appStatus isEqualToString:@"REG"]) {
        if (compEdited) {
            [dict setObject:[[companyData objectAtIndex:0] objectForKey:@"App_Status"] forKey:@"AppStatus"];
            [dict setObject:[[companyData objectAtIndex:0] objectForKey:@"App_ProductKey"] forKey:@"AppProductKey"];
            [dict setObject:[[companyData objectAtIndex:0] objectForKey:@"App_ReqExpDate"] forKey:@"AppExpDate"];
            [dict setObject:[[companyData objectAtIndex:0] objectForKey:@"App_Action"] forKey:@"AppAction"];
        }
        else
        {
            [dict setObject:[json objectForKey:@"Status"] forKey:@"AppStatus"];
            [dict setObject:[json objectForKey:@"DeviceID"] forKey:@"AppDeviceID"];
            [dict setObject:[json objectForKey:@"ProductKey"] forKey:@"AppProductKey"];
            [dict setObject:[json objectForKey:@"ExpDate"] forKey:@"AppExpDate"];
            [dict setObject:[json objectForKey:@"Action"] forKey:@"AppAction"];
        }
        
    }
    else
    {
        [dict setObject:[[companyData objectAtIndex:0] objectForKey:@"App_Status"] forKey:@"AppStatus"];
        [dict setObject:[[companyData objectAtIndex:0] objectForKey:@"App_ProductKey"] forKey:@"AppProductKey"];
        [dict setObject:[[companyData objectAtIndex:0] objectForKey:@"App_ReqExpDate"] forKey:@"AppExpDate"];
        [dict setObject:[[companyData objectAtIndex:0] objectForKey:@"App_Action"] forKey:@"AppAction"];
    }
    
    
    //[dict setObject:[NSString stringWithFormat:@"%d",self.switchEnableGst2.on] forKey:@"CompEnable"];
    [dict setObject:dbPath forKey:@"SqlPath"];
    
    [companyArray addObject:dict];
    dict = nil;
    
    NSString *result = [PublicSqliteMethod updateIntoCompanyTableWithDataArray:companyArray];
    
    if ([result isEqualToString:@"Success"]) {
        [self replaceCompanyName];
        [self showAlertView:@"Data save" title:@"Success"];
    }
    else
    {
        [self showAlertView:result title:@"Error"];
    }
    
}

-(void)checkCompDb
{
    
    companyData = [PublicSqliteMethod checkCompanyProfileWithDbPath:dbPath];
    
    if ([[[companyData objectAtIndex:0] objectForKey:@"App_LicenseID"] length] > 0) {
        self.labelLicenseKey.text = [NSString stringWithFormat:@"License ID: %@",[[companyData objectAtIndex:0] objectForKey:@"App_LicenseID"]];
    }
    
    if ([[[companyData objectAtIndex:0] objectForKey:@"User_Action"] isEqualToString:@"New"]) {
        userAction = @"New";
        appStatus = [[companyData objectAtIndex:0] objectForKey:@"App_Status"];
    }
    else
    {
        userAction = @"Edit";
        
        self.companyName2.text = [[companyData objectAtIndex:0]objectForKey:@"Comp_Company"];
        self.companyAddr12.text = [[companyData objectAtIndex:0]objectForKey:@"Comp_Address1"];
        
        self.companyAddr22.text = [[companyData objectAtIndex:0]objectForKey:@"Comp_Address2"];
        self.companyAddr32.text = [[companyData objectAtIndex:0]objectForKey:@"Comp_Address3"];
        self.companyCity2.text = [[companyData objectAtIndex:0]objectForKey:@"Comp_City"];
        self.companyPostCode2.text = [[companyData objectAtIndex:0]objectForKey:@"Comp_PostCode"];
        self.companyState2.text = [[companyData objectAtIndex:0]objectForKey:@"Comp_State"];
        self.companyCountry2.text = [[companyData objectAtIndex:0]objectForKey:@"Comp_Country"];
        self.companyTel2.text = [[companyData objectAtIndex:0]objectForKey:@"Comp_Telephone"];
        self.companyEmail2.text = [[companyData objectAtIndex:0]objectForKey:@"Comp_Email"];
        self.companyWebSite2.text = [[companyData objectAtIndex:0]objectForKey:@"Comp_WebSite"];
        self.companyGst2.text = [[companyData objectAtIndex:0]objectForKey:@"Comp_GstNo"];
        self.companyRegistrationNo2.text = [[companyData objectAtIndex:0]objectForKey:@"Comp_RegistrationNo"];
        appStatus = [[companyData objectAtIndex:0] objectForKey:@"App_Status"];
        
    }
    
    //companyData = nil;
    
}
-(void)closeDatabase
{
    [dbComp close];
}

#pragma mark - call web api

-(void)updateWebApiRegitration
{
    [KVNProgress showWithStatus:@"Updating..."];
    NSString *toDay;
    NSDate *toDayDate = [NSDate date];
    //NSDateFormatter *dateFormater = [[NSDateFormatter alloc] init];
    //[dateFormater setDateFormat:@"yyyy-MM-dd"];
    NSDateFormatter *dateFormater = [[LibraryAPI sharedInstance] getDateFormateryyyymmdd];
    toDay = [dateFormater stringFromDate:toDayDate];
    NSUInteger dayCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"defaultDayCount"];
    
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc]initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    NSDictionary *parameters = @{@"DeviceID":[[companyData objectAtIndex:0] objectForKey:@"App_LicenseID"],@"DateTime":toDay,@"CompanyName1":self.companyName2.text,@"CompanyName2":@"",@"Address1":self.companyAddr12.text,@"Address2":self.companyAddr22.text,@"PostCode":self.companyPostCode2.text,@"Country":self.companyCountry2.text,@"Email":self.companyEmail2.text,@"Terminal":[[companyData objectAtIndex:0] objectForKey:@"App_TerminalQty"],@"intVersion":@"34",@"PurchaseID":[[companyData objectAtIndex:0] objectForKey:@"App_PurchaseID"],@"LCode":@"1713",@"Status":appStatus,@"UpdCompany_YN":@"1",@"UpdTerminal_YN":@"0",@"AddDay":[NSNumber numberWithUnsignedInteger: dayCount]};
    
    NSLog(@"REQ %@",parameters);
    NSMutableURLRequest *req = [[AFJSONRequestSerializer serializer]requestWithMethod:@"POST" URLString:[NSString stringWithFormat:@"%@%@",baseUrl, @"/RegisterDevice.aspx"] parameters:parameters error:nil];
    req.timeoutInterval = [[[NSUserDefaults standardUserDefaults]valueForKey:@"timeoutInterval"]longValue];
    
    [[manager dataTaskWithRequest:req completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if (!error) {
            json = [NSJSONSerialization JSONObjectWithData:responseObject
                                                                 options:kNilOptions
                                                                   error:&error];
            
            if (json.count > 0) {
                NSLog(@"Update Comp Profile %@",json);
                if ([[json objectForKey:@"Result"] isEqualToString:@"True"]) {
                    [KVNProgress dismiss];
                    //api2DeviceID = [json objectForKey:@"DeviceID"];
                    //api2ProductKey = [json objectForKey:@"ProductKey"];
                    //api2Status = [json objectForKey:@"Status"];
                    //api2ExpDate = [[companyData objectAtIndex:0] objectForKey:@"App_ReqExpDate"];
                    [self updateCompany];
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
                [self showAlertView:@"Data return is empty. Please try again" title:@"Warning"];
            }
            
        } else {
            [KVNProgress dismiss];
            NSLog(@"Error: %@, %@, %@", error, response, responseObject);
            [self showAlertView:[NSString stringWithFormat:@"%@",error] title:@"Warning"];
            
        }
    }]resume];
}

#pragma mark - alertView

-(void)showAlertView:(NSString *)msg title:(NSString *)title
{
    
    //alertType = @"Normal";
    
    /*
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"OK");
    }]
    ];
    
    [self presentViewController:alert animated:NO completion:nil];
     */
    UIAlertController *alert = [[LibraryAPI sharedInstance] showAlertViewWithMsg:msg Title:title];
    
    [self presentViewController:alert animated:NO completion:nil];
    alert = nil;
    
}

/*
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    
    if ([alertType isEqualToString:@"Alert"]) {
        if (buttonIndex == 0)
        {
            [self updateWebApiRegitration];
        }
    }
}
*/
#pragma mark - check field
-(BOOL)checkTextField
{
    if ([self.companyName2.text isEqualToString:@""]) {
        [self showAlertView:@"Company name cannot empty" title:@"Warning"];
        return NO;
    }
    else if ([self.companyAddr12.text isEqualToString:@""])
    {
        [self showAlertView:@"Address 1 cannot empty" title:@"Warning"];
        return NO;
    }
    else if ([self.companyAddr22.text isEqualToString:@""])
    {
        [self showAlertView:@"Address 2 cannot empty" title:@"Warning"];
        return NO;
    }
    /*
    else if ([self.companyAddr32.text isEqualToString:@""])
    {
        [self showAlertView:@"Address 3 cannot empty" title:@"Warning"];
        return NO;
    }
    */
    else if ([self.companyRegistrationNo2.text isEqualToString:@""])
    {
        [self showAlertView:@"Registration No. cannot empty" title:@"Warning"];
        return NO;
    }
    else if ([self.companyEmail2.text isEqualToString:@""] || [self.companyEmail2.text length] == 0)
    {
        [self showAlertView:@"Email cannot empty" title:@"Warning"];
        return NO;
    }
    
    else if ([self.companyPostCode2.text isEqualToString:@""])
    {
        [self showAlertView:@" PostCode cannot empty" title:@"Warning"];
        return NO;
    }
    else if ([self.companyCountry2.text isEqualToString:@""])
    {
        [self showAlertView:@" Country cannot empty" title:@"Warning"];
        return NO;
    }
    else if ([self.companyTel2.text isEqualToString:@""])
    {
        [self showAlertView:@"Telephone cannot empty" title:@"Warning"];
        return NO;
    }
    
    else if ([self.companyGst2.text isEqualToString:@""])
    {
        //[self showAlertView:@"Gst No Cannot Empty" title:@"Warning"];
        //return NO;
    }
    
    
    NSString *emailRegEx = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
    //Valid email address
    
    if ([emailTest evaluateWithObject:self.companyEmail2.text] == NO)
    {
        [self showAlertView:@"Email not in proper format" title:@"Warning"];
        return NO;
    }
    
    return  YES;
}

-(BOOL)checkCompanyDataEditOrNot
{
    NSMutableArray *checkCompanyArray = [[NSMutableArray alloc] initWithCapacity:1];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    [dict setObject:self.companyName2.text forKey:@"CompName"];
    [dict setObject:self.companyAddr12.text forKey:@"CompAdd1"];
    [dict setObject:self.companyAddr22.text forKey:@"CompAdd2"];
    [dict setObject:self.companyPostCode2.text forKey:@"CompPost"];
    [dict setObject:self.companyCountry2.text forKey:@"CompCountry"];
    [checkCompanyArray addObject:dict];
    dict = nil;
    
    
    NSMutableArray *checkCompanyArray2 = [[NSMutableArray alloc] initWithCapacity:1];
    NSMutableDictionary *dict2 = [NSMutableDictionary dictionary];
    [dict2 setObject:[[companyData objectAtIndex:0]objectForKey:@"Comp_Company"] forKey:@"CompName"];
    [dict2 setObject:[[companyData objectAtIndex:0]objectForKey:@"Comp_Address1"] forKey:@"CompAdd1"];
    [dict2 setObject:[[companyData objectAtIndex:0]objectForKey:@"Comp_Address2"] forKey:@"CompAdd2"];
    [dict2 setObject:[[companyData objectAtIndex:0]objectForKey:@"Comp_PostCode"] forKey:@"CompPost"];
    [dict2 setObject:[[companyData objectAtIndex:0]objectForKey:@"Comp_Country"] forKey:@"CompCountry"];
    
    [checkCompanyArray2 addObject:dict2];
    dict2 = nil;
    
    if ([checkCompanyArray isEqualToArray:checkCompanyArray2]) {
        checkCompanyArray = nil;
        checkCompanyArray2 = nil;
        compEdited = true;
        return true;
    }
    else
    {
        checkCompanyArray = nil;
        checkCompanyArray2 = nil;
        compEdited = false;
        return false;
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

-(void)writeCompanyName
{
   
    //get the documents directory:
    /*
    NSArray *paths = NSSearchPathForDirectoriesInDomains
    (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    //make a file name to write the data to using the documents directory:
    NSString *fileName = [NSString stringWithFormat:@"%@/data.txt",
                          documentsDirectory];
    //create content - four lines of text
    NSString *content = self.companyName2.text;
    
    //save content to the documents directory
    [content writeToFile:fileName
              atomically:NO
                encoding:NSStringEncodingConversionAllowLossy
                   error:nil];
     */
    
    
}

-(void)replaceCompanyName
{
    //NSError * error;
    //NSString * stringFilepath = @"data.txt";
    /*
    NSArray *paths = NSSearchPathForDirectoriesInDomains
    (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [NSString stringWithFormat:@"%@/data.txt",
                          documentsDirectory];
    
    NSString *content = self.companyName2.text;
    
    [content writeToFile:filePath atomically:YES encoding:NSWindowsCP1250StringEncoding error:nil];
    */
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
