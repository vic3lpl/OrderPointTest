//
//  TerminalViewController.h
//  IpadOrder
//
//  Created by IRS on 1/6/16.
//  Copyright (c) 2016 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseDetailViewController.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "SelectCatTableViewController.h"

@interface TerminalViewController : BaseDetailViewController<UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate,SelectCatDelegate>
@property (weak, nonatomic) IBOutlet UISwitch *swEnable;
- (IBAction)swChangeValue:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *labelDevice1;
@property (weak, nonatomic) IBOutlet UILabel *labelIPAddress;
@property (weak, nonatomic) IBOutlet UITableView *tableDeviceList;
//- (IBAction)btnDelete:(id)sender;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentWorkMode;
- (IBAction)changeWorkMode:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *textServerIP;
@property (weak, nonatomic) IBOutlet UITextField *textTerminalCode;

//@property (weak, nonatomic) IBOutlet UIProgressView *progress;
//- (IBAction)btnSendData:(id)sender;
@property (weak, nonatomic) IBOutlet UIView *viewTerminal;
- (IBAction)btnClickSyncServer:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *btnSyncServer;
@property (weak, nonatomic) IBOutlet UIView *viewTerminalBg;
@property (strong, nonatomic) NSString *dataStatus;
@property (weak, nonatomic) IBOutlet UILabel *labelTerminalQtyCode;
@property (weak, nonatomic) IBOutlet UITextField *textTerminalQty;
//@property (strong, nonatomic) UIPopoverController *popOver;
@property (weak, nonatomic) IBOutlet UIView *viewTerminalSndBg;
@property (weak, nonatomic) IBOutlet UILabel *labelServerDeviceIP;


@end
