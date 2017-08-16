//
//  ActivateDeviceViewController.m
//  IpadOrder
//
//  Created by IRS on 13/05/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import "ActivateDeviceViewController.h"
#import "LibraryAPI.h"
#import <FMDB.h>
#import <AFNetworking/AFNetworking.h>
#import <KVNProgress.h>
#import "PublicSqliteMethod.h"

extern NSString *baseUrl;
@interface ActivateDeviceViewController ()
{
    NSString *dbPath;
    FMDatabase *dbTable;
    NSMutableArray *compArray;
    NSString *btnClickStatus;
    NSString *appLicenseID;
    NSString *appRegStatus;
}
@end

@implementation ActivateDeviceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationController.navigationBar.hidden = YES;
    self.preferredContentSize = CGSizeMake(600, 500);
    self.textCompanyName.delegate = self;
    self.textAdd1.delegate = self;
    self.textAdd2.delegate = self;
    self.textPostCode.delegate = self;
    self.textCountry.delegate = self;
    self.textEmail.delegate = self;
    self.textTerminalQty.delegate = self;
    self.btnSelectReg.backgroundColor = [UIColor whiteColor];
    self.btnSelectReReg.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.6];
    [self.btnSelectReg setTitleColor:[UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0] forState:UIControlStateNormal];
    
    dbPath = [[LibraryAPI sharedInstance] getDbPath];
    
    compArray = [[NSMutableArray alloc] init];
    
    [self.btnRegister addTarget:self action:@selector(detectRequestButttonAction) forControlEvents:UIControlEventTouchUpInside];
    
    UITapGestureRecognizer *tapBackground = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(minimizeKeyboard)];
    tapBackground.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapBackground];
    
    //self.view.backgroundColor = [UIColor clearColor];
    
    
    UIGraphicsBeginImageContext(self.view.frame.size);
    [[UIImage imageNamed:@"Shadow"] drawInRect:self.view.bounds];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:image];

    [self getCompanyProfileData];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - textfield delegate

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (textField == self.textAdd1) {
        if ([btnClickStatus isEqualToString:@"ReReg"]) {
            return YES;
        }
        else
        {
            return NO;
        }
        
    }
    else if(textField == self.textCompanyName)
    {
        if ([btnClickStatus isEqualToString:@"ReReg"]) {
            return YES;
        }
        else
        {
            return NO;
        }
    }
    else if(textField == self.textAdd2)
    {
        if ([btnClickStatus isEqualToString:@"ReReg"]) {
            return YES;
        }
        else
        {
            return NO;
        }
    }
    else if (textField == self.textTerminalQty)
    {
        SelectCatTableViewController *selectCatTableViewController = [[SelectCatTableViewController alloc]init];
        selectCatTableViewController.delegate = self;
        selectCatTableViewController.filterType = @"TerminalNo";
        //self.popOver = [[UIPopoverController alloc]initWithContentViewController:selectCatTableViewController];
        
        [self.view endEditing:YES];
        
        
        selectCatTableViewController.modalPresentationStyle = UIModalPresentationPopover;
        selectCatTableViewController.popoverPresentationController.sourceRect = CGRectMake(self.textTerminalQty.frame.size.width /
                                                                                           2, self.textTerminalQty.frame.size.height / 2, 1, 1);
        selectCatTableViewController.popoverPresentationController.sourceView = self.textTerminalQty;
        selectCatTableViewController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionLeft;
        
        [self presentViewController:selectCatTableViewController animated:YES completion:nil];
        
        /*
        [self.popOver presentPopoverFromRect:CGRectMake(self.textTerminalQty.frame.size.width /
                                                        2, self.textTerminalQty.frame.size.height / 2, 1, 1) inView:self.textTerminalQty permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
         */
        return NO;
    }
    else
    {
        return NO;
    }
    
}

#pragma mark - self method

-(void)minimizeKeyboard
{
    [self.view endEditing:YES];
    
}

-(void)detectRequestButttonAction
{
    if ([btnClickStatus isEqualToString:@"Reg"]) {
        [self checkTextFieldEmpty];
    }
    else
    {
        if ([self.textAdd1.text length] == 0)
        {
            [self showAlertView:@"License id cannot empty" title:@"Warning"];
            return;
        }
        else if ([self.textAdd2.text length] == 0)
        {
            [self showAlertView:@"Dealer id cannot empty" title:@"Warning"];
            return;
        }
        
        [self callRequestLicenseWebApi];
    }
}

