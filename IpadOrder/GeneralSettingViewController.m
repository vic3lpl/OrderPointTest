//
//  GeneralSettingViewController.m
//  IpadOrder
//
//  Created by IRS on 8/25/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "GeneralSettingViewController.h"
#import <FMDB.h>
#import "LibraryAPI.h"
#import "RoundingViewController.h"
#import <MBProgressHUD.h>

@interface GeneralSettingViewController ()
{
    FMDatabase *dbGs;
    NSString *dbPath;
    NSString *terminalType;
    int textViewTag;
}
@end

@implementation GeneralSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self setTitle:@"General Setting"];
    NSLog(@"ffffff");
    textViewTag = 0;
    dbPath = [[LibraryAPI sharedInstance]getDbPath];
    terminalType = [[LibraryAPI sharedInstance]getWorkMode];
    
    UIBarButtonItem *addBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(editGeneralSetting:)];
    self.navigationItem.rightBarButtonItem = addBtn;
    
    self.textServiceGst.delegate = self;
    self.textDefaultGSTCode.delegate = self;
    self.textDefaultSVGCode.delegate = self;
    self.textKioskName.delegate = self;
    //self.textServiceGst.enabled = NO;
    
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    //self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:34/255.0 green:171/255.0 blue:241/255.0 alpha:1.0];
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.translucent = NO;
    
    self.viewGeneralBg.layer.cornerRadius = 20.0;
    self.viewGeneralBg.layer.masksToBounds = YES;
    
    UIGraphicsBeginImageContext(self.view.frame.size);
    [[UIImage imageNamed:@"IO_Background1024"] drawInRect:self.view.bounds];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:image];
    
    [self getGeneralSetting];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - sqlie3

-(void)getGeneralSetting
{
    FMDatabase *db = [FMDatabase databaseWithPath:dbPath];
    
    if (![db open]) {
        NSLog(@"Fail To Open");
        return;
    }
    
    [[LibraryAPI sharedInstance]setDbPath:dbPath];
    
    FMResultSet *rs = [db executeQuery:@"select * from GeneralSetting"];
    
    if ([rs next]) {
        self.switchTax.on = [rs boolForColumn:@"GS_TaxInclude"];
        self.switchServiceGst.on = [rs boolForColumn:@"GS_ServiceTaxGst"];
        self.textServiceGst.text = [rs stringForColumn:@"GS_ServiceGstCode"];
        self.switchKitchenReceiptGroup.on = [rs boolForColumn:@"GS_KitchenReceiptGrouping"];
        self.textCurrency.text = [rs stringForColumn:@"GS_Currency"];
        self.switchEnableGST.on = [rs boolForColumn:@"GS_EnableGST"];
        self.switchEnableSVG.on = [rs boolForColumn:@"GS_EnableSVG"];
        self.textDefaultGSTCode.text = [rs stringForColumn:@"GS_DefaultGSTCode"];
        self.textDefaultSVGCode.text = [rs stringForColumn:@"GS_DefaultSVGCode"];
        self.switchEnableKioskMode.on = [rs intForColumn:@"GS_EnableKioskMode"];
        self.textKioskName.text = [rs stringForColumn:@"GS_DefaultKioskName"];
        if (self.switchEnableGST.isOn) {
            self.textDefaultGSTCode.hidden = false;
        }
        else
        {
            self.textDefaultGSTCode.hidden = true;
        }
        
        if (self.switchEnableSVG.isOn) {
            self.textDefaultSVGCode.hidden = false;
        }
        else
        {
            self.textDefaultSVGCode.hidden = true;
        }
        
        if (self.switchEnableKioskMode.isOn) {
            self.textKioskName.hidden = false;
        }
        else
        {
            self.textKioskName.hidden = true;
        }
        
    }
    
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
    }
    
    [rs close];
    [db close];
}

