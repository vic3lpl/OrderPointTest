//
//  TablePlanViewController.m
//  IpadOrder
//
//  Created by IRS on 7/14/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "TablePlanViewController.h"
#import <FMDB.h>
#import "LibraryAPI.h"
#import <MBProgressHUD.h>

@interface TablePlanViewController ()
{
    NSString *dbPath;
    FMDatabase *dbTable;
    NSMutableArray *tableArray;
    NSString *userAction;
    long tableSelectedIndex;
}
@end

@implementation TablePlanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    UIBarButtonItem *addTable = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addTablePlan:)];
    self.navigationItem.rightBarButtonItem = addTable;
    self.tablePlanTableView.delegate = self;
    self.tablePlanTableView.dataSource = self;
    dbPath = [[LibraryAPI sharedInstance]getDbPath];
    tableArray = [[NSMutableArray alloc]init];
    
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:34/255.0 green:171/255.0 blue:241/255.0 alpha:1.0];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    //self.tablePlanTableView.separatorColor = [UIColor colorWithRed:13/255.0 green:149/255.0 blue:226/255.0 alpha:1.0];
    self.navigationController.navigationBar.translucent = NO;
    
    self.tablePlanTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self setTitle:@"Table List"];
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [self checkTablePlan];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)checkTablePlan
{
    dbTable = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTable open]) {
        NSLog(@"Fail To Open");
        return;
    }
    [tableArray removeAllObjects];
    FMResultSet *rs = [dbTable executeQuery:@"Select * from TablePlan"];
    //category = [NSMutableArray array];
    while ([rs next]) {
        //[category addObjectsFromArray:[rs resultDictionary]];
        //dict = [rs resultDictionary];
        
        [tableArray addObject:[rs resultDictionary]];
    }
    
    [rs close];
    [dbTable close];
    [self.tablePlanTableView reloadData];
}

-(void)addTablePlan:(id)sender
{
    userAction = @"New";
    /*
    UIAlertView *alertViewChangeName=[[UIAlertView alloc]initWithTitle:@"Add Table" message:@"Add New Table ?" delegate:self cancelButtonTitle:@"Save" otherButtonTitles:@"Cancel", nil];
    alertViewChangeName.alertViewStyle=UIAlertViewStylePlainTextInput;
    [alertViewChangeName show];
     */
    
}

#pragma mark - tableview

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    // Return the number of rows in the section.
    return [tableArray count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *Identifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:Identifier];
    if (cell == nil) {
        //        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:Identifier] autorelease];
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:Identifier];
    }
    cell.textLabel.text = [[tableArray objectAtIndex:indexPath.row] objectForKey:@"TP_Name"];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //remove the deleted object from your data source.
        //If your data source is an NSMutableArray, do this
        /*
        userAction = @"Delete";
        tableSelectedIndex = indexPath.row;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning"
                                                        message:@"Sure To Delete ?"
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:@"Cancel",nil];
        [alert show];
        */
        // tell table to refresh now
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    userAction = @"Edit";
    tableSelectedIndex = indexPath.row;
    
    [self editCategory];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    //[self.catTextV resignFirstResponder];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 54;
    //return 360;
}


