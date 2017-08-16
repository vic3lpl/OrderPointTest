//
//  SelectTablePlanViewController.h
//  IpadOrder
//
//  Created by IRS on 7/15/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <YAScrollSegmentControl/YAScrollSegmentControl.h>
#import "MultiSOViewController.h"
#import "TransferTableFromViewController.h"
#import "OptionSelectTableViewController.h"
#import "TransferTableToViewController.h"
#import "AppUtility.h"
#import "PosCommand.h"
#import "TscCommand.h"
#import "ImageTranster.h"
#import "XYSDK.h"
#import "PaxEntryViewController.h"
#import "EditBillViewController.h"

@interface SelectTablePlanViewController : UIViewController <UIActionSheetDelegate,MultiSODelegate,UIScrollViewDelegate,TransferTableFromDelegate,OptionSelectTableDelegate,TransferTableToDelegate,POS_APIDelegate,XYWIFIManagerDelegate,PaxEntryDelegate,EditBillDelegate>
{
    //UIScrollView *scrollTbSection;
    NSMutableArray *viewControllers;
    
}
@property (weak, nonatomic) IBOutlet UITableView *tablePlanTableView;
- (IBAction)goToSetting:(id)sender;
- (IBAction)gotoTableDesign:(id)sender;
//- (IBAction)testBtn:(id)sender;
@property (strong, nonatomic) IBOutlet UIView *tablePlanView;
@property (strong, nonatomic) IBOutlet YAScrollSegmentControl *segmentSection;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollTbSection;
//@property (nonatomic, retain) NSMutableArray *viewControllers;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollViewTb;
@property (weak, nonatomic) IBOutlet UIButton *btnOption;
@property (weak, nonatomic) IBOutlet UIView *fakeView; //for option pop up to display
@property (nonatomic, strong) XYWIFIManager *wifiManager;


//- (IBAction)secondSpliView:(id)sender;

@end
