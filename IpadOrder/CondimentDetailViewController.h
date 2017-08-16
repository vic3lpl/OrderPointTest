//
//  CondimentDetailViewController.h
//  IpadOrder
//
//  Created by IRS on 03/09/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SelectCatTableViewController.h"
#import "NumericKeypadDelegate.h"

@protocol CondimentDetailViewDelegate <NSObject>

@required
-(void)passbackCondimentDetailAray:(NSMutableDictionary *)dict Status:(NSString *)status;

@end

@interface CondimentDetailViewController : UIViewController<SelectCatDelegate,UITextFieldDelegate,NumericKeypadDelegate>
@property (weak, nonatomic) IBOutlet UITextField *textCondimentCode;
@property (weak, nonatomic) IBOutlet UITextField *textCondimentDesc;
//@property (weak, nonatomic) IBOutlet NumericKeypadTextField *textCondimentPrice;
@property (weak, nonatomic) IBOutlet NumericKeypadTextField *textCondimentPrice;

@property (weak, nonatomic) IBOutlet UITextField *textCondimentGroup;
@property(weak,nonatomic)NSString *cdCode;
@property(weak,nonatomic)NSString *cdAction;
@property(weak,nonatomic)NSString *condimentHdrCode;

@property(weak,nonatomic)NSString *cdDescription;
@property(weak,nonatomic)NSString *cdPrice;

- (IBAction)btnOKCondimentDtlClick:(id)sender;
- (IBAction)btnCancelCondimentDtlClick:(id)sender;
@property (nonatomic,weak) id<CondimentDetailViewDelegate>delegate;


@end
