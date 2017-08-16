//
//  VoidReportViewController.m
//  IpadOrder
//
//  Created by IRS on 11/05/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import "VoidReportViewController.h"
#import "VoidReportListingViewController.h"

@interface VoidReportViewController ()
//@property (nonatomic, strong)UIPopoverController *popOverDate;
@end

@implementation VoidReportViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.textVoidReportDateFrom.delegate = self;
    self.textVoidReportDateTo.delegate = self;
    
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"dd/MMM/yyyy"];
    NSString *dateString = [dateFormat stringFromDate:today];
    
    self.textVoidReportDateFrom.text = dateString;
    [dateFormat setDateFormat:@"dd/MMM/yyyy"];
    NSString *dateString2 = [dateFormat stringFromDate:today];
    self.textVoidReportDateTo.text = dateString2;
    
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0];
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    self.viewVoidReport.layer.cornerRadius = 10.0;
    self.viewVoidReport.layer.masksToBounds = YES;
    
    [self setTitle:@"Void Report"];
    
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
    //self.popOverDate = [[UIPopoverController alloc]initWithContentViewController:datePickerViewController];
    
    if (textField.tag == 0) {
        [self.view endEditing:YES];
        datePickerViewController.textType = @"XDate1";
        
        datePickerViewController.modalPresentationStyle = UIModalPresentationPopover;
        datePickerViewController.popoverPresentationController.sourceRect = CGRectMake(self.textVoidReportDateFrom.frame.size.width /
                                                                                       2, self.textVoidReportDateFrom.frame.size.height / 2, 1, 1);
        datePickerViewController.popoverPresentationController.sourceView = self.textVoidReportDateFrom;
        datePickerViewController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionLeft;
        
        [self presentViewController:datePickerViewController animated:YES completion:nil];
        
        /*
        [self.popOverDate presentPopoverFromRect:CGRectMake(self.textVoidReportDateFrom.frame.size.width /
                                                            2, self.textVoidReportDateFrom.frame.size.height / 2, 1, 1) inView:self.textVoidReportDateFrom permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
         */
    }
    else if (textField.tag == 1)
    {
        [self.view endEditing:YES];
        datePickerViewController.textType = @"XDate2";
        
        datePickerViewController.modalPresentationStyle = UIModalPresentationPopover;
        datePickerViewController.popoverPresentationController.sourceRect = CGRectMake(self.textVoidReportDateFrom.frame.size.width /
                                                                                       2, self.textVoidReportDateTo.frame.size.height / 2, 1, 1);
        datePickerViewController.popoverPresentationController.sourceView = self.textVoidReportDateTo;
        datePickerViewController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionLeft;
        
        [self presentViewController:datePickerViewController animated:YES completion:nil];
        
        /*
        [self.popOverDate presentPopoverFromRect:CGRectMake(self.textVoidReportDateTo.frame.size.width /
                                                            2, self.textVoidReportDateTo.frame.size.height / 2, 1, 1) inView:self.textVoidReportDateTo permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
         */
    }
    else
    {
        [self.view endEditing:NO];
    }
    
    return NO;
    
}

#pragma mark - delegate methof

-(void)getDatePickerDateValue:(NSString *)dateValue returnTextName:(NSString *)textName
{
    if ([textName isEqualToString:@"XDate1"]) {
        self.textVoidReportDateFrom.text = dateValue;
    }
    else if ([textName isEqualToString:@"XDate2"])
    {
        self.textVoidReportDateTo.text = dateValue;
    }
    
    //[self.popOverDate dismissPopoverAnimated:YES];
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

- (IBAction)btnVoidReportSearch:(id)sender {
    VoidReportListingViewController *voidReportListingViewController = [[VoidReportListingViewController alloc]init];
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"dd/MMM/yyyy"];
    NSDate *dateFrom = [dateFormat dateFromString:self.textVoidReportDateFrom.text];
    NSDate *dateTo = [dateFormat dateFromString:self.textVoidReportDateTo.text];
    
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    NSString *dateString1 = [dateFormat stringFromDate:dateFrom];
    NSString *dateString2 = [dateFormat stringFromDate:dateTo];
    
    voidReportListingViewController.voidReasonDateFrom = dateString1;
    voidReportListingViewController.voidReasonDateTo = dateString2;
    
    voidReportListingViewController.voidReasonDateFromDisplay = self.textVoidReportDateFrom.text;
    voidReportListingViewController.voidReasonDateToDisplay = self.textVoidReportDateTo.text;
    
    //voidReportListingViewController.xReadingDateFromDisplay = self.textXReadingDateFrom.text;
    //voidReportListingViewController.xReadingDateToDisplay = self.textXReadingDateTo.text;
    [self.navigationController pushViewController:voidReportListingViewController animated:YES];
}
@end
