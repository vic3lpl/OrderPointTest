//
//  OrderDetailViewController.h
//  IpadOrder
//
//  Created by IRS on 8/6/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NumericKeypadDelegate.h"
#import "OrderAddCondimentViewController.h"

@protocol OrderDetailDelegate <NSObject>

@required
-(void)passSalesDataBack:(NSMutableArray *)dataBack dataStatus:(NSString *)flag tablePosition:(int)position ArrayIndex:(int)arrayIndex;
-(void)editAddConfimentViewWithPosition:(NSUInteger)position ShowAll:(NSString *)showAll;

-(void)editPackageItemWithPosition:(NSUInteger)position;
@end

@interface OrderDetailViewController : UIViewController<NumericKeypadDelegate,UITextFieldDelegate,OrderAddCondimentDelegate>
- (IBAction)btnCancel:(id)sender;
@property (strong, nonatomic) IBOutlet NumericKeypadTextField *textItemPrice;
@property (strong, nonatomic) IBOutlet NumericKeypadTextField *textItemQty;
@property (strong, nonatomic) IBOutlet UITextField *textSubTotal;
@property (strong, nonatomic) IBOutlet UITextField *textTotal;
@property (strong, nonatomic) IBOutlet UILabel *labelItemName;

@property (strong, nonatomic) IBOutlet UITextField *textTotalTax;
@property (strong, nonatomic) IBOutlet UITextView *textRemark;
@property (strong, nonatomic) IBOutlet UISegmentedControl *discountSegment;
- (IBAction)discountType:(id)sender;
@property (strong, nonatomic) IBOutlet UITextField *textDiscountAmt;
@property (strong, nonatomic) IBOutlet UIButton *btnAdd;

@property (strong, nonatomic) IBOutlet NumericKeypadTextField *textDiscount;

@property long im_ItemNo;
@property long position;
@property NSString *dataStatus;
@property NSString *tbName;
@property NSString *odDineStatus;

//- (IBAction)btnPlus:(id)sender;
//- (IBAction)btnMinus:(id)sender;
//- (IBAction)addBackSaveData:(id)sender;

@property(weak,nonatomic)id<OrderDetailDelegate>delegate;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentTakeAwayYN;
- (IBAction)clickSegmentTakeAwayYN:(id)sender;
- (IBAction)clickSegmentQty:(id)sender;
@property (weak, nonatomic) IBOutlet UISegmentedControl *SegmentQtyBtn;
- (IBAction)btnEditCondiment:(id)sender;


@end
