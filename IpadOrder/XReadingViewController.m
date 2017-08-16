//
//  XReadingViewController.m
//  IpadOrder
//
//  Created by IRS on 9/14/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "XReadingViewController.h"
#import "XReadingReportViewController.h"

@interface XReadingViewController ()
//@property (nonatomic, strong)UIPopoverController *popOverDate;
@end

@implementation XReadingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.textXReadingDateFrom.delegate = self;
    self.textXReadingDateTo.delegate = self;
    
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"dd/MMM/yyyy"];
    NSString *dateString = [dateFormat stringFromDate:today];
    
    self.textXReadingDateFrom.text = dateString;
    [dateFormat setDateFormat:@"dd/MMM/yyyy"];
    NSString *dateString2 = [dateFormat stringFromDate:today];
    self.textXReadingDateTo.text = dateString2;
    
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    
    //self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:34/255.0 green:171/255.0 blue:241/255.0 alpha:1.0];
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0];
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    self.viewRptXReadBg.layer.cornerRadius = 10.0;
    self.viewRptXReadBg.layer.masksToBounds = YES;
    
    /*
    UIGraphicsBeginImageContext(self.view.frame.size);
    [[UIImage imageNamed:@"IO_Background1024"] drawInRect:self.view.bounds];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:image];
    */
    [self setTitle:@"X Reading"];
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
        datePickerViewController.popoverPresentationController.sourceRect = CGRectMake(self.textXReadingDateFrom.frame.size.width /
                                                                                       2, self.textXReadingDateFrom.frame.size.height / 2, 1, 1);
        datePickerViewController.popoverPresentationController.sourceView = self.textXReadingDateFrom;
        datePickerViewController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionLeft;
        
        [self presentViewController:datePickerViewController animated:YES completion:nil];
        /*
        [self.popOverDate presentPopoverFromRect:CGRectMake(self.textXReadingDateFrom.frame.size.width /
                                                                  2, self.textXReadingDateFrom.frame.size.height / 2, 1, 1) inView:self.textXReadingDateFrom permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
         */
    }
    else if (textField.tag == 1)
    {
        [self.view endEditing:YES];
        datePickerViewController.textType = @"XDate2";
        
        datePickerViewController.modalPresentationStyle = UIModalPresentationPopover;
        datePickerViewController.popoverPresentationController.sourceRect = CGRectMake(self.textXReadingDateTo.frame.size.width /
                                                                                       2, self.textXReadingDateTo.frame.size.height / 2, 1, 1);
        datePickerViewController.popoverPresentationController.sourceView = self.textXReadingDateTo;
        datePickerViewController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionLeft;
        
        [self presentViewController:datePickerViewController animated:YES completion:nil];
        /*
        [self.popOverDate presentPopoverFromRect:CGRectMake(self.textXReadingDateTo.frame.size.width /
                                                                  2, self.textXReadingDateTo.frame.size.height / 2, 1, 1) inView:self.textXReadingDateTo permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
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
        self.textXReadingDateFrom.text = dateValue;
    }
    else if ([textName isEqualToString:@"XDate2"])
    {
        self.textXReadingDateTo.text = dateValue;
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

- (IBAction)btnXReadingSearch:(id)sender {
    XReadingReportViewController *xReadingReportViewController = [[XReadingReportViewController alloc]init];
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"dd/MMM/yyyy"];
    NSDate *dateFrom = [dateFormat dateFromString:self.textXReadingDateFrom.text];
    NSDate *dateTo = [dateFormat dateFromString:self.textXReadingDateTo.text];
    
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    NSString *dateString1 = [dateFormat stringFromDate:dateFrom];
    NSString *dateString2 = [dateFormat stringFromDate:dateTo];
    
    xReadingReportViewController.xReadingDateFrom = dateString1;
    xReadingReportViewController.xReadingDateTo = dateString2;
    
    xReadingReportViewController.xReadingDateFromDisplay = self.textXReadingDateFrom.text;
    xReadingReportViewController.xReadingDateToDisplay = self.textXReadingDateTo.text;
    [self.navigationController pushViewController:xReadingReportViewController animated:YES];
}
@end
