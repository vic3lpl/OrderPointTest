//
//  PrintBillSelectionViewController.h
//  IpadOrder
//
//  Created by IRS on 04/05/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BillListingViewController.h"

@protocol PrintBillDelegate <NSObject>

@required
-(void)printSelectedSalesOrderWithSalesOrderNo:(NSString *)salesDocNo BillStatus:(NSString *)billStatus;

@end

@interface PrintBillSelectionViewController : UIViewController<BillListingDelegate>
@property (nonatomic,weak)id<PrintBillDelegate>delegate;
- (IBAction)dismissPrintBillSelectionView:(id)sender;
- (IBAction)clickPrintCurrentBill:(id)sender;
- (IBAction)clickBtnFindBill:(id)sender;
@end
