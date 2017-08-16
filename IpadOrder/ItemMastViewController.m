//
//  ItemMastViewController.m
//  IpadOrder
//
//  Created by IRS on 7/2/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "ItemMastViewController.h"
#import "ItemMastEditViewController.h"
#import "ModalViewController.h"
#import "UISplitViewController+DetailViewSwapper.h"
#import "ItemMastTableViewCell.h"
#import "LibraryAPI.h"
#import <FMDB.h>
#import <MBProgressHUD.h>
#import <HNKCache.h>
#import "PublicMethod.h"
#import "PublicSqliteMethod.h"

@interface ItemMastViewController ()<UISearchBarDelegate>
{
    NSString *dbPath;
    //NSMutableArray *itemMastArray;
    FMDatabase *dbItem;
    NSString *itemNo;
    NSString *itemCode;
    NSString *itemCurrency;
    
    //for image
    NSString *documentPath;
    NSString *filePath;
    NSString *terminalType;
    //NSString *alertFlag;
    //NSMutableArray *twoDArray;
    //NSMutableArray *catArray;
    
    NSString *imImgFileName;
    NSMutableArray *itemGroupArray;
    NSMutableArray *itemSectionTitleArray;
}
@property(nonatomic,strong) UISearchBar *searchController;
@end

@implementation ItemMastViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self setTitle:@"Item"];
    
    dbPath = [[LibraryAPI sharedInstance]getDbPath];
    itemCurrency = [[LibraryAPI sharedInstance]getCurrencySymbol];
    self.itemMastTableView.delegate = self;
    self.itemMastTableView.dataSource = self;
    terminalType = [[LibraryAPI sharedInstance] getWorkMode];
    
    documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    UIBarButtonItem *addBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(AddItemMast:)];
    self.navigationItem.rightBarButtonItem = addBtn;
    
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    
    //self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:34/255.0 green:171/255.0 blue:241/255.0 alpha:1.0];
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.translucent = NO;
    UINib *finalNib = [UINib nibWithNibName:@"ItemMastTableViewCell" bundle:nil];
    [[self itemMastTableView]registerNib:finalNib forCellReuseIdentifier:@"ItemMastTableViewCell"];
    
    self.itemMastTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    //self.itemMastTableView.separatorColor = [UIColor colorWithRed:13/255.0 green:149/255.0 blue:226/255.0 alpha:1.0];
}

-(void)viewWillLayoutSubviews
{
    
    self.searchController = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44.0)];
    self.searchController.delegate = self;
    self.searchController.placeholder = @"Search";
    //self.searchController.frame = CGRectMake(self.searchController.frame.origin.x, self.searchController.frame.origin.y, self.view.frame.size.width, 44.0);
    self.searchController.barTintColor = [UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0];
    self.itemMastTableView.tableHeaderView = self.searchController;
}

-(void)viewWillAppear:(BOOL)animated
{
    //itemMastArray = [[NSMutableArray alloc]init];
    //twoDArray = [NSMutableArray new];
    //catArray = [[NSMutableArray alloc] init];
    
    itemGroupArray = [[NSMutableArray alloc] init];
    itemSectionTitleArray = [[NSMutableArray alloc] init];
    
    //[self checkItemMast:@"%"];
    [self checkItemMast:@"%"];
}

