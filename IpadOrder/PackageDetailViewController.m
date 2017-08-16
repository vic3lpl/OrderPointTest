//
//  PackageDetailViewController.m
//  IpadOrder
//
//  Created by IRS on 08/03/2017.
//  Copyright © 2017 IrsSoftware. All rights reserved.
//

#import "PackageDetailViewController.h"
#import "LibraryAPI.h"
#import <FMDB.h>
#import "PublicSqliteMethod.h"

@interface PackageDetailViewController ()
{
    NSString *dbPath;
    NSMutableArray *itemArray;
    NSMutableArray *packageDetailArray;
    NSMutableArray *itemGroupArray;
    NSMutableArray *itemSectionTitleArray;
}
@end

@implementation PackageDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    dbPath = [[LibraryAPI sharedInstance] getDbPath];
    
    /*
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    */
    self.navigationController.navigationBar.hidden = TRUE;
    self.navigationController.navigationBar.translucent = NO;
    
    self.preferredContentSize = CGSizeMake(700, 650);
    
    
    self.tableIViewItemMast.delegate = self;
    self.tableIViewItemMast.dataSource = self;
    self.textSearchItem.delegate  =self;
    self.tableViewPackageDetail.delegate = self;
    self.tableViewPackageDetail.dataSource = self;
    
    self.textPackageItemName.text = _packageItemDesc;
    packageDetailArray = [[NSMutableArray alloc]init];
    itemGroupArray = [[NSMutableArray alloc] init];
    itemSectionTitleArray = [[NSMutableArray alloc] init];
    
    UIBarButtonItem *addBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(savePackageItemDetail)];
    self.navigationItem.rightBarButtonItem = addBtn;
    /*
    UIBarButtonItem *backPackageHdrView = [[UIBarButtonItem alloc] initWithTitle:@"< Package Item" style:UIBarButtonItemStylePlain target:self action:@selector(backToPackageHdrViewBtn:)];
    self.navigationItem.leftBarButtonItem = backPackageHdrView;
    */
    
    [self.textSearchItem addTarget:self action:@selector(startFilterItem:) forControlEvents:UIControlEventEditingChanged];
    
    self.textPackageItemName.enabled = false;
}

