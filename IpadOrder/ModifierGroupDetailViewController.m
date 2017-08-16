//
//  ModifierGroupDetailViewController.m
//  IpadOrder
//
//  Created by IRS on 27/02/2017.
//  Copyright © 2017 IrsSoftware. All rights reserved.
//

#import "ModifierGroupDetailViewController.h"
#import "LibraryAPI.h"
#import <FMDB.h>
#import "NumPadTextField/NumericKeypadTextField.h"
#import "NumericKeypadViewController.h"
#import "PublicSqliteMethod.h"

@interface ModifierGroupDetailViewController ()
{
    NSString *dbPath;
    NSMutableArray *itemMastArray;
    NSMutableArray *modifierDetailArray;
    NSMutableArray *itemGroupArray;
    NSMutableArray *itemSectionTitleArray;
}
@end
NSString *bigBtn;
@implementation ModifierGroupDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    dbPath = [[LibraryAPI sharedInstance] getDbPath];
    itemMastArray = [[NSMutableArray alloc]init];
    modifierDetailArray = [[NSMutableArray alloc]init];
    itemGroupArray = [[NSMutableArray alloc] init];
    itemSectionTitleArray = [[NSMutableArray alloc] init];
    
    UIBarButtonItem *addBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(saveModifierGroup)];
    self.navigationItem.rightBarButtonItem = addBtn;
    /*
    UIBarButtonItem *backModifierHdrView = [[UIBarButtonItem alloc]initWithTitle:@"< Modifier" style:UIBarButtonItemStylePlain target:self action:@selector(backToModifierGroupView:)];
    self.navigationItem.leftBarButtonItem = backModifierHdrView;
    [backModifierHdrView setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor],NSForegroundColorAttributeName, nil] forState:UIControlStateNormal];
    */
    
    self.tableViewItemMast.delegate = self;
    self.tableViewItemMast.dataSource = self;
    
    self.tableViewModifierDetail.dataSource = self;
    self.tableViewModifierDetail.delegate  =self;
    
    self.textModifierItemMastSearch.delegate = self;
    
    bigBtn = @"Done";
    self.textMGMin.numericKeypadDelegate = self;
    
    [self.textModifierItemMastSearch addTarget:self action:@selector(textfieldKeyChange:) forControlEvents:UIControlEventEditingChanged];
}

-(void)viewWillAppear:(BOOL)animated{
    if ([_mGHUserAction isEqualToString:@"Update"]) {
        self.textMGCode.enabled = false;
    }
    [self getItemModifierDataWithDesc:@"%"];
    [self filterItemMastWithDesc:@"%"];
}

-(void)viewWillDisappear:(BOOL)animated
{
    itemMastArray = nil;
    modifierDetailArray = nil;
}

#pragma mark - NumberPadDelegate
-(void)saveActionFormTextField:(UITextField *)textField
{
    [textField resignFirstResponder];
    //NSLog(@"Password is %@",textField.text);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)backToModifierGroupView:id{
    
    [self.navigationController popViewControllerAnimated:NO];
}

