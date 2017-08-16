//
//  AppUtility.m
//  IpadOrder
//
//  Created by IRS on 15/06/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import "AppUtility.h"

@interface APP_UTILITY()

@end

@implementation APP_UTILITY

+ (APP_UTILITY *)sharedInstance
{
    static APP_UTILITY *sharedInstance = nil;
    
    if (!sharedInstance) {
        sharedInstance = [[super allocWithZone:nil] init];
        
        //AppUtility.userDefaults = [NSUserDefaults standardUserDefaults];
        
        //[AppUtility initPeripheralArray];
        //[AppUtility loadPeripheralList];
    }
    
    return sharedInstance;
}

- (void)showAlertView:(NSString *)title message:(NSString *)message
{
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
}

@end