-(void)editGeneralSetting:(id)sender
{
    if ([[LibraryAPI sharedInstance]getUserRole] == 0) {
        [self showAlertView:@"You have no permission to edit data" title:@"Warning"];
        return;
    }
    
    if ([self.textCurrency.text length] == 0 || [self.textCurrency.text isEqualToString:@""])
    {
        [self showAlertView:@"Currency cannot empty" title:@"Warning"];
        return;
    }
    
    if (self.switchEnableGST.isOn)
    {
        if ([self.textDefaultGSTCode.text length] == 0 || [self.textDefaultGSTCode.text isEqualToString:@""])
        {
            [self showAlertView:@"Default GST code cannot empty" title:@"Warning"];
            return;
        }
        [[LibraryAPI sharedInstance] setServiceTaxGstCode:self.textServiceGst.text];
    }
    else
    {
        self.textDefaultGSTCode.text = @"";
        [[LibraryAPI sharedInstance] setServiceTaxGstCode:nil];
    }
    
    if (self.switchEnableSVG.isOn)
    {
        if ([self.textDefaultSVGCode.text length] == 0 || [self.textDefaultSVGCode.text isEqualToString:@""])
        {
            [self showAlertView:@"Default SVG code cannot empty" title:@"Warning"];
            return;
        }
    }
    else
    {
        self.textDefaultSVGCode.text = @"";
    }
    
    if (self.switchEnableKioskMode.isOn)
    {
        if ([self.textKioskName.text length] == 0 || [self.textKioskName.text isEqualToString:@""])
        {
            [self showAlertView:@"Default table cannot empty" title:@"Warning"];
            return;
        }
    }
    else
    {
        self.textKioskName.text = @"";
    }
    
    FMDatabase *db = [FMDatabase databaseWithPath:dbPath];
    if ([terminalType isEqualToString:@"Main"]) {

        if (![db open]) {
            NSLog(@"Fail To Open");
            return;
        }
        
        BOOL noDbError = [db executeUpdate:@"Update GeneralSetting set GS_TaxInclude = ?"
                          " , GS_ServiceTaxGst = ?, GS_ServiceGstCode = ?, GS_KitchenReceiptGrouping = ?"
                          " , GS_Currency = ?, GS_EnableGST = ?, GS_DefaultGSTCode = ?, GS_EnableSVG = ?, GS_DefaultSVGCode = ?,GS_EnableKioskMode = ?, GS_DefaultKioskName = ? "
                          ,[NSNumber numberWithBool:self.switchTax.on],[NSNumber numberWithBool:self.switchServiceGst.on], self.textServiceGst.text, [NSNumber numberWithInt:self.switchKitchenReceiptGroup.on], self.textCurrency.text, [NSNumber numberWithInt:self.switchEnableGST.on],self.textDefaultGSTCode.text,[NSNumber numberWithInt:self.switchEnableSVG.on], self.textDefaultSVGCode.text,[NSNumber numberWithInt:self.switchEnableKioskMode.on],self.textKioskName.text];
        
        if (noDbError) {
            if (self.switchTax.isOn) {
                [[LibraryAPI sharedInstance]setTaxType:@"Inc"];
            }
            else
            {
                [[LibraryAPI sharedInstance]setTaxType:@"IEx"];
            }
            
            
            if (self.switchKitchenReceiptGroup.isOn) {
                [[LibraryAPI sharedInstance]setKitchenReceiptGroup:self.switchKitchenReceiptGroup.on];
            }
            else
            {
                [[LibraryAPI sharedInstance]setKitchenReceiptGroup:self.switchKitchenReceiptGroup.on];
            }
            [[LibraryAPI sharedInstance]setKioskMode:self.switchEnableKioskMode.on];
            [[LibraryAPI sharedInstance] setCurrencySymbol:self.textCurrency.text];
            [[LibraryAPI sharedInstance] setEnableGst:self.switchEnableGST.on];
            
            [self showAlertView:@"Data update" title:@"Updated"];
        }
        else
        {
            [self showAlertView:[db lastErrorMessage] title:@"Fail"];
        }
        //[rs close];
        [db close];

    }
    else
    {
        if (![db open]) {
            NSLog(@"Fail To Open");
            return;
        }
        
        [db executeUpdate:@"Update GeneralSetting set"
         " GS_EnableKioskMode = ?, GS_DefaultKioskName = ? "
         ,[NSNumber numberWithInt:self.switchEnableKioskMode.on],self.textKioskName.text];
        
        if ([db hadError]) {
            [self showAlertView:[db lastErrorMessage] title:@"Fail"];
            
        }
        else
        {
            [[LibraryAPI sharedInstance]setKioskMode:self.switchEnableKioskMode.on];
            [self showAlertView:@"Only Non Table Service is updated" title:@"Information"];
        }
        
    }
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
    UIAlertController * alert = [[LibraryAPI sharedInstance] showAlertViewWithMsg:msg Title:title];
    
    [self presentViewController:alert animated:YES completion:nil];
    
    alert = nil;
}


