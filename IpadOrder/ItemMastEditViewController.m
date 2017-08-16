//
//  ItemMastEditViewController.m
//  IpadOrder
//
//  Created by IRS on 7/3/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "ItemMastEditViewController.h"
#import "SelectCatTableViewController.h"
#import "NumPadTextField/NumericKeypadTextField.h"
#import "NumericKeypadViewController.h"
#import "LibraryAPI.h"
#import <FMDB.h>
#import <HNKCache.h>
#import "PublicMethod.h"
#import "PackageDetailViewController.h"

@interface ItemMastEditViewController ()
{
    FMDatabase *dbItemMast;
    NSString *dbPath;
    //NSString *userAction;
    BOOL dbHadError;
    NSMutableArray *printerArray;
    NSString *printerName;
    int printerIndex;
    NSString *alertFlag;
    NSArray *paths;
    NSString *documentsDirectory;
    NSString *filePath;
    NSString *itemImageName;
    NSString *imgPath;
    NSMutableArray *condimentGroupArray;
    NSData *imgData;
    NSString *selectedImageName;
    NSMutableArray *packageItemArray;
    
    
}
//@property(nonatomic,strong)UIPopoverController *popOver;
//@property(nonatomic,strong)UIPopoverController *imgPopOver;
@end
NSString *bigBtn;
@implementation ItemMastEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.textCategory.delegate = self;
    self.textItemTax.delegate = self;
    self.textServiceTax.delegate = self;
    //self.textPrinter.delegate = self;
    // Do any additional setup after loading the view from its nib.
    
    printerArray = [[NSMutableArray alloc]init];
    condimentGroupArray = [[NSMutableArray alloc]init];
    packageItemArray = [[NSMutableArray alloc]init];
    
    self.textItemPrice.delegate = self;
    
    self.tableViewPrinter.delegate = self;
    self.tableViewPrinter.dataSource = self;
    
    self.tableViewCondimentGroup.delegate  =self;
    self.tableViewCondimentGroup.dataSource = self;
    
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0];
    
    UIBarButtonItem *addBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(addItemMast:)];
    self.navigationItem.rightBarButtonItem = addBtn;
    
    self.viewBgItemMastEdit.layer.cornerRadius = 20.0;
    //self.viewBgItemMastEdit.layer.borderWidth = 1.0;
    self.viewBgItemMastEdit.layer.masksToBounds = YES;
    
    dbPath = [[LibraryAPI sharedInstance]getDbPath];
    selectedImageName = @"";
    
    self.textItemPrice.numericKeypadDelegate = self;
    
    // this bigbtn is use to set numeric keypad button
    bigBtn = @"Done";
    paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    documentsDirectory = [paths objectAtIndex:0];
    self.imgItemMast.userInteractionEnabled = true;
    
    self.imgItemMast.layer.borderWidth = 1.0;
    self.imgItemMast.layer.borderColor = [[UIColor blackColor] CGColor];
    self.imgItemMast.layer.cornerRadius = 10.0;
    
    UITapGestureRecognizer *tapImage = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(btnCamera)];
    [self.imgItemMast addGestureRecognizer:tapImage];
    
     //[self.textItemPrice addTarget:self action:@selector(textBeginEditing:) forControlEvents:UIControlEventEditingDidBegin];
    [self changeButtonColorWith];
    self.tableViewPrinter.separatorColor = [UIColor blackColor];
    [self checkOneItemMast];
}

-(void)viewDidDisappear:(BOOL)animated
{
    packageItemArray = nil;
    printerArray = nil;
    condimentGroupArray = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)addItemMast:(id)sender
{
    //NSLog(@"%hhd",self.switchItemHot.on);
    
    if ([[LibraryAPI sharedInstance]getUserRole] == 0) {
        [self showAlertView:@"You have no permission to edit data" title:@"Warning"];
        return;
    }
    
    BOOL checkItemTextField = [self checkTextField];
    
    if (!checkItemTextField) {
        return;
    }
    
    
    if ([self.userAction isEqualToString:@"New"]) {
        [self saveItemMast];
    }
    else if([self.userAction isEqualToString:@"Edit"])
    {
        [self updateItemMast];
    }
    
}

#pragma mark - NumberPadDelegate
-(void)saveActionFormTextField:(UITextField *)textField
{
    [textField resignFirstResponder];
    //NSLog(@"Password is %@",textField.text);
}

#pragma mark - sqlite

