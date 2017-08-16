//
//  ItemTaxEditViewController.h
//  IpadOrder
//
//  Created by IRS on 7/10/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NumericKeypadDelegate.h"

@interface ItemTaxEditViewController : UIViewController <NumericKeypadDelegate,UITextFieldDelegate>
{
    
}
@property (weak, nonatomic) IBOutlet UITextField *textTaxName;
@property (weak, nonatomic) IBOutlet UITextField *textTaxDesc;
@property (weak, nonatomic) IBOutlet NumericKeypadTextField *textTaxPercent;

@property (nonatomic, copy)NSString *userTaxAction;
@property (nonatomic,copy)NSString *taxName;
@property (weak, nonatomic) IBOutlet UIView *viewTaxBg;
@property (weak, nonatomic) IBOutlet UITextField *textAccTaxCode;

@end
