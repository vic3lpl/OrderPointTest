//
//  SelectModifierItemViewController.h
//  IpadOrder
//
//  Created by IRS on 10/03/2017.
//  Copyright © 2017 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OrderAddCondimentViewController.h"

@protocol SelectModifierItemDelegate <NSObject>
@required

-(void)finalModifierItemSelectionWithModifierArray:(NSMutableArray *)mArray WithCondiment:(NSString *)withCondiment ItemArray:(NSMutableArray *)itemArray;

-(void)finalEditedModifierItemSelectionWithModifierArray:(NSMutableArray *)mArray WithCondiment:(NSString *)withCondiment ItemArray:(NSMutableArray *)itemArray;

@end

@interface SelectModifierItemViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableViewPackageItem;
@property (strong, nonatomic) NSString *modifierCode;
@property (nonatomic,weak) id<SelectModifierItemDelegate>delegate;
@property (retain, nonatomic)NSArray *modifierAddedCondimentArray;
@property (strong, nonatomic)NSString *orderPackageSelectedIndex;
@end
