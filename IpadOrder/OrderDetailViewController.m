//
//  OrderDetailViewController.m
//  IpadOrder
//
//  Created by IRS on 8/6/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "OrderDetailViewController.h"
#import "NumPadTextField/NumericKeypadTextField.h"
#import "NumericKeypadViewController.h"
#import <FMDB.h>
#import "LibraryAPI.h"

@interface OrderDetailViewController ()
{
    NSString *dbPath;
    FMDatabase *dbTable;
    
    double gst;
    
    // no include tax
    double itemSellingPrice;
    double totalItemSellingAmt;
    
    // tax amt
    double itemTaxAmt;
    double totalItemTaxAmt;
    double itemDiscountInPercent;
    
    NSString *taxType;
    NSMutableArray *salesArray;
    NSMutableArray *editSalesArray;
    
    NSString *itemCode;
    
    // for kitchen receipt
    NSString *printStatus;
    NSString *orgQty;
    
    // for tax Code
    NSString *itemGstCode;
    
    // for service tax
    double serviceTaxRate;
    NSString *itemServiceTaxCode;
    //double itemServcieTaxAmt;
    double totalItemServiceTaxAmt;
    
    //----- for item take away or dine in
    int itemTakeAwayYN;
    //NSString *tbService;
    NSString *orderStatus;
    NSString *terminalType;
    NSString *totalItemCondimentSurCharge;

}
@end

