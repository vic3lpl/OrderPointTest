#import <Foundation/Foundation.h>

//status check macro
#define IS_INCLUDE_STATUS(target, key) (((target) & (key)) == (key))

enum ResultErrorType {
    RESULT_ERR_NONE = 0,
    RESULT_ERR_EPOSPRINT,
    RESULT_ERR_EPSONIO,
    RESULT_ERR_EPOSBT
};

@interface Result : NSObject
    //properties
    @property (nonatomic, assign) unsigned long printerStatus;
    @property (nonatomic, assign) unsigned long batteryStatus;
    @property (nonatomic, assign) int errStatus;
    @property (nonatomic, assign) int errType;

- (id)init;
- (void)setErrInfo:(int)type Status:(int)status;

@end