#pragma mark - tableview
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    if (tableView == self.tableViewItemMast) {
        
        return [itemGroupArray count];
    }
    else
    {
        return 1;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (tableView == self.tableViewItemMast) {
        return 50;
    }
    else
    {
        return 0;
    }
    
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableViewItemMast) {
        UIView *viewHeader = [UIView.alloc initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 20)];
        viewHeader.backgroundColor = [UIColor colorWithRed:240/255.0 green:240/255.0 blue:240/255.0 alpha:1.0];
        UILabel *lblHeadertitle = [[UILabel alloc] initWithFrame:CGRectMake(5, 15, 200, 20)];
        [lblHeadertitle setFont:[UIFont boldSystemFontOfSize:18]];
        //customize lblHeadertitle
        lblHeadertitle.text = [[itemSectionTitleArray objectAtIndex:section] objectForKey:@"IC_Description"];
        [viewHeader addSubview:lblHeadertitle];
        
        return viewHeader;
    }
    else
    {
        
        return nil;
    }
    
}
/*
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (tableView == self.tableViewItemMast) {
        return [[itemSectionTitleArray objectAtIndex:section] objectForKey:@"IC_Description"];
    }
    else
    {
        return @"";
    }
    //return @"fxxk";
}
*/

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (tableView == self.tableViewItemMast) {
        NSString *sectionTitle = [[itemSectionTitleArray objectAtIndex:section]objectForKey:@"IC_Description"];
        return [[[itemGroupArray objectAtIndex:section] objectForKey:sectionTitle] count];
    }
    else
    {
        return [modifierDetailArray count];
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *Identifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:Identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:Identifier];
    }
    
    if (tableView == self.tableViewItemMast) {
        NSString *sectionTitle = [[itemSectionTitleArray objectAtIndex:indexPath.section] objectForKey:@"IC_Description"];
        NSArray *sectionItemMast = [[itemGroupArray objectAtIndex:indexPath.section ] objectForKey:sectionTitle];
        
        cell.textLabel.text = [[sectionItemMast objectAtIndex:indexPath.row] objectForKey:@"IM_Description"];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %0.2f",[[LibraryAPI sharedInstance] getCurrencySymbol],[[[sectionItemMast objectAtIndex:indexPath.row] objectForKey:@"IM_SalesPrice"] doubleValue]];
        
        sectionItemMast = nil;
    }
    else if (tableView == self.tableViewModifierDetail){
        cell.textLabel.text = [[modifierDetailArray objectAtIndex:indexPath.row]objectForKey:@"IM_Description"];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%0.2f",[[[modifierDetailArray objectAtIndex:indexPath.row]objectForKey:@"IM_SalesPrice"] doubleValue]];
    }
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (tableView == self.tableViewItemMast) {
        
        NSString *sectionTitle = [[itemSectionTitleArray objectAtIndex:indexPath.section]objectForKey:@"IC_Description"];
        
        NSArray *sectionItemMast = [[itemGroupArray objectAtIndex:indexPath.section] objectForKey:sectionTitle];
        
        NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"IM_ItemCode MATCHES[cd] %@",
                                   [[sectionItemMast objectAtIndex:indexPath.row] objectForKey:@"IM_ItemCode"]];
        
        NSArray *parentObject = [modifierDetailArray filteredArrayUsingPredicate:predicate1];
        
        if (parentObject.count > 0) {
            parentObject = nil;
            return;
        }
        else
        {
            NSMutableDictionary *sectionDic = [NSMutableDictionary dictionary];
            
            [sectionDic setObject:[[sectionItemMast objectAtIndex:indexPath.row] objectForKey:@"IM_ItemCode"] forKey:@"IM_ItemCode"];
            [sectionDic setObject:[[sectionItemMast objectAtIndex:indexPath.row] objectForKey:@"IM_Description"] forKey:@"IM_Description"];
            [sectionDic setObject:@"0.00" forKey:@"IM_SalesPrice"];
            [sectionDic setObject:[[sectionItemMast objectAtIndex:indexPath.row] objectForKey:@"IM_FileName"]forKey:@"IM_FileName"];
            
            [modifierDetailArray addObject:sectionDic];
            
            //[itemMastArray removeObjectAtIndex:indexPath.row];
            [[[itemGroupArray objectAtIndex:indexPath.section] objectForKey:sectionTitle] removeObjectAtIndex:indexPath.row];
            
            sectionDic = nil;
            [self.tableViewModifierDetail reloadData];
            [self.tableViewItemMast reloadData];
            
            if (modifierDetailArray.count > 0) {
                long lastRowNumber = [self.tableViewModifierDetail numberOfRowsInSection:0] - 1;
                NSIndexPath *ip = [NSIndexPath indexPathForRow:lastRowNumber inSection:0];
                [self.tableViewModifierDetail scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionTop animated:NO];
            }
            
        }
        sectionItemMast = nil;
        parentObject = nil;
    }
    else{
        [self promptKeyInItemPriceWithItemIndex:indexPath.row];
    }
    

}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView == self.tableViewModifierDetail) {
        return YES;
    }
    else
    {
        return NO;
    }
    
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        [modifierDetailArray removeObjectAtIndex:indexPath.row];
        
        [self.tableViewModifierDetail reloadData];
        
        [self filterItemMastWithDesc:@"%"];
        
        /*
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict = [[modifierDetailArray objectAtIndex:indexPath.row] mutableCopy];
        [itemMastArray addObject:dict];
        dict = nil;
        [modifierDetailArray removeObjectAtIndex:indexPath.row];
        
        [self.tableViewModifierDetail reloadData];
        [self.tableViewItemMast reloadData];
        
        if (itemMastArray.count > 0) {
            long lastRowNumber = [self.tableViewItemMast numberOfRowsInSection:0] - 1;
            NSIndexPath *ip = [NSIndexPath indexPathForRow:lastRowNumber inSection:0];
            [self.tableViewItemMast scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionTop animated:NO];
        }
         */
        
        
    }
}

