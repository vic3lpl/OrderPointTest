//
//  PaxEntryViewController.m
//  IpadOrder
//
//  Created by IRS on 26/08/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import "PaxEntryViewController.h"
#import "NumPadTextField/NumericKeypadTextField.h"
#import "NumericKeypadViewController.h"
#import "LibraryAPI.h"

#define ACCEPTABLE_CHARACTERS @"0123456789"
@interface PaxEntryViewController ()

@end

@implementation PaxEntryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.preferredContentSize = CGSizeMake(336, 521);
    
    UIImageView *paxIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Pax_32"]];
    paxIcon.frame = CGRectMake(0.0, 0.0, paxIcon.image.size.width, paxIcon.image.size.height);
    paxIcon.contentMode = UIViewContentModeScaleAspectFill;
    //paxIcon.contentMode = UIViewContentModeCenter;
    self.textIcon.leftView = paxIcon;
    self.textIcon.leftViewMode = UITextFieldViewModeAlways;
    self.textPaxEntry.borderStyle = UITextBorderStyleRoundedRect;
    self.textPaxEntry.layer.borderColor = [UIColor grayColor].CGColor;
    self.textPaxEntry.layer.cornerRadius = 1.0;
    
    paxIcon = nil;
    
    self.textPaxEntry.delegate = self;
    self.labelPaxTableName.text = [[LibraryAPI sharedInstance]getTableName];
    bigBtn = @"Confirm";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string  {
    
    if(textField==self.textPaxEntry&&range.location==0)
    {
        if ([string hasPrefix:@"0"])
        {
            return NO;
        }
    }
    
    NSLog(@"%ld",textField.text.length + string.length - range.length);
    
    if (textField.text.length + string.length - range.length > 3) {
        return NO;
    }
    
    NSCharacterSet *cs = [[NSCharacterSet characterSetWithCharactersInString:ACCEPTABLE_CHARACTERS] invertedSet];
    
    NSString *filtered = [[string componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
    
    return [string isEqualToString:filtered];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)btnCancelPaxEntry:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}
- (IBAction)btnConfirmPaxEntry:(id)sender {
    if ([self checkPaxNoTextField]) {
        [self.textPaxEntry resignFirstResponder];
        
        if (_delegate != nil) {
            if ([_requirePaxEntryView isEqualToString:@"SelectTableView"]) {
                [_delegate afterKeyInPaxNumberWithPaxNo:self.textPaxEntry.text];
            }
            else if ([_requirePaxEntryView isEqualToString:@"OrderingView"]) {
                [_delegate editKeyInPaxNumberWithPaxNo:self.textPaxEntry.text];
            }
        }
    }
    else
    {
        //[self.textPaxEntry becomeFirstResponder];
        [self showAlertView:@"Customer number cannot empty" title:@"Information"];
    }
    
}

-(BOOL)checkPaxNoTextField
{
    if ([self.textPaxEntry.text length] == 0) {
        return false;
    }
    else
    {
        return true;
    }
}

#pragma mark - alertView

-(void)showAlertView:(NSString *)msg title:(NSString *)title
{
    UIAlertController * alert = [[LibraryAPI sharedInstance] showAlertViewWithMsg:msg Title:title];
    
    [self presentViewController:alert animated:YES completion:nil];
    
    alert = nil;
    
    /*
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:msg
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
     */
}
- (IBAction)btnPaxNumPad:(id)sender {
    UIButton *button = (UIButton *) sender;
    
    NSString *textChecking;
    
    if ([button.titleLabel.text isEqualToString:@"C"]) {
        
        self.textPaxEntry.text = @"";
    }
    else
    {
        textChecking = [self.textPaxEntry.text
                      stringByAppendingString:button.titleLabel.text];
        //self.textPaxEntry.text = [self.textPaxEntry.text
                                //stringByAppendingString:button.titleLabel.text];
        
        if (textChecking.length > 3) {
            return;
        }
        else
        {
            self.textPaxEntry.text = textChecking;
        }
        
    }
    
    if ([self.textPaxEntry.text isEqualToString:@"0"] && [self.textPaxEntry.text length] == 1 ) {
        self.textPaxEntry.text = @"";
    }
    
}
@end
