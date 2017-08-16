//
//  BillListingTableViewCell.h
//  IpadOrder
//
//  Created by IRS on 04/05/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BillListingTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *labelDocNo;
@property (weak, nonatomic) IBOutlet UILabel *labelDocAmt;
@property (weak, nonatomic) IBOutlet UILabel *labelStatus;

@end
