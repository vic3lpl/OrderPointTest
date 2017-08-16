//
//  VoidOrderReasonViewController.h
//  IpadOrder
//
//  Created by IRS on 03/05/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol VoidOrderReasonDelegate<NSObject>
@required
-(void)dismissVoidOrderViewWithResult:(NSString *)result;
@end

@interface VoidOrderReasonViewController : UIViewController

- (IBAction)btnCancelVoidOrder:(id)sender;
- (IBAction)btnVoidOrder:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *textAdminPassword;
@property (weak, nonatomic) IBOutlet UITextField *textVoidReason;
@property (weak, nonatomic) IBOutlet UITextField *textUsername;
@property (strong,nonatomic) NSString *voidTableName;

@property(nonatomic, weak)id<VoidOrderReasonDelegate>delegate;

//@property NSString *voidSONo;

@end
