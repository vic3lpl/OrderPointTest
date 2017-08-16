//
//  OrderAddCondimentViewController.h
//  IpadOrder
//
//  Created by IRS on 04/09/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OrderAddCondimentDelegate <NSObject>

@optional
-(void)passBackToOrderScreenWithCondimentDtl:(NSMutableArray *)array DisplayFormat:(NSString *)displayFormat TotalCondimentPrice:(double)totalCondimentPrice Status:(NSString *)status CondimentUnitPrice:(double)condimentUnitPrice PredicatePrice:(double)predicatePrice;

-(void)passBackToOrderScreenWithEditedCondimentDtl:(NSMutableArray *)array DisplayFormat:(NSString *)displayFormat TotalCondimentPrice:(double)totalCondimentPrice ParentIndex:(NSString *)parentIndex CondimentUnitPrice:(double)condimentUnitPrice;

-(void)passBackToOrderPackageItemDetailWithCondimentDtl:(NSMutableArray *)array DisplayFormat:(NSString *)displayFormat TotalCondimentPrice:(double)totalCondimentPrice Status:(NSString *)status CondimentUnitPrice:(double)condimentUnitPrice;

-(void)passBackToOrderPackageItemDetailWithEditedCondimentDtl:(NSMutableArray *)array DisplayFormat:(NSString *)displayFormat TotalCondimentPrice:(double)totalCondimentPrice ParentIndex:(NSString *)parentIndex CondimentUnitPrice:(double)condimentUnitPrice;

-(void)passBackToOrderModifierItemDetailWithCondimentDtl:(NSMutableArray *)array DisplayFormat:(NSString *)displayFormat TotalCondimentPrice:(double)totalCondimentPrice Status:(NSString *)status CondimentUnitPrice:(double)condimentUnitPrice;

-(void)passBackToOrderModifierItemDetailWithEditedCondimentDtl:(NSMutableArray *)array DisplayFormat:(NSString *)displayFormat TotalCondimentPrice:(double)totalCondimentPrice Status:(NSString *)status CondimentUnitPrice:(double)condimentUnitPrice;

-(void)forceOrderDetailViewControllerClose;

-(void)reverseSelectedPackageItem;

@end

@interface OrderAddCondimentViewController : UIViewController<UICollectionViewDataSource,UICollectionViewDelegate,UIScrollViewDelegate>
{
    //NSMutableArray *icAddedArray;
}
@property (weak, nonatomic) IBOutlet UICollectionView *collectionAddCondiment;
@property (weak, nonatomic) IBOutlet UIScrollView *secretScrollView;

@property (strong, nonatomic)NSString *icItemCode;
@property (strong, nonatomic)NSString *icItemPrice;

@property (strong, nonatomic)NSString *collectionItemCode;
@property (strong, nonatomic)NSString *icStatus;
@property (retain, nonatomic)NSArray *icAddedArray;
@property (strong, nonatomic)NSString *selectedCHCode;
@property (strong, nonatomic)NSString *addCondimentFrom;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionCondimentGroup;

@property (nonatomic,weak) id<OrderAddCondimentDelegate>delegate;
@property (strong, nonatomic)NSString *parentIndex;
- (IBAction)btnDoneSelectCondiment:(id)sender;

@property (weak, nonatomic) IBOutlet UIPageControl *pageControlCondimentgroup;


//@property (weak, nonatomic)NSString *showAll;
@end
