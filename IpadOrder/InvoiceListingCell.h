//
//  InvoiceListingCell.h
//  IpadOrder
//
//  Created by IRS on 9/10/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InvoiceListingCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *labelInvNo;
@property (strong, nonatomic) IBOutlet UILabel *labelInvDate;
@property (strong, nonatomic) IBOutlet UILabel *labelInvSubtotal;
@property (strong, nonatomic) IBOutlet UILabel *labelInvTax;
@property (strong, nonatomic) IBOutlet UILabel *labelInvTotal;
@property (weak, nonatomic) IBOutlet UILabel *labelInvSvc;

@end
