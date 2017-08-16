//
//  OrderItemCell.h
//  IpadOrder
//
//  Created by IRS on 8/5/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OrderItemCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imgItem1;
@property (weak, nonatomic) IBOutlet UIImageView *imgItem2;
@property (weak, nonatomic) IBOutlet UIImageView *imgItem3;
@property (weak, nonatomic) IBOutlet UILabel *lblItem1;
@property (weak, nonatomic) IBOutlet UILabel *lblItem2;
@property (weak, nonatomic) IBOutlet UILabel *lblItem3;

@end
