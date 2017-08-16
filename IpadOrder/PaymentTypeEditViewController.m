//
//  PaymentTypeEditViewController.m
//  IpadOrder
//
//  Created by IRS on 24/11/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import "PaymentTypeEditViewController.h"
#import <FMDB.h>
#import "LibraryAPI.h"


@interface PaymentTypeEditViewController ()
{
    NSString *dbPath;
    BOOL dbHadError;
    BOOL checkTextEmpty;
    NSString *paymentTypeImgName;
}
@end

@implementation PaymentTypeEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setTitle:@"Payment Mode"];
    UIBarButtonItem *addBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(editPaymentType:)];
    self.navigationItem.rightBarButtonItem = addBtn;
    
    UITapGestureRecognizer *tapImage = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(callOutSelectPaymentType)];
    [self.imgPaymentType setUserInteractionEnabled:YES];
    [self.imgPaymentType addGestureRecognizer:tapImage];
    
    dbPath = [[LibraryAPI sharedInstance]getDbPath];
    
    if ([self.editPaymentTypeAction isEqualToString:@"Edit"]) {
        [self getOnePaymentType];
    }
    
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)editPaymentType:(id)sender
{
    
    if ([[LibraryAPI sharedInstance]getUserRole] == 0) {
        [self showAlertView:@"You have no permission to edit data" title:@"Warning"];
        return;
    }
    
    if ([self.editPaymentTypeAction isEqualToString:@"New"]) {
        [self savePaymentType];
    }
    else if ([self.editPaymentTypeAction isEqualToString:@"Edit"])
    {
        [self updatePaymentType];
    }
}

-(void)getOnePaymentType
{
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
    
        FMResultSet *rs = [db executeQuery:@"Select * from PaymentType where PT_Code = ?", self.editPaymentTypeCode];
        
        if ([rs next]) {
            self.textPaymentTypeCode.enabled = false;
            paymentTypeImgName = [rs stringForColumn:@"PT_ImgName"];
            self.switchPaymentTypeSelected.on = [rs intForColumn:@"PT_Checked"];
            self.textPaymentTypeCode.text = [rs stringForColumn:@"PT_Code"];
            self.textPaymentTypeDescription.text = [rs stringForColumn:@"PT_Description"];
            if ([[rs stringForColumn:@"PT_Type"] isEqualToString:@"Cash"]) {
                self.switchExchange.on = true;
            }
            else
            {
                self.switchExchange.on = false;
            }
            self.imgPaymentType.image = [UIImage imageNamed:[rs stringForColumn:@"PT_ImgName"]];
            
        }
        
        [rs close];
    
    }];
    
    
    [queue close];
    
}

-(void)savePaymentType
{
    checkTextEmpty = [self checkTextField];
    
    if (!checkTextEmpty) {
        return;
    }
    
    if (paymentTypeImgName.length == 0) {
        [self showAlertView:@"Please select an image" title:@"Information"];
        return;
    }
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        NSString *payType;
        FMResultSet *rs = [db executeQuery:@"Select * from PaymentType where PT_Code = ?",self.textPaymentTypeCode.text];
        
        if ([rs next]) {
            [rs close];
            [self showAlertView:@"Duplicate id" title:@"Fail"];
            return;
        }
        else
        {
            [rs close];
        }
        
        if (self.switchExchange.on) {
            payType = @"Cash";
        }
        else
        {
            payType = @"Card";
        }
        
        dbHadError = [db executeUpdate:@"Insert into PaymentType ("
                      "PT_Code, PT_Description,PT_Checked, PT_Type, PT_ImgName) values ("
                      "?,?,?,?,?)",self.textPaymentTypeCode.text, self.textPaymentTypeDescription.text,[NSNumber numberWithInt:self.switchPaymentTypeSelected.on],payType,paymentTypeImgName];
        if (dbHadError)
        {
            //[self showAlertView:@"Data Saved" title:@"Success"];
            [self.navigationController popViewControllerAnimated:YES];
        }
        else
        {
            [self showAlertView:[db lastErrorMessage] title:@"Error"];
        }
    }];
    
    [queue close];
    //[dbUserName close];
    
    
}

-(void)updatePaymentType
{
    
    checkTextEmpty = [self checkTextField];
    
    if (!checkTextEmpty) {
        return;
    }

    if (paymentTypeImgName.length == 0) {
        [self showAlertView:@"Please select an image" title:@"Information"];
        return;
    }
    
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSString *payType;
        
        if (self.switchExchange.on) {
            payType = @"Cash";
        }
        else
        {
            payType = @"Card";
        }
        
        
        [db executeUpdate:@"Update PaymentType set PT_Description = ?,PT_Checked = ?, PT_Type = ?, PT_ImgName = ? where PT_Code = ?",self.textPaymentTypeDescription.text,[NSNumber numberWithBool:self.switchPaymentTypeSelected.on],payType,paymentTypeImgName,self.textPaymentTypeCode.text];
        
        if ([db hadError]) {
            [self showAlertView:[db lastErrorMessage] title:@"Error"];
        }
        else
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
        
    }];
    [queue close];
    
}

-(BOOL)checkTextField
{
    if ([self.textPaymentTypeCode.text isEqualToString:@""]) {
        [self showAlertView:@"Payment type code cannot empty" title:@"Warning"];
        return NO;
    }
    else if ([self.textPaymentTypeDescription.text isEqualToString:@""])
    {
        [self showAlertView:@"Description cannot empty" title:@"Warning"];
        return NO;
    }
    
    return  YES;
}

#pragma mark - delegate
-(void)getSelectedPaymentTypeImgNameWithImgName:(NSString *)name
{
    paymentTypeImgName = name;
    self.imgPaymentType.image = [UIImage imageNamed:name];
    [self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark - select img payment type
-(void)callOutSelectPaymentType
{
    PaymentTypeImgViewController *paymentTypeImgViewController = [[PaymentTypeImgViewController alloc]init];
    paymentTypeImgViewController.delegate = self;
    //self.popOver = [[UIPopoverController alloc]initWithContentViewController:selectCatTableViewController];
    
    paymentTypeImgViewController.modalPresentationStyle = UIModalPresentationPopover;
    paymentTypeImgViewController.popoverPresentationController.sourceView = self.imgPaymentType;
    paymentTypeImgViewController.popoverPresentationController.sourceRect = CGRectMake(self.imgPaymentType.frame.size.width /
                                                                                       2, self.imgPaymentType.frame.size.height / 2, 1, 1);
    paymentTypeImgViewController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUnknown;
    
    [self presentViewController:paymentTypeImgViewController animated:YES completion:nil];
}

#pragma mark - touch backgound
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


#pragma mark - alertView

-(void)showAlertView:(NSString *)msg title:(NSString *)title
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:msg
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

@end
