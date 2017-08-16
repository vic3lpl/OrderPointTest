//
//  InvoiceListingFooterCell.h
//  IpadOrder
//
//  Created by IRS on 9/10/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InvoiceListingFooterCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *labelTotal;
@property (strong, nonatomic) IBOutlet UILabel *labelTotalTaxAmt;
@property (strong, nonatomic) IBOutlet UILabel *labelGTotalAmt;
@property (weak, nonatomic) IBOutlet UILabel *labelTotalSvcAmt;
@property (weak, nonatomic) IBOutlet UILabel *labelTotalSubTotal;

@end
