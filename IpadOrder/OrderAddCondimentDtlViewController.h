//
//  OrderAddCondimentDtlViewController.h
//  IpadOrder
//
//  Created by IRS on 04/09/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OrderAddCondimentDtlViewController : UIViewController<UICollectionViewDelegate,UICollectionViewDataSource>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionAddCondimentDtl;
@property (weak, nonatomic) NSString *chCode;
@end
