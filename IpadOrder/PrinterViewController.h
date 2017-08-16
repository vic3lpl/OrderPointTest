//
//  PrinterViewController.h
//  IpadOrder
//
//  Created by IRS on 7/7/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseDetailViewController.h"
#import "SelectPrinterTableViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "AppUtility.h"
#import "PosCommand.h"
#import "TscCommand.h"
#import "ImageTranster.h"
#import "XYSDK.h"
//#import <POS_API/POS_API.h>


@interface PrinterViewController : BaseDetailViewController<UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate,SelectPrinterDelegate,CBCentralManagerDelegate,POS_APIDelegate,XYWIFIManagerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *printerListView;
@property (weak, nonatomic) IBOutlet UITextField *textIPAdd;
@property (weak, nonatomic) IBOutlet UITextField *textModel;

@property (weak, nonatomic) IBOutlet UITableView *savedPrinterTableView;
- (IBAction)btnPrintSample:(id)sender;

- (IBAction)btnRemovePrinter:(id)sender;
@property (strong, nonatomic) IBOutlet UITextField *textPrinterType;
- (IBAction)btnAddReceiptPrinter:(id)sender;
- (IBAction)btnAddKitchenPrinter:(id)sender;
@property (weak, nonatomic) IBOutlet UIView *viewPrinterBg;
//- (IBAction)btnTestPrint:(id)sender;
//- (IBAction)btnXprinterPrint:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *btnRemovePrinter;
@property (weak, nonatomic) IBOutlet UIButton *btnAddKitchenPrinter;

- (IBAction)textFlyTech:(id)sender;



@end
