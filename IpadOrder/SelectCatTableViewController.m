//
//  SelectCatTableViewController.m
//  IpadOrder
//
//  Created by IRS on 7/9/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "SelectCatTableViewController.h"
#import <FMDB.h>
#import "LibraryAPI.h"


@interface SelectCatTableViewController ()<UISearchBarDelegate>
{
    NSString *dbPath;
    NSMutableArray *category;
    FMDatabase *dbCat;
}
@property(nonatomic,strong)UISearchBar *searchController;
@end

@implementation SelectCatTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    category = [[NSMutableArray alloc]init];
    /*
    self.searchController = [[UISearchBar alloc] init];
    self.searchController.delegate = self;
    self.searchController.placeholder = @"Search";
    self.searchController.frame = CGRectMake(self.searchController.frame.origin.x, self.searchController.frame.origin.y, self.searchController.frame.size.width, 44.0);
    
    self.tableView.tableHeaderView = self.searchController;
    */
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.preferredContentSize = CGSizeMake(320, 393);
    dbPath = [[LibraryAPI sharedInstance]getDbPath];
    [self getCategory];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - sqlite

-(void)getCategory
{
    dbCat = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbCat open]) {
        NSLog(@"Fail To Open");
        return;
    }
    [category removeAllObjects];
    
    if ([self.filterType isEqualToString:@"Category"]) {
        
    
        FMResultSet *rs = [dbCat executeQuery:@"Select IC_Category as Field1, 0 as Field2, IC_Description as Field3 from ItemCatg"];
        //category = [NSMutableArray array];
        while ([rs next]) {
            //[category addObjectsFromArray:[rs resultDictionary]];
            //dict = [rs resultDictionary];
            [category addObject:[rs resultDictionary]];
        }
        [rs close];
    }
    else if ([self.filterType isEqualToString:@"Gst"])
    {
        FMResultSet *rs = [dbCat executeQuery:@"Select T_Name as Field1, 0 as Field2,T_Description as Field3, T_Percent as Field4 from Tax order by Field3"];
        while ([rs next]) {
            [category addObject:[rs resultDictionary]];
        }
        [rs close];
    }
    else if ([self.filterType isEqualToString:@"ServiceTax"])
    {
        FMResultSet *rs = [dbCat executeQuery:@"Select T_Name as Field1, 0 as Field2, T_Description as Field3,T_Percent as Field4 from Tax order by Field3"];
        while ([rs next]) {
            [category addObject:[rs resultDictionary]];
        }
        [rs close];
    }
    else if ([self.filterType isEqualToString:@"ItemMast"])
    {
        FMResultSet *rs = [dbCat executeQuery:@"Select IM_Description as Field1, IM_SalesPrice as Field2,'' as Field3 from ItemMast order by IM_Description"];
        while ([rs next]) {
            [category addObject:[rs resultDictionary]];
        }
        [rs close];
    }
    else if ([self.filterType isEqualToString:@"Kiosk"])
    {
        FMResultSet *rs = [dbCat executeQuery:@"Select TP_Name as Field1, 0 as Field2,'' as Field3 from TablePlan order by TP_Name"];
        while ([rs next]) {
            [category addObject:[rs resultDictionary]];
        }
        [rs close];
    }
    else if ([self.filterType isEqualToString:@"Country"])
    {
        FMResultSet *rs = [dbCat executeQuery:@"Select C_Name as Field1, 0 as Field2,'' as Field3 from Country order by C_Name"];
        while ([rs next]) {
            [category addObject:[rs resultDictionary]];
        }
        [rs close];
    }
    else if ([self.filterType isEqualToString:@"ModiType"])
    {
        
        //NSMutableDictionary *dict = [[NSMutableDictionary alloc] init]; // Don't always need this
        // Note you can't use setObject: forKey: if you are using NSDictionary
        
        NSMutableDictionary * dict1 = [NSMutableDictionary
                                       dictionaryWithObjects:@[@"Single"]
                                       forKeys:@[@"Field1"]];
        NSMutableDictionary * dict2 = [NSMutableDictionary
                                       dictionaryWithObjects:@[@"Multiple"]
                                       forKeys:@[@"Field1"]];
        
        [category addObject:dict1];
        [category addObject:dict2];
        
    }
    else if ([self.filterType isEqualToString:@"PrinterBrand"])
    {
        NSMutableDictionary *printerBrand1 = [NSMutableDictionary dictionary];
        [printerBrand1 setObject:@"Star TSP Line Mode" forKey:@"Field1"];
        [printerBrand1 setObject:@"Line" forKey:@"Field2"];
        [printerBrand1 setObject:@"Star" forKey:@"Field3"];
        NSMutableDictionary *printerBrand2 = [NSMutableDictionary dictionary];
        [printerBrand2 setObject:@"Star TSP Raster Mode" forKey:@"Field1"];
        [printerBrand2 setObject:@"Raster" forKey:@"Field2"];
        [printerBrand2 setObject:@"Star" forKey:@"Field3"];
        NSMutableDictionary *printerBrand3 = [NSMutableDictionary dictionary];
        [printerBrand3 setObject:@"Asterix ST-EP Raster Mode" forKey:@"Field1"];
        [printerBrand3 setObject:@"Raster" forKey:@"Field2"];
        [printerBrand3 setObject:@"Asterix" forKey:@"Field3"];
        
        [category addObject:printerBrand1];
        [category addObject:printerBrand2];
        [category addObject:printerBrand3];
        
        printerBrand1 = nil;
        printerBrand2 = nil;
        printerBrand3 = nil;
    }
    else if ([self.filterType isEqualToString:@"TerminalNo"])
    {
        NSMutableDictionary *terminalNo0 = [NSMutableDictionary dictionary];
        [terminalNo0 setObject:@"0" forKey:@"Field1"];
        [terminalNo0 setObject:[NSNumber numberWithInt:0] forKey:@"Field2"];
        [terminalNo0 setObject:@"" forKey:@"Field3"];
        
        NSMutableDictionary *terminalNo1 = [NSMutableDictionary dictionary];
        [terminalNo1 setObject:@"1" forKey:@"Field1"];
        [terminalNo1 setObject:[NSNumber numberWithInt:1] forKey:@"Field2"];
        [terminalNo1 setObject:@"" forKey:@"Field3"];
        
        NSMutableDictionary *terminalNo2 = [NSMutableDictionary dictionary];
        [terminalNo2 setObject:@"2" forKey:@"Field1"];
        [terminalNo2 setObject:[NSNumber numberWithInt:2] forKey:@"Field2"];
        [terminalNo2 setObject:@"" forKey:@"Field3"];
        
        NSMutableDictionary *terminalNo3 = [NSMutableDictionary dictionary];
        [terminalNo3 setObject:@"3" forKey:@"Field1"];
        [terminalNo3 setObject:[NSNumber numberWithInt:3] forKey:@"Field2"];
        [terminalNo3 setObject:@"" forKey:@"Field3"];
        
        NSMutableDictionary *terminalNo4 = [NSMutableDictionary dictionary];
        [terminalNo4 setObject:@"4" forKey:@"Field1"];
        [terminalNo4 setObject:[NSNumber numberWithInt:4] forKey:@"Field2"];
        [terminalNo4 setObject:@"" forKey:@"Field3"];
        
        NSMutableDictionary *terminalNo5 = [NSMutableDictionary dictionary];
        [terminalNo5 setObject:@"5" forKey:@"Field1"];
        [terminalNo5 setObject:[NSNumber numberWithInt:5] forKey:@"Field2"];
        [terminalNo5 setObject:@"" forKey:@"Field3"];
        
        [category addObject:terminalNo0];
        [category addObject:terminalNo1];
        [category addObject:terminalNo2];
        [category addObject:terminalNo3];
        [category addObject:terminalNo4];
        [category addObject:terminalNo5];
        
        terminalNo1 = nil;
        terminalNo2 = nil;
        terminalNo3 = nil;
        terminalNo4 = nil;
        terminalNo5 = nil;
    }
    else if ([self.filterType isEqualToString:@"CondimentGroup"])
    {
        FMResultSet *rs = [dbCat executeQuery:@"Select CH_Code as Field1, 0 as Field2,CH_Description as Field3 from CondimentHdr order by CH_Code"];
        while ([rs next]) {
            [category addObject:[rs resultDictionary]];
        }
        [rs close];
    }
    
    [dbCat close];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return category.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *Identifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:Identifier];
    if (cell == nil) {
        //        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:Identifier] autorelease];
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:Identifier];
    }
    
    [[cell textLabel]setFont:[UIFont boldSystemFontOfSize:18]];
    if ([self.filterType isEqualToString:@"ServiceTax"] || [self.filterType isEqualToString:@"Gst"])
    {
        //cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@%",[[category objectAtIndex:indexPath.row] objectForKey:@"Field3"],[[category objectAtIndex:indexPath.row] objectForKey:@"Field4"]];
        cell.textLabel.text = [NSString stringWithFormat:@"%@ - %.2f%@",[[category objectAtIndex:indexPath.row] objectForKey:@"Field1"],[[[category objectAtIndex:indexPath.row] objectForKey:@"Field4"] doubleValue],@"%"];
        cell.detailTextLabel.text = [[category objectAtIndex:indexPath.row] objectForKey:@"Field3"];
    }
    else
    {
        cell.textLabel.text = [[category objectAtIndex:indexPath.row] objectForKey:@"Field1"];
        cell.detailTextLabel.text = [[category objectAtIndex:indexPath.row] objectForKey:@"Field3"];
    }
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_delegate != nil) {
        
        [_delegate getSelectedCategory:[[category objectAtIndex:indexPath.row]objectForKey:@"Field1"] field2:[[[category objectAtIndex:indexPath.row]objectForKey:@"Field2"] stringValue] field3:[[category objectAtIndex:indexPath.row]objectForKey:@"Field3"] filterType:self.filterType];
        
        category = nil;
        
        //[self dismissViewControllerAnimated:YES completion:nil];
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
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
