//
//  BaseDetailViewController.h
//  MasterDetail


#import <UIKit/UIKit.h>

@interface BaseDetailViewController : UIViewController <UISplitViewControllerDelegate>

@property(nonatomic, strong) UIPopoverController *masterPopoverController;

@end
