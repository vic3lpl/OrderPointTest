//
//  main.m
//  IpadOrder
//
//  Created by IRS on 6/29/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

NSString *baseUrl = @"http://idealerapsx.azurewebsites.net";
NSString *appApiVersion = @"2016.12.14";
NSString *orderPointVersion = @"v1.4.05.2017";
int main(int argc, char * argv[]) {
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