#pragma mark - checking
-(void)showTextField
{
    //self.textAdd2.hidden = NO;
    self.textPostCode.hidden = NO;
    self.textCountry.hidden = NO;
    self.textPurchaseID.hidden = NO;
    self.textTerminalQty.hidden = NO;
    self.textEmail.hidden = NO;
    //self.labelActivateAddress2.hidden = NO;
    self.labelActivatePostCode.hidden = NO;
    self.labelActivateCountry.hidden = NO;
    self.labelActivateDealerID.hidden = NO;
    self.labelActivateTerminalQty.hidden = NO;
    self.labelEmail.hidden = NO;
}

-(void)hideTextField
{
    //self.textCompanyName.text = @"";
    self.textAdd1.text = @"";
    self.textAdd2.text = @"";
    self.textPostCode.hidden = YES;
    self.textCountry.hidden = YES;
    self.textPurchaseID.hidden = YES;
    self.textTerminalQty.hidden = YES;
    self.textEmail.hidden = YES;
    //self.labelActivateAddress2.hidden = YES;
    self.labelActivatePostCode.hidden = YES;
    self.labelActivateCountry.hidden = YES;
    self.labelActivateDealerID.hidden = YES;
    self.labelActivateTerminalQty.hidden = YES;
    self.labelEmail.hidden = YES;
}

-(void)checkTextFieldEmpty
{
    
    if ([self.textCompanyName.text length] == 0) {
        [self showAlertView:@"Company name cannot empty" title:@"Warning"];
        return;
    }
    else if ([self.textAdd1.text length] == 0)
    {
        [self showAlertView:@"Address 1 cannot empty" title:@"Warning"];
        return;
    }
    else if ([self.textAdd2.text length] == 0)
    {
        [self showAlertView:@"Address 2 cannot empty" title:@"Warning"];
        return;
    }
    else if ([self.textPostCode.text length] == 0)
    {
        [self showAlertView:@"PostCode cannot empty" title:@"Warning"];
        return;
    }
    else if ([self.textCountry.text length] == 0)
    {
        [self showAlertView:@"Country cannot empty" title:@"Warning"];
        return;
    }
    else if ([self.textPurchaseID.text length] == 0)
    {
        [self showAlertView:@"Dealer id cannot empty" title:@"Warning"];
        return;
    }
    else if ([self.textTerminalQty.text length] == 0)
    {
        [self showAlertView:@"Terminal qty cannot empty" title:@"Warning"];
        return;
    }
    else if ([self.textEmail.text length] == 0)
    {
        [self showAlertView:@"Email cannot empty" title:@"Warning"];
        return;
    }
    
    [self callRequestLicenseWebApi];
}


#pragma mark - sqlite part
-(void)getCompanyProfileData
{
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        /*
        FMResultSet *rsTerminal = [db executeQuery:@"Select count(*) as terminalQty from Terminal where T_Code != ?",@"null"];
        
        if ([rsTerminal next]) {
            self.textTerminalQty.text = [rsTerminal stringForColumn:@"terminalQty"];
        }
        [rsTerminal close];
        */
        FMResultSet *rs = [db executeQuery:@"Select * from Company"];
        
        if ([rs next])
        {
            [compArray addObject:[rs resultDictionary]];
            self.textCompanyName.text = [rs stringForColumn:@"Comp_Company"];
            self.textAdd1.text = [rs stringForColumn:@"Comp_Address1"];
            self.textAdd2.text = [rs stringForColumn:@"Comp_Address2"];
            self.textPostCode.text = [rs stringForColumn:@"Comp_PostCode"];
            self.textCountry.text = [rs stringForColumn:@"Comp_Country"];
            self.textEmail.text = [rs stringForColumn:@"Comp_Email"];
        }
        
        [rs close];
        
        FMResultSet *rsAppReg = [db executeQuery:@"Select App_LicenseID, App_Status,App_PurchaseID,App_TerminalQty from AppRegistration"];
        
        if ([rsAppReg next]) {
            //self.textTerminalQty.text = [rsAppReg stringForColumn:@"App_TerminalQty"];
            self.textTerminalQty.text = @"";
            if ([[rsAppReg stringForColumn:@"App_LicenseID"] length] > 0) {
                appLicenseID = [rsAppReg stringForColumn:@"App_LicenseID"];
                appRegStatus = [rsAppReg stringForColumn:@"App_Status"];
                self.textPurchaseID.text = [rsAppReg stringForColumn:@"App_PurchaseID"];
            }else
            {
                appLicenseID = @"";
                appRegStatus = @"";
            }
        }
        else
        {
            appLicenseID = @"";
            appRegStatus = @"";
        }
        
        [rsAppReg close];
        
    }];
    
    [queue close];
    
}

