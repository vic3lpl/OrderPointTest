//
//  RootTableViewController.m
//  IpadOrder
//
//  Created by IRS on 7/1/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "RootTableViewController.h"
#import "ItemMastViewController.h"
#import "UISplitViewController+DetailViewSwapper.h"
#import "ItemCategoryViewController.h"
//#import "ModifierViewController.h"
#import "UserNameViewController.h"
#import "PrinterViewController.h"
#import "ItemTaxViewController.h"
#import "TablePlanViewController.h"
#import "TableSectionViewController.h"
#import "GeneralSettingViewController.h"
#import "PaymentTypeViewController.h"
#import "LibraryAPI.h"
#import <FMDB.h>
#import "RoundingViewController.h"
#import "TerminalViewController.h"
#import "CompanyDetailViewController.h"
#import "CondimentGroupViewController.h"
#import "CondimentViewController.h"
#import "LinkToAccSettingViewController.h"
#import "PrintOptionViewController.h"
#import "ModifierHdrViewController.h"
#import "PackageHdrViewController.h"

@interface RootTableViewController ()
{
    NSString *dbPath;
    //FMDatabase *db;
    
}
@property NSArray *menus;
@end

@implementation RootTableViewController
@synthesize menus = menus;
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, (self.view.frame.size.width), self.view.frame.size.height-104);
    
    menus = [NSMutableArray arrayWithObjects:@"Company",@"Item Category",@"Item",@"Condiment Group",@"Modifier",@"Tax",@"User",@"Table Section",@"General Setting",@"Rounding",@"Printer",@"Receipt Design",@"Payment Mode",@"IRS BizSuite Setting",@"Terminal", nil];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.tableView.separatorColor = [UIColor clearColor];
    [self.tableView reloadData];
}

-(void)viewWillAppear:(BOOL)animated
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0]; // set to whatever you want to be selected first
    [self.tableView selectRowAtIndexPath:indexPath animated:NO  scrollPosition:UITableViewScrollPositionNone];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidLayoutSubviews
{
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.tableView setLayoutMargins:UIEdgeInsetsZero];
    }
}

