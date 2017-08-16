#import <Foundation/Foundation.h>
#import "Result.h"

@interface MsgMaker : NSObject
    //public methods
    + (NSString *)makeErrorMessage:(Result *)result;
    + (NSString *)makeWarningMessage:(Result *)result;

@end
