//
//  InvoiceListingViewController.m
//  IpadOrder
//
//  Created by IRS on 9/10/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "InvoiceListingViewController.h"
#import "InvoiceListingCell.h"
#import "InvoiceListingFooterCell.h"
#import "LibraryAPI.h"
#import <FMDB.h>
#import "InvoiceDetailViewController.h"
#import <CoreText/CoreText.h>
#import "ReaderConstants.h"

#define kPadding 30
@interface InvoiceListingViewController ()
{
    NSString *dbPath;
    FMDatabase *dbTable;
    NSMutableArray *invListingArray;
    NSMutableArray *invListingFooterArray;
    CGSize paperSize;
    int myColumnwidth;
    NSMutableArray *pdfArray;
    int itemCount;
    NSString *pdfPath;
    NSString *compName;
    NSString *compAdd1;
    NSString *compAdd2;
    NSString *compAdd34;
}
@end

@implementation InvoiceListingViewController
@synthesize invListingDateFrom,invListingDateTo,invListingDateFromDisplay,invListingDateToDisplay;
- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableViewInvListing.delegate = self;
    self.tableViewInvListing.dataSource = self;
    
    myColumnwidth = 0;
    itemCount = 30;
    
    invListingArray = [[NSMutableArray alloc]init];
    invListingFooterArray = [[NSMutableArray alloc]init];
    pdfArray = [[NSMutableArray alloc]init];
    dbPath = [[LibraryAPI sharedInstance]getDbPath];
    
    // Do any additional setup after loading the view from its nib.
    UINib *catNib = [UINib nibWithNibName:@"InvoiceListingCell" bundle:nil];
    [[self tableViewInvListing]registerNib:catNib forCellReuseIdentifier:@"InvoiceListingCell"];
    
    UINib *footNib = [UINib nibWithNibName:@"InvoiceListingFooterCell" bundle:nil];
    [[self tableViewInvListing]registerNib:footNib forCellReuseIdentifier:@"InvoiceListingFooterCell"];
    
    UIBarButtonItem *addBtn = [[UIBarButtonItem alloc]initWithTitle:@"PDF" style:UIBarButtonItemStylePlain target:self action:@selector(generatePDF)];
    self.navigationItem.rightBarButtonItem = addBtn;
    
    self.tableViewInvListing.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self getInvoiceListingData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidLayoutSubviews
{
    if ([self.tableViewInvListing respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableViewInvListing setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([self.tableViewInvListing respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.tableViewInvListing setLayoutMargins:UIEdgeInsetsZero];
    }
}

#pragma mark - sqlite

-(void)getInvoiceListingData
{
    dbTable = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTable open]) {
        NSLog(@"Fail To Open");
        return;
    }
    [invListingArray removeAllObjects];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        
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
        
        FMResultSet *rs = [db executeQuery:@"Select IvH_DocNo,IvH_Date,IvH_DocAmt,IvH_DocSubTotal,IvH_DocTaxAmt,IvH_DocServiceTaxAmt,sum(IvD_TotalEx) as SubtotalExclude from InvoiceHdr left join InvoiceDtl on  InvoiceHdr.IvH_DocNo = InvoiceDtl.IvD_DocNo"
                           " where date(IvH_Date) "
                           " between date(?) and date(?) group by IvH_DocNo order by IvH_DocNo desc",invListingDateFrom,invListingDateTo];
        //category = [NSMutableArray array];
        if ([db hadError]) {
            [self showAlertView:[db lastErrorMessage] title:@"Fail"];
        }
        [pdfArray removeAllObjects];
        NSArray* invoiceInfo2;;
        NSArray* headers = [NSArray arrayWithObjects:@"InvNo", @"Date", @"SubTotal", @"Tax",@"Svc",@"Amt", nil];
        [pdfArray addObject:headers];
        while ([rs next]) {
            
            
            invoiceInfo2 = [NSArray arrayWithObjects:[rs stringForColumn:@"IvH_DocNo"], [rs stringForColumn:@"IvH_Date"], [NSString stringWithFormat:@"%0.2f",[rs doubleForColumn:@"SubtotalExclude"]], [NSString stringWithFormat:@"%0.2f",[rs doubleForColumn:@"IvH_DocTaxAmt"]],[NSString stringWithFormat:@"%0.2f",[rs doubleForColumn:@"IvH_DocServiceTaxAmt"]],[NSString stringWithFormat:@"%0.2f",[rs doubleForColumn:@"IvH_DocAmt"]], nil];
            [invListingArray addObject:[rs resultDictionary]];
            //[invArray arrayByAddingObject:invoiceInfo2];
            [pdfArray addObject:invoiceInfo2];
            
        }
        
        //dbHadError = [dbItemCat executeUpdate:@"delete from itemcatg"];
        [rs close];
        
        FMResultSet *rs2 = [db executeQuery:@"Select sum(IvH_DocAmt) as TotalAmt, sum(IvH_DocTaxAmt) as TotalTaxAmt,sum(TotalSubTotal) as TotalSubTotal, sum(IvH_DocServiceTaxAmt) as TotalSvcAmt from InvoiceHdr "
            " left join (select sum(IvD_TotalEx) as TotalSubTotal, IvD_DocNo from  InvoiceDtl group by IvD_DocNo) as t1 on InvoiceHdr.IvH_DocNo = t1.IvD_DocNo"
            " where IvH_Status = ? and date(IvH_Date) between date(?) and date(?) group by IvH_Status order by IvH_Date desc",@"Pay",invListingDateFrom,invListingDateTo];
        
        
        if ([rs2 next]) {
            [invListingFooterArray addObject:[rs2 resultDictionary]];
            NSArray* footers = [NSArray arrayWithObjects:@"", @"Total Sales", [NSString stringWithFormat:@"%0.2f",[rs2 doubleForColumn:@"TotalSubTotal"]], [NSString stringWithFormat:@"%0.2f",[rs2 doubleForColumn:@"TotalTaxAmt"]],[NSString stringWithFormat:@"%0.2f",[rs2 doubleForColumn:@"TotalSvcAmt"]],[NSString stringWithFormat:@"%0.2f",[rs2 doubleForColumn:@"TotalAmt"]], nil];
            [pdfArray addObject:footers];
        }
        [rs2 close];
    
    }];
    
    [queue close];
    [dbTable close];
    
    //[self.itemMastTableView reloadData];
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
    if (invListingArray.count > 0) {
        return invListingArray.count + 2;
    }
    else
    {
        return 0;
    }
    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    id tbCell;
    //NSLog(@"%d",indexPath.row);
    if (indexPath.row == invListingArray.count + 2 - 1) {
        InvoiceListingFooterCell *cellFooter = [tableView dequeueReusableCellWithIdentifier:@"InvoiceListingFooterCell"];
        cellFooter.labelTotal.text = @"Total Sales";
        cellFooter.labelTotalSubTotal.text = [NSString stringWithFormat:@"%0.2f",[[[invListingFooterArray objectAtIndex:0] objectForKey:@"TotalSubTotal"]doubleValue]];
        cellFooter.labelGTotalAmt.text = [NSString stringWithFormat:@"%0.2f",[[[invListingFooterArray objectAtIndex:0] objectForKey:@"TotalAmt"]doubleValue]];
        cellFooter.labelTotalTaxAmt.text = [NSString stringWithFormat:@"%0.2f",[[[invListingFooterArray objectAtIndex:0] objectForKey:@"TotalTaxAmt"]doubleValue]];
        cellFooter.labelTotalSvcAmt.text = [NSString stringWithFormat:@"%0.2f",[[[invListingFooterArray objectAtIndex:0] objectForKey:@"TotalSvcAmt"]doubleValue]];
        tbCell = cellFooter;
    }
    else if (indexPath.row == invListingArray.count + 2 - 2)
    {
        InvoiceListingFooterCell *cellFooter = [tableView dequeueReusableCellWithIdentifier:@"InvoiceListingFooterCell"];
        cellFooter.labelGTotalAmt.text = @"";
        cellFooter.labelTotal.text = @"";
        cellFooter.labelTotalTaxAmt.text = @"";
        cellFooter.labelTotalSvcAmt.text = @"";
        cellFooter.labelTotalSubTotal.text = @"";
        tbCell = cellFooter;
    }
    else
    {
        InvoiceListingCell *cell = [tableView dequeueReusableCellWithIdentifier:@"InvoiceListingCell"];
    
        cell.labelInvNo.text = [[invListingArray objectAtIndex:indexPath.row] objectForKey:@"IvH_DocNo"];
        cell.labelInvDate.text = [[invListingArray objectAtIndex:indexPath.row]objectForKey:@"IvH_Date"];
        cell.labelInvSubtotal.text = [NSString stringWithFormat:@"%0.2f",[[[invListingArray objectAtIndex:indexPath.row]objectForKey:@"SubtotalExclude"] doubleValue]];
        cell.labelInvTax.text = [NSString stringWithFormat:@"%0.2f",[[[invListingArray objectAtIndex:indexPath.row]objectForKey:@"IvH_DocTaxAmt"] doubleValue]];
        cell.labelInvTotal.text = [NSString stringWithFormat:@"%0.2f",[[[invListingArray objectAtIndex:indexPath.row]objectForKey:@"IvH_DocAmt"] doubleValue]];
        cell.labelInvSvc.text = [NSString stringWithFormat:@"%0.2f", [[[invListingArray objectAtIndex:indexPath.row]objectForKey:@"IvH_DocServiceTaxAmt"]doubleValue]];
        
        if (indexPath.row % 2) {
            cell.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0];
            
        } else {
            cell.backgroundColor = [UIColor whiteColor];
        }
        
        tbCell = cell;
    }
    
    return tbCell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == invListingArray.count + 2 - 1 || indexPath.row == invListingArray.count + 2 - 2 ) {
        return;
    }
    InvoiceDetailViewController *invoiceDetailViewController = [[InvoiceDetailViewController alloc]init];
    invoiceDetailViewController.invNo = [[invListingArray objectAtIndex:indexPath.row] objectForKey:@"IvH_DocNo"];
    [self.navigationController pushViewController:invoiceDetailViewController animated:YES];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
    //return 360;
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

