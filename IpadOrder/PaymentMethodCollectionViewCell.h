//
//  PaymentMethodCollectionViewCell.h
//  IpadOrder
//
//  Created by IRS on 02/03/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PaymentMethodCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imgPayMethod;
@property (weak, nonatomic) IBOutlet UILabel *labelPaymentMethod;
@property (weak, nonatomic) IBOutlet UIView *viewBackground;

@end