-(void)checkOneItemMast
{
    self.buttonOpenPackageItem.enabled = false;
    
    dbItemMast = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbItemMast open]) {
        NSLog(@"Fail To Open");
        return;
    }

    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rsTb = [db executeQuery:@"Select * from Printer where P_Type = ?",@"Kitchen"];
        [printerArray removeAllObjects];
        while ([rsTb next]) {
            NSMutableDictionary *printerDict = [NSMutableDictionary dictionary];
            
            [printerDict setObject:[rsTb stringForColumn:@"P_PortName"] forKey:@"P_Port"];
            [printerDict setObject:[rsTb stringForColumn:@"P_PrinterName"] forKey:@"P_Name"];
            [printerDict setObject:@"Non" forKey:@"P_Selected"];
            
            [printerArray addObject:printerDict];
            printerDict = nil;
        }
        
        [rsTb close];
        
        FMResultSet *rsCon = [db executeQuery:@"Select *, 'Non' as 'C_Selected' from CondimentHdr order by CH_Description"];
        
        while ([rsCon next]) {
            [condimentGroupArray addObject:[rsCon resultDictionary]];
        }
        
        [rsCon close];
        
        FMResultSet *rsDefaultTaxCode = [db executeQuery:@"Select * from GeneralSetting"];
        
        if ([rsDefaultTaxCode next]) {
            if ([rsDefaultTaxCode intForColumn:@"GS_EnableGST"] == 1) {
                self.textItemTax.text = [rsDefaultTaxCode stringForColumn:@"GS_DefaultGSTCode"];
            }
            
            if ([rsDefaultTaxCode intForColumn:@"GS_EnableSVG"] == 1) {
                self.textServiceTax.text = [rsDefaultTaxCode stringForColumn:@"GS_DefaultSVGCode"];
            }
            
        }
        [rsDefaultTaxCode close];
        
        FMResultSet *rs = [db executeQuery:@"Select *, ifnull(IP.IP_ItemNo,'-') as checkFlag, IFNULL(IM_FileName,'no_image.jpg') as IM_ImgFileName, ifnull(IC.IC_ItemCode,'-') as checkCondiment from ItemMast IM left join ItemPrinter IP on IM.IM_ItemCode = IP.IP_ItemNo left join ItemCondiment IC on IM.IM_ItemCode = IC.IC_ItemCode where IM_Itemno = ?",self.itemNo];
        //category = [NSMutableArray array];
        self.textItemCode.enabled = YES;
        
        while ([rs next]) {
            self.textItemCode.enabled = NO;
            self.textItemCode.text = [rs stringForColumn:@"IM_ItemCode"];
            //self.textItemName.text = [rs stringForColumn:@"IM_ItemName"];
            self.textItemDesc.text = [rs stringForColumn:@"IM_Description"];
            self.textItemPrice.text = [NSString stringWithFormat:@"%.2f",[[rs stringForColumn:@"IM_SalesPrice"]doubleValue]];
            self.textItemTax.text = [rs stringForColumn:@"IM_Tax"];
            self.textCategory.text = [rs stringForColumn:@"IM_Category"];
            self.textServiceTax.text = [rs stringForColumn:@"IM_ServiceTax"];
            self.textItemDesc2.text = [rs stringForColumn:@"IM_Description2"];
            filePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",[rs stringForColumn:@"IM_FileName"]]];
            self.switchPackageItem.on = [rs intForColumn:@"IM_ServiceType"];
            itemImageName = [rs stringForColumn:@"IM_ImgFileName"];
            
            if ([[rs stringForColumn:@"IM_ServiceType"] isEqualToString:@"1"]) {
                self.buttonOpenPackageItem.enabled = true;
            }
            else
            {
                self.buttonOpenPackageItem.enabled = false;
            }
            
            [self changeButtonColorWith];
            
            self.imgItemMast.image = [UIImage imageWithContentsOfFile:filePath];
            
            if (self.imgItemMast.image == nil) {
                self.imgItemMast.image = [UIImage imageNamed:@"no_image.jpg"];
            }
            self.imgItemMast.clipsToBounds = true;
            self.imgItemMast.clipsToBounds = YES;
            //self.imgItemMast.layer.cornerRadius = 5.0;
            if (![[rs stringForColumn:@"checkFlag"] isEqualToString:@"-"]) {
                
                for (int i = 0; i < printerArray.count; i++) {
                    if ([[rs stringForColumn:@"IP_PrinterName"] isEqualToString:[[printerArray objectAtIndex:i] objectForKey:@"P_Name"]]) {
                        NSMutableDictionary *printerDict2 = [NSMutableDictionary dictionary];
                        
                        printerDict2 = [printerArray objectAtIndex:i];
                        [printerDict2 setValue:@"Yes" forKey:@"P_Selected"];
                        [printerArray replaceObjectAtIndex:i withObject:printerDict2];
                        printerDict2 = nil;
                    }
                }

            }
            
            if (![[rs stringForColumn:@"checkCondiment"] isEqualToString:@"-"]) {
                
                for (int i = 0; i < condimentGroupArray.count; i++) {
                    if ([[rs stringForColumn:@"IC_CondimentHdrCode"] isEqualToString:[[condimentGroupArray objectAtIndex:i] objectForKey:@"CH_Code"]]) {
                        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                        
                        dict = [condimentGroupArray objectAtIndex:i];
                        [dict setValue:@"Yes" forKey:@"C_Selected"];
                        [condimentGroupArray replaceObjectAtIndex:i withObject:dict];
                        dict = nil;
                    }
                }
                
            }
            
        }
        [self.tableViewPrinter reloadData];
        [self.tableViewCondimentGroup reloadData];
        [rs close];
        
        [packageItemArray removeAllObjects];
        
        FMResultSet *rsPackDtl = [db executeQuery:@"Select * from PackageItemDtl where PD_Code = ?",self.textItemCode.text];
        NSLog(@"aaaa %@",self.textItemCode.text);
        while ([rsPackDtl next]) {
            NSMutableDictionary *sectionDic = [NSMutableDictionary dictionary];
            
            [sectionDic setObject:[rsPackDtl stringForColumn:@"PD_Code"] forKey:@"PD_Code"];
            [sectionDic setObject:[rsPackDtl stringForColumn:@"PD_ItemDescription"] forKey:@"PD_Description"];
            [sectionDic setObject:[rsPackDtl stringForColumn:@"PD_ItemCode"] forKey:@"PD_ItemCode"];
            [sectionDic setObject:[rsPackDtl stringForColumn:@"PD_Price"] forKey:@"PD_Price"];
            [sectionDic setObject:[rsPackDtl stringForColumn:@"PD_MinChoice"] forKey:@"PD_MinChoice"];
            //[sectionDic setObject:@"ItemMast" forKey:@"PD_Type"];
            [sectionDic setObject:[rsPackDtl stringForColumn:@"PD_ItemType"] forKey:@"PD_ItemType"];
            
            [packageItemArray addObject:sectionDic];
            sectionDic = nil;
        }
        [rsPackDtl close];

    }];
    
    
    //dbHadError = [dbItemCat executeUpdate:@"delete from itemcatg"];
    
    [dbItemMast close];
    //[self.itemMastTableView reloadData];
}

