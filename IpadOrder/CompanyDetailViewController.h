//
//  CompanyDetailViewController.h
//  IpadOrder
//
//  Created by IRS on 31/03/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseDetailViewController.h"
#import "SelectCatTableViewController.h"

@interface CompanyDetailViewController : BaseDetailViewController<UITextFieldDelegate,SelectCatDelegate>
@property (nonatomic, retain) UIPopoverController *popoverController;
@property (weak, nonatomic) IBOutlet UITextField *companyName2;
@property (weak, nonatomic) IBOutlet UITextField *companyAddr12;
@property (weak, nonatomic) IBOutlet UITextField *companyAddr22;
@property (weak, nonatomic) IBOutlet UITextField *companyAddr32;

@property (weak, nonatomic) IBOutlet UITextField *companyCity2;
@property (weak, nonatomic) IBOutlet UITextField *companyPostCode2;
@property (weak, nonatomic) IBOutlet UITextField *companyState2;
@property (weak, nonatomic) IBOutlet UITextField *companyCountry2;
@property (weak, nonatomic) IBOutlet UITextField *companyTel2;
@property (weak, nonatomic) IBOutlet UITextField *companyEmail2;
@property (weak, nonatomic) IBOutlet UITextField *companyWebSite2;
@property (weak, nonatomic) IBOutlet UITextField *companyGst2;
@property (weak, nonatomic) IBOutlet UITextField *companyRegistrationNo2;

@property (strong, nonatomic) IBOutlet UIImageView *imgCompanyLogo2;
@property (strong, nonatomic) IBOutlet UIButton *btnChooseImg2;
@property (weak, nonatomic) IBOutlet UISwitch *switchEnableGst2;
//- (IBAction)switchTestClick:(id)sender;
@property (weak, nonatomic) IBOutlet UIView *viewCompanyBg2;
@property (weak, nonatomic) IBOutlet UILabel *labelLicenseKey;

@end
