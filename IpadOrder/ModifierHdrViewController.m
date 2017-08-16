//
//  ModifierHdrViewController.m
//  IpadOrder
//
//  Created by IRS on 07/03/2017.
//  Copyright © 2017 IrsSoftware. All rights reserved.
//

#import "ModifierHdrViewController.h"
#import "LibraryAPI.h"
#import <FMDB.h>
#import "ModifierGroupDetailViewController.h"

@interface ModifierHdrViewController ()
{
    NSMutableArray *modifierHdrArray;
    long sectionSelectedIndex;
    BOOL dbNoError;
    NSString *dbPath;
    FMDatabase *dbTable;
    NSString *mGCode;
}
@end

@implementation ModifierHdrViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self setTitle:@"Modifier Group"];
    
    dbPath = [[LibraryAPI sharedInstance]getDbPath];
    
    self.tableViewModifierHdr.delegate = self;
    self.tableViewModifierHdr.dataSource = self;
    
    self.tableViewModifierHdr.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    UIBarButtonItem *addBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addModifierGroup:)];
    self.navigationItem.rightBarButtonItem = addBtn;
    
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0];
    self.navigationController.navigationBar.translucent = NO;
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    
}

-(void)viewDidAppear:(BOOL)animated
{
    modifierHdrArray = [[NSMutableArray alloc]init];
    [self checkModifierHdr];
}

-(void)addModifierGroup:id{
    ModifierGroupDetailViewController *modifierGroupDetailViewController = [[ModifierGroupDetailViewController alloc]init];
    modifierGroupDetailViewController.mGHUserAction = @"Add";
    [self.navigationController pushViewController:modifierGroupDetailViewController animated:NO];
    //[self.navigationController presentViewController:modifierGroupDetailViewController animated:NO completion:nil];
}

-(void)checkModifierHdr
{
    dbTable = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTable open]) {
        NSLog(@"Fail To Open");
        return;
    }
    
    [modifierHdrArray removeAllObjects];
    
    FMResultSet *rs = [dbTable executeQuery:@"Select * from ModifierHdr"];
    
    while ([rs next]) {
        [modifierHdrArray addObject:[rs resultDictionary]];
    }
    
    [rs close];
    [dbTable close];
    [self.tableViewModifierHdr reloadData];
    
}

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
    return [modifierHdrArray count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *Identifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:Identifier];
    if (cell == nil) {
        //        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:Identifier] autorelease];
        //cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:Identifier];
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:Identifier];
    }
    cell.textLabel.text = [[modifierHdrArray objectAtIndex:indexPath.row] objectForKey:@"MH_Description"];
    //cell.textLabel.textColor = [UIColor colorWithRed:36/255.0 green:36/255.0 blue:36/255.0 alpha:1.0];
    cell.detailTextLabel.text = [[modifierHdrArray objectAtIndex:indexPath.row] objectForKey:@"MH_Code"];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ModifierGroupDetailViewController *modifierGroupDetailViewController = [[ModifierGroupDetailViewController alloc]init];
    modifierGroupDetailViewController.mGHCode = [[modifierHdrArray objectAtIndex:indexPath.row] objectForKey:@"MH_Code"];
    modifierGroupDetailViewController.mGHUserAction = @"Update";
    [self.navigationController pushViewController:modifierGroupDetailViewController animated:NO];
    
    modifierHdrArray = nil;
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 54;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        mGCode = [[modifierHdrArray objectAtIndex:indexPath.row] objectForKey:@"MH_Code"];
        if ([[[LibraryAPI sharedInstance] getWorkMode] isEqualToString:@"Main"]) {
            
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"Warning"
                                         message:@"Sure To Delete ?"
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* yesButton = [UIAlertAction
                                        actionWithTitle:@"OK"
                                        style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * action) {
                                            [self alertActionSelection];
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
            [self showAlertView:@"Terminal cannot delete item" title:@"Warning"];
        }
        
    }
}

- (void)alertActionSelection
{
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rs = [db executeQuery:@"Select * from PackageItemDtl where PD_ItemCode = ? limit 1",mGCode];
        
        if ([rs next]) {
            [self showAlertView:@"Data in used" title:@"Warning"];
            //return;
        }
        else
        {
            [db executeUpdate:@"delete from ModifierHdr where MH_Code = ?",mGCode];
            
            [db executeUpdate:@"delete from ModifierDtl where MD_MGCode = ?",mGCode];
        }
        
    }];
    
    [queue close];
    [self checkModifierHdr];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - alertView

-(void)showAlertView:(NSString *)msg title:(NSString *)title
{
    UIAlertController * alert = [[LibraryAPI sharedInstance] showAlertViewWithMsg:msg Title:title];
    
    [self presentViewController:alert animated:YES completion:nil];
    
    alert = nil;
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
