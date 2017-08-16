//
//  ActivateDeviceViewController.h
//  IpadOrder
//
//  Created by IRS on 13/05/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SelectCatTableViewController.h"

@protocol ActivateDeviceDelegate <NSObject>
@required
-(void)afterRequestTerminalDevice;

@end

@interface ActivateDeviceViewController : UIViewController<UITextFieldDelegate,SelectCatDelegate>

@property (weak, nonatomic) IBOutlet UIButton *btnRegister;
@property (weak, nonatomic) IBOutlet UITextField *textCompanyName;
@property (weak, nonatomic) IBOutlet UITextField *textAdd1;
@property (weak, nonatomic) IBOutlet UITextField *textAdd2;
@property (weak, nonatomic) IBOutlet UITextField *textPostCode;
@property (weak, nonatomic) IBOutlet UITextField *textCountry;
@property (weak, nonatomic) IBOutlet UITextField *textPurchaseID;
@property (weak, nonatomic) IBOutlet UITextField *textTerminalQty;
- (IBAction)closeActivateDevice:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *btnSelectReg;
@property (weak, nonatomic) IBOutlet UIButton *btnSelectReReg;
@property (weak, nonatomic) IBOutlet UILabel *labelShare1;
@property (weak, nonatomic) IBOutlet UILabel *labelShare2;
@property (weak, nonatomic) IBOutlet UILabel *labelActivateAddress2;
@property (weak, nonatomic) IBOutlet UILabel *labelActivatePostCode;
@property (weak, nonatomic) IBOutlet UILabel *labelActivateCountry;
@property (weak, nonatomic) IBOutlet UILabel *labelActivateDealerID;
@property (weak, nonatomic) IBOutlet UILabel *labelActivateTerminalQty;
- (IBAction)btnRegActionSelected:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *textEmail;
@property (weak, nonatomic) IBOutlet UILabel *labelEmail;
//@property (strong, nonatomic) UIPopoverController *popOver;
@property(nonatomic,weak)id<ActivateDeviceDelegate>delegate;
@end
