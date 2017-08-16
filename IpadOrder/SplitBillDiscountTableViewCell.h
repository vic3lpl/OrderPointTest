//
//  SplitBillDiscountTableViewCell.h
//  IpadOrder
//
//  Created by IRS on 31/03/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SplitBillDiscountTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *labelSplitDiscItem;
@property (weak, nonatomic) IBOutlet UILabel *labelSplitDiscQty;
@property (weak, nonatomic) IBOutlet UILabel *labelSplitDiscPrice;
@property (weak, nonatomic) IBOutlet UILabel *labelSplitDiscTotal;
@property (weak, nonatomic) IBOutlet UILabel *labelSplitDiscDisc;
@property (weak, nonatomic) IBOutlet UILabel *labelSplitDiscTakeAway;
@property (weak, nonatomic) IBOutlet UIImageView *imgSplitDiscTakeAway;

@end
