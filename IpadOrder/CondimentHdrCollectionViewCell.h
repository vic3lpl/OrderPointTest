//
//  CondimentHdrCollectionViewCell.h
//  IpadOrder
//
//  Created by IRS on 05/09/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
/*
@class CondimentHdrCollectionViewCell;
@protocol CondimentHdrDelegate <NSObject>

-(void)customCell:(CondimentHdrCollectionViewCell *)cell actionForButton:(UIButton *)inButton;

@end
*/
@interface CondimentHdrCollectionViewCell : UICollectionViewCell
//@property (weak, nonatomic) IBOutlet UIButton *btnCondimentGroup;
//@property (weak, nonatomic) id<CondimentHdrDelegate> condimentHdrDelegate;
@property (weak, nonatomic) IBOutlet UILabel *labelCondimentGroup;
@property (weak, nonatomic) IBOutlet UIImageView *imgBackground;

@end
