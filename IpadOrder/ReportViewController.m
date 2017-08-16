//
//  ReportViewController.m
//  IpadOrder
//
//  Created by IRS on 9/9/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "ReportViewController.h"

@interface ReportViewController ()

@end

@implementation ReportViewController
@synthesize splitViewController;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    
    [splitViewController.view setFrame:CGRectMake(0,0, 768, 1024)];
    
    self.view.frame=CGRectMake(0,100, 768, 1024);
    
    [self.view addSubview:splitViewController.view];
    
    //self.navigationController.toolbarHidden = NO;
    
    //self.navigationController.navigationBar.hidden=NO;
    
    //self.title = @"Structure";
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button addTarget:self
               action:@selector(closeReportSplitView)
     forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"< Back" forState:UIControlStateNormal];
    //[button setBackgroundColor:[UIColor redColor]];
    
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.frame = CGRectMake(4, 28, 60, 30);
    [self.view addSubview:button];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation NS_AVAILABLE_IOS(5_0){
    
    return NO;
    
}

-(void)closeReportSplitView
{
    [self dismissViewControllerAnimated:NO completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
