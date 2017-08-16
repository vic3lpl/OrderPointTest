//
//  LinkToAccountViewController.h
//  IpadOrder
//
//  Created by IRS on 11/10/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DatePickerViewController.h"

@interface LinkToAccountViewController : UIViewController <UITextFieldDelegate,DatePickerDelegate>
- (IBAction)btnLinkToAcct:(id)sender;

- (IBAction)btnCancelLinkAccount:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *textLinkAccDateFrom;
@property (weak, nonatomic) IBOutlet UITextField *textLinkAccDateTo;
@property (strong, nonatomic) NSString *accPassword;

@property (weak, nonatomic) IBOutlet UILabel *labelFailDocNo;


@end
