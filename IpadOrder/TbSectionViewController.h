//
//  TbSectionViewController.h
//  IpadOrder
//
//  Created by IRS on 26/02/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TbSectionDelegate <NSObject>

@optional
-(void)passTbSectionBackToSelectTableViewWithNo:(int)tbSectionNo SectionName:(NSString *)tbSectionName;

@end

@interface TbSectionViewController : UIViewController
{
    int pageNumber;
}
-(id)initWithPageNumber:(int)page;
@property NSString *tableSection;
@property(nonatomic, weak)id<TbSectionDelegate>delegate;
@end
