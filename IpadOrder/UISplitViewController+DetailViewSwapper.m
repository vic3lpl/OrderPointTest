//
//  UISplitViewController+DetailViewSwapper.m
//  MasterDetail


#import "UISplitViewController+DetailViewSwapper.h"
#import "BaseDetailViewController.h"

@implementation UISplitViewController (DetailViewSwapper)

- (UIViewController *) getCurrentDetailViewController
{
    UINavigationController *detailNavigationController = [self.viewControllers objectAtIndex:1];
    return detailNavigationController.topViewController;
}

- (void) movePopoverButtonFrom: (UIViewController *) currentDetailViewController to: (UIViewController *) newDetailViewController
{
    UIBarButtonItem *popoverButton = currentDetailViewController.navigationItem.leftBarButtonItem;
    currentDetailViewController.navigationItem.leftBarButtonItem = nil;
    
    newDetailViewController.navigationItem.leftBarButtonItem = popoverButton;
}

- (void) copyMasterPopoverControllerFrom: (UIViewController *) currentDetailViewController to: (UIViewController *) newDetailViewController
{
    if ([currentDetailViewController isKindOfClass:[BaseDetailViewController class]]
        && [newDetailViewController isKindOfClass:[BaseDetailViewController class]])
    {
        UIPopoverController *masterPopoverController = ((BaseDetailViewController *) currentDetailViewController).masterPopoverController;
        ((BaseDetailViewController *)newDetailViewController).masterPopoverController = masterPopoverController;
    }
        
}

- (void) replaceDetailViewControllerInViewControllersArrayWith: (UIViewController *) newDetailViewController
{
    UINavigationController *navController=[[UINavigationController alloc] init];
    [navController pushViewController:newDetailViewController animated:YES];
    
    self.viewControllers =  [[NSArray alloc] initWithObjects:
                             [self.viewControllers objectAtIndex:0],
                             navController,
                             nil];
    
}

-(void) dismissMasterPopoverControllerFrom: (UIViewController *)detailViewController
{
    if ([detailViewController isKindOfClass:[BaseDetailViewController class]])
    {
        [((BaseDetailViewController *)detailViewController).masterPopoverController dismissPopoverAnimated:YES];
    }

}


- (void) swapDetailViewControllerWith:(UIViewController<UISplitViewControllerDelegate> *)newDetailViewController
{
    UIViewController *currentDetailViewController = [self getCurrentDetailViewController];
    
    [self movePopoverButtonFrom: currentDetailViewController to: newDetailViewController];
    
    [self copyMasterPopoverControllerFrom: currentDetailViewController to: newDetailViewController];
    
    [self replaceDetailViewControllerInViewControllersArrayWith:newDetailViewController];

    [self dismissMasterPopoverControllerFrom: newDetailViewController];
      
    self.delegate = newDetailViewController;
}

@end
