//
//  XReadingReportViewController.m
//  IpadOrder
//
//  Created by IRS on 9/14/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "XReadingReportViewController.h"
#import "LibraryAPI.h"
#import <FMDB.h>
#import "XReadingReportCell.h"
#import <CoreText/CoreText.h>
#import "ReaderConstants.h"
#define kXReportPadding 20
@interface XReadingReportViewController ()
{
    NSString *dbPath;
    FMDatabase *dbTable;
    NSMutableArray *xReadingArray;
    
    CGSize paperSize;
    int myColumnwidth;
    NSMutableArray *pdfArray;
    int itemCount;
    NSString *pdfPath;
    NSArray* XreadingInfo;
    NSString *reportTitle;
    
    NSString *compName;
    NSString *compAdd1;
    NSString *compAdd2;
    NSString *compAdd34;
}
@end

@implementation XReadingReportViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    xReadingArray = [[NSMutableArray alloc]init];
    dbPath = [[LibraryAPI sharedInstance]getDbPath];
    self.tableViewXReading.delegate = self;
    self.tableViewXReading.dataSource = self;
    pdfArray = [[NSMutableArray alloc]init];
    // Do any additional setup after loading the view from its nib.
    UINib *cellNib = [UINib nibWithNibName:@"XReadingReportCell" bundle:nil];
    [[self tableViewXReading]registerNib:cellNib forCellReuseIdentifier:@"XReadingReportCell"];
    
    UIBarButtonItem *addBtn = [[UIBarButtonItem alloc]initWithTitle:@"PDF" style:UIBarButtonItemStylePlain target:self action:@selector(generatePDF)];
    self.navigationItem.rightBarButtonItem = addBtn;
    
    [self.btnItemSales addTarget:self action:@selector(getItemSalesData) forControlEvents:UIControlEventTouchUpInside];
    [self.btnHourlySales addTarget:self action:@selector(getHourlySalesData) forControlEvents:UIControlEventTouchUpInside];
    [self.btnPaymentType addTarget:self action:@selector(getPaymentType) forControlEvents:UIControlEventTouchUpInside];
    
    self.tableViewXReading.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self getItemSalesData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidLayoutSubviews
{
    if ([self.tableViewXReading respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableViewXReading setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([self.tableViewXReading respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.tableViewXReading setLayoutMargins:UIEdgeInsetsZero];
    }
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
    return xReadingArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    XReadingReportCell *cell = [tableView dequeueReusableCellWithIdentifier:@"XReadingReportCell"];
    
    if ([self.labelReportTitle.text isEqualToString:@"Item Sales"]) {
        cell.labelLabel1.text = [NSString stringWithFormat:@"%0.2f",[[[xReadingArray objectAtIndex:indexPath.row]objectForKey:@"qty"] doubleValue]];;
        cell.labelLabel2.text = [[xReadingArray objectAtIndex:indexPath.row]objectForKey:@"desc"];
        cell.labelLabel3.text = [NSString stringWithFormat:@"%0.2f",[[[xReadingArray objectAtIndex:indexPath.row]objectForKey:@"amt"] doubleValue]];
        //NSLog(@"%d",xReadingArray.count);
        if (indexPath.row == xReadingArray.count - 1) {
            cell.labelLabel1.text = @"";
            cell.labelLabel2.textColor = [UIColor colorWithRed:50/255.0 green:159/255.0 blue:72/255.0 alpha:1.0];
            cell.labelLabel3.textColor = [UIColor colorWithRed:50/255.0 green:159/255.0 blue:72/255.0 alpha:1.0];
            [cell.labelLabel2 setFont:[UIFont fontWithName:@"Semibold" size:17]];
            [cell.labelLabel3 setFont:[UIFont fontWithName:@"Semibold" size:17]];
        }
        else
        {
            cell.labelLabel2.textColor = [UIColor blackColor];
            cell.labelLabel3.textColor = [UIColor blackColor];
            [cell.labelLabel2 setFont:[UIFont fontWithName:@"Regular" size:17]];
            [cell.labelLabel3 setFont:[UIFont fontWithName:@"Regular" size:17]];
        }
        
    }
    else if ([self.labelReportTitle.text isEqualToString:@"Hourly Sales"])
    {
        cell.labelLabel1.text = [NSString stringWithFormat:@"%0.2f",[[[xReadingArray objectAtIndex:indexPath.row]objectForKey:@"qty"] doubleValue]];;
        cell.labelLabel2.text = [NSString stringWithFormat:@"%@ - %@",[[xReadingArray objectAtIndex:indexPath.row]objectForKey:@"HourlyFrom"],[[xReadingArray objectAtIndex:indexPath.row]objectForKey:@"HourlyTo"]];
        cell.labelLabel3.text = [NSString stringWithFormat:@"%0.2f",[[[xReadingArray objectAtIndex:indexPath.row]objectForKey:@"amt"] doubleValue]];
        if (indexPath.row == xReadingArray.count - 1) {
            cell.labelLabel1.text = @"";
            cell.labelLabel2.text = @"Total";
            cell.labelLabel2.textColor = [UIColor colorWithRed:50/255.0 green:159/255.0 blue:72/255.0 alpha:1.0];
            cell.labelLabel3.textColor = [UIColor colorWithRed:50/255.0 green:159/255.0 blue:72/255.0 alpha:1.0];
            [cell.labelLabel2 setFont:[UIFont fontWithName:@"Semibold" size:17]];
            [cell.labelLabel3 setFont:[UIFont fontWithName:@"Semibold" size:17]];
        }
        else
        {
            cell.labelLabel2.textColor = [UIColor blackColor];
            cell.labelLabel3.textColor = [UIColor blackColor];
            [cell.labelLabel2 setFont:[UIFont fontWithName:@"Regular" size:17]];
            [cell.labelLabel3 setFont:[UIFont fontWithName:@"Regular" size:17]];
        }
    }
    else if ([self.labelReportTitle.text isEqualToString:@"Payment Type"])
    {
        cell.labelLabel1.text = [NSString stringWithFormat:@"%0.2f",[[[xReadingArray objectAtIndex:indexPath.row]objectForKey:@"qty"] doubleValue]];;
        cell.labelLabel2.text = [NSString stringWithFormat:@"%@",[[xReadingArray objectAtIndex:indexPath.row]objectForKey:@"Type"]];
        cell.labelLabel3.text = [NSString stringWithFormat:@"%0.2f",[[[xReadingArray objectAtIndex:indexPath.row]objectForKey:@"amt"] doubleValue]];
        
        if (indexPath.row == xReadingArray.count - 1) {
            cell.labelLabel1.text = @"";
            cell.labelLabel2.textColor = [UIColor colorWithRed:50/255.0 green:159/255.0 blue:72/255.0 alpha:1.0];
            cell.labelLabel3.textColor = [UIColor colorWithRed:50/255.0 green:159/255.0 blue:72/255.0 alpha:1.0];
            [cell.labelLabel2 setFont:[UIFont fontWithName:@"Semibold" size:17]];
            [cell.labelLabel3 setFont:[UIFont fontWithName:@"Semibold" size:17]];
        }
        else
        {
            cell.labelLabel2.textColor = [UIColor blackColor];
            cell.labelLabel3.textColor = [UIColor blackColor];
            [cell.labelLabel2 setFont:[UIFont fontWithName:@"Regular" size:17]];
            [cell.labelLabel3 setFont:[UIFont fontWithName:@"Regular" size:17]];
        }
    }
    
    if (indexPath.row == xReadingArray.count - 1) {
        cell.backgroundColor = [UIColor whiteColor];
    }
    else
    {
        if (indexPath.row % 2) {
            cell.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0];
            
        } else {
            cell.backgroundColor = [UIColor whiteColor];
        }
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

#pragma mark - sqlite function

-(void)getItemSalesData
{
    reportTitle = @"SalesItem";
    self.labelReportTitle.text = @"Item Sales";
    self.labelFLabel.text = @"Transaction (Qty)";
    self.labelSLabel.text = @"Description";
    self.labelTLabel.text = @"Actual Sales";
    
    [self selectedButtonColorWithButtonName:@"ItemSales"];
    
    dbTable = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTable open]) {
        NSLog(@"Fail To Open");
        return;
    }
    [xReadingArray removeAllObjects];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        double totalItemSales = 0.00;
        FMResultSet *rsComp = [db executeQuery:@"Select * from Company"];
        
        if ([rsComp next]) {
            compName = [rsComp stringForColumn:@"Comp_Company"];
            compAdd1 = [NSString stringWithFormat:@"%@", [rsComp stringForColumn:@"Comp_Address1"]];
            compAdd2 = [NSString stringWithFormat:@"%@", [rsComp stringForColumn:@"Comp_Address2"]];
            compAdd34 = [NSString stringWithFormat:@"%@", [rsComp stringForColumn:@"Comp_Address3"]];
        }
        else
        {
            compName = @"";
            compAdd1 = @"";
            compAdd1 = @"";
            compAdd34 = @"";
        }
        [rsComp close];
        
        FMResultSet *rs = [db executeQuery:@"Select IvD_ItemDescription as desc,sum(IvD_Price) as amt, "
                           "sum(IvD_Quantity) as qty from InvoiceHdr Ih "
                           "left join InvoiceDtl Iv on Ih.IvH_DocNo = Iv.IvD_DocNo "
                           //"left join ItemMast Im on Iv.IvD_ItemNo = Im.IM_ItemCode "
                           "where date(Ih.IvH_Date) between date(?) and date(?)"
                           "group by Iv.IvD_ItemCode order by qty desc",_xReadingDateFrom,_xReadingDateTo];
        //category = [NSMutableArray array];
        if ([db hadError])
        {
            [self showAlertView:[db lastErrorMessage] title:@"Fail"];
        }
        
        [pdfArray removeAllObjects];
        
        NSArray* headers = [NSArray arrayWithObjects:@"Transaction", @"Description", @"Actual Sales", nil];
        [pdfArray addObject:headers];
        headers = nil;
        while ([rs next]) {
            XreadingInfo = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d",[rs intForColumn:@"qty"]], [rs stringForColumn:@"desc"], [NSString stringWithFormat:@"%0.2f",[rs doubleForColumn:@"amt"]], nil];
            totalItemSales += [rs doubleForColumn:@"amt"];
            [xReadingArray addObject:[rs resultDictionary]];
            [pdfArray addObject:XreadingInfo];
        }
        XreadingInfo = nil;
        //dbHadError = [dbItemCat executeUpdate:@"delete from itemcatg"];
        [rs close];
        
        NSMutableDictionary *footerData = [NSMutableDictionary dictionary];
        
        [footerData setObject:@" " forKey:@"qty"];
        [footerData setObject:@"Total" forKey:@"desc"];
        [footerData setObject:[NSString stringWithFormat:@"%0.2f",totalItemSales] forKey:@"amt"];
        
        [xReadingArray addObject:footerData];
        footerData = nil;
        
        NSArray* footer = [NSArray arrayWithObjects:@" ", @"Total", [NSString stringWithFormat:@"%0.2f",totalItemSales], nil];
        [pdfArray addObject:footer];
        
        footer = nil;
        
    }];
    
    [queue close];
    [dbTable close];
    [self.tableViewXReading reloadData];

}


