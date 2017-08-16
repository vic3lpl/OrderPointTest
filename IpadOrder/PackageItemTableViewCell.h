//
//  PackageItemTableViewCell.h
//  IpadOrder
//
//  Created by IRS on 05/04/2017.
//  Copyright © 2017 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PackageItemTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *labelModifierTitle;
@property (weak, nonatomic) IBOutlet UILabel *labelPackageItemName;

@end
