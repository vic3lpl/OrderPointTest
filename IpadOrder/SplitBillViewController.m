//
//  SplitBillViewController.m
//  IpadOrder
//
//  Created by IRS on 8/21/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "SplitBillViewController.h"
#import <FMDB.h>
#import "LibraryAPI.h"
#import "OrderFinalCell.h"
#import "OrderFinalDiscountCell.h"
#import "AppDelegate.h"
#import "SplitBillTableViewCell.h"
#import "SplitBillDiscountTableViewCell.h"
#import "SplitBillQtyViewController.h"

@interface SplitBillViewController ()
{
    FMDatabase *dbTable;
    NSMutableArray *finalSplitBillArray;
    NSMutableArray *recalSpliBillArray;
    
    double gstPercent;
    NSString *dbPath;
    
    NSString *docNo;
    BOOL dbNoError;
    //int selectedTableNo;
    NSString *taxType;
    
    NSString *itemCode;
    double itemDiscountInPercent;
    int position;
    NSString *orgIMQty;
    NSString *orgDiscAmt;
    BOOL insertResult;
    NSString *oldSONo;
    NSString *orgPrice;
    
    NSString *cancelStatus;
    
    // service tax
    NSString *serviceTaxGstTotal123;
    NSString *serviceTaxGstTotalRight;
    NSString *serviceTaxGstTotalLeft;
    double serviceTaxGst;
    NSString *tpServiceTax2;
    
    // for take away
    NSString *takeAwayYN;
    
    // for enable gst
    int enableGstYN;
    
    //multipeer data transfer use
    NSMutableArray *combineOldNewSOArray;
    NSString *terminalType;
    AppDelegate *appDelegate;
    MCPeerID *specificPeer;
    NSMutableArray *requestServerData;
    NSString *strDiffSide;
    NSString *sodManualID;
    NSString *sodModifierHdrCode;
    //-----------------------------
    NSString *imTotalCondimentSurCharge;
    
    
}
@property (nonatomic, strong)UIPopoverPresentationController *popOverSplitBillPay;
-(void)getSplitBillSalesOrderNoWithNotification:(NSNotification *)notification;

-(void)getSplitBillSalesOrderDtlWithNotification:(NSNotification *)notification;
@end

@implementation SplitBillViewController
@synthesize splitBillArray;
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.preferredContentSize = CGSizeMake(1000, 710);
    
    self.navigationController.navigationBar.hidden = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(getSplitBillSalesOrderNoWithNotification:)
                                                 name:@"GetSplitBillSalesOrderNoWithNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(getSplitBillSalesOrderDtlWithNotification:)
                                                 name:@"GetSplitBillSalesOrderDtlWithNotification"
                                               object:nil];
    
    dbPath = [[LibraryAPI sharedInstance]getDbPath];
    docNo = [[LibraryAPI sharedInstance]getDocNo];
    oldSONo = docNo;
    //selectedTableNo = [[LibraryAPI sharedInstance]getTableNo];
    taxType = [[LibraryAPI sharedInstance]getTaxType];
    enableGstYN = [[LibraryAPI sharedInstance]getEnableGst];
    cancelStatus = @"NoPay";
    terminalType = [[LibraryAPI sharedInstance]getWorkMode];
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    requestServerData = [[NSMutableArray alloc] init];
    
    self.splitBillTableView.dataSource = self;
    self.splitBillTableView.delegate = self;
    self.splitBillTableView.separatorColor = [UIColor clearColor];
    
    self.subSplitBillTableView.delegate = self;
    self.subSplitBillTableView.dataSource = self;
    self.subSplitBillTableView.separatorColor = [UIColor clearColor];
    
    self.splitBillTableView.allowsMultipleSelection = YES;
    splitBillArray = [[NSMutableArray alloc] init];
    finalSplitBillArray = [[NSMutableArray alloc]init];
    recalSpliBillArray = [[NSMutableArray alloc]init];
    combineOldNewSOArray = [[NSMutableArray alloc]init];
    
    tpServiceTax2 = [[LibraryAPI sharedInstance]getServiceTaxPercent];
    serviceTaxGst = [[LibraryAPI sharedInstance]getServiceTaxGstPercent];
    /*
    UIGraphicsBeginImageContext(self.view.frame.size);
    [[UIImage imageNamed:@"promtBlue.jpg"] drawInRect:self.view.bounds];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:image];
    */
    UINib *finalNib = [UINib nibWithNibName:@"SplitBillTableViewCell" bundle:nil];
    [[self splitBillTableView]registerNib:finalNib forCellReuseIdentifier:@"SplitBillTableViewCell"];
    
    UINib *subNib = [UINib nibWithNibName:@"SplitBillTableViewCell" bundle:nil];
    [[self subSplitBillTableView]registerNib:subNib forCellReuseIdentifier:@"SplitBillTableViewCell"];
    
    self.splitBillTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.subSplitBillTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    if ([taxType isEqualToString:@"Inc"]) {
        self.label1.text = @"Total Tax(Inc)";
        self.label2.text = @"Total Tax(Inc)";
    }
    else
    {
        self.label1.text = @"Total Tax(Excl)";
        self.label2.text = @"Total Tax(Excl)";
    }
    
    if ([terminalType isEqualToString:@"Main"])
    {
        [self checkTableStatus];
    }
    else
    {
        self.soO.text = docNo;
        [self requestSOWantToSplitFromServer];
    }
    
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillLayoutSubviews
{
    //[super viewWillLayoutSubviews];
    //self.view.superview.bounds = CGRectMake(0, 0, 1000, 710);
    //[self getItemMast];
}

-(void)viewDidLayoutSubviews
{
    if ([self.splitBillTableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.splitBillTableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([self.splitBillTableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.splitBillTableView setLayoutMargins:UIEdgeInsetsZero];
    }
    
    if ([self.subSplitBillTableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.subSplitBillTableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([self.subSplitBillTableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.subSplitBillTableView setLayoutMargins:UIEdgeInsetsZero];
    }
}

#pragma mark - sqlite

-(void)checkTableStatus
{
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        
        NSString *itemServiceTaxGst;
        NSString *itemServiceTaxGstLong;
        
        FMResultSet *rs1 = [db executeQuery:@"Select SOD_ItemCode as IM_ItemCode, SOD_ItemDescription as IM_Description,"
                            "SOD_Price as IM_Price2,SOD_Quantity as IM_Qty,SOD_DiscValue as IM_Discount,SOD_SellingPrice as IM_SellingPrice,"
                            "SOD_UnitPrice as IM_Price, SOD_Remark as IM_Remark, SOD_TakeAway_YN as IM_TakeAway_YN,"
                            "SOD_DiscType as IM_DiscountType, SOD_SellTax as IM_Tax, SOD_TotalSalesTax as IM_TotalTax,"
                            "SOD_TotalSalesTaxLong as IM_totalItemTaxAmtLong, SOD_TotalEx as IM_totalItemSellingAmt,"
                            "SOD_TotalExLong as IM_totalItemSellingAmtLong, SOD_TotalInc as IM_Total, SOD_TotalDisc as IM_DiscountAmt,SOD_SubTotal as IM_SubTotal,SOD_DiscInPercent as IM_DiscountInPercent,SOH_DocNo,SOD_DocNo,SOH_Status, SOH_DocAmt, SOH_DocSubTotal, SOH_DiscAmt, SOH_DocTaxAmt,SOH_DocServiceTaxAmt, SOH_DocServiceTaxGstAmt,SOH_Rounding,IFNULL(T_Percent,'0') as T_Percent, IFNULL(T_Name,'-') as IM_TaxCode"
                            " , IFNULL(SOD_ServiceTaxCode,'-') as IM_ServiceTaxCode, SOD_ServiceTaxAmt as IM_ServiceTaxAmt, SOD_ServiceTaxRate as IM_ServiceTaxRate "
                            " ,SOD_TakeAwayYN as IM_TakeAwayYN, SOH_PaxNo , IFNULL(SOD_TotalCondimentSurCharge,'0.00') as SOD_TotalCondimentSurCharge, SOD_ManualID, SOD_ModifierID, SOD_ModifierHdrCode"
                            " from SalesOrderHdr s1"
                            " left join SalesOrderDtl s2"
                            " on s1.SOH_DocNo = s2.SOD_DocNo"
                            //" left join ItemMast I1 on s2.SOD_ItemNo = I1.IM_ItemCode"
                            " left join Tax T1 on s2.SOD_TaxCode = T1.T_Name"
                            " where s1.SOH_Table = ? and s1.SOH_Status = 'New' and SOH_DocNo = ? order by SOD_AutoNo", _splitTableName,docNo];
        
        
        if ([dbTable hadError]) {
            [self showAlertView:[dbTable lastErrorMessage] title:@"Fail"];
        }
        
        while ([rs1 next]) {
            
            docNo = [rs1 stringForColumn:@"SOH_DocNo"];
            NSMutableDictionary *data = [NSMutableDictionary dictionary];
            //[orderFinalArray addObject:[rs1 resultDictionary]];
            
            self.soO.text = [rs1 stringForColumn:@"SOH_DocNo"];
            [data setObject:@"OldSO" forKey:@"SplitType"];
            
            //[data setObject:[NSString stringWithFormat:@"%ld",(long)[rs1 intForColumn:@"IM_ItemNo"]] forKey:@"IM_ItemNo"];
            [data setObject:[rs1 stringForColumn:@"IM_ItemCode"] forKey:@"IM_ItemCode"];
            [data setObject:[rs1 stringForColumn:@"IM_Description"] forKey:@"IM_Description"];
            [data setObject:[NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"IM_Price"]] forKey:@"IM_Price"];
            [data setObject:[NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"IM_Price2"]] forKey:@"IM_SalesPrice"];
            //one item selling price not included tax
            [data setObject:[rs1 stringForColumn:@"IM_SellingPrice"] forKey:@"IM_SellingPrice"];
            [data setObject:[rs1 stringForColumn:@"IM_DiscountInPercent"] forKey:@"IM_DiscountInPercent"];
            [data setObject:[rs1 stringForColumn:@"IM_Tax"] forKey:@"IM_Tax"];
            [data setObject:[NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"IM_Qty"]] forKey:@"IM_Qty"];
            
            [data setObject:[rs1 stringForColumn:@"T_Percent"] forKey:@"IM_Gst"];
            
            [data setObject:[rs1 stringForColumn:@"IM_TotalTax"] forKey:@"IM_TotalTax"]; //sum tax amt
            [data setObject:[rs1 stringForColumn:@"IM_DiscountType"]forKey:@"IM_DiscountType"];
            [data setObject:[rs1 stringForColumn:@"IM_Discount"] forKey:@"IM_Discount"]; // discount given
            [data setObject:[NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"IM_DiscountAmt"] ] forKey:@"IM_DiscountAmt"];  // sum discount
            [data setObject:[rs1 stringForColumn:@"IM_SubTotal"] forKey:@"IM_SubTotal"];
            [data setObject:[rs1 stringForColumn:@"IM_Total"] forKey:@"IM_Total"];
            [data setObject:[rs1 stringForColumn:@"IM_totalItemSellingAmt"]forKey:@"IM_totalItemSellingAmt"];  // subtotal not include tax n will replace this
            [data setObject:[rs1 stringForColumn:@"IM_totalItemSellingAmtLong"]forKey:@"IM_totalItemSellingAmtLong"];  // subtotal not include tax
            [data setObject:[rs1 stringForColumn:@"IM_totalItemTaxAmtLong"] forKey:@"IM_totalItemTaxAmtLong"];  // total tax amt
            
            //IM_totalItemSellingAmtLong
            
            if ([taxType isEqualToString:@"Inc"]) {
                itemServiceTaxGst = [NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"IM_ServiceTaxAmt"] * ([[LibraryAPI sharedInstance]getServiceTaxGstPercent] / 100)];
                itemServiceTaxGstLong = [NSString stringWithFormat:@"%0.6f",[rs1 doubleForColumn:@"IM_ServiceTaxAmt"] * ([[LibraryAPI sharedInstance] getServiceTaxGstPercent]/100)];
            }
            else
            {
                itemServiceTaxGst = @"0.00";
                itemServiceTaxGstLong = [rs1 stringForColumn:@"IM_ServiceTaxAmt"];
            }
            
            //---------tax code-------------
            [data setObject:[rs1 stringForColumn:@"IM_TaxCode"] forKey:@"IM_GSTCode"];
            
            //-------------service tax-------------
            [data setObject:[rs1 stringForColumn:@"IM_ServiceTaxCode"] forKey:@"IM_ServiceTaxCode"];  //svc tax code
            [data setObject:[rs1 stringForColumn:@"IM_ServiceTaxAmt"] forKey:@"IM_ServiceTaxAmt"]; // service tax amount
            [data setObject:[rs1 stringForColumn:@"IM_ServiceTaxRate"] forKey:@"IM_ServiceTaxRate"];
            [data setObject:itemServiceTaxGst forKey:@"IM_ServiceTaxGstAmt"];
            [data setObject:itemServiceTaxGstLong forKey:@"IM_ServiceTaxGstAmtLong"];
            
            
            serviceTaxGstTotal123 = [NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"SOH_DocServiceTaxGstAmt"]];
            
            //-----------for take away----------------------
            [data setObject:[NSString stringWithFormat:@"%d",[rs1 intForColumn:@"IM_TakeAwayYN"]] forKey:@"IM_TakeAwayYN"];
            
            [data setObject:[rs1 stringForColumn:@"IM_Remark"] forKey:@"IM_Remark"];
            
            //------------ for table pax data -------------------
            [data setObject:[rs1 stringForColumn:@"SOH_PaxNo"] forKey:@"SOH_PaxNo"];
            
            // for condiment calculation
            
            [data setObject:[NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"SOD_TotalCondimentSurCharge"]] forKey:@"IM_TotalCondimentSurCharge"];
            [data setObject:[rs1 stringForColumn:@"SOD_ManualID"] forKey:@"SOD_ManualID"];
            [data setObject:[NSString stringWithFormat:@"%ld",splitBillArray.count + 1] forKey:@"Index"];
            //------------ for transfer data use ----------------
            [data setObject:@"SplitSaleOrder" forKey:@"IM_Flag"];
            [data setObject:self.soO.text forKey:@"IM_DocNo"];
            [data setObject:_splitTableName forKey:@"SOH_TableName"];
            [data setObject:@"1" forKey:@"IM_InsertSplitFlag"];
            
            [data setObject:@"0.00" forKey:@"SOH_DocSubTotal"];
            [data setObject:@"0.00" forKey:@"SOH_DiscAmt"];
            [data setObject:@"0.00" forKey:@"SOH_DocTaxAmt"];
            [data setObject:@"0.00" forKey:@"SOH_DocAmt"];
            [data setObject:@"0.00" forKey:@"SOH_Rounding"];
            [data setObject:@"0.00" forKey:@"SOH_DocServiceTaxAmt"];
            [data setObject:@"0.00" forKey:@"SOH_DocServiceTaxGstAmt"];
            [data setObject:@"OrgSplitSO" forKey:@"PayForWhich"];
            
            // for modifier
            [data setObject:[rs1 stringForColumn:@"SOD_ModifierID"] forKey:@"SOD_ModifierID"];
            [data setObject:[rs1 stringForColumn:@"SOD_ModifierHdrCode"] forKey:@"SOD_ModifierHdrCode"];
            
            if ([[rs1 stringForColumn:@"SOD_ModifierHdrCode"]length] > 0) {
                [data setObject:@"PackageItemOrder" forKey:@"OrderType"];
                [data setObject:@"Yes" forKey:@"UnderPackageItemYN"];
                [data setObject:@"1" forKey:@"PD_MinChoice"];
                [data setObject:@"00" forKey:@"PackageItemIndex"];
                [data setObject:[rs1 stringForColumn:@"SOD_ModifierHdrCode"] forKey:@"PD_ModifierHdrCode"];
            }
            else
            {
                [data setObject:@"No" forKey:@"UnderPackageItemYN"];
                [data setObject:@"ItemOrder" forKey:@"OrderType"];
                [data setObject:@"1" forKey:@"PD_MinChoice"];
            }
            
            if ([[rs1 stringForColumn:@"SOD_ModifierHdrCode"] isEqualToString:[rs1 stringForColumn:@"IM_ItemCode"]])
            {
                [data setObject:@"ItemMast" forKey:@"PD_ItemType"];
            }
            else{
                [data setObject:@"Modifier" forKey:@"PD_ItemType"];
            }
            
            if ([[rs1 stringForColumn:@"SOD_ModifierHdrCode"]length] == 0 && [[rs1 stringForColumn:@"SOD_ModifierID"] length] > 0) {
                [data setObject:@"1" forKey:@"IM_ServiceType"];
            }
            
            self.labelOrgSubTotal.text = [NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"SOH_DocSubTotal"]];
            self.labelOrgTotalDiscount.text = [NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"SOH_DiscAmt"]];
            
            self.labelOrgTotalTax.text = [rs1 stringForColumn:@"SOH_DocTaxAmt"];
            
            self.labelOrgTotal.text = [NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"SOH_DocAmt"]];
            self.labelOrgRounding.text = [NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"SOH_Rounding"]];
            self.labelOrgServiceCharge.text = [NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"SOH_DocServiceTaxAmt"]];
            
            self.labelOrgExSubTotal.text = [NSString stringWithFormat:@"%0.2f",[rs1 doubleForColumn:@"IM_totalItemSellingAmt"] + [self.labelOrgExSubTotal.text doubleValue]];
            
            [splitBillArray addObject:data];
            
            [splitBillArray addObjectsFromArray:[PublicSqliteMethod getSalesOrderCondimentWithDBPath:dbPath SalesOrderNo:docNo ItemCode:[rs1 stringForColumn:@"IM_ItemCode"] ManualID:[rs1 stringForColumn: @"SOD_ManualID"] ParentIndex:splitBillArray.count]];
            
        }
        [rs1 close];
        
    }];
    
    [queue close];
    //[dbTable close];
    
    //[self.splitBillTableView reloadData];
    [self reIndexSplitBillArray];
    
}

