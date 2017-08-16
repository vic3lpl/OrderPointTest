//
//  KeyNumericViewController.h
//  IpadOrder
//
//  Created by IRS on 8/26/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NumericKeypadDelegate.h"

@protocol NumericKeyDelegate <NSObject>
@optional
-(void)passNumericBack:(double)noKey flag:(NSString *)flag splitBillArrayIndex:(int)index TotalCondimentSurCharge:(double)totalCondimentCharge;

@end

@interface KeyNumericViewController : UIViewController <NumericKeypadDelegate,UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet NumericKeypadTextField *textNumeric;


- (IBAction)btnConfirmNum:(id)sender;


- (IBAction)btnCancelNum:(id)sender;

@property(nonatomic,weak)id<NumericKeyDelegate>delegate;
@property double orgSOQty;
@property double orgSOItemCount;
@property double orgTotalCondimentSurcharge;
@end