-(void)getHourlySalesData
{
    reportTitle = @"SalesHourly";
    self.labelReportTitle.text = @"Hourly Sales";
    self.labelFLabel.text = @"Transaction";
    self.labelSLabel.text = @"Time Interval";
    self.labelTLabel.text = @"Amount";
    dbTable = [FMDatabase databaseWithPath:dbPath];
    
    [self selectedButtonColorWithButtonName:@"Hourly"];
    
    if (![dbTable open]) {
        NSLog(@"Fail To Open");
        return;
    }
    [xReadingArray removeAllObjects];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        double totalItemSales = 0.00;
        FMResultSet *rs = [db executeQuery:@"select strftime('%H:%M',datetime((strftime('%s', IvH_Date) / 3600) * 3600, 'unixepoch')) HourlyFrom,"
                           " count(*) qty, sum(IvH_DocAmt) amt"
                           " ,strftime('%H:%M',datetime(datetime((strftime('%s', IvH_Date) / 3600) * 3600, 'unixepoch'),'59.99 minutes')) HourlyTo"
                           ",strftime('%H', datetime((strftime('%s', IvH_Date) / 3600) * 3600, 'unixepoch')) Hour"
                           " from InvoiceHdr"
                           " where date(IvH_Date) between date(?) and date(?) "
                           " group by Hour",_xReadingDateFrom,_xReadingDateTo];
        
        
        if ([db hadError]) {
            [self showAlertView:[db lastErrorMessage] title:@"Fail"];
        }
        //category = [NSMutableArray array];
        [pdfArray removeAllObjects];
        NSArray* headers = [NSArray arrayWithObjects:@"Transaction", @"Time Interval", @"Actual Sales", nil];
        [pdfArray addObject:headers];
        while ([rs next]) {
            
            XreadingInfo = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d",[rs intForColumn:@"qty"]],[NSString stringWithFormat:@"%@ - %@",[rs stringForColumn:@"HourlyFrom"],[rs stringForColumn:@"HourlyTo"]], [NSString stringWithFormat:@"%0.2f",[rs doubleForColumn:@"amt"]], nil];
            totalItemSales += [rs doubleForColumn:@"amt"];
            [xReadingArray addObject:[rs resultDictionary]];
            [pdfArray addObject:XreadingInfo];
            
        }
        XreadingInfo = nil;
        
        NSMutableDictionary *footerData = [NSMutableDictionary dictionary];
        
        [footerData setObject:@" " forKey:@"qty"];
        [footerData setObject:@"" forKey:@"HourlyFrom"];
        [footerData setObject:@"" forKey:@"HourlyTo"];
        [footerData setObject:[NSString stringWithFormat:@"%0.2f",totalItemSales] forKey:@"amt"];
        
        [xReadingArray addObject:footerData];
        footerData = nil;
        
        
        //dbHadError = [dbItemCat executeUpdate:@"delete from itemcatg"];
        [rs close];
        
        NSArray* footer = [NSArray arrayWithObjects:@" ", @"Total", [NSString stringWithFormat:@"%0.2f",totalItemSales], nil];
        [pdfArray addObject:footer];
        
        footer = nil;
        
    }];
    
    
    
    [queue close];
    [dbTable close];
    [self.tableViewXReading reloadData];
}

