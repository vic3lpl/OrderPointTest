//
//  CondimentGroupViewController.m
//  IpadOrder
//
//  Created by IRS on 02/09/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import "CondimentGroupViewController.h"
#import <FMDB.h>
#import "LibraryAPI.h"
#import "ItemTaxEditViewController.h"
#import <MBProgressHUD.h>
#import "CondimentGroupEditViewController.h"

@interface CondimentGroupViewController ()
{
    NSString *dbPath;
    FMDatabase *dbTable;
    NSMutableArray *condimentArray;
    NSString *chCode;
    NSString *terminalType;
    NSString *alertType;
}
@end

@implementation CondimentGroupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    UIBarButtonItem *addBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addCondimentGroup:)];
    self.navigationItem.rightBarButtonItem = addBtn;
    condimentArray = [[NSMutableArray alloc]init];
    self.TableCondimentGroup.delegate = self;
    self.TableCondimentGroup.dataSource = self;
    terminalType = [[LibraryAPI sharedInstance] getWorkMode];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0];
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    self.TableCondimentGroup.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    dbPath = [[LibraryAPI sharedInstance]getDbPath];
    [self setTitle:@"Condiment Group"];
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [self getCondimentGroup];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)addCondimentGroup:(id)sender
{
    if ([terminalType isEqualToString:@"Main"]) {
        
        CondimentGroupEditViewController *condimentGroupEditViewController = [[CondimentGroupEditViewController alloc]init];
        condimentGroupEditViewController.action = @"New";
        //[itemMastEditViewController setModalPresentationStyle:UIModalPresentationFormSheet];
        [self.navigationController pushViewController:condimentGroupEditViewController animated:NO];
    }
    else
    {
        [self showAlertView:@"Terminal cannot access" title:@"Warning"];
        //[self showMyHudMessageBoxWithMessage:@"Terminal Cannot Access"];
    }
}

#pragma mark - sqlite
-(void)getCondimentGroup
{
    dbTable = [FMDatabase databaseWithPath:dbPath];
    
    //BOOL dbHadError;
    
    if (![dbTable open]) {
        NSLog(@"Fail To Open");
        return;
    }
    
    [condimentArray removeAllObjects];
    FMResultSet *rs = [dbTable executeQuery:@"Select * from CondimentHdr"];
    
    while ([rs next]) {
        [condimentArray addObject:[rs resultDictionary]];
    }
    
    [rs close];
    [dbTable close];
    [self.TableCondimentGroup reloadData];
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
    return [condimentArray count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *Identifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:Identifier];
    if (cell == nil) {
        //        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:Identifier] autorelease];
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:Identifier];
    }
    cell.textLabel.text = [[condimentArray objectAtIndex:indexPath.row] objectForKey:@"CH_Description"];
    cell.textLabel.textColor = [UIColor colorWithRed:36/255.0 green:36/255.0 blue:36/255.0 alpha:1.0];
    cell.detailTextLabel.textColor = [UIColor colorWithRed:128/255.0 green:128/255.0 blue:128/255.0 alpha:1.0];
    cell.detailTextLabel.text = [[condimentArray objectAtIndex:indexPath.row] objectForKey:@"CH_Code"];;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([terminalType isEqualToString:@"Main"]) {
        CondimentGroupEditViewController *condimentGroupEditViewController = [[CondimentGroupEditViewController alloc]init];
        condimentGroupEditViewController.action = @"Edit";
        condimentGroupEditViewController.chCode = [[condimentArray objectAtIndex:indexPath.row] objectForKey:@"CH_Code"];
        //[itemMastEditViewController setModalPresentationStyle:UIModalPresentationFormSheet];
        [self.navigationController pushViewController:condimentGroupEditViewController animated:NO];
    }
    else
    {
        [self showAlertView:@"Terminal cannot access" title:@"Warning"];
    }
    
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //remove the deleted object from your data source.
        //If your data source is an NSMutableArray, do this
        if ([terminalType isEqualToString:@"Main"]) {
            alertType = @"Delete";
            chCode = [[condimentArray objectAtIndex:indexPath.row] objectForKey:@"CH_Code"];
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"Warning"
                                         message:@"Sure To Delete ?"
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* yesButton = [UIAlertAction
                                        actionWithTitle:@"OK"
                                        style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * action) {
                                            [self alertActionCondimentGroupSelection];
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
        }
        else
        {
            
            [self showAlertView:@"Terminal cannot delete condiment group" title:@"Warning"];
        }
        
        
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 54;
    //return 360;
}

#pragma mark - show alertview
-(void)showAlertView:(NSString *)msg title:(NSString *)title
{
    alertType = @"Normal";
    /*
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:msg
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
     */
    UIAlertController *alert = [[LibraryAPI sharedInstance] showAlertViewWithMsg:msg Title:title];
    [self presentViewController:alert animated:NO completion:nil];
}

#pragma mark - alertview response
- (void)alertActionCondimentGroupSelection
{
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
        [queue inDatabase:^(FMDatabase *db) {
            FMResultSet *rs = [db executeQuery:@"Select * from ItemCondiment where IC_CondimentHdrCode = ? ",chCode];
            
            if ([rs next]) {
                [rs close];
                [self showAlertView:@"Cannot delete. This condiment has assign to particular item." title:@"Warning"];
                return;
            }
            else
            {
                [rs close];
                [db executeUpdate:@"delete from CondimentHdr where CH_Code = ?",chCode];
                if ([db hadError]) {
                    [self showAlertView:[db lastErrorMessage] title:@"Warning"];
                    return;
                }
                else
                {
                    [db executeUpdate:@"delete from CondimentDtl where CD_CondimentHdrCode = ?",chCode];
                    if ([db hadError]) {
                        [self showAlertView:[db lastErrorMessage] title:@"Warning"];
                        return;
                    }
                    
                }
            }
            
        }];
    
    
    [queue close];
    [self getCondimentGroup];
    
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
