//
//  OptionSelectTableViewController.h
//  IpadOrder
//
//  Created by IRS on 04/04/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppUtility.h"
#import <QuartzCore/QuartzCore.h>
#import "PosCommand.h"
#import "TscCommand.h"
#import "ImageTranster.h"
#import "XYSDK.h"


@protocol OptionSelectTableDelegate <NSObject>

@optional
-(void)selectTableFindBillView;
-(void)kioskFindBillView;
-(void)selectTableEditedBillView;
-(void)kioskEditBillView;
-(void)kiosOpenMoreView;
@end

@interface OptionSelectTableViewController : UIViewController<POS_APIDelegate,XYWIFIManagerDelegate>
@property (weak, nonatomic) IBOutlet UIButton *btnOpenDrawer;
//@property NSString *portName;
@property (weak, nonatomic) IBOutlet UIButton *btnFindBill;
@property(nonatomic,weak)id<OptionSelectTableDelegate>delegate;
@property (weak, nonatomic) IBOutlet UIButton *btnUnlockDock;
@property (weak, nonatomic) IBOutlet UIView *viewShadowForOption;
@property (nonatomic, strong) XYWIFIManager *wifiManager;
@property (weak, nonatomic) IBOutlet UIButton *btnEditBill;
@property (weak, nonatomic) IBOutlet UIButton *btnOptionMore;

//@property (weak, nonatomic) NSString *optionViewFlag;
@end
