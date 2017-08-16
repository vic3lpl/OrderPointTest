//
//  InvoiceDetailViewController.m
//  IpadOrder
//
//  Created by IRS on 9/10/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "InvoiceDetailViewController.h"
#import "LibraryAPI.h"
#import <FMDB.h>
#import "InvoiceDetailCell.h"


@interface InvoiceDetailViewController ()
{
    NSString *dbPath;
    FMDatabase *dbTable;
    NSMutableArray *invDetailArray;
}
@end

@implementation InvoiceDetailViewController
@synthesize invNo;
- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableViewInvDetail.delegate = self;
    self.tableViewInvDetail.dataSource = self;
    dbPath = [[LibraryAPI sharedInstance]getDbPath];
    invDetailArray = [[NSMutableArray alloc] init];
    
    self.title = @"Cash Sales Detail";
    
    // Do any additional setup after loading the view from its nib.
    UINib *catNib = [UINib nibWithNibName:@"InvoiceDetailCell" bundle:nil];
    [[self tableViewInvDetail]registerNib:catNib forCellReuseIdentifier:@"InvoiceDetailCell"];
    
    self.tableViewInvDetail.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self getInvoiceListingDetailData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidLayoutSubviews
{
    if ([self.tableViewInvDetail respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableViewInvDetail setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([self.tableViewInvDetail respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.tableViewInvDetail setLayoutMargins:UIEdgeInsetsZero];
    }
}

#pragma mark - sqlite

-(void)getInvoiceListingDetailData
{
    /*
    dbTable = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTable open]) {
        NSLog(@"Fail To Open");
        return;
    }
     */
    [invDetailArray removeAllObjects];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"select IvD_ItemDescription,IvD_Quantity, IvD_UnitPrice, IvD_DiscValue, IvD_TotalInc, IvD_TotalEx, IvH_DocSubTotal, IvH_DocAmt, IvH_DocTaxAmt, IvH_DiscAmt, IvH_DocServiceTaxAmt,IvD_TotalDisc,IvD_ManualID, Case when length(IvD_ModifierHdrCode) > 0 then 'PackageItemOrder' else 'ItemOrder'  end as 'OrderType'  from InvoiceHdr IH left join invoicedtl ID on IH.IvH_docno = ID.IvD_docno where ih.ivH_docno = ? order by IvD_AutoNo", invNo];
        
        while ([rs next]) {
            [invDetailArray addObject:[rs resultDictionary]];
            
            FMResultSet *rsCdm = [db executeQuery:@"Select ' - - ' || IVC_CDDescription as IvD_ItemDescription, IVC_CDQty as IvD_Quantity, '0.00' as IvD_UnitPrice, '0.0' as IvD_DiscValue, '0.00' as IvD_TotalInc, '0.00' as IvD_TotalEx, '0.00' as IvH_DocSubTotal, '0.00' as IvH_DocAmt, '0.00' as IvH_DocTaxAmt, '0.00' as IvH_DiscAmt, '0.00' as IvH_DocServiceTaxAmt,'0.00' as IvD_TotalDisc, 'CondimentOrder' as OrderType from InvoiceCondiment where IVC_CDManualKey = ?", [rs stringForColumn:@"IvD_ManualID"]];
            
            while ([rsCdm next]) {
                [invDetailArray addObject:[rsCdm resultDictionary]];
            }
            [rsCdm close];
            
        }
        
        [rs close];
    }];
    
    for (int i = 0; i < invDetailArray.count; i++) {
        if ([[[invDetailArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"]) {
            self.labelDetailDiscount.text = [NSString stringWithFormat:@"%0.2f",[[[invDetailArray objectAtIndex:i]objectForKey:@"IvH_DiscAmt"] doubleValue]];
            self.labelDetailGTotal.text = [NSString stringWithFormat:@"%0.2f",[[[invDetailArray objectAtIndex:i]objectForKey:@"IvH_DocAmt"] doubleValue]];
            self.labelDetailTax.text = [NSString stringWithFormat:@"%0.2f",[[[invDetailArray objectAtIndex:i]objectForKey:@"IvH_DocTaxAmt"] doubleValue]];
            self.labelDetailTotal.text = [NSString stringWithFormat:@"%0.2f",[[[invDetailArray objectAtIndex:i]objectForKey:@"IvD_TotalEx"] doubleValue] + [self.labelDetailTotal.text doubleValue]];
            self.labelDetailSVG.text = [NSString stringWithFormat:@"%0.2f",[[[invDetailArray objectAtIndex:i]objectForKey:@"IvH_DocServiceTaxAmt"] doubleValue]];
        }
        
    }
    
    
    [queue close];
    
    //[dbTable close];
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
    return invDetailArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    InvoiceDetailCell *cell = [tableView dequeueReusableCellWithIdentifier:@"InvoiceDetailCell"];
    
    
    cell.labelDQty.text = [NSString stringWithFormat:@"%0.2f",[[[invDetailArray objectAtIndex:indexPath.row] objectForKey:@"IvD_Quantity"] doubleValue]];
    if ([[[invDetailArray objectAtIndex:indexPath.row]objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"]) {
        cell.labelDItemDesc.text = [[invDetailArray objectAtIndex:indexPath.row] objectForKey:@"IvD_ItemDescription"];
        cell.labelDUnitPrice.text = [NSString stringWithFormat:@"%0.2f",[[[invDetailArray objectAtIndex:indexPath.row]objectForKey:@"IvD_UnitPrice"] doubleValue]];
        cell.labelDDiscAmt.text = [NSString stringWithFormat:@"%0.2f",[[[invDetailArray objectAtIndex:indexPath.row]objectForKey:@"IvD_TotalDisc"] doubleValue]];
        cell.labelDTotalAmt.text = [NSString stringWithFormat:@"%0.2f",[[[invDetailArray objectAtIndex:indexPath.row]objectForKey:@"IvD_TotalEx"] doubleValue]];
    }
    else if ([[[invDetailArray objectAtIndex:indexPath.row]objectForKey:@"OrderType"] isEqualToString:@"PackageItemOrder"])
    {
        cell.labelDItemDesc.text = [NSString stringWithFormat:@" - %@",[[invDetailArray objectAtIndex:indexPath.row] objectForKey:@"IvD_ItemDescription"]];
        cell.labelDQty.text = @"1.00";
        cell.labelDUnitPrice.text = @"";
        cell.labelDDiscAmt.text = @"";
        cell.labelDTotalAmt.text = @"";
    }
    else
    {
        cell.labelDItemDesc.text = [NSString stringWithFormat:@"%@",[[invDetailArray objectAtIndex:indexPath.row] objectForKey:@"IvD_ItemDescription"]];
        
        cell.labelDUnitPrice.text = @"";
        cell.labelDDiscAmt.text = @"";
        cell.labelDTotalAmt.text = @"";
    }
    
    
    
    
    if (indexPath.row % 2) {
        cell.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0];
    } else {
        cell.backgroundColor = [UIColor whiteColor];
    }
    
    return cell;
    
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
    //return 360;
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
