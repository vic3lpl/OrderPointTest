//
//  OrderCustomerInfoViewController.h
//  IpadOrder
//
//  Created by IRS on 05/12/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OrderCustomerInfoDelegate <NSObject>

@required
-(void)passBackCustomerInfoWithCustName:(NSString *)custName CustAdd1:(NSString *)custAdd1 CustAdd2:(NSString *)custAdd2 CustAdd3:(NSString *)custAdd3 TelNo:(NSString *)custTelNo CustGstNo:(NSString *)custGstNo;

@end

@interface OrderCustomerInfoViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextField *textOrderCustomerName;
@property (weak, nonatomic) IBOutlet UITextField *textOrderCustomerAddress1;
@property (weak, nonatomic) IBOutlet UITextField *textOrderCustomerTelNo;

@property (weak, nonatomic) IBOutlet UITextField *textOrderCustomerAddress2;

@property(nonatomic, weak)id<OrderCustomerInfoDelegate>delegate;
- (IBAction)btnCancelOrderCustomer:(id)sender;
- (IBAction)btnSaveOrderCustomer:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *textOrderCustomerGstNo;
@property (weak, nonatomic) IBOutlet UITextField *textOrderCustomerAddress3;
@property (nonatomic, copy) NSMutableDictionary *custDict;


//@property (weak, nonatomic) IBOutlet UITextField *textOrderCustomerGstNo;

@end
