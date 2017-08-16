//
//  TestAZViewController.h
//  IpadOrder
//
//  Created by IRS on 11/23/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TestAzDelegate <NSObject>

@required
-(void)testAz;

@end

@interface TestAZViewController : UIViewController
- (IBAction)btnTestDone:(id)sender;
@property (nonatomic,weak) id<TestAzDelegate>delegate;

@end
