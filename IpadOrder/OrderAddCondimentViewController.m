//
//  OrderAddCondimentViewController.m
//  IpadOrder
//
//  Created by IRS on 04/09/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import "OrderAddCondimentViewController.h"
#import "FullyHorizontalFlowLayout.h"
#import "LibraryAPI.h"
#import <FMDB.h>
#import "OrderAddCondimentDtlCollectionViewCell.h"
#import "OrderAddCondimentDtlViewController.h"
#import "CondimentHdrCollectionViewCell.h"

static NSString * const itemHdrIdentifier = @"CondimentHdrCollectionViewCell";
static NSString * const itemDtlIdentifier = @"OrderAddCondimentDtlCollectionViewCell";
@interface OrderAddCondimentViewController ()
{
    NSString *dbPath;
    FMDatabase *dbTable;
    NSMutableArray *condimentGroupArray;
    NSMutableArray *condimentDtlArray;
    NSString *chCode;
    NSMutableArray *addedCondimentArray;
    double totalCondimentPrice;
    //NSString *parentIndex;
    double condimentUnitPrice;
    NSUInteger condimentGroupSelectedIndex;
    //long cdtHdrIndexSelected;
}
@end

@implementation OrderAddCondimentViewController
@synthesize icAddedArray, parentIndex;
/*
-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    
}
*/
- (void)viewDidLoad {
    [super viewDidLoad];
    self.preferredContentSize = CGSizeMake(520, 621);
    
    condimentGroupArray = [[NSMutableArray alloc] init];
    condimentDtlArray = [[NSMutableArray alloc] init];
    addedCondimentArray = [[NSMutableArray alloc] init];
    totalCondimentPrice = 0.00;
    condimentUnitPrice = 0.00;
    dbPath = [[LibraryAPI sharedInstance] getDbPath];
    
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    // Do any additional setup after loading the view from its nib.
    self.navigationController.navigationBar.translucent = NO;
    
    UINib *itemHdrNib = [UINib nibWithNibName:itemHdrIdentifier bundle:nil];
    [_collectionCondimentGroup registerNib:itemHdrNib forCellWithReuseIdentifier:itemHdrIdentifier];
    
    UINib *itemDtlNib = [UINib nibWithNibName:itemDtlIdentifier bundle:nil];
    [_collectionAddCondiment registerNib:itemDtlNib forCellWithReuseIdentifier:itemDtlIdentifier];
    
    FullyHorizontalFlowLayout *collectionHdrViewLayout = [FullyHorizontalFlowLayout new];
    collectionHdrViewLayout.itemSize = CGSizeMake(130., 50.);
    [collectionHdrViewLayout setSectionInset:UIEdgeInsetsMake(0, 0, 0, 0)];
    collectionHdrViewLayout.minimumInteritemSpacing = 0;
    collectionHdrViewLayout.minimumLineSpacing = 0;
    
    FullyHorizontalFlowLayout *collectionDtlViewLayout = [FullyHorizontalFlowLayout new];
    
    collectionDtlViewLayout.itemSize = CGSizeMake(120., 120.);
    [collectionDtlViewLayout setSectionInset:UIEdgeInsetsMake(0, 5, 0, 5)];
    
    UIBarButtonItem *newBackButton =
    [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(backToOrderingView)];
    self.navigationItem.leftBarButtonItem = newBackButton;
    /*
    UIBarButtonItem *doneButton =
    [[UIBarButtonItem alloc] initWithTitle:@"  Done"
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(confirmAddCondiment)];
     */
    
    UIBarButtonItem *allCondimentButton =
    [[UIBarButtonItem alloc] initWithTitle:@"Show All"
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(showAllCondimentGroup)];
    self.navigationItem.rightBarButtonItems = @[allCondimentButton];
    
    [self.collectionAddCondiment setCollectionViewLayout:collectionDtlViewLayout];
    _collectionAddCondiment.dataSource = self;
    _collectionAddCondiment.delegate = self;
    _collectionAddCondiment.pagingEnabled = true;
    self.secretScrollView.delegate = self;
    
    
    [self.collectionCondimentGroup setCollectionViewLayout:collectionHdrViewLayout];
    self.collectionCondimentGroup.dataSource = self;
    self.collectionCondimentGroup.delegate = self;
    self.collectionCondimentGroup.pagingEnabled  =true;
    
    if ([[self checkItemIncludeCondiment]isEqualToString:@"0"]) {
        [self getCondimentGroupWithKeyWord:@"%"];
    }
    else
    {
        [self getCondimentGroupWithKeyWord:_icItemCode];
    }
    
    //[self getCondimentDtl];
    
    if ([_icStatus isEqualToString:@"Edit"]) {
        if (icAddedArray.count > 0) {
            [addedCondimentArray addObjectsFromArray: icAddedArray];
            parentIndex = [[icAddedArray objectAtIndex:0] objectForKey:@"ParentIndex"];
        }
        else
        {
            //NSLog(@"testing - %@",_addCondimentFrom);
            //parentIndex = @"0";
        }
        
    }
    else
    {
        parentIndex = @"0";
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)backToOrderingView
{
    condimentDtlArray = nil;
    condimentGroupArray = nil;
    addedCondimentArray = nil;
    icAddedArray = nil;
    
    if ([_addCondimentFrom isEqualToString:@"OrderModifierItemView"]) {
        if (_delegate != nil) {
            [_delegate reverseSelectedPackageItem];
        }
    }
    
    [self.navigationController dismissViewControllerAnimated:NO completion:nil];
}

-(void)showAllCondimentGroup
{
    [self getCondimentGroupWithKeyWord:@"%"];
}

-(void)confirmAddCondiment
{
    
    //NSMutableString displayFormat;
    
    for (int i = 0; i < addedCondimentArray.count; i++) {
        totalCondimentPrice = totalCondimentPrice + ([[[addedCondimentArray objectAtIndex:i] objectForKey:@"UnitQty"] doubleValue] * [[[addedCondimentArray objectAtIndex:i] objectForKey:@"CDPrice"] doubleValue]);
        condimentUnitPrice = condimentUnitPrice + [[[addedCondimentArray objectAtIndex:i] objectForKey:@"CDPrice"] doubleValue];
    }
    
    if (_delegate != nil) {
        if ([_icStatus isEqualToString:@"New"]) {
            if ([_addCondimentFrom isEqualToString:@"OrderingView"]) {
                [_delegate passBackToOrderScreenWithCondimentDtl:addedCondimentArray DisplayFormat:@"-" TotalCondimentPrice:totalCondimentPrice Status:_icStatus CondimentUnitPrice:condimentUnitPrice PredicatePrice:[_icItemPrice doubleValue] + totalCondimentPrice];
            }
            else if([_addCondimentFrom isEqualToString:@"OrderPackageItemView"])
            {
                [_delegate passBackToOrderPackageItemDetailWithCondimentDtl:addedCondimentArray DisplayFormat:@"-" TotalCondimentPrice:totalCondimentPrice Status:_icStatus CondimentUnitPrice:condimentUnitPrice];
            }
            else if([_addCondimentFrom isEqualToString:@"OrderModifierItemView"])
            {
                [_delegate passBackToOrderModifierItemDetailWithCondimentDtl:addedCondimentArray DisplayFormat:@"-" TotalCondimentPrice:totalCondimentPrice Status:_icStatus CondimentUnitPrice:condimentUnitPrice];
            }
            
        }
        else
        {
            if ([_addCondimentFrom isEqualToString:@"OrderingView"]) {
                [_delegate passBackToOrderScreenWithEditedCondimentDtl:addedCondimentArray DisplayFormat:@"-" TotalCondimentPrice:totalCondimentPrice ParentIndex:parentIndex CondimentUnitPrice:condimentUnitPrice];
            }
            else if([_addCondimentFrom isEqualToString:@"OrderPackageItemView"]){
                [_delegate passBackToOrderPackageItemDetailWithEditedCondimentDtl:addedCondimentArray DisplayFormat:@"-" TotalCondimentPrice:totalCondimentPrice ParentIndex:parentIndex CondimentUnitPrice:condimentUnitPrice];
            }
            else if([_addCondimentFrom isEqualToString:@"OrderModifierItemView"])
            {
                
                [_delegate passBackToOrderModifierItemDetailWithCondimentDtl:addedCondimentArray DisplayFormat:@"-" TotalCondimentPrice:totalCondimentPrice Status:_icStatus CondimentUnitPrice:condimentUnitPrice];
                
                //[_delegate passBackToOrderPackageItemDetailWithEditedCondimentDtl:addedCondimentArray DisplayFormat:@"-" TotalCondimentPrice:totalCondimentPrice ParentIndex:parentIndex CondimentUnitPrice:condimentUnitPrice];
                
            }
            
        }
        condimentDtlArray = nil;
        condimentGroupArray = nil;
        addedCondimentArray = nil;
        icAddedArray = nil;
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}

#pragma mark - sqlite
-(NSString *)checkItemIncludeCondiment
{
    __block NSString*result;
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"Select * from ItemCondiment where IC_ItemCode = ?",_icItemCode];
        
        if (![rs next]) {
            result = @"0";
        }
        else
        {
            result = @"1";
            
        }
        [rs close];
    }];
    [queue close];
    return result;
}

