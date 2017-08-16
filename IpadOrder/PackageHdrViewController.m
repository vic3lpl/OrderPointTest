//
//  PackageHdrViewController.m
//  IpadOrder
//
//  Created by IRS on 08/03/2017.
//  Copyright © 2017 IrsSoftware. All rights reserved.
//

#import "PackageHdrViewController.h"
#import "LibraryAPI.h"
#import <FMDB.h>
#import "PackageDetailViewController.h"

@interface PackageHdrViewController ()
{
    NSMutableArray *packageHdrArray;
    NSString *dbPath;
    FMDatabase *dbTable;
}
@end

@implementation PackageHdrViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self setTitle:@"Package Item"];
    
    dbPath = [[LibraryAPI sharedInstance]getDbPath];
    //packageHdrArray = [[NSMutableArray alloc] init];
    self.tableViewPackageItem.delegate = self;
    self.tableViewPackageItem.dataSource = self;
    
    self.tableViewPackageItem.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0];
    self.navigationController.navigationBar.translucent = NO;
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidAppear:(BOOL)animated
{
    packageHdrArray = [[NSMutableArray alloc]init];
    [self getAllPackageItemMast];
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
    return [packageHdrArray count];
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *Identifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:Identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:Identifier];
    }
    cell.textLabel.text = [[packageHdrArray objectAtIndex:indexPath.row] objectForKey:@"IM_Description"];
    cell.detailTextLabel.text = [[packageHdrArray objectAtIndex:indexPath.row] objectForKey:@"IM_ItemCode"];
    //cell.textLabel.textColor = [UIColor colorWithRed:36/255.0 green:36/255.0 blue:36/255.0 alpha:1.0];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    PackageDetailViewController *packageDetailViewController = [[PackageDetailViewController alloc]init];
    packageDetailViewController.packageItemCode = [[packageHdrArray objectAtIndex:indexPath.row] objectForKey:@"IM_ItemCode"];
    packageDetailViewController.packageItemDesc = [[packageHdrArray objectAtIndex:indexPath.row] objectForKey:@"IM_Description"];
    [self.navigationController pushViewController:packageDetailViewController animated:NO];
    
    packageHdrArray = nil;
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 54;
}


#pragma mark - sqlite 3

-(void)getAllPackageItemMast
{
    dbTable = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTable open]) {
        NSLog(@"Fail To Open");
        return;
    }
    
    [packageHdrArray removeAllObjects];
    
    FMResultSet *rs = [dbTable executeQuery:@"Select * from ItemMast where IM_ServiceType = ?",[NSNumber numberWithInt:1]];
    
    while ([rs next]) {
        [packageHdrArray addObject:[rs resultDictionary]];
    }
    
    [rs close];
    [dbTable close];
    [self.tableViewPackageItem reloadData];
    
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
