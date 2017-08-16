//
//  TerminalListTableViewCell.h
//  IpadOrder
//
//  Created by IRS on 1/8/16.
//  Copyright (c) 2016 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TerminalListTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *labelDeviceName;
@property (weak, nonatomic) IBOutlet UIButton *btnUnPair;
@property (weak, nonatomic) IBOutlet UITextField *textTermialID;
@property (weak, nonatomic) IBOutlet UILabel *labelConnected;
@property (weak, nonatomic) IBOutlet UIButton *btnAddTerminal;
@property (weak, nonatomic) IBOutlet UILabel *labelNo;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentAddRemoveTerminal;

@end