-(void)getCondimentGroupWithKeyWord:(NSString *)keyWord
{
    [condimentGroupArray removeAllObjects];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        NSString *sqlCommand;
        FMResultSet *rs ;
        
        
        
        if ([keyWord isEqualToString:@"%"]) {
            sqlCommand = @"Select CH_Code, CH_Description from CondimentHdr";
            sqlCommand = [NSString stringWithFormat:@"%@",sqlCommand];
            rs = [db executeQuery:sqlCommand];
        }
        else
        {
            sqlCommand = @"Select CH_Code, CH_Description from ItemCondiment IC left join CondimentHdr CH on IC.IC_CondimentHdrCode = CH.CH_Code";
            sqlCommand = [NSString stringWithFormat:@"%@ %@",sqlCommand,@"where IC.IC_ItemCode = ?"];
            rs = [db executeQuery:sqlCommand,keyWord];
        }
        
        while ([rs next])
        {
            [condimentGroupArray addObject:[rs resultDictionary]];
        }
        [rs close];
        
    }];
    
    
    [queue close];
    if (condimentGroupArray.count > 0) {
        if (_selectedCHCode != nil) {
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"CH_Code MATCHES[cd] %@",
                                      _selectedCHCode];
            
            NSArray * selectedObject = [condimentGroupArray filteredArrayUsingPredicate:predicate];
            
            if (selectedObject.count > 0) {
                NSUInteger indexOfArray = 0;
                indexOfArray = [condimentGroupArray indexOfObject:selectedObject[0]];
                chCode = _selectedCHCode;
                [self manualDidSelectCollectionViewWithIndexNo:indexOfArray];
            }
            else
            {
                chCode =[[condimentGroupArray objectAtIndex:0] objectForKey:@"CH_Code"];
                [self manualDidSelectCollectionViewWithIndexNo:0];
            }
            selectedObject = nil;
            
        }
        else
        {
            chCode =[[condimentGroupArray objectAtIndex:0] objectForKey:@"CH_Code"];
            [self manualDidSelectCollectionViewWithIndexNo:0];
        }
        
    }
    else
    {
        chCode = @"Null@";
    }
    
    long pageControlCount = 0;
    
    pageControlCount = condimentGroupArray.count % 4;
    
    if (pageControlCount == 0) {
        pageControlCount = condimentGroupArray.count / 4;
    }
    else
    {
        pageControlCount = (condimentGroupArray.count / 4)+1;
    }
    
    self.pageControlCondimentgroup.numberOfPages = pageControlCount;
    [self.collectionCondimentGroup reloadData];
}

