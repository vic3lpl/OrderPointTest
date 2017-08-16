//
//  MultiSOViewController.h
//  IpadOrder
//
//  Created by IRS on 8/28/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MultiSODelegate <NSObject>
@optional
-(void)passBackMultiSelectedSONo:(NSString *)soNo TableName:(NSString *)tableName TableNo:(NSInteger)tableNo PaxNo:(NSString *)paxNo;


@end

@interface MultiSOViewController : UIViewController <UITableViewDataSource,UITableViewDelegate>
- (IBAction)btnNewOrder:(id)sender;


@property  int tbSelectNo;
@property  (strong, nonatomic) NSString *tbSelecName;
@property (strong, nonatomic) IBOutlet UITableView *soTableView;
@property(nonatomic, weak)id<MultiSODelegate>delegate;
//@property  (strong, nonatomic) NSString *tbDineStatus;
@end