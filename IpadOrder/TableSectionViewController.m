//
//  TableSectionViewController.m
//  IpadOrder
//
//  Created by IRS on 8/5/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "TableSectionViewController.h"
#import "LibraryAPI.h"
#import <FMDB.h>
#import <MBProgressHUD.h>
#import "TbSectionViewController.h"

@interface TableSectionViewController ()
{
    NSMutableArray *tableSection;
    long sectionSelectedIndex;
    BOOL dbNoError;
    NSString *dbPath;
    FMDatabase *dbTableSection;
    NSString *terminalType;
    NSString *alertFlag;
}
@end

@implementation TableSectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self setTitle:@"Table Section"];
    tableSection = [[NSMutableArray alloc]init];
    
    dbPath = [[LibraryAPI sharedInstance]getDbPath];
    terminalType = [[LibraryAPI sharedInstance]getWorkMode];
    
    self.tableSectionTableView.delegate = self;
    self.tableSectionTableView.dataSource = self;
    
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    //self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:34/255.0 green:171/255.0 blue:241/255.0 alpha:1.0];
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0];
    self.navigationController.navigationBar.translucent = NO;
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    //self.tableSectionTableView.separatorColor = [UIColor colorWithRed:13/255.0 green:149/255.0 blue:226/255.0 alpha:1.0];
    self.tableSectionTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self checkTableSection];
}

-(void)viewDidLayoutSubviews
{
    if ([self.tableSectionTableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableSectionTableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([self.tableSectionTableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.tableSectionTableView setLayoutMargins:UIEdgeInsetsZero];
    }
}

-(void)checkTableSection
{
    dbTableSection = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTableSection open]) {
        NSLog(@"Fail To Open");
        return;
    }
    
    [tableSection removeAllObjects];
    
    FMResultSet *rs = [dbTableSection executeQuery:@"Select * from TableSection"];
    
    while ([rs next]) {
        [tableSection addObject:[rs resultDictionary]];
    }
    
    [rs close];
    [dbTableSection close];
    [self.tableSectionTableView reloadData];
    
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
    return [tableSection count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *Identifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:Identifier];
    if (cell == nil) {
        //        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:Identifier] autorelease];
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:Identifier];
    }
    cell.textLabel.text = [[tableSection objectAtIndex:indexPath.row] objectForKey:@"TS_Name"];
    cell.textLabel.textColor = [UIColor colorWithRed:36/255.0 green:36/255.0 blue:36/255.0 alpha:1.0];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //userAction = @"Edit";
    if ([terminalType isEqualToString:@"Main"]) {
        sectionSelectedIndex = indexPath.row;
        
        [self editCategory];
    }
    else
    {
        //[self showMyHudMessageBoxWithMessage:@"Terminal Cannot Edit Table Section"];
        [self showAlertView:@"Terminal cannot edit table section" title:@"Warning"];
    }
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 54;
}

#pragma mark - alertView2

-(void)showAlertView:(NSString *)msg title:(NSString *)title
{
    alertFlag =@"Alert";
    
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

#pragma mark - alert view

-(void)editCategory
{
    
    if ([[LibraryAPI sharedInstance]getUserRole] == 0) {
        [self showAlertView:@"You have no permission to edit data" title:@"Warning"];
        return;
    }
    
    alertFlag = @"Edit";
    
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle: @"Update Section Name"
                                                                              message: [NSString stringWithFormat:@"Change %@ To ?",[[tableSection objectAtIndex:sectionSelectedIndex]objectForKey:@"TS_Name"]]
                                                                       preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Section name";
        textField.textColor = [UIColor blackColor];
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.borderStyle = UITextBorderStyleRoundedRect;
        textField.text = [[tableSection objectAtIndex:sectionSelectedIndex]objectForKey:@"TS_Name"];
    }];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Update" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSArray * textfields = alertController.textFields;
        UITextField * namefield = textfields[0];
        [self tableSectionAlertControlSelectionWithTextField:namefield.text];
        
        //UITextField * passwordfiled = textfields[1];
        //NSLog(@"%@:%@",namefield.text,passwordfiled.text);
        
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
    }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
    
    /*
    UIAlertView *alertViewChangeName=[[UIAlertView alloc]initWithTitle:@"Update Section Name" message:[NSString stringWithFormat:@"Change %@ To ?",[[tableSection objectAtIndex:sectionSelectedIndex]objectForKey:@"TS_Name"]] delegate:self cancelButtonTitle:@"Update" otherButtonTitles:@"Cancel", nil];
    
    
    alertViewChangeName.alertViewStyle=UIAlertViewStylePlainTextInput;
    UITextField* textField = [alertViewChangeName textFieldAtIndex:0];
    textField.text = [[tableSection objectAtIndex:sectionSelectedIndex]objectForKey:@"TS_Name"];
    [alertViewChangeName show];
     */
    
}


