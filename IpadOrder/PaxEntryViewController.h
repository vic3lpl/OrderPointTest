//
//  PaxEntryViewController.h
//  IpadOrder
//
//  Created by IRS on 26/08/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NumericKeypadDelegate.h"

@protocol PaxEntryDelegate <NSObject>

@optional
-(void)afterKeyInPaxNumberWithPaxNo:(NSString *)paxNo;
-(void)editKeyInPaxNumberWithPaxNo:(NSString *)paxNo;

@end
@interface PaxEntryViewController : UIViewController<NumericKeypadDelegate,UITextFieldDelegate>
- (IBAction)btnCancelPaxEntry:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *textPaxEntry;

@property (weak, nonatomic) IBOutlet UILabel *labelPaxTableName;
- (IBAction)btnConfirmPaxEntry:(id)sender;
@property(nonatomic,copy) NSString *requirePaxEntryView;
@property(weak,nonatomic)id<PaxEntryDelegate>delegate;

- (IBAction)btnPaxNumPad:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *textIcon;


@end
