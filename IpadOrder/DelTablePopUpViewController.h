//
//  DelTablePopUpViewController.h
//  IpadOrder
//
//  Created by IRS on 7/24/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NumericKeypadDelegate.h"

@protocol DeleteTableDelegate <NSObject>
@required
-(void)delTableName:(NSString *)delName UpdatePercent:(NSString *)updatePercent Overide:(int)overide ImageName:(NSString *)imgName DineType:(int)dineType;

-(void)showNewImageWithImgName:(NSString *)imgName Rotate:(float)rotate TableName:(NSString *)tableName;

@end

@interface DelTablePopUpViewController : UIViewController<NumericKeypadDelegate,UITextFieldDelegate>

- (IBAction)deleteTable:(id)sender;

@property(nonatomic,weak)id<DeleteTableDelegate>delegate;
- (IBAction)btnChangeTableName:(id)sender;
@property (strong, nonatomic) IBOutlet UITextField *textTableName;
@property NSString *tbName;
@property NSString *tbPercent;
@property NSString *tbSelectedImgName;
@property float tbAngle;
@property int tbOveride;
@property int tbDineType;
//@property (weak, nonatomic) IBOutlet UITextField *textServiceCharge;
@property (weak, nonatomic) IBOutlet NumericKeypadTextField *textServiceCharge;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentEditOverideSvg;
- (IBAction)clickSegmentEditOverideSvg:(id)sender;
//@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentSelectImage;
//- (IBAction)clickSegmentSelectImage:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *btnRotate;
@property (weak, nonatomic) IBOutlet UIButton *btnUpdateTable1;
@property (weak, nonatomic) IBOutlet UIButton *btnUpdateTable2;
@property (weak, nonatomic) IBOutlet UIButton *btnUpdateTable3;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentTableServeType;
- (IBAction)clickSegmentEditServeType:(id)sender;

@end