// generate pdf

#pragma mark - generate PDF

-(void)generatePDF
{

    [self setupPDFDocumentNamed:@"InvListing" Width:900 Height:1100];
    
    [self createPdfPage];
    
    [self finishPDF];
    [self openPDFVfrReader];
    //[self sendPDFThroughEmail];
}


-(void)showPDFFile
{
    NSString* pdfFileName = [self getPDFFileName];
    
    UIWebView* webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    
    NSURL *url = [NSURL fileURLWithPath:pdfFileName];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [webView setScalesPageToFit:YES];
    [webView loadRequest:request];
    
    [self.view addSubview:webView];
    
}

-(NSString*)getPDFFileName
{
    NSString* fileName = @"InvListing.pdf";
    
    NSArray *arrayPaths =
    NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *path = [arrayPaths objectAtIndex:0];
    NSString* pdfFileName = [path stringByAppendingPathComponent:fileName];
    
    return pdfFileName;
    
}


-(void)createPdfPage
{
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
    
    //pageCount = (pdfArray.count / 30) + 1;
    
    for (int i = 0; i < pageCount; i++) {
        
        [self beginPDFPage];
        
        //textCompName = [[self addText:@"adsfsdfadsf"
                    //   withFrame:CGRectMake(350, 30, 900, 1100) fontSize:20.0f];
        
        [self drawTableTitleDataAt:CGPointMake(100, 90) withRowHeight:30 andColumnWidth:700 andTitleRow:1 andTitle:compName andAlignment:@"Center" andFontSize:15];
        
        //textCompAdd12 = [self addText:compAdd12
                       //withFrame:CGRectMake(350, kPadding, 900, 1100) fontSize:20.0f];
        [self drawTableTitleDataAt:CGPointMake(100, 60) withRowHeight:30 andColumnWidth:700 andTitleRow:2 andTitle:compAdd1 andAlignment:@"Center" andFontSize:15];
        
        [self drawTableTitleDataAt:CGPointMake(100, 60) withRowHeight:30 andColumnWidth:700 andTitleRow:3 andTitle:compAdd2 andAlignment:@"Center" andFontSize:15];
        
        [self drawTableTitleDataAt:CGPointMake(100, 60) withRowHeight:30 andColumnWidth:700 andTitleRow:4 andTitle:compAdd34 andAlignment:@"Center" andFontSize:15];
        
        [self drawTableTitleDataAt:CGPointMake(100, 60) withRowHeight:30 andColumnWidth:700 andTitleRow:5 andTitle:@"Invoice Listing" andAlignment:@"Center" andFontSize:15];
        
        
        [self drawTableTitleDataAt:CGPointMake(100, 60) withRowHeight:30 andColumnWidth:700 andTitleRow:6 andTitle:[NSString stringWithFormat:@"%@ - %@",invListingDateFromDisplay,invListingDateToDisplay] andAlignment:@"Center" andFontSize:15];
        
        //textHeaderDateFilter = [self addText:[NSString stringWithFormat:@"%@ - %@",invListingDateFromDisplay,invListingDateToDisplay]
          //             withFrame:CGRectMake(350, 90, 900, 1100) fontSize:18.0f];
        
        [self drawTableTitleDataAt:CGPointMake(100, 60) withRowHeight:30 andColumnWidth:735 andTitleRow:6 andTitle:[NSString stringWithFormat:@"Printed Date : %@",dateString ]andAlignment:@"Right" andFontSize:15];
        /*
        textHeaderDatePrint = [self addText:[NSString stringWithFormat:@"Printed Date : %@",dateString]
                                   withFrame:CGRectMake(350, 120, 900, 1100) fontSize:18.0f];
         */
        
        int rowHeight = 30;
        int columnWidth = 120;
        
        int numberOfRows = itemCount;
        int numberOfColumns = 6;
        
        [self drawTableAt:CGPointMake(80, 240) withRowHeight:rowHeight andColumnWidth:columnWidth andRowCount:numberOfRows andColumnCount:numberOfColumns];
        
        [self drawTableDataAt:CGPointMake(80, 220) withRowHeight:rowHeight andColumnWidth:columnWidth andRowCount:numberOfRows andColumnCount:numberOfColumns];
        
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



-(void)drawTableAt:(CGPoint)origin
     withRowHeight:(int)rowHeight
    andColumnWidth:(int)columnWidth
       andRowCount:(int)numberOfRows
    andColumnCount:(int)numberOfColumns

{
    // this for loop is drawing line
    for (int i = 0; i <= numberOfRows; i++)
    {
        int newOrigin = origin.y + (rowHeight*i);
        
        CGPoint from = CGPointMake(origin.x, newOrigin);
        //CGPoint to = CGPointMake(origin.x + (numberOfColumns*columnWidth) + columnWidth, newOrigin);
        CGPoint to = CGPointMake((numberOfColumns*columnWidth)+columnWidth, newOrigin);
        
        [self drawLineFromPoint:from toPoint:to withColor:[UIColor redColor]];
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


- (void)drawLineFromPoint:(CGPoint)from toPoint:(CGPoint)to withColor:(UIColor*)color2 {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetLineWidth(context, 2.0);
    
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    
    CGFloat components[] = {0.2, 0.2, 0.2, 0.3};
    
    CGColorRef color = CGColorCreate(colorspace, components);
    
    CGContextSetStrokeColorWithColor(context, color);
    
    
    CGContextMoveToPoint(context, from.x, from.y);
    CGContextAddLineToPoint(context, to.x, to.y);
    
    CGContextStrokePath(context);
    CGColorSpaceRelease(colorspace);
    CGColorRelease(color);
    
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
                alignment = @"Left";
            }
            int newOriginX = origin.x + (widthCalc * 105);
            int newOriginY = origin.y + ((i+1)*rowHeight);
            
            CGRect frame = CGRectMake(newOriginX, newOriginY, columnWidth, rowHeight);
            NSLog(@"%@",NSStringFromCGRect(frame));
            [self drawText:[infoToDraw objectAtIndex:j] inFrame:frame flag:alignment fontSize:16];
        }        
    }    
}

-(void)drawText:(NSString*)textToDraw inFrame:(CGRect)frameRect flag:(NSString *)alignFlag fontSize:(int)fontSize
{
    
    CFMutableAttributedStringRef attrStr = CFAttributedStringCreateMutable(kCFAllocatorDefault, 0);
    CFAttributedStringReplaceString (attrStr, CFRangeMake(0, 0), (CFStringRef) textToDraw);
    
    //    create font
    //UIFont *boldFont = [UIFont boldSystemFontOfSize:fontSize];
    CTFontRef font = CTFontCreateWithName(CFSTR("TimesNewRomanPSMT"), fontSize, NULL);
    //CGFloat fontSize1 = CTFontGetSize(font);
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


-(void)beginPDFPage
{
    UIGraphicsBeginPDFPageWithInfo(CGRectMake(0, 0, paperSize.width, paperSize.height), nil);
    
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



-(void)finishPDF
{
    UIGraphicsEndPDFContext();
}


#pragma mark - send email


-(void)sendPDFThroughEmail
{
    MFMailComposeViewController *compose = [[MFMailComposeViewController alloc]init];
    [compose setMailComposeDelegate:self];
    if ([MFMailComposeViewController canSendMail]) {
        [compose setToRecipients:[NSArray arrayWithObjects:@"", nil]];
        [compose setSubject:@"Invoice Listing"];
        [compose setMessageBody:@"This is a PDF file" isHTML:YES];
        [compose setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
        
        NSData *data = [NSData dataWithContentsOfFile:pdfPath];
        [compose addAttachmentData:data mimeType:@"application/pdf" fileName:@"InvListing.pdf"];
        [self presentViewController:compose animated:YES completion:nil];
    }
}

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result) {
        case MFMailComposeResultCancelled:
            NSLog(@"Cancel");
            break;
        case MFMailComposeResultFailed:
            [self showAlertView:@"Please check email setting" title:@"Warning"];
            NSLog(@"Fail");
        case MFMailComposeResultSent:
            NSLog(@"Send");
            
        default:
            break;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - vfr reader
-(void)openPDFVfrReader
{
    ReaderDocument *document = [ReaderDocument withDocumentFilePath:pdfPath password:nil];
    //document.canEmail = YES;
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
    [self getInvoiceListingData];
    [self dismissViewControllerAnimated:YES completion:nil];
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