#pragma mark - sqlite

-(void)filterItemMastWithDesc:(NSString *)desc
{
    [itemMastArray removeAllObjects];
    [itemGroupArray removeAllObjects];
    [itemSectionTitleArray removeAllObjects];
    /*
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rsCategory = [db executeQuery:@"Select IC_Category,IC_Description from ItemCatg"];
        
        while ([rsCategory next]) {
            NSMutableDictionary *groupDict = [NSMutableDictionary dictionary];
            
            FMResultSet *rsItem = [db executeQuery:@"Select IM_ItemNo,IM_ItemCode, IM_Description,IM_SalesPrice,IFNULL(IM_FileName,'no_image.jpg') as IM_FileName from ItemMast where IM_Description like ? and IM_ServiceType = ? and IM_Category = ?",[NSString stringWithFormat:@"%@%@%@",@"%",desc,@"%"],[NSNumber numberWithInt:0],[rsCategory stringForColumn:@"IC_Category"]];
            
            while ([rsItem next]) {
                
                NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"IM_ItemCode MATCHES[cd] %@",
                                           [rsItem stringForColumn:@"IM_ItemCode"]];
                
                NSArray *modifierObject = [modifierDetailArray filteredArrayUsingPredicate:predicate1];
                
                if (modifierObject.count == 0) {
                    
                    NSMutableDictionary *sectionDic = [NSMutableDictionary dictionary];
                    
                    [sectionDic setObject:[rsItem stringForColumn:@"IM_ItemCode"] forKey:@"IM_ItemCode"];
                    [sectionDic setObject:[rsItem stringForColumn:@"IM_Description"] forKey:@"IM_Description"];
                    [sectionDic setObject:[rsItem stringForColumn:@"IM_SalesPrice"] forKey:@"IM_SalesPrice"];
                    [sectionDic setObject:[rsItem stringForColumn:@"IM_FileName"] forKey:@"IM_FileName"];
                    
                    [itemMastArray addObject:sectionDic];
                    sectionDic = nil;
                    
                }
                
                modifierObject = nil;
                predicate1 = nil;
                
            }
            if (itemMastArray.count > 0) {
                
                [itemSectionTitleArray addObject:[rsCategory resultDictionary]];
                
                [groupDict setObject:[itemMastArray mutableCopy] forKey:[rsCategory stringForColumn:@"IC_Description"]];
                [itemGroupArray addObject:groupDict];
            }
            
            [itemMastArray removeAllObjects];
            [rsItem close];
        }
        
    }];
    
    [queue close];
    */
    [itemGroupArray addObjectsFromArray:[PublicSqliteMethod getItemMastGroupingWithDbPath:dbPath Description:desc ModifierDetailArray:modifierDetailArray ViewName:@"ModifierGroup" ItemServiceType:@"0"]];
    
    for (int i = 0; i < itemGroupArray.count; i++) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setObject:[[itemGroupArray objectAtIndex:i] objectForKey:@"IC_Name"] forKey:@"IC_Description"];
        [itemSectionTitleArray addObject:dict];
        dict = nil;
    }
    
    [self.tableViewItemMast reloadData];
}

