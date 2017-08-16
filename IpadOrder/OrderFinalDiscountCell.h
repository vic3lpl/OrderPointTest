//
//  OrderFinalDiscountCell.h
//  IpadOrder
//
//  Created by IRS on 8/11/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OrderFinalDiscountCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *finalDisDesc;
@property (strong, nonatomic) IBOutlet UILabel *finalDisQty;
@property (strong, nonatomic) IBOutlet UILabel *finalDisPrice;
@property (strong, nonatomic) IBOutlet UILabel *finalDisAmt;
@property (strong, nonatomic) IBOutlet UILabel *finalDisDis;
@property (weak, nonatomic) IBOutlet UILabel *finalDisTakeAway;
@property (weak, nonatomic) IBOutlet UIImageView *finalDisTakeAwayImg;

@end
