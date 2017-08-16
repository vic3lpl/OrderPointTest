//
//  LinkToAccountViewController.m
//  IpadOrder
//
//  Created by IRS on 11/10/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import "LinkToAccountViewController.h"
#import "LibraryAPI.h"
#import <FMDB.h>
#import <AFNetworking/AFNetworking.h>
#import "PublicMethod.h"
#import <KVNProgress.h>

@interface LinkToAccountViewController ()
{
    NSString *dbPath;
    NSMutableArray *dateArray;
    //NSMutableArray *structurePaymentMode;
    NSMutableArray *paymentTotalAmtArray;
    NSMutableArray *structureAccCode;
    NSString *errorMsg;
    
}
//@property (nonatomic, strong)UIPopoverController *popOverLADate;
@end

@implementation LinkToAccountViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.preferredContentSize = CGSizeMake(240, 343);
    
    structureAccCode = [[NSMutableArray alloc]init];
    
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"dd/MMM/yyyy"];
    NSString *dateString = [dateFormat stringFromDate:today];
    
    self.textLinkAccDateFrom.text = dateString;
    [dateFormat setDateFormat:@"dd/MMM/yyyy"];
    NSString *dateString2 = [dateFormat stringFromDate:today];
    self.textLinkAccDateTo.text = dateString2;
    
    self.textLinkAccDateFrom.delegate = self;
    self.textLinkAccDateTo.delegate = self;
    
    dbPath = [[LibraryAPI sharedInstance] getDbPath];
    dateArray = [[NSMutableArray alloc] init];
    //structurePaymentMode = [[NSMutableArray alloc] init];
    paymentTotalAmtArray = [[NSMutableArray alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - text editing
-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    DatePickerViewController *datePickerViewController = [[DatePickerViewController alloc]init];
    datePickerViewController.delegate = self;
    //self.popOverLADate = [[UIPopoverController alloc]initWithContentViewController:datePickerViewController];
    
    if (textField.tag == 0) {
        [self.view endEditing:YES];
        datePickerViewController.textType = @"LADate1";
        
        datePickerViewController.modalPresentationStyle = UIModalPresentationPopover;
        datePickerViewController.popoverPresentationController.sourceRect = CGRectMake(self.textLinkAccDateFrom.frame.size.width /
                                                                                       2, self.textLinkAccDateFrom.frame.size.height / 2, 1, 1);
        datePickerViewController.popoverPresentationController.sourceView = self.textLinkAccDateFrom;
        datePickerViewController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionLeft;
        
        [self presentViewController:datePickerViewController animated:YES completion:nil];
        /*
        [self.popOverLADate presentPopoverFromRect:CGRectMake(self.textLinkAccDateFrom.frame.size.width /
                                                            2, self.textLinkAccDateFrom.frame.size.height / 2, 1, 1) inView:self.textLinkAccDateFrom permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
         */
    }
    else if (textField.tag == 1)
    {
        [self.view endEditing:YES];
        datePickerViewController.textType = @"LADate2";
        
        datePickerViewController.modalPresentationStyle = UIModalPresentationPopover;
        datePickerViewController.popoverPresentationController.sourceRect = CGRectMake(self.textLinkAccDateTo.frame.size.width /
                                                                                       2, self.textLinkAccDateTo.frame.size.height / 2, 1, 1);
        datePickerViewController.popoverPresentationController.sourceView = self.textLinkAccDateTo;
        datePickerViewController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionLeft;
        
        [self presentViewController:datePickerViewController animated:YES completion:nil];
        
        /*
        [self.popOverLADate presentPopoverFromRect:CGRectMake(self.textLinkAccDateTo.frame.size.width /
                                                            2, self.textLinkAccDateTo.frame.size.height / 2, 1, 1) inView:self.textLinkAccDateTo permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
         */
    }
    else
    {
        [self.view endEditing:NO];
    }
    
    return NO;
    
}

#pragma mark - delegate
-(void)getDatePickerDateValue:(NSString *)dateValue returnTextName:(NSString *)textName
{
    if ([textName isEqualToString:@"LADate1"]) {
        self.textLinkAccDateFrom.text = dateValue;
    }
    else if ([textName isEqualToString:@"LADate2"])
    {
        self.textLinkAccDateTo.text = dateValue;
    }
    
    //[self.popOverLADate dismissPopoverAnimated:YES];
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

#pragma mark - link to acc

- (IBAction)btnCancelLinkAccount:(id)sender {
    dateArray = nil;
    paymentTotalAmtArray = nil;
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)btnLinkToAcct:(id)sender
{
    
    [KVNProgress showWithStatus:@"Start uploading..."];
    
    [dateArray removeAllObjects];
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"dd/MMM/yyyy"];
    NSDate *dateFrom = [dateFormat dateFromString:self.textLinkAccDateFrom.text];
    NSDate *dateTo = [dateFormat dateFromString:self.textLinkAccDateTo.text];
    
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    NSString *dateString1 = [dateFormat stringFromDate:dateFrom];
    NSString *dateString2 = [dateFormat stringFromDate:dateTo];
    
    [self makeDateArrayWithDateFrom:dateString1 DateTo:dateString2];
    __block NSMutableArray *structureInvoiceHdr = [[NSMutableArray alloc] init];
    __block NSMutableArray *structurePaymentMode = [[NSMutableArray alloc]init];
    __block BOOL arJournalResult;
    __block NSString *failDocNo;
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        NSString *docNo;
        NSString *dateLong;
        NSString *dateShort;
        NSDate *dateData;
        NSString *year;
        NSString *month;
        NSString *day;
        NSUInteger dataHeaderCount = 0;
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        //NSUInteger invHdrCount;
        //[dateFormatter setDateFormat:@"dd/MMM/yyyy"];
        //[dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
        
        
        FMResultSet *rsLASetting = [db executeQuery:@"Select LA_ClientID, LA_AccUSerID, LA_Company ,LA_CashSalesAC, LA_CashSalesRoundingAC, LA_ServiceChargeAC, LA_CashSalesDesc, LA_AccUrl, LA_CustomerAC, LA_AccUrl from LinkAccount"];
        
        if ([rsLASetting next])
        {
            [structureAccCode addObject:[rsLASetting resultDictionary]];
        }
        [rsLASetting close];
        
        for (int i = 0; i < dateArray.count; i++) {
            //NSLog(@"%@",[dates objectAtIndex:i]);
            
            
            dateData = [dateArray objectAtIndex:i];
            //NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:dateData];
            
            [formatter setDateFormat:@"yyyy"];
            year = [formatter stringFromDate:dateData];
            [formatter setDateFormat:@"MM"];
            month = [formatter stringFromDate:dateData];
            [formatter setDateFormat:@"dd"];
            day = [formatter stringFromDate:dateData];
            //day = @"2";
            
            //error
            
            dateShort = [NSString stringWithFormat:@"%@%@%@",year,month,day];
            dateLong = [NSString stringWithFormat:@"%@-%@-%@",year,month,day];
            
            FMResultSet *rsCheckDate = [db executeQuery:@"Select IvH_DocAmt from InvoiceHdr where date(IvH_Date) = date(?)", dateLong];
            
            if ([rsCheckDate next]) {
                dataHeaderCount = 1;
            }
            else
            {
                dataHeaderCount = 0;
            }
            [rsCheckDate close];
            
            FMResultSet *rsSumIvH;
            NSString *IH_TaxIncluded_YN;
            if (dataHeaderCount == 1) {
                rsSumIvH = [db executeQuery:@"select sum(IvH_DocAmt) as IH_DocAmt, sum(IvH_DocTaxAmt) as IH_SalesTax, sum(IvH_DocServiceTaxAmt) as IH_ServiceTax , sum(IvH_DocServiceTaxGstAmt) as IH_ServiceTaxAmt, sum(IvH_DiscAmt) as IH_Discount, sum(IvH_Rounding) as IH_Rounding , ifnull(IvH_TaxIncluded_YN,0) as IH_TaxIncluded_YN, 'NotEmpty' as IH_Flag  from InvoiceHdr where date(IvH_Date) = date(?) group by ifnull(IvH_TaxIncluded_YN,0)",dateLong];
            }
            else
            {
                if ([[[LibraryAPI sharedInstance] getTaxType] isEqualToString:@"IEx"]){
                    docNo = [NSString stringWithFormat:@"CS%@%@",dateShort,@"EP"];
                    IH_TaxIncluded_YN = @"0";
                }
                else
                {
                    docNo = [NSString stringWithFormat:@"CS%@%@",dateShort,@"IP"];
                    IH_TaxIncluded_YN = @"1";
                }
                
                rsSumIvH = [db executeQuery:@"select 0.00 as IH_DocAmt, 0.00 as IH_SalesTax, 0.00 as IH_ServiceTax , 0.00 as IH_ServiceTaxAmt, 0.00 as IH_Discount, 0.00 as IH_Rounding , ? as IH_TaxIncluded_YN, 'Empty' as IH_Flag",IH_TaxIncluded_YN];
            }
            
            while ([rsSumIvH next]) {
                NSMutableDictionary *data = [NSMutableDictionary dictionary];
                
                if ([rsSumIvH intForColumn:@"IH_TaxIncluded_YN"] == 0) {
                    docNo = [NSString stringWithFormat:@"CS%@%@",dateShort,@"EP"];
                }
                else
                {
                    docNo = [NSString stringWithFormat:@"CS%@%@",dateShort,@"IP"];
                }
                
                [data setObject:docNo forKey:@"IH_DocNo_Default"];
                [data setObject:docNo forKey:@"IH_DocNo"];
                [data setObject:[rsSumIvH stringForColumn:@"IH_DocAmt"] forKey:@"IH_DocAmt"];
                [data setObject:dateLong forKey:@"IH_UpdDate"];
                [data setObject:[[structureAccCode objectAtIndex:0] objectForKey:@"LA_CustomerAC"] forKey:@"IH_AcctCode"];
                [data setObject:[rsSumIvH stringForColumn:@"IH_SalesTax"] forKey:@"IH_SalesTax"];
                [data setObject:[rsSumIvH stringForColumn:@"IH_ServiceTax"] forKey:@"IH_ServiceTax"];
                [data setObject:[rsSumIvH stringForColumn:@"IH_ServiceTaxAmt"] forKey:@"IH_ServiceTaxAmt"];
                [data setObject:[rsSumIvH stringForColumn:@"IH_Discount"] forKey:@"IH_Discount"];
                [data setObject:[rsSumIvH stringForColumn:@"IH_TaxIncluded_YN"] forKey:@"IH_TaxIncluded_YN"];
                [data setObject:[rsSumIvH stringForColumn:@"IH_Flag"] forKey:@"IH_Flag"];
                //NSLog(@"%0.2f",[rsSumIvH doubleForColumn:@"IH_Rounding"]);
                if ([[NSString stringWithFormat:@"%0.2f",[rsSumIvH doubleForColumn:@"IH_Rounding"]] isEqualToString:@"-0.00"]) {
                    [data setObject:@"0.00" forKey:@"IH_Rounding"];
                }
                else
                {
                    [data setObject:[NSString stringWithFormat:@"%0.2f",[rsSumIvH doubleForColumn:@"IH_Rounding"]] forKey:@"IH_Rounding"];
                }
                
                [structureInvoiceHdr addObject:data];
                
                data = nil;
            }
            [rsSumIvH close];
        }
        
        NSDateFormatter *dateF = [[NSDateFormatter alloc] init];
        NSDate *startDate;
        BOOL taxIncludeYN = false;
        
        for (int i = 0; i < structureInvoiceHdr.count; i++) {
            
            [KVNProgress updateStatus:[[structureInvoiceHdr objectAtIndex:i] objectForKey:@"IH_DocNo"]];
            
            failDocNo = [[structureInvoiceHdr objectAtIndex:i] objectForKey:@"IH_DocNo"];
            NSString *jsonStart = @"[";
            NSString *jsonCL = [NSString stringWithFormat:@"[{\"CL_Code\":\"%@\"}]",[[structureAccCode objectAtIndex:0] objectForKey:@"LA_ClientID"]];
            NSString *jsonCO = [NSString stringWithFormat:@"[{\"CO_Name\":\"%@\"}]",[[structureAccCode objectAtIndex:0] objectForKey:@"LA_Company"]];
            NSString *jsonUser = [NSString stringWithFormat:@"[{\"US_UserID\":\"%@\",\"US_Password\":\"%@\"}]",[[structureAccCode objectAtIndex:0] objectForKey:@"LA_AccUserID"],_accPassword];
            
            NSString *jsonARJEH = @"";
            NSString *jsonARJED1 = @"";
            NSString *jsonARJED2 = @"";
            NSString *jsonARJED3 = @"";
            NSString *jsonARJEDStart = @"[";
            NSString *jsonARJEDEnd = @"]";
            NSString *jsonJournal = @"";
            
            
            //NSMutableDictionary *finalData = [[NSMutableDictionary alloc] init];
            
            if ([[[structureInvoiceHdr objectAtIndex:i] objectForKey:@"IH_TaxIncluded_YN"] isEqualToString:@"0"]){
                taxIncludeYN = false;
            }
            else
            {
                taxIncludeYN = true;
            }
           
            [dateF setDateFormat:@"yyyy-MM-dd"];
            [dateF setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
            startDate = [dateF dateFromString:[[structureInvoiceHdr objectAtIndex:i] objectForKey:@"IH_UpdDate"]];
            
            FMResultSet *rsPayMode = [db executeQuery:@"Select IvH_PaymentType1 as IvH_PaymentMode,IvH_PaymentType2 as IvH_PaymentMode02,IvH_PaymentType3 as IvH_PaymentMode03,IvH_PaymentType4 as IvH_PaymentMode04,IvH_PaymentType5 as IvH_PaymentMode05,IvH_PaymentType6 as IvH_PaymentMode06,IvH_PaymentType7 as IvH_PaymentMode07,IvH_PaymentType8 as IvH_PaymentMode08 from InvoiceHdr where date(IvH_Date) = date(?) group by IvH_PaymentType1,IvH_PaymentType2,IvH_PaymentType3,IvH_PaymentType4,IvH_PaymentType5,IvH_PaymentType6,IvH_PaymentType7,IvH_PaymentType8",[[structureInvoiceHdr objectAtIndex:i] objectForKey:@"IH_UpdDate"]];
            [structurePaymentMode removeAllObjects];
            
            while ([rsPayMode next])
            {
                
                
                if ([self checkPaymentTypeIsNullOrDash:[rsPayMode stringForColumn:@"IvH_PaymentMode"]].length) {
                    NSMutableDictionary *data = [NSMutableDictionary dictionary];
                    [data setObject:[rsPayMode stringForColumn:@"IvH_PaymentMode"] forKey:@"IvH_PaymentMode"];
                    [structurePaymentMode addObject:data];
                    data = nil;
                    //[structurePaymentMode addObject:[rsPayMode stringForColumn:@"IvH_PaymentMode"]];
                }
                if ([self checkPaymentTypeIsNullOrDash:[rsPayMode stringForColumn:@"IvH_PaymentMode02"]].length) {
                    NSMutableDictionary *data = [NSMutableDictionary dictionary];
                    [data setObject:[rsPayMode stringForColumn:@"IvH_PaymentMode"] forKey:@"IvH_PaymentMode"];
                    [structurePaymentMode addObject:data];
                    data = nil;
                }
                if ([self checkPaymentTypeIsNullOrDash:[rsPayMode stringForColumn:@"IvH_PaymentMode03"]].length) {
                    NSMutableDictionary *data = [NSMutableDictionary dictionary];
                    [data setObject:[rsPayMode stringForColumn:@"IvH_PaymentMode"] forKey:@"IvH_PaymentMode"];
                    [structurePaymentMode addObject:data];
                    data = nil;
                }
                
                if ([self checkPaymentTypeIsNullOrDash:[rsPayMode stringForColumn:@"IvH_PaymentMode04"]].length) {
                    NSMutableDictionary *data = [NSMutableDictionary dictionary];
                    [data setObject:[rsPayMode stringForColumn:@"IvH_PaymentMode"] forKey:@"IvH_PaymentMode"];
                    [structurePaymentMode addObject:data];
                    data = nil;
                }
                if ([self checkPaymentTypeIsNullOrDash:[rsPayMode stringForColumn:@"IvH_PaymentMode05"]].length) {
                    NSMutableDictionary *data = [NSMutableDictionary dictionary];
                    [data setObject:[rsPayMode stringForColumn:@"IvH_PaymentMode"] forKey:@"IvH_PaymentMode"];
                    [structurePaymentMode addObject:data];
                    data = nil;
                }
                if ([self checkPaymentTypeIsNullOrDash:[rsPayMode stringForColumn:@"IvH_PaymentMode06"]].length) {
                    NSMutableDictionary *data = [NSMutableDictionary dictionary];
                    [data setObject:[rsPayMode stringForColumn:@"IvH_PaymentMode"] forKey:@"IvH_PaymentMode"];
                    [structurePaymentMode addObject:data];
                    data = nil;
                }
                if ([self checkPaymentTypeIsNullOrDash:[rsPayMode stringForColumn:@"IvH_PaymentMode07"]].length) {
                    NSMutableDictionary *data = [NSMutableDictionary dictionary];
                    [data setObject:[rsPayMode stringForColumn:@"IvH_PaymentMode"] forKey:@"IvH_PaymentMode"];
                    [structurePaymentMode addObject:data];
                    data = nil;
                }
                if ([self checkPaymentTypeIsNullOrDash:[rsPayMode stringForColumn:@"IvH_PaymentMode08"]].length) {
                    NSMutableDictionary *data = [NSMutableDictionary dictionary];
                    [data setObject:[rsPayMode stringForColumn:@"IvH_PaymentMode"] forKey:@"IvH_PaymentMode"];
                    [structurePaymentMode addObject:data];
                    data = nil;
                }
                
            }
            [rsPayMode close];
            
            NSArray *groupPayType;
            
            groupPayType = [structurePaymentMode valueForKeyPath:@"@distinctUnionOfObjects.IvH_PaymentMode"];
            NSUInteger intRow = 0;
            
            NSMutableDictionary *postDate = [NSMutableDictionary dictionary];
            [postDate setObject:[NSString stringWithFormat:@"/Date(%.0f000)/", [startDate timeIntervalSince1970]] forKey:@"PostDate"];
            //NSLog(@"%@",[postDate objectForKey:@"PostDate"]);
            
            jsonARJEH = [NSString stringWithFormat:@"{\"ARJEH_ID\":%d,\"ARJEH_DocNo\":\"%@\",\"ARJEH_Reference\":\"%@\",\"ARJEH_Description\":\"%@\",\"ARJEH_Note\":\"%@\",\"ARJEH_CurrencyRate\":%@,\"ARJEH_PostingDate\":\"%@\",\"ARJEH_DocDate\":\"%@\",\"ARJEH_TransDate\":\"%@\",\"ARJEH_Status\":%@,\"ARJEH_TaxInclusive\":%@,\"ARJEH_TaxItemize\":%@,\"ARJEH_DocTypeID\":%d,\"ARJEH_JournalTypeID\":%d,\"ARJEH_CompanyCurrencyID\":%d,\"ARJEH_PostingPeriod\":%d,\"ARJEH_Attachment\":%@,\"ARJEH_PaymentTermID\":%d,\"ARJEH_DueDate\":\"%@\",\"ARJEH_CustomerID\":%d,\"ARJEH_DocumentAmount\":%d,\"ARJEH_OutstandingAmount\":%d,\"ARJEH_CompanyID\":%d,\"ARJEH_ClientID\":%d,\"ARJEH_ModifiedBy\":%d,\"ARJEH_DateModified\":\"%@\",\"ARJEH_CreatedBy\":%d,\"ARJEH_DateCreated\":\"%@\",\"ARJEH_SourceDocID\":%d,\"ARJEH_GSTDate\":\"%@\",\"ARJEH_SettlementDate\":\"%@\"}",0,[[structureInvoiceHdr objectAtIndex:i] objectForKey:@"IH_DocNo"],@"",[[structureAccCode objectAtIndex:0] objectForKey:@"LA_CashSalesDesc"],@"",@"1",[NSString stringWithFormat:@"\\/Date(%.0f000)\\/", [startDate timeIntervalSince1970]],[NSString stringWithFormat:@"\\/Date(%.0f000)\\/", [startDate timeIntervalSince1970]],[NSString stringWithFormat:@"\\/Date(%.0f000)\\/", [startDate timeIntervalSince1970]],@"null",@"false",@"false",0,0,0,1520,@"null",0,[NSString stringWithFormat:@"\\/Date(%@)\\/", @"-62135596800000"],0,0,0,0,0,0,[NSString stringWithFormat:@"\\/Date(%@)\\/", @"-62135596800000"],0,[NSString stringWithFormat:@"\\/Date(%@)\\/", @"-62135596800000"],0,[NSString stringWithFormat:@"\\/Date(%.0f000)\\/", [startDate timeIntervalSince1970]],[NSString stringWithFormat:@"\\/Date(%@)\\/", @"-62135596800000"]];
            
            FMResultSet *rsIvDtl;
            
            if ([[[structureInvoiceHdr objectAtIndex:i] objectForKey:@"IH_Flag"] isEqualToString: @"NotEmpty"]) {
                if ([[[structureInvoiceHdr objectAtIndex:i] objectForKey:@"IH_TaxIncluded_YN"] integerValue] == 1) {
                    rsIvDtl = [db executeQuery:@"select IvD_ItemTaxCode as ID_T_Code, ifnull(IvH_TaxIncluded_YN, 0) as IvH_TaxIncluded_YN , sum(IvD_TotalEx) as TaxableAmt, sum(IvD_TotalSalesTax) as TotalSalesTax,ifnull(Tax.T_AccTaxCode,'') as T_AccTaxCode from InvoiceDtl"
                               " left join ItemMast on IM_ItemCode = IvD_ItemCode"
                               " left join InvoiceHdr on IvD_DocNo = IvH_DocNo"
                               " left join Tax on IvD_ItemTaxCode = Tax.T_Name"
                               " where date(IvH_Date) = ? and IvH_DocNo like 'CS%' and IvH_TaxIncluded_YN = 1 group by IvD_ItemTaxCode, ifnull(IvH_TaxIncluded_YN,0)",[[structureInvoiceHdr objectAtIndex:i] objectForKey:@"IH_UpdDate"]];
                }
                else
                {
                    rsIvDtl = [db executeQuery:@"select IvD_ItemTaxCode as ID_T_Code, ifnull(IvH_TaxIncluded_YN, 0) as IvH_TaxIncluded_YN , sum(IvD_TotalEx) as TaxableAmt, sum(IvD_TotalSalesTax) as TotalSalesTax, ifnull(Tax.T_AccTaxCode,'') as T_AccTaxCode from InvoiceDtl"
                               " left join ItemMast on IM_ItemCode = IvD_ItemCode"
                               " left join InvoiceHdr on IvD_DocNo = IvH_DocNo"
                               " left join Tax on IvD_ItemTaxCode = Tax.T_Name"
                               " where date(IvH_Date) = ? and IvH_DocNo like 'CS%' and (IvH_TaxIncluded_YN = 0 or IvH_TaxIncluded_YN is null) group by IvD_ItemTaxCode, ifnull(IvH_TaxIncluded_YN,0)",[[structureInvoiceHdr objectAtIndex:i] objectForKey:@"IH_UpdDate"]];
                }

            }
            else
            {
                rsIvDtl = [db executeQuery:@"select '' as ID_T_Code, '2' as IvH_TaxIncluded_YN , '0.00' as TaxableAmt, '0.00' as TotalSalesTax, '' as T_AccTaxCode "];
            }
            double decAmt = 0.00;
            NSString *tAccCode;
            while ([rsIvDtl next]) {
                if ([[[structureInvoiceHdr objectAtIndex:i] objectForKey:@"IH_TaxIncluded_YN"] isEqualToString:@"1"]) {
                    decAmt = [rsIvDtl doubleForColumn:@"TaxableAmt"] + [rsIvDtl doubleForColumn:@"TotalSalesTax"];
                }
                else
                {
                    decAmt = [rsIvDtl doubleForColumn:@"TaxableAmt"];
                }
                
                
                if ([rsIvDtl stringForColumn:@"T_AccTaxCode"].length == 0) {
                    tAccCode = @"";
                }
                else
                {
                    tAccCode = [NSString stringWithFormat:@"-%@",[rsIvDtl stringForColumn:@"T_AccTaxCode"]];
                }
                
                if (dataHeaderCount == 0) {
                    tAccCode = @"";
                }
                
                jsonARJED1 = [NSString stringWithFormat:@"{\"tempID\":%@"
                             @",\"ARJEH_ID\":%d"
                             @",\"ARJED_Seq\":%ld"
                             @",\"ARJEH_CurrencyRate\":%@"
                             @",\"ARJED_Description\":\"%@\""
                             @",\"ARJED_Description2\":\"%@\""
                             @",\"ARJED_SourceDR\":%@"
                             @",\"ARJED_SourceCR\":\"%@\""
                             @",\"ARJED_DR\":%@"
                             @",\"ARJED_CR\":\"%@\""
                             @",\"ARJED_SupplyPurchase\":%@"
                             @",\"ARJED_TaxDR\":%@"
                             @",\"ARJED_TaxCR\":\"%@\""
                             @",\"ARJED_TaxableDR\":%@"
                             @",\"ARJED_TaxableCR\":\"%@\""
                             @",\"ARJED_TotalDR\":%@"
                             @",\"ARJED_TotalCR\":\"%@\""
                             @",\"ARJED_TaxAdjustment\":%@"
                             @",\"ARJED_TaxExportCountry\":%@"
                             @",\"ARJED_RefNo\":\"%@\""
                             @",\"ARJED_Note\":%@"
                             @",\"ARJED_TaxPermitNo\":%@"
                             @",\"ARJED_ARJEHID\":%@"
                             @",\"ARJED_CCOADID\":%@"
                             @",\"ARJED_ProjectID\":%@"
                             @",\"ARJED_CostCentreID\":%@"
                             @",\"ARJED_TaxTypeID\":%@"
                             @",\"ARJED_CompanyCurrencyID\":%@"
                             @",\"ARJED_CurrencyRate\":\"%d\""
                             @",\"ARJED_DocDR\":%@"
                             @",\"ARJED_DocCR\":\"%@\""
                             @",\"ARJED_TaxTypeDesc\":\"%@\""
                             @",\"ARJED_ProjectDesc\":%@"
                             @",\"ARJED_CostCentreDesc\":\"%@\""
                             @"}"
                             ,@"null"
                             ,0
                             ,intRow + 1
                             ,@"null"
                             ,[[structureAccCode objectAtIndex:0] objectForKey:@"LA_CashSalesAC"]
                             ,[NSString stringWithFormat:@"%@%@",[[structureAccCode objectAtIndex:0] objectForKey:@"LA_CashSalesDesc"],tAccCode]
                             ,@"null"
                             ,[NSString stringWithFormat:@"%0.2f",decAmt]
                             ,@"null"
                             ,[NSString stringWithFormat:@"%0.2f",decAmt]
                             ,@"null"
                             ,@"null"
                             ,[NSString stringWithFormat:@"%0.2f",[rsIvDtl doubleForColumn:@"TotalSalesTax"]]
                             ,@"null"
                             ,[NSString stringWithFormat:@"%0.2f",[rsIvDtl doubleForColumn:@"TaxableAmt"]]
                             ,@"null"
                             ,[NSString stringWithFormat:@"%0.2f",[rsIvDtl doubleForColumn:@"TaxableAmt"] + [rsIvDtl doubleForColumn:@"TotalSalesTax"]]
                             ,@"null"
                             ,@"null"
                             ,@""
                             ,@"null"
                             ,@"null"
                             ,@"null"
                             ,@"null"
                             ,@"null"
                             ,@"null"
                             ,@"null"
                             ,@"null"
                             ,1
                             ,@"null"
                             ,[NSString stringWithFormat:@"%0.2f",decAmt]
                             ,[NSString stringWithFormat:@"%@",[rsIvDtl stringForColumn:@"T_AccTaxCode"]]
                             ,@"null"
                             ,@""
                             ];
                                intRow += 1;
            }
            
            [rsIvDtl close];
            
            FMResultSet *rsSvc;
            
            if ([[[structureInvoiceHdr objectAtIndex:i] objectForKey:@"IH_Flag"] isEqualToString: @"NotEmpty"]) {
                rsSvc = [db executeQuery:@"Select sum(IvH_DocServiceTaxAmt) as IH_ServiceTax, ifnull(IvH_ServiceTaxGstCode,'') as IH_ServiceTaxCode , sum(IvH_DocServiceTaxGstAmt) as IH_ServiceTaxAmt, T_AccTaxCode from InvoiceHdr"
                         " left join Tax on IvH_ServiceTaxGstCode = T_Name"
                         " where date(IvH_Date) = ? and IvH_DocNo like 'CS%' and IvH_DocServiceTaxAmt <> 0 and IvH_TaxIncluded_YN = ? group by IvH_ServiceTaxGstCode",[[structureInvoiceHdr objectAtIndex:i] objectForKey:@"IH_UpdDate"],[[structureInvoiceHdr objectAtIndex:i] objectForKey:@"IH_TaxIncluded_YN"]];
            }
            else
            {
                rsSvc = [db executeQuery:@"Select '0.00' as IH_ServiceTax, '' as IH_ServiceTaxCode , '0.00' as IH_ServiceTaxAmt,'' as T_AccTaxCode "];
            }
            
            
            
            while ([rsSvc next]) {
                decAmt = 0.00;
                if ([[[structureInvoiceHdr objectAtIndex:i] objectForKey:@"IH_TaxIncluded_YN"] isEqualToString:@"1"]) {
                    decAmt = [rsSvc doubleForColumn:@"IH_ServiceTax"] + [rsSvc doubleForColumn:@"IH_ServiceTaxAmt"];
                }
                else
                {
                    decAmt = [rsSvc doubleForColumn:@"IH_ServiceTax"];
                }
                
                jsonARJED2 = [NSString stringWithFormat:@",{\"tempID\":%@"
                              @",\"ARJEH_ID\":%d"
                              @",\"ARJED_Seq\":%ld"
                              @",\"ARJEH_CurrencyRate\":%@"
                              @",\"ARJED_Description\":\"%@\""
                              @",\"ARJED_Description2\":\"%@\""
                              @",\"ARJED_SourceDR\":%@"
                              @",\"ARJED_SourceCR\":\"%@\""
                              @",\"ARJED_DR\":%@"
                              @",\"ARJED_CR\":\"%@\""
                              @",\"ARJED_SupplyPurchase\":%@"
                              @",\"ARJED_TaxDR\":%@"
                              @",\"ARJED_TaxCR\":\"%@\""
                              @",\"ARJED_TaxableDR\":%@"
                              @",\"ARJED_TaxableCR\":\"%@\""
                              @",\"ARJED_TotalDR\":%@"
                              @",\"ARJED_TotalCR\":\"%@\""
                              @",\"ARJED_TaxAdjustment\":%@"
                              @",\"ARJED_TaxExportCountry\":%@"
                              @",\"ARJED_RefNo\":\"%@\""
                              @",\"ARJED_Note\":%@"
                              @",\"ARJED_TaxPermitNo\":%@"
                              @",\"ARJED_ARJEHID\":%@"
                              @",\"ARJED_CCOADID\":%@"
                              @",\"ARJED_ProjectID\":%@"
                              @",\"ARJED_CostCentreID\":%@"
                              @",\"ARJED_TaxTypeID\":%@"
                              @",\"ARJED_CompanyCurrencyID\":%@"
                              @",\"ARJED_CurrencyRate\":\"%d\""
                              @",\"ARJED_DocDR\":%@"
                              @",\"ARJED_DocCR\":\"%@\""
                              @",\"ARJED_TaxTypeDesc\":\"%@\""
                              @",\"ARJED_ProjectDesc\":%@"
                              @",\"ARJED_CostCentreDesc\":\"%@\""
                              @"}"
                              ,@"null"
                              ,0
                              ,intRow + 1
                              ,@"null"
                              ,[[structureAccCode objectAtIndex:0] objectForKey:@"LA_ServiceChargeAC"]
                              ,@"SERVICE CHARGES"
                              ,@"null"
                              ,[NSString stringWithFormat:@"%0.2f",decAmt]
                              ,@"null"
                              ,[NSString stringWithFormat:@"%0.2f",decAmt]
                              ,@"null"
                              ,@"null"
                              ,[NSString stringWithFormat:@"%0.2f",[rsSvc doubleForColumn:@"IH_ServiceTaxAmt"]]
                              ,@"null"
                              ,[NSString stringWithFormat:@"%0.2f",[rsSvc doubleForColumn:@"IH_ServiceTax"]]
                              ,@"null"
                              ,[NSString stringWithFormat:@"%0.2f",[rsSvc doubleForColumn:@"IH_ServiceTax"] + [rsSvc doubleForColumn:@"IH_ServiceTaxAmt"]]
                              ,@"null"
                              ,@"null"
                              ,@""
                              ,@"null"
                              ,@"null"
                              ,@"null"
                              ,@"null"
                              ,@"null"
                              ,@"null"
                              ,@"null"
                              ,@"null"
                              ,1
                              ,@"null"
                              ,[NSString stringWithFormat:@"%0.2f",decAmt]
                              ,[NSString stringWithFormat:@"%@",[rsSvc stringForColumn:@"T_AccTaxCode"]]
                              ,@"null"
                              ,@""
                              ];
                
                                intRow += 1;
                
                
            }
            
            if ([[[structureInvoiceHdr objectAtIndex:i] objectForKey:@"IH_Rounding"] doubleValue] != 0.00) {
                
                jsonARJED3 = [NSString stringWithFormat:@",{\"tempID\":%@"
                              @",\"ARJEH_ID\":%d"
                              @",\"ARJED_Seq\":%ld"
                              @",\"ARJEH_CurrencyRate\":%@"
                              @",\"ARJED_Description\":\"%@\""
                              @",\"ARJED_Description2\":\"%@\""
                              @",\"ARJED_SourceDR\":%@"
                              @",\"ARJED_SourceCR\":\"%@\""
                              @",\"ARJED_DR\":%@"
                              @",\"ARJED_CR\":\"%@\""
                              @",\"ARJED_SupplyPurchase\":%@"
                              @",\"ARJED_TaxDR\":%@"
                              @",\"ARJED_TaxCR\":%d"
                              @",\"ARJED_TaxableDR\":%@"
                              @",\"ARJED_TaxableCR\":\"%@\""
                              @",\"ARJED_TotalDR\":%@"
                              @",\"ARJED_TotalCR\":\"%@\""
                              @",\"ARJED_TaxAdjustment\":%@"
                              @",\"ARJED_TaxExportCountry\":%@"
                              @",\"ARJED_RefNo\":\"%@\""
                              @",\"ARJED_Note\":%@"
                              @",\"ARJED_TaxPermitNo\":%@"
                              @",\"ARJED_ARJEHID\":%@"
                              @",\"ARJED_CCOADID\":%@"
                              @",\"ARJED_ProjectID\":%@"
                              @",\"ARJED_CostCentreID\":%@"
                              @",\"ARJED_TaxTypeID\":%@"
                              @",\"ARJED_CompanyCurrencyID\":%@"
                              @",\"ARJED_CurrencyRate\":\"%d\""
                              @",\"ARJED_DocDR\":%@"
                              @",\"ARJED_DocCR\":\"%@\""
                              @",\"ARJED_TaxTypeDesc\":\"%@\""
                              @",\"ARJED_ProjectDesc\":%@"
                              @",\"ARJED_CostCentreDesc\":\"%@\""
                              @"}"
                              ,@"null"
                              ,0
                              ,intRow + 1
                              ,@"null"
                              ,[[structureAccCode objectAtIndex:0] objectForKey:@"LA_CashSalesRoundingAC"]
                              ,@"PAYMENT ROUNDING"
                              ,@"null"
                              ,[NSString stringWithFormat:@"%0.2f",[[[structureInvoiceHdr objectAtIndex:i] objectForKey:@"IH_Rounding"] doubleValue]]
                              ,@"null"
                              ,[NSString stringWithFormat:@"%0.2f",[[[structureInvoiceHdr objectAtIndex:i] objectForKey:@"IH_Rounding"] doubleValue]]
                              ,@"null"
                              ,@"null"
                              ,0
                              ,@"null"
                              ,[NSString stringWithFormat:@"%0.2f",[[[structureInvoiceHdr objectAtIndex:i] objectForKey:@"IH_Rounding"] doubleValue]]
                              ,@"null"
                              ,[NSString stringWithFormat:@"%0.2f",[[[structureInvoiceHdr objectAtIndex:i] objectForKey:@"IH_Rounding"] doubleValue]]
                              ,@"null"
                              ,@"null"
                              ,@""
                              ,@"null"
                              ,@"null"
                              ,@"null"
                              ,@"null"
                              ,@"null"
                              ,@"null"
                              ,@"null"
                              ,@"null"
                              ,1
                              ,@"null"
                              ,[NSString stringWithFormat:@"%0.2f",[[[structureInvoiceHdr objectAtIndex:i] objectForKey:@"IH_Rounding"] doubleValue]]
                              ,@""
                              ,@"null"
                              ,@""
                              ];
                
                                intRow += 1;
            }
            [rsSvc close];
            
            jsonJournal = [NSString stringWithFormat:@"{\"JournalTypeDesc\":\"%@\",\"CompanyCurrencyDesc\":\"%@\",\"PaymentTermDesc\":\"%@\",\"AccCode\":\"%@\",\"BadDebtUnappliedAmt\":%@}",@"SALES JOURNAL",@"RINGGIT MALAYSIA",@"",[[structureInvoiceHdr objectAtIndex:i] objectForKey:@"IH_AcctCode"],@"false"];
            
            
            //
            // json string
            NSString *jsonEnd = @"]";
            
            NSString *combineAllJson = [NSString stringWithFormat:@"%@%@,%@,%@,%@,%@%@%@%@%@,%@%@",jsonStart,jsonCL,jsonCO,jsonUser,jsonARJEH,jsonARJEDStart,jsonARJED1,jsonARJED2,jsonARJED3,jsonARJEDEnd,jsonJournal,jsonEnd];
            
            //json string end
            
            
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",[[structureAccCode objectAtIndex:0] objectForKey:@"LA_AccUrl"],@"/api/rest/ARJournalEntry/PostARJournalEntry"]];
            
            
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
            [request setHTTPMethod:@"Post"];
            [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
            [request setHTTPBody:[combineAllJson dataUsingEncoding:NSUTF8StringEncoding]];
            
            __block BOOL isRunLoopNested = NO;
            __block BOOL isOperationCompleted = NO;
            
            [NSURLConnection sendAsynchronousRequest:request
                                               queue:[NSOperationQueue mainQueue]
                                   completionHandler:^(NSURLResponse *response,
                                                       NSData *data, NSError *connectionError)
             {
                 if (data.length > 0 && connectionError == nil)
                 {
                     
                     
                     NSArray *responceData = [PublicMethod manuallyConvertAccReturnJsonWithData:data];
                     
                     if ([[[responceData objectAtIndex:0] objectForKey:@"Result"] isEqualToString:@"True"]){
                         
                         NSLog(@"Complete Step 1");
                         arJournalResult = true;
                         //NSLog(@"Completed All");
                         isOperationCompleted = YES;
                         if (isRunLoopNested) {
                             CFRunLoopStop(CFRunLoopGetCurrent()); // CFRunLoopRun() returns
                         }
                         
                     }
                     else
                     {
                         //[[LibraryAPI sharedInstance] showAlertViewWithTitlw:[[responceData objectAtIndex:0] objectForKey:@"Mesage"] Title:@"Error"];
                         
                         //UIPasteboard *copyToClipBoard = [UIPasteboard generalPasteboard];
                         //copyToClipBoard.string = combineAllJson;
                         
                         errorMsg = [[responceData objectAtIndex:0] objectForKey:@"Message"];
                         
                         arJournalResult = false;
                         NSLog(@"Completed step 1 with error!");
                         isOperationCompleted = YES;
                         if (isRunLoopNested) {
                             CFRunLoopStop(CFRunLoopGetCurrent()); // CFRunLoopRun() returns
                         }
                         
                     }
                     
                 }
                 else
                 {
                     
                 }
             }];
            
            if ( ! isOperationCompleted) {
                isRunLoopNested = YES;
                NSLog(@"Waiting...");
                CFRunLoopRun(); // Magic!
                isRunLoopNested = NO;
            }
            NSLog(@"Continue To Posting");
            
            if (arJournalResult) {
                NSLog(@"Start Posting");
                //BOOL result;
                if ([[[structureInvoiceHdr objectAtIndex:i] objectForKey:@"IH_Flag"] isEqualToString: @"NotEmpty"]) {
                    arJournalResult = [self startPostingKnockOffDataWithInvoiceHdr:structureInvoiceHdr Index:i PaymentModeArray:groupPayType JSONCL:jsonCL JSONCo:jsonCO JSONUser:jsonUser Date:startDate];
                }
                else
                {
                    arJournalResult = true;
                }
                
                groupPayType = nil;
                if (!arJournalResult) {
                    [KVNProgress dismiss];
                    break;
                }
                
            }
            else
            {
                break;
            }
            
            
        }
        
    }];
    
    if (arJournalResult) {
        
        UIAlertController * alert = [[LibraryAPI sharedInstance] showAlertViewWithMsg:@"Progress complete" Title:@"Information"];
        self.labelFailDocNo.text = @"";
        [self presentViewController:alert animated:YES completion:nil];
    }
    else
    {
        
        UIAlertController * alert = [[LibraryAPI sharedInstance] showAlertViewWithMsg:errorMsg Title:@"Information"];
        if (failDocNo.length == 0) {
            self.labelFailDocNo.text = [NSString stringWithFormat:@"No transaction no sync"];
        }
        else
        {
            self.labelFailDocNo.text = [NSString stringWithFormat:@"Transaction %@ fail to sync",failDocNo];
        }
        
        [self presentViewController:alert animated:YES completion:nil];
        
    }
    
    structureInvoiceHdr = nil;
    structurePaymentMode = nil;
    
    [KVNProgress dismiss];
    
}

-(BOOL)startPostingKnockOffDataWithInvoiceHdr:(NSMutableArray *)ivHeader Index:(NSUInteger)index PaymentModeArray:(NSArray *)payModeArray JSONCL:(NSString *)jsonCL JSONCo:(NSString *)jsonCO JSONUser:(NSString *)jsonUser Date:(NSDate *)postDate
{
    
    NSMutableArray *arrayData1 = [[NSMutableArray alloc]init];
    NSUInteger intRow = 0;
    NSString *orDocNo = @"";
    __block BOOL postingResult;
    
    orDocNo = [NSString stringWithFormat:@"OR%@",[[ivHeader objectAtIndex:index] objectForKey:@"IH_DocNo_Default"]];
    NSString *jsonARPD = @"";
    
    NSMutableString *finalJsonAPRD = [[NSMutableString alloc] init];
    NSString *jsonARPK = @"";
    NSString *jsonJournal = @"";
    NSString *jsonARPH = [NSString stringWithFormat:@"{"
                          @"\"ARPH_ID\":%d"
                          @",\"ARPH_DocNo\":\"%@\""
                          @",\"ARPH_CustomerID\":%d"
                          @",\"ARPH_CurrencyRate\":%d"
                          @",\"ARPH_DocDate\":\"%@\""
                          @",\"ARPH_PostingDate\":\"%@\""
                          @",\"ARPH_TransDate\":\"%@\""
                          @",\"ARPH_Description\":\"%@\""
                          @",\"ARPH_TotalPaymentAmount\":%@"
                          @",\"ARPH_KnockOffAmount\":%d"
                          @",\"ARPH_UnappliedAmount\":%d"
                          @",\"ARPH_Reference\":\"%@\""
                          @",\"ARPH_Status\":%@"
                          @",\"ARPH_Remark\":\"%@\""
                          @",\"ARPH_Attachment\":%@"
                          @",\"ARPH_ClientID\":%d"
                          @",\"ARPH_CompanyID\":%d"
                          @",\"ARPH_DocTypeID\":%d"
                          @",\"ARPH_CompanyCurrencyID\":%d"
                          @",\"ARPH_PostingPeriod\":%d"
                          @",\"ARPH_ModifiedBy\":%d"
                          @",\"ARPH_DateModified\":\"%@\""
                          @",\"ARPH_CreatedBy\":%d"
                          @",\"ARPH_DateCreated\":\"%@\""
                          @"}"
                          ,0
                          ,orDocNo
                          ,0
                          ,1
                          ,[NSString stringWithFormat:@"\\/Date(%.0f000)\\/", [postDate timeIntervalSince1970]]
                          ,[NSString stringWithFormat:@"\\/Date(%.0f000)\\/", [postDate timeIntervalSince1970]]
                          ,[NSString stringWithFormat:@"\\/Date(%.0f000)\\/", [postDate timeIntervalSince1970]]
                          ,@"TESTING DESC"
                          ,[NSString stringWithFormat:@"%0.2F",[[[ivHeader objectAtIndex:index] objectForKey:@"IH_DocAmt"] doubleValue]]
                          ,0
                          ,0
                          ,@""
                          ,@"null"
                          ,@"TEST REMARK"
                          ,@"null"
                          ,0
                          ,0
                          ,0
                          ,0
                          ,0
                          ,0
                          ,[NSString stringWithFormat:@"\\/Date(%.@)\\/", @"-62135596800000"]
                          ,0
                          ,[NSString stringWithFormat:@"\\/Date(%@)\\/", @"-62135596800000"]
                  ];
    
    
    
    
    for (int k = 0; k < payModeArray.count; k++) {
        NSString *decPaymentModeAmt;
        NSString *paymentACCode;
        [self getTotalPaymentModeWithMode:[payModeArray objectAtIndex:k] InvDate:[[ivHeader objectAtIndex:index] objectForKey:@"IH_UpdDate"]];
        
        paymentACCode = [self getPaymentACCodeWithPaymentType:[payModeArray objectAtIndex:k]];
        
        if ([[payModeArray objectAtIndex:k] isEqualToString:@"Cash"]) {
            decPaymentModeAmt = [NSString stringWithFormat:@"%0.2f",[[[paymentTotalAmtArray objectAtIndex:0] objectForKey:@"amt"] doubleValue] - [[[paymentTotalAmtArray objectAtIndex:1] objectForKey:@"TotalChange"] doubleValue]];
        }
        else
        {
            decPaymentModeAmt = [NSString stringWithFormat:@"%0.2f",[[[paymentTotalAmtArray objectAtIndex:0] objectForKey:@"amt"] doubleValue]];
        }
        
        jsonARPD = [NSString stringWithFormat:@"{"
                              @"\"tempID\":%d"
                              @",\"ARPD_ID\":%d"
                              @",\"ARPD_ARPHID\":%@"
                              @",\"ARPD_Seq\":%ld"
                              @",\"ARPH_CurrencyRate\":\"%d\""
                              @",\"ARPD_PaymentMode\":%@"
                              @",\"ARPD_Remark\":\"%@\""
                              @",\"ARPD_ChequeNo\":\"%@\""
                              @",\"ARPD_BankChargeAmount\":\"%@\""
                              @",\"ARPD_PaymentAmount\":\"%@\""
                              @",\"ARPD_Status\":%@"
                              @",\"ARPD_CancelDate\":%@"
                              @",\"ARPD_BankChargeTaxAmount\":\"%@\""
                              @",\"ARPD_TaxTypeID\":\"%@\""
                              @",\"ARPD_Reason\":\"%@\""
                              @",\"ARPD_CompanyCurrency\":\"%@\""
                              @",\"ARPD_CurrencyRate\":\"%@\""
                              @",\"ARPD_TaxTypeDesc\":\"%@\""
                              @"}"
                              ,2
                              ,46
                              ,@"null"
                              ,intRow + 1
                              ,1
                              ,@"null"
                              ,paymentACCode
                              ,@""
                              ,@""
                              ,decPaymentModeAmt
                              ,@"null"
                              ,@"null"
                              ,@""
                              ,@""
                              ,@""
                              ,@"Ringgit Malaysia"
                              ,@"1.00"
                              ,@""
                              ];
        
        
        NSMutableDictionary *postPaymentModeData = [NSMutableDictionary dictionary];
        [postPaymentModeData setObject:jsonARPD forKey:@"ARPDMode"];
        [arrayData1 addObject:postPaymentModeData];
        postPaymentModeData = nil;
        
        intRow += 1;
    }
    
    
    for (int k = 0; k < arrayData1.count; k++) {
        if ( k == 0) {
            [finalJsonAPRD appendString:[NSString stringWithFormat:@"%@",[[arrayData1 objectAtIndex:k] objectForKey:@"ARPDMode"]]];
        }
        else
        {
            [finalJsonAPRD appendString:[NSString stringWithFormat:@",%@",[[arrayData1 objectAtIndex:k] objectForKey:@"ARPDMode"]]];
        }
    }
    
    
    if ([[[ivHeader objectAtIndex:index] objectForKey:@"IH_DocAmt"] doubleValue] > 0) {
        
        jsonARPK = [NSString stringWithFormat:@"[{\"ARPKO_ID\":%@"
                    @",\"ARPKO_ARPaymentID\":%@"
                    @",\"DocumentType\":%@"
                    @",\"ID\":%@"
                    @",\"DiscountAmount\":\"%@\""
                    @",\"Payment\":\"%@\""
                    @",\"KnockOffDate\":\"%@\""
                    @",\"Status\":%@"
                    @",\"LocalPayment\":\"%@\""
                    @",\"Rate\":\"%d\""
                    @",\"ARDocNo\":\"%@\""
                    @"}]"
                    ,@"null"
                    ,@"null"
                    ,@"null"
                    ,@"null"
                    ,@"0"
                    ,[NSString stringWithFormat:@"%0.2f",[[[ivHeader objectAtIndex:index] objectForKey:@"IH_DocAmt"] doubleValue]]
                    ,[NSString stringWithFormat:@"\\/Date(%.0f000)\\/", [postDate timeIntervalSince1970]]
                    ,@"null"
                    ,[NSString stringWithFormat:@"%0.2f",[[[ivHeader objectAtIndex:index] objectForKey:@"IH_DocAmt"] doubleValue]]
                    ,1
                    ,[[ivHeader objectAtIndex:index] objectForKey:@"IH_DocNo"]
                    ];
    }
    
    jsonJournal = [NSString stringWithFormat:@"{\"JournalTypeDesc\":\"%@\",\"CompanyCurrencyDesc\":\"%@\",\"PaymentTermDesc\":\"%@\",\"AccCode\":\"%@\",\"BadDebtUnappliedAmt\":%@}",@"SALES JOURNAL",@"RINGGIT MALAYSIA",@"",[[ivHeader objectAtIndex:index] objectForKey:@"IH_AcctCode"],@"false"];
    
    //NSString *combineAllJson = [NSString stringWithFormat:@"[%@,%@,%@,%@,[%@],%@,%@]",jsonCL,jsonCO,jsonUser,jsonARPH,finalJsonAPRD,jsonARPK,jsonJournal];
    
    NSString *combineAllJson = [NSString stringWithFormat:@"[%@,%@,%@,%@,[%@],%@,%@]",jsonCL,jsonCO,jsonUser,jsonARPH,finalJsonAPRD,jsonARPK,jsonJournal];
    //NSLog(@"%@",combineAllJson);
    
    //NSData* data2 = [combineAllJson dataUsingEncoding:NSUTF8StringEncoding];
    
    //NSArray *responceData = [NSJSONSerialization JSONObjectWithData:data2 options:NSJSONReadingMutableContainers error:nil];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",[[structureAccCode objectAtIndex:0] objectForKey:@"LA_AccUrl"],@"/api/rest/ARPayment/PostARPayment"]];
    
    //NSURL *url = [NSURL URLWithString:@"http://test1.irsbizsuite.com.my/api/rest/ARPayment/PostARPayment"];
    
    __block BOOL isRunLoopNested = NO;
    __block BOOL isOperationCompleted = NO;
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"Post"];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[combineAllJson dataUsingEncoding:NSUTF8StringEncoding]];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response,
                                               NSData *data, NSError *connectionError)
     {
         if (data.length > 0 && connectionError == nil)
         {
             
             
             NSArray *responceData = [PublicMethod manuallyConvertAccReturnJsonWithData:data];
             
             if ([[[responceData objectAtIndex:0] objectForKey:@"Result"] isEqualToString:@"True"]){
                 postingResult = true;
                 NSLog(@"Completed Step 2!");
                 
                 isOperationCompleted = YES;
                 if (isRunLoopNested) {
                     CFRunLoopStop(CFRunLoopGetCurrent()); // CFRunLoopRun() returns
                 }
                 
             }
             else
             {
                 //[[LibraryAPI sharedInstance] showAlertViewWithTitlw:[[responceData objectAtIndex:0] objectForKey:@"Mesage"] Title:@"Error"];
                 
                 //UIAlertController * alert = [[LibraryAPI sharedInstance] showAlertViewWithMsg:[[responceData objectAtIndex:0] objectForKey:@"Mesage"] Title:@"Information"];
                 
                 //[self presentViewController:alert animated:YES completion:nil];
                 errorMsg = [[responceData objectAtIndex:0] objectForKey:@"Message"];
                 postingResult = false;
                 NSLog(@"Completed step 2 With Error!");
                 
                 isOperationCompleted = YES;
                 if (isRunLoopNested) {
                     CFRunLoopStop(CFRunLoopGetCurrent()); // CFRunLoopRun() returns
                 }
                 
             }
             
         }
         else
         {
             
         }
     }];
    
    if ( ! isOperationCompleted) {
        isRunLoopNested = YES;
        NSLog(@"Waiting... step 2");
        CFRunLoopRun(); // Magic!
        isRunLoopNested = NO;
    }
    
    NSLog(@"back to step 1");
    return postingResult;
}