-(void)getPaymentType
{
    reportTitle = @"Payment Type";
    self.labelReportTitle.text = @"Payment Type";
    self.labelFLabel.text = @"Transaction";
    self.labelSLabel.text = @"Description";
    self.labelTLabel.text = @"Amount";
    [self selectedButtonColorWithButtonName:@"PaymentType"];
    dbTable = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTable open]) {
        NSLog(@"Fail To Open");
        return;
    }
    [xReadingArray removeAllObjects];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        double totalItemSales = 0.00;
        double totalChange = 0.00;
        
        FMResultSet *rsChange = [db executeQuery:@"Select sum(IvH_ChangeAmt) as TotalChange from InvoiceHdr where date(IvH_Date) between date(?) and date(?) ",_xReadingDateFrom,_xReadingDateTo];
        
        if ([rsChange next]) {
            totalChange = [rsChange doubleForColumn:@"TotalChange"];
        }
        else
        {
            totalChange = 0.00;
        }
        [rsChange close];
        
        FMResultSet *rs = [db executeQuery:@"select qty,Type,Amt, ifnull(PT_Description,'') as PT_Description from ( "
                           "select sum(qty) qty, Type, sum(amt) amt from ( "
                           "select count(*) qty, IvH_PaymentType1 as Type, sum(IvH_PaymentAmt1) Amt from InvoiceHdr where date(IvH_Date) between date(?) and date(?) group by Ivh_PaymentType1 "
                           " union "
                           "select count(*) qty, IvH_PaymentType2 as Type, sum(IvH_PaymentAmt2) Amt from InvoiceHdr where date(IvH_Date) between date(?) and date(?) group by Ivh_PaymentType2 "
                           " union "
                           "select count(*) qty, IvH_PaymentType3 as Type, sum(IvH_PaymentAmt3) Amt from InvoiceHdr where date(IvH_Date) between date(?) and date(?) group by Ivh_PaymentType3 "
                           " union "
                           "select count(*) qty, IvH_PaymentType4 as Type, sum(IvH_PaymentAmt4) Amt from InvoiceHdr where date(IvH_Date) between date(?) and date(?) group by Ivh_PaymentType4 "
                           " union "
                           "select count(*) qty, IvH_PaymentType5 as Type, sum(IvH_PaymentAmt5) Amt from InvoiceHdr where date(IvH_Date) between date(?) and date(?) group by Ivh_PaymentType5 "
                           " union "
                           "select count(*) qty, IvH_PaymentType6 as Type, sum(IvH_PaymentAmt6) Amt from InvoiceHdr where date(IvH_Date) between date(?) and date(?) group by Ivh_PaymentType6 "
                           " union "
                           "select count(*) qty, IvH_PaymentType7 as Type, sum(IvH_PaymentAmt7) Amt from InvoiceHdr where date(IvH_Date) between date(?) and date(?) group by Ivh_PaymentType7 "
                           " union "
                           "select count(*) qty, IvH_PaymentType8 as Type, sum(IvH_PaymentAmt8) Amt from InvoiceHdr where date(IvH_Date) between date(?) and date(?) group by Ivh_PaymentType8 "
                           ") where Type != '-' group by Type) as Tb1"
                           " left join PaymentType Pt on Tb1.Type = Pt.PT_Code",_xReadingDateFrom,_xReadingDateTo,_xReadingDateFrom,_xReadingDateTo,_xReadingDateFrom,_xReadingDateTo,_xReadingDateFrom,_xReadingDateTo,_xReadingDateFrom,_xReadingDateTo,_xReadingDateFrom,_xReadingDateTo,_xReadingDateFrom,_xReadingDateTo,_xReadingDateFrom,_xReadingDateTo];
        //category = [NSMutableArray array];
        
        if ([db hadError]) {
            [self showAlertView:[db lastErrorMessage] title:@"Fail"];
            return;
        }
        
        [pdfArray removeAllObjects];
        NSArray* headers = [NSArray arrayWithObjects:@"Transaction", @"Description", @"Amount", nil];
        [pdfArray addObject:headers];
        NSString *actualAmt;
        while ([rs next]) {
            
            if ([[rs stringForColumn:@"Type"] isEqualToString:@"Cash"]) {
                actualAmt = [NSString stringWithFormat:@"%0.2f",[rs doubleForColumn:@"amt"] - totalChange];
            }
            else
            {
                actualAmt = [NSString stringWithFormat:@"%0.2f",[rs doubleForColumn:@"amt"]];
            }
            
            XreadingInfo = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d",[rs intForColumn:@"qty"]],[NSString stringWithFormat:@"%@",[rs stringForColumn:@"Type"]], actualAmt, nil];
            
            NSMutableDictionary *paymentData = [NSMutableDictionary dictionary];
            
            [paymentData setObject:[rs stringForColumn:@"qty"] forKey:@"qty"];
            [paymentData setObject:[rs stringForColumn:@"Type"] forKey:@"Type"];
            [paymentData setObject:actualAmt forKey:@"amt"];
            [paymentData setObject:[rs stringForColumn:@"PT_Description"] forKey:@"PT_Description"];
            
            [xReadingArray addObject:paymentData];
            paymentData = nil;
            
            totalItemSales += [actualAmt doubleValue];
            [pdfArray addObject:XreadingInfo];
            
        }
        
        NSMutableDictionary *footerData = [NSMutableDictionary dictionary];
        
        [footerData setObject:@" " forKey:@"qty"];
        [footerData setObject:@"Total" forKey:@"Type"];
        [footerData setObject:[NSString stringWithFormat:@"%0.2f",totalItemSales] forKey:@"amt"];
        
        [xReadingArray addObject:footerData];
        footerData = nil;
        
        XreadingInfo = nil;
        //dbHadError = [dbItemCat executeUpdate:@"delete from itemcatg"];
        [rs close];
        
        NSArray* footer = [NSArray arrayWithObjects:@" ", @"Total", [NSString stringWithFormat:@"%0.2f",totalItemSales], nil];
        [pdfArray addObject:footer];
        
        footer = nil;
    }];
    
    [queue close];
    [dbTable close];
    [self.tableViewXReading reloadData];
}

