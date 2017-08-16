//
//  DelTablePopUpViewController.m
//  IpadOrder
//
//  Created by IRS on 7/24/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "DelTablePopUpViewController.h"
#import "EditTableNameViewController.h"
#import "NumPadTextField/NumericKeypadTextField.h"
#import "NumericKeypadViewController.h"
#import "LibraryAPI.h"
#import <FMDB.h>

@interface DelTablePopUpViewController ()
{
    NSString *action;
    NSString *dbPath;
    FMDatabase *dbTable;
    //NSString *currentTableName;
    //float rotateCount;
    //NSString *tbImgName;
}
@end

@implementation DelTablePopUpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    bigBtn = @"Confirm";
    // Do any additional setup after loading the view from its nib.
    self.textTableName.text = _tbName;
    
    [self.btnUpdateTable1 addTarget:self action:@selector(updateTable1) forControlEvents:UIControlEventTouchUpInside];
    [self.btnUpdateTable2 addTarget:self action:@selector(updateTable2) forControlEvents:UIControlEventTouchUpInside];
    [self.btnUpdateTable3 addTarget:self action:@selector(updateTable3) forControlEvents:UIControlEventTouchUpInside];
    
    dbPath = [[LibraryAPI sharedInstance] getDbPath];
    
    self.textServiceCharge.delegate = self;
    self.textServiceCharge.numericKeypadDelegate = self;
    self.textServiceCharge.text = _tbPercent;
    self.segmentEditOverideSvg.selectedSegmentIndex = _tbOveride;
    self.segmentTableServeType.selectedSegmentIndex = _tbDineType;
    //self.textServiceCharge.text = _tbPercent;
    self.preferredContentSize = CGSizeMake(266, 380);
    
    //rotateCount = 0.0;
    [self.btnRotate.layer setBorderWidth:1.0];
    [self.btnRotate.layer setBorderColor:[UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0].CGColor];
    [self.btnRotate.layer setCornerRadius:5.0];
    [self.btnRotate addTarget:self action:@selector(rotateTableImage) forControlEvents:UIControlEventTouchUpInside];
    
    if (_tbOveride == 0) {
        self.textServiceCharge.enabled = NO;
    }
    else
    {
        self.textServiceCharge.enabled = YES;
    }
    
    if ([_tbSelectedImgName isEqualToString:@"Table1"]) {
        [self.btnUpdateTable1 setSelected:true];
        [self.btnUpdateTable2 setSelected:false];
        [self.btnUpdateTable3 setSelected:false];
    }
    else if([_tbSelectedImgName isEqualToString:@"Table2"])
    {
        [self.btnUpdateTable1 setSelected:false];
        [self.btnUpdateTable2 setSelected:true];
        [self.btnUpdateTable3 setSelected:false];
    }
    else if([_tbSelectedImgName isEqualToString:@"Table3"])
    {
        [self.btnUpdateTable1 setSelected:false];
        [self.btnUpdateTable2 setSelected:false];
        [self.btnUpdateTable3 setSelected:true];
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - highlight textfield
-(void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == self.textServiceCharge) {
        //this is textfield 2, so call your method here
        //[self.textPayAmt becomeFirstResponder];
        [self.textServiceCharge selectAll:nil];
    }
}

#pragma mark - custom keyboard delegate
-(void)saveActionFormTextField:(UITextField *)textField
{
    [textField resignFirstResponder];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)deleteTable:(id)sender {
    action = @"Delete";
    
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Warning"
                                 message:@"Sure To Delete ?"
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* yesButton = [UIAlertAction
                                actionWithTitle:@"OK"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
                                    [self delTableAlertActionSelection];
                                }];
    
    UIAlertAction* noButton = [UIAlertAction
                               actionWithTitle:@"Cancel"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   //Handle no, thanks button
                               }];
    
    [alert addAction:yesButton];
    [alert addAction:noButton];
    
    [self presentViewController:alert animated:YES completion:nil];
    
    /*
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning"
                                                    message:@"Sure To Delete ?"
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:@"Cancel",nil];
    [alert show];
     */
}


#pragma mark - alertview response
- (void)delTableAlertActionSelection
{
    if (![action isEqualToString:@"Non"]) {
        if ([action isEqualToString:@"Delete"]) {
            //if (buttonIndex == 0) {
                if (_delegate != nil) {
                    [_delegate delTableName:@"Delete" UpdatePercent:@"0.00" Overide:0 ImageName:@"-" DineType:0];
                }
            //}
        }
    }

    
}

