//
//  ImageToDrag.h
//
//  Created by John on 1/11/11.
//  Copyright iOSDeveloperTips.com All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>


@interface ImageToDrag : UIImageView <UIGestureRecognizerDelegate>
{
	CGPoint currentPoint;
    
    CGFloat _lastScale;
    CGFloat _lastRotation;
    CGFloat _firstX;
    CGFloat _firstY;
    CAShapeLayer *_marque;
}

@property (nonatomic,weak) NSString *dbPath;
@property (nonatomic,weak) NSString *tpName;
@property (nonatomic) CGFloat lscale;

@end