-(NSString *)insertIntoCompanyTableWhenReRegWithCompanyName:(NSString *)companyName LicenseID:(NSString *)licenseID DealerID:(NSString *)dealerID PurchaseID:(NSString *)purchaseID TerminalQty:(NSString *)terminalQty
{
    
    __block NSString *result;
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        //[dbComp beginTransaction];
        [db executeUpdate:@"Delete from Company"];
        [db executeUpdate:@"Delete from AppRegistration"];
        
        [db executeUpdate:@"insert into company (Comp_Company) values (?)",companyName];
        
        if (![db hadError]) {
            result = @"Success";
        }
        else
        {
            result = [db lastErrorMessage];
            *rollback = YES;
        }
        
        NSDate *today = [NSDate date];
        //NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        //[dateFormat setDateFormat:@"yyyy-MM-dd"];
        NSDateFormatter *dateFormat = [[LibraryAPI sharedInstance] getDateFormateryyyymmdd];
        NSString *dateStartDemo = [dateFormat stringFromDate:today];
        
        NSDate *dateEnd = [today dateByAddingTimeInterval:60*60*24*30];
        NSString *dateEndDemo = [dateFormat stringFromDate:dateEnd];
        
        if ([result isEqualToString:@"Success"]) {
            [db executeUpdate:@"Insert into AppRegistration ( "
             " App_CompanyName, App_Status, App_PurchaseID, App_DealerID, App_LicenseID, App_TerminalQty) values(?,?,?,?,?,?)",companyName,@"RE-REG",purchaseID, dealerID,licenseID,terminalQty];
            
            if ([db hadError]) {
                result = [db lastErrorMessage];
                *rollback = YES;
            }
            else
            {
                result = @"Success";
            }
            
        }
        
        dateEndDemo = nil;
        dateStartDemo = nil;
        dateFormat = nil;
        
    }];
    
    
    
    [queue close];
    
    return result;
}


/*
-(void)updateAppReg//istrationTableWithLicenseID:(NSString *)licenseID ProductKey:(NSString *)productKey DeviceStatus:(NSString *)deviceStatus PurchaseID:(NSString *)purchaseID TerminalQty:(NSString *)qty
{
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"Update AppRegistration set App_LicenseID = ?, App_ProductKey = ?, App_Status = ?, App_PurchaseID = ?, App_TerminalQty = ?",licenseID, productKey, deviceStatus,purchaseID,qty];
        
        if (![db hadError]) {
            [KVNProgress dismiss];
            [[LibraryAPI sharedInstance] setAppStatus:deviceStatus];
            [self showAlertView:@"Success Request" title:@"Success"];
        }
    }];
    
    [queue close];
}
 */

#pragma mark - afnetworking part

