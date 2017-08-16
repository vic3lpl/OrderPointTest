//
//  CondimentGroupEditViewController.m
//  IpadOrder
//
//  Created by IRS on 03/09/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import "CondimentGroupEditViewController.h"
#import "LibraryAPI.h"
#import <FMDB.h>


@interface CondimentGroupEditViewController ()
{
    FMDatabase *dbTable;
    NSString *dbPath;
    NSMutableArray *condimentDtlArray;
    
}
@end

@implementation CondimentGroupEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    dbPath = [[LibraryAPI sharedInstance] getDbPath];
    UIBarButtonItem *addBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(btnActionTaken)];
    self.navigationItem.rightBarButtonItem = addBtn;
    
    condimentDtlArray = [[NSMutableArray alloc] init];
    self.tableCondimentDetail.delegate = self;
    self.tableCondimentDetail.dataSource = self;
    
    self.tableCondimentDetail.clipsToBounds = NO;
    self.tableCondimentDetail.layer.masksToBounds = NO;
    self.tableCondimentDetail.layer.borderWidth = 2.0;
    self.tableCondimentDetail.layer.borderColor = [[UIColor colorWithRed:199.0/255 green:201.0/255 blue:201.0/255 alpha:1.0] CGColor];
    // Do any additional setup after loading the view from its nib.
    
    if ([_action isEqualToString:@"Edit"]) {
        [self getCondimentGroupHdr];
        self.textCondimentGroupCode.enabled = false;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)getCondimentGroupHdr
{
    //dbTable = [FMDatabase databaseWithPath:dbPath];
    
    //BOOL dbHadError;
    /*
    if (![dbTable open]) {
        NSLog(@"Fail To Open");
        return;
    }
    */
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"Select * from CondimentHdr where CH_Code = ?",_chCode];
        
        if ([rs next]) {
            self.textCondimentDesc.text = [rs stringForColumn:@"CH_Description"];
            self.textCondimentGroupCode.text = [rs stringForColumn:@"CH_Code"];
        }
        
        [rs close];
        
        
        [condimentDtlArray removeAllObjects];
        FMResultSet *rsDtl = [db executeQuery:@"Select CD_Code,CD_Description,CD_Price,CD_CondimentHdrCode from CondimentDtl where CD_CondimentHdrCode = ?",self.textCondimentGroupCode.text];
        
        while ([rsDtl next]) {
            [condimentDtlArray addObject:[rsDtl resultDictionary]];
        }
        
        [rsDtl close];
        
    }];
    [queue close];
    
    [self.tableCondimentDetail reloadData];
    
    //[dbTable close];
}

-(void)btnActionTaken
{
    
    if ([[LibraryAPI sharedInstance]getUserRole] == 0) {
        [self showAlertView:@"You have no permission to edit data" title:@"Warning"];
        return;
    }
    
    if ([self checkTextField]) {
        if ([_action isEqualToString:@"New"]) {
            [self saveCondimentGroupHdr];
        }
        else
        {
            [self editCondimentGroupHdr];
        }
    }
}

-(void)saveCondimentGroupHdr
{
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rsCheck = [db executeQuery:@"Select * from CondimentHdr where CH_Code = ?",self.textCondimentGroupCode.text];
        
        if ([rsCheck next]) {
            [self showAlertView:@"Condiment group code duplicate" title:@"Warning"];
            return;
        }
        [rsCheck close];
        
        [db executeUpdate:@"Insert into CondimentHdr (CH_Code, CH_Description) values (?,?)",self.textCondimentGroupCode.text,self.textCondimentDesc.text];
        
        if ([db hadError]) {
            [self showAlertView:[db lastErrorMessage] title:@"Fail"];
            return;
        }
        else
        {
            [db executeUpdate:@"Delete from CondimentDtl where CD_CondimentHdrCode = ?",self.textCondimentGroupCode.text];
            
            if ([db hadError]) {
                *rollback = YES;
                [self showAlertView:[db lastErrorMessage] title:@"Fail"];
                return;
            }
            else
            {
                for (int i = 0; i < condimentDtlArray.count; i++) {
                    [db executeUpdate:@"Insert into CondimentDtl (CD_Code, CD_Description, CD_Price, CD_CondimentHdrCode) values (?,?,?,?)",[[condimentDtlArray objectAtIndex:i] objectForKey:@"CD_Code"],[[condimentDtlArray objectAtIndex:i] objectForKey:@"CD_Description"],[[condimentDtlArray objectAtIndex:i] objectForKey:@"CD_Price"],self.textCondimentGroupCode.text];
                    
                    if ([db hadError]) {
                        *rollback = YES;
                        [self showAlertView:[db lastErrorMessage] title:@"Fail"];
                        return;
                    }
                    
                }
            }
            
            [self.navigationController popViewControllerAnimated:NO];
        }
        
    }];
    [queue close];
    
}

-(void)editCondimentGroupHdr
{
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        [db executeUpdate:@"Update CondimentHdr set CH_Description = ? where CH_Code = ?",self.textCondimentDesc.text,self.textCondimentGroupCode.text];
        
        if ([db hadError]) {
            [self showAlertView:[db lastErrorMessage] title:@"Fail"];
            return;
        }
        else
        {
            [db executeUpdate:@"Delete from CondimentDtl where CD_CondimentHdrCode = ?",self.textCondimentGroupCode.text];
            
            if ([db hadError]) {
                *rollback = YES;
                [self showAlertView:[db lastErrorMessage] title:@"Fail"];
                return;
            }
            else
            {
                for (int i = 0; i < condimentDtlArray.count; i++) {
                    [db executeUpdate:@"Insert into CondimentDtl (CD_Code, CD_Description, CD_Price, CD_CondimentHdrCode) values (?,?,?,?)",[[condimentDtlArray objectAtIndex:i] objectForKey:@"CD_Code"],[[condimentDtlArray objectAtIndex:i] objectForKey:@"CD_Description"],[[condimentDtlArray objectAtIndex:i] objectForKey:@"CD_Price"],self.textCondimentGroupCode.text];
                    
                    if ([db hadError]) {
                        *rollback = YES;
                        [self showAlertView:[db lastErrorMessage] title:@"Fail"];
                        return;
                    }

                }
            }
            
            [self.navigationController popViewControllerAnimated:NO];
        }
        
    }];
    [queue close];
    
}

