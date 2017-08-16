//
//  DetailViewController.h
//  IpadOrder
//
//  Created by IRS on 7/1/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseDetailViewController.h"

@interface DetailViewController : BaseDetailViewController<UISplitViewControllerDelegate,UINavigationControllerDelegate,UIPopoverControllerDelegate>

@property (nonatomic, retain) UIPopoverController *popoverController;
@property (weak, nonatomic) IBOutlet UITextField *companyName;
@property (weak, nonatomic) IBOutlet UITextField *companyAddr1;
@property (weak, nonatomic) IBOutlet UITextField *companyAddr2;
@property (weak, nonatomic) IBOutlet UITextField *companyAddr3;

@property (weak, nonatomic) IBOutlet UITextField *companyCity;
@property (weak, nonatomic) IBOutlet UITextField *companyPostCode;
@property (weak, nonatomic) IBOutlet UITextField *companyState;
@property (weak, nonatomic) IBOutlet UITextField *companyCountry;
@property (weak, nonatomic) IBOutlet UITextField *companyTel;
@property (weak, nonatomic) IBOutlet UITextField *companyEmail;
@property (weak, nonatomic) IBOutlet UITextField *companyWebSite;
@property (weak, nonatomic) IBOutlet UITextField *companyGst;
@property (weak, nonatomic) IBOutlet UITextField *companyRegistrationNo;

@property (strong, nonatomic) IBOutlet UIImageView *imgCompanyLogo;
@property (strong, nonatomic) IBOutlet UIButton *btnChooseImg;
@property (weak, nonatomic) IBOutlet UISwitch *switchEnableGst;
//- (IBAction)switchTestClick:(id)sender;
@property (weak, nonatomic) IBOutlet UIView *viewCompanyBg;

@property (nonatomic,retain) id detailStruct;
@end
