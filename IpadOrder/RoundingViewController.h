//
//  RoundingViewController.h
//  IpadOrder
//
//  Created by IRS on 9/17/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NumericKeypadDelegate.h"
#import "BaseDetailViewController.h"

@interface RoundingViewController : BaseDetailViewController <NumericKeypadDelegate,UITextFieldDelegate>
@property (strong, nonatomic) IBOutlet NumericKeypadTextField *r1;
@property (strong, nonatomic) IBOutlet NumericKeypadTextField *r2;
@property (strong, nonatomic) IBOutlet NumericKeypadTextField *r3;
@property (strong, nonatomic) IBOutlet NumericKeypadTextField *r4;
@property (strong, nonatomic) IBOutlet NumericKeypadTextField *r5;
@property (strong, nonatomic) IBOutlet NumericKeypadTextField *r6;
@property (strong, nonatomic) IBOutlet NumericKeypadTextField *r7;
@property (strong, nonatomic) IBOutlet NumericKeypadTextField *r8;
@property (strong, nonatomic) IBOutlet NumericKeypadTextField *r9;
@property (weak, nonatomic) IBOutlet UIView *viewRoundBg;

@end
