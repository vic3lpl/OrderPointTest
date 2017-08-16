//
//  TransferTableFromViewController.h
//  IpadOrder
//
//  Created by IRS on 09/05/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TransferTableFromDelegate <NSObject>

@required
-(void)askSelectedTableViewRefreshTablePlan;
-(void)selectTableAtSelectTableViewWithFromDocNo:(NSString *)fromDocNo FromTableName:(NSString *)fromTableName SelectedOption:(NSString *)selectedOption TransferType:(NSString *)transferType FromTableDineType:(NSString *)fromTableDineType;
@end

@interface TransferTableFromViewController : UIViewController <UITableViewDataSource,UITableViewDelegate>
- (IBAction)closeTrandferTableFromView:(id)sender;
@property (weak, nonatomic) IBOutlet UITableView *tableViewSOToTransfer;
@property (weak, nonatomic) IBOutlet UILabel *labelTitleRemark;
@property (strong, nonatomic) IBOutlet NSString *selectedMultiTbName;
@property(weak,nonatomic)id<TransferTableFromDelegate>delegate;
@property(nonatomic,strong)NSString *transferFromSelectOption;
@end