@implementation OrderDetailViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.preferredContentSize = CGSizeMake(850, 700);
    
    self.textItemPrice.delegate = self;
    self.textDiscount.delegate = self;
    self.textItemQty.delegate = self;

    self.textItemPrice.numericKeypadDelegate = self;
    self.textItemQty.numericKeypadDelegate = self;
    self.textDiscount.numericKeypadDelegate = self;
    bigBtn = @"Confirm";
    //[self.textDiscount addTarget:self action:@selector(textBeginEditing:) forControlEvents:UIControlEventEditingDidBegin];
    
    taxType = [[LibraryAPI sharedInstance]getTaxType];
    terminalType = [[LibraryAPI sharedInstance] getWorkMode];
    salesArray = [[NSMutableArray alloc]init];
    editSalesArray = [[NSMutableArray alloc]init];
    dbPath = [[LibraryAPI sharedInstance]getDbPath];
    [self.btnAdd addTarget:self action:@selector(addBackSaveData:) forControlEvents:UIControlEventTouchUpInside];
    
    self.textRemark.layer.borderWidth = 1.0f;
    self.textRemark.layer.borderColor = [[UIColor colorWithRed:128/255.0 green:128/255.0 blue:128/255.0 alpha:1.0] CGColor];
    self.textRemark.layer.cornerRadius = 10;
    self.SegmentQtyBtn.selectedSegmentIndex = -1;
    
    
    if ([_dataStatus isEqualToString:@"New"]) {
        //[self.btnAdd setTitle:@"Add" forState:UIControlStateNormal];
        //[self getItemMast];
    }
    else
    {
        [self.btnAdd setTitle:@"Update" forState:UIControlStateNormal];
        [self getEditSalesArray];
    }
    
    self.textSubTotal.enabled = NO;
    self.textTotal.enabled = NO;
    self.textTotalTax.enabled = NO;
    self.textDiscountAmt.enabled = NO;
    
    if ([_odDineStatus isEqualToString:@"1"]) {
        self.segmentTakeAwayYN.enabled = NO;
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillLayoutSubviews
{
    //[super viewWillLayoutSubviews];
    
    //self.view.superview.bounds = CGRectMake(0, 0, 850, 700);
    //[self getItemMast];
}

/*
-(void)textBeginEditing:(id)sender
{
    //self.textDiscount.text = nil;
}
*/

-(void)getEditSalesArray
{
    
    [editSalesArray  addObjectsFromArray:[[LibraryAPI sharedInstance]getEditOrderDetailArray]];
    //_im_ItemNo = [[[editSalesArray objectAtIndex:0] objectForKey:@"IM_ItemNo"] integerValue];
    gst = [[[editSalesArray objectAtIndex:0] objectForKey:@"IM_Gst"] doubleValue];
    serviceTaxRate = [[[editSalesArray objectAtIndex:0] objectForKey:@"IM_ServiceTaxRate"] doubleValue];
    orderStatus = [[editSalesArray objectAtIndex:0] objectForKey:@"Status"];
    itemCode = [[editSalesArray objectAtIndex:0] objectForKey:@"IM_ItemCode"];
    self.labelItemName.text = [[editSalesArray objectAtIndex:0] objectForKey:@"IM_Description"];
    self.textItemPrice.text = [[editSalesArray objectAtIndex:0]objectForKey:@"IM_Price"];
    self.textItemQty.text = [NSString stringWithFormat:@"%0.2f",[[[editSalesArray objectAtIndex:0]objectForKey:@"IM_Qty"] doubleValue]];
    self.textDiscount.text = [NSString stringWithFormat:@"%0.2f",[[[editSalesArray objectAtIndex:0]objectForKey:@"IM_Discount"] doubleValue]];
    self.discountSegment.selectedSegmentIndex = [[[editSalesArray objectAtIndex:0]objectForKey:@"IM_DiscountType"] integerValue];
    self.textSubTotal.text = [[editSalesArray objectAtIndex:0]objectForKey:@"IM_SubTotal"];
    self.textDiscountAmt.text = [[editSalesArray objectAtIndex:0]objectForKey:@"IM_DiscountAmt"];
    self.textTotalTax.text = [[editSalesArray objectAtIndex:0]objectForKey:@"IM_TotalTax"];
    self.textTotal.text = [[editSalesArray objectAtIndex:0]objectForKey:@"IM_Total"];
    self.textRemark.text = [[editSalesArray objectAtIndex:0]objectForKey:@"IM_Remark"];
    itemDiscountInPercent = [[[editSalesArray objectAtIndex:0]objectForKey:@"IM_DiscountInPercent"] doubleValue];
    totalItemCondimentSurCharge = [[editSalesArray objectAtIndex:0]objectForKey:@"IM_TotalCondimentSurCharge"];
    
    if ([taxType isEqualToString:@"Inc"]) {
        
        totalItemSellingAmt = ([[[editSalesArray objectAtIndex:0]objectForKey:@"IM_SubTotal"] doubleValue]) / ((gst / 100)+1);
        
        totalItemTaxAmt = ([[[editSalesArray objectAtIndex:0]objectForKey:@"IM_SubTotal"] doubleValue]) - totalItemSellingAmt;
        //itemTaxAmt = [[[editSalesArray objectAtIndex:0]objectForKey:@"IM_SubTotal"] doubleValue] - totalItemSellingAmt;
        itemTaxAmt = [[[editSalesArray objectAtIndex:0]objectForKey:@"IM_Tax"] doubleValue];
    }
    else
    {
        totalItemSellingAmt = [[[editSalesArray objectAtIndex:0]objectForKey:@"IM_SubTotal"] doubleValue];
        totalItemTaxAmt = [[[editSalesArray objectAtIndex:0]objectForKey:@"IM_TotalTax"] doubleValue];
        //itemTaxAmt = [[[editSalesArray objectAtIndex:0]objectForKey:@"IM_TotalTax"] doubleValue];
        itemTaxAmt = [[[editSalesArray objectAtIndex:0]objectForKey:@"IM_Tax"] doubleValue];
        
    }
    // kitchen receipt
    printStatus = [[editSalesArray objectAtIndex:0] objectForKey:@"IM_Print"];
    orgQty = [[editSalesArray objectAtIndex:0] objectForKey:@"IM_OrgQty"];
    
    itemGstCode = [[editSalesArray objectAtIndex:0]objectForKey:@"IM_GSTCode"];
    itemServiceTaxCode = [[editSalesArray objectAtIndex:0]objectForKey:@"IM_ServiceTaxCode"];
    totalItemServiceTaxAmt = [[[editSalesArray objectAtIndex:0]objectForKey:@"IM_ServiceTaxAmt"]doubleValue];
    //----- for item dine in or TK
    itemTakeAwayYN = [[[editSalesArray objectAtIndex:0] objectForKey:@"IM_TakeAwayYN"] integerValue];
    self.segmentTakeAwayYN.selectedSegmentIndex = itemTakeAwayYN;
    [self calcAmount];
    
}

#pragma mark - highlight textfield
-(void)textFieldDidBeginEditing:(UITextField *)textField {
    
    [textField selectAll:nil];
    
}

#pragma mark - custom keyboard delegate
-(void)saveActionFormTextField:(UITextField *)textField
{
    [self calcAmount];
    [textField resignFirstResponder];
}

-(void)keyPressActionFormTextField:(UITextField *)textField
{
    if (textField == self.textDiscount) {
        [self calcDiscountAmt:textField.text];
    }
    else if (textField == self.textItemPrice)
    {
        [self calcAmount];
    }
    else if (textField == self.textItemQty)
    {
        [self calcAmount];
    }
    
    //NSLog(@"%@",textField.text);
}

#pragma mark - touch background
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

#pragma mark - sqlite

#pragma mark - btn click
- (IBAction)btnCancel:(id)sender {
    salesArray = nil;
    editSalesArray = nil;
    [self dismissViewControllerAnimated:NO completion:nil];
}
- (IBAction)discountType:(id)sender {
    switch (self.discountSegment.selectedSegmentIndex) {
        case 0:
            [self calcAmount];
            break;
        case 1:
            [self calcAmount];
        default:
            break;
    }
}

- (void)addBackSaveData:(id)sender {
    
    if ([self.textItemQty.text doubleValue] == 0) {
        [self showAlertView:@"Item qty cannot 0" title:@"Warning"];
        return;
    }
    
    NSString *decimalRegEx = @"^[0-9+-]+(?:\\.[0-9]{2})?$";
    NSPredicate *decimalTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", decimalRegEx];
    //Valid email address
    
    if ([decimalTest evaluateWithObject:self.textItemPrice.text] == NO)
    {
        [self showAlertView:@"Invalid price" title:@"Warning"];
        return;
        
    }
    else if ([decimalTest evaluateWithObject:self.textItemQty.text] == NO)
    {
        //[self showAlertView:@"Qty Not In Proper Format" title:@"Warning"];
        //return;
    }
    else if ([decimalTest evaluateWithObject:self.textDiscount.text] == NO)
    {
        [self showAlertView:@"Invalid discount" title:@"Warning"];
        return;
    }
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    
    
    [data setObject:orderStatus forKey:@"Status"];
    [data setObject:itemCode forKey:@"IM_ItemCode"];
    [data setObject:self.labelItemName.text forKey:@"IM_Description"];
    [data setObject:[NSString stringWithFormat:@"%0.2f",[self.textItemPrice.text doubleValue]] forKey:@"IM_Price"];
    //one item selling price not included tax
    [data setObject:[NSString stringWithFormat:@"%0.6f",itemSellingPrice] forKey:@"IM_SellingPrice"];
    [data setObject:[NSString stringWithFormat:@"%0.6f",itemTaxAmt] forKey:@"IM_Tax"];
    [data setObject:self.textItemQty.text forKey:@"IM_Qty"];
    [data setObject:[NSString stringWithFormat:@"%f",itemDiscountInPercent] forKey:@"IM_DiscountInPercent"];
    
    [data setObject:[NSString stringWithFormat:@"%ld",(long)gst] forKey:@"IM_Gst"];
    
    [data setObject:self.textTotalTax.text forKey:@"IM_TotalTax"]; //sum tax amt
    [data setObject:[NSString stringWithFormat:@"%ld",(long)self.discountSegment.selectedSegmentIndex] forKey:@"IM_DiscountType"];
    [data setObject:self.textDiscount.text forKey:@"IM_Discount"]; // discount given
    [data setObject:self.textDiscountAmt.text forKey:@"IM_DiscountAmt"];  // sum discount
    [data setObject:self.textSubTotal.text forKey:@"IM_SubTotal"];
    [data setObject:self.textTotal.text forKey:@"IM_Total"];
    
    //------------------------------------------------------------------------------------------
    [data setObject:[NSString stringWithFormat:@"%0.2f", totalItemSellingAmt] forKey:@"IM_totalItemSellingAmt"];  // subtotal not include tax n will replace this
    [data setObject:[NSString stringWithFormat:@"%0.6f", totalItemSellingAmt] forKey:@"IM_totalItemSellingAmtLong"];  // subtotal not include tax
    [data setObject:[NSString stringWithFormat:@"%0.6f", totalItemTaxAmt] forKey:@"IM_totalItemTaxAmtLong"];  // total tax amt
    
    [data setObject:self.textRemark.text forKey:@"IM_Remark"];
    
    //---------------for tax code --------------------
    [data setObject:itemGstCode forKey:@"IM_GSTCode"];
    
    //-------------service tax-------------
    [data setObject:itemServiceTaxCode forKey:@"IM_ServiceTaxCode"];  //svc tax code
    
    [data setObject:[NSString stringWithFormat:@"%0.6f", totalItemServiceTaxAmt] forKey:@"IM_ServiceTaxAmt"]; // service tax amount
    [data setObject:[NSString stringWithFormat:@"%ld",(long)serviceTaxRate] forKey:@"IM_ServiceTaxRate"];
    
    [data setObject:@"ItemOrder" forKey:@"OrderType"];
    [data setObject:[NSString stringWithFormat:@"%0.2f",[totalItemCondimentSurCharge doubleValue] * 1.00] forKey:@"IM_TotalCondimentSurCharge"];
    [data setObject:[NSString stringWithFormat:@"%0.2f",[totalItemCondimentSurCharge doubleValue] * 1.00] forKey:@"IM_NewTotalCondimentSurCharge"];
    //--------- take away ---------------
    [data setObject:[NSString stringWithFormat:@"%ld",self.segmentTakeAwayYN.selectedSegmentIndex] forKey:@"IM_TakeAwayYN"];
    
    if ([terminalType isEqualToString:@"Terminal"]) {
        [data setObject:@"Order" forKey:@"IM_Flag"];
        [data setObject:_tbName forKey:@"IM_Table"];
        
    }
    
    // for kitchen receipt detect +/- qty
    
    int adjQty;
    NSLog(@"qty : %@",self.textItemQty.text);
    adjQty = [self.textItemQty.text intValue] - [orgQty intValue];
    
    if ([printStatus isEqualToString:@"Printed"]) {
        if (adjQty > 0) {
            [data setObject:@"Print" forKey:@"IM_Print"];
            [data setObject:[NSString stringWithFormat:@"%d",adjQty] forKey:@"IM_OrgQty"];
        }
        else if (adjQty == 0)
        {
            [data setObject:@"Printed" forKey:@"IM_Print"];
            [data setObject:[NSString stringWithFormat:@"%d",[orgQty intValue]] forKey:@"IM_OrgQty"];
        }
        else if (adjQty < 0)
        {
            [data setObject:@"Print" forKey:@"IM_Print"];
            [data setObject:[NSString stringWithFormat:@"%d",adjQty] forKey:@"IM_OrgQty"];
        }
    }
    else
    {
        [data setObject:@"Print" forKey:@"IM_Print"];
        [data setObject:[NSString stringWithFormat:@"%d",[self.textItemQty.text intValue]] forKey:@"IM_OrgQty"];
    }
    
    [salesArray addObject:data];
    
    if (_delegate != nil) {
        [_delegate passSalesDataBack:salesArray dataStatus:_dataStatus tablePosition:_position ArrayIndex:0];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
}

#pragma mark - custom method
-(void)calcAmount
{
    
    // GST EX
    if ([taxType isEqualToString:@"IEx"]) {
        if ([self.textDiscount.text doubleValue] == 0) {
            self.textSubTotal.text = [NSString stringWithFormat:@"%.02f",round(([self.textItemQty.text doubleValue] * [self.textItemPrice.text doubleValue])*100)/100];
            itemSellingPrice = [self.textItemPrice.text doubleValue];
            self.textTotalTax.text = [NSString stringWithFormat:@"%.02f",[self.textSubTotal.text doubleValue] * (gst/100)];
            
            self.textTotal.text = [NSString stringWithFormat:@"%.02f", [self.textSubTotal.text doubleValue] + [self.textTotalTax.text doubleValue]];
            totalItemSellingAmt = [self.textSubTotal.text doubleValue];
            totalItemTaxAmt = [[NSString stringWithFormat:@"%.06f",([self.textSubTotal.text doubleValue]) * (gst/100)] doubleValue];
            totalItemServiceTaxAmt = totalItemSellingAmt * (serviceTaxRate / 100.0);
        }
        else
        {
            //self.textSubTotal.text = [NSString stringWithFormat:@"%.02f",[self.textItemQty.text doubleValue] * [self.textItemPrice.text doubleValue]];
            self.textSubTotal.text = [NSString stringWithFormat:@"%.02f",round(([self.textItemQty.text doubleValue] * [self.textItemPrice.text doubleValue])*100)/100];
            itemSellingPrice = [self.textItemPrice.text doubleValue];
            [self calcDiscountAmt:self.textDiscount.text];
        }
        
    }
    else
    {
        //gst InC
        if ([self.textDiscount.text doubleValue] == 0.00) {
            
            //self.textSubTotal.text = [NSString stringWithFormat:@"%.02f",[self.textItemQty.text doubleValue] * [self.textItemPrice.text doubleValue]];
            self.textSubTotal.text = [NSString stringWithFormat:@"%.02f",round(([self.textItemQty.text doubleValue] * [self.textItemPrice.text doubleValue])*100)/100];
            self.textDiscountAmt.text = @"0.00";
            self.textTotalTax.text = [NSString stringWithFormat:@"%.02f",itemTaxAmt * [self.textItemQty.text doubleValue]];
            itemSellingPrice = [self.textItemPrice.text doubleValue] / ((gst / 100)+1);
            totalItemSellingAmt = ([self.textSubTotal.text doubleValue]) / ((gst / 100)+1);
            totalItemTaxAmt = itemTaxAmt * [self.textItemQty.text doubleValue];
            self.textTotal.text = self.textSubTotal.text;
            totalItemServiceTaxAmt = totalItemSellingAmt * (serviceTaxRate / 100.0);
        }
        else
        {
            //self.textSubTotal.text = [NSString stringWithFormat:@"%.02f",[self.textItemQty.text doubleValue] * [self.textItemPrice.text doubleValue]];
            self.textSubTotal.text = [NSString stringWithFormat:@"%.02f",round(([self.textItemQty.text doubleValue] * [self.textItemPrice.text doubleValue])*100)/100];
            itemSellingPrice = [self.textItemPrice.text doubleValue] / ((gst / 100)+1);
            [self calcDiscountAmt:self.textDiscount.text];
        }
        
    }
    
}

// all calculate in percent
-(void)calcDiscountAmt:(NSString *)disAmt
{
    
    if (self.discountSegment.selectedSegmentIndex == 0) {
        if ([taxType isEqualToString:@"IEx"]) {
            self.textDiscountAmt.text = [NSString stringWithFormat:@"%0.2f",[self.textSubTotal.text doubleValue] * ([disAmt doubleValue] / 100)];
            
            [self calcFinalExAmt];
        }
        else
        {
            
            self.textDiscountAmt.text = [NSString stringWithFormat:@"%0.2f",[self.textSubTotal.text doubleValue] * ([disAmt doubleValue] / 100)];
            [self calcFinalIncAmt];
    
        }
        itemDiscountInPercent = [self.textDiscount.text doubleValue];
    }
    else
    {
        itemDiscountInPercent = [self.textDiscount.text doubleValue] / [self.textSubTotal.text doubleValue] * 100;
        if ([taxType isEqualToString:@"IEx"]) {
            self.textDiscountAmt.text = [NSString stringWithFormat:@"%0.2f",[disAmt doubleValue]];
            [self calcFinalExAmt];
        }
        else
        {
            
            self.textDiscountAmt.text = [NSString stringWithFormat:@"%0.2f",[disAmt doubleValue]];
            [self calcFinalIncAmt];
            
        }
        
    }
}

-(void)calcFinalExAmt
{
    self.textSubTotal.text = [NSString stringWithFormat:@"%.02f",[self.textItemQty.text doubleValue] * [self.textItemPrice.text doubleValue]];
    
    self.textTotalTax.text = [NSString stringWithFormat:@"%.02f",([self.textSubTotal.text doubleValue] - [self.textDiscountAmt.text doubleValue]) * (gst/100)];
    NSLog(@"%@",self.textTotalTax.text);
    self.textTotal.text = [NSString stringWithFormat:@"%.02f", [self.textSubTotal.text doubleValue] + [self.textTotalTax.text doubleValue] - [self.textDiscountAmt.text doubleValue]];
    totalItemSellingAmt = [self.textSubTotal.text doubleValue];
    totalItemTaxAmt = [[NSString stringWithFormat:@"%.06f",([self.textSubTotal.text doubleValue] - [self.textDiscountAmt.text doubleValue]) * (gst/100)]doubleValue];
    totalItemServiceTaxAmt = (totalItemSellingAmt - [self.textDiscountAmt.text doubleValue]) * (serviceTaxRate / 100.0);
}

-(void)calcFinalIncAmt
{
    double itemInPriceAfterDis;
    NSString *b4Discount;
    
    
    self.textSubTotal.text = [NSString stringWithFormat:@"%.02f",[self.textItemQty.text doubleValue] * [self.textItemPrice.text doubleValue]];
    b4Discount = [NSString stringWithFormat:@"%0.2f",([self.textItemQty.text doubleValue] * [self.textItemPrice.text doubleValue]) - [self.textDiscountAmt.text doubleValue]];
    itemInPriceAfterDis = ([b4Discount doubleValue]) / ((gst / 100)+1);
    
    
    self.textTotalTax.text = [NSString stringWithFormat:@"%.02f",[self.textSubTotal.text doubleValue] - [self.textDiscountAmt.text doubleValue] - itemInPriceAfterDis];
    self.textTotal.text = [NSString stringWithFormat:@"%0.2f",[self.textSubTotal.text doubleValue] - [self.textDiscountAmt.text doubleValue]];
    
    totalItemSellingAmt = itemInPriceAfterDis;
    totalItemTaxAmt = [self.textSubTotal.text doubleValue] - [self.textDiscountAmt.text doubleValue] - itemInPriceAfterDis;
    totalItemServiceTaxAmt = [[NSString stringWithFormat:@"%0.2f",itemInPriceAfterDis]doubleValue] * (serviceTaxRate / 100.0);
}

#pragma mark - click segment

- (IBAction)clickSegmentTakeAwayYN:(id)sender {
    switch (self.segmentTakeAwayYN.selectedSegmentIndex) {
        case 0:
            //serviceTaxRate = [[[editSalesArray objectAtIndex:0] objectForKey:@"IM_ServiceTaxRate"] doubleValue];
            [self getTableServiceChargeRate];
            break;
        case 1:
            serviceTaxRate = 0.00;
        default:
            break;
    }
    [self calcAmount];
}

- (IBAction)clickSegmentQty:(id)sender {
    
    switch (self.SegmentQtyBtn.selectedSegmentIndex) {
        case 0:
            self.textItemQty.text = [NSString stringWithFormat:@"%ld",[self.textItemQty.text integerValue] + 1];
            [self calcAmount];
            break;
        case 1:
            //if ([self.textItemQty.text integerValue] - 1 < 1) {
                //return;
            //}
            self.textItemQty.text = [NSString stringWithFormat:@"%ld",[self.textItemQty.text integerValue] - 1];
            [self calcAmount];
        default:
            break;
    }
    
    self.SegmentQtyBtn.selectedSegmentIndex = -1;
}

-(void)getTableServiceChargeRate
{
    
    dbTable = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTable open]) {
        NSLog(@"Fail To Open Database");
        return;
    }
    
    FMResultSet *rsTable = [dbTable executeQuery:@"Select TP_Name,TP_Percent, TP_Overide from TablePlan where TP_Name = ?",_tbName];
    
    if ([rsTable next]) {
        //selectedTableName = [rsTable stringForColumn:@"TP_Name"];
        if ([rsTable intForColumn:@"TP_Overide"] == 1) {
            if ([rsTable doubleForColumn:@"TP_Percent"] > 0.0) {
                //get service tax percent follow table
                
                serviceTaxRate = [rsTable doubleForColumn:@"TP_Percent"];
            }
            else if ([rsTable doubleForColumn:@"TP_Percent"] == 0.0) {
                serviceTaxRate = 0.00;
            }
            else
            {
                serviceTaxRate = 0.00;
            }
            [rsTable close];
        }
        else
        {
            [rsTable close];
            [self getItemDefaultServiceCharge];
            
        }
    }
    [dbTable close];
}

