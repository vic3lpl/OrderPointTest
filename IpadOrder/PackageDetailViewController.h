//
//  PackageDetailViewController.h
//  IpadOrder
//
//  Created by IRS on 08/03/2017.
//  Copyright © 2017 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PackageDetailViewDelegate <NSObject>

@required
-(void)passBackPackageDetailSettingArray:(NSMutableArray *)packageArray;

@end

@interface PackageDetailViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *textPackageItemName;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentServiceType;
@property (weak, nonatomic) IBOutlet UITableView *tableIViewItemMast;
- (IBAction)segmentServiceTypeChangeValue:(id)sender;
@property (strong,nonatomic) NSString *packageItemCode;
@property (strong,nonatomic) NSString *packageItemDesc;

@property (weak, nonatomic) IBOutlet UITextField *textSearchItem;
@property (weak, nonatomic) IBOutlet UITableView *tableViewPackageDetail;
@property (retain, nonatomic)NSArray *packageItemDetailArray;

- (IBAction)btnCancelPackageItemDetailClick:(id)sender;
@property (nonatomic,weak) id<PackageDetailViewDelegate>delegate;
- (IBAction)btnOKPackageItemDetailClick:(id)sender;

@end