-(void)getCondimentDtl
{
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"Select *, '0' as UnitQty from CondimentDtl where CD_CondimentHdrCode = ?",chCode];
        
        while ([rs next]) {
            NSMutableDictionary *data = [NSMutableDictionary dictionary];
            [data setObject:_icItemCode forKey:@"ItemCode"];
            [data setObject:chCode forKey:@"CHCode"];
            [data setObject:[rs stringForColumn:@"CD_Code"] forKey:@"CDCode"];
            [data setObject:[rs stringForColumn:@"CD_Description"] forKey:@"CDDescription"];
            [data setObject:[rs stringForColumn:@"UnitQty"] forKey:@"UnitQty"];
            [data setObject:[rs stringForColumn:@"CD_Price"] forKey:@"CDPrice"];
            [data setObject:@"0.00" forKey:@"IM_DiscountAmt"];
            [data setObject:@"CondimentOrder" forKey:@"OrderType"];
            [data setObject:@"0" forKey:@"ParentIndex"];
            [condimentDtlArray addObject:data];
            data = nil;
        }
        [rs close];
        
    }];
    
    [queue close];
    
    if ([_icStatus isEqualToString:@"Edit"]) {
        for (int i = 0; i < condimentDtlArray.count; i++) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"CDCode MATCHES[cd] %@",
                                      [[condimentDtlArray objectAtIndex:i] objectForKey:@"CDCode"]];
            
            NSArray * selectedObject = [icAddedArray filteredArrayUsingPredicate:predicate];
            NSString *unitQty;
            if (selectedObject.count > 0) {
                NSUInteger indexOfArray = 0;
                indexOfArray = [icAddedArray indexOfObject:selectedObject[0]];
                unitQty = [NSString stringWithFormat:@"%ld",[[[icAddedArray objectAtIndex:indexOfArray] objectForKey:@"UnitQty"] integerValue]];
                [self replaceCondimentOrderWithQty:unitQty Index:i ArrayName:@"condimentDtlArray"];
            }
            selectedObject = nil;
            
        }
    }
    
    
    [self.collectionAddCondiment reloadData];
}