-(NSArray *)convertApiStringToJsonFormatWithReturnData:(NSData *)dataReturn
{
    NSString* responseString = [[NSString alloc] initWithData:dataReturn encoding:NSUTF8StringEncoding];
    
    NSLog(@"response1: %@",responseString);
    
    responseString = [responseString stringByReplacingOccurrencesOfString:@"\""
                                                               withString:@""];
    responseString = [responseString stringByReplacingOccurrencesOfString:@"'"
                                                               withString:@"\""];
    
    
    responseString = [NSString stringWithFormat:@"[%@]",responseString];
    
    NSData* data2 = [responseString dataUsingEncoding:NSUTF8StringEncoding];
    
    return [NSJSONSerialization JSONObjectWithData:data2 options:NSJSONReadingMutableContainers error:nil];
}

-(void)makeDateArrayWithDateFrom:(NSString *)dateFrom DateTo:(NSString *)dateTo
{
    [dateArray removeAllObjects];
    
    NSDateFormatter *f = [[NSDateFormatter alloc] init];
    [f setDateFormat:@"yyyy-MM-dd"];
    [f setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    NSDate *startDate = [f dateFromString:dateFrom];
    NSDate *endDate = [f dateFromString:dateTo];
    
    
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorianCalendar components:NSCalendarUnitDay
                                                        fromDate:startDate
                                                          toDate:endDate
                                                         options:0];
    
    for (int i = 0; i < components.day; ++i) {
        NSDateComponents *newComponents = [NSDateComponents new];
        newComponents.day = i;
        
        NSDate *date = [gregorianCalendar dateByAddingComponents:newComponents
                                                          toDate:startDate
                                                         options:0];
        [dateArray addObject:date];
    }
    
    [dateArray addObject:endDate];
}