-(void)getItemModifierDataWithDesc:(NSString *)imDesc{
    
    [itemMastArray removeAllObjects];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        /*
        FMResultSet *rsItem = [db executeQuery:@"Select IM_ItemNo,IM_ItemCode, IM_Description,IM_SalesPrice,IFNULL(IM_FileName,'no_image.jpg') as IM_FileName from ItemMast where IM_Description like ? and IM_ServiceType = ?",[NSString stringWithFormat:@"%@%@%@",@"%",imDesc,@"%"],[NSNumber numberWithInt:0]];
        //NSMutableArray *imArray = [[NSMutableArray alloc]init];
        
        while ([rsItem next]) {
            NSMutableDictionary *sectionDic = [NSMutableDictionary dictionary];
            
            [sectionDic setObject:[rsItem stringForColumn:@"IM_ItemCode"] forKey:@"IM_ItemCode"];
            [sectionDic setObject:[rsItem stringForColumn:@"IM_Description"] forKey:@"IM_Description"];
            [sectionDic setObject:[rsItem stringForColumn:@"IM_SalesPrice"] forKey:@"IM_SalesPrice"];
            [sectionDic setObject:[rsItem stringForColumn:@"IM_FileName"] forKey:@"IM_FileName"];
            
            [itemMastArray addObject:sectionDic];
            sectionDic = nil;
        }
        [rsItem close];
        */
        FMResultSet *rsMGHdr = [db executeQuery:@"Select * from ModifierHdr where MH_Code = ?", _mGHCode];
        
        if ([rsMGHdr next]) {
            self.textMGCode.text = [rsMGHdr stringForColumn:@"MH_Code"];
            self.textMGDesc.text = [rsMGHdr stringForColumn:@"MH_Description"];
            self.textMGMin.text = [rsMGHdr stringForColumn:@"MH_MinChoice"];
        }
        [rsMGHdr close];
        FMResultSet *rsMGDetail = [db executeQuery:@"Select * from ModifierDtl where MD_MGCode = ?",_mGHCode];
        
        while ([rsMGDetail next]) {
            NSMutableDictionary *mdDict = [NSMutableDictionary dictionary];
            
            [mdDict setObject:[rsMGDetail stringForColumn:@"MD_Price"] forKey:@"IM_SalesPrice"];
            [mdDict setObject:[rsMGDetail stringForColumn:@"MD_ItemDescription"] forKey:@"IM_Description"];
            [mdDict setObject:[rsMGDetail stringForColumn:@"MD_ItemCode"] forKey:@"IM_ItemCode"];
            [mdDict setObject:[rsMGDetail stringForColumn:@"MD_ItemFileName"] forKey:@"IM_FileName"];
            
            [modifierDetailArray addObject:mdDict];
            mdDict = nil;
        }
        [rsMGDetail close];
        
    }];
    
    [queue close];
    [self.tableViewItemMast reloadData];
    [self.tableViewModifierDetail reloadData];
}

-(void)textfieldKeyChange:id{
    
    [self filterItemMastWithDesc:self.textModifierItemMastSearch.text];
}

-(void)saveModifierGroup{
    if ([self checkTextFieldEmpty]) {
        [self addModifierGroup];
    }
}

