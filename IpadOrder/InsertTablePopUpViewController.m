//
//  InsertTablePopUpViewController.m
//  IpadOrder
//
//  Created by IRS on 7/23/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "InsertTablePopUpViewController.h"
#import "LibraryAPI.h"
#import <FMDB.h>
#import "NumPadTextField/NumericKeypadTextField.h"
#import "NumericKeypadViewController.h"

@interface InsertTablePopUpViewController ()
{
    NSString *dbPath;
    FMDatabase *dbTable;
    NSString *tableImgName;
}
@end

@implementation InsertTablePopUpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    tableImgName = @"Table1";
    // Do any additional setup after loading the view from its nib.
    self.textPercent.numericKeypadDelegate = self;
    self.textPercent.delegate = self;
    bigBtn = @"Confirm";
    dbPath = [[LibraryAPI sharedInstance] getDbPath];
    self.preferredContentSize = CGSizeMake(263, 377);
    
    [self.btnTable1 addTarget:self action:@selector(btnSelectTable1:) forControlEvents:UIControlEventTouchUpInside];
    [self.btnTable2 addTarget:self action:@selector(btnSelectTable2:) forControlEvents:UIControlEventTouchUpInside];
    [self.btnTable3 addTarget:self action:@selector(btnSelectTable3:) forControlEvents:UIControlEventTouchUpInside];
    [self.btnCancelAddTable addTarget:self action:@selector(btnCancelAddTableView) forControlEvents:UIControlEventTouchUpInside];
    [self.btnTable1 setSelected:true];
    //[self getDefaultServiceCharge];
    self.textPercent.enabled = NO;
    self.segmentDineType.selectedSegmentIndex = 0;
    [self.tbName becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - highlight textfield
-(void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == self.textPercent) {
        //this is textfield 2, so call your method here
        //[self.textPayAmt becomeFirstResponder];
        [self.textPercent selectAll:nil];
    }
}

#pragma mark - custom keyboard delegate
-(void)saveActionFormTextField:(UITextField *)textField
{
    [textField resignFirstResponder];
}

#pragma mark - uipopover delegate
/*
-(BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
    return NO;
}
 */
-(BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
    return NO;
}

#pragma mark - delegate


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(void)btnCancelAddTableView
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)btnSaveTableClick:(id)sender {
    
    if ([[self.tbName.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0 || self.tbName.text.length == 0)
    {
        [self showAlertView:@"Table name cannot empty" title:@"Warning"];
        return;
    }
    /*
    if ([[self.tbName.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0 || self.tbName.text.length == 0)
    {
        [self showAlertView:@"Table Name Cannot Empty" title:@"Warning"];
        return;
    }
     */
    
    if (self.segmentOveride.selectedSegmentIndex == 1) {
        if ([[self.textPercent.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0 || self.textPercent.text.length == 0)
        {
            [self showAlertView:@"Overide percent cannot empty" title:@"Warning"];
            return;
        }
    }
    
    
    if (_delegate != nil) {
        [_delegate saveTableName:self.tbName.text Percent:self.textPercent.text Overide:self.segmentOveride.selectedSegmentIndex ImgName:tableImgName DineType:self.segmentDineType.selectedSegmentIndex];
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

#pragma mark - sqlite

-(void)getDefaultServiceCharge
{
    dbTable = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTable open]) {
        NSLog(@"Fail To Open Db");
        return;
    }
    
    FMResultSet *rs = [dbTable executeQuery:@"Select * from Tax where T_Name = ?", @"SVC"];
    
    if ([rs next]) {
        self.textPercent.text = [NSString stringWithFormat:@"%.2f",[rs doubleForColumn:@"T_Percent"]];
    }
    
    [rs close];
    [dbTable close];
}

#pragma mark - segment click

- (IBAction)segmentOverideClick:(id)sender {
    switch (self.segmentOveride.selectedSegmentIndex) {
        case 0:
            self.textPercent.enabled = NO;
            self.textPercent.text = @"";
            
            if (_segmentDineType.selectedSegmentIndex == 1) {
                self.segmentOveride.selectedSegmentIndex = 1;
                self.textPercent.enabled = YES;
            }
            
            break;
        case 1:
            self.textPercent.enabled = YES;
            [self.textPercent becomeFirstResponder];
            break;
        default:
            break;
    }
}

- (IBAction)btnSelectTable1:(id)sender {
    tableImgName = @"Table1";
    [self.btnTable1 setSelected:true];
    [self.btnTable2 setSelected:false];
    [self.btnTable3 setSelected:false];
}

- (IBAction)btnSelectTable2:(id)sender {
    tableImgName = @"Table2";
    [self.btnTable1 setSelected:false];
    [self.btnTable2 setSelected:true];
    [self.btnTable3 setSelected:false];
}

- (IBAction)btnSelectTable3:(id)sender {
    tableImgName = @"Table3";
    [self.btnTable1 setSelected:false];
    [self.btnTable2 setSelected:false];
    [self.btnTable3 setSelected:true];
}
- (IBAction)segmentDineTypeClick:(id)sender {
    switch (self.segmentDineType.selectedSegmentIndex) {
        case 0:
            self.textPercent.enabled = NO;
            self.textPercent.text = @"";
            self.segmentOveride.selectedSegmentIndex = 0;
            break;
        case 1:
            self.textPercent.text = @"0";
            self.textPercent.enabled = YES;
            self.segmentOveride.selectedSegmentIndex = 1;
            break;
        default:
            break;
    }
}
@end
