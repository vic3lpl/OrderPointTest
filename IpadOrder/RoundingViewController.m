//
//  RoundingViewController.m
//  IpadOrder
//
//  Created by IRS on 9/17/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "RoundingViewController.h"
#import "NumPadTextField/NumericKeypadTextField.h"
#import "NumericKeypadViewController.h"
#import <FMDB.h>
#import "LibraryAPI.h"
#import <MBProgressHUD.h>

@interface RoundingViewController ()
{
    NSString *dbPath;
    NSMutableArray *roudingArray;
    FMDatabase *dbTable;
    NSString *terminalType;
    
}
@end

@implementation RoundingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    dbPath = [[LibraryAPI sharedInstance]getDbPath];
    self.r1.numericKeypadDelegate = self;
    self.r2.numericKeypadDelegate = self;
    self.r3.numericKeypadDelegate = self;
    self.r4.numericKeypadDelegate = self;
    self.r5.numericKeypadDelegate = self;
    self.r6.numericKeypadDelegate = self;
    self.r7.numericKeypadDelegate = self;
    self.r8.numericKeypadDelegate = self;
    self.r9.numericKeypadDelegate = self;
    
    self.r1.delegate = self;
    self.r2.delegate = self;
    self.r3.delegate = self;
    self.r4.delegate = self;
    self.r5.delegate = self;
    self.r6.delegate = self;
    self.r7.delegate = self;
    self.r8.delegate = self;
    self.r9.delegate = self;
    self.title = @"Rounding";
    bigBtn = @"Confirm";
    terminalType = [[LibraryAPI sharedInstance] getWorkMode];
    UIBarButtonItem *addBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(editRounding)];
    self.navigationItem.rightBarButtonItem = addBtn;
    
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    //self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:34/255.0 green:171/255.0 blue:241/255.0 alpha:1.0];
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.translucent = NO;
    
    self.viewRoundBg.layer.cornerRadius = 20.0;
    self.viewRoundBg.layer.masksToBounds = YES;
    
    /*
    UIGraphicsBeginImageContext(self.view.frame.size);
    [[UIImage imageNamed:@"IO_Background1024"] drawInRect:self.view.bounds];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:image];
    */
    [self getRoundingData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - highlight textfield
-(void)textFieldDidBeginEditing:(UITextField *)textField {
    
    //this is textfield 2, so call your method here
    //[self.textPayAmt becomeFirstResponder];
    [textField selectAll:nil];
    
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

#pragma mark - NumberPadDelegate
-(void)saveActionFormTextField:(UITextField *)textField
{
    textField.text = [NSString stringWithFormat:@"%ld",[textField.text integerValue]];
    [textField resignFirstResponder];
    
}

#pragma mark - sqlite3
-(void)getRoundingData
{
    dbTable = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTable open]) {
        NSLog(@"Fail To Open");
        return;
    }
    
    FMResultSet *rs = [dbTable executeQuery:@"Select * from Rounding"];
    //category = [NSMutableArray array];
    if ([dbTable hadError]) {
        [self showAlertView:[dbTable lastErrorMessage] title:@"Fail"];
        return;
    }
    
    if ([rs next]) {
        
        //self.switchItemHot.on = [rs intForColumn:@"IM_Favorite"];
        self.r1.text = [rs stringForColumn:@"R1"];
        self.r2.text = [rs stringForColumn:@"R2"];
        self.r3.text = [rs stringForColumn:@"R3"];
        self.r4.text = [rs stringForColumn:@"R4"];
        self.r5.text = [rs stringForColumn:@"R5"];
        self.r6.text = [rs stringForColumn:@"R6"];
        self.r7.text = [rs stringForColumn:@"R7"];
        self.r8.text = [rs stringForColumn:@"R8"];
        self.r9.text = [rs stringForColumn:@"R9"];
        
    }
    else
    {
        //self.textItemCode.enabled = YES;
    }
    
    //dbHadError = [dbItemCat executeUpdate:@"delete from itemcatg"];
    [rs close];
    [dbTable close];
    //[self.itemMastTableView reloadData];
}

-(void)editRounding
{
    if ([[LibraryAPI sharedInstance]getUserRole] == 0) {
        [self showAlertView:@"You have no permission to edit data" title:@"Warning"];
        return;
    }
    
    if ([self.r1.text integerValue] > 10 || [self.r2.text integerValue] > 10 || [self.r3.text integerValue] > 10 || [self.r4.text integerValue] > 10 || [self.r5.text integerValue] > 10 || [self.r6.text integerValue] > 10 || [self.r7.text integerValue] > 10 || [self.r8.text integerValue] > 10 || [self.r9.text integerValue] > 10) {
        [self showAlertView:@"Rounding value cannot more than 10" title:@"Updated"];
        return;
    }
    
    if ([terminalType isEqualToString:@"Main"]) {
        dbTable = [FMDatabase databaseWithPath:dbPath];
        
        if (![dbTable open]) {
            NSLog(@"Fail To Open");
            return;
        }
        
        [dbTable executeUpdate:@"Update Rounding set R1 = ?, R2 = ?, R3 = ?, R4 = ?, R5 = ?, R6 = ?, R7 = ?, R8 = ?, R9 = ?",[NSNumber numberWithInt:[self.r1.text integerValue]],[NSNumber numberWithInt:[self.r2.text integerValue]],[NSNumber numberWithInt:[self.r3.text integerValue]],[NSNumber numberWithInt:[self.r4.text integerValue]],[NSNumber numberWithInt:[self.r5.text integerValue]],[NSNumber numberWithInt:[self.r6.text integerValue]],[NSNumber numberWithInt:[self.r7.text integerValue]],[NSNumber numberWithInt:[self.r8.text integerValue]],[NSNumber numberWithInt:[self.r9.text integerValue]]];
        
        if (![dbTable hadError]) {
            [self showAlertView:@"Data update" title:@"Updated"];
        }
        else
        {
            [self showAlertView:[dbTable lastErrorMessage] title:@"Fail"];
        }
        //[rs close];
        [dbTable close];
    }
    else
    {
        //[self showMyHudMessageBoxWithMessage:@"Terminal Cannot Edit Rounding"];
        [self showAlertView:@"Terminal cannot edit rounding" title:@"Warning"];
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

#pragma mark - show hub message box

-(void)showMyHudMessageBoxWithMessage:(NSString *)message
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.margin = 30.0f;
    hud.yOffset = 200.0f;
    
    hud.labelText = message;
    
    hud.removeFromSuperViewOnHide = YES;
    
    [hud hide:YES afterDelay:0.6];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