#pragma mark - alertView

-(void)showAlertView:(NSString *)msg title:(NSString *)title
{
    UIAlertController * alert = [[LibraryAPI sharedInstance] showAlertViewWithMsg:msg Title:title];
    
    [self presentViewController:alert animated:YES completion:nil];
    
    alert = nil;
    /*
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:msg
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
     */
}

#pragma mark - generate PDF

-(void)generatePDF
{
    [self setupPDFDocumentNamed:@"XReading" Width:900 Height:1100];
    
    [self createPdfPage];
    
    [self finishPDF];
    [self openPDFVfrReader];
}

-(void)setupPDFDocumentNamed:(NSString *)name Width:(float)width Height:(float)height
{
    
    paperSize = CGSizeMake(width, height);
    NSString *newPDFName = [NSString stringWithFormat:@"%@.pdf",name];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [paths objectAtIndex:0];
    NSLog(@"%@",documentDirectory);
    pdfPath = [documentDirectory stringByAppendingPathComponent:newPDFName];
    UIGraphicsBeginPDFContextToFile(pdfPath, CGRectZero, nil);
    
}


-(void)createPdfPage
{
    NSString *pdfTitle;
    int pageCount = 0;
    
    if (pdfArray.count % 29 == 0) {
        pageCount = pdfArray.count / 29;
    }
    else
    {
        pageCount = (pdfArray.count / 29) + 1;
    }
    
    if (pdfArray.count >= 29) {
        itemCount = 29;
        
    }
    else
    {
        itemCount = pdfArray.count;
    }
    
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"dd/MMM/yyyy"];
    NSString *dateString = [dateFormat stringFromDate:today];
    
    for (int i = 0; i < pageCount; i++) {
        
        [self beginPDFPage];
        
        //CGRect textRect;
        //CGRect textHeaderDateFilter;
        
        if ([reportTitle isEqualToString:@"SalesItem"]) {
            pdfTitle = @"XReading Item Sales";
            
        }
        else if ([reportTitle isEqualToString:@"SalesHourly"])
        {
            pdfTitle = @"XReading Hourly Sales";
        }
        else if ([reportTitle isEqualToString:@"Payment Type"])
        {
            
            pdfTitle = @"XReading Payment Type";
        }
        
        
        [self drawTableTitleDataAt:CGPointMake(100, 90) withRowHeight:30 andColumnWidth:700 andTitleRow:1 andTitle:compName andAlignment:@"Center" andFontSize:15];
        
        //textCompAdd12 = [self addText:compAdd12
        //withFrame:CGRectMake(350, kPadding, 900, 1100) fontSize:20.0f];
        [self drawTableTitleDataAt:CGPointMake(100, 60) withRowHeight:30 andColumnWidth:700 andTitleRow:2 andTitle:compAdd1 andAlignment:@"Center" andFontSize:15];
        
        [self drawTableTitleDataAt:CGPointMake(100, 60) withRowHeight:30 andColumnWidth:700 andTitleRow:3 andTitle:compAdd2 andAlignment:@"Center" andFontSize:15];
        
        [self drawTableTitleDataAt:CGPointMake(100, 60) withRowHeight:30 andColumnWidth:700 andTitleRow:4 andTitle:compAdd34 andAlignment:@"Center" andFontSize:15];
        
        [self drawTableTitleDataAt:CGPointMake(100, 60) withRowHeight:30 andColumnWidth:700 andTitleRow:5 andTitle:pdfTitle andAlignment:@"Center" andFontSize:15];
        
        [self drawTableTitleDataAt:CGPointMake(100, 60) withRowHeight:30 andColumnWidth:700 andTitleRow:6 andTitle:[NSString stringWithFormat:@"%@ - %@",_xReadingDateFromDisplay,_xReadingDateToDisplay] andAlignment:@"Center" andFontSize:15];
        
        //textHeaderDateFilter = [self addText:[NSString stringWithFormat:@"%@ - %@",invListingDateFromDisplay,invListingDateToDisplay]
        //             withFrame:CGRectMake(350, 90, 900, 1100) fontSize:18.0f];
        
        [self drawTableTitleDataAt:CGPointMake(100, 60) withRowHeight:30 andColumnWidth:735 andTitleRow:6 andTitle:[NSString stringWithFormat:@"Printed Date : %@",dateString ]andAlignment:@"Right" andFontSize:15];
        
        
        
        int rowHeight = 30;
        int columnWidth = 120;
        
        int numberOfRows = itemCount;
        int numberOfColumns = 3;
        
        //[self drawTableAt:CGPointMake(125, 80) withRowHeight:rowHeight andColumnWidth:columnWidth andRowCount:numberOfRows andColumnCount:numberOfColumns];
        
        [self drawTableDataAt:CGPointMake(200, 240) withRowHeight:rowHeight andColumnWidth:columnWidth andRowCount:numberOfRows andColumnCount:numberOfColumns];
        
        
        if (pdfArray.count >= 29) {
            itemCount = 29;
            NSRange r;
            r.location = 0;
            r.length = 29;
            [pdfArray removeObjectsInRange:r];
            
            if (pdfArray.count <= 29) {
                itemCount = pdfArray.count;
            }
            
        }
        else
        {
            itemCount = pdfArray.count;
        }
        
        
    }
    
    
}

