//
//  OrderPackageItemViewController.m
//  IpadOrder
//
//  Created by IRS on 09/03/2017.
//  Copyright © 2017 IrsSoftware. All rights reserved.
//

#import "OrderPackageItemViewController.h"
#import "OrderAddCondimentViewController.h"
#import "LibraryAPI.h"
#import <FMDB.h>
#import "PublicMethod.h"
#import "TestVVVViewController.h"
#import "SelectModifierCollectionViewCell.h"
#import <Haneke.h>
#import "FullyHorizontalFlowLayout.h"
#import "PackageItemTableViewCell.h"

static NSString * const modifierItemMastCellIdentifier = @"SelectModifierCollectionViewCell";
@interface OrderPackageItemViewController ()
{
    NSMutableArray *packageItemDetailArray;
    FMDatabase *dbTable;
    NSUInteger selectedTableViewIndex;
    
    NSString *imgPath;
    UIImage *imgBtn;
    NSString *imgDir;
    
    NSString *modifierGroupCode;
    NSUInteger modifierItemMastCount;
    NSMutableArray *modifierItemArray;
    NSArray *modifierAddedCondimentArray;
    NSString *modifierItemCode;
    NSUInteger modifierItemIndex;
    NSString *preSelectModifierItemCode;
}
@end

@implementation OrderPackageItemViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    packageItemDetailArray = [[NSMutableArray alloc] init];
    modifierItemArray = [[NSMutableArray alloc] init];
    //modifierAddedCondimentArray = [[NSMutableArray alloc] init];
    
    modifierItemMastCount = 0;
    imgDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    [self setTitle:_imName];
    
    self.tableViewPackageItemListing.delegate = self;
    self.tableViewPackageItemListing.dataSource = self;
    self.preferredContentSize = CGSizeMake(857, 577);
    
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.translucent = NO;
    
    UINib *modifierItemCollectionNib = [UINib nibWithNibName:modifierItemMastCellIdentifier bundle:nil];
    
    [_collectionModifierItemList registerNib:modifierItemCollectionNib forCellWithReuseIdentifier:modifierItemMastCellIdentifier];
    
    FullyHorizontalFlowLayout *collectionViewLayout = [FullyHorizontalFlowLayout new];
    
    self.scrollViewModifierItem.delegate = self;
    
    self.tableViewPackageItemListing.clipsToBounds = NO;
    self.tableViewPackageItemListing.layer.masksToBounds = NO;
    
    [self.tableViewPackageItemListing.layer setShadowColor:[[UIColor grayColor] CGColor]];
    [self.tableViewPackageItemListing.layer setShadowOffset:CGSizeMake(0, 0)];
    [self.tableViewPackageItemListing.layer setShadowRadius:5.0];
    [self.tableViewPackageItemListing.layer setShadowOpacity:1];
    
    [self.viewModifierItem.layer setShadowColor:[[UIColor grayColor] CGColor]];
    self.viewModifierItem.layer.masksToBounds = NO;
    self.viewModifierItem.layer.shadowOffset = CGSizeMake(0, 0);
    self.viewModifierItem.layer.shadowRadius = 5;
    self.viewModifierItem.layer.shadowOpacity = 1;
    
    collectionViewLayout.itemSize = CGSizeMake(130., 130.);
    [collectionViewLayout setSectionInset:UIEdgeInsetsMake(0, 5, 0, 5)];
    
    [self.collectionModifierItemList setCollectionViewLayout:collectionViewLayout];
    _collectionModifierItemList.dataSource = self;
    _collectionModifierItemList.delegate = self;
    _collectionModifierItemList.pagingEnabled = true;
    
    self.tableViewPackageItemListing.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    if (_completedOrderPackageArray.count == 0) {
        [self getPackageItemDetail];
    }
    else
    {
        [self makeEditPackageItemDetailArray];
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)makeEditPackageItemDetailArray
{
    //NSLog(@"%@",_completedOrderPackageArray);
    
    NSPredicate *predicate;
    
    for (int i = 0; i < _completedOrderPackageArray.count; i++) {
        
        //NSMutableDictionary *sectionDic = [NSMutableDictionary dictionary];
        if ([[[_completedOrderPackageArray objectAtIndex:i] objectForKey:@"OrderType"] isEqualToString:@"PackageItemOrder"]) {
            
            predicate = [NSPredicate predicateWithFormat:@"ParentIndex MATCHES[cd] %@",
                         [[_completedOrderPackageArray objectAtIndex:i] objectForKey:@"Index"]];
            
            NSArray *condimentArray = [_completedOrderPackageArray filteredArrayUsingPredicate:predicate];
            
            [self generatePackageItemDetailArayWithDict:[_completedOrderPackageArray objectAtIndex:i] PackageIndex:[[[_completedOrderPackageArray objectAtIndex:i] objectForKey:@"Index"] integerValue]Status:@"Edit" CondimentQty:condimentArray.count];
            
            condimentArray = nil;
            
        }
        else{
            
            [self generatePackageItemCondimentDetailWithDict:[_completedOrderPackageArray objectAtIndex:i] ParentIndex:[[[_completedOrderPackageArray objectAtIndex:i] objectForKey:@"ParentIndex"] integerValue]];
        }
            /*
            [sectionDic setObject:[[_completedOrderPackageArray objectAtIndex:i] objectForKey:@"IM_DiscountAmt"] forKey:@"IM_DiscountAmt"];
            [sectionDic setObject:[[_completedOrderPackageArray objectAtIndex:i] objectForKey:@"OrderType"] forKey:@"OrderType"];
            [sectionDic setObject:[[_completedOrderPackageArray objectAtIndex:i] objectForKey:@"PD_CondimentQty"] forKey:@"PD_CondimentQty"];
            [sectionDic setObject:[[_completedOrderPackageArray objectAtIndex:i] objectForKey:@"PD_ItemCode"] forKey:@"PD_ItemCode"];
            [sectionDic setObject:[[_completedOrderPackageArray objectAtIndex:i] objectForKey:@"PD_ItemDescription"] forKey:@"PD_ItemDescription"];
            [sectionDic setObject:[[_completedOrderPackageArray objectAtIndex:i] objectForKey:@"PD_ItemType"] forKey:@"PD_ItemType"];
            [sectionDic setObject:[[_completedOrderPackageArray objectAtIndex:i] objectForKey:@"PD_MinChoice"] forKey:@"PD_MinChoice"];
            [sectionDic setObject:[[_completedOrderPackageArray objectAtIndex:i] objectForKey:@"PD_Modi//fierGroupCode"] forKey:@"PD_Mod//ifierGroupCode"];
            [sectionDic setObject:[[_completedOrderPackageArray objectAtIndex:i] objectForKey:@"PD_NewTotalCondimentSurCharge"] forKey:@"PD_NewTotalCondimentSurCharge"];
            [sectionDic setObject:[[_completedOrderPackageArray objectAtIndex:i] objectForKey:@"PD_Price"] forKey:@"PD_Price"];
            [sectionDic setObject:[[_completedOrderPackageArray objectAtIndex:i] objectForKey:@"PD_Status"] forKey:@"PD_Status"];
            
            [sectionDic setObject:[[_completedOrderPackageArray objectAtIndex:i] objectForKey:@"PackageIndex"] forKey:@"PackageIndex"];
            [sectionDic setObject:[[_completedOrderPackageArray objectAtIndex:i] objectForKey:@"PackageItemCode"] forKey:@"PackageItemCode"];
            [sectionDic setObject:[[_completedOrderPackageArray objectAtIndex:i] objectForKey:@"PackageItemDesc"] forKey:@"PackageItemDesc"];
            [sectionDic setObject:[[_completedOrderPackageArray objectAtIndex:i] objectForKey:@"ParentIndex"] forKey:@"ParentIndex"];
            [sectionDic setObject:[[_completedOrderPackageArray objectAtIndex:i] objectForKey:@"UnderPackageItemYN"] forKey:@"UnderPackageItemYN"];
            
        }
        else
        {
            [sectionDic setObject:[[_completedOrderPackageArray objectAtIndex:i] objectForKey:@"CDCode"] forKey:@"CDCode"];
            [sectionDic setObject:[[_completedOrderPackageArray objectAtIndex:i] objectForKey:@"CDDescription"] forKey:@"CDDescription"];
            [sectionDic setObject:[[_completedOrderPackageArray objectAtIndex:i] objectForKey:@"CDPrice"] forKey:@"CDPrice"];
            [sectionDic setObject:[[_completedOrderPackageArray objectAtIndex:i] objectForKey:@"CHCode"] forKey:@"CHCode"];
            [sectionDic setObject:[[_completedOrderPackageArray objectAtIndex:i] objectForKey:@"IM_DiscountAmt"] forKey:@"IM_DiscountAmt"];
            [sectionDic setObject:[[_completedOrderPackageArray objectAtIndex:i] objectForKey:@"ItemCode"] forKey:@"ItemCode"];
            [sectionDic setObject:[[_completedOrderPackageArray objectAtIndex:i] objectForKey:@"OrderType"] forKey:@"OrderType"];
            [sectionDic setObject:_imCode forKey:@"PackageItemCode"];
            [sectionDic setObject:_imName forKey:@"PackageItemDesc"];
            
            [sectionDic setObject:[[_completedOrderPackageArray objectAtIndex:i] objectForKey:@"ParentIndex"] forKey:@"ParentIndex"];
            [sectionDic setObject:@"Yes" forKey:@"UnderPackageItemYN"];
            [sectionDic setObject:[[_completedOrderPackageArray objectAtIndex:i] objectForKey:@"UnitQty"] forKey:@"UnitQty"];
             */
        //}
        
        
        
    }
    predicate = nil;
    [self.tableViewPackageItemListing reloadData];
    [self reIndexOrderingData];
    
    //NSLog(@"ccc %@",packageItemDetailArray);
}

