#import <Foundation/Foundation.h>
#import "Result.h"

@implementation Result

@synthesize printerStatus;
@synthesize batteryStatus;
@synthesize errType;
@synthesize errStatus;

-(id)init
{
    self = [super init];
    if(self) {
        printerStatus = 0;
        batteryStatus = 0;
        errStatus = 0;
        errType = RESULT_ERR_NONE;
    }
    return self;
}

-(void)setErrInfo:(int)type Status:(int)status
{
    errType = type;
    errStatus = status;
}

@end
