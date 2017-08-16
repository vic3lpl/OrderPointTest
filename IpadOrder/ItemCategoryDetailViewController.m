//
//  ItemCategoryDetailViewController.m
//  IpadOrder
//
//  Created by IRS on 08/03/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import "ItemCategoryDetailViewController.h"
#import <FMDB.h>
#import "LibraryAPI.h"

@interface ItemCategoryDetailViewController ()
{
    NSString *dbPath;
    FMDatabase *dbCategory;
    NSData *imgData;
    NSString *imgPath;
    NSArray *paths;
    NSString *documentsDirectory;
    NSString *imgName;
    NSString *pickImageFlag;
    
}
//@property(nonatomic,strong)UIPopoverController *imgCatPopOver;
@end

@implementation ItemCategoryDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.preferredContentSize = CGSizeMake(382, 150);
    self.navigationController.navigationBar.hidden = YES;
    
    dbPath = [[LibraryAPI sharedInstance] getDbPath];
    
    paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    documentsDirectory = [paths objectAtIndex:0];
    self.textTextCategoryDesc.delegate = self;
    self.imgCategory.userInteractionEnabled = true;
    UITapGestureRecognizer *tapImage = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(openPhotoLibrary)];
    [self.imgCategory addGestureRecognizer:tapImage];
    
    [self.btnSaveCategory addTarget:self action:@selector(saveItemCategory) forControlEvents:UIControlEventTouchUpInside];
    
    self.imgCategory.layer.borderWidth = 1.0;
    self.imgCategory.layer.borderColor = [[UIColor blackColor] CGColor];
    self.imgCategory.layer.cornerRadius = 10.0;
    pickImageFlag = @"UnPick";
    if ([_catStatus isEqualToString:@"Edit"]) {
        //self.btnSaveCategory.enabled = NO;
        self.textCategory.enabled = NO;
        [self checkItemCatg];
    }
    
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - textfield delegate
-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (textField == self.textTextCategoryDesc) {
        self.textTextCategoryDesc.text = self.textCategory.text;
    }
}

#pragma mark - sqlite

-(void)checkItemCatg
{
    dbCategory = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbCategory open]) {
        NSLog(@"Fail To Open");
        return;
    }
    
    FMResultSet *rs = [dbCategory executeQuery:@"Select * from ItemCatg where IC_Category = ?",_category];
    //category = [NSMutableArray array];
    if ([rs next]) {
        
        self.textCategory.text = [rs stringForColumn:@"IC_Category"];
        self.textTextCategoryDesc.text = [rs stringForColumn:@"IC_Description"];
        
        documentsDirectory = [paths objectAtIndex:0];
        imgPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg",[rs stringForColumn:@"IC_Category"]]];
        
        self.imgCategory.image = [UIImage imageWithContentsOfFile:imgPath];
        self.imgCategory.clipsToBounds = YES;
        
        if (self.imgCategory.image == nil) {
            self.imgCategory.image = [UIImage imageNamed:@"no_image.jpg"];
        }

    }
    
    [rs close];
    [dbCategory close];
}

-(void)saveItemCategory
{
    if ([[LibraryAPI sharedInstance]getUserRole] == 0) {
        [self showAlertView:@"You have no permission to edit data" title:@"Warning"];
        return;
    }
    
    BOOL checking = [self checkingAllTextView];
    
    if (checking == false) {
        return;
    }
    
    if ([_catStatus isEqualToString:@"Edit"]) {
        [self updateCategoryImage];
    }
    else
    {
        
        if ([self.textCategory.text isEqualToString:@""]) {
            [self showAlertView:@"Category cannot empty" title:@"Warning"];
            return;
        }
        
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
        
        [queue inDatabase:^(FMDatabase *db) {
            
            FMResultSet *rs = [db executeQuery:@"Select * from ItemCatg where IC_Category = ?",[self.textCategory.text uppercaseString]];
            
            if ([rs next]) {
                [rs close];
                [self showAlertView:@"Duplicate category code" title:@"Information"];
                return;
            }
            [rs close];
            
            [db executeUpdate:@"insert into ItemCatg (IC_Category, IC_Description) values (?,?)",self.textCategory.text,self.textTextCategoryDesc.text];
            
            if ([db hadError]) {
                [self showAlertView:[dbCategory lastErrorMessage] title:@"Error"];
            }
            else
            {
                
                imgName = [NSString stringWithFormat:@"%@.jpg",self.textCategory.text];
                
                if ([pickImageFlag isEqualToString:@"UnPick"]) {
                    imgData = UIImageJPEGRepresentation([UIImage imageNamed:@"no_image.jpg"],0.7);
                }
                else
                {
                    imgData = UIImageJPEGRepresentation(self.imgCategory.image,0.7);
                }
                
                documentsDirectory = [paths objectAtIndex:0];
                imgPath = [documentsDirectory stringByAppendingPathComponent:imgName];
                [imgData writeToFile:imgPath atomically:YES];
                
                //[imgData writeToFile:imgPath atomically:YES];
                [self dismissViewControllerAnimated:YES completion:nil];
                
                if (_delegate != nil) {
                    [_delegate resultFromCategoryDetail];
                }
                
            }
        }];
        [queue close];
    }
    
}