-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    SelectCatTableViewController *selectCatTableViewController = [[SelectCatTableViewController alloc]init];
    selectCatTableViewController.delegate = self;
    textViewTag = textField.tag;
    
    //self.popOver = [[UIPopoverController alloc]initWithContentViewController:selectCatTableViewController];
    
    if (textField.tag == 0) {
        
        selectCatTableViewController.filterType = @"Gst";
        [self.view endEditing:YES];
        
        selectCatTableViewController.modalPresentationStyle = UIModalPresentationPopover;
        selectCatTableViewController.popoverPresentationController.sourceView = self.textServiceGst;
        selectCatTableViewController.popoverPresentationController.sourceRect = CGRectMake(self.textServiceGst.frame.size.width /
                                                                                           2, self.textServiceGst.frame.size.height / 2, 1, 1);
        [self presentViewController:selectCatTableViewController animated:YES completion:nil];
        
       
        return NO;
    }
    else if (textField.tag == 1) {
        
        selectCatTableViewController.filterType = @"Gst";
        [self.view endEditing:YES];
        
        selectCatTableViewController.modalPresentationStyle = UIModalPresentationPopover;
        selectCatTableViewController.popoverPresentationController.sourceView = self.textDefaultGSTCode;
        selectCatTableViewController.popoverPresentationController.sourceRect = CGRectMake(self.textDefaultGSTCode.frame.size.width /
                                                                                           2, self.textDefaultGSTCode.frame.size.height / 2, 1, 1);
        [self presentViewController:selectCatTableViewController animated:YES completion:nil];
        
        
        return NO;
    }
    else if (textField.tag == 2) {
        
        selectCatTableViewController.filterType = @"Gst";
        [self.view endEditing:YES];
        
        selectCatTableViewController.modalPresentationStyle = UIModalPresentationPopover;
        selectCatTableViewController.popoverPresentationController.sourceView = self.textDefaultSVGCode;
        selectCatTableViewController.popoverPresentationController.sourceRect = CGRectMake(self.textDefaultSVGCode.frame.size.width /
                                                                                           2, self.textDefaultSVGCode.frame.size.height / 2, 1, 1);
        [self presentViewController:selectCatTableViewController animated:YES completion:nil];
        
        return NO;
    }
    else if (textField.tag == 3) {
        
        selectCatTableViewController.filterType = @"Kiosk";
        [self.view endEditing:YES];
        
        selectCatTableViewController.modalPresentationStyle = UIModalPresentationPopover;
        selectCatTableViewController.popoverPresentationController.sourceView = self.textKioskName;
        selectCatTableViewController.popoverPresentationController.sourceRect = CGRectMake(self.textKioskName.frame.size.width /
                                                                                           2, self.textKioskName.frame.size.height / 2, 1, 1);
        [self presentViewController:selectCatTableViewController animated:YES completion:nil];
        
        return NO;
    }
    else
    {
        return YES;
    }
}

