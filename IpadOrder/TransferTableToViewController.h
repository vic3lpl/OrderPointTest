//
//  TransferTableToViewController.h
//  IpadOrder
//
//  Created by IRS on 09/05/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PosCommand.h"
#import "TscCommand.h"
#import "ImageTranster.h"
#import "XYSDK.h"

@protocol TransferTableToDelegate <NSObject>
@optional
-(void)backOrCloseTransferToView;

-(void)combineTwoTableWithFromSalesOrder:(NSString *)fromSalesOrder ToSalesOrder:(NSString *)toSalesOrder;

@end
@interface TransferTableToViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,XYWIFIManagerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableViewTransferToTableList;
@property (weak, nonatomic) IBOutlet UILabel *labelTransferToTitle;
@property (nonatomic, strong)NSString *fromTableName;
@property (nonatomic, strong)NSString *fromDocNo;
@property (nonatomic, strong)NSString *toTableName;
@property (nonatomic, strong)NSString *transferType;
@property(nonatomic,weak)id<TransferTableToDelegate>delegate;
@property (nonatomic, strong) XYWIFIManager *wifiManager;
@property (nonatomic, strong)NSString *selectedOption;
@property (nonatomic, strong)NSString *fromTableDineType;

@end
