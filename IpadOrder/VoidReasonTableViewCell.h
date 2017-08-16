//
//  VoidReasonTableViewCell.h
//  IpadOrder
//
//  Created by IRS on 11/05/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VoidReasonTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *labelVoidReason;
@property (weak, nonatomic) IBOutlet UILabel *labelVoidDocNo;
@property (weak, nonatomic) IBOutlet UILabel *labelVoidDate;

@end