-(void)viewDidAppear:(BOOL)animated
{
    itemArray = [[NSMutableArray alloc]init];
    
    [self rebuildPackageItemDetail];
    [self filterItemMastWithDesc:@"%"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidDisappear:(BOOL)animated
{
    packageDetailArray = nil;
    itemArray = nil;
    itemSectionTitleArray = nil;
    itemGroupArray = nil;
}

#pragma mark - touch background
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

#pragma mark - tableview
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    if (tableView == self.tableIViewItemMast) {
        
        return [itemGroupArray count];
    }
    else
    {
        return 1;
    }
    //return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (tableView == self.tableIViewItemMast) {
        return 50;
    }
    else
    {
        return 0;
    }
    
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableIViewItemMast) {
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
    if (tableView == self.tableIViewItemMast) {
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
    if (tableView == self.tableIViewItemMast) {
        //return [itemArray count];
        NSString *sectionTitle = [[itemSectionTitleArray objectAtIndex:section]objectForKey:@"IC_Description"];
        //NSArray *sectionItemMast = [[itemGroupArray objectAtIndex:section] objectForKey:sectionTitle];
        return [[[itemGroupArray objectAtIndex:section] objectForKey:sectionTitle] count];
    }
    else
    {
        return [packageDetailArray count];
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *Identifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:Identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:Identifier];
    }
    
    if (tableView == self.tableIViewItemMast) {
        
        NSString *sectionTitle = [[itemSectionTitleArray objectAtIndex:indexPath.section] objectForKey:@"IC_Description"];
        NSArray *sectionItemMast = [[itemGroupArray objectAtIndex:indexPath.section ] objectForKey:sectionTitle];
        //NSString *itemName = [sectionItemMast objectAtIndex:indexPath.row];
        
        cell.textLabel.text = [[sectionItemMast objectAtIndex:indexPath.row] objectForKey:@"PD_Description"];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %0.2f",[[LibraryAPI sharedInstance] getCurrencySymbol],[[[sectionItemMast objectAtIndex:indexPath.row] objectForKey:@"PD_Price"] doubleValue]];
        
        sectionItemMast = nil;
    }
    else if (tableView == self.tableViewPackageDetail){
        cell.textLabel.text = [[packageDetailArray objectAtIndex:indexPath.row]objectForKey:@"PD_Description"];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %0.2f",[[LibraryAPI sharedInstance] getCurrencySymbol],[[[packageDetailArray objectAtIndex:indexPath.row]objectForKey:@"PD_Price"] doubleValue]];
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *sectionTitle = [[itemSectionTitleArray objectAtIndex:indexPath.section]objectForKey:@"IC_Description"];
    
    NSArray *sectionItemMast = [[itemGroupArray objectAtIndex:indexPath.section] objectForKey:sectionTitle];
    
    if (tableView == self.tableIViewItemMast) {
        NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"PD_ItemCode MATCHES[cd] %@",
                                   [[sectionItemMast objectAtIndex:indexPath.row] objectForKey:@"PD_ItemCode"]];
        
        NSArray *parentObject = [packageDetailArray filteredArrayUsingPredicate:predicate1];
        
        if (parentObject.count > 0) {
            parentObject = nil;
            return;
        }
        else
        {
            NSMutableDictionary *sectionDic = [NSMutableDictionary dictionary];
            
            [sectionDic setObject:[[sectionItemMast objectAtIndex:indexPath.row] objectForKey:@"PD_Code"] forKey:@"PD_Code"];
            [sectionDic setObject:[[sectionItemMast objectAtIndex:indexPath.row] objectForKey:@"PD_ItemCode"] forKey:@"PD_ItemCode"];
            [sectionDic setObject:[[sectionItemMast objectAtIndex:indexPath.row] objectForKey:@"PD_Description"] forKey:@"PD_Description"];
            [sectionDic setObject:@"0.00" forKey:@"PD_Price"];
            [sectionDic setObject:[[sectionItemMast objectAtIndex:indexPath.row] objectForKey:@"PD_MinChoice"]forKey:@"PD_MinChoice"];
            [sectionDic setObject:[[sectionItemMast objectAtIndex:indexPath.row] objectForKey:@"PD_ItemType"] forKey:@"PD_ItemType"];
            
            [packageDetailArray addObject:sectionDic];
            [[[itemGroupArray objectAtIndex:indexPath.section] objectForKey:sectionTitle] removeObjectAtIndex:indexPath.row];
            
            
            sectionDic = nil;
            [self.tableViewPackageDetail reloadData];
            [self.tableIViewItemMast reloadData];
            
            if (packageDetailArray.count > 0) {
                long lastRowNumber = [self.tableViewPackageDetail numberOfRowsInSection:0] - 1;
                NSIndexPath *ip = [NSIndexPath indexPathForRow:lastRowNumber inSection:0];
                [self.tableViewPackageDetail scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionTop animated:NO];
            }
            
        }
        
        parentObject = nil;
    }
    else
    {
        if ([[[packageDetailArray objectAtIndex:indexPath.row] objectForKey:@"PD_ItemType"] isEqualToString:@"ItemMast"]) {
            [self promptKeyInPackageItemPriceWithItemIndex:indexPath.row];
        }
        
    }
    
    sectionItemMast = nil;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView == self.tableViewPackageDetail) {
        return YES;
    }
    else{
        return NO;
    }
    
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [packageDetailArray removeObjectAtIndex:indexPath.row];
    
    [self.tableViewPackageDetail reloadData];
    
    [self startFilterItem:nil];
    
    /*
    NSString *moveToLastYN;
    
    moveToLastYN = @"No";
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        if ([[[packageDetailArray objectAtIndex:indexPath.row] objectForKey:@"PD_ItemType"] isEqualToString:@"ItemMast"] && self.segmentServiceType.selectedSegmentIndex == 0)
        {
            moveToLastYN = @"Yes";
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            dict = [[packageDetailArray objectAtIndex:indexPath.row] mutableCopy];
            [itemArray addObject:dict];
            
            dict = nil;
            [self.tableIViewItemMast reloadData];
        }
        else if ([[[packageDetailArray objectAtIndex:indexPath.row] objectForKey:@"PD_ItemType"] isEqualToString:@"Modifier"] && self.segmentServiceType.selectedSegmentIndex == 1)
        {
            moveToLastYN = @"Yes";
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            dict = [[packageDetailArray objectAtIndex:indexPath.row] mutableCopy];
            [itemArray addObject:dict];
            dict = nil;
            [self.tableIViewItemMast reloadData];
        }
        
        [packageDetailArray removeObjectAtIndex:indexPath.row];
        
        [self.tableViewPackageDetail reloadData];
        
        [self.tableIViewItemMast reloadData];
        
        if (itemArray.count > 0) {
            if ([moveToLastYN isEqualToString:@"Yes"]) {
                long lastRowNumber = [self.tableIViewItemMast numberOfRowsInSection:0] - 1;
                NSIndexPath *ip = [NSIndexPath indexPathForRow:lastRowNumber inSection:0];
                [self.tableIViewItemMast scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionTop animated:NO];
            }
            
        }
        
    }
     */
}


