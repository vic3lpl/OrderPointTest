//
//  UserNameSaveViewController.m
//  IpadOrder
//
//  Created by IRS on 7/7/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "UserNameSaveViewController.h"
#import <FMDB.h>
#import "LibraryAPI.h"

@interface UserNameSaveViewController ()
{
    FMDatabase *dbUserName;
    NSString *dbPath;
    BOOL dbHadError;
    BOOL checkTextEmpty;
}

@end

@implementation UserNameSaveViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self setTitle:@"User"];
    UIBarButtonItem *addBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(editUser:)];
    self.navigationItem.rightBarButtonItem = addBtn;
    dbPath = [[LibraryAPI sharedInstance]getDbPath];
    
    self.viewUserBg.layer.cornerRadius = 20.0;
    self.viewUserBg.layer.masksToBounds = YES;
    
    /*
    UIGraphicsBeginImageContext(self.view.frame.size);
    [[UIImage imageNamed:@"IO_Background1024"] drawInRect:self.view.bounds];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:image];
    */
    [self getOneUserName];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)editUser:(id)sender
{
    //NSLog(@"dddddd %d",[[LibraryAPI sharedInstance]getUserRole]);
    if (_userRole == 0) {
        [self showAlertView:@"You have no permission to edit data" title:@"Warning"];
        return;
    }
    
    if ([self.userNameAction isEqualToString:@"New"]) {
        [self saveUserName];
    }
    else if ([self.userNameAction isEqualToString:@"Edit"])
    {
        [self updateUserName];
    }
}

#pragma mark - sqlite

-(void)getOneUserName
{
    dbUserName = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbUserName open]) {
        NSLog(@"Fail To Open Db");
        return;
    }
    
    FMResultSet *rs = [dbUserName executeQuery:@"Select * from UserLogin where UL_ID = ?", self.userName];
    
    if ([rs next]) {
        self.textUserName.enabled = NO;
        self.textUserName.text = [rs stringForColumn:@"UL_ID"];
        self.textPassword.text = [rs stringForColumn:@"UL_Password"];
        self.textConfirmPassword.text = [rs stringForColumn:@"UL_Password"];
        self.segmentRole.selectedSegmentIndex = [rs intForColumn:@"UL_Role"];
        self.segmentReprintBillPermission.selectedSegmentIndex = [rs intForColumn:@"UL_ReprintBillPermission"];
    }
    
    [rs close];
    [dbUserName close];
    
}

-(void)saveUserName
{
    checkTextEmpty = [self checkTextField];
    
    if (!checkTextEmpty) {
        return;
    }
    
    //dbUserName = [FMDatabase databaseWithPath:dbPath];
    
    ////if (![dbUserName open]) {
    //    NSLog(@"Failt To Open DB");
    //    return;
    //}
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"Select * from UserLogin where UL_ID = ?",self.textUserName.text.uppercaseString];
        
        if ([rs next]) {
            [rs close];
            [self showAlertView:@"Duplicate id" title:@"Fail"];
            return;
        }
        else
        {
            [rs close];
        }
        
        
        dbHadError = [db executeUpdate:@"Insert into UserLogin ("
                      "UL_ID, UL_Password,UL_Role, UL_ReprintBillPermission) values ("
                      "?,?,?,?)",self.textUserName.text.uppercaseString, self.textPassword.text,[NSNumber numberWithInteger:self.segmentRole.selectedSegmentIndex],[NSNumber numberWithInteger:self.segmentReprintBillPermission.selectedSegmentIndex]];
        if (dbHadError) {
            //[self showAlertView:@"Data Saved" title:@"Success"];
            [self.navigationController popViewControllerAnimated:YES];
        }
        else
        {
            [self showAlertView:[dbUserName lastErrorMessage] title:@"Error"];
        }
    }];
    
    [queue close];
    //[dbUserName close];
    
    
}

-(void)updateUserName
{
    
    checkTextEmpty = [self checkTextField];
    
    if (!checkTextEmpty) {
        return;
    }
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        [db executeUpdate:@"Update UserLogin set UL_Password = ?,UL_Role = ?, UL_ReprintBillPermission = ? where UL_ID = ?",self.textPassword.text,[NSNumber numberWithInteger:self.segmentRole.selectedSegmentIndex],[NSNumber numberWithInteger:self.segmentReprintBillPermission.selectedSegmentIndex],self.userName];
        if ([db hadError]) {
            [self showAlertView:[db lastErrorMessage] title:@"Error"];
        }
        else
        {
            
        }
        
        if (self.segmentRole.selectedSegmentIndex == 0) {
            FMResultSet *rsUser = [db executeQuery:@"Select count(*) as TotalAdmin from UserLogin where UL_Role = 1"];
            
            if ([rsUser next]) {
                if ([rsUser intForColumn:@"TotalAdmin"] >= 1) {
                    //[[LibraryAPI sharedInstance]setUserRole:self.segmentRole.selectedSegmentIndex];
                    [self.navigationController popViewControllerAnimated:YES];
                }
                else
                {
                    *rollback = YES;
                    [self showAlertView:@"At least 1 admin user needed" title:@"Information"];
                    //return;
                }
                
            }
            [rsUser close];
        }
        else
        {
            //[[LibraryAPI sharedInstance]setUserRole:self.segmentRole.selectedSegmentIndex];
            [self.navigationController popViewControllerAnimated:YES];
        }
        
    }];

    
}

#pragma mark - alertView

-(void)showAlertView:(NSString *)msg title:(NSString *)title
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:msg
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

#pragma mark - check empty field

-(BOOL)checkTextField
{
    if ([self.textUserName.text isEqualToString:@""]) {
        [self showAlertView:@"UserName cannot empty" title:@"Warning"];
        return NO;
    }
    else if ([self.textPassword.text isEqualToString:@""])
    {
        [self showAlertView:@"Password cannot empty" title:@"Warning"];
        return NO;
    }
    else if ([self.textConfirmPassword.text isEqualToString:@""])
    {
        [self showAlertView:@"Confirm password cannot empty" title:@"Warning"];
        return NO;
    }
    else if (![self.textPassword.text isEqualToString: self.textConfirmPassword.text ])
    {
        [self showAlertView:@"New password & confirm password not match" title:@"Warning"];
        return NO;
    }
    return  YES;
}

#pragma mark - touch backgound
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
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
