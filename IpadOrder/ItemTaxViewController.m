//
//  ItemTaxViewController.m
//  IpadOrder
//
//  Created by IRS on 7/10/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "ItemTaxViewController.h"
#import <FMDB.h>
#import "LibraryAPI.h"
#import "ItemTaxEditViewController.h"
#define TAG_DEl 1
#define TAG_CHECKDEL 2
#import <MBProgressHUD.h>

@interface ItemTaxViewController ()
{
    NSString *dbPath;
    FMDatabase *dbTax;
    NSMutableArray *taxArray;
    NSString *taxName;
    //BOOL allowDelTax;
    NSString *terminalType;
    NSString *alertFlag;
}
@end

@implementation ItemTaxViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    UIBarButtonItem *addBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addTax:)];
    self.navigationItem.rightBarButtonItem = addBtn;
    taxArray = [[NSMutableArray alloc]init];
    self.itemTaxTableView.delegate = self;
    self.itemTaxTableView.dataSource = self;
    terminalType = [[LibraryAPI sharedInstance] getWorkMode];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    //self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:34/255.0 green:171/255.0 blue:241/255.0 alpha:1.0];
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0];
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    self.itemTaxTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    dbPath = [[LibraryAPI sharedInstance]getDbPath];
    [self setTitle:@"Tax List"];
    
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [self checkItemTax];
}

-(void)viewDidLayoutSubviews
{
    if ([self.itemTaxTableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.itemTaxTableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([self.itemTaxTableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.itemTaxTableView setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)addTax:(id)sender
{
    if ([terminalType isEqualToString:@"Main"]) {
        ItemTaxEditViewController *itemTaxViewController = [[ItemTaxEditViewController alloc]init];
        itemTaxViewController.userTaxAction = @"New";
        [self.navigationController pushViewController:itemTaxViewController animated:YES];
    }
    else
    {
        [self showAlertView:@"Terminal cannot add tax" title:@"Warning"];
        //[self showMyHudMessageBoxWithMessage:@"Terminal Cannot Add Tax"];
    }
    
}

#pragma mark - sqlite

-(void)checkItemTax
{
    dbTax = [FMDatabase databaseWithPath:dbPath];
    
    //BOOL dbHadError;
    
    if (![dbTax open]) {
        NSLog(@"Fail To Open");
        return;
    }
    
    [taxArray removeAllObjects];
    FMResultSet *rs = [dbTax executeQuery:@"Select * from Tax"];
    
    while ([rs next]) {
        [taxArray addObject:[rs resultDictionary]];
    }
    
    [rs close];
    [dbTax close];
    [self.itemTaxTableView reloadData];
    
    
}

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
    return [taxArray count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *Identifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:Identifier];
    if (cell == nil) {
        //        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:Identifier] autorelease];
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:Identifier];
    }
    cell.textLabel.text = [[taxArray objectAtIndex:indexPath.row] objectForKey:@"T_Name"];
    cell.textLabel.textColor = [UIColor colorWithRed:36/255.0 green:36/255.0 blue:36/255.0 alpha:1.0];
    cell.detailTextLabel.textColor = [UIColor colorWithRed:128/255.0 green:128/255.0 blue:128/255.0 alpha:1.0];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%0.2f %@",[[[taxArray objectAtIndex:indexPath.row] objectForKey:@"T_Percent"] doubleValue],@"%"];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([terminalType isEqualToString:@"Main"]) {
        
        ItemTaxEditViewController *itemTaxEditViewController = [[ItemTaxEditViewController alloc]init];
        itemTaxEditViewController.userTaxAction = @"Edit";
        itemTaxEditViewController.taxName = [[taxArray objectAtIndex:indexPath.row]objectForKey:@"T_Name"];
        //[itemMastEditViewController setModalPresentationStyle:UIModalPresentationFormSheet];
        [self.navigationController pushViewController:itemTaxEditViewController animated:NO];
    }
    else
    {
        [self showAlertView:@"Terminal cannot access" title:@"Warning"];
        //[self showMyHudMessageBoxWithMessage:@"Terminal Cannot Access"];
    }
    
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //remove the deleted object from your data source.
        //If your data source is an NSMutableArray, do this
        if ([terminalType isEqualToString:@"Main"]) {
            alertFlag = @"Delete";
            taxName = [[taxArray objectAtIndex:indexPath.row] objectForKey:@"T_Name"];
            
            
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"Warning"
                                         message:@"Sure To Delete ?"
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* yesButton = [UIAlertAction
                                        actionWithTitle:@"OK"
                                        style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * action) {
                                            [self itemTaxAlertActionSelected];
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
            alert.tag = TAG_CHECKDEL;
            [alert show];
             */
        }
        else
        {
            //[self showMyHudMessageBoxWithMessage:@"Terminal Cannot Delete Tax"];
            [self showAlertView:@"Terminal cannot delete tax" title:@"Warning"];
        }
        
        
    }
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 54;
    //return 360;
}


#pragma mark - alertview response
- (void)itemTaxAlertActionSelected
{
    /*
    if ([alertFlag isEqualToString:@"Alert"]) {
        return;
    }
    */
    
        
    dbTax = [FMDatabase databaseWithPath:dbPath];
    //BOOL dbHadError;
    if (![dbTax open]) {
        NSLog(@"Fail To Open");
        //allowDelTax = NO;
        return;
    }
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"Select * from ItemMast where IM_Tax = ? or IM_ServiceTax = ?",taxName, taxName];
        
        if ([rs next]) {
            
            [rs close];
            [self showAlertView:@"Data in use" title:@"Warning"];
            
        }
        else
        {
            BOOL dbHadError = [dbTax executeUpdate:@"delete from Tax where T_Name = ?",taxName];
            if (dbHadError) {
                
            }
            else
            {
                
                [self showAlertView:[db lastErrorMessage] title:@"Warning"];
            }
        }
        
    }];
    
    
    [dbTax close];
    [queue close];
    [self checkItemTax];
    

    //[self.catTableView reloadData];
    
    
}
#pragma mark - show alertview
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


@end