#pragma mark - sqlite

-(void)getPackageItemDetail
{
    dbTable = [FMDatabase databaseWithPath:[[LibraryAPI sharedInstance] getDbPath]];
    
    if (![dbTable open]) {
        NSLog(@"Fail To Open");
        return;
    }
    
    [packageItemDetailArray removeAllObjects];
    
    FMResultSet *rs = [dbTable executeQuery:@"Select PD_ItemCode as IM_ItemCode, PD_ItemDescription as IM_Description,PD_ItemDescription as MH_Description, PD_Price as IM_Price, PD_ItemType, PD_MinChoice"
                       ",IFNULL(t2.T_Name,'-') as IM_ServiceTaxCode,IFNULL(t1.T_Name,'-') as IM_GSTCode,IFNULL(P.P_PortName,'0.0.0.0') as IM_IpAddress, IFNULL(P.P_PrinterName,'NonPrinter') as IM_PrinterName, 0 as IM_TotalCondimentSurCharge from PackageItemDtl PD "
                       " left join ItemMast IM on PD.PD_ItemCode = IM.IM_ItemCode"
                       " left join Tax t1 on IM.IM_Tax = t1.T_Name "
                       " left join Tax t2 on IM.IM_ServiceTax = t2.T_Name "
                       " left join (select IP_ItemNo, IP_PrinterName from ItemPrinter group by IP_ItemNo) as IP on  IP.IP_ItemNo = IM.IM_ItemCode"
                       " left join Printer P on IP.IP_PrinterName = P.P_PrinterName"
                       " where PD.PD_Code = ? order by PD_ID",_imCode];
    NSUInteger index = 1;
    NSUInteger rsCount = 0;
    NSUInteger highLightRow = 0;
    NSString *firstModifier = @"FirstModifier";
    
    while ([rs next]) {
        if ([[rs stringForColumn:@"PD_ItemType"] isEqualToString:@"Modifier"]) {
            //firstModifier = @"FirstModifier";
            if ([firstModifier isEqualToString:@"FirstModifier"]) {
                modifierGroupCode = [rs stringForColumn:@"IM_ItemCode"];
                highLightRow = rsCount;
                selectedTableViewIndex = highLightRow;
                firstModifier = @"SecondModifier";
            }
            
        }
        if ([rs intForColumn:@"PD_MinChoice"] >= 1) {
            for (int i = 0; i < [rs intForColumn:@"PD_MinChoice"]; i++) {
                
                [self generatePackageItemDetailArayWithDict:[rs resultDictionary] PackageIndex:index Status:@"New" CondimentQty:0];
                //data = nil;
                index++;
                rsCount++;
                
            }
        }
        
    }
    
    [rs close];
    [dbTable close];
    [self.tableViewPackageItemListing reloadData];
    
    //if ([firstModifier length]>0) {
        NSIndexPath *indexPathForFirstModifierRow = [NSIndexPath indexPathForItem:highLightRow inSection:0];
        [self.tableViewPackageItemListing selectRowAtIndexPath:indexPathForFirstModifierRow animated:NO  scrollPosition:UITableViewScrollPositionNone];
        [self tableView:self.tableViewPackageItemListing didSelectRowAtIndexPath:indexPathForFirstModifierRow];
    //}
    
    
    //[self getModifierItemMastDetail];
}