#pragma mark - uicollection and scroll view part

#pragma mark - programatic didselect collectionview
-(void)manualDidSelectCollectionViewWithIndexNo:(NSUInteger)rowNo
{
    condimentGroupSelectedIndex = rowNo;
    NSIndexPath *indexPathForFirstRow = [NSIndexPath indexPathForItem:rowNo inSection:0];
    [self.collectionCondimentGroup selectItemAtIndexPath:indexPathForFirstRow animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    [self collectionView:self.collectionCondimentGroup didSelectItemAtIndexPath:indexPathForFirstRow];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    long count;
    if (collectionView == self.collectionCondimentGroup)
    {
        count = condimentGroupArray.count;
    }
    else if(collectionView == self.collectionAddCondiment)
    {
        count = condimentDtlArray.count;
    }
    
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    id cellToReturn;
    if (collectionView == self.collectionCondimentGroup)
    {
        CondimentHdrCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:itemHdrIdentifier forIndexPath:indexPath];
        [cell.labelCondimentGroup setText:[[condimentGroupArray objectAtIndex:indexPath.row] objectForKey:@"CH_Description"]];
        [cell.labelCondimentGroup setTag:indexPath.row];
        
        //[[cell btnCondimentGroup] addTarget:self action:@selector(callCondimentDtlView:) forControlEvents:UIControlEventTouchUpInside];
        
        if (condimentGroupSelectedIndex == indexPath.row) {
            cell.imgBackground.image = [UIImage imageNamed:@"CdtHdrWhite.png"];
            cell.labelCondimentGroup.textColor = [UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0];
        }
        else
        {
            cell.imgBackground.image = [UIImage imageNamed:@"CdtHdrBlue.png"];
            cell.labelCondimentGroup.textColor = [UIColor whiteColor];
        }
        
        
        cellToReturn = cell;
    }
    else if(collectionView == self.collectionAddCondiment)
    {
        OrderAddCondimentDtlCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:itemDtlIdentifier forIndexPath:indexPath];
        
        cell.layer.borderWidth=1.0f;
        cell.layer.cornerRadius = 4;
        cell.layer.borderColor=[UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0].CGColor;
        
        //cell.labelBadgeNo.layer.borderWidth = 1;
        //cell.labelBadgeNo.layer.cornerRadius = 8;
        //cell.labelBadgeNo.layer.masksToBounds = YES;
        [cell.btnCondimentDtl addTarget:self
                                 action:@selector(addOnCondimentDtl:)
                       forControlEvents:UIControlEventTouchUpInside];
        
        [cell.btnAddCdt addTarget:self
                                 action:@selector(addOnCondimentDtl:)
                       forControlEvents:UIControlEventTouchUpInside];
        
        [cell.btnDeductCdt addTarget:self
                           action:@selector(deductCondimentDtl:)
                 forControlEvents:UIControlEventTouchUpInside];
        
        /*
        UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(cancelAddOnCondimentDtl:)];
        tapGes.numberOfTapsRequired = 1;
        [cell.labelBadgeNo addGestureRecognizer:tapGes];
        cell.labelBadgeNo.userInteractionEnabled = true;
        */
        [cell.btnCondimentDtl setTitle:[[condimentDtlArray objectAtIndex:indexPath.row] objectForKey:@"CDDescription"] forState:UIControlStateNormal];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"CDCode MATCHES[cd] %@",
                                  [[condimentDtlArray objectAtIndex:indexPath.row] objectForKey:@"CDCode"]];
        
        NSArray * selectedObject = [addedCondimentArray filteredArrayUsingPredicate:predicate];
        
        if (selectedObject.count > 0) {
            NSUInteger indexOfArray = 0;
            indexOfArray = [addedCondimentArray indexOfObject:selectedObject[0]];
            cell.labelBadgeNo.hidden = false;
            cell.btnDeductCdt.hidden = false;
            cell.btnAddCdt.hidden = false;
            cell.labelBadgeNo.text = [NSString stringWithFormat:@"%ld",[[[addedCondimentArray objectAtIndex:indexOfArray] objectForKey:@"UnitQty"] integerValue]];
        }
        else
        {
            if ([[[condimentDtlArray objectAtIndex:indexPath.row] objectForKey:@"UnitQty"] integerValue] > 0) {
                cell.labelBadgeNo.hidden = false;
                cell.btnDeductCdt.hidden = false;
                cell.btnAddCdt.hidden = false;
                cell.labelBadgeNo.text = [NSString stringWithFormat:@"%ld",[[[condimentDtlArray objectAtIndex:indexPath.row] objectForKey:@"UnitQty"] integerValue]];
            }
            else
            {
                cell.labelBadgeNo.hidden = true;
                cell.btnDeductCdt.hidden = true;
                cell.btnAddCdt.hidden = true;
                cell.labelBadgeNo.text = @"0";
            }
        }
        selectedObject = nil;
        
        cellToReturn = cell;
    }
    
    //
    
    return cellToReturn;
}


- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)view forElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
    
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (collectionView == self.collectionCondimentGroup)
    {
        condimentGroupSelectedIndex = indexPath.row;
        self.title = [[condimentGroupArray objectAtIndex:indexPath.row] objectForKey:@"CH_Description"];
        [self callCondimentDtlViewWithIndexNo:indexPath.row];
        
        [self.collectionCondimentGroup reloadData];
    }
}

-(void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (collectionView == self.collectionAddCondiment)
    {
        UICollectionViewCell *datasetCell =[collectionView cellForItemAtIndexPath:indexPath];
        datasetCell.contentView.backgroundColor = [UIColor clearColor];
    }
    
}


-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.secretScrollView) {
        CGPoint contentOffset = scrollView.contentOffset;
        contentOffset.x = contentOffset.x - self.collectionAddCondiment.contentInset.left;
        self.collectionAddCondiment.contentOffset = contentOffset;
    }
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    CGFloat pageWidth = self.collectionCondimentGroup.frame.size.width;
    self.pageControlCondimentgroup.currentPage = self.collectionCondimentGroup.contentOffset.x / pageWidth;
}

#pragma mark - adding condiment

-(void)callCondimentDtlViewWithIndexNo:(NSUInteger)index
{
    
    chCode = [[condimentGroupArray objectAtIndex:index] objectForKey:@"CH_Code"];
    [condimentDtlArray removeAllObjects];
    [self getCondimentDtl];
}


