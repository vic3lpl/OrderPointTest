//
//  TestScrollViewController.h
//  IpadOrder
//
//  Created by IRS on 12/23/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TestScrollViewController : UIViewController
{
    int pageNumber;
}
- (id)initWithPageNumber:(int)page;
@end