-(void)saveItemMast
{
    __block NSString *flag;
    
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormat = [[LibraryAPI sharedInstance] getDateFormaterhh_mm];
    
    selectedImageName = [NSString stringWithFormat:@"%@_%@.jpg",self.textItemCode.text,[dateFormat stringFromDate:today]];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rsIM = [db executeQuery:@"Select * from ItemMast where IM_ItemCode = ?",[self.textItemCode.text uppercaseString]];
        
        if ([rsIM next]) {
            flag = @"False";
            [self showAlertView:@"Duplicate item code" title:@"Warning"];
            return;
        }
        
        [db executeUpdate:@"Insert into ItemMast ("
                      "IM_ItemCode, IM_Description, IM_Location, IM_Category, IM_SalesPrice,"
                      "IM_Tax, IM_ServiceTax, IM_Favorite, IM_Description2,IM_FileName, IM_ServiceType ) values ("
                      "?,?,?,?,?,?,?,?,?,?,?)",self.textItemCode.text, self.textItemDesc.text, @"-",self.textCategory.text, self.textItemPrice.text,self.textItemTax.text, self.textServiceTax.text, [NSNumber numberWithBool:0],self.textItemDesc2.text,selectedImageName,[NSNumber numberWithBool:self.switchPackageItem.on]];
        
        if (![db hadError]) {
            flag = @"True";
            
            //documentsDirectory = [paths objectAtIndex:0];
            imgPath = [documentsDirectory stringByAppendingPathComponent:selectedImageName];
            [imgData writeToFile:imgPath atomically:YES];
        }
        else
        {
            flag = @"False";
            [self showAlertView:[dbItemMast lastErrorMessage] title:@"Error"];
            *rollback = YES;
            return;
        }
        
        for (int i =0; i < printerArray.count; i++) {
            if ([[[printerArray objectAtIndex:i] objectForKey:@"P_Selected"] isEqualToString:@"Yes"]) {
                [db executeUpdate:@"Insert into ItemPrinter ("
                 " IP_ItemNo, IP_PrinterPort, IP_PrinterName)"
                 " values (?,?,?)",self.textItemCode.text,[[printerArray objectAtIndex:i] objectForKey:@"P_Port"], [[printerArray objectAtIndex:i] objectForKey:@"P_Name"]];
                
                if ([db hadError]) {
                    flag = @"False";
                    [self showAlertView:[db lastErrorMessage] title:@"Error"];
                    *rollback = YES;
                    return;
                }
                else
                {
                    flag = @"True";
                    //[self showAlertView:@"Data Save" title:@"Success"];
                }
            }
        }
        
        for (int i =0; i < condimentGroupArray.count; i++) {
            if ([[[condimentGroupArray objectAtIndex:i] objectForKey:@"C_Selected"] isEqualToString:@"Yes"]) {
                [db executeUpdate:@"Insert into ItemCondiment ("
                 " IC_ItemCode, IC_CondimentHdrCode)"
                 " values (?,?)",self.textItemCode.text,[[condimentGroupArray objectAtIndex:i] objectForKey:@"CH_Code"]];
                
                if ([db hadError]) {
                    flag = @"False";
                    [self showAlertView:[db lastErrorMessage] title:@"Error"];
                    *rollback = YES;
                    return;
                }
                else
                {
                    flag = @"True";
                    //[self showAlertView:@"Data Save" title:@"Success"];
                }
            }
        }
        
        if (self.switchPackageItem.on == true) {
            [db executeUpdate:@"Delete from PackageItemDtl where PD_Code = ?",self.textItemCode.text];
            
            for (int i = 0; i < packageItemArray.count; i++) {
                [db executeUpdate:@"Insert into PackageItemDtl (PD_Code, PD_ItemCode, PD_ItemDescription, PD_Price, PD_MinChoice, PD_ItemType) Values (?,?,?,?,?,?)", self.textItemCode.text,[[packageItemArray objectAtIndex:i] objectForKey:@"PD_ItemCode"],[[packageItemArray objectAtIndex:i] objectForKey:@"PD_Description"],[[packageItemArray objectAtIndex:i] objectForKey:@"PD_Price"],[[packageItemArray objectAtIndex:i] objectForKey:@"PD_MinChoice"],[[packageItemArray objectAtIndex:i]objectForKey:@"PD_ItemType"]];
                
                if ([db hadError]) {
                    flag = @"False";
                    [self showAlertView:[db lastErrorMessage] title:@"Error"];
                    *rollback = YES;
                    return;
                }
                else{
                    flag = @"True";
                }
                
            }
        }
        
        
    }];
    
    [queue close];
    
    printerArray = nil;
    condimentGroupArray = nil;
    
    if ([flag isEqualToString:@"True"]) {
        paths = nil;
        [self.navigationController popViewControllerAnimated:YES];
    }
    
}

