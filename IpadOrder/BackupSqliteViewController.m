//
//  BackupSqliteViewController.m
//  IpadOrder
//
//  Created by IRS on 9/7/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "BackupSqliteViewController.h"
#import <DropboxSDK/DropboxSDK.h>
#import "LibraryAPI.h"
#import "AppDelegate.h"
#import <MBProgressHUD.h>
#import <KVNProgress/KVNProgress.h>
#import <FMDB.h>


@interface BackupSqliteViewController ()<DBRestClientDelegate>
{
    NSString *dbPath;
    NSMutableArray *dropboxFileArray;
    NSString *alertType;
    CGFloat myProgress;
    NSMutableArray *dropboxImageArray;
    int uploadSuccessCount;
    int downloadSuccessCount;
    long totalFileUpload;
    long totalFileDownload;
    NSString *downloadFileSuccess;
    NSString *restoreFileType;
    NSMutableArray *readAppRegistrationArray;
    
    NSString *databaseID;
    //NSString *uploadType;
}
@property (nonatomic) KVNProgressConfiguration *basicConfiguration;
//@property(nonatomic,strong) DBRestClient *restClient;
@end

@implementation BackupSqliteViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    dropboxFileArray  = [[NSMutableArray alloc]init];
    dropboxImageArray = [[NSMutableArray alloc]init];
    readAppRegistrationArray = [[NSMutableArray alloc]init];
    
    dbPath = [[LibraryAPI sharedInstance] getDbPath];
    downloadFileSuccess = @"True";
    //kvprogress
    self.basicConfiguration = [KVNProgressConfiguration defaultConfiguration];
    
    UIBarButtonItem *btnBackBackupDropBox = [[UIBarButtonItem alloc]initWithTitle:@"< Back" style:UIBarButtonItemStylePlain target:self action:@selector(btnBackBackupDropBox:)];
    self.navigationItem.leftBarButtonItem = btnBackBackupDropBox;
    
    [self.btnBackupDropBox addTarget:self action:@selector(backupSqlite:) forControlEvents:UIControlEventTouchUpInside];
    [self.btnRestoreDropBox addTarget:self action:@selector(restoreSqlite:) forControlEvents:UIControlEventTouchUpInside];
    
    databaseID = [[NSUserDefaults standardUserDefaults] objectForKey:@"databaseID"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshView:) name:@"refreshView" object:nil];
    /*
    UIGraphicsBeginImageContext(self.view.frame.size);
    [[UIImage imageNamed:@"IO_Background1024"] drawInRect:self.view.bounds];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:image];
    */
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:255/255.0 green:86/255.0 blue:19/255.0 alpha:1.0];
    
    // navigation bar title text coloe
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    // navigatio bar button text color
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    [self setTitle:@"Backup & Restore"];
    
}

-(void)refreshView:(NSNotification *) notification
{
    //NSLog(@"Yeah");
    if ([[DBSession sharedSession] isLinked]) {
        [[self restClient]loadMetadata:@"/Images"];
        self.viewBackup.hidden = NO;
        [self.btnLinkDropBox setTitle:@"UNLINK" forState:UIControlStateNormal];
        [self.btnLinkDropBox setBackgroundImage:[UIImage imageNamed:@"RedBig"] forState:UIControlStateNormal];
    }

    
}

