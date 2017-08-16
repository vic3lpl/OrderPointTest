//
//  ReprotDetailViewController.m
//  IpadOrder
//
//  Created by IRS on 9/9/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "ReprotDetailViewController.h"
#import "InvoiceListingViewController.h"

@interface ReprotDetailViewController ()
{
    NSString *newDateFormat;
}
@end

@implementation ReprotDetailViewController
@synthesize detailStruct;
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.textInvoiceDateFrom.delegate = self;
    self.textInvoiceDateTo.delegate = self;
    
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"dd/MMM/yyyy"];
    NSString *dateString = [dateFormat stringFromDate:today];
    
    self.textInvoiceDateFrom.text = dateString;
    [dateFormat setDateFormat:@"dd/MMM/yyyy"];
    NSString *dateString2 = [dateFormat stringFromDate:today];
    self.textInvoiceDateTo.text = dateString2;
    
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    
    //self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:34/255.0 green:171/255.0 blue:241/255.0 alpha:1.0];
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.translucent = NO;
    
    self.viewRptInvListingBg.layer.cornerRadius = 10.0;
    self.viewRptInvListingBg.layer.masksToBounds = YES;
    /*
    UIGraphicsBeginImageContext(self.view.frame.size);
    [[UIImage imageNamed:@"IO_Background1024"] drawInRect:self.view.bounds];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:image];
    */
    [self setTitle:@"Invoice Listing"];
    
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
    //self.popoverController = [[UIPopoverController alloc]initWithContentViewController:datePickerViewController];
    
    if (textField.tag == 1) {
        [self.view endEditing:YES];
        datePickerViewController.textType = @"InvDate1";
        
        datePickerViewController.modalPresentationStyle = UIModalPresentationPopover;
        datePickerViewController.popoverPresentationController.sourceRect = CGRectMake(self.textInvoiceDateFrom.frame.size.width /
                                                                                       2, self.textInvoiceDateFrom.frame.size.height / 2, 1, 1);
        datePickerViewController.popoverPresentationController.sourceView = self.textInvoiceDateFrom;
        datePickerViewController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionLeft;
        
        [self presentViewController:datePickerViewController animated:YES completion:nil];
        
        /*
        [self.popoverController presentPopoverFromRect:CGRectMake(self.textInvoiceDateFrom.frame.size.width /
                                                                  2, self.textInvoiceDateFrom.frame.size.height / 2, 1, 1) inView:self.textInvoiceDateFrom permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
         */
    }
    else if (textField.tag == 2)
    {
        [self.view endEditing:YES];
        datePickerViewController.textType = @"InvDate2";
        
        datePickerViewController.modalPresentationStyle = UIModalPresentationPopover;
        datePickerViewController.popoverPresentationController.sourceRect = CGRectMake(self.textInvoiceDateTo.frame.size.width /
                                                                                       2, self.textInvoiceDateTo.frame.size.height / 2, 1, 1);
        datePickerViewController.popoverPresentationController.sourceView = self.textInvoiceDateTo;
        datePickerViewController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionLeft;
        
        [self presentViewController:datePickerViewController animated:YES completion:nil];
        
        /*
        [self.popoverController presentPopoverFromRect:CGRectMake(self.textInvoiceDateTo.frame.size.width /
                                                                  2, self.textInvoiceDateTo.frame.size.height / 2, 1, 1) inView:self.textInvoiceDateTo permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
         */
    }
    else
    {
        [self.view endEditing:NO];
    }
    
    return NO;
    
}

#pragma mark - datepicker delegate
-(void)getDatePickerDateValue:(NSString *)dateValue returnTextName:(NSString *)textName
{
    if ([textName isEqualToString:@"InvDate1"]) {
        self.textInvoiceDateFrom.text = dateValue;
    }
    else if ([textName isEqualToString:@"InvDate2"])
    {
        self.textInvoiceDateTo.text = dateValue;
    }
    
    //[self.popoverController dismissPopoverAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

/*
- (void)splitViewController:(UISplitViewController*)svc
     willHideViewController:(UIViewController *)aViewController
          withBarButtonItem:(UIBarButtonItem*)barButtonItem
       forPopoverController:(UIPopoverController*)pc
{
    
    [barButtonItem setTitle:@"Structures"];
    [[self navigationItem] setLeftBarButtonItem:barButtonItem];
    [self setPopoverController:pc];
}


- (void)splitViewController:(UISplitViewController*)svc
     willShowViewController:(UIViewController *)aViewController
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    [[self navigationItem] setLeftBarButtonItem:nil];
    [self setPopoverController:nil];
}
*/

- (IBAction)btnSearchInvListing:(id)sender {
    InvoiceListingViewController *invoiceListingViewController = [[InvoiceListingViewController alloc]init];
    
    // Convert string to date object
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"dd/MMM/yyyy"];
    NSDate *dateFrom = [dateFormat dateFromString:self.textInvoiceDateFrom.text];
    NSDate *dateTo = [dateFormat dateFromString:self.textInvoiceDateTo.text];
    
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    NSString *dateString1 = [dateFormat stringFromDate:dateFrom];
    NSString *dateString2 = [dateFormat stringFromDate:dateTo];
    
    invoiceListingViewController.invListingDateFrom = dateString1;
    invoiceListingViewController.invListingDateTo = dateString2;
    invoiceListingViewController.invListingDateFromDisplay = self.textInvoiceDateFrom.text;
    invoiceListingViewController.invListingDateToDisplay = self.textInvoiceDateTo.text;
    [self.navigationController pushViewController:invoiceListingViewController animated:YES];
}
@end
