//
//  SelectCatTableViewController.h
//  IpadOrder
//
//  Created by IRS on 7/9/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SelectCatDelegate <NSObject>

@required
-(void)getSelectedCategory:(NSString *)field1 field2:(NSString *)field2 field3:(NSString *)field3 filterType:(NSString *)filterType;

@end
@interface SelectCatTableViewController : UITableViewController

@property (nonatomic,weak) id<SelectCatDelegate>delegate;
@property(nonatomic,copy) NSString *filterType;
@end