-(void)updateItemMast
{
    dbItemMast = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbItemMast open]) {
        NSLog(@"Fail To Open");
        return;
    }
    
    if ([selectedImageName length] == 0) {
        selectedImageName = itemImageName;
    }
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [db executeUpdate:@"Update ItemMast set"
                      " IM_ItemCode = ?, IM_Description = ?, IM_Location = ?, IM_Category = ?, IM_SalesPrice = ?, IM_Tax = ?, IM_ServiceTax = ?, IM_Favorite = ?, IM_Description2 = ?,IM_FileName = ?, IM_ServiceType = ?"
         " where IM_ItemNo = ?",self.textItemCode.text, self.textItemDesc.text, @"-",self.textCategory.text, self.textItemPrice.text,self.textItemTax.text, self.textServiceTax.text, [NSNumber numberWithBool:0], self.textItemDesc2.text,selectedImageName,[NSNumber numberWithBool:self.switchPackageItem.on],self.itemNo];
        
        if (![db hadError])
        {
            
            [db executeUpdate:@"Update PackageItemDtl set PD_ItemDescription = ? where PD_ItemCode = ? and PD_ItemType = ?",self.textItemDesc.text, self.textItemCode.text, @"ItemMast"];
            
            if (![db hadError]) {
                if ([selectedImageName length] == 0) {
                    selectedImageName = @"no_image.jpg";
                }
                [db executeUpdate:@"Update ModifierDtl set MD_ItemDescription = ?, MD_ItemFileName = ? where MD_ItemCode = ?",self.textItemDesc.text,selectedImageName, self.textItemCode.text];
                
                if ([db hadError]) {
                    [self showAlertView:[db lastErrorMessage] title:@"Error"];
                    *rollback = YES;
                    return;
                }
                
            }
            else
            {
                [self showAlertView:[db lastErrorMessage] title:@"Error"];
                *rollback = YES;
                return;
            }
            
            if (![selectedImageName isEqualToString:itemImageName]) {
                [PublicMethod removeExistingFileFromDirectoryWithFileName:itemImageName];
                
                documentsDirectory = [paths objectAtIndex:0];
                imgPath = [documentsDirectory stringByAppendingPathComponent:selectedImageName];
                [imgData writeToFile:imgPath atomically:YES];
            }
            
            [db executeUpdate:@"Delete from ItemPrinter where IP_ItemNo = ?",self.textItemCode.text];
            [db executeUpdate:@"Delete from ItemCondiment where IC_ItemCode = ?",self.textItemCode.text];
            
            if (![db hadError]) {
                for (int i =0; i < printerArray.count; i++) {
                    if ([[[printerArray objectAtIndex:i] objectForKey:@"P_Selected"] isEqualToString:@"Yes"]) {
                        [db executeUpdate:@"Insert into ItemPrinter ("
                         " IP_ItemNo, IP_PrinterPort, IP_PrinterName)"
                         " values (?,?,?)",self.textItemCode.text,[[printerArray objectAtIndex:i] objectForKey:@"P_Port"], [[printerArray objectAtIndex:i] objectForKey:@"P_Name"]];
                        
                        if ([db hadError]) {
                            [self showAlertView:[db lastErrorMessage] title:@"Error"];
                            *rollback = YES;
                            return;
                        }
                        else
                        {
                            
                        }
                    }
                    
                }
                
                for (int i =0; i < condimentGroupArray.count; i++) {
                    if ([[[condimentGroupArray objectAtIndex:i] objectForKey:@"C_Selected"] isEqualToString:@"Yes"]) {
                        [db executeUpdate:@"Insert into ItemCondiment ("
                         " IC_ItemCode, IC_CondimentHdrCode)"
                         " values (?,?)",self.textItemCode.text,[[condimentGroupArray objectAtIndex:i] objectForKey:@"CH_Code"]];
                        
                        if ([db hadError]) {
                            [self showAlertView:[db lastErrorMessage] title:@"Error"];
                            *rollback = YES;
                            return;
                        }
                        else
                        {
                            
                        }
                    }
                    
                }
                
                if (self.switchPackageItem.on == true) {
                    [db executeUpdate:@"Delete from PackageItemDtl where PD_Code = ?",self.textItemCode.text];
                    
                    for (int i = 0; i < packageItemArray.count; i++) {
                        [db executeUpdate:@"Insert into PackageItemDtl (PD_Code, PD_ItemCode, PD_ItemDescription, PD_Price, PD_MinChoice, PD_ItemType) Values (?,?,?,?,?,?)", self.textItemCode.text,[[packageItemArray objectAtIndex:i] objectForKey:@"PD_ItemCode"],[[packageItemArray objectAtIndex:i] objectForKey:@"PD_Description"],[[packageItemArray objectAtIndex:i] objectForKey:@"PD_Price"],[[packageItemArray objectAtIndex:i] objectForKey:@"PD_MinChoice"],[[packageItemArray objectAtIndex:i]objectForKey:@"PD_ItemType"]];
                        
                        if ([db hadError]) {
                            [self showAlertView:[db lastErrorMessage] title:@"Error"];
                            *rollback = YES;
                            return;
                        }
                        else{
                            
                        }
                        
                    }
                }
                
                //[self showAlertView:@"Data Updated" title:@"Success"];
                printerArray = nil;
                condimentGroupArray = nil;
                [self.navigationController popViewControllerAnimated:YES];
            }
            else
            {
                [self showAlertView:[db lastErrorMessage] title:@"Error"];
                *rollback = YES;
                return;
            }
            
            //[self showAlertView:@"Data Updated" title:@"Success"];
        }
        else
        {
            [self showAlertView:[dbItemMast lastErrorMessage] title:@"Error"];
            *rollback = YES;
            return;
        }
        
    }];
    
    [queue close];
    //[dbItemMast close];
    [[HNKCache sharedCache] removeImagesForKey:self.textItemCode.text];
    
}

