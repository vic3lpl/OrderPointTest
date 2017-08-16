//
//  DragTablePlanViewController.h
//  IpadOrder
//
//  Created by IRS on 7/20/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InsertTablePopUpViewController.h"
#import "DelTablePopUpViewController.h"
#import <YAScrollSegmentControl/YAScrollSegmentControl.h>
//#import "TbSectionViewController.h"

@interface DragTablePlanViewController : UIViewController<InsertTableDelegate,DeleteTableDelegate,UIGestureRecognizerDelegate,UIScrollViewDelegate,UIPopoverControllerDelegate,UIPopoverPresentationControllerDelegate>
{
    NSMutableArray *viewControllers;
}

@property (weak, nonatomic) IBOutlet UIView *tablePlanFloor;

- (IBAction)delete:(id)sender;
//@property (strong, nonatomic) IBOutlet UITextField *tableName;
@property (strong, nonatomic) IBOutlet YAScrollSegmentControl *scrollSegmentView;

//@property (strong, nonatomic) IBOutlet UIButton *btnAddTable;
- (IBAction)backTablePlan:(id)sender;

//- (IBAction)btnSaveTablePlan:(id)sender;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollDesignBtnTbSection;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollDesignViewDragTbPlan;


@end
