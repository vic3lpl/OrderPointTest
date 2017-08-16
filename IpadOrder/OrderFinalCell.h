//
//  OrderFinalCell.h
//  IpadOrder
//
//  Created by IRS on 8/7/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OrderFinalCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *finalAmt;
@property (strong, nonatomic) IBOutlet UILabel *finalQty;
@property (strong, nonatomic) IBOutlet UILabel *finalDesc;
@property (strong, nonatomic) IBOutlet UILabel *finalPrice;
//@property (strong, nonatomic) IBOutlet UILabel *finalTax;
@property (weak, nonatomic) IBOutlet UILabel *finalTakeAway;
@property (weak, nonatomic) IBOutlet UIImageView *finalTakeAwayImg;

@end
