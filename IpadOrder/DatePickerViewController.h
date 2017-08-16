//
//  DatePickerViewController.h
//  IpadOrder
//
//  Created by IRS on 9/10/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol DatePickerDelegate<NSObject>
@required
-(void)getDatePickerDateValue:(NSString *)dateValue returnTextName:(NSString *)textName;
@end
@interface DatePickerViewController : UIViewController

@property(nonatomic,weak)id<DatePickerDelegate>delegate;
- (IBAction)btnSelectInvoiceDate:(id)sender;
@property (strong, nonatomic) IBOutlet UIDatePicker *dateInv;
@property NSString *textType;
@end