#pragma mark - sqlite

-(void)startFilterItem:id{
    if (self.segmentServiceType.selectedSegmentIndex == 0) {
        
        [self filterItemMastWithDesc:self.textSearchItem.text];
    }
    else
    {
        [self getModifierGroupDataWithMGDesc:self.textSearchItem.text];
    }
}

-(void)filterItemMastWithDesc:(NSString *)desc
{
    [itemGroupArray removeAllObjects];
    [itemArray removeAllObjects];
    [itemSectionTitleArray removeAllObjects];
    /*
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rsCategory = [db executeQuery:@"Select IC_Category,IC_Description from ItemCatg"];
        
        while ([rsCategory next]) {
            
            NSMutableDictionary *groupDict = [NSMutableDictionary dictionary];
            
            FMResultSet *rsItem = [db executeQuery:@"Select IM_ItemCode, IM_Description,IM_SalesPrice,IFNULL(IM_FileName,'no_image.jpg') as IM_FileName, IM_Category from ItemMast where IM_Description like ? and IM_ServiceType = ? and IM_Category = ?",[NSString stringWithFormat:@"%@%@%@",@"%",desc,@"%"], [NSNumber numberWithInt:0],[rsCategory stringForColumn:@"IC_Category"]];
            
            while ([rsItem next]) {
                
                NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"PD_ItemCode MATCHES[cd] %@",
                                           [rsItem stringForColumn:@"IM_ItemCode"]];
                
                NSArray *filterObject = [packageDetailArray filteredArrayUsingPredicate:predicate1];
                
                if (filterObject.count == 0) {
                    NSMutableDictionary *sectionDic = [NSMutableDictionary dictionary];
                    
                    [sectionDic setObject:[rsItem stringForColumn:@"IM_ItemCode"] forKey:@"PD_Code"];
                    [sectionDic setObject:[rsItem stringForColumn:@"IM_ItemCode"] forKey:@"PD_ItemCode"];
                    [sectionDic setObject:[rsItem stringForColumn:@"IM_Description"] forKey:@"PD_Description"];
                    [sectionDic setObject:[rsItem stringForColumn:@"IM_SalesPrice"] forKey:@"PD_Price"];
                    [sectionDic setObject:@"ItemMast" forKey:@"PD_ItemType"];
                    
                    //[sectionDic setObject:@"ItemMast" forKey:@"PD_Type"];
                    [sectionDic setObject:@"1" forKey:@"PD_MinChoice"];
                    
                    [itemArray addObject:sectionDic];
                    sectionDic = nil;
                }
                
                predicate1 = nil;
                filterObject = nil;
                
            }
            if (itemArray.count > 0) {
                
                [itemSectionTitleArray addObject:[rsCategory resultDictionary]];
                
                [groupDict setObject:[itemArray mutableCopy] forKey:[rsCategory stringForColumn:@"IC_Description"]];
                [itemGroupArray addObject:groupDict];
            }
            
            [itemArray removeAllObjects];
            
            [rsItem close];
            groupDict = nil;
        }
        [rsCategory close];
        
        
    }];
    
    [queue close];
    */
    
    [itemGroupArray addObjectsFromArray:[PublicSqliteMethod getItemMastGroupingWithDbPath:dbPath Description:desc ModifierDetailArray:packageDetailArray ViewName:@"PackageDetail" ItemServiceType:@"0"]];
    
    for (int i = 0; i < itemGroupArray.count; i++) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setObject:[[itemGroupArray objectAtIndex:i] objectForKey:@"IC_Name"] forKey:@"IC_Description"];
        [itemSectionTitleArray addObject:dict];
        dict = nil;
    }
    
    [self.tableIViewItemMast reloadData];
}

