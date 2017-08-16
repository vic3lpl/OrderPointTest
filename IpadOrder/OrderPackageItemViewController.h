//
//  OrderPackageItemViewController.h
//  IpadOrder
//
//  Created by IRS on 09/03/2017.
//  Copyright © 2017 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OrderAddCondimentViewController.h"
#import "SelectModifierItemViewController.h"

@protocol OrderPackageItemDelegate <NSObject>
@required
-(void)passBackPackageItemDetailToOrderScreenWithPackageDetail:(NSMutableArray *)array DisplayFormat:(NSString *)displayFormat TotalSurcharge:(double)totalSurcharge Status:(NSString *)status PackageItemCode:(NSString *)pItemCode PackageItemDesc:(NSString *)pItemDesc;

-(void)passBackEditedPackageItemDetailToOrderScreenWithPackageDetail:(NSMutableArray *)array DisplayFormat:(NSString *)displayFormat TotalSurcharge:(double)totalSurcharge Status:(NSString *)status PackageItemCode:(NSString *)pItemCode PackageItemDesc:(NSString *)pItemDesc OrderingViewParentIndex:(NSString *)parentIndex;

@end

@interface OrderPackageItemViewController : UIViewController <UITableViewDelegate, UITableViewDataSource,OrderAddCondimentDelegate, SelectModifierItemDelegate, UICollectionViewDelegate,UICollectionViewDataSource,UIScrollViewDelegate>

- (IBAction)btnTestData:(id)sender;
@property (weak, nonatomic) IBOutlet UITableView *tableViewPackageItemListing;
- (IBAction)btnCompletePackageSelection:(id)sender;
@property (strong, nonatomic) NSString *imCode;
@property (strong, nonatomic) NSString *imName;
@property (strong, nonatomic) NSString *orderPackageStatus;
@property (strong, nonatomic) NSString *orderingViewParentIndex;
@property (assign, nonatomic) BOOL itemWithCondiment;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionModifierItemList;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollViewModifierItem;
@property (retain, nonatomic)NSArray *completedOrderPackageArray;

- (IBAction)btnCancelPackageSelection:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *labelModifierTitle;

@property (weak, nonatomic) IBOutlet UIView *viewModifierItem;
@property (nonatomic,weak) id<OrderPackageItemDelegate>delegate;
@end
