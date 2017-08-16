//
//  ImageToDrag.m
//
//  Created by John on 1/11/11.
//  Copyright iOSDeveloperTips.com All rights reserved.
//

#import "ImageToDrag.h"
#import <FMDatabase.h>

@implementation ImageToDrag

- (id)initWithImage:(UIImage *)image
{
	if (self = [super initWithImage:image])
		self.userInteractionEnabled = YES;
    
    /*
    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(scale:)];
    [pinchRecognizer setDelegate:self];
    [self addGestureRecognizer:pinchRecognizer];
    
    UIRotationGestureRecognizer *rotationRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotate:)];
    [rotationRecognizer setDelegate:self];
    [self addGestureRecognizer:rotationRecognizer];
    */
	return self;
}


-(void)scale:(id)sender {
    
    if([(UIPinchGestureRecognizer*)sender state] == UIGestureRecognizerStateBegan) {
        _lastScale = 1.0;
    }
    
    CGFloat scale = 1.0 - (_lastScale - [(UIPinchGestureRecognizer*)sender scale]);
    
    //CGFloat scale = 1.0 + ([(UIPinchGestureRecognizer *)sender scale] - _lastScale);
    
    CGAffineTransform currentTransform = self.transform;
    CGAffineTransform newTransform = CGAffineTransformScale(currentTransform, scale, scale);
    
    [self setTransform:newTransform];
    
    _lastScale = [(UIPinchGestureRecognizer*)sender scale];
   
    if ([(UIPinchGestureRecognizer *)sender state] == UIGestureRecognizerStateEnded) {
        _lastScale = [(UIPinchGestureRecognizer*)sender scale];
         //_lastScale = scale;
        [self updateImgScale];
    }
    NSLog(@"check scale %f  scale %f",_lastScale,scale);
    //[self showOverlayWithFrame:photoImage.frame];
    
}

-(void)rotate:(id)sender {
    
    if([(UIRotationGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
        
        _lastRotation = 0.0;
        return;
    }
    
    CGFloat rotation = 0.0 - (_lastRotation - [(UIRotationGestureRecognizer*)sender rotation]);
    
    CGAffineTransform currentTransform = self.transform;
    CGAffineTransform newTransform = CGAffineTransformRotate(currentTransform,rotation);
    
    [self setTransform:newTransform];
    
    _lastRotation = [(UIRotationGestureRecognizer*)sender rotation];
   
    //[self showOverlayWithFrame:self.frame];
}

- (void) touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
	// When a touch starts, get the current location in the view
	currentPoint = [[touches anyObject] locationInView:self];
    
    NSLog(@"%f",currentPoint.x);
}

- (void) touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
	// Get active location upon move
	CGPoint activePoint = [[touches anyObject] locationInView:self];

	// Determine new point based on where the touch is now located
	CGPoint newPoint = CGPointMake(self.center.x + (activePoint.x - currentPoint.x),
                                 self.center.y + (activePoint.y - currentPoint.y));

	//--------------------------------------------------------
	// Make sure we stay within the bounds of the parent view
	//--------------------------------------------------------
  float midPointX = CGRectGetMidX(self.bounds);
	// If too far right...
  if (newPoint.x > self.superview.bounds.size.width  - midPointX)
  	newPoint.x = self.superview.bounds.size.width - midPointX;
	else if (newPoint.x < midPointX) 	// If too far left...
  	newPoint.x = midPointX;
  
	float midPointY = CGRectGetMidY(self.bounds);
  // If too far down...
	if (newPoint.y > self.superview.bounds.size.height  - midPointY)
  	newPoint.y = self.superview.bounds.size.height - midPointY;
	else if (newPoint.y < midPointY)	// If too far up...
  	newPoint.y = midPointY;

	// Set new center location
	self.center = newPoint;

    //NSLog(@"x= %f , y=%f",newPoint.x,newPoint.y);
    
}

/*
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return NO;
}

#pragma mark UIGestureRegognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return ![gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] && ![gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]];
}
*/
#pragma mark - sqlite
-(void)updateImgScale
{
    FMDatabase *dbTableDesign = [FMDatabase databaseWithPath:_dbPath];
    
    if (![dbTableDesign open]) {
        NSLog(@"Failt To Open DB");
        return;
    }
    
    [dbTableDesign executeUpdate:@"Delete from TempTablePlan where TP_ID = ?",[NSNumber numberWithInt:self.tag]];
    
    BOOL dbNoError = [dbTableDesign executeUpdate:@"Insert into TempTablePlan ("
     "TP_ID, TP_Scale) values (?,?)",[NSNumber numberWithInt:self.tag],[NSNumber numberWithFloat:_lastScale]];
    
    if (dbNoError) {
        NSLog(@"Success");
    }
    else
    {
        NSLog(@"Error");
    }
    
    
    [dbTableDesign close];
    
}

@end