-(void)viewWillAppear:(BOOL)animated
{
    self.viewBackup.hidden = YES;
    if ([[DBSession sharedSession] isLinked]) {
        //[self.restClient loadMetadata:@"/"];
    }
    else
    {
        
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (DBRestClient*)restClient {
    if (restClient == nil) {
        restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        restClient.delegate = self;
    }
    return restClient;
}

-(IBAction)didPressLink{
    if (![[DBSession sharedSession] isLinked]) {
        
        [[DBSession sharedSession] linkFromController:self];
    } else {
        [[DBSession sharedSession] unlinkAll];
        
        alertType = @"non";
        /*
        [[[UIAlertView alloc]
           initWithTitle:@"Account Unlinked!" message:@"Your dropbox account has been unlinked"
           delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
          
         show];
         */
        [self.btnLinkDropBox setTitle:@"LINK" forState:UIControlStateNormal];
        self.viewBackup.hidden = YES;
        [self.btnLinkDropBox setBackgroundImage:[UIImage imageNamed:@"LBlueLong"] forState:UIControlStateNormal];
    }
    
    //NSString* title = [[DBSession sharedSession] isLinked] ? @"Unlink Dropbox" : @"Link Dropbox";
    //[self.btnLinkDropBox setTitle:title forState:UIControlStateNormal];
    
    //[self updateButtons];
}

- (void)updateButtons {
    
    self.btnBackupDropBox.enabled = [[DBSession sharedSession] isLinked];
    self.btnRestoreDropBox.enabled = [[DBSession sharedSession] isLinked];
}

#pragma mark - private method
-(void)btnBackBackupDropBox:(id)sender
{
    if ([[DBSession sharedSession] isLinked]) {
        
        [[DBSession sharedSession] unlinkAll];
    }
    dropboxFileArray = nil;
    dropboxImageArray = nil;
    [self.navigationController popViewControllerAnimated:NO];
    
}

-(void)backupSqlite:(id)sender
{
    
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Warning"
                                 message:@"Confirm to backup ?"
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* yesButton = [UIAlertAction
                                actionWithTitle:@"OK"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
                                    if (databaseID.length > 0) {
                                        [self writeCompanyName];
                                    }
                                    
                                    if ([[DBSession sharedSession] isLinked]) {
                                        uploadSuccessCount = 0;
                                        self.basicConfiguration.backgroundType = KVNProgressBackgroundTypeSolid;
                                        
                                        [KVNProgress showWithStatus:@"Loading..."];
                                        [self.restClient loadMetadata:@"/Images"];
                                        [self.restClient loadMetadata:@"/"];
                                        //[self.restClient loadMetadata:@"/Images"];
                                        
                                        
                                    }
                                    else
                                    {
                                        [self showAlertView:@"Please link dropBox" title:@"Warning"];
                                    }
                                }];
    
    UIAlertAction* noButton = [UIAlertAction
                               actionWithTitle:@"Cancel"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   //Handle no, thanks button
                               }];
    
    [alert addAction:yesButton];
    [alert addAction:noButton];
    
    [self presentViewController:alert animated:YES completion:nil];
    alert = nil;
    
}

-(void)restoreSqlite:(id)sender
{
    
    if ([[LibraryAPI sharedInstance]getUserRole] == 0) {
        [self showAlertView:@"You have no permission to restore" title:@"Warning"];
        return;
    }
    
    if ([[[LibraryAPI sharedInstance] getAppStatus] isEqualToString:@"DEMO"] || [[[LibraryAPI sharedInstance] getAppStatus]isEqualToString:@"REQ"]) {
        [self showAlertView:@"Please register your device first" title:@"Warning"];
        return;
    }
    else if([[[LibraryAPI sharedInstance] getAppStatus] length] == 0)
    {
        [self showAlertView:@"Please register your device first" title:@"Warning"];
        return;
    }

    downloadSuccessCount = 0;
    if ([[DBSession sharedSession] isLinked]) {
        alertType = @"restore";
        
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Warning"
                                     message:@"Are you want to restore from DropBox ?"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* yesButton = [UIAlertAction
                                    actionWithTitle:@"OK"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
                                        totalFileDownload = 0;
                                        if ([self readExistingDatabaseAppRegTable]) {
                                            self.basicConfiguration.backgroundType = KVNProgressBackgroundTypeSolid;
                                            downloadFileSuccess = @"True";
                                            [KVNProgress showWithStatus:@"Downloading Database..."];
                                            [self.restClient loadMetadata:@"/Images"];
                                            //[self restoreDBFromDropBox];
                                            [self restoreDatabaseIDFromDropBox];
                                            //[self restoreCompanyFromDropBox];
                                        }
                                        else
                                        {
                                            [self showAlertView:@"Cannot read registration data." title:@"Fail"];
                                        }
                                    }];
        
        UIAlertAction* noButton = [UIAlertAction
                                   actionWithTitle:@"Cancel"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {
                                       //Handle no, thanks button
                                   }];
        
        [alert addAction:yesButton];
        [alert addAction:noButton];
        
        [self presentViewController:alert animated:YES completion:nil];
        alert = nil;
        
        /*
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Alert"
                              message:@"Are you want to restore from dropBox ?"
                              delegate:self
                              cancelButtonTitle:@"OK"//0
                              otherButtonTitles:@"Cancel", nil];//1
        [alert show];
         */
    }
    else
    {
        [self showAlertView:@"Please link dropBox" title:@"Warning"];
    }
    
}

