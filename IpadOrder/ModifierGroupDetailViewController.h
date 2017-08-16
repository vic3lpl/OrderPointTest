//
//  ModifierGroupDetailViewController.h
//  IpadOrder
//
//  Created by IRS on 27/02/2017.
//  Copyright © 2017 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NumericKeypadDelegate.h"

@interface ModifierGroupDetailViewController : UIViewController <UITableViewDataSource,UITableViewDelegate, UITextFieldDelegate, NumericKeypadDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableViewItemMast;
@property (weak, nonatomic) IBOutlet UITableView *tableViewModifierDetail;
@property (weak, nonatomic) IBOutlet UITextField *textModifierItemMastSearch;
@property (weak, nonatomic) IBOutlet UITextField *textMGCode;
@property (weak, nonatomic) IBOutlet UITextField *textMGDesc;
//@property (weak, nonatomic) IBOutlet NumericKeypadTextField *textMGMin;
@property (weak, nonatomic) IBOutlet NumericKeypadTextField *textMGMin;

@property (strong, nonatomic)NSString *mGHCode;
@property (strong, nonatomic)NSString *mGHUserAction;
@end
