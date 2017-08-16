//
//  UserNameViewController.m
//  IpadOrder
//
//  Created by IRS on 7/7/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "UserNameViewController.h"
#import "UserNameSaveViewController.h"
#import "LibraryAPI.h"
#import <FMDB.h>
#import <MBProgressHUD.h>

@interface UserNameViewController ()
{
    NSString *dbPath;
    FMDatabase *dbUser;
    NSMutableArray *userNameArray;
    NSString *userName;
    NSString *terminalType;
    NSString *alertFlag;
}
//@property NSMutableArray *userNameArray;
@end

@implementation UserNameViewController

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    dbPath = [[LibraryAPI sharedInstance]getDbPath];
    terminalType = [[LibraryAPI sharedInstance] getWorkMode];
    if (self) {
        userNameArray = [[NSMutableArray alloc]init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.userTableView.delegate = self;
    self.userTableView.dataSource = self;
    // Do any additional setup after loading the view from its nib.
    [self setTitle:@"User List"];
    UIBarButtonItem *addBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addUser:)];
    self.navigationItem.rightBarButtonItem = addBtn;
    
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    //self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:34/255.0 green:171/255.0 blue:241/255.0 alpha:1.0];
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.translucent = NO;
    
    self.userTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

-(void)viewWillAppear:(BOOL)animated
{
    [self checkUserLogin];
}

-(void)viewDidLayoutSubviews
{
    if ([self.userTableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.userTableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([self.userTableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.userTableView setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)addUser:(id)sender
{
    if ([terminalType isEqualToString:@"Main"]) {
        UserNameSaveViewController *userSaveViewController = [[UserNameSaveViewController alloc]init];
        userSaveViewController.userNameAction = @"New";
        userSaveViewController.userRole = [[LibraryAPI sharedInstance] getUserRole];
        [self.navigationController pushViewController:userSaveViewController animated:YES];
    }
    else
    {
        //[self showMyHudMessageBoxWithMessage:@"Terminal Cannot Add User"];
        [self showAlertView:@"Terminal cannot add user" title:@"Warning"];
    }
    
}

-(void)checkUserLogin
{
    dbUser = [FMDatabase databaseWithPath:dbPath];
    
    //BOOL dbHadError;
    
    if (![dbUser open]) {
        NSLog(@"Fail To Open");
        return;
    }
    
    [userNameArray removeAllObjects];
    FMResultSet *rs = [dbUser executeQuery:@"Select * from UserLogin"];
    
    while ([rs next]) {
        [userNameArray addObject:[rs resultDictionary]];
    }
    
    [rs close];
    [dbUser close];
    [self.userTableView reloadData];
}

#pragma mark - Table View

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return userNameArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = [[userNameArray objectAtIndex:indexPath.row] objectForKey:@"UL_ID"];
    cell.textLabel.textColor = [UIColor colorWithRed:36/255.0 green:36/255.0 blue:36/255.0 alpha:1.0];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([terminalType isEqualToString:@"Main"]) {
        UserNameSaveViewController *userSaveViewController = [[UserNameSaveViewController alloc]init];
        userSaveViewController.userNameAction = @"Edit";
        userSaveViewController.userName = [[userNameArray objectAtIndex:indexPath.row]objectForKey:@"UL_ID"];
        userSaveViewController.userRole = [[LibraryAPI sharedInstance] getUserRole];
        [self.navigationController pushViewController:userSaveViewController animated:NO];
    }
    else
    {
        //[self showMyHudMessageBoxWithMessage:@"Terminal Cannot Access"];
        [self showAlertView:@"Terminal cannot access" title:@"Warning"];
    }
    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        if ([terminalType isEqualToString:@"Main"]) {
            userName = [[userNameArray objectAtIndex:indexPath.row] objectForKey:@"UL_ID"];
            
            if ([userName isEqualToString:@"ADMIN"]) {
                return;
            }
            alertFlag = @"Delete";
            
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"Warning"
                                         message:@"Sure To Delete ?"
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* yesButton = [UIAlertAction
                                        actionWithTitle:@"OK"
                                        style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * action) {
                                            [self userNameAlertActionSelction];
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
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning"
                                                            message:@"Sure To Delete ?"
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:@"Cancel",nil];
            [alert show];
             */
        }
        else
        {
            //[self showMyHudMessageBoxWithMessage:@"Terminal Cannot Delete User"];
            [self showAlertView:@"Terminal cannot delete user" title:@"Warning"];
        }
        
        
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 54;
    //return 360;
}

#pragma mark - alertview response
- (void)userNameAlertActionSelction
{
    /*
    if ([alertFlag isEqualToString:@"Alert"]) {
        return;
    }
     */
    
    dbUser = [FMDatabase databaseWithPath:dbPath];
    BOOL dbHadError;
    if (![dbUser open]) {
        NSLog(@"Fail To Open");
        return;
    }
    
    //if (buttonIndex == 0) {
        
    dbHadError = [dbUser executeUpdate:@"delete from UserLogin where UL_ID = ?",userName];
    //}
    
    
    [dbUser close];
    [self checkUserLogin];
    //[self.catTableView reloadData];
    
    
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

#pragma mark - alertView

-(void)showAlertView:(NSString *)msg title:(NSString *)title
{
    alertFlag = @"Alert";
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