#pragma mark - upload restore to dropbox
-(void)uploadDbToDropBox
{
    
    NSString *filename = @"iorder.db";
    NSString *localDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *localPath = [localDir stringByAppendingPathComponent:filename];
    
    // Upload file to Dropbox
    NSString *destDir = @"/";
    [self.restClient uploadFile:filename toPath:destDir withParentRev:nil fromPath:localPath];
    
}

-(void)myProgressTask
{
    while (myProgress < 1.0f) {
        //myProgress += myProgress;
        HUD.progress = myProgress;
        usleep(50000);
    }
}

-(void)restoreDBFromDropBox
{
    restoreFileType = @"DataBase";
    NSString *localDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *databasePath = [localDir stringByAppendingPathComponent:@"iorder.db"];
    NSString *dropBoxPath = @"/iorder.db";
    [self.restClient loadFile:dropBoxPath intoPath:databasePath];
    //[self restoreImageFileFromDropBox];
}

-(void)restoreDatabaseIDFromDropBox
{
    restoreFileType = @"DbID";
    NSString *localDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *databasePath = [localDir stringByAppendingPathComponent:@"data2.txt"];
    NSString *dropBoxPath = @"/Images/data.txt";
    [self.restClient loadFile:dropBoxPath intoPath:databasePath];
    
}

-(void)deleteFileFromDropBox
{
    [self.restClient deletePath:@"/Images/data.txt"];
    [self.restClient deletePath:@"/iorder.db"];
}
// event for upload file
#pragma mark - dropbox delegate method

-(void)restClient:(DBRestClient *)client uploadProgress:(CGFloat)progress forFile:(NSString *)destPath from:(NSString *)srcPath
{
    myProgress = progress;
    
}
// event for upload file
- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath
              from:(NSString *)srcPath metadata:(DBMetadata *)metadata {
    uploadSuccessCount ++;
    //[self showAlertView:@"Backup Completed" title:@"Backup"];
    if (uploadSuccessCount == totalFileUpload) {
        
        [self showSuccessLoading];
        
    }

}

- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error {
    totalFileUpload--;
    [self showAlertView:@"One of the files fail to backup. Please try again" title:@"Fail Backup"];
    [KVNProgress dismiss];
    
}


//delete file
-(void)restClient:(DBRestClient *)client deletedPath:(NSString *)path
{
    NSLog(@"Success Delete at %@",path);
    
    if ([path isEqualToString:@"/Images/data.txt"]) {
        return;
    }
    [self uploadDbToDropBox];
}
-(void)restClient:(DBRestClient *)client deletePathFailedWithError:(NSError *)error
{
    NSDictionary* json = error.userInfo;
    
    if ([[json objectForKey:@"path"] isEqualToString:@"/Images/data.txt"]) {
        NSLog(@"Cannot Find data.txt");
        return;
    }
    
    [self showAlertView:[NSString stringWithFormat:@"%@",error] title:@"Fail Backup"];
    [KVNProgress dismiss];
}

-(void)restClient:(DBRestClient *)client loadProgress:(CGFloat)progress forFile:(NSString *)destPath
{
    myProgress = progress;
    
}
// download from dropbox
// event for download file
#pragma mark - dropbox download event