-(void)getModifierItemMastDetail
{
    [modifierItemArray removeAllObjects];
    modifierItemMastCount = 0;
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:[[LibraryAPI sharedInstance] getDbPath]];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"Select * "
                           " ,IFNULL(t2.T_Name,'-') as Svc_Name,IFNULL(t1.T_Name,'-') as T_Name"
                           " ,IFNULL(P.P_PortName,'0.0.0.0') as IM_IpAddress, "
                           " IFNULL(P.P_PrinterName,'NonPrinter') as IM_PrinterName "
                           " ,IFNULL(MD_ItemFileName,'no_image.jpg') as MD_ImgName"
                           " from ModifierDtl MD"
                           " left join ModifierHdr MH on MD.MD_MGCode = MH.MH_Code"
                           " left join ItemMast IM on MD.MD_ItemCode = IM.IM_ItemCode"
                           " left join Tax t1 on IM.IM_Tax = t1.T_Name "
                           " left join Tax t2 on IM.IM_ServiceTax = t2.T_Name "
                           " left join (select IP_ItemNo, IP_PrinterName from ItemPrinter group by IP_ItemNo) as IP on  IP.IP_ItemNo = IM.IM_ItemCode"
                           " left join Printer P on IP.IP_PrinterName = P.P_PrinterName"
                           " where MD.MD_MGCode = ?",modifierGroupCode];
        
        while ([rs next]) {
            
            //NSMutableDictionary *sectionDic = [NSMutableDictionary dictionary];
            
            NSMutableDictionary *data = [NSMutableDictionary dictionary];
            
            [data setObject:@"Non" forKey:@"Status"];
            [data setObject:@"NonSONo" forKey:@"SOH_DocNo"];
            [data setObject:[rs stringForColumn:@"MD_ItemCode"] forKey:@"IM_ItemCode"];
            [data setObject:[rs stringForColumn:@"MD_ItemDescription"] forKey:@"IM_Description"];
            //--------------item with condiment unit price = condiment unitprice + item unitprice------------
            
            [data setObject:[rs stringForColumn:@"MD_Price"] forKey:@"IM_Price"];
            
            //----------------------------------------------------------------------------------------
            [data setObject:[rs stringForColumn:@"MD_Price"] forKey:@"IM_SalesPrice"];
            //one item selling price not included tax
            [data setObject:[rs stringForColumn:@"MD_Price"] forKey:@"IM_SellingPrice"];
            //[data setObject:[NSString stringWithFormat:@"%0.6f",itemTaxAmt] forKey:@"IM_Tax"];
            [data setObject:@"0.00" forKey:@"IM_Tax"];
            [data setObject:@"0" forKey:@"IM_Qty"];
            [data setObject:@"0.00" forKey:@"IM_DiscountInPercent"];
            
            [data setObject:@"0.00" forKey:@"IM_Gst"];
            
            [data setObject:@"0.00" forKey:@"IM_TotalTax"]; //sum tax amt
            [data setObject:@"0" forKey:@"IM_DiscountType"];
            [data setObject:@"0" forKey:@"IM_Discount"]; // discount given
            [data setObject:@"0.00" forKey:@"IM_DiscountAmt"];  // sum discount
            [data setObject:@"0" forKey:@"IM_SubTotal"];
            [data setObject:[rs stringForColumn:@"MD_Price"] forKey:@"IM_Total"];
            
            //------------tax code-----------------
            [data setObject:[rs stringForColumn:@"T_Name"] forKey:@"IM_GSTCode"];
            
            //-------------service tax-------------
            [data setObject:[rs stringForColumn:@"Svc_Name"] forKey:@"IM_ServiceTaxCode"];  //svc tax code
            [data setObject:@"0.00" forKey:@"IM_ServiceTaxAmt"]; // service tax amount
            [data setObject:@"0.00" forKey:@"IM_ServiceTaxRate"];
            [data setObject:@"0.00" forKey:@"IM_ServiceTaxGstAmt"];
            [data setObject:@"0.00" forKey:@"IM_ServiceTaxGstAmtLong"];
            //[data setObject:textServiceTaxGst forKey:@"IM_ServiceTaxGstAmt"];
            
            //------------------------------------------------------------------------------------------
            [data setObject:@"0.00"forKey:@"IM_totalItemSellingAmt"];  // subtotal not include tax n will replace this
            [data setObject:@"0.00" forKey:@"IM_totalItemSellingAmtLong"];  // subtotal not include tax
            [data setObject:@"0.00" forKey:@"IM_totalItemTaxAmtLong"];  // total tax amt
            
            [data setObject:@"0.00" forKey:@"IM_totalServiceTaxAmt"];  // total service tax amt
            
            [data setObject:@"" forKey:@"IM_Remark"];
            [data setObject:@"" forKey:@"IM_TableName"];
            //---------for print kitchen receipt----------------
            
            [data setObject:@"Print" forKey:@"IM_Print"];
            [data setObject:@"1" forKey:@"IM_OrgQty"];
            [data setObject:[rs stringForColumn:@"IM_IpAddress"] forKey:@"IM_IpAddress"];
            [data setObject:[rs stringForColumn:@"IM_PrinterName"] forKey:@"IM_PrinterName"];
            //---------for item dine in or take away ------------
            [data setObject:@"" forKey:@"IM_TakeAwayYN"];
            
            //--------- for table pax no ---------------------
            [data setObject:@"1" forKey:@"SOH_PaxNo"];
            [data setObject:@"" forKey:@"PayDocType"];
            //[data setObject:@"PackageItemOrder" forKey:@"OrderType"];
            [data setObject:@"0.00" forKey:@"IM_TotalCondimentSurCharge"];
            [data setObject:@"0.00" forKey:@"IM_NewTotalCondimentSurCharge"];
            //[data setObject:@"-" forKey:@"Index"];
            //---------for main to decide this array-------------
            if ([[[LibraryAPI sharedInstance] getWorkMode] isEqualToString:@"Terminal"]) {
                [data setObject:@"Order" forKey:@"IM_Flag"];
                [data setObject:@"0.00" forKey:@"IM_labelTotal"];
                [data setObject:@"0.00" forKey:@"IM_labelTotalDiscount"];
                [data setObject:@"0.00" forKey:@"IM_labelRound"];
                [data setObject:@"0.00" forKey:@"IM_labelSubTotal"];
                [data setObject:@"0.00" forKey:@"IM_labelTaxTotal"];
                [data setObject:@"0.00" forKey:@"IM_labelServiceTaxTotal"];
                [data setObject:@"0.00" forKey:@"IM_serviceTaxGstTotal"];
                [data setObject:@"" forKey:@"IM_Table"];
                
                [data setObject:@"" forKey:@"CName"];
                [data setObject:@"" forKey:@"CAdd1"];
                [data setObject:@"" forKey:@"CAdd2"];
                [data setObject:@"" forKey:@"CAdd3"];
                [data setObject:@"" forKey:@"CTelNo"];
                [data setObject:@"" forKey:@"CGstNo"];
                
            }
            
            //[sectionDic setObject:[rs stringForColumn:@"MD_ItemCode"] forKey:@"PD_ItemCode"];
            //[sectionDic setObject:[rs stringForColumn:@"MD_ItemDescription"] forKey:@"PD_ItemDescription"];
            //[sectionDic setObject:[rs stringForColumn:@"MD_Price"] forKey:@"PD_Price"];
            [data setObject:@"1" forKey:@"PD_MinChoice"];
            [data setObject:@"0" forKey:@"PD_CondimentQty"];
            [data setObject:@"0" forKey:@"PD_NewTotalCondimentSurCharge"];
            [data setObject:@"PackageItemOrder" forKey:@"OrderType"];
            [data setObject:[NSString stringWithFormat:@"%lu",selectedTableViewIndex] forKey:@"PackageIndex"];
            [data setObject:@"Modifier" forKey:@"PD_ItemType"];
            [data setObject:[rs stringForColumn:@"MD_ImgName"] forKey:@"PD_ImgFileName"];
            [data setObject:@"Edit" forKey:@"PD_Status"];
            [data setObject:[rs stringForColumn:@"MD_MGCode"] forKey:@"PD_ModifierHdrCode"];
            [data setObject:[rs stringForColumn:@"MH_Description"] forKey:@"MH_Description"];
            [data setObject:@"0.00" forKey:@"IM_DiscountAmt"];
            
            [data setObject:@"Yes" forKey:@"UnderPackageItemYN"];
            [data setObject:_imCode  forKey:@"PackageItemCode"];
            [data setObject:_imName forKey:@"PackageItemDesc"];
            [data setValue:_orderingViewParentIndex forKey:@"PackageItemIndex"];
            
            [modifierItemArray addObject:data];
            modifierItemMastCount++;
            //[modifierItemArray addObject:[rs resultDictionary]];
        }
        
    }];
    [queue close];
    
    [self makeUiCollectionView];
    //[self.collectionModifierItemList reloadData];
}



#pragma mark - collectionView
-(void)makeUiCollectionView
{
    
    //_collectionViewMenu.contentInset = UIEdgeInsetsMake(0, 20, 0, 20);
    _collectionModifierItemList.contentSize = CGSizeMake(_collectionModifierItemList.frame.size.width * modifierItemMastCount, _collectionModifierItemList.frame.size.height);
    
    self.scrollViewModifierItem.contentSize = _collectionModifierItemList.contentSize;
    [_collectionModifierItemList addGestureRecognizer:self.scrollViewModifierItem.panGestureRecognizer];
    _collectionModifierItemList.panGestureRecognizer.enabled = NO;
    _collectionModifierItemList.pagingEnabled = true;
    [_collectionModifierItemList reloadData];
    
    
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    
    return modifierItemArray.count;
    
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    self.labelModifierTitle.text = [[modifierItemArray objectAtIndex:indexPath.row]objectForKey:@"MH_Description"];
    
    static NSString *identifier = @"SelectModifierCollectionViewCell";
    
    SelectModifierCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
        
    imgPath = [imgDir stringByAppendingPathComponent:[[modifierItemArray objectAtIndex:indexPath.row]objectForKey:@"PD_ImgFileName"]];
        
    imgBtn = [UIImage imageWithContentsOfFile:imgPath];
        
    [cell.imageMItemMast hnk_setImage:imgBtn withKey:[[modifierItemArray objectAtIndex:indexPath.row]objectForKey:@"IM_ItemCode"] placeholder:[UIImage imageNamed:@"no_image.jpg"]];
        
    cell.labelMDesc.text = [[modifierItemArray objectAtIndex:indexPath.row]objectForKey:@"IM_Description"];
    cell.labelMSurcharge.text = [[modifierItemArray objectAtIndex:indexPath.row] objectForKey:@"IM_Price"];
    
    if ([[[modifierItemArray objectAtIndex:indexPath.row]objectForKey:@"IM_ItemCode"] isEqualToString:modifierItemCode]) {
        cell.labelMDesc.textColor = [UIColor redColor];
    }
    else{
        cell.labelMDesc.textColor = [UIColor blackColor];
    }
    
    cell.contentView.backgroundColor = [UIColor clearColor];
    cell.imageMItemMast.layer.cornerRadius = 10.0;
    cell.imageMItemMast.layer.masksToBounds = YES;
    
    
    
    return cell;
}


- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)view forElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
    
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    __block NSMutableArray *modifierItemCondimentArray;
    modifierItemCondimentArray = [[NSMutableArray alloc] init];
    modifierItemCode = [[modifierItemArray objectAtIndex:indexPath.row] objectForKey:@"IM_ItemCode"];
    
    // this preSelectModifier ItemCode is used to make sure all condiment item assign to select modifier item.
    preSelectModifierItemCode = [[modifierItemArray objectAtIndex:indexPath.row] objectForKey:@"IM_ItemCode"];
    
    modifierItemIndex = indexPath.row;
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:[[LibraryAPI sharedInstance] getDbPath]];
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rsResult = [db executeQuery:@"Select * from ItemCondiment where IC_ItemCode = ?",[[modifierItemArray objectAtIndex:indexPath.row] objectForKey:@"IM_ItemCode"]];
        
        if ([rsResult next]) {
            if ([[[packageItemDetailArray objectAtIndex:selectedTableViewIndex] objectForKey:@"PD_CondimentQty"] integerValue] == 0) {
                [self openAddInCondimentViewWithPackageItemCode:[[modifierItemArray objectAtIndex:indexPath.row] objectForKey:@"IM_ItemCode"] ViewName:@"OrderModifierItemView"];
            }
            else{
                
                [self editPackageItemCondimentWithPosition:selectedTableViewIndex ViewName:@"OrderModifierItemView"];
                
                
            }
            
        }
        else
        {
            
            [modifierItemCondimentArray addObject:[modifierItemArray objectAtIndex:indexPath.row]];
            [self finalEditedModifierItemSelectionWithModifierArray:nil WithCondiment:@"No" ItemArray:modifierItemCondimentArray];
            
            if (selectedTableViewIndex + 1 > packageItemDetailArray.count) {
                return;
            }
            else{
                modifierGroupCode = [[packageItemDetailArray objectAtIndex:selectedTableViewIndex] objectForKey:@"PD_ModifierHdrCode"];
                
                NSInteger lastrow;
                
                lastrow = [self getLastRowOfTablePackageList];
                
                if (lastrow == selectedTableViewIndex) {
                    modifierItemCode = [[packageItemDetailArray objectAtIndex:selectedTableViewIndex] objectForKey:@"IM_ItemCode"];
                    NSIndexPath *indexPathForFirstModifierRow = [NSIndexPath indexPathForItem:selectedTableViewIndex inSection:0];
                    [self.tableViewPackageItemListing selectRowAtIndexPath:indexPathForFirstModifierRow animated:NO  scrollPosition:UITableViewScrollPositionNone];
                    
                }
                else{
                    modifierItemCode = @"";
                    
                    NSIndexPath *indexPathForFirstModifierRow = [NSIndexPath indexPathForItem:selectedTableViewIndex inSection:0];
                    [self.tableViewPackageItemListing selectRowAtIndexPath:indexPathForFirstModifierRow animated:NO  scrollPosition:UITableViewScrollPositionNone];
                    [self tableView:self.tableViewPackageItemListing didSelectRowAtIndexPath:indexPathForFirstModifierRow];
                }
                
            }
            
            [self getModifierItemMastDetail];
            
        }
        [rsResult close];
        
    }];
    
    [queue close];
    
    [self.collectionModifierItemList reloadData];
}

-(void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell *datasetCell =[collectionView cellForItemAtIndexPath:indexPath];
    datasetCell.contentView.backgroundColor = [UIColor clearColor];
}

/*
 -(UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
 {
 
 }
 */


-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.scrollViewModifierItem) {
        CGPoint contentOffset = scrollView.contentOffset;
        contentOffset.x = contentOffset.x - self.collectionModifierItemList.contentInset.left;
        self.collectionModifierItemList.contentOffset = contentOffset;
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

#pragma mark - tableview

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    // Return the number of rows in the section.
    return [packageItemDetailArray count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    id cellToReturn;
    /*
    static NSString *Identifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:Identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:Identifier];
    }
    */
    
    if ([[[packageItemDetailArray objectAtIndex:indexPath.row] objectForKey:@"PD_ItemType"] isEqualToString:@"Modifier"]) {
        
        UINib *nib = [UINib nibWithNibName:@"PackageItemTableViewCell" bundle:nil];
        [tableView registerNib:nib forCellReuseIdentifier:@"PackageItemTableViewCell"];
        PackageItemTableViewCell *packageItemTableViewCell = [tableView dequeueReusableCellWithIdentifier:@"PackageItemTableViewCell"];
        
        packageItemTableViewCell.labelModifierTitle.text = [[packageItemDetailArray objectAtIndex:indexPath.row] objectForKey:@"MH_Description"];
        packageItemTableViewCell.labelPackageItemName.text = [[packageItemDetailArray objectAtIndex:indexPath.row] objectForKey:@"IM_Description"];
        //cell.detailTextLabel.text = @"";
        packageItemTableViewCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        cellToReturn = packageItemTableViewCell;
    }
    else if ([[[packageItemDetailArray objectAtIndex:indexPath.row] objectForKey:@"PD_ItemType"] isEqualToString:@"ItemMast"])
    {
        static NSString *Identifier = @"Cell";
        
        UITableViewCell *cell2 = [tableView dequeueReusableCellWithIdentifier:Identifier];
        if (cell2 == nil) {
            cell2 = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:Identifier];
        }
        
        cell2.textLabel.text = [NSString stringWithFormat:@"%@",[[packageItemDetailArray objectAtIndex:indexPath.row] objectForKey:@"IM_Description"]];
        //cell2.detailTextLabel.text = [[packageItemDetailArray objectAtIndex:indexPath.row] objectForKey:@"UnitQty"];
        //cell2.accessoryType = UITableViewCellAccessoryNone;
        cellToReturn = cell2;
    }
    else
    {
        static NSString *Identifier = @"Cell";
        
        UITableViewCell *cell2 = [tableView dequeueReusableCellWithIdentifier:Identifier];
        if (cell2 == nil) {
            cell2 = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:Identifier];
        }
        
        cell2.textLabel.text = [NSString stringWithFormat:@"  ~  %@",[[packageItemDetailArray objectAtIndex:indexPath.row] objectForKey:@"CDDescription"]];
        //cell2.detailTextLabel.text = [[packageItemDetailArray objectAtIndex:indexPath.row] objectForKey:@"UnitQty"];
        cell2.accessoryType = UITableViewCellAccessoryNone;
        cellToReturn = cell2;
    }
    
    
    //cell.textLabel.textColor = [UIColor colorWithRed:36/255.0 green:36/255.0 blue:36/255.0 alpha:1.0];
    
    return cellToReturn;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if ([[[packageItemDetailArray objectAtIndex:indexPath.row] objectForKey:@"CDDescription"] length] > 0) {
        return;
    }
    
    selectedTableViewIndex = indexPath.row;
    
    if ([[[packageItemDetailArray objectAtIndex:indexPath.row] objectForKey:@"PD_ItemType"] isEqualToString:@"ItemMast"]) {
        if ([[[packageItemDetailArray objectAtIndex:indexPath.row] objectForKey:@"PD_CondimentQty"] integerValue] == 0) {
            FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:[[LibraryAPI sharedInstance] getDbPath]];
            
            [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                FMResultSet *rsResult = [db executeQuery:@"Select * from ItemCondiment where IC_ItemCode = ?",[[packageItemDetailArray objectAtIndex:indexPath.row] objectForKey:@"IM_ItemCode"]];
                
                if ([rsResult next]) {
                    [self openAddInCondimentViewWithPackageItemCode:[[packageItemDetailArray objectAtIndex:indexPath.row] objectForKey:@"IM_ItemCode"] ViewName:@"OrderPackageItemView"];
                }
                [rsResult close];
                
            }];
            
            [queue close];
        }
        else
        {
            preSelectModifierItemCode = [[packageItemDetailArray objectAtIndex:indexPath.row] objectForKey:@"IM_ItemCode"];
            
            [self editPackageItemCondimentWithPosition:indexPath.row ViewName:@"OrderPackageItemView"];
        }
        [modifierItemArray removeAllObjects];
        [self.collectionModifierItemList reloadData];
    }
    else
    {
        
        if ([[[packageItemDetailArray objectAtIndex:indexPath.row] objectForKey:@"PD_Status"] isEqualToString:@"New"]) {
            
            modifierGroupCode = [[packageItemDetailArray objectAtIndex:indexPath.row] objectForKey:@"PD_ModifierHdrCode"];
            modifierItemCode = @"";
            [self getModifierItemMastDetail];

        }
        else{
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ParentIndex MATCHES[cd] %@",
                                      [[packageItemDetailArray objectAtIndex:indexPath.row]objectForKey:@"PackageIndex"]];
            
            modifierGroupCode = [[packageItemDetailArray objectAtIndex:indexPath.row] objectForKey:@"PD_ModifierHdrCode"];
            modifierItemCode = [[packageItemDetailArray objectAtIndex:indexPath.row] objectForKey:@"IM_ItemCode"];
            modifierAddedCondimentArray = [packageItemDetailArray filteredArrayUsingPredicate:predicate];
            
            [self getModifierItemMastDetail];
            
        }
        
    }
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 54;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    if ([[[packageItemDetailArray objectAtIndex:indexPath.row] objectForKey:@"OrderType"] isEqualToString:@"CondimentOrder"])
    {
        return YES;
    }
    else{
        return NO;
    }
    //return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        NSMutableArray *discardedItems = [NSMutableArray array];
        //SomeObjectClass *item;
        [discardedItems addObject:[packageItemDetailArray objectAtIndex:indexPath.row]];
        double totalCondiment = 0;
        for (int i = 0; i < packageItemDetailArray.count; i++)
        {
            if ([[[packageItemDetailArray objectAtIndex:i] objectForKey:@"PackageIndex"] isEqualToString:[[packageItemDetailArray objectAtIndex:indexPath.row] objectForKey:@"ParentIndex"]])
            {
                totalCondiment = [[[packageItemDetailArray objectAtIndex:i] objectForKey:@"PD_NewTotalCondimentSurCharge"] doubleValue] - ([[[packageItemDetailArray objectAtIndex:indexPath.row] objectForKey:@"CDPrice"] doubleValue] * [[[packageItemDetailArray objectAtIndex:indexPath.row] objectForKey:@"UnitQty"] doubleValue]);
                
                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                dict = [packageItemDetailArray objectAtIndex:i];
                [dict setValue:[NSString stringWithFormat:@"%0.2f",totalCondiment] forKey:@"PD_NewTotalCondimentSurCharge"];
                [dict setValue:[NSString stringWithFormat:@"%0.2f",totalCondiment] forKey:@"IM_TotalCondimentSurCharge"];
                [packageItemDetailArray replaceObjectAtIndex:i withObject:dict];
                dict = nil;
                
            }
            
        }
        
        [packageItemDetailArray removeObjectsInArray:discardedItems];
        discardedItems = nil;
    }
    [self.tableViewPackageItemListing reloadData];
}