-(void)updateCategoryImage
{
    
    BOOL checking = [self checkingAllTextView];
    
    if (checking == false) {
        return;
    }
    
    dbCategory = [FMDatabase databaseWithPath:dbPath];
    
    //BOOL dbHadError;
    
    if (![dbCategory open]) {
        NSLog(@"Fail To Open");
        return;
    }
    
    [dbCategory executeUpdate:@"update ItemCatg set IC_Description = ? where IC_Category = ?",self.textTextCategoryDesc.text,[self.textCategory.text uppercaseString]];
    
    if ([dbCategory hadError]) {
        [self showAlertView:[dbCategory lastErrorMessage] title:@"Error"];
        [dbCategory close];
    }
    else
    {
        [dbCategory close];
        
        if ([pickImageFlag isEqualToString:@"Pick"]) {
            imgName = [NSString stringWithFormat:@"%@.jpg",self.textCategory.text];
            
            imgData = UIImageJPEGRepresentation(self.imgCategory.image,0.7);
            
            documentsDirectory = [paths objectAtIndex:0];
            imgPath = [documentsDirectory stringByAppendingPathComponent:imgName];
            [imgData writeToFile:imgPath atomically:YES];
            
            //[imgData writeToFile:imgPath atomically:YES];
        }
        [self dismissViewControllerAnimated:YES completion:nil];
        
        if (_delegate != nil) {
            [_delegate resultFromCategoryDetail];
        }
        
    }
    
}

-(void)openPhotoLibrary
{
    UIImagePickerController *picker = [[UIImagePickerController alloc]init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    //self.imgCatPopOver = [[UIPopoverController alloc]initWithContentViewController:picker];
    
    
    picker.modalPresentationStyle = UIModalPresentationPopover;
    picker.popoverPresentationController.sourceView = self.imgCategory;
    picker.popoverPresentationController.sourceRect = CGRectMake(0, 0, 170, 250);
    
    //[self.imgCatPopOver presentPopoverFromRect:CGRectMake(0, 0, 170, 250) inView:self.imgCategory permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    [self presentViewController:picker animated:YES completion:nil];
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
    
    UIAlertController *alert = [[LibraryAPI sharedInstance] showAlertViewWithMsg:msg Title:title];
    [self presentViewController:alert animated:NO completion:nil];
}

#pragma mark - imageview click

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    self.imgCategory.image = chosenImage;
    self.imgCategory.clipsToBounds = true;
    
    pickImageFlag = @"Pick";
    chosenImage = nil;
    [picker dismissViewControllerAnimated:YES completion:nil];
    
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    pickImageFlag = @"UnPick";
    [picker dismissViewControllerAnimated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
     
     

- (IBAction)btnCancelCategory:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - check textview empty
-(BOOL)checkingAllTextView
{
    if ([self.textCategory.text length] == 0) {
        [self showAlertView:@"Category cannot empty" title:@"Warning"];
        return false;
    }
    else if ([self.textTextCategoryDesc.text length] == 0)
    {
        [self showAlertView:@"Description cannot empty" title:@"Warning"];
        return false;
    }
    else
    {
        return true;
    }
}
@end
