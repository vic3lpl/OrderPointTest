//
//  TestScaleViewController.h
//  IpadOrder
//
//  Created by IRS on 7/27/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ImageToDrag.h"
#import <YAScrollSegmentControl/YAScrollSegmentControl.h>

@interface TestScaleViewController : UIViewController <UIGestureRecognizerDelegate,YAScrollSegmentControlDelegate>


- (IBAction)clickBtn:(id)sender;
//@property (strong, nonatomic) IBOutlet UIView *myview;
@property (strong, nonatomic) IBOutlet YAScrollSegmentControl *scrollSegment;

- (IBAction)addView:(id)sender;

- (IBAction)removeSegment:(id)sender;

@end
