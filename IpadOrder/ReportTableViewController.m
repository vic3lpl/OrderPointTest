//
//  ReportTableViewController.m
//  IpadOrder
//
//  Created by IRS on 9/9/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "ReportTableViewController.h"
#import "UISplitViewController+DetailViewSwapper.h"
#import "XReadingViewController.h"
#import "DailyCollectionViewController.h"
#import "VoidReportViewController.h"

@interface ReportTableViewController ()
{
    NSArray *reportMenu;
}
@end

@implementation ReportTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Do any additional setup after loading the view.    self.tableView.scrollEnabled=NO;
    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, (self.view.frame.size.width), self.view.frame.size.height-104);
    reportMenu = [NSMutableArray arrayWithObjects:@"Invoice Listing",@"X Reading",@"Daily Collection", @"Void Report", nil];
    // self.tableView.scrollEnabled=NO;
    //self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:34/255.0 green:171/255.0 blue:241/255.0 alpha:1.0];
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
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
    return reportMenu.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *Identifier;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:Identifier];
    if (cell == nil) {
        //        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:Identifier] autorelease];
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:Identifier];
    }
    cell.textLabel.text = [reportMenu objectAtIndex:indexPath.row];
    cell.textLabel.textColor = [UIColor colorWithRed:66/255.0 green:66/255.0 blue:66/255.0 alpha:1.0];
    cell.textLabel.highlightedTextColor = [UIColor whiteColor];
    
    return cell;
}

#pragma mark - UITableViewDelegate methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //    [detailViewController getDetailForStructure:@"abc"];
    if (indexPath.row == 0) {
        ReprotDetailViewController *reportDetailViewController = [[ReprotDetailViewController alloc]init];
        [self.splitViewController swapDetailViewControllerWith:reportDetailViewController];
    }
    else if (indexPath.row == 1)
    {
        XReadingViewController *xReadingViewController = [[XReadingViewController alloc]init];
        [self.splitViewController swapDetailViewControllerWith:xReadingViewController];
    }
    else if (indexPath.row == 2)
    {
        DailyCollectionViewController *dailyCollectionViewController = [[DailyCollectionViewController alloc]init];
        [self.splitViewController swapDetailViewControllerWith:dailyCollectionViewController];
    }
    else if (indexPath.row == 3)
    {
        VoidReportViewController *voidReportViewController = [[VoidReportViewController alloc]init];
        [self.splitViewController swapDetailViewControllerWith:voidReportViewController];
    }
    
    
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0;
}

@end
