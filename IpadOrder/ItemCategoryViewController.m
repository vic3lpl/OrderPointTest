//
//  ItemCategoryViewController.m
//  IpadOrder
//
//  Created by IRS on 7/2/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "ItemCategoryViewController.h"
#import "LibraryAPI.h"
#import <FMDB.h>
#import <MBProgressHUD.h>
#import "ItemCatgTableViewCell.h"


@interface ItemCategoryViewController ()
{
    NSString *userAction;
    NSMutableArray *category;
    NSUInteger categorySelectedIndex;
    BOOL dbHadError;
    NSString *dbPath;
    FMDatabase *dbItemCat;
    NSString *terminalType;
    // for image use
    NSString *documentPath;
    NSString *filePath;
    NSString *alertFlag;
    
}
//@property (nonatomic, strong)UIPopoverController *popOverCatDetail;
@property (nonatomic, strong)UIPopoverPresentationController *popOverCatDetail;
@end

@implementation ItemCategoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self setTitle:@"Category"];
    category = [[NSMutableArray alloc]init];
    
    dbPath = [[LibraryAPI sharedInstance]getDbPath];
    terminalType = [[LibraryAPI sharedInstance]getWorkMode];
    
    documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    UIBarButtonItem *addBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addCategory:)];
    self.navigationItem.rightBarButtonItem = addBtn;
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    
    //self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:34/255.0 green:171/255.0 blue:241/255.0 alpha:1.0];
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.translucent = NO;
    UINib *itemCatgNib = [UINib nibWithNibName:@"ItemCatgTableViewCell" bundle:nil];
    [[self catTableView] registerNib:itemCatgNib forCellReuseIdentifier:@"ItemCatgTableViewCell"];
    self.catTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.catTableView.delegate = self;
    self.catTableView.dataSource = self;
    
    [self checkItemCatg];
}

