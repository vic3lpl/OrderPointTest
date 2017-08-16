//
//  SelectModifierItemViewController.m
//  IpadOrder
//
//  Created by IRS on 10/03/2017.
//  Copyright © 2017 IrsSoftware. All rights reserved.
//

#import "SelectModifierItemViewController.h"
#import "LibraryAPI.h"
#import <FMDB.h>
#import "SelectModifierItemCell.h"
#import <Haneke.h>
#import <QuartzCore/QuartzCore.h>
#import "PublicMethod.h"

@interface SelectModifierItemViewController ()
{
    FMDatabase *dbTable;
    NSMutableArray *modifierItemArray;
    NSString *documentPath;
    NSString *imagePath;
    UIImage *cacheModifierImage;
    NSMutableArray *modifierItemCondimentArray;
    NSUInteger selectedModifierItemIndex;
}
@end

@implementation SelectModifierItemViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.preferredContentSize = CGSizeMake(520, 621);
    self.tableViewPackageItem.delegate  =self;
    self.tableViewPackageItem.dataSource = self;
    modifierItemArray = [[NSMutableArray alloc] init];
    modifierItemCondimentArray = [[NSMutableArray alloc] init];
    
    documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.translucent = NO;
    UINib *finalNib = [UINib nibWithNibName:@"SelectModifierItemCell" bundle:nil];
    [[self tableViewPackageItem]registerNib:finalNib forCellReuseIdentifier:@"SelectModifierItemCell"];
    
    //self.tableViewPackageItem.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self getModifierGroupDetailWithMGHCode:_modifierCode];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - tableview
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [modifierItemArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SelectModifierItemCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SelectModifierItemCell"];
    
    cell.labelPackageItemDesc.text = [[modifierItemArray objectAtIndex:indexPath.row] objectForKey:@"PD_ItemDescription"];
    cell.labelPackageItemPrice.text = [NSString stringWithFormat:@"%@",[NSNumber numberWithDouble:[[[modifierItemArray objectAtIndex:indexPath.row]objectForKey:@"PD_Price"] doubleValue]]];
    
    imagePath = [documentPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",[[modifierItemArray objectAtIndex:indexPath.row]objectForKey:@"PD_ImgFileName"]]];
    cacheModifierImage = [UIImage imageWithContentsOfFile:imagePath];
    
    [cell.imagePackageItem hnk_setImage:cacheModifierImage withKey:[[modifierItemArray objectAtIndex:indexPath.row] objectForKey:@"PD_ItemCode"] placeholder:[UIImage imageNamed:@"no_image.jpg"]];
    
    //[cell.imagePackageItem hnk]
    
    //cell.contentView.backgroundColor = [UIColor clearColor];
    cell.imagePackageItem.layer.cornerRadius = 10.0;
    cell.imagePackageItem.layer.masksToBounds = YES;
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 90;
    //return 360;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    selectedModifierItemIndex = indexPath.row;
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:[[LibraryAPI sharedInstance] getDbPath]];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rsResult = [db executeQuery:@"Select * from ItemCondiment where IC_ItemCode = ?",[[modifierItemArray objectAtIndex:indexPath.row] objectForKey:@"PD_ItemCode"]];
        
        if ([rsResult next]) {
            if ([_modifierAddedCondimentArray count] == 0) {
                [self openAddInCondimentViewWithModifierItemCode:[[modifierItemArray objectAtIndex:indexPath.row] objectForKey:@"PD_ItemCode"]];
            }
            else{
                [self editAddInCondimentViewWithModifierItemCode:[[modifierItemArray objectAtIndex:indexPath.row] objectForKey:@"PD_ItemCode"]];
            }
            
        }
        else
        {
            if (_delegate != nil) {
                [modifierItemCondimentArray addObject:[modifierItemArray objectAtIndex:indexPath.row] ];
                [_delegate finalEditedModifierItemSelectionWithModifierArray:nil WithCondiment:@"No" ItemArray:modifierItemCondimentArray];
                [self.navigationController popViewControllerAnimated:NO];
            }
        }
        [rsResult close];
        
    }];
    
    [queue close];
    
}

#pragma mark - sqlite 3