-(void)addModifierGroup
{
    __block NSString *result;
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        //NSString *result;
        if ([_mGHUserAction isEqualToString:@"Add"]) {
            [db executeUpdate:@"Insert into ModifierHdr (MH_Code, MH_Description, MH_MinChoice) Values (?,?,?)", self.textMGCode.text, self.textMGDesc.text, self.textMGMin.text];
        }
        else{
            [db executeUpdate:@"Update ModifierHdr set MH_Description = ?, MH_MinChoice = ? where MH_Code = ?",self.textMGDesc.text, self.textMGMin.text, _mGHCode];
            
            [db executeUpdate:@"Update PackageItemDtl set PD_MinChoice = ? where PD_ItemCode = ?",self.textMGMin.text,_mGHCode];
        }
        
        if([db hadError])
        {
            result = @"False";
            [self showAlertView:[db lastErrorMessage] title:@"Warning"];
            *rollback = YES;
            return;
        }
        else
        {
            [db executeUpdate:@"Delete from ModifierDtl where MD_MGCode = ?",_mGHCode];
            
            for (int i = 0; i < modifierDetailArray.count; i++) {
                [db executeUpdate:@"Insert into ModifierDtl (MD_MGCode, MD_Price, MD_ItemCode, MD_ItemDescription, MD_ItemFileName) Values (?,?,?,?,?)", self.textMGCode.text, [[modifierDetailArray objectAtIndex:i] objectForKey:@"IM_SalesPrice"], [[modifierDetailArray objectAtIndex:i] objectForKey:@"IM_ItemCode"],[[modifierDetailArray objectAtIndex:i] objectForKey:@"IM_Description"], [[modifierDetailArray objectAtIndex:i] objectForKey:@"IM_FileName"]];
                
                if ([db hadError]) {
                    [self showAlertView:[db lastErrorMessage] title:@"Warning"];
                    result = @"False";
                    *rollback = YES;
                    return;
                }
                else
                {
                    result = @"True";
                }
                
            }
        }
        
    }];
    
    [queue close];
    
    if ([result isEqualToString:@"True"]) {
        itemMastArray = nil;
        modifierDetailArray = nil;
        [self.navigationController popViewControllerAnimated:NO];
    }
    
}

#pragma mark - prompt out msg
-(void)promptKeyInItemPriceWithItemIndex:(NSUInteger)tableIndex
{
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle: @"Surcharge ?"
                                                                              message: @" "
                                                                       preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Price";
        textField.textColor = [UIColor blackColor];
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.borderStyle = UITextBorderStyleRoundedRect;
        //textField.text = [[tableSection objectAtIndex:sectionSelectedIndex]objectForKey:@"TS_Name"];
    }];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Update" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSArray *textfields = alertController.textFields;
        UITextField *namefield = textfields[0];
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict = [modifierDetailArray objectAtIndex:tableIndex];
        [dict setValue:[NSString stringWithFormat:@"%0.2f",[namefield.text doubleValue]] forKey:@"IM_SalesPrice"];
        
        [modifierDetailArray replaceObjectAtIndex:tableIndex withObject:dict];
        
        dict = nil;
        
        [self.tableViewModifierDetail reloadData];
        
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
    }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

-(BOOL)checkTextFieldEmpty{
    if ([self.textMGCode.text length] == 0 || [self.textMGCode.text isEqualToString:@" "]) {
        [self showAlertView:@"Code cannot empty" title:@"Warning"];
        return false;
    }
    else if ([self.textMGDesc.text length] == 0 || [self.textMGDesc.text isEqualToString:@" "]){
        [self showAlertView:@"Description cannot empty" title:@"Warning"];
        return false;
    }
    else if ([self.textMGMin.text length] == 0 || [self.textMGMin.text isEqualToString:@"0"]){
        [self showAlertView:@"Description cannot empty or zero" title:@"Warning"];
        return false;
    }
    else if ([modifierDetailArray count] == 0){
        [self showAlertView:@"Modifier item cannot empty" title:@"Warning"];
        return false;
    }
    else{
        return true;
    }
}

#pragma mark - alertView

-(void)showAlertView:(NSString *)msg title:(NSString *)title
{
    
    UIAlertController *alert = [[LibraryAPI sharedInstance] showAlertViewWithMsg:msg Title:title];
    
    [self presentViewController:alert animated:NO completion:nil];
    alert = nil;
}

@end