-(void)rebuildPackageItemDetail
{
    
    [packageDetailArray removeAllObjects];
    
    for (int i = 0; i < _packageItemDetailArray.count; i++) {
        NSMutableDictionary *sectionDic = [NSMutableDictionary dictionary];
        
        [sectionDic setObject:[[_packageItemDetailArray objectAtIndex:i] objectForKey:@"PD_Code"] forKey:@"PD_Code"];
        [sectionDic setObject:[[_packageItemDetailArray objectAtIndex:i] objectForKey:@"PD_Description"] forKey:@"PD_Description"];
        [sectionDic setObject:[[_packageItemDetailArray objectAtIndex:i] objectForKey:@"PD_ItemCode"] forKey:@"PD_ItemCode"];
        [sectionDic setObject:[[_packageItemDetailArray objectAtIndex:i] objectForKey:@"PD_ItemCode"] forKey:@"IM_ItemCode"];
        [sectionDic setObject:[[_packageItemDetailArray objectAtIndex:i] objectForKey:@"PD_Price"] forKey:@"PD_Price"];
        [sectionDic setObject:[[_packageItemDetailArray objectAtIndex:i] objectForKey:@"PD_MinChoice"] forKey:@"PD_MinChoice"];
        //[sectionDic setObject:@"ItemMast" forKey:@"PD_Type"];
        [sectionDic setObject:[[_packageItemDetailArray objectAtIndex:i] objectForKey:@"PD_ItemType"] forKey:@"PD_ItemType"];
        
        [packageDetailArray addObject:sectionDic];
        sectionDic = nil;
        [self.tableViewPackageDetail reloadData];
    }
    
}


-(void)getModifierGroupDataWithMGDesc:(NSString *)mGDesc{
    
    [itemArray removeAllObjects];
    [itemGroupArray removeAllObjects];
    [itemSectionTitleArray removeAllObjects];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rsItem = [db executeQuery:@"Select MH_Code, MH_Description, MH_MinChoice from ModifierHdr where MH_Description like ?",[NSString stringWithFormat:@"%@%@%@",@"%",mGDesc,@"%"]];
        //NSMutableArray *imArray = [[NSMutableArray alloc]init];
        
        while ([rsItem next]) {
            
            NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"PD_ItemCode MATCHES[cd] %@",
                                       [rsItem stringForColumn:@"MH_Code"]];
            
            NSArray *object = [packageDetailArray filteredArrayUsingPredicate:predicate1];
            
            if (object.count == 0) {
                NSMutableDictionary *sectionDic = [NSMutableDictionary dictionary];
                
                [sectionDic setObject:_packageItemCode forKey:@"PD_Code"];
                [sectionDic setObject:[rsItem stringForColumn:@"MH_Code"] forKey:@"PD_ItemCode"];
                [sectionDic setObject:[rsItem stringForColumn:@"MH_Description"] forKey:@"PD_Description"];
                [sectionDic setObject:@"0.00" forKey:@"PD_Price"];
                [sectionDic setObject:[rsItem stringForColumn:@"MH_MinChoice"] forKey:@"PD_MinChoice"];
                [sectionDic setObject:@"Modifier" forKey:@"PD_ItemType"];
                
                [itemArray addObject:sectionDic];
                sectionDic = nil;
            }
            object = nil;
            predicate1 = nil;
            
        }
        NSMutableDictionary *groupDict = [NSMutableDictionary dictionary];
        [groupDict setObject:@"Modifier" forKey:@"IC_Description"];
        [itemSectionTitleArray addObject:groupDict];
        
        [groupDict setObject:[itemArray mutableCopy] forKey:@"Modifier"];
        [itemGroupArray addObject:groupDict];
        groupDict = nil;
        [rsItem close];
        
    }];
    
    [queue close];
    [self.tableIViewItemMast reloadData];
}