-(BOOL)insertIntoSalesOrder:(NSString *)date OldSO:(NSString *)oldSO NewSO:(NSString *)newSO
{
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSString *newSONo;
        NSString *modifierID = @"";
        NSString *modifierHdrCode = @"";
        
        [db executeUpdate:@"Delete from SalesOrderHdr where SOH_DocNo = ?",oldSO];
        
        [db executeUpdate:@"Delete from SalesOrderDtl where SOD_DocNo = ?",oldSO];
        
        [db executeUpdate:@"Delete from SalesOrderCondiment where SOC_DocNo = ?",oldSO];
        
        [db executeUpdate:@"Delete from SalesOrderHdr where SOH_DocNo = ?",newSO];
        
        [db executeUpdate:@"Delete from SalesOrderDtl where SOD_DocNo = ?",newSO];
        
        [db executeUpdate:@"Delete from SalesOrderCondiment where SOC_DocNo = ?",newSO];
        
        //NSLog(@"%@",self.labelOrgSubTotal.text);
        FMResultSet *docRs = [db executeQuery:@"Select DOC_Number,DOC_Header from DocNo"
                              " where DOC_Header = 'SO'"];
        int updateDocNo = 0;
        if ([docRs next]) {
            updateDocNo = [docRs intForColumn:@"DOC_Number"] + 1;
            newSONo = [NSString stringWithFormat:@"%@%09.f",[docRs stringForColumn:@"DOC_Header"],[[docRs stringForColumn:@"DOC_Number"]doubleValue] + 1];
        }
        [docRs close];
        
        NSUInteger taxIncludedYN = 0;
        
        if ([[[LibraryAPI sharedInstance] getTaxType] isEqualToString:@"IEx"]) {
            taxIncludedYN = 0;
        }
        else
        {
            taxIncludedYN = 1;
        }
        
        @try {
            //---------left side sales order
            if (splitBillArray.count > 0) {
                
                dbNoError = [db executeUpdate:@"Insert into SalesOrderHdr ("
                             "SOH_DocNo,SOH_Date,SOH_DocAmt,SOH_DiscAmt,SOH_Rounding,SOH_Table,SOH_User,SOH_AcctCode,SOH_Status, SOH_DocSubTotal,SOH_DocTaxAmt,SOH_DocServiceTaxAmt,SOH_DocServiceTaxGstAmt, SOH_PaxNo,SOH_TerminalName,SOH_TaxIncluded_YN,SOH_ServiceTaxGstCode,SOH_CustName,SOH_CustAdd1,SOH_CustAdd2,SOH_CustAdd3,SOH_CustTelNo,SOH_CustGstNo)"
                             "values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",newSONo,date,self.labelOrgTotal.text,self.labelOrgTotalDiscount.text,self.labelOrgRounding.text,_splitTableName,[[LibraryAPI sharedInstance] getUserName],@"Cash",@"New",self.labelOrgSubTotal.text,self.labelOrgTotalTax.text,self.labelOrgServiceCharge.text,serviceTaxGstTotalLeft,_splitPaxNo,@"Server",[NSNumber numberWithInteger:taxIncludedYN],[[LibraryAPI sharedInstance] getServiceTaxGstCode],[_splitCustomerInfoDict objectForKey:@"Name"],[_splitCustomerInfoDict objectForKey:@"Add1"],[_splitCustomerInfoDict objectForKey:@"Add2"],[_splitCustomerInfoDict objectForKey:@"Add3"],[_splitCustomerInfoDict objectForKey:@"TelNo"],[_splitCustomerInfoDict objectForKey:@"GstNo"]];
                if (dbNoError) {
                    for (int i = 0; i < splitBillArray.count; i++) {
                        if ([[[splitBillArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"] ||
                            [[[splitBillArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"PackageItemOrder"])
                        {
                            
                            if ([[[splitBillArray objectAtIndex:i] objectForKey:@"IM_ServiceType"] isEqualToString:@"1"])
                            {
                                modifierID = [NSString stringWithFormat:@"M%@-%@",newSONo,[[splitBillArray objectAtIndex:i] objectForKey:@"Index"]];
                            }
                            else
                            {
                                if ([[[splitBillArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"]) {
                                    modifierID = @"";
                                }
                            }
                            
                            if ([[[splitBillArray objectAtIndex:i] objectForKey:@"SOD_ModifierHdrCode"] length] > 0) {
                                modifierHdrCode = [[splitBillArray objectAtIndex:i] objectForKey:@"SOD_ModifierHdrCode"];
                            }
                            else{
                                modifierHdrCode = @"";
                            }
                            
                            if ([[[splitBillArray objectAtIndex:i] objectForKey:@"IM_Qty"]doubleValue] > 0.00 || [[[splitBillArray objectAtIndex:i] objectForKey:@"SOD_ModifierHdrCode"] length] > 0) {
                                dbNoError = [db executeUpdate:@"Insert into SalesOrderDtl "
                                             "(SOD_AcctCode, SOD_DocNo, SOD_ItemCode, SOD_ItemDescription, SOD_Quantity, SOD_Price, SOD_DiscValue, SOD_SellingPrice, SOD_UnitPrice, SOD_Remark, SOD_TakeAway_YN,SOD_DiscType,SOD_SellTax,SOD_TotalSalesTax,SOD_TotalSalesTaxLong,SOD_TotalEx,SOD_TotalExLong,SOD_TotalInc,SOD_TotalDisc,SOD_SubTotal,SOD_DiscInPercent,SOD_TaxCode,SOD_ServiceTaxCode, SOD_ServiceTaxAmt, SOD_TaxRate,SOD_ServiceTaxRate,SOD_TakeAwayYN,SOD_TotalCondimentSurCharge,SOD_ManualID,SOD_TerminalName,SOD_ModifierID, SOD_ModifierHdrCode) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",@"Cash",newSONo,[[splitBillArray objectAtIndex:i] objectForKey:@"IM_ItemCode"],[[splitBillArray objectAtIndex:i] objectForKey:@"IM_Description"],[[splitBillArray objectAtIndex:i] objectForKey:@"IM_Qty"],[[splitBillArray objectAtIndex:i] objectForKey:@"IM_SalesPrice"],[[splitBillArray objectAtIndex:i] objectForKey:@"IM_Discount"],[[splitBillArray objectAtIndex:i] objectForKey:@"IM_SellingPrice"],[[splitBillArray objectAtIndex:i] objectForKey:@"IM_Price"],[[splitBillArray objectAtIndex:i] objectForKey:@"IM_Remark"],[NSNumber numberWithInt:0],[[splitBillArray objectAtIndex:i] objectForKey:@"IM_DiscountType"],[[splitBillArray objectAtIndex:i] objectForKey:@"IM_Tax"],[[splitBillArray objectAtIndex:i] objectForKey:@"IM_TotalTax"],
                                             [[splitBillArray objectAtIndex:i] objectForKey:@"IM_totalItemTaxAmtLong"],[[splitBillArray objectAtIndex:i] objectForKey:@"IM_totalItemSellingAmt"],
                                             [[splitBillArray objectAtIndex:i] objectForKey:@"IM_totalItemSellingAmtLong"],[[splitBillArray objectAtIndex:i] objectForKey:@"IM_Total"],[[splitBillArray objectAtIndex:i] objectForKey:@"IM_DiscountAmt"],[[splitBillArray objectAtIndex:i] objectForKey:@"IM_SubTotal"],[[splitBillArray objectAtIndex:i] objectForKey:@"IM_DiscountInPercent"],([[[splitBillArray objectAtIndex:i] objectForKey:@"IM_GSTCode"] isEqualToString:@"-"])?nil:[[splitBillArray objectAtIndex:i] objectForKey:@"IM_GSTCode"],([[[splitBillArray objectAtIndex:i]objectForKey:@"IM_ServiceTaxCode"] isEqualToString:@"-"])?nil:[[splitBillArray objectAtIndex:i]objectForKey:@"IM_ServiceTaxCode"],[[splitBillArray objectAtIndex:i]objectForKey:@"IM_ServiceTaxAmt"],[[splitBillArray objectAtIndex:i] objectForKey:@"IM_Gst"],[[splitBillArray objectAtIndex:i] objectForKey:@"IM_ServiceTaxRate"],[[splitBillArray objectAtIndex:i] objectForKey:@"IM_TakeAwayYN"],[[splitBillArray objectAtIndex:i] objectForKey:@"IM_TotalCondimentSurCharge"],[NSString stringWithFormat:@"%@-%@",newSONo,[[splitBillArray objectAtIndex:i] objectForKey:@"Index"]],@"Server", modifierID, modifierHdrCode];
                                
                            }
                            
                        }
                        else
                        {
                            dbNoError = [db executeUpdate:@"Insert into SalesOrderCondiment"
                                         " (SOC_DocNo, SOC_ItemCode, SOC_CHCode, SOC_CDCode, SOC_CDDescription, SOC_CDPrice, SOC_CDDiscount, SOC_DateTime,SOC_CDQty,SOC_CDManualKey) Values (?,?,?,?,?,?,?,?,?,?)",newSONo,[[splitBillArray objectAtIndex:i] objectForKey:@"ItemCode"],[[splitBillArray objectAtIndex:i] objectForKey:@"CHCode"],[[splitBillArray objectAtIndex:i] objectForKey:@"CDCode"],[[splitBillArray objectAtIndex:i] objectForKey:@"CDDescription"],[[splitBillArray objectAtIndex:i] objectForKey:@"CDPrice"],[NSNumber numberWithDouble:0.00],date,[[splitBillArray objectAtIndex:i] objectForKey:@"UnitQty"],[NSString stringWithFormat:@"%@-%@",newSONo,[[splitBillArray objectAtIndex:i] objectForKey:@"ParentIndex"]]];
                        }
                        
                        if (!dbNoError) {
                            insertResult = false;
                            [self showAlertView:[dbTable lastErrorMessage] title:@"Fail"];
                            *rollback = YES;
                            return;
                        }
                        else
                        {
                            dbNoError = [db executeUpdate:@"Update DocNo set DOC_Number = ? where DOC_Header = 'SO'",[NSNumber numberWithInt:updateDocNo]];
                            if (!dbNoError) {
                                insertResult = false;
                                [self showAlertView:[dbTable lastErrorMessage] title:@"Fail"];
                                *rollback = YES;
                                return;
                            }
                            else
                            {
                                self.soO.text = newSONo;
                            }
                        }
                        
                        
                    }
                    
                }
                else
                {
                    insertResult = false;
                    [self showAlertView:[dbTable lastErrorMessage] title:@"Fail"];
                    *rollback = YES;
                    return;
                }
            }
            
            
            //----------change org so to new so--------------------
            
            if (finalSplitBillArray.count > 0) {
                FMResultSet *docRs2 = [db executeQuery:@"Select DOC_Number,DOC_Header from DocNo"
                                       " where DOC_Header = 'SO'"];
                if ([docRs2 next]) {
                    updateDocNo = [docRs2 intForColumn:@"DOC_Number"] + 1;
                    newSONo = [NSString stringWithFormat:@"%@%09.f",[docRs2 stringForColumn:@"DOC_Header"],[[docRs2 stringForColumn:@"DOC_Number"]doubleValue] + 1];
                }
                [docRs2 close];
                // right side sales order
                dbNoError = [db executeUpdate:@"Insert into SalesOrderHdr ("
                             "SOH_DocNo,SOH_Date,SOH_DocAmt,SOH_DiscAmt,SOH_Rounding,SOH_Table,SOH_User,SOH_AcctCode,SOH_Status, SOH_DocSubTotal,SOH_DocTaxAmt,SOH_DocServiceTaxAmt,SOH_DocServiceTaxGstAmt,SOH_PaxNo,SOH_TerminalName,SOH_TaxIncluded_YN,SOH_ServiceTaxGstCode,SOH_CustName,SOH_CustAdd1,SOH_CustAdd2,SOH_CustAdd3,SOH_CustTelNo,SOH_CustGstNo)"
                             "values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",newSONo,date,self.labelTotalAmt.text,self.labelTotalDiscount.text,self.labelRounding.text,_splitTableName,[[LibraryAPI sharedInstance] getUserName],@"Cash",@"New",self.labelSubTotal.text,self.labelTotalTax.text,self.labelTotalServiceCharge.text,serviceTaxGstTotalRight,@"0",@"Server",[NSNumber numberWithInteger:taxIncludedYN],[[LibraryAPI sharedInstance] getServiceTaxGstCode],[_splitCustomerInfoDict objectForKey:@"Name"],[_splitCustomerInfoDict objectForKey:@"Add1"],[_splitCustomerInfoDict objectForKey:@"Add2"],[_splitCustomerInfoDict objectForKey:@"Add3"],[_splitCustomerInfoDict objectForKey:@"TelNo"],[_splitCustomerInfoDict objectForKey:@"GstNo"]];
                if (dbNoError) {
                    for (int i = 0; i < finalSplitBillArray.count; i++) {
                        if ([[[finalSplitBillArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"] ||
                            [[[finalSplitBillArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"PackageItemOrder"])
                        {
                            
                            if ([[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_ServiceType"] isEqualToString:@"1"])
                            {
                                modifierID = [NSString stringWithFormat:@"M%@-%@",newSONo,[[finalSplitBillArray objectAtIndex:i] objectForKey:@"Index"]];
                            }
                            else
                            {
                                if ([[[finalSplitBillArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"]) {
                                    modifierID = @"";
                                }
                            }
                            
                            if ([[[finalSplitBillArray objectAtIndex:i] objectForKey:@"SOD_ModifierHdrCode"] length] > 0) {
                                modifierHdrCode = [[finalSplitBillArray objectAtIndex:i] objectForKey:@"SOD_ModifierHdrCode"];
                            }
                            else{
                                modifierHdrCode = @"";
                            }
                            
                            dbNoError = [db executeUpdate:@"Insert into SalesOrderDtl "
                                         "(SOD_AcctCode, SOD_DocNo, SOD_ItemCode, SOD_ItemDescription, SOD_Quantity, SOD_Price, SOD_DiscValue, SOD_SellingPrice, SOD_UnitPrice, SOD_Remark, SOD_TakeAway_YN,SOD_DiscType,SOD_SellTax,SOD_TotalSalesTax,SOD_TotalSalesTaxLong,SOD_TotalEx,SOD_TotalExLong,SOD_TotalInc,SOD_TotalDisc,SOD_SubTotal,SOD_DiscInPercent,SOD_TaxCode,SOD_ServiceTaxCode, SOD_ServiceTaxAmt, SOD_TaxRate,SOD_ServiceTaxRate,SOD_TakeAwayYN,SOD_TotalCondimentSurCharge,SOD_ManualID,SOD_TerminalName,SOD_ModifierID, SOD_ModifierHdrCode) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",@"Cash",newSONo,[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_ItemCode"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_Description"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_Qty"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_SalesPrice"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_Discount"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_SellingPrice"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_Price"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_Remark"],[NSNumber numberWithInt:0],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_DiscountType"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_Tax"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_TotalTax"],
                                         [[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_totalItemTaxAmtLong"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_totalItemSellingAmt"],
                                         [[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_totalItemSellingAmtLong"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_Total"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_DiscountAmt"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_SubTotal"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_DiscountInPercent"],([[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_GSTCode"] isEqualToString:@"-"])?nil:[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_GSTCode"],([[[finalSplitBillArray objectAtIndex:i]objectForKey:@"IM_ServiceTaxCode"] isEqualToString:@"-"])?nil:[[finalSplitBillArray objectAtIndex:i]objectForKey:@"IM_ServiceTaxCode"],[[finalSplitBillArray objectAtIndex:i]objectForKey:@"IM_ServiceTaxAmt"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_Gst"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_ServiceTaxRate"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_TakeAwayYN"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_TotalCondimentSurCharge"],[NSString stringWithFormat:@"%@-%@",newSONo,[[finalSplitBillArray objectAtIndex:i] objectForKey:@"Index"]],@"Server", modifierID, modifierHdrCode];
                        }
                        else
                        {
                            dbNoError = [db executeUpdate:@"Insert into SalesOrderCondiment"
                                         " (SOC_DocNo, SOC_ItemCode, SOC_CHCode, SOC_CDCode, SOC_CDDescription, SOC_CDPrice, SOC_CDDiscount, SOC_DateTime,SOC_CDQty,SOC_CDManualKey) Values (?,?,?,?,?,?,?,?,?,?)",newSONo,[[finalSplitBillArray objectAtIndex:i] objectForKey:@"ItemCode"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"CHCode"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"CDCode"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"CDDescription"],[[finalSplitBillArray objectAtIndex:i] objectForKey:@"CDPrice"],[NSNumber numberWithDouble:0.00],date,[[finalSplitBillArray objectAtIndex:i] objectForKey:@"UnitQty"],[NSString stringWithFormat:@"%@-%@",newSONo,[[finalSplitBillArray objectAtIndex:i] objectForKey:@"ParentIndex"]]];
                        }
                        
                        
                        
                        if (!dbNoError) {
                            insertResult = false;
                            [self showAlertView:[dbTable lastErrorMessage] title:@"Fail"];
                            *rollback = YES;
                            return;
                        }
                        else
                        {
                            dbNoError = [db executeUpdate:@"Update DocNo set DOC_Number = ? where DOC_Header = 'SO'",[NSNumber numberWithInt:updateDocNo]];
                            if (!dbNoError) {
                                insertResult= false;
                                [self showAlertView:[dbTable lastErrorMessage] title:@"Fail"];
                                *rollback = YES;
                                return;
                            }
                            else
                            {
                                self.soN.text = newSONo;
                                //[self.soN setTextColor:[UIColor blackColor]];
                                insertResult = true;
                            }
                        }
                    }
                    
                }
                else
                {
                    insertResult = false;
                    [self showAlertView:[dbTable lastErrorMessage] title:@"Fail"];
                    return;
                }
                
            }
        } @catch (NSException *exception) {
            insertResult = false;
            [self showAlertView:exception.reason title:@"Exception error"];
            *rollback = YES;
            return;
        } @finally {
            
        }
        
        
    }];
    
    [queue close];
    
    //[dbTable close];
    return insertResult;
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
    int rowCount;
    // Return the number of rows in the section.
    if (tableView == self.splitBillTableView) {
        rowCount = splitBillArray.count;
    }
    else if(tableView == self.subSplitBillTableView)
    {
        rowCount = finalSplitBillArray.count;
    }
    
    return  rowCount;
    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    id cellToReturn;
    
    if (tableView == self.splitBillTableView) {
        if ([[[splitBillArray objectAtIndex:indexPath.row]objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"])
        {
            if ([[[splitBillArray objectAtIndex:indexPath.row]objectForKey:@"IM_DiscountAmt"] isEqualToString:@"0.00"]) {
                SplitBillTableViewCell *orderFinalCell = [tableView dequeueReusableCellWithIdentifier:@"SplitBillTableViewCell"];
                
                UIImageView *line = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, orderFinalCell.bounds.size.width, 1)];
                line.backgroundColor = [UIColor colorWithRed:196/255.0 green:196/255.0 blue:196/255.0 alpha:1.0];
                [orderFinalCell addSubview:line];
                line = nil;
                
                [[orderFinalCell labelItemDesc] setText:[[splitBillArray objectAtIndex:indexPath.row] objectForKey:@"IM_Description"]];
                
                [[orderFinalCell labelItemQty] setText:[[splitBillArray objectAtIndex:indexPath.row]objectForKey:@"IM_Qty"]];
                [[orderFinalCell labelItemPrice] setText:[[splitBillArray objectAtIndex:indexPath.row]objectForKey:@"IM_Price"]];
                
                if ([[[splitBillArray objectAtIndex:indexPath.row]objectForKey:@"IM_TakeAwayYN"] isEqualToString:@"1"]) {
                    [[orderFinalCell labelTakeAway] setText:@"T"];
                    orderFinalCell.imgTakeAway.image = [UIImage imageNamed:@"takeaway"];
                }
                else
                {
                    [[orderFinalCell labelTakeAway] setText:@""];
                    orderFinalCell.imgTakeAway.image = [UIImage imageNamed:@"dinein"];
                }
                
                orderFinalCell.labelItemTotal.text = [NSString stringWithFormat:@"%0.2f",[[[splitBillArray objectAtIndex:indexPath.row] objectForKey:@"IM_Price"] doubleValue] * [[[splitBillArray objectAtIndex:indexPath.row] objectForKey:@"IM_Qty"] doubleValue]];
                
                cellToReturn = orderFinalCell;
            }
            else
            {
                UINib *nib = [UINib nibWithNibName:@"SplitBillDiscountTableViewCell" bundle:nil];
                [tableView registerNib:nib forCellReuseIdentifier:@"SplitBillDiscountTableViewCell"];
                SplitBillDiscountTableViewCell *orderFinalDiscountCell = [tableView dequeueReusableCellWithIdentifier:@"SplitBillDiscountTableViewCell"];
                
                UIImageView *line = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, orderFinalDiscountCell.bounds.size.width, 1)];
                line.backgroundColor = [UIColor colorWithRed:196/255.0 green:196/255.0 blue:196/255.0 alpha:1.0];
                [orderFinalDiscountCell addSubview:line];
                line = nil;
                
                [[orderFinalDiscountCell labelSplitDiscItem] setText:[[splitBillArray objectAtIndex:indexPath.row] objectForKey:@"IM_Description"]];
                [[orderFinalDiscountCell labelSplitDiscQty] setText:[[splitBillArray objectAtIndex:indexPath.row]objectForKey:@"IM_Qty"]];
                [[orderFinalDiscountCell labelSplitDiscPrice] setText:[[splitBillArray objectAtIndex:indexPath.row]objectForKey:@"IM_Price"]];
                
                
                if ([[[splitBillArray objectAtIndex:indexPath.row]objectForKey:@"IM_TakeAwayYN"] isEqualToString:@"1"]) {
                    [[orderFinalDiscountCell labelSplitDiscTakeAway] setText:@"T"];
                    orderFinalDiscountCell.imgSplitDiscTakeAway.image = [UIImage imageNamed:@"takeaway"];
                }
                else
                {
                    [[orderFinalDiscountCell labelSplitDiscTakeAway] setText:@""];
                    orderFinalDiscountCell.imgSplitDiscTakeAway.image = [UIImage imageNamed:@"dinein"];
                }
                
                orderFinalDiscountCell.labelSplitDiscDisc.text = [NSString stringWithFormat:@"(%@)",[[splitBillArray objectAtIndex:indexPath.row]objectForKey:@"IM_DiscountAmt"]];
                
                orderFinalDiscountCell.labelSplitDiscTotal.text = [NSString stringWithFormat:@"%0.2f",[[[splitBillArray objectAtIndex:indexPath.row] objectForKey:@"IM_Price"] doubleValue] * [[[splitBillArray objectAtIndex:indexPath.row] objectForKey:@"IM_Qty"] doubleValue]];
                
                cellToReturn = orderFinalDiscountCell;
            }

        }
        else if ([[[splitBillArray objectAtIndex:indexPath.row]objectForKey:@"OrderType"] isEqualToString:@"PackageItemOrder"])
        {
            SplitBillTableViewCell *orderFinalCell = [tableView dequeueReusableCellWithIdentifier:@"SplitBillTableViewCell"];
            
            UIImageView *line = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, orderFinalCell.bounds.size.width, 1)];
            line.backgroundColor = [UIColor whiteColor];
            [orderFinalCell addSubview:line];
            line = nil;
            
            
            [[orderFinalCell labelItemDesc] setText:[NSString stringWithFormat:@"  ~  %@",[[splitBillArray objectAtIndex:indexPath.row] objectForKey:@"IM_Description"]]];
            
            [[orderFinalCell labelItemQty] setText:@"1.00"];
            
            orderFinalCell.labelItemPrice.text = @"";
            
            orderFinalCell.labelItemTotal.text = @"";
            
            cellToReturn = orderFinalCell;
        }
        else
        {
            SplitBillTableViewCell *orderFinalCell = [tableView dequeueReusableCellWithIdentifier:@"SplitBillTableViewCell"];
            
            UIImageView *line = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, orderFinalCell.bounds.size.width, 1)];
            line.backgroundColor = [UIColor whiteColor];
            [orderFinalCell addSubview:line];
            line = nil;
            
            [[orderFinalCell labelItemDesc] setText:[NSString stringWithFormat:@"  ~    ~   %@",[[splitBillArray objectAtIndex:indexPath.row] objectForKey:@"CDDescription"]]];
            
            [[orderFinalCell labelItemQty] setText:[NSString stringWithFormat:@"%.2f",([[[splitBillArray objectAtIndex:indexPath.row]objectForKey:@"UnitQty"] doubleValue])]];
            [[orderFinalCell labelItemPrice] setText:@""];
            [[orderFinalCell labelItemTotal] setText:@""];
            
            cellToReturn = orderFinalCell;
        }
    }
    else if (tableView == self.subSplitBillTableView)
    {
        if ([[[finalSplitBillArray objectAtIndex:indexPath.row]objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"])
        {
            if ([[[finalSplitBillArray objectAtIndex:indexPath.row]objectForKey:@"IM_DiscountAmt"] isEqualToString:@"0.00"])
            {
                SplitBillTableViewCell *orderFinalCell = [tableView dequeueReusableCellWithIdentifier:@"SplitBillTableViewCell"];
                
                UIImageView *line = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, orderFinalCell.bounds.size.width, 1)];
                line.backgroundColor = [UIColor colorWithRed:196/255.0 green:196/255.0 blue:196/255.0 alpha:1.0];
                [orderFinalCell addSubview:line];
                line = nil;
                
                [[orderFinalCell labelItemDesc] setText:[[finalSplitBillArray objectAtIndex:indexPath.row] objectForKey:@"IM_Description"]];
                
                [[orderFinalCell labelItemQty] setText:[[finalSplitBillArray objectAtIndex:indexPath.row]objectForKey:@"IM_Qty"]];
                [[orderFinalCell labelItemPrice] setText:[[finalSplitBillArray objectAtIndex:indexPath.row]objectForKey:@"IM_Price"]];
                
                if ([[[finalSplitBillArray objectAtIndex:indexPath.row]objectForKey:@"IM_TakeAwayYN"] isEqualToString:@"1"]) {
                    [[orderFinalCell labelTakeAway] setText:@"T"];
                    orderFinalCell.imgTakeAway.image = [UIImage imageNamed:@"takeaway"];
                }
                else
                {
                    [[orderFinalCell labelTakeAway] setText:@""];
                    orderFinalCell.imgTakeAway.image = [UIImage imageNamed:@"dinein"];
                }
                
                orderFinalCell.labelItemTotal.text = [NSString stringWithFormat:@"%0.2f",[[[finalSplitBillArray objectAtIndex:indexPath.row] objectForKey:@"IM_Price"] doubleValue] * [[[finalSplitBillArray objectAtIndex:indexPath.row] objectForKey:@"IM_Qty"] doubleValue]];
                
                cellToReturn = orderFinalCell;
            }
            else
            {
                UINib *nib = [UINib nibWithNibName:@"SplitBillDiscountTableViewCell" bundle:nil];
                [tableView registerNib:nib forCellReuseIdentifier:@"SplitBillDiscountTableViewCell"];
                SplitBillDiscountTableViewCell *orderFinalDiscountCell = [tableView dequeueReusableCellWithIdentifier:@"SplitBillDiscountTableViewCell"];
                
                UIImageView *line = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, orderFinalDiscountCell.bounds.size.width, 1)];
                line.backgroundColor = [UIColor colorWithRed:196/255.0 green:196/255.0 blue:196/255.0 alpha:1.0];
                [orderFinalDiscountCell addSubview:line];
                line = nil;
                
                [[orderFinalDiscountCell labelSplitDiscItem] setText:[[finalSplitBillArray objectAtIndex:indexPath.row] objectForKey:@"IM_Description"]];
                [[orderFinalDiscountCell labelSplitDiscQty] setText:[[finalSplitBillArray objectAtIndex:indexPath.row]objectForKey:@"IM_Qty"]];
                [[orderFinalDiscountCell labelSplitDiscPrice] setText:[[finalSplitBillArray objectAtIndex:indexPath.row]objectForKey:@"IM_Price"]];
                
                
                if ([[[finalSplitBillArray objectAtIndex:indexPath.row]objectForKey:@"IM_TakeAwayYN"] isEqualToString:@"1"]) {
                    [[orderFinalDiscountCell labelSplitDiscTakeAway] setText:@"T"];
                    orderFinalDiscountCell.imgSplitDiscTakeAway.image = [UIImage imageNamed:@"takeaway"];
                }
                else
                {
                    [[orderFinalDiscountCell labelSplitDiscTakeAway] setText:@""];
                    orderFinalDiscountCell.imgSplitDiscTakeAway.image = [UIImage imageNamed:@"dinein"];
                }
                
                //[[orderFinalDiscountCell finalDisDis] setText:[[orderFinalArray objectAtIndex:indexPath.row]objectForKey:@"IM_DiscountAmt"]];
                
                orderFinalDiscountCell.labelSplitDiscDisc.text = [NSString stringWithFormat:@"(%@)",[[finalSplitBillArray objectAtIndex:indexPath.row]objectForKey:@"IM_DiscountAmt"]];
                
                orderFinalDiscountCell.labelSplitDiscTotal.text = [NSString stringWithFormat:@"%0.2f",[[[finalSplitBillArray objectAtIndex:indexPath.row] objectForKey:@"IM_Price"] doubleValue] * [[[finalSplitBillArray objectAtIndex:indexPath.row] objectForKey:@"IM_Qty"] doubleValue]];
                
                cellToReturn = orderFinalDiscountCell;
            }

        }
        else if ([[[finalSplitBillArray objectAtIndex:indexPath.row]objectForKey:@"OrderType"] isEqualToString:@"PackageItemOrder"])
        {
            SplitBillTableViewCell *orderFinalCell = [tableView dequeueReusableCellWithIdentifier:@"SplitBillTableViewCell"];
            
            UIImageView *line = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, orderFinalCell.bounds.size.width, 1)];
            line.backgroundColor = [UIColor whiteColor];
            [orderFinalCell addSubview:line];
            line = nil;
            
            
            [[orderFinalCell labelItemDesc] setText:[NSString stringWithFormat:@"  ~  %@",[[finalSplitBillArray objectAtIndex:indexPath.row] objectForKey:@"IM_Description"]]];
            
            [[orderFinalCell labelItemQty] setText:@"1.00"];
            
            orderFinalCell.labelItemPrice.text = @"";
            
            orderFinalCell.labelItemTotal.text = @"";
            
            cellToReturn = orderFinalCell;
        }
        else
        {
            SplitBillTableViewCell *orderFinalCell = [tableView dequeueReusableCellWithIdentifier:@"SplitBillTableViewCell"];
            
            UIImageView *line = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, orderFinalCell.bounds.size.width, 1)];
            line.backgroundColor = [UIColor whiteColor];
            [orderFinalCell addSubview:line];
            line = nil;
            
            [[orderFinalCell labelItemDesc] setText:[NSString stringWithFormat:@"  ~    ~   %@",[[finalSplitBillArray objectAtIndex:indexPath.row] objectForKey:@"CDDescription"]]];
            
            [[orderFinalCell labelItemQty] setText:[[finalSplitBillArray objectAtIndex:indexPath.row]objectForKey:@"UnitQty"]];
            [[orderFinalCell labelItemPrice] setText:@""];
            [[orderFinalCell labelItemTotal] setText:@""];
            
            cellToReturn = orderFinalCell;
        }
    }
    

    return cellToReturn;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (tableView == self.splitBillTableView) {
        
        if ([[[splitBillArray objectAtIndex:indexPath.row] objectForKey:@"OrderType"] isEqualToString:@"CondimentOrder"]) {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            return;
        }
        
        NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"OrderType MATCHES[cd] %@",
                                   @"ItemOrder"];
        
        NSArray *parentObject = [splitBillArray filteredArrayUsingPredicate:predicate1];
        
        if (parentObject.count == 1) {
            if ([[[splitBillArray objectAtIndex:indexPath.row] objectForKey:@"IM_Qty"] doubleValue] == 1) {
                [self showAlertView:@"Original bill cannot empty" title:@"Information"];
                return;
            }
        }
        predicate1 = nil;
        parentObject = nil;
        
        itemCode = [[splitBillArray objectAtIndex:indexPath.row] objectForKey:@"IM_ItemCode"];
        orgIMQty = [[splitBillArray objectAtIndex:indexPath.row] objectForKey:@"IM_Qty"];
        orgDiscAmt = [[splitBillArray objectAtIndex:indexPath.row] objectForKey:@"IM_DiscountAmt"];
        takeAwayYN = [[splitBillArray objectAtIndex:indexPath.row] objectForKey:@"IM_TakeAwayYN"];
        position = indexPath.row;
        orgPrice = [[splitBillArray objectAtIndex:indexPath.row] objectForKey:@"IM_Price"];
        sodManualID = [[splitBillArray objectAtIndex:indexPath.row] objectForKey:@"SOD_ManualID"];
        sodModifierHdrCode = [[splitBillArray objectAtIndex:indexPath.row] objectForKey:@"SOD_ModifierHdrCode"];
        
        imTotalCondimentSurCharge = [[splitBillArray objectAtIndex:indexPath.row] objectForKey:@"IM_TotalCondimentSurCharge"];
        
        itemDiscountInPercent = [[[splitBillArray objectAtIndex:indexPath.row]objectForKey:@"IM_DiscountInPercent"] doubleValue];
        
        if([sodModifierHdrCode length] > 0)
        {
            [self showAlertView:@"Modifier item cannot split" title:@"Warning"];
        }
        else if ([orgIMQty doubleValue] <= 0.00) {
            [self showAlertView:@"Qty is 0. Cannot split" title:@"Warning"];
        }
        else if ([orgIMQty doubleValue] == 1.00)
        {
            [combineOldNewSOArray removeAllObjects];
            [self passNumericBack:1 flag:@"recalcSplitSO" splitBillArrayIndex:0 TotalCondimentSurCharge:[[[splitBillArray objectAtIndex:indexPath.row] objectForKey:@"IM_TotalCondimentSurCharge"] doubleValue]];
            
            
            if (finalSplitBillArray.count == 0) {
                
            }
            else
            {
                [combineOldNewSOArray addObjectsFromArray:finalSplitBillArray];
            }
            
            
            
            if (splitBillArray.count == 0) {
                
            }
            else
            {
                [combineOldNewSOArray addObjectsFromArray:splitBillArray];
            }
            
            
        }
        else
        {
            
            NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"OrderType MATCHES[cd] %@",
                                       @"ItemOrder"];
            
            NSArray *parentObject = [splitBillArray filteredArrayUsingPredicate:predicate1];
            
            KeyNumericViewController *keyNumericViewController = [[KeyNumericViewController alloc] init];
            keyNumericViewController.delegate = self;
            keyNumericViewController.orgSOQty = [orgIMQty doubleValue];
            keyNumericViewController.orgSOItemCount = parentObject.count; //splitBillArray.count;
            keyNumericViewController.orgTotalCondimentSurcharge = [imTotalCondimentSurCharge doubleValue];
            [keyNumericViewController setModalPresentationStyle:UIModalPresentationFormSheet];
            //[keyNumericViewController setModalInPopover:YES];
            [self presentViewController:keyNumericViewController animated:NO completion:nil];
            
            predicate1 = nil;
            parentObject = nil;
            
            [combineOldNewSOArray removeAllObjects];
            [combineOldNewSOArray addObjectsFromArray:finalSplitBillArray];
            [combineOldNewSOArray addObjectsFromArray:splitBillArray];
            
        }
    }
    
    
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int height;
    if (tableView == self.splitBillTableView) {
        if ([[[splitBillArray objectAtIndex:indexPath.row] objectForKey:@"IM_DiscountAmt"] isEqualToString:@"0.00"]) {
            height = 44;
        }
        else
        {
            height = 70;
        }
    }
    else if (tableView == self.subSplitBillTableView)
    {
        if ([[[finalSplitBillArray objectAtIndex:indexPath.row] objectForKey:@"IM_DiscountAmt"] isEqualToString:@"0.00"]) {
            height = 44;
        }
        else
        {
            height = 70;
        }
    }
    
    
    return height;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView == self.subSplitBillTableView) {
        return YES;
    }
    else
    {
        return NO;
    }
    
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.subSplitBillTableView) {
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            
            if ([[[finalSplitBillArray objectAtIndex:indexPath.row] objectForKey:@"OrderType"]isEqualToString:@"CondimentOrder"]) {
                return;
            }
            else if ([[[finalSplitBillArray objectAtIndex:indexPath.row] objectForKey:@"OrderType"]isEqualToString:@"PackageItemOrder"])
            {
                return;
            }
            
            orgPrice = [[finalSplitBillArray objectAtIndex:indexPath.row] objectForKey:@"IM_Price"];
            
            NSMutableArray *discardedItems = [NSMutableArray array];
            //SomeObjectClass *item;
            [discardedItems addObject:[finalSplitBillArray objectAtIndex:indexPath.row]];
            
            if ([[[finalSplitBillArray objectAtIndex:indexPath.row] objectForKey:@"IM_ServiceType"] isEqualToString:@"1"]) {
                for (int i = 0; i < finalSplitBillArray.count; i++) {
                    
                    if ([[[finalSplitBillArray objectAtIndex:i] objectForKey:@"PackageItemIndex"] isEqualToString:[NSString stringWithFormat:@"%lu",indexPath.row + 1]])
                    {
                        [discardedItems addObject:[[finalSplitBillArray objectAtIndex:i] mutableCopy]];
                    }
                    
                    //[finalSplitBillArray addObjectsFromArray:discardedItems];
                    
                }
                
            }
            else
            {
                for (int i = 0; i < finalSplitBillArray.count; i++) {
                    
                    if ([[[finalSplitBillArray objectAtIndex:i] objectForKey:@"ParentIndex"] isEqualToString:[NSString stringWithFormat:@"%ld",indexPath.row + 1]])
                    [discardedItems addObject:[[finalSplitBillArray objectAtIndex:i] mutableCopy]];
                    
                }
            }
            
            [finalSplitBillArray removeObjectsInArray:discardedItems];
            [self reIndexFinalSplitBillArray];
            
            NSString *parentIndex;
            NSString *packageItemIndex;
            for (int i = 0; i < discardedItems.count; i++) {
                NSDictionary *data2 = [NSDictionary dictionary];
                data2 = [discardedItems objectAtIndex:i];
                if ([[[discardedItems objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"] || [[[discardedItems objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"PackageItemOrder"])
                {
                    [data2 setValue:[NSString stringWithFormat:@"%ld",splitBillArray.count + 1] forKey:@"Index"];
                    parentIndex = [NSString stringWithFormat:@"%ld",splitBillArray.count + 1];
                    
                    if ([[[discardedItems objectAtIndex:i] objectForKey:@"IM_ServiceType"] isEqualToString:@"1"]) {
                        packageItemIndex = [NSString stringWithFormat:@"%lu",splitBillArray.count + 1];
                    }
                    
                    if ([[[discardedItems objectAtIndex:i] objectForKey:@"PackageItemIndex"] length] > 0) {
                        [data2 setValue:packageItemIndex forKey:@"PackageItemIndex"];
                    }
                    
                }
                else
                {
                    [data2 setValue:parentIndex forKey:@"ParentIndex"];
                    if ([[[discardedItems objectAtIndex:i] objectForKey:@"UnderPackageItemYN"] isEqualToString:@"Yes"]){
                        [data2 setValue:packageItemIndex forKey:@"PackageItemIndex"];
                    }
                }
                
                [discardedItems replaceObjectAtIndex:i withObject:data2];
                data2 = nil;
            }
            
            [splitBillArray addObjectsFromArray:discardedItems];
            
            [self.splitBillTableView reloadData];
            [self.subSplitBillTableView reloadData];
            
            [self calcSalesTotal];
            // tell table to refresh now
        }
    }
    
}

#pragma mark - method
-(void)recalculateTax
{
    double itemExShort = 0.00;
    double itemExLong = 0.00;
    double finalTotalSellingFigure = 0.00;
    double finalTotalTax = 0.00;
    NSString *stringItemExLong;
    NSString *stringItemExShort;
    NSString *temp;
    
    double diffCent = 0.00;
    if ([taxType isEqualToString:@"Inc"]) {
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        for (int i = 0; i < finalSplitBillArray.count; i++) {
            //if ([[[splitBillArray objectAtIndex:i]objectForKey:@"IM_Selected"] isEqualToString:@"Yes"]) {
                data = [finalSplitBillArray objectAtIndex:i];
                [data setValue:[NSString stringWithFormat:@"%0.2f",[[[finalSplitBillArray objectAtIndex:i]objectForKey:@"IM_totalItemSellingAmtLong" ] doubleValue]] forKey:@"IM_totalItemSellingAmt"];
                
                [data setValue:[NSString stringWithFormat:@"%0.2f",[[[finalSplitBillArray objectAtIndex:i]objectForKey:@"IM_totalItemTaxAmtLong" ] doubleValue]] forKey:@"IM_TotalTax"];
                
                [finalSplitBillArray replaceObjectAtIndex:i withObject:data];
                
                itemExShort = itemExShort + [[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_totalItemSellingAmt"] doubleValue];
                stringItemExShort = [NSString stringWithFormat:@"%0.2f",itemExShort];
                
                itemExLong = itemExLong + [[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_totalItemSellingAmtLong"] doubleValue];
                stringItemExLong = [NSString stringWithFormat:@"%0.2f",itemExLong];
            //}
            
            
        }
        
        if ([stringItemExLong doubleValue] != [stringItemExShort doubleValue]) {
            //itemExLong = [stringItemExLong doubleValue] - [stringItemExShort doubleValue];
            itemExLong = itemExLong - itemExShort;
            temp = [NSString stringWithFormat:@"%0.2f",itemExLong];
            diffCent = [temp doubleValue];
            NSLog(@"checking %f",diffCent);
            
        }
        else
        {
            diffCent = 0.00;
        }
        
        NSMutableDictionary *data2 = [NSMutableDictionary dictionary];
        
        for (int i = finalSplitBillArray.count-1; i >= 0; i--) {
            
            if ( [[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_totalItemSellingAmt"] doubleValue] > diffCent)
            {
                
                finalTotalSellingFigure = [[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_totalItemSellingAmt"] doubleValue] + diffCent;
                finalTotalTax = [[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_TotalTax"] doubleValue] - diffCent;
                data2 = [finalSplitBillArray objectAtIndex:i];
                [data2 setValue:[NSString stringWithFormat:@"%0.2f",finalTotalSellingFigure] forKey:@"IM_totalItemSellingAmt"];
                [data2 setValue:[NSString stringWithFormat:@"%0.2f",finalTotalTax] forKey:@"IM_TotalTax"];
                
                [finalSplitBillArray replaceObjectAtIndex:i withObject:data];
                break;
            }
            
        }
    }
    
    [self calcSalesTotal];
    
}

-(void)calcSalesTotal
{
    
    NSString *labelTotalItemTax = @"0.00";
    
    //--------------right side bill--------------------
    self.labelRounding.text = @"0.00";
    self.labelSubTotal.text = @"0.00";
    self.labelTotalTax.text = @"0.00";
    self.labelTotalAmt.text = @"0.00";
    self.labelTotalDiscount.text = @"0.00";
    self.labelTotalServiceCharge.text = @"0.00";
    self.labelExSubTotal.text = @"0.00";
        
    NSDictionary *totalDictRight = [NSDictionary dictionary];
    NSString *totalTaxableAmtRight = @"0.00";
    NSString *totalTaxAmtRight = @"0.00";
    
    totalDictRight = [PublicSqliteMethod calclateSalesTotalWith:finalSplitBillArray TaxType:taxType ServiceTaxGst:serviceTaxGst DBPath:dbPath];
    
    if (![taxType isEqualToString:@"IEx"]) {
        NSString *finalTotalSellingFigure2;
        NSString *finalTotalTax2;
        double adjTax = 0.00;
        
        adjTax = [[NSString stringWithFormat:@"%0.2f",[[totalDictRight objectForKey:@"dccc"] doubleValue] - [[totalDictRight objectForKey:@"duuu"] doubleValue]] doubleValue];
        if (adjTax != 0.00) {
            
            NSMutableDictionary *data2 = [NSMutableDictionary dictionary];
            if ([[LibraryAPI sharedInstance] getEnableSVG] == 0) {
                int rowCount = 1;
                if ([[[finalSplitBillArray objectAtIndex:finalSplitBillArray.count - 1] objectForKey:@"IM_GSTCode"] isEqualToString:@"SR"]) {
                    rowCount = 1;
                }
                else
                {
                    rowCount = 2;
                }
                finalTotalSellingFigure2 = [NSString stringWithFormat:@"%.02f",[[[finalSplitBillArray objectAtIndex:finalSplitBillArray.count - rowCount] objectForKey:@"IM_totalItemSellingAmt"] doubleValue] - adjTax];
                
                finalTotalTax2 = [NSString stringWithFormat:@"%.02f",[[[finalSplitBillArray objectAtIndex:finalSplitBillArray.count - rowCount] objectForKey:@"IM_TotalTax"] doubleValue] + adjTax];
                data2 = [finalSplitBillArray objectAtIndex:finalSplitBillArray.count - rowCount];
                [data2 setValue:[NSString stringWithFormat:@"%@",finalTotalSellingFigure2] forKey:@"IM_totalItemSellingAmt"];
                [data2 setValue:[NSString stringWithFormat:@"%@",finalTotalTax2] forKey:@"IM_TotalTax"];
                
                [finalSplitBillArray replaceObjectAtIndex:finalSplitBillArray.count - rowCount withObject:data2];
                
            }
        }
    }
    
    if ([[LibraryAPI sharedInstance] getEnableSVG] == 0) {
        for (int i = 0; i < finalSplitBillArray.count; i++) {
            totalTaxableAmtRight = [NSString stringWithFormat:@"%0.2f",[[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_totalItemSellingAmt"] doubleValue] + [totalTaxableAmtRight doubleValue]];
            totalTaxAmtRight = [NSString stringWithFormat:@"%0.2f",[[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_TotalTax"] doubleValue] + [totalTaxAmtRight doubleValue]];
        }
    }
    else
    {
        totalTaxableAmtRight = [totalDictRight objectForKey:@"SubTotalEx"];
        totalTaxAmtRight = [totalDictRight objectForKey:@"TotalGst"];
    }
    
    self.labelExSubTotal.text = totalTaxableAmtRight;
    serviceTaxGstTotalRight = [totalDictRight objectForKey:@"TotalServiceChargeGst"];
    
    self.labelSubTotal.text = [totalDictRight objectForKey:@"SubTotal"];
    self.labelTotalTax.text = totalTaxAmtRight;
    self.labelTotalAmt.text = [totalDictRight objectForKey:@"Total"];
    self.labelTotalDiscount.text = [totalDictRight objectForKey:@"TotalDiscount"];
    self.labelTotalServiceCharge.text = [totalDictRight objectForKey:@"ServiceCharge"];
    self.labelRounding.text = [totalDictRight objectForKey:@"Rounding"];
    
    if (finalSplitBillArray.count > 0 ) {
        NSMutableDictionary *rightSidedata = [NSMutableDictionary dictionary];
        rightSidedata = [finalSplitBillArray objectAtIndex:0];
        
        [rightSidedata setValue:self.labelSubTotal.text forKey:@"SOH_DocSubTotal"];
        [rightSidedata setValue:self.labelTotalDiscount.text forKey:@"SOH_DiscAmt"];
        [rightSidedata setValue:self.labelTotalTax.text forKey:@"SOH_DocTaxAmt"];
        [rightSidedata setValue:self.labelTotalAmt.text forKey:@"SOH_DocAmt"];
        [rightSidedata setValue:self.labelRounding.text forKey:@"SOH_Rounding"];
        [rightSidedata setValue:self.labelTotalServiceCharge.text forKey:@"SOH_DocServiceTaxAmt"];
        [rightSidedata setValue:serviceTaxGstTotalRight forKey:@"SOH_DocServiceTaxGstAmt"];
        
        //[data setObject:@"0.00" forKey:@"SOH_DocServiceTaxGstAmt"];
        
        [finalSplitBillArray replaceObjectAtIndex:0 withObject:rightSidedata];
        rightSidedata = nil;
    }
    
    //---------------left side bill---------------------
    
    self.labelOrgRounding.text = @"0.00";
    self.labelOrgSubTotal.text = @"0.00";
    self.labelOrgTotal.text = @"0.00";
    self.labelOrgTotalDiscount.text = @"0.00";
    self.labelOrgTotalTax.text = @"0.00";
    self.labelOrgServiceCharge.text = @"0.00";
    self.labelOrgExSubTotal.text = @"0.00";
    labelTotalItemTax = @"0.00";
    
    NSDictionary *totalDictLeft = [NSDictionary dictionary];
    NSString *totalTaxableAmtLeft = @"0.00";
    NSString *totalTaxAmtLeft = @"0.00";
    
    totalDictLeft = [PublicSqliteMethod calclateSalesTotalWith:splitBillArray TaxType:taxType ServiceTaxGst:serviceTaxGst DBPath:dbPath];
    
    if (![taxType isEqualToString:@"IEx"]) {
        NSString *finalTotalSellingFigure2;
        NSString *finalTotalTax2;
        double adjTax = 0.00;
        
        adjTax = [[NSString stringWithFormat:@"%0.2f",[[totalDictLeft objectForKey:@"dccc"] doubleValue] - [[totalDictLeft objectForKey:@"duuu"] doubleValue]] doubleValue];
        if (adjTax != 0.00) {
            
            NSMutableDictionary *data2 = [NSMutableDictionary dictionary];
            if ([[LibraryAPI sharedInstance] getEnableSVG] == 0) {
                int rowCount = 1;
                if ([[[splitBillArray objectAtIndex:splitBillArray.count - 1] objectForKey:@"IM_GSTCode"] isEqualToString:@"SR"]) {
                    rowCount = 1;
                }
                else
                {
                    rowCount = 2;
                }
                finalTotalSellingFigure2 = [NSString stringWithFormat:@"%.02f",[[[splitBillArray objectAtIndex:splitBillArray.count - rowCount] objectForKey:@"IM_totalItemSellingAmt"] doubleValue] - adjTax];
                
                finalTotalTax2 = [NSString stringWithFormat:@"%.02f",[[[splitBillArray objectAtIndex:splitBillArray.count - rowCount] objectForKey:@"IM_TotalTax"] doubleValue] + adjTax];
                data2 = [splitBillArray objectAtIndex:splitBillArray.count - rowCount];
                [data2 setValue:[NSString stringWithFormat:@"%@",finalTotalSellingFigure2] forKey:@"IM_totalItemSellingAmt"];
                [data2 setValue:[NSString stringWithFormat:@"%@",finalTotalTax2] forKey:@"IM_TotalTax"];
                
                [splitBillArray replaceObjectAtIndex:splitBillArray.count - rowCount withObject:data2];
                
            }
        }
    }
    
    if ([[LibraryAPI sharedInstance] getEnableSVG] == 0) {
        for (int i = 0; i < splitBillArray.count; i++) {
            totalTaxableAmtLeft = [NSString stringWithFormat:@"%0.2f",[[[splitBillArray objectAtIndex:i] objectForKey:@"IM_totalItemSellingAmt"] doubleValue] + [totalTaxableAmtLeft doubleValue]];
            totalTaxAmtLeft = [NSString stringWithFormat:@"%0.2f",[[[splitBillArray objectAtIndex:i] objectForKey:@"IM_TotalTax"] doubleValue] + [totalTaxAmtLeft doubleValue]];
        }
    }
    else
    {
        totalTaxableAmtLeft = [totalDictLeft objectForKey:@"SubTotalEx"];
        totalTaxAmtLeft = [totalDictLeft objectForKey:@"TotalGst"];
    }

    self.labelOrgExSubTotal.text = totalTaxableAmtLeft;
    serviceTaxGstTotalLeft = [totalDictLeft objectForKey:@"TotalServiceChargeGst"];
    
    self.labelOrgSubTotal.text = [totalDictLeft objectForKey:@"SubTotal"];
    self.labelOrgTotalTax.text = totalTaxAmtLeft;
    self.labelOrgTotal.text = [totalDictLeft objectForKey:@"Total"];
    self.labelOrgTotalDiscount.text = [totalDictLeft objectForKey:@"TotalDiscount"];
    self.labelOrgServiceCharge.text = [totalDictLeft objectForKey:@"ServiceCharge"];
    self.labelOrgRounding.text = [totalDictLeft objectForKey:@"Rounding"];
    
    if (splitBillArray.count > 0 ) {
        NSMutableDictionary *leftSidedata = [NSMutableDictionary dictionary];
        leftSidedata = [splitBillArray objectAtIndex:0];
        
        [leftSidedata setValue:self.labelOrgSubTotal.text forKey:@"SOH_DocSubTotal"];
        [leftSidedata setValue:self.labelOrgTotalDiscount.text forKey:@"SOH_DiscAmt"];
        [leftSidedata setValue:self.labelOrgTotalTax.text forKey:@"SOH_DocTaxAmt"];
        [leftSidedata setValue:self.labelOrgTotal.text forKey:@"SOH_DocAmt"];
        [leftSidedata setValue:self.labelOrgRounding.text forKey:@"SOH_Rounding"];
        [leftSidedata setValue:self.labelOrgServiceCharge.text forKey:@"SOH_DocServiceTaxAmt"];
        [leftSidedata setValue:serviceTaxGstTotalLeft forKey:@"SOH_DocServiceTaxGstAmt"];
        
        [splitBillArray replaceObjectAtIndex:0 withObject:leftSidedata];
        leftSidedata = nil;
    }
    
}

-(void)recalcOldBill
{
    NSString *imQty;
    //NSString *imItemNo;
    for (int i = 0; i < splitBillArray.count; i++) {
        imQty = [[splitBillArray objectAtIndex:i] objectForKey:@"IM_Qty"];
        if ([imQty doubleValue] == 0.00) {
            //break;
        }
        else
        {
            itemCode = [[splitBillArray objectAtIndex:i] objectForKey:@"IM_ItemCode"];
            
        }
        
    }
    //
}

#pragma mark - btn click

- (IBAction)splitBillViewCancel:(id)sender {
    if (![self.soO.text isEqualToString:@"SO"]) {
        oldSONo = self.soO.text;
    }
    
    //NSLog(@"Checking Splitbill array : %@", finalSplitBillArray);
    
    [[LibraryAPI sharedInstance]setDocNo:oldSONo];
    if (_delegate != nil) {
        [self dismissViewControllerAnimated:NO completion:nil];
        [_delegate cancelSplitBill:cancelStatus];
        
    }
    
    //[self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)btnPayClick:(id)sender {
    
    cancelStatus = @"PayClick";
    strDiffSide = @"Yes Right";
    NSDate *today = [NSDate date];
    
    NSDateFormatter *dateFormat = [[LibraryAPI sharedInstance] getDateFormaterhhmmss];
    NSString *dateString = [dateFormat stringFromDate:today];
    BOOL splitSO;
    
    if (finalSplitBillArray.count<= 0) {
        [self showAlertView:@"Please split bill" title:@"Warning"];
        return;
    }
    
    if ([terminalType isEqualToString:@"Main"]) {
        if (self.soN.text.length > 2) {
            //splitSO = true;
            splitSO = [self insertIntoSalesOrder:dateString OldSO:self.soO.text NewSO:self.soN.text];
            
        }
        else
        {
            docNo = self.soO.text;
            splitSO = [self insertIntoSalesOrder:dateString OldSO:self.soO.text NewSO:self.soN.text];
        }
        
        
        if (!splitSO) {
            [self showAlertView:@"InValid Data" title:@"Fail"];
        }
        else
        {
            [self reindexSplitNFinalSplitArray];
            PaymentViewController *paymentViewController = [[PaymentViewController alloc]init];
            
            [[LibraryAPI sharedInstance]setDocNo:self.soN.text];
            
            [[LibraryAPI sharedInstance]setDirectOrderDetail:finalSplitBillArray];
            paymentViewController.delegate = self;
            paymentViewController.splitBill_YN = strDiffSide;
            paymentViewController.splitBillTotalAmt = self.labelTotalAmt.text;
            paymentViewController.splitBillTotalDiscAmt = self.labelTotalDiscount.text;
            paymentViewController.tbName = _splitTableName;
            paymentViewController.finalPaxNo = @"0";
            paymentViewController.splitBillTotalTaxAmt = self.labelTotalTax.text;
            paymentViewController.splitBillSubTotalAmt = self.labelSubTotal.text;
            paymentViewController.terminalType = [[LibraryAPI sharedInstance]getWorkMode];
            paymentViewController.dictPayCust = _splitCustomerInfoDict;
            
            UINavigationController *navbar = [[UINavigationController alloc]  initWithRootViewController:paymentViewController];
            navbar.modalPresentationStyle = UIModalPresentationPopover;
            
            _popOverSplitBillPay = [navbar popoverPresentationController];
            _popOverSplitBillPay.delegate = self;
            _popOverSplitBillPay.permittedArrowDirections = 0;
            _popOverSplitBillPay.sourceView = self.view;
            _popOverSplitBillPay.sourceRect = CGRectMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2, 1, 1);
            [self presentViewController:navbar animated:YES completion:nil];
            
        }
    }
    else
    {
        
        if ([terminalType isEqualToString:@"Terminal"]) {
            if([[appDelegate.mcManager connectedPeerArray]count] <= 0) {
                [self showAlertView:@"Server disconnect" title:@"Warning"];
                return;
            }
        }
        
        [combineOldNewSOArray removeAllObjects];
        
        if (finalSplitBillArray.count == 0) {
            NSMutableDictionary *data = [NSMutableDictionary dictionary];
            [data setObject:@"NewSO" forKey:@"SplitType"];
            [data setObject:@"SplitSaleOrder" forKey:@"IM_Flag"];
            [data setObject:self.soN.text forKey:@"IM_DocNo"];
            [data setObject:@"0" forKey:@"IM_InsertSplitFlag"];
            [finalSplitBillArray addObject:data];
            data = nil;
            [combineOldNewSOArray addObjectsFromArray:finalSplitBillArray];
        }
        else
        {
            NSMutableDictionary *modifySplitBillDict = [NSMutableDictionary dictionary];
            
            for (int i = 0; i < finalSplitBillArray.count; i++) {
                
                modifySplitBillDict = [[finalSplitBillArray objectAtIndex:i] mutableCopy];
                
                [modifySplitBillDict setValue:self.soN.text forKey:@"IM_DocNo"];
                [modifySplitBillDict setValue:@"NewSO" forKey:@"SplitType"];
                
                [finalSplitBillArray replaceObjectAtIndex:i withObject:modifySplitBillDict];
            }
            
            modifySplitBillDict = nil;
            
            [combineOldNewSOArray addObjectsFromArray:finalSplitBillArray];
        }
        
        if (splitBillArray.count == 0) {
            NSMutableDictionary *data = [NSMutableDictionary dictionary];
            [data setObject:@"OldSO" forKey:@"SplitType"];
            [data setObject:@"SplitSaleOrder" forKey:@"IM_Flag"];
            [data setObject:self.soO.text forKey:@"IM_DocNo"];
            [data setObject:@"0" forKey:@"IM_InsertSplitFlag"];
            [splitBillArray addObject:data];
            data = nil;
            [combineOldNewSOArray addObjectsFromArray:splitBillArray];
        }
        else
        {
            
            NSMutableDictionary *modifySplitBillDict = [NSMutableDictionary dictionary];
            
            for (int i = 0; i < splitBillArray.count; i++) {
                
                modifySplitBillDict = [[splitBillArray objectAtIndex:i] mutableCopy];
                
                [modifySplitBillDict setValue:self.soO.text forKey:@"IM_DocNo"];
                [modifySplitBillDict setValue:@"OldSO" forKey:@"SplitType"];
                [splitBillArray replaceObjectAtIndex:i withObject:modifySplitBillDict];
            }
            
            modifySplitBillDict = nil;
            
            //[combineOldNewSOArray addObjectsFromArray:finalSplitBillArray];
            
            [combineOldNewSOArray addObjectsFromArray:splitBillArray];
        }
        
        NSMutableDictionary *modifyPayForWhichSO = [NSMutableDictionary dictionary];
        
        
        for (int i = 0; i < combineOldNewSOArray.count; i++) {
            
            modifyPayForWhichSO = [[combineOldNewSOArray objectAtIndex:i] mutableCopy];
            
            [modifyPayForWhichSO setValue:@"NewSplitSO" forKey:@"PayForWhich"];
            
            [combineOldNewSOArray replaceObjectAtIndex:i withObject:modifyPayForWhichSO];
        }
        
        modifyPayForWhichSO = nil;
        
        [self sendSplitSOToServer];
    }
    
}


- (IBAction)btnPayOrgSO:(id)sender {
    cancelStatus = @"PayClick";
    strDiffSide = @"Yes Left";
    NSDate *today = [NSDate date];
    //NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    //[dateFormat setDateFormat:@"yyyy-MM-dd hh:mm"];
    NSDateFormatter *dateFormat = [[LibraryAPI sharedInstance] getDateFormaterhhmmss];
    NSString *dateString = [dateFormat stringFromDate:today];
    BOOL splitSO;
    
    if (splitBillArray.count<= 0) {
        [self showAlertView:@"Empty sales order" title:@"Warning"];
        return;
    }
    
    if ([terminalType isEqualToString:@"Main"]) {
        if (finalSplitBillArray.count<= 0) {
            //
            splitSO = [self insertIntoSalesOrder:dateString OldSO:self.soO.text NewSO:self.soN.text];
            [self orgSOCallPayment];
        }
        else
        {
            if (self.soN.text.length > 2) {
                //splitSO = true;
                splitSO = [self insertIntoSalesOrder:dateString OldSO:self.soO.text NewSO:self.soN.text];
                
            }
            else
            {
                docNo = self.soO.text;
                //splitSO = [self insertIntoSalesOrder:dateString];
                splitSO = [self insertIntoSalesOrder:dateString OldSO:self.soO.text NewSO:self.soN.text];
            }
            
            
            if (!splitSO) {
                [self showAlertView:@"InValid data" title:@"Fail"];
            }
            else
            {
                [self reindexSplitNFinalSplitArray];
                [self orgSOCallPayment];
                
            }
        }
    }
    else
    {
        
        if ([terminalType isEqualToString:@"Terminal"]) {
            if([[appDelegate.mcManager connectedPeerArray]count] <= 0) {
                [self showAlertView:@"Server disconnect" title:@"Warning"];
                return;
            }
        }
        
        if (finalSplitBillArray.count > 0) {
            NSMutableDictionary *data = [NSMutableDictionary dictionary];
            data = [finalSplitBillArray objectAtIndex:0];
            [data setValue:[_splitCustomerInfoDict objectForKey:@"Name"] forKey:@"CName"];
            [data setValue:[_splitCustomerInfoDict objectForKey:@"Add1"] forKey:@"CAdd1"];
            [data setValue:[_splitCustomerInfoDict objectForKey:@"Add2"] forKey:@"CAdd2"];
            [data setValue:[_splitCustomerInfoDict objectForKey:@"Add3"] forKey:@"CAdd3"];
            [data setValue:[_splitCustomerInfoDict objectForKey:@"TelNo"] forKey:@"CTelNo"];
            [data setValue:[_splitCustomerInfoDict objectForKey:@"GstNo"] forKey:@"CGstNo"];
            
            [finalSplitBillArray replaceObjectAtIndex:0 withObject:data];
            data = nil;
        }
        
        if (splitBillArray.count > 0) {
            NSMutableDictionary *data2 = [NSMutableDictionary dictionary];
            data2 = [splitBillArray objectAtIndex:0];
            [data2 setValue:[_splitCustomerInfoDict objectForKey:@"Name"] forKey:@"CName"];
            [data2 setValue:[_splitCustomerInfoDict objectForKey:@"Add1"] forKey:@"CAdd1"];
            [data2 setValue:[_splitCustomerInfoDict objectForKey:@"Add2"] forKey:@"CAdd2"];
            [data2 setValue:[_splitCustomerInfoDict objectForKey:@"Add3"] forKey:@"CAdd3"];
            [data2 setValue:[_splitCustomerInfoDict objectForKey:@"TelNo"] forKey:@"CTelNo"];
            [data2 setValue:[_splitCustomerInfoDict objectForKey:@"GstNo"] forKey:@"CGstNo"];
            
            [splitBillArray replaceObjectAtIndex:0 withObject:data2];
            data2 = nil;
        }
        
        [combineOldNewSOArray removeAllObjects];
        
        if (finalSplitBillArray.count == 0) {
            NSMutableDictionary *data = [NSMutableDictionary dictionary];
            [data setObject:@"NewSO" forKey:@"SplitType"];
            [data setObject:@"SplitSaleOrder" forKey:@"IM_Flag"];
            [data setObject:self.soN.text forKey:@"IM_DocNo"];
            [data setObject:@"0" forKey:@"IM_InsertSplitFlag"];
            
            [finalSplitBillArray addObject:data];
            data = nil;
            [combineOldNewSOArray addObjectsFromArray:finalSplitBillArray];
        }
        else
        {
            NSMutableDictionary *modifySplitBillDict = [NSMutableDictionary dictionary];
            
            for (int i = 0; i < finalSplitBillArray.count; i++) {
                
                modifySplitBillDict = [finalSplitBillArray objectAtIndex:i];
                
                [modifySplitBillDict setValue:self.soN.text forKey:@"IM_DocNo"];
                [modifySplitBillDict setObject:@"NewSO" forKey:@"SplitType"];
                [finalSplitBillArray replaceObjectAtIndex:i withObject:modifySplitBillDict];
            }
            
            modifySplitBillDict = nil;
            
            [combineOldNewSOArray addObjectsFromArray:finalSplitBillArray];
            
        }
        
        if (splitBillArray.count == 0) {
            NSMutableDictionary *data = [NSMutableDictionary dictionary];
            [data setObject:@"OldSO" forKey:@"SplitType"];
            [data setObject:@"SplitSaleOrder" forKey:@"IM_Flag"];
            [data setObject:self.soO.text forKey:@"IM_DocNo"];
            [data setObject:@"0" forKey:@"IM_InsertSplitFlag"];
            
            [splitBillArray addObject:data];
            data = nil;
            [combineOldNewSOArray addObjectsFromArray:splitBillArray];
        }
        else
        {
            
            NSMutableDictionary *modifySplitBillDict = [NSMutableDictionary dictionary];
            
            for (int i = 0; i < splitBillArray.count; i++) {
                
                modifySplitBillDict = [splitBillArray objectAtIndex:i];
                
                [modifySplitBillDict setValue:self.soO.text forKey:@"IM_DocNo"];
                [modifySplitBillDict setValue:@"OldSO" forKey:@"SplitType"];
                [splitBillArray replaceObjectAtIndex:i withObject:modifySplitBillDict];
            }
            
            modifySplitBillDict = nil;
            
            [combineOldNewSOArray addObjectsFromArray:splitBillArray];
        }
        
        NSMutableDictionary *modifyPayForWhichSO = [NSMutableDictionary dictionary];
        
        for (int i = 0; i < combineOldNewSOArray.count; i++) {
            
            modifyPayForWhichSO = [combineOldNewSOArray objectAtIndex:i];
            
            [modifyPayForWhichSO setValue:@"OldSplitSO" forKey:@"PayForWhich"];
            
            [combineOldNewSOArray replaceObjectAtIndex:i withObject:modifyPayForWhichSO];
        }
        
        modifyPayForWhichSO = nil;
        
        [self sendSplitSOToServer];
    }

}

#pragma mark - custom method

-(void)orgSOCallPayment
{
    PaymentViewController *paymentViewController = [[PaymentViewController alloc]init];
    
    [[LibraryAPI sharedInstance]setDocNo:self.soO.text];
    [[LibraryAPI sharedInstance]setDirectOrderDetail:splitBillArray];
    paymentViewController.delegate = self;
    paymentViewController.splitBill_YN = strDiffSide;
    paymentViewController.splitBillTotalAmt = self.labelOrgTotal.text;
    paymentViewController.splitBillTotalDiscAmt = self.labelOrgTotalDiscount.text;
    paymentViewController.splitBillTotalTaxAmt = self.labelOrgTotalTax.text;
    paymentViewController.splitBillSubTotalAmt = self.labelOrgSubTotal.text;
    paymentViewController.tbName = _splitTableName;
    paymentViewController.finalPaxNo = _splitPaxNo;
    paymentViewController.dictPayCust = _splitCustomerInfoDict;
    paymentViewController.terminalType = [[LibraryAPI sharedInstance]getWorkMode];
    
    
    UINavigationController *navbar = [[UINavigationController alloc]  initWithRootViewController:paymentViewController];
    navbar.modalPresentationStyle = UIModalPresentationPopover;
    //navbar.contentSizeForViewInPopover = CGSizeMake(266, 200);
    
    _popOverSplitBillPay = [navbar popoverPresentationController];
    _popOverSplitBillPay.delegate = self;
    _popOverSplitBillPay.permittedArrowDirections = 0;
    _popOverSplitBillPay.sourceView = self.view;
    _popOverSplitBillPay.sourceRect = CGRectMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2, 1, 1);
    [self presentViewController:navbar animated:YES completion:nil];
    
    /*
    self.popOverSplitBillPay = [[UIPopoverController alloc]initWithContentViewController:navbar];
    self.popOverSplitBillPay.delegate = self;
    [self.popOverSplitBillPay presentPopoverFromRect:CGRectMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2, 1, 1) inView:self.view permittedArrowDirections:0 animated:YES];
     */
    
    
}

#pragma mark - delegate method
-(void)successMakePayment:(NSString *)payLeftOrRight
{
    if ([payLeftOrRight isEqualToString:@"Yes Right"]) {
        [finalSplitBillArray removeAllObjects];
        [self.subSplitBillTableView reloadData];
        self.labelSubTotal.text = @"0.00";
        self.labelTotalTax.text = @"0.00";
        self.labelTotalAmt.text = @"0.00";
        self.labelTotalDiscount.text = @"0.00";
        self.labelTotalServiceCharge.text = @"0.00";
        [self.splitBillTableView reloadData];
        
        self.soN.text = @"SO";
        //[self.soN setTextColor:[UIColor clearColor]];
    }
    else
    {
        [splitBillArray removeAllObjects];
        [self.splitBillTableView reloadData];
        self.labelOrgSubTotal.text = @"0.00";
        self.labelOrgTotal.text = @"0.00";
        self.labelOrgTotalDiscount.text = @"0.00";
        self.labelOrgTotalTax.text = @"0.00";
        self.labelOrgServiceCharge.text = @"0.00";
        self.labelOrgRounding.text = @"0.00";
        self.labelOrgExSubTotal.text = @"0.00";
        self.soO.text = @"SO";
        //[self.splitBillTableView reloadData];
        
    }
    
    if (splitBillArray.count == 0 && finalSplitBillArray.count == 0) {
        if (![self.soO.text isEqualToString:@"SO"]) {
            oldSONo = self.soO.text;
        }
        
        [[LibraryAPI sharedInstance]setDocNo:oldSONo];
        if (_delegate != nil) {
            
            [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
            [_delegate cancelSplitBill:cancelStatus];
            
        }
        
    }
    else if (finalSplitBillArray.count == 0 && [self.labelOrgTotal.text isEqualToString:@"0.00"])
    {
        if (![self.soO.text isEqualToString:@"SO"]) {
            oldSONo = self.soO.text;
        }
        
        [[LibraryAPI sharedInstance]setDocNo:oldSONo];
        if (_delegate != nil) {
            
            [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
            [_delegate cancelSplitBill:cancelStatus];
            
        }
    }
    else
    {
        if ([terminalType isEqualToString:@"Terminal"]) {
            
            NSMutableDictionary *modifySplitBillDict = [NSMutableDictionary dictionary];
            
            for (int i = 0; i < splitBillArray.count; i++) {
                
                modifySplitBillDict = [splitBillArray objectAtIndex:i];
                
                [modifySplitBillDict setValue:self.soO.text forKey:@"IM_DocNo"];
                
                [splitBillArray replaceObjectAtIndex:i withObject:modifySplitBillDict];
            }
            
            modifySplitBillDict = nil;
            
        }
    }
    
}

-(void)cancelPayment:(NSString *)soOldNo
{
    //[[LibraryAPI sharedInstance]setDocNo:soOldNo];
    if ([soOldNo isEqualToString:@"CancelPay"]) {
        oldSONo = self.soO.text;
    }
    
}

-(void)passNumericBack:(double)noKey flag:(NSString *)flag splitBillArrayIndex:(int)index TotalCondimentSurCharge:(double)totalCondimentCharge
{
    [self recalculateOrder:noKey flag:flag splitBillArrayIndex:index TotalCondimentSurCharge:totalCondimentCharge];
    
    [self recalculateOrder:[[[splitBillArray objectAtIndex:position] objectForKey:@"IM_Qty"] doubleValue] flag:@"recalcOrgSO" splitBillArrayIndex:position TotalCondimentSurCharge:totalCondimentCharge];
    [self calcSalesTotal];
}

-(void)recalculateOrder:(double)qty flag:(NSString *)flag splitBillArrayIndex:(int)index TotalCondimentSurCharge:(double)charge
{
    //splitBillArray is org so
    //finalSplitBillArray is SO split from org SO
    
    dbTable = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTable open]) {
        NSLog(@"Fail To Open");
        return;
    }
    
    NSString *itemSellingPrice;
    NSString *itemPrice;
    NSString *totalTax;
    NSString *subTotal;
    NSString *itemTaxAmt;
    NSString *total;
    NSString *discountAmt;
    NSString *totalItemSellingAmt;
    NSString *totalItemTaxAmt;
    NSString *b4Discount;
    NSString *itemInPriceAfterDis;
    NSString *textServiceTax;
    NSString *sqlCommand;
    double serviceTaxRate;
    
    NSString *itemServiceTaxGst;
    NSString *itemServiceTaxGstLong;
    NSString *originalPackageItemIndex;
    
    sqlCommand = [NSString stringWithFormat:@"%@ %@ as FinalSellPrice,%@ as IM_TotalCondimentSurCharge",@"Select ItemMast.*, IFNULL(t1.T_Percent,'0') as T_Percent, IFNULL(t1.T_Name,'-') as T_Name, IFNULL(t2.T_Percent,'0') as Svc_Percent, IFNULL(t2.T_Name,'-') as Svc_Name,",orgPrice,imTotalCondimentSurCharge];
    
    FMResultSet *rs = [dbTable executeQuery:[NSString stringWithFormat:@"%@ %@",sqlCommand,@" from ItemMast "
                       "left join Tax t1 on ItemMast.IM_Tax = t1.T_Name "
                       " left join Tax t2 on ItemMast.IM_ServiceTax = t2.T_Name "
                       "where IM_ItemCode = ?"],itemCode];
    
    
    if ([rs next]) {
        //NSLog(@"%@",[rs stringForColumn:@"FinalSellPrice"]);
        if (enableGstYN == 0) {
            gstPercent = 0.00;
        }
        else
        {
            gstPercent = [rs doubleForColumn:@"T_Percent"];
        }
        
        if ([taxType isEqualToString:@"Inc"]) {
            //gst inc
            itemPrice = [NSString stringWithFormat:@"%.02f",[rs doubleForColumn:@"FinalSellPrice"]];
            itemSellingPrice = [NSString stringWithFormat:@"%0.6f",[rs doubleForColumn:@"FinalSellPrice"] / ((gstPercent / 100)+1)];
            itemTaxAmt = [NSString stringWithFormat:@"%.06f",[rs doubleForColumn:@"FinalSellPrice"] - [itemSellingPrice doubleValue]];
            if (itemDiscountInPercent == 0.00) {
                
                itemTaxAmt = [NSString stringWithFormat:@"%.06f",[rs doubleForColumn:@"FinalSellPrice"] - [itemSellingPrice doubleValue]];
                
                
                subTotal = [NSString stringWithFormat:@"%.02f",[rs doubleForColumn:@"FinalSellPrice"] * qty];
                discountAmt = @"0.00";
                totalTax = [NSString stringWithFormat:@"%.02f",[itemTaxAmt doubleValue] * qty];
                totalItemSellingAmt = [NSString stringWithFormat:@"%.06f",[subTotal doubleValue] / ((gstPercent / 100)+1)];
                totalItemTaxAmt = [NSString stringWithFormat:@"%.06f",[subTotal doubleValue] - [discountAmt doubleValue] - [totalItemSellingAmt doubleValue]];
                total = subTotal;
            }
            else
            {
                
                discountAmt = [NSString stringWithFormat:@"%.02f",[rs doubleForColumn:@"FinalSellPrice"] * (itemDiscountInPercent / 100) * qty];
                subTotal = [NSString stringWithFormat:@"%.02f",[rs doubleForColumn:@"FinalSellPrice"] * qty];
                b4Discount = [NSString stringWithFormat:@"%0.2f",[subTotal doubleValue] - [discountAmt doubleValue]];
                itemInPriceAfterDis = [NSString stringWithFormat:@"%0.6f",[b4Discount doubleValue] / ((gstPercent / 100)+1)];
                
                totalTax = [NSString stringWithFormat:@"%0.2f",[subTotal doubleValue] - [discountAmt doubleValue] - [itemInPriceAfterDis doubleValue]];
                
                total = [NSString stringWithFormat:@"%0.2f",[subTotal doubleValue] - [discountAmt doubleValue] - [itemInPriceAfterDis doubleValue]];
                
                totalItemSellingAmt = itemInPriceAfterDis;
                
                totalItemTaxAmt = [NSString stringWithFormat:@"%0.6f",[subTotal doubleValue] - [discountAmt doubleValue] - [itemInPriceAfterDis doubleValue]];
                
                
            }
            
            
        }
        else
        {
            // gst ex
            itemSellingPrice = [rs stringForColumn:@"FinalSellPrice"];
            itemPrice = [NSString stringWithFormat:@"%.02f",[rs doubleForColumn:@"FinalSellPrice"]];
            itemTaxAmt = [NSString stringWithFormat:@"%.02f",[rs doubleForColumn:@"FinalSellPrice"] * (gstPercent / 100)];;
            if (itemDiscountInPercent == 0.00) {
                discountAmt = @"0.00";
                
                subTotal = [NSString stringWithFormat:@"%.02f",[rs doubleForColumn:@"FinalSellPrice"] * qty];
                totalTax = [NSString stringWithFormat:@"%.02f",[subTotal doubleValue] * (gstPercent / 100)];
                
                total = [NSString stringWithFormat:@"%.02f",[subTotal doubleValue] + [totalTax doubleValue]];
                
                totalItemSellingAmt = subTotal;
                totalItemTaxAmt = [NSString stringWithFormat:@"%.06f",[subTotal doubleValue] * (gstPercent / 100)];
                //textServiceTax = [NSString stringWithFormat:@"%.02f",totalItemSellingAmt * (tpServiceTax / 100.0)];
            }
            else
            {
                discountAmt = [NSString stringWithFormat:@"%.02f",[rs doubleForColumn:@"FinalSellPrice"] * (itemDiscountInPercent / 100) * qty];
                subTotal = [NSString stringWithFormat:@"%.02f",[rs doubleForColumn:@"FinalSellPrice"] * qty];
                totalTax = [NSString stringWithFormat:@"%.02f",([subTotal doubleValue] - [discountAmt doubleValue]) * (gstPercent / 100)];
                total = [NSString stringWithFormat:@"%.02f",([subTotal doubleValue] + [totalTax doubleValue] - [discountAmt doubleValue])];
                //totalItemSellingAmt = [NSString stringWithFormat:@"%0.2f",[subTotal doubleValue] - [discountAmt doubleValue]];
                totalItemSellingAmt = [NSString stringWithFormat:@"%0.2f",[subTotal doubleValue]];
                //totalItemTaxAmt = totalTax;
                totalItemTaxAmt = [NSString stringWithFormat:@"%.06f",([subTotal doubleValue] - [discountAmt doubleValue]) * (gstPercent / 100)];
                
            }
            
        }
        
        if ([[LibraryAPI sharedInstance] getEnableSVG] == 1) {
            if ([_splitTableDineType isEqualToString:@"0"])
            {
                if ([takeAwayYN isEqualToString:@"0"]) {
                    if ([tpServiceTax2 isEqualToString:@"-"]) {
                        serviceTaxRate = [rs doubleForColumn:@"Svc_Percent"];
                    }
                    else
                    {
                        if ([rs doubleForColumn:@"Svc_Percent"] == 0.00) {
                            serviceTaxRate = [rs doubleForColumn:@"Svc_Percent"];
                        }
                        else
                        {
                            serviceTaxRate = [tpServiceTax2 doubleValue];
                        }
                        
                    }
                }
                else
                {
                    serviceTaxRate = 0.00;
                }
            }
            else
            {
                if ([rs doubleForColumn:@"Svc_Percent"] == 0.00) {
                    serviceTaxRate = [rs doubleForColumn:@"Svc_Percent"];
                }
                else
                {
                    if ([tpServiceTax2 isEqualToString:@"-"]) {
                        serviceTaxRate = 0;
                    }
                    else
                    {
                        serviceTaxRate = [tpServiceTax2 doubleValue];
                    }
                    
                }
            }
            
        }
        else
        {
            serviceTaxRate = 0.00;
            textServiceTax = @"0.00";
            itemServiceTaxGst = @"0.00";
            itemServiceTaxGstLong = @"0.00";
        }
        
        
        if ([taxType isEqualToString:@"Inc"]) {
            if (itemDiscountInPercent == 0) {
                textServiceTax = [NSString stringWithFormat:@"%.06f",[[NSString stringWithFormat:@"%0.8f",[totalItemSellingAmt doubleValue]]doubleValue] * (serviceTaxRate / 100.0)];
                
                itemServiceTaxGst = [NSString stringWithFormat:@"%0.2f",[textServiceTax doubleValue] * ([[LibraryAPI sharedInstance]getServiceTaxGstPercent] / 100)];
                itemServiceTaxGstLong = [NSString stringWithFormat:@"%0.6f",[textServiceTax doubleValue] * ([[LibraryAPI sharedInstance]getServiceTaxGstPercent] / 100)];
            }
            else
            {
                textServiceTax = [NSString stringWithFormat:@"%.06f",[itemInPriceAfterDis doubleValue] * (serviceTaxRate / 100.0)];
                
                itemServiceTaxGst = [NSString stringWithFormat:@"%0.2f",[textServiceTax doubleValue] * ([[LibraryAPI sharedInstance]getServiceTaxGstPercent] / 100)];
                itemServiceTaxGstLong = [NSString stringWithFormat:@"%0.6f",[textServiceTax doubleValue] * ([[LibraryAPI sharedInstance]getServiceTaxGstPercent] / 100)];
            }
        }
        else
        {
            if (itemDiscountInPercent == 0) {
                textServiceTax = [NSString stringWithFormat:@"%.06f",[[NSString stringWithFormat:@"%0.8f",[totalItemSellingAmt doubleValue]]doubleValue] * (serviceTaxRate / 100.0)];
                
                itemServiceTaxGst = @"0.00";
                itemServiceTaxGstLong = textServiceTax;
            }
            else
            {
                textServiceTax = [NSString stringWithFormat:@"%.06f",([totalItemSellingAmt doubleValue] - [discountAmt doubleValue]) * (serviceTaxRate / 100.0)];
                
                itemServiceTaxGst = @"0.00";
                itemServiceTaxGstLong = textServiceTax;
            }
        }
        
    }
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    
    if ([flag isEqualToString:@"recalcSplitSO"] ) {
        [data setObject:@"NewSO" forKey:@"SplitType"];
        [data setObject:self.soN.text forKey:@"IM_DocNo"];
    }
    else if ([flag isEqualToString:@"recalcOrgSO"])
    {
        [data setObject:@"OldSO" forKey:@"SplitType"];
        [data setObject:self.soO.text forKey:@"IM_DocNo"];
    }
    
    [data setObject:[NSString stringWithFormat:@"%@",itemCode] forKey:@"IM_ItemCode"];
    [data setObject:[rs stringForColumn:@"IM_Description"] forKey:@"IM_Description"];
    [data setObject:itemPrice forKey:@"IM_Price"];
    [data setObject:[rs stringForColumn:@"IM_SalesPrice"] forKey:@"IM_SalesPrice"];
    //one item selling price not included tax
    [data setObject:itemSellingPrice forKey:@"IM_SellingPrice"];
    [data setObject:[NSString stringWithFormat:@"%@",itemTaxAmt] forKey:@"IM_Tax"];
    [data setObject:[NSString stringWithFormat:@"%0.2f",qty] forKey:@"IM_Qty"];
    [data setObject:[NSString stringWithFormat:@"%f",itemDiscountInPercent] forKey:@"IM_DiscountInPercent"];
    
    [data setObject:[NSString stringWithFormat:@"%ld",(long)gstPercent] forKey:@"IM_Gst"];
    
    [data setObject:totalTax forKey:@"IM_TotalTax"]; //sum tax amt
    [data setObject:[NSString stringWithFormat:@"%ld",(long)0] forKey:@"IM_DiscountType"];
    [data setObject:[NSString stringWithFormat:@"%f",itemDiscountInPercent] forKey:@"IM_Discount"]; // discount given
    [data setObject:discountAmt forKey:@"IM_DiscountAmt"];  // sum discount
    [data setObject:subTotal forKey:@"IM_SubTotal"];
    [data setObject:total forKey:@"IM_Total"];
    
    //------------------------------------------------------------------------------------------
    [data setObject:[NSString stringWithFormat:@"%0.2f", [totalItemSellingAmt doubleValue]] forKey:@"IM_totalItemSellingAmt"];  // subtotal not include tax n will replace this
    [data setObject:[NSString stringWithFormat:@"%@", totalItemSellingAmt] forKey:@"IM_totalItemSellingAmtLong"];  // subtotal not include tax
    [data setObject:[NSString stringWithFormat:@"%@", totalItemTaxAmt] forKey:@"IM_totalItemTaxAmtLong"];  // total tax amt
    
    //-------------tax code------------------
    [data setObject:[rs stringForColumn:@"T_Name"] forKey:@"IM_GSTCode"];
    
    //-------------service tax-------------
    [data setObject:[rs stringForColumn:@"Svc_Name"] forKey:@"IM_ServiceTaxCode"];  //svc tax code
    [data setObject:textServiceTax forKey:@"IM_ServiceTaxAmt"]; // service tax amount
    [data setObject:[NSString stringWithFormat:@"%ld",(long)serviceTaxRate] forKey:@"IM_ServiceTaxRate"];
    [data setObject:itemServiceTaxGst forKey:@"IM_ServiceTaxGstAmt"];
    [data setObject:itemServiceTaxGstLong forKey:@"IM_ServiceTaxGstAmtLong"];
    
    //-------------for take away-----------------
    [data setObject:[NSString stringWithFormat:@"%@",takeAwayYN] forKey:@"IM_TakeAwayYN"];
    [data setObject:@"split" forKey:@"IM_Remark"];
    
    [data setObject:@"ItemOrder" forKey:@"OrderType"];
    [data setObject:[NSString stringWithFormat:@"%0.2f",charge] forKey:@"IM_TotalCondimentSurCharge"];
    [data setObject:@"0.00" forKey:@"IM_NewTotalCondimentSurCharge"];
    [data setObject:sodManualID forKey:@"SOD_ManualID"];
    
    [data setObject:sodModifierHdrCode forKey:@"SOD_ModifierHdrCode"];
    
    // for transfer use
    [data setObject:@"SplitSaleOrder" forKey:@"IM_Flag"];
    [data setObject:_splitTableName forKey:@"SOH_TableName"];
    [data setObject:@"1" forKey:@"IM_InsertSplitFlag"];
    
    [data setObject:@"0.00" forKey:@"SOH_DocSubTotal"];
    [data setObject:@"0.00" forKey:@"SOH_DiscAmt"];
    [data setObject:@"0.00" forKey:@"SOH_DocTaxAmt"];
    [data setObject:@"0.00" forKey:@"SOH_DocAmt"];
    [data setObject:@"0.00" forKey:@"SOH_Rounding"];
    [data setObject:@"0.00" forKey:@"SOH_DocServiceTaxAmt"];
    [data setObject:@"0.00" forKey:@"SOH_DocServiceTaxGstAmt"];
    [data setObject:@"OrgSplitSO" forKey:@"PayForWhich"];
    [data setObject:[rs stringForColumn:@"IM_ServiceType"] forKey:@"IM_ServiceType"];
    
    // after key split number
    if ([flag isEqualToString:@"recalcSplitSO"] ) {
        // calc org when split amount
        [data setObject:[NSString stringWithFormat:@"%ld",finalSplitBillArray.count + 1] forKey:@"Index"];
        [finalSplitBillArray addObject:data];
        
        // deduct org so qty when move to new so
        NSMutableDictionary *dataUpdateTable = [NSMutableDictionary dictionary];
        dataUpdateTable = [splitBillArray objectAtIndex:position];
        [dataUpdateTable setValue:[NSString stringWithFormat:@"%0.2f", [orgIMQty doubleValue] - qty] forKey:@"IM_Qty"];
        [dataUpdateTable setValue:[NSString stringWithFormat:@"%0.2f", [subTotal doubleValue] - ([rs doubleForColumn:@"IM_SalesPrice"] * qty)] forKey:@"IM_SubTotal"];
        [dataUpdateTable setValue:[NSString stringWithFormat:@"%0.2f", [orgDiscAmt doubleValue] - [discountAmt doubleValue]] forKey:@"IM_DiscountAmt"] ;
        
        [splitBillArray replaceObjectAtIndex:position withObject:dataUpdateTable];
        dataUpdateTable = nil;
        
        if ([terminalType isEqualToString:@"Main"]) {
            
            if([[[splitBillArray objectAtIndex:position] objectForKey:@"IM_ServiceType"] isEqualToString:@"1"])
            {
                [self splitPackageItemFromLeftToRight];
                
            }
            else
            {
                [finalSplitBillArray addObjectsFromArray:[PublicSqliteMethod getSalesOrderCondimentWithDBPath:dbPath SalesOrderNo:self.soO.text ItemCode:[data objectForKey:@"IM_ItemCode"] ManualID:sodManualID ParentIndex:finalSplitBillArray.count]];
            }
            
        }
        else
        {
    
            if([[[splitBillArray objectAtIndex:position] objectForKey:@"IM_ServiceType"] isEqualToString:@"1"])
            {
                [self splitPackageItemFromLeftToRight];
                
            }
            else
            {
                for (int i = 0; i < splitBillArray.count; i++) {
                    if ([[[splitBillArray objectAtIndex:i] objectForKey:@"ParentIndex"] isEqualToString:[NSString stringWithFormat:@"%d",position + 1]])
                    {
                        //[condimentItems addObject:[splitBillArray objectAtIndex:i]];
                        NSMutableDictionary *data = [NSMutableDictionary dictionary];
                        [data setObject:[[splitBillArray objectAtIndex:i] objectForKey:@"ItemCode"] forKey:@"ItemCode"];
                        [data setObject:[[splitBillArray objectAtIndex:i] objectForKey:@"CHCode"] forKey:@"CHCode"];
                        [data setObject:[[splitBillArray objectAtIndex:i] objectForKey:@"CDCode"] forKey:@"CDCode"];
                        [data setObject:[[splitBillArray objectAtIndex:i] objectForKey:@"CDDescription"] forKey:@"CDDescription"];
                        [data setObject:[[splitBillArray objectAtIndex:i] objectForKey:@"UnitQty"] forKey:@"UnitQty"];
                        [data setObject:[[splitBillArray objectAtIndex:i] objectForKey:@"CDPrice"] forKey:@"CDPrice"];
                        [data setObject:@"0.00" forKey:@"IM_DiscountAmt"];
                        [data setObject:@"CondimentOrder" forKey:@"OrderType"];
                        
                        [data setObject:[NSString stringWithFormat:@"%@",[[splitBillArray objectAtIndex:i] objectForKey:@"ParentIndex"]] forKey:@"ParentIndex"];
                        [finalSplitBillArray addObject:data];
                        data = nil;
                    }
                    
                }
            }
            
            //[finalSplitBillArray addObjectsFromArray:condimentItems];
            //condimentItems = nil;
        }
        
        
        [self recalculateTax2:finalSplitBillArray flag:@"recalcSplitSO"];
        [self reIndexFinalSplitBillArray];
    }
    else if ([flag isEqualToString:@"recalcOrgSO"])
    {
        // recalc org so
        if (qty == 0.00) {
            //[splitBillArray removeObjectAtIndex:index];
            NSMutableArray *discardedItems = [NSMutableArray array];
            //SomeObjectClass *item;
            [discardedItems addObject:[splitBillArray objectAtIndex:index]];
            for (int i = 0; i < splitBillArray.count; i++) {
                if([[[splitBillArray objectAtIndex:index] objectForKey:@"IM_ServiceType"] isEqualToString:@"1"])
                {
                    if ([[[splitBillArray objectAtIndex:i] objectForKey:@"PackageItemIndex"] isEqualToString:[NSString stringWithFormat:@"%d",index + 1]])
                        [discardedItems addObject:[splitBillArray objectAtIndex:i]];
                }
                else{
                    if ([[[splitBillArray objectAtIndex:i] objectForKey:@"ParentIndex"] isEqualToString:[NSString stringWithFormat:@"%d",index + 1]])
                        [discardedItems addObject:[splitBillArray objectAtIndex:i]];
                }
                
            }
            [splitBillArray removeObjectsInArray:discardedItems];
            discardedItems = nil;
            
        }
        else
        {
            [splitBillArray replaceObjectAtIndex:index withObject:data];
        }
        
        [self recalculateTax2:splitBillArray flag:@"recalcOrgSO"];
        [self reIndexSplitBillArray];
        
    }
    else
    {
        // when click save button
        [splitBillArray replaceObjectAtIndex:index withObject:data];
    }
    
    [self.splitBillTableView reloadData];
    //NSLog(@"%d",finalSplitBillArray.count);
    [self.subSplitBillTableView reloadData];
    //[rs close];
    [dbTable close];
    //[self recalculateTax];
    
    
}

-(void)splitPackageItemFromLeftToRight
{
    NSMutableArray *movingItems = [NSMutableArray array];
    //originalPackageItemIndex =
    for (int i = 0; i < splitBillArray.count; i++) {
        
        if ([[[splitBillArray objectAtIndex:i] objectForKey:@"PackageItemIndex"] isEqualToString:[NSString stringWithFormat:@"%d",position + 1]])
        {
            [movingItems addObject:[[splitBillArray objectAtIndex:i] mutableCopy]];
        }
        
        
    }
    
    [finalSplitBillArray addObjectsFromArray:movingItems];
    movingItems = nil;
}

-(void)recalculateTax2:(NSMutableArray *)soArray flag:(NSString *)flag
{
    double itemExShort = 0.00;
    double itemExLong = 0.00;
    //double finalTotalSellingFigure = 0.00;
    //double finalTotalTax = 0.00;
    NSString *stringItemExLong;
    NSString *stringItemExShort;
    NSString *temp;
    
    double diffCent = 0.00;
    if ([taxType isEqualToString:@"Inc"]) {
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        for (int i = 0; i < soArray.count; i++) {
            //if ([[[splitBillArray objectAtIndex:i]objectForKey:@"IM_Selected"] isEqualToString:@"Yes"]) {
            data = [soArray objectAtIndex:i];
            [data setValue:[NSString stringWithFormat:@"%0.2f",[[[soArray objectAtIndex:i]objectForKey:@"IM_totalItemSellingAmtLong" ] doubleValue]] forKey:@"IM_totalItemSellingAmt"];
            
            [data setValue:[NSString stringWithFormat:@"%0.2f",[[[soArray objectAtIndex:i]objectForKey:@"IM_totalItemTaxAmtLong" ] doubleValue]] forKey:@"IM_TotalTax"];
            
            [soArray replaceObjectAtIndex:i withObject:data];
            
            itemExShort = itemExShort + [[[soArray objectAtIndex:i] objectForKey:@"IM_totalItemSellingAmt"] doubleValue];
            stringItemExShort = [NSString stringWithFormat:@"%0.2f",itemExShort];
            
            itemExLong = itemExLong + [[[soArray objectAtIndex:i] objectForKey:@"IM_totalItemSellingAmtLong"] doubleValue];
            stringItemExLong = [NSString stringWithFormat:@"%0.2f",itemExLong];
            //}
            
            
        }
        
        if ([stringItemExLong doubleValue] != [stringItemExShort doubleValue]) {
            //itemExLong = [stringItemExLong doubleValue] - [stringItemExShort doubleValue];
            itemExLong = itemExLong - itemExShort;
            temp = [NSString stringWithFormat:@"%0.2f",itemExLong];
            diffCent = [temp doubleValue];
            NSLog(@"checking %f",diffCent);
            
        }
        else
        {
            diffCent = 0.00;
        }

        
        if ([flag isEqualToString:@"recalcSplitSO"]) {
            for (int i = 0; i < soArray.count; i++) {
                [finalSplitBillArray replaceObjectAtIndex:i withObject:[soArray objectAtIndex:i]];
            }
            //[finalSplitBillArray addObjectsFromArray:soArray];
        }
        else if ([flag isEqualToString:@"recalcOrgSO"])
        {
            for (int i = 0; i < soArray.count; i++) {
                [splitBillArray replaceObjectAtIndex:i withObject:[soArray objectAtIndex:i]];
            }
        }
    }
    
    
    //[self calcSale//sTotal];
    
}

#pragma mark - data reindex
-(void)reIndexSplitBillArray
{
    NSString *parentIndex;
    NSString *packageItemIndex;
    
    for (int i = 0; i < splitBillArray.count; i++) {
        NSDictionary *data2 = [NSDictionary dictionary];
        data2 = [splitBillArray objectAtIndex:i];
        if ([[[splitBillArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"] || [[[splitBillArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"PackageItemOrder"]) {
            [data2 setValue:[NSString stringWithFormat:@"%d",i + 1] forKey:@"Index"];
            parentIndex = [NSString stringWithFormat:@"%d",i + 1];
            
            if ([[[splitBillArray objectAtIndex:i] objectForKey:@"IM_ServiceType"]length] > 0)
            {
                packageItemIndex = [NSString stringWithFormat:@"%d",i + 1];
            }
            
            if ([[[splitBillArray objectAtIndex:i] objectForKey:@"PackageItemIndex"] length] > 0) {
                [data2 setValue:packageItemIndex forKey:@"PackageItemIndex"];
            }
            
        }
        else
        {
            [data2 setValue:parentIndex forKey:@"ParentIndex"];
            
            if ([[[splitBillArray objectAtIndex:i] objectForKey:@"UnderPackageItemYN"] isEqualToString:@"Yes"]){
                [data2 setValue:packageItemIndex forKey:@"PackageItemIndex"];
            }
            
            //[data2 setValue:packageItemIndex forKey:@"PackageItemIndex"];
        }
        
        [splitBillArray replaceObjectAtIndex:i withObject:data2];
        data2 = nil;
    }
}

-(void)reIndexFinalSplitBillArray
{
    NSString *parentIndex;
    NSString *packageItemIndex;
    
    for (int i = 0; i < finalSplitBillArray.count; i++) {
        NSDictionary *data2 = [NSDictionary dictionary];
        data2 = [finalSplitBillArray objectAtIndex:i];
        if ([[[finalSplitBillArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"] || [[[finalSplitBillArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"PackageItemOrder"])
        {
            [data2 setValue:[NSString stringWithFormat:@"%d",i + 1] forKey:@"Index"];
            parentIndex = [NSString stringWithFormat:@"%d",i + 1];
            
            if ([[[finalSplitBillArray objectAtIndex:i] objectForKey:@"IM_ServiceType"] isEqualToString:@"1"]) {
                packageItemIndex = [NSString stringWithFormat:@"%d",i + 1];
            }
            
            if ([[[finalSplitBillArray objectAtIndex:i] objectForKey:@"PackageItemIndex"] length] > 0) {
                [data2 setValue:packageItemIndex forKey:@"PackageItemIndex"];
            }
            
        }
        else
        {
            [data2 setValue:parentIndex forKey:@"ParentIndex"];
            
            if ([[[finalSplitBillArray objectAtIndex:i] objectForKey:@"UnderPackageItemYN"] isEqualToString:@"Yes"]){
                [data2 setValue:packageItemIndex forKey:@"PackageItemIndex"];
            }
            
        }
        
        [finalSplitBillArray replaceObjectAtIndex:i withObject:data2];
        data2 = nil;
    }
}

#pragma mark - multipeer transfer

-(void)requestSOWantToSplitFromServer
{

    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [requestServerData removeAllObjects];
    [data setObject:@"Request" forKey:@"Result"];
    [data setObject:@"-" forKey:@"Message"];
    [data setObject:@"RequestSODtlWantSplit" forKey:@"IM_Flag"];
    [data setObject:self.soO.text forKey:@"SO_DocNo"];
    [data setObject:_splitTableName forKey:@"TP_Name"];
    [data setObject:[NSString stringWithFormat:@"%f",[[LibraryAPI sharedInstance] getServiceTaxGstPercent]] forKey:@"ServiceTaxGstPercent"];
    //[data setObject:[NSString stringWithFormat:@"%d",compEnableGst] forKey:@"CompEnableGst"];
    
    [requestServerData addObject:data];
    NSData *dataToBeSend = [NSKeyedArchiver archivedDataWithRootObject:requestServerData];
    NSArray *allPeers = [[appDelegate.mcManager session] connectedPeers];
    NSError *error;
    
    for (int i = 0; i < allPeers.count; i++) {
        specificPeer = [allPeers objectAtIndex:i];
        
        if ([specificPeer.displayName isEqualToString:@"Server"]) {
            NSArray *oneArray = @[[appDelegate.mcManager.session.connectedPeers objectAtIndex:i]];
            [appDelegate.mcManager.session sendData:dataToBeSend
                                             toPeers:oneArray
                                            withMode:MCSessionSendDataReliable
                                               error:&error];
        }
        
    }
    
    if (error) {
        NSLog(@"Erro : %@", [error localizedDescription]);
    }
    
}

-(void)getSplitBillSalesOrderNoWithNotification:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray *soDTL;
        soDTL = [notification object];
        
        if ([[[soDTL objectAtIndex:0] objectForKey:@"Result"] isEqualToString:@"True"]) {
            self.soN.text = [[soDTL objectAtIndex:0] objectForKey:@"NewSODocNo"];
            self.soO.text = [[soDTL objectAtIndex:0] objectForKey:@"OrgSODocNo"];
        }
        else
        {
            [self showAlertView:@"Fail to split bill. Please try again" title:@"Warning"];
            soDTL = nil;
            return;
        }
        
        
        
        PaymentViewController *paymentViewController = [[PaymentViewController alloc]init];
        
        if ([[[soDTL objectAtIndex:0] objectForKey:@"PayForWhichSO"] isEqualToString:@"OldSplitSO"]) {
            [[LibraryAPI sharedInstance]setDocNo:self.soO.text];
            [[LibraryAPI sharedInstance]setDirectOrderDetail:splitBillArray];
        }
        else
        {
            [[LibraryAPI sharedInstance]setDocNo:self.soN.text];
            [[LibraryAPI sharedInstance]setDirectOrderDetail:finalSplitBillArray];
        }
        
        soDTL = nil;
        paymentViewController.delegate = self;
        paymentViewController.splitBill_YN = strDiffSide;
        paymentViewController.splitBillTotalAmt = self.labelTotalAmt.text;
        paymentViewController.splitBillTotalDiscAmt = self.labelTotalDiscount.text;
        paymentViewController.splitBillTotalTaxAmt = self.labelTotalTax.text;
        paymentViewController.splitBillSubTotalAmt = self.labelSubTotal.text;
        paymentViewController.tbName = _splitTableName;
        paymentViewController.payDocType = @"SalesOrder";
        paymentViewController.terminalType = [[LibraryAPI sharedInstance]getWorkMode];
        paymentViewController.dictPayCust = _splitCustomerInfoDict;
        
        UINavigationController *navbar = [[UINavigationController alloc]  initWithRootViewController:paymentViewController];
        navbar.modalPresentationStyle = UIModalPresentationPopover;
        
        _popOverSplitBillPay = [navbar popoverPresentationController];
        _popOverSplitBillPay.delegate = self;
        _popOverSplitBillPay.permittedArrowDirections = 0;
        _popOverSplitBillPay.sourceView = self.view;
        _popOverSplitBillPay.sourceRect = CGRectMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2, 1, 1);
        [self presentViewController:navbar animated:YES completion:nil];
        
        /*
        self.popOverSplitBillPay = [[UIPopoverController alloc]initWithContentViewController:navbar];
        self.popOverSplitBillPay.delegate = self;
        [self.popOverSplitBillPay presentPopoverFromRect:CGRectMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2, 1, 1) inView:self.view permittedArrowDirections:0 animated:YES];
         */
    });
    
}

-(void)getSplitBillSalesOrderDtlWithNotification:(NSNotification *)notification
{
    NSArray *soDTL;
    soDTL = [notification object];
    
    dispatch_async(dispatch_get_main_queue(), ^{
    self.soO.text = oldSONo;
    
    for (int i=0; i < soDTL.count; i++) {
        if ([[[soDTL objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"]) {
            self.labelOrgSubTotal.text = [[soDTL objectAtIndex:i] objectForKey:@"SOH_DocSubTotal"];
            //NSLog(@"Testing 123 %@",[[soDTL objectAtIndex:i] objectForKey:@"SOH_DocSubTotal"]);
            self.labelOrgExSubTotal.text = [NSString stringWithFormat:@"%0.2f",[[[soDTL objectAtIndex:i] objectForKey:@"IM_totalItemSellingAmt"] doubleValue] + [self.labelOrgExSubTotal.text doubleValue]];
            
            self.labelOrgTotalDiscount.text = [NSString stringWithFormat:@"%0.2f",[[[soDTL objectAtIndex:i] objectForKey:@"SOH_DiscAmt"] doubleValue]];
            self.labelOrgTotalTax.text = [NSString stringWithFormat:@"%0.2f",[[[soDTL objectAtIndex:i] objectForKey:@"SOH_DocTaxAmt"]doubleValue]];
            self.labelOrgTotal.text = [NSString stringWithFormat:@"%0.2f",[[[soDTL objectAtIndex:i] objectForKey:@"SOH_DocAmt"]doubleValue]];
            self.labelOrgRounding.text = [NSString stringWithFormat:@"%0.2f",[[[soDTL objectAtIndex:i] objectForKey:@"SOH_Rounding"]doubleValue]];
            self.labelOrgServiceCharge.text = [NSString stringWithFormat:@"%0.2f",[[[soDTL objectAtIndex:i] objectForKey:@"SOH_DocServiceTaxAmt"]doubleValue]];
        }
        //[splitBillArray addObjectsFromArray:soDTL];
        [splitBillArray addObject:[soDTL objectAtIndex:i]];
    }
    [self reIndexSplitBillArray];
    [self.splitBillTableView reloadData];
    });
    soDTL = nil;
    
    
}


-(void)sendSplitSOToServer
{
    
    NSData *dataToBeSent = [NSKeyedArchiver archivedDataWithRootObject:combineOldNewSOArray];
    
    NSArray *allPeers = [appDelegate.mcManager.session connectedPeers];
    
    NSError *error;
    //NSLog(@"Peer count %@",allPeers);
    
    if (allPeers.count <= 0) {
        [self showAlertView:@"Unable to connect." title:@"Warning"];
        return;
    }
    
    for (int i = 0; i < allPeers.count; i++) {
        specificPeer = [allPeers objectAtIndex:i];
        
        if ([specificPeer.displayName isEqualToString:@"Server"]) {
            NSArray *oneArray = @[[appDelegate.mcManager.session.connectedPeers objectAtIndex:i]];
            [appDelegate.mcManager.session sendData:dataToBeSent
                                             toPeers:oneArray
                                            withMode:MCSessionSendDataReliable
                                               error:&error];
        }
        
    }
    
    if (error) {
        NSLog(@"Erro : %@", [error localizedDescription]);
        [self showAlertView:[error localizedDescription] title:@"Warning"];
        return;
    }
    else
    {
        //[self.navigationController popViewControllerAnimated:YES];
    }
    
}

#pragma mark - alertView

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
    
    alert = nil;
}

#pragma mark - reindex salesorder after click pay
-(void)reindexSplitNFinalSplitArray
{
    int parentIndex = 0;
    for (int i = 0; i < splitBillArray.count; i++) {
        NSDictionary *data2 = [NSDictionary dictionary];
        data2 = [splitBillArray objectAtIndex:i];
        if ([[[splitBillArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"]) {
            parentIndex = i + 1;
            [data2 setValue:[NSString stringWithFormat:@"%d",i + 1] forKey:@"Index"];
            [data2 setValue:self.soO.text forKey:@"IM_DocNo"];
            [data2 setValue:[NSString stringWithFormat:@"%@-%@",self.soO.text,[[splitBillArray objectAtIndex:i] objectForKey:@"Index"]] forKey:@"SOD_ManualID"];
        }
        else
        {
            [data2 setValue:[NSString stringWithFormat:@"%d",parentIndex] forKey:@"ParentIndex"];
        }
        
        [splitBillArray replaceObjectAtIndex:i withObject:data2];
        data2 = nil;
    }
    
    for (int i = 0; i < finalSplitBillArray.count; i++) {
        NSDictionary *data2 = [NSDictionary dictionary];
        data2 = [finalSplitBillArray objectAtIndex:i];
        if ([[[finalSplitBillArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"ItemOrder"]) {
            parentIndex = i + 1;
            [data2 setValue:[NSString stringWithFormat:@"%d",i + 1] forKey:@"Index"];
            [data2 setValue:self.soN.text forKey:@"IM_DocNo"];
            [data2 setValue:[NSString stringWithFormat:@"%@-%@",self.soN.text,[[finalSplitBillArray objectAtIndex:i] objectForKey:@"Index"]] forKey:@"SOD_ManualID"];
        }
        else
        {
            [data2 setValue:[NSString stringWithFormat:@"%d",parentIndex] forKey:@"ParentIndex"];
        }
        
        [finalSplitBillArray replaceObjectAtIndex:i withObject:data2];
        data2 = nil;
    }
}

@end



