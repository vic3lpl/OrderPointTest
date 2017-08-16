//
//  ContainerViewController.m
//  SpliViewExampleForAmirAkramPMLN
//
//  Created by Qasim Masud on 06/02/2013.
//  Copyright (c) 2013 Qasim Masud. All rights reserved.
//

#import "ContainerViewController.h"

@interface ContainerViewController ()

@end

@implementation ContainerViewController
@synthesize splitViewController;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [splitViewController.view setFrame:CGRectMake(0,0, 768, 1024)];
    //   [self.view removeFromSuperview];
    self.view.frame=CGRectMake(0,100, 768, 1024);
	
    [self.view addSubview:splitViewController.view];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button addTarget:self
               action:@selector(closeSplitView:)
     forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"< Back" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.frame = CGRectMake(4, 28, 60, 30);
    [self.view addSubview:button];
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)closeSplitView:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation NS_AVAILABLE_IOS(5_0){
    return NO;
}

@end
