//
//  VoidReportListingViewController.m
//  IpadOrder
//
//  Created by IRS on 11/05/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import "VoidReportListingViewController.h"
#import "LibraryAPI.h"
#import <FMDB.h>
#import "VoidReasonTableViewCell.h"
#import <CoreText/CoreText.h>
#import "ReaderConstants.h"
#import "SalesOrderDetailReportViewController.h"
#define kXReportPadding 20

@interface VoidReportListingViewController ()
{
    NSString *dbPath;
    FMDatabase *dbTable;
    NSMutableArray *voidReasonArray;
    NSString *pdfPath;
    CGSize paperSize;
    
    NSArray* voidReportPDFArray;
    NSString *reportTitle;
    
    NSString *compName;
    NSString *compAdd1;
    NSString *compAdd2;
    NSString *compAdd34;
    NSMutableArray *pdfArray;
    int itemCount;
}
@end

@implementation VoidReportListingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.tableVoidReason.delegate = self;
    self.tableVoidReason.dataSource = self;
    voidReasonArray = [[NSMutableArray alloc]init];
    pdfArray = [[NSMutableArray alloc]init];
    dbPath = [[LibraryAPI sharedInstance]getDbPath];
    
    UIBarButtonItem *addBtn = [[UIBarButtonItem alloc]initWithTitle:@"PDF" style:UIBarButtonItemStylePlain target:self action:@selector(generateVoidPDF)];
    self.navigationItem.rightBarButtonItem = addBtn;
    
    UINib *cellNib = [UINib nibWithNibName:@"VoidReasonTableViewCell" bundle:nil];
    [[self tableVoidReason]registerNib:cellNib forCellReuseIdentifier:@"VoidReasonTableViewCell"];
    
    self.tableVoidReason.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self getSalesOrderVoidReason];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - sqlite
-(void)getSalesOrderVoidReason
{
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
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
        
        FMResultSet *rsVReason = [db executeQuery:@"Select SOH_DocNo, SOH_Reason, date(SOH_VoidDate) as SOH_VoidDate from SalesOrderHdr where SOH_Status = ? and date(SOH_VoidDate) between date(?) and date(?) order by SOH_VoidDate",@"Void",_voidReasonDateFrom,_voidReasonDateTo];
        
        [pdfArray removeAllObjects];
        
        NSArray* headers = [NSArray arrayWithObjects:@"Date",@"Sales Order", @"Reason", nil];
        [pdfArray addObject:headers];
        
        while ([rsVReason next]) {
            voidReportPDFArray = [NSArray  arrayWithObjects:[rsVReason stringForColumn:@"SOH_VoidDate"],[rsVReason stringForColumn:@"SOH_DocNo"],[rsVReason stringForColumn:@"SOH_Reason"], nil];
            
            [voidReasonArray addObject:[rsVReason resultDictionary]];
            [pdfArray addObject:voidReportPDFArray];
        }
        voidReportPDFArray = nil;
        [rsVReason close];
        
    }];
    [queue close];
    [self.tableVoidReason reloadData];
}

#pragma mark - table

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    // Return the number of rows in the section.
    return voidReasonArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    VoidReasonTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VoidReasonTableViewCell"];
    
    cell.labelVoidDocNo.text = [[voidReasonArray objectAtIndex:indexPath.row] objectForKey:@"SOH_DocNo"];
    cell.labelVoidReason.text = [NSString stringWithFormat:@"%@",[[voidReasonArray objectAtIndex:indexPath.row]objectForKey:@"SOH_Reason"]];
    cell.labelVoidDate.text = [[voidReasonArray objectAtIndex:indexPath.row] objectForKey:@"SOH_VoidDate"];
    
    if (indexPath.row % 2) {
        cell.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0];
        
    } else {
        cell.backgroundColor = [UIColor whiteColor];
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SalesOrderDetailReportViewController *salesOrderDetailReportViewController = [[SalesOrderDetailReportViewController alloc] init];
    salesOrderDetailReportViewController.docNo = [[voidReasonArray objectAtIndex:indexPath.row] objectForKey:@"SOH_DocNo"];
    [self.navigationController pushViewController:salesOrderDetailReportViewController animated:YES];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
    //return 360;
}

