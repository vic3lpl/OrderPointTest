//
//  UserNameSaveViewController.h
//  IpadOrder
//
//  Created by IRS on 7/7/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UserNameSaveViewController : UIViewController
@property(nonatomic, copy)NSString *userName;
@property(nonatomic,copy)NSString *userNameAction;
@property (weak, nonatomic) IBOutlet UITextField *textUserName;
@property (weak, nonatomic) IBOutlet UITextField *textPassword;
@property (weak, nonatomic) IBOutlet UITextField *textConfirmPassword;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentRole;
@property (weak, nonatomic) IBOutlet UIView *viewUserBg;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentReprintBillPermission;
@property NSUInteger userRole;
@end