-(double)getDailyCollectionTotalWithPaymentType:(NSString *)paymentType Date:(NSString *)date TaxInclueded:(NSUInteger)taxIncludedFlag
{
    return 0.00;
}

-(NSString *)checkPaymentTypeIsNullOrDash:(NSString *)type
{
    if (!type.length) {
        return nil;
    }
    else if ([type isEqualToString:@"-"])
    {
        return nil;
    }
    else
    {
        return type;
    }
}

#pragma mark - sqlite
-(void)getTotalPaymentModeWithMode:(NSString *)mode InvDate:(NSString *)date
{
    [paymentTotalAmtArray removeAllObjects];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        
        //NSMutableArray *yyy = [[NSMutableArray alloc] init];
        
        FMResultSet *rs = [db executeQuery:@"select sum(qty) qty, Type, sum(amt) amt from ( "
                           "select count(*) qty, IvH_PaymentType1 as Type, sum(IvH_PaymentAmt1) Amt from InvoiceHdr where date(IvH_Date) = date(?) and IvH_PaymentType1 = ? group by Ivh_PaymentType1 "
                           " union "
                           "select count(*) qty, IvH_PaymentType2 as Type, sum(IvH_PaymentAmt2) Amt from InvoiceHdr where date(IvH_Date) = date(?) and IvH_PaymentType2 = ? group by Ivh_PaymentType2 "
                           " union "
                           "select count(*) qty, IvH_PaymentType3 as Type, sum(IvH_PaymentAmt3) Amt from InvoiceHdr where date(IvH_Date) = date(?) and IvH_PaymentType3 = ? group by Ivh_PaymentType3 "
                           " union "
                           "select count(*) qty, IvH_PaymentType4 as Type, sum(IvH_PaymentAmt4) Amt from InvoiceHdr where date(IvH_Date) = date(?) and IvH_PaymentType4 = ? group by Ivh_PaymentType4 "
                           " union "
                           "select count(*) qty, IvH_PaymentType5 as Type, sum(IvH_PaymentAmt5) Amt from InvoiceHdr where date(IvH_Date) = date(?) and IvH_PaymentType5 = ? group by Ivh_PaymentType5 "
                           " union "
                           "select count(*) qty, IvH_PaymentType6 as Type, sum(IvH_PaymentAmt6) Amt from InvoiceHdr where date(IvH_Date) = date(?) and IvH_PaymentType6 = ? group by Ivh_PaymentType6 "
                           " union "
                           "select count(*) qty, IvH_PaymentType7 as Type, sum(IvH_PaymentAmt7) Amt from InvoiceHdr where date(IvH_Date) = date(?) and IvH_PaymentType7 = ? group by Ivh_PaymentType7 "
                           " union "
                           "select count(*) qty, IvH_PaymentType8 as Type, sum(IvH_PaymentAmt8) Amt from InvoiceHdr where date(IvH_Date) = date(?) and IvH_PaymentType8 = ? group by Ivh_PaymentType8 "
                           ") where Type != '-' group by Type",date,mode,date,mode,date,mode,date,mode,date,mode,date,mode,date,mode,date,mode];
        //category = [NSMutableArray array];
        
        if ([rs next]) {
            //XreadingInfo = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d",[rs intForColumn:@"qty"]],[NSString stringWithFormat:@"%@",[rs stringForColumn:@"Type"]], [NSString stringWithFormat:@"%0.2f",[rs doubleForColumn:@"amt"]], nil];
            //[yyy addObject:[rs resultDictionary]];
            [paymentTotalAmtArray addObject:[rs resultDictionary]];
            
        }
        
        [rs close];
        
        if ([mode isEqualToString:@"Cash"]) {
            FMResultSet *rsTotalChange = [db executeQuery:@"Select sum(IvH_ChangeAmt) as TotalChange from InvoiceHdr where date(IvH_Date) = ?",date];
            
            if ([rsTotalChange next]) {
                [paymentTotalAmtArray addObject:[rsTotalChange resultDictionary]];
            }
            
            [rsTotalChange close];
        }
    }];
    
    [queue close];

}

