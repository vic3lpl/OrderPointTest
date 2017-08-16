//
//  SalesOrderDetailReportViewController.m
//  IpadOrder
//
//  Created by IRS on 28/06/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import "SalesOrderDetailReportViewController.h"
#import "LibraryAPI.h"
#import <FMDB.h>
#import "SalesOrderDetailTableViewCell.h"

@interface SalesOrderDetailReportViewController ()
{
    NSString *dbPath;
    FMDatabase *dbTable;
    NSMutableArray *soDetailArray;
}
@end

@implementation SalesOrderDetailReportViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableViewSODetail.delegate = self;
    self.tableViewSODetail.dataSource = self;
    dbPath = [[LibraryAPI sharedInstance]getDbPath];
    soDetailArray = [[NSMutableArray alloc] init];
    // Do any additional setup after loading the view from its nib.
    self.title = @"Voided Order Detail";
    UINib *catNib = [UINib nibWithNibName:@"SalesOrderDetailTableViewCell" bundle:nil];
    [[self tableViewSODetail]registerNib:catNib forCellReuseIdentifier:@"SalesOrderDetailTableViewCell"];
    
    self.tableViewSODetail.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self getSalesOrderListingDetailData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - sqlite

-(void)getSalesOrderListingDetailData
{
    dbTable = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTable open]) {
        NSLog(@"Fail To Open");
        return;
    }
    [soDetailArray removeAllObjects];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"select SOD_ItemDescription,SOD_Quantity, SOD_UnitPrice, SOD_DiscValue, SOD_TotalInc, SOD_TotalEx, SOH_DocSubTotal, SOH_DocAmt, SOH_DocTaxAmt, SOH_DiscAmt, SOH_DocServiceTaxAmt,SOD_TotalDisc,SOD_ManualID, Case when length(SOD_ModifierHdrCode) > 0 then 'PackageItemOrder' else 'ItemOrder'  end as 'OrderType' from SalesOrderHdr SOH left join SalesOrderDtl SOD on SOH.SOH_DocNo = SOD.SOD_DocNo where SOH.SOH_DocNo = ? order by SOD_AutoNo", _docNo];
        
        while ([rs next]) {
            [soDetailArray addObject:[rs resultDictionary]];
            
            FMResultSet *rsCdm = [dbTable executeQuery:@"Select ' - - ' || SOC_CDDescription as SOC_ItemDescription, SOC_CDQty as SOC_Quantity, '0.00' as SOC_UnitPrice, '0.0' as SOC_DiscValue, '0.00' as SOC_TotalInc, '0.00' as SOC_TotalEx, '0.00' as SOC_DocSubTotal, '0.00' as SOC_DocAmt, '0.00' as SOC_DocTaxAmt, '0.00' as SOC_DiscAmt, '0.00' as SOC_DocServiceTaxAmt,'0.00' as SOC_TotalDisc, 'CondimentOrder' as OrderType from SalesOrderCondiment where SOC_CDManualKey = ?", [rs stringForColumn:@"SOD_ManualID"]];
            
            while ([rsCdm next]) {
                [soDetailArray addObject:[rsCdm resultDictionary]];
            }
            [rsCdm close];
            
        }
        
        [rs close];
        
    }];
    [queue close];
    
    for (int i = 0; i < soDetailArray.count; i++) {
        self.labelSalesOrderDiscAmt.text = [NSString stringWithFormat:@"%0.2f",[[[soDetailArray objectAtIndex:i]objectForKey:@"SOH_DiscAmt"] doubleValue]];
        self.labelSalesOrderTotalAmt.text = [NSString stringWithFormat:@"%0.2f",[[[soDetailArray objectAtIndex:i]objectForKey:@"SOH_DocAmt"] doubleValue]];
        self.labelSalesOrderTaxAmt.text = [NSString stringWithFormat:@"%0.2f",[[[soDetailArray objectAtIndex:i]objectForKey:@"SOH_DocTaxAmt"] doubleValue]];
        self.labelSalesOrderExSubTotalAmt.text = [NSString stringWithFormat:@"%0.2f",[[[soDetailArray objectAtIndex:i]objectForKey:@"SOD_TotalEx"] doubleValue] + [self.labelSalesOrderExSubTotalAmt.text doubleValue]];
        self.labelSalesOrderSVCAmt.text = [NSString stringWithFormat:@"%0.2f",[[[soDetailArray objectAtIndex:i]objectForKey:@"SOH_DocServiceTaxAmt"] doubleValue]];
    }
    
    //[rs close];
    [dbTable close];
}

#pragma mark - tableview

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    // Return the number of rows in the section.
    return soDetailArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    SalesOrderDetailTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SalesOrderDetailTableViewCell"];
    
    if ([[[soDetailArray objectAtIndex:indexPath.row]objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"])
    {
        cell.labelSODItemDesc.text = [[soDetailArray objectAtIndex:indexPath.row] objectForKey:@"SOD_ItemDescription"];
        cell.labelSODQty.text = [[[soDetailArray objectAtIndex:indexPath.row] objectForKey:@"SOD_Quantity"] stringValue];
        cell.labelSODPrice.text = [NSString stringWithFormat:@"%0.2f",[[[soDetailArray objectAtIndex:indexPath.row]objectForKey:@"SOD_UnitPrice"] doubleValue]];
        cell.labelSODDiscAmt.text = [NSString stringWithFormat:@"%0.2f",[[[soDetailArray objectAtIndex:indexPath.row]objectForKey:@"SOD_TotalDisc"] doubleValue]];
        cell.labelSODTotal.text = [NSString stringWithFormat:@"%0.2f",[[[soDetailArray objectAtIndex:indexPath.row]objectForKey:@"SOD_TotalEx"] doubleValue]];
    }
    else if ([[[soDetailArray objectAtIndex:indexPath.row]objectForKey:@"OrderType"] isEqualToString:@"PackageItemOrder"])
    {
        cell.labelSODItemDesc.text = [NSString stringWithFormat:@" - %@",[[soDetailArray objectAtIndex:indexPath.row] objectForKey:@"SOD_ItemDescription"]];
        cell.labelSODQty.text = @"1.00";
        cell.labelSODQty.text = @"";
        cell.labelSODDiscAmt.text = @"";
        cell.labelSODTotal.text = @"";
    }
    else
    {
        cell.labelSODItemDesc.text = [NSString stringWithFormat:@"%@",[[soDetailArray objectAtIndex:indexPath.row] objectForKey:@"SOC_ItemDescription"]];
        
        cell.labelSODPrice.text = @"";
        cell.labelSODDiscAmt.text = @"";
        cell.labelSODTotal.text = @"";
    }
    
    
    
    
    if (indexPath.row % 2) {
        cell.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0];
        
    } else {
        cell.backgroundColor = [UIColor whiteColor];
    }
    
    return cell;
    
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