-(void)viewDidLayoutSubviews
{
    if ([self.catTableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.catTableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([self.catTableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.catTableView setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - sqlite

-(void)checkItemCatg
{
    dbItemCat = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbItemCat open]) {
        NSLog(@"Fail To Open");
        return;
    }
    [category removeAllObjects];
    FMResultSet *rs = [dbItemCat executeQuery:@"Select * from ItemCatg"];
    //category = [NSMutableArray array];
    while ([rs next]) {
        //[category addObjectsFromArray:[rs resultDictionary]];
        //dict = [rs resultDictionary];
        [category addObject:[rs resultDictionary]];
    }
    
    [rs close];
    [dbItemCat close];
    [self.catTableView reloadData];
}

#pragma mark - tableview


-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

-(void)addCategory:(id)sender
{
    if ([terminalType isEqualToString:@"Main"]) {
        ItemCategoryDetailViewController *itemCategoryDetailViewController = [[ItemCategoryDetailViewController alloc] init];
        itemCategoryDetailViewController.delegate = self;
        itemCategoryDetailViewController.catStatus = @"New";
        
        
        UINavigationController *navbar = [[UINavigationController alloc]  initWithRootViewController:itemCategoryDetailViewController];
        navbar.modalPresentationStyle = UIModalPresentationPopover;
        
        _popOverCatDetail = [navbar popoverPresentationController];
        _popOverCatDetail.delegate = self;
        _popOverCatDetail.permittedArrowDirections = 0;
        
        
        _popOverCatDetail.sourceView = self.view;
        _popOverCatDetail.sourceRect = CGRectMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2, 1, 1);
        [self presentViewController:navbar animated:YES completion:nil];
        
        /*
        self.popOverCatDetail = [[UIPopoverController alloc]initWithContentViewController:navbar];
        self.popOverCatDetail.delegate = self;
        [self.popOverCatDetail presentPopoverFromRect:CGRectMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2, 1, 1) inView:self.view permittedArrowDirections:0 animated:YES];
         */
    }
    else
    {
        //[self showMyHudMessageBoxWithMessage:@"Terminal Cannot Add Category"];
        [self showAlertView:@"Terminal cannot add category" title:@"Warning"];
    }
    
    
    
}

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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    // Return the number of rows in the section.
    return [category count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *Identifier = @"ItemCatgTableViewCell";
    
    ItemCatgTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:Identifier];
    
    filePath = [documentPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg",[[category objectAtIndex:indexPath.row] objectForKey:@"IC_Category"]]];
    
    cell.imgItemCatgCell.image = [UIImage imageWithContentsOfFile:filePath];
    cell.imgItemCatgCell.clipsToBounds = YES;
    cell.imgItemCatgCell.layer.cornerRadius = 10.0;
    
    if (cell.imgItemCatgCell.image == nil) {
        cell.imgItemCatgCell.image = [UIImage imageNamed:@"no_image.jpg"];
    }
    
    cell.labelItemCatgNameCell.text = [[category objectAtIndex:indexPath.row] objectForKey:@"IC_Category"];
    cell.labelItemCatgDescription.textColor = [UIColor colorWithRed:36/255.0 green:36/255.0 blue:36/255.0 alpha:1.0];
    cell.labelItemCatgDescription.text = [[category objectAtIndex:indexPath.row]objectForKey:@"IC_Description"];
    cell.labelItemCatgDescription.textColor = [UIColor colorWithRed:128/255.0 green:128/255.0 blue:128/255.0 alpha:1.0];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //remove the deleted object from your data source.
        //If your data source is an NSMutableArray, do this
        if ([terminalType isEqualToString:@"Main"]) {
            userAction = @"Delete";
            alertFlag = @"Delete";
            categorySelectedIndex = indexPath.row;
            
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"Warning"
                                         message:@"Sure To Delete ?"
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* yesButton = [UIAlertAction
                                        actionWithTitle:@"OK"
                                        style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * action) {
                                            [self alertActionCategorySelction];
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
            categorySelectedIndex = indexPath.row;
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning"
                                                            message:@"Sure To Delete ?"
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:@"Cancel",nil];
            [alert show];
             */
        }
        else
        {
            //[self showMyHudMessageBoxWithMessage:@"Terminal Cannot Delete Category"];
            [self showAlertView:@"Terminal cannot delete category" title:@"Warning"];
        }
        
        
        // tell table to refresh now
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([terminalType isEqualToString:@"Main"]) {
        userAction = @"Edit";
        categorySelectedIndex = indexPath.row;
        
        
        ItemCategoryDetailViewController *itemCategoryDetailViewController = [[ItemCategoryDetailViewController alloc] init];
        itemCategoryDetailViewController.delegate = self;
        itemCategoryDetailViewController.catStatus = @"Edit";
        itemCategoryDetailViewController.category = [[category objectAtIndex:indexPath.row] objectForKey:@"IC_Category"];
        UINavigationController *navbar = [[UINavigationController alloc]  initWithRootViewController:itemCategoryDetailViewController];
        navbar.modalPresentationStyle = UIModalPresentationPopover;
        
        _popOverCatDetail = [navbar popoverPresentationController];
        _popOverCatDetail.delegate = self;
        _popOverCatDetail.permittedArrowDirections = 0;
        _popOverCatDetail.sourceView = self.view;
        _popOverCatDetail.sourceRect = CGRectMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2, 1, 1);
        [self presentViewController:navbar animated:YES completion:nil];
        
        
        /*
        self.popOverCatDetail = [[UIPopoverController alloc]initWithContentViewController:navbar];
        self.popOverCatDetail.delegate = self;
        [self.popOverCatDetail presentPopoverFromRect:CGRectMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2, 1, 1) inView:self.view permittedArrowDirections:0 animated:YES];
         */
    }
    else
    {
        [self showMyHudMessageBoxWithMessage:@"Terminal Cannot Access"];
    }
    
    
    //[self editCategory];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    //[self.catTextV resignFirstResponder];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
    //return 360;
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

#pragma mark - alertview response
- (void)alertActionCategorySelction
{
    
    dbItemCat = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbItemCat open]) {
        NSLog(@"Fail To Open");
        return;
    }
    
    if ([userAction isEqualToString:@"Delete"]) {
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
        
        
        [queue inDatabase:^(FMDatabase *db) {
            FMResultSet *rs = [db executeQuery:@"Select * from ItemMast where IM_Category = ?",[[category objectAtIndex:categorySelectedIndex]objectForKey:@"IC_Category"]];
            
            if ([rs next]) {
                
                [rs close];
                
                [self showAlertView:@"Data in use" title:@"Warning"];
            }
            else
            {
                dbHadError = [dbItemCat executeUpdate:@"delete from ItemCatg where IC_Category = ?",[[category objectAtIndex:categorySelectedIndex]objectForKey:@"IC_Category"]];
                if (dbHadError) {
                    //allowDelTax = YES;
                    
                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
                    
                    NSString *filePaths = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg",[[category objectAtIndex:categorySelectedIndex]objectForKey:@"IC_Category"]]];
                    
                    [fileManager removeItemAtPath:filePaths error:nil];
                    
                    
                }
                else
                {
                    [self showAlertView:[db lastErrorMessage] title:@"Warning"];
                }
            }
            
        }];
        
    }
    
    [dbItemCat close];
    [self checkItemCatg];
    //[self.catTableView reloadData];
    
    
}

-(void)showAlertView:(NSString *)msg title:(NSString *)title
{
    //alertFlag = @"Alert";
    /*
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:msg
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
     */
    UIAlertController *alert = [[LibraryAPI sharedInstance] showAlertViewWithMsg:msg Title:title];
    
    [self presentViewController:alert animated:YES completion:nil];
    
    alert = nil;
    
}


#pragma mark - delegate

-(void)resultFromCategoryDetail
{
    [self checkItemCatg];
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