/*
#pragma mark - text editing

-(void)textBeginEditing:(id)sender
{
    self.textItemPrice.text = nil;
}
*/

#pragma mark - highlight textfield
-(void)textFieldDidBeginEditing:(UITextField *)textField {
    
    [textField selectAll:nil];
    
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    SelectCatTableViewController *selectCatTableViewController = [[SelectCatTableViewController alloc]init];
    selectCatTableViewController.delegate = self;
    //self.popOver = [[UIPopoverController alloc]initWithContentViewController:selectCatTableViewController];
    
    if (textField.tag == 5) {
        
        selectCatTableViewController.filterType = @"Category";
        [self.view endEditing:YES];
        selectCatTableViewController.modalPresentationStyle = UIModalPresentationPopover;
        selectCatTableViewController.popoverPresentationController.sourceView = self.textCategory;
        selectCatTableViewController.popoverPresentationController.sourceRect = CGRectMake(self.textCategory.frame.size.width /
                                                                                           2, self.textCategory.frame.size.height / 2, 1, 1);
        [self presentViewController:selectCatTableViewController animated:YES completion:nil];
        /*
        [self.popOver presentPopoverFromRect:CGRectMake(self.textCategory.frame.size.width /
                                                    2, self.textCategory.frame.size.height / 2, 1, 1) inView:self.textCategory permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
         */
        return NO;
    }
    else if (textField.tag == 3)
    {
        selectCatTableViewController.filterType = @"Gst";
        [self.view endEditing:YES];
        
        selectCatTableViewController.modalPresentationStyle = UIModalPresentationPopover;
        selectCatTableViewController.popoverPresentationController.sourceView = self.textItemTax;
        selectCatTableViewController.popoverPresentationController.sourceRect = CGRectMake(self.textItemTax.frame.size.width /
                                                                                           2, self.textItemTax.frame.size.height / 2, 1, 1);
        [self presentViewController:selectCatTableViewController animated:YES completion:nil];
        
        /*
        [self.popOver presentPopoverFromRect:CGRectMake(self.textItemTax.frame.size.width /
                                                        2, self.textItemTax.frame.size.height / 2, 1, 1) inView:self.textItemTax permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
        return NO;
         */
        return NO;
    }
    
    else if (textField.tag == 6)
    {
       
        selectCatTableViewController.filterType = @"ServiceTax";
        [self.view endEditing:YES];
        
        selectCatTableViewController.modalPresentationStyle = UIModalPresentationPopover;
        selectCatTableViewController.popoverPresentationController.sourceView = self.textServiceTax;
        selectCatTableViewController.popoverPresentationController.sourceRect = CGRectMake(self.textServiceTax.frame.size.width /
                                                                                           2, self.textServiceTax.frame.size.height / 2, 1, 1);
        [self presentViewController:selectCatTableViewController animated:YES completion:nil];
        /*
        [self.popOver presentPopoverFromRect:CGRectMake(self.textServiceTax.frame.size.width /
                                                        2, self.textServiceTax.frame.size.height / 2, 1, 1) inView:self.textServiceTax permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
        return NO;
         */
        return NO;
         
    }
    
    else
    {
        return YES;
    }
    selectCatTableViewController = nil;
}