#pragma mark - touch background
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

#pragma mark - show alertview
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
}

#pragma mark - check field
-(BOOL)checkTextField
{
    
    if (condimentDtlArray.count == 0) {
        [self showAlertView:@"Condiment detail cannot empty" title:@"Warning"];
        return NO;
    }
    
    if ([self.textCondimentGroupCode.text isEqualToString:@""]) {
        [self showAlertView:@"Group code cannot empty" title:@"Warning"];
        return NO;
    }
    else if ([self.textCondimentDesc.text isEqualToString:@""])
    {
        [self showAlertView:@"Group description cannot empty" title:@"Warning"];
        return NO;
    }
    
    else
    {
        return YES;
    }
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
    return [condimentDtlArray count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *Identifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:Identifier];
    if (cell == nil) {
        //        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:Identifier] autorelease];
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:Identifier];
    }
    
    cell.textLabel.text = [[condimentDtlArray objectAtIndex:indexPath.row] objectForKey:@"CD_Description"];
    cell.textLabel.textColor = [UIColor colorWithRed:36/255.0 green:36/255.0 blue:36/255.0 alpha:1.0];
    cell.detailTextLabel.textColor = [UIColor colorWithRed:128/255.0 green:128/255.0 blue:128/255.0 alpha:1.0];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@%0.2f",[[LibraryAPI sharedInstance] getCurrencySymbol],[[[condimentDtlArray objectAtIndex:indexPath.row] objectForKey:@"CD_Price"] doubleValue]];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    CondimentDetailViewController *condimentDetailViewController = [[CondimentDetailViewController alloc]init];
    condimentDetailViewController.delegate = self;
    condimentDetailViewController.cdAction = @"Edit";
    condimentDetailViewController.cdCode = [[condimentDtlArray objectAtIndex:indexPath.row] objectForKey:@"CD_Code"];
    condimentDetailViewController.cdPrice = [[condimentDtlArray objectAtIndex:indexPath.row] objectForKey:@"CD_Price"];
    condimentDetailViewController.cdDescription = [[condimentDtlArray objectAtIndex:indexPath.row] objectForKey:@"CD_Description"];
    
    UINavigationController *navbar = [[UINavigationController alloc]  initWithRootViewController:condimentDetailViewController];
    
    navbar.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    navbar.modalPresentationStyle = UIModalPresentationFormSheet;
    [condimentDetailViewController setModalPresentationStyle:UIModalPresentationFormSheet];
    [condimentDetailViewController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    
    [self.navigationController presentViewController:navbar animated:NO completion:nil];
    
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [condimentDtlArray removeObjectAtIndex:indexPath.row];
    [self.tableCondimentDetail reloadData];
    }

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 54;
    //return 360;
}

- (IBAction)btnAddCondimentDetailClick:(id)sender {
    CondimentDetailViewController *condimentDetailViewController = [[CondimentDetailViewController alloc]init];
    condimentDetailViewController.delegate = self;
    condimentDetailViewController.cdAction = @"New";
    
    UINavigationController *navbar = [[UINavigationController alloc]  initWithRootViewController:condimentDetailViewController];
    
    navbar.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    navbar.modalPresentationStyle = UIModalPresentationFormSheet;
    [condimentDetailViewController setModalPresentationStyle:UIModalPresentationFormSheet];
    [condimentDetailViewController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    
    [self.navigationController presentViewController:navbar animated:NO completion:nil];
}

#pragma mark - delegate from Condiment detail view
-(void)passbackCondimentDetailAray:(NSMutableDictionary *)dict Status:(NSString *)status
{
    [self.navigationController dismissViewControllerAnimated:NO completion:nil];
    
    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"CD_Code MATCHES[cd] %@",
                               [dict objectForKey:@"CD_Code"]];
    
    NSArray *resultObject = [condimentDtlArray filteredArrayUsingPredicate:predicate1];
    
    if ([status isEqualToString:@"New"]) {
        if (resultObject.count > 0) {
            NSUInteger indexOfArray = 0;
            indexOfArray = [condimentDtlArray indexOfObject:resultObject[0]];
            //[condimentDtlArray removeObjectAtIndex:indexOfArray];
            //[condimentDtlArray replaceObjectAtIndex:indexOfArray withObject:dict];
            [self showAlertView:@"Condiment code exist" title:@"Warning"];
        }
        else
        {
            [condimentDtlArray addObject:dict];
        }
    }
    else
    {
        
        if (resultObject.count > 0) {
            NSUInteger indexOfArray = 0;
            indexOfArray = [condimentDtlArray indexOfObject:resultObject[0]];
            //[condimentDtlArray removeObjectAtIndex:indexOfArray];
            [condimentDtlArray replaceObjectAtIndex:indexOfArray withObject:dict];
        }
        //[condimentDtlArray addObject:dict];
        predicate1 = nil;
        resultObject = nil;
    }
    
    
    [self.tableCondimentDetail reloadData];
}
@end