- (void)restClient:(DBRestClient *)client loadedFile:(NSString *)localPath
       contentType:(NSString *)contentType metadata:(DBMetadata *)metadata {
    
    downloadSuccessCount++;
    
    if ([restoreFileType isEqualToString:@"DataBase"]) {
        restoreFileType = @"Images";
        [self showSuccessRestoreDBLoading];
        
    }
    else if ([restoreFileType isEqualToString:@"DbID"]) {
        restoreFileType = @"DataBase";
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains
        (NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
        //make a file name to write the data to using the documents directory:
        NSString *fileName = [NSString stringWithFormat:@"%@/data2.txt",
                              documentsDirectory];
        
        NSString* content = [NSString stringWithContentsOfFile:fileName
                                                      encoding:NSUTF8StringEncoding
                                                         error:NULL];
        
        if ([databaseID isEqualToString:content]) {
            [self restoreDBFromDropBox];
        }
        else
        {
            [KVNProgress dismiss];
            [self showAlertView:@"Company Name Not Match" title:@"Warning"];
            [self removeDataTxtFileWithFileName:@"data2.txt"];
        }
        paths = nil;
        
        
    }
    else if([restoreFileType isEqualToString:@"Images"])
    {
        if (downloadSuccessCount == totalFileDownload) {
            if ([downloadFileSuccess isEqualToString:@"True"]) {
                //[self showSuccessLoading];
            }
            
        }
    }
    
    
}

- (void)restClient:(DBRestClient *)client loadFileFailedWithError:(NSError *)error {
    
    NSDictionary* json = error.userInfo;
    
    if ([[json objectForKey:@"path"] isEqualToString:@"/Images/data.txt"]) {
        NSLog(@"Cannot Find data.txt");
        restoreFileType = @"DataBase";
        [self restoreDBFromDropBox];
        return;
    }
    
    totalFileDownload--;
    if ([downloadFileSuccess isEqualToString:@"True"]) {
        downloadFileSuccess = @"False";
    }
    NSLog(@"There was an error loading the file: %@", error);
    
    if ([downloadFileSuccess isEqualToString:@"False" ]) {
        [self showAlertView:[NSString stringWithFormat:@"%@",@"One of the image file missing"] title:@"Fail Load File"];
        downloadFileSuccess = @"Other";
        [KVNProgress dismiss];
    }
    
    //json = nil;
}


- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
    NSMutableArray* filePaths = [NSMutableArray new];
    NSString *metadataPath;
    if (metadata.isDirectory) {
        metadataPath = metadata.path;
        NSLog(@"Folder '%@' contains:", metadata.path);
        //metaDatas = metadata;
        NSArray* validExtensions = [NSArray arrayWithObjects:@"db", @"sqlite",@"png",@"jpg", nil];
        
        if ([metadataPath isEqualToString:@"/"]) {
            for (DBMetadata* child in metadata.contents) {
                NSString* extension = [[child.path pathExtension] lowercaseString];
                if (!child.isDirectory && [validExtensions indexOfObject:extension] != NSNotFound) {
                    [filePaths addObject:child.path];
                    
                }
            }
        }
        else if ([metadataPath isEqualToString:@"/Images"])
        {
            for (DBMetadata* child in metadata.contents) {
                NSString* extension = [[child.path pathExtension] lowercaseString];
                if (!child.isDirectory && [validExtensions indexOfObject:extension] != NSNotFound)
                {
                    [filePaths addObject:[child.path substringFromIndex:8]];
                    
                }
            }
        }
        
    }
    
    if ([metadataPath isEqualToString:@"/"]) {
        dropboxFileArray = filePaths;
        
        if (dropboxFileArray.count > 0) {
            [self deleteFileFromDropBox];
        }
        else
        {
            [self uploadDbToDropBox];
        }
        [self startUploadImageFiles];
        
    }
    else
    {
        dropboxImageArray = filePaths;
        
        if (dropboxImageArray.count == 0) {
            [[self restClient] createFolder:@"/Images"];
        }
        
    }
    
    
    
    
}

#pragma mark - dropbox create folder event

-(void)restClient:(DBRestClient *)client createdFolder:(DBMetadata *)folder
{
    NSLog(@"Created Folder Path %@",folder.path);
    NSLog(@"Created Folder name %@",folder.filename);
    //[self startUploadImageFiles];
}

- (void)restClient:(DBRestClient*)client createFolderFailedWithError:(NSError*)error{
    //NSLog(@"%d",error.code);
    if (error.code == 403) {
        //checking file existing
    }
    else
    {
        [self showAlertView:@"Error" title:@"Error"];
    }
}

#pragma mark - alertView

-(void)showAlertView:(NSString *)msg title:(NSString *)title
{
    alertType = @"non";
    
    UIAlertController * alert = [[LibraryAPI sharedInstance] showAlertViewWithMsg:msg Title:title];
    
    [self presentViewController:alert animated:YES completion:nil];
    
    alert = nil;
    
    /*
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:msg
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
     */
}

