//
//  ItemMastEditViewController.h
//  IpadOrder
//
//  Created by IRS on 7/3/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SelectCatTableViewController.h"
#import "NumericKeypadDelegate.h"
#import "PackageDetailViewController.h"

@interface ItemMastEditViewController : UIViewController<UITextFieldDelegate,SelectCatDelegate,NumericKeypadDelegate,UITableViewDataSource,UITableViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIPopoverPresentationControllerDelegate,PackageDetailViewDelegate>


@property (weak, nonatomic) IBOutlet UITextField *textItemCode;

@property (weak, nonatomic) IBOutlet UITextField *textItemDesc;
@property (weak, nonatomic) IBOutlet UITextField *textItemTax;

@property (weak, nonatomic) IBOutlet UISwitch *switchItemHot;
@property (weak, nonatomic) IBOutlet UITextField *textServiceTax;
@property (weak, nonatomic) IBOutlet UITextField *textPrinter;
//- (IBAction)btnAddPrinter:(id)sender;

@property (weak, nonatomic) IBOutlet UITableView *tableViewPrinter;

@property (weak, nonatomic) IBOutlet NumericKeypadTextField *textItemPrice;

@property (weak, nonatomic) IBOutlet UITextField *textCategory;
@property (weak, nonatomic) IBOutlet UITextField *textItemDesc2;

@property(nonatomic,copy)NSString *itemNo;
@property(nonatomic,copy)NSString *userAction;
@property (weak, nonatomic) IBOutlet UIImageView *imgItemMast;
//- (IBAction)btnCamera:(id)sender;
//@property (weak, nonatomic) IBOutlet UIButton *buttonCamera;
@property (weak, nonatomic) IBOutlet UIView *viewBgItemMastEdit;
@property (weak, nonatomic) IBOutlet UITableView *tableViewCondimentGroup;
@property (weak, nonatomic) IBOutlet UISwitch *switchPackageItem;
- (IBAction)switchPackageItemSelect:(id)sender;
- (IBAction)btnOpenPackageItem:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *buttonOpenPackageItem;

@end
