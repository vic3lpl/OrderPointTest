//
//  SelectModifierItemCell.h
//  IpadOrder
//
//  Created by IRS on 11/03/2017.
//  Copyright © 2017 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SelectModifierItemCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imagePackageItem;
@property (weak, nonatomic) IBOutlet UILabel *labelPackageItemDesc;
@property (weak, nonatomic) IBOutlet UILabel *labelPackageItemPrice;

@end
