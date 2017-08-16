//
//  TestAZViewController.m
//  IpadOrder
//
//  Created by IRS on 11/23/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "TestAZViewController.h"

@interface TestAZViewController ()

@end

@implementation TestAZViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)btnTestDone:(id)sender {
    if (_delegate != nil) {
        [_delegate testAz];
    }
}
@end
