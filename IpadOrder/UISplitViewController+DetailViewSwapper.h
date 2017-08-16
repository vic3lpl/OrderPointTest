//
//  UISplitViewController+DetailViewSwapper.h
//  MasterDetail


#import <UIKit/UIKit.h>

@interface UISplitViewController (DetailViewSwapper)

- (void)swapDetailViewControllerWith: (UIViewController<UISplitViewControllerDelegate> *) newDetailViewController;

@end
