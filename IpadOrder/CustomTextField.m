//
//  CustomTextField.m
//  IpadOrder
//
//  Created by IRS on 24/02/2016.
//  Copyright © 2016 IrsSoftware. All rights reserved.
//

#import "CustomTextField.h"

@implementation CustomTextField

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (CGRect)textRectForBounds:(CGRect)bounds
{
    return CGRectInset(bounds, 5, 0);
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
    return CGRectInset(bounds, 5, 0);
}

- (void)drawRect:(CGRect)rect
{
    
    UIImage *textFieldBackground = [[UIImage imageNamed:@"blueBorder.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(8.0, 5.0, 8.0, 5.0)];
    [textFieldBackground drawInRect:[self bounds]];
     
}

@end
