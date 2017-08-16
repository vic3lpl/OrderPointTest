//
//  SalesOrderDetailTableViewCell.h
//  IpadOrder
//
//  Created by IRS on 28/06/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SalesOrderDetailTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *labelSODTotal;
@property (weak, nonatomic) IBOutlet UILabel *labelSODDiscAmt;
@property (weak, nonatomic) IBOutlet UILabel *labelSODPrice;
@property (weak, nonatomic) IBOutlet UILabel *labelSODQty;
@property (weak, nonatomic) IBOutlet UILabel *labelSODItemDesc;

@end
