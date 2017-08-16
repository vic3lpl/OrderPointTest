//
//  PaymentTypeImgViewController.h
//  IpadOrder
//
//  Created by IRS on 29/11/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PaymentTypeImgDelegate <NSObject>

@required
-(void)getSelectedPaymentTypeImgNameWithImgName:(NSString *)name;

@end

@interface PaymentTypeImgViewController : UIViewController
@property (nonatomic,weak) id<PaymentTypeImgDelegate>delegate;

- (IBAction)btnSelectPaymentTypeImg:(id)sender;


@end