-(void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    //NSLog(@"%@",[[packageItemDetailArray objectAtIndex:indexPath.row] objectForKey:@"PD_ItemCode"]);
}

- (void)openAddInCondimentViewWithPackageItemCode:(NSString *)packageItemCode ViewName:(NSString *)viewName {
    OrderAddCondimentViewController *orderAddCondimentViewController = [[OrderAddCondimentViewController alloc]initWithNibName:@"OrderAddCondimentViewController" bundle:nil];
    
    orderAddCondimentViewController.delegate = self;
    orderAddCondimentViewController.icItemCode = packageItemCode;
    //orderAddCondimentViewController.selectedCHCode = nil;
    orderAddCondimentViewController.icStatus = @"New";
    orderAddCondimentViewController.addCondimentFrom = viewName;
    
    UINavigationController *navbar = [[UINavigationController alloc]  initWithRootViewController:orderAddCondimentViewController];
    
    navbar.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    navbar.modalPresentationStyle = UIModalPresentationFormSheet;
    navbar.popoverPresentationController.sourceView = self.view;
    navbar.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2, 1, 1);
    
    [orderAddCondimentViewController setModalPresentationStyle:UIModalPresentationFormSheet];
    [orderAddCondimentViewController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    
    [self presentViewController:navbar animated:NO completion:nil];
}


-(void)editPackageItemCondimentWithPosition:(NSUInteger)position ViewName:(NSString *)viewName
{
    
    NSPredicate *predicate;
    if (packageItemDetailArray.count == position+1) {
        predicate = [NSPredicate predicateWithFormat:@"ParentIndex MATCHES[cd] %@",
                     [[packageItemDetailArray objectAtIndex:position]objectForKey:@"ParentIndex"]];
    }
    else
    {
        predicate = [NSPredicate predicateWithFormat:@"ParentIndex MATCHES[cd] %@",
                     [[packageItemDetailArray objectAtIndex:position + 1]objectForKey:@"ParentIndex"]];
    }
    
    
    OrderAddCondimentViewController *orderAddCondimentViewController = [[OrderAddCondimentViewController alloc]initWithNibName:@"OrderAddCondimentViewController" bundle:nil];
    orderAddCondimentViewController.delegate = self;
    orderAddCondimentViewController.addCondimentFrom = viewName;
    
    if ([preSelectModifierItemCode isEqualToString:[[packageItemDetailArray objectAtIndex:position] objectForKey:@"IM_ItemCode"]]) {
        orderAddCondimentViewController.icItemCode = [[packageItemDetailArray objectAtIndex:position] objectForKey:@"IM_ItemCode"];
        
        if ([packageItemDetailArray filteredArrayUsingPredicate:predicate].count == 0){
            orderAddCondimentViewController.parentIndex = [NSString stringWithFormat:@"%ld",position+1];
        }
        else
        {
            orderAddCondimentViewController.icAddedArray = [packageItemDetailArray filteredArrayUsingPredicate:predicate];
        }
        
    }
    else
    {
        orderAddCondimentViewController.icItemCode = preSelectModifierItemCode;
        orderAddCondimentViewController.parentIndex = @"0";
    }
    
    
    orderAddCondimentViewController.selectedCHCode = nil;
    orderAddCondimentViewController.icStatus = @"Edit";
    //orderAddCondimentViewController.showAll = showAll;
    
    
    
    
    UINavigationController *navbar = [[UINavigationController alloc]  initWithRootViewController:orderAddCondimentViewController];
    
    navbar.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    navbar.modalPresentationStyle = UIModalPresentationFormSheet;
    navbar.popoverPresentationController.sourceView = self.view;
    navbar.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2, 1, 1);
    
    [orderAddCondimentViewController setModalPresentationStyle:UIModalPresentationFormSheet];
    [orderAddCondimentViewController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    
    [self presentViewController:navbar animated:NO completion:nil];
}

#pragma mark - delegate from SelectModifierItemView
-(void)finalModifierItemSelectionWithModifierArray:(NSArray *)mArray WithCondiment:(NSString *)withCondiment ItemArray:(NSMutableArray *)itemArray
{
    
    if (mArray.count > 0) {
        
        [packageItemDetailArray insertObject:[itemArray objectAtIndex:0] atIndex:selectedTableViewIndex + 1];
        for (int j = 0; j < mArray.count; j++) {
            [packageItemDetailArray insertObject:[mArray objectAtIndex:j] atIndex:selectedTableViewIndex + 2 + j];
        }
    }
    else{
        [packageItemDetailArray insertObject:[itemArray objectAtIndex:0] atIndex:selectedTableViewIndex + 1];
    }
    
    [packageItemDetailArray removeObjectAtIndex:selectedTableViewIndex];
    
    [self.tableViewPackageItemListing reloadData];
    NSInteger lastRow = [self getLastRowOfTablePackageList];
    
    if (lastRow == selectedTableViewIndex) {
        //[self.tableViewPackageItemListing reloadData];
        
        NSIndexPath *indexPathForFirstModifierRow = [NSIndexPath indexPathForItem:selectedTableViewIndex inSection:0];
        [self.tableViewPackageItemListing selectRowAtIndexPath:indexPathForFirstModifierRow animated:NO  scrollPosition:UITableViewScrollPositionNone];
        //[self tableView:self.tableViewPackageItemListing didSelectRowAtIndexPath:indexPathForFirstModifierRow];
    }
    else
    {
        //[self.tableViewPackageItemListing reloadData];
        NSIndexPath *indexPathForFirstModifierRow;
        
        if (selectedTableViewIndex + 1 + mArray.count > lastRow) {
            indexPathForFirstModifierRow = [NSIndexPath indexPathForItem:selectedTableViewIndex inSection:0];
        }
        else
        {
            indexPathForFirstModifierRow = [NSIndexPath indexPathForItem:selectedTableViewIndex + 1 + mArray.count inSection:0];
        }
        
        [self.tableViewPackageItemListing selectRowAtIndexPath:indexPathForFirstModifierRow animated:NO  scrollPosition:UITableViewScrollPositionNone];
        [self tableView:self.tableViewPackageItemListing didSelectRowAtIndexPath:indexPathForFirstModifierRow];
        
    }
    
    [self reIndexOrderingData];
    
}

