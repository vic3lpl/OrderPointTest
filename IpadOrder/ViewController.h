//
//  ViewController.h
//  IpadOrder
//
//  Created by IRS on 6/29/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NumericKeypadDelegate.h"
#import "ActivateDeviceViewController.h"
#import "AppUtility.h"
#import "PosCommand.h"
#import "TscCommand.h"
#import "ImageTranster.h"
#import "XYSDK.h"
#import "GCDAsyncSocket.h"

@interface ViewController : UIViewController <NumericKeypadDelegate,ActivateDeviceDelegate,POS_APIDelegate,XYWIFIManagerDelegate,GCDAsyncSocketDelegate>

- (IBAction)userBtn:(id)sender;
@property (strong, nonatomic) IBOutlet UITextField *textUserId;
@property (strong, nonatomic) IBOutlet UITextField *textPassword;

//@property (weak, nonatomic) IBOutlet UIView *userTableView;
- (IBAction)testSplitView:(id)sender;
- (IBAction)loginBtn:(id)sender;
//- (IBAction)btntest:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *btntestoutlet;
@property(strong,nonatomic)NSString *terminalName;

@property (weak, nonatomic) IBOutlet UIView *testView;
- (IBAction)popOverRegisterView:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *btnRegistration;
@property (weak, nonatomic) IBOutlet UILabel *labelExpdate;
@property (weak, nonatomic) IBOutlet UILabel *labelExpDate2;
@property (weak, nonatomic) IBOutlet UILabel *labelTitle;
@property (nonatomic, strong) XYWIFIManager *wifiManager;
@property (nonatomic, strong) NSThread *thread;
//@property (weak, nonatomic) IBOutlet UIImageView *ggg;

@end
