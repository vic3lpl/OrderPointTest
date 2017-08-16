//
//  InsertTablePopUpViewController.h
//  IpadOrder
//
//  Created by IRS on 7/23/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NumericKeypadDelegate.h"

@protocol InsertTableDelegate <NSObject>

@required
-(void)saveTableName:(NSString *)insName Percent:(NSString *)percent Overide:(int)overide ImgName:(NSString *)imgName DineType:(int)dineType;

@end

@interface InsertTablePopUpViewController : UIViewController <NumericKeypadDelegate,UITextFieldDelegate,UIPopoverControllerDelegate,UIPopoverPresentationControllerDelegate>

@property (nonatomic,weak) id<InsertTableDelegate>delegate;
- (IBAction)btnSaveTableClick:(id)sender;
@property (strong, nonatomic) IBOutlet UITextField *tbName;
@property (strong, nonatomic) IBOutlet NumericKeypadTextField *textPercent;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentOveride;

- (IBAction)segmentOverideClick:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *btnTable1;
@property (weak, nonatomic) IBOutlet UIButton *btnTable2;
@property (weak, nonatomic) IBOutlet UIButton *btnTable3;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentDineType;
- (IBAction)segmentDineTypeClick:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *btnCancelAddTable;



@end
