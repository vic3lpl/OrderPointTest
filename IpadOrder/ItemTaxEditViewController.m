//
//  ItemTaxEditViewController.m
//  IpadOrder
//
//  Created by IRS on 7/10/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "ItemTaxEditViewController.h"
#import <FMDB.h>
#import "LibraryAPI.h"
#import "NumPadTextField/NumericKeypadTextField.h"
#import "NumericKeypadViewController.h"
//#import "TestScrollViewController.h"

//static NSUInteger kNumberOfPages = 10;
@interface ItemTaxEditViewController ()
{
    NSString *dbPath;
    FMDatabase *dbTax;
    BOOL dbHadError;
}

@end

NSString *bigBtn;
@implementation ItemTaxEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    UIBarButtonItem *addBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(editTax:)];
    self.navigationItem.rightBarButtonItem = addBtn;
    bigBtn = @"Done";
    self.textTaxPercent.numericKeypadDelegate = self;
    self.textTaxPercent.delegate = self;
    dbPath = [[LibraryAPI sharedInstance]getDbPath];
    //[self createScrollMenu];
    self.viewTaxBg.layer.cornerRadius = 20.0;
    self.viewTaxBg.layer.masksToBounds = YES;
    //
    
    [self getOneTax];
}

-(void)editTax:(id)sender
{
    if ([[LibraryAPI sharedInstance]getUserRole] == 0) {
        [self showAlertView:@"You have no permission to edit data" title:@"Warning"];
        return;
    }
    
    BOOL checkEmpty = [self checkTextField];
    
    if (!checkEmpty) {
        return;
    }
    
    if ([self.userTaxAction isEqualToString:@"New"]) {
        [self saveTax];
    }
    else
    {
        [self UpdateTax];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - sqlite

-(void)getOneTax
{
    dbTax = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTax open]) {
        NSLog(@"Fail To Open Db");
        return;
    }
    
    FMResultSet *rs = [dbTax executeQuery:@"Select * from Tax where T_Name = ?", self.taxName];
    
    if ([rs next]) {
        self.textTaxName.enabled = NO;
        self.textTaxName.text = [rs stringForColumn:@"T_Name"];
        self.textTaxDesc.text = [rs stringForColumn:@"T_Description"];
        self.textTaxPercent.text = [NSString stringWithFormat:@"%.2f",[[rs stringForColumn:@"T_Percent"] doubleValue]];
        self.textAccTaxCode.text = [rs stringForColumn:@"T_AccTaxCode"];
    }
    
    [rs close];
    [dbTax close];
    
}

-(void)saveTax
{
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"Select * from Tax where T_Name = ?",[self.textTaxName.text uppercaseString]];
                           
        if ([rs next]) {
            [rs close];
            [self showAlertView:@"Tax code duplicate" title:@"Information"];
            return;
        }
        [rs close];
        
        [db executeUpdate:@"insert into Tax (T_Name, T_Description, T_Percent, T_AccTaxCode) values (?,?,?,?)",self.textTaxName.text,self.textTaxDesc.text,self.textTaxPercent.text,self.textAccTaxCode.text];
        
        if (![db hadError]) {
            //[self showAlertView:@"Data Save" title:@"Success"];
            [self.navigationController popViewControllerAnimated:YES];
        }
        else
        {
            [self showAlertView:[dbTax lastErrorMessage] title:@"Error"];
        }
    }];
    
    
    
}

-(void)UpdateTax
{
    dbTax = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTax open]) {
        NSLog(@"Fail To Open Db");
        return;
    }
    
    dbHadError = [dbTax executeUpdate:@"update Tax set T_Name = ?, T_Description = ?, T_Percent = ?, T_AccTaxCode = ? where T_Name = ?",self.textTaxName.text,self.textTaxDesc.text,self.textTaxPercent.text,self.textAccTaxCode.text,self.taxName];
    
    if (dbHadError) {
        //[self showAlertView:@"Data Save" title:@"Success"];
        [self.navigationController popViewControllerAnimated:YES];
    }
    else
    {
        [self showAlertView:[dbTax lastErrorMessage] title:@"Error"];
    }
    
    [dbTax close];
}

#pragma mark - NumberPadDelegate
-(void)saveActionFormTextField:(UITextField *)textField
{
    [textField resignFirstResponder];
    NSLog(@"Password is %@",textField.text);
}


#pragma mark - alertView

-(void)showAlertView:(NSString *)msg title:(NSString *)title
{
    /*
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:msg
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
     */
    UIAlertController * alert = [[LibraryAPI sharedInstance] showAlertViewWithMsg:msg Title:title];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - check empty field

-(BOOL)checkTextField
{
    if ([self.textTaxName.text isEqualToString:@""]) {
        [self showAlertView:@"Tax cannot empty" title:@"Warning"];
        return NO;
    }
    else if ([self.textTaxDesc.text isEqualToString:@""])
    {
        [self showAlertView:@"Description cannot empty" title:@"Warning"];
        return NO;
    }
    else if ([self.textTaxPercent.text isEqualToString:@""])
    {
        [self showAlertView:@"Percent cannot empty" title:@"Warning"];
        return NO;
    }
    
    return  YES;
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

/*
- (void)createScrollMenu
{
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(13, 278, 665, 463)];
    
    int x = 0;
    for (int i = 0; i < 8; i++) {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(x, 0, 100, 100)];
        [button setTitle:[NSString stringWithFormat:@"Button %d", i] forState:UIControlStateNormal];
        
        [scrollView addSubview:button];
        
        x += button.frame.size.width;
    }
    
    scrollView.contentSize = CGSizeMake(x, scrollView.frame.size.height);
    scrollView.backgroundColor = [UIColor redColor];
    
    [self.view addSubview:scrollView];
}
 */

@end