-(void)getModifierGroupDetailWithMGHCode:(NSString *)mghCode{
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:[[LibraryAPI sharedInstance] getDbPath]];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"Select MD_ItemCode, MD_ItemDescription, MD_Price, MD_ItemFileName, MD_MGCode from ModifierDtl where MD_MGCode = ?",_modifierCode];
        
        while ([rs next]) {
            
            NSMutableDictionary *sectionDic = [NSMutableDictionary dictionary];
            
            [sectionDic setObject:[rs stringForColumn:@"MD_ItemCode"] forKey:@"PD_ItemCode"];
            [sectionDic setObject:[rs stringForColumn:@"MD_ItemDescription"] forKey:@"PD_ItemDescription"];
            [sectionDic setObject:[rs stringForColumn:@"MD_Price"] forKey:@"PD_Price"];
            [sectionDic setObject:@"1" forKey:@"PD_MinChoice"];
            [sectionDic setObject:@"0" forKey:@"PD_CondimentQty"];
            [sectionDic setObject:@"0" forKey:@"PD_NewTotalCondimentSurCharge"];
            [sectionDic setObject:@"PackageItemOrder" forKey:@"OrderType"];
            [sectionDic setObject:_orderPackageSelectedIndex forKey:@"Index"];
            [sectionDic setObject:@"Modifier" forKey:@"PD_ItemType"];
            [sectionDic setObject:[rs stringForColumn:@"MD_ItemFileName"] forKey:@"PD_ImgFileName"];
            [sectionDic setObject:@"Edit"forKey:@"PD_Status"];
            [sectionDic setObject:[rs stringForColumn:@"MD_MGCode"] forKey:@"PD_ModifierHdrCode"];
            [modifierItemArray addObject:sectionDic];
            
            //[modifierItemArray addObject:[rs resultDictionary]];
        }
        
    }];
    [queue close];
    
    [self.tableViewPackageItem reloadData];
}

- (void)openAddInCondimentViewWithModifierItemCode:(NSString *)modifierItemCode {
    OrderAddCondimentViewController *orderAddCondimentViewController = [[OrderAddCondimentViewController alloc]initWithNibName:@"OrderAddCondimentViewController" bundle:nil];
    
    //orderAddCondimentViewController.delegate = self;
    orderAddCondimentViewController.icItemCode = modifierItemCode;
    //orderAddCondimentViewController.selectedCHCode = nil;
    orderAddCondimentViewController.icStatus = @"New";
    orderAddCondimentViewController.addCondimentFrom = @"OrderModifierItemView";
    //orderAddCondimentViewController.parentIndex = _orderPackageSelectedIndex;
    
    UINavigationController *navbar = [[UINavigationController alloc]  initWithRootViewController:orderAddCondimentViewController];
    
    navbar.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    navbar.modalPresentationStyle = UIModalPresentationFormSheet;
    navbar.popoverPresentationController.sourceView = self.view;
    navbar.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2, 1, 1);
    
    [orderAddCondimentViewController setModalPresentationStyle:UIModalPresentationFormSheet];
    [orderAddCondimentViewController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    
    [self presentViewController:navbar animated:NO completion:nil];
}

-(void)editAddInCondimentViewWithModifierItemCode:(NSString *)modifierItemCode{
    OrderAddCondimentViewController *orderAddCondimentViewController = [[OrderAddCondimentViewController alloc]initWithNibName:@"OrderAddCondimentViewController" bundle:nil];
    //orderAddCondimentViewController.delegate = self;
    orderAddCondimentViewController.addCondimentFrom = @"OrderModifierItemView";
    orderAddCondimentViewController.icItemCode = modifierItemCode;
    orderAddCondimentViewController.selectedCHCode = nil;
    orderAddCondimentViewController.icStatus = @"Edit";
    //orderAddCondimentViewController.showAll = showAll;
    if (_modifierAddedCondimentArray.count == 0){
        orderAddCondimentViewController.parentIndex = _orderPackageSelectedIndex;
    }
    else
    {
        orderAddCondimentViewController.icAddedArray = _modifierAddedCondimentArray;
    }

    UINavigationController *navbar = [[UINavigationController alloc]  initWithRootViewController:orderAddCondimentViewController];
    
    navbar.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    navbar.modalPresentationStyle = UIModalPresentationFormSheet;
    navbar.popoverPresentationController.sourceView = self.view;
    navbar.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2, 1, 1);
    
    [orderAddCondimentViewController setModalPresentationStyle:UIModalPresentationFormSheet];
    [orderAddCondimentViewController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    
    [self presentViewController:navbar animated:NO completion:nil];
}

