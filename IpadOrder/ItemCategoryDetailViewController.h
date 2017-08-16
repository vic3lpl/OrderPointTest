//
//  ItemCategoryDetailViewController.h
//  IpadOrder
//
//  Created by IRS on 08/03/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ItemCategoryDetailDelegate <NSObject>
@required
-(void)resultFromCategoryDetail;
@end

@interface ItemCategoryDetailViewController : UIViewController <UIImagePickerControllerDelegate,UINavigationControllerDelegate,UITextFieldDelegate>
//@property (weak, nonatomic) IBOutlet UITextField *imgCategory;
@property (weak, nonatomic) IBOutlet UIButton *btnSaveCategory;
- (IBAction)btnCancelCategory:(id)sender;
@property(nonatomic,weak)NSString *category;
@property(nonatomic,weak)NSString *catStatus;
@property (weak, nonatomic) IBOutlet UITextField *textCategory;
@property (nonatomic,weak) id<ItemCategoryDetailDelegate>delegate;
@property (weak, nonatomic) IBOutlet UIImageView *imgCategory;
@property (weak, nonatomic) IBOutlet UITextField *textTextCategoryDesc;


@end