#pragma mark - generate PDF

-(void)generateVoidPDF
{
    [self setupPDFDocumentNamed:@"Void Report" Width:900 Height:1100];
    
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
            
        pdfTitle = @"Void Report";
        
        
        [self drawTableTitleDataAt:CGPointMake(100, 90) withRowHeight:30 andColumnWidth:700 andTitleRow:1 andTitle:compName andAlignment:@"Center" andFontSize:15];
        
        //textCompAdd12 = [self addText:compAdd12
        //withFrame:CGRectMake(350, kPadding, 900, 1100) fontSize:20.0f];
        [self drawTableTitleDataAt:CGPointMake(100, 60) withRowHeight:30 andColumnWidth:700 andTitleRow:2 andTitle:compAdd1 andAlignment:@"Center" andFontSize:15];
        
        [self drawTableTitleDataAt:CGPointMake(100, 60) withRowHeight:30 andColumnWidth:700 andTitleRow:3 andTitle:compAdd2 andAlignment:@"Center" andFontSize:15];
        
        [self drawTableTitleDataAt:CGPointMake(100, 60) withRowHeight:30 andColumnWidth:700 andTitleRow:4 andTitle:compAdd34 andAlignment:@"Center" andFontSize:15];
        
        [self drawTableTitleDataAt:CGPointMake(100, 60) withRowHeight:30 andColumnWidth:700 andTitleRow:5 andTitle:pdfTitle andAlignment:@"Center" andFontSize:15];
        
        [self drawTableTitleDataAt:CGPointMake(100, 60) withRowHeight:30 andColumnWidth:700 andTitleRow:6 andTitle:[NSString stringWithFormat:@"%@ - %@",_voidReasonDateFromDisplay,_voidReasonDateToDisplay] andAlignment:@"Center" andFontSize:15];
        
        //textHeaderDateFilter = [self addText:[NSString stringWithFormat:@"%@ - %@",invListingDateFromDisplay,invListingDateToDisplay]
        //             withFrame:CGRectMake(350, 90, 900, 1100) fontSize:18.0f];
        
        [self drawTableTitleDataAt:CGPointMake(100, 60) withRowHeight:30 andColumnWidth:735 andTitleRow:6 andTitle:[NSString stringWithFormat:@"Printed Date : %@",dateString ]andAlignment:@"Right" andFontSize:15];
        
        
        
        int rowHeight = 30;
        int columnWidth = 120;
        
        int numberOfRows = itemCount;
        int numberOfColumns = 3;
        
        [self drawTableDataAt:CGPointMake(100, 240) withRowHeight:rowHeight andColumnWidth:columnWidth andRowCount:numberOfRows andColumnCount:numberOfColumns];
        
        
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
    int specWidth = 0;
    NSString *alignment;
    for(int i = 0; i < itemCount; i++)
    {
        NSArray* infoToDraw = [[pdfArray objectAtIndex:i] copy];
        
        for (int j = 0; j < numberOfColumns; j++)
        {
            if(j == 0)
            {
                widthCalc = j;
                alignment = @"Left";
            }
            else if (j == 1)
            {
                widthCalc = j;
                alignment = @"Left";
                columnWidth = 200;
                specWidth = 180;
                
            }
            else if (j == 2)
            {
                widthCalc = j;
                alignment = @"Left";
                columnWidth = 400;
                specWidth = 160;
            }
            
            int newOriginX = origin.x + (widthCalc * specWidth);
            int newOriginY = origin.y + ((i+1)*rowHeight);
            NSLog(@"%d",newOriginX);
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