#pragma mark - delegate from OrderAddOnCondiment
-(void)passBackToOrderModifierItemDetailWithCondimentDtl:(NSMutableArray *)array DisplayFormat:(NSString *)displayFormat TotalCondimentPrice:(double)totalCondimentPrice Status:(NSString *)status CondimentUnitPrice:(double)condimentUnitPrice
{
    [modifierItemCondimentArray addObject:[modifierItemArray objectAtIndex:selectedModifierItemIndex]];
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    data = [modifierItemCondimentArray objectAtIndex:0];
    [data setValue:[NSString stringWithFormat:@"%0.2f",totalCondimentPrice] forKey:@"PD_NewTotalCondimentSurCharge"];
    [modifierItemCondimentArray replaceObjectAtIndex:0 withObject:data];
    data = nil;
    
    for (int i = 0; i < array.count; i++) {
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        data = [array objectAtIndex:i];
        [data setValue:[NSString stringWithFormat:@"%@",_orderPackageSelectedIndex] forKey:@"ParentIndex"];
        [array replaceObjectAtIndex:i withObject:data];
        data = nil;
        
    }
    
    //[modifierItemCondimentArray addObjectsFromArray:array];
    
    if (_delegate != nil) {
        if (array.count >= 1) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            dict = [modifierItemCondimentArray objectAtIndex:0];
            [dict setValue:[NSString stringWithFormat:@"%lu",(unsigned long)array.count] forKey:@"PD_CondimentQty"];
            [modifierItemCondimentArray replaceObjectAtIndex:0 withObject:dict];
            dict = nil;
            if ([status isEqualToString:@"New"]) {
                [_delegate finalModifierItemSelectionWithModifierArray:array WithCondiment:@"Yes" ItemArray:modifierItemCondimentArray];
            }
            else{
                [_delegate finalEditedModifierItemSelectionWithModifierArray:array WithCondiment:@"Yes" ItemArray:modifierItemCondimentArray];
            }
        }
        else{
            if ([status isEqualToString:@"New"]) {
                [_delegate finalModifierItemSelectionWithModifierArray:array WithCondiment:@"No" ItemArray:modifierItemCondimentArray];
            }
            else{
                [_delegate finalEditedModifierItemSelectionWithModifierArray:array WithCondiment:@"No" ItemArray:modifierItemCondimentArray];
            }
        }
        modifierItemCondimentArray = nil;
        modifierItemArray = nil;
        [self.navigationController popViewControllerAnimated:NO];
    }
    
}

/*
-(void)passBackToOrderModifierItemDetailWithEditedCondimentDtl:(NSMutableArray *)array DisplayFormat:(NSString *)displayFormat TotalCondimentPrice:(double)totalCondimentPrice Status:(NSString *)status CondimentUnitPrice:(double)condimentUnitPrice
{
    [modifierItemCondimentArray addObject:[modifierItemArray objectAtIndex:selectedModifierItemIndex]];
    
    for (int i = 0; i < array.count; i++) {
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        data = [array objectAtIndex:i];
        [data setValue:[NSString stringWithFormat:@"%@",_orderPackageSelectedIndex] forKey:@"ParentIndex"];
        [array replaceObjectAtIndex:i withObject:data];
        data = nil;
        
    }
    
    //[modifierItemCondimentArray addObjectsFromArray:array];
    
    if (_delegate != nil) {
        if (array.count >= 1) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            dict = [modifierItemCondimentArray objectAtIndex:0];
            [dict setValue:[NSString stringWithFormat:@"%lu",(unsigned long)array.count] forKey:@"PD_CondimentQty"];
            [modifierItemCondimentArray replaceObjectAtIndex:0 withObject:dict];
            dict = nil;
            [_delegate finalEditedModifierItemSelectionWithModifierArray:array WithCondiment:@"Yes" ItemArray:modifierItemCondimentArray];
        }
        else{
            [_delegate finalEditedModifierItemSelectionWithModifierArray:array WithCondiment:@"No" ItemArray:modifierItemCondimentArray];
        }
        modifierItemCondimentArray = nil;
        modifierItemArray = nil;
        [self.navigationController popViewControllerAnimated:NO];
    }
}
*/
@end