-(void)getItemDefaultServiceCharge
{
    dbTable = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTable open]) {
        NSLog(@"Fail To Open Database");
        return;
    }
    
    FMResultSet *rsItemSVG = [dbTable executeQuery:@"Select ItemMast.*, t1.T_Percent as T_Percent, t1.T_Name as T_Name, IFNULL(t2.T_Percent,'0') as Svc_Percent, t2.T_Name as Svc_Name from ItemMast "
                       "left join Tax t1 on ItemMast.IM_Tax = t1.T_Name "
                       " left join Tax t2 on ItemMast.IM_ServiceTax = t2.T_Name "
                       "where IM_ItemCode = ?",itemCode];
    
    if ([rsItemSVG next]) {
        if ([rsItemSVG doubleForColumn:@"Svc_Percent"] != 0.00) {
            serviceTaxRate = [rsItemSVG doubleForColumn:@"Svc_Percent"];
            
        }
        else
        {
            serviceTaxRate = 0.00;
            //textServiceTax = @"0.00";
        }
    }
    [dbTable close];
}

-(void)forceOrderDetailViewControllerCloseWithShowAllStatus:(NSString *)showAll PackageItemYN:(NSString *)packageItemYN
{
    if (_delegate != nil) {
        salesArray = nil;
        editSalesArray = nil;
        if ([packageItemYN isEqualToString:@"No"]) {
            [_delegate editAddConfimentViewWithPosition:_position ShowAll:showAll];
        }
        else{
            [_delegate editPackageItemWithPosition:_position];
        }
        
    }
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

- (IBAction)btnEditCondiment:(id)sender {
    
    __block int count = 0;
    __block NSString *packageItemYN;
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rsItem = [db executeQuery:@"Select IM_ServiceType from ItemMast where IM_ItemCode = ?",itemCode];
        
        if ([rsItem next]) {
            if ([[rsItem stringForColumn:@"IM_ServiceType"] isEqualToString:@"1"]) {
                packageItemYN = @"Yes";
            }
            else
            {
                packageItemYN = @"No";
                [rsItem close];
                
                FMResultSet *rs = [db executeQuery:@"Select * from ItemCondiment where IC_ItemCode = ?",itemCode];
                
                if (![rs next]) {
                    count = 0;
                }
                else
                {
                    count = 1;
                    
                }
                [rs close];
            }
        }
        
        
    }];
    [queue close];
    
    if (count == 0) {
        [self forceOrderDetailViewControllerCloseWithShowAllStatus:@"Yes" PackageItemYN:packageItemYN];
    }
    else
    {
        [self forceOrderDetailViewControllerCloseWithShowAllStatus:@"No" PackageItemYN:packageItemYN];
    }
    
}
@end