-(void)viewDidLayoutSubviews
{
    if ([self.itemMastTableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.itemMastTableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([self.itemMastTableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.itemMastTableView setLayoutMargins:UIEdgeInsetsZero];
    }
}

-(void)AddItemMast:(id)sender
{
    if ([terminalType isEqualToString:@"Main"]) {
        ItemMastEditViewController *itemMastEditViewController = [[ItemMastEditViewController alloc]init];
        itemMastEditViewController.userAction = @"New";
    
        [self.navigationController pushViewController:itemMastEditViewController animated:NO];
        
        //twoDArray = [NSMutableArray new];
        //catArray = [[NSMutableArray alloc] init];
        itemGroupArray = [[NSMutableArray alloc] init];
        itemSectionTitleArray = [[NSMutableArray alloc] init];
        //itemMastArray = nil;
    }
    else
    {
        //[self showMyHudMessageBoxWithMessage:@"Terminal Cannot Add Item"];
        [self showAlertView:@"Terminal cannot add item" title:@"Warning"];
    }
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - search bar event
-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    
    [searchBar setShowsCancelButton:YES animated:NO];
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    
    [self checkItemMast:[NSString stringWithFormat:@"%@",searchBar.text]];
    
    //searchBar.text = @"";
    [searchBar setShowsCancelButton:NO animated:NO];
    [searchBar resignFirstResponder];
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchBar.text = @"";
    [self checkItemMast:@"%"];
    [[self view] endEditing:YES];
}

#pragma mark - sqlite3

-(void)checkItemMast:(NSString *)imDesc
{
    [itemGroupArray removeAllObjects];
    [itemSectionTitleArray removeAllObjects];
    /*
    [catArray removeAllObjects];
    [twoDArray removeAllObjects];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rsCatg = [db executeQuery:@"Select IC_Category,IC_Description from ItemCatg"];
        
        while ([rsCatg next]) {
            //NSMutableArray *catArray = [[NSMutableArray alloc] init];
            [catArray addObject:[rsCatg resultDictionary]];
            
            FMResultSet *rsItem = [db executeQuery:@"Select IM_ItemNo,IM_ItemCode, IM_Description,IM_SalesPrice,IFNULL(IM_FileName,'no_image.jpg') as IM_FileName from ItemMast where IM_Category = ? and IM_Description like ?",[rsCatg stringForColumn:@"IC_Category"],imdesc];
            NSMutableArray *imArray = [[NSMutableArray alloc]init];
            
            while ([rsItem next]) {
                NSMutableDictionary *sectionDic = [NSMutableDictionary dictionary];
                
                [sectionDic setObject:[rsItem stringForColumn:@"IM_ItemNo"] forKey:@"IM_ItemNo"];
                [sectionDic setObject:[rsItem stringForColumn:@"IM_ItemCode"] forKey:@"IM_ItemCode"];
                [sectionDic setObject:[rsItem stringForColumn:@"IM_Description"] forKey:@"IM_Description"];
                [sectionDic setObject:[rsItem stringForColumn:@"IM_SalesPrice"] forKey:@"IM_SalesPrice"];
                [sectionDic setObject:[rsItem stringForColumn:@"IM_FileName"] forKey:@"IM_FileName"];
                
                [imArray addObject:sectionDic];
                sectionDic = nil;
            }
            [rsItem close];
            [twoDArray addObject:[NSMutableDictionary dictionaryWithObject:imArray forKey:[rsCatg stringForColumn:@"IC_Description"]]];
            imArray = nil;
            
        }
        [rsCatg close];
        
    }];
    
    //NSLog(@"%@",twoDArray);
    [queue close];
     */
    
    [itemGroupArray addObjectsFromArray:[PublicSqliteMethod getItemMastGroupingWithDbPath:dbPath Description:imDesc ModifierDetailArray:nil ViewName:@"ItemMast" ItemServiceType:@"%"]];
    
    for (int i = 0; i < itemGroupArray.count; i++) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setObject:[[itemGroupArray objectAtIndex:i] objectForKey:@"IC_Name"] forKey:@"IC_Description"];
        [itemSectionTitleArray addObject:dict];
        dict = nil;
    }
    
    [self.itemMastTableView reloadData];
    
}


