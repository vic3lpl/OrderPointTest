//
//  BackupSqliteViewController.h
//  IpadOrder
//
//  Created by IRS on 9/7/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MBProgressHUD.h>

@class DBRestClient;
@interface BackupSqliteViewController : UIViewController<MBProgressHUDDelegate>
{
    MBProgressHUD *HUD;
    DBRestClient* restClient;
}
@property (strong, nonatomic) IBOutlet UIButton *btnBackupDropBox;
-(IBAction)didPressLink;
@property (strong, nonatomic) IBOutlet UIButton *btnRestoreDropBox;
@property (strong, nonatomic) IBOutlet UIButton *btnLinkDropBox;
@property (strong, nonatomic) IBOutlet UIView *viewBackup;


@end