-(void)finalEditedModifierItemSelectionWithModifierArray:(NSMutableArray *)mArray WithCondiment:(NSString *)withCondiment ItemArray:(NSMutableArray *)itemArray
{
    NSMutableArray *discardedItems = [NSMutableArray array];
    
    for (int i = 0; i < packageItemDetailArray.count; i++) {
        if ([[[packageItemDetailArray objectAtIndex:i] objectForKey:@"ParentIndex"] isEqualToString:[NSString stringWithFormat:@"%lu",selectedTableViewIndex+1]])
        {
            [discardedItems addObject:[packageItemDetailArray objectAtIndex:i]];
        }
    }
    [packageItemDetailArray removeObjectsInArray:discardedItems];
    
    if (mArray.count > 0) {
        
        [packageItemDetailArray insertObject:[itemArray objectAtIndex:0] atIndex:selectedTableViewIndex + 1];
        for (int j = 0; j < mArray.count; j++) {
            [packageItemDetailArray insertObject:[mArray objectAtIndex:j] atIndex:selectedTableViewIndex + 2 + j];
        }
    }
    else{
        [packageItemDetailArray insertObject:[itemArray objectAtIndex:0] atIndex:selectedTableViewIndex + 1];
    }
    
    [packageItemDetailArray removeObjectAtIndex:selectedTableViewIndex];
    
    
    [self.tableViewPackageItemListing reloadData];
    
    NSInteger lastRow = [self getLastRowOfTablePackageList];
    
    if (lastRow == selectedTableViewIndex) {
        //[self.tableViewPackageItemListing reloadData];
        
        NSIndexPath *indexPathForFirstModifierRow = [NSIndexPath indexPathForItem:selectedTableViewIndex inSection:0];
        [self.tableViewPackageItemListing selectRowAtIndexPath:indexPathForFirstModifierRow animated:NO  scrollPosition:UITableViewScrollPositionNone];
        //[self tableView:self.tableViewPackageItemListing didSelectRowAtIndexPath:indexPathForFirstModifierRow];
    }
    else
    {
        NSLog(@"highlight row : %lu", selectedTableViewIndex + 1 + mArray.count);
        
        //[self.tableViewPackageItemListing reloadData];
        //NSIndexPath *indexPathForFirstModifierRow = [NSIndexPath indexPathForItem:selectedTableViewIndex + 1 + mArray.count inSection:0];
        NSIndexPath *indexPathForFirstModifierRow;
        //= [NSIndexPath indexPathForItem:selectedTableViewIndex + 1 + mArray.count inSection:0];
        
        if (selectedTableViewIndex + 1 + mArray.count > lastRow) {
            indexPathForFirstModifierRow = [NSIndexPath indexPathForItem:selectedTableViewIndex inSection:0];
        }
        else
        {
            indexPathForFirstModifierRow = [NSIndexPath indexPathForItem:selectedTableViewIndex + 1 + mArray.count inSection:0];
        }
        
        
        [self.tableViewPackageItemListing selectRowAtIndexPath:indexPathForFirstModifierRow animated:NO  scrollPosition:UITableViewScrollPositionNone];
        [self tableView:self.tableViewPackageItemListing didSelectRowAtIndexPath:indexPathForFirstModifierRow];
        
    }
    
    //[self.tableViewPackageItemListing reloadData];
    [self reIndexOrderingData];
    
}

#pragma mark - delegate from Add condiment
-(void)passBackToOrderPackageItemDetailWithCondimentDtl:(NSMutableArray *)array DisplayFormat:(NSString *)displayFormat TotalCondimentPrice:(double)totalCondimentPrice Status:(NSString *)status CondimentUnitPrice:(double)condimentUnitPrice{
    // condimentUnitPrice = sum all condiment unit price
    // totalCondimentPrice = condimentUnitPrice X total qty
    if (array.count > 0) {
        NSLog(@"selected row %lu",(unsigned long)selectedTableViewIndex);
        
        for (int i = 0; i < array.count; i++) {
            NSMutableDictionary *data = [NSMutableDictionary dictionary];
            data = [array objectAtIndex:i];
            [data setValue:[NSString stringWithFormat:@"%lu",selectedTableViewIndex+1] forKey:@"ParentIndex"];
            [data setObject:@"Yes" forKey:@"UnderPackageItemYN"];
            [data setObject:_imCode forKey:@"PackageItemCode"];
            [data setObject:_imName forKey:@"PackageItemDesc"];
            [packageItemDetailArray insertObject:data atIndex:selectedTableViewIndex + 1];
            data = nil;
            
        }
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict = [packageItemDetailArray objectAtIndex:selectedTableViewIndex];
        [dict setValue:[NSString stringWithFormat:@"%lu",array.count] forKey:@"PD_CondimentQty"];
        [dict setValue:[NSString stringWithFormat:@"%0.2f",totalCondimentPrice] forKey:@"PD_NewTotalCondimentSurCharge"];
        [dict setValue:[NSString stringWithFormat:@"%0.2f",totalCondimentPrice] forKey:@"IM_TotalCondimentSurCharge"];
        [packageItemDetailArray replaceObjectAtIndex:selectedTableViewIndex withObject:dict];
        
        dict = nil;
        
        [self.tableViewPackageItemListing reloadData];
    }
    
    [self reIndexOrderingData];
    
}

-(void)passBackToOrderPackageItemDetailWithEditedCondimentDtl:(NSMutableArray *)array DisplayFormat:(NSString *)displayFormat TotalCondimentPrice:(double)totalCondimentPrice ParentIndex:(NSString *)parentIndex CondimentUnitPrice:(double)condimentUnitPrice
{
    packageItemDetailArray = [PublicMethod softingOrderCondimentWithEditedCondimentDtl:array DisplayFormat:@"-" TotalCondimentPrice:totalCondimentPrice ParentIndex:parentIndex CondimentUnitPrice:condimentUnitPrice OriginalArray:packageItemDetailArray FromView:@"PackageItem" KeyName:@"PackageIndex"];
    
    // this for remove last dict, this last dict is used to ordering
    [packageItemDetailArray removeObjectAtIndex:packageItemDetailArray.count-1];
    [self reIndexOrderingData];
    
    [self.tableViewPackageItemListing reloadData];

}

#pragma mark - delegate from modifier item OrderAddOnCondiment
-(void)passBackToOrderModifierItemDetailWithCondimentDtl:(NSMutableArray *)array DisplayFormat:(NSString *)displayFormat TotalCondimentPrice:(double)totalCondimentPrice Status:(NSString *)status CondimentUnitPrice:(double)condimentUnitPrice
{
    // run this for prevent array reference to packageDetailLsitArray
    NSMutableArray *copyArray = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < array.count; i++) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setObject:[[array objectAtIndex:i] objectForKey:@"CDCode"] forKey:@"CDCode"];
        [dict setObject:[[array objectAtIndex:i] objectForKey:@"CHCode"] forKey:@"CHCode"];
        [dict setObject:[[array objectAtIndex:i] objectForKey:@"CDDescription"] forKey:@"CDDescription"];
        [dict setObject:[[array objectAtIndex:i] objectForKey:@"CDPrice"] forKey:@"CDPrice"];
        [dict setObject:[[array objectAtIndex:i] objectForKey:@"IM_DiscountAmt"] forKey:@"IM_DiscountAmt"];
        [dict setObject:preSelectModifierItemCode forKey:@"ItemCode"];
        [dict setObject:@"Yes" forKey:@"UnderPackageItemYN"];
        [dict setObject:_imCode forKey:@"PackageItemCode"];
        [dict setObject:_imName forKey:@"PackageItemDesc"];
        [dict setObject:[[array objectAtIndex:i] objectForKey:@"OrderType"] forKey:@"OrderType"];
        if ([status isEqualToString:@"New"]) {
            [dict setObject:[NSString stringWithFormat:@"%lu",selectedTableViewIndex] forKey:@"ParentIndex"];
        }
        else{
            [dict setObject:[NSString stringWithFormat:@"%lu",selectedTableViewIndex + 1] forKey:@"ParentIndex"];
        }
        
        [dict setObject:[[array objectAtIndex:i] objectForKey:@"UnitQty"] forKey:@"UnitQty"];
        
        [copyArray addObject:dict];
        dict = nil;

    }
    
    
    
    NSMutableArray *selectedModifierItemArray = [[NSMutableArray alloc] init];
    
    [selectedModifierItemArray addObject:[modifierItemArray objectAtIndex:modifierItemIndex]];
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    data = [selectedModifierItemArray objectAtIndex:0];
    [data setValue:[NSString stringWithFormat:@"%0.2f",totalCondimentPrice] forKey:@"PD_NewTotalCondimentSurCharge"];
    [data setValue:[NSString stringWithFormat:@"%0.2f",totalCondimentPrice] forKey:@"IM_TotalCondimentSurCharge"];
    //if ([status isEqualToString:@"Edit"]) {
      //  [data setValue:_orderingViewParentIndex forKey:@"PackageItemIndex"];
    //}
    
    [data setValue:[NSString stringWithFormat:@"%lu",copyArray.count] forKey:@"PD_CondimentQty"];
    [selectedModifierItemArray replaceObjectAtIndex:0 withObject:data];
    data = nil;
    
        if (copyArray.count >= 1) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            dict = [selectedModifierItemArray objectAtIndex:0];
            [dict setValue:[NSString stringWithFormat:@"%lu",(unsigned long)copyArray.count] forKey:@"PD_CondimentQty"];
            [selectedModifierItemArray replaceObjectAtIndex:0 withObject:dict];
            dict = nil;
            if ([status isEqualToString:@"New"]) {
                [self finalModifierItemSelectionWithModifierArray:copyArray WithCondiment:@"Yes" ItemArray:selectedModifierItemArray];
            }
            else{
                [self finalEditedModifierItemSelectionWithModifierArray:copyArray WithCondiment:@"Yes" ItemArray:selectedModifierItemArray];
            }
        }
        else{
            if ([status isEqualToString:@"New"]) {
                [self finalModifierItemSelectionWithModifierArray:copyArray WithCondiment:@"No" ItemArray:selectedModifierItemArray];
            }
            else{
                //NSLog(@"%@",@"ddddd");
                [self finalEditedModifierItemSelectionWithModifierArray:copyArray WithCondiment:@"No" ItemArray:selectedModifierItemArray];
            }
        }
        selectedModifierItemArray = nil;
        copyArray = nil;
        //modifierItemArray = nil;
        //[self.navigationController popViewControllerAnimated:NO];
    //}
    
}

