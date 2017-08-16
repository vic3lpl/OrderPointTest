//
//  ContainerViewController.h
//  SpliViewExampleForAmirAkramPMLN
//
//  Created by Qasim Masud on 06/02/2013.
//  Copyright (c) 2013 Qasim Masud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RootTableViewController.h"
//#import "DetailViewController.h"
#import "CompanyDetailViewController.h"
@interface ContainerViewController : UIViewController
{
    UISplitViewController  *splitViewController;
}
@property (nonatomic, retain) IBOutlet UISplitViewController *splitViewController;
//@property (nonatomic, retain) IBOutlet DetailViewController *detailViewController;
@property (nonatomic, retain) IBOutlet RootTableViewController *rootViewController;
@property (nonatomic, retain) IBOutlet CompanyDetailViewController *detailViewController;
@end
