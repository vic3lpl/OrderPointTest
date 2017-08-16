//
//  CondimentDetailViewController.m
//  IpadOrder
//
//  Created by IRS on 03/09/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import "CondimentDetailViewController.h"
#import "LibraryAPI.h"
#import <FMDB.h>
#import "NumPadTextField/NumericKeypadTextField.h"
#import "NumericKeypadViewController.h"

@interface CondimentDetailViewController ()
{
    FMDatabase *dbTable;
    NSString *dbPath;
    NSString *chCode;
    NSMutableDictionary *condimentDtlDict;
}
//@property(nonatomic,strong)UIPopoverController *popOver;
@end

@implementation CondimentDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    dbPath = [[LibraryAPI sharedInstance] getDbPath];
    
    self.navigationController.navigationBar.hidden = TRUE;
    self.navigationController.navigationBar.translucent = NO;
    
    self.preferredContentSize = CGSizeMake(401, 250);
    
    // Do any additional setup after loading the view from its nib.
    //self.textCondimentGroup.delegate = self;
    self.textCondimentPrice.numericKeypadDelegate = self;
    self.textCondimentPrice.delegate = self;
    //self.textCondimentPrice.delegate = self;
    bigBtn = @"Done";
    
    if ([_cdAction isEqualToString:@"Edit"]) {
        [self getCondimentDetail];
        self.textCondimentCode.enabled = false;
    }
    else
    {
        [self.textCondimentCode becomeFirstResponder];
        self.textCondimentPrice.text = @"0.00";
    }
    
}

#pragma mark - NumberPadDelegate
-(void)saveActionFormTextField:(UITextField *)textField
{
    [textField resignFirstResponder];
}

#pragma mark - sqlite
-(void)getCondimentDetail
{
    
    self.textCondimentCode.text = _cdCode;
    self.textCondimentDesc.text = _cdDescription;
    self.textCondimentPrice.text = [NSString stringWithFormat:@"%0.2f",[_cdPrice doubleValue]];
    
    /*
    dbTable = [FMDatabase databaseWithPath:dbPath];
    
    //BOOL dbHadError;
    
    if (![dbTable open]) {
        NSLog(@"Fail To Open");
        return;
    }
    
    FMResultSet *rs = [dbTable executeQuery:@"Select * from CondimentDtl cd left join CondimentHdr ch on cd.CD_CondimentHdrCode = ch.CH_Code where CD_Code = ?",_cdCode];
    
    if ([rs next]) {
        self.textCondimentCode.text = [rs stringForColumn:@"CD_Code"];
        self.textCondimentDesc.text = [rs stringForColumn:@"CD_Description"];
        self.textCondimentPrice.text = [NSString stringWithFormat:@"%0.2f",[[rs stringForColumn:@"CD_Price"] doubleValue]];
        //self.textCondimentGroup.text = [rs stringForColumn:@"CH_Description"];
        chCode = [rs stringForColumn:@"CD_CondimentHdrCode"];
    }
    
    [rs close];
    [dbTable close];
     */
}

-(void)saveCondimentDtl
{
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rsCheck = [db executeQuery:@"Select * from CondimentDtl where CD_Code = ?",self.textCondimentCode.text];
        
        if ([rsCheck next]) {
            [self showAlertView:@"Condiment code duplicate" title:@"Warning"];
            return;
        }
        [rsCheck close];
        
        [db executeUpdate:@"Insert into CondimentDtl (CD_Code, CD_Description, CD_Price, CD_CondimentHdrCode) values (?,?,?,?)",self.textCondimentCode.text,self.textCondimentDesc.text,self.textCondimentPrice.text,chCode];
        
        if ([db hadError]) {
            [self showAlertView:[db lastErrorMessage] title:@"Fail"];
            return;
        }
        else
        {
            [self.navigationController popViewControllerAnimated:NO];
        }
        
    }];
    [queue close];
}

-(void)editCondimentDtlHdr
{
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        [db executeUpdate:@"Update CondimentDtl set CD_Description = ?, CD_Price = ?, CD_CondimentHdrCode = ? where CD_Code = ?",self.textCondimentDesc.text,self.textCondimentPrice.text,chCode,self.textCondimentCode.text];
        
        if ([db hadError]) {
            [self showAlertView:[db lastErrorMessage] title:@"Fail"];
            return;
        }
        else
        {
            [self.navigationController popViewControllerAnimated:NO];
        }
        
    }];
    [queue close];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - all delegate is here
-(void)getSelectedCategory:(NSString *)field1 field2:(NSString *)field2 field3:(NSString *)field3 filterType:(NSString *)filterType
{
    chCode = field1;
    //self.textCondimentGroup.text = field3;
    //[self.popOver dismissPopoverAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - show alertview
-(void)showAlertView:(NSString *)msg title:(NSString *)title
{
    UIAlertController * alert = [[LibraryAPI sharedInstance] showAlertViewWithMsg:msg Title:title];
    
    [self presentViewController:alert animated:YES completion:nil];
    
}

#pragma mark - touch background
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

#pragma mark - highlight textfield
-(void)textFieldDidBeginEditing:(UITextField *)textField {
    
    [textField selectAll:nil];
    
}

#pragma mark - check field
-(BOOL)checkTextField
{
    if ([self.textCondimentCode.text isEqualToString:@""]) {
        [self showAlertView:@"Condiment code cannot empty" title:@"Warning"];
        return NO;
    }
    else if ([self.textCondimentDesc.text isEqualToString:@""])
    {
        [self showAlertView:@"Condiment description cannot empty" title:@"Warning"];
        return NO;
    }
    else if ([self.textCondimentPrice.text isEqualToString:@""])
    {
        [self showAlertView:@"Condiment price cannot empty" title:@"Warning"];
        return NO;
    }
    else
    {
        return YES;
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)btnOKCondimentDtlClick:(id)sender {
    if ([[LibraryAPI sharedInstance]getUserRole] == 0) {
        [self showAlertView:@"You have no permission to edit data" title:@"Warning"];
        return;
    }
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    [dict setObject:self.textCondimentCode.text forKey:@"CD_Code"];
    [dict setObject:self.textCondimentDesc.text forKey:@"CD_Description"];
    [dict setObject:self.textCondimentPrice.text forKey:@"CD_Price"];
    //[dict setObject:_cdCode forKey:@"CD_OldHdrCode"];
    //[dict setObject:_condimentHdrCode forKey:@"CD_CondimentHdrCode"];
    
    if ([self checkTextField]) {
        if (_delegate != nil) {
            [_delegate passbackCondimentDetailAray:dict Status:_cdAction];
            dict = nil;
        }
    }
}

- (IBAction)btnCancelCondimentDtlClick:(id)sender {
    [self.navigationController dismissViewControllerAnimated:NO completion:nil];
}
@end
