//
//  PaymentMethodTableViewCell.h
//  IpadOrder
//
//  Created by IRS on 8/20/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PaymentMethodTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *cellLabelTotalAmt;
@property (strong, nonatomic) IBOutlet UIButton *cellBtnCash;

@end