#pragma mark - Table view data source

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
    
    UIView *view = [[UIView alloc] init];
    [view setBackgroundColor:[UIColor colorWithRed:59/255.0 green:132/255.0 blue:209/255.0 alpha:1.0]];
    [cell setSelectedBackgroundView:view];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [menus count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *Identifier;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:Identifier];
    if (cell == nil) {
        //        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:Identifier] autorelease];
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:Identifier];
    }
    cell.textLabel.text =  [menus objectAtIndex:indexPath.row];
    cell.textLabel.textColor = [UIColor colorWithRed:66/255.0 green:66/255.0 blue:66/255.0 alpha:1.0];
    cell.textLabel.highlightedTextColor = [UIColor whiteColor];
    //cell.backgroundColor = [UIColor clearColor];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *viewControllerArray=[[NSMutableArray alloc] initWithArray:[[self.splitViewController.viewControllers objectAtIndex:1] viewControllers]];
    [viewControllerArray removeLastObject];
    [[LibraryAPI sharedInstance]setRefreshTB:@"Refresh,1"];
    if (indexPath.row == 0)
    {
        CompanyDetailViewController *detailViewController = [[CompanyDetailViewController alloc]init];
        [self.splitViewController swapDetailViewControllerWith:detailViewController];
        detailViewController = nil;
 
    }
    
    else if (indexPath.row == 1)
    {
        ItemCategoryViewController *itemCategoryViewController = [[ItemCategoryViewController alloc]init];
        [self.splitViewController swapDetailViewControllerWith:itemCategoryViewController];
        itemCategoryViewController = nil;
    }
    else if (indexPath.row == 2)
    {
        ItemMastViewController *itemMastViewController = [[ItemMastViewController alloc]init];
        [self.splitViewController swapDetailViewControllerWith:itemMastViewController];
        itemMastViewController = nil;
        
    }
    else if (indexPath.row == 3)
    {
        
        CondimentGroupViewController *condimentGroupViewController = [[CondimentGroupViewController alloc]init];
        [self.splitViewController swapDetailViewControllerWith:condimentGroupViewController];
        condimentGroupViewController = nil;
        
        
    }
    else if (indexPath.row == 4)
    {
        
        ModifierHdrViewController *modifierViewController = [[ModifierHdrViewController alloc]initWithNibName:@"ModifierHdrViewController" bundle:nil];
        [self.splitViewController swapDetailViewControllerWith:modifierViewController];
        modifierViewController = nil;
    }
    /*
    else if (indexPath.row == 4)
    {
        
        CondimentViewController *condimentViewController = [[CondimentViewController alloc]init];
        [self.splitViewController swapDetailViewControllerWith:condimentViewController];
        condimentViewController = nil;
        
        
    }
     */
    else if (indexPath.row == 5)
    {
        ItemTaxViewController *itemTaxViewController = [[ItemTaxViewController alloc]initWithNibName:@"ItemTaxViewController" bundle:nil];
        [self.splitViewController swapDetailViewControllerWith:itemTaxViewController];
        itemTaxViewController = nil;
        
    }
    else if (indexPath.row == 6)
    {
        
        UserNameViewController *userNameViewController = [[UserNameViewController alloc]initWithNibName:@"UserNameViewController" bundle:nil];
        [self.splitViewController swapDetailViewControllerWith:userNameViewController];
        userNameViewController = nil;
        
    }
    
    else if (indexPath.row == 7)
    {
        
        TableSectionViewController *tableSectionViewController = [[TableSectionViewController alloc]init];
        [self.splitViewController swapDetailViewControllerWith:tableSectionViewController];
        tableSectionViewController = nil;
        
    }
    else if (indexPath.row == 8)
    {
        
        GeneralSettingViewController *generalSettingViewController = [[GeneralSettingViewController alloc]init];
        [self.splitViewController swapDetailViewControllerWith:generalSettingViewController];
        generalSettingViewController = nil;
        
    }
    else if (indexPath.row == 9)
    {
        
        RoundingViewController *roundingViewController = [[RoundingViewController alloc]init];
        [self.splitViewController swapDetailViewControllerWith:roundingViewController];
        roundingViewController = nil;
        
    }
    else if (indexPath.row == 10)
    {
        
        PrinterViewController *printerViewController = [[PrinterViewController alloc]initWithNibName:@"PrinterViewController" bundle:nil];
        [self.splitViewController swapDetailViewControllerWith:printerViewController];
        printerViewController = nil;
        
    }
    else if (indexPath.row == 11)
    {
        PrintOptionViewController *printOptionViewController = [[PrintOptionViewController alloc]initWithNibName:@"PrintOptionViewController" bundle:nil];
        [self.splitViewController swapDetailViewControllerWith:printOptionViewController];
        printOptionViewController = nil;
    }
    else if (indexPath.row == 12)
    {
        PaymentTypeViewController *paymentViewController = [[PaymentTypeViewController alloc]initWithNibName:@"PaymentTypeViewController" bundle:nil];
        [self.splitViewController swapDetailViewControllerWith:paymentViewController];
        paymentViewController = nil;
    }
    
    else if (indexPath.row == 13)
    {
        LinkToAccSettingViewController *linkToAccSettingViewController = [[LinkToAccSettingViewController alloc] initWithNibName:@"LinkToAccSettingViewController" bundle:nil];
        [self.splitViewController swapDetailViewControllerWith:linkToAccSettingViewController];
        
        linkToAccSettingViewController = nil;
    }
    
    else if (indexPath.row == 14)
    {
        
        TerminalViewController *terminalViewController = [[TerminalViewController alloc]initWithNibName:@"TerminalViewController" bundle:nil];
        [self.splitViewController swapDetailViewControllerWith:terminalViewController];
        terminalViewController = nil;
        
        
    }
    
    /*
    else if (indexPath.row == 5)
    {
        
        PackageHdrViewController *packageHdrViewController = [[PackageHdrViewController alloc]initWithNibName:@"PackageHdrViewController" bundle:nil];
        [self.splitViewController swapDetailViewControllerWith:packageHdrViewController];
        packageHdrViewController = nil;
    }
    */
    //else if (indexPath.row == 4)
    //{
    
    //ModifierViewController *modifierViewController = [[ModifierViewController alloc]init];
    //[self.splitViewController swapDetailViewControllerWith:modifierViewController];
    
    //}
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 64;
    //return 360;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
