//
//  AppUtility.h
//  IpadOrder
//
//  Created by IRS on 15/06/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import <Foundation/Foundation.h>
@import POS_API;
#define AppUtility [APP_UTILITY sharedInstance]
@interface APP_UTILITY : NSObject
@property BOOL isConnect;
- (void)showAlertView:(NSString *)title message:(NSString *)message;
-(NSUUID *)convertStringToUUID:(NSString *)uuidString;

+ (APP_UTILITY *)sharedInstance;

@end
