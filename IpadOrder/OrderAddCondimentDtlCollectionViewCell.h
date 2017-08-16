//
//  OrderAddCondimentDtlCollectionViewCell.h
//  IpadOrder
//
//  Created by IRS on 04/09/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OrderAddCondimentDtlCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIButton *btnCondimentDtl;
@property (weak, nonatomic) IBOutlet UILabel *labelBadgeNo;
@property (weak, nonatomic) IBOutlet UIButton *btnDeductCdt;
@property (weak, nonatomic) IBOutlet UIButton *btnAddCdt;

@end