/*
-(void)savePackageItemDetail
{
    //[self showAlertView:@"1" title:@"cccc"];
    __block NSString *result;
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        [db executeUpdate:@"Delete from PackageItemDtl where PD_Code = ?",_packageItemCode];
        
        for (int i = 0; i < packageDetailArray.count; i++) {
            [db executeUpdate:@"Insert into PackageItemDtl (PD_Code, PD_ItemCode, PD_ItemDescription, PD_Price, PD_MinChoice, PD_ItemType) Values (?,?,?,?,?,?)", _packageItemCode,[[packageDetailArray objectAtIndex:i] objectForKey:@"PD_ItemCode"],[[packageDetailArray objectAtIndex:i] objectForKey:@"PD_Description"],[[packageDetailArray objectAtIndex:i] objectForKey:@"PD_Price"],[[packageDetailArray objectAtIndex:i] objectForKey:@"PD_MinChoice"],[[packageDetailArray objectAtIndex:i]objectForKey:@"PD_ItemType"]];
            
            if ([db hadError]) {
                result = @"False";
                return;
            }
            else{
                result = @"True";
            }
            
        }
        
    }];
    
    [queue close];
    
    if ([result isEqualToString:@"True"]) {
        itemArray = nil;
        packageDetailArray = nil;
        [self.navigationController popViewControllerAnimated:NO];
    }
    
}
*/
-(void)promptKeyInPackageItemPriceWithItemIndex:(NSUInteger)tableIndex
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
        dict = [packageDetailArray objectAtIndex:tableIndex];
        [dict setValue:[NSString stringWithFormat:@"%0.2f",[namefield.text doubleValue]] forKey:@"PD_Price"];
        
        [packageDetailArray replaceObjectAtIndex:tableIndex withObject:dict];
        
        dict = nil;
        
        [self.tableViewPackageDetail reloadData];
        
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
    }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)segmentServiceTypeChangeValue:(id)sender {
    if (self.segmentServiceType.selectedSegmentIndex == 0) {
        
        [self filterItemMastWithDesc:@"%"];
        
    }
    else
    {
        [self getModifierGroupDataWithMGDesc:@"%"];
    }
}


#pragma mark - alertView

-(void)showAlertView:(NSString *)msg title:(NSString *)title
{
    UIAlertController * alert = [[LibraryAPI sharedInstance] showAlertViewWithMsg:msg Title:title];
    
    [self presentViewController:alert animated:YES completion:nil];
    
    alert = nil;
}
- (IBAction)btnCancelPackageItemDetailClick:(id)sender {
    
    if (_delegate != nil) {
        packageDetailArray = nil;
        itemArray = nil;
        itemSectionTitleArray = nil;
        itemGroupArray = nil;
        [_delegate passBackPackageDetailSettingArray:[_packageItemDetailArray mutableCopy]];
    }

}
- (IBAction)btnOKPackageItemDetailClick:(id)sender {
    if (_delegate != nil) {
        
        itemArray = nil;
        itemSectionTitleArray = nil;
        itemGroupArray = nil;
        [_delegate passBackPackageDetailSettingArray:[packageDetailArray mutableCopy]];
        packageDetailArray = nil;
    }
}
@end