-(void)callRequestLicenseWebApi
{
    [KVNProgress showWithStatus:@"Data Sending..."];
    NSString *toDay;
    NSDate *toDayDate = [NSDate date];
    //NSDateFormatter *dateFormater = [[NSDateFormatter alloc] init];
    //[dateFormater setDateFormat:@"yyyy-MM-dd"];
    NSDateFormatter *dateFormater = [[LibraryAPI sharedInstance] getDateFormateryyyymmdd];
    
    toDay = [dateFormater stringFromDate:toDayDate];
    int dayCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"defaultDayCount"];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc]initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    NSDictionary *parameters;
    if ([appRegStatus isEqualToString:@"RE-REG"]) {
        parameters = @{@"DeviceID":self.textAdd1.text,@"DateTime":toDay,@"AddDay":[NSNumber numberWithInt: 0],@"CompanyName1":self.textCompanyName.text,@"CompanyName2":@"",@"Address1":@"",@"Address2":@"",@"PostCode":@"",@"Country":@"",@"Email":@"",@"Terminal":@"0",@"intVersion":@"34",@"PurchaseID":self.textAdd2.text,@"LCode":@"1713",@"Status":appRegStatus,@"UpdCompany_YN":@"0",@"UpdTerminal_YN":@"0"};
    }
    else
    {
        parameters = @{@"DeviceID":appLicenseID,@"DateTime":toDay,@"AddDay":[NSNumber numberWithInt: dayCount],@"CompanyName1":self.textCompanyName.text,@"CompanyName2":@"",@"Address1":self.textAdd1.text,@"Address2":self.textAdd2.text,@"PostCode":self.textPostCode.text,@"Country":self.textCountry.text,@"Email":self.textEmail.text,@"Terminal":self.textTerminalQty.text,@"intVersion":@"34",@"PurchaseID":self.textPurchaseID.text,@"LCode":@"1713",@"Status":appRegStatus,@"UpdCompany_YN":@"0",@"UpdTerminal_YN":@"0"};
    }
    
    //NSLog(@"%@",parameters);
    
    NSMutableURLRequest *req = [[AFJSONRequestSerializer serializer]requestWithMethod:@"POST" URLString:[NSString stringWithFormat:@"%@%@",baseUrl, @"/RegisterDevice.aspx"] parameters:parameters error:nil];
    
    req.timeoutInterval= [[[NSUserDefaults standardUserDefaults] valueForKey:@"timeoutInterval"] longValue];
    
    [[manager dataTaskWithRequest:req completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        BOOL returnResult;
        if (!error) {
            NSDictionary* json = [NSJSONSerialization JSONObjectWithData:responseObject
                                                                 options:kNilOptions
                                                                   error:&error];
            
            //NSLog(@"json result : %@",json);
            
            if (json.count > 0) {
                if ([[json objectForKey:@"Result"] isEqualToString:@"True"]) {
                    
                    [[LibraryAPI sharedInstance] setAppApiVersion:[json objectForKey:@"AppVersion"]];
                    
                    if ([[json objectForKey:@"Status"] isEqualToString:@"RE-REG"]) {
                        if ([[self insertIntoCompanyTableWhenReRegWithCompanyName:self.textCompanyName.text LicenseID:[json objectForKey:@"DeviceID"] DealerID:@"" PurchaseID:self.textAdd2.text TerminalQty:[json objectForKey:@"TerminalNo"]] isEqualToString:@"Success"])
                        {
                            [KVNProgress dismiss];
                            if (_delegate != nil) {
                                [_delegate afterRequestTerminalDevice];
                            }
                            [self showAlertView:@"Please restart the app" title:@"Warning"];
                        }
                        else
                        {
                            [KVNProgress dismiss];
                            [self showAlertView:@"Please try again" title:@"Warning"];
                        }
                    }
                    else
                    {
                        appLicenseID = [json objectForKey:@"DeviceID"];
                        returnResult = [PublicSqliteMethod updateAppRegistrationTableWithLicenseID:[json objectForKey:@"DeviceID"] ProductKey:[json objectForKey:@"ProductKey"] DeviceStatus:[json objectForKey:@"Status"] PurchaseID:self.textPurchaseID.text TerminalQty:self.textTerminalQty.text DBPath:dbPath RequestExpDate:[json objectForKey:@"ExpDate"] RequestAction:@""];
                        
                        if (returnResult == true) {
                            [KVNProgress dismiss];
                            [[LibraryAPI sharedInstance] setAppStatus:[json objectForKey:@"Status"]];
                            [self showAlertView:@"Success request" title:@"Success"];
                            if (_delegate != nil) {
                                [_delegate afterRequestTerminalDevice];
                            }
                            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                        }
                    }
                    
                    [[NSUserDefaults standardUserDefaults] setObject:[json objectForKey:@"DatabaseID"] forKey:@"databaseID"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    
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
            [self showAlertView:[NSString stringWithFormat:@"%@",error] title:@"Cannot connect server"];
            //NSLog(@"Error: %@, %@, %@", error, response, responseObject);
        }
    }] resume];
    
    //[req setHTTPBody:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)closeActivateDevice:(id)sender {
    compArray = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - selcted cat delegate
-(void)getSelectedCategory:(NSString *)field1 field2:(NSString *)field2 field3:(NSString *)field3 filterType:(NSString *)filterType
{
    self.textTerminalQty.text = field1;
    
    //[self.popOver dismissPopoverAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
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

#pragma mark - btn click methid
- (IBAction)btnRegActionSelected:(id)sender {
    UIButton *button = (UIButton *) sender;
    
    if (button.tag == 0)
    {
        self.btnSelectReg.backgroundColor = [UIColor whiteColor];
        [self.btnSelectReg setTitleColor:[UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0] forState:UIControlStateNormal];
        [self.btnSelectReReg setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        self.btnSelectReReg.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.6];
        self.labelShare2.text = @"Address 1";
        self.labelActivateAddress2.text = @"Address 2";
        [self showTextField];
        btnClickStatus = @"Reg";
        [self getCompanyProfileData];
    }
    else if (button.tag == 1)
    {
        self.btnSelectReReg.backgroundColor = [UIColor colorWithWhite:1.0 alpha:1.0];
        self.btnSelectReg.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.6];
        
        [self.btnSelectReReg setTitleColor:[UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0] forState:UIControlStateNormal];
        [self.btnSelectReg setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        
        self.labelShare2.text = @"License ID";
        self.labelActivateAddress2.text = @"Dealer ID";
        
        [self hideTextField];
        appRegStatus = @"RE-REG";
        btnClickStatus = @"ReReg";
    }
    button = nil;
}
@end