-(IBAction)addOnCondimentDtl:(UIButton *)sender
{
    OrderAddCondimentDtlCollectionViewCell *cell = (OrderAddCondimentDtlCollectionViewCell *)sender.superview.superview;
    
    NSIndexPath *indexPath = [self.collectionAddCondiment indexPathForCell:cell];
    
    NSString *orderCount;
    
    
    if (addedCondimentArray.count > 0) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"CDCode MATCHES[cd] %@",
                                  [[condimentDtlArray objectAtIndex:indexPath.row] objectForKey:@"CDCode"]];
        
        NSArray * selectedObject = [addedCondimentArray filteredArrayUsingPredicate:predicate];
        
        if (selectedObject.count > 0) {
            NSUInteger indexOfArray = 0;
            indexOfArray = [addedCondimentArray indexOfObject:selectedObject[0]];
            orderCount = [NSString stringWithFormat:@"%ld",[[[addedCondimentArray objectAtIndex:indexOfArray] objectForKey:@"UnitQty"] integerValue] + 1];
            [self replaceCondimentOrderWithQty:orderCount Index:indexOfArray ArrayName:@"addedCondimentArray"];
            
        }
        else
        {
            orderCount = @"1";
            [self addCondimentToFinalArrayWithIndexPath:indexPath UnitQty:orderCount];
        }
        selectedObject = nil;
        
    }
    else
    {
        orderCount = @"1";
        [self addCondimentToFinalArrayWithIndexPath:indexPath UnitQty:orderCount];
    }
    
    cell.labelBadgeNo.text = orderCount;
    cell.labelBadgeNo.hidden = false;
    cell.btnDeductCdt.hidden = false;
    cell.btnAddCdt.hidden = false;
    
    cell = nil;
}

-(IBAction)deductCondimentDtl:(UIButton *)sender
{
    OrderAddCondimentDtlCollectionViewCell *cell = (OrderAddCondimentDtlCollectionViewCell *)sender.superview.superview;
    
    NSIndexPath *indexPath = [self.collectionAddCondiment indexPathForCell:cell];
    
    NSString *orderCount;
    
    
    if (addedCondimentArray.count > 0) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"CDCode MATCHES[cd] %@",
                                  [[condimentDtlArray objectAtIndex:indexPath.row] objectForKey:@"CDCode"]];
        
        NSArray * selectedObject = [addedCondimentArray filteredArrayUsingPredicate:predicate];
        
        if (selectedObject.count > 0) {
            NSUInteger indexOfArray = 0;
            indexOfArray = [addedCondimentArray indexOfObject:selectedObject[0]];
            orderCount = [NSString stringWithFormat:@"%ld",[[[addedCondimentArray objectAtIndex:indexOfArray] objectForKey:@"UnitQty"] integerValue] - 1];
            if ([orderCount integerValue] <= 0) {
                orderCount = 0;
                //cell.labelBadgeNo.text = @"0";
                [addedCondimentArray removeObjectAtIndex:indexOfArray];
                //[self.collectionAddCondiment reloadData];
                cell.labelBadgeNo.hidden = true;
                cell.btnDeductCdt.hidden = true;
                cell.btnAddCdt.hidden = true;
                
            }
            else
            {
                [self replaceCondimentOrderWithQty:orderCount Index:indexOfArray ArrayName:@"addedCondimentArray"];
            }
            
        }
        else
        {
            orderCount = @"1";
            [self addCondimentToFinalArrayWithIndexPath:indexPath UnitQty:orderCount];
        }
        selectedObject = nil;
        
    }
    else
    {
        //orderCount = @"1";
        //[self addCondimentToFinalArrayWithIndexPath:indexPath UnitQty:orderCount];
    }
    
    cell.labelBadgeNo.text = orderCount;
    //cell.labelBadgeNo.hidden = false;
    //cell.btnDeductCdt.hidden = false;
    //cell.btnAddCdt.hidden = false;
    
    cell = nil;
}