-(NSString *)getPaymentACCodeWithPaymentType:(NSString *)type
{
    __block NSString *code;
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"Select PT_AccCode from PaymentType where PT_Code = ?", type];
        
        if ([rs next]) {
            code = [rs stringForColumn:@"PT_AccCode"];
        }
        else
        {
            code = @"Non";
        }
        [rs close];
    }];
    [queue close];
    
    return code;
    
}

-(NSMutableDictionary *)generateEmptyInvHdrWithDateShort:(NSString *)dateShort DateLong:(NSString *)dateLong
{
    NSString *docNo;
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    NSString *IH_TaxIncluded_YN;
    if ([[[LibraryAPI sharedInstance] getTaxType] isEqualToString:@"IEx"]){
        docNo = [NSString stringWithFormat:@"CS%@%@",dateShort,@"EP"];
        IH_TaxIncluded_YN = @"0";
    }
    else
    {
        docNo = [NSString stringWithFormat:@"CS%@%@",dateShort,@"IP"];
        IH_TaxIncluded_YN = @"1";
    }
    
    [data setObject:docNo forKey:@"IH_DocNo_Default"];
    [data setObject:docNo forKey:@"IH_DocNo"];
    [data setObject:@"0.00"forKey:@"IH_DocAmt"];
    [data setObject:dateLong forKey:@"IH_UpdDate"];
    [data setObject:[[structureAccCode objectAtIndex:0] objectForKey:@"LA_CustomerAC"] forKey:@"IH_AcctCode"];
    [data setObject:@"0.00" forKey:@"IH_SalesTax"];
    [data setObject:@"0.00" forKey:@"IH_ServiceTax"];
    [data setObject:@"0.00" forKey:@"IH_ServiceTaxAmt"];
    [data setObject:@"0.00" forKey:@"IH_Discount"];
    [data setObject:IH_TaxIncluded_YN forKey:@"IH_TaxIncluded_YN"];
    [data setObject:@"0.00" forKey:@"IH_Rounding"];
    
    return data;
}

@end
