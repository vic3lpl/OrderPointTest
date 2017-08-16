//
//  TestScrollViewController.m
//  IpadOrder
//
//  Created by IRS on 12/23/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "TestScrollViewController.h"
static NSArray *__pageControlColorList = nil;
@interface TestScrollViewController ()

@end

@implementation TestScrollViewController

+ (UIColor *)pageControlColorWithIndex:(NSUInteger)index {
    if (__pageControlColorList == nil) {
        __pageControlColorList = [[NSArray alloc] initWithObjects:[UIColor redColor], [UIColor greenColor], [UIColor magentaColor],
                                  [UIColor blueColor], [UIColor orangeColor], [UIColor brownColor], [UIColor grayColor], nil];
    }
    
    // Mod the index by the list length to ensure access remains in bounds.
    return [__pageControlColorList objectAtIndex:index % [__pageControlColorList count]];
}

- (id)initWithPageNumber:(int)page {
    if (self = [super initWithNibName:@"TestScrollViewController" bundle:nil]) {
        pageNumber = page;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.view.backgroundColor = [TestScrollViewController pageControlColorWithIndex:pageNumber];
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

@end