#pragma mark - alertView

-(void)showAlertView:(NSString *)msg title:(NSString *)title
{
    alertFlag = @"Normal";
    
    UIAlertController *alert = [[LibraryAPI sharedInstance] showAlertViewWithMsg:msg Title:title];
    
    [self presentViewController:alert animated:NO completion:nil];
    alert = nil;
}

/*
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    dbItemMast = [FMDatabase databaseWithPath:dbPath];
    //BOOL dbHadError;
    if (![dbItemMast open]) {
        NSLog(@"Fail To Open");
        return;
    }
    
    if ([alertFlag isEqualToString:@"Delete"]) {
        if (buttonIndex == 0) {
            //[printerArray removeObjectAtIndex:(NSUInteger)]
            [dbItemMast executeUpdate:@"delete from ItemPrinter where IP_ItemNo = ? and IP_PrinterPort = ?",self.textItemCode.text,[[printerArray objectAtIndex:printerIndex] objectForKey:@"P_Port"]];
            
            if ([dbItemMast hadError]) {
                [self showAlertView:[dbItemMast lastErrorMessage] title:@"Error"];
            }
            else
            {
                [printerArray removeObjectAtIndex:printerIndex];
                [self.tableViewPrinter reloadData];
            }
            
        }
    }
    
    [dbItemMast close];
    
}
*/