-(void)drawTableTitleDataAt:(CGPoint)origin
              withRowHeight:(int)rowHeight
             andColumnWidth:(int)columnWidth
                andTitleRow:(int)titleRow
                   andTitle:(NSString *)title andAlignment:(NSString *)alignment andFontSize:(int)fontSize
{
    
    //int widthCalc = 0;
    int newOriginY = 0;
    
    //widthCalc = j;
    //columnWidth = 750;
    
    int newOriginX = 100;
    if (titleRow == 1) {
        newOriginY = 60;
    }
    else
    {
        newOriginY = (titleRow * 30) + 30;
    }
    
    
    CGRect frame = CGRectMake(newOriginX, newOriginY, columnWidth, rowHeight);
    //NSLog(@"%@",NSStringFromCGRect(frame));
    [self drawText:title inFrame:frame flag:alignment fontSize:fontSize];
}


-(void)drawTableDataAt:(CGPoint)origin
         withRowHeight:(int)rowHeight
        andColumnWidth:(int)columnWidth
           andRowCount:(int)numberOfRows
        andColumnCount:(int)numberOfColumns
{
    
    int widthCalc = 0;
    NSString *alignment;
    for(int i = 0; i < itemCount; i++)
    {
        NSArray* infoToDraw = [[pdfArray objectAtIndex:i] copy];
        
        for (int j = 0; j < numberOfColumns; j++)
        {
            if (j == 1) {
                widthCalc = j;
                columnWidth = 240;
                alignment = @"Left";
            }
            else if (j > 1)
            {
                widthCalc = j + 1;
                columnWidth = 120;
                alignment = @"Right";
            }
            else
            {
                widthCalc = j;
                alignment = @"Center";
            }
            int newOriginX = origin.x + (widthCalc * 120);
            int newOriginY = origin.y + ((i+1)*rowHeight);
            
            CGRect frame = CGRectMake(newOriginX, newOriginY, columnWidth, rowHeight);
            
            [self drawText:[infoToDraw objectAtIndex:j] inFrame:frame flag:alignment fontSize:16];
        }
    }
}

