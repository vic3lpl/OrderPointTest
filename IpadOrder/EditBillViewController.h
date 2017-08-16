//
//  EditBillViewController.h
//  IpadOrder
//
//  Created by IRS on 30/08/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppUtility.h"

@protocol EditBillDelegate <NSObject>

@optional
-(void)editBillOnOrderScreenWithTableName:(NSString *)tableName TableNo:(NSInteger)tableNo DineType:(NSString *)dineType OverrideTableSVC:(NSString *)overrideTableSVC PaxNo:(NSString *)paxNo CSDocNo:(NSString *)csDocNo TpServicePercent:(NSString *)tpServicePercent;

-(void)orderingEditBillOnOrderScreenWithTableName:(NSString *)tableName TableNo:(NSInteger)tableNo DineType:(NSString *)dineType OverrideTableSVC:(NSString *)overrideTableSVC PaxNo:(NSString *)paxNo CSDocNo:(NSString *)csDocNo TpServicePercent:(NSString *)tpServicePercent;

@end

@interface EditBillViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableEditBillListing;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBarEditBill;
- (IBAction)btnCancelEditBillSelected:(id)sender;
@property(nonatomic,weak)id<EditBillDelegate>delegate;
@end
