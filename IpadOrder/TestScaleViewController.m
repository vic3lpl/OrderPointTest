//
//  TestScaleViewController.m
//  IpadOrder
//
//  Created by IRS on 7/27/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "TestScaleViewController.h"

@interface TestScaleViewController ()
{
    UIImageView *img;
    CGPoint currentPoint;
    int segmentIndex;
    UIView *selectedView;
    NSMutableArray *newButton;
}

@end

@implementation TestScaleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    // Do any additional setup after loading the view from its nib.
    img = [[ImageToDrag alloc]initWithImage:[UIImage imageNamed:@"TableBlue"]];
    newButton = [[NSMutableArray alloc]init];
    self.scrollSegment.delegate = self;
    self.scrollSegment.buttons = @[@"Section 1"];
    self.scrollSegment.selectedIndex = 0;
    
    UIView *dyView = [[UIView alloc]initWithFrame:CGRectMake(19, 105, 870, 649)];
    dyView.tag = 10000;
    dyView.backgroundColor = [UIColor grayColor];
    
    [self.view addSubview:dyView];
    
    UILabel *myLabel = [[UILabel alloc]initWithFrame:CGRectMake(389, 310, 92, 30)];
    myLabel.text = [NSString stringWithFormat:@"Section %lu",(long)self.scrollSegment.buttons.count];
    [myLabel setTextColor:[UIColor whiteColor]];
    [dyView addSubview:myLabel];
    
    /*
    UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc]
                                                        initWithTarget:self
                                                        action:@selector(handlePinch:)];[self.table addGestureRecognizer:pinchGestureRecognizer];
    UIRotationGestureRecognizer *rotateRecognizer = [[UIRotationGestureRecognizer alloc]
                                                     initWithTarget:self
                                                     action:@selector(handleRotate:)];
    //[self.table addGestureRecognizer:rotateRecognizer];
    
    //[self.table addGestureRecognizer:pinchGestureRecognizer];
    
    //pinchGestureRecognizer.delegate = self;
    //rotateRecognizer.delegate = self;
     */
    
}



- (void) handleRotate:(UIRotationGestureRecognizer*) recognizer
{
    UIGestureRecognizerState state = [recognizer state];
    
    if (state == UIGestureRecognizerStateBegan || state == UIGestureRecognizerStateChanged)
    {
        CGFloat rotation = [recognizer rotation];
        [recognizer.view setTransform:CGAffineTransformRotate(recognizer.view.transform, rotation)];
        [recognizer setRotation:0];
    }
}


- (void) handlePinch:(UIPinchGestureRecognizer*) recognizer
{
    recognizer.view.transform = CGAffineTransformScale(recognizer.view.transform, recognizer.scale, recognizer.scale);
    NSLog(@"%f", recognizer.scale);
    recognizer.scale = 1;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return ![gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] && ![gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return NO;
}



- (IBAction)clickBtn:(id)sender {
    
    newButton = [self.scrollSegment.buttons mutableCopy];
    [newButton addObject:[NSString stringWithFormat:@"Section %lu",(long)self.scrollSegment.buttons.count + 1]];

    self.scrollSegment.buttons = newButton;
    self.scrollSegment.selectedIndex = newButton.count - 1;
    
    UIView *dyView = [[UIView alloc]initWithFrame:CGRectMake(19, 105, 870, 649)];
    dyView.tag = 10000 + newButton.count - 1;
    dyView.backgroundColor = [UIColor grayColor];
    
    [self.view addSubview:dyView];
    
    UILabel *myLabel = [[UILabel alloc]initWithFrame:CGRectMake(389, 310, 92, 30)];
    myLabel.text = [NSString stringWithFormat:@"Section %lu",(long)self.scrollSegment.buttons.count];
    [myLabel setTextColor:[UIColor whiteColor]];
    [myLabel setFont:[UIFont boldSystemFontOfSize:15]];
    [dyView addSubview:myLabel];
    
}

-(void)didSelectItemAtIndex:(NSInteger)index
{
    NSLog(@"Button selected at index: %lu", (long)index);
    
    for (int j = 0; j < self.scrollSegment.buttons.count; j ++) {
        UIView *delImgView = (UIView*) [self.view viewWithTag:j+10000];
        if (j+10000 == index + 10000) {
            segmentIndex = j + 10000;
            delImgView.hidden = NO;
        }
        else
        {
            delImgView.hidden = YES;
        }
        delImgView = nil;
    }
   
    
}



- (IBAction)addView:(id)sender {
    img = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"TableBlue"]];
    //img.dbPath = dbPath;
    img.center = CGPointMake(300, 300);
    
    img.userInteractionEnabled = YES;
    
    selectedView = (UIView *)[self.view viewWithTag:segmentIndex];
    
    [selectedView addSubview:img];
}

- (IBAction)removeSegment:(id)sender {
    //self.scrollSegment.buttons
}
@end