-(void)drawText:(NSString*)textToDraw inFrame:(CGRect)frameRect flag:(NSString *)alignFlag fontSize:(int)fontSize
{
    
    CFMutableAttributedStringRef attrStr = CFAttributedStringCreateMutable(kCFAllocatorDefault, 0);
    CFAttributedStringReplaceString (attrStr, CFRangeMake(0, 0), (CFStringRef) textToDraw);
    
    //    create font
    CTFontRef font = CTFontCreateWithName(CFSTR("TimesNewRomanPSMT"), fontSize, NULL);
    
    //    create paragraph style and assign text alignment to it
    CTTextAlignment alignment;
    if ([alignFlag isEqualToString:@"Right"]) {
        alignment = kCTTextAlignmentRight;
    }
    else if([alignFlag isEqualToString:@"Left"])
    {
        alignment = kCTTextAlignmentLeft;
    }
    else
    {
        alignment = kCTTextAlignmentCenter;
    }
    
    CTParagraphStyleSetting _settings[] = {    {kCTParagraphStyleSpecifierAlignment, sizeof(alignment), &alignment} };
    CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(_settings, sizeof(_settings) / sizeof(_settings[0]));
    
    //    set paragraph style attribute
    CFAttributedStringSetAttribute(attrStr, CFRangeMake(0, CFAttributedStringGetLength(attrStr)), kCTParagraphStyleAttributeName, paragraphStyle);
    
    CFAttributedStringSetAttribute(attrStr, CFRangeMake(0, CFAttributedStringGetLength(attrStr)), kCTFontAttributeName, font);
    //---------------------------
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(attrStr);
    
    
    CGMutablePathRef framePath = CGPathCreateMutable();
    CGPathAddRect(framePath, NULL, frameRect);
    
    // Get the frame that will do the rendering.
    CFRange currentRange = CFRangeMake(0, 0);
    CTFrameRef frameRef = CTFramesetterCreateFrame(framesetter, currentRange, framePath, NULL);
    CGPathRelease(framePath);
    
    // Get the graphics context.
    CGContextRef    currentContext = UIGraphicsGetCurrentContext();
    
    // Put the text matrix into a known state. This ensures
    // that no old scaling factors are left in place.
    CGContextSetTextMatrix(currentContext, CGAffineTransformIdentity);
    
    
    // Core Text draws from the bottom-left corner up, so flip
    // the current transform prior to drawing.
    CGContextTranslateCTM(currentContext, 0, frameRect.origin.y*2);
    CGContextScaleCTM(currentContext, 1.0, -1.0);
    
    // Draw the frame.
    CTFrameDraw(frameRef, currentContext);
    
    CGContextScaleCTM(currentContext, 1.0, -1.0);
    CGContextTranslateCTM(currentContext, 0, (-1)*frameRect.origin.y*2);
    
    
    CFRelease(frameRef);
    CFRelease(attrStr);
    CFRelease(framesetter);
    //---------------------------
    
    
    //    release paragraph style and font
    CFRelease(paragraphStyle);
    CFRelease(font);
}

