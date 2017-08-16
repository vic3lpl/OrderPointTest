//
//  PrintOptionViewController.m
//  IpadOrder
//
//  Created by IRS on 07/12/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import "PrintOptionViewController.h"
#import <FMDB.h>
#import "LibraryAPI.h"

@interface PrintOptionViewController ()
{
    NSString *dbPath;
}
@end

@implementation PrintOptionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self setTitle:@"Receipt Design"];
    UIBarButtonItem *addBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(editPrintOption:)];
    self.navigationItem.rightBarButtonItem = addBtn;
    
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.translucent = NO;
    
    self.textViewReceiptFormat.editable = NO;
    dbPath = [[LibraryAPI sharedInstance]getDbPath];
    
    self.textReceiptFooter.delegate = self;
    
    [self getPrintOptionData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - textfield delegate
-(void)textViewDidChange:(UITextView *)textView
{
    NSUInteger maxNumberOfLines = 5;
    NSUInteger numLines = textView.contentSize.height/textView.font.lineHeight;
    if (numLines > maxNumberOfLines)
    {
        textView.text = [textView.text substringToIndex:textView.text.length - 1];
    }
}

#pragma mark - sqlie3

-(void)getPrintOptionData
{
    FMDatabase *db = [FMDatabase databaseWithPath:dbPath];
    
    if (![db open]) {
        NSLog(@"Fail To Open");
        return;
    }
    
    [[LibraryAPI sharedInstance]setDbPath:dbPath];
    
    FMResultSet *rs = [db executeQuery:@"select * from PrintOption"];
    
    if ([rs next]) {
        
        self.textReceiptHeader.text = [rs stringForColumn:@"PO_ReceiptHeader"];
        self.textReceiptFooter.text = [rs stringForColumn:@"PO_ReceiptFooter"];
        self.switchCustInfo.on = [rs boolForColumn:@"PO_ShowCustomerInfo"];
        //self.switchPaymentMode.on = [rs boolForColumn:@"PO_ShowPaymentMode"];
        self.switchGstSummary.on = [rs boolForColumn:@"PO_ShowGstSummary"];
        self.switchCompanyTelNo.on = [rs boolForColumn:@"PO_ShowCompanyTelNo"];
        self.switchDiscount.on = [rs boolForColumn:@"PO_ShowDiscount"];
        self.switchServiceCharge.on = [rs boolForColumn:@"PO_ShowServiceCharge"];
        self.switchSubTotalIncGst.on = [rs boolForColumn:@"PO_ShowSubTotalIncGst"];
        self.segmentReceiptContent.selectedSegmentIndex = [rs intForColumn:@"PO_ReceiptContent"];
        self.switchItemDesc2.on = [rs boolForColumn:@"PO_ShowItemDescription2"];
        self.switchPackageItemDtl.on = [rs boolForColumn:@"PO_ShowPackageItemDetail"];
    }
    
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
    }
    
    [self showReceiptFormat];
    
    [rs close];
    [db close];
}

-(void)editPrintOption:(id)sender
{
    if ([[LibraryAPI sharedInstance]getUserRole] == 0) {
        [self showAlertView:@"You have no permission to edit data" title:@"Warning"];
        return;
    }
    
    if ([[[LibraryAPI sharedInstance] getWorkMode] isEqualToString:@"Terminal"]) {
        [self showAlertView:@"Terminal cannot edit print option" title:@"Warning"];
        return;
    }
    
    
    //FMDatabase *db = [FMDatabase databaseWithPath:dbPath];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"Update PrintOption set PO_ReceiptHeader = ?, PO_ReceiptFooter = ?, PO_ShowCustomerInfo = ?, PO_ShowGstSummary = ?, PO_ShowCompanyTelNo = ?, PO_ShowDiscount = ?, PO_ShowServiceCharge = ?, PO_ShowSubTotalIncGst = ?, PO_ReceiptContent = ?, PO_ShowItemDescription2 = ?, PO_ShowPackageItemDetail = ?",self.textReceiptHeader.text,self.textReceiptFooter.text,[NSNumber numberWithInt:self.switchCustInfo.on],[NSNumber numberWithInt:self.switchGstSummary.on],[NSNumber numberWithInt:self.switchCompanyTelNo.on],[NSNumber numberWithInt:self.switchDiscount.on],[NSNumber numberWithInt:self.switchServiceCharge.on],[NSNumber numberWithInt:self.switchSubTotalIncGst.on], [NSNumber numberWithInteger:self.segmentReceiptContent.selectedSegmentIndex],[NSNumber numberWithInt:self.switchItemDesc2.on],[NSNumber numberWithInt:self.switchPackageItemDtl.on]];
        
        if (![db hadError]) {
            
            [[LibraryAPI sharedInstance] setShowPackageDetail:self.switchPackageItemDtl.on];
            
            [self showAlertView:@"Data update" title:@"Updated"];
        }
        else
        {
            [self showAlertView:[db lastErrorMessage] title:@"Fail"];
        }
        
    }];
    
    [queue close];
    
    
}


#pragma mark - alertView

-(void)showAlertView:(NSString *)msg title:(NSString *)title
{
    UIAlertController * alert = [[LibraryAPI sharedInstance] showAlertViewWithMsg:msg Title:title];
    
    [self presentViewController:alert animated:YES completion:nil];
    
    alert = nil;
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)clickSegmentReceiptContent:(id)sender {
    
    [self showReceiptFormat];
}

-(void)showReceiptFormat
{
    NSMutableString *receiptFormat = [[NSMutableString alloc] init];
    
    switch (self.segmentReceiptContent.selectedSegmentIndex) {
        case 0:
            
            //currencyLine = @"Item                        Qty   Price    Total\r\n";
            
            [receiptFormat appendString:@"Item                         Qty    Price     Total\r\n"];
            //[receiptFormat appendString:currencyLine];
            [receiptFormat appendString:@"                                           (RM)         \r\n"];
            [receiptFormat appendString:@"Item A                     1.00   10.00    10.00\r\nItem A Description 2\r\n"];
            [receiptFormat appendString:@"Item B                     1.00   15.00    15.00\r\nItem B Description 2\r\n"];
            [receiptFormat appendString:@"Item C                     1.00   11.00    11.00\r\nItem C Description 2\r\n"];
            self.textViewReceiptFormat.text = receiptFormat;
            break;
        case 1:
            
            [receiptFormat appendString:@"Item                Qty    Price     Disc    Total\r\n"];
            [receiptFormat appendString:@"                                  (RM)     (RM)        \r\n"];
            //[receiptFormat appendString:currencyLine];
            [receiptFormat appendString:@"Item A            1.00   10.00     1.00     9.00\r\nItem A Description 2\r\n"];
            [receiptFormat appendString:@"Item B            1.00   11.00     0.00    11.00\r\nItem B Description 2\r\n"];
            [receiptFormat appendString:@"Item C            1.00    9.00     0.90     8.10\r\nItem C Description 2\r\n"];
            self.textViewReceiptFormat.text = receiptFormat;
            break;
    }
    
    
    
    receiptFormat = nil;
}
@end