/*
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    
    if ([alertType isEqualToString:@"restore"]) {
        totalFileDownload = 0;
        if (buttonIndex == 1) {
            //NSLog(@"Nothing");
        }
        else if (buttonIndex == 0)
        {
            if ([self readExistingDatabaseAppRegTable]) {
                self.basicConfiguration.backgroundType = KVNProgressBackgroundTypeSolid;
                downloadFileSuccess = @"True";
                [KVNProgress showWithStatus:@"Downloading Database..."];
                [self.restClient loadMetadata:@"/Images"];
                [self restoreDBFromDropBox];
            }
            else
            {
                [self showAlertView:@"Cannot read registration data." title:@"Fail"];
            }
            
        }
        
    }
    
    
    //[self.catTableView reloadData];
}
*/
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - upload and download image
-(void)startUploadImageFiles
{
    NSString *destDir = @"/Images";
    totalFileUpload = 0;
    NSString * resourcePath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    //NSString * documentsPath = [resourcePath stringByAppendingPathComponent:@"Documents"];
    NSError * error;
    NSArray * directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:resourcePath error:&error];
    NSString *localPath;
    totalFileUpload = directoryContents.count + 1;
    if (dropboxImageArray.count <= 0) {
        for (int i = 0; i < directoryContents.count; i++) {
            if ([[directoryContents objectAtIndex:i] isEqualToString:@"EposLog"])
            {
                totalFileUpload--;
            }
            else if ([[directoryContents objectAtIndex:i] isEqualToString:@".DS_Store"])
            {
                totalFileUpload--;
            }
            else if ([[directoryContents objectAtIndex:i] isEqualToString:@"iorder.db"])
            {
                totalFileUpload--;
            }
            else if ([[directoryContents objectAtIndex:i] isEqualToString:@"iorder.db-shm"])
            {
                totalFileUpload--;
            }
            else if ([[directoryContents objectAtIndex:i] isEqualToString:@"iorder.db-wal"])
            {
                totalFileUpload--;
            }
            
        }
        
    }
    
    if (dropboxImageArray.count > 0) {
        totalFileUpload = 1;
        for (int i = 0; i < directoryContents.count; i++) {
            if (![dropboxImageArray containsObject:[directoryContents objectAtIndex:i]]) {
                
                if ([[directoryContents objectAtIndex:i] isEqualToString:@"EposLog"])
                {
                    
                }
                else if ([[directoryContents objectAtIndex:i] isEqualToString:@".DS_Store"])
                {
                    
                }
                else if ([[directoryContents objectAtIndex:i] isEqualToString:@"iorder.db"])
                {
                    
                }
                else if ([[directoryContents objectAtIndex:i] isEqualToString:@"iorder.db-shm"])
                {
                    
                }
                else if ([[directoryContents objectAtIndex:i] isEqualToString:@"iorder.db-wal"])
                {
                    
                }
                else
                {
                    totalFileUpload++;
                    localPath = [resourcePath stringByAppendingPathComponent:[directoryContents objectAtIndex:i]];
                    [self.restClient uploadFile:[directoryContents objectAtIndex:i] toPath:destDir withParentRev:nil fromPath:localPath];
                }
                
            }
            
        }

    }
    else
    {
        for (int i = 0; i < directoryContents.count; i++) {
            if (![dropboxImageArray containsObject:[directoryContents objectAtIndex:i]]) {
                
                if ([[directoryContents objectAtIndex:i] isEqualToString:@"EposLog"])
                {
                    
                }
                else if ([[directoryContents objectAtIndex:i] isEqualToString:@".DS_Store"])
                {
                    
                }
                else if ([[directoryContents objectAtIndex:i] isEqualToString:@"iorder.db"])
                {
                    
                }
                else if ([[directoryContents objectAtIndex:i] isEqualToString:@"iorder.db-shm"])
                {
                    
                }
                else if ([[directoryContents objectAtIndex:i] isEqualToString:@"iorder.db-wal"])
                {
                    
                }
                else
                {
                    localPath = [resourcePath stringByAppendingPathComponent:[directoryContents objectAtIndex:i]];
                    [self.restClient uploadFile:[directoryContents objectAtIndex:i] toPath:destDir withParentRev:nil fromPath:localPath];
                }
                
            }
            
        }
    }
    
    
    //[self showSuccessLoading];
}

-(void)restoreImageFileFromDropBox
{
    
    totalFileDownload = dropboxImageArray.count + 1;
    NSString *localDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *databasePath;
    
    for (int i = 0; i < dropboxImageArray.count; i++)
    {
            databasePath = [localDir stringByAppendingPathComponent:[dropboxImageArray objectAtIndex:i]];
            NSString *dropBoxPath = [NSString stringWithFormat:@"/Images/%@",[dropboxImageArray objectAtIndex:i]];
            [self.restClient loadFile:dropBoxPath intoPath:databasePath];
    }
    
    //[self startRepalcingRestoreDatabase];
    [self performSelector:@selector(startRepalcingRestoreDatabase) withObject:nil afterDelay:20.0 ];
}

