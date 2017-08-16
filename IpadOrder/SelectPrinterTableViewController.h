//
//  SelectPrinterTableViewController.h
//  IpadOrder
//
//  Created by IRS on 10/21/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol SelectPrinterDelegate <NSObject>
@required
-(void)getSelectedPrinter:(NSString *)type field2:(NSString *)mode field3:(NSString *)brand;
@end
@interface SelectPrinterTableViewController : UITableViewController
@property (nonatomic,weak) id<SelectPrinterDelegate>delegate;
@end
