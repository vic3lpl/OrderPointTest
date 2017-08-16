//
//  SplitBillTableViewCell.h
//  IpadOrder
//
//  Created by IRS on 31/03/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SplitBillTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *labelItemDesc;
@property (weak, nonatomic) IBOutlet UILabel *labelItemQty;
@property (weak, nonatomic) IBOutlet UILabel *labelItemPrice;
@property (weak, nonatomic) IBOutlet UILabel *labelItemTotal;
@property (weak, nonatomic) IBOutlet UILabel *labelTakeAway;
@property (weak, nonatomic) IBOutlet UIImageView *imgTakeAway;

@end