-(void)startRepalcingRestoreDatabase
{
    //[KVNProgress showWithStatus:@"Updating Database..."];
    if([self replaceRestoreDatabaseWithReadData])
    {
        [self showAlertView:@"Please restart app" title:@"Success"];
    }
    else
    {
        [self showAlertView:@"Restore fail. Please re-install and re-register." title:@"Warning"];
    }
}

#pragma mark - kvprogress
-(void)showSuccessLoading
{
    
    if (databaseID.length > 0) {
        [self removeDataTxtFileWithFileName:@"data.txt"];
    }
    
    [KVNProgress showSuccessWithStatus:@"Process Complete"];
}

-(void)showSuccessRestoreDBLoading
{
    //[KVNProgress showSuccessWithStatus:@"Database Success Restore"];
    [self performSelector:@selector(showDownloadingImageLoading) withObject:nil afterDelay:3.0 ];
    
    if (databaseID.length > 0) {
        [self removeDataTxtFileWithFileName:@"data2.txt"];
        
    }
    
}

-(void)showDownloadingImageLoading
{
    //[KVNProgress showWithStatus:@"Downloading Images N Updating Database..."];
    [self restoreImageFileFromDropBox];
}

#pragma mark read n replace appregistration table to restore db
-(BOOL)readExistingDatabaseAppRegTable
{
    [readAppRegistrationArray removeAllObjects];
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rsRead = [db executeQuery:@"Select * from AppRegistration"];
        
        if ([rsRead next]) {
            [readAppRegistrationArray addObject:[rsRead resultDictionary]];
        }
        [rsRead close];
        
    }];
    [queue close];
    
    if (readAppRegistrationArray.count > 0) {
        return true;
    }
    else
    {
        return false;
    }
}

-(BOOL)replaceRestoreDatabaseWithReadData
{
    __block BOOL updateResult;
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    [queue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"Update AppRegistration set App_CompanyName = ?, App_LicenseID = ?"
         ", App_RegKey = ?, App_ProductKey = ?, App_Status = ?"
         ", App_ReqExpdate = ?, App_Action = ?, App_TerminalQty = ?"
         ", App_DealerID = ?, App_PurchaseID = ?",[[readAppRegistrationArray objectAtIndex:0] objectForKey:@"App_CompanyName"],[[readAppRegistrationArray objectAtIndex:0] objectForKey:@"App_LicenseID"],[[readAppRegistrationArray objectAtIndex:0] objectForKey:@"App_RegKey"],[[readAppRegistrationArray objectAtIndex:0] objectForKey:@"App_ProductKey"],[[readAppRegistrationArray objectAtIndex:0] objectForKey:@"App_Status"],[[readAppRegistrationArray objectAtIndex:0] objectForKey:@"App_ReqExpdate"],[[readAppRegistrationArray objectAtIndex:0] objectForKey:@"App_Action"],[NSNumber numberWithInt:[[[readAppRegistrationArray objectAtIndex:0] objectForKey:@"App_TerminalQty"] integerValue]],[[readAppRegistrationArray objectAtIndex:0] objectForKey:@"App_PurchaseID"],[[readAppRegistrationArray objectAtIndex:0] objectForKey:@"App_DealerID"]];
        
        if (![db hadError]) {
            updateResult = true;
            //NSLog(@"%@",@"Success Replace Data");
        }
        else
        {
            updateResult = false;
        }
        
        
    }];
    [queue close];
    
    if (updateResult == true) {
        [KVNProgress showSuccessWithStatus:@"Progress Complete."];
        return true;
    }
    else
    {
        [KVNProgress dismiss];
        return false;
    }
    //return updateResult;
}


-(void)writeCompanyName
{
    
    //get the documents directory:
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains
    (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    //make a file name to write the data to using the documents directory:
    NSString *fileName = [NSString stringWithFormat:@"%@/data.txt",
                          documentsDirectory];
    //create content - four lines of text
    NSString *content = databaseID;
    
    //save content to the documents directory
    [content writeToFile:fileName
              atomically:NO
                encoding:NSStringEncodingConversionAllowLossy
                   error:nil];
    
    
}


-(void)removeDataTxtFileWithFileName:(NSString *)fileName
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSString *filePath = [NSString stringWithFormat:@"%@/%@",
                          documentsPath,fileName];
    NSError *error;
    
    if([fileManager fileExistsAtPath:filePath])
    {
        [fileManager removeItemAtPath:filePath error:&error];
    }
    
    
}
@end