#pragma mark - delegate method
-(void)getSelectedCategory:(NSString *)field1 field2:(NSString *)field2 field3:(NSString *)field3 filterType:(NSString *)filterType
{
    if ([filterType isEqualToString:@"Gst"]) {
        self.textItemTax.text = field1;
    }
    else if ([filterType isEqualToString:@"Category"])
    {
        self.textCategory.text = field1;
    }
    else if ([filterType isEqualToString:@"ServiceTax"])
    {
        self.textServiceTax.text = field1;
        //printerName = field3;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - check field
-(BOOL)checkTextField
{
    if ([self.textItemCode.text isEqualToString:@""]) {
        [self showAlertView:@"Item code cannot empty" title:@"Warning"];
        return NO;
    }
    else if ([self.textItemDesc.text isEqualToString:@""])
    {
        [self showAlertView:@"Description cannot empty" title:@"Warning"];
        return NO;
    }
    else if ([self.textItemPrice.text isEqualToString:@""])
    {
        [self showAlertView:@"Price cannot empty" title:@"Warning"];
        return NO;
    }
    else if ([self.textItemPrice.text isEqualToString:@""])
    {
        [self showAlertView:@"Price cannot empty" title:@"Warning"];
        return NO;
    }
    else if ([self.textCategory.text isEqualToString:@""])
    {
        [self showAlertView:@"Category cannot empty" title:@"Warning"];
        return NO;
    }
    
    if (self.switchPackageItem.on == YES && packageItemArray.count == 0) {
        [self showAlertView:@"Package item list is empty" title:@"Warning"];
        return NO;
    }
    
    return  YES;
}

#pragma mark - tableview delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    // Return the number of rows in the section.
    if (tableView == self.tableViewPrinter) {
        return [printerArray count];
    }
    else
    {
        return [condimentGroupArray count];
    }
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSMutableDictionary *printerDict3 = [NSMutableDictionary dictionary];
    NSMutableDictionary *condimentDict = [NSMutableDictionary dictionary];
    
    if (tableView == self.tableViewPrinter) {
        /*
        if(self.switchPackageItem.isOn)
        {
            [self showAlertView:@"Kitchen printer not available for package item" title:@"Information"];
            return;
        }
        */
        if (cell.accessoryType == UITableViewCellAccessoryNone) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            
            printerDict3 = [printerArray objectAtIndex:indexPath.row];
            [printerDict3 setValue:@"Yes" forKey:@"P_Selected"];
            [printerArray replaceObjectAtIndex:indexPath.row withObject:printerDict3];
            
            
        }
        else
        {
            cell.accessoryType = UITableViewCellAccessoryNone;
            //NSMutableDictionary *printerDict3 = [NSMutableDictionary dictionary];
            printerDict3 = [printerArray objectAtIndex:indexPath.row];
            [printerDict3 setValue:@"Non" forKey:@"P_Selected"];
            [printerArray replaceObjectAtIndex:indexPath.row withObject:printerDict3];
            
        }
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [tableView reloadData];
    }
    else
    {
        if(self.switchPackageItem.isOn)
        {
            return;
        }
        if (cell.accessoryType == UITableViewCellAccessoryNone) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            
            condimentDict = [condimentGroupArray objectAtIndex:indexPath.row];
            [condimentDict setValue:@"Yes" forKey:@"C_Selected"];
            [condimentGroupArray replaceObjectAtIndex:indexPath.row withObject:condimentDict];
            
            
        }
        else
        {
            cell.accessoryType = UITableViewCellAccessoryNone;
            condimentDict = [condimentGroupArray objectAtIndex:indexPath.row];
            [condimentDict setValue:@"Non" forKey:@"C_Selected"];
            [condimentGroupArray replaceObjectAtIndex:indexPath.row withObject:condimentDict];
        }
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [tableView reloadData];
    }
    condimentDict = nil;
    printerDict3 = nil;
    
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableViewPrinter) {
        if ([[[printerArray objectAtIndex:indexPath.row] objectForKey:@"P_Selected"] isEqualToString:@"Yes"]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *Identifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:Identifier];
    
    if (cell == nil) {
        //        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:Identifier] autorelease];
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:Identifier];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (tableView == self.tableViewPrinter) {
        cell.textLabel.text = [[printerArray objectAtIndex:indexPath.row] objectForKey:@"P_Name"];
        cell.detailTextLabel.text = [[printerArray objectAtIndex:indexPath.row] objectForKey:@"P_Port"];
        
        if ([[[printerArray objectAtIndex:indexPath.row] objectForKey:@"P_Selected"] isEqualToString:@"Yes"]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else
        {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    else
    {
        cell.textLabel.text = [[condimentGroupArray objectAtIndex:indexPath.row] objectForKey:@"CH_Description"];
        cell.detailTextLabel.text = [[condimentGroupArray objectAtIndex:indexPath.row] objectForKey:@"CH_Code"];
        
        if ([[[condimentGroupArray objectAtIndex:indexPath.row] objectForKey:@"C_Selected"] isEqualToString:@"Yes"]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else
        {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
    }
    
    
    return cell;
}

- (void)btnCamera{
    
    if ([self.textItemCode.text isEqualToString:@""]) {
        [self showAlertView:@"Item code cannot empty" title:@"Information"];
        return;
    }
    
    UIImagePickerController *picker = [[UIImagePickerController alloc]init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    picker.modalPresentationStyle                   = UIModalPresentationPopover;
    picker.popoverPresentationController.sourceView = self.imgItemMast;
    picker.popoverPresentationController.sourceRect = CGRectMake(0, 0, 170, 250);
    [self presentViewController:picker animated:YES completion:nil];
    
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSDate *today = [NSDate date];
    //NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    //[dateFormat setDateFormat:@"yyyy-MM-dd hh-mm"];
    NSDateFormatter *dateFormat = [[LibraryAPI sharedInstance] getDateFormaterhh_mm];
    
    
    selectedImageName = [NSString stringWithFormat:@"%@_%@.jpg",self.textItemCode.text,[dateFormat stringFromDate:today]];
    
    
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    self.imgItemMast.image = chosenImage;
    self.imgItemMast.clipsToBounds = YES;
    //NSData *data = UIImageJPEGRepresentation(chosenImage,0.7);
    imgData = UIImageJPEGRepresentation(chosenImage,0.5);
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)switchPackageItemSelect:(id)sender {
    if (self.switchPackageItem.isOn) {
        self.buttonOpenPackageItem.enabled = true;
        
        NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"C_Selected MATCHES[cd] %@",
                                   @"Yes"];
        
        NSArray *parentObject = [condimentGroupArray filteredArrayUsingPredicate:predicate1];
        
        if (parentObject.count > 0) {
            [self showAlertView:@"Item with condiment cannot enable Package Item" title:@"Warning"];
            self.switchPackageItem.on = false;
        }
        
        parentObject = nil;
    }
    else
    {
        self.buttonOpenPackageItem.enabled = false;
    }
    
    [self changeButtonColorWith];
    
}

- (IBAction)btnOpenPackageItem:(id)sender {
    
    PackageDetailViewController *packageDetailViewController = [[PackageDetailViewController alloc]init];
    packageDetailViewController.delegate = self;
    packageDetailViewController.packageItemCode = self.textItemCode.text;
    packageDetailViewController.packageItemDesc = self.textItemDesc.text;
    packageDetailViewController.packageItemDetailArray = packageItemArray;
    
    
    UINavigationController *navbar = [[UINavigationController alloc]  initWithRootViewController:packageDetailViewController];
    
    navbar.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    navbar.modalPresentationStyle = UIModalPresentationFormSheet;
    [packageDetailViewController setModalPresentationStyle:UIModalPresentationFormSheet];
    [packageDetailViewController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    
    [self.navigationController presentViewController:navbar animated:NO completion:nil];
    
}

-(void)changeButtonColorWith
{
    if (self.switchPackageItem.isOn) {
        self.buttonOpenPackageItem.layer.borderColor = [[UIColor colorWithRed:0.0/255 green:122.0/255 blue:255.0/255 alpha:1.0] CGColor];
        self.buttonOpenPackageItem.layer.borderWidth = 1.0;
        self.buttonOpenPackageItem.layer.cornerRadius = 5.0;
        [self.buttonOpenPackageItem setTitleColor:[UIColor colorWithRed:0.0/255 green:122.0/255 blue:255.0/255 alpha:1.0] forState:UIControlStateNormal];
    }
    else
    {
        self.buttonOpenPackageItem.layer.borderColor = [[UIColor grayColor] CGColor];
        self.buttonOpenPackageItem.layer.borderWidth = 1.0;
        self.buttonOpenPackageItem.layer.cornerRadius = 5.0;
        [self.buttonOpenPackageItem setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    }
    
}

#pragma mark - delegate from packageitem detail view
-(void)passBackPackageDetailSettingArray:(NSMutableArray *)packageArray
{
    [self.navigationController dismissViewControllerAnimated:NO completion:nil];
    [packageItemArray removeAllObjects];
    packageItemArray = packageArray;
}
@end