#pragma delegate
-(void)getSelectedCategory:(NSString *)field1 field2:(NSString *)field2 field3:(NSString *)field3 filterType:(NSString *)filterType
{
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    if (textViewTag == 0) {
        self.textServiceGst.text = field1;
    }
    else if (textViewTag == 1)
    {
        self.textDefaultGSTCode.text = field1;
    }
    else if (textViewTag == 2)
    {
        self.textDefaultSVGCode.text = field1;
    }
    else if (textViewTag == 3)
    {
        
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
        
        [queue inDatabase:^(FMDatabase *db) {
            FMResultSet *rs = [db executeQuery:@"Select * from SalesOrderHdr where SOH_Table = ? and SOH_Status = ?",field1,@"New"];
            
            if ([rs next]) {
                [self showAlertView:@"Table in used" title:@"Warning"];
            }
            else
            {
                self.textKioskName.text = field1;
            }
            
        }];
    
    }
    
    //[self.popOver dismissPopoverAnimated:YES];
    
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

#pragma mark - switch action

- (IBAction)switchServiceGstAction:(id)sender {
    if (self.switchServiceGst.on) {
        self.textServiceGst.enabled = YES;
    }
    else
    {
        self.textServiceGst.enabled = NO;
    }
}

- (IBAction)switchActionEnableGST:(id)sender {
    if (self.switchEnableGST.isOn) {
        
        self.textDefaultGSTCode.hidden = false;
    }
    else
    {
        self.textDefaultGSTCode.hidden = true;
    }
}
- (IBAction)switchActionEnableSVG:(id)sender {
    if (self.switchEnableSVG.isOn) {
        
        self.textDefaultSVGCode.hidden = false;
    }
    else
    {
        self.textDefaultSVGCode.hidden = true;
    }
}
- (IBAction)switchActionEnableKioskMode:(id)sender {
    if (self.switchEnableKioskMode.isOn) {
        [self insertDefaultTableToKiosk];
        
    }
    else
    {
        self.textKioskName.hidden = true;
    }
}

-(void)insertDefaultTableToKiosk
{
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        NSString *sectionName;
        
        FMResultSet *rsComp = [db executeQuery:@"Select * from Company"];
        
        if (![rsComp next]) {
            self.switchEnableKioskMode.on = 0;
            [self showAlertView:@"Company cannot empty" title:@"Warning"];
            return;
        }
        [rsComp close];
        
        FMResultSet *rsCat = [db executeQuery:@"Select * from ItemCatg"];
        
        if (![rsCat next]) {
            self.switchEnableKioskMode.on = 0;
            [self showAlertView:@"Item category cannot empty" title:@"Warning"];
            return;
        }
        [rsCat close];
        
        FMResultSet *rsTable = [db executeQuery:@"Select * from TablePlan"];
        
        if (![rsTable next]) {
            
            [rsTable close];
            
            FMResultSet *rsSection = [db executeQuery:@"Select TS_Name from TableSection limit 1"];
            
            if ([rsSection next]) {
                sectionName = [rsSection stringForColumn:@"TS_Name"];
            }
            [rsSection close];
            
            [db executeUpdate:@"Insert into TablePlan ("
             "TP_Name, TP_Description,TP_Scale, TP_Rotate, TP_Xis, TP_Yis,TP_Section,TP_Percent,TP_Overide, TP_ImgName, TP_DineType) values ("
             "?,?,?,?,?,?,?,?,?,?,?)",@"Default", @"-",[NSNumber numberWithFloat:1.00],[NSNumber numberWithFloat:0.00],[NSNumber numberWithFloat:300.00],[NSNumber numberWithFloat:300.00],sectionName,@"",[NSNumber numberWithInt:0],@"Table1", [NSNumber numberWithInt:0]];
            
            if ([db hadError]) {
                [self showAlertView:[db lastErrorMessage] title:@"Warning"];
            }
            else
            {
                self.textKioskName.hidden = false;
            }
        }
        else
        {
            [rsTable close];
            self.textKioskName.hidden = false;
        }
        
    }];
    
    [queue close];
    
}
@end