#pragma mark - alertview response
- (void)tableSectionAlertControlSelectionWithTextField:(NSString *)textfield
{
    if ([alertFlag isEqualToString:@"Alert"]) {
        return;
    }
    
    dbTableSection = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTableSection open]) {
        NSLog(@"Fail To Open");
        return;
    }
    
    // the user clicked OK
    
        
        if ([textfield isEqualToString:@""]) {
            
            alertFlag = @"Alert";
            [self showAlertView:@"Section name empty" title:@"Warning"];
        }
        else
        {
            FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
            
            [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                
                FMResultSet *rs = [db executeQuery:@"Select * from TableSection where TS_Name = ?",[textfield uppercaseString]];
                
                if ([rs next]) {
                    [rs close];
                    [self showAlertView:@"Table section duplicate" title:@"Warning"];
                    return;
                }
                [rs close];
                
                dbNoError = [db executeUpdate:@"update TableSection set TS_Name = ? where TS_Name = ?",[textfield uppercaseString],[[tableSection objectAtIndex:sectionSelectedIndex]objectForKey:@"TS_Name"]];
                
                if (dbNoError) {
                    dbNoError = [db executeUpdate:@"update TablePlan set TP_Section = ? where TP_Section = ?",[textfield uppercaseString],[[tableSection objectAtIndex:sectionSelectedIndex]objectForKey:@"TS_Name"]];
                    
                    if (!dbNoError) {
                        alertFlag = @"Alert";
                        [self showAlertView:[db lastErrorMessage] title:@"Warning"];
                        *rollback = YES;
                        return;
                    }
                    else
                    {
                        
                    }
                    
                }
                else
                {
                    
                    alertFlag = @"Alert";
                    [self showAlertView:[db lastErrorMessage] title:@"Warning"];
                }
                
            }];
            
            /*
            [queue inDatabase:^(FMDatabase *db) {
                dbNoError = [dbTableSection executeUpdate:@"update TableSection set TS_Name = ? where TS_Name = ?",[[alertView textFieldAtIndex:0]text],[[tableSection objectAtIndex:sectionSelectedIndex]objectForKey:@"TS_Name"]];
                
                if (dbNoError) {
                    
                    dbNoError = [dbTableSection executeUpdate:@"update TablePlans set TP_Section = ? where TP_Section = ?",[[[alertView textFieldAtIndex:0]text]uppercaseString],[[tableSection objectAtIndex:sectionSelectedIndex]objectForKey:@"TS_Name"]];
                    
                    if (dbNoError) {
                        //[db commit];
                        hud.labelText = @"Data Update";
                        hud.removeFromSuperViewOnHide = YES;
                        
                        [hud hide:YES afterDelay:0.6];
                    }
                    else
                    {
                        //[db rollback];
                        hud.labelText = [dbTableSection lastErrorMessage];
                        hud.removeFromSuperViewOnHide = YES;
                        
                        [hud hide:YES afterDelay:0.6];
                    }
                    
                }
                else
                {
                    //[db rollback];
                    hud.labelText = [dbTableSection lastErrorMessage];
                    hud.removeFromSuperViewOnHide = YES;
                    
                    [hud hide:YES afterDelay:0.8];
                }
            }];
             */
            
        }

    
    [dbTableSection close];
    [self checkTableSection];
    //[self.catTableView reloadData];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    
    [hud hide:YES afterDelay:0.8];
}

#pragma mark - refresh table section scroll
-(void)refreshTbScrollView
{
    TbSectionViewController *controller = [[TbSectionViewController alloc] initWithPageNumber:0];
    
    controller = nil;
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