-(void)reverseSelectedPackageItem
{
    NSIndexPath *indexPathForFirstModifierRow = [NSIndexPath indexPathForItem:selectedTableViewIndex inSection:0];
    [self.tableViewPackageItemListing selectRowAtIndexPath:indexPathForFirstModifierRow animated:NO  scrollPosition:UITableViewScrollPositionNone];
    [self tableView:self.tableViewPackageItemListing didSelectRowAtIndexPath:indexPathForFirstModifierRow];
}

-(void)reIndexOrderingData
{
    NSString *parentIndex;
    for (int i = 0; i < packageItemDetailArray.count; i++)
    {
        NSDictionary *data2 = [NSDictionary dictionary];
        data2 = [packageItemDetailArray objectAtIndex:i];
        if ([[[packageItemDetailArray objectAtIndex:i] objectForKey:@"PD_ItemType"] isEqualToString:@"ItemMast"] || [[[packageItemDetailArray objectAtIndex:i] objectForKey:@"PD_ItemType"] isEqualToString:@"Modifier"]) {
            [data2 setValue:[NSString stringWithFormat:@"%d",i + 1] forKey:@"PackageIndex"];
            parentIndex = [NSString stringWithFormat:@"%d",i + 1];
        }
        else
        {
            [data2 setValue:parentIndex forKey:@"ParentIndex"];
            [data2 setValue:parentIndex forKey:@"ParentIndex2"];
        }
        
        [packageItemDetailArray replaceObjectAtIndex:i withObject:data2];
        data2 = nil;
    }
    parentIndex = nil;
    
}

-(NSInteger)getLastRowOfTablePackageList
{
    NSInteger lastrow;
    NSInteger lastSectionIndex = [self.tableViewPackageItemListing numberOfSections] - 1;
    lastrow = [self.tableViewPackageItemListing numberOfRowsInSection:lastSectionIndex] - 1;
    
    return lastrow;
}


- (IBAction)btnCompletePackageSelection:(id)sender {
    //NSLog(@"package item - %@",packageItemDetailArray);
    
    NSPredicate *predicate1;
    predicate1 = [NSPredicate predicateWithFormat:@"PD_ItemType MATCHES[cd] %@",
                  @"ItemMast"];
    
    NSPredicate *predicate2;
    predicate2 = [NSPredicate predicateWithFormat:@"PD_ItemType MATCHES[cd] %@",
                  @"Modifier"];
    
    NSPredicate *predicate3;
    predicate3 = [NSPredicate predicateWithFormat:@"PD_Status MATCHES[cd] %@",
                  @"New"];
    
    NSPredicate *predicate4;
    predicate4 = [NSPredicate predicateWithFormat:@"PD_ItemType MATCHES[cd] %@",
                  @"Modifier"];
    
    NSPredicate *predicateOr = [NSCompoundPredicate orPredicateWithSubpredicates:@[predicate1, predicate2]];
    
    NSPredicate *predicateAnd = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate3, predicate4]];
    
    NSArray *checkingArray = [packageItemDetailArray filteredArrayUsingPredicate:predicateAnd];
    
    if (checkingArray.count > 0) {
        [self showAlertView:@"One of the item not selected" title:@"Warning"];
        return;
    }
    
    NSArray *array = [packageItemDetailArray filteredArrayUsingPredicate:predicateOr];
    double totalSurcharge = 0;
    for (int i = 0; i < array.count; i++) {
        totalSurcharge = totalSurcharge + [[[array objectAtIndex:i] objectForKey:@"PD_NewTotalCondimentSurCharge"] doubleValue] + [[[array objectAtIndex:i] objectForKey:@"IM_Price"] doubleValue];
    }
    NSLog(@"Total Surcharge : %0.2f",totalSurcharge);
    predicate1 = nil;
    predicate2 = nil;
    predicateOr = nil;
    
    predicate3 = nil;
    predicate4 = nil;
    predicateAnd = nil;
    
    if (_delegate != nil) {
        if (_completedOrderPackageArray.count == 0) {
            [_delegate passBackPackageItemDetailToOrderScreenWithPackageDetail:packageItemDetailArray DisplayFormat:@"-" TotalSurcharge:totalSurcharge Status:@"New" PackageItemCode:_imCode PackageItemDesc:_imName];
        }
        else{
            
            for (int i = 0; i < packageItemDetailArray.count; i++) {
                NSDictionary *dict = [NSDictionary dictionary];
                dict = [packageItemDetailArray objectAtIndex:i];
                
                [dict setValue:_orderingViewParentIndex forKey:@"ParentIndex"];
                [packageItemDetailArray replaceObjectAtIndex:i withObject:dict];
                dict = nil;
                
            }
            
            [_delegate passBackEditedPackageItemDetailToOrderScreenWithPackageDetail:packageItemDetailArray DisplayFormat:@"-" TotalSurcharge:totalSurcharge Status:@"Edit" PackageItemCode:_imCode PackageItemDesc:_imName OrderingViewParentIndex:_orderingViewParentIndex];
        }
        
    }
    
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)btnCancelPackageSelection:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}