-(void)addCondimentToFinalArrayWithIndexPath:(NSIndexPath *)indexPath UnitQty:(NSString *)orderCount
{
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data setObject:_icItemCode forKey:@"ItemCode"];
    [data setObject:chCode forKey:@"CHCode"];
    [data setObject:[[condimentDtlArray objectAtIndex:indexPath.row] objectForKey:@"CDCode"] forKey:@"CDCode"];
    [data setObject:[[condimentDtlArray objectAtIndex:indexPath.row] objectForKey:@"CDDescription"] forKey:@"CDDescription"];
    [data setObject:orderCount forKey:@"UnitQty"];
    [data setObject:[[condimentDtlArray objectAtIndex:indexPath.row] objectForKey:@"CDPrice"] forKey:@"CDPrice"];
    [data setObject:@"0.00" forKey:@"IM_DiscountAmt"];
    [data setObject:@"CondimentOrder" forKey:@"OrderType"];
    [data setObject:parentIndex forKey:@"ParentIndex"];
    
    [addedCondimentArray addObject:data];

    data = nil;
}

-(void)replaceCondimentOrderWithQty:(NSString *)qty Index:(NSUInteger)index ArrayName:(NSString *)name
{
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    if ([name isEqualToString:@"condimentDtlArray"]) {
        data = [condimentDtlArray objectAtIndex:index];
        [data setValue:qty forKey:@"UnitQty"];
        [condimentDtlArray replaceObjectAtIndex:index withObject:data];
    }
    else if ([name isEqualToString:@"addedCondimentArray"])
    {
        data = [addedCondimentArray objectAtIndex:index];
        [data setValue:qty forKey:@"UnitQty"];
        [addedCondimentArray replaceObjectAtIndex:index withObject:data];
    }
    
    
    data = nil;
}

-(void)cancelAddOnCondimentDtl:(UITapGestureRecognizer *)sender
{
    OrderAddCondimentDtlCollectionViewCell *cell = (OrderAddCondimentDtlCollectionViewCell *)sender.view.superview.superview;
    
    NSIndexPath *indexPath = [self.collectionAddCondiment indexPathForCell:cell];
    
    for (int i= 0; i < addedCondimentArray.count; i++) {
        if ([[[addedCondimentArray objectAtIndex:i] objectForKey:@"CDCode"] isEqualToString:[[condimentDtlArray objectAtIndex:indexPath.row] objectForKey:@"CDCode"]]) {
            [addedCondimentArray removeObjectAtIndex:i];
        }
    }
    
    cell.labelBadgeNo.text = @"0";
    cell.labelBadgeNo.hidden = true;
    cell.btnDeductCdt.hidden = true;
    cell.btnAddCdt.hidden = true;
    cell = nil;
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)btnDoneSelectCondiment:(id)sender {
    [self confirmAddCondiment];
}
@end