- (IBAction)btnChangeTableName:(id)sender {
    
    
    if ([[self.textTableName.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0 || self.textTableName.text.length == 0)
    {
        [self showAlertView:@"Table name cannot empty" title:@"Warning"];
        return;
    }
    
    if (self.segmentEditOverideSvg.selectedSegmentIndex == 1) {
        if ([[self.textServiceCharge.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0 || self.textServiceCharge.text.length == 0)
        {
            [self showAlertView:@"Override percent cannot empty" title:@"Warning"];
            return;
        }
    }
    
    if (_delegate != nil) {
        
        if ([self checkTableNameDuplicate]) {
            [_delegate delTableName:self.textTableName.text UpdatePercent:self.textServiceCharge.text Overide:self.segmentEditOverideSvg.selectedSegmentIndex ImageName:_tbSelectedImgName DineType:self.segmentTableServeType.selectedSegmentIndex];
        }
        
        
    }
    
    /*
    action = @"Edit";
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning"
                                                    message:@"Sure To Update Table Name / SVG ?"
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:@"Cancel",nil];
    [alert show];
     */
}

- (IBAction)clickSegmentEditOverideSvg:(id)sender {
    switch (self.segmentEditOverideSvg.selectedSegmentIndex) {
        case 0:
            self.textServiceCharge.enabled = NO;
            self.textServiceCharge.text = @"";
            
            if (_segmentTableServeType.selectedSegmentIndex == 1) {
                self.segmentEditOverideSvg.selectedSegmentIndex = 1;
                self.textServiceCharge.enabled = YES;
            }
            
            break;
        case 1:
            self.textServiceCharge.enabled = YES;
            //[self.textServiceCharge becomeFirstResponder];
            break;
        default:
            break;
    }
}

-(void)rotateTableImage
{
    
    if (_tbAngle == 1.5) {
        _tbAngle = 0.0;
    }
    else
    {
        _tbAngle = _tbAngle + 0.5;
    }
    
    if (_delegate != nil) {
        //[_delegate showNewImageWithImgName:self.segmentSelectImage.selectedSegmentIndex Rotate:_tbAngle];
    }
}

#pragma mark - update table select

-(void)updateTable1
{
    _tbSelectedImgName = @"Table1";
    if (_delegate != nil) {
        [self.btnUpdateTable1 setSelected:true];
        [self.btnUpdateTable2 setSelected:false];
        [self.btnUpdateTable3 setSelected:false];
        [_delegate showNewImageWithImgName:_tbSelectedImgName Rotate:0 TableName:_tbName];
    }
}

-(void)updateTable2
{
    _tbSelectedImgName = @"Table2";
    if (_delegate != nil) {
        [self.btnUpdateTable1 setSelected:false];
        [self.btnUpdateTable2 setSelected:true];
        [self.btnUpdateTable3 setSelected:false];
        [_delegate showNewImageWithImgName:_tbSelectedImgName Rotate:0 TableName:_tbName];
    }
}

-(void)updateTable3
{
    _tbSelectedImgName = @"Table3";
    if (_delegate != nil) {
        [self.btnUpdateTable1 setSelected:false];
        [self.btnUpdateTable2 setSelected:false];
        [self.btnUpdateTable3 setSelected:true];
        [_delegate showNewImageWithImgName:_tbSelectedImgName Rotate:0 TableName:_tbName];
    }
}

#pragma mark - alertView

-(void)showAlertView:(NSString *)msg title:(NSString *)title
{
    action = @"Non";
    
    UIAlertController * alert = [[LibraryAPI sharedInstance] showAlertViewWithMsg:msg Title:title];
    
    [self presentViewController:alert animated:YES completion:nil];
    
    alert = nil;
}

- (IBAction)clickSegmentEditServeType:(id)sender {
    switch (self.segmentTableServeType.selectedSegmentIndex) {
        case 0:
            self.textServiceCharge.enabled = NO;
            self.textServiceCharge.text = @"";
            self.segmentEditOverideSvg.selectedSegmentIndex = 0;
            break;
        case 1:
            self.textServiceCharge.enabled = YES;
            self.textServiceCharge.text = @"0";
            self.segmentEditOverideSvg.selectedSegmentIndex = 1;
            //[self.textServiceCharge becomeFirstResponder];
            break;
        default:
            break;
    }
}

-(BOOL)checkTableNameDuplicate
{
    if (![_tbName isEqualToString:self.textTableName.text]) {
        dbTable = [FMDatabase databaseWithPath:dbPath];
        
        if (![dbTable open]) {
            NSLog(@"Fail To Open Db");
            return false;
        }
        
        FMResultSet *rs = [dbTable executeQuery:@"Select * from TablePlan where TP_Name = ?", self.textTableName.text];
        
        if ([rs next]) {
            [self showAlertView:@"Table name exist." title:@"Warning"];
            [rs close];
            [dbTable close];
            return false;
            
        }
        else
        {
            [rs close];
            [dbTable close];
            return true;
        }
        
        
    }
    else
    {
        return true;
    }
}



@end
