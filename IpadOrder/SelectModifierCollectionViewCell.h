//
//  SelectModifierCollectionViewCell.h
//  IpadOrder
//
//  Created by IRS on 15/03/2017.
//  Copyright © 2017 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SelectModifierCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imageMItemMast;
@property (weak, nonatomic) IBOutlet UILabel *labelMSurcharge;
@property (weak, nonatomic) IBOutlet UILabel *labelMDesc;
@property (weak, nonatomic) IBOutlet UILabel *labelSelected;

@end
