//
//  TbSectionViewController.m
//  IpadOrder
//
//  Created by IRS on 26/02/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import "TbSectionViewController.h"
#import <FMDB.h>
#import "LibraryAPI.h"
#import <QuartzCore/QuartzCore.h>

@interface TbSectionViewController ()
{
    NSString *dbPath;
    FMDatabase *dbTbSection;
    int sectionStartNo;
    int sectionEndNo;
    NSMutableArray *sectionArray;
    
    NSArray *arrPath;
    NSString *imgDir;
    NSString *imgPath;
}
@end

@implementation TbSectionViewController

-(id)initWithPageNumber:(int)page
{
    if (self = [super initWithNibName:@"TbSectionViewController" bundle:nil]) {
        pageNumber = page;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    sectionArray = [[NSMutableArray alloc] init];
    dbPath = [[LibraryAPI sharedInstance] getDbPath];
    
    if (pageNumber == 0) {
        sectionStartNo = 0;
        sectionEndNo = 7;
    }
    else
    {
        sectionStartNo = (7 * pageNumber) + 1;
        sectionEndNo = 7 * (pageNumber + 1);
    }
     
    
    dbTbSection = [FMDatabase databaseWithPath:dbPath];
    
    if (![dbTbSection open]) {
        NSLog(@"Fail To Open");
        return;
    }
    
    //FMResultSet *rs = [dbTbSection executeQuery:@"Select * from TableSection"];
    
    FMResultSet *rs = [dbTbSection executeQuery:@"Select *, "
                       " (Select count(*) from TableSection as t2 where t2.TS_Name < t1.TS_Name) as Row_Num"
                       " from TableSection as t1"
                       " where Row_Num between ? and ?",[NSNumber numberWithInt:sectionStartNo],[NSNumber numberWithInt:sectionEndNo]];
    
    while ([rs next]) {
        [sectionArray addObject:[rs resultDictionary]];
    }
    
    [rs close];
    
    int x = 5;
    int y = 3;
    
    for (int i = 0; i < sectionArray.count; i++) {
        UIButton *btnSection = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        btnSection.frame = CGRectMake(x, y, 117.0, 45.0);
        [btnSection setTitle:[[sectionArray objectAtIndex:i] objectForKey:@"TS_Name"] forState:UIControlStateNormal];
        [btnSection setTag:[[[sectionArray objectAtIndex:i] objectForKey:@"TS_ID"] integerValue] + 20000];
        [btnSection setTitleColor:[UIColor blueColor] forState:UIControlStateSelected];
        //[btnSection setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        
        //[btnSection setBackgroundImage:[UIImage imageNamed:@"blacktab"] forState:UIControlStateNormal];
        [btnSection setBackgroundColor:[UIColor colorWithRed:9/255.0 green:82/255.0 blue:159/255.0 alpha:1.0]];
        
        //[btnSection setUserInteractionEnabled:true];
        
        [self.view addSubview:btnSection];
        if (i == 0) {
            [btnSection sendActionsForControlEvents:UIControlEventTouchDown];
        }
        
        btnSection = nil;
        //calc next button x (8 is space between button, 105 is button width)
        x = x + 117 + 9;
        
    }

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
/*
-(IBAction)btnSectionClickWithNo:(id)sender
{
    //UIButton *btn = (UIButton *)sender;
    
    //UIImageView *imgView = (UIImageView*) [self.view viewWithTag:gesture.view.tag];
    
    for (int i = 0; i < sectionArray.count; i++) {
        if ([[[sectionArray objectAtIndex:i] objectForKey:@"TS_ID"] integerValue] + 20000 == [sender tag]) {
            UIButton *btn = (UIButton *)[self.view viewWithTag:[sender tag]];
            
            [btn setBackgroundImage:[UIImage imageNamed:@"purpletab"] forState:UIControlStateNormal];
            btn = nil;
        }
        else
        {
            UIButton *btn = (UIButton *)[self.view viewWithTag:[[[sectionArray objectAtIndex:i] objectForKey:@"TS_ID"] integerValue] + 20000];
            
            [btn setBackgroundImage:[UIImage imageNamed:@"blacktab"] forState:UIControlStateNormal];
            btn = nil;
        }
    }
    
    
    
    int tbSectionNo = 0;
    if (_delegate != nil) {
        NSLog(@"%@",[sender currentTitle]);
        tbSectionNo = [sender tag];
        
        [_delegate passTbSectionBackToSelectTableViewWithNo:tbSectionNo SectionName:[sender currentTitle]];
    }
}
 */

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