- (CGRect)addText:(NSString*)text withFrame:(CGRect)frame fontSize:(float)fontSize {
    UIFont *font = [UIFont systemFontOfSize:fontSize];
    
    //CGSize sSize = [text sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:17.0f]}];
    
    CGSize stringSize = CGSizeMake(paperSize.width - 2*20 - 2*20, paperSize.height - 2*20 - 2*20);
    
    CGRect textRect = [text boundingRectWithSize:stringSize
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:@{NSFontAttributeName:font}
                                         context:nil];
    
    CGSize size = textRect.size;
    
    float textWidth = frame.size.width;
    if (textWidth < size.width) {
        textWidth = size.width;
    }
    if (textWidth > paperSize.width) {
        textWidth = paperSize.width = frame.origin.x;
    }
    
    CGRect renderingRect = CGRectMake(frame.origin.x, frame.origin.y, textWidth, stringSize.height);
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    /// Set line break mode
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    /// Set text alignment
    paragraphStyle.alignment = NSTextAlignmentLeft;
    
    NSDictionary *attributes = @{ NSFontAttributeName: font,
                                  NSParagraphStyleAttributeName: paragraphStyle };
    
    [text drawInRect:renderingRect withAttributes:attributes];
    
    frame = CGRectMake(frame.origin.x, frame.origin.y, textWidth, stringSize.height);
    
    return frame;
    
}

