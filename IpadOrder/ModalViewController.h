//
//  ModalViewController.h
//  IpadOrder
//
//  Created by IRS on 6/30/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NumericKeypadDelegate.h"

@interface ModalViewController : UIViewController<NumericKeypadDelegate,UITextFieldDelegate>
- (IBAction)done:(id)sender;

@property (strong, nonatomic) IBOutlet NumericKeypadTextField *ttt;

@end