#pragma mark - tableview
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return [itemGroupArray count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    NSString *sectionTitle = [[itemSectionTitleArray objectAtIndex:section]objectForKey:@"IC_Description"];
    return [[[itemGroupArray objectAtIndex:section] objectForKey:sectionTitle] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[itemSectionTitleArray objectAtIndex:section] objectForKey:@"IC_Description"];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *viewHeader = [UIView.alloc initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 20)];
    viewHeader.backgroundColor = [UIColor colorWithRed:240/255.0 green:240/255.0 blue:240/255.0 alpha:1.0];
    UILabel *lblHeadertitle = [[UILabel alloc] initWithFrame:CGRectMake(5, 15, 200, 20)];
    [lblHeadertitle setFont:[UIFont boldSystemFontOfSize:18]];
    //customize lblHeadertitle
    lblHeadertitle.text = [[itemSectionTitleArray objectAtIndex:section] objectForKey:@"IC_Description"];
    [viewHeader addSubview:lblHeadertitle];
    
    return viewHeader;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 50;
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *Identifier = @"ItemMastTableViewCell";
    
    ItemMastTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:Identifier];
    
    NSString *sectionTitle = [[itemSectionTitleArray objectAtIndex:indexPath.section] objectForKey:@"IC_Description"];
    NSArray *sectionItemMast = [[itemGroupArray objectAtIndex:indexPath.section ] objectForKey:sectionTitle];
    
    cell.labelItemMastCell.text = [[sectionItemMast objectAtIndex:indexPath.row] objectForKey:@"IM_Description"];
    cell.labelItemMastPriceCell.text = [NSString stringWithFormat:@"%@ %0.2f",itemCurrency,[[[sectionItemMast objectAtIndex:indexPath.row] objectForKey:@"IM_SalesPrice"] doubleValue]];
    
    filePath = [documentPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",[[sectionItemMast objectAtIndex:indexPath.row]objectForKey:@"IM_FileName"]]];
    
    cell.imgItemMastCell.image = [UIImage imageWithContentsOfFile:filePath];
    cell.imgItemMastCell.clipsToBounds = YES;
    cell.imgItemMastCell.layer.cornerRadius = 10.0;
    //cell.imgItemMastCell.contentMode = UIViewContentModeScaleAspectFill;
    cell.labelItemMastPriceCell.textColor = [UIColor grayColor];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    if (cell.imgItemMastCell.image == nil) {
        cell.imgItemMastCell.image = [UIImage imageNamed:@"no_image.jpg"];
    }
    
    sectionTitle = nil;
    sectionItemMast = nil;
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([terminalType isEqualToString:@"Main"]) {
        ItemMastEditViewController *itemMastEditViewController = [[ItemMastEditViewController alloc]init];
        NSString *sectionTitle = [[itemSectionTitleArray objectAtIndex:indexPath.section] objectForKey:@"IC_Description"];
        NSArray *sectionItemMast = [[itemGroupArray objectAtIndex:indexPath.section ] objectForKey:sectionTitle];
        
        itemMastEditViewController.userAction = @"Edit";
        itemMastEditViewController.itemNo = [[sectionItemMast objectAtIndex:indexPath.row]objectForKey:@"IM_ItemNo"];
        //[itemMastEditViewController setModalPresentationStyle:UIModalPresentationFormSheet];
        
        [self.navigationController pushViewController:itemMastEditViewController animated:NO];
        
        sectionItemMast = nil;
        
        sectionTitle = nil;
        //catArray = nil;
        //twoDArray = nil;
        itemSectionTitleArray = nil;
        itemGroupArray = nil;
        //itemMastArray = nil;
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
        //remove the deleted object from your data source.
        //If your data source is an NSMutableArray, do this
        NSString *sectionTitle = [[itemSectionTitleArray objectAtIndex:indexPath.section] objectForKey:@"IC_Description"];
        NSArray *sectionItemMast = [[itemGroupArray objectAtIndex:indexPath.section ] objectForKey:sectionTitle];
        
        itemNo = [[sectionItemMast objectAtIndex:indexPath.row] objectForKey:@"IM_ItemNo"];
        itemCode = [[sectionItemMast objectAtIndex:indexPath.row] objectForKey:@"IM_ItemCode"];
        imImgFileName = [[sectionItemMast objectAtIndex:indexPath.row] objectForKey:@"IM_FileName"];
        
        if ([terminalType isEqualToString:@"Main"]) {
            //alertFlag = @"Delete";
            
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
            //[self showMyHudMessageBoxWithMessage:@"Terminal Cannot Delete Item"];
            [self showAlertView:@"Terminal cannot delete item" title:@"Warning"];
        }
        
        sectionTitle= nil;
        sectionItemMast = nil;
        
        
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
    //return 360;
}


- (void)alertActionSelection
{
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rs = [db executeQuery:@"Select * from SalesOrderDtl where SOD_ItemCode = ?",itemCode];
        
        if ([rs next]) {
            [self showAlertView:@"Data in use" title:@"Warning"];
        }
        else
        {
            
            FMResultSet *rsIvD = [db executeQuery:@"Select * from InvoiceDtl where IvD_ItemCode = ?",itemCode];
            
            if ([rsIvD next]) {
                [self showAlertView:@"Data in use" title:@"Warning"];
            }
            else
            {
                
                [db executeUpdate:@"delete from ItemMast where IM_ItemNo = ?",itemNo];
                
                if (![imImgFileName isEqualToString:@"no_image.jpg"]) {
                    [PublicMethod removeExistingFileFromDirectoryWithFileName:imImgFileName];
                    
                    [[HNKCache sharedCache] removeImagesForKey:itemCode];
                }
            }
            
            
        }
    }];
    
    [queue close];
    [self checkItemMast:@"%"];
    
}

#pragma mark - alertView

-(void)showAlertView:(NSString *)msg title:(NSString *)title
{
    UIAlertController * alert = [[LibraryAPI sharedInstance] showAlertViewWithMsg:msg Title:title];
    
    [self presentViewController:alert animated:YES completion:nil];
    
    alert = nil;
    /*
    alertFlag = @"Alert";
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:msg
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
     */
}

#pragma mark - show hub
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
