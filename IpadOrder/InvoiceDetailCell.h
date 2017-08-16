//
//  InvoiceDetailCell.h
//  IpadOrder
//
//  Created by IRS on 9/10/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InvoiceDetailCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *labelDItemDesc;
@property (strong, nonatomic) IBOutlet UILabel *labelDQty;
@property (strong, nonatomic) IBOutlet UILabel *labelDUnitPrice;
@property (strong, nonatomic) IBOutlet UILabel *labelDDiscAmt;
@property (strong, nonatomic) IBOutlet UILabel *labelDTotalAmt;

@end