#pragma mark - alertview response
/*
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    dbTable = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTable open]) {
        NSLog(@"Fail To Open");
        return;
    }
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.margin = 30.f;
    hud.yOffset = 200.f;
    // the user clicked OK
    if ([userAction isEqualToString:@"Delete"]) {
        if (buttonIndex == 0) {
            
            
            BOOL dbHadError = [dbTable executeUpdate:@"delete from TablePlan where TP_ID = ?",[[tableArray objectAtIndex:tableSelectedIndex]objectForKey:@"TP_ID"]];
            if (dbHadError) {
                //allowDelTax = YES;
                hud.labelText = @"Data Delete";
                hud.removeFromSuperViewOnHide = YES;
                
                [hud hide:YES afterDelay:0.6];
            }
            else
            {
                hud.labelText = [dbTable lastErrorMessage];
                hud.removeFromSuperViewOnHide = YES;
                
                [hud hide:YES afterDelay:0.6];
            }
            
            
        }
        else
        {
            hud.removeFromSuperViewOnHide = YES;
            [hud hide:YES];
        }
    }
    else if ([userAction isEqualToString:@"Edit"])
    {
        if (buttonIndex == 0) {
            // do something here...
            //[category replaceObjectAtIndex:categorySelectedIndex withObject:[[alertView textFieldAtIndex:0]text]];
            
            if ([[[alertView textFieldAtIndex:0]text] isEqualToString:@""]) {
                hud.labelText = @"Data Cannot Empty";
                
                NSLog(@"%f",hud.xOffset);
                hud.removeFromSuperViewOnHide = YES;
                
                [hud hide:YES afterDelay:0.6];
            }
            else
            {
                BOOL dbHadError = [dbTable executeUpdate:@"update TablePlan set TP_Name = ? where TP_ID = ?",[[alertView textFieldAtIndex:0]text],[[tableArray objectAtIndex:tableSelectedIndex]objectForKey:@"TP_ID"]];
                
                if (dbHadError) {
                    hud.labelText = @"Data Updated";
                    hud.removeFromSuperViewOnHide = YES;
                    
                    [hud hide:YES afterDelay:0.6];
                }
                else
                {
                    hud.labelText = [dbTable lastErrorMessage];
                    hud.removeFromSuperViewOnHide = YES;
                    
                    [hud hide:YES afterDelay:0.6];
                }
                userAction = @"New";
            }
            
        }
        else
        {
            hud.removeFromSuperViewOnHide = YES;
            
            [hud hide:YES];
        }
    }
    else if ([userAction isEqualToString:@"New"])
    {
        
        if (buttonIndex == 0) {
            FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
            [queue inDatabase:^(FMDatabase *db) {
                
                
                FMResultSet *rs = [db executeQuery:@"Select * from TablePlan where TP_Name = ?",[[alertView textFieldAtIndex:0]text]];
                
                
                if ([rs next]) {
                    
                    [rs close];
                    
                    hud.labelText = @"Duplicate Table Name.";
                    
                    NSLog(@"%f",hud.xOffset);
                    hud.removeFromSuperViewOnHide = YES;
                    
                    [hud hide:YES afterDelay:0.6];
                }
                else
                {
                    BOOL dbHadError = [dbTable executeUpdate:@"insert into TablePlan (TP_Name, TP_Description) values (?,?)",[[alertView textFieldAtIndex:0]text],@"-"];
                    if (dbHadError) {
                        hud.labelText = @"Data Save";
                        hud.removeFromSuperViewOnHide = YES;
                        
                        [hud hide:YES afterDelay:0.6];
                    }
                    else
                    {
                        hud.labelText = [dbTable lastErrorMessage];
                        hud.removeFromSuperViewOnHide = YES;
                        
                        [hud hide:YES afterDelay:0.6];
                    }
                }
                
            }];

        }
        else
        {
            
            hud.removeFromSuperViewOnHide = YES;
            
            [hud hide:YES];
        }
        
        
 
        
        if (buttonIndex == 0) {
            //[category addObject:[[alertView textFieldAtIndex:0]text]];
            if ([[[alertView textFieldAtIndex:0]text] isEqualToString:@""]) {
                hud.labelText = @"Data Cannot Empty";
                hud.removeFromSuperViewOnHide = YES;
                
                [hud hide:YES afterDelay:3];
            }
            else
            {
                BOOL dbHadError = [dbTable executeUpdate:@"insert into TablePlan (TP_Name, TP_Description) values (?,?)",[[alertView textFieldAtIndex:0]text],@"-"];
                if (dbHadError) {
                    hud.labelText = @"Data Save";
                    hud.removeFromSuperViewOnHide = YES;
                    
                    [hud hide:YES afterDelay:3];
                }
                else
                {
                    hud.labelText = [dbTable lastErrorMessage];
                    hud.removeFromSuperViewOnHide = YES;
                    
                    [hud hide:YES afterDelay:3];
                }
            }
         
        }
 
    }
    [dbTable close];
    [self checkTablePlan];
    //[self.catTableView reloadData];
    
    
}
*/
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

-(void)editCategory
{
    /*
    UIAlertView *alertViewChangeName=[[UIAlertView alloc]initWithTitle:@"Update Table" message:[NSString stringWithFormat:@"Change %@ To ?",[[tableArray objectAtIndex:tableSelectedIndex]objectForKey:@"TP_ID"]] delegate:self cancelButtonTitle:@"Update" otherButtonTitles:@"Cancel", nil];
    alertViewChangeName.alertViewStyle=UIAlertViewStylePlainTextInput;
    [alertViewChangeName show];
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