-(void)beginPDFPage
{
    UIGraphicsBeginPDFPageWithInfo(CGRectMake(0, 0, paperSize.width, paperSize.height), nil);
    
}

-(void)finishPDF
{
    UIGraphicsEndPDFContext();
}


#pragma mark - vfr reader
-(void)openPDFVfrReader
{
    ReaderDocument *document = [ReaderDocument withDocumentFilePath:pdfPath password:nil];
    
    if (document != nil) {
        ReaderViewController *readerViewController = [[ReaderViewController alloc]initWithReaderDocument:document];
        readerViewController.delegate = self;
        readerViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        readerViewController.modalPresentationStyle = UIModalPresentationOverFullScreen;
        [self presentViewController:readerViewController animated:YES completion:nil];
    }
    
}

-(void)dismissReaderViewController:(ReaderViewController *)viewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - button color
-(void)selectedButtonColorWithButtonName:(NSString *)name
{
    if ([name isEqualToString:@"ItemSales"]) {
        self.btnItemSales.backgroundColor = [UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0];
        
        self.btnHourlySales.backgroundColor = [UIColor colorWithRed:109/255.0 green:182/255.0 blue:255/255.0 alpha:1.0];
        self.btnPaymentType.backgroundColor = [UIColor colorWithRed:109/255.0 green:182/255.0 blue:255/255.0 alpha:1.0];
        
        [self.btnItemSales setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.btnHourlySales setTitleColor:[UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0] forState:UIControlStateNormal];
        [self.btnPaymentType setTitleColor:[UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0] forState:UIControlStateNormal];
        
    }
    else if ([name isEqualToString:@"Hourly"])
    {
        self.btnItemSales.backgroundColor = [UIColor colorWithRed:109/255.0 green:182/255.0 blue:255/255.0 alpha:1.0];
        self.btnHourlySales.backgroundColor = [UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0];
        self.btnPaymentType.backgroundColor = [UIColor colorWithRed:109/255.0 green:182/255.0 blue:255/255.0 alpha:1.0];
        
        [self.btnItemSales setTitleColor:[UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0] forState:UIControlStateNormal];
        [self.btnHourlySales setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.btnPaymentType setTitleColor:[UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0] forState:UIControlStateNormal];
        
    }
    else if ([name isEqualToString:@"PaymentType"])
    {
        self.btnPaymentType.backgroundColor = [UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0];
        self.btnItemSales.backgroundColor = [UIColor colorWithRed:109/255.0 green:182/255.0 blue:255/255.0 alpha:1.0];
        self.btnHourlySales.backgroundColor = [UIColor colorWithRed:109/255.0 green:182/255.0 blue:255/255.0 alpha:1.0];
        
        [self.btnItemSales setTitleColor:[UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0] forState:UIControlStateNormal];
        [self.btnHourlySales setTitleColor:[UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0] forState:UIControlStateNormal];
        [self.btnPaymentType setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    
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