-(void)generatePackageItemDetailArayWithDict:(NSDictionary *)dict PackageIndex:(NSUInteger)index Status:(NSString *)status CondimentQty:(NSUInteger)condimentQty
{
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    
    //NSLog(@"ddd : %@",dict);
    
    if([[dict objectForKey:@"PD_ItemType"] isEqualToString:@"ItemMast"] || [[dict objectForKey:@"PD_ItemType"] isEqualToString:@"Modifier"])
    {
        [data setObject:@"Non" forKey:@"Status"];
        [data setObject:@"NonSONo" forKey:@"SOH_DocNo"];
        [data setObject:[dict objectForKey:@"IM_ItemCode"] forKey:@"IM_ItemCode"];
        [data setObject:[dict objectForKey:@"IM_Description"] forKey:@"IM_Description"];
        
        [data setObject:[dict objectForKey:@"IM_Price"] forKey:@"IM_Price"];
        
        //----------------------------------------------------------------------------------------
        [data setObject:[dict objectForKey:@"IM_Price"] forKey:@"IM_SalesPrice"];
        //one item selling price not included tax
        [data setObject:[dict objectForKey:@"IM_Price"] forKey:@"IM_SellingPrice"];
        //[data setObject:[NSString stringWithFormat:@"%0.6f",itemTaxAmt] forKey:@"IM_Tax"];
        [data setObject:@"0.00" forKey:@"IM_Tax"];
        [data setObject:@"0" forKey:@"IM_Qty"];
        [data setObject:@"0.00" forKey:@"IM_DiscountInPercent"];
        
        [data setObject:@"0.00" forKey:@"IM_Gst"];
        
        [data setObject:@"0.00" forKey:@"IM_TotalTax"]; //sum tax amt
        [data setObject:@"0" forKey:@"IM_DiscountType"];
        [data setObject:@"0" forKey:@"IM_Discount"]; // discount given
        [data setObject:@"0.00" forKey:@"IM_DiscountAmt"];  // sum discount
        [data setObject:@"0" forKey:@"IM_SubTotal"];
        [data setObject:[dict objectForKey:@"IM_Price"] forKey:@"IM_Total"];
        
        //------------tax code-----------------
        [data setObject:[dict objectForKey:@"IM_GSTCode"] forKey:@"IM_GSTCode"];
        
        //-------------service tax-------------
        [data setObject:[dict objectForKey:@"IM_ServiceTaxCode"] forKey:@"IM_ServiceTaxCode"];  //svc tax code
        [data setObject:@"0.00" forKey:@"IM_ServiceTaxAmt"]; // service tax amount
        [data setObject:@"0.00" forKey:@"IM_ServiceTaxRate"];
        [data setObject:@"0.00" forKey:@"IM_ServiceTaxGstAmt"];
        [data setObject:@"0.00" forKey:@"IM_ServiceTaxGstAmtLong"];
        //[data setObject:textServiceTaxGst forKey:@"IM_ServiceTaxGstAmt"];
        
        //------------------------------------------------------------------------------------------
        [data setObject:@"0.00"forKey:@"IM_totalItemSellingAmt"];  // subtotal not include tax n will replace this
        [data setObject:@"0.00" forKey:@"IM_totalItemSellingAmtLong"];  // subtotal not include tax
        [data setObject:@"0.00" forKey:@"IM_totalItemTaxAmtLong"];  // total tax amt
        
        [data setObject:@"0.00" forKey:@"IM_totalServiceTaxAmt"];  // total service tax amt
        
        [data setObject:@"" forKey:@"IM_Remark"];
        [data setObject:@"" forKey:@"IM_TableName"];
        //---------for print kitchen receipt----------------
        
        [data setObject:@"Print" forKey:@"IM_Print"];
        [data setObject:@"1" forKey:@"IM_OrgQty"];
        [data setObject:[dict objectForKey:@"IM_IpAddress"] forKey:@"IM_IpAddress"];
        [data setObject:[dict objectForKey:@"IM_PrinterName"] forKey:@"IM_PrinterName"];
        //---------for item dine in or take away ------------
        [data setObject:@"" forKey:@"IM_TakeAwayYN"];
        
        //--------- for table pax no ---------------------
        [data setObject:@"1" forKey:@"SOH_PaxNo"];
        [data setObject:@"" forKey:@"PayDocType"];
        [data setObject:@"PackageItemOrder" forKey:@"OrderType"];
        [data setObject:[dict objectForKey:@"IM_TotalCondimentSurCharge"] forKey:@"IM_TotalCondimentSurCharge"];
        [data setObject:@"0.00" forKey:@"IM_NewTotalCondimentSurCharge"];
        //[data setObject:@"-" forKey:@"Index"];
        //---------for main to decide this array-------------
        if ([[[LibraryAPI sharedInstance] getWorkMode] isEqualToString:@"Terminal"]) {
            [data setObject:@"Order" forKey:@"IM_Flag"];
            [data setObject:@"0.00" forKey:@"IM_labelTotal"];
            [data setObject:@"0.00" forKey:@"IM_labelTotalDiscount"];
            [data setObject:@"0.00" forKey:@"IM_labelRound"];
            [data setObject:@"0.00" forKey:@"IM_labelSubTotal"];
            [data setObject:@"0.00" forKey:@"IM_labelTaxTotal"];
            [data setObject:@"0.00" forKey:@"IM_labelServiceTaxTotal"];
            [data setObject:@"0.00" forKey:@"IM_serviceTaxGstTotal"];
            [data setObject:@"" forKey:@"IM_Table"];
            
            [data setObject:@"" forKey:@"CName"];
            [data setObject:@"" forKey:@"CAdd1"];
            [data setObject:@"" forKey:@"CAdd2"];
            [data setObject:@"" forKey:@"CAdd3"];
            [data setObject:@"" forKey:@"CTelNo"];
            [data setObject:@"" forKey:@"CGstNo"];
            
        }
        
        [data setObject:[dict objectForKey:@"PD_MinChoice"] forKey:@"PD_MinChoice"];
        [data setObject:[NSString stringWithFormat:@"%lu",condimentQty] forKey:@"PD_CondimentQty"];
        [data setObject:[dict objectForKey:@"IM_TotalCondimentSurCharge"] forKey:@"PD_NewTotalCondimentSurCharge"];
        //[sectionDic setObject:@"PackageItemOrder" forKey:@"OrderType"];
        [data setObject:[NSString stringWithFormat:@"%ld",index] forKey:@"PackageIndex"];
        [data setObject:[dict objectForKey:@"PD_ItemType"] forKey:@"PD_ItemType"];
        [data setObject:status forKey:@"PD_Status"];
        if ([status isEqualToString:@"Edit"]) {
            [data setObject:[dict objectForKey:@"PD_ModifierHdrCode"] forKey:@"PD_ModifierHdrCode"];
        }
        else{
            [data setObject:[dict objectForKey:@"IM_ItemCode"] forKey:@"PD_ModifierHdrCode"];
        }
        [data setObject:[dict objectForKey:@"MH_Description"] forKey:@"MH_Description"];
        
        //[sectionDic setObject:@"0.00" forKey:@"IM_DiscountAmt"];
        
        [data setObject:@"Yes" forKey:@"UnderPackageItemYN"];
        [data setObject:_imCode  forKey:@"PackageItemCode"];
        [data setObject:_imName forKey:@"PackageItemDesc"];
        [data setObject:_orderingViewParentIndex forKey:@"PackageItemIndex"];
    }
    else
    {
        
        [data setObject:[dict objectForKey:@"IM_ItemCode"] forKey:@"IM_ItemCode"];
        [data setObject:[dict objectForKey:@"IM_Description"] forKey:@"IM_Description"];
        [data setObject:[dict objectForKey:@"IM_Price"] forKey:@"IM_Price"];
        [data setObject:[dict objectForKey:@"PD_MinChoice"] forKey:@"PD_MinChoice"];
        [data setObject:@"0" forKey:@"PD_CondimentQty"];
        [data setObject:@"0" forKey:@"PD_NewTotalCondimentSurCharge"];
        [data setObject:@"PackageItemOrder" forKey:@"OrderType"];
        [data setObject:[NSString stringWithFormat:@"%ld",index] forKey:@"PackageIndex"];
        [data setObject:[dict objectForKey:@"PD_ItemType"] forKey:@"PD_ItemType"];
        [data setObject:@"New" forKey:@"PD_Status"];
        [data setObject:[dict objectForKey:@"IM_ItemCode"] forKey:@"PD_ModifierHdrCode"];
        [data setObject:@"0.00" forKey:@"IM_DiscountAmt"];
        
        [data setObject:@"Yes" forKey:@"UnderPackageItemYN"];
        [data setObject:_imCode  forKey:@"PackageItemCode"];
        [data setObject:_imName forKey:@"PackageItemDesc"];
        [data setObject:_orderingViewParentIndex forKey:@"PackageItemIndex"];
        
    }
    
    [packageItemDetailArray addObject:data];
    data = nil;
}

-(void)generatePackageItemCondimentDetailWithDict:(NSDictionary *)dict ParentIndex:(NSUInteger)index
{
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    
    [data setObject:[dict objectForKey:@"CDCode"] forKey:@"CDCode"];
    [data setObject:[dict objectForKey:@"CDDescription"] forKey:@"CDDescription"];
    [data setObject:[dict objectForKey:@"CDPrice"] forKey:@"CDPrice"];
    [data setObject:[dict objectForKey:@"CHCode"] forKey:@"CHCode"];
    [data setObject:[dict objectForKey:@"IM_DiscountAmt"] forKey:@"IM_DiscountAmt"];
    [data setObject:[dict objectForKey:@"ItemCode"] forKey:@"ItemCode"];
    [data setObject:[dict objectForKey:@"OrderType"] forKey:@"OrderType"];
    [data setObject:_imCode forKey:@"PackageItemCode"];
    [data setObject:_imName forKey:@"PackageItemDesc"];
    
    [data setObject:[NSString stringWithFormat:@"%lu",index] forKey:@"ParentIndex"];
    [data setObject:@"Yes" forKey:@"UnderPackageItemYN"];
    [data setObject:[dict objectForKey:@"UnitQty"] forKey:@"UnitQty"];
    [data setObject:_orderingViewParentIndex forKey:@"PackageItemIndex"];
    
    [packageItemDetailArray addObject:data];
    
    data = nil;
}

#pragma mark - alertView

-(void)showAlertView:(NSString *)msg title:(NSString *)title
{
    UIAlertController * alert = [[LibraryAPI sharedInstance] showAlertViewWithMsg:msg Title:title];
    
    [self presentViewController:alert animated:YES completion:nil];
    
    alert = nil;
}
@end
