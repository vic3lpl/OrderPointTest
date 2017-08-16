//
//  OrderAddCondimentDtlViewController.m
//  IpadOrder
//
//  Created by IRS on 04/09/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import "OrderAddCondimentDtlViewController.h"
#import "FullyHorizontalFlowLayout.h"
#import "LibraryAPI.h"
#import <FMDB.h>
#import "OrderAddCondimentDtlCollectionViewCell.h"

static NSString * const itemCellIdentifier = @"OrderAddCondimentDtlCollectionViewCell";
@interface OrderAddCondimentDtlViewController ()
{
    NSString *dbPath;
    FMDatabase *dbTable;
    NSMutableArray *condimentDetailArray;
}

@end

@implementation OrderAddCondimentDtlViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.preferredContentSize = CGSizeMake(520, 585);
    
    condimentDetailArray = [[NSMutableArray alloc] init];
    dbPath = [[LibraryAPI sharedInstance] getDbPath];
    
    // Do any additional setup after loading the view from its nib.
    
    UINib *itemCollectionNib = [UINib nibWithNibName:itemCellIdentifier bundle:nil];
    
    [_collectionAddCondimentDtl registerNib:itemCollectionNib forCellWithReuseIdentifier:itemCellIdentifier];
    
    FullyHorizontalFlowLayout *collectionViewLayout = [FullyHorizontalFlowLayout new];
    
    collectionViewLayout.itemSize = CGSizeMake(120., 120.);
    [collectionViewLayout setSectionInset:UIEdgeInsetsMake(0, 5, 0, 5)];
    
    /*
    UIBarButtonItem *newBackButton =
    [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(backToOrderingView)];
    self.navigationItem.leftBarButtonItem = newBackButton;
     */
    
    [self.collectionAddCondimentDtl setCollectionViewLayout:collectionViewLayout];
    self.collectionAddCondimentDtl.dataSource = self;
    self.collectionAddCondimentDtl.delegate = self;
    self.collectionAddCondimentDtl.pagingEnabled = true;
    //self.secretScrollView.delegate = self;
    
    [self getCondimentDtl];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - sqlite
-(void)getCondimentDtl
{
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"Select *, '0' as OrderQty from CondimentDtl where CD_CondimentHdrCode = ?",_chCode];
        
        while ([rs next]) {
            [condimentDetailArray addObject:[rs resultDictionary]];
        }
        [rs close];
        
    }];
    
    
    [queue close];
    [self.collectionAddCondimentDtl reloadData];
}

#pragma mark - uicollection and scroll view part

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return condimentDetailArray.count;
    
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    //static NSString *identifier = @"OrderAddCondimentCollectionViewCell";
    
    OrderAddCondimentDtlCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:itemCellIdentifier forIndexPath:indexPath];
    
    [cell.btnCondimentDtl setTitle:[[condimentDetailArray objectAtIndex:indexPath.row] objectForKey:@"CD_Description"] forState:UIControlStateNormal];
    cell.labelBadgeNo.layer.borderWidth = 1;
    cell.labelBadgeNo.layer.cornerRadius = 8;
    cell.labelBadgeNo.layer.masksToBounds = YES;
    cell.labelBadgeNo.hidden = true;
    [cell.btnCondimentDtl addTarget:self
                    action:@selector(addOnCondimentDtl:)
          forControlEvents:UIControlEventTouchUpInside];
    
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(cancelAddOnCondimentDtl:)];
    //tapGes.delegate = self;
    tapGes.numberOfTapsRequired = 1;
    [cell.labelBadgeNo addGestureRecognizer:tapGes];
    cell.labelBadgeNo.userInteractionEnabled = true;
    
    
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
    /*
     long itemSelectedIndex;
     
     if ([isFiltered isEqualToString:@"True"]) {
     itemSelectedIndex = [[[itemMastArrayFilter objectAtIndex:indexPath.row] objectForKey:@"IM_No"] integerValue];
     }
     else
     {
     itemSelectedIndex = [[[itemMastArray objectAtIndex:indexPath.row] objectForKey:@"IM_No"] integerValue];
     }
     
     UICollectionViewCell *datasetCell =[collectionView cellForItemAtIndexPath:indexPath];
     datasetCell.contentView.backgroundColor = [UIColor colorWithRed:189/255.0 green:189/255.0 blue:189/255.0 alpha:1.0];
     directExit = @"No";
     
     [self groupCalcItemPrice:itemSelectedIndex ItemQty:@"1.0" KitchReceiptStatus:@"Print"];
     */
    /*
     if ([terminalType isEqualToString:@"Terminal"]) {
     
     }
     */
    
}

-(void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell *datasetCell =[collectionView cellForItemAtIndexPath:indexPath];
    datasetCell.contentView.backgroundColor = [UIColor clearColor];
}

-(IBAction)addOnCondimentDtl:(UIButton *)sender
{
    OrderAddCondimentDtlCollectionViewCell *cell = (OrderAddCondimentDtlCollectionViewCell *)sender.superview.superview;
    
    NSIndexPath *indexPath = [self.collectionAddCondimentDtl indexPathForCell:cell];
    
    NSString *orderCount = [[condimentDetailArray objectAtIndex:indexPath.row] objectForKey:@"OrderQty"];
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data setValue:[NSString stringWithFormat:@"%ld",[orderCount integerValue] + 1] forKey:@"OrderQty"];
    [condimentDetailArray replaceObjectAtIndex:indexPath.row withObject:data];
    cell.labelBadgeNo.text = [NSString stringWithFormat:@"%ld",[orderCount integerValue] + 1];
    cell.labelBadgeNo.hidden = false;
    data = nil;
    cell = nil;
}

-(void)cancelAddOnCondimentDtl:(UITapGestureRecognizer *)sender
{
    OrderAddCondimentDtlCollectionViewCell *cell = (OrderAddCondimentDtlCollectionViewCell *)sender.view.superview.superview;
    
    NSIndexPath *indexPath = [self.collectionAddCondimentDtl indexPathForCell:cell];
    
    //NSString *orderCount = @"0";
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data setValue:@"0" forKey:@"OrderQty"];
    [condimentDetailArray replaceObjectAtIndex:indexPath.row withObject:data];
    cell.labelBadgeNo.text = @"0";
    cell.labelBadgeNo.hidden = true;
    data = nil;
    cell = nil;
}

/*
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.secretScrollView) {
        CGPoint contentOffset = scrollView.contentOffset;
        contentOffset.x = contentOffset.x - self.collectionAddCondiment.contentInset.left;
        self.collectionAddCondiment.contentOffset = contentOffset;
    }
}
 */
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
