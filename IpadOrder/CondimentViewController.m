//
//  CondimentViewController.m
//  IpadOrder
//
//  Created by IRS on 03/09/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import "CondimentViewController.h"
#import "LibraryAPI.h"
#import <FMDB.h>
#import "CondimentDetailViewController.h"

@interface CondimentViewController ()
{
    FMDatabase *dbTable;
    NSString *dbPath;
    NSMutableArray *condimentArray;
    NSString *alertType;
    NSString *cdCode;
    
}
@end

@implementation CondimentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    condimentArray = [[NSMutableArray alloc] init];
    dbPath = [[LibraryAPI sharedInstance] getDbPath];
    self.tableCondimentDetail.delegate  =self;
    self.tableCondimentDetail.dataSource = self;
    [self setTitle:@"Condiment"];
    
    UIBarButtonItem *addBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addCondimentDetail)];
    self.navigationItem.rightBarButtonItem = addBtn;
    
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0];
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
}

-(void)viewWillAppear:(BOOL)animated
{
    [self getCondimentDetail];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)addCondimentDetail
{
    if ([[[LibraryAPI sharedInstance] getWorkMode] isEqualToString:@"Main"]) {
        CondimentDetailViewController *condimentDetailViewController = [[CondimentDetailViewController alloc]init];
        condimentDetailViewController.cdAction = @"New";
        [self.navigationController pushViewController:condimentDetailViewController animated:NO];
    }
    else
    {
        [self showAlertView:@"Terminal cannot add condiment" title:@"Warning"];
        //[self showMyHudMessageBoxWithMessage:@"Terminal Cannot Add Tax"];
    }
    
    
}

#pragma mark - sqlite

-(void)getCondimentDetail
{
    dbTable = [FMDatabase databaseWithPath:dbPath];
    
    //BOOL dbHadError;
    
    if (![dbTable open]) {
        NSLog(@"Fail To Open");
        return;
    }
    
    [condimentArray removeAllObjects];
    FMResultSet *rs = [dbTable executeQuery:@"Select CD_Code,CD_Description,CD_Price,IFNULL(CD_CondimentHdrCode,'-') as CD_CondimentHdrCode, CH_Description from CondimentDtl CD left join CondimentHdr CH on CD.CD_CondimentHdrCode = CH.CH_Code"];
    
    while ([rs next]) {
        [condimentArray addObject:[rs resultDictionary]];
    }
    
    [rs close];
    [dbTable close];
    [self.tableCondimentDetail reloadData];
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
    cell.textLabel.text = [[condimentArray objectAtIndex:indexPath.row] objectForKey:@"CD_Description"];
    cell.textLabel.textColor = [UIColor colorWithRed:36/255.0 green:36/255.0 blue:36/255.0 alpha:1.0];
    cell.detailTextLabel.textColor = [UIColor colorWithRed:128/255.0 green:128/255.0 blue:128/255.0 alpha:1.0];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@%0.2f",[[condimentArray objectAtIndex:indexPath.row] objectForKey:@"CH_Description"],[[LibraryAPI sharedInstance] getCurrencySymbol],[[[condimentArray objectAtIndex:indexPath.row] objectForKey:@"CD_Price"] doubleValue]];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[[LibraryAPI sharedInstance] getWorkMode] isEqualToString:@"Main"]) {
        CondimentDetailViewController *condimentDetailViewController = [[CondimentDetailViewController alloc]init];
        condimentDetailViewController.cdAction = @"Edit";
        condimentDetailViewController.cdCode = [[condimentArray objectAtIndex:indexPath.row] objectForKey:@"CD_Code"];
        //[itemMastEditViewController setModalPresentationStyle:UIModalPresentationFormSheet];
        [self.navigationController pushViewController:condimentDetailViewController animated:NO];
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
        
        if ([[[LibraryAPI sharedInstance] getWorkMode] isEqualToString:@"Main"]) {
            alertType = @"Delete";
            cdCode = [[condimentArray objectAtIndex:indexPath.row] objectForKey:@"CD_Code"];
            
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"Warning"
                                         message:@"Sure To Delete ?"
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* yesButton = [UIAlertAction
                                        actionWithTitle:@"OK"
                                        style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * action) {
                                            [self condimentAlertActionSelection];
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
    
    UIAlertController * alert = [[LibraryAPI sharedInstance] showAlertViewWithMsg:msg Title:title];
    
    [self presentViewController:alert animated:YES completion:nil];
    
}


#pragma mark - alertview response
- (void)condimentAlertActionSelection
{
    /*
    if ([alertType isEqualToString:@"Normal"]) {
        return;
    }
    else
    {
        
       
        
    }
    */
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
        [queue inDatabase:^(FMDatabase *db) {
            
            [db executeUpdate:@"delete from CondimentDtl where CD_Code = ?",cdCode];
            if ([db hadError]) {
                [self showAlertView:[db lastErrorMessage] title:@"Warning"];
            }
            else
            {
                //[self showAlertView:[db lastErrorMessage] title:@"Warning"];
            }
            
        }];
    
    [queue close];
    [self getCondimentDetail];
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
